# Combat `.gd` verification checklist

**Inventory:** 20 scripts under `combat/` (not 21 — document any future additions here).

| # | Path |
|---|------|
| 1 | `combat/scripts/cluster_detector.gd` |
| 2 | `combat/scripts/combat_root.gd` |
| 3 | `combat/scripts/combat_test.gd` |
| 4 | `combat/scripts/encounter.gd` |
| 5 | `combat/scripts/free_spins.gd` |
| 6 | `combat/scripts/goal_def.gd` |
| 7 | `combat/scripts/goal_grid_clear.gd` |
| 8 | `combat/scripts/goal_payout_threshold.gd` |
| 9 | `combat/scripts/goal_tracker.gd` |
| 10 | `combat/scripts/goal_wild_count.gd` |
| 11 | `combat/scripts/grid_manager.gd` |
| 12 | `combat/scripts/line_detector.gd` |
| 13 | `combat/scripts/meter.gd` |
| 14 | `combat/scripts/multiplier.gd` |
| 15 | `combat/scripts/princess_controller.gd` |
| 16 | `combat/scripts/rng.gd` |
| 17 | `combat/scripts/symbol_def.gd` |
| 18 | `combat/scripts/symbol_slot.gd` |
| 19 | `combat/test/determinism_check.gd` |
| 20 | `combat/test/princess_check.gd` |

**Headless checks (from repo root, with Godot on PATH):**

```bat
tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/princess_check.gd
tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd
```

**`qa agent` playtest bundle (combat + canonical scene smoke + RTP metrics):** same two lines above, then:

```bat
tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/rtp_audit.gd
tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://test/scene_smoke_check.gd
tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/combat_test_scaffold_check.gd
```

(`rtp_audit` prints metrics; exit code is always 0 unless the script errors. `scene_smoke_check` exits non-zero on load/instantiate failure and validates `combat_test` scaffold nodes. `combat_test_scaffold_check` is a dedicated gate for stripped-scene regressions.)

**Pre-commit (optional, repo hook):** `python AXEL/axel_project/tools/qa/check_combat_test_scaffold.py --staged` blocks commits that remove required `combat_test.tscn` nodes.

**Troubleshooting headless / `class_name` resolution:** If Godot reports missing types like `EncounterDef` or `GoalDef`, ensure [`.godot/global_script_class_cache.cfg`](../.godot/global_script_class_cache.cfg) includes all combat `class_name` entries, or open the project once in the editor to regenerate the cache.

**Test scripts:** In Godot 4, `await node.ready` after the node is already ready never resumes; tests use `is_node_ready()` guards (see `princess_check.gd` / `determinism_check.gd`).
