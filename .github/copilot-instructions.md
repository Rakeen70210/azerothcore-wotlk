# GitHub Copilot Instructions for AzerothCore & mod-playerbots

## Project Context
You are working on **AzerothCore** (WotLK server emulator) with the **mod-playerbots** module.
- **Core Language**: C++17 (server), SQL (database), Bash (scripts).
- **Build System**: CMake, wrapped by `./acore.sh`.
- **Module System**: Logic is modularized in `modules/`. You are primarily focused on `modules/mod-playerbots`.

## Architecture

### AzerothCore (Core)
- **`src/server/game/`**: Main game logic.
- **`src/server/scripts/`**: Scripted events, instances, and bosses.
- **`deps/`**: External dependencies (Boost, ACE, etc.).
- **`data/sql/`**: Database schemas and updates.

### mod-playerbots (Module)
- **`PlayerbotAI`**: Main controller for a bot. Handles updates and state.
- **`Engine`**: Decision-making core. Manages `Strategy` execution.
- **`Strategy`**: A collection of `Trigger`s and `Action`s (e.g., "Tank", "Heal", "Grind").
- **`Trigger`**: Checks conditions (e.g., "Low Health").
- **`Action`**: Performs tasks (e.g., "Cast Healing Wave").
- **`AiObjectContext`**: Dependency injection/Factory for AI components.

## Critical Workflows

### Build & Run
- **Prerequisites**: [Linux Requirements](https://www.azerothcore.org/wiki/linux-requirements).
- **Build**: `./acore.sh compiler build` (Builds core + modules).
- **Clean**: `./acore.sh compiler clean`.
- **Run Worldserver**: `./acore.sh run-worldserver`.
- **Run Authserver**: `./acore.sh run-authserver`.

### Code Style (Strictly Enforced)
- **Indentation**: 4 spaces (NO tabs).
- **Const Correctness**: Use **East Const** (`type const*`, `auto const&`).
  - `const Player*` -> `Player const*`
  - `const auto&` -> `auto const&`
- **Control Structures**:
  - Space after `if`: `if (condition)` NOT `if(condition)`.
  - Braces on **new lines** for `if`/`else`.
- **Helpers (Prefer these over raw checks)**:
  - `IsItem()`, `IsCreature()` instead of `GetTypeId() == TYPEID_...`.
  - `GetNpcFlags()`, `HasNpcFlag()` instead of `GetUInt32Value(UNIT_NPC_FLAGS)`.
  - `ObjectGuid::ToString().c_str()` instead of `ObjectGuid::GetCounter()`.

### Bot Development Pattern
To add a new behavior:
1.  **Create Action**: Inherit from `Action`. Implement `Execute()`.
2.  **Create Trigger**: Inherit from `Trigger`. Implement `Check()`.
3.  **Register**: Add to `*ActionContext` and `*TriggerContext` (e.g., `WarriorAiObjectContext` for class-specifics).
4.  **Add to Strategy**: Include the trigger/action pair in a `Strategy` constructor.

## Common Commands & Tools
- **Codestyle Check**: `python apps/codestyle/codestyle-cpp.py`.
- **Create Module**: `./modules/create_module.sh`.
- **DB Updates**: SQL files in `data/sql/updates/`.

## Key Files
- **`modules/mod-playerbots/src/PlayerbotAI.h`**: Bot interface.
- **`modules/mod-playerbots/src/strategy/AiObjectContext.cpp`**: Registry.
- **`modules/mod-playerbots/src/strategy/Action.h`**: Base Action class.
- **`modules/mod-playerbots/src/strategy/Trigger.h`**: Base Trigger class.
