-- ------------------------------------------------------------------
-- STEP 1: CLEANUP
-- ------------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry` BETWEEN 60001 AND 60012;
DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 60001 AND 60012;
DELETE FROM `creature_loot_template` WHERE `Entry` BETWEEN 60001 AND 60012;

-- ------------------------------------------------------------------
-- STEP 2: CREATE THEMATIC ELITES
-- We use standard models that look "Elite" but fit the zones.
-- ------------------------------------------------------------------

-- TIER 1 (Level 15)
-- Humanoid: Looks like a Defias Bandit (Display 2357)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60001, 'Wanted Fugitive', 'Tier 1 Elite', 15, 15, 14, 1.1, 1, 1, 7, 60001, 2.5, 2.0);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60001, 0, 2357, 1.0, 1.0);
-- Beast: Looks like a Black Worg (Display 646)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60002, 'Alpha Worg', 'Tier 1 Elite', 15, 15, 14, 1.2, 1, 1, 1, 60002, 2.5, 2.0);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60002, 0, 646, 1.0, 1.0);

-- TIER 2 (Level 25)
-- Humanoid: Looks like a Dark Iron Dwarf or Evil Gnome (Display 10280)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60003, 'Dark Iron Saboteur', 'Tier 2 Elite', 25, 25, 14, 1.1, 1, 1, 7, 60003, 3.0, 2.5);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60003, 0, 10280, 1.0, 1.0);
-- Beast: Looks like a Giant Spider (Display 424)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60004, 'Venomous Terror', 'Tier 2 Elite', 25, 25, 14, 1.3, 1, 1, 1, 60004, 3.0, 2.5);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60004, 0, 424, 1.0, 1.0);

-- TIER 3 (Level 35)
-- Humanoid: Looks like a Scarlet Crusader (Display 1556)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60005, 'Heretic Crusader', 'Tier 3 Elite', 35, 35, 14, 1.2, 1, 1, 7, 60005, 3.5, 3.0);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60005, 0, 1556, 1.0, 1.0);
-- Beast: Looks like a Jungle Tiger (Display 660)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60006, 'Primal Stalker', 'Tier 3 Elite', 35, 35, 14, 1.3, 1, 1, 1, 60006, 3.5, 3.0);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60006, 0, 660, 1.0, 1.0);

-- TIER 4 (Level 45)
-- Humanoid: Looks like a Sandfury Troll (Display 6423)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60007, 'Sandfury Warlord', 'Tier 4 Elite', 45, 45, 14, 1.2, 1, 1, 7, 60007, 4.0, 3.5);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60007, 0, 6423, 1.0, 1.0);
-- Monster: Looks like an Earth Elemental (Display 2371)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60008, 'Crystalline Giant', 'Tier 4 Elite', 45, 45, 14, 1.0, 1, 1, 4, 60008, 4.0, 3.5);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60008, 0, 2371, 1.0, 1.0);

-- TIER 5 (Level 55)
-- Humanoid: Looks like a Blackrock Orc (Display 10537)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60009, 'Blackrock Enforcer', 'Tier 5 Elite', 55, 55, 14, 1.2, 1, 1, 7, 60009, 5.0, 4.0);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60009, 0, 10537, 1.0, 1.0);
-- Undead: Looks like a Ghoul (Display 11249)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60010, 'Plague Monstrosity', 'Tier 5 Elite', 55, 55, 14, 1.3, 1, 1, 6, 60010, 5.0, 4.0);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60010, 0, 11249, 1.0, 1.0);

-- TIER 6 (Level 65)
-- Humanoid: Looks like a Twilight Cultist (Display 2882)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60011, 'Twilight Ascendant', 'Tier 6 Elite', 65, 65, 14, 1.2, 1, 1, 7, 60011, 10.0, 5.0);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60011, 0, 2882, 1.0, 1.0);
-- Demon: Looks like a Felguard (Display 18615)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `scale`, `rank`, `unit_class`, `type`, `lootid`, `HealthModifier`, `DamageModifier`) VALUES (60012, 'Void Terror', 'Tier 6 Elite', 65, 65, 14, 1.3, 1, 1, 3, 60012, 10.0, 5.0);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (60012, 0, 18615, 1.0, 1.0);

-- ------------------------------------------------------------------
-- STEP 3: LINK LOOT (Using Refs 30001-30006 from previous script)
-- ------------------------------------------------------------------
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `GroupId`) VALUES
(60001, 200001, 30001, 100, 0), (60002, 200001, 30001, 100, 0), -- Tier 1
(60003, 200002, 30002, 100, 0), (60004, 200002, 30002, 100, 0), -- Tier 2
(60005, 200003, 30003, 100, 0), (60006, 200003, 30003, 100, 0), -- Tier 3
(60007, 200004, 30004, 100, 0), (60008, 200004, 30004, 100, 0), -- Tier 4
(60009, 200005, 30005, 100, 0), (60010, 200005, 30005, 100, 0), -- Tier 5
(60011, 200006, 30006, 100, 0), (60012, 200006, 30006, 100, 0); -- Tier 6