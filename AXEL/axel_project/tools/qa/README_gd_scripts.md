# AXEL QA Canon Consistency Checks

Headless audits for visual/gameplay drift vs canon. Run manually or via `run_default_playtest.ps1`.

Stdout prints `CANON_AUDIT_JSON` (always exits 0 — warn + recommend; parse JSON for findings).

## Commands

```bat
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/canon_consistency_audit.gd
```

- Always exits **0** (warn + recommend).
- Prints `CANON_AUDIT_JSON` on stdout for QA report ingestion.

## Shared validators

`qa_canon_validators.gd` (`QaCanonValidators`) is also used by:

- `res://combat/test/combat_test_scaffold_check.gd` (hard gate on scaffold + duplicate grid)
- `res://tools/scene_smoke_check.gd` (combat_test scaffold subset)

Pre-commit (`tools/qa/check_combat_test_scaffold.py --staged`): if staged `combat_test.tscn` has inline `Grid*` nodes under `CombatRoot` while instancing `combat_root.tscn`, the hook auto-removes those node blocks, restages the file, and re-runs validation (blocks only if still invalid).

## Audited scenes

- `res://combat/combat_test.tscn` — scaffold nodes, duplicate CombatRoot grid stack, grid cell count
- `res://scenes/Arc_1/1.1_SchoolExterior.tscn` — player/camera/interact contract, speed/scale profile, `ExplorationViewport` (`1400×1400` design window; leaf behind-zone fade: manual F5 only — see shipped `1.1_SchoolExterior.gd`)
- `res://scenes/Arc_1/1.2_Corridor.tscn` — player/overlay contract, corridor_large speed/scale profile (`185.3` / scale `0.198` for the 12-cell tall Mike sheet), `WalkableWorld/EnvironmentColliders/*` paths, `ExplorationViewport` (`1920×1200` design window)
- **New exploration scenes** using `background_camera_controller.gd` — `collect_background_camera_findings` (camera view must stay inside computed art rect; no-op on legacy 1.1/1.2)

Profile bounds come from `plans/scenes/SCENE_BUILDING.md` large-scene player profiles. Background/camera pipeline: same file.

## Room-edge wall sprite clearance

```bat
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/wall_sprite_clearance_check.gd
```

Measures how far Mike’s walk drawing + `ShadowOutline` stick past the Front circle, then checks `LeftWall` / `RightWall` / `TopWall` / `BottomWall` inset vs that amount × live Player scale. Skips 2.4, 1.1 `LeftWall`, and walk-off walls. Exits 0 on `WALL_SPRITE_CLEARANCE OK`.

## Independent CollisionShape2D (no shared Shape2D)

```bat
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/collision_shape_unique_check.gd
```

Scans `res://scenes/**/*.tscn`. Two `CollisionShape2D` nodes must not share a `SubResource` (or any `.tres` except Mike’s `hitbox_front.tres`). Exits 0 on `COLLISION_SHAPE_UNIQUE OK`.

## Shader built-in scope (helpers must not read SCREEN_UV / etc.)

```bat
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/shader_builtin_scope_check.gd
```

Scans `.gdshader` / `.gdshaderinc` under `scenes/`, `tools/`, `combat/`, `scripts/`. Custom helper functions must not read fragment/vertex built-ins (`SCREEN_UV`, `SCREEN_PIXEL_SIZE`, `FRAGCOORD`, `UV`, `COLOR`, …) — pass those in from `fragment()` / `vertex()` / `light()` / `start()` / `process()`. Exits 0 on `SHADER_BUILTIN_SCOPE OK`. Does not compile shaders; after CRT edits also run a short windowed `--quit-after` and check the console for `SHADER ERROR`.

## Combat HUD piece placement (drawing-backed HUD regression)

```bat
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/hud_piece_placement_check.gd
```

Loads `combat/combat_test.tscn` inside a `1920×1280` `SubViewport` and asserts, in plate space:

- `HudArtGuide` and `HudPieces` sit at `0,0` sized `3508×2480` (1:1 with `axel_ui.png`).
- Each `NEW_*` piece matches its measured rect from the mockup, and renders at its texture's native size (no stretch blur).
- No `NEW_*` / `MOVE_*` node leaves the plate or collapses to zero size.
- `%CombatRoot`'s `GridUI` fills at least 98% of `GridHost`.

Exits 0 on `HUD piece placement check OK`. This is the gate against the guide drifting and dragging the whole HUD with it. Companion diagnostics: `hud_layout_probe.gd` (prints rects) and `hud_capture.gd` (renders a PNG — run **without** `--headless`).

## Corridor collision probe (1.2 regression)

```bat
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/corridor_collision_probe.gd
```

Scripted walk into `LeftWall` / `RightWall` after cover-fit layout; exits 0 on block, 1 on pass-through. **Note:** runtime 1.2 uses `ExplorationViewport` (`1920×1200`); this headless probe still forces `root.size = 1400×900` before load — update probe window if layout regression checks must match runtime design viewport.
