# AXEL Project Structure and Naming

Target folder taxonomy for `AXEL/axel_project` and naming rules for new work.
Prefer the **live project tree** when this file and disk disagree — update this doc when structure changes.

## Goals

- Keep runtime-facing files grouped by purpose (assets, scenes, scripts, combat, tools).
- Reduce root-level clutter and make ownership obvious.
- Prefer small, safe moves when reorganizing.

## Current top-level layout (live)

- `assets/` — runtime art (`sprites/`) and first game audio (`audio/` — typewriter WAVs)
- `scenes/`
  - `Main_Menu/`, `Arc_1/` … `Arc_7/`, `Endings/`
  - `core/` — background/camera/player helpers, placeholders
  - `player/` — shared facing hitboxes (`hitbox_front.tres` / `hitbox_side.tres` / `hitbox_back.tres`)
  - `ui/` — dialogue, interact prompt, shared UI
  - `fx/` — noir/scanline/CRT overlays, memory indicator, glitch/pulse
- `scripts/`
  - `autoload/` — `AxelPostFxStack`, `AxelEventFx`
  - `Player.gd` (and related gameplay scripts as they land under `gameplay/` / `ui/` / `debug/`)
- `combat/` — self-contained combat subsystem (`scripts/`, `scenes/`, `art/`, `data/`, `test/`, …)
- `tools/` — QA, bots, capture, visual-style helpers
- `plans/` — design and AI governance docs (`core/`, `scenes/`, `combat/`, `references/`)
- `exports/` — ignore unless a task explicitly asks (legacy HTML/JSON reference, drawings, Moon Princess captures). Autoload `GameManager.gd` still lives here for historical path reasons.

## Naming rules

- Folders: `snake_case` by default; keep legacy arc names (`Arc_1`, `Endings`, `Main_Menu`).
- GDScript: `snake_case.gd` for new files; keep PascalCase only when already wired.
- Scenes: narrative numbering (`1.1_Name.tscn`, …) under `Arc_<N>/` (or `Endings/` / `Main_Menu/`).
- Data: `snake_case.json` when adding new tables.

## Migration policy

- Prefer non-breaking, incremental moves.
- When moving runtime assets, update `.gd` / `.tscn` / `.import` references in the same change.
- Record structure migrations in git commits.
