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


**Implemented (Godot):** `4.1_TeachersLounge.tscn` + `.gd` — walkable shell (`extends ExplorationRoom`; Player is `Player.tscn`) with hand-drawn `4.1_TeachersLounge.png` (3508×2480, white fill + black ink), authored scale `0.257` / speed `226.9` (30% larger than the shared `0.198`), `STATIC_LOCKED` camera (art-centered, no `static_center` bias), one door back to `2.4_ClassroomsCorridor` (`classrooms_corridor_spawn_side="lounge_door"`; `[E]` arrival uses `interact_arrival_t` along `DoorInteractArea`). Furniture/debris colliders are `CollisionPolygon2D` on the ink (left upper strip, left cabinet, tilted table, chair, key bench, right clutter); floor papers stay walkable. Outer walls are polygons too. `InteractPromptOverlay` uses the shared zero `screen_offset` default. Canon enter lines play once via `GameManager.teachers_lounge_enter_line_seen`. **Key:** large `KeyNearArea` plays Arc 4.3 walk-near lines once (`teachers_key_line_seen`; deferred if dialogue busy); smaller `KeyInteractArea` `[E]` uses `LorePickup.take` (`hasKey` + inventory `"Teacher Key"` + Arc 4.4 lines). Bench key ink stays drawn for now — later add a flashlight-style `KeyVisual` under `EnvironmentColliders` to hide it. **Memory:** `PlayerLayer/MemoryIndicator` with `memory_key = "teachers_memory"` and `interact_area_path` to `MemoryInteractArea` (`visual_offset` / `screen_offset` zero) opens `4.2_TeachersMemory`; standing spot saved via `teachers_lounge_memory_return_pos`. After leaving 4.2, `"Liar. You knew exactly where he was."` plays once (`teachers_liar_line_seen`). Key and memory work in either order. Starting zone sizes are guesses — drag in the editor. Hub 1.3 still loads this file by path.

---



### 4.2 Teachers' Lounge Memory (`loc_teachers_memory`)

**Location label:** `TEACHERS' LOUNGE`
*(Plays as a memory still from 4.1 — shared `AxelEventFx` enter glitch is 0.65s, not a separate 250ms flash)*

**Dialogue:**

> POLICE: "So, when did you see him last?"
>
> "That day during lunch. I mean I guess he was in the same classes as me."
>
> POLICE: "You guess?"
>
> "He's so - silent. I barely notice him anymore."
>
> [beat]  
>
> ---  
>
> [AFTER EXITTING MEMORY]:
>
> Liar. You knew exactly where he was.

**Implemented (Godot):** `4.2_TeachersMemory.tscn` + `.gd` — still-image memory (`extends MemoryStill`; crop via `scenes/core/memory_frame.gd`; local `4.2_teachers_memory_frame.gd` is a one-line `extends MemoryFrame`). Same still shell as 2.2 / 3.2 (white placeholder PNG `4.2_Teachers_Memory.png` 3508×2480, region crop + frame above dialogue bar, CONTAIN camera, `ExitLayer` 110 red `[X]`). Police lines use `|grey|` (light grey, no on-screen `POLICE:` tag); player lines white. Once-ever via `teachers_memory_line_seen`; `add_memory_once("teachers_memory")` on exit. Returns to 4.1; post-exit "Liar." line lives in 4.1 (not in this still).

---



### 4.3 Key Wall (`loc_key_wall`)

**Location label:** `TEACHERS' LOUNGE`
*(In-room walk-near zone on the bench in 4.1 — not a separate location)*

**Dialogue:**

> There's a key.
>
> Why hasn't anyone nicked it yet?

**Choices:**


| Button label | Condition  | Target           |
| ------------ | ---------- | ---------------- |
| Take the key | No key yet | Key Pickup       |
| Turn back    | —          | Teachers' Lounge |


**Implemented (Godot):** Large `KeyNearArea` in `4.1_TeachersLounge` — plays these lines once (`teachers_key_line_seen`). Smaller `KeyInteractArea` handles take-key (`4.4`).

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


**Implemented (Godot):** Small `KeyInteractArea` `[E]` in `4.1_TeachersLounge` — `LorePickup.take` sets `hasKey`, adds inventory `"Teacher Key"`, plays these lines. Bench PNG ink is **not** hidden yet (follow-up: `KeyVisual` overlay like kitchen flashlight).

---

