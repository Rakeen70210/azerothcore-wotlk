# Purpose
- The purpose of this project is to allow a solo player to play through WOTLK 3.3.5a using [azerothcore-wotlk](https://github.com/mod-playerbots/azerothcore-wotlk/tree/Playerbot), specifically with the [mod-playerbots](https://github.com/mod-playerbots/mod-playerbots) module to simulate an active and alive world.

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
