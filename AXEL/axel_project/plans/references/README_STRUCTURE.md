# AXEL Project Structure and Naming

Target folder taxonomy for `AXEL/axel_project` and naming rules for new work.
Prefer the **live project tree** when this file and disk disagree — update this doc when structure changes.

## Goals

- Keep runtime-facing files grouped by purpose (assets, scenes, scripts, combat, tools).
- Reduce root-level clutter and make ownership obvious.
- Prefer small, safe moves when reorganizing.

## Current top-level layout (live)

- `assets/` — runtime art (`sprites/`) and game audio (`audio/` — typewriter WAVs plus `music/` `.ogg` stems: live `B_Goes_Down_p2` menu / `B_Goes_Down_p1` overworld; combat casino `casino_Drums_p1`/`p2`, `casino_p1`/`p2`, `casino_like_that`; unused on-disk `B_Goes_Down_Drums_*`, `p3`/`p4`)
- `default_bus_layout.tres` — `Master`, `Music` (~`-12` dB), `Typewriter` (typing loop), `TypewriterOpen` (bar open/close + Panner)
- `scenes/`
  - `Main_Menu/`, `Arc_1/` … `Arc_7/`, `Endings/`
  - `core/` — background/camera/player helpers, placeholders
  - `player/` — shared Front hitbox (`hitbox_front.tres`), shared pose nudge (`pose_nudge.tres` + `mike_pose_nudge.gd`); unused `hitbox_back.tres` / `hitbox_side.tres` were archived 2026-09-17
  - `ui/` — dialogue, interact prompt, locker, pause, world-item card
  - `fx/` — noir/scanline/CRT overlays, memory indicator, glitch/pulse
  - `world/` — floor-item pickup + white pointing-hand marker (`ItemMarker.tscn`)
- `scripts/`
  - `autoload/` — `AxelPostFxStack`, `AxelEventFx`, `AxelMusic`, `AxelSettings`, `AxelPause`, `AxelSaves`, `AxelRun`, `AxelWorld`
  - `debug/` — `AxelCombatDevTools` (editor/debug-only combat menu; open from Settings → DEV TOOLS)
  - `Player.gd` (and related gameplay scripts as they land under `gameplay/` / `ui/` / `debug/`)
- `combat/` — self-contained combat subsystem (`scripts/`, `scenes/`, `art/`, `data/`, `test/`, …)
- `tools/` — QA, bots, capture, visual-style helpers
- `plans/` — design and AI governance docs (`core/`, `scenes/`, `combat/`, `references/`)
- `exports/` — live room/combat drawings plus autoload `GameManager.gd`. First-pass leftovers (HTML prototype, Moon Princess scrape, unused alts) live under `archive/2026-09-17/` with `.gdignore`.
- `archive/` — dated leftover copies; `.gdignore` so Godot does not import them.

## Naming rules

- Folders: `snake_case` by default; keep legacy arc names (`Arc_1`, `Endings`, `Main_Menu`).
- GDScript: `snake_case.gd` for new files; keep PascalCase only when already wired.
- Scenes: narrative numbering (`1.1_Name.tscn`, …) under `Arc_<N>/` (or `Endings/` / `Main_Menu/`).
- Data: `snake_case.json` when adding new tables.

## Migration policy

- Prefer non-breaking, incremental moves.
- When moving runtime assets, update `.gd` / `.tscn` / `.import` references in the same change.
- Record structure migrations in git commits.
