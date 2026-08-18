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

### Rule (mandatory for every new scene): white background, black outlines/placeholders

Author **source** colors against the noir/VFX remap — not the final on-screen look. Production VFX is **8-band inverted noir** (see `AI_DOCS.md` § Style and FX). The filter still turns white ground dark and black ink red.

**Always:**

1. **Background PNG / empty fill:** pure **white** (`#ffffff` / `Color(1,1,1,1)`). Never ship a black or near-black clear fill — under VFX that becomes a red field (wrong).
2. **All drawn placeholders and other authored shapes:** **black** fills (`Color(0,0,0,…)`).
3. **All outlines** (`Line2D`, strokes, borders on placeholders/props): **black** (`Color(0,0,0,1)`).

Do not use red, brown, or grey “preview” colors in the editor for outlines — they will not match the intended black→red look after post-FX.

### Scene tree

```
Root (Node2D + scene script)
├── WalkableWorld (Node2D)
│   ├── Background (Sprite2D, centered=false, z_index=-100, script: locked_exploration_background.gd, metadata/_edit_lock_ = true)
│   └── EnvironmentColliders (Node2D) — texture-pixel space; sync on layout_applied
├── Camera2D — script: res://scenes/core/background_camera_controller.gd
├── Player (CharacterBody2D under WalkableWorld/Player for new scenes — see migration note)
│   (legacy Arc 1 still uses PlayerLayer CanvasLayer — do not rewire without approval)
├── TopDialogueOverlay (instanced) — must draw ABOVE InteractPromptOverlay
└── InteractPromptOverlay (instanced)
```

**Layer order (UI):** dialogue above `[E]` prompt; both above CRT / baseline post-FX. Hub/map chrome (red `X`, travel choices) that must stay readable: CanvasLayer ~110 (above CRT 108, below dialogue 111) — do not rely on root Control `z_index`. See `AI_DOCS.md` § Style and FX.

**Dialogue:** `TopDialogueOverlay` API in `AI_DOCS.md` § Style and FX. Multi-line: `show_lines([...])`. In-bar swap: `cancel_pending_line()` → `type_line()` → `await_line_advance()` → `hide_line()`. Opt-in mid-line pause: `|beat:<seconds>|` inside the string (see AI_DOCS example); do not auto-insert. Other-speaker lines: prefix with `NAME:` (ALL CAPS) or `|other|` (marker never shown) so the overlay types them in bright red; player/narration stays white.

**Memory indicator:** instance `scenes/fx/MemoryIndicator.tscn` under `PlayerLayer` (above noir). Cover-fit scenes: capture editor position, remap on `layout_applied` — do not derive from another node’s shape. `visual_offset` stays `(0, 0)` unless asked.

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

### Rule: any node placed against the background must spawn from its own editor position

Player spawn points, memory-indicator glows, and any other node whose on-screen
spot should match where you dragged it in the editor MUST follow this pattern
— never hardcode a spawn constant, and never re-derive a node's runtime
position from a *different* node (e.g. snapping onto an interact area's shape).
That silently makes the node's own editor position dead/unused, so nudging it
in the editor does nothing at runtime.

1. In `_ready()` (before the first `layout_applied`), capture the node's
   authored `position` into a `_foo_tex` variable. At this point it's still in
   texture-pixel space (same frame as `EnvironmentColliders`).
2. In the `layout_applied` handler, once `EnvironmentColliders` has its final
   `position`/`scale`, set `node.global_position = env.to_global(_foo_tex)`.
3. To move the spot, drag the node itself in the editor — do not add an
   offset constant or point it at another node's position.

See `2.3_Kitchen.gd` (`_player_spawn_tex`) and `2.1_Cafeteria.gd`
(`_player_spawn_tex`, `_memory_indicator_tex`) for reference implementations.

### Rule: no visual offset from the node (default)

By default the **player model**, **memory glow**, and **`[E]` interact chip**
must sit on their node. No extra offset.

- Player: `AnimatedSprite`, `ShadowOutline`, and `CollisionShape2D` stay at
  `(0, 0)` on the Player node. Do not author a sprite/collision child offset
  to “fix” spawn. Move the Player node itself.
- Memory glow: `MemoryIndicator.visual_offset` stays `Vector2.ZERO`. Align
  `MemoryInteractArea` to the same editor point as the glow node.
- `[E]` chip: `InteractPromptOverlay.screen_offset` stays `Vector2.ZERO`
  (shared default). Do not put a scene-wide override on the overlay node.

Cover-fit remap (`env.to_global(_foo_tex)` from that node’s own editor
position) is **not** an offset. Child `position`, `visual_offset`, and
`screen_offset` **are** offsets — leave them zero unless the user asks for
one specific nudge (then scope it to that one zone/node).

### Rule: each CollisionShape2D gets its own Shape2D resource

Never share one `RectangleShape2D` / `CircleShape2D` / other `Shape2D` SubResource across two `CollisionShape2D` nodes that should resize or scale independently.

Godot stores the shape as a shared resource. If two doors point at the same SubResource, editing size/scale on one changes the other.

1. After duplicating a `CollisionShape2D` in the editor: select the shape in the Inspector → **Make Unique**.
2. In `.tscn` text: every door/interact/wall collider that must be tuned alone needs its own `[sub_resource type="RectangleShape2D" id="..."]` and a matching `shape = SubResource("...")`.
3. Door blockers belong under their own `StaticBody2D` (e.g. `LoungeDoorBlock` → `Lounge_CollisionShape2D`), not as orphan `CollisionShape2D` children of `EnvironmentColliders`.

### Rule: interact-prompt "[E]" chip has no offset by default

Same as the no-visual-offset rule above. `InteractPromptOverlay.gd`'s
`screen_offset` export defaults to `Vector2.ZERO` — the chip centers exactly
on the interact anchor (the `CollisionShape2D`'s `global_position`). Never
add a nudge (screen-space `screen_offset` override in a scene's `.tscn`, or
a world-space anchor offset in the scene script) as a blanket/default
choice. Only add one when explicitly asked for a specific interact point,
and scope it as narrowly as possible (ideally per-zone in the scene
script's anchor function, not the whole-scene `screen_offset`, since one
`InteractPromptOverlay` node is shared by every interact zone in a scene).

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
3. Wire `Sprite2D` background (`z_index=-100`, `centered=false`) to the drawing; prefer `WalkableWorld/Background` + lock script for new scenes. PNG empty fill = pure **white** (never black — VFX turns white ground dark / black ink red). Placeholders and **all outlines** = **black**.
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

- Zones: `TreeLine_Bottom_Behind` / `TreeLine_Top_Behind` / `RightWall_Behind` + `leaf_occlusion_zone.gd`
- Wired in `1.1_SchoolExterior.gd` → `Player.configure_leaf_occlusion_polygons` → `white_sprite.gdshader`
- Trees use a trunk Y-gate. `RightWall_Behind` uses cutoff `1e9` (no trunk line) so only the polygon matters. Shader: cutoff `> 1e8` means “allow,” not “off.”
- Canon `feather_px = 2.0` on all behind zones (1.1 trees + right wall, 2.1 tables/chairs, 3.1 wall/bush/well)

## What is walkable / shipped

Do not maintain a static “shipped list” here. Inspect live `scenes/Arc_*` and scene scripts for what is currently walkable vs placeholder. This file is how-to; the game tree is status.
