# AXEL — Scene Dialogues: Arc 3 — Cafeteria

---

### 3.1 Cafeteria (`loc_cafeteria`)

**Location label:** `CAFETERIA`

**Dialogue [SOURCE]:**

> Tables are overturned. The air reeks of rancid grease. In the middle of the hall you see a ghostly figure sitting alone at an intact table. The kitchen area is dark.

**[REWRITE]:**

> Even through all the chaos you can hear the chattering students of the past.

**Choices:**


| Button label        | Target           |
| ------------------- | ---------------- |
| Approach Your table | Cafeteria Memory |
| Search the kitchen  | Kitchen          |
| Return to locker    | Locker Hub       |


---

### 3.2 Cafeteria Memory (`loc_cafeteria_memory`)

**Location label:** `CAFETERIA`
*(Memory — glitch flash on enter, no interaction area)*

**Dialogue [SOURCE]:**

> You are sitting at the same table. The popular kids invite you over. Your friend whispers, 'Don't go.' You stand up, laugh and shout loud: 'Sorry, I can't deal with your whining.' You leave them alone.

**[REWRITE]:**

> "Do you think I'm a bad person?"
>
> [beat]
>
> You answer, "No."
>
> [beat]
>
> "I just - don't have the energy. To be around you."
>
> [beat]
>
> "Sorry."
>
> "Oh," they sigh.
>
> [beat]
>
> "No. I understand."

**Choices:**


| Button label | Target    |
| ------------ | --------- |
| Go back      | Cafeteria |


---

### 3.3 Kitchen (`loc_kitchen`)

**Location label:** `KITCHEN`

**Dialogue [SOURCE]:**

> The kitchen is rotting at the seams. You see the rot pile up in the air. The smell is horrendus.

**[REWRITE]:**

> Everything is rotten here. Everything.
>
> [beat]
>
> This includes you.

**Choices:**


| Button label                                                                            | Target                    |
| --------------------------------------------------------------------------------------- | ------------------------- |
| Turn back                                                                               | Cafeteria                 |
| *(Hidden — click on scene image triggers flashlight pickup before flashlight is found)* | Kitchen Flashlight Pickup |


---

### 3.4 Kitchen — Flashlight Pickup (`action_get_flashlight`)

**Location label:** `KITCHEN`

**Dialogue [SOURCE]:**

> Your hand hits cold metal. You found an industrial flashlight!

**[REWRITE]:**

> Let there be light!

**Choices:**


| Button label | Target    |
| ------------ | --------- |
| Nice         | Cafeteria |


---

