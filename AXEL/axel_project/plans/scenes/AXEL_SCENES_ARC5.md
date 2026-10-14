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


**Implemented (Godot):** `5.1_Classroom.tscn` + `.gd` — walkable room (`extends ExplorationRoom`; Player is `Player.tscn`) with hand-drawn art, kept box walls plus nine drag-to-place furniture polygon blockers, door back to corridor (`interact_arrival_t` along the door), one-shot desk `[E]` → `5.2_ClassroomDesk`. Desk glow is `PlayerLayer/MemoryIndicator` with `collected_bool_property = "classroom_desk_seen"` and `interact_area_path` to `DeskInteractArea` (editor point `(2712, 2160)`; `visual_offset` zero; the glow remaps itself). Board `[E]` is `BoardInteractArea` (own `RectangleShape2D`, starter box on the chalkboard at `(1790, 420)` matching `BoardGlow` center, taller so Mike can stand in it). Pressing `[E]` plays the board lines in the dialogue bar, then that same bar becomes the answer field: a blinking white caret, press the bar (click or interact) and the caret turns red, then you can type. Enter submits one guess for the whole save. The question names one floor item from this run and asks which room it is in, or was in if that item was already picked up. The right room sets `hasName` / `knowsName` (the existing +15% goal bump), plays the success line and the symbol line (`"Something's scratched under it: %s"`), and starts the name fight. Reading the board again after that repeats the symbol line. Anything else plays `Nah.` and the field does not open again. Esc leaves without using the guess. `5.3_ClassroomBoard` is not opened. Board outline glow stays `BoardGlow/Outline` (`prop_line_halo.gdshader`) — not a `MemoryIndicator` blob. Furniture 6–9 have behind filters (`FurnitureBlock6_Behind` … `FurnitureBlock9_Behind`, `feather_px = 2`). The fade line is each green polygon’s own front, not the walk blocker, so standing in front stays solid and a slanted front follows Mike’s feet. Authored Player scale `0.298` / speed `255.9` (50% larger than the shared sheet-retuned `0.198`). Enter lines once via `GameManager.classroom_enter_line_seen`. After desk leave, `classroom_desk_seen` hides the glow, disables the desk zone, and restores Mike via `classroom_desk_return_pos`. Interact chip offset is zero. Correct answer stays in this room (the old 5.4 grey-box is not opened).

---

### 5.2 Classroom — Desk (`loc_desk`)

**Location label:** `CLASSROOM`

**Animation sequence (plays once on first visit):**


| Step | Background image | Story text |
| ---- | ---------------- | ---------- |
| Open | `desk_empty.png` on white fill (noir → black) | `This was their desk.` |
| Beat | same empty plate | 1.5s hold after the line types |
| Flash | `desk_hand.png` + shake + dim | 1.0s, no new line |
| Hold | `desk.png` (undim, opening line hides) | then `You said it was a dare.` |
| Hold | same final plate | then `I'd spit on you if I could.` |


**Dialogue:**

> This was their desk.
>
> [beat 1.5s, then hand plate 1.0s]
>
> You said it was a dare.
>
> I'd spit on you if I could.

**Choices:**


| Button label  | Target    |
| ------------- | --------- |
| Close the lid | Classroom |


---

**Implemented (Godot):** `5.2_ClassroomDesk.tscn` + `.gd` — still-scene (`extends MemoryStill`; local shake/dim stays in `_play_opening`). After `_can_exit`, leave with `[X]`, left-click/tap, or Tab/E/Space/Enter. Opens on `desk_empty.png` + `This was their desk.` + 1.5s beat → `desk_hand.png` 1.0s (local camera offset shake + white dim) → `desk.png` (bar hides so the plate is visible) → `You said it was a dare.` → `I'd spit on you if I could.` Sets `classroom_desk_seen` on leave; does **not** call `add_memory_once`. Art copied from Finnish `pöytä_*` plates; empty PNG fill is white so noir reads as black.

---

### 5.3 Classroom — Board (`loc_board`)

**Location label:** `CLASSROOM`

**Dialogue:**

> On the board there are weird ass symbols and equations.
>
> You can only make out one question:
>
> "In which room is X?" (or "was", if that item was already picked up). X is one floor item chosen from this save's seed.

**Input:** Text field — one guess per save. The answer is that item's room (`cafeteria`, `kitchen`, `hallway` / `hall` / `halls` / `classrooms corridor`, `teachers lounge` / `lounge`, `classroom`, `basement` / `basement door`, `backyard`). Not case-sensitive. A leading `in`, `inside`, or `on` still counts (`in kitchen`, `inside hallway`, `on basement door`). `corridor` alone does not count. Esc does not use the guess.

**Fail text:**

> Nah.

**Choices:**


| Button label | Target    |
| ------------ | --------- |
| Turn back    | Classroom |


**Implemented (Godot):** Not its own scene. After the lines above, `5.1` keeps the dialogue bar open and uses it as the text field (`await_text_entry`).


---

### 5.4 Classroom — Board Success (`loc_board_success`)

**Location label:** `CLASSROOM`

**Dialogue:**

> TODO: write line
>
> Something's scratched under it: [symbol]

**Symbol:** a correct answer reveals one of ten symbols (`Δ Ω † ‡ § ¶ ¤ ∞ ◊ ∑`, picked by the run seed and saved as `RunState.board_symbol`). Reading the board again repeats the symbol line. The player must pick this symbol at the basement corpse (`6.8`) for the true ending.

**Choices:**


| Button label  | Target     |
| ------------- | ---------- |
| Take the name | Locker Hub |


---
