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
- **Overworld UI overlays (scene-instanced, not autoload):** `TopDialogueOverlay` (layer 110, bottom bar + typewriter); `show_line()` / `show_lines()` = CRT power on → typewriter → **press to advance** → scramble to next line or CRT power off on last line; `type_line()` = in-bar swap with scramble glitch when bar already up; `await_line_advance()` after standalone `type_line()` when the scene owns hide timing; `cancel_pending_line()` stops an in-flight sequence without hiding the bar and **without** `CrtPowerFx.cancel()` (must keep bar at full opacity for scramble swap); `interrupt_line()` hard-cuts, cancels CRT, and hides. **Player input while bar visible:** during typing, Tab / E / Space / Enter / click → **instantly reveal the full line** (was a 5× speed boost); when line is fully shown, same inputs **advance** (next-line scramble or CRT off). **Auto-advance:** lines never wait forever — after a normal typewriter finish, auto-advances on a reading-time timer (`3s + 0.5774·sqrt(extra words)`, capped `20s`); after an instant skip-reveal, a flat `2s` grace instead. Input consumed so same press does not interact. `allow_skip=false` disables skip-reveal + manual advance entirely (input ignored) but the reading-timer auto-advance still fires. `InteractPromptOverlay` (layer 111, world-anchored `[E]` chip — `hide_prompt_immediate()` calls `CrtPowerFx.cancel()` then hides; use before `change_scene_to_file`, not animated `hide_prompt()`). Chip may overlap dialogue bar (layer 111 above 110). **`UiPolygonHotspot`** (`scenes/ui/ui_polygon_hotspot.gd`) — Control-layer clickable polygon on cover-fit `TextureRect` backgrounds; export `background_path` (e.g. `../Background` on hub map) so `PolygonAnchor` syncs to drawn art; child `PolygonAnchor/CollisionPolygon2D` points in **texture-pixel space** (same convention as Arc 1 colliders); `activated` signal; runtime hover tint only. **Tune in editor:** drag `CollisionPolygon2D` **vertex handles** only (keep node at `(0,0)`); Godot collision gizmo is the editor preview (`show_editor_preview` off by default). Shared CRT power tweens: `scenes/ui/crt_power_fx.gd` (`power_on` / `power_off` / `cancel()` — `cancel()` kills tweens and frame-polls awaits so interrupt cannot hang; interact uses `compact_chip_options()` — no white beam wash). Do not embed baseline post-FX in `.tscn`.
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
- **New PNG exploration scenes (mandatory):** After background layout, derive camera limits from art size — never hand-tune `limit_*` / `fixed_x`. Shared helpers: `scenes/core/background_layout.gd` (`BackgroundLayout.apply` → scale, position, `world_rect`) and `scenes/core/background_camera_controller.gd` (`BackgroundCamera` on `Camera2D`). Default `camera_mode = static_locked` for new imports; enable `movable_follow` only when designer needs 2D pan. Per-scene `fit_mode` export: `cover` or `contain`. Optional per-scene `margin_px` (e.g. `12`) insets camera limits to hide CRT red fringe — do **not** change the global CRT shader for edge trim. Player under `WalkableWorld/Player` in world space for new scenes (see migration note below). Sync `EnvironmentColliders` (texture-pixel space) on `layout_applied`. No post-FX embedded in `.tscn`. **Background lock:** attach `scenes/core/locked_exploration_background.gd` on `WalkableWorld/Background` (sets `metadata/_edit_lock_` in editor). **Arc 2 first walkable (shipped):** `2.1_Cafeteria.tscn` + `2.1_Cafeteria.gd` — `2.1_Cafeteria.png`, `STATIC_LOCKED`/`COVER`, `margin_px=12`, player scale `3` / speed `253`; enter dialogue once; `[E]` zones → `2.2_CafeteriaMemory` / `2.3_Kitchen` (still placeholders) / return `1.3_LockerHub`.
- **Arc 1 exploration scenes (1.1 / 1.2 — legacy, do not change without approval):** Root node named after the scene file (e.g. `1.2_Corridor`, not suffixed variants). Cameras: both now use `Camera2D` + `background_camera_controller.gd` (`BackgroundCamera`, art-derived limits) — `1.2` = `STATIC_LOCKED`/`COVER` (`static_center.x=560`), `1.1` = `MOVABLE_FOLLOW`/`COVER` following `PlayerLayer/Player` (migrated from the old `camera_follow_vertical.gd`; that script is retained unused for rollback). Player stays under the `PlayerLayer` CanvasLayer (`layer=100`, `follow_viewport_enabled`) in both — this keeps the player drawn above noir; it was NOT reparented to world space. Border colliders under `EnvironmentColliders` in **texture-pixel space** (child `StaticBody2D` → shape at `(0,0)`). **Both 1.1 and 1.2** sync colliders on `layout_applied` (`1.2_Corridor.gd` direct cover-fit; `1.1_SchoolExterior.gd` old-baseline remap so hand-placed walls track live cover-fit). **1.1 road lock:** Player `@export locked_feet_y = 385` (horizontal walk only; default `-1` = off elsewhere). `1.2` uses `corridor_large` profile — player scale `3.0`, speed `362`. Window size/aspect is now **project-wide** (`project.godot`: base `1920×1280` = true 3:2, `content_scale_aspect=1` Keep); window is resizable to any resolution and gameplay auto-letterboxes to 3:2. `scenes/core/exploration_viewport.gd` is inert (kept so 1.1/1.2 still load; no longer resizes the OS window). Background cover-fit only in scene script; no `WalkableWorld` scroll. **1.2 locker route (shipped):** additive `LockerInteractArea` + `InteractPromptOverlay`; opening smell line once-ever (`corridor_spawn_line_seen`); locker proximity line once-ever (`corridor_locker_line_seen`) — if smell bar still up, locker text uses `type_line()` swap (no CRT off/on); `[E]` shows on zone enter (may overlap dialogue); `hide_prompt_immediate()` then `change_scene_to_file` → `1.3_LockerHub.tscn`; return via hub `X` restores `corridor_return_pos`. **1.2 right exit (shipped):** `ExitTrigger` past moved `RightWall` → `1.4_BasementDoor.tscn`; left-edge return restores `corridor_return_pos`. **1.3 Locker Hub / 1.4 Basement Door (shipped in Arc 1):** hub = UI map + four destination buttons (`UiPolygonHotspot` on map paper); basement door = walkable room (`1.4_BasementDoor.png`, `margin_px=12`, no `RoomOutline`), once-ever `"Not yet."` on `[E]` (`basement_door_line_seen`). **1.1 leaf fade (legacy, scene-local):** `EnvironmentColliders/TreeLine_Bottom_Behind` + `TreeLine_Top_Behind` — each `Area2D` uses `scenes/fx/leaf_occlusion_zone.gd` (`feather_px` export; polygon from child `CollisionPolygon2D`). `1.1_SchoolExterior.gd` → `Player.configure_leaf_occlusion_polygons` → `white_sprite.gdshader` (polygon feather mask × trunk Y gate + `player_anchor_y` feet anchor). Trunk cutoffs from `TreeLine_Bottom` / `TreeLine_Top` `StaticBody2D` polygons. **Tune in editor:** drag behind-zone polygon points; adjust `Feather Px` per tree (designer hand-tuned `12.0` on both zones — do not overwrite without playtest). `1.2` never calls leaf setup — no fade. **1.1 playtest:** `1.1_SchoolExterior_Playtest.tscn` inherits the base scene with `skip_intro = true` (spawn at stones, no glitch/dialogue intro). Edit `1.1_SchoolExterior.tscn` for layout/colliders — playtest picks up changes unless a property is overridden in the child scene. Bots may still use env `AXEL_SKIP_INTRO=1`. Intro skip also via `@export var skip_intro` on `1.1_SchoolExterior.gd`.
- **Arc 1 migration (deferred):** Move 1.1/1.2 player to `WalkableWorld/Player`, replace `PlayerLayer` screen-space follow with world-space + documented render order (`z_index` above noir), rewire cameras to `BackgroundCamera`. See `SCENE_BUILDER_AGENT_SPEC.md` → "Deferred migration".
- **Headless checks:** `tools/qa/run_default_playtest.ps1`, `tools/bots/README.md` — run manually when you want verification; not required every chat.
- **Collisions (editor):** `plans/core/PLAYTEST_DEBUG_COLLISIONS.md`
- **Indexing:** Root `.cursorignore` — excludes logs, `.godot`, export captures, tool caches; keeps `exports/game_data.json` and `exports/GameManager.gd` indexed. `@`-mention excluded paths when needed.
