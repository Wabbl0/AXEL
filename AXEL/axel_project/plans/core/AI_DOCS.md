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

- **Narrative:** Godot exploration scenes (`scenes/*`) + autoload `GameManager` (`exports/GameManager.gd`) — flags, memories, once-ever scene keys, corridor return position. Active transitions use `change_scene_to_file()`. Ignore HTML/`game_data.json` UI paths; strip leftover HTML-UI code so the current game does not depend on guarded `load_scene()`. **Debug playtest:** `OS.is_debug_build()` skips loading/saving `user://axel_game_state.json` so dialogue flags reset each editor run.
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

- Palette (production canon): black + `#ff0000` + `#4a0000`. CRT/scanline/glitch/shake are core identity. An experimental multi-color / 8-band noir shader may be playtested (`DEBUG_USE_NOIR_8BAND_TEST` / `AXEL_NOIR_8BAND=1`); do not treat it as production canon until promoted. Document and ship against 3-band noir.
- **Post-FX (non-combat):** Autoload `AxelPostFxStack` — noir + scanline + CRT on scene change; `ensure_attached_to_current_scene()` re-attaches if overlays are missing after an aborted swap. **Exclude** `res://combat/*`. Do not embed those three overlays in overworld `.tscn`. Env `AXEL_DISABLE_POST_FX=1` for isolated tests. CRT player tuning (overworld white sprite only): edit `scenes/fx/CrtPluginOverlay.tscn` → `FilterRect` material — `chroma`, `player_chroma`, `player_white_boost`, `player_crt_reduction` in `crt_plugin_overlay.gdshader` (not the Remote tree while playing).
- **Event FX:** Autoload `AxelEventFx` — transition glitch, jumpscare API, interface pulse cadence. Details: `plans/references/AXEL_OVERWORLD_EVENT_FX.md`. Honors `AXEL_DISABLE_POST_FX=1` and `AXEL_DISABLE_EVENT_FX=1`.
- **Layer order:** baseline post-FX below UI; **dialogue above the `[E]` interact prompt** (prompt must not cover dialogue); both above CRT.
- **Overworld UI overlays (scene-instanced, not autoload):**
  - `TopDialogueOverlay` — bottom bar + typewriter. `show_line` / `show_lines`: CRT power on → typewriter → press to advance → scramble to next line or CRT power off on last line. `type_line`: in-bar scramble swap when bar already up. `await_line_advance` after standalone `type_line` when the scene owns hide timing. `cancel_pending_line`: stop in-flight sequence without hiding bar / without `CrtPowerFx.cancel()`. `interrupt_line`: hard-cut, cancel CRT, hide. `is_sequence_busy`: dialogue still doing something (typing, waiting, or CRT power on/off) — do not start a new `show_line` while busy. `hide_line` is token-safe (stale hide cannot blank a newer line). While typing, Tab/E/Space/Enter/click instantly reveals the full line; when fully shown, same inputs advance. Auto-advance: after normal typewriter finish `3s + 0.5774·sqrt(extra words)` (cap `20s`); after skip-reveal flat `2s`. `allow_skip=false` disables skip/manual advance but auto-advance still fires.
  - `InteractPromptOverlay` — world-anchored `[E]` chip. Default `screen_offset` is `(0, 0)` (no offset unless requested). Anchor = interact `CollisionShape2D.global_position`. Use `hide_prompt_immediate()` before `change_scene_to_file`. Per-zone cosmetic nudge: if one zone’s chip looks wrong, add a small Vector2 in that scene’s `_interact_anchor()` for that zone only — do not change the shared default; nudge moves the chip only, not the trigger.
  - `UiPolygonHotspot` — Control-layer clickable polygon on cover-fit backgrounds; points in texture-pixel space; `activated` signal; hover tint; tune vertex handles only (node at `(0,0)`).
  - Shared CRT power tweens: `scenes/ui/crt_power_fx.gd` (`power_on` / `power_off` / `cancel()`). Interact uses `compact_chip_options()` (no white beam wash).
- Typography: VT323 primary. Mood: dread, guilt, memory corruption; wins feel uneasy, not celebratory.



## Lore anchors

Lore here is canon but may still change. Detailed written lore: `plans/scenes/`.

- Decaying school; guilt-driven return. Primary navigation is walking between connected scenes; locker hub is not the main room-to-room path. School map (collectible) unlocks locker fast travel after being found by exploring — does not raise combat encounter goals.
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
| Explore   | Auto / Composer     | Beginner explore template (`AI_CHANGELOG.md` → `### Beginner explore template`); **no implement** — agent ends with `EXPLORATION ARTIFACT` block |
| Plan      | Premium + Plan mode | Premium plan template (`AI_CHANGELOG.md` → `### Premium plan template`); paste **artifact only** — **no read/grep/search**                       |
| Implement | Auto / Cursor Grok  | Paste plan block only; point at this file for canon                                                                                              |


Handoff: copy only the `--- EXPLORATION ARTIFACT ---` … `--- END ARTIFACT ---` block from Explore into Plan — not the whole thread. If the artifact is thin, send Explore back to Auto to expand line refs; do not let Plan verify in the repo.

Batch clarifying questions in **one** message on premium. Use git commits for history. Headless verify: `tools/qa/run_default_playtest.ps1` when touching combat, scenes, or movement contracts.

## Optional references

- **Building a new scene? Read first:** `plans/scenes/SCENE_BUILDING.md` — mandatory exploration template, camera/background pipeline, player profiles, filename invariant, background-swap checklist. Alias: `scene agent`.
- **Scene dialogue index:** `plans/scenes/AXEL_SCENES_NEW.md` → `AXEL_SCENES_ARC1.md` … `ARC7.md` (locked rewrite dialogue; no HTML SOURCE).
- **Folder / naming taxonomy:** `plans/references/README_STRUCTURE.md`.
- **New PNG exploration scenes (mandatory summary):** Derive camera limits from art size — never hand-tune `limit_`* / `fixed_x`. Helpers: `scenes/core/background_layout.gd`, `scenes/core/background_camera_controller.gd`. Default `camera_mode = static_locked`; `fit_mode` `cover` or `contain`; optional `margin_px` (e.g. `12`). Sync `EnvironmentColliders` on `layout_applied`. No post-FX in `.tscn`. Lock background with `locked_exploration_background.gd`. Full tree + QA smoke: `SCENE_BUILDING.md`. **Shipped Arc 2 walkable:** `2.1_Cafeteria` and `2.3_Kitchen` (flashlight in-room on 2.3; `2.2` still placeholder; `2.3` now uses its real hand-drawn `2.3_Kitchen.png`, 3508×2480). See ARC2 Implemented notes.
- **Memory indicator (reusable, all Memories):** `scenes/fx/MemoryIndicator.tscn` + `memory_indicator.gd` — looping white/gray glow marker (source art `exports/Drawings/Memory.png`, luminance-converted to `assets/sprites/memory_glow-Sheet.png`, 5×48px frames) for the middle of a memory's InteractArea. Must be parented under the scene's `PlayerLayer` (CanvasLayer above Noir, layer 100) — a plain child of `WalkableWorld`/`EnvironmentColliders` would get crushed to black/red by `NoirPaletteOverlay`. Exports: `indicator_scale` (default `1.5`), `visual_offset` (screen-pixel nudge of the sprite only, anchor stays locked). **If the scene uses texture-pixel space that gets remapped at runtime (cover-fit scenes)**, spawn the indicator from its own editor position like the Player spawn point — capture `position` in `_ready()`, remap via `env.to_global()` on every `layout_applied` (see `_memory_indicator_tex` / `_sync_memory_indicator()` in `2.1_Cafeteria.gd`). Do not re-derive it from another node's shape (e.g. the interact area) — that makes the indicator's own editor position dead. Shipped test instance: `2.1_Cafeteria` table zone.
- **Arc 1 exploration scenes (1.1 / 1.2 — legacy, do not change without approval):** Root node named after the scene file — keep root `position` at `(0, 0)` (a non-zero root offset desyncs cover-fit art from camera limits and shows post-FX red void). Cameras use `Camera2D` + `background_camera_controller.gd` — limits from the art’s **global** rect + COVER auto-zoom (never hand-tune `limit_*` / `fixed_x`). `1.2` = `STATIC_LOCKED`/`COVER` (`static_center.x=560`), `1.1` = `MOVABLE_FOLLOW`/`COVER` following `PlayerLayer/Player`. Player stays under `PlayerLayer` (layer 100) in both. Colliders in texture-pixel space; sync on `layout_applied`. **Player cover sync:** `player_cover_sync.gd` on 1.1 / 1.2 / 1.4 / 2.1 / 2.3. **1.1 movement:** free X/Y within colliders — no `locked_feet_y` road lock. Do not re-enable global canvas stretch to “fix” player size (use `PlayerCoverSync` + baseline). `1.2` = `corridor_large` (scale `3.0`, speed `362`). Window is project-wide `1920×1280` with stretch `disabled`. `exploration_viewport.gd` is inert. **1.2 locker / right exit / 1.3 hub / 1.4 basement door:** see ARC1 Implemented notes and Style and FX above. **1.1 leaf fade:** legacy `leaf_occlusion_zone.gd` — do not copy without design pass. **1.1 playtest:** `1.1_SchoolExterior_Playtest.tscn` with `skip_intro = true`.
- **Arc 1 migration (deferred):** Move 1.1/1.2 player to `WalkableWorld/Player`; document render order above noir. See `SCENE_BUILDING.md` → Deferred migration.
- **Headless checks:** `tools/qa/run_default_playtest.ps1`, `tools/bots/README.md` — run manually when you want verification; not required every chat.
- **Collisions (editor):** `plans/core/PLAYTEST_DEBUG_COLLISIONS.md`
- **Indexing:** Root `.cursorignore` — excludes logs, `.godot`, export captures, `plans/archive/`**, tool caches; keeps `exports/game_data.json` and `exports/GameManager.gd` indexed. `@`-mention excluded paths when needed.

