# AXEL Scene Layout Rules

## Goal

Keep scenes visibly abandoned, looted, broken, and rotting while preserving readable movement flow for the player.

## Core Composition

- Build from a recognizable institutional base (classroom rows, corridor wall props, library shelf blocks).
- Disrupt structure with decay clusters (fallen props, tilt offsets, missing symmetry).
- Keep focal narrative props (locker, desk, board, graffiti) readable near primary camera attention.

## Pathing Policy (Balanced)

- Maintain one clear primary route from entry region to exit/interaction region.
- Allow occasional narrow chokepoints to increase tension.
- Never block the route with hard obstacles.
- Place heavier debris on side lanes and corners first.

## Decay and Chaos

- Use clustered clutter, not uniform scatter.
- Prefer edge and wall accumulation for debris/trash.
- Keep center-lane clutter sparse unless the scene explicitly calls for pressure.

## Placement Roles

- `wall_prop`: lockers, cabinets, mounted boards, wall decals.
- `floor_anchor`: desks, shelf islands, teacher furniture.
- `floor_clutter`: debris, trash, broken fragments.
- `focal_prop`: interactive or memory-important item.

## Large Scene Profiles

Large scenes use per-scene tagged profiles:

- `corridor_large`: player scale `3.0`, speed `362` (editor-tuned; ~`180 × scale × 0.67` when adjusting scale)
- `classroom_large`: player scale `0.86`, speed `160`
- `library_large`: player scale `0.78`, speed `145`
- `default`: player scale `1.00`, speed `180`

## Per-scene exploration viewport (Arc 1 legacy — 1.1 / 1.2)

Global `project.godot` stays at **1400×900** (do not change without approval — prior 1280×720 experiment broke 1.1). Arc 1 scenes instead resize the OS window on enter via `scenes/core/exploration_viewport.gd`:

- Add child node `ExplorationViewport` with `@export design_viewport: Vector2i` matching background PNG aspect so cover-fit is 1:1 (no side crop / post-FX void fringe).
- **1.2:** `Vector2i(1920, 1200)` — matches `1.2_Corridor.png` (2400×1500, 1.6:1).
- **1.1:** `Vector2i(1400, 1400)` — square window for ~3520² school exterior art.
- **Debug scale:** `@export debug_scale` or env `AXEL_DEBUG_VIEWPORT_SCALE` (e.g. `1.33` → 2560×1600 on 1.2).
- Restores previous window size on `_exit_tree` so combat/menu unchanged.
- **1.2 layout:** `_apply_background_layout()` in `1.2_Corridor.gd` must run deferred after resize. User-facing resolution/scale settings autoload is a separate future task.

## Background and camera pipeline (new PNG scenes)

New exploration scenes MUST derive `Camera2D` limits from the background PNG — never hand-tune `limit_*` or `fixed_x`. Void outside the art shows through post-FX as red/CRT fringe.

- **Layout:** `scenes/core/background_layout.gd` — `BackgroundLayout.apply` (cover/contain → `world_rect`).
- **Camera:** `scenes/core/background_camera_controller.gd` — `BackgroundCamera` on `Camera2D`; default `camera_mode = static_locked`.
- **Colliders:** authorship in texture-pixel space under `WalkableWorld/EnvironmentColliders`; sync on `Camera2D.layout_applied` (new scenes) or `1.2_Corridor.gd` `_sync_environment_colliders(cover_scale, bg_position)` (legacy 1.2).
- **Player:** world space under `WalkableWorld/Player` on new scenes (legacy 1.1/1.2 still use `PlayerLayer` until migration).

Full template, JSON fields, and QA smoke: `plans/scenes/SCENE_BUILDER_AGENT_SPEC.md` → "Exploration Scene Template". Canon summary: `plans/core/AI_DOCS.md` → Optional references.

## Arc 1.1 player leaf fade (legacy)

Scene-specific; do not copy to new scenes without a design pass.

- **Nodes:** `EnvironmentColliders/TreeLine_Bottom_Behind`, `TreeLine_Top_Behind` — `Area2D` + `leaf_occlusion_zone.gd` + child `CollisionPolygon2D` (behind-canopy fade zones). Trunk depth line: `TreeLine_Bottom` / `TreeLine_Top` `StaticBody2D` polygons.
- **Editor tuning:** Select each `TreeLine_*_Behind` node → Inspector `Feather Px`; edit polygon points on `CollisionPolygon2D`. Green preview overlay when zone selected in editor. Designer hand-tuned both zones to `feather_px = 12.0` and adjusted polygon shapes in editor — treat as authored layout; do not reset without playtest.
- **Wiring:** `1.1_SchoolExterior.gd` `_configure_leaf_occlusion_masks()` resolves `TreeLine_*_Behind` zones → `Player.configure_leaf_occlusion_polygons` (world polygon + per-zone feather + trunk Y cutoffs).
- **Shader:** `scenes/fx/white_sprite.gdshader` — fade = feathered polygon mask × trunk Y gate (`leaf_gate_softness`, `player_anchor_y` from lower-body collision). Empty polygon count disables that tree mask. `1.2` does not call setup.

## Unknown Asset Handling

- If classification confidence is below threshold, move asset to quarantine list.
- Quarantined assets are excluded from auto-placement.
- Quarantine report must include filename and top candidate classes.

## Blueprint Reconciliation

- Scene intent comes from `AXEL_SCENES_BLUEPRINT.md`.
- Narrative tone and canon come from `core/AI_DOCS.md`.
- If a requested scene composition conflicts with path safety, path safety wins and the draft includes a note.

## Review Bundle Requirements

Each draft set must include:

- Placement JSON per scene
- Preview image per scene
- `review_notes.md` that explains:
  - why each focal cluster exists
  - where chokepoints are and why
  - what was quarantined
