# AXEL — Scene Dialogues: Arc 7 — Basement

---

### 7.1 Basement Door (`basement_entry`)

**Location label:** `BASEMENT DOOR`

**Dialogue [SOURCE]:**

> A heavy metal door. The sign reads 'ENTRY FORBIDDEN'.

**[REWRITE]:**

> x

**Choices:**


| Button label            | Condition | Target          |
| ----------------------- | --------- | --------------- |
| Unlock with key         | Has key   | Basement Stairs |
| Try the handle (Locked) | No key    | Basement Locked |
| Go back                 | —         | Locker Hub      |


---

### 7.2 Basement Locked (`basement_locked`)

**Location label:** `LOCKED`

**Dialogue [SOURCE]:**

> The door won't budge. You need a key.

**[REWRITE]:**

> You need a key, dumbass.

**Choices:**


| Button label | Target     |
| ------------ | ---------- |
| Go back      | Locker Hub |


---

### 7.3 Basement Stairs (`basement_stairs`)

**Location label:** `STAIRCASE`

**Dialogue [SOURCE]:**

> The door opens. Before you lie pitch-black stairs. The smell is nauseating. Are you ready to step into the darkness?

**[REWRITE]:**

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

### 7.4 Basement Main (`basement_main`)

**Location label:** `MAIN CHAMBER`

**Dialogue [SOURCE]:**

> The beam hits soft soil. In the corner something metallic glints. There is no going back.

**[REWRITE]:**

> x

**Choices:**


| Button label          | Condition     | Target           |
| --------------------- | ------------- | ---------------- |
| Pick up the shovel    | No shovel yet | Shovel Pickup    |
| Dig (Requires shovel) | Has shovel    | Basement Digging |
| Turn back             | —             | Basement Stuck   |


---

### 7.5 Shovel Pickup (`action_get_shovel`)

**Location label:** `FOUND`

**Dialogue [SOURCE]:**

> You found a rusty shovel.

**[REWRITE]:**

> The same old shovel still here.

**Choices:**


| Button label | Target        |
| ------------ | ------------- |
| Continue     | Basement Main |


---

### 7.6 Basement Stuck (`basement_stuck`)

**Location label:** `NO RETURN`

**Dialogue [SOURCE]:**

> The door is locked behind you. You must face this.

**[REWRITE]:**

> I'm not letting you.

**Choices:**


| Button label | Target        |
| ------------ | ------------- |
| Back         | Basement Main |


---

### 7.7 Basement Digging (`basement_digging`)

**Location label:** `DIGGING`

**Dialogue [SOURCE]:**

> You strike the shovel into the ground. Thud. Fabric… bone. The final memory surfaces.

**[REWRITE]:**

> As you keep digging.
>
> A memory surfaces.

**Choices:**


| Button label   | Target          |
| -------------- | --------------- |
| FACE THE TRUTH | Basement Corpse |


---

### 7.8 Basement Corpse — Puzzle (`basement_question`)

**Location label:** `CORPSE`

**Dialogue [SOURCE]:**

> Before you is a mummified body. Its jaw drops open. A voice echoes in your head: 'WHO AM I?'

**[REWRITE]:**

> [instead of the name, the game just runs a check if the puzzle was completed in the classroom]

**Input:** Text field — correct answer: `AXEL` (case-insensitive)

**On correct + has Name flag:** → Ending True
**On correct + no Name flag:** → Ending 4
**On wrong answer:** → Ending 3 (auto-routed after 2 seconds, no fail text in source)

---
