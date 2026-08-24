# AXEL — Scene Dialogues: Arc 2 — Cafeteria

> Dialogue under each scene is locked canon (rewrites). Do not restore old HTML prototype SOURCE text.

---

### 2.1 Cafeteria (`loc_cafeteria`)

**Location label:** `CAFETERIA`

**Dialogue:**

> Even through all the chaos you can hear the chattering students of the past.

**Choices:**


| Button label        | Target           |
| ------------------- | ---------------- |
| Approach Your table | Cafeteria Memory |
| Search the kitchen  | Kitchen          |
| Return to locker    | Locker Hub       |


**Implemented (Godot):** `2.1_Cafeteria.tscn` + `2.1_Cafeteria.gd` — first Arc 2 walkable room: `PlayerLayer` (layer 100; authored scale `0.198347`, speed `189.75`; spawn from editor `Player` position, or left peek when `cafeteria_spawn_side="basement_left"` from 1.4), `2.1_Cafeteria.png` cover-fit + locked background, `BackgroundCamera` `STATIC_LOCKED`/`COVER` with `margin_px=12` and `static_center=(960,0)` (top-biased so foodline/kitchen stay in frame), collider sync + `PlayerCoverSync` on `layout_applied`. Enter line once via `GameManager.cafeteria_enter_line_seen` + `TopDialogueOverlay` (does not replay after 2.2 memory or other returns). `[E]` zones: table → `2.2_CafeteriaMemory.tscn` (drawn memory still; saves exact standing spot in texture-pixel space as transient `cafeteria_table_return_pos` and restores it on return — not the table-zone center), kitchen → `2.3_Kitchen.tscn` (`KitchenInteractArea` at texture-pixel `(3000, 880)` — 220px higher than the old `1100`), left return → `1.4_BasementDoor.tscn` (`basement_spawn_side="cafeteria_right"`), right backyard → `3.1_Backyard.tscn` (`backyard_spawn_side="cafeteria_door"`; return peeks with `cafeteria_spawn_side="backyard_right"`), bottom classrooms → `2.4_ClassroomsCorridor.tscn` (`classrooms_corridor_spawn_side="cafeteria_door"`; return peeks with `cafeteria_spawn_side="classrooms_bottom"`). Hub 1.3 cafeteria button still loads 2.1 directly. Fade: `TableBlockLeft_Behind` / `ChairBlockBottom_Behind` / `ChairBlockTop_Behind`. `TableBlockLeft`/`Right` have separate rectangle shapes; `LeftDoorBlock` / `BackyardDoorBlock` / `ClassroomsDoorBlock` solid near their doors. No embedded post-FX. Tune wall/zone shapes in the editor if hotspots feel off.

**Memory indicator:** `PlayerLayer/MemoryIndicator` — instance of `scenes/fx/MemoryIndicator.tscn` (white/gray looping glow, see `AI_DOCS.md` → Memory indicator). Spawns from its own editor position (texture-pixel space), same pattern as the Player spawn — captured into `_memory_indicator_tex` in `_ready()`, remapped via `env.to_global()` on every `layout_applied` (`_sync_memory_indicator()` in `2.1_Cafeteria.gd`). After a successful 2.2 visit, `GameManager.add_memory_once("cafeteria_memory")` collects it (counts toward 5/5); 2.1 then hides the glow and disables `TableInteractArea` so table `[E]` is gone. Debug builds skip save load, so the glow returns each editor run. Drag `PlayerLayer/MemoryIndicator` in the editor to move it; it no longer snaps onto `TableInteractArea`'s shape. The `[E]` chip over this same zone has no offset (centers on `TableInteractArea`'s shape) — `2.1_Cafeteria`'s `InteractPromptOverlay.screen_offset` is left at the default `Vector2.ZERO` on purpose (see `SCENE_BUILDING.md` → "chip has no offset by default"); only add a nudge back if explicitly asked.

---



### 2.2 Cafeteria Memory (`loc_cafeteria_memory`)

**Location label:** `CAFETERIA`
*(Memory — glitch flash on enter, no interaction area)*

**Dialogue:**

> AXEL: Do you think I'm a bad person?
>
> [beat]
>
> No.
>
> [beat]
>
> I just   
> [beat]  
> don't have the energy. To be around you.
>
> [beat]
>
> Sorry.
>
> AXEL: Oh.
>
> [beat]
>
> AXEL: No. I understand.

**Choices:**


| Button label | Target    |
| ------------ | --------- |
| Go back      | Cafeteria |


**Implemented (Godot):** `2.2_CafeteriaMemory.tscn` + `.gd` — still-image memory (no player / no interact chip). Hand-drawn `2.2_Cafeteria_Memory.png` runtime top-crop to 1.85:1 (`region_rect`), locked background (`STATIC_LOCKED`/`CONTAIN`, `max_auto_zoom=1`, `margin_px=12`), then fitted large in the space above the dialogue bar (small side margins, some black at top and just above the bar). No overlay letterbox bars; world-space white void fill so post-FX empty areas stay dark, not red. Spoken lines match the rewrite above (no wrapping quotes or action tags; mid-line `|beat:1.5|` on the energy line). Canon lines play once via `GameManager.cafeteria_memory_line_seen`. Axel’s lines omit the on-screen `AXEL:` tag (`|other|`) and type in bright red; player/narration stays white. After the bar fully closes, a red `[X]` on CanvasLayer 110 (same hub chrome as 1.3), **left-click / tap**, or **Tab / E / Space / Enter** return to `2.1_Cafeteria.tscn` at the saved standing spot. Leave is gated until `_can_exit` (dialogue finished). On leave, `add_memory_once("cafeteria_memory")`. Art was already red-on-black; converted to white fill + black ink so 8-band noir shows production reds. No embedded post-FX.

---



### 2.3 Kitchen (`loc_kitchen`)

**Location label:** `KITCHEN`

**Enter dialogue:**

> Everything is rotten here. Everything.
>
> [beat]
>
> This includes you.

**Flashlight pickup dialogue** *(in-room* `[E]` *zone — no separate 2.4 scene):*

> Let there be light!

**Choices / interactions:**


| Action                                | Target / result                                                                            |
| ------------------------------------- | ------------------------------------------------------------------------------------------ |
| Door `[E]`                            | Return to Cafeteria                                                                        |
| Flashlight `[E]` (once, if not owned) | Set `hasFlashlight`, add Flashlight to inventory, play pickup line, hide flashlight visual |


**Implemented (Godot):** `2.3_Kitchen.tscn` + `2.3_Kitchen.gd` — walkable kitchen with `2.3_Kitchen.png` (`STATIC_LOCKED`/`COVER`, `margin_px=12`, `static_center=(560,0)`), `PlayerLayer` scale `0.330579` / speed `253.4`, collider sync + `PlayerCoverSync` on `layout_applied`. Enter line once via `GameManager.kitchen_enter_line_seen`. Flashlight pickup is **in-room** (no `2.4_KitchenFlashlightPickup.tscn`). World-space `FlashlightVisual` (`exports/Drawings/Flashlight.png`) sits on the interact zone with a faint ink-halo glow (`prop_ink_halo.gdshader`); both go through the global noir stack (not above it). Pickup hides the drawing immediately. Door `[E]` → `2.1_Cafeteria.tscn` with `kitchen_spawn_side="kitchen_door"`. Single static background art (no dark→lit swap). No embedded post-FX. Spawn point always matches wherever `PlayerLayer/Player` is placed in the editor (same pattern as 2.1 Cafeteria) — drag that node to move the spawn, no hardcoded constant.

**Real hand-drawn background (replaces flat placeholder):** `2.3_Kitchen.png` is now the actual hand-drawn art (3508×2480, was a flat placeholder at 2400×1500) — same filename, re-imported in place. All debug placeholder visuals (`Polygon2D`/`Line2D`/`Label` boxes for prep table, center table, fridge, shelves, door, flashlight) are removed. Room walls (`TopWall`/`BottomWall`/`LeftWall`/`RightWall`) resized to the new texture bounds. Exactly 3 furniture colliders kept, positions measured from the art (texture-pixel space): `TableBlock` (2175, 1832), `RightShelvesBlock` (3284, 935), `TopLeftShelvesBlock` (645, 250). The new art does not draw a door, fridge, or flashlight, so those functional zones were placed at sensible open-floor spots rather than removed: `DoorWall`/`DoorInteractArea` on the right wall between the shelves and stove (~3300–3460, 1740), `FlashlightInteractArea` near the top-left shelf (550, 550); the `Player` node's editor position (texture-pixel space) is the spawn point, currently placed next to the door. Re-tune any of these in the editor if they feel off against the final art; no dialogue/camera/gameplay-logic changes.

---



### 2.4 Classrooms Corridor (connector)

**Implemented (Godot) — shell only:** `2.4_ClassroomsCorridor.tscn` + `.gd` — L-shaped connector with hand-drawn `2.4_ClassroomsCorridor.png` (7016×4960, white fill + black ink). `BackgroundCamera` `MOVABLE_FOLLOW`/`COVER` with `margin_px=12` following `PlayerLayer/Player` (authored scale `0.198347` / speed `253.4`, cover-synced). **Vertical-leg size ramp:** `VerticalSizeRampArea` under `EnvironmentColliders` (texture-pixel box on the first vertical arm). While Mike is inside, an extra multiplier lerps from 100% at the top to `@export vertical_far_scale` (default `1.5`) at the bottom; after leave, last size is kept. Applied after every `PlayerCoverSync.apply()` (picture + hitbox + walk speed); `authored_*` untouched. Spawn seeds: fresh Play / cafeteria → 100%; lounge / classroom → 150%. Live doors: top of the vertical arm → Cafeteria, bottom of the vertical arm → Teachers' Lounge, left door on the south wall of the horizontal arm → Classroom (return peek is above that door). The far-left stub `FutureDoorInteractArea` (`"Not yet."`) is reserved for a later loop-around link to `1.2_Corridor` — **do not wire a real transition without approval** (`1.2` is legacy). Three extra drawn doors are line-only stubs: south-wall door between future and classroom (`"Try the next one."`), east-wall door between lounge and cafeteria (`"No, the next one."`), north-end door right of cafeteria (`"You missed it."`). Placeholder `Line2D`/`Polygon2D` visuals removed. Spawn-side peeks via `classrooms_corridor_spawn_side`. Editor `Player` position is the default spawn. `InteractPromptOverlay` uses the shared zero `screen_offset` default. No enter line. Not arc-complete content. Re-tune wall/door/ramp shapes in the editor if they sit off the ink.

---

