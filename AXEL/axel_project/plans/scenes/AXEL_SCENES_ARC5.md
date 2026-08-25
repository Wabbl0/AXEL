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


**Implemented (Godot):** `5.1_Classroom.tscn` + `.gd` — walkable room with hand-drawn art, kept box walls plus nine drag-to-place furniture polygon blockers, door back to corridor (`interact_arrival_t` along the door), one-shot desk `[E]` → `5.2_ClassroomDesk`, looping `MemoryIndicator` (drag onto board; no board `[E]` yet). Authored Player scale `0.298` / speed `255.9` (50% larger than the shared sheet-retuned `0.198`). Enter lines once via `GameManager.classroom_enter_line_seen`. After desk leave, `classroom_desk_seen` disables the desk zone and restores Mike via `classroom_desk_return_pos`. Interact chip offset is zero. 5.3/5.4 still deferred.

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

**Implemented (Godot):** `5.2_ClassroomDesk.tscn` + `.gd` — still-scene shell (locked bg, dialogue overlay, red X). After `_can_exit`, leave with `[X]`, left-click/tap, or Tab/E/Space/Enter. Timed plates `desk_empty.png` → `desk_hand.png` (+ local camera offset shake + dim) → `desk.png`, then canon lines with `|beat:1.5|`. Sets `classroom_desk_seen` on leave; does **not** call `add_memory_once`. Art copied from Finnish `pöytä_*` plates.

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
