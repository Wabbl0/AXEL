# AXEL — Scene Dialogues: Arc 5 — Classroom

---

### 5.1 Classroom (`loc_classroom`)

**Location label:** `CLASSROOM`

**Dialogue [SOURCE]:**

> Dust dances in the beams of light. In the back row one desk sits apart from the others. A chalkboard stands at the front.

**[REWRITE]:**

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


**Final dialogue [SOURCE]:**

> This is THEIR desk. You remember. It was a dare.

**[REWRITE]:**

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

**Dialogue [SOURCE]:**

> On the board is code: 'if (name == ____) { remember(); }'. Do you know the name?

**[REWRITE]:**

> On the board there are weird ass symbols and equations.
>
> You can only make out one question:
>
> "[something relevant that is only learned through playing the slots]"

**Input:** Text field — correct answer: `AXEL` (case-insensitive, trimmed)

**Fail text [SOURCE]:**

> The board doesn't respond.

**[REWRITE fail text]:**

> Nah.

**Choices:**


| Button label | Target    |
| ------------ | --------- |
| Turn back    | Classroom |


---

### 5.4 Classroom — Board Success (`loc_board_success`)

**Location label:** `CLASSROOM`

**Dialogue [SOURCE]:**

> At least YOU remember that much.

**[REWRITE]:**

> x

**Choices:**


| Button label  | Target     |
| ------------- | ---------- |
| Take the name | Locker Hub |


---
