# AXEL — Scene Dialogues: Arc 2 — Cafeteria

---

### 2.1 Cafeteria (`loc_cafeteria`)

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


**Implemented (Godot):** `2.1_Cafeteria.tscn` + `2.1_Cafeteria.gd` — first Arc 2 walkable room: `PlayerLayer` (layer 100; scale `1.5`, speed `126.5`), `2.1_Cafeteria.png` cover-fit + locked background, `BackgroundCamera` `STATIC_LOCKED`/`COVER` with `margin_px=12` and `static_center=(960,0)` (top-biased so foodline/kitchen stay in frame), collider sync on `layout_applied`. Enter line once via `TopDialogueOverlay`. `[E]` zones: table → `2.2_CafeteriaMemory.tscn` (still placeholder), kitchen → `2.3_Kitchen.tscn` (still placeholder), left return → `1.3_LockerHub.tscn`. No ghost float sprite yet; no embedded post-FX. Tune wall/zone shapes in the editor if hotspots feel off.

---

### 2.2 Cafeteria Memory (`loc_cafeteria_memory`)

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

### 2.3 Kitchen (`loc_kitchen`)

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

### 2.4 Kitchen — Flashlight Pickup (`action_get_flashlight`)

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
