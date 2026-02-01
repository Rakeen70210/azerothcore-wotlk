#include "mod_elite_dynamic_gear_loader.h"

#include "Config.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Player.h"
#include "QueryResult.h"
#include "DatabaseScript.h"
#include "DBCStores.h"
#include "Log.h"
#include "LootMgr.h"
#include "MiscScript.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Random.h"
#include "Tokenize.h"
#include "StringConvert.h"

#include <algorithm>
#include <array>
#include <limits>
#include <mutex>
#include <optional>
#include <shared_mutex>
#include <string>
#include <unordered_set>
#include <vector>

namespace
{
    // AzerothCore item qualities are 0..7 (ITEM_QUALITY_POOR..ITEM_QUALITY_HEIRLOOM).
    constexpr uint8 kQualityCount = 8;

    enum class ContentType : uint8
    {
        World,
        Dungeon,
        Raid
    };

    struct LevelWindow
    {
        uint8 low{3};
        uint8 high{3};
    };

    struct DropProfile
    {
        float chancePercent{20.0f};
        uint8 minDrops{1};
        uint8 maxDrops{1};
        LevelWindow reqLevelWindow{};
        std::array<float, kQualityCount> qualityWeights{};
    };

    struct IlvlBand
    {
        uint16 low{0};
        uint16 high{0};
        bool valid{false};
    };

    struct ModuleConfig
    {
        bool enabled{true};

        // Candidate pool filters
        bool excludeRequiredSkillItems{true};
        std::unordered_set<uint32> excludedInventoryTypes;

        // Runtime selection safety
        uint32 pickAttempts{25};

        // Boss handling
        float bossChanceMultiplier{1.5f};
        uint8 bossExtraDropsBonus{0}; // adds to min/max drops

        // Ilvl banding derived from DB by RequiredLevel buckets.
        uint8 ilvlPercentileLow{20};
        uint8 ilvlPercentileHigh{80};
        uint16 ilvlBandExpand{0}; // widen both sides by this many ilvls

        // Profiles
        DropProfile world{};
        DropProfile dungeon{};
        DropProfile raid{};
    };

    struct Cache
    {
        uint8 maxPlayerLevel{80};

        // Indexed by RequiredLevel (1..max), then by Quality (0..7)
        std::vector<std::array<std::vector<uint32>, kQualityCount>> itemsByReqLevelAndQuality;

        // Expected ilvl band by target level (1..max). Derived from DB items with RequiredLevel = level.
        std::vector<IlvlBand> ilvlBandByLevel;
    };

    std::shared_mutex g_cacheMutex;
    std::shared_ptr<Cache const> g_cache;
    std::shared_mutex g_configMutex;
    std::shared_ptr<ModuleConfig const> g_configPtr;

    uint8 ClampToLevel(int32 level, uint8 maxPlayerLevel)
    {
        if (level < 1)
            return 1;
        if (level > maxPlayerLevel)
            return maxPlayerLevel;
        return uint8(level);
    }

    std::unordered_set<uint32> ParseUIntSet(std::string const& csv)
    {
        std::unordered_set<uint32> out;
        for (std::string_view tok : Acore::Tokenize(csv, ',', false))
        {
            if (auto v = Acore::StringTo<uint32>(tok))
                out.insert(*v);
        }
        return out;
    }

    std::array<float, kQualityCount> LoadQualityWeights(std::string const& prefix, std::array<float, kQualityCount> const& defaults)
    {
        std::array<float, kQualityCount> weights = defaults;
        for (uint8 q = 0; q < kQualityCount; ++q)
        {
            std::string key = prefix + "." + Acore::ToString(q);
            weights[q] = sConfigMgr->GetOption<float>(key, weights[q], false);
            if (weights[q] < 0.0f)
                weights[q] = 0.0f;
        }
        return weights;
    }

    ModuleConfig LoadConfig()
    {
        ModuleConfig cfg;

        cfg.enabled = sConfigMgr->GetOption<bool>("EliteDynamicGear.Enabled", true);
        cfg.excludeRequiredSkillItems = sConfigMgr->GetOption<bool>("EliteDynamicGear.ExcludeRequiredSkillItems", true);
        cfg.excludedInventoryTypes = ParseUIntSet(sConfigMgr->GetOption<std::string>("EliteDynamicGear.ExcludedInventoryTypes", "4,19", false));

        cfg.pickAttempts = sConfigMgr->GetOption<uint32>("EliteDynamicGear.PickAttempts", 25);

        cfg.bossChanceMultiplier = sConfigMgr->GetOption<float>("EliteDynamicGear.BossChanceMultiplier", 1.5f);
        cfg.bossExtraDropsBonus = uint8(std::max(0, sConfigMgr->GetOption<int32>("EliteDynamicGear.BossExtraDropsBonus", 0)));

        cfg.ilvlPercentileLow = uint8(std::clamp(sConfigMgr->GetOption<int32>("EliteDynamicGear.IlvlBand.PercentileLow", 20), 0, 100));
        cfg.ilvlPercentileHigh = uint8(std::clamp(sConfigMgr->GetOption<int32>("EliteDynamicGear.IlvlBand.PercentileHigh", 80), 0, 100));
        cfg.ilvlBandExpand = uint16(std::max(0, sConfigMgr->GetOption<int32>("EliteDynamicGear.IlvlBand.Expand", 0)));

        // Defaults tuned for a solo-player progression server:
        // - Open world elites guarantee 1 blue+ gear drop (up to 2).
        cfg.world.chancePercent = sConfigMgr->GetOption<float>("EliteDynamicGear.World.ChancePercent", 100.0f);
        cfg.world.minDrops = uint8(std::max(0, sConfigMgr->GetOption<int32>("EliteDynamicGear.World.MinDrops", 1)));
        cfg.world.maxDrops = uint8(std::max<int32>(cfg.world.minDrops, sConfigMgr->GetOption<int32>("EliteDynamicGear.World.MaxDrops", 2)));
        cfg.world.reqLevelWindow.low = uint8(std::max(0, sConfigMgr->GetOption<int32>("EliteDynamicGear.World.ReqLevelWindow.Low", 3)));
        cfg.world.reqLevelWindow.high = uint8(std::max(0, sConfigMgr->GetOption<int32>("EliteDynamicGear.World.ReqLevelWindow.High", 3)));
        cfg.world.qualityWeights = LoadQualityWeights(
            "EliteDynamicGear.World.QualityWeight",
            // 0 poor, 1 common, 2 uncommon, 3 rare, 4 epic, 5 legendary, 6 artifact, 7 heirloom
            // Open world elites: blue (rare) or higher only by default.
            { 0.0f, 0.0f, 0.0f, 10.0f, 2.0f, 0.0f, 0.0f, 0.0f });

        cfg.dungeon.chancePercent = sConfigMgr->GetOption<float>("EliteDynamicGear.Dungeon.ChancePercent", 35.0f);
        cfg.dungeon.minDrops = uint8(std::max(0, sConfigMgr->GetOption<int32>("EliteDynamicGear.Dungeon.MinDrops", 1)));
        cfg.dungeon.maxDrops = uint8(std::max<int32>(cfg.dungeon.minDrops, sConfigMgr->GetOption<int32>("EliteDynamicGear.Dungeon.MaxDrops", 1)));
        cfg.dungeon.reqLevelWindow.low = uint8(std::max(0, sConfigMgr->GetOption<int32>("EliteDynamicGear.Dungeon.ReqLevelWindow.Low", 2)));
        cfg.dungeon.reqLevelWindow.high = uint8(std::max(0, sConfigMgr->GetOption<int32>("EliteDynamicGear.Dungeon.ReqLevelWindow.High", 2)));
        cfg.dungeon.qualityWeights = LoadQualityWeights(
            "EliteDynamicGear.Dungeon.QualityWeight",
            { 0.0f, 0.5f, 8.0f, 5.0f, 0.5f, 0.0f, 0.0f, 0.0f });

        cfg.raid.chancePercent = sConfigMgr->GetOption<float>("EliteDynamicGear.Raid.ChancePercent", 60.0f);
        cfg.raid.minDrops = uint8(std::max(0, sConfigMgr->GetOption<int32>("EliteDynamicGear.Raid.MinDrops", 1)));
        cfg.raid.maxDrops = uint8(std::max<int32>(cfg.raid.minDrops, sConfigMgr->GetOption<int32>("EliteDynamicGear.Raid.MaxDrops", 2)));
        cfg.raid.reqLevelWindow.low = uint8(std::max(0, sConfigMgr->GetOption<int32>("EliteDynamicGear.Raid.ReqLevelWindow.Low", 1)));
        cfg.raid.reqLevelWindow.high = uint8(std::max(0, sConfigMgr->GetOption<int32>("EliteDynamicGear.Raid.ReqLevelWindow.High", 1)));
        cfg.raid.qualityWeights = LoadQualityWeights(
            "EliteDynamicGear.Raid.QualityWeight",
            { 0.0f, 0.0f, 2.0f, 10.0f, 5.0f, 0.1f, 0.0f, 0.0f });

        return cfg;
    }

    uint16 Percentile(std::vector<uint16> const& sorted, uint8 p)
    {
        if (sorted.empty())
            return 0;
        uint32 n = uint32(sorted.size());
        uint32 idx = (uint32(p) * (n - 1)) / 100;
        return sorted[idx];
    }

    std::shared_ptr<Cache> BuildCache(ModuleConfig const& cfg)
    {
        auto cache = std::make_shared<Cache>();
        cache->maxPlayerLevel = uint8(std::clamp(sConfigMgr->GetOption<int32>("MaxPlayerLevel", 80), 1, 255));
        cache->itemsByReqLevelAndQuality.assign(cache->maxPlayerLevel + 1, {});
        cache->ilvlBandByLevel.assign(cache->maxPlayerLevel + 1, {});

        std::vector<std::vector<uint16>> ilvlsByReqLevel(cache->maxPlayerLevel + 1);

        // We build a candidate pool from the game DB itself.
        // Keep the query to only the fields we need to reduce memory pressure.
        QueryResult result = WorldDatabase.Query(
            "SELECT entry, RequiredLevel, ItemLevel, Quality, class, InventoryType, RequiredSkill "
            "FROM item_template "
            "WHERE class IN (2,4) AND InventoryType <> 0");

        if (!result)
        {
            LOG_WARN("server.loading", "[EliteDynamicGear] item_template query returned no rows; dynamic gear drops disabled.");
            return cache;
        }

        uint32 totalCandidates = 0;
        do
        {
            Field* fields = result->Fetch();
            uint32 itemId = fields[0].Get<uint32>();
            uint32 reqLevel = fields[1].Get<uint32>();
            uint32 itemLevel = fields[2].Get<uint32>();
            uint32 quality = fields[3].Get<uint32>();
            uint32 itemClass = fields[4].Get<uint32>();
            uint32 inventoryType = fields[5].Get<uint32>();
            uint32 requiredSkill = fields[6].Get<uint32>();

            (void)itemClass; // kept for future expansion; query already filters to weapon/armor.

            if (reqLevel == 0 || reqLevel > cache->maxPlayerLevel)
                continue;

            if (quality >= kQualityCount)
                continue;

            if (cfg.excludeRequiredSkillItems && requiredSkill != 0)
                continue;

            if (!cfg.excludedInventoryTypes.empty() && cfg.excludedInventoryTypes.find(inventoryType) != cfg.excludedInventoryTypes.end())
                continue;

            cache->itemsByReqLevelAndQuality[reqLevel][quality].push_back(itemId);
            ilvlsByReqLevel[reqLevel].push_back(uint16(std::min<uint32>(itemLevel, std::numeric_limits<uint16>::max())));
            ++totalCandidates;
        } while (result->NextRow());

        // Compute ilvl bands per required level bucket.
        for (uint8 level = 1; level <= cache->maxPlayerLevel; ++level)
        {
            auto& vec = ilvlsByReqLevel[level];
            if (vec.empty())
                continue;

            std::sort(vec.begin(), vec.end());
            uint16 low = Percentile(vec, cfg.ilvlPercentileLow);
            uint16 high = Percentile(vec, cfg.ilvlPercentileHigh);

            if (cfg.ilvlBandExpand > 0)
            {
                low = (low > cfg.ilvlBandExpand) ? uint16(low - cfg.ilvlBandExpand) : 0;
                high = uint16(std::min<uint32>(high + cfg.ilvlBandExpand, std::numeric_limits<uint16>::max()));
            }

            if (low > high)
                std::swap(low, high);

            cache->ilvlBandByLevel[level] = IlvlBand{ low, high, true };
        }

        LOG_INFO("server.loading", "[EliteDynamicGear] Loaded {} equippable item candidates across req levels 1..{}.", totalCandidates, cache->maxPlayerLevel);
        return cache;
    }

    bool IsEligibleElite(Creature const* creature)
    {
        if (!creature || creature->IsPet())
            return false;

        // Include rares (silver) and all higher ranks; exclude normal.
        return creature->GetCreatureTemplate()->rank != CREATURE_ELITE_NORMAL;
    }

    bool IsBossLike(Creature const* creature)
    {
        if (!creature)
            return false;

        if (creature->GetCreatureTemplate()->rank == CREATURE_ELITE_WORLDBOSS)
            return true;

        if (creature->isWorldBoss())
            return true;

        return creature->IsDungeonBoss();
    }

    ContentType GetContentType(Creature const* creature)
    {
        if (!creature)
            return ContentType::World;

        Map const* map = creature->GetMap();
        if (!map)
            return ContentType::World;

        if (map->IsRaid())
            return ContentType::Raid;

        if (map->IsDungeon())
            return ContentType::Dungeon;

        return ContentType::World;
    }

    DropProfile const& GetProfile(ModuleConfig const& cfg, ContentType ct)
    {
        switch (ct)
        {
            case ContentType::Raid: return cfg.raid;
            case ContentType::Dungeon: return cfg.dungeon;
            case ContentType::World:
            default: return cfg.world;
        }
    }

    uint8 ResolveTargetLevel(Creature const* creature, uint8 maxPlayerLevel)
    {
        if (!creature)
            return 1;

        uint8 level = ClampToLevel(creature->GetLevel(), maxPlayerLevel);

        // For open world, prefer zone/area "area_level" (DBC) if present.
        Map const* map = creature->GetMap();
        if (map && !map->IsDungeon() && !map->IsRaid())
        {
            if (uint32 zoneId = creature->GetZoneId())
            {
                if (AreaTableEntry const* zone = sAreaTableStore.LookupEntry(zoneId))
                {
                    if (zone->area_level > 0)
                        level = ClampToLevel(zone->area_level, maxPlayerLevel);
                }
            }

            if (uint32 areaId = creature->GetAreaId())
            {
                if (AreaTableEntry const* area = sAreaTableStore.LookupEntry(areaId))
                {
                    if (area->area_level > 0)
                        level = ClampToLevel(area->area_level, maxPlayerLevel);
                }
            }
        }

        return level;
    }

    uint8 PickQuality(std::array<float, kQualityCount> const& weights)
    {
        float total = 0.0f;
        for (float w : weights)
            total += w;

        if (total <= 0.0f)
            return 2; // default to uncommon if weights are misconfigured

        float r = frand(0.0f, total);
        float acc = 0.0f;
        for (uint8 q = 0; q < kQualityCount; ++q)
        {
            acc += weights[q];
            if (r <= acc)
                return q;
        }
        return uint8(kQualityCount - 1);
    }

    std::optional<uint32> PickItemId(
        Cache const& cache,
        ModuleConfig const& cfg,
        ContentType contentType,
        uint8 targetLevel,
        uint8 minReqLevel,
        uint8 maxReqLevel,
        Player const* lootOwner,
        ObjectGuid sourceGuid)
    {
        if (minReqLevel > maxReqLevel)
            std::swap(minReqLevel, maxReqLevel);

        minReqLevel = std::max<uint8>(1, minReqLevel);
        maxReqLevel = std::min<uint8>(cache.maxPlayerLevel, maxReqLevel);
        targetLevel = std::min<uint8>(cache.maxPlayerLevel, std::max<uint8>(1, targetLevel));

        IlvlBand band{};
        if (targetLevel < cache.ilvlBandByLevel.size())
            band = cache.ilvlBandByLevel[targetLevel];

        DropProfile const& profile = GetProfile(cfg, contentType);

        for (uint32 attempt = 0; attempt < cfg.pickAttempts; ++attempt)
        {
            uint8 reqLevel = urand(minReqLevel, maxReqLevel);
            uint8 quality = PickQuality(profile.qualityWeights);

            auto const& bucket = cache.itemsByReqLevelAndQuality[reqLevel][quality];
            if (bucket.empty())
                continue;

            uint32 itemId = bucket[urand(0u, uint32(bucket.size() - 1))];
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
            if (!proto)
                continue;

            if (proto->RequiredLevel < minReqLevel || proto->RequiredLevel > maxReqLevel)
                continue;

            if (cfg.excludeRequiredSkillItems && proto->RequiredSkill != 0)
                continue;

            if (!cfg.excludedInventoryTypes.empty() && cfg.excludedInventoryTypes.find(proto->InventoryType) != cfg.excludedInventoryTypes.end())
                continue;

            if (band.valid && (proto->ItemLevel < band.low || proto->ItemLevel > band.high))
                continue;

            // Check that the chosen item is actually lootable/visible for the looter.
            LootStoreItem tmp(itemId, 0, 100.0f, false, LOOT_MODE_DEFAULT, 0, 1, 1);
            LootItem preview(tmp);
            if (!preview.AllowedForPlayer(lootOwner, sourceGuid))
                continue;

            return itemId;
        }

        return std::nullopt;
    }

    void AddDynamicDrops(Loot* loot, Player* lootOwner, Creature* source, uint16 lootMode)
    {
        if (!loot || !lootOwner || !source)
            return;

        std::shared_ptr<Cache const> cache;
        {
            std::shared_lock lock(g_cacheMutex);
            cache = g_cache;
        }
        if (!cache)
            return;

        std::shared_ptr<ModuleConfig const> cfg;
        {
            std::shared_lock lock(g_configMutex);
            cfg = g_configPtr;
        }
        if (!cfg || !cfg->enabled)
            return;

        ContentType contentType = GetContentType(source);
        DropProfile const& profile = GetProfile(*cfg, contentType);

        bool isBoss = IsBossLike(source);
        float chance = profile.chancePercent;
        if (isBoss)
            chance = std::min(100.0f, chance * std::max(0.0f, cfg->bossChanceMultiplier));

        if (!roll_chance_f(std::max(0.0f, chance)))
            return;

        uint8 targetLevel = ResolveTargetLevel(source, cache->maxPlayerLevel);

        uint8 minReq = ClampToLevel(int32(targetLevel) - int32(profile.reqLevelWindow.low), cache->maxPlayerLevel);
        uint8 maxReq = ClampToLevel(int32(targetLevel) + int32(profile.reqLevelWindow.high), cache->maxPlayerLevel);

        uint8 minDrops = profile.minDrops;
        uint8 maxDrops = profile.maxDrops;
        if (isBoss && cfg->bossExtraDropsBonus > 0)
        {
            minDrops = uint8(std::min<uint32>(uint32(minDrops) + cfg->bossExtraDropsBonus, 255u));
            maxDrops = uint8(std::min<uint32>(uint32(maxDrops) + cfg->bossExtraDropsBonus, 255u));
        }

        if (maxDrops < minDrops)
            maxDrops = minDrops;

        uint8 dropsToAdd = (maxDrops > minDrops) ? uint8(urand(minDrops, maxDrops)) : minDrops;
        if (dropsToAdd == 0)
            return;

        for (uint8 i = 0; i < dropsToAdd; ++i)
        {
            std::optional<uint32> itemId = PickItemId(
                *cache,
                *cfg,
                contentType,
                targetLevel,
                minReq,
                maxReq,
                lootOwner,
                loot->sourceWorldObjectGUID);

            if (!itemId)
                return;

            LootStoreItem add(*itemId, 0, 100.0f, false, lootMode, 0, 1, 1);
            loot->AddItem(add);
        }
    }

    class EliteDynamicGearDatabaseScript : public DatabaseScript
    {
    public:
        EliteDynamicGearDatabaseScript()
            : DatabaseScript("EliteDynamicGearDatabaseScript", { DATABASEHOOK_ON_AFTER_DATABASES_LOADED })
        {
        }

        void OnAfterDatabasesLoaded(uint32 /*updateFlags*/) override
        {
            ModuleConfig cfg = LoadConfig();
            auto cache = BuildCache(cfg);
            auto cfgPtr = std::make_shared<ModuleConfig>(std::move(cfg));

            {
                std::unique_lock lock(g_configMutex);
                g_configPtr = std::move(cfgPtr);
            }
            {
                std::unique_lock lock(g_cacheMutex);
                g_cache = std::move(cache);
            }
        }
    };

    class EliteDynamicGearLootScript : public MiscScript
    {
    public:
        EliteDynamicGearLootScript()
            : MiscScript("EliteDynamicGearLootScript", { MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS })
        {
        }

        void OnAfterLootTemplateProcess(Loot* loot, LootTemplate const* /*tab*/, LootStore const& store, Player* lootOwner, bool /*personal*/, bool /*noEmptyError*/, uint16 lootMode) override
        {
            // Only creatures.
            if (&store != &LootTemplates_Creature)
                return;

            if (!loot || !lootOwner)
                return;

            Creature* source = ObjectAccessor::GetCreature(*lootOwner, loot->sourceWorldObjectGUID);
            if (!source)
                return;

            if (!IsEligibleElite(source))
                return;

            AddDynamicDrops(loot, lootOwner, source, lootMode);
        }
    };
}

void Addmod_elite_dynamic_gearScripts()
{
    new EliteDynamicGearDatabaseScript();
    new EliteDynamicGearLootScript();
}
