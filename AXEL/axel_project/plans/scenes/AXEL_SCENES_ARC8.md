# AXEL — Scene Dialogues: Arc 8 — Endings

---

### 8.1 Ending 1 — Fear (`ending_1`)

**Location label:** `ENDING #1`

**Dialogue [SOURCE]:**

> Fear wins over curiosity. You walk away. In the nights that follow you have nightmares, but you never learn the truth.

**[REWRITE]:**

> Coward
>
> Coward
>
> Coward
>
> Coward
>
> ...

**Choices:**


| Button label | Target                       |
| ------------ | ---------------------------- |
| Start again  | School Exterior (full reset) |


---

### 8.2 Ending 2 — Darkness (`ending_2`)

**Location label:** `ENDING #2`

**Dialogue [SOURCE]:**

> You step into darkness without light. Your foot slips. You tumble down the stairs and your neck breaks. The shadows consume you.

**[REWRITE]:**

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
| ------------ | ---------------------------- |
| Start again  | School Exterior (full reset) |


---

### 8.3 Ending 3 — Wrong Answer (`ending_3`)

**Location label:** `ENDING #3`

**Dialogue [SOURCE]:**

> You answer wrong. 'You still don't care!' the voice screams. The basement walls glow red. Fire engulfs you. You are in hell.

**[REWRITE]:**

> His eyes won't return yours.
>
> It's not complete.

**Choices:**


| Button label | Target                       |
| ------------ | ---------------------------- |
| Start again  | School Exterior (full reset) |


---

### 8.4 Ending 4 — No Name (`ending_4`)

**Location label:** `ENDING #4`

**Dialogue [SOURCE]:**

> You whisper 'Axel'. The body goes silent. But then the police burst in. You have no evidence (Name missing) that it was suicide. You are convicted of murder.

**[REWRITE]:**

> [instead of the name, the game just runs a check if the puzzle was completed in the classroom]
>
> You hear sirens.
>
> Then see the red and blue lights.
>
> What comes around, goes around.

**Choices:**


| Button label | Target                       |
| ------------ | ---------------------------- |
| Start again  | School Exterior (full reset) |


---

### 8.5 True Ending (`ending_true`)

**Location label:** `TRUE ENDING`

**Dialogue [SOURCE]:**

> You whisper 'Axel' and give the name. A spirit leaves the body. He looks at peace. 'This can't hurt me anymore,' he laughs. You are forgiven.

**[REWRITE]:**

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

### 8.6 Epilogue (`epilogue`)

**Location label:** `EPILOGUE`

**Dialogue [SOURCE]:**

> You sit together in the backyard. You and a ghost. You smoke in silence. Smoke rises toward the sky. You are free.

**[REWRITE]:**

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
| ------------ | ---------------------------- |
| Exit         | School Exterior (full reset) |


---

## What was missing from the first version of this file


| Scene               | What was missing                                                                                                                                                 |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `loc_key_wall`      | Entire scene omitted — *"Most hooks are empty. One rusty key still hangs."*                                                                                      |
| Backyard step 2     | Yard reveal text was buried in inline JS `loadScene()`, not in the `story` object: *"YOU look down. There it is. A lighter with the name 'AXEL' written on it."* |
| `loc_yard_memory`   | Listed only as a click step but the named scene (reached via "Remember the name") was not separated out                                                          |
| `basement_question` | No fail text is defined in source — player routes to Ending 3 silently after 2s (was implied but not noted)                                                      |
