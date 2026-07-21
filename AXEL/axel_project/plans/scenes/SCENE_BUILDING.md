# AXEL Scene Building

**Read this first when building or editing a walkable exploration scene.**

Canon alias: `scene agent` / scene building. Conflicts resolve via `plans/core/AI_DOCS.md`.

## Canon sources

1. `plans/core/AI_DOCS.md`
2. This file (`plans/scenes/SCENE_BUILDING.md`)
3. `plans/scenes/AXEL_SCENES_NEW.md` → per-arc dialogue (`AXEL_SCENES_ARC1.md` … `ARC7.md`)

## Goal

Keep scenes visibly abandoned, looted, broken, and rotting while preserving readable movement for the player.

## Core composition

- Build from a recognizable institutional base (classroom rows, corridor wall props, library shelves).
- Disrupt with decay clusters (fallen props, tilt, missing symmetry).
- Keep focal narrative props (locker, desk, board, graffiti) readable near camera attention.

## Pathing (balanced)

- One clear primary route from entry to exit/interaction.
- Occasional narrow chokepoints for tension.
- Never hard-block the route.
- Heavier debris on side lanes and corners first.
- Clustered clutter, not uniform scatter; sparse center lane unless intentional pressure.

## Placement roles

- `wall_prop`: lockers, cabinets, boards, wall decals
- `floor_anchor`: desks, shelf islands, furniture
- `floor_clutter`: debris, trash
- `focal_prop`: interactive or memory-important item

## Player scale profiles

- `corridor_large`: scale `3.0`, speed `362` (~`180 × scale × 0.67` when retuning)
- `classroom_large`: scale `0.86`, speed `160`
- `library_large`: scale `0.78`, speed `145`
- `default`: scale `1.00`, speed `180`

## Exploration scene template (mandatory for new PNG scenes)

Use the shared background + camera pipeline. Do **not** hand-tune `limit_*` or `fixed_x`. Do **not** embed noir/scanline/CRT overlays (`AxelPostFxStack` owns those).

### Scene tree

```
Root (Node2D + scene script)
├── WalkableWorld (Node2D)
│   ├── Background (Sprite2D, centered=false, z_index=-100, script: locked_exploration_background.gd, metadata/_edit_lock_ = true)
│   └── EnvironmentColliders (Node2D) — texture-pixel space; sync on layout_applied
├── Camera2D — script: res://scenes/core/background_camera_controller.gd
├── Player (CharacterBody2D under WalkableWorld/Player for new scenes — see migration note)
├── TopDialogueOverlay (instanced)
└── InteractPromptOverlay (instanced)
```

**Dialogue:** `TopDialogueOverlay` API in `AI_DOCS.md` § Style and FX. Multi-line: `show_lines([...])`. In-bar swap: `cancel_pending_line()` → `type_line()` → `await_line_advance()` → `hide_line()`.

### Camera2D exports (`BackgroundCamera`)

| Export | Default | Purpose |
|--------|---------|---------|
| `background_path` | — | `NodePath` to `WalkableWorld/Background` |
| `fit_mode` | `cover` | `BackgroundLayout.FitMode` (`cover` or `contain`) |
| `camera_mode` | `static_locked` | Enable `movable_follow` only when pan is needed |
| `margin_px` | `0` | Inset art rect for CRT trim (often `12`) |
| `target_path` | — | Follow target |
| `background_y` | `0` | Vertical offset |
| `follow_smoothing` | `5` | Movable follow lerp |
| `max_auto_zoom` | `4` | Cap auto-zoom for small art |
| `static_center` | `(inf, inf)` | Optional fixed center for `static_locked` |

### `_ready()` order

1. Layout via `BackgroundLayout.apply` (camera does this when `background_path` is set).
2. Sync `EnvironmentColliders` on `Camera2D.layout_applied`.
3. Camera limits applied by `BackgroundCamera`.

```gdscript
func _ready() -> void:
	$Camera2D.layout_applied.connect(_on_background_layout_applied)

func _on_background_layout_applied(scale_factor: float, bg_position: Vector2, _world_rect: Rect2) -> void:
	_sync_environment_colliders(scale_factor, bg_position)
```

### Background / camera helpers

- Layout: `scenes/core/background_layout.gd`
- Camera: `scenes/core/background_camera_controller.gd`
- Colliders: texture-pixel space under `WalkableWorld/EnvironmentColliders`
- Player: world space under `WalkableWorld/Player` on **new** scenes (legacy 1.1/1.2 still use `PlayerLayer`)
- Cover sync: `scenes/core/player_cover_sync.gd` so Mike scales with window resize

### QA smoke (new scenes)

After `_ready`, headless smoke MUST call:

- `QaCanonValidators.collect_background_camera_findings(root, scene_path)`
- `QaCanonValidators.collect_background_editor_lock_findings` (background must have `metadata/_edit_lock_`)

### Playtest variants (optional)

Inherited child `.tscn` that instances the canonical scene and overrides only playtest flags (e.g. `skip_intro = true`). Do not duplicate the full tree. Example: `1.1_SchoolExterior_Playtest.tscn`.

## Window resolution (project-wide)

- Base `1920×1280` (3:2) in `project.godot`; gameplay letterboxes when the window shape differs.
- `BackgroundCamera` recomputes on `size_changed`.
- `exploration_viewport.gd` is **inert** (kept so 1.1/1.2 still load).

## Canonical filename invariant

Always target `<arc>.<index>_<Name>.tscn` (e.g. `1.2_Corridor.tscn`). Never create aliases like `Corridor.tscn`. Scenes live under `Arc_<N>/` (or `Endings/`, `Main_Menu/` for `7.x` / `0.x`).

## Background swap checklist (hand-drawn PNG)

**Naming:** `exports/Drawings/<sceneNumber>_<SceneName>.png` (e.g. `2.3_Kitchen.png`).

1. Drawing exists + `.import` generated; note texture uid.
2. Inventory `.tscn` nodes — remove visual-only placeholders; keep collision, interact areas, player, UI overlays, scene script.
3. Wire `Sprite2D` background (`z_index=-100`, `centered=false`) to the drawing; prefer `WalkableWorld/Background` + lock script for new scenes.
4. Remove orphaned `ext_resource` / tilemap `sub_resource` entries.
5. Verify `@onready` / `get_node()` paths still exist.
6. Editor check: loads, art visible, player moves, post-FX on top, dialogue readable, transitions work.

Do not embed baseline post-FX in the `.tscn`.

## Deferred migration — Arc 1 (1.1 / 1.2)

Do not rewire without approval. Still deferred:

1. Move player to `WalkableWorld/Player` (replace `PlayerLayer` screen-space follow).
2. Keep player above noir via `z_index` / layer order.
3. Cameras already use `background_camera_controller.gd` on 1.1/1.2.

## Arc 1.1 leaf fade (legacy)

Do not copy to new scenes without a design pass.

- Zones: `TreeLine_Bottom_Behind` / `TreeLine_Top_Behind` + `leaf_occlusion_zone.gd`
- Wired in `1.1_SchoolExterior.gd` → `Player.configure_leaf_occlusion_polygons` → `white_sprite.gdshader`
- Designer-tuned `feather_px = 12.0` — do not reset without playtest

## Reference ship examples

- Arc 1 walkable: `1.1`, `1.2`, `1.4`
- Arc 2 walkable: `2.1_Cafeteria`, `2.3_Kitchen`
- Hub UI: `1.3_LockerHub`
