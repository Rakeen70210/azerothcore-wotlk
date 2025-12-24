-- Set a starting GUID (Change this if your DB is crowded)
SET @GUID_START := 7000000; 

-- ------------------------------------------------------------------
-- TIER 1 (Lv 10-20)
-- ------------------------------------------------------------------
-- Spawn "Wanted Fugitive" (60001) near existing Humanoids (Bandits, etc.)
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60001, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel BETWEEN 10 AND 20 AND ct.type = 7 AND ct.npcflag = 0 AND c.map IN (0, 1) ORDER BY RAND() LIMIT 30;

SET @GUID_START := @GUID_START + 1000;

-- Spawn "Alpha Worg" (60002) near existing Beasts (Forests, etc.)
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60002, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel BETWEEN 10 AND 20 AND ct.type = 1 AND ct.npcflag = 0 AND c.map IN (0, 1) ORDER BY RAND() LIMIT 30;

SET @GUID_START := @GUID_START + 1000;

-- ------------------------------------------------------------------
-- TIER 2 (Lv 21-30)
-- ------------------------------------------------------------------
-- Humanoids -> Dark Iron Saboteur
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60003, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel BETWEEN 21 AND 30 AND ct.type = 7 AND ct.npcflag = 0 AND c.map IN (0, 1) ORDER BY RAND() LIMIT 30;

SET @GUID_START := @GUID_START + 1000;

-- Beasts/Undead -> Venomous Terror
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60004, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel BETWEEN 21 AND 30 AND ct.type IN (1, 6) AND ct.npcflag = 0 AND c.map IN (0, 1) ORDER BY RAND() LIMIT 30;

SET @GUID_START := @GUID_START + 1000;

-- ------------------------------------------------------------------
-- TIER 3 (Lv 31-40)
-- ------------------------------------------------------------------
-- Humanoids -> Heretic Crusader
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60005, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel BETWEEN 31 AND 40 AND ct.type = 7 AND ct.npcflag = 0 AND c.map IN (0, 1) ORDER BY RAND() LIMIT 30;

SET @GUID_START := @GUID_START + 1000;

-- Beasts -> Primal Stalker
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60006, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel BETWEEN 31 AND 40 AND ct.type = 1 AND ct.npcflag = 0 AND c.map IN (0, 1) ORDER BY RAND() LIMIT 30;

SET @GUID_START := @GUID_START + 1000;

-- ------------------------------------------------------------------
-- TIER 4 (Lv 41-50)
-- ------------------------------------------------------------------
-- Humanoids -> Sandfury Warlord
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60007, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel BETWEEN 41 AND 50 AND ct.type = 7 AND ct.npcflag = 0 AND c.map IN (0, 1) ORDER BY RAND() LIMIT 30;

SET @GUID_START := @GUID_START + 1000;

-- Elementals/Beasts -> Crystalline Giant
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60008, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel BETWEEN 41 AND 50 AND ct.type IN (1, 4) AND ct.npcflag = 0 AND c.map IN (0, 1) ORDER BY RAND() LIMIT 30;

SET @GUID_START := @GUID_START + 1000;

-- ------------------------------------------------------------------
-- TIER 5 (Lv 51-59)
-- ------------------------------------------------------------------
-- Humanoids -> Blackrock Enforcer
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60009, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel BETWEEN 51 AND 59 AND ct.type = 7 AND ct.npcflag = 0 AND c.map IN (0, 1) ORDER BY RAND() LIMIT 30;

SET @GUID_START := @GUID_START + 1000;

-- Undead/Demons -> Plague Monstrosity
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60010, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel BETWEEN 51 AND 59 AND ct.type IN (3, 6) AND ct.npcflag = 0 AND c.map IN (0, 1) ORDER BY RAND() LIMIT 30;

SET @GUID_START := @GUID_START + 1000;

-- ------------------------------------------------------------------
-- TIER 6 (Lv 60+)
-- ------------------------------------------------------------------
-- Humanoids -> Twilight Ascendant
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60011, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel >= 60 AND ct.type = 7 AND ct.npcflag = 0 AND c.map IN (0, 1, 530) ORDER BY RAND() LIMIT 40;

SET @GUID_START := @GUID_START + 1000;

-- Demons/Undead/Beasts -> Void Terror
INSERT INTO `creature` (`id1`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`)
SELECT 60012, c.map, 1, 1, c.position_x + (RAND()*10-5), c.position_y + (RAND()*10-5), c.position_z, RAND() * 6.28, 300, 10, 1
FROM `creature` c JOIN `creature_template` ct ON c.id1 = ct.entry CROSS JOIN (SELECT @rownum := 0) r
WHERE ct.minlevel >= 60 AND ct.type IN (1, 3, 6) AND ct.npcflag = 0 AND c.map IN (0, 1, 530) ORDER BY RAND() LIMIT 40;