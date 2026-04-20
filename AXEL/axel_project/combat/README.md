# AXEL combat (Phase 1 — silent grid)

- **Play test scene:** open `combat/combat_test.tscn` in the Godot editor and press **F6** (Play Scene). Do not change the project main scene.
- **Regenerate placeholder PNGs:** `python combat/art/generate_placeholders.py` from the `axel_project` folder.
- **Determinism check (CLI):** from `axel_project`, run  
  `godot --path . --headless -s res://combat/test/determinism_check.gd`  
  Expect: `Determinism check OK (100 spins, seed 12345).`
