# AXEL combat (Phase 1 — silent grid)

- **Play test scene (default):** open `combat/combat_test.tscn` in the Godot editor and press **F6** (Play Scene). Do not change the project main scene. See [`README_COMBAT_TEST_VERSIONS.md`](README_COMBAT_TEST_VERSIONS.md).
- **Regenerate suit symbol PNGs:** `python combat/art/generate_placeholders.py` from the `axel_project` folder. Writes square/triangle/star/heart, then adds a 1px faint white halo around cigarette, bottle, hand, and skull without redrawing them.
- **Determinism check (CLI):** from `axel_project`, run  
  `godot --path . --headless -s res://combat/test/determinism_check.gd`  
  Expect: `Determinism check OK (100 spins, seed 12345).`
- **Power / vice behavior check (CLI):** from `axel_project`, run  
  `godot --path . --headless -s res://combat/test/powers_check.gd`  
  Expect: `Powers check OK.`
