# AXEL — Scene Dialogues: Arc 5 — Classroom

> Dialogue under each scene is locked canon (rewrites). Do not restore old HTML prototype SOURCE text.

---

### 5.1 Classroom (`loc_classroom`)

**Location label:** `CLASSROOM`

**Dialogue:**

> This is where the shit went down.
>
> If shit going down is you, highly caffinated, ignoring your teachers and usually skipping class to go for a smoke.
>
> How did you ever get anywhere in life?

**Choices:**


| Button label      | Target          |
| ----------------- | --------------- |
| Inspect the desk  | Classroom Desk  |
| Look at the board | Classroom Board |
| Return to locker  | Locker Hub      |


**Implemented (Godot) — shell only, mini-games deferred:** `5.1_Classroom.tscn` + `.gd` — walkable shell with hand-drawn `5.1_Classroom.png` (from `5.1_Classroom_v2`; white fill + black ink), Kitchen player profile, `STATIC_LOCKED` camera, one door back to `2.4_ClassroomsCorridor` (`classrooms_corridor_spawn_side="classroom_door"`). Placeholder desk/board polygons removed; door colliders are left for manual placement. Canon enter lines play once via `GameManager.classroom_enter_line_seen`. Desk/board puzzle scenes are **not** wired yet — structure only, not arc-complete. Hub 1.3 still loads this file by path.

---

### 5.2 Classroom — Desk (`loc_desk`)

**Location label:** `CLASSROOM`

**Animation sequence (plays once on first visit):**


| Timestamp    | Background image              | Story text                      |
| ------------ | ----------------------------- | -------------------------------- |
| t = 0 ms     | `desk_empty.jpg`              | *(blank)*                       |
| t = 650 ms   | `desk_hand.png` + shake + dim | *(blank)*                       |
| t = 1 000 ms | `desk.png`                    | *(blank)*                       |
| t = 1 300 ms | `desk.png`                    | Final dialogue revealed (below) |


**Final dialogue:**

> It's THEIR desk.
>
> You said it was a dare.
>
> [beat]
>
> I'd spit on you if I could.

**Choices:**


| Button label  | Target    |
| ------------- | --------- |
| Close the lid | Classroom |


---

### 5.3 Classroom — Board (`loc_board`)

**Location label:** `CLASSROOM`

**Dialogue:**

> On the board there are weird ass symbols and equations.
>
> You can only make out one question:
>
> "[something relevant that is only learned through playing the slots]"

**Input:** Text field — correct answer: `AXEL` (case-insensitive, trimmed)

**Fail text:**

> Nah.

**Choices:**


| Button label | Target    |
| ------------ | --------- |
| Turn back    | Classroom |


---

### 5.4 Classroom — Board Success (`loc_board_success`)

**Location label:** `CLASSROOM`

**Dialogue:**

> TODO: write line

**Choices:**


| Button label  | Target     |
| ------------- | ---------- |
| Take the name | Locker Hub |


---
