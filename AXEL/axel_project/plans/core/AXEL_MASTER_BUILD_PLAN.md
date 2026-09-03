# AXEL Master Build Plan

Build brief for the agent that finishes AXEL. Written 2026-09-03 from a full read of the
live project, not from memory of earlier chats.

**Canon order for this document:** `plans/core/AI_DOCS.md` wins on engine and scene
contracts (player spawn, cover-fit, hitbox, walls, collider uniqueness, post-FX layering,
window scaling). This file wins on *what to build and what the author decided*. As of
writing there are **no live conflicts between the two** — an earlier draft of this plan
proposed overriding canon on window stretch and that was reversed (D21, § 1.5). If you find
a new conflict, surface it and ask; do not silently pick a side.

---

## 0. How to use this document

**Read order before touching anything:**

1. `plans/core/AI_DOCS.md` — engine and scene contracts. Treat as non-negotiable.
2. This file, all of it. § 1.5 first if you are touching resolution or scaling.
3. `plans/scenes/SCENE_BUILDING.md` — only when building or editing a room.
4. `plans/combat/AXEL_combat_design.md` + `AXEL_combat_implementation.md` — only for combat work.
5. `plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md` — only for item work. Catalog edits go
   here and nowhere else.

**Your authority.** The author has stated your reasoning is the final say on *how* to
implement. You may restructure phases, reject an approach in this plan, and propose better
ones. You are expected to push back in writing when this plan is wrong.

**The limit on that authority.** Ask the author before adding any feature not listed in
§ 2. One standing exception: rebindable keys and controller support are pre-approved
(see D19). "Ask first" means ask — not implement-then-mention.

**Verification is not optional.** Every phase below has acceptance criteria. Run them.
Report exit codes. If a claim cannot be verified, write "could not verify" instead of
assuming. The existing gates are in `AGENTS.md`; the Windows launcher is
`tools/cmd/godot.cmd`, and `Godot_v4.7.2-stable_win64_console.exe` at the repo root is the
build that gives you stdout on Windows.

---

## 1. Verified current state

Everything in this section was read or executed on 2026-09-03. Line numbers are from that day.

### 1.1 What is playable today

Main Menu → 1.1 exterior → 1.2 corridor → 1.3 locker → 1.3 map → 1.4 basement door →
2.1 cafeteria → 2.3 kitchen (flashlight) → 2.4 classrooms corridor → 4.1 teacher's lounge
(key) → 5.1 classroom → 5.2 desk, plus 3.1 backyard, the three memory stills (2.2, 3.2,
4.2), and Ending 1 via the 1.1 left walk-off.

That is **16 real narrative scenes**. Every one has hand-drawn background art, a real
script, wired dialogue, and working exits.

### 1.2 What is built but unreachable

**Combat is essentially finished and completely orphaned.** `combat/scripts/combat_root.gd`
(~2260 lines) runs a full 5×5 cascading slot: line detection with wild substitution
(`line_detector.gd`), gravity cascades, a cascade multiplier, a three-section premium meter,
the Trinity round, Free Spins with per-princess spin counts, and all three princess powers
(Love transform, Star wilds, Storm low-pay removal in `princess_controller.gd`). RNG is a
single seeded stream (`rng.gd`), seeded once per encounter in `setup_new_grid()`, and
`spin_sync()` mirrors `spin()` for headless tests. 75 item resources in `combat/data/items/`
all resolve through `item_effect_dispatcher.gd`.

None of it is reachable in a normal playthrough. No scene under `scenes/` calls
`change_scene_to_file` into `res://combat/`. `AxelMusic.to_combat()` exists and is never
called by any game scene. The only entry is opening `combat/combat_test.tscn` by hand.

### 1.3 What does not exist at all

Save slots. Options. Credits. Pause. Inventory UI. A runtime CRT toggle. `RunState`. The
shop. Acts. Encounter progression. Any `AudioServer` call. Any custom input action. Any
`addons/` folder. Any generic screenshot tool for Windows.

**18 narrative scenes are `ScenePlaceholder.gd` black panels** — no art, no player, no
exits, and in most cases no dialogue:

- All 8 of Arc 6: `6.1_BasementDoor` … `6.8_BasementCorpse`. Zero `.gd` files in `scenes/Arc_6/`.
- Endings `7.2_Ending2`, `7.3_Ending3`, `7.4_Ending4`, `7.5_EndingTrue`, `7.6_Epilogue`.
- Board puzzle `5.3_ClassroomBoard`, `5.4_ClassroomBoardSuccess`.
- Orphans superseded by in-room implementations: `3.2_BackyardHint`,
  `4.3_TeachersKeyWall`, `4.4_TeachersKeyPickup`.

`1.3_SchoolMap.tscn` is a black `ColorRect` with runtime-built text buttons. There is no map
image in it. `exports/Drawings/map.png` (1792×2400) exists and is referenced by nothing.

### 1.4 Verified engine and config facts

`project.godot` is minimal. It contains `[application]`, `[autoload]`, `[debug]`,
`[display]` (only `viewport_width=1920`, `viewport_height=1280`), `[physics]`
(`3d/physics_engine="Jolt Physics"`), and `[rendering]`
(`rendering_device/driver.windows="d3d12"`,
`environment/defaults/default_clear_color=Color(1, 1, 1, 1)`).

- **There is no `[input]` section.** Every game key is a raw keycode read in a script.
  `scripts/Player.gd` reads WASD plus `ui_*` arrows directly; interact and exit keys are
  raw `KEY_E` / `KEY_ESCAPE` / `KEY_BACKSPACE` / `KEY_DELETE` checks scattered across scene
  scripts. `ui_cancel` is bound to Escape by engine default and is referenced by no GDScript.
- **Stretch is `disabled`, aspect `keep`.** Neither key is written to `project.godot`, so
  the engine defaults apply — Godot's `canvas_items`/`expand` default change (commit
  `29795e4`, 2026-04-21) explicitly does not affect existing projects.
- `display/window/size/resizable` is `true`, `borderless` false, `vsync_mode` 1.
- `rendering/textures/canvas_textures/default_texture_filter` is 1 (Nearest).
- Five autoloads: `GameManager` (`exports/GameManager.gd`), `AxelPostFxStack`,
  `AxelEventFx`, `AxelMusic`, `AxelCombatDevTools`.
- `get_tree().paused` appears **nowhere** in the project.

**Audio bus tree.** A headless probe of the live bus tree returned:

```
bus_count=4
bus 0 name=Master mute=false volume_db=0.0000
bus 1 name=Music mute=false volume_db=0.0695
bus 2 name=Typewriter mute=false volume_db=0.0000
bus 3 name=TypewriterOpen mute=false volume_db=0.0000
```

Four buses, nothing muted. **There is no Effects or SFX bus**, so the D4 Effects slider has
nothing to control until Phase 0.5 builds one. No script in the project calls `AudioServer`
at all, so there is no runtime volume control of any kind.

One thing to be careful about: the author mutes Master by hand in the editor while working,
which writes `bus/0/mute = true` into `default_bus_layout.tres`. If you ever find the game
silent, check that line before hunting for a bug — and never commit it as `true`.

### 1.5 Uncommitted work already in the tree — read this before Phase 0.3

`git status` shows **uncommitted modifications made by a parallel agent session** that was
running at the same time this plan was written. The author confirmed it. They are real,
verified code, not intentions. Do not bulldoze them.

**The snapshot below is from 2026-09-03 and may already be stale.** Before starting, run
`git status` and read the newest entries in `plans/core/AI_CHANGELOG.md` yourself. That
session may have continued after this document was written.

Modified and not yet committed: `plans/core/AI_DOCS.md`, `plans/scenes/SCENE_BUILDING.md`,
`plans/core/AI_CHANGELOG.md`, `tools/qa/run_default_playtest.ps1`, and per that changelog
entry ("Fullscreen framing, dialogue size, and spawn fixes") also
`scenes/ui/TopDialogueOverlay.gd`, `scenes/Arc_2/2.4_ClassroomsCorridor.gd`,
`scenes/core/background_layout.gd`, `scenes/core/background_camera_controller.gd`,
`scenes/Arc_1/1.1_SchoolExterior.gd`, `project.godot`, plus two new tests.

**That session solved the fullscreen problem while keeping stretch disabled.** Verified in code:

- `TopDialogueOverlay.gd` recomputes its own font and outline size from live viewport
  height. `_dialogue_window_scale()` returns
  `clampf(viewport_size.y / DESIGN_VIEWPORT_H, 0.5, 2.5) * TEXT_BOOST`, applied in
  `_apply_dialogue_scale()` as `font_size` and `outline_size` overrides and re-run on
  `get_viewport().size_changed`. The live dialogue baseline is 48 px at 1920×1280. The bar
  height grows to fit rather than clipping. **This is the exact problem that made canon ban
  `canvas_items` — it is now handled another way.**
- `background_layout.gd` has `const MAX_EDGE_REVEAL := 0.05` and an `edge_reveal` parameter
  on `apply()`; `background_camera_controller.gd` has `@export var edge_reveal: float = -1.0`
  with `_resolved_edge_reveal()`. Static-locked `cover` rooms can reveal a thin clear-colour
  strip instead of cropping hard on wide monitors. The strip reads as dark because the
  exploration clear colour is pure white under the noir/CRT stack — that is why
  `project.godot` has `default_clear_color=Color(1, 1, 1, 1)`. Movable-follow rooms (1.1,
  2.4) stay on plain cover.
- New regression tests exist: `scenes/core/test/background_fit_check.gd` (asserts the cover
  and edge-reveal math at 16:9 and 3:2) and `scenes/core/test/corridor_depth_seed_check.gd`.
- `tools/qa/run_default_playtest.ps1` was fixed (its `$repo` path resolution was wrong) and
  now runs ten checks including both new ones. **Use this script as the gate rather than
  listing checks by hand.**

**This approach is now the locked decision — see D21.** An earlier draft of this plan told
you to switch to `canvas_items` + `expand`. The author has since reversed that, because the
parallel session addressed the same problems without touching stretch. Stretch stays
`disabled`. Do not re-open it without asking.

Why it matters mechanically: under stretch `disabled`,
`get_viewport().get_visible_rect().size.y` is the real window height, and that is precisely
what makes `_dialogue_window_scale()` and the `edge_reveal` cover math work. Switching to
`canvas_items` would normalise that height to the base size, turning the dialogue scaling
into a constant and making `edge_reveal` double-compensate for aspect crop that `expand`
already handles. Both mechanisms depend on stretch staying off.

---

## 2. Locked decisions

These came from a direct Q&A with the author on 2026-09-03. Cite them by ID (D1, D2, …)
when you deviate or when you report back.

### Front-end

- **D1 — Title.** Reimagine `scenes/Main_Menu/0.1_MainMenu.tscn` with five entries:
  Continue, New Game, Load Game, Options, Credits. Compose the look from art that already
  exists: `exports/Drawings/1.1_SchoolExterior.png` as a slow-drifting backdrop under heavy
  noir + CRT + glitch, with an AXEL logotype in VT323. No new background art.
- **D2 — Saves.** A dedicated Saves scene managing exactly 3 slots, reachable from New
  Game, Load Game and Continue. Continue resumes the most recently played slot.
- **D3 — Save timing.** Autosave on every room change **and** manual save from the pause menu.
- **D4 — Options.** Master / Music / Effects volume; resolution; graphics quality; CRT
  on/off; window mode (fullscreen / borderless / windowed); VSync toggle and FPS cap;
  reduce flashing, screen shake and glitch intensity; UI scale; dialogue text speed and
  auto-advance toggle. **No brightness or gamma slider** — the dark scenes are getting real
  art later, so brightness is not the fix.
- **D5 — Credits.** EGGK — author. Music — EGGK and Tomi Räsänen. Background art — Viivi
  Hassinen. Add engine and font attribution as required by their licences; ask before
  adding any other name.
- **D6 — Pause.** ESC opens a pause menu everywhere in the game, combat included. Entries:
  Resume, Options, Inventory, Map, Quit to Title, Quit to Desktop. Blocked while dialogue is
  typing so it cannot desync the typewriter. Quitting mid-encounter counts as a combat loss
  (see D8). Inventory must show Flashlight / Key / Shovel / Name and the memory count — no
  such UI exists today. Map is available from pause only once the map has been found.

### Combat

- **D7 — Entry.** The locker is the gate. The player opens the locker in
  `scenes/Arc_1/1.3_LockerHub.tscn`, equips items, and starts a run of encounters across
  Act I (The Locker), Act II (Cafeteria + Classrooms), Act III (The Basement), per
  `plans/combat/AXEL_combat_design.md`.
- **D8 — Loss is permanent.** Losing a combat encounter ends the game and **deletes that
  save file immediately.**
- **D9 — Tombstone.** The dead slot is not blanked. It shows `DIED` with that run's stats —
  memories found, items held, playtime. It cannot be resumed, only overwritten by a New Game.
- **D10 — Warning is in-fiction.** The player learns the stakes from an AXEL dialogue line
  before the first encounter. No system popup, no confirmation dialog.
- **D11 — Locker loadout.** The locker interior displays every item the player owns on its
  shelves and hooks. Click to equip, up to 7 slots (9 with the expander item —
  `item_inventory.gd` `BASE_MAX_SLOTS := 7`). Hovering an item reveals what it does.
- **D12 — Grid symbols are frozen.** All 8 textures in `combat/art/grid_symbols/` stay
  exactly as they are, including the four programmatic low-pay placeholders. Do not
  redraw, upscale, or resize them.
- **D13 — Combat effects to add.** Nothing may be moved or redrawn; effects layer on top.
  Multiplier-scaled screen shake and glitch flash. Symbol juice (easing, squash/stretch,
  win pulses, a drawn connecting line across winning symbols). Full-screen Trinity and Free
  Spins entry sequences. A princess portrait HUD showing which power is armed. Ambient
  dread — idle motion on the skull, CRT wobble on big wins, grime creeping in as the goal
  approaches.
- **D14 — Cascade wave.** Symbols land as a left-to-right wave: column 0 lands first, each
  following column delayed by **0.33 s**, so a full grid settles in roughly 1.5 s. The
  author's phrasing was "the bottom left symbol hits the bottom first and then the one next
  to it on a 0.33 sec difference"; per-column was confirmed as the intent.
- **D15 — No combat SFX yet.** Build the hooks and leave them empty. The author is making
  the sounds. Do not source, synthesize or commit placeholder audio.
- **D16 — Item icons.** Regenerate all 75 at 256×256 using AI image generation, then run
  them through the 8-band noir palette so they match the game.

### Everything else

- **D17 — 3D map diorama.** `1.3_SchoolMap` becomes a real 3D scene. Each known room is a
  plane or card in 3D space showing that room's actual background PNG, arranged as the
  school's layout and connected by corridors. The player orbits it and clicks a room to
  travel there. The basement is present but locked.
- **D18 — Missing scenes get grey-box art.** Build the 18 stubs fully playable using
  obvious grey-box placeholders, clearly marked so Viivi can replace them. The basement
  scenes *will* get real art later, so do not design around darkness as a permanent look
  and do not treat grey-box as shippable.
- **D19 — Latitude.** Ask before adding anything not in this section. Pre-approved
  exception: rebindable keys and controller support, ideally via an existing addon.
- **D20 — Build order.** Front-end first, then combat integration and the locker, then the
  map, then the missing content. Rationale: it makes the game shippable soonest.
- **D21 — Scaling stays as canon has it: stretch `disabled`.** Do **not** switch to
  `canvas_items` / `expand`. Multi-resolution support is handled by the two mechanisms a
  parallel session already built and verified — in-overlay dialogue font scaling from live
  viewport height, and the `edge_reveal` budget on static-locked cover rooms (§ 1.5). Your
  job is to verify those hold up across every target resolution and window mode and to fill
  whatever gaps remain, not to replace them. `AI_DOCS.md` and `SCENE_BUILDING.md` are
  correct on this point and need no reversal.

**Viral Forge folder.** `exports/Viral Forge/` holds 12 strategy documents from May 2026.
Use them as flavour only: they argue for maximum cascade juice and a tone where wins feel
wrong, which agrees with `AI_DOCS.md`. Build no sharing or virality features from them.
Their Steam-release and web-prototype recommendations are out of scope.

---

## 3. Hard constraints

Breaking any of these is a regression, not a design choice.

- **Combat stays deterministic.** One seeded stream per encounter. No `randi()` /
  `randf()` outside `combat/scripts/rng.gd`. Every FX addition from D13 and D14 must be
  visual only — if `determinism_check.gd` output changes, the change is wrong.
- **`combat/combat_test.tscn` is a protected scaffold.** Keep `%CombatRoot`, `%MetaBox`,
  `%SeedSpinBox`, `%SpinButton`, `%BankrollLabel`, the stake row, and the Free Spins choice
  buttons. Run `combat/test/combat_test_scaffold_check.gd` before and after combat edits.
- **Narrative and combat layers do not blur.** No slot logic in exploration scripts. No
  story flags inside combat RNG. The bridge is an explicit, narrow API.
- **Player node is the spawn.** Never hardcode a spawn `Vector2`, never skip the first
  cover-fit remap, never derive the player position from another node.
- **Live destination box, every play.** Measure the destination `InteractArea` /
  `ExitTrigger` with `InteractArrival` after cover-fit. Never reuse arrival coordinates
  from chat, changelog, or an older `.tscn`.
- **Shared player hitbox and cover scale.** `scenes/player/hitbox_front.tres` is radius
  only. Do not author per-room player polygons. Do not retune a `.tscn` Player `scale` to
  make one window look right.
- **Independent `CollisionShape2D`.** Every collider owns its own `Shape2D`. Make Unique
  after duplicating. Only `hitbox_front.tres` is shared.
- **Post-FX authoring colours.** PNG or empty fill is pure white, never black. Placeholders
  and outlines are black. Noir inverts, so this is backwards from intuition — grey-box art
  in Phase 6 must follow it or the rooms will render wrong.
- **No baseline post-FX in `.tscn` files.** `AxelPostFxStack` attaches them.
- **No machine-absolute paths** in shipped gameplay code.
- **Catalog edits only in** `plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.

---

## 4. Known traps

Each of these was verified. Several will silently waste a day if you do not know about them.

**Do not "fix" multi-resolution by enabling stretch.** It is the obvious move and it is
wrong here. `AI_DOCS.md` bans it, a parallel session solved the same problems another way,
and the author has explicitly confirmed stretch stays `disabled` (D21, § 1.5). The existing
dialogue font scaling and `edge_reveal` cover math both read the real window size and would
break or double-compensate under `canvas_items`. Likewise, never retune a `.tscn` Player
`scale` to make one monitor look right — that is a separate standing canon ban.

**Controller support has a prerequisite you cannot skip.** There is no InputMap. Rebinding
and gamepad support are impossible until every raw keycode is migrated to named actions.
That migration is Phase 0, task 2, and it touches `scripts/Player.gd` plus roughly a dozen
scene scripts. Candidate addons, most to least heavyweight:
[G.U.I.D.E](https://github.com/godotneers/G.U.I.D.E/) (unified input, runtime rebinding,
input prompts), [Controller Icons](https://github.com/frepiso/godot-v4.x-controller-icons-addon)
(glyphs only, auto device detection),
[Runtime Controls Remap](https://store.godotengine.org/asset/dastmo/runtime-controls-remap/)
(lightweight, updated July 2026). Evaluate and recommend; do not assume.

**`GameManager` cannot support save slots as written.** It writes one fixed path
(`user://axel_game_state.json`), stores no player position and no current scene, has no
`reset_state()` / `new_game()` / `delete_save()`, and `MainMenu.gd` never clears it — so in
a release build "New Game" silently inherits the previous playthrough. `_persistence_enabled()`
returns `not OS.is_debug_build()`, which means **saving is entirely off in the editor**;
you will need a debug override to test slots at all. Of the seven flags in
`_default_game_state()`, only `hasFlashlight` and `hasKey` are ever written; `hasShovel`,
`hasName`, `knowsName`, `deskSequencePlayed` and `isDead` have no writers anywhere.

**No Effects bus and no runtime volume control.** The bus tree is Master, Music, Typewriter,
TypewriterOpen (§ 1.4). The D4 Effects slider has nothing to control until Phase 0.5 builds
it, and nothing in the project calls `AudioServer`. Separately: a muted Master in
`default_bus_layout.tres` is usually the author muting audio by hand while working, not a
bug — check that line first if the game is silent, and do not commit it as `true`.

**Combat has two disagreeing win conditions.** `_finalize_encounter_if_needed()`
(`combat_root.gd:1953`) decides a win from `is_chip_bar_goal_complete()`
(`combat_root.gd:402-408`) — cumulative winnings against a 10× chip-bar target. Meanwhile
`goal_tracker` is fed every spin but only affects an early Free Spins exit. The three
`GoalDef` subclasses that exist (`goal_payout_threshold.gd`, `goal_wild_count.gd`,
`goal_grid_clear.gd`) are a fraction of what the design doc describes. Phase 2 has to pick
one system and make the other follow it.

**Goals scale with lore items — this is canon and easy to miss.** Per `AI_DOCS.md`, every
lore item that counts toward the true ending also raises combat encounter goals, so the
true-ending path is deliberately harder. The school map is the exception: it unlocks locker
fast travel and does *not* raise goals.

**The memory counter is short one source.** It prints `X/5` but only four scenes call
`add_memory_once` (`scene_3`, `cafeteria_memory`, `backyard_memory`, `teachers_memory`).
The fifth needs to come from Phase 6 content.

**The exports folder is excluded from indexing** by the root `.cursorignore` (only
`game_data.json` and `GameManager.gd` are re-included). Art paths under
`exports/Drawings/` will not appear in search results — `@`-mention them explicitly. Also
note `AXEL/axel_project/plans/archive/**` and `plans/core/archive/**` are excluded on
purpose; do not resurrect them.

**Item icons have no source art in the repo.** `tools/combat/bake_item_icons.gd` bakes 75
icons at a hardcoded `SIZE := 48`, starting from a hash-based noir placeholder and only
using real art if a LimeZu Modern Interiors/Exteriors single is found via
`tools/combat/item_icon_sources.json`. Those LimeZu PNGs are **not in the repo.** So today's
icons are placeholders or downscaled third-party tiles. D16 replaces them outright, which
also removes a third-party licence dependency from the credits.

**Two weight problems for Phase 7.** The music stems are six ~43 MB WAVs plus five ~1.2 MB
casino stems — roughly 250 MB of uncompressed audio in `assets/audio/music/`. And
`exports/Drawings/2.4_ClassroomsCorridor.png` is 7016×4960, which is a large VRAM
allocation for one room and a serious problem if the Phase 5 diorama loads every room
texture at once.

**`--headless` does not compile shaders.** After any CRT or shader edit, also run a short
windowed pass with `--quit-after` and grep the console for `SHADER ERROR`. The dummy
renderer will happily report success on a broken shader.

**`playthrough_dialogue_loop.gd` fails under pure `--headless`** by design — it waits for a
fade-in that never settles with the dummy renderer. It is not part of CI. Do not "fix" it.

---

## 5. Build phases

Ordered per D20. Each phase lists its goal, the work, and how you prove it is done.

### Phase 0 — Foundations

Nothing else is safe or verifiable until this exists.

**0.1 Windows capture tool.** Build a generic scene-to-PNG capture: take a scene path, an
output path, a frame count and a resolution; load, settle, grab
`get_viewport().get_texture().get_image()`, save. `AGENTS.md` documents
`tools/capture_scene.sh` and `res://tools/capture_scene.gd` — **neither is in the repo**;
they are Linux CI artifacts. Model the new tool on the two Windows captures that do exist,
`tools/qa/hud_capture.gd` and `tools/visual_style/capture_scene_1_1_style_sweep.gd`, and
drive it from a `.ps1` beside `tools/qa/run_default_playtest.ps1`. It must not use
`--headless` (no GPU, no shaders). Use the console executable so you can read stdout. This
tool is how you satisfy the author's request to study screenshots and reference them back
to files — you will use it in every phase after this one.

**0.2 InputMap migration.** Create named actions — move up/down/left/right, interact,
advance dialogue, pause, back/cancel, and whatever combat needs — and replace every raw
keycode check in `scripts/Player.gd` and the scene scripts. Preserve exact current
behaviour: WASD plus arrows for movement, Tab/E/Space/Enter/click all advancing dialogue,
Esc/Backspace/Delete backing out of the hub and map. Then add gamepad bindings and the
rebinding UI (D19).

**0.3 Resolution and scaling — verify, do not rewrite** (D21). Stretch stays `disabled` and
the base stays 1920×1280. The mechanisms are already in place (§ 1.5); this task is to prove
they hold and to close whatever they miss.

Using the 0.1 capture tool, walk every real room plus every new front-end screen at
**1366×768, 1920×1080, 2560×1440, 3840×2160, and one 16:10 size** (1920×1200), in windowed,
borderless and fullscreen. For each, check: dialogue text is readable and not clipped, the
`edge_reveal` strip reads as a deliberate dark edge rather than a bug, Mike and the memory
glow stay at the right size relative to the room, interact chips sit on their triggers, and
nothing important falls outside the frame.

Expect gaps in places the parallel session had no reason to touch, since the front-end did
not exist yet — the Saves, Options and Credits screens, the pause menu, and the combat HUD
all need anchoring that survives these resolutions. `combat_test.tscn` HUD anchors are
already checked at 1280×720 and 800×600 by `combat_test_scaffold_check.gd`; extend that
coverage rather than assuming it.

Report what you found per resolution with captures attached. If something genuinely cannot
be solved without stretch, say so and ask — do not switch unilaterally.

Also confirm `scenes/core/exploration_viewport.gd` stays inert, and add a UI scale slider
(D4) that composes with the existing dialogue scaling instead of fighting it.

**0.4 Settings persistence.** A `ConfigFile` at `user://axel_settings.cfg`, loaded before
the first frame paints, applied by a small autoload. Settings are separate from saves and
survive save deletion (D8) — losing a run must not reset the player's volume.

**0.5 Audio bus tree.** Add an `Effects` bus and reparent `Typewriter` and
`TypewriterOpen` under it, plus new buses for combat and UI SFX so D15's empty hooks have
somewhere to land. That yields the three sliders D4 asks for: Master, Music, Effects. Then
add the `AudioServer` volume plumbing, which does not exist anywhere yet, and persist the
levels via 0.4. Re-verify the typewriter mix afterwards — `TopDialogueOverlay.tscn` sets
per-clip volumes (`OpenClosePlayer` at −16 dB, `TypeLoopPlayer` at 0 dB) that assumed
direct routing to Master.

**0.6 Global pause.** A pause autoload owning `get_tree().paused`. Nothing uses it today,
so establish the contract now: which nodes get `PROCESS_MODE_ALWAYS`, how post-FX and music
behave while paused, and the guard that refuses to pause while
`TopDialogueOverlay.is_sequence_busy()` is true (D6).

**Done when:** the capture tool produces a correct PNG of an arbitrary scene at an
arbitrary resolution; no raw keycode gameplay checks remain; the game is visually correct at
all five test resolutions in all three window modes, with captures to prove it; settings
survive a restart; audio is audible and the three sliders work; ESC pauses and un-pauses
without breaking dialogue; and `tools/qa/run_default_playtest.ps1` reports every check
passing (it now covers the background-fit, cover-sync, walk-speed, spawn-sync,
interact-arrival and corridor-depth regressions — do not hand-roll that list).

### Phase 1 — Front-end

**1.1 Title** (D1). Five entries. Continue is disabled when no slot exists — today it is
unconditionally disabled and pops an "not implemented" dialog. New Game must reset
`GameManager` state, which it currently does not.

**1.2 Saves scene** (D2, D3, D9). Three slots. Each slot shows enough to choose between
runs: memories found, items, playtime, last room, timestamp. Store that metadata as a small
header inside the slot file so the picker never parses a whole save. Write atomically — temp
file, then `DirAccess.rename_absolute` over the real one — and stamp a `version` field from
day one. Add the room and player-position fields `GameManager` is missing. Tombstone slots
render as `DIED` with the run stats and offer only overwrite.

**1.3 Options** (D4). Group into Audio, Video, Gameplay, Accessibility, Controls. Three notes:

Because stretch is `disabled` (D21), the viewport *is* the window — so a "resolution"
setting genuinely changes how much of each room is visible, not just how big it looks. That
makes it a real gameplay-affecting setting rather than cosmetic. Offer sensible window sizes
filtered to those the player's monitor can actually display, keep window mode as its own
control, and make sure every size you offer has been checked in 0.3.

"Graphics quality" in a 2D game is mostly shader cost, so map the presets to CRT and noir
shader complexity, scanline and noise passes, MSAA, and the Phase 5 diorama's 3D render
scale — not to texture resolution.

The reduce-flashing control is an accessibility requirement, not a nice-to-have: this game
ships glitch bursts, jumpscares and CRT roll, and it must be possible to turn those down
without turning the game off.

**1.4 Credits** (D5). EGGK, Tomi Räsänen, Viivi Hassinen. Include Godot and VT323 (SIL Open
Font Licence) attribution. Ask before adding anyone else.

**1.5 Pause menu** (D6). Wire it into the Phase 0.6 autoload. Build the inventory panel —
Flashlight, Key, Shovel, Name, memory count — since none exists. Gate Map on the map having
been found.

**Done when:** a full loop works from cold start — New Game, play, autosave, manual save,
quit to title, Continue, Load Game, all three slots independent, options persisting across
restart, ESC pausing everywhere, and credits reachable. Capture every new screen at two
resolutions.

### Phase 2 — Combat integration

**2.1 `RunState`.** `plans/combat/AXEL_combat_implementation.md` marks this "planned but
not built". It owns the run: act, encounter index, currency, stake, equipped items,
bankroll between encounters. It must serialise into the save slot so a run survives quit
and resume.

**2.2 Locker loadout** (D7, D11). `1.3_LockerHub.tscn` currently has a background, one
`UiPolygonHotspot` for the map paper, a red X, and no player node. Add the open-locker
interior view with owned items on shelves, click-to-equip up to 7 (9 with the expander), and
hover descriptions sourced from the item catalog. This is also where D16's icons get used.

**2.3 Bridge.** A narrow API in both directions: overworld → combat carrying the encounter
definition, act, goal and equipped items; combat → overworld carrying the result. Call
`AxelMusic.to_combat()` and `to_overworld()`, which already exist and are unused. Respect
the layer separation in § 3 — no story flags inside combat RNG.

**2.4 Acts and goals.** Act I Locker, Act II Cafeteria + Classrooms, Act III Basement, per
the design doc. Reconcile the two win conditions (§ 4). Implement goal scaling from lore
items, with the school map exempt (§ 4).

**2.5 Permadeath** (D8, D9, D10). On loss: delete the slot file, write the tombstone, return
to title. Also triggered by quitting mid-encounter from the pause menu (D6). The in-fiction
warning line goes in before the first encounter and must not fire twice — use the same
once-ever flag pattern as the existing `*_line_seen` setters.

**Done when:** a player can walk from the menu to the locker, equip items, fight an
encounter, win and return to the school, and separately lose and watch the slot become a
tombstone. `determinism_check.gd`, `princess_check.gd`, `combat_test_scaffold_check.gd`,
`item_synergy_smoke.gd` and `scene_smoke_check.gd` all still exit 0.

### Phase 3 — Combat look

Art may not move or change (D12). Everything here layers on top.

**3.1 Cascade wave** (D14). The plumbing is already there:
`symbol_slot.play_drop(from, to, duration, delay)` takes a delay
(`symbol_slot.gd:52`), and `combat_root.gd` already staggers. Today the populate path uses
`delay := (float(r) + float(c) * 0.25) * fx_stagger_sec` with `fx_stagger_sec = 0.01`
(`combat_root.gd:1210`, `:35-38`) — a wave so fast it reads as simultaneous. Change it to a
per-column delay of 0.33 s, and apply the same wave to the gravity path
(`combat_root.gd:1439`, currently a flat `0.0` delay) and the spawn path (`:1452-1456`) so
cascades and refills match. Expose the step as an `@export` so the author can retune it
without a code change. Watch the total: the awaits at `:1214` and `:1458` gate the spin, so
a 1.5 s wave lengthens every spin — capture a before/after and check the spin still feels
responsive.

**3.2 Multiplier-scaled shake and glitch** (D13). Called for in the combat plan, never
built. Scale magnitude to the multiplier so a big cascade physically destabilises the
screen. Must respect the D4 reduce-flashing setting.

**3.3 Symbol juice** (D13). Better drop easing, squash and stretch on landing, win pulses,
and a drawn line connecting winning symbols. `symbol_slot.gd` already has a solid
five-phase win popup to match in quality.

**3.4 Trinity and Free Spins entries** (D13). Today these are a grid flash and a border
pulse (`_play_grid_white_flash_async()`, `_refresh_grid_border_for_state()`). Make them
full-screen moments that read as dread, not celebration.

**3.5 Princess portrait HUD** (D13). Planned, never built, and there are no portrait
sprites — only the three symbol icons. This is the one item in D13 that needs new art;
propose an approach before generating anything.

**3.6 Ambient dread** (D13). Idle motion on the skull meter, CRT wobble on big wins, grime
creeping in as the goal gets closer.

**3.7 Empty SFX hooks** (D15). Signals and named playback points, no audio files.

**Done when:** `determinism_check.gd` output is byte-identical to before Phase 3, captures
show each new effect, and a windowed `--quit-after` pass reports no `SHADER ERROR`.

### Phase 4 — Item icons

Regenerate all 75 at 256×256 (D16), remap through the 8-band noir palette so they sit in the
game's world, and wire them into the locker (2.2) and the combat item picker.
`tools/combat/bake_item_icons.gd` hardcodes `SIZE := 48` and expects LimeZu sources that are
not in the repo — expect to rework the pipeline rather than reuse it. Keep ids stable:
`combat/data/items/*.tres` reference icons by id, `L-A` deliberately has no file, and
`item_synergy_smoke.gd` asserts its absence.

**Done when:** 75 icons exist at 256×256, every `.tres` resolves its icon, the locker and
picker render them crisply at all five test resolutions, and `item_synergy_smoke.gd` exits 0.

### Phase 5 — 3D map diorama

The author's decision (D17) is a real 3D scene, and the project has **zero 3D nodes** today.
`3d/physics_engine="Jolt Physics"` is already configured; the renderer is Forward+.

Each known room becomes a plane in 3D space textured with that room's actual background PNG,
laid out as the school and joined by corridors. Camera orbits; clicking a room travels there.
The basement is present and locked, replacing the permanently disabled `ENTER THE BASEMENT`
button in `1.3_SchoolMap.gd`. Preserve the existing exits: X / Esc returns to the locker hub,
and the hub returns to the corridor.

Two things to get right. **Texture budget:** the room PNGs are 3508×2480 and one is
7016×4960 — loading them all at full size will hurt. Bake downscaled diorama textures rather
than reusing the originals directly. **Post-FX:** `AxelPostFxStack` attaches 2D overlays on
scene change; confirm noir, scanline and CRT still composite correctly over a 3D viewport, or
the map will look nothing like the rest of the game.

Canon to honour: the map is a collectible that unlocks locker fast travel once found, and it
does not raise combat goals (§ 4).

**Done when:** the diorama renders and orbits, every unlocked room is clickable and travels
correctly, the basement reads as locked, post-FX matches the rest of the game, `scene_smoke_check.gd`
exits 0, and frame time is acceptable at 3840×2160 on the lowest graphics preset.

### Phase 6 — Missing content

18 stub scenes, grey-boxed and clearly marked (D18). **Follow the post-FX authoring colour
rule** (§ 3) or the grey-box rooms will render inverted.

- **Arc 6 basement, 6.1–6.8.** No scripts exist at all. Needs backgrounds, player, colliders,
  arrival boxes, the key / flashlight / shovel gates, the shovel pickup writing `hasShovel`,
  the digging sequence, and the corpse name puzzle.
- **Board puzzle, 5.3 and 5.4.** The AXEL text input and the success beat that finally
  writes `hasName` / `knowsName`. `5.1_Classroom.gd` only plays teaser lines today
  (`BOARD_LINES`).
- **Endings 7.2–7.6 and routing.** Darkness (no flashlight), Wrong Answer, No Name, True
  Ending, Epilogue. Only 7.1 is implemented; 7.2–7.6 have no inbound edge and no exit. Route
  them from the flags, and give each one a way back to the title — several currently dead-end.
- **Basement access.** The 1.4 door still answers `"Not yet."` and the map's basement entry
  is disabled. Open the path.
- **Fifth memory.** Add the missing `add_memory_once` source so the `X/5` counter can complete
  (§ 4).
- **Orphans.** `3.2_BackyardHint`, `4.3_TeachersKeyWall`, `4.4_TeachersKeyPickup` are
  superseded by in-room implementations and are not canon. Recommend deletion; ask first.
- **Deferred polish noted in the Arc 4 plan:** hide the key art after pickup, the way the
  flashlight does.

**Done when:** a playthrough reaches every one of the five endings plus the epilogue, all
four lore items are obtainable, the memory counter can reach 5/5, and every scene has a
route in and a route out.

### Phase 7 — Release optimization

- **Audio.** ~250 MB of WAV in `assets/audio/music/`. Convert to Ogg Vorbis for release and
  confirm the `AudioStreamSynchronized` layering and the timed crossfades in `axel_music.gd`
  still line up — the combat stem logic is beat-sensitive.
- **Textures.** Review import settings across `exports/Drawings/`, especially
  `2.4_ClassroomsCorridor.png` at 7016×4960. Mipmaps, compression and per-texture size
  limits, without breaking the Nearest filter the pixel look depends on.
- **Export presets.** None are configured. Add Windows at minimum.
- **Performance.** Measure at all five test resolutions on the lowest and highest graphics
  presets. The full-screen shader stack (noir + scanline + CRT, plus the interface pulse)
  is the main cost in a 2D game — make sure the graphics presets actually relieve it.
- **Debug gates.** `AxelCombatDevTools`, `DEBUG_USE_NOIR_8BAND_TEST` and
  `COMBAT_ROOM_FX_TEST` (`axel_post_fx_stack.gd:14-20`) are compile-time constants set to
  `true`. Confirm each behaves correctly in a release build.
- **Save robustness.** Corrupt a slot on purpose and confirm the game degrades gracefully
  instead of crashing. With D8 in play, a crash that eats a save is unforgivable.

---

## 6. Definition of done

1. A player who has never seen the game can start it, adjust options, start a new game in a
   chosen slot, play to an ending, and quit — without touching the editor.
2. It looks correct at 1366×768, 1920×1080, 2560×1440, 3840×2160 and one 16:10 size, in
   windowed, borderless and fullscreen, with captures on file.
3. All `AGENTS.md` gates exit 0, and combat determinism is unchanged from before this work.
4. Every screen and every room has a capture, reviewed against its source files.
5. `plans/core/AI_DOCS.md`, `plans/scenes/SCENE_BUILDING.md` and
   `plans/core/AI_CHANGELOG.md` reflect what was actually built, with a changelog entry per
   the template at the top of that file.
6. A written report listing what was built, what was skipped and why, every deviation from
   this plan with its reasoning, and every unrequested addition for the author to veto (D19).

---

## 7. Open questions to raise before or during the build

Do not guess these. Ask.

1. **Act structure vs. the 16 built rooms.** The design doc's Act II covers Cafeteria and
   Classrooms and Act III the Basement, but the basement does not exist until Phase 6. Does
   Act III wait for Phase 6, or does Act II close the loop for now?
2. **Encounter count and difficulty curve.** The design doc says 3 encounters per act plus a
   boss. Only one `EncounterDef` exists (`combat/data/encounters/encounter_payout.tres`).
   Confirm the shape before authoring the rest.
3. **The shop.** The design doc has a shop or dare room between encounters. It was not
   discussed in the Q&A and is not in D1–D20. Confirm whether it is in scope.
4. **Item acquisition.** The locker shows items the player *owns* (D11), but nothing in the
   overworld grants items today. Where do they come from — shop, encounter rewards,
   exploration finds?
5. **Autosave and permadeath interaction.** D3 autosaves on room change and D8 deletes on
   loss. Confirm the intended sequence when a player enters combat, since an autosave
   immediately before an encounter is the file that gets destroyed.
6. **Princess portrait art** (D13, 3.5) — the one effect that needs new art. Get approval on
   the approach first.
7. **Orphan stub deletion** — `3.2_BackyardHint`, `4.3`, `4.4`.
8. **Commit the parallel session's work first.** The fullscreen framing, dialogue scaling and
   `edge_reveal` changes in § 1.5 are still uncommitted. Confirm with the author that they
   are final and committed before you build on top of them, so a later `git checkout` cannot
   silently remove the foundation Phase 0.3 depends on.
