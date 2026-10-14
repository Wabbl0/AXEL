# AXEL — Scene Dialogues: Arc 6 — Basement

> Dialogue under each scene is locked canon (rewrites). Do not restore old HTML prototype SOURCE text.

---

### 6.1 Basement Door (`basement_entry`)

**Location label:** `BASEMENT DOOR`

**Dialogue:**

> TODO: write line

**Choices:**


| Button label            | Condition | Target          |
| ----------------------- | --------- | --------------- |
| Unlock with key         | Has key   | Basement Stairs |
| Try the handle (Locked) | No key    | Basement Locked |
| Go back                 | —         | Locker Hub (1.4) |


---

### 6.2 Basement Locked (`basement_locked`)

**Location label:** `LOCKED`

**Dialogue:**

> You need a key, dumbass.

**Choices:**


| Button label | Target     |
| ------------ | ---------- |
| Go back      | Locker Hub (1.4) |


---

### 6.3 Basement Stairs (`basement_stairs`)

**Location label:** `STAIRCASE`

**Dialogue:**

> The door opens to a terrible screetch.
>
> In front of you stairs descending into pitch-blackness.
>
> Are you ready?

**Choices:**


| Button label  | Condition      | Target        |
| ------------- | -------------- | ------------- |
| Go down       | Has flashlight | Basement Main |
| Go down       | No flashlight  | Ending 2      |
| I'm not ready | —              | Locker Hub (1.4) |


---

### 6.4 Basement Main (`basement_main`)

**Location label:** `MAIN CHAMBER`

**Dialogue:**

> TODO: write line

**Choices:**


| Button label          | Condition     | Target           |
| --------------------- | ------------- | ---------------- |
| Pick up the shovel    | No shovel yet | Shovel Pickup    |
| Dig (Requires shovel) | Has shovel    | Basement Digging |
| Turn back             | —             | Basement Stuck   |


---

### 6.5 Shovel Pickup (`action_get_shovel`)

**Location label:** `FOUND`

**Dialogue:**

> The same old shovel still here.

**Choices:**


| Button label | Target        |
| ------------ | ------------- |
| Continue     | Basement Main |


---

### 6.6 Basement Stuck (`basement_stuck`)

**Location label:** `NO RETURN`

**Dialogue:**

> I'm not letting you.

**Choices:**


| Button label | Target        |
| ------------ | ------------- |
| Back         | Basement Main |


---

### 6.7 Basement Digging (`basement_digging`)

**Location label:** `DIGGING`

**Dialogue:**

> As you keep digging.
>
> A memory surfaces.

**Choices:**


| Button label   | Target          |
| -------------- | --------------- |
| FACE THE TRUTH | Basement Corpse |


---

### 6.8 Basement Corpse — Puzzle (`basement_question`)

**Location label:** `CORPSE`

**Dialogue:**

> The body is waiting for a name.

**Choices:** ten symbol buttons (`Δ Ω † ‡ § ¶ ¤ ∞ ◊ ∑`) in a seed-shuffled order.

| Pick | Condition | Target |
| ---- | --------- | ------ |
| The board's symbol | Board answered (`hasName`) | True Ending |
| Any other symbol, or board never answered | — | Ending 4 |

**Implemented (Godot):** Grey-box `6.8` does not ask you to type. It shows the ten symbols (`AxelWorld.corpse_symbol_order()`); `AxelWorld.corpse_symbol_correct()` picks the true ending. No equipped-item check. Ending 3 is not opened from here.

**Wiring note:** "Locker Hub" in this file means the `1.4` basement door room. The `1.4` door always opens `6.1`; going back to `1.4` places the player at the door.

---
