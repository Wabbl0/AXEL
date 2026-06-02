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
- `res://scenes/Arc_1/1.1_SchoolExterior.tscn` — player/camera/interact contract, speed/scale profile
- `res://scenes/Arc_1/1.2_Corridor.tscn` — player/overlay contract, corridor_large speed/scale profile

Profile bounds come from `plans/scenes/SCENE_LAYOUT_RULES.md` large-scene table.
