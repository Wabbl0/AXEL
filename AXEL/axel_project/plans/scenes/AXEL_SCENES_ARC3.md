# AXEL — Scene Dialogues: Arc 3 — Backyard

> Dialogue under each scene is locked canon (rewrites). Do not restore old HTML prototype SOURCE text.
> **Canon layout:** one Backyard scene with internal click steps (not separate `3.1b` / `3.1c` / `3.1d` scene files).

---

### 3.1 Backyard — default state (`loc_yard`)

**Location label:** `BACKYARD`

**Dialogue:**

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

### 3.1 — Click step 1: Memory flash (`loc_yard_memory` text)

**Location label:** `BACKYARD`
*(Glitch flash 250ms, then this text replaces scene text)*

**Dialogue:**

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

### 3.1 — Click step 2: Name reveal

**Location label:** `BACKYARD`
*(No glitch — text swaps directly)*

**Dialogue:**

> You light up your cigarette.
>
> Tastes of tar and regret.
>
> Yum.

---

### 3.1 — After sequence (named memory beat)

**Location label:** `BACKYARD`
*(Reached via "Remember the name" after the sequence)*

**Dialogue:**

> TODO: write line

**Choices:**


| Button label      | Target     |
| ----------------- | ---------- |
| Remember the name | Locker Hub |


---

### 3.2 Backyard Hint / Intermission (`loc_yard_hint`)

**Location label:** `INTERMISSION`

**Dialogue [DYNAMIC — chosen at runtime from smoking-hint logic]:**


| Condition          | Line |
| ------------------ | ---- |
| No flashlight      | TODO: write line |
| No name            | TODO: write line |
| No key             | TODO: write line |
| Memories < 5       | TODO: write line |
| All conditions met | TODO: write line |


**Choices:**


| Button label | Target   |
| ------------ | -------- |
| Continue     | Backyard |


---
