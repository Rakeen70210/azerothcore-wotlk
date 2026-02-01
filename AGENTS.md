# Purpose
- The purpose of this project is to allow a solo player to play through WOTLK 3.3.5a using [azerothcore-wotlk](https://github.com/mod-playerbots/azerothcore-wotlk/tree/Playerbot), specifically with the [mod-playerbots](https://github.com/mod-playerbots/mod-playerbots) module to simulate an active and alive world.

# Local Customizations (Solo Progression)
- Canonical design doc: `doc/EliteDynamicGearDropsPlan.md`
- Implemented module: `modules/mod-elite-dynamic-gear/`
- Goal: all elite mobs (gold + silver rares) can drop *equippable* gear that stays level-appropriate to the zone/content; no out-of-bracket gear (e.g., Durotar elites shouldn’t drop level-40-required items).
- Current policy (open world): **guaranteed** 1 extra **blue+** (rare/epic) equippable item, up to 2, **additive** on top of existing loot tables.
- Module config (loaded via `CONFIG_FILE_LIST`): copy `modules/mod-elite-dynamic-gear/conf/mod_elite_dynamic_gear.conf.dist` to `env/dist/etc/modules/mod_elite_dynamic_gear.conf` and restart `worldserver`.
- Devcontainer build (avoids host deps): `docker compose --profile dev run --rm --no-deps ac-dev-server bash -lc 'cmake -S . -B var/build/dev -DCMAKE_BUILD_TYPE=RelWithDebInfo -DMODULES=static && cmake --build var/build/dev -j"$(nproc)"'`
  - Note: `docker compose --profile dev up ...` may fail if host ports like `3724` are already in use; prefer `docker compose run` for one-off builds.

# Repository Guidelines

## Project Structure & Module OrganizationQ

- `src/`: C++ source code.
  - `src/server/`: auth/world server code and game systems.
  - `src/common/`: shared utilities and platform code.
  - `src/test/`: GoogleTest-based unit tests.
- `modules/`: optional features and gameplay extensions (e.g. `modules/mod-playerbots`).
- `apps/`: developer tooling (installer, compiler wrapper, codestyle, docker helpers).
- `data/sql/` and `src/sql_scripts/`: SQL data and one-off maintenance scripts.
- `conf/dist/`: default configuration templates; prefer local overrides in `conf/` or runtime `env/dist/etc/`.
- `docker-compose.yml`: local Docker stack (use `docker-compose.override.yml` for customizations).

## Build, Test, and Development Commands

- `./acore.sh`: interactive dashboard for common workflows (setup, build, run, docker).
- `./acore.sh compiler build`: configure + build via the repo’s compiler wrapper.
- `cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo`: configure an out-of-tree build.
- `cmake --build build`: compile (authserver/worldserver and tools, depending on options).

## Testing Guidelines

- Unit tests live under `src/test/` and use GoogleTest.
- Enable and run tests:
  - `cmake -S . -B build -DBUILD_TESTING=ON`
  - `ctest --test-dir build` (or run `build/src/test/unit_tests` directly)
