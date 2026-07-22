# AXEL AI Docs

Canonical guidance for AI agents. Read this file for substantive AXEL work. Load subsystem plans only when the task touches that area.

**Scope:** `plans/*`, `combat/*`, `exports/*`, `AXEL/html/*`, `scenes/*`, `scripts/*`

## Canon hierarchy

When sources conflict, resolve in this order:

1. This file (`plans/core/AI_DOCS.md`)
2. `plans/combat/AXEL_combat_implementation.md`
3. `plans/combat/AXEL_combat_design.md`
4. `plans/references/AXEL_notes.md`
5. Prototype: `AXEL/html/game.html`, `styles_game.css`, `styles.css`
6. `exports/*` and `exports/Moon Princess Files/*` (reference only for combat runtime)

## Architecture (do not blur layers)

- **Narrative:** `game.html` + `exports/game_data.json` + autoload `GameManager` (`exports/GameManager.gd`) — flags, memories, once-ever scene keys, corridor return position. Legacy HTML-UI `load_scene()` path remains guarded when UI nodes are absent. **Debug playtest:** `OS.is_debug_build()` skips loading/saving `user://axel_game_state.json` so dialogue flags reset each editor run.
- **Combat:** `combat/scripts/combat_root.gd` orchestrates spin lifecycle. Moon Princess exports are reference captures, not runtime canon.

## Combat invariants

Unless explicitly redesigning:

- 5×5 grid; deterministic RNG; line wins 3+ rows/cols (no flood-fill cluster wins).
- Wild: only exactly-3 winning lines spawn wild in the middle cell.
- Multiplier tied to cascade progression.
- Princess map: `cigarette`→Storm, `booze`/`alcohol`→Star, `bloody hand`→Love.
- **Trinity Run** = regular free spins; **SUPER Free Spins** = later bonus. Clarify if prompt says only "Free Spins".
- Item ids: extended `TIER-FAMILY` uppercase (`C-A`); baseline digit suffix (`C1`). New mechanic default = five tiers (Common→Legendary) unless one tier requested.
- Catalog edits only in `plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.
- **Protected scaffold:** `combat/combat_test.tscn` — keep `%CombatRoot`, `%MetaBox`, `%SeedSpinBox`, `%SpinButton`, `%BankrollLabel`, stake row, SUPER FS buttons. Run `combat/test/combat_test_scaffold_check.gd` before combat edits.

## Style and FX

- Palette: black + `#ff0000` + `#4a0000`. CRT/scanline/glitch/shake are core identity.
- **Post-FX (non-combat):** Autoload `AxelPostFxStack` — noir + scanline + CRT on scene change; `ensure_attached_to_current_scene()` reconciles if overlays are missing after an aborted swap. **Exclude** `res://combat/*`. Do not embed those three overlays in overworld `.tscn`. Env `AXEL_DISABLE_POST_FX=1` for isolated tests. CRT player tuning (overworld white sprite only): edit `scenes/fx/CrtPluginOverlay.tscn` → `FilterRect` material — `chroma` (env), `player_chroma`, `player_white_boost`, `player_crt_reduction` in `crt_plugin_overlay.gdshader` (not the Remote tree while playing).
- **Event FX:** Autoload `AxelEventFx` — transition glitch, jumpscare API, interface pulse cadence. Details: `plans/references/AXEL_OVERWORLD_EVENT_FX.md`. Honors `AXEL_DISABLE_POST_FX=1` and `AXEL_DISABLE_EVENT_FX=1`.
- **Overworld UI overlays (scene-instanced, not autoload):** `TopDialogueOverlay` (layer 110, bottom bar + typewriter); `show_line()` / `show_lines()` = CRT power on → typewriter → **press to advance** → scramble to next line or CRT power off on last line; `type_line()` = in-bar swap with scramble glitch when bar already up; `await_line_advance()` after standalone `type_line()` when the scene owns hide timing; `cancel_pending_line()` stops an in-flight sequence without hiding the bar and **without** `CrtPowerFx.cancel()` (must keep bar at full opacity for scramble swap); `interrupt_line()` hard-cuts, cancels CRT, and hides; `is_sequence_busy()` true for the whole show/hide await (covers CRT gaps where bar alpha is ~0 — scenes should not start a new `show_line` while busy); `hide_line()` is token-safe so a stale hide cannot blank a newer line. **Player input while bar visible:** during typing, Tab / E / Space / Enter / click → **instantly reveal the full line** (was a 5× speed boost); when line is fully shown, same inputs **advance** (next-line scramble or CRT off). **Auto-advance:** lines never wait forever — after a normal typewriter finish, auto-advances on a reading-time timer (`3s + 0.5774·sqrt(extra words)`, capped `20s`); after an instant skip-reveal, a flat `2s` grace instead. Input consumed so same press does not interact. `allow_skip=false` disables skip-reveal + manual advance entirely (input ignored) but the reading-timer auto-advance still fires. `InteractPromptOverlay` (layer 111, world-anchored `[E]` chip — `hide_prompt_immediate()` calls `CrtPowerFx.cancel()` then hides; use before `change_scene_to_file`, not animated `hide_prompt()`). Chip world anchor = interact area `CollisionShape2D.global_position` (rectangle center); screen nudge via export `screen_offset` (default `(0, -52)`). **Per-zone cosmetic nudge:** if one zone's chip looks off-center while others are fine, do not touch the shared `screen_offset` default — add a small `Vector2` constant in that scene's script and add it to the anchor only for that `_active_zone` inside `_interact_anchor()` (e.g. `TABLE_PROMPT_VISUAL_OFFSET` in `2.1_Cafeteria.gd`); this only moves the visible chip, not the trigger box. Chip may overlap dialogue bar (layer 111 above 110). **`UiPolygonHotspot`** (`scenes/ui/ui_polygon_hotspot.gd`) — Control-layer clickable polygon on cover-fit `TextureRect` backgrounds; export `background_path` (e.g. `../Background` on hub map) so `PolygonAnchor` syncs to drawn art; child `PolygonAnchor/CollisionPolygon2D` points in **texture-pixel space** (same convention as Arc 1 colliders); `activated` signal; runtime hover tint only. **Tune in editor:** drag `CollisionPolygon2D` **vertex handles** only (keep node at `(0,0)`); Godot collision gizmo is the editor preview (`show_editor_preview` off by default). Shared CRT power tweens: `scenes/ui/crt_power_fx.gd` (`power_on` / `power_off` / `cancel()` — `cancel()` kills tweens and frame-polls awaits so interrupt cannot hang; interact uses `compact_chip_options()` — no white beam wash). Do not embed baseline post-FX in `.tscn`.
- Typography: VT323 primary. Mood: dread, guilt, memory corruption; wins feel uneasy, not celebratory.

## Lore anchors

Decaying school; guilt-driven return; locker hub. Memories; Flashlight/Key/Shovel/Name; basement confrontation; Axel identity and endings. Cigarettes/lighter ritual as recurring motifs.

## How to work

- Plans = design truth; code = behavior truth — reconcile before changing mechanics.
- Ask before large or ambiguous scope; do not assume unstated layout, economy, or behavior.
- Prefer scoped, additive edits; keep combat deterministic and replayable.
- No machine-absolute paths in shared gameplay code.
- If a request conflicts with canon, stop and offer 2–4 options (strict canon, adapted, explicit override) before implementing.

## Chat workflow (API cost)

Cursor does not auto-route exploration to cheaper models inside one premium Plan chat — you choose the model per chat. **Use a new chat for each step** (Explore → Plan → Implement). Continuing in the same thread after explore makes Premium re-read the repo.

| Step | Model | Prompt pattern |
|------|--------|----------------|
| Explore | Auto / Composer | Beginner explore template (`AI_CHANGELOG.md` → `### Beginner explore template`); **no implement** — agent ends with `EXPLORATION ARTIFACT` block |
| Plan | Premium + Plan mode | Premium plan template (`AI_CHANGELOG.md` → `### Premium plan template`); paste **artifact only** — **no read/grep/search** |
| Implement | Auto | Paste plan block only; point at this file for canon |

Handoff: copy only the `--- EXPLORATION ARTIFACT ---` … `--- END ARTIFACT ---` block from Explore into Plan — not the whole thread. If the artifact is thin, send Explore back to Auto to expand line refs; do not let Plan verify in the repo.

Batch clarifying questions in **one** message on premium. Use git commits for history; optional changelog append on `update docs` (`## YYYY-MM-DD` day section + `###` entry title — see `plans/core/AI_CHANGELOG.md`). Headless verify: `tools/qa/run_default_playtest.ps1` when touching combat, scenes, or movement contracts.

## Optional references

- **Building a new scene? Read first:** `plans/scenes/SCENE_BUILDING.md` — mandatory exploration template, camera/background pipeline, player profiles, filename invariant, background-swap checklist. Alias: `scene agent`.
- **Scene dialogue index:** `plans/scenes/AXEL_SCENES_NEW.md` → `AXEL_SCENES_ARC1.md` … `ARC7.md` (locked rewrite dialogue; no HTML SOURCE).
- **Folder / naming taxonomy:** `plans/references/README_STRUCTURE.md`.
- **New PNG exploration scenes (mandatory summary):** Derive camera limits from art size — never hand-tune `limit_*` / `fixed_x`. Helpers: `scenes/core/background_layout.gd`, `scenes/core/background_camera_controller.gd`. Default `camera_mode = static_locked`; `fit_mode` `cover` or `contain`; optional `margin_px` (e.g. `12`). Sync `EnvironmentColliders` on `layout_applied`. No post-FX in `.tscn`. Lock background with `locked_exploration_background.gd`. Full tree + QA smoke: `SCENE_BUILDING.md`. **Shipped Arc 2 walkable:** `2.1_Cafeteria` and `2.3_Kitchen` (flashlight in-room on 2.3; `2.2` still placeholder; `2.3` now uses its real hand-drawn `2.3_Kitchen.png`, 3508×2480). See ARC2 Implemented notes.
- **Memory indicator (reusable, all Memories):** `scenes/fx/MemoryIndicator.tscn` + `memory_indicator.gd` — looping white/gray glow marker (source art `exports/Drawings/Memory.png`, luminance-converted to `assets/sprites/memory_glow-Sheet.png`, 5×48px frames) for the middle of a memory's InteractArea. Must be parented under the scene's `PlayerLayer` (CanvasLayer above Noir, layer 100) — a plain child of `WalkableWorld`/`EnvironmentColliders` would get crushed to black/red by `NoirPaletteOverlay`. Exports: `indicator_scale` (default `1.5`), `visual_offset` (screen-pixel nudge of the sprite only, anchor stays locked). **If the interact area's coordinates are texture-pixel space that gets remapped at runtime (cover-fit scenes)**, the owning scene script must re-sync the indicator's `global_position` from the live interact shape's `global_position` on every `layout_applied` (see `_sync_memory_indicator()` in `2.1_Cafeteria.gd`) — a hardcoded editor position will drift once the background is cover-scaled. Shipped test instance: `2.1_Cafeteria` table zone.
- **Arc 1 exploration scenes (1.1 / 1.2 — legacy, do not change without approval):** Root node named after the scene file. Cameras use `Camera2D` + `background_camera_controller.gd` — `1.2` = `STATIC_LOCKED`/`COVER` (`static_center.x=560`), `1.1` = `MOVABLE_FOLLOW`/`COVER` following `PlayerLayer/Player`. Player stays under `PlayerLayer` (layer 100) in both. Colliders in texture-pixel space; sync on `layout_applied`. **Player cover sync:** `player_cover_sync.gd` on 1.1 / 1.2 / 1.4 / 2.1 / 2.3. **1.1 road lock:** `locked_feet_y = 385`. `1.2` = `corridor_large` (scale `3.0`, speed `362`). Window is project-wide `1920×1280`. `exploration_viewport.gd` is inert. **1.2 locker / right exit / 1.3 hub / 1.4 basement door:** see ARC1 Implemented notes and Style and FX above. **1.1 leaf fade:** legacy `leaf_occlusion_zone.gd` — do not copy without design pass. **1.1 playtest:** `1.1_SchoolExterior_Playtest.tscn` with `skip_intro = true`.
- **Arc 1 migration (deferred):** Move 1.1/1.2 player to `WalkableWorld/Player`; document render order above noir. See `SCENE_BUILDING.md` → Deferred migration.
- **Headless checks:** `tools/qa/run_default_playtest.ps1`, `tools/bots/README.md` — run manually when you want verification; not required every chat.
- **Collisions (editor):** `plans/core/PLAYTEST_DEBUG_COLLISIONS.md`
- **Indexing:** Root `.cursorignore` — excludes logs, `.godot`, export captures, `plans/archive/**`, tool caches; keeps `exports/game_data.json` and `exports/GameManager.gd` indexed. `@`-mention excluded paths when needed.
