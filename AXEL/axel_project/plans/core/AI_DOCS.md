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

- **Narrative:** `game.html` + `exports/game_data.json` + `exports/GameManager.gd` — flags, memories, endings.
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
- **Overworld UI overlays (scene-instanced, not autoload):** `TopDialogueOverlay` (layer 110, bottom bar + typewriter); `InteractPromptOverlay` (layer 111, world-anchored `[E]` chip — use `hide_prompt_immediate()` before `change_scene_to_file`, not animated `hide_prompt()`). Shared CRT power tweens: `scenes/ui/crt_power_fx.gd` (`power_on` / `power_off`; interact uses `compact_chip_options()` — no white beam wash). Do not embed baseline post-FX in `.tscn`.
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

- **Scene agent:** `plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`, `tools/scene_builder/*` — canonical numbered filenames only (e.g. `1.2_Corridor.tscn`, never alias `Corridor.tscn`).
- **New PNG exploration scenes (mandatory):** After background layout, derive camera limits from art size — never hand-tune `limit_*` / `fixed_x`. Shared helpers: `scenes/core/background_layout.gd` (`BackgroundLayout.apply` → scale, position, `world_rect`) and `scenes/core/background_camera_controller.gd` (`BackgroundCamera` on `Camera2D`). Default `camera_mode = static_locked` for new imports; enable `movable_follow` only when designer needs 2D pan. Per-scene `fit_mode` export: `cover` or `contain`. Player under `WalkableWorld/Player` in world space for new scenes (see migration note below). No post-FX embedded in `.tscn`. **Background lock:** attach `scenes/core/locked_exploration_background.gd` on `WalkableWorld/Background` (sets `metadata/_edit_lock_` in editor).
- **Arc 1 exploration scenes (1.1 / 1.2 — legacy, do not change without approval):** Root node named after the scene file (e.g. `1.2_Corridor`, not suffixed variants). Shared tree: `Camera2D` + `camera_follow_vertical.gd` (fixed X, smooth vertical follow on `PlayerLayer/Player`); border colliders under `WalkableWorld/EnvironmentColliders` in **texture-pixel space** (child `StaticBody2D` → shape at `(0,0)`; `1.2_Corridor.gd` syncs collider scale/offset with cover-fit background). `1.2` uses `corridor_large` profile — player scale `3.0`, speed `362`. Per-scene window size via `scenes/core/exploration_viewport.gd` (`design_viewport` export; `1.2` = `1920×1200`, `1.1` = `1400×1400`; debug scale env `AXEL_DEBUG_VIEWPORT_SCALE`). Background cover-fit only in scene script; no `WalkableWorld` scroll. Manual camera limits remain until a dedicated migration pass (`AXEL_SCENES_BLUEPRINT.md` §1.2 for tuned values). **1.1 leaf fade (legacy, scene-local):** `EnvironmentColliders/TreeLine_Bottom_Behind` + `TreeLine_Top_Behind` — each `Area2D` uses `scenes/fx/leaf_occlusion_zone.gd` (`feather_px` export; polygon from child `CollisionPolygon2D`). `1.1_SchoolExterior.gd` → `Player.configure_leaf_occlusion_polygons` → `white_sprite.gdshader` (polygon feather mask × trunk Y gate + `player_anchor_y` feet anchor). Trunk cutoffs from `TreeLine_Bottom` / `TreeLine_Top` `StaticBody2D` polygons. **Tune in editor:** drag behind-zone polygon points; adjust `Feather Px` per tree (designer hand-tuned `12.0` on both zones — do not overwrite without playtest). `1.2` never calls leaf setup — no fade. **1.1 playtest:** `1.1_SchoolExterior_Playtest.tscn` inherits the base scene with `skip_intro = true` (spawn at stones, no glitch/dialogue intro). Edit `1.1_SchoolExterior.tscn` for layout/colliders — playtest picks up changes unless a property is overridden in the child scene. Bots may still use env `AXEL_SKIP_INTRO=1`. Intro skip also via `@export var skip_intro` on `1.1_SchoolExterior.gd`.
- **Arc 1 migration (deferred):** Move 1.1/1.2 player to `WalkableWorld/Player`, replace `PlayerLayer` screen-space follow with world-space + documented render order (`z_index` above noir), rewire cameras to `BackgroundCamera`. See `SCENE_BUILDER_AGENT_SPEC.md` → "Deferred migration".
- **Headless checks:** `tools/qa/run_default_playtest.ps1`, `tools/bots/README.md` — run manually when you want verification; not required every chat.
- **Collisions (editor):** `plans/core/PLAYTEST_DEBUG_COLLISIONS.md`
- **Indexing:** Root `.cursorignore` — excludes logs, `.godot`, export captures, tool caches; keeps `exports/game_data.json` and `exports/GameManager.gd` indexed. `@`-mention excluded paths when needed.
