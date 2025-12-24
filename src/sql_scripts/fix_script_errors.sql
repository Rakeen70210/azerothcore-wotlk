-- Fix "Script named '...' is not assigned in the database" errors
UPDATE `creature_template` SET `ScriptName` = 'npc_tallhorn_stag' WHERE `entry` = 26363;
UPDATE `creature_template` SET `ScriptName` = 'npc_amberpine_woodsman' WHERE `entry` = 27293;
UPDATE `creature_template` SET `ScriptName` = 'npc_vics_flying_machine' WHERE `entry` = 28710;

-- Fix "Script named '...' is assigned in the database, but has no code!" errors
-- Remove script from Warpweaver NPCs since mod-transmog is not installed
UPDATE `creature_template` SET `ScriptName` = '' WHERE `entry` IN (190010, 190011);

-- Remove missing spell script
DELETE FROM `spell_script_names` WHERE `spell_id` = 50380 AND `ScriptName` = 'spell_bloodspore_haze';
