# AXEL (Godot Repository)

This repository contains the AXEL Godot project and supporting tools used for development, testing, and QA automation.

## Project At a Glance

- **Engine:** Godot 4.6 (`Forward Plus`)
- **Primary project:** `AXEL/axel_project`
- **Main scene:** `res://scenes/Main_Menu/0.1_MainMenu.tscn`
- **Platform focus:** Windows development workflow (PowerShell + `.cmd` helpers)

## Repository Layout

- `AXEL/` - game source, scenes, scripts, plans, and test content.
- `tools/` - helper commands (including Godot launch wrappers).
- `logs/` - generated logs and debug outputs.
- `.cursor/` - local AI/editor workflow config.

## Getting Started

### 1) Open the project in Godot

- Open Godot and import: `AXEL/axel_project/project.godot`
- Or launch one of the included editor binaries from repository root:
  - `Godot_v4.6.2-stable_win64.exe`
  - `Godot_v4.6.2-stable_win64_console.exe`

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

## Documentation Pointers

- Combat notes: `AXEL/axel_project/combat/README.md`
- Bot playthrough docs: `AXEL/axel_project/tools/bots/README.md`
- Structure conventions: `AXEL/axel_project/plans/README_STRUCTURE.md`

## Repository Status

Active development. Systems and content may change as gameplay, narrative, and tooling evolve.

## License

No repository-level license file is currently present. Add a `LICENSE` file before open-source distribution.
