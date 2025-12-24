DELETE FROM `gameobject_loot_template` WHERE `Entry` BETWEEN 30001 AND 30006;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(30001, 1, 30001, 100, 0, 1, 0, 1, 1, 'Tier 1 Chest Reference'),
(30002, 1, 30002, 100, 0, 1, 0, 1, 1, 'Tier 2 Chest Reference'),
(30003, 1, 30003, 100, 0, 1, 0, 1, 1, 'Tier 3 Chest Reference'),
(30004, 1, 30004, 100, 0, 1, 0, 1, 1, 'Tier 4 Chest Reference'),
(30005, 1, 30005, 100, 0, 1, 0, 1, 1, 'Tier 5 Chest Reference'),
(30006, 1, 30006, 100, 0, 1, 0, 1, 1, 'Tier 6 Chest Reference');
