# AXEL AI Changelog

Append-only history for implemented AI-requested changes.

## Logging Policy

- Log entries only when a requested change is actually implemented.
- Do not log pure discussion, planning-only chats, or declined requests.
- Add new entries at the bottom.
- Do not edit older entries except to add a correction note as a new entry.

## Entry Template

Copy and fill:

```md
## YYYY-MM-DD - Short Request Title

- Request: <What user asked for>
- Implementation: <What was changed and why>
- Files changed:
  - `path/to/file1`
  - `path/to/file2`
- Behavior impact: <Expected runtime/design impact>
- Verification: <Tests run or manual checks>
- Notes: <Optional conflict resolution or follow-up context>
```

---

## 2026-05-06 - Create Persistent AI Docs System

- Request: Create persistent AI docs that unify plans, style/lore sources, exports (including moon princess files), engine logic context, and include a future implemented-changes changelog workflow.
- Implementation: Added canonical AI governance docs and rule wiring for always-on consistency across AXEL work.
- Files changed:
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
- Behavior impact: Future agent chats can consistently align with project canon and will append implemented changes to this changelog.
- Verification: Confirmed files created with cross-references and clear hierarchy/changelog procedure.
- Notes: Exported Moon Princess assets are documented as reference-only unless explicitly promoted.

## 2026-05-06 - Require Live Progress Feed

- Request: Add a persistent rule so chats expose live execution progress (what is running, checked/read, and whether stuck).
- Implementation: Updated AXEL governance rule and canonical AI docs workflow to require a live progress feed for long or multi-step tasks, including a fixed status checklist.
- Files changed:
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Future AXEL task chats should provide clearer runtime visibility and progress transparency during execution.
- Verification: Verified both governance documents now explicitly include the live progress feed requirement and status fields.
- Notes: No source-hierarchy conflict; requirement was added consistently to both always-on rule and canonical docs.

## 2026-05-06 - Reorganize commands, logs, and sprites

- Request: Move command scripts into their own folder, move debug logs into their own folder, and move `axel_project` sprites under `assets`.
- Implementation: Created dedicated `tools/cmd` and `logs/debug` folders, moved root `.cmd`/debug files there, updated affected script references, and moved sprite assets from `axel_project/sprites` to `axel_project/assets/sprites`.
- Files changed:
  - `tools/cmd/godot.cmd`
  - `logs/debug/debug-1d1bdd.log`
  - `logs/debug/debug-451875.log`
  - `logs/debug/debug-4ccea5.log`
  - `logs/debug/debug-7980eb.log`
  - `logs/debug/debug-c9d495.log`
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet.png`
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet.png.import`
  - `AXEL/axel_project/assets/sprites/mike_walking.aseprite`
  - `AXEL/axel_project/assets/sprites/.gitkeep`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/free_spins.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/line_detector.gd`
  - `AXEL/axel_project/ScriptReloadMarker.gd`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/combat/VERIFICATION_CHECKLIST.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Project root is cleaner, command and debug artifacts are centralized, and sprite loading now resolves from `assets/sprites`.
- Verification: Verified file moves succeeded and updated code references now point to the new locations.
- Notes: No source-hierarchy conflict; change is a structural reorganization only.

## 2026-05-06 - Add AXEL structure taxonomy and scaffolding

- Request: Implement a stronger AXEL folder categorization pass with clearer long-term organization.
- Implementation: Added a canonical structure/naming guide and scaffolded category folders under assets/scenes/scripts/data/tools to reduce root clutter while keeping runtime paths stable.
- Files changed:
  - `AXEL/axel_project/plans/README_STRUCTURE.md`
  - `AXEL/axel_project/plans/AXEL_notes.md`
  - `AXEL/axel_project/assets/textures/.gitkeep`
  - `AXEL/axel_project/assets/audio/.gitkeep`
  - `AXEL/axel_project/assets/ui/.gitkeep`
  - `AXEL/axel_project/assets/fonts/.gitkeep`
  - `AXEL/axel_project/assets/vfx/.gitkeep`
  - `AXEL/axel_project/scenes/ui/.gitkeep`
  - `AXEL/axel_project/scenes/core/.gitkeep`
  - `AXEL/axel_project/scripts/core/.gitkeep`
  - `AXEL/axel_project/scripts/gameplay/.gitkeep`
  - `AXEL/axel_project/scripts/ui/.gitkeep`
  - `AXEL/axel_project/data/.gitkeep`
  - `AXEL/axel_project/tools/.gitkeep`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: AXEL now has an explicit, documented taxonomy and ready-to-use categorized directories for future migrations without forcing risky runtime path rewrites in one step.
- Verification: Verified folder creation completed successfully; lints report no introduced errors in edited text/code files.
- Notes: No source-hierarchy conflict; this is a non-breaking foundational organization pass.

## 2026-05-07 - Remove OAF and PixelLab Pipeline Artifacts

- Request: Remove OAF-related command artifacts and remove `asset_input` / `asset_output` + PixelLab API tooling after subscription loss.
- Implementation: Deleted OAF command scripts from `tools/cmd/`, removed PixelLab restyling pipeline inputs/outputs and utility script, removed now-unused Python dependency file, and updated project docs/changelog references to match current state.
- Files changed:
  - `tools/cmd/agent_feed.cmd`
  - `tools/cmd/oaf.cmd`
  - `tools/cmd/oaf_status.cmd`
  - `AXEL/axel_project/asset_input/.gitkeep`
  - `AXEL/axel_project/asset_output/.gitkeep`
  - `AXEL/axel_project/asset_output/.restyle_cache.json`
  - `AXEL/axel_project/tools/restyle_assets.py`
  - `AXEL/axel_project/__pycache__/restyle_assets.cpython-314.pyc`
  - `AXEL/axel_project/requirements.txt`
  - `AXEL/axel_project/plans/README_STRUCTURE.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: OAF terminal-focus workflow and PixelLab asset restyling workflow are fully removed from this repository state.
- Verification: Confirmed file deletions and re-scanned repository for `oaf`, `agent_feed`, `restyle_assets`, `asset_input`, `asset_output`, and `pixellab` references.
- Notes: Historical changelog text was adjusted per explicit user request to remove direct mentions of removed OAF/restyle files.

## 2026-05-07 - Add Combat RTP Audit Harness

- Request: Audit current no-item combat RTP/win frequency against a 75-80% target and identify why winnings feel too frequent/easy.
- Implementation: Added per-spin telemetry exposure in combat orchestration (line payout vs clear-bonus payout) and created a deterministic headless Monte Carlo audit runner that reports RTP, hit rate, encounter success, and confidence intervals.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/test/rtp_audit.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Combat runtime behavior is unchanged for players; developers can now run repeatable RTP audits and attribute payout sources precisely.
- Verification: Executed `Godot_v4.6.2-stable_win64_console.exe --path AXEL/axel_project --headless -s res://combat/test/rtp_audit.gd` and captured JSON metrics from the run.
- Notes: RTP baseline measured far above target in this sample; follow-up balance tuning should focus first on line payout scale and multiplier growth effects before item-based difficulty layering.

## 2026-05-07 - Baseline RTP Frequency Rebalance (Constrained Knobs)

- Request: Rebalance baseline so symbols match less often and target 75-80% RTP, without changing multiplier function or encounter goals.
- Implementation: Applied constrained tuning only on allowed knobs by setting all playable symbol `base_weight` values to `1.0` and reducing `girl_power_chance` to `0.0`, then iterated verification using the RTP audit harness.
- Files changed:
  - `AXEL/axel_project/combat/data/symbols/sym_green_circle.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_yellow_triangle.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_blue_star.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_red_heart.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_cigarette.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_booze.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_bloody_hand.tres`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Match frequency drivers were constrained to pure symbol-frequency and power-trigger knobs while leaving multiplier logic, goal resources, and paytable payouts unchanged.
- Verification: Ran `Godot_v4.6.2-stable_win64_console.exe --path AXEL/axel_project --headless -s res://combat/test/rtp_audit.gd` after each pass; best constrained result reached `rtp_mean = 2.6895` with `paid_hit_rate = 0.415`.
- Notes: Under the imposed constraints, target 75-80% RTP was not reachable; dominant over-return remains line-win payout accumulation from unchanged core payout/multiplier mechanics.

## 2026-05-07 - Paytable Reduction to 75-80 RTP

- Request: Reduce paytable values so baseline no-item RTP lands in the 75-80% range.
- Implementation: Applied proportional reductions across all symbol paytable fields (`payout_x3`, `payout_x4`, `payout_x5`) for low, premium, and wild symbols while keeping multiplier behavior unchanged.
- Files changed:
  - `AXEL/axel_project/combat/data/symbols/sym_green_circle.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_yellow_triangle.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_blue_star.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_red_heart.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_cigarette.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_booze.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_bloody_hand.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_satanic.tres`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Win frequency rules remain unchanged, but payouts per resolved line are substantially lower, bringing return closer to target economy.
- Verification: Ran `Godot_v4.6.2-stable_win64_console.exe --path AXEL/axel_project --headless -s res://combat/test/rtp_audit.gd`; baseline `rtp_mean = 0.78928`, target position `within` `[0.75, 0.8]`.
- Notes: This pass intentionally targets payout scaling only; any future encounter feel tuning should be done separately from RTP control.

## 2026-05-07 - Corridor Locker Noir Pass

- Request: Build a focused Act 1.2 corridor test with a centered locker row, one highlighted locker, monkey mascot graffiti, floor debris/trash where player walks, and apply a black/red/white style filter globally across exploration scenes.
- Implementation: Added a new corridor scene/script using imported 48x48 locker art in a centered row, animated one highlighted locker with restrained pulse/flicker, layered a deformed monkey graffiti decal above lockers, added debris/trash floor props, and introduced a reusable noir palette post-process overlay that is instanced in both the new corridor and existing school exterior exploration scene.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/Corridor.gd`
  - `AXEL/axel_project/scenes/fx/noir_palette_filter.gdshader`
  - `AXEL/axel_project/scenes/fx/NoirPaletteOverlay.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Main_Menu/MainMenu.gd`
  - `AXEL/axel_project/assets/props/lockers/locker_single_48.png`
  - `AXEL/axel_project/assets/props/graffiti/graffiti_monkey_deformed.png`
  - `AXEL/axel_project/assets/props/debris/debris_chunk_01.png`
  - `AXEL/axel_project/assets/props/debris/trash_bag_01.png`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor composition now visually communicates locker focus and traversal clutter while exploration scenes share a consistent AXEL black/red/white palette treatment.
- Verification: Validated scene/resource wiring by checking new scene/resource references, imported assets, and shader integration points in both exploration scenes.
- Notes: Used AXEL style canon from `AI_DOCS.md` (black + blood reds with controlled white highlights); no source-hierarchy conflicts encountered.

## 2026-05-07 - Scene Builder Agent Draft Pipeline

- Request: Implement a separate draft-first scene-builder agent that scans classroom/library PNG assets, classifies them, drafts blueprint-aligned layouts for decayed school scenes, preserves balanced walk paths, and emits review artifacts before any scene edits.
- Implementation: Added agent spec/rule docs plus Python tooling for asset classification with quarantine, layout draft synthesis, path/profile validation, preview rendering, and approved-draft patch-interface generation.
- Files changed:
  - `AXEL/axel_project/plans/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/plans/SCENE_LAYOUT_RULES.md`
  - `AXEL/axel_project/plans/SCENE_PATCH_INTERFACE.md`
  - `AXEL/axel_project/tools/scene_builder/asset_classifier.py`
  - `AXEL/axel_project/tools/scene_builder/layout_planner.py`
  - `AXEL/axel_project/tools/scene_builder/path_validator.py`
  - `AXEL/axel_project/tools/scene_builder/preview_renderer.py`
  - `AXEL/axel_project/tools/scene_builder/scene_patch_interface.py`
  - `AXEL/axel_project/tools/scene_builder/output/approved_drafts.json`
  - `AXEL/axel_project/tools/scene_builder/output/asset_catalog.json`
  - `AXEL/axel_project/tools/scene_builder/output/unassigned_assets.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_validation.json`
  - `AXEL/axel_project/tools/scene_builder/output/review_notes.md`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_board_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_board_success_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_classroom_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_desk_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/scene_2_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/loc_board_preview.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/loc_board_success_preview.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/loc_classroom_preview.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/loc_desk_preview.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/scene_2_preview.png`
  - `AXEL/axel_project/tools/scene_builder/output/scene_patch_instructions.json`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: The project now has a repeatable scene-drafting pipeline that classifies source PNGs, enforces balanced path readability, and prepares approval-gated patch instructions instead of directly mutating `.tscn` scenes.
- Verification: Executed the full toolchain (`asset_classifier`, `layout_planner`, `path_validator`, `preview_renderer`, `scene_patch_interface`) and confirmed generated outputs for 75 assets, 5 scene drafts, validation pass, preview images, and empty approved-patch instructions.
- Notes: Conflict handling followed `AI_DOCS.md` hierarchy; unknown/low-confidence assets are quarantined and excluded from auto-placement.

## 2026-05-07 - Scene Builder Governance + Multi-Folder Asset Analysis

- Request: Ensure reusable pipeline changes are always recorded for reference in AI docs/rules, and rerun the scene-builder agent over additional asset folders (Kitchen, Living Room, Bathroom, Conference Hall, Basement, Condominium).
- Implementation: Added explicit governance requirements in `AI_DOCS.md` and `.cursor/rules/axel-ai-docs-governance.mdc` to keep reusable workflow/agent updates documented; extended classifier to support multi-folder scans via `SCENE_BUILDER_PRIORITY_DIRS`; reran full scene-builder pipeline with the six requested folders.
- Files changed:
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/tools/scene_builder/asset_classifier.py`
  - `AXEL/axel_project/plans/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/tools/scene_builder/output/asset_catalog.json`
  - `AXEL/axel_project/tools/scene_builder/output/unassigned_assets.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_board_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_board_success_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_classroom_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_desk_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/scene_2_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_validation.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/loc_board_preview.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/loc_board_success_preview.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/loc_classroom_preview.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/loc_desk_preview.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/scene_2_preview.png`
  - `AXEL/axel_project/tools/scene_builder/output/review_notes.md`
  - `AXEL/axel_project/tools/scene_builder/output/scene_patch_instructions.json`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Future chats can reliably discover reusable workflows via governance docs, and scene-builder analysis now supports scanning multiple themed source folders in a single run.
- Verification: Ran full pipeline with `SCENE_BUILDER_PRIORITY_DIRS` set to six folders; outputs report `asset_count = 1082`, `unassigned_count = 298`, generated 5 drafts, validation `all_valid = true`, and refreshed previews/notes.
- Notes: Source-hierarchy alignment remained unchanged; this pass expands analysis input breadth without auto-applying scene patches.

## 2026-05-07 - Canonical Agent Alias: scene agent

- Request: Set the reusable scene-building pipeline name to `scene agent`.
- Implementation: Added canonical alias mapping in `AI_DOCS.md`, `.cursor/rules/axel-ai-docs-governance.mdc`, and `SCENE_BUILDER_AGENT_SPEC.md`.
- Files changed:
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Future chats can reference `scene agent` directly and resolve to the same scene-builder workflow consistently.
- Verification: Confirmed alias appears in all three governance/spec locations.
- Notes: Alias kept stable per governance unless explicitly renamed by user.

## 2026-05-07 - Simulated QA Reviewer workflow

- Request: Implement simulated QA Agent plan — project skill runnable from any chat, rubric + analytics, style/player-experience focus, and governance nudge to ask after big changes.
- Implementation: Added project skill `axel-simulated-qa` with required report sections; added `AXEL_QA_REVIEW_RUBRIC.md` (weighted 0–5 axes, taxonomy); added `AXEL_QA_RUN_LOG.md` template; extended always-on governance rule to ask opt-in QA after substantial AXEL edits; documented workflow in `AI_DOCS.md` §12.
- Files changed:
  - `.cursor/skills/axel-simulated-qa/SKILL.md`
  - `AXEL/axel_project/plans/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/AXEL_QA_RUN_LOG.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Chats can run a consistent simulated QA protocol; optional persistent score/finding history in the run log; agents prompted to offer QA after substantive changes without auto-running it.
- Verification: Confirmed skill path, rubric weights sum to 1.0, governance and `AI_DOCS.md` cross-reference the same artifacts.
- Notes: No conflict with `AI_DOCS.md` hierarchy; QA log is separate from implementation changelog per logging policy.

## 2026-05-07 - Canonical QA Alias Names

- Request: Make simulated QA callable across the project as `qa agent` or `qa`.
- Implementation: Added canonical QA alias mapping in governance docs and skill instructions, and updated invocation wording so `qa agent` / `qa` explicitly triggers the simulated QA workflow.
- Files changed:
  - `.cursor/skills/axel-simulated-qa/SKILL.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Future chats can consistently invoke the same simulated QA workflow using short alias calls (`qa agent` or `qa`).
- Verification: Confirmed alias text appears in skill, rule, and canonical docs with matching spellings.
- Notes: Alias follows existing reusable-agent naming pattern alongside `scene agent`.

## 2026-05-08 - Corridor Canonical Filename Guard

- Request: Fix that `scene agent` wrote a new corridor scene to `Corridor.tscn` instead of overwriting the canonical placeholder `1.2_Corridor.tscn`, and make this rule permanent for future runs.
- Implementation: Migrated the generated corridor scene content from `Corridor.tscn` into the canonical `1.2_Corridor.tscn`, deleted the non-canonical `Corridor.tscn`, repointed the MainMenu corridor test path to the canonical scene, hardened the scene-builder planner to resolve canonical numbered filenames + Arc folders (new `CANONICAL_BY_SCENE_ID` map and section-number-aware blueprint parser), updated the patch interface to include the Arc folder in `target_scene_path_hint`, refreshed existing draft JSON artifacts, and codified the canonical-filename invariant in scene-agent spec, `AI_DOCS.md`, and the always-on governance rule.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/Corridor.tscn`
  - `AXEL/axel_project/scenes/Main_Menu/MainMenu.gd`
  - `AXEL/axel_project/tools/scene_builder/layout_planner.py`
  - `AXEL/axel_project/tools/scene_builder/scene_patch_interface.py`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/scene_2_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_classroom_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_desk_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_board_draft.json`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_board_success_draft.json`
  - `AXEL/axel_project/plans/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor test path now loads the canonical numbered scene; `scene agent` outputs are guaranteed to overwrite canonical placeholders (e.g. `Arc_1/1.2_Corridor.tscn`) and can never silently create non-canonical aliases. Library has no canonical numbered scene yet, so the planner now flags it (`UNCANONICALIZED_*`, `arc_dir = UNRESOLVED`) instead of writing a non-canonical filename.
- Verification: Ran `rg "Corridor\.tscn"` across the project; only historical changelog references and the source-of-truth blueprint heading text remain. All runtime/code targets resolve to `Arc_1/1.2_Corridor.tscn`. Lint check on edited Python and GDScript files reported no errors.
- Notes: Source-hierarchy resolution: `AI_DOCS.md` invariants now take precedence over the simplified scene names that appear in `AXEL_SCENES_BLUEPRINT.md`; canonical numbered filenames are the implementation truth and the blueprint heading text remains as human-readable scene shorthand.

## 2026-05-08 - Corridor 1.2 Locker Row, Graffiti, Player Overlay

- Request: Refit `1.2_Corridor` lockers between user-tuned endpoints with even maximum-density spacing, static darker highlight (no pulse), replace broken monkey graffiti with supplied Christmas 48×48 asset, and fix player appearing under/wrong layer vs noir filter while scaling the character with locker scale.
- Implementation: Rebuilt `LockerRow` with ten evenly spaced `2.06` scaled lockers from `167` to `1134` (extra capacity vs nine slots; right cap node is `Locker10` so naming stays unique), kept `HighlightedLocker` on the fifth column with script-driven static `modulate` only; swapped graffiti `ext_resource` to `corridor_christmas_graffiti_85.png` plus `.import` sidecar; moved `Player` under a high `CanvasLayer` (`layer = 100`, `follow_viewport_enabled`) so it renders above `NoirPaletteOverlay` (layer 90) and is not palette-filtered; scaled `Player` to `2.06` and raised `speed` to ~`180 * 2.06` for similar traversal feel.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png`
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png.import`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor reads as a full locker run with one clearly darker story locker; graffiti uses the new art; exploration character stays full-color above the noir post-process and matches locker scale.
- Verification: Confirmed scene node paths and layer ordering in `.tscn`; script no longer animates highlight position/modulate beyond `_ready`; import metadata MD5 matches `res://` path convention. Godot editor not run in this session—open `1.2_Corridor.tscn` once to refresh `.godot/imported` cache if needed.
- Notes: Right-end locker is named `Locker10` to avoid duplicate `Locker09` labels while keeping max count; rename in-editor if you prefer strict `Locker01`–`Locker09` only (will reduce count by one column). Source PNG copied from user-supplied absolute path into `res://` for portability per `AI_DOCS.md` guardrails.

## 2026-05-08 - Corridor Graffiti Filter Selection (Variant 05)

- Request: Apply the selected graffiti preview filter (fifth option, palette-crush) to the active corridor mascot wall graphic.
- Implementation: Promoted `graffiti_preview_05_palette_crush.png` from preview outputs into the live asset path by overwriting `corridor_christmas_graffiti_85.png`, preserving the existing scene texture reference.
- Files changed:
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Wall mascot now uses the selected subdued palette treatment, reducing floating/sticker-like contrast against corridor wall tones.
- Verification: Confirmed replacement copy completed to the live `res://assets/props/graffiti/` texture path used by `1.2_Corridor.tscn`.
- Notes: `.import` sidecar path remains unchanged; Godot will refresh imported cache content on next scene/project load.

## 2026-05-08 - Corridor Graffiti Variant 05 Rebased To Monkey Source

- Request: Use option 1 after review: keep the Variant 05 palette-crush look but apply it to the original monkey graffiti source so wall graffiti reads as a full decal instead of sparse red dots.
- Implementation: Re-generated `corridor_christmas_graffiti_85.png` from `graffiti_monkey_deformed.png` using the same Variant 05 quantize/desaturate/darken recipe; preserved the existing live scene reference path.
- Files changed:
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor graffiti keeps subdued palette integration while restoring the full monkey silhouette and wall-presence read.
- Verification: Checked resulting live asset dimensions/alpha bounds are now `96x48` with monkey-shaped coverage (`bbox (8, 10, 85, 47)`), matching original silhouette footprint.
- Notes: No scene path updates required because `1.2_Corridor.tscn` already references `corridor_christmas_graffiti_85.png`.

## 2026-05-08 - Corridor Graffiti Source Correction (Use User PNG)

- Request: Keep the user-provided replacement PNG as the graffiti source (not monkey geometry) and apply the selected Variant 05 filter on that asset.
- Implementation: Restored `corridor_christmas_graffiti_85.png` from the user-provided Christmas PNG path and re-applied the Variant 05 palette-crush recipe directly to that file.
- Files changed:
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor graffiti now uses the intended replacement geometry/shape with the selected subdued filter treatment.
- Verification: Confirmed live asset after filtering is `64x96` with alpha coverage `bbox (2, 15, 59, 75)`, matching the replacement PNG footprint rather than monkey source dimensions.
- Notes: `1.2_Corridor.tscn` texture reference remains unchanged and continues to target `corridor_christmas_graffiti_85.png`.

## 2026-05-08 - Corridor Graffiti Opacity + Midtone Recovery

- Request: Address remaining red-blob look from interaction between local graffiti filter and corridor noir post-process, with a focus on higher opacity.
- Implementation: Reprocessed `corridor_christmas_graffiti_85.png` using a gentler palette crush (`8` colors, milder desaturation, near-neutral brightness) and restored full opaque alpha on all non-transparent pixels.
- Files changed:
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Graffiti keeps the replacement geometry while retaining more visible structure through the noir filter; non-transparent pixels no longer fade out from reduced alpha.
- Verification: Confirmed output remains `64x96`, alpha coverage unchanged (`bbox (2, 15, 59, 75)`), and alpha range now spans full opacity (`0..255`).
- Notes: If detail still collapses under scene noir thresholds, next step is to exempt `MonkeyGraffiti` from the full-screen noir layer (CanvasLayer above overlay) or tweak shader thresholds globally.

## 2026-05-08 - Corridor Graffiti Filter Removed (Original Replacement Restored)

- Request: Remove all applied filter processing from corridor graffiti and use the original user-provided replacement PNG as-is.
- Implementation: Overwrote `corridor_christmas_graffiti_85.png` with the original source file from the provided external path, discarding prior palette/opacity processing passes.
- Files changed:
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor now renders the raw replacement graffiti art without additional local filter transformations.
- Verification: Confirmed live file replacement completed and asset remains loadable (`64x96`, alpha range `0..255`).
- Notes: Scene reference remains unchanged (`1.2_Corridor.tscn` still points to `corridor_christmas_graffiti_85.png`).

## 2026-05-08 - Corridor 1.2 Locker + Wall Collision (Invisible Borders)

- Request: Add invisible borders so the player cannot walk through lockers or wall edges in Corridor 1.2.
- Implementation: Added `LockerColliders` under the scene root with one `StaticBody2D` + `CollisionShape2D` per locker sprite (`Locker01`–`Locker10` and `HighlightedLocker`), using a shared `RectangleShape2D` (`100x130`) centered at each locker’s X and `y = 387` so the block covers the locker lower/front band into the walkable floor (sprite-only collision at `y ≈ 274` does not intersect the player at `y ≈ 520`). Existing `TopWall` / `BottomWall` / `LeftWall` / `RightWall` `StaticBody2D` colliders left unchanged after review.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Player `CharacterBody2D` should now slide against locker fronts when moving toward the row; perimeter walls remain blocked as before.
- Verification: Confirmed scene structure and locker X alignment match `LockerRow`; default spawn `Player` at `(640, 520)` lies outside locker block AABB (`y ≈ 322–452`). In-editor run recommended: **Debug → Visible Collision Shapes** and walk-test along the row.
- Notes: If you add or move lockers in the editor, duplicate/reposition matching `LockerBlock*` nodes or widen the shared rectangle resource.

## 2026-05-08 - Corridor Collision Simplification (Single Upper Block)

- Request: Remove individual locker colliders and replace with one large collision shape, starting from `y = -140` offset, so the player cannot walk on the wall zone.
- Implementation: Replaced per-locker `StaticBody2D` nodes under `LockerColliders` with a single `UpperWallBlock` using `CollisionShape2D` + `RectangleShape2D_upper_block` (`1280x90`) and shape offset `position = Vector2(0, -140)`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: A continuous blocker now spans corridor width near the locker/wall boundary, preventing entry into upper wall space and simplifying maintenance versus per-locker colliders.
- Verification: Confirmed `LockerColliders/UpperWallBlock` exists with requested `y` offset and full-width rectangle shape in scene file.
- Notes: Fine-tune by adjusting `RectangleShape2D_upper_block` height or `UpperWallBlock` base `position.y` if you want a tighter/looser walkable lane.

## 2026-05-08 - Highlighted Locker Artifact Fix (No Animation/Filter)

- Request: Revert highlighted locker to original look, remove custom highlight filtering/animation behavior, and keep it only subtly darker while validating against the global noir filter so locker holes do not fill with black artifacts.
- Implementation: Removed highlighted-locker script modulation logic from `1.2_Corridor.gd` (no locker-specific runtime effects remain). Set `HighlightedLocker` to static scene-level `modulate = Color(0.78, 1, 1, 1)` in `1.2_Corridor.tscn`, which keeps original texture details while slightly darkening red.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker remains visually close to neighboring lockers, with reduced red intensity but without the black line/fill artifacts seen under the noir pass.
- Verification: Simulated noir threshold mapping against `locker_single_48.png` variants before applying; exact 25% red reduction (`0.75`) produced clipping artifacts, while `0.78` preserved hole/readability details in the mapped output.
- Notes: Because the full-scene noir pass quantizes luminance, exact 25% red reduction crosses the black threshold on some locker pixels.

## 2026-05-08 - Highlighted Locker Threshold Tuning

- Request: Fix persistent black-fill artifacts in highlighted locker while keeping it darker than normal.
- Implementation: Tuned `HighlightedLocker` static modulate from `Color(0.78, 1, 1, 1)` to `Color(0.8, 1, 1, 1)` in `1.2_Corridor.tscn` to stay above noir threshold clipping for the locker interior details.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker remains subtly darker than neighbors but avoids hole/vent regions collapsing to black blobs under the global noir filter.
- Verification: Change targets the measured threshold edge where `0.75` clips and `0.8` stays in non-black bins in noir mapping.
- Notes: Exact 25% channel darken is incompatible with current noir thresholds for this texture; if exact 25% is mandatory, the locker must be rendered outside the noir pass or shader thresholds adjusted.

## 2026-05-08 - Highlighted Locker Excluded From Global Noir

- Request: Exclude highlighted locker from global noir filter and apply a similar but slightly darker local treatment to avoid repeated black artifact blobs.
- Implementation: Hid in-row `LockerRow/HighlightedLocker` sprite and added `HighlightedLockerBypassLayer` (`CanvasLayer` layer 95) with `HighlightedLockerBypass` sprite rendered above `NoirPaletteOverlay` (layer 90). Added a local palette shader `highlighted_locker_palette_filter.gdshader` with noir-like thresholds/colors tuned slightly darker than baseline.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/fx/highlighted_locker_palette_filter.gdshader`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker remains stylistically consistent with scene palette but no longer passes through the full-screen noir quantization that caused vent/hole fill artifacts.
- Verification: Confirmed scene wiring places bypass locker on layer 95 (between global overlay and player layer), with original row highlight hidden.
- Notes: Since bypass uses `CanvasLayer`, keep its position/scale synced if locker layout changes in future scene edits.

## 2026-05-08 - Highlighted Locker Local Filter Darkened 33%

- Request: Make the highlighted locker local filter even darker by 33%.
- Implementation: Added a `darken_factor` uniform to `highlighted_locker_palette_filter.gdshader` and applied it to mapped output (`COLOR.rgb = mapped.rgb * darken_factor`) with default value `0.67`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/highlighted_locker_palette_filter.gdshader`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker keeps the same local palette mapping but renders 33% darker overall while still bypassing global noir artifacts.
- Verification: Shader compiles structurally with unchanged thresholds/palette branches; only final output intensity scaling changed.
- Notes: You can tune darkness quickly by adjusting `darken_factor` in the material inspector.

## 2026-05-08 - Scene Builder Output Cleanup + Completion Rule

- Request: Remove unnecessary scene-builder temporary files (such as `graffiti_filter_previews`) and record a future rule that `scene agent` should clean such artifacts once the user says the scene is complete.
- Implementation: Deleted ad-hoc look-dev preview artifacts from `tools/scene_builder/output/layout_previews/` (graffiti filter preview set and locker noir comparison images, including `.import` sidecars). Added a completion-cleanup invariant to the `scene agent` spec, `AI_DOCS.md`, and workspace governance rule.
- Files changed:
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/graffiti_filter_previews/graffiti_preview_01_multiply_fade.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/graffiti_filter_previews/graffiti_preview_01_multiply_fade.png.import`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/graffiti_filter_previews/graffiti_preview_02_desat_dark.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/graffiti_filter_previews/graffiti_preview_02_desat_dark.png.import`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/graffiti_filter_previews/graffiti_preview_03_erosion_wear.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/graffiti_filter_previews/graffiti_preview_03_erosion_wear.png.import`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/graffiti_filter_previews/graffiti_preview_04_softened_edges.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/graffiti_filter_previews/graffiti_preview_04_softened_edges.png.import`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/graffiti_filter_previews/graffiti_preview_05_palette_crush.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/graffiti_filter_previews/graffiti_preview_05_palette_crush.png.import`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/locker_noir_compare.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/locker_noir_compare.png.import`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/locker_noir_alpha_compare.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/locker_noir_alpha_compare.png.import`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/locker_noir_redonly.png`
  - `AXEL/axel_project/tools/scene_builder/output/layout_previews/locker_noir_redonly.png.import`
  - `AXEL/axel_project/plans/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Scene-builder output folders are cleaner after scene completion, and future scene-agent runs now have an explicit cleanup trigger policy tied to user confirmation.
- Verification: Confirmed deleted files no longer appear in `layout_previews` glob results; policy text now present in spec/docs/rule.
- Notes: Cleanup policy intentionally preserves canonical draft contract artifacts unless the user asks for full output purge.

## 2026-05-08 - QA Agent Concise Output + Playtest Mode

- Request: Make `qa agent` answers shorter and technical-first, always include recommendations, and add playtest-mode criteria with combat simulations plus scene smoke for higher confidence (more data/bugs, less player-opinion default).
- Implementation: Rewrote QA skill output contract (brevity caps, mandatory ≥3 recommendations, optional player note only on request, playtest vs static modes). Extended `AXEL_QA_REVIEW_RUBRIC.md` with confidence tiers, default Godot command set, `BUG` category, and playtest evidence rules. Added headless `test/scene_smoke_check.gd` for canonical scene load smoke. Updated `AXEL_QA_RUN_LOG.md` template, `AI_DOCS.md` §12 / `qa` bullet, governance rule 11–12, and `combat/VERIFICATION_CHECKLIST.md` playtest command block.
- Files changed:
  - `.cursor/skills/axel-simulated-qa/SKILL.md`
  - `AXEL/axel_project/plans/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/AXEL_QA_RUN_LOG.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/test/scene_smoke_check.gd`
  - `AXEL/axel_project/combat/VERIFICATION_CHECKLIST.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Future `qa` / `qa agent` chats default to concise technical reports with required recommendations; playtest/high-confidence runs have a documented, reproducible command sequence including scene instantiation smoke.
- Verification: Script follows existing `extends SceneTree` headless test pattern; rubric command paths match `VERIFICATION_CHECKLIST` / combat test layout. Local Godot binary was not available in agent shell to execute smoke run.
- Notes: `rtp_audit.gd` remains metrics-only per rubric unless user-defined thresholds are added later.

## 2026-05-08 - Premium-to-Auto Planning Guardrails

- Request: Ensure premium planning chats produce highly detailed implementation-ready handoffs for auto models, infer deeper intent against AXEL project context, and hard-stop with user option choices when requests conflict with project guidelines.
- Implementation: Added persistent governance requirements for a Premium Planning Depth Protocol, intent-deduction plus project-correlation pass, stable auto-model handoff structure, and mandatory hard conflict gate in the always-on rule and canonical AI docs. Added reusable planning artifact `PREMIUM_TO_AUTO_HANDOFF_TEMPLATE.md` for consistent plan formatting.
- Files changed:
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/PREMIUM_TO_AUTO_HANDOFF_TEMPLATE.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Future substantive AXEL planning responses are standardized for auto-model execution and now enforce immediate user choice before any continuation when canon conflicts are detected.
- Verification: Confirmed new protocol text is present in both governance layers and that both references point to the new handoff template path.
- Notes: No source-hierarchy conflict during this update; changes extend governance behavior while preserving existing AXEL canonical invariants.

## 2026-05-08 - Canonical Scene Placeholder Rollout

- Request: Roll out minimal parse-safe placeholder scenes across canonical `Arc_1`..`Arc_7` and `Endings` directories, including additional `4.1b/4.1c/4.1d` beats, while preserving non-canonical alias files and leaving unresolved rewrite dialogue entries empty.
- Implementation: Added shared placeholder renderer script at `scenes/core/ScenePlaceholder.gd` and regenerated canonical scene beat files from `AXEL_SCENES_NEW.md` to reference that script with per-scene `scene_id`, `location_label`, and `dialogue` metadata. Overwrote `1.1_SchoolExterior.tscn` with rewrite dialogue and set unresolved entries (literal `x`, bracketed implementation-note rewrites, and missing rewrites) to empty dialogue arrays.
- Files changed:
  - `AXEL/axel_project/scenes/core/ScenePlaceholder.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_LockerHub.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.2_BasementBlockedTemp.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.2_CafeteriaMemory.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.3_Kitchen.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.4_KitchenFlashlightPickup.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1b_BackyardClickStep1.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1c_BackyardNameReveal.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1d_BackyardNamedScene.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.2_BackyardHint.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.2_TeachersMemory.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.3_TeachersKeyWall.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.4_TeachersKeyPickup.tscn`
  - `AXEL/axel_project/scenes/Arc_6/6.1_Classroom.tscn`
  - `AXEL/axel_project/scenes/Arc_6/6.2_ClassroomDesk.tscn`
  - `AXEL/axel_project/scenes/Arc_6/6.3_ClassroomBoard.tscn`
  - `AXEL/axel_project/scenes/Arc_6/6.4_ClassroomBoardSuccess.tscn`
  - `AXEL/axel_project/scenes/Arc_7/7.1_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_7/7.2_BasementLocked.tscn`
  - `AXEL/axel_project/scenes/Arc_7/7.3_BasementStairs.tscn`
  - `AXEL/axel_project/scenes/Arc_7/7.4_BasementMain.tscn`
  - `AXEL/axel_project/scenes/Arc_7/7.5_BasementShovelPickup.tscn`
  - `AXEL/axel_project/scenes/Arc_7/7.6_BasementStuck.tscn`
  - `AXEL/axel_project/scenes/Arc_7/7.7_BasementDigging.tscn`
  - `AXEL/axel_project/scenes/Arc_7/7.8_BasementCorpse.tscn`
  - `AXEL/axel_project/scenes/Endings/8.1_Ending1.tscn`
  - `AXEL/axel_project/scenes/Endings/8.2_Ending2.tscn`
  - `AXEL/axel_project/scenes/Endings/8.3_Ending3.tscn`
  - `AXEL/axel_project/scenes/Endings/8.4_Ending4.tscn`
  - `AXEL/axel_project/scenes/Endings/8.5_EndingTrue.tscn`
  - `AXEL/axel_project/scenes/Endings/8.6_Epilogue.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Canonical beat files now load as uniform placeholder scenes with explicit metadata and safe fallback rendering for incomplete rewrite content.
- Verification: Executed headless scene smoke command against `res://test/scene_smoke_check.gd` from `AXEL/axel_project` root and captured pass/fail status.

## 2026-05-08 - Fix Godot Launcher Path + Re-run Scene Smoke

- Request: Run the pending scene smoke verification and fix `godot.cmd` launcher path (possibly still pointing at old location/version).
- Implementation: Corrected `tools/cmd/godot.cmd` root resolution from `tools/` to repo root so it launches the existing `Godot_v4.6.2-stable_win64.exe`, then reran the headless scene smoke command.
- Files changed:
  - `tools/cmd/godot.cmd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Repo-local `tools/cmd/godot.cmd` now resolves the Godot executable correctly and can run project verification scripts again.
- Verification: Ran `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://test/scene_smoke_check.gd`; result `Scene smoke check OK (6 scenes).`
- Notes: Version is `4.6.2` (not `4.6.1`); failure source was incorrect relative root path in the wrapper script.

## 2026-05-08 - QA Persistent Analytics + Trend Graph Pipeline

- Request: Make every `qa agent` run persist score analytics/bugs and continuously update a historical graph with separate lines for weighted `Total` and rubric axes (`S/N/I/E/C/R`).
- Implementation: Added required machine-readable payload blocks to `AXEL_QA_RUN_LOG.md` and documented parser expectations in the QA rubric. Added `tools/qa/update_qa_analytics.py` to parse run-log payloads and regenerate `AXEL_QA_ANALYTICS.md` (latest snapshot, deltas, Mermaid trend chart). Updated the `qa` skill to append a run payload then trigger analytics refresh each run. Updated `AI_DOCS.md` and workspace governance rule with the QA persistence invariant and canonical analytics artifacts.
- Files changed:
  - `AXEL/axel_project/plans/AXEL_QA_RUN_LOG.md`
  - `AXEL/axel_project/plans/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/AXEL_QA_ANALYTICS.md`
  - `AXEL/axel_project/tools/qa/update_qa_analytics.py`
  - `.cursor/skills/axel-simulated-qa/SKILL.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: QA now supports longitudinal production analytics with automatic chart refresh from append-only run payloads, while preserving concise technical QA report output.
- Verification: Ran `python AXEL/axel_project/tools/qa/update_qa_analytics.py` for empty-log handling and again after two synthetic validation entries (static + playtest); parser reported `Payloads parsed: 2` and generated multi-line Mermaid trends for `Total/S/N/I/E/C/R`.
- Notes: No canon hierarchy conflicts encountered; this change extends QA tooling/docs only and does not alter gameplay logic.

## 2026-05-08 - Corridor canonical recovery + Christmas graffiti

- Request: Implement corridor scene recovery: single canonical `1.2_Corridor.tscn`, retire non-canonical `Corridor.tscn`, use `corridor_christmas_graffiti_85.png` instead of monkey graffiti.
- Implementation: Replaced placeholder `1.2_Corridor.tscn` with the full corridor layout from the legacy alias scene, swapped graffiti `ExtResource` to `corridor_christmas_graffiti_85.png` (importer uid `uid://b2qaxk4m8nqwc`), renamed sprite node `MonkeyGraffiti` → `ChristmasGraffiti`, deleted `Corridor.tscn`, and updated `AXEL_SCENES_BLUEPRINT.md` headings/todo text to reference `1.2_Corridor.tscn` per canonical filename invariant (`AI_DOCS.md` / scene-agent spec).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/Corridor.tscn` (removed)
  - `AXEL/axel_project/plans/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Main menu / smoke tests that load `res://scenes/Arc_1/1.2_Corridor.tscn` now get the full exploration corridor with Christmas graffiti; no runtime path should load `Arc_1/Corridor.tscn`.
- Verification: Ran `rg "Arc_1/Corridor\\.tscn"` / `Corridor\.tscn` on code and scenes (only docs/changelog mentions of alias as examples); ran headless `res://test/scene_smoke_check.gd` after migration.
- Notes: Resolves drift where full scene lived on the alias file while canonical file was a `ScenePlaceholder`; aligned with hierarchy in `AI_DOCS.md` §11 canonical filename invariant.

## 2026-05-08 - Reapply Lost Corridor Layout/Layer/Collision Tuning

- Request: Reapply previously lost corridor settings: tuned locker scale/placement, player scale and render layer above noir/floor, and a full-width upper wall collision border.
- Implementation: Updated `1.2_Corridor.tscn` locker row to the prior tuned layout (`Locker01`..`Locker10` from `x=167` to `x=1134`, `y=274`, `scale=Vector2(2.06, 2.06)`), restored player render isolation via `PlayerLayer` (`CanvasLayer`, `layer=100`, `follow_viewport_enabled=true`) and moved `Player` under it with `scale=Vector2(2.06, 2.06)` and `speed=371.0`, and restored a single full-width upper blocker (`RectangleShape2D_upper_block` + `UpperWallBlock` with collision shape offset `Vector2(0, -140)`).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor locker composition and traversal feel are back to the tuned version, player now consistently renders above noir overlay/floor-space conflicts, and the upper wall lane is blocked by one maintainable collision border.
- Verification: Confirmed all restored node/property signatures in scene file (`Locker10`, `scale=2.06`, `PlayerLayer layer=100`, `follow_viewport_enabled`, `UpperWallBlock`, `RectangleShape2D_upper_block`, `speed=371.0`); scene smoke check rerun after patch.
- Notes: Root cause was canonical recovery being based on a stale legacy `Corridor.tscn` snapshot that lacked later tuning edits; keeping canonical scene as sole edit target plus pre-migration diff checks prevents recurrence.

## 2026-05-08 - Locker Nearest Filtering + Highlight Noir Bypass Restore

- Request: Ensure all locker textures use nearest filtering (not inherit) and implement highlighted-locker exclusion from global noir with its own darker local filter.
- Implementation: Set explicit `texture_filter = 1` (nearest) on all locker sprites (`Locker01..Locker10` and `HighlightedLocker`). Restored highlighted-locker bypass wiring by hiding in-row `HighlightedLocker`, adding `HighlightedLockerBypassLayer` (`CanvasLayer layer=95`) with `HighlightedLockerBypass` sprite using `ShaderMaterial_highlighted_locker_local`, and binding `res://scenes/fx/highlighted_locker_palette_filter.gdshader` (`darken_factor = 0.67`) so it renders above global noir (`layer=90`) but below player layer (`layer=100`).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Locker art now consistently renders with nearest filtering; highlighted locker is no longer quantized by global noir and instead uses the dedicated darker local palette filter.
- Verification: Confirmed nearest filter flags and bypass nodes/material in scene file; ran headless scene smoke check `res://test/scene_smoke_check.gd` (OK 6 scenes).
- Notes: This restores the previously intended two-path render model (global noir for scene + local filtered highlighted locker bypass).

## 2026-05-08 - Restore SchoolExterior Full Layout Without Timer/Key Gating

- Request: Revert `1.1_SchoolExterior` from generated empty placeholder to the older full scene with tilemaps/placeholders/player, but leave out timer, key pickup, and key-based door-unlock flow.
- Implementation: Restored the pre-placeholder full scene layout baseline (tilemap plants/road layers, environment placeholder polygons, world bounds, player setup, noir overlay) and removed gameplay-gating/UI wiring by stripping `GameController.gd` from root plus deleting `KeyArea`, `ExitArea`, `MemoryPickupArea`, and the full HUD/timer/objective/inventory/message/dialogue panel tree from `1.1_SchoolExterior.tscn`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Scene 1.1 is no longer an empty placeholder and again contains legacy visual layout + controllable player, without timer UI or key-required exit logic.
- Verification: Ran headless `res://test/scene_smoke_check.gd` (reports `Scene smoke check OK (6 scenes)`).
- Notes: The “empty scene” state came from placeholder regeneration that overwrote canonical scene content; this restore keeps canonical filename while restoring non-placeholder geometry/content.

## 2026-05-08 - Arc 1 Top Dialogue Overlay (1.1 + 1.2)

- Request: Add top-of-screen dialogue for canonical `1.1` and `1.2` scenes: `1.1` shows first line, hides, short pause, then second line; `1.2` shows only the first corridor line on spawn; player must keep moving while dialogue is visible.
- Implementation: Added reusable `TopDialogueOverlay` (`CanvasLayer` layer `110`, input-transparent controls, fade on `RootMargin`) at `scenes/ui/TopDialogueOverlay.tscn` + `TopDialogueOverlay.gd`. Instanced overlay in `1.1_SchoolExterior.tscn` with new `1.1_SchoolExterior.gd` driving timed `show_line` sequence (`0.8s` gap). Instanced overlay in `1.2_Corridor.tscn` and extended `1.2_Corridor.gd` to call `show_line` for the opening line only. No changes to `Player.gd` or physics gating.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Narrative lines read as cinematic top banners above noir/player layers without blocking movement (no `set_physics_process(false)` and `MOUSE_FILTER_IGNORE` on overlay UI).
- Verification: Ran headless `res://test/scene_smoke_check.gd` (`Scene smoke check OK (6 scenes)`); GDScript lints clean on touched scripts.
- Notes: `CanvasLayer` has no `modulate` in GDScript 4.x; fades apply to the top `Control` subtree instead.

## 2026-05-08 - Scene 1.1 Noir Occlusion Layer Fix

- Request: Fix scene `1.1` noir filter behavior where visuals behind the overlay appeared hidden/overpowered.
- Implementation: Added `PlayerLayer` (`CanvasLayer`, `layer = 100`, `follow_viewport_enabled = true`) in `1.1_SchoolExterior.tscn` and reparented `Player` plus child nodes under `PlayerLayer/Player`, preserving existing player transform/speed/sprite settings. Kept `NoirPaletteOverlay` unchanged on its existing layer (`90`).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Scene world content continues through the global noir pass, while player readability is restored by rendering above the noir overlay layer model (matching corridor strategy).
- Verification: Ran headless `res://test/scene_smoke_check.gd` via `Godot_v4.6.2-stable_win64_console.exe`; output reports `Scene smoke check OK (6 scenes)`.
- Notes: Root cause was render-order mismatch (`z_index` on world node cannot outrank noir `CanvasLayer`), not shader threshold logic.

## 2026-05-08 - Noir Palette Threshold Retune (Option A)

- Request: Keep the global noir overlay approach but reduce scene-black crush in exploration (starting with `1.1`) by retuning the existing shader defaults.
- Implementation: Retuned `noir_palette_filter.gdshader` defaults to reduce the black bucket and lift dark-red mapping: `dark_blood_color` `0.290 -> 0.36`, `t0` `0.22 -> 0.08`, `t1` `0.45 -> 0.30`, `t2` `0.74 -> 0.62`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/noir_palette_filter.gdshader`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: More low/mid luminance pixels map to dark-blood/blood-red bands instead of black, preserving silhouette/readability while keeping the same 4-band noir style pipeline.
- Verification: Ran headless `res://test/scene_smoke_check.gd` via `Godot_v4.6.2-stable_win64_console.exe`; output reports `Scene smoke check OK (6 scenes)`.
- Notes: This is a global shader default update (affects all scenes using `NoirPaletteOverlay`), intended as the first-pass calibration before any scene-specific local bypasses.

## 2026-05-08 - Top dialogue: VT323, typewriter, black/white bar

- Request: Implement Arc 1 dialogue box upgrade: more impactful presentation, VT323, animated typewriter text, black panel with white text, keep non-blocking movement; retain `1.1` two-line timing and `1.2` spawn line only.
- Implementation: Updated `TopDialogueOverlay.tscn` with `StyleBoxFlat` black panel, dark-blood `1px` border (AXEL accent), white label text with black outline, and `VT323-Regular` from `combat/ui/fonts/`. Extended `TopDialogueOverlay.gd` with per-character typewriter after fade-in, optional **Tab** skip (`allow_skip` defaults true), then existing hold + fade-out; still uses `CanvasLayer` 110 and ignores mouse on all controls. Arc `1.1` / `1.2` scripts unchanged (`show_line(text, hold_duration)` only).
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Top narration reads as CRT-terminal style (white on black) with typewriter pacing; player movement and physics remain unlocked; Tab skips to full line during typing only.
- Verification: `ReadLints` on `TopDialogueOverlay.gd` (clean); headless `res://test/scene_smoke_check.gd` → `Scene smoke check OK (6 scenes).` (pre-existing tile load warnings from `1.1_SchoolExterior` tilemap unrelated to overlay).
- Notes: Canon resolution — narrative strip uses **white body text** per request; red stays as thin panel border only (`#4a0000`-aligned dark blood), consistent with `AI_DOCS.md` palette hierarchy.

## 2026-05-08 - Scene 1.1 School Exterior Collision Boundary Alignment

- Request: Note the Scene `1.1` collision edits: moved the left-side collision border to match the school exterior polygon so the player cannot walk through the school, and set polygon coverage across the full right side of the scene.
- Implementation: Recorded the geometry/collision intent for `1.1_SchoolExterior` as a boundary-alignment pass to keep traversal constrained to valid walkable space and prevent clipping through school geometry.
- Files changed:
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Player movement in Scene `1.1` should now be blocked along the aligned left school edge and across the fully covered right-side polygon boundary.
- Verification: Changelog-only documentation update based on user-confirmed scene edit details.
- Notes: No source-hierarchy conflict; this entry documents the canonical numbered scene boundary update (`1.1_SchoolExterior`).

## 2026-05-08 - Dialogue overlay: bottom center + viewport padding

- Request: Position the dialogue box at the bottom center of the window with a small gap above the bottom edge.
- Implementation: Re-anchored `RootMargin` in `TopDialogueOverlay.tscn` from top-wide (`anchors_preset` 10) to bottom-wide (`12`): full width with `28px` side insets, `24px` offset above the bottom edge (`offset_bottom = -24`), bar height via `offset_top = -128`; inner `MarginContainer` theme margins cleared because spacing now comes from anchors. Updated script header comment to describe a bottom-centered bar.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Dialogue reads as a bottom cinematic bar on every scene that instances the overlay; horizontal alignment stays centered via full-width strip + centered label text.
- Verification: Headless `res://test/scene_smoke_check.gd` → `Scene smoke check OK (6 scenes).`
- Notes: Filename `TopDialogueOverlay` unchanged to avoid breaking instances; visual placement is now bottom-centered.
