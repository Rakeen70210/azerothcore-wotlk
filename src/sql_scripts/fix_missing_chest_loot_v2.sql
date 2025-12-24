-- Cleanup incorrect loot templates that caused recursion
DELETE FROM `gameobject_loot_template` WHERE `Entry` BETWEEN 30001 AND 30006;

-- Cleanup old/new loot templates to be safe
DELETE FROM `gameobject_loot_template` WHERE `Entry` BETWEEN 40001 AND 40006;

-- Insert new Gameobject Loot Templates (40001-40006) that reference Reference Loot Templates (30001-30006)
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(40001, 1, 30001, 100, 0, 1, 0, 1, 1, 'Tier 1 Chest Reference'),
(40002, 1, 30002, 100, 0, 1, 0, 1, 1, 'Tier 2 Chest Reference'),
(40003, 1, 30003, 100, 0, 1, 0, 1, 1, 'Tier 3 Chest Reference'),
(40004, 1, 30004, 100, 0, 1, 0, 1, 1, 'Tier 4 Chest Reference'),
(40005, 1, 30005, 100, 0, 1, 0, 1, 1, 'Tier 5 Chest Reference'),
(40006, 1, 30006, 100, 0, 1, 0, 1, 1, 'Tier 6 Chest Reference');
