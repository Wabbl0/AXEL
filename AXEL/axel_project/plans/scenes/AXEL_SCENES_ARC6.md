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
| Go back                 | —         | Locker Hub      |


---

### 6.2 Basement Locked (`basement_locked`)

**Location label:** `LOCKED`

**Dialogue:**

> You need a key, dumbass.

**Choices:**


| Button label | Target     |
| ------------ | ---------- |
| Go back      | Locker Hub |


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
| I'm not ready | —              | Locker Hub    |


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

**Implemented (Godot):** Grey-box `6.8` does not ask you to type. **Face it** opens the true ending when the classroom board was answered and that floor item is equipped. Otherwise it opens Ending 4. Ending 3 is not opened from here.

---
