-- ------------------------------------------------------------------
-- STEP 1: CLEANUP
-- Remove previous custom entries to ensure a clean slate
-- ------------------------------------------------------------------
DELETE FROM `reference_loot_template` WHERE `Entry` BETWEEN 30001 AND 30006;
DELETE FROM `creature_loot_template` WHERE `Reference` BETWEEN 30001 AND 30006;

-- ------------------------------------------------------------------
-- STEP 2: CREATE TIERED LOOT LISTS
-- Filter: Rare (3) or Epic (4), Bind on Pickup (Bonding 1), Weapons/Armor
-- NO ID FILTER: Allows TBC items that match these item levels to drop.
-- ------------------------------------------------------------------

-- TIER 1: Low Level Dungeons (Deadmines, WC, SFK)
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 30001, entry, 0, 0, 0, 1, 1, 1, 1, CONCAT('Tier 1 Custom - ', name)
FROM `item_template`
WHERE `ItemLevel` BETWEEN 15 AND 25 
AND `Quality` IN (3,4) AND `Bonding` = 1 AND `Class` IN (2,4);

-- TIER 2: Mid-Low Dungeons (BFD, Gnomer, RFK)
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 30002, entry, 0, 0, 0, 1, 1, 1, 1, CONCAT('Tier 2 Custom - ', name)
FROM `item_template`
WHERE `ItemLevel` BETWEEN 26 AND 35 
AND `Quality` IN (3,4) AND `Bonding` = 1 AND `Class` IN (2,4);

-- TIER 3: Mid Dungeons (Scarlet Monastery, RFD)
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 30003, entry, 0, 0, 0, 1, 1, 1, 1, CONCAT('Tier 3 Custom - ', name)
FROM `item_template`
WHERE `ItemLevel` BETWEEN 36 AND 45 
AND `Quality` IN (3,4) AND `Bonding` = 1 AND `Class` IN (2,4);

-- TIER 4: Mid-High Dungeons (Uldaman, ZF, Maraudon)
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 30004, entry, 0, 0, 0, 1, 1, 1, 1, CONCAT('Tier 4 Custom - ', name)
FROM `item_template`
WHERE `ItemLevel` BETWEEN 46 AND 55 
AND `Quality` IN (3,4) AND `Bonding` = 1 AND `Class` IN (2,4);

-- TIER 5: High Dungeons (Sunken Temple, BRD, LBRS)
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 30005, entry, 0, 0, 0, 1, 1, 1, 1, CONCAT('Tier 5 Custom - ', name)
FROM `item_template`
WHERE `ItemLevel` BETWEEN 56 AND 65 
AND `Quality` IN (3,4) AND `Bonding` = 1 AND `Class` IN (2,4);

-- TIER 6: Raids / End Game (UBRS, MC, BWL, Naxx / Early TBC Dungeons)
-- Extended cap to 100 to ensure all Naxx gear is caught
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 30006, entry, 0, 0, 0, 1, 1, 1, 1, CONCAT('Tier 6 Custom - ', name)
FROM `item_template`
WHERE `ItemLevel` BETWEEN 66 AND 100 
AND `Quality` IN (3,4) AND `Bonding` = 1 AND `Class` IN (2,4);

-- ------------------------------------------------------------------
-- STEP 3: ASSIGN TIERS TO MOBS BASED ON LEVEL
-- Map Tier lists (30001-30006) to Mobs of appropriate levels
-- ------------------------------------------------------------------

-- Map Tier 1 (Items 15-25) to Mobs Level 10-20
INSERT IGNORE INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT lootid, 200001, 30001, 100, 0, 1, 0, 1, 2, 'Custom Tier 1 Drop'
FROM `creature_template` WHERE `minlevel` BETWEEN 10 AND 20 AND `rank` >= 1 AND `lootid` != 0;

-- Map Tier 2 (Items 26-35) to Mobs Level 21-30
INSERT IGNORE INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT lootid, 200002, 30002, 100, 0, 1, 0, 1, 2, 'Custom Tier 2 Drop'
FROM `creature_template` WHERE `minlevel` BETWEEN 21 AND 30 AND `rank` >= 1 AND `lootid` != 0;

-- Map Tier 3 (Items 36-45) to Mobs Level 31-40
INSERT IGNORE INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT lootid, 200003, 30003, 100, 0, 1, 0, 1, 2, 'Custom Tier 3 Drop'
FROM `creature_template` WHERE `minlevel` BETWEEN 31 AND 40 AND `rank` >= 1 AND `lootid` != 0;

-- Map Tier 4 (Items 46-55) to Mobs Level 41-50
INSERT IGNORE INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT lootid, 200004, 30004, 100, 0, 1, 0, 1, 2, 'Custom Tier 4 Drop'
FROM `creature_template` WHERE `minlevel` BETWEEN 41 AND 50 AND `rank` >= 1 AND `lootid` != 0;

-- Map Tier 5 (Items 56-65) to Mobs Level 51-59
INSERT IGNORE INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT lootid, 200005, 30005, 100, 0, 1, 0, 1, 2, 'Custom Tier 5 Drop'
FROM `creature_template` WHERE `minlevel` BETWEEN 51 AND 59 AND `rank` >= 1 AND `lootid` != 0;

-- Map Tier 6 (Items 66-100) to Mobs Level 60+
INSERT IGNORE INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT lootid, 200006, 30006, 100 , 0, 1, 0, 1, 2, 'Custom Tier 6 Drop'
FROM `creature_template` WHERE `minlevel` >= 60 AND `rank` >= 1 AND `lootid` != 0;