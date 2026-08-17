# AXEL AI Docs

Canonical guidance for AI agents. Read this file for substantive AXEL work. Load subsystem plans only when the task touches that area.

**Scope:** Primary: `plans/*`, `combat/*`, `scenes/*`, `scripts/*`. Also `assets/*` and `tools/*` when the task touches them. Ignore `exports/*` and `AXEL/html/*` unless a task explicitly says to use them.

## Canon hierarchy

When sources conflict, resolve in this order:

1. This file (`plans/core/AI_DOCS.md`) — wins over every other plan/doc so future plans obey this foundation
2. `plans/combat/AXEL_combat_implementation.md` — open only when the user states the prompt is combat-related; otherwise ignore
3. `plans/combat/AXEL_combat_design.md` — same combat-only open rule
4. `plans/references/AXEL_notes.md`

Combat design, combat implementation, and `AXEL_notes` can change and are guiding suggestions — not absolute truth.

Ignore `exports/*` and `AXEL/html/*` unless a task explicitly says to use them.



## Architecture (do not blur layers)

Keep narrative and combat cleanly separated. They will be wired later, but must not mix concerns (no slot logic in exploration scripts; no story flags inside combat RNG).

- **Narrative:** Godot exploration scenes (`scenes/*`) + autoload `GameManager` (`exports/GameManager.gd`) — flags, memories, once-ever scene keys, corridor return position, spawn sides. Active transitions use `change_scene_to_file()`. Ignore archived HTML/`game_data.json` UI. **Debug playtest:** `OS.is_debug_build()` skips loading/saving `user://axel_game_state.json` so dialogue flags reset each editor run.
- **Combat:** `combat/scripts/combat_root.gd` orchestrates spin lifecycle. Open combat plans only when the user states the prompt is combat-related.



## Combat invariants

Unless explicitly redesigning:

- 5×5 grid; deterministic RNG; line wins 3+ rows/cols (no flood-fill cluster wins).
- Wild: only exactly-3 winning lines spawn wild in the middle cell.
- Multiplier tied to cascade progression.
- Princess map: `cigarette`→Storm, `alcohol`→Star, `bloody hand`→Love. Prefer the name “alcohol” (not “booze”) in docs and user-facing text.
- Bonus sequence (unambiguous): **normal spins → Trinity round → Free Spins**. Trinity ≠ Free Spins. Never call Trinity “Free Spins.” Replace “SUPER Free Spins” with **Free Spins** everywhere. Free Spins starts if Trinity clears all non-wild symbols (no new symbols spawn during Trinity). During Trinity each princess power activates once in order: Love (then matches), then Star, then Storm.
- Item ids: extended `TIER-FAMILY` uppercase (`C-A`); baseline digit suffix (`C1`). New mechanic default = five tiers total (Common → Uncommon → Rare → Epic → Legendary) unless one tier or a subset is requested.
- Catalog edits only in `plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.
- **Protected scaffold:** `combat/combat_test.tscn` — keep `%CombatRoot`, `%MetaBox`, `%SeedSpinBox`, `%SpinButton`, `%BankrollLabel`, stake row, Free Spins choice buttons. Run `combat/test/combat_test_scaffold_check.gd` before combat edits.



## Style and FX

- Palette (production canon): 8-band inverted noir — 4 reds, 2 warm greys, 2 blacks. CRT/scanline/glitch/shake are core identity. Shader: `tools/visual_style/shaders/noir_palette_8band_test.gdshader` (on via `DEBUG_USE_NOIR_8BAND_TEST` / `AXEL_NOIR_8BAND=1`). The old 3-band noir (`scenes/fx/noir_palette_filter.gdshader`, black + `#ff0000` + `#4a0000`) is retired — do not document or ship against it.
- **Post-FX (non-combat):** Autoload `AxelPostFxStack` — noir + scanline + CRT on scene change; `ensure_attached_to_current_scene()` re-attaches if overlays are missing after an aborted swap. **Exclude** `res://combat/*`. Do not embed those three overlays in overworld `.tscn`. Env `AXEL_DISABLE_POST_FX=1` for isolated tests. CRT player tuning (overworld white sprite only): edit `scenes/fx/CrtPluginOverlay.tscn` → `FilterRect` material — `chroma`, `player_chroma`, `player_white_boost`, `player_crt_reduction` in `crt_plugin_overlay.gdshader` (not the Remote tree while playing).
- **Event FX:** Autoload `AxelEventFx` — transition glitch, jumpscare API, interface pulse cadence. Details: `plans/references/AXEL_OVERWORLD_EVENT_FX.md`. Honors `AXEL_DISABLE_POST_FX=1` and `AXEL_DISABLE_EVENT_FX=1`.
- **Layer order:** baseline post-FX below UI; **dialogue above the `[E]` interact prompt** (prompt must not cover dialogue); both above CRT. Hub/map chrome that must stay readable (red `X`, travel choices) goes on **CanvasLayer ~110** (above CRT 108, below dialogue 111) — root Control `z_index` is not enough under autoload post-FX.
- **Overworld UI overlays (scene-instanced, not autoload):**
  - `TopDialogueOverlay` (above interact prompt) — bottom bar + typewriter. Playtest layout: `@export bar_width_fraction` defaults to `BAR_WIDTH_FRACTION_PLAYTEST` (~0.88 = midpoint of full vs first 2/3 test, then +5%); set to `1.0` (`BAR_WIDTH_FRACTION_FULL`) to restore the old nearly-full bar. `@export bottom_gap_viewport_fraction` (default `0.03`) lifts the bar by that fraction of window height; `0` falls back to `bottom_gap_px` / `BOTTOM_GAP_PX_FULL`. Default type speed `35` CPS (~25% faster than the old `28`, to offset scramble flashes). `show_line` / `show_lines`: CRT power on → typewriter → press to advance → scramble to next line or CRT power off on last line. Other-speaker lines type in bright red: ALL-CAPS tag like `AXEL:` or opt-in `|other|` (marker never shown); player/narration stays white. `type_line`: in-bar scramble swap when bar already up. `await_line_advance` after standalone `type_line` when the scene owns hide timing. `cancel_pending_line`: stop in-flight sequence without hiding bar / without `CrtPowerFx.cancel()`. `interrupt_line`: hard-cut, cancel CRT, hide. `is_sequence_busy`: dialogue still doing something (typing, waiting, or CRT power on/off) — do not start a new `show_line` while busy. `hide_line` is token-safe (stale hide cannot blank a newer line). While typing, Tab/E/Space/Enter/click instantly reveals the full line; when fully shown, same inputs advance. Per-char cryptic flash while typing is ON by default (`@export fx_char_scramble`); letters/digits only, ~40% chance, ~30–50 ms, then the real character. Opt-in mid-line pause: insert `|beat:<seconds>|` in the string (markers never shown); e.g. `"Even after all these years the smell is the same.|beat:1.5| They must've used some really toxic paint."` — beats are author-only, never auto-inserted. Advance during a beat ends the pause and typing resumes; advance while typing still full-reveals (display text only). Auto-advance clock starts when the line is fully shown (after typing/beats); formula unchanged: `3s + 0.5774·sqrt(extra words)` (cap `20s`); after skip-reveal flat `2s`. `allow_skip=false` disables skip/manual advance but auto-advance still fires.
  - `InteractPromptOverlay` — world-anchored `[E]` chip. Default `screen_offset` is `(0, 0)` (no offset unless requested). Anchor = interact `CollisionShape2D.global_position`. Use `hide_prompt_immediate()` before `change_scene_to_file`. Per-zone cosmetic nudge: if one zone’s chip looks wrong, add a small Vector2 in that scene’s `_interact_anchor()` for that zone only — do not change the shared default; nudge moves the chip only, not the trigger.
  - `UiPolygonHotspot` — Control-layer clickable polygon on cover-fit backgrounds; points in texture-pixel space; `activated` signal; hover tint; tune vertex handles only (node at `(0,0)`).
  - Shared CRT power tweens: `scenes/ui/crt_power_fx.gd` (`power_on` / `power_off` / `cancel()`). Interact uses `compact_chip_options()` (no white beam wash).
- Typography: VT323 primary. Mood: dread, guilt, memory corruption; wins feel uneasy, not celebratory.



## Lore anchors

Lore here is canon but may still change. Detailed written lore: `plans/scenes/`.

- Decaying school; guilt-driven return. Primary navigation is walking between connected scenes; locker hub is not the main room-to-room path (locker view only — no travel menu on the hub). School map (collectible) unlocks locker fast travel after being found by exploring — does not raise combat encounter goals. Live flow: map paper on `1.3_LockerHub` opens `1.3_SchoolMap` (travel choices + locked basement); map `X` returns to hub, hub `X` returns to corridor.
- Memories; Flashlight / Key / Shovel / Name (Name may change to a classroom find). Each lore item that counts toward the true ending also increases combat encounter goals (true ending path is harder).
- Basement confrontation; Axel identity and endings.
- Cigarettes/lighter ritual as recurring motifs.

## How to work

- Plans = design truth; code = behavior truth — reconcile before changing mechanics.
- Ask before large or ambiguous scope; do not assume unstated layout, economy, or behavior.
- Prefer scoped, additive edits; keep combat deterministic and replayable.
- No machine-absolute paths in shared gameplay code.
- If a prompt breaks established rules, remind the user of those rules before implementing. Most often the new prompt becomes the new canon after that reminder/confirmation.



## Chat workflow (API cost)

Cursor does not auto-route exploration to cheaper models inside one premium Plan chat — you choose the model per chat. **Use a new chat for each step** (Explore → Plan → Implement). Continuing in the same thread after explore makes Premium re-read the repo.


| Step      | Model               | Prompt pattern                                                                                                                                   |
| --------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Explore   | Auto / Composer     | `@plans/PRE-PLAN_Artifact`; **no implement** — final reply is **only** the `EXPLORATION ARTIFACT` block (easy copy-paste)                        |
| Plan      | Premium + Plan mode | `@plans/PREMIUM_Artifact` + paste artifact in chat — **never edit** that template file; create **only a new plan**; **no read/grep/search**      |
| Implement | Auto / Cursor Grok  | Paste plan block only; point at this file for canon                                                                                              |


Handoff: copy only the `--- EXPLORATION ARTIFACT ---` … `--- END ARTIFACT ---` block from Explore into Plan — not the whole thread. If the artifact is thin, send Explore back to Auto to expand line refs; do not let Plan verify in the repo.

**Plan chat handoff rule:** When the user pastes an exploration artifact into a new chat and `@`-references `plans/PREMIUM_Artifact`, treat that file as **instructions only**. Never edit `PREMIUM_Artifact` (do not insert the artifact into it). Use the pasted artifact + the PREMIUM template as reference, then create **only a new plan** (chat output / new plan file if asked). Same rule for `plans/PRE-PLAN_Artifact`: it is a prompt template, not a place to store artifacts.

Batch clarifying questions in **one** message on premium. Use git commits for history. Headless verify: `tools/qa/run_default_playtest.ps1` when touching combat, scenes, or movement contracts.

## Optional references

This file is a rulebook, not a shipped-scene catalog. What exists / is walkable comes from the live game (`scenes/`, scripts). Deep scene how-to: `SCENE_BUILDING.md` (must stay current). Written lore: `plans/scenes/`.

- **Building a new scene? Read first:** `plans/scenes/SCENE_BUILDING.md` — exploration template, camera/background pipeline, post-FX white/black color rule, player profiles, filename invariant, background-swap checklist. Alias: `scene agent`.
- **Scene dialogue index:** `plans/scenes/AXEL_SCENES_NEW.md` → `AXEL_SCENES_ARC1.md` … `ARC7.md` (locked rewrite dialogue; no HTML SOURCE).
- **Folder / naming taxonomy:** `plans/references/README_STRUCTURE.md` (review against live layout when stale).
- **New PNG exploration scenes (rules):** Derive camera limits from art size — never hand-tune `limit_*` / `fixed_x`. Helpers: `scenes/core/background_layout.gd`, `scenes/core/background_camera_controller.gd`. Default `camera_mode = static_locked`; `fit_mode` `cover` or `contain`; optional `margin_px`. Sync `EnvironmentColliders` on `layout_applied`. No baseline post-FX in `.tscn`. Lock background with `locked_exploration_background.gd`. **Post-FX authoring colors (mandatory):** PNG/empty fill = pure white (never black — VFX turns white ground dark); placeholders and all outlines = black (noir turns black red). Full tree + QA: `SCENE_BUILDING.md`.
- **Memory indicator (rules):** `scenes/fx/MemoryIndicator.tscn` + `memory_indicator.gd` — parent under `PlayerLayer` (above noir) so noir does not crush it. For cover-fit texture-pixel scenes, capture editor position and remap on `layout_applied`; do not derive from another node’s shape. Details/examples: live scenes + `SCENE_BUILDING.md`.
- **Legacy Arc 1 scenes:** Do not change without approval. Specific layout/numbers live in the scenes and `SCENE_BUILDING.md`, not here.
- **Headless checks:** `tools/qa/run_default_playtest.ps1`, `tools/bots/README.md` — run manually when you want verification; not required every chat.
- **Indexing:** Root `.cursorignore` — excludes logs, `.godot`, export captures, `plans/archive/**`, tool caches; keeps `exports/game_data.json` and `exports/GameManager.gd` indexed. `@`-mention excluded paths when needed.

