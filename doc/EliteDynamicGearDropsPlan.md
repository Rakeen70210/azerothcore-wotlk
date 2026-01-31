# Elite Dynamic Gear Drops (Zone-/Level-Relative) — Implementation Plan

## Goal
Make **all elite mobs** (gold + silver: dungeon/raid elites, bosses, rares/rare-elites) capable of dropping **any equippable gear** from the game’s database **bounded to the level range appropriate to where the mob is** (open world zone, dungeon, raid). Concretely:

- An elite in **Durotar** should **not** drop gear that requires **level 40**.
- A **level ~30** elite in a dungeon should drop **item-level/required-level appropriate** gear for level ~30 content.
- This applies to **all elite creatures** across **open world, dungeons, and raids**.

This plan assumes AzerothCore (3.3.5a) and uses **runtime loot injection** rather than rewriting every creature’s DB loot tables.

**Server context:** this is a solo-player server (with `mod-playerbots`). The defaults below should prioritize “fun/steady progression” over strict economy preservation, but still avoid extreme out-of-bracket drops.

## Non-Goals / Clarifications (Decide Up Front)
These decisions affect balance, performance, and implementation details. Confirm them before coding:

1. **Additive vs replacement**: Do we **add** a “dynamic gear roll” *in addition to* existing loot, or **replace** existing loot templates for elites?
2. **Drop frequency**: Should *every* eligible elite always drop at least 1 gear item, or should it be chance-based (recommended), or scaled by difficulty (world/dungeon/raid)?
3. **Quality policy**: Should open-world elites be capped at e.g. green/blue while raids can roll epics, or should all contexts be allowed to roll any quality as long as it’s level-appropriate?
4. **Bind rules**: Items keep their normal `item_template` bind rules (BoE/BoP), or do you want overrides?
5. **Expansion scope**: AzerothCore is WotLK; confirm the intended max level (80) and whether custom content/patches change item availability.

## Key Constraints in AzerothCore
- Creature loot is normally driven by DB tables like `creature_loot_template`, but global behavior can be extended by scripts/modules.
- Loot generation provides a hook point:
  - `Loot::FillLoot(...)` calls `LootTemplate::Process(...)`
  - then calls `sScriptMgr->OnAfterLootTemplateProcess(...)` (see `src/server/game/Loot/LootMgr.cpp`)
- `Loot::AddItem(LootStoreItem const&)` is available to add generated items using the same logic as template drops (random suffix/property generation, stack sizing, etc.).

## High-Level Approach (Recommended)
Create a new module (example name: `modules/mod-elite-dynamic-gear`) that **injects additional gear drops** into creature loot during `OnAfterLootTemplateProcess` **only when the loot source is an elite creature** and only when the chosen item matches the **resolved level bracket** of that creature’s location/content.

This approach:
- Automatically applies to **all elite mobs** without DB editing every creature.
- Can be tuned via config / DB override tables.
- Avoids enormous SQL maintenance and remains compatible with future DB creature changes.

## Definitions

### What counts as “elite”
AzerothCore uses `creature_template.rank` (see `CREATURE_ELITE_*` constants). The “gold/silver” requirement maps best to **all non-normal ranks**:

- `CREATURE_ELITE_RARE` (silver dragon / rare)
- `CREATURE_ELITE_ELITE` (gold)
- `CREATURE_ELITE_RAREELITE`
- `CREATURE_ELITE_WORLDBOSS` (includes most raid/dungeon bosses)

Implementation should treat **any rank != `CREATURE_ELITE_NORMAL`** as eligible, with a config option to exclude specific ranks if desired.

### What counts as “gear” (equippable items only)
Use `item_template` (World DB) and define “gear” as **equippable items** only, including weapons and all wearable slots (e.g., armor pieces, rings, trinkets, cloaks, necks).

Recommended base filter:
- `Class` in:
  - `ITEM_CLASS_WEAPON` (2)
  - `ITEM_CLASS_ARMOR` (4) (includes rings/trinkets/etc. in WotLK itemization)
- Must be equippable:
  - `InventoryType != 0` (and/or a whitelist of equip inventory types to be explicit)

Recommended exclusions (configurable):
- Shirts/tabards (often cosmetic)
- Fishing poles and purely-profession “tools” if you don’t want them in the pool
- Items with `RequiredSkill` (engineering goggles, etc.) if you want “universally usable” drops (otherwise rely on `AllowedForPlayer` checks and accept that bots/players without the profession won’t see them)

## Level Bracketing: “Relative to the Zone They Are In”
This is the hardest part to do “perfectly” without a custom zone-level table. The plan supports multiple resolvers with a clear fallback chain.

### Resolver hierarchy (recommended)
1. **Instance context (dungeon/raid)**:
   - Use creature’s effective level as the primary anchor (most reliable).
   - Optionally clamp to an instance-defined bracket if you choose to maintain a map-level table for instances.
2. **Open world**:
   - Use creature’s current area/zone IDs and DBC hints:
     - `AreaTableEntry::area_level` exists (see `src/server/shared/DataStores/DBCStructure.h`), but it’s a single “area level” value and may be `0` for many areas.
   - If DBC area level is missing/unreliable, fall back to:
     - creature’s level (or template min/max level)
3. **Optional: authoritative overrides**:
   - A custom DB table mapping `(mapId, zoneId[, areaId]) -> minLevel, maxLevel` for strict control.

### Bracket shape
Define:
- `targetLevel`: from resolver chain above.
- `minReqLevel = max(1, targetLevel - windowLow)`
- `maxReqLevel = min(maxServerLevel, targetLevel + windowHigh)`

Defaults to consider (tunable):
- World elites: `±2` or `±3` required levels
- Dungeons: `±1` or `±2`
- Raids: `±0` to `±1` (tighter), but allow higher quality

## Item-Level Appropriateness (Beyond RequiredLevel)
Using only `RequiredLevel` is simple but can still produce “weird” power spikes. To satisfy “item level gear close to what it should be”, add an **ItemLevel band** too.

### Two viable strategies

#### Strategy A (Fast to implement): RequiredLevel + configurable ItemLevel window
- Filter by `RequiredLevel` band.
- Also require `ItemLevel` to be within `[ilvlMin, ilvlMax]` where:
  - `expectedIlvl = f(targetLevel)`
  - `ilvlMin = expectedIlvl - ilvlWindowLow`
  - `ilvlMax = expectedIlvl + ilvlWindowHigh`

`f(level)` can start as a simple approximation, then refined.

#### Strategy B (Best accuracy): empirical mapping derived from your DB
At server start (or via a tool command), scan `item_template` and compute a per-required-level distribution:
- For each `RequiredLevel L`, gather gear items and compute percentiles of `ItemLevel`.
- Use median (p50) as `expectedIlvl[L]` and use p20–p80 (or similar) as the band.

This automatically adapts to the server’s item DB (custom items included) and avoids hardcoding formulas.

Recommended default: Strategy B.

## Preventing Unlootable / Nonsense Drops
Even if an item is “gear”, it may be unusable by the current looter(s) (class restrictions, faction flags, profession requirements, etc.). AzerothCore already checks visibility/lootability via `LootItem::AllowedForPlayer(...)` and related logic, but you should still avoid generating items that no one can see.

Recommended handling:
- When generating candidate items, attempt selection up to `N` times (e.g. 20):
  - pick an item ID
  - ensure `ItemTemplate` exists and passes filters
  - ensure `LootItem(LootStoreItem(...)).AllowedForPlayer(lootOwner, loot->sourceWorldObjectGUID)` is true (or for any nearby group member if you want group-aware drops)
- If no valid item found in `N` attempts, skip dynamic drop for that kill.

## Drop Logic (How Many Items, How Often)
Because “any gear from the DB” is extremely broad, this needs explicit balancing controls.

### Proposed default behavior
- For each eligible elite kill, roll:
  - `WorldEliteDropChance` (e.g. 10–25%)
  - `DungeonEliteDropChance` (higher, e.g. 25–50%)
  - `BossDropChance` (higher, e.g. 50–100%, or drop count scaled)
- If success, add `minDrops..maxDrops` items (often 1) selected via the item picker.

### Quality weighting
Do not choose “uniform random across all gear”; it will skew heavily toward common-quality items and undesirable slots. Use a weighted model:
- Weight by `Quality` (e.g. poor excluded; common low; uncommon moderate; rare low; epic very low outside raids).
- Optionally weight by `InventoryType` to avoid over-dropping the most common categories.

Store weights in config and allow per-content-type overrides:
- world vs dungeon vs raid
- bosses vs trash
- rare vs elite vs rare-elite vs worldboss

## Architecture & Implementation Steps

### Phase 1 — Prototype (core mechanics)
1. Create module skeleton `modules/mod-elite-dynamic-gear/`:
   - `src/mod_elite_dynamic_gear_loader.{h,cpp}`
   - `src/mod_elite_dynamic_gear_scripts.cpp`
   - optional: `conf/mod_elite_dynamic_gear.conf.dist`
2. Implement a `GlobalScript` (or appropriate script type) that handles:
   - `OnAfterLootTemplateProcess(Loot* loot, LootTemplate const* tab, LootStore const& store, Player* lootOwner, ...)`
3. Gate logic early:
   - only run if `&store == &LootTemplates_Creature` (creature loot only)
   - resolve the loot source creature:
     - `Creature* source = ObjectAccessor::GetCreature(*lootOwner, loot->sourceWorldObjectGUID)`
   - return unless `source` is valid and `source->GetCreatureTemplate()->rank != CREATURE_ELITE_NORMAL`
4. Resolve `targetLevel` and `minReqLevel/maxReqLevel` using the resolver chain.
5. Pick an item ID and inject:
   - Construct `LootStoreItem(itemId, /*reference*/0, /*chance*/100.0f, /*needs_quest*/false, lootMode, /*group*/0, /*mincount*/1, /*maxcount*/1)`
   - Call `loot->AddItem(...)`

Deliverable: elites reliably gain “extra gear roll” drops that stay within a rough level band.

### Phase 2 — Candidate indexing + performance
Naively querying/scanning `item_template` per kill is too slow. Add caches:

1. During server startup (`OnAfterDatabasesLoaded` via `DatabaseScript` or module init), build an in-memory index:
   - `candidatesByRequiredLevel[L] -> vector<itemId>`
   - optional nested maps for quality/content weighting
2. Apply hard filters during indexing:
   - gear-only
   - exclude obvious junk categories (configurable)
   - exclude `RequiredLevel` outside 1..max
3. At runtime, candidate selection becomes:
   - pick required-level bucket(s) within bracket
   - apply quality weighting
   - sample item ID
   - validate with `AllowedForPlayer` and item-level band

Deliverable: stable performance even with heavy farming.

### Phase 3 — Accurate “expected ilvl” mapping (Strategy B)
1. While building candidate index, also compute distributions:
   - for each `RequiredLevel`, collect item levels of candidates
   - compute median and percentiles (or min/max with trimming)
2. Store `expectedIlvl[L]` and `[ilvlLow[L], ilvlHigh[L]]`.
3. Enforce the ilvl band at runtime.

Deliverable: drops feel “right” for the level, even if required-level data is inconsistent.

### Phase 4 — Zone-level strictness via optional DB override
If you want strict “zone level” rather than “mob level”, add a custom table:

`mod_elite_dynamic_gear_zone_levels`
- `map_id` INT
- `zone_id` INT
- `area_id` INT (0 = any)
- `min_level` TINYINT
- `max_level` TINYINT
- `comment` VARCHAR

Resolver then becomes:
- if override exists for `(map, zone[, area])`, use it
- else fall back to DBC area level / creature level

Deliverable: deterministic bracket control and easy tuning per zone/instance.

### Phase 5 — Admin tools & tuning
Add:
- Config options:
  - enable/disable feature
  - chance and drop counts by content type/rank
  - level windows and ilvl band policy
  - quality weights
  - exclusions (inventory types, qualities, profession-required items)
- GM/console commands (optional):
  - reload candidate cache
  - print resolved bracket for a targeted creature
  - simulate N kills and summarize output distribution
- Debug logging toggles:
  - log chosen item IDs and reason if selection retries fail

## Data / SQL Planning

### Minimal DB changes (recommended)
No mandatory world DB edits if you keep everything in code + `.conf`.

### Optional DB support tables
1. `mod_elite_dynamic_gear_zone_levels` (zone bracket overrides)
2. `mod_elite_dynamic_gear_item_blacklist` (`item_id`, `comment`)
3. `mod_elite_dynamic_gear_item_whitelist` (if you prefer opt-in rather than opt-out)

### Useful analysis SQL (for tuning)
Identify candidate gear counts per required level:
```sql
SELECT RequiredLevel, COUNT(*) AS cnt
FROM item_template
WHERE Class IN (2,4) AND InventoryType <> 0
GROUP BY RequiredLevel
ORDER BY RequiredLevel;
```

Spot outliers (high ilvl for low required level):
```sql
SELECT entry, name, RequiredLevel, ItemLevel, Quality
FROM item_template
WHERE Class IN (2,4) AND InventoryType <> 0
ORDER BY (ItemLevel - RequiredLevel) DESC
LIMIT 50;
```

## Testing & Validation

### Functional testing (manual / GM)
1. Pick representative locations:
   - low-level open world (e.g., Durotar)
   - mid-level dungeon (~30)
   - max-level dungeon/raid
2. Spawn/locate an elite, kill repeatedly, and verify:
   - no drops with `RequiredLevel` far outside bracket
   - ilvl roughly matches expected for bracket
   - quality distribution aligns with config
3. Validate group behavior:
   - items should be visible to at least one eligible player
   - loot rules (master loot / threshold) still work

### Automated / repeatable testing
If you want automated checks:
- Add a small test harness command that simulates the picker logic without requiring real loot windows, and prints histogram summaries by:
  - required level
  - item level
  - quality
  - inventory type
- Run it in CI or as a local developer command after DB updates.

## Edge Cases to Handle Explicitly
- `RequiredLevel = 0` items: decide whether to exclude or only allow when `ItemLevel` is also low.
- Profession-required gear (engineering goggles): either allow (true “any gear”) or exclude (reduce “junk” drops).
- Faction-restricted items: rely on `AllowedForPlayer` checks to avoid invisible items.
- Heirlooms/legendary: usually should be excluded or set to near-zero weight.
- Custom items with unusual required level / ilvl: Strategy B distribution mapping naturally adapts, but still consider blacklisting.

## Rollout Strategy
1. Start with conservative defaults (low drop chance, limited quality) to avoid economy disruption.
2. Enable debug logging for a short period to validate bracket resolution and item selection.
3. Collect feedback, adjust weights/windows, then disable debug logging.
4. Optionally introduce zone override table once you see where DBC/creature-level inference is inaccurate.

## Deliverables Checklist
- `modules/mod-elite-dynamic-gear/` module with loot injection hook.
- Config file with sane defaults and clear comments.
- Optional SQL for zone overrides and blacklists.
- Debug/simulation command (optional but strongly recommended).
- Documentation explaining tuning knobs and how “zone level” is resolved.
