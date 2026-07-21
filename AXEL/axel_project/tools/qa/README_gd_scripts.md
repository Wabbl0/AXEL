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
- `res://scenes/Arc_1/1.2_Corridor.tscn` — player/overlay contract, corridor_large speed/scale profile (`362` / scale `3.0`), `WalkableWorld/EnvironmentColliders/*` paths, `ExplorationViewport` (`1920×1200` design window)
- **New exploration scenes** using `background_camera_controller.gd` — `collect_background_camera_findings` (camera view must stay inside computed art rect; no-op on legacy 1.1/1.2)

Profile bounds come from `plans/scenes/SCENE_BUILDING.md` large-scene player profiles. Background/camera pipeline: same file.

## Corridor collision probe (1.2 regression)

```bat
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/corridor_collision_probe.gd
```

Scripted walk into `LeftWall` / `RightWall` after cover-fit layout; exits 0 on block, 1 on pass-through. **Note:** runtime 1.2 uses `ExplorationViewport` (`1920×1200`); this headless probe still forces `root.size = 1400×900` before load — update probe window if layout regression checks must match runtime design viewport.
