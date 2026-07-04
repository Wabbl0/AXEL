# AGENTS.md

## Cursor Cloud specific instructions

AXEL is a single-product **Godot 4.6.3** game (GDScript). The engine binary is the
only real dependency; the Godot project lives in `AXEL/axel_project`. There is no
package manager, database, or backend service.

### Environment (provided by the startup update script)

- `godot` (Godot 4.6.3-stable, Linux headless-capable build) is on `PATH` at
  `/usr/local/bin/godot`.
- `xvfb`, `ffmpeg`, and Mesa software renderers (`mesa-vulkan-drivers` /
  llvmpipe/lavapipe, `libgl1-mesa-dri`) are installed for GPU-less rendering.
- The update script pre-runs `godot --headless --path AXEL/axel_project --import`
  to warm the `.godot/` cache. **This warm-import is required**: without it,
  `class_name` types (e.g. `CombatRoot`, `EncounterDef`) are unresolved and every
  headless script fails immediately with a parse error. If you pull new assets or
  hit "Could not find type" errors, re-run the import command.

### Running the headless test suite (all exit 0 on success)

Run from the repo root:

- Combat determinism: `godot --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd`
- Princess behavior: `godot --headless --path AXEL/axel_project -s res://combat/test/princess_check.gd`
- Combat scaffold: `godot --headless --path AXEL/axel_project -s res://combat/test/combat_test_scaffold_check.gd`
- Scene smoke (loads 6 scenes): `godot --headless --path AXEL/axel_project -s res://tools/scene_smoke_check.gd`
- RTP audit (metrics only, always exits 0): `godot --headless --path AXEL/axel_project -s res://combat/test/rtp_audit.gd`

These mirror the CI gate in `.github/workflows/combat-tests.yml` (on branch
`cursor/github-actions-combat-ci-3288`). Harmless `RID/ObjectDB ... leaked at exit`
warnings are printed after the `... OK` line — check the exit code and the `OK`
message, not those warnings.

### Overworld playthrough bots (`AXEL/axel_project/tools/bots/`)

- `playthrough_arc1_exterior.gd` passes headlessly (walk + interact + scene transition).
- `playthrough_dialogue_loop.gd` **fails under pure `--headless`**: it waits for the
  `TopDialogueOverlay` fade-in to become visible, which does not settle with the
  dummy renderer. It is NOT part of CI. To exercise dialogue-visibility flows, run
  under a display (Xvfb) with software rendering instead of `--headless`.

### Running the game with a picture (Xvfb + software rendering)

There is no physical GPU. To run/render the game, use a virtual display and Mesa
software drivers. A VNC desktop is also available on `DISPLAY=:1`.

- Interactive run: `DISPLAY=:1 godot --path AXEL/axel_project`
  (audio falls back to a dummy driver — the ALSA "cannot find card" errors are expected).
- **Scene -> PNG capture:** `tools/capture_scene.sh <res://scene.tscn> <output.png> [frames] [WIDTHxHEIGHT]`
  wraps Xvfb + software rendering and delegates to `res://tools/capture_scene.gd`.
  Example: `tools/capture_scene.sh res://scenes/Main_Menu/0.1_MainMenu.tscn out/menu.png 40 1280x720`.

### Mobile portrait / touch controls

The project targets iPhone portrait (base canvas 720x1560, `canvas_items` +
`expand` stretch). Touch UI (fixed bottom-center virtual joystick from the
`TouchControls` autoload, `[TAP]` interact chips) activates on real mobile /
web-mobile targets, or anywhere when the env var `AXEL_FORCE_TOUCH=1` is set.

- Portrait desktop test run: `DISPLAY=:1 AXEL_FORCE_TOUCH=1 godot --path AXEL/axel_project`
  (window opens 396x858; mouse clicks/drags emulate touch).
- Touch playthrough bot (headless, exit 0 on success):
  `godot --headless --path AXEL/axel_project -s res://tools/bots/playthrough_touch_joystick.gd`
  (joystick visibility, drag-to-walk, steer to door, tap-to-interact transition).
- Portrait captures: pass a portrait resolution to the capture script, e.g.
  `AXEL_FORCE_TOUCH=1 tools/capture_scene.sh res://scenes/Arc_1/1.2_Corridor.tscn out.png 90 390x844`.
- Web (iPhone Safari) build: `godot --headless --path AXEL/axel_project --export-release Web ../web_export/index.html`
  (requires web export templates in `~/.local/share/godot/export_templates/4.6.3.stable/`;
  the preset is a `nothreads` build so it runs without cross-origin-isolation headers).
  Serve `AXEL/web_export/` statically and open it in Safari/Chrome; a mobile
  user agent (or any touch-capable browser) enables the touch UI.

### Notes

- `tools/cmd/godot.cmd` is a Windows-only launcher; on Linux call `godot` directly.
- The configured main scene is `res://scenes/Main_Menu/0.1_MainMenu.tscn`.
