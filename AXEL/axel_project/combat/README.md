# AXEL combat (Phase 1 — silent grid)

- **Play test scene (default):** open `combat/combat_test.tscn` in the Godot editor and press **F6** (Play Scene). Do not change the project main scene. See [`README_COMBAT_TEST_VERSIONS.md`](README_COMBAT_TEST_VERSIONS.md).
- **Regenerate symbol PNGs:** `python combat/art/generate_placeholders.py` from the `axel_project` folder (writes to `combat/art/grid_symbols/`).
- **Determinism check (CLI):** from `axel_project`, run  
  `godot --path . --headless -s res://combat/test/determinism_check.gd`  
  Expect: `Determinism check OK (100 spins, seed 12345).`
- **Princess behavior check (CLI):** from `axel_project`, run  
  `godot --path . --headless -s res://combat/test/princess_check.gd`  
  Expect: `Princess check OK.`
