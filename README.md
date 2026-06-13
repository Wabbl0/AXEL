# AXEL (Godot Repository)

[![Combat Tests](https://github.com/Wabbl0/Godot/actions/workflows/combat-tests.yml/badge.svg)](https://github.com/Wabbl0/Godot/actions/workflows/combat-tests.yml)

This repository contains the AXEL Godot project and supporting tools used for development, testing, and QA automation.

## Project At a Glance

- **Engine:** Godot 4.6 (`Forward Plus`)
- **Primary project:** `AXEL/axel_project`
- **Main scene:** `res://scenes/Main_Menu/0.1_MainMenu.tscn`
- **Platform focus:** Windows development workflow (PowerShell + `.cmd` helpers)
- **CI:** GitHub Actions runs the full combat test suite on every push/PR (see `.github/workflows/combat-tests.yml`)

## Repository Layout

- `AXEL/` - game source, scenes, scripts, plans, and test content.
- `tools/` - helper commands (including Godot launch wrappers).
- `logs/` - generated logs and debug outputs.
- `.cursor/` - local AI/editor workflow config.

## Getting Started

### 1) Open the project in Godot

- Open Godot and import: `AXEL/axel_project/project.godot`
- Or launch one of the included editor binaries from repository root:
  - `Godot_v4.6.3-stable_win64.exe`
  - `Godot_v4.6.3-stable_win64_console.exe`

### 2) Run the game

The configured main scene is:

- `res://scenes/Main_Menu/0.1_MainMenu.tscn`

### 3) Useful CLI commands

From repository root:

```bat
:: Combat determinism smoke
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd

:: Combat princess behavior check
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/princess_check.gd

:: Overworld bot playthroughs
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/bots/playthrough_arc1_exterior.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/bots/playthrough_dialogue_loop.gd
```

## CI / Automated Tests

The workflow at `.github/workflows/combat-tests.yml` runs automatically on every push or pull request that touches `combat/`, the QA tools, or the workflow file itself. It can also be triggered manually from the **Actions** tab → **Combat Tests** → **Run workflow**.

**What it runs (in order):**

| Step | Script | Blocks CI? |
|------|--------|-----------|
| Determinism check | `combat/test/determinism_check.gd` | Yes |
| Princess behavior | `combat/test/princess_check.gd` | Yes |
| RTP audit (metrics) | `combat/test/rtp_audit.gd` | No |
| Scaffold check | `combat/test/combat_test_scaffold_check.gd` | Yes |
| Item balance/synergy | `combat/test/item_balance_audit.gd` + `item_synergy_smoke.gd` | Yes (if items exist) |
| Scene smoke check | `tools/scene_smoke_check.gd` | Yes |

**How it works:** The workflow downloads the Godot 4.6.3 Linux binary, installs Mesa lavapipe (software Vulkan so Forward Plus initialises on GPU-less runners), imports the project to rebuild the script-class cache, then runs each test script with `--headless`. The binary is cached between runs to keep job times short.

**Running the same checks locally (Windows):**

```bat
powershell AXEL/axel_project/tools/qa/run_default_playtest.ps1
```

**Note on mobile:** The headless test scripts run on Linux CI only — there is no Godot headless runtime for Android or iOS. The interactive `combat_test.tscn` scene could be exported to Android via Godot's export system, but that requires Android SDK/NDK setup, export presets, and touch-input handling that are not currently configured in this project.

## Documentation Pointers

- Combat notes: `AXEL/axel_project/combat/README.md`
- Bot playthrough docs: `AXEL/axel_project/tools/bots/README.md`
- Structure conventions: `AXEL/axel_project/plans/README_STRUCTURE.md`

## Repository Status

Active development. Systems and content may change as gameplay, narrative, and tooling evolve.

## License

No repository-level license file is currently present. Add a `LICENSE` file before open-source distribution.
