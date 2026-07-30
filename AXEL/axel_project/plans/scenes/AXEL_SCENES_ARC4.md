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


**Implemented (Godot) — shell only, mini-games deferred:** `4.1_TeachersLounge.tscn` + `.gd` — walkable shell with flat placeholder background, Kitchen player profile, `STATIC_LOCKED` camera, one door back to `2.4_ClassroomsCorridor` (`classrooms_corridor_spawn_side="lounge_door"`). Canon enter lines play once via `GameManager.teachers_lounge_enter_line_seen`. Memory sequence / key pickup are **not** built yet — structure only, not arc-complete. Hub 1.3 still loads this file by path.

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
