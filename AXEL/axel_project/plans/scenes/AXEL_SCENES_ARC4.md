# AXEL — Scene Dialogues: Arc 4 — Backyard

---

### 4.1 Backyard — default state (`loc_yard`)

**Location label:** `BACKYARD`

**Dialogue [SOURCE]:**

> The corner at the back of the school. The wall has a weird graffiti on it. You still smell the teen rebelry around.

**[REWRITE]:**

> The spirit of rebellion is still present here. Nice graffiti.
>
> [beat]
>
> You could never be this talented.

**Choices:**


| Button label      | Target        |
| ----------------- | ------------- |
| Smoke a cigarette | Backyard Hint |
| Return to locker  | Locker Hub    |


> **Note:** On first visit (before yard memory plays), clicking anywhere on the scene advances the click sequence below instead of triggering the buttons normally.

---

### 4.1b Backyard — Click step 1: Memory flash (`loc_yard_memory` text)

**Location label:** `BACKYARD`
*(Glitch flash 250ms, then this text replaces scene text — sourced from `story.loc_yard_memory.text`)*

**Dialogue [SOURCE]:**

> Your friend looks gaunt. 'Just to make sure you don't steal my lighter again I'm going to write my name on it.'

**[REWRITE]:**

> "Oh. Sorry. I'll go," they say.
>
> "No. I don't mind."
>
> "Haven't seen you in school for awhile."
>
> "Didn't think you'd notice.
>
> "What does that mean?"
>
> "Nothing."
>
> [beat]
>
> "Are we still friends?"

---

### 4.1c Backyard — Click step 2: Name reveal (inline JS `yardRevealText`)

**Location label:** `BACKYARD`
*(No glitch — text swaps directly. This line lives in `loadScene()` JS, not in the `story` object)*

**Dialogue [SOURCE]:**

> YOU look down. There it is. A lighter with the name "AXEL" written on it.

**[REWRITE]:**

> You light up your cigarette.
>
> Tastes of tar and regret.
>
> Yum.

---

### 4.1d Backyard — Named scene (`loc_yard_memory`)

**Location label:** `BACKYARD`
*(This is the actual `story.loc_yard_memory` scene object — same text as 4.1b, but reached via the "Remember the name" button after the sequence)*

**Dialogue [SOURCE]:**

> Your friend looks gaunt. 'Just to make sure you don't steal my lighter again I'm going to write my name on it.

**[REWRITE]:**

> x

**Choices:**


| Button label      | Target     |
| ----------------- | ---------- |
| Remember the name | Locker Hub |


---

### 4.2 Backyard Hint / Intermission (`loc_yard_hint`)

**Location label:** `INTERMISSION`

**Dialogue [DYNAMIC — chosen at runtime from `getSmokingHintText()`]:**


| Condition          | Line [SOURCE]                                                         |
| ------------------ | --------------------------------------------------------------------- |
| No flashlight      | The basement is bound to be dark. I need something to light the way   |
| No name            | I remember their face. But their name escapes me                      |
| No key             | The basement is bound to be locked. I better look around for the key. |
| Memories < 5       | I should look around more. There's something I'm forgetting.          |
| All conditions met | I'm ready.                                                            |


**[REWRITE any hint lines you want to change:]**

**Choices:**


| Button label | Target   |
| ------------ | -------- |
| Continue     | Backyard |


---
