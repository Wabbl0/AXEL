# AXEL — Scene Dialogues: Arc 1 — Intro & Hub

> **How to use this file**
> Dialogue under each scene is locked canon (rewrites). Do not restore old HTML prototype SOURCE text.
> Blank lines marked `TODO: write line` still need authoring.

---

### 1.1 School Exterior (`start`)

**Location label:** *(empty)*

**Dialogue:**

> You promised, you'd never come back.  
> [beat]  
> Yet, here we are.  
> [beat]  
> Pathetic.

**Choices:**


| Button label | Target   |
| ------------ | -------- |
| Walk inside  | Corridor |
| Turn away    | Ending 1 |


**Implemented (Godot):** `1.1_SchoolExterior.tscn` + `.gd` — walkable start (`extends ExplorationRoom`, `_use_default_interact_loop = false` for the intro; Player is `scenes/player/Player.tscn`). Default spawn is the `Player` node (`PlayerSpawnSync`; skip-intro and the intro walk-in both use that node, not the stones; live stand is a bit above the left rocks so the new hitbox does not snag). Door `[E]` → Corridor (`1.2`) with `corridor_spawn_side="exterior_door"` and `interact_arrival_t` mapped along the door. After the intro, the left road stays open; left-edge `ExitTrigger` → Ending 1 (`7.1_Ending1.tscn`). Return from 1.2 peeks at the school doors via `exterior_spawn_side="corridor_door"` (skips intro; arrival uses `InteractArrival` along the door polygon). Behind fade zones `TreeLine_Bottom_Behind` / `TreeLine_Top_Behind` / `RightWall_Behind` / `Stump_Left_Behind` / `Rocks_Left_Behind` / `Rocks_Right_Behind` (`feather_px = 2`). Trees use a collision-front Y-gate (opaque in front of the trunk). Stump and rocks fade from each green polygon’s own front, so a slanted edge follows Mike’s feet. The right wall fades only inside its polygon. Layout details: `SCENE_BUILDING.md` (legacy Arc 1). No embedded post-FX.

---

### 1.2 Corridor (`scene_2`)

**Location label:** `CORRIDOR`

**Dialogue:**

> Even after all these years the smell is the same. They must've used some really toxic paint.  
> [beat]  
> This was your locker.

**Choices:**


| Button label      | Target           |
| ----------------- | ---------------- |
| Go to your locker | Locker Hub       |
| Return outside    | School Exterior  |


**Implemented (Godot):** `1.2_Corridor.tscn` + `1.2_Corridor.gd` — walkable corridor (`extends ExplorationRoom`, `_use_default_interact_loop = false` for locker/arrow; Player is `Player.tscn`; `STATIC_LOCKED`/`COVER`); default spawn is the `Player` node on first cover-fit (`PlayerSpawnSync`); locker `[E]` zone → `1.3_LockerHub.tscn`; left-edge `ExteriorInteractArea` `[E]` at spawn → `1.1_SchoolExterior.tscn` (`exterior_spawn_side="corridor_door"`; `interact_arrival_t` along the interact box); return from 1.1 lands **inside** `ExteriorInteractArea` (`corridor_spawn_side="exterior_door"`; `apply_arrival_inside`, t on Y — top of 1.1’s door box → top of 1.2’s box). Right-edge `ExitTrigger` → `1.4_BasementDoor.tscn` (`basement_spawn_side="corridor_left"`; arrival height maps along each `ExitTrigger` via `interact_arrival_t` + `InteractArrival` — not floor-line world Y). Once-ever smell + locker lines via `GameManager`. No embedded post-FX.

---

### 1.3 Locker Hub (`scene_3`)

**Location label:** none (locker view only)

**Dialogue:**

> Oh look, a map of the school.  
> [beat]  
> Was your memory so bad you needed a map of the school?

**Hub:** map paper opens the locker map overlay. A highlighted room travels only after you have walked there and, if that room has floor items, picked up at least one. Red `X` (CanvasLayer 110, above CRT), Esc, Backspace, or Delete returns to the corridor when the map is closed.

**School map:** pause Map opens the same overlay (`1.3_SchoolMap`). The button stays grey until the locker map lines (`scene_3`) have played. `X` / Esc returns Mike to the saved spot. A travel click uses that room's Player node. The basement is not a button on this map.

**Implemented (Godot):** `1.3_LockerHub.tscn` + `1.3_LockerHub.gd` — locker background only; `ItemAnchor/Map` is a 4-point `Polygon2D` of `exports/Drawings/axel_map_v2.png` (drag corners with Edit Points to warp it); the flashlight, key, and name tag sit on the locker picture (`locker_shelves.gd`); each stays hidden until that item is picked up; the shovel is not shown here; after a correct board answer the name tag picture becomes that floor item's icon; combat items stay on the item wheel; no **LOCKER** button or overlay. **Place the pictures:** drag `LockerShelves/ItemAnchor/Flashlight`, `Key`, and `Nametag`. `MapHotspot` (`UiPolygonHotspot`, `background_path = ../Background`) on the MAP paper opens the map overlay on the locker (clicks ignored during first-visit dialogue): full-screen black at 75% opacity, the map drawing centered, hover fills that grow a little, with the name centered, for Entrance, Cafeteria, Kitchen, Backyard, Teachers' Lounge, Classroom, and Hallway. Hovering also lists that room's remaining floor items to the right and places a small pointing hand where the item sits in the room. A click travels only after a visit, plus one pickup when the room has floor items. Entrance travels after a visit. Hallway is `2.4`. Overlay `X` / Esc / Backspace / Delete closes it and stays on the locker. Locker red `X` on CanvasLayer 110, Esc, Backspace, or Delete exits to corridor when the overlay is closed. Pause Map opens the same overlay. Its `X` / Esc returns to the saved spot; a travel click uses the dest Player node. The basement is not on this map. Reachable from `1.2_Corridor.tscn` locker interact zone. First-visit lines use `TopDialogueOverlay.show_lines()`; player can skip with click / E / Space / Enter while the bar is up (`CrtPowerFx.cancel()` on skip — no session freeze). **Tune map hit area:** `MapHotspot/PolygonAnchor/CollisionPolygon2D` vertex handles in texture-pixel space.


---

### 1.4 Basement Door — walkable gate (`basement_door`)

**Location label:** `BASEMENT`

**Dialogue:**

> Not yet.

**Implemented (Godot):** `1.4_BasementDoor.tscn` + `1.4_BasementDoor.gd` — walkable room (`extends ExplorationRoom`, default `[E]` loop; Player is `Player.tscn`) with `exports/Drawings/1.4_BasementDoor_v2.png` (**3508×2480**, white fill + black ink; `STATIC_LOCKED`/`COVER`, shared `edge_reveal` so wide monitors show a thin white strip the CRT darkens, `margin_px=12` to hide CRT red fringe, `static_center=(560, 0)`; no `RoomOutline` line). Mike authored scale `0.198` / speed `185.3` (same as 1.2), with `_OLD_BG_SCALE` `0.352` kept as the room baseline. Default spawn is the `Player` node (`PlayerSpawnSync`); no hardcoded spawn `Vector2`. `AnimatedSprite` position stays `(0, 0)`; pose nudge is `AnimatedSprite.offset` from shared `pose_nudge.tres`. One `CollisionFront` at the shared 1.1 Front placement (left-walk mirrors X). `ShadowOutline` uses the shared 1.2 silhouette fit. The chained door and floor line are in the drawing (no extra door polygon or floor `Line2D`). `FloorDividerWall` sits on the ink line (texture y `1504`). `[E]` near the chained door plays `"Not yet."` and stays in the room (do not load a grey-box basement scene; bar still up → skip/advance only; `basement_door_line_seen` saved but not an interact gate). Left-edge `ExitTrigger` auto-return to `1.2_Corridor.tscn` with right-edge peek spawn (`corridor_spawn_side="basement_right"`; arrival height maps along each `ExitTrigger` via `interact_arrival_t` + `InteractArrival` — not floor-line world Y). Right-edge `CafeteriaInteractArea` `[E]` → `2.1_Cafeteria.tscn` (`cafeteria_spawn_side="basement_left"`; return from cafeteria peeks on 1.4 right via `basement_spawn_side="cafeteria_right"`; arrival height maps along each InteractArea via `interact_arrival_t` + `InteractArrival` then hitbox clamp — not absolute world Y; `RightWall` moved like 1.2). Reachable from `1.2_Corridor.tscn` right-edge `ExitTrigger` (approved `RightWall` move). No embedded post-FX.

---
