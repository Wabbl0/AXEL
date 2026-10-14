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
| 3.1 backyard | `0.277` | `241.0` |
| 4.1 teachers’ lounge | `0.342` | `293.3` |
| 5.1 classroom | `0.298` | `255.9` |

Kitchen is above scale `0.3` (no small-scale extra). 1.4 matches the shared `0.198` / `185.3` (same as 1.2). 2.1 / 5.1 are 50% larger than the shared `0.198`. 3.1 is 40% larger (`0.277`). 4.1 is `0.342` / `293.3` (33% above the previous lounge `0.257`; above `0.3`, so no small-scale extra). 1.1 gets the most below-0.3 extra.

Old profile names (`classroom_large` `0.86`, `library_large` `0.78`) are retired — do not copy those numbers onto the new sheet.

## Memory and item indicator sizes

These numbers are authored at the same **1920×1280 cover-fit** as the player table. `PlayerCoverSync` still multiplies the memory glow by `live_cover / baseline`. The items_indicator still multiplies its size by the room’s live cover scale.

The glow stays the same size next to Mike as in **2.1** (player `0.298`, glow `2.25`). The items_indicator stays the same size next to Mike as in **1.4** (player `0.198`, baseline `0.352`, items_indicator `180`).

`IndicatorFit.memory_from_player` (`scenes/core/indicator_fit.gd`): `2.25 × (player_scale / 0.298)`, rounded to three decimals.

`IndicatorFit.item_marker_px`: `180 × (0.352 / 0.198) × (player_scale / room_baseline)`, rounded to one decimal. `180 × 0.352 / 0.198` is `320`. `room_baseline` is the baseline `PlayerCoverSync` already uses (`_OLD_BG_SCALE` on 1.1 / 1.2 / 1.4; otherwise plain 1920×1280 cover: `1920/3508` on the 3508×2480 plates, `1920/7016` on 2.4).

Do not hand-tune these in the Inspector. `bind_player_cover()` sets the glow before cover-fit captures it. The floor pickup asks the room for the items_indicator size. The 2.4 depth ramp still changes only Mike; the items_indicator stays at the 100% end. The 1.2 arrow hint keeps its own scale.

| Scene | Memory scale | Item size |
| --- | --- | --- |
| 1.1 exterior | `0.596` | `75.5` |
| 1.2 corridor | `1.495` | `116.0` |
| 1.4 basement door | `1.495` | `180.0` |
| 2.1 cafeteria | `2.250` | `174.2` |
| 2.3 kitchen | `2.499` | `193.5` |
| 2.4 classrooms corridor | `1.495` | `231.5` |
| 3.1 backyard | `2.091` | `162.0` |
| 4.1 teachers’ lounge | `2.582` | `200.0` |
| 5.1 classroom | `2.250` | `174.2` |

Live glows: 2.1, 3.1, 4.1, 5.1. Live items_indicators: rooms with a scatter count above 0 (1.4, 2.1, 2.3, 2.4, 4.1, 5.1). The other numbers are what a new glow or items_indicator in that room would use. Regression: `scenes/core/test/indicator_fit_check.gd`.

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
Root (`extends ExplorationRoom`)
├── WalkableWorld (Node2D)
│   ├── Background (Sprite2D, centered=false, z_index=-100, script: locked_exploration_background.gd, metadata/_edit_lock_ = true)
│   └── EnvironmentColliders (Node2D) — texture-pixel space; sync on layout_applied
├── Camera2D — script: res://scenes/core/background_camera_controller.gd
├── PlayerLayer (CanvasLayer 100, follow viewport)
│   └── Player — instance `res://scenes/player/Player.tscn` (legacy Arc 1 also uses this layer — do not rewire without approval)
├── TopDialogueOverlay (instanced) — must draw ABOVE InteractPromptOverlay
└── InteractPromptOverlay (instanced)
```

**Layer order (UI):** dialogue above `[E]` prompt; both above CRT / baseline post-FX (108). The CRT interference wave (`InterfacePulseOverlay` 112) sits above dialogue 111 so the roll also hits the bar (viewport `BackBufferCopy`; glitch 113). Hub/map chrome (red `X`, travel choices) that must stay readable: CanvasLayer ~110 (above CRT 108, below dialogue 111) — do not rely on root Control `z_index`. See `AI_DOCS.md` § Style and FX.

**Dialogue:** `TopDialogueOverlay` API in `AI_DOCS.md` § Style and FX. Multi-line: `show_lines([...])`. In-bar swap: `cancel_pending_line()` → `type_line()` → `await_line_advance()` → `hide_line()`. Opt-in mid-line pause: `|beat:<seconds>|` inside the string (see AI_DOCS example); do not auto-insert. Other-speaker lines: prefix with `NAME:` (ALL CAPS) or `|other|` (marker never shown) so the overlay types them in bright red; player/narration stays white. Stretch stays disabled; the overlay itself recomputes dialogue font size and outline from viewport height so the text-to-window ratio stays constant in a separate fullscreen window. Baseline scene value is `32`, but the live dialogue baseline is `48` at `1920×1280` (1.5x boost, rounded to an integer so VT323 stays crisp). Keep padding/margins authored; let the bar height grow to fit the full line instead of clipping bigger text. Audio lives on the overlay scene (every room that instances it gets it): open WAV on bar on, same clip reversed on real hide, `axel_typewriter_v4.wav` only while letters type. Typing ticks use the `Typewriter` bus; open/close uses `TypewriterOpen` (Panner for the bar click only). Per-clip mix is `OpenClosePlayer` / `TypeLoopPlayer` `Volume Db` in `TopDialogueOverlay.tscn` — do not add per-room players. Board answer in 5.1: `show_lines_keep_bar` then `await_text_entry` — the same bar, a blinking caret that turns from white to red when the bar is pressed, then typing. Enter submits. Do not open `5.3_ClassroomBoard` for that field.

**Music:** Do not instance soundtrack players in menu/overworld/combat `.tscn` files. Autoload `AxelMusic` owns BGM (`B_Goes_Down_p2` menu → 10s crossfade to `p1` on New Game; a fight keeps `p1` and fades in `B_Goes_Down_Drums_p1` over 10s; `B_Goes_Down_Drums_p2` fades in for Vice Round and stays through Free Spins if that round leads there). Loudness: `Music` bus in `default_bus_layout.tres`. Master compresses from -14 dB (ratio 2, +12 dB), then a hard limiter with no extra gain.

**Memory indicator:** instance `scenes/fx/MemoryIndicator.tscn` under `PlayerLayer` (above noir). Authored `indicator_scale` comes from § Memory and item indicator sizes (2.1 stays `2.25`; the packed scene default is that same number). The blob is red; the `Halo` behind it is a white outline 0.96 texture pixels thick at 75% opacity (`marker_silhouette_outline.gdshader`). The glow captures its editor position and remaps on `layout_applied` — do not derive from another node’s shape. `visual_offset` stays `(0, 0)` unless asked. Set `memory_key` (or `collected_bool_property` for the desk) and `interact_area_path` on the instance so the glow hides itself and disables the walk-up box when collected. Do not copy `_sync_memory_indicator` / `_apply_collected_memory` into a new room.

**Player packed scene:** instance `scenes/player/Player.tscn` under `PlayerLayer`. Keep that room’s authored `position` / `scale` / `speed` (and collision extras if that room already had them). Do not paste a new AnimatedSprite + ShadowOutline tree. Silhouette numbers stay on the packed scene.

**Room script trunk:** new walkable rooms `extends ExplorationRoom` (`scenes/core/exploration_room.gd`). Fill in `zone_ids` / `zone_area` / `on_zone_interact` (and peek/occlusion leaves). Doors use `leave_through` + `ExplorationTransition`. Lore pickups use `LorePickup.take` (flashlight and key are the same function, different flag/lines). Memory stills `extends MemoryStill`; picture crop uses `memory_frame.gd`. 1.1 intro and 1.2 locker/arrow keep `_use_default_interact_loop = false`. Frozen peeks, kitchen Y `90`, and 2.4 depth ramp stay in those room scripts.

**Floor item marker:** runtime `scenes/world/ItemMarker.tscn` on `PlayerLayer` (items_indicator, drop shadow, red outline 1.92 texture pixels thick at 75% opacity). Items_indicator size comes from § Memory and item indicator sizes (1.4 stays `180`). The pickup `Area2D` stays under `EnvironmentColliders`. Do not put a catalog icon on the floor. Scatter must keep the 220 px interact circle plus an 8 px pad off walls and furniture, and the spot must sit on the walkable floor connected to Mike. The live Area2D radius stays 220.

**1.2 right-arrow hint:** runtime `scenes/fx/DirectionHint.tscn` on `PlayerLayer`. Pin to the viewport right edge at scale `1.67`; do not pass it to `bind_player_cover` as an extra. **2.1 down-arrow hint** uses that same scene, rotated to point down, placed just above the live `ClassroomsInteractArea` (not a screen-edge pin, not a cover-fit extra). **1.4 right-arrow hint** uses that same scene, pointing right, pinned to the viewport right edge (same scale; not a cover-fit extra). Do not copy these hints into other rooms. Details: `AI_DOCS.md`.

**1.3 locker shelves (hub only):** flashlight, key, and name tag pictures on `ItemAnchor` (`scenes/ui/locker_shelves.gd`). No **LOCKER** button or overlay. Each picture stays hidden until that item is picked up. After a correct board answer, the name tag picture becomes that floor item's icon. The shovel is not on the locker. Drag `Flashlight`, `Key`, and `Nametag` in the 2D editor. Each picture has a `ClipPolygon`: inside the shape stays, outside is cut off, with a 1px edge (`locker_shelf_clip.gd`). Do not drag `ItemAnchor` — that node follows the picture. Combat items stay on the item wheel. Do not copy these pictures into other rooms. The school map drawing (`exports/Drawings/axel_map_v2.png`) is `ItemAnchor/Map`, a 4-point `Polygon2D`. With Map selected, use the viewport **Edit Points** tool and drag a corner to warp the picture. Do not add points, and do not move the UV points — that slides the picture inside the shape instead of bending the corners. In play, `locker_map_above_noir.gd` redraws that same polygon above the noir layer so the black fill and red lines stay as drawn. Hovering the paper lays a faint red tint on the drawing. The open map rocks slowly about 1 degree side to side. Clicking that paper opens `locker_map_overlay.gd` on CanvasLayer 110: a full-screen black rect at 75% opacity, the same drawing centered on top, and hover boxes (texture pixels in `AREAS`) that grow a little, fill red, and center the section name. The hover also lists that room's remaining floor items to the right of the highlight, and a small items_indicator sits on the highlight where the item is in the room drawing. A click travels only after a visit, plus one floor-item pickup when that room has items_indicators. Entrance loads `1.2` only after `1.4` has been visited. Before that, the Entrance click does nothing. A click on the room you opened the map from does nothing. The basement is not a travel button; its items_indicator is pinned on the right half of Entrance. `X` / Esc / Backspace / Delete closes the overlay and stays on the locker. Pause Map uses that same overlay on `1.3_SchoolMap`.

**1.4 chained door:** `[E]` on the center door loads grey-box `6.1_BasementDoor`. Returning from `6.1`/`6.2`/`6.3` uses spawn side `basement_door` and places the player on the live `DoorInteractArea`. Walking into right-edge `CafeteriaExitTrigger` loads `2.1` and peeks on `2.1`'s live `ReturnInteractArea` (`basement_left`). Coming back from `2.1` peeks on that same right trigger.

### Camera2D exports (`BackgroundCamera`)

| Export | Default | Purpose |
|--------|---------|---------|
| `background_path` | — | `NodePath` to `WalkableWorld/Background` |
| `fit_mode` | `cover` | `BackgroundLayout.FitMode` (`cover` or `contain`). Live: `static_locked` rooms always run **contain** (`effective_fit_mode()`), so the whole PNG shows — except that a static room with a follow target keeps its height on narrow screens (see Window resolution); this export only feeds the 1920×1280 cover baseline for `PlayerCoverSync` and movable-follow rooms |
| `camera_mode` | `static_locked` | Enable `movable_follow` only when pan is needed |
| `margin_px` | `0` | Inset art rect for CRT trim (often `12`; static edge-reveal rooms skip this auto-zoom path) |
| `edge_reveal` | `-1` | Only for `cover` layouts; ignored by `static_locked` rooms (they are contain) |
| `target_path` | — | Follow target |
| `background_y` | `0` | Vertical offset |
| `follow_smoothing` | `5` | Movable follow lerp |
| `max_auto_zoom` | `4` | Cap auto-zoom for small art |
| `static_center` | `(inf, inf)` | Ignored by `static_locked` contain rooms (the camera centers on the picture at zoom 1) |

### `_ready()` order

1. `bind_player_cover()` on `ExplorationRoom` (set `_OLD_BG_SCALE` on `_player_cover_sync` first for 1.1/1.2/1.4). That binds Mike, the PNG baseline, memory glow, and `layout_applied` → `sync_world_space`. Do **not** store a separate spawn constant.
2. Look up this room’s InteractAreas. Call_deferred restore / enter lines.
3. Layout via `BackgroundLayout.apply` (camera does this when `background_path` is set). `bind_player_cover()` already connected `layout_applied` — do not connect it a second time.

```gdscript
func _ready() -> void:
	bind_player_cover()
	# Then look up this room’s InteractAreas and call_deferred restore/enter lines.
```

### Background / camera helpers

- Layout: `scenes/core/background_layout.gd`
- Camera: `scenes/core/background_camera_controller.gd`
- Colliders: texture-pixel space under `WalkableWorld/EnvironmentColliders`
- Player: world space under `PlayerLayer` (instance `scenes/player/Player.tscn`). Do not rewire 1.1/1.2 off `PlayerLayer` without approval.
- Cover sync: `scenes/core/player_cover_sync.gd` — first layout uses the 1920×1280 (or legacy `_OLD_BG_SCALE`) baseline; later resizes keep the same Mike-vs-room ratio. 1.4 uses `_OLD_BG_SCALE` `0.352` on the 3508×2480 plate. Authored Mike there is `0.198` / `185.3`, the same as 1.2.
- Spawn: `scenes/core/player_spawn_sync.gd` — the Player node is the spawn. Capture with `env.to_local` **before** moving `EnvironmentColliders`, apply with `env.to_global` after. Do this on the **first** layout, not only later resizes. Regression: `scenes/core/test/player_spawn_sync_check.gd`.

### Rule: Mike walk sheet (12-cell)

Do not slice the raw `kävely_etu` / `kävely_sivu` drawings as a grid. Pack with `tools/pack_mike_walk_sheet.py` (ink-box cuts). Live look:

- Whole figure: inverted source ink (painted white in `kävely_*` becomes black holes — no extra fill plate). Eyes/scribble holes stay opaque. Head and body share the same charcoal invert — do not flatten chin-down to solid white.
- Empty around Mike: transparent.
- Packer drops far-off specks (`FAR_BLOB_DIST`) and extra islands under 120 px (stray waist/head strokes).
- `white_sprite.gdshader` keeps packed RGB and multiplies `COLOR.rgb` so `ShadowOutline` modulate can be black. Mike is **not** noir-inverted. CRT still runs on him. Play and the editor show `ShadowOutline` with the shared 1.2 fit (a slightly larger black copy behind the white figure) on every pose. Pose nudges must not shift that silhouette — `Player.gd` divides the shadow offset by the outline scale. Do not force `ShadowOutline.visible = false` in the editor tool.

`Player.gd` animations: `walk_down` / `walk_up` / `walk_right` + `flip_h` for left; idle / idle_back / idle_side keep last facing. Walk loop FPS is **5** (`animation_fps`, same as 1.2). Assign `res://assets/sprites/mike_sprite_frames.tres` in the editor. The old 13-frame sheet lives under `archive/2026-09-17/assets/sprites/` (Godot ignores that folder). Copy it out of archive onto the live sheet only if you need that rollback, then revert Player + scales.

### Rule: optional walk-position size ramp (2.4 only today)

`PlayerCoverSync` is window/cover-fit only. If a drawing has zooming perspective, a scene-local walk-through `Area2D` may multiply scale + speed **after** `PlayerCoverSync.apply()`. Live: `2.4` `VerticalSizeRampArea` (100% at cafeteria end → `@export vertical_far_scale` `1.5` at the corner; last size kept after leave). Do not put this in the shared cover-sync helper. Grow around the Player node, not the feet.

### Rule: do not retune Player `.tscn` scale for another computer

If Mike looks wrong vs the furniture **at 1920×1280**, change the authored scale in that scene. If he only looks wrong on a small Game tab / other monitor, the scaler is broken — fix `PlayerCoverSync`, not the scene number. Never edit Player `scale` to “match this window.”

### Rule: PlayerLayer extras share the cover ratio

`bind_player_cover()` sets `PlayerLayer/MemoryIndicator` to that room’s authored glow scale, then binds it to the cover ratio. Extra PlayerLayer nodes (not Mike, not the glow) use `bind_extra_node` + `apply`. Props under `EnvironmentColliders` (e.g. kitchen flashlight, 5.1 board glow) already follow `env.scale` — no second scaler.

### Rule: first-visit enter lines play once

Scene enter / discovery lines use a GameManager `*_seen` flag. They must not replay when returning from another room, a memory still, or a side peek. Same rule for every walkable scene.

### Rule: memory still leave (after the bar closes)

Still-image memories have no player and no `[E]` chip. After `_can_exit` (dialogue finished, or already-seen skip), leave with: red `[X]`, left-click, tap, or Tab/E/Space/Enter. Same keys during lines still skip/advance, and Esc does too. They must not leave until the bar is closed. Shared controller: `scenes/core/memory_still.gd`. Picture crop: `scenes/core/memory_frame.gd`. Live: `2.2`, `3.2`, `4.2`, `5.2` (desk keeps local shake).

### Rule: always measure the live dest box this Play

Door arrival is **not** a remembered `Vector2`. After cover-fit on **this** run, `InteractArrival` must read the dest `InteractArea` / `ExitTrigger` (`_area_rect_in_env` via `place_in_area` / `place_on_area` / `place_node_on_area_center`). That follows the shape as it is in the scene now — including editor drags since the last chat.

Applies to **every** room-to-room door, including `1.x` (`1.1`↔`1.2`, `1.2`↔`1.4`, `1.4`↔`2.1`), `2.1`→`2.3`, `2.1`↔`2.4`, `2.1`→`3.1`, and the other `[E]` pairs — unless the pair is a **hard spawn** listed below.

**Forbidden (this is how 2.4 landed at ~Y 815 instead of the live center ~5856×352):**

1. Copying texture coords from chat, changelog, or an earlier `.tscn` grep and treating them as the land point.
2. Skipping a re-read of the dest `.tscn` / live rect in *this* session (“I already know the box”).
3. Replacing a live-box land with `BOTTOM`/`TOP` + `resolve_inside_clearance` (or an extra peek-margin) because a TopWall drawing check failed — unless the user asked for that push.

`[E]` stays on the live `CollisionShape2D.global_position` (no extra chip offset unless asked). If the chip looks “off the door,” first check whether Mike was parked off the box.

**Hard spawns (leave these; they are not “re-derive from live center”):**

- Fresh Play / F6: the **Player node** (`PlayerSpawnSync`).
- Map / hub travel: Player node (no door box).
- Memory still return: saved standing spot.
- `2.3`→`2.1` kitchen: Player node X from live `KitchenInteractArea` `t`, texture Y `90` (`KITCHEN_STAND_TEX_Y`). Skip wall clamp.

Helper: `scenes/core/interact_arrival.gd`. Regression: `scenes/core/test/interact_arrival_check.gd`.

### Rule: room-to-room spawn maps along leave/arrive boxes

Use the live dest box (rule above). Then pick the **placement mode** for that pair — do not invent a new `Vector2`.

**Frozen peek (do not change the peek to “fix” others):** `1.2`→`1.4`, `1.4`→`2.1`, `2.1`→`2.3` — `place_on_area` on the **live** dest box, into-room past the short edge, then `clamp_hitbox_to_walls`. **Approved peek example:** `1.2`↔`1.4` `ExitTrigger`. Top of the leave box → top of the arrive box; bottom → bottom. Do **not** copy world Y, floor-line offsets, or scene size. Peek still measures the live shape every Play.

**`2.1`→`2.4` cafeteria door:** Player node (the model) on the live `CafeteriaInteractArea` center (`place_node_on_area_center`). Skip `resolve_inside_clearance`. Do not land Front-on-center — that pushes the walk drawing out the top of the PNG. **`2.4`→`2.1`:** Front on the live `ClassroomsInteractArea` center (`place_in_area` + `DEFAULT_T` + `CENTER_Y`); skip clearance. **`2.4`→`5.1` classroom door:** Player node on the live `DoorInteractArea` center (`place_node_on_area_center`); skip clearance. Leave-`t` on Y parked Front in `DoorWall` at the top-right. Do not hardcode coords.

**Other non-frozen `[E]` pairs:** save `GameManager.interact_arrival_t` (0 = top/left of the source box, 1 = bottom/right). Measure `t` from the Front hitbox in `EnvironmentColliders` texture space. Take `t` **once** on the destination (deferred restore after first layout, like `1.2`). On every `layout_applied`: always `PlayerSpawnSync` + cover-sync; if a door peek is still pending, `call_deferred` place — do **not** place-and-clear inside the first layout, and do **not** re-apply cover/depth after place. Map `t` onto the matching dest box with `apply_arrival_inside` (inset by Front radius; `t` on the long axis; `depth_frac` usually `0.5`), then `resolve_inside_clearance` so the walk drawing stays on the floor (may sit a little off the box if a wall overlaps — e.g. 4.1 vs TopWall). Live pairs on this mode: `1.1`→`1.2`, `2.1`↔`3.1`, `2.4`↔`4.1`. Missing `t` (hub/map) falls back to center (`0.5`).

### Rule: Player node is the spawn (mandatory)

There is no separate spawn point. The `Player` node **is** the spawn.

- Drag `PlayerLayer/Player` (instance of `scenes/player/Player.tscn`) on the drawing. That is where Mike starts a fresh Play / F6.
- **Forbidden:** hardcoded `env.to_global(Vector2(...))`, skipping the first cover-fit remap, teleporting default spawn onto a door / stones / interact shape, or storing a spawn constant that can go stale.
- **Allowed elsewhere:** only GameManager peek / return when arriving from another room. Arrival along a dest InteractArea / ExitTrigger (`interact_arrival_t`) may place off the Player node. Pause Map **X / Esc** is a tex restore (`pause_map_return_tex` + `PlayerSpawnSync.apply_tex`). A map travel click still uses the dest Player node and clears the pause-map path/tex.
- 1.1 intro may start off-screen and walk **to** the remapped Player node. Skip-intro leaves Mike on that node. Do not walk to a computed stones target instead. The first line plays to the end before the walk-away lines or Ending 1. After that line closes, the Moving lesson card opens once per save. Walking during that line does not start them. If Mike is already in the left exit when it ends, Ending 1 starts.
- Helper: `PlayerSpawnSync.capture_tex` before mutating `EnvironmentColliders`, then `apply_tex` after. Works for both unscaled (2.1-style) and pre-scaled (1.2/1.4 `_OLD_BG_SCALE`) colliders.
- Editor: assign `res://assets/sprites/mike_sprite_frames.tres` on `AnimatedSprite` / `ShadowOutline` so Mike is visible on the node while you drag. Play still rebuilds frames in `Player.gd`. Keep `ShadowOutline` visible in the editor (the pose-nudge tool must not force it off). `AnimatedSprite` stays hidden in the 2D view because the pose stack draws it.
- Shared hitbox (default): `CollisionFront` points at `res://scenes/player/hitbox_front.tres`. That `.tres` is **radius only**; node `position` is the shared 1.1 Front `(-37.812428, 126.04143)` on `Player.tscn`. Pose nudges line every facing onto this one circle. Walking left (A) mirrors Front X so the circle stays on the flipped side pose (right/D is the authored side). `Player.gd` reapplies Front on Play and removes `CollisionBack` / `CollisionSide` if they still exist. Instance `Player.tscn` so the editor preview matches. Do not recreate Back/Side.
- Alpha hitbox (opt-in): set `use_alpha_collision` on that Player. Select `Player` for the cyan editor preview of the traced outline.

### Rule: any other node placed against the background must spawn from its own editor position

Memory-indicator glows follow this pattern **inside** `memory_indicator.gd` (`capture_editor_tex` / `remap_to_env`). Do not copy `_memory_indicator_tex` into a room script. Any other node whose on-screen
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
`player.position`. Glow: instance `MemoryIndicator.tscn` and set `memory_key` /
`interact_area_path` (desk: `collected_bool_property`).

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
  `CollisionBack` / `CollisionSide`. That placement lives on `Player.tscn`.
  Do not zero it or invent a per-room player polygon.
- Shared exception — `ShadowOutline`: uses the 1.2 fit on every walkable room
  (`position` `(-5.0416956, -5.041732)`, `scale` `(1.0335996, 0.9969109)`).
  `Player.gd` reapplies this at Play and in the editor. The same fit is used
  for every spritesheet pose; pose-nudge `offset` is divided by that scale so
  Front / Back / Side do not shift the silhouette. That fit lives on
  `Player.tscn`. Do not invent a per-room silhouette.
- Memory glow: `MemoryIndicator.visual_offset` stays `Vector2.ZERO`. Align
  `MemoryInteractArea` to the same editor point as the glow node.
- `[E]` chip: `InteractPromptOverlay.screen_offset` stays `Vector2.ZERO`
  (shared default). Do not put a scene-wide override on the overlay node.
  Floor items do not use a second `[E]` chip. The walk-near card sits 10px
  under the painted items_indicator and carries `[E]` on its bottom-right line. Door
  chips may stay visible during dialogue.

Cover-fit remap (`env.to_global(_foo_tex)` from that node’s own editor
position) is **not** an offset. Child `position`, `visual_offset`, and
`screen_offset` **are** offsets — leave them zero unless the user asks for
one specific nudge (then scope it to that one zone/node).

### Rule: every CollisionShape2D is independent (mandatory)

Every `CollisionShape2D` must work as an individual. Editing one must never resize, scale, or move another.

**Why:** Godot stores the box/circle as a **shared** `Shape2D` resource. Duplicating a collider (a door, wall, or `[E]` zone) often leaves both nodes pointing at the same `SubResource`. Then changing size on `DoorSideRight` also changes `DoorSideLeft` — they look “linked.”

**Always:**

- Each `CollisionShape2D` gets its **own** `RectangleShape2D` / `CircleShape2D` / other `Shape2D`. No sharing.
- After you duplicate a collider in the editor: select the shape in the Inspector → **Make Unique**.
- In `.tscn` text: one `[sub_resource type="RectangleShape2D" id="..."]` per collider. Never two `shape = SubResource("same_id")` lines.

**Exception:** Mike’s `CollisionFront` is *meant* to share `res://scenes/player/hitbox_front.tres` across every room. Do not Make Unique that.

Door blockers belong under their own `StaticBody2D` (e.g. `LoungeDoorBlock` → `Lounge_CollisionShape2D`), not as orphan `CollisionShape2D` children of `EnvironmentColliders`.

Regression: `tools/qa/collision_shape_unique_check.gd` (`COLLISION_SHAPE_UNIQUE OK`).

### Rule: room-edge walls keep Mike's feet circle on the picture

The Front circle is what `move_and_slide` stops. Each edge wall's inner face must sit on or inside the PNG edge, so the circle never leaves the picture. The walk cell (`439×971`) plus `ShadowOutline` may stick past the edge: `AxelRoomEdge` paints black over everything outside the frame, so that overhang is hidden (changed in playtest batch E, 2026-10-12; growing walls by the whole drawing would cover doors and exits in most rooms). The checker still prints the full-drawing inset for reference.

- Keep `LeftWall` / `RightWall` / `TopWall` / `BottomWall` **inside the PNG edge**. Give each wall its own `RectangleShape2D` (Make Unique) so one edit does not resize the opposite wall.
- Skip walls that must stay open: 1.1 `LeftWall` (Ending 1), 1.2 `RightWall`, and 1.4 `LeftWall` / `RightWall` (walk-off). Skip 2.4 (already thickened in play). 2.4 `RightWall` is a `CollisionPolygon2D` on the slanted ink (top `(6902, 0)` to bottom `(6678, 4960)`, solid out to x `7016`) — do not turn it back into a vertical rectangle. `2.1`→`2.4` cafeteria arrival stands the Player node on the live box (skip clearance) so the model stays on the PNG. Do not thin walls that already pass.
- Furniture / door blockers are not this rule.

Live: 1.1 Top only; 1.2 / 1.4 / 2.1 / 2.3 / 3.1 / 4.1 / 5.1 edge walls that were too thin. Kitchen example: unique Left `200×2480` / Right `158×2480` / Top `3508×346` / Bottom `3508×193`. 3.1 after the 40% scale bump: Left `138×2480` / Right `132×2480` / Bottom `3508×162` (Top already thicker than required). 1.4 at Mike `0.198`: Top `3508×646` still passes. Right and Bottom inner faces were moved in so the smaller drawing stays on the PNG (Right inset about 148, Bottom about 182). `LeftWall` stays the walk-off. Those three 1.4 walls pass `tools/qa/wall_sprite_clearance_check.gd`.

### Rule: interact-prompt "[E]" chip has no offset by default

Same as the no-visual-offset rule above. `InteractPromptOverlay.gd`'s
`screen_offset` export defaults to `Vector2.ZERO` — the chip centers exactly
on the interact anchor (the `CollisionShape2D`'s `global_position`). Never
add a nudge (screen-space `screen_offset` override in a scene's `.tscn`, or
a world-space anchor offset in the scene script) as a blanket/default
choice. Only add one when explicitly asked for a specific interact point,
and scope it as narrowly as possible (`InteractSpot.prompt_visual_offset`,
or override `interact_anchor()` on `ExplorationRoom` — not the whole-scene
`screen_offset`, since one `InteractPromptOverlay` node is shared by every
interact zone in a scene).

After duplicating an InteractArea, reset the child’s `CollisionShape2D`
**position** to `(0, 0)` (or a small ink nudge). A leftover thousands-of-pixels
offset parks `[E]` on the source door. Live mistake: 2.4 ExtraDoor1/3 after
duplicating ExtraDoor3. ExtraDoor2’s small `(4, -116.5)` nudge is fine.

### QA smoke (new scenes)

After `_ready`, headless smoke MUST call:

- `QaCanonValidators.collect_background_camera_findings(root, scene_path)`
- `QaCanonValidators.collect_background_editor_lock_findings` (background must have `metadata/_edit_lock_`)

New walkable scenes `extends ExplorationRoom`, call `bind_player_cover()`, and instance `Player.tscn`. That wires `PlayerCoverSync` + `PlayerSpawnSync` (Player node, first layout included). Regression: `scenes/core/test/player_cover_sync_check.gd`, `scenes/core/test/player_walk_speed_check.gd`, `scenes/core/test/indicator_fit_check.gd`, `scenes/core/test/player_spawn_sync_check.gd`. Room-edge walls: `tools/qa/wall_sprite_clearance_check.gd`. Independent colliders: `tools/qa/collision_shape_unique_check.gd`.

### Playtest variants (optional)

Do not duplicate a walkable room into a second `.tscn` just to skip the intro. On live `1.1_SchoolExterior`, set Inspector `skip_intro`, or run with `AXEL_SKIP_INTRO=1`. The old inherited `1.1_SchoolExterior_Playtest.tscn` was moved to `archive/2026-09-17/scenes/Arc_1/` (Godot ignores that folder).

## Window resolution (project-wide)

- Base `1920×1280` (3:2) in `project.godot`. Stretch stays **disabled** (no letterbox / Keep-aspect canvas stretch — that shrank dialogue fonts).
- Game tab / OS window may be any size or aspect; `BackgroundCamera` cover-fits the PNG and recomputes on `size_changed`.
- Static-locked rooms use contain (playtest batch E): the whole picture is visible at any window shape, with dark bars where the shape differs from the PNG. **Narrow-screen exception (2026-10-13):** a static-locked room with a follow target (`target_path` set, `BackgroundCamera.keeps_height()`) never shrinks below its 1920×1280 size relative to the window height (`BackgroundLayout.apply(..., keep_height)`). On a window narrower than the PNG's shape, the room keeps its height, Mike keeps his size relative to the screen height, and the camera pans left and right with him (`_follow_x`). The whole picture still shows at 1.415:1 or wider for the 3508×2480 rooms and at 1.5:1 or wider for 1.2 (2400×1500); wider windows are unchanged. Rooms with no target (memory stills) stay whole. 1.2's camera targets Mike. `AxelWorld`'s item-placement probe uses the same fit. Regression: `tools/qa/narrow_zoom_check.gd`. Movable-follow rooms (1.1 / 2.4) stay on plain cover and scroll to the rest. Every non-combat scene uses the same dark edge: it starts at 0% opacity 3 px outside that scene’s background texture and reaches 80% opacity over the next 40 px. The TV curve is off so the edge is not mirrored. Combat stays flat.
- Mike, walls (`EnvironmentColliders`), and art share one cover scale via `PlayerCoverSync` from the 1920×1280 baseline (1.1/1.2: `_OLD_BG_SCALE`; 1.4: `0.352` room baseline; Mike is authored at `0.198` / `185.3`, same as 1.2).
- Exploration clear color in `project.godot` stays pure white so any exposed strip turns dark under the shipped noir/CRT stack instead of grey or red.
- `exploration_viewport.gd` is **inert** (kept so 1.1/1.2 still load).
- **Fixed-pixel UI chrome must self-scale.** Corner `X` buttons (hub / map / memory stills), the 1.3 map travel buttons, the `[E]` chip, and the pause scrim rescale from the live window height via `UiViewportScale.factor` (`scenes/core/ui_viewport_scale.gd`; authored baseline 1920×1280, clamp 0.5–2.5, times the player `ui_scale` setting). New chrome applies it in `_ready` **and** on `get_viewport().size_changed` (bound method, not a lambda, so the connection dies with the scene). `TopDialogueOverlay` keeps its own font scaling; the `ui_scale` setting composes into both. Without this, chrome authored in pixels turns unreadably small at 3840×2160 (stretch stays disabled per canon).

## Canonical filename invariant

Always target `<arc>.<index>_<Name>.tscn` (e.g. `1.2_Corridor.tscn`). Never create aliases like `Corridor.tscn`. Scenes live under `Arc_<N>/` (or `Endings/`, `Main_Menu/` for `7.x` / `0.x`).

## Background swap checklist (hand-drawn PNG)

**Naming:** `exports/Drawings/<sceneNumber>_<SceneName>.png` (e.g. `2.3_Kitchen.png`).

1. Drawing exists + `.import` generated; note texture uid. `process/size_limit` must stay `0` if colliders are authored on the PNG’s real pixels (2.4 was capped at `2048` and the cafeteria door sat off the room).
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
- Trees use a collision-front Y-gate (the trunk line): fade only when standing behind the trunk, not when overlapping the canopy from the front. Stump and rocks use each green polygon’s own lowest point, so a slanted front follows Mike’s feet. `RightWall_Behind` uses cutoff `1e9` (no Y-gate) so only the polygon matters. `RightWall_Behind` may include a `Roof_Behind` child polygon for the school roof (editor-placed). Shader: cutoff `> 1e8` means “allow,” not “off.” Extra `CollisionPolygon2D` children under one behind zone all count (max 4 per zone). Tree extras still use the nearest trunk collision as their front line. Stump and rock extras each use that polygon’s own lowest point. Furniture and yard behind zones (2.1 / 3.1 / 4.1 / 5.1 furniture 6–9) use that same polygon-front line, so standing in front of the green shape stays solid. 3.1’s wall still samples the fade at Mike’s feet, so his whole sprite fades above `TopWall` when his feet are inside the wall shape.
- Shader has 6 behind slots. Canon `feather_px = 2.0` on all behind zones (1.1 trees + wall + stump + rocks, 2.1 tables/chairs, 3.1 wall/bush/well, 4.1 table/chair/left cabinet, 5.1 furniture 6–9)

## What is walkable / shipped

Do not maintain a static “shipped list” here. Inspect live `scenes/Arc_*` and scene scripts for what is currently walkable vs placeholder. This file is how-to; the game tree is status.
