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

These numbers are **authored at 1920×1280 cover-fit** of that scene’s PNG (not “whatever your Game tab is”). Runtime `PlayerCoverSync` multiplies them by `live_cover / baseline`.

Mike’s live walk sheet is a 12-cell strip (`mike_walking-Sheet_meta.txt`: ~439×971). Authored scale keeps on-screen height near the old 64×scale look: `new_scale ≈ old_scale × (64 / cell_h)`.

**Walk speed from scale (mandatory):** Authored `speed` comes from `PlayerWalkSpeed.from_scale(scale)` (`scenes/core/player_walk_speed.gd`). Stride constant `K = 169.8 / 0.198` (shared-room pair, **~33% slower** than the old `253.4` reference). Below scale `0.3`, add extra world speed linear in how far under that threshold (`1.1` at `0.079` gets `+33.5`; same slope everywhere). Result is rounded to one decimal. `PlayerCoverSync.bind_from_player` applies the formula; do not hand-tune Inspector speed against scale. Do not re-run the formula on live cover-sync or 2.4 depth ramp (those already multiply scale and speed together).

Live authored Player scale / speed at **1920×1280** (then `PlayerCoverSync` multiplies). Walk loop FPS is **5** everywhere. Scale is stored to three decimals; speed to one.

| Scene | Scale | Speed |
| --- | --- | --- |
| 1.1 exterior | `0.079` | `101.2` |
| 1.2 corridor | `0.198` | `185.3` |
| 1.4 basement door | `0.198` | `185.3` |
| 2.1 cafeteria | `0.298` | `255.9` |
| 2.3 kitchen | `0.331` | `283.9` |
| 2.4 classrooms corridor | `0.198` | `185.3` |
| 3.1 backyard | `0.198` | `185.3` |
| 4.1 teachers’ lounge | `0.198` | `185.3` |
| 5.1 classroom | `0.298` | `255.9` |

Kitchen is above scale `0.3` (no small-scale extra). 2.1 / 5.1 are 50% larger than the shared `0.198`. 1.1 gets the most below-0.3 extra.

Old profile names (`classroom_large` `0.86`, `library_large` `0.78`) are retired — do not copy those numbers onto the new sheet.

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

**Dialogue:** `TopDialogueOverlay` API in `AI_DOCS.md` § Style and FX. Multi-line: `show_lines([...])`. In-bar swap: `cancel_pending_line()` → `type_line()` → `await_line_advance()` → `hide_line()`. Opt-in mid-line pause: `|beat:<seconds>|` inside the string (see AI_DOCS example); do not auto-insert. Other-speaker lines: prefix with `NAME:` (ALL CAPS) or `|other|` (marker never shown) so the overlay types them in bright red; player/narration stays white. Audio lives on the overlay scene (every room that instances it gets it): open WAV on bar on, same clip reversed on real hide, `axel_typewriter_v4.wav` only while letters type. Typing ticks use the `Typewriter` bus; open/close uses `TypewriterOpen` (Panner for the bar click only). Per-clip mix is `OpenClosePlayer` / `TypeLoopPlayer` `Volume Db` in `TopDialogueOverlay.tscn` — do not add per-room players.

**Music:** Do not instance soundtrack players in menu/overworld/combat `.tscn` files. Autoload `AxelMusic` owns BGM (`B_Goes_Down_p2` menu → 10s crossfade to `p1` on New Game; combat casino layers via `to_combat` / first-win / Trinity hooks). Loudness: `Music` bus in `default_bus_layout.tres`.

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

1. `PlayerCoverSync.bind_from_player` then `bind_design_from_background(background, camera.fit_mode)` (1.1/1.2 set `_OLD_BG_SCALE` first so bind_design no-ops; 1.4 sets 1.2’s `0.546` the same way). Do **not** store a separate spawn constant.
2. Bind PlayerLayer extras that should match the room (e.g. memory glow) via `bind_extra_node`. Capture glow editor positions if needed (`_foo_tex`).
3. Connect `Camera2D.layout_applied` → sync `EnvironmentColliders` + `PlayerSpawnSync` + `PlayerCoverSync.apply`.
4. Layout via `BackgroundLayout.apply` (camera does this when `background_path` is set).

```gdscript
func _ready() -> void:
	_player_cover_sync.bind_from_player(_player)
	_player_cover_sync.bind_design_from_background(
		$WalkableWorld/Background, $Camera2D.fit_mode, $Camera2D.background_y
	)
	$Camera2D.layout_applied.connect(_on_background_layout_applied)

func _sync_world_space(cover_scale: float, bg_position: Vector2) -> void:
	var env := $WalkableWorld/EnvironmentColliders
	var tex := PlayerSpawnSync.capture_tex(env, _player)
	env.position = bg_position
	env.scale = Vector2.ONE * cover_scale
	PlayerSpawnSync.apply_tex(env, _player, tex)
	_player_cover_sync.apply(_player, cover_scale, bg_position)
```

### Background / camera helpers

- Layout: `scenes/core/background_layout.gd`
- Camera: `scenes/core/background_camera_controller.gd`
- Colliders: texture-pixel space under `WalkableWorld/EnvironmentColliders`
- Player: world space under `WalkableWorld/Player` on **new** scenes (legacy 1.1/1.2 still use `PlayerLayer`)
- Cover sync: `scenes/core/player_cover_sync.gd` — first layout uses the 1920×1280 (or legacy `_OLD_BG_SCALE`) baseline; later resizes keep the same Mike-vs-room ratio. 1.4 uses 1.2’s `0.546` (same 2400×1500 PNG size).
- Spawn: `scenes/core/player_spawn_sync.gd` — the Player node is the spawn. Capture with `env.to_local` **before** moving `EnvironmentColliders`, apply with `env.to_global` after. Do this on the **first** layout, not only later resizes. Regression: `scenes/core/test/player_spawn_sync_check.gd`.

### Rule: Mike walk sheet (12-cell)

Do not slice the raw `kävely_etu` / `kävely_sivu` drawings as a grid. Pack with `tools/pack_mike_walk_sheet.py` (ink-box cuts). Live look:

- Head: inverted source face (painted white in `kävely_*` becomes black holes — no extra fill plate). Eyes/scribble holes stay opaque.
- Chin down: solid white ink (not see-through).
- Empty around Mike: transparent.
- Packer drops far-off specks (`FAR_BLOB_DIST`) and extra islands under 120 px (stray waist/head strokes).
- `white_sprite.gdshader` keeps packed RGB and multiplies `COLOR.rgb` so `ShadowOutline` modulate can be black. Mike is **not** noir-inverted. CRT still runs on him. Play and the editor show `ShadowOutline` with the shared 1.2 fit (a slightly larger black copy behind the white figure) on every pose. Pose nudges must not shift that silhouette — `Player.gd` divides the shadow offset by the outline scale. Do not force `ShadowOutline.visible = false` in the editor tool.

`Player.gd` animations: `walk_down` / `walk_up` / `walk_right` + `flip_h` for left; idle / idle_back / idle_side keep last facing. Walk loop FPS is **5** (`animation_fps`, same as 1.2). Assign `res://assets/sprites/mike_sprite_frames.tres` in the editor. Rollback: restore `mike_walking-Sheet_legacy13.png` over the live sheet and revert Player + scales.

### Rule: optional walk-position size ramp (2.4 only today)

`PlayerCoverSync` is window/cover-fit only. If a drawing has zooming perspective, a scene-local walk-through `Area2D` may multiply scale + speed **after** `PlayerCoverSync.apply()`. Live: `2.4` `VerticalSizeRampArea` (100% at cafeteria end → `@export vertical_far_scale` `1.5` at the corner; last size kept after leave). Do not put this in the shared cover-sync helper. Grow around the Player node, not the feet.

### Rule: do not retune Player `.tscn` scale for another computer

If Mike looks wrong vs the furniture **at 1920×1280**, change the authored scale in that scene. If he only looks wrong on a small Game tab / other monitor, the scaler is broken — fix `PlayerCoverSync`, not the scene number. Never edit Player `scale` to “match this window.”

### Rule: PlayerLayer extras share the cover ratio

Anything on `PlayerLayer` that should match the drawing (memory glow) gets the same cover ratio via `bind_extra_node` + `apply`. Props under `EnvironmentColliders` (e.g. kitchen flashlight) already follow `env.scale` — no second scaler.

### Rule: first-visit enter lines play once

Scene enter / discovery lines use a GameManager `*_seen` flag. They must not replay when returning from another room, a memory still, or a side peek. Same rule for every walkable scene.

### Rule: memory still leave (after the bar closes)

Still-image memories have no player and no `[E]` chip. After `_can_exit` (dialogue finished, or already-seen skip), leave with: red `[X]`, left-click, tap, or Tab/E/Space/Enter. Same keys during lines still skip/advance — they must not leave until the bar is closed. Live: `2.2`, `3.2`, `5.2`.

### Rule: room-to-room spawn maps along leave/arrive boxes

**Approved example (match this):** `1.2_Corridor` ↔ `1.4_BasementDoor` via each scene’s `ExitTrigger`. Top of the leave box → top of the arrive box; bottom → bottom. Do **not** copy world Y, floor-line offsets, or scene size.

For `[E]` InteractAreas and other side `ExitTrigger`s, use the same helper: save `GameManager.interact_arrival_t` (0 = top/left of the source box, 1 = bottom/right). Measure `t` from the Front hitbox in `EnvironmentColliders` texture space (the circle sits below the Player node). Take `t` **once** on the destination (deferred restore after first layout, like `1.2`). On every `layout_applied`: always `PlayerSpawnSync` + cover-sync; if a door peek is still pending, `call_deferred` place — do **not** place-and-clear inside the first layout. Map `t` onto the matching dest box, keep the into-room peek on the short axis, land the Front circle on that point, then nudge with `InteractArrival.clamp_hitbox_to_walls`. Helper: `scenes/core/interact_arrival.gd`. Missing `t` (hub/map) falls back to center (`0.5`). Fresh Play / F6 still uses the Player node. Memory stills keep exact standing-spot restore. Live `[E]` pairs: `1.4`↔`2.1`, `2.1`↔`2.3`/`3.1`/`2.4`, `2.4`↔`4.1`/`5.1`, `1.1`↔`1.2`. Live walk-off: `1.2`↔`1.4`. Regression: `scenes/core/test/interact_arrival_check.gd`.

### Rule: Player node is the spawn (mandatory)

There is no separate spawn point. The `Player` node **is** the spawn.

- Drag `PlayerLayer/Player` (or `WalkableWorld/Player` on new scenes) on the drawing. That is where Mike starts a fresh Play / F6.
- **Forbidden:** hardcoded `env.to_global(Vector2(...))`, skipping the first cover-fit remap, teleporting default spawn onto a door / stones / interact shape, or storing a spawn constant that can go stale.
- **Allowed elsewhere:** only GameManager peek / return when arriving from another room. Arrival along a dest InteractArea / ExitTrigger (`interact_arrival_t`) may place off the Player node.
- 1.1 intro may start off-screen and walk **to** the remapped Player node. Skip-intro leaves Mike on that node. Do not walk to a computed stones target instead.
- Helper: `PlayerSpawnSync.capture_tex` before mutating `EnvironmentColliders`, then `apply_tex` after. Works for both unscaled (2.1-style) and pre-scaled (1.2/1.4 `_OLD_BG_SCALE`) colliders.
- Editor: assign `res://assets/sprites/mike_sprite_frames.tres` on `AnimatedSprite` / `ShadowOutline` so Mike is visible on the node while you drag. Play still rebuilds frames in `Player.gd`. Keep `ShadowOutline` visible in the editor (the pose-nudge tool must not force it off). `AnimatedSprite` stays hidden in the 2D view because the pose stack draws it.
- Shared hitbox (default): `CollisionFront` points at `res://scenes/player/hitbox_front.tres`. That `.tres` is **radius only**; node `position` is the shared 1.1 Front `(-37.812428, 126.04143)`. Pose nudges line every facing onto this one circle. Walking left (A) mirrors Front X so the circle stays on the flipped side pose (right/D is the authored side). `Player.gd` reapplies Front on Play and removes `CollisionBack` / `CollisionSide` if they still exist. Copy the 1.1 Front position into a new room’s `.tscn` so the editor preview matches. Do not recreate Back/Side.
- Alpha hitbox (opt-in): set `use_alpha_collision` on that Player. Select `Player` for the cyan editor preview of the traced outline.

### Rule: any other node placed against the background must spawn from its own editor position

Memory-indicator glows and any other node whose on-screen
spot should match where you dragged it in the editor MUST follow this pattern
— never hardcode a position constant, and never re-derive a node's runtime
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

Player spawn uses `PlayerSpawnSync` (above), not a `_player_spawn_tex` copy of
`player.position`. See `2.1_Cafeteria.gd` (`_memory_indicator_tex`) for the
glow pattern.

### Rule: no visual offset from the node (default)

By default the **player model**, **memory glow**, and **`[E]` interact chip**
must sit on their node. No extra offset.

- Player: `AnimatedSprite` **position** stays at `(0, 0)` on the Player node. Do not
  author a sprite child `position` to “fix” spawn. Move the Player node itself.
- Shared exception — pose nudge: `AnimatedSprite.offset` comes from
  `res://scenes/player/pose_nudge.tres` (Front / Back / Side). Select the
  **Player** node → Inspector group **Pose Nudge**. `Editor Pose Preview`
  switches which pose is solid; the other two stay faded on top in the 2D
  view (live). Type roughly 80–200 on X/Y — tiny values like `1` will not
  show. A yellow cross is the Player origin. Do not drag frames in
  SpriteFrames — Play rebuilds those. One edit is shared by every room; Ctrl+S
  so `pose_nudge.tres` is saved.
- Shared exception — hitbox: `CollisionFront` uses the shared 1.1 Front
  `(-37.812428, 126.04143)`. `Player.gd` reapplies it at Play and removes
  `CollisionBack` / `CollisionSide`. Copy Front into a new room’s `.tscn` so
  the editor preview matches. Do not zero it or invent a per-room player polygon.
- Shared exception — `ShadowOutline`: uses the 1.2 fit on every walkable room
  (`position` `(-5.0416956, -5.041732)`, `scale` `(1.0335996, 0.9969109)`).
  `Player.gd` reapplies this at Play and in the editor. The same fit is used
  for every spritesheet pose; pose-nudge `offset` is divided by that scale so
  Front / Back / Side do not shift the silhouette. Copy the 1.2 position/scale
  into a new room’s `.tscn` so the editor preview matches. Do not invent a
  per-room silhouette.
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

**Exception:** Mike’s `CollisionFront` is *meant* to share `res://scenes/player/hitbox_front.tres` across every room. Do not Make Unique that.

Godot stores the shape as a shared resource. If two doors point at the same SubResource, editing size/scale on one changes the other.

1. After duplicating a `CollisionShape2D` in the editor: select the shape in the Inspector → **Make Unique**.
2. In `.tscn` text: every door/interact/wall collider that must be tuned alone needs its own `[sub_resource type="RectangleShape2D" id="..."]` and a matching `shape = SubResource("...")`.
3. Door blockers belong under their own `StaticBody2D` (e.g. `LoungeDoorBlock` → `Lounge_CollisionShape2D`), not as orphan `CollisionShape2D` children of `EnvironmentColliders`.

### Rule: room-edge walls must hide Mike’s drawing (not only the feet circle)

The Front circle is what `move_and_slide` stops. The walk cell (`439×971`) plus `ShadowOutline` stick past that circle, so a 40px `LeftWall` on the PNG edge lets the picture of Mike walk off the drawing.

**Required inset** (from the picture edge to the wall’s inner face) = how far the drawing sticks past the circle in that facing, times live Player scale. The checker computes this; do not copy a one-size-fits-all texture width.

- Grow `LeftWall` / `RightWall` / `TopWall` / `BottomWall` **from the PNG edge inward**. Give each wall its own `RectangleShape2D` (Make Unique) so one edit does not resize the opposite wall.
- Skip walls that must stay open: 1.1 `LeftWall` (Ending 1), 1.2 `RightWall` and 1.4 `LeftWall` (walk-off). Skip 2.4 (already thickened in play). Do not thin walls that already pass.
- Furniture / door blockers are not this rule.

Live: 1.1 Top only; 1.2 / 1.4 / 2.1 / 2.3 / 3.1 / 4.1 / 5.1 edge walls that were too thin. Kitchen example: unique Left `200×2480` / Right `158×2480` / Top `3508×346` / Bottom `3508×193`. Regression: `tools/qa/wall_sprite_clearance_check.gd` (`WALL_SPRITE_CLEARANCE OK`).

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

New walkable scenes must wire `PlayerCoverSync` (`bind_from_player` + `bind_design_from_background`) and spawn through `PlayerSpawnSync` (Player node, first layout included). Regression: `scenes/core/test/player_cover_sync_check.gd`, `scenes/core/test/player_walk_speed_check.gd`, `scenes/core/test/player_spawn_sync_check.gd`. Room-edge walls: `tools/qa/wall_sprite_clearance_check.gd`.

### Playtest variants (optional)

Inherited child `.tscn` that instances the canonical scene and overrides only playtest flags (e.g. `skip_intro = true`). Do not duplicate the full tree. Example: `1.1_SchoolExterior_Playtest.tscn`.

## Window resolution (project-wide)

- Base `1920×1280` (3:2) in `project.godot`. Stretch stays **disabled** (no letterbox / Keep-aspect canvas stretch — that shrank dialogue fonts).
- Game tab / OS window may be any size or aspect; `BackgroundCamera` cover-fits the PNG and recomputes on `size_changed`.
- Mike, walls (`EnvironmentColliders`), and art share one cover scale via `PlayerCoverSync` from the 1920×1280 baseline (1.1/1.2: `_OLD_BG_SCALE`; 1.4: same `0.546` as 1.2).
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

- Zones: `TreeLine_Bottom_Behind` / `TreeLine_Top_Behind` / `RightWall_Behind` / `Stump_Left_Behind` / `Rocks_Left_Behind` / `Rocks_Right_Behind` + `leaf_occlusion_zone.gd`
- Wired in `1.1_SchoolExterior.gd` → `Player.configure_leaf_occlusion_polygons` → `white_sprite.gdshader`
- Trees, stump, and rocks use a collision-front Y-gate (same as the tree trunk line): fade only when standing behind the object, not when overlapping from the front. `RightWall_Behind` uses cutoff `1e9` (no Y-gate) so only the polygon matters. Shader: cutoff `> 1e8` means “allow,” not “off.” Extra `CollisionPolygon2D` children under one behind zone all count (max 4 per zone). Each extra polygon uses the nearest rock/stump collision as its own front line.
- Shader has 6 behind slots. Canon `feather_px = 2.0` on all behind zones (1.1 trees + wall + stump + rocks, 2.1 tables/chairs, 3.1 wall/bush/well)

## What is walkable / shipped

Do not maintain a static “shipped list” here. Inspect live `scenes/Arc_*` and scene scripts for what is currently walkable vs placeholder. This file is how-to; the game tree is status.
