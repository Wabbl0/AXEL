# AXEL — Scene Dialogues: Arc 4 — Teachers' Lounge

> Dialogue under each scene is locked canon (rewrites). Do not restore old HTML prototype SOURCE text.

---

### 4.1 Teachers' Lounge (`loc_teachers`)

**Location label:** `TEACHERS' LOUNGE`

**Dialogue:**

> You always wondered what the teachers were doing behind closed doors.
>
> [beat]
>
> Pervert.

**Choices:**


| Button label                                                             | Target                         |
| ------------------------------------------------------------------------ | ------------------------------ |
| Return to locker                                                         | Locker Hub                     |
| *(Hidden — click on scene advances memory sequence before key is found)* | → Teachers Memory → Key Pickup |


**Implemented (Godot) — shell only, mini-games deferred:** `4.1_TeachersLounge.tscn` + `.gd` — walkable shell with hand-drawn `4.1_TeachersLounge.png` (3508×2480, white fill + black ink), authored scale `0.198` / speed `185.3`, `STATIC_LOCKED` camera (art-centered, no `static_center` bias), one door back to `2.4_ClassroomsCorridor` (`classrooms_corridor_spawn_side="lounge_door"`; `[E]` arrival uses `interact_arrival_t` along `DoorInteractArea`). Placeholder `Line2D`/`Polygon2D` visuals removed. Furniture/debris colliders are `CollisionPolygon2D` on the ink (left upper strip, left cabinet, tilted table, chair, key bench, right clutter); floor papers stay walkable. Outer walls are polygons too. `InteractPromptOverlay` uses the shared zero `screen_offset` default. Canon enter lines play once via `GameManager.teachers_lounge_enter_line_seen`. Memory sequence / key pickup are **not** built yet — the key is drawn on the bench but is not an `[E]` zone. Hub 1.3 still loads this file by path. Re-tune furniture/door shapes in the editor if they sit off the ink.

---

### 4.2 Teachers' Lounge Memory (`loc_teachers_memory`)

**Location label:** `TEACHERS' LOUNGE`
*(Plays as embedded click step within Teachers' Lounge — glitch flash 250ms before text swaps)*

**Dialogue:**

> "So, when did you see him last?" the police officer asked.
>
> "That day during lunch. I mean I guess he was in the same classes as me."
>
> "You guess?"
>
> "He's so - silent. I barely notice him anymore."
>
> [beat]
>
> Liar. You knew exactly where he was.

---

### 4.3 Key Wall (`loc_key_wall`)

**Location label:** `TEACHERS' LOUNGE`
*(Currently unreachable via normal navigation — reserved for future use)*

**Dialogue:**

> There's a key.
>
> Why hasn't anyone nicked it yet?

**Choices:**


| Button label | Condition  | Target           |
| ------------ | ---------- | ---------------- |
| Take the key | No key yet | Key Pickup       |
| Turn back    | —          | Teachers' Lounge |


---

### 4.4 Teachers' Lounge — Key Pickup (`action_get_key`)

**Location label:** `TEACHERS' LOUNGE`

**Dialogue:**

> You take the key.
>
> [beat]
>
> Like a good little boy.

**Choices:**


| Button label | Target           |
| ------------ | ---------------- |
| Nice         | Teachers' Lounge |


---
