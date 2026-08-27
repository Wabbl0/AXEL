# AXEL — Scene Dialogues: Arc 3 — Backyard

> Dialogue under each scene is locked canon (rewrites). Do not restore old HTML prototype SOURCE text.
> **Canon layout:** 3.1 is the walkable yard; 3.2 is its own still-image memory scene (like 2.2). No hint scene. No in-yard click-steps. No “remember the name.”

---

### 3.1 Backyard (`loc_yard`)

**Location label:** `BACKYARD`

**Enter dialogue:**

> The spirit of rebellion is still present here. [beat] Nice graffiti.
>
> You could never be this talented.

**After leaving 3.2 (**`[memory ends]`**):**

> You light up your cigarette.
>
> Tastes of tar and regret.
>
> Yum.

**Choices:**


| Button label        | Target                                 |
| ------------------- | -------------------------------------- |
| Graffiti glow `[E]` | Backyard Memory (3.2), until collected |
| Door `[E]`          | Cafeteria (2.1)                        |


**Implemented (Godot):** `3.1_Backyard.tscn` + `.gd` — walkable yard with hand-drawn `3.1_Backyard.png` (from `3.1_Backyard_v2`; authoring white fill + black ink so 8-band noir shows red-on-black), authored scale `0.277` / speed `241.0`, `STATIC_LOCKED` camera, one door back to `2.1_Cafeteria` (`cafeteria_spawn_side="backyard_right"`; `[E]` arrival uses `interact_arrival_t` along `DoorInteractArea`). Building colliders `DoorSideLeft` / `DoorSideRight` / `DoorBottom` are authored on the drawing (each has its own `RectangleShape2D` so they resize independently; re-tune in the editor if they sit off the ink). Behind fade zones `Wall_Behind` / `Bush_Behind` / `Well_Behind` (`LeafOcclusionZone`, `feather_px = 2`) are authored polygons; wall uses feet-in-zone fade so the sprite stays faded even above `TopWall`; bush and well fade per pixel to match their polygons. Canon enter lines play once via `GameManager.backyard_enter_line_seen`. First line uses a mid-line `|beat:1.5|` wait before “Nice graffiti” (same bar, not a new line).

**Memory indicator:** `PlayerLayer/MemoryIndicator` — instance of `scenes/fx/MemoryIndicator.tscn` (white/gray looping glow). Spawns from its own editor position (texture-pixel space), captured into `_memory_indicator_tex` in `_ready()`, remapped via `env.to_global()` on every `layout_applied`. `MemoryInteractArea` is authored at the same graffiti point so the glow and walk-up `[E]` zone stay aligned; `InteractPromptOverlay` uses the shared zero `screen_offset` default (no scene-wide chip nudge). `[E]` on `MemoryInteractArea` opens `3.2_BackyardMemory.tscn` and saves the exact standing spot as transient `backyard_memory_return_pos`. After a successful 3.2 leave, `GameManager.add_memory_once("backyard_memory")` collects it (counts toward 5/5); 3.1 then hides the glow, disables `MemoryInteractArea`, restores the standing spot, and plays the cigarette three-liner once via `backyard_cigarette_line_seen`. Debug builds skip save load, so the glow returns each editor run. Drag `PlayerLayer/MemoryIndicator` in the editor to move it. Hub 1.3 still loads this file by path. No embedded post-FX. No hint scene.

---



### 3.2 Backyard Memory (`loc_yard_memory`)

**Location label:** `BACKYARD`
*(Memory still — no player / no interact chip)*

**Dialogue:**

> AXEL: Oh. Sorry. I'll go.
>
> No. I don't mind.
>
> [beat]   
> Haven't seen you in school for awhile.
>
> AXEL: Didn't think you'd notice.
>
> What does that mean?
>
> AXEL: Nothing.
>
> [beat]
>
> AXEL: Are we still friends?

**Choices:**


| Button label      | Target         |
| ----------------- | -------------- |
| Go back `[X]` / E | Backyard (3.1) |


**Implemented (Godot):** `3.2_BackyardMemory.tscn` + `.gd` — still-image memory (no player / no interact chip). Hand-drawn `3.1_Backyard_Memory.png` (3508×2480, white fill + black ink; artist filename kept) runtime top-crop to 1.85:1 (`region_rect`), locked background (`STATIC_LOCKED`/`CONTAIN`, `max_auto_zoom=1`, `margin_px=12`), then fitted large in the space above the dialogue bar (small side margins, some black at top and just above the bar). Scene-local `3.2_backyard_memory_frame.gd` (copy of 2.2’s frame script; 2.2 file is not renamed). No overlay letterbox bars; world-space white void fill so post-FX empty areas stay dark, not red. Canon lines play once via `GameManager.backyard_memory_line_seen`. Axel’s lines omit the on-screen `AXEL:` tag (`|other|`) and type in bright red; player/narration stays white. After the bar fully closes, a red `[X]` on CanvasLayer 110, **left-click / tap**, or **Tab / E / Space / Enter** return to `3.1_Backyard.tscn` at the saved standing spot. Leave is gated until `_can_exit` (dialogue finished). On leave, `add_memory_once("backyard_memory")`. Cigarette lines do **not** play here — they play on 3.1 after return. No extra 250ms glitch; only the normal scene-change glitch. No embedded post-FX.

---

