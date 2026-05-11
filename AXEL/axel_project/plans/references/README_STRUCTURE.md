# AXEL Project Structure and Naming

This document defines the target folder taxonomy for `AXEL/axel_project` and the naming rules used for future work.

## Goals

- Keep runtime-facing files grouped by purpose (assets, scenes, scripts, combat, tools).
- Reduce root-level clutter and make ownership obvious.
- Preserve backward compatibility while migrating in small, safe steps.

## Canonical Top-Level Layout

Use this structure for all new content:

- `assets/`
  - `sprites/` (character and object sprite sheets)
  - `textures/` (backgrounds, UI textures, static images)
  - `audio/` (music, ambience, SFX)
  - `ui/` (UI-specific visual assets)
  - `fonts/`
  - `vfx/` (FX textures/shaders that are asset-centric)
  - `data/` (runtime JSON/config tables, non-export source data)
- `scenes/`
  - `Main_Menu/`
  - `Arc_1/` ... `Arc_7/`
  - `Endings/`
  - `ui/` (shared scene widgets/panels)
  - `core/` (bootstrap/loading/meta scenes)
- `scripts/`
  - `core/` (autoloads, save/profile/session utilities)
  - `gameplay/` (player movement, interaction, exploration systems)
  - `ui/` (HUD/menu/panel controllers)
- `combat/` (self-contained combat subsystem)
  - `scripts/`, `scenes/`, `art/`, `test/`
- `tools/` (local utility scripts and build helpers)
- `plans/` (design and AI governance docs)
- `exports/` (reference exports and migration assets)

## Naming Rules

- Folders:
  - Use `snake_case` by default.
  - Preserve legacy arc folder names (`Arc_1`, `Endings`, `Main_Menu`) unless doing a dedicated migration.
- GDScript files:
  - Use `snake_case.gd` for general scripts.
  - Keep legacy PascalCase file names only when tied to existing scene/script references.
- Scenes:
  - Keep existing narrative numbering convention (`1.1_...`, `8.1_...`) for story flow readability.
- Data files:
  - Use `snake_case.json`.
- Utility scripts:
  - Use `snake_case.py` or `snake_case.cmd`.

## Migration Policy

- Prefer non-breaking, incremental moves.
- If moving runtime assets, update all references in `.gd`, `.tscn`, and `.import` files in the same change.
- Record all implemented structure migrations in `plans/core/AI_CHANGELOG.md`.

## Current Migration State (Implemented)

- Commands centralized at repository `tools/cmd/`.
- Debug logs centralized at repository `logs/debug/`.
- Character sprites moved from `sprites/` to `assets/sprites/`.
- Runtime data root moved from `data/` to `assets/data/` (non-breaking because root data was placeholder-only).

## Next Safe Migrations

- Move exploration image pipeline from `pictures/` into `assets/textures/story/` with compatibility shim updates.
- Introduce `scripts/gameplay/` and move player/exploration scripts there after scene reference updates.
- Introduce `scenes/ui/` for reusable shared UI scenes.
