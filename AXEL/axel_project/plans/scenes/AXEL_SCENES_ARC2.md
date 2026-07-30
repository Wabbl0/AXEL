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


**Implemented (Godot):** `2.1_Cafeteria.tscn` + `2.1_Cafeteria.gd` — first Arc 2 walkable room: `PlayerLayer` (layer 100; authored scale `2.25`, speed `189.75`; spawn from editor `Player` position, or left peek when `cafeteria_spawn_side="basement_left"` from 1.4), `2.1_Cafeteria.png` cover-fit + locked background, `BackgroundCamera` `STATIC_LOCKED`/`COVER` with `margin_px=12` and `static_center=(960,0)` (top-biased so foodline/kitchen stay in frame), collider sync + `PlayerCoverSync` on `layout_applied`. Enter line once via `TopDialogueOverlay`. `[E]` zones: table → `2.2_CafeteriaMemory.tscn` (still placeholder), kitchen → `2.3_Kitchen.tscn` (walkable, shipped), left return → `1.4_BasementDoor.tscn` (`basement_spawn_side="cafeteria_right"`), right backyard → `3.1_Backyard.tscn` (`backyard_spawn_side="cafeteria_door"`; return peeks with `cafeteria_spawn_side="backyard_right"`), bottom classrooms → `2.4_ClassroomsCorridor.tscn` (`classrooms_corridor_spawn_side="cafeteria_door"`; return peeks with `cafeteria_spawn_side="classrooms_bottom"`). Hub 1.3 cafeteria button still loads 2.1 directly. Fade: `TableBlockLeft_Behind` / `ChairBlockBottom_Behind` / `ChairBlockTop_Behind`. `TableBlockLeft`/`Right` have separate rectangle shapes; `LeftDoorBlock` / `BackyardDoorBlock` / `ClassroomsDoorBlock` solid near their doors. No embedded post-FX. Tune wall/zone shapes in the editor if hotspots feel off.

**Memory indicator (test placement):** `PlayerLayer/MemoryIndicator` — instance of `scenes/fx/MemoryIndicator.tscn` (white/gray looping glow, see `AI_DOCS.md` → Memory indicator), visual marker only, no memory-collection logic wired. Spawns from its own editor position (texture-pixel space), same pattern as the Player spawn — captured into `_memory_indicator_tex` in `_ready()`, remapped via `env.to_global()` on every `layout_applied` (`_sync_memory_indicator()` in `2.1_Cafeteria.gd`). Drag `PlayerLayer/MemoryIndicator` in the editor to move it; it no longer snaps onto `TableInteractArea`'s shape. The `[E]` chip over this same zone has no offset (centers on `TableInteractArea`'s shape) — `2.1_Cafeteria`'s `InteractPromptOverlay.screen_offset` is left at the default `Vector2.ZERO` on purpose (see `SCENE_BUILDING.md` → "chip has no offset by default"); only add a nudge back if explicitly asked.

---



### 2.2 Cafeteria Memory (`loc_cafeteria_memory`)

**Location label:** `CAFETERIA`
*(Memory — glitch flash on enter, no interaction area)*

**Dialogue:**

> AXEL: "Do you think I'm a bad person?"
>
> [beat]
>
> You answer, "No."
>
> [beat]
>
> "I just - don't have the energy. To be around you."
>
> [beat]
>
> "Sorry."
>
> AXEL: "Oh," they sigh.
>
> [beat]
>
> AXEL: "No. I understand."

**Choices:**


| Button label | Target    |
| ------------ | --------- |
| Go back      | Cafeteria |


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


**Implemented (Godot):** `2.3_Kitchen.tscn` + `2.3_Kitchen.gd` — walkable kitchen with `2.3_Kitchen.png` (`STATIC_LOCKED`/`COVER`, `margin_px=12`, `static_center=(560,0)`), `PlayerLayer` scale `3.0` / speed `253.4`, collider sync + `PlayerCoverSync` on `layout_applied`. Enter line once via `GameManager.kitchen_enter_line_seen`. Flashlight pickup is **in-room** (no `2.4_KitchenFlashlightPickup.tscn`). Door `[E]` → `2.1_Cafeteria.tscn` with `kitchen_spawn_side="kitchen_door"`. Single static background art (no dark→lit swap). No embedded post-FX. Spawn point always matches wherever `PlayerLayer/Player` is placed in the editor (same pattern as 2.1 Cafeteria) — drag that node to move the spawn, no hardcoded constant.

**Real hand-drawn background (replaces flat placeholder):** `2.3_Kitchen.png` is now the actual hand-drawn art (3508×2480, was a flat placeholder at 2400×1500) — same filename, re-imported in place. All debug placeholder visuals (`Polygon2D`/`Line2D`/`Label` boxes for prep table, center table, fridge, shelves, door, flashlight) are removed. Room walls (`TopWall`/`BottomWall`/`LeftWall`/`RightWall`) resized to the new texture bounds. Exactly 3 furniture colliders kept, positions measured from the art (texture-pixel space): `TableBlock` (2175, 1832), `RightShelvesBlock` (3284, 935), `TopLeftShelvesBlock` (645, 250). The new art does not draw a door, fridge, or flashlight, so those functional zones were placed at sensible open-floor spots rather than removed: `DoorWall`/`DoorInteractArea` on the right wall between the shelves and stove (~3300–3460, 1740), `FlashlightInteractArea` near the top-left shelf (550, 550); the `Player` node's editor position (texture-pixel space) is the spawn point, currently placed next to the door. Re-tune any of these in the editor if they feel off against the final art; no dialogue/camera/gameplay-logic changes.

---



### 2.4 Classrooms Corridor (connector)

**Implemented (Godot) — shell only:** `2.4_ClassroomsCorridor.tscn` + `.gd` — L-shaped connector (flat placeholder `2.4_ClassroomsCorridor.png`). `BackgroundCamera` `MOVABLE_FOLLOW`/`COVER` with `margin_px=12` following `PlayerLayer/Player` (Kitchen profile scale `3.0` / speed `253.4`). Live doors: top → Cafeteria, opposite (bottom of vertical arm) → Teachers' Lounge, far left end → Classroom. `Future_1_2_Door` is drawn-only (no Area2D / no interact) reserved for a later loop-around link to `1.2_Corridor` — **do not wire without approval** (`1.2` is legacy). Spawn-side peeks via `classrooms_corridor_spawn_side`. No enter line. Not arc-complete content.

---

