# Project: AzerothCore (WoW Server)

## Environment & Database
- **Platform:** Linux / Docker Devcontainer
- **Database Host:** `ac-database` (Internal Docker Network)
- **Database User:** `root`
- **Database Pass:** `password`
- **World DB:** `acore_world`

## Development Workflows
### Custom SQL
- Custom SQL files must be placed in: `data/sql/custom/db_world/` (for world DB changes).
- These are automatically loaded by the server on startup or via the `acore.sh` dashboard.
- Avoid placing SQL files in `src/sql_scripts/` as they are ignored by the importer.

### Issue Log: Invisible Chests (2025-12-02)
- **Problem:** Custom chests (Entries 500001-500006) were not visible.
- **Cause 1:** SQL files were originally in `src/sql_scripts/`, so they weren't loaded.
- **Cause 2:** `spawn_tiered_chests.sql` contained valid X/Y coordinates but `0.00` Z-coordinates, spawning objects underground.
- **Fix:**
  1. Moved `create_chest_500001.sql` to `data/sql/custom/db_world/`.
  2. Disabled the bad spawn script (`spawn_tiered_chests.sql.disabled`).
  3. Deleted invalid spawns via `DELETE FROM gameobject WHERE id BETWEEN 500001 AND 500006;`.
  4. **Module mod-chest-fix:** Created a custom C++ module (`.fixchests`) that calculates correct ground Z-coordinates for all 1602 chests using server map data and updates the database.
  
### Data Source Notes
- **LootCollector / Ascension:** The chest coordinates come from the Ascension private server (Bronzebeard). Ascension uses custom map edits, which explains why ~1000 out of 1602 coordinates returned `INVALID_HEIGHT` on the standard 3.3.5a map. 605 coordinates were valid and fixed.
