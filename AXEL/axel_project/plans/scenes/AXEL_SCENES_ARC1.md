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


**Implemented (Godot):** `1.1_SchoolExterior.tscn` + `.gd` — walkable start. Default spawn is the `Player` node (`PlayerSpawnSync`; skip-intro and the intro walk-in both use that node, not the stones; live stand is a bit above the left rocks so the new hitbox does not snag). Door `[E]` → Corridor (`1.2`) with `corridor_spawn_side="exterior_door"` and `interact_arrival_t` mapped along the door. After the intro, the left road stays open; left-edge `ExitTrigger` → Ending 1 (`7.1_Ending1.tscn`). Return from 1.2 peeks at the school doors via `exterior_spawn_side="corridor_door"` (skips intro; arrival uses `InteractArrival` along the door polygon). Behind fade zones `TreeLine_Bottom_Behind` / `TreeLine_Top_Behind` / `RightWall_Behind` / `Stump_Left_Behind` / `Rocks_Left_Behind` / `Rocks_Right_Behind` (`feather_px = 2`). Trees / stump / rocks use a collision-front Y-gate (opaque from the front); wall fades only inside its polygon. Layout details: `SCENE_BUILDING.md` (legacy Arc 1). No embedded post-FX.

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


**Implemented (Godot):** `1.2_Corridor.tscn` + `1.2_Corridor.gd` — walkable corridor (`STATIC_LOCKED`/`COVER`); default spawn is the `Player` node on first cover-fit (`PlayerSpawnSync`); locker `[E]` zone → `1.3_LockerHub.tscn`; left-edge `ExteriorInteractArea` `[E]` at spawn → `1.1_SchoolExterior.tscn` (`exterior_spawn_side="corridor_door"`; `interact_arrival_t` along the interact box); return from 1.1 peeks on `ExteriorInteractArea` via `corridor_spawn_side="exterior_door"`. Right-edge `ExitTrigger` → `1.4_BasementDoor.tscn` (`basement_spawn_side="corridor_left"`; arrival height maps along each `ExitTrigger` via `interact_arrival_t` + `InteractArrival` — not floor-line world Y). Once-ever smell + locker lines via `GameManager`. No embedded post-FX.

---

### 1.3 Locker Hub (`scene_3`)

**Location label:** none (locker view only)

**Dialogue:**

> Oh look, a map of the school.  
> [beat]  
> Was your memory so bad you needed a map of the school?

**Hub:** no travel menu. Map paper hotspot opens `1.3_SchoolMap.tscn`. Red `X` (CanvasLayer 110, above CRT) returns to corridor.

**School map (`1.3_SchoolMap`) choices:**


| Button label                       | Target                           |
| ----------------------------------- | -------------------------------- |
| Go to the cafeteria                | Cafeteria                        |
| Go to the classroom                | Classroom                        |
| Go to the backyard                 | Backyard                         |
| Go to the teacher's lounge         | Teachers' Lounge                 |
| ENTER THE BASEMENT *(red, locked)* | Basement Blocked / Basement Door |

**Implemented (Godot):** `1.3_LockerHub.tscn` + `1.3_LockerHub.gd` — locker background only; `MapHotspot` (`UiPolygonHotspot`, `background_path = ../Background`) on the MAP paper → `change_scene_to_file` to `1.3_SchoolMap.tscn` (clicks ignored during first-visit dialogue); red `X` on CanvasLayer 110 exits to corridor. `1.3_SchoolMap.tscn` + `.gd` — flat black placeholder background; bottom-left travel choices (four destinations + locked red basement); red `X` on CanvasLayer 110 returns to locker hub. Reachable from `1.2_Corridor.tscn` locker interact zone. First-visit lines use `TopDialogueOverlay.show_lines()`; player can skip with click / E / Space / Enter while the bar is up (`CrtPowerFx.cancel()` on skip — no session freeze). **Tune map hit area:** `MapHotspot/PolygonAnchor/CollisionPolygon2D` vertex handles in texture-pixel space.


---

### 1.4 Basement Door — walkable gate (`basement_door`)

**Location label:** `BASEMENT`

**Dialogue:**

> Not yet.

**Implemented (Godot):** `1.4_BasementDoor.tscn` + `1.4_BasementDoor.gd` — walkable room with `exports/Drawings/1.4_BasementDoor.png` (same **2400×1500** as `1.2_Corridor.png`; `STATIC_LOCKED`/`COVER`, `margin_px=12` to hide CRT red fringe; no `RoomOutline` line). Mike authored scale `0.198` / speed `185.3` matching 1.2, with 1.2’s `_OLD_BG_SCALE` `0.546` so on-screen size matches the corridor. Default spawn is the `Player` node (`PlayerSpawnSync`); no hardcoded spawn `Vector2`. `AnimatedSprite` position stays `(0, 0)`; pose nudge is `AnimatedSprite.offset` from shared `pose_nudge.tres`. One `CollisionFront` at the shared 1.1 Front placement (left-walk mirrors X). `ShadowOutline` uses the shared 1.2 silhouette fit. Chained-door placeholder: grey `DoorWall` poly hidden, `DoorBody` black, `DoorVisuals` `z_index=10` so chains show through noir. Floor/wall divider aligned toward 1.2’s floor junction (`FloorDividerLine` y `790`). `[E]` near door plays `"Not yet."` when the dialogue bar is closed (bar still up → skip/advance only; `basement_door_line_seen` saved but not an interact gate). Left-edge `ExitTrigger` auto-return to `1.2_Corridor.tscn` with right-edge peek spawn (`corridor_spawn_side="basement_right"`; arrival height maps along each `ExitTrigger` via `interact_arrival_t` + `InteractArrival` — not floor-line world Y). Right-edge `CafeteriaInteractArea` `[E]` → `2.1_Cafeteria.tscn` (`cafeteria_spawn_side="basement_left"`; return from cafeteria peeks on 1.4 right via `basement_spawn_side="cafeteria_right"`; arrival height maps along each InteractArea via `interact_arrival_t` + `InteractArrival` then hitbox clamp — not absolute world Y; `RightWall` moved like 1.2). Reachable from `1.2_Corridor.tscn` right-edge `ExitTrigger` (approved `RightWall` move). No embedded post-FX.

---
