# AXEL — Scene Dialogues: Arc 2 — Hub

---

### 2.1 Locker Hub (`scene_3`)

**Location label:** `YOUR LOCKER`

**Dialogue [SOURCE]:**

> You are in your sanctuary. There's a picture of the two of you on the locker door. The map shows four circled locations. The basement entrance has been blacked out.

**[REWRITE]:**

> Oh look, a map of the school.  
> [beat]  
> Was your memory so bad you needed a map of the school?

**Choices:**


| Button label                       | Target                           |
| ---------------------------------- | -------------------------------- |
| Go to the cafeteria                | Cafeteria                        |
| Go to the classroom                | Classroom                        |
| Go to the backyard                 | Backyard                         |
| Go to the teacher's lounge         | Teachers' Lounge                 |
| ENTER THE BASEMENT *(red, locked)* | Basement Blocked / Basement Door |

**Implemented (Godot):** `2.1_LockerHub.tscn` + `2.1_LockerHub.gd` — four destinations above (basement omitted); `MapHotspot` (`UiPolygonHotspot`, `background_path = ../Background`) on the MAP paper → swaps background to `map.png` (hover tint + click only inside polygon; clicks ignored during first-visit dialogue); red `X` exit to corridor. Reachable from `1.2_Corridor.tscn` locker interact zone. First-visit lines use `TopDialogueOverlay.show_line()`; player can skip with click / E / Space / Enter while the bar is up (`CrtPowerFx.cancel()` on skip — no session freeze). **Tune map hit area:** `MapHotspot/PolygonAnchor/CollisionPolygon2D` vertex handles in texture-pixel space.


---

### 2.2 Basement Blocked — temporary gate (`basement_blocked_temp`)

**Location label:** `BASEMENT`

**Dialogue [SOURCE]:**

> The basement is sealed off for now. Come back later.

**[REWRITE]:**

> Not yet.

**Choices:**


| Button label | Target     |
| ------------ | ---------- |
| Go back      | Locker Hub |


---
