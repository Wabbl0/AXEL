# AI_DOCS Q&A Log

Append-only answer log for the interactive canon overhaul.
Game/runtime is preferred over stale docs when they conflict; final wording comes from user verdicts.

## How to read entries

- **Verdict:** `canon` | `not canon` | `explain` | `split` | `park`
- **Final wording:** text that should land in AI_DOCS (or linked docs)
- **Cascade:** related files that may need updates later

---

## Answers

### S0-01 — Title / purpose
- **Original claim:** Canonical guidance for AI agents. Read this file for substantive AXEL work.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** `.cursor/rules/axel-ai-docs-governance.mdc`

### S0-02 — Load subsystem plans on demand
- **Original claim:** Load subsystem plans only when the task touches that area.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S0-03 — Scope globs
- **Original claim:** Scope: `plans/*`, `combat/*`, `exports/*`, `AXEL/html/*`, `scenes/*`, `scripts/*`
- **Verdict:** explain
- **Final wording:** Primary scope: `plans/*`, `combat/*`, `scenes/*`, `scripts/*`. Also `assets/*` and `tools/*` when the task touches them. Ignore `exports/*` and `AXEL/html/*` unless a task explicitly says to use them.
- **Cascade:** —

### S1-01 — AI_DOCS always first in conflict order
- **Original claim:** When sources conflict, resolve in this order — #1 This file (`plans/core/AI_DOCS.md`)
- **Verdict:** canon (revised)
- **Final wording:** AI_DOCS wins over every other plan/doc when they disagree, so future plans obey the foundation laid out here. (During this overhaul, live game/code informs what AI_DOCS should say; after rewrite, AI_DOCS is top canon among docs.)
- **Cascade:** `.cursor/rules/axel-ai-docs-governance.mdc`

### S1-02 — Combat implementation plan #2
- **Original claim:** Conflict order #2: `plans/combat/AXEL_combat_implementation.md`
- **Verdict:** canon (+ explain)
- **Final wording:** #2 in conflict order. Open only when the user states the prompt is combat-related; otherwise ignore.
- **Cascade:** `plans/combat/AXEL_combat_implementation.md`

### S1-03 — Combat design plan #3
- **Original claim:** Conflict order #3: `plans/combat/AXEL_combat_design.md`
- **Verdict:** canon
- **Final wording:** (unchanged) — same combat-only open rule as S1-02 implied by hierarchy under combat plans
- **Cascade:** `plans/combat/AXEL_combat_design.md`

### S1-04 — AXEL_notes #4
- **Original claim:** Conflict order #4: `plans/references/AXEL_notes.md`
- **Verdict:** canon (+ explain)
- **Final wording:** Keep #4. Addendum: combat design, combat implementation, and AXEL_notes can change and are guiding suggestions — not absolute truth.
- **Cascade:** `plans/references/AXEL_notes.md`

### S1-05 — HTML prototype #5
- **Original claim:** Conflict order #5: Prototype `AXEL/html/game.html`, `styles_game.css`, `styles.css`
- **Verdict:** not canon
- **Final wording:** Remove from hierarchy. Ignore `AXEL/html/*` unless a task explicitly says to use it (same as S0-03).
- **Cascade:** —

### S1-06 — Exports / Moon Princess #6
- **Original claim:** Conflict order #6: `exports/*` and `exports/Moon Princess Files/*` (reference only for combat runtime)
- **Verdict:** not canon
- **Final wording:** Remove from hierarchy. Ignore `exports/*` unless a task explicitly says to use it (same as S0-03).
- **Cascade:** —

### S2-01 — Narrative layer definition
- **Original claim:** Narrative: `game.html` + `exports/game_data.json` + autoload `GameManager` — flags, memories, once-ever scene keys, corridor return position.
- **Verdict:** explain / split
- **Final wording:** Narrative = Godot exploration scenes (`scenes/*`) + autoload `GameManager` (`exports/GameManager.gd`). HTML portion (`game.html`, JSON-driven UI, related HTML assets) is archived/ignored — old version; current game only takes inspiration from it. `GameManager.gd` remains relevant.
- **Cascade:** Architecture section of AI_DOCS; any docs still treating HTML as active narrative

### S2-02 — What GameManager owns
- **Original claim:** GameManager owns flags, memories, once-ever scene keys, corridor return position.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S2-03 — Legacy HTML-UI load_scene()
- **Original claim:** Legacy HTML-UI `load_scene()` path remains guarded when UI nodes are absent.
- **Verdict:** not canon
- **Final wording:** Do not document or rely on legacy `load_scene()` / HTML-UI. Ignore it. Current Godot narrative uses scene scripts + `change_scene_to_file()`. Strip or isolate leftover HTML-UI code in `GameManager` so the current game does not need that guarded path.
- **Cascade:** `exports/GameManager.gd` (code cleanup follow-through); AI_DOCS Architecture
- **Follow-through:** Remove/archive guarded HTML-UI path after Q&A (or isolate so only overworld-relevant GameManager APIs remain).

### S2-04 — Debug playtest persistence skip
- **Original claim:** Debug playtest: `OS.is_debug_build()` skips loading/saving `user://axel_game_state.json` so dialogue flags reset each editor run.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S2-05 — Combat layer / combat_root
- **Original claim:** Combat: `combat/scripts/combat_root.gd` orchestrates spin lifecycle.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S2-06 — Moon Princess exports reference
- **Original claim:** Moon Princess exports are reference captures, not runtime canon.
- **Verdict:** not canon
- **Final wording:** Remove / ignore. Do not cite Moon Princess exports unless a task explicitly asks.
- **Cascade:** —

### S2-07 — Do not blur layers
- **Original claim:** Architecture: do not blur narrative vs combat layers.
- **Verdict:** canon (+ explain)
- **Final wording:** Keep narrative and combat cleanly separated. They will be wired later, but must not mix concerns (no slot logic in exploration scripts; no story flags inside combat RNG).
- **Cascade:** `.cursor/rules/axel-ai-docs-governance.mdc`

### S3-01 — 5×5 grid
- **Original claim:** 5×5 grid
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S3-02 — Deterministic RNG
- **Original claim:** Deterministic RNG
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S3-03 — Line wins 3+ rows/cols
- **Original claim:** Line wins 3+ rows/cols (no flood-fill cluster wins).
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S3-04 — Wild on exactly-3 lines
- **Original claim:** Wild: only exactly-3 winning lines spawn wild in the middle cell.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —
- **Note:** Code also skips wild spawn during active free spins; user kept doc claim as-is.

### S3-05 — Multiplier / cascade
- **Original claim:** Multiplier tied to cascade progression.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S3-06 — Princess map
- **Original claim:** Princess map: cigarette→Storm, booze/alcohol→Star, bloody hand→Love.
- **Verdict:** canon (+ explain)
- **Final wording:** Princess map: `cigarette`→Storm, `alcohol`→Star, `bloody hand`→Love. Prefer the name “alcohol” (not “booze”) in docs and user-facing text.
- **Cascade:** AI_DOCS; combat plans/docs that say “booze”; user-facing combat labels/text that still say “booze”
- **Follow-through:** Rename “booze” → “alcohol” in texts; keep or migrate internal symbol id separately if needed.

### S3-07 — Trinity Run = regular free spins
- **Original claim:** Trinity Run = regular free spins
- **Verdict:** canon (+ explain)
- **Final wording:** Trinity Run is the meter-triggered bonus round (not yet the Free Spin round). If a Trinity round clears all non-wild symbols from the grid (no new symbols spawn during Trinity), the Free Spin round starts. During Trinity, each princess power activates once in order: Love first (then matches resolve), then Star, then Storm (same pattern).
- **Cascade:** combat plans that name Trinity / SUPER FS

### S3-08 — SUPER Free Spins = later bonus
- **Original claim:** SUPER Free Spins = later bonus
- **Verdict:** canon (+ explain)
- **Final wording:** The later bonus is named **Free Spins** everywhere (replace “SUPER Free Spins”). If “Trinity” is accidentally called “Free Spins” anywhere, rename it to **Trinity**. Trinity ≠ Free Spins.
- **Cascade:** AI_DOCS; combat plans; UI/scaffold labels that say SUPER Free Spins or mislabel Trinity as Free Spins
- **Follow-through:** Text rename pass for SUPER Free Spins → Free Spins; fix Trinity mislabels.

### S3-09 — Clarify “Free Spins” prompts
- **Original claim:** Clarify if prompt says only "Free Spins".
- **Verdict:** explain
- **Final wording:** Naming is unambiguous: **normal spins → Trinity round → Free Spins**. “Free Spins” always means the later bonus, never Trinity. Agents should not treat the sequence as ambiguous; ask only if a prompt clearly mixes the names.
- **Cascade:** AI_DOCS combat invariants naming bullet

### S3-10 — Item id formats
- **Original claim:** Item ids: extended `TIER-FAMILY` uppercase (`C-A`); baseline digit suffix (`C1`).
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S3-11 — Five-tier default for new mechanics
- **Original claim:** New mechanic default = five tiers (Common→Legendary) unless one tier requested.
- **Verdict:** canon (+ explain)
- **Final wording:** Five tiers total: Common → Uncommon → Rare → Epic → Legendary. New mechanic defaults to all five unless one tier (or a subset) is requested.
- **Cascade:** `plans/references/AXEL_notes.md` (still says four tiers)

### S3-12 — Catalog edits location
- **Original claim:** Catalog edits only in `plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S3-13 — Protected combat test scaffold
- **Original claim:** Protected scaffold: `combat/combat_test.tscn` — keep `%CombatRoot`, `%MetaBox`, `%SeedSpinBox`, `%SpinButton`, `%BankrollLabel`, stake row, SUPER FS buttons.
- **Verdict:** canon (+ explain)
- **Final wording:** Keep those unique nodes / stake row / Free Spins choice buttons. Label them Free Spins (not SUPER Free Spins).
- **Cascade:** `combat/combat_test.tscn` UI text; AI_DOCS scaffold bullet
- **Follow-through:** Rename SUPER Free Spins UI copy → Free Spins.

### S3-14 — Scaffold check before combat edits
- **Original claim:** Run `combat/test/combat_test_scaffold_check.gd` before combat edits.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-01 — Palette
- **Original claim:** Palette: black + `#ff0000` + `#4a0000`.
- **Verdict:** canon (+ note)
- **Final wording:** Canon palette remains black + `#ff0000` + `#4a0000`. Note: an experimental noir shader with more colors is being tested; do not treat that expanded set as canon until promoted.
- **Cascade:** S4-09 (8-band test flag); `axel_post_fx_stack.gd`

### S4-02 — CRT/scanline/glitch/shake identity
- **Original claim:** CRT/scanline/glitch/shake are core identity.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-03 — AxelPostFxStack owns baseline overlays
- **Original claim:** Post-FX (non-combat): Autoload `AxelPostFxStack` — noir + scanline + CRT on scene change.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-04 — ensure_attached_to_current_scene recovery
- **Original claim:** `ensure_attached_to_current_scene()` reconciles if overlays are missing after an aborted swap.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-05 — Exclude combat from post-FX
- **Original claim:** Exclude `res://combat/*` from post-FX.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-06 — Do not embed baseline overlays in overworld .tscn
- **Original claim:** Do not embed those three overlays in overworld `.tscn`.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-07 — AXEL_DISABLE_POST_FX
- **Original claim:** Env `AXEL_DISABLE_POST_FX=1` for isolated tests.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-08 — CRT player tuning
- **Original claim:** CRT player tuning via `CrtPluginOverlay.tscn` / `crt_plugin_overlay.gdshader` params (not Remote tree while playing).
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-09 — 8-band noir test vs production 3-band
- **Original claim / mismatch:** `DEBUG_USE_NOIR_8BAND_TEST := true` vs production 3-band.
- **Verdict:** canon (document production)
- **Final wording:** Production post-FX uses 3-band noir. 8-band is opt-in test only (`DEBUG_USE_NOIR_8BAND_TEST` / env `AXEL_NOIR_8BAND=1`); not canon until promoted. Agents should keep documenting production 3-band.
- **Cascade:** AI_DOCS Style/FX note; do not flip the debug flag in this docs overhaul unless asked
- **Note:** Flag may stay `true` locally for playtesting; that does not change documented production canon.

### S4-10 — AxelEventFx responsibilities
- **Original claim:** Event FX: Autoload `AxelEventFx` — transition glitch, jumpscare API, interface pulse cadence. Details: `plans/references/AXEL_OVERWORLD_EVENT_FX.md`.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-11 — Event FX env disables
- **Original claim:** Event FX honors `AXEL_DISABLE_POST_FX=1` and `AXEL_DISABLE_EVENT_FX=1`.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-12 — TopDialogueOverlay basics
- **Original claim:** `TopDialogueOverlay` is scene-instanced (not autoload); layer 110; bottom bar + typewriter.
- **Verdict:** canon (+ amend)
- **Final wording:** Scene-instanced (not autoload); bottom bar + typewriter. Dialogue bar must draw **above CRT** and **above** the `[E]` interact prompt (prompt must not cover dialogue).
- **Cascade:** Layer numbers in AI_DOCS / `TopDialogueOverlay` / `InteractPromptOverlay` — current code has dialogue 110 and prompt 111 (prompt above); needs flip or reassignment so dialogue wins.
- **Follow-through:** Fix canvas layer order so dialogue > interact prompt > CRT.

### S4-13 — show_line / show_lines flow
- **Original claim:** `show_line()` / `show_lines()` = CRT power on → typewriter → press to advance → scramble to next line or CRT power off on last line.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-14 — type_line in-bar swap
- **Original claim:** `type_line()` = in-bar swap with scramble glitch when bar already up.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-15 — await_line_advance
- **Original claim:** `await_line_advance()` after standalone `type_line()` when the scene owns hide timing.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-16 — cancel_pending_line
- **Original claim:** `cancel_pending_line()` stops an in-flight sequence without hiding the bar and without `CrtPowerFx.cancel()`.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-17 — interrupt_line
- **Original claim:** `interrupt_line()` hard-cuts, cancels CRT, and hides.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-18 — is_sequence_busy
- **Original claim:** `is_sequence_busy()` true for the whole show/hide await (covers CRT gaps where bar alpha is ~0 — scenes should not start a new `show_line` while busy).
- **Verdict:** canon (+ simpler wording)
- **Final wording:** `is_sequence_busy()` means the dialogue box is still doing something (typing, waiting for advance, or CRT power on/off). Scenes must not start a new `show_line` while busy.
- **Cascade:** AI_DOCS Style/FX dialogue bullet (prefer plain wording)

### S4-19 — hide_line token-safe
- **Original claim:** `hide_line()` is token-safe so a stale hide cannot blank a newer line.
- **Verdict:** canon
- **Final wording:** (keep meaning; prefer plain wording in AI_DOCS)
- **Cascade:** —

### S4-20 — Skip-reveal vs advance inputs
- **Original claim:** During typing Tab/E/Space/Enter/click instantly reveal; when fully shown, same inputs advance.
- **Verdict:** canon
- **Final wording:** (unchanged; prefer plain wording)
- **Cascade:** —

### S4-21 — Auto-advance timers
- **Original claim:** Auto-advance reading timer `3s + 0.5774·sqrt(extra words)` capped `20s`; after skip-reveal flat `2s`; input consumed.
- **Verdict:** canon
- **Final wording:** (unchanged; prefer plain wording)
- **Cascade:** —

### S4-22 — allow_skip=false
- **Original claim:** `allow_skip=false` disables skip-reveal + manual advance (input ignored) but reading-timer auto-advance still fires.
- **Verdict:** canon (batch: remaining dialogue-box claims)
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-batch — Remaining TopDialogueOverlay-only claims
- **Verdict:** canon (user directive: all next dialogue-box-affiliated questions flagged canon)
- **Covered:** dialogue API/behavior already listed in Style/FX for `TopDialogueOverlay` (show/type/await/cancel/interrupt/busy/hide/input/auto-advance/allow_skip). Prefer plain wording in rewrite.
- **Not covered by batch (still ask):** InteractPromptOverlay, prompt anchor/nudge, UiPolygonHotspot, CrtPowerFx shared utility, typography, mood.
- **Cascade:** AI_DOCS Style/FX dialogue bullet rewrite

### S4-23 — InteractPromptOverlay
- **Original claim:** layer 111, world-anchored `[E]` chip; `hide_prompt_immediate()` before scene change; `screen_offset` default `(0, -52)`.
- **Verdict:** not canon (partial keep)
- **Final wording:** Keep InteractPromptOverlay as scene-instanced world-anchored `[E]` chip; use `hide_prompt_immediate()` before `change_scene_to_file`. Default `screen_offset` is `(0, 0)` — no offset unless specifically requested. Dialogue draws above the interact prompt (update layer order accordingly).
- **Cascade:** AI_DOCS; `InteractPromptOverlay` / `TopDialogueOverlay` layers; any docs citing `(0, -52)`
- **Follow-through:** Ensure dialogue layer > prompt layer in code.

### S4-24 — Per-zone cosmetic nudge
- **Original claim:** If one zone's chip looks off-center, don't change shared `screen_offset` default — add a per-zone Vector2 in that scene's `_interact_anchor()`.
- **Verdict:** canon
- **Final wording:** Keep the rule (per-zone visual nudge only; doesn't move the trigger). Drop stale `TABLE_PROMPT_VISUAL_OFFSET` cafeteria example unless a live example exists.
- **Cascade:** AI_DOCS (remove obsolete example name if unused)

### S4-25 — UiPolygonHotspot
- **Original claim:** `UiPolygonHotspot` — Control-layer clickable polygon on cover-fit backgrounds; texture-pixel space; activated signal; hover tint; tune vertex handles only.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-26 — CrtPowerFx + no baseline post-FX in .tscn
- **Original claim:** Shared CRT power tweens in `crt_power_fx.gd`; interact uses `compact_chip_options()`; do not embed baseline post-FX in `.tscn`.
- **Verdict:** canon
- **Final wording:** (unchanged; baseline-in-.tscn already covered by S4-06)
- **Cascade:** —

### S4-31 — Typography VT323
- **Original claim:** Typography: VT323 primary.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S4-32 — Mood
- **Original claim:** Mood: dread, guilt, memory corruption; wins feel uneasy, not celebratory.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S5-01 — Decaying school / guilt return / locker hub
- **Original claim:** Decaying school; guilt-driven return; locker hub.
- **Verdict:** canon (+ explain)
- **Final wording:** Decaying school; guilt-driven return. Primary navigation is walking between connected scenes. Locker hub exists but is not the main room-to-room path. School map is planned to unlock only after finding it by walking scenes first (exact final product TBD).
- **Cascade:** Lore anchors; scene docs that overstate hub-first navigation

### S5-02 — Memories / collectibles
- **Original claim:** Memories; Flashlight/Key/Shovel/Name.
- **Verdict:** canon (+ explain)
- **Final wording:** Lore collectibles include Memories plus Flashlight / Key / Shovel / Name (Name may change to something found in the classroom). Each lore item that counts toward the true ending also increases combat encounter goals — true ending path is harder. School map is also a collectible: unlocks locker fast travel only; does **not** raise encounter goals. Map is found by walking scenes first.
- **Cascade:** Lore anchors; combat/encounter goal docs when wired
- **Note:** Flashlight is live in kitchen; several others still planned.

### S5-03 — Basement confrontation
- **Original claim:** Basement confrontation.
- **Verdict:** canon
- **Final wording:** (unchanged — story beat; full playable climax still largely planned)
- **Cascade:** —

### S5-04 — Axel identity and endings
- **Original claim:** Axel identity and endings.
- **Verdict:** canon
- **Final wording:** (unchanged — core mystery; ending scenes exist, many still placeholders)
- **Cascade:** —

### S5-05 — Cigarettes/lighter motifs + lore source note
- **Original claim:** Cigarettes/lighter ritual as recurring motifs.
- **Verdict:** canon (+ explain)
- **Final wording:** Cigarettes/lighter ritual as recurring motifs. Lore bullets in AI_DOCS are canon but may still change. Most detailed written lore lives under `plans/scenes/`.
- **Cascade:** Lore anchors section

### S6-01 — Plans vs code truth
- **Original claim:** Plans = design truth; code = behavior truth — reconcile before changing mechanics.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S6-02 — Ask before large/ambiguous scope
- **Original claim:** Ask before large or ambiguous scope; do not assume unstated layout, economy, or behavior.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S6-03 — Scoped additive edits / combat determinism
- **Original claim:** Prefer scoped, additive edits; keep combat deterministic and replayable.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S6-04 — No machine-absolute paths
- **Original claim:** No machine-absolute paths in shared gameplay code.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S6-05 — Conflict with canon
- **Original claim:** If a request conflicts with canon, stop and offer 2–4 options (strict canon, adapted, explicit override) before implementing.
- **Verdict:** canon (+ explain)
- **Final wording:** If a prompt breaks established rules, remind the user of those rules before implementing. Most often the new prompt will become the new canon after that reminder/confirmation.
- **Cascade:** How to work; governance rule if it still says only “offer 2–4 options”

### S7-01 — New chat per Explore/Plan/Implement
- **Original claim:** Use a new chat for each step (Explore → Plan → Implement).
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S7-02 — Model table
- **Original claim:** Explore Auto/Composer; Plan Premium+Plan mode; Implement Auto/Cursor Grok (+ templates).
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S7-03 — Exploration artifact handoff
- **Original claim:** Handoff = copy only EXPLORATION ARTIFACT into Plan; Plan must not re-verify in repo.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S7-04 — Batch clarifying questions on premium
- **Original claim:** Batch clarifying questions in one message on premium.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S7-05 — Git commits for history
- **Original claim:** Use git commits for history.
- **Verdict:** canon
- **Final wording:** (unchanged) — agents still only commit when the user asks.
- **Cascade:** —

### S7-06 — Headless verify playtest script
- **Original claim:** Headless verify: `tools/qa/run_default_playtest.ps1` when touching combat, scenes, or movement contracts.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S8-01 — SCENE_BUILDING / scene agent
- **Original claim:** Building a new scene? Read `plans/scenes/SCENE_BUILDING.md` first. Alias: `scene agent`.
- **Verdict:** canon (+ explain)
- **Final wording:** Keep as the mandatory scene-building entry point / `scene agent` alias. Must be reviewed and updated against current game state so it stays relevant (cascade / follow-up pass).
- **Cascade:** `plans/scenes/SCENE_BUILDING.md` — full current-state review required
- **Follow-through:** After AI_DOCS S8 Q&A, walk SCENE_BUILDING against live scenes/helpers and update stale bits.

### S8-02 — Scene dialogue index
- **Original claim:** `AXEL_SCENES_NEW.md` → `AXEL_SCENES_ARC1.md` … `ARC7.md` (locked rewrite dialogue; no HTML SOURCE).
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S8-03 — Folder / naming taxonomy
- **Original claim:** Folder / naming taxonomy: `plans/references/README_STRUCTURE.md`.
- **Verdict:** canon (+ explain)
- **Final wording:** Keep as the taxonomy reference, but review/update contents against current game layout (likely stale since early development).
- **Cascade:** `plans/references/README_STRUCTURE.md` — current-state review required
- **Follow-through:** During cascade, check folder layout vs live project and fix stale guidance.

### S8-04 — Derive camera limits from art
- **Original claim:** Derive camera limits from art size — never hand-tune `limit_*` / `fixed_x`.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S8-05 — Background layout/camera helpers
- **Original claim:** Helpers: `background_layout.gd`, `background_camera_controller.gd`.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S8-06 — Default camera_mode / fit_mode / margin
- **Original claim:** Default `camera_mode = static_locked`; `fit_mode` cover or contain; optional `margin_px`.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S8-07 — Sync EnvironmentColliders on layout_applied
- **Original claim:** Sync `EnvironmentColliders` on `layout_applied`.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S8-08 — Locked exploration background
- **Original claim:** Lock background with `locked_exploration_background.gd`.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S8-09 — Shipped Arc 2 walkable inventory
- **Original claim:** Shipped Arc 2 walkable: 2.1 / 2.3; 2.2 placeholder; kitchen art note.
- **Verdict:** not canon
- **Final wording:** Remove from AI_DOCS. AI_DOCS is an overall instructions/rulebook, not a shipped-scene reference guide — what’s walkable/shipped comes from live game state. Same for other AI_DOCS scene-inventory dumps (Arc 1 detail lists, “shipped test instance” notes).
- **Cascade:** AI_DOCS Optional references rewrite; SCENE_BUILDING / arc notes may hold scene status if needed

### S8-principle — AI_DOCS is rulebook not scene catalog
- **Verdict:** canon (user directive)
- **Final wording:** Do not keep shipped-scene inventories or per-scene numeric dumps in AI_DOCS. Point to live game + `SCENE_BUILDING.md` / `plans/scenes/` instead.
- **Applies to:** S8-09 removed; Arc 1 detail bullet removed/shrunk; MemoryIndicator “shipped test instance” removed; S8-11–S8-25 scene-specific dumps treated as out of AI_DOCS scope (rules may remain in SCENE_BUILDING).

### S8-10 — Memory indicator rules
- **Original claim:** MemoryIndicator parent under PlayerLayer; cover-fit remap on layout_applied; don’t derive from another shape.
- **Verdict:** canon
- **Final wording:** Keep as short rules in AI_DOCS; details/examples in live scenes + SCENE_BUILDING.
- **Cascade:** SCENE_BUILDING if memory-indicator guidance is thin there

### S8-11–S8-25 — Arc 1 per-scene dumps
- **Original claim:** Root at (0,0); camera modes 1.1/1.2; player layer; cover sync scene list; 1.1 free XY; no canvas stretch; corridor_large; window 1920×1280; exploration_viewport inert; leaf fade; playtest scene; deferred migration; etc.
- **Verdict:** not canon for AI_DOCS (per S8-principle)
- **Final wording:** Removed from AI_DOCS. Legacy Arc 1: do not change without approval; specifics from live scenes + SCENE_BUILDING.
- **Cascade:** SCENE_BUILDING current-state review should absorb any still-needed Arc 1 rules

### S8-26 — Headless checks optional
- **Original claim:** Headless checks via run_default_playtest.ps1 / bots README — manual, not every chat.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —

### S8-27 — Collisions editor doc
- **Original claim:** Collisions (editor): `plans/core/PLAYTEST_DEBUG_COLLISIONS.md`
- **Verdict:** not canon
- **Final wording:** Remove pointer from AI_DOCS and delete `PLAYTEST_DEBUG_COLLISIONS.md`.
- **Cascade:** delete file; strip AI_DOCS bullet; any other refs to that path

### S8-28 — .cursorignore indexing
- **Original claim:** Root `.cursorignore` excludes logs/`.godot`/export captures/`plans/archive/**`/tool caches; keeps `exports/game_data.json` and `exports/GameManager.gd` indexed.
- **Verdict:** canon
- **Final wording:** (unchanged)
- **Cascade:** —
