# Combat `.gd` verification checklist

**Inventory:** scripts under `combat/` (update this table when adding/removing).

| # | Path |
|---|------|
| 1 | `combat/scripts/combat_root.gd` |
| 2 | `combat/scripts/combat_test.gd` |
| 3 | `combat/scripts/encounter.gd` |
| 4 | `combat/scripts/free_spins.gd` |
| 5 | `combat/scripts/goal_def.gd` |
| 6 | `combat/scripts/goal_grid_clear.gd` |
| 7 | `combat/scripts/goal_payout_threshold.gd` |
| 8 | `combat/scripts/goal_tracker.gd` |
| 9 | `combat/scripts/goal_wild_count.gd` |
| 10 | `combat/scripts/grid_manager.gd` |
| 11 | `combat/scripts/item_def.gd` |
| 12 | `combat/scripts/item_inventory.gd` |
| 13 | `combat/scripts/line_detector.gd` |
| 14 | `combat/scripts/meter.gd` |
| 15 | `combat/scripts/multiplier.gd` |
| 16 | `combat/scripts/premium_skull_meter.gd` |
| 17 | `combat/scripts/princess_controller.gd` |
| 18 | `combat/scripts/rng.gd` |
| 19 | `combat/scripts/symbol_def.gd` |
| 20 | `combat/scripts/symbol_slot.gd` |
| 21 | `combat/test/determinism_check.gd` |
| 22 | `combat/test/princess_check.gd` |

**Note:** `cluster_detector.gd` was removed (contradicted line-wins canon; unused). A future “N+ symbols anywhere” item can rebuild that idea from scratch.

**Headless checks (from repo root, with Godot on PATH):**

```bat
tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/princess_check.gd
tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd
```

**Full playtest bundle:** from repo root, `powershell AXEL/axel_project/tools/qa/run_default_playtest.ps1` (combat checks, scene smoke, canon audit, bots). Or run individually:

```bat
tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/rtp_audit.gd
tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://tools/scene_smoke_check.gd
```

(`rtp_audit` prints metrics; exit code is always 0 unless the script errors. `scene_smoke_check` exits non-zero on load/instantiate failure.)

**Troubleshooting headless / `class_name` resolution:** If Godot reports missing types like `EncounterDef` or `GoalDef`, ensure [`.godot/global_script_class_cache.cfg`](../.godot/global_script_class_cache.cfg) includes all combat `class_name` entries, or open the project once in the editor to regenerate the cache.

**Test scripts:** In Godot 4, `await node.ready` after the node is already ready never resumes; tests use `is_node_ready()` guards (see `princess_check.gd` / `determinism_check.gd`).
