# AXEL — Scene Dialogues: Arc 1 — Intro & Hub

> **How to use this file**
> Every line marked **[SOURCE]** is the exact original text extracted directly from `game.html`.
> Lines marked **[REWRITE]** are your cue to replace that text with your own version.
> Leave a line blank under **[REWRITE]** until you're ready to fill it in.
> Once you're happy with a scene, remove the tag entirely — that means it's locked.

---

### 1.1 School Exterior (`start`)

**Location label:** *(empty)*

**Dialogue [SOURCE]:**

> You stand before the rotting wooden school building. The sky is grey. You feel a jolt in your chest, your GUILT lies here. You've come to finish what was left undone years ago.

**[REWRITE]:**

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


---

### 1.2 Corridor (`scene_2`)

**Location label:** `CORRIDOR`

**Dialogue [SOURCE]:**

> You step inside. The smell hits you—a mix of mold and old floor cleaner. The past is leaking into the present. You remember that your locker is at the end of the hallway.

**[REWRITE]:**

> Even after all these years the smell is the same. They must've used some really toxic paint.  
> [beat]  
> This was your locker.

**Choices:**


| Button label      | Target     |
| ----------------- | ---------- |
| Go to your locker | Locker Hub |
| Turn away         | Ending 1   |


**Implemented (Godot):** `1.2_Corridor.tscn` + `1.2_Corridor.gd` — walkable corridor (`STATIC_LOCKED`/`COVER`); locker `[E]` zone → `1.3_LockerHub.tscn`; right-edge `ExitTrigger` → `1.4_BasementDoor.tscn`; return position saved as `corridor_return_pos`. Once-ever smell + locker lines via `GameManager`. No embedded post-FX.

---

### 1.3 Locker Hub (`scene_3`)

**Location label:** `YOUR LOCKER`

**Dialogue [SOURCE]:**

> You are in your sanctuary. There's a picture of the two of you on the locker door. The map shows four circled locations. The basement entrance has been blacked out.

**[REWRITE]:**

> Oh look, a map of the school.  
> [beat]  
> Was your memory so bad you needed a map of the school?

**Choices:**


| Button label                       | Target                           |
| ----------------------------------- | -------------------------------- |
| Go to the cafeteria                | Cafeteria                        |
| Go to the classroom                | Classroom                        |
| Go to the backyard                 | Backyard                         |
| Go to the teacher's lounge         | Teachers' Lounge                 |
| ENTER THE BASEMENT *(red, locked)* | Basement Blocked / Basement Door |

**Implemented (Godot):** `1.3_LockerHub.tscn` + `1.3_LockerHub.gd` — four destinations above (basement omitted); `MapHotspot` (`UiPolygonHotspot`, `background_path = ../Background`) on the MAP paper → swaps background to `map.png` (hover tint + click only inside polygon; clicks ignored during first-visit dialogue); red `X` exit to corridor. Reachable from `1.2_Corridor.tscn` locker interact zone. First-visit lines use `TopDialogueOverlay.show_line()`; player can skip with click / E / Space / Enter while the bar is up (`CrtPowerFx.cancel()` on skip — no session freeze). **Tune map hit area:** `MapHotspot/PolygonAnchor/CollisionPolygon2D` vertex handles in texture-pixel space.


---

### 1.4 Basement Door — walkable gate (`basement_door`)

**Location label:** `BASEMENT`

**Dialogue [SOURCE]:**

> The basement is sealed off for now. Come back later.

**[REWRITE]:**

> Not yet.

**Implemented (Godot):** `1.4_BasementDoor.tscn` + `1.4_BasementDoor.gd` — walkable room with `exports/Drawings/1.4_BasementDoor.png` (`STATIC_LOCKED`/`COVER`, `margin_px=12` to hide CRT red fringe; no `RoomOutline` line), chained-door interact art, floor/wall divider, `[E]` near door plays `"Not yet."` when the dialogue bar is closed (bar still up → skip/advance only; `basement_door_line_seen` saved but not an interact gate), left-edge `ExitTrigger` auto-return to `1.2_Corridor.tscn` with right-edge peek spawn (`corridor_spawn_side="basement_right"`). Reachable from `1.2_Corridor.tscn` right-edge `ExitTrigger` (approved `RightWall` move). Replaces dialog-only `1.4_BasementBlockedTemp.tscn`. No embedded post-FX.

---
