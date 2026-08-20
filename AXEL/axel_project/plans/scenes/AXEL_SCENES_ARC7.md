# AXEL — Scene Dialogues: Arc 7 — Endings

> Dialogue under each scene is locked canon (rewrites). Do not restore old HTML prototype SOURCE text.

---

### 7.1 Ending 1 — Fear (`ending_1`)

**Location label:** `ENDING #1`

**Dialogue:**

> Coward.
>
> *(repeat `"Coward."` 100 times)*

**Choices:**


| Button label | Target    |
| ------------ | --------- |
| *(auto)*     | Main Menu |


**Implemented (Godot):** `7.1_Ending1.tscn` + `.gd` — white void fill + `TopDialogueOverlay`; plays `"Coward."` 100 times via `show_lines` (skip/auto-advance allowed), then `change_scene_to_file` to `0.1_MainMenu.tscn`. Reachable by walking left off `1.1_SchoolExterior` after the intro. No embedded post-FX.


---

### 7.2 Ending 2 — Darkness (`ending_2`)

**Location label:** `ENDING #2`

**Dialogue:**

> The shadows consume you.
>
> You lose your footing.
>
> Is this how it ends?
>
> Really?
>
> I mean...
>
> Your fault for thinking you could see where you're stepping in pitch-black.
>
> If only you had a FLASHLIGHT.
>
> You know the tool that lights up dark places.
>
> Maybe it's in the kitchen. I don't know.
>
> Your dumb.

**Choices:**


| Button label | Target                       |
| ------------ | ----------------------------- |
| Start again  | School Exterior (full reset) |


---

### 7.3 Ending 3 — Wrong Answer (`ending_3`)

**Location label:** `ENDING #3`

**Dialogue:**

> His eyes won't return yours.
>
> It's not complete.

**Choices:**


| Button label | Target                       |
| ------------ | ----------------------------- |
| Start again  | School Exterior (full reset) |


---

### 7.4 Ending 4 — No Name (`ending_4`)

**Location label:** `ENDING #4`

**Dialogue:**

> [instead of the name, the game just runs a check if the puzzle was completed in the classroom]
>
> You hear sirens.
>
> Then see the red and blue lights.
>
> What comes around, goes around.

**Choices:**


| Button label | Target                       |
| ------------ | ----------------------------- |
| Start again  | School Exterior (full reset) |


---

### 7.5 True Ending (`ending_true`)

**Location label:** `TRUE ENDING`

**Dialogue:**

> Maybe it wasn't ALL your fault.
>
> Maybe I was too harsh.
>
> Okay.
>
> I'll say it.
>
> Ugh.
>
> I'm sorry.
>
> [a spirit leaves the body]

**Choices:**


| Button label       | Target   |
| ------------------ | -------- |
| Go to the backyard | Epilogue |


---

### 7.6 Epilogue (`epilogue`)

**Location label:** `EPILOGUE`

**Dialogue:**

> [player smokes in the end screen with the spirit in the backyard]
>
> "I should quit."
>
> "Yeah, don't want to end like me before your time"
>
> It was a really bad joke, but you still laugh.
>
> Just like old times.

**Choices:**


| Button label | Target                       |
| ------------ | ----------------------------- |
| Exit         | School Exterior (full reset) |


---
