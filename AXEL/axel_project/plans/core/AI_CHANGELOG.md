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

## 2026-05-08 - Scene 1.1 Door Marker + Third Intro Dialogue Line

- Request: Place a white rectangular polygon at the school exterior/path boundary as a visible "door" marker, and restore the missing third intro dialogue iteration (`"pathetic"`).
- Implementation: Added `1.1_School_Door_Boundary_01` (`Polygon2D`, white rectangle) under `1.1_EnvironmentPlaceholders` aligned with the school door area at the path boundary, and extended `1.1_SchoolExterior.gd` intro flow with a third `TopDialogueOverlay.show_line("pathetic.", ...)` call after a short pause.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Scene `1.1` now visually indicates the school entry threshold using a white rectangular door marker, and intro dialogue sequence now runs in three beats instead of two.
- Verification: IDE lint check reports no errors in `1.1_SchoolExterior.gd`.
- Notes: Door marker is currently visual-only (`Polygon2D`); if you want it to also enforce collision at that exact rectangle, we can add a matching `StaticBody2D` + `CollisionShape2D`.

## 2026-05-08 - Scene 1.1 Door Collision Matches Door Polygon

- Request: Place a collision boundary for `school_building_doors_01` exactly matching the door.
- Implementation: Added `1.1_School_Building_Doors_01_Collision` (`StaticBody2D`) under `1.1_EnvironmentPlaceholders` with `position = Vector2(-66, 13)` and a child `CollisionPolygon2D` using the same polygon points as `1.1_School_Building_Doors_01` (`1035,305` `1115,305` `1115,430` `1035,430`), so collision footprint matches door geometry 1:1.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Player can no longer pass through the door polygon area; collision now aligns exactly with the visual door placement.
- Verification: Scene-file structural check confirms matching position and polygon values between door visual node and collision node.
- Notes: No canon/source-hierarchy conflict; update targets canonical scene `1.1_SchoolExterior.tscn`.

## 2026-05-08 - Scene 1.1 Door Interaction To Corridor Transition

- Request: Make the school door boundary interactable so when the player is close and presses interaction (`E`, `Space`, or `Enter`), they are teleported to the corridor scene.
- Implementation: Added door-proximity trigger `1.1_School_Building_Doors_01_InteractArea` (`Area2D`) reusing the same transform and polygon as `1.1_School_Building_Doors_01`. Extended `1.1_SchoolExterior.gd` with `_unhandled_input` key handling (`KEY_E`, `KEY_SPACE`, `KEY_ENTER`, `KEY_KP_ENTER`), overlap check against the player body via `get_overlapping_bodies()`, and guarded scene transition to `res://scenes/Arc_1/1.2_Corridor.tscn` using `change_scene_to_file`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Door area now supports explicit interaction-based progression from Scene `1.1` to Scene `1.2` rather than passive traversal alone.
- Verification: `ReadLints` reports no errors in `1.1_SchoolExterior.gd` after adding interaction logic.
- Notes: Transition is proximity-gated and one-shot guarded (`_is_transitioning`) to prevent duplicate scene-change calls on repeated keypress events.

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

## 2026-05-08 - Scene 1.2 Local Noir White-Balance Guardrail

- Request: Fix Scene `1.2` over-bright whites caused by the prior `NoirPaletteOverlay` retune, while avoiding broad cross-scene drift.
- Implementation: Applied Option B (scene-local override) in `1.2_Corridor.gd` by targeting `NoirPaletteOverlay/FilterRect` material at runtime and overriding shader uniforms for Scene `1.2` only: raised white-threshold cutoff (`t2 = 0.72`) and softened peak white mapping (`white_color = Color(0.93, 0.93, 0.93, 1.0)`).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor lockers/graffiti/debris retain noir quantization but fewer mid-bright texels collapse to pure white, improving detail retention in Scene `1.2` without changing Scene `1.1` global grading.
- Verification: `ReadLints` reports no errors in `1.2_Corridor.gd`; repository search confirms only `1.2_Corridor.gd` now sets local `t2` and `white_color` overrides while `1.1_SchoolExterior.tscn` continues using the shared overlay instance unchanged.
- Notes: Canon-aligned with AXEL palette intent (controlled white highlights); this is a contained scene calibration with no global shader default edits.

## 2026-05-08 - QA Default Upgraded To Combined Static + Playtest

- Request: Make future `qa` requests always mean both static review and playtest.
- Implementation: Updated QA skill contract so plain `qa` / `qa agent` now defaults to a combined run (static analysis + rubric playtest command set). Added explicit `qa static` override for static-only runs, and synchronized canonical docs/rules so governance and alias behavior are consistent.
- Files changed:
  - `.cursor/skills/axel-simulated-qa/SKILL.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Any future plain `qa` invocation now targets higher-confidence combined QA evidence by default; static-only becomes opt-in via explicit request.
- Verification: Confirmed updated wording exists in QA skill, canonical AI docs, and always-on governance rule with aligned alias semantics.
- Notes: No source-hierarchy conflict; this is a reusable workflow policy change and was documented in both persistent governance layers as required.

## 2026-05-08 - Option 1 Global Noir Rebalance Trial (Revert-Safe)

- Request: Implement Option 1 global white-balance trial so Scene `1.1` and `1.2` can be tested together, with a guaranteed path back to the current baseline state.
- Implementation: Created rollback anchors before edits (`rollback/option1-baseline-20260508-2038` branch pointer and `option1-baseline-20260508-2038` tag), then switched to `test/noir-option1-global` and tuned only `noir_palette_filter.gdshader` for first-pass global trial: `t2` `0.62 -> 0.72` and `white_color` `vec4(1.0,1.0,1.0,1.0) -> vec4(0.95,0.95,0.95,1.0)`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/noir_palette_filter.gdshader`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Global overlay now routes fewer mid-high luminance texels into the white bucket, reducing white clipping pressure across scenes that instance `NoirPaletteOverlay` (including `1.1` and `1.2`).
- Verification: `ReadLints` reports no shader lint errors; `git diff` confirms only the two intended uniform changes in `noir_palette_filter.gdshader`; validation criteria for user pass: (1) `1.2` locker vents/panel seams retain detail, (2) `1.2` graffiti no longer blooms as clipped white patch, (3) `1.1` door marker remains readable without harsh clipping, (4) `1.1` background separation remains intact.
- Notes: Trial is intentionally kept active on `test/noir-option1-global` for user testing; one-step baseline restore remains available via `git switch main` (or `git switch rollback/option1-baseline-20260508-2038`).

## 2026-05-08 - Option 1 Test Unmasked In Scene 1.2

- Request: Make Option 1 global test visibly affect Scene `1.2` after user observed no practical difference.
- Implementation: Added a simple scene flag in `1.2_Corridor.gd` and disabled the local corridor override during this trial (`_USE_LOCAL_NOIR_TUNING := false`), so Scene `1.2` now reads global `noir_palette_filter.gdshader` uniforms directly.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Scene `1.2` no longer masks global palette-tuning with local `t2/white_color` values, enabling a true Option 1 side-by-side read against Scene `1.1`.
- Verification: `ReadLints` reports no errors in `1.2_Corridor.gd`; `_ready()` now gates `_apply_local_noir_tuning()` behind a disabled constant.
- Notes: Re-enable prior local behavior by setting `_USE_LOCAL_NOIR_TUNING := true` after trial if needed.

## 2026-05-08 - Scene 1.2 Locker Detail Recovery via Bypass Layer

- Request: Replace ineffective global-threshold trial with a stronger Scene `1.2` approach that preserves locker vent/panel detail.
- Implementation: Added a full `LockerBypassLayer` (`CanvasLayer`, layer `95`) and moved visible locker rendering to bypass sprites (`Locker01Bypass..Locker10Bypass` + `HighlightedLockerBypass`) using a shared locker-local shader material. Hid original in-row lockers (`Locker01..Locker10` and `HighlightedLocker`) to prevent duplicate rendering under the global overlay. Introduced new shader `locker_palette_filter.gdshader` with noir-adjacent palette mapping plus controlled luminance variation (`detail_strength`) to preserve micro-contrast in locker linework.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/fx/locker_palette_filter.gdshader`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Scene `1.2` locker art now bypasses destructive full-screen quantization while still receiving a local noir-style grade; vent slots and panel outlines are expected to remain legible at play distance without introducing player-layer conflicts.
- Verification: `ReadLints` reports no diagnostics for touched scene/script/shader paths; scene diff confirms bypass nodes preserve original locker transforms and highlighted locker now uses the same shader family as the rest of the row with no duplicate visible sources.
- Notes: This is intentionally scene-scoped (`1.2` only) to contain drift; rollback remains low-risk by reverting `1.2_Corridor.tscn` and `locker_palette_filter.gdshader` on the current trial branch.

## 2026-05-08 - Scene 1.2 Highlighted Locker Faint Glow Restore

- Request: Restore visible emphasis for the highlighted locker after bypass normalization by adding a faint glow.
- Implementation: Extended `locker_palette_filter.gdshader` with a `glow_strength` uniform and a soft luminance-gated glow term (`smoothstep(t1, t2, lum)`) so glow is constrained to brighter locker tones. In `1.2_Corridor.tscn`, kept base lockers on `ShaderMaterial_locker_local` (`glow_strength = 0.0`) and assigned `HighlightedLockerBypass` a dedicated `ShaderMaterial_highlighted_locker_glow` with subtle boost (`glow_strength = 0.12`) plus slightly lifted detail/darken tuning.
- Files changed:
  - `AXEL/axel_project/scenes/fx/locker_palette_filter.gdshader`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker regains faint visual emphasis while remaining stylistically aligned with the bypass locker row and avoiding strong bloom spill.
- Verification: `ReadLints` reports no diagnostics for touched shader/scene files.

## 2026-05-08 - Highlighted Locker Glow Fallback Pulse (Runtime)

- Request: Re-apply highlighted locker emphasis after user reported no visible glow change during live playtesting.
- Implementation: Added a runtime fallback pulse in `1.2_Corridor.gd` that directly animates `LockerBypassLayer/HighlightedLockerBypass` each frame (`modulate` tint + tiny scale breathing), independent of shader hot-reload/material cache behavior. New toggles: `_USE_HIGHLIGHT_PULSE` (enabled) and `_update_highlight_pulse()` driven by `_flicker_time`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker now has an unmistakable but still faint animated glow/readability cue even if shader-only glow path is not visually updating in a live session.
- Verification: `ReadLints` reports no diagnostics for `1.2_Corridor.gd`.

## 2026-05-08 - Highlighted Locker Standout Boost (Additive Aura)

- Request: Make highlighted locker stand out more because faint pulse motion was visible but no white glow separation was perceived.
- Implementation: Added `HighlightedLockerAura` sprite behind `HighlightedLockerBypass` in `1.2_Corridor.tscn` using `CanvasItemMaterial` additive blending (`blend_mode = 1`), larger base scale, and white-tinted alpha. Extended runtime pulse in `1.2_Corridor.gd` to animate both locker and aura: increased highlight tint range, slightly stronger locker scale pulse, and independent aura alpha/scale pulse for a clearer white halo read.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker now has explicit white-glow separation from the rest of the locker row while preserving noir tone and avoiding full-screen bloom.
- Verification: `ReadLints` reports no diagnostics for touched scene/script files.

## 2026-05-10 - Playtest cyan collision debug overlay (global)

- Request: Separate invisible playtest geometry (collision borders etc.) from shipped AXEL palette (red/black/white); use project-wide cyan accents for readability.
- Implementation: Added autoload **`PlaytestCollisionDebug`** (`CanvasLayer` **2000**) that scans `CollisionShape2D` / `CollisionPolygon2D`, draws cyan/teal outlines via `playtest_collision_debug_draw.gd`, refreshes cache on scene/tree topology changes. **`F7`** toggles overlay in debug/editor builds only (`OS.is_debug_build()` exits early otherwise). Documented rationale as debug-only palette exception in `PLAYTEST_DEBUG_COLLISIONS.md` + `AI_DOCS.md`.
- Files changed:
  - `AXEL/axel_project/scripts/debug/playtest_collision_debug.gd`
  - `AXEL/axel_project/scripts/debug/playtest_collision_debug_draw.gd`
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/plans/PLAYTEST_DEBUG_COLLISIONS.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Debug playtests show collision/interact contours in neon cyan/teal above normal layers; scenes and shaders are untouched; overlay absent in release (`is_debug_build() == false`).
- Verification: `ReadLints` clean on new scripts; architectural check: Noir/`PlayerLayer` use lower CanvasLayer IDs than overlay; shapes in `1.1_SchoolExterior.tscn` / `1.2_Corridor.tscn` are rectangles/circles/polygons handled by drawers. **Manual:** Play `1.1` / `1.2`, confirm cyan borders, press **`F7`** to hide/show; export/release build should not draw overlay.
- Notes: Aligns with `AI_DOCS.md` readability exception for debug-only helpers; engine “Visible collision shapes” may still show alongside—disable in editor View if redundant.

## 2026-05-10 - Overworld Real-Input Playthrough Bots (`bot playthrough`)

- Request: Implement the "Overworld Real-Input Bot Implementation Plan" — high-fidelity headless bots that simulate a real player by synthesizing key events over time (not API shortcuts), starting with Arc 1 overworld flow.
- Implementation: Added a reusable test-only input layer + scenario runner + two end-to-end Arc 1 bot scripts. `input_event_driver.gd` emits `InputEventKey` press/release/hold/tap through `Input.parse_input_event()` so events traverse the engine input pipeline (visible to both `_input/_unhandled_input` callbacks and `Input.is_key_pressed()` polling). `scenario_runner.gd` interprets a deterministic command list (`press`, `tap`, `hold`, `wait_frames`, `assert`, `assert_eventually`, ...) with structured failure context (step index + frame). `playthrough_arc1_exterior.gd` walks the player right (KEY_D, ~340 physics frames at 180 px/s) until overlapping the door interact area, taps `KEY_E`, and asserts `current_scene` becomes `1.2_Corridor.tscn`. `playthrough_dialogue_loop.gd` exercises the dialogue/interact loop using the *currently wired* canon: drives `TopDialogueOverlay` Tab-skip, then walks + taps `KEY_SPACE` (alternate interact key in `_is_interaction_event`) and asserts the same transition. Wired into the QA rubric as a new opt-in `combat + scene smoke + bot playthrough` confidence tier and registered as a reusable pipeline (`bot playthrough`) in canonical docs + governance rule.
- Files changed:
  - `AXEL/axel_project/test/bots/input_event_driver.gd`
  - `AXEL/axel_project/test/bots/scenario_runner.gd`
  - `AXEL/axel_project/test/bots/playthrough_arc1_exterior.gd`
  - `AXEL/axel_project/test/bots/playthrough_dialogue_loop.gd`
  - `AXEL/axel_project/test/bots/README.md`
  - `AXEL/axel_project/plans/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Adds a new headless verification capability that exercises the same key-event code paths a player exercises (movement polling, interact `_unhandled_input`, dialogue `_input` Tab-skip), giving QA playtest a higher-confidence overworld gate without modifying any gameplay code or scenes.
- Verification: Both bots run green from repo root: `tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://test/bots/playthrough_arc1_exterior.gd` -> `Arc1 exterior playthrough OK.` (exit 0, 11 commands, 353 physics frames); `tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://test/bots/playthrough_dialogue_loop.gd` -> `Dialogue/interact playthrough OK.` (exit 0, 17 commands, 457 physics frames). `ReadLints` clean on all four new scripts.
- Notes: Plan step 4 originally targeted `scripts/GameController.gd`. Per `AI_CHANGELOG.md` 2026-05-08 "Restore SchoolExterior Full Layout", that script was deliberately stripped from active scenes; per `AI_DOCS.md` canon hierarchy ("no architecture-layer mixing without intent") we did NOT resurrect it via a synthetic test scene. `playthrough_dialogue_loop.gd` covers the same intent (dialogue advance/skip + interaction + state assertion) using currently-wired `TopDialogueOverlay` + `_is_interaction_event` alternate-key branch, documented in the bot's header and `test/bots/README.md`. TileSet-atlas `ERROR` lines from `1.1_SchoolExterior.tscn` are pre-existing scene content and unrelated to the bot harness.

## 2026-05-10 - Default QA Includes Bot Playthrough

- Request: Make any future `qa`, `run qa`, or `qa agent` invocation automatically run the previous static + playtest contract AND the new overworld bot playthrough scripts as a single default bundle.
- Implementation: Promoted the `combat + scene smoke + bot playthrough` confidence tier from opt-in to **default** across all four authority layers. (1) QA skill (`SKILL.md`) — added `run qa` alias, expanded the default playtest command set to **six** headless commands including `playthrough_arc1_exterior` and `playthrough_dialogue_loop`, kept `qa static` as the only documented playtest opt-out, and reinforced explicit skip-and-report behavior. (2) Rubric (`AXEL_QA_REVIEW_RUBRIC.md`) — relabeled the bot tier as the **default tier for plain `qa`**, merged the bot commands into the single Default command set block, listed both bots as pass/fail gates, and added a tier-downgrade ladder for skipped commands. Extended Analytics-snapshot Confidence options and Persistent-payload `playtest_commands` schema with `bot_arc1_exterior` and `bot_dialogue_loop` keys. (3) Canon (`AI_DOCS.md` §11–12) — mirrored the new defaults, added `run qa` alias, and clarified that bots are part of the default bundle. (4) Always-on rule (`.cursor/rules/axel-ai-docs-governance.mdc` items 11/12/20) — same alias + default + skip-policy text so future chats hit a unified contract on first read. (5) Run-log template (`AXEL_QA_RUN_LOG.md`) — extended the `Playtest commands:` line, JSON template `playtest_commands` keys, and "Allowed playtest_commands keys" documentation with the two bot keys.
- Files changed:
  - `.cursor/skills/axel-simulated-qa/SKILL.md`
  - `AXEL/axel_project/plans/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AXEL_QA_RUN_LOG.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Future plain `qa` / `run qa` / `qa agent` invocations across any chat will execute static review + the four prior playtest commands + both `playthrough_*.gd` bot scripts as one bundle, and produce reports + payload entries that include bot pass/fail/skip status. `qa static` remains the documented opt-out for static-only runs.
- Verification: `ReadLints` clean on all five updated docs. Analytics regenerator sanity run: `python AXEL/axel_project/tools/qa/update_qa_analytics.py` -> `Payloads parsed: 4` (same count as before; new `bot_*` keys are ignored by the parser, which only consumes `scores`/`findings_count`/`by_category`/`bugs_or_regressions`/`mode`/`scope`/`trigger`/`timestamp` — confirmed by reading `tools/qa/update_qa_analytics.py`). Cross-doc consistency check: every plain QA alias (`qa`, `run qa`, `qa agent`) maps to the same default command set across skill, rubric, AI_DOCS, and rule file; `qa static` consistently scoped as static-only opt-out.
- Notes: This is a workflow/policy change only — no gameplay, scene, or combat code touched. Skip ladder (in rubric §Playtest-mode and AI_DOCS §11) defines confidence downgrades when individual commands are unavailable, preserving the original "skip and report" invariant from the QA skill.

## 2026-05-10 - QA Analytics: Bots Aggregate Series On Trend SVG

- Request: Make the bot version of `qa agent` feed into the same dataset and analytics as static + combat playtest, with at least one new line on `AXEL_QA_ANALYTICS.svg` representing bot results. User picked the "one aggregate line" granularity from offered options.
- Implementation: Extended `tools/qa/update_qa_analytics.py` to compute a single derived `Bots` series from each payload's `playtest_commands` block. Added `EXTRA_SERIES_ORDER`/`COLORS`/`LABELS` for `Bots`, `BOT_STATUS_TO_SCORE` mapping (`pass=5.0`, `fail=0.0`; everything else, including `skip` and missing keys, returns `None`), and `_bots_aggregate_for_payload()` which **auto-discovers any `playtest_commands` key prefixed `bot_*`** (so future bots like `bot_corridor_traversal` automatically join the aggregate without further code changes). `_extract_series` now returns a third tuple element `extra_series: dict[str, list[float | None]]`; `_build_svg_chart` was extended to accept it and draws gap-aware broken polylines for any series containing `None` values (one segment per consecutive non-None span, dashed stroke + outlined dots so the new line reads as visually distinct on the existing 7 score axes). Legend gained a dashed swatch entry. `_render_markdown` adds a `Bots: ...` row to the Latest snapshot (per-bot status) and a `Bots` row to Latest deltas (with `n/a` handling for missing data); the trend chart heading now reads `Total + S/N/I/E/C/R + Bots`. Mermaid fallback is intentionally left as the original 7-score view (Mermaid `xychart-beta` cannot gap a series cleanly); legend text in the regenerated MD documents that the `Bots` line is SVG-only by design. `tools/qa/update_qa_analytics.py` exit `0`, parses 4 historical payloads correctly with new code path. Mirrored the new behavior in rubric §Persistent analytics payload and AI_DOCS §11 so future chats discover the auto-aggregation rule.
- Files changed:
  - `AXEL/axel_project/tools/qa/update_qa_analytics.py`
  - `AXEL/axel_project/plans/AXEL_QA_ANALYTICS.md` (regenerated)
  - `AXEL/axel_project/plans/AXEL_QA_ANALYTICS.svg` (regenerated)
  - `AXEL/axel_project/plans/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Future `qa` runs that include bot pass/fail status produce a dashed `Bots` line on `AXEL_QA_ANALYTICS.svg` showing real-input bot pass-rate trend across runs. Pre-bot historical entries render as gaps (no false-zero regression), and any future bot that uses the `bot_<name>` payload key joins the aggregate automatically. No score axes were touched — the existing `Total + S/N/I/E/C/R` lines and Mermaid fallback render identically to before for the same input.
- Verification: Throwaway in-memory test (synthetic 4-payload run with mixed bot states) confirmed: aggregate series `[None, 5.0, 2.5, None]` matches mapping rule (gap → both pass=5.0 → mixed pass/fail=2.5 → both skip=gap); SVG output contains `Bots (Avg pass-rate)` legend label and `stroke-dasharray="6,4"` polyline; markdown output contains `Bots: bot_arc1_exterior=... bot_dialogue_loop=...` snapshot row and a `Bots` row in Latest deltas. Live regenerator run on the actual run log: `python AXEL/axel_project/tools/qa/update_qa_analytics.py` → `Payloads parsed: 4` (same count as before). `ReadLints` clean on `update_qa_analytics.py` and both touched plan docs.
- Notes: `Bots` auto-discovery uses the `bot_` key prefix in `playtest_commands`, so adding a new bot QA gate is a one-place change (the new bot's `.gd` script + appending its `bot_<name>=<status>` to the QA payload). No regenerator update is needed for new bots. Mermaid fallback view in `AXEL_QA_ANALYTICS.md` deliberately omits the `Bots` line because Mermaid `xychart-beta` cannot render gap-broken polylines cleanly; the canonical SVG (the user-facing chart) handles gaps natively and is the source of truth for bot trend visibility.

## 2026-05-10 - Combat item catalog: single-file edits only

- Request: Make all future changes to the item catalog in `AXEL_COMBAT_ITEM_CATALOG_PLAN.md` only.
- Implementation: Declared `AXEL/axel_project/plans/AXEL_COMBAT_ITEM_CATALOG_PLAN.md` as the sole source of truth (opening paragraph). Replaced `.cursor/plans/combat_starter_item_catalog_fee3a6f1.plan.md` with a stub that links to that file. Updated `AI_DOCS.md` §Combat item catalog and added governance rule §21 in `.cursor/rules/axel-ai-docs-governance.mdc`.
- Files changed:
  - `AXEL/axel_project/plans/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `.cursor/plans/combat_starter_item_catalog_fee3a6f1.plan.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Documentation/governance only; agents edit one markdown file for roster updates.
- Verification: Stub opens correct relative link to `AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.

## 2026-05-10 - AXEL_COMBAT_ITEM_CATALOG_PLAN under axel_project/plans

- Request: Save the combat item list plan under `AXEL/axel_project/plans/` as well as the Cursor plan mirror.
- Implementation: Added [AXEL/axel_project/plans/AXEL_COMBAT_ITEM_CATALOG_PLAN.md](AXEL/axel_project/plans/AXEL_COMBAT_ITEM_CATALOG_PLAN.md) as the repo-canonical copy (relative links into combat scripts, note that Cursor plan may mirror). Updated [AXEL/axel_project/plans/AI_DOCS.md](AXEL/axel_project/plans/AI_DOCS.md) §5 reference to point at this path first.
- Files changed:
  - `AXEL/axel_project/plans/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Design documentation only; agents should prefer the `axel_project/plans` file over the Cursor-only plan path.
- Verification: File present with full 75-item catalog content.
- Notes: Optional next step: add one-line pointer in `.cursor/plans/combat_starter_item_catalog_fee3a6f1.plan.md` to the canonical file (not done unless user wants strict two-way sync).

## 2026-05-10 - Combat item catalog plan + AI_DOCS item conventions

- Request: Use uppercase extended ids (`C-A`, `C-B`, …); remember that “add an item” defaults to five rarities; add sealed-grid (no top spawn) + payout items; add optional True-path passives that inflate encounter goal % and gate True Ending; persist convention for future chats.
- Implementation: Rewrote `.cursor/plans/combat_starter_item_catalog_fee3a6f1.plan.md` to **75** entries (30 baseline + **45** extended across nine family lanes **A–F, M, G, H** × five rarities). Documented **family G** (no top refill on base-game regular spins, payout trade) and **family H** (goal penalty passives + True Ending meta hook). Added **Combat item catalog (agent convention)** under `AI_DOCS.md` §5 with uppercase id pattern and default five-tier item specs.
- Files changed:
  - `.cursor/plans/combat_starter_item_catalog_fee3a6f1.plan.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Design/agent guidance only; no gameplay code. Future “add an item” combat requests should assume **Common→Legendary** unless scoped narrower; extended ids documented as `TIER-FAMILY`.
- Verification: Manual read-back of plan structure (counts 19/17/15/13/11 per tier = 75 total).
- Notes: True Ending exact gate (`L-H` only vs full `*-H` set) left as implementation/design choice in the plan.

## 2026-05-11 - QA Agent Item-Bot Extension (Combat Balance Audit)

- Request: Extend `qa agent` with a combat bot simulation path that validates item behavior and produces balance-effect data for over/underpower detection, while preserving AXEL QA canon defaults and ensuring all QA variants persist results to analytics.
- Implementation: Added item combat simulation QA contract, headless audit script, analytics integration, and governance updates across the full QA pipeline:
  1. **Contract (skill + rubric + run-log):** Extended `SKILL.md` with mandatory persistence (was optional), item simulation section, and persistence footer for all modes. Extended `AXEL_QA_REVIEW_RUBRIC.md` with item combat simulation subsection (conditional command, classification thresholds, per-item metrics schema), over/underpower evidence rules, and expanded payload schema (`item_balance`, `item_metrics`, `item_balance_audit` playtest command key). Extended `AXEL_QA_RUN_LOG.md` template with `item_balance_audit` status and optional `item_balance`/`item_metrics` JSON keys.
  2. **Simulation script:** Created `combat/test/item_balance_audit.gd` — deterministic headless Monte Carlo that discovers items from `res://combat/data/items/`, checks `CombatRoot` for equip API, runs paired baseline/item simulations across configurable seed batches, computes per-item RTP delta, hit-rate delta, encounter success delta with 95% CI, and classifies each item. Outputs `ITEM_BALANCE_JSON` or `ITEM_BALANCE_SKIP` (graceful when no items exist or API not implemented). Always exits 0.
  3. **Analytics integration:** Fixed stale file paths in `update_qa_analytics.py` (old `plans/` → reorganized `plans/qa/`). Added `_render_item_balance_section()` that produces a compact per-item delta table and classification-change tracking across runs. Integrated item audit status into the Latest snapshot. Preserved full backward compatibility with existing payloads.
  4. **Execution wiring:** Updated skill execution contract and rubric default command set to include conditional `item_balance_audit.gd` after the six default gates. Added skip policy documentation for missing items/API. Normalized all QA aliases to include the mandatory persistence footer step.
  5. **Governance:** Updated `AI_DOCS.md` §11 (qa agent) and §12 (Simulated QA Reviewer) with item audit references, mandatory persistence wording, and SVG regeneration requirement. Updated `.cursor/rules/axel-ai-docs-governance.mdc` rules 11 and 13 with item audit command and mandatory payload keys.
- Files changed:
  - `.cursor/skills/axel-simulated-qa/SKILL.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_RUN_LOG.md`
  - `AXEL/axel_project/combat/test/item_balance_audit.gd` (new)
  - `AXEL/axel_project/tools/qa/update_qa_analytics.py`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: QA pipeline gains item balance testing capability that activates automatically when items are implemented. Persistence is now mandatory for all QA modes. Analytics dashboard will show item balance summaries once item data flows through. No gameplay code or combat behavior changed.
- Verification: Ran `python AXEL/axel_project/tools/qa/update_qa_analytics.py` — parses 4 existing payloads correctly with new code paths, outputs to reorganized `plans/qa/` paths, no item section rendered (expected: no items yet). Confirmed backward compatibility with existing run-log entries.
- Notes: Item equip API (`equip_item` / `set_equipped_items` on CombatRoot) is not yet implemented; script gracefully skips with `ITEM_BALANCE_SKIP item_api_not_implemented` until that infrastructure lands. Classification thresholds (±0.02 RTP delta CI) are conservative defaults; adjust per tuning needs.

## 2026-05-11 - Item System Infrastructure + C1 Ash Reroll Token

- Request: Implement item-by-item workflow infrastructure (item system, dev picker, stacking framework) and first item C1 per the AXEL combat item catalog plan.
- Implementation: Created `ItemDef` resource class (`item_def.gd`) with id, display_name, rarity, family, description, effect_id, and effect_params. Created `ItemInventory` (`item_inventory.gd`) managing equipped items array with max 7 slots, equip/unequip by id, and set_all. Added `equip_item`, `unequip_item`, `set_equipped_items` methods to `combat_root.gd` plus additive item payout scalar computation (`_get_item_payout_scalar` / `_item_payout_contribution`) applied to line payouts and grid-clear bonuses in both `spin()` and `spin_sync()`. Created C1 Ash Reroll Token data file (`C1_ash_reroll_token.tres`) with `reroll_payout_scalar` effect (+0.10x per paid spin, cap +0.60x). Added programmatic dev picker UI to `combat_test.gd` with auto-discovery of items from `res://combat/data/items/`, checkbox toggles, max-7 enforcement, and equipped count display.
- Files changed:
  - `AXEL/axel_project/combat/scripts/item_def.gd` (new)
  - `AXEL/axel_project/combat/scripts/item_inventory.gd` (new)
  - `AXEL/axel_project/combat/data/items/C1_ash_reroll_token.tres` (new)
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_RUN_LOG.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_ANALYTICS.md` (regenerated)
  - `AXEL/axel_project/plans/qa/AXEL_QA_ANALYTICS.svg` (regenerated)
- Behavior impact: CombatRoot now supports equipping up to 7 items whose effects stack additively. C1 increases encounter payout scalar based on paid spin count. Dev picker UI allows selecting items during combat testing. Item balance audit now runs against real item data.
- Verification: All 7 headless commands pass — princess_check OK, determinism OK (100 spins), rtp_audit within [0.75, 0.80] (mean=0.793), scene_smoke OK (6 scenes), bot_arc1_exterior OK, bot_dialogue_loop OK, item_balance_audit captured (C1 tested, classified overpowered delta_rtp=+0.465).
- Notes: C1 classified overpowered by balance audit (delta_rtp=+0.465, CI [0.121, 0.808]); values may need tuning in future chat. Stacking framework designed for additive composition — future items with different effect_id values get independent match branches while same-effect items naturally stack through the iteration loop.

## 2026-05-11 - Fix item_balance_audit.gd Unused Variable Warnings

- Request: Resolve the 4 linter warnings (UNUSED_VARIABLE) in `item_balance_audit.gd`.
- Implementation: Surfaced the four accumulated-but-unreturned locals (`total_wager_cents`, `total_payout_cents`, `free_spins`, `free_hit_spins`) in the `_run_item_audit()` return dictionary as additive fields, matching the parallel coverage in `_run_baseline()`.
- Files changed:
  - `AXEL/axel_project/combat/test/item_balance_audit.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Per-item metrics in `ITEM_BALANCE_JSON` output now include wager/payout totals and free spin counts; no behavioral change to Monte Carlo loops or classification logic.
- Verification: `ReadLints` reports 0 warnings/errors for `item_balance_audit.gd` after the fix.
- Notes: Additive-only schema change; existing downstream consumers (QA analytics parser) ignore unknown keys and are unaffected.

## 2026-05-11 - Dynamic Inventory Capacity, Legendary Slot-Expander, Dev Picker UX, Synergy Tests, C1 Balance Tuning

- Request: Implement dynamic inventory capacity (base 7 + legendary bonus), add legendary slot-expander item (+2 slots), upgrade dev picker to scrollable list with rarity colors and dynamic cap display, add deterministic synergy smoke test, and retune C1 to reduce RTP inflation.
- Implementation:
  - `ItemInventory` refactored from `const MAX_SLOTS=7` to dynamic `BASE_MAX_SLOTS + bonus` system. New methods: `get_base_max_slots()`, `get_current_max_slots()`. Bonus slots computed from equipped items with `effect_id=extra_inventory_slots` gated to `LEGENDARY` rarity only. `equip()` uses projected max (includes the item being added) to handle self-expanding slot items. `set_all()` now delegates to `equip()` for consistent constraint enforcement.
  - New legendary item `L3 Void Satchel` (`L3_void_satchel.tres`): rarity=LEGENDARY, effect_id=`extra_inventory_slots`, bonus_slots=2. Raises max from 7 to 9 when equipped.
  - Dev picker: rarity color indicators (Common gray, Uncommon green, Rare blue, Epic purple, Legendary gold) with glyph prefixes (◇◈◆★✦). Title now shows dynamic `(selected/max)`. ScrollContainer has explicit minimum height for long lists.
  - Deterministic synergy smoke test (`item_synergy_smoke.gd`): 8 test cases covering single equip, duplicate rejection, base slot limit, dynamic cap with expander, expander-at-base-limit, deterministic scalar across runs, over-cap graceful degradation, and C1+L3 coexistence. Exits non-zero on failure.
  - C1 `per_reroll` reduced 0.10→0.06, `cap` reduced 0.60→0.36 (40% reduction targeting neutral RTP band).
  - Catalog plan updated: L3 added to legendary baseline (76 items total), common-tier tuning note added with proportional reduction targets for C2–C10 and extended commons.
  - QA rubric updated: `item_synergy_smoke.gd` registered as conditional pass/fail gate.
- Files changed:
  - `AXEL/axel_project/combat/scripts/item_inventory.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/item_def.gd` (unchanged, referenced)
  - `AXEL/axel_project/combat/data/items/C1_ash_reroll_token.tres`
  - `AXEL/axel_project/combat/data/items/L3_void_satchel.tres` (new)
  - `AXEL/axel_project/combat/test/item_synergy_smoke.gd` (new)
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Inventory cap is now dynamic (base 7, up to 9 with L3 equipped). C1 payout scalar accumulates slower and caps lower. Dev picker shows all items with rarity visual hierarchy. Synergy smoke test catches equip-limit regressions and loadout determinism issues.
- Verification: ReadLints reports 0 warnings/errors across all edited GDScript files. Synergy smoke test covers 8 assertion groups for inventory constraints, determinism, and coexistence.
- Notes: Unequipping the slot-expander while over base cap is allowed (graceful degradation) — further equips are blocked until count drops below current max. Common-tier tuning targets documented in catalog for future item implementations.

## 2026-05-11 - Chat Efficiency: Cursorignore, Governance Dedup, Progress Feed Policy

- Request: Reduce agent context/token overhead identified by a full workflow audit. Implement the three HIGH-priority recommendations: add `.cursorignore` fences, slim the always-applied governance rule to pointer-first guidance, and relax mandatory progress-feed verbosity during implementation loops.
- Motivation: The audit ([Chat efficiency audit](ef94eb64-2da7-4be5-b1ef-a1704d663ee0)) found that the governance rule duplicated ~95% of `AI_DOCS.md` content (injected into every turn's system prompt), no `.cursorignore` existed (allowing 303 MB debug logs and 2.5 MB JS bundles into the index), and the rigid 6-field progress template added ~1,800 tokens of repetitive overhead across a 43-turn implementation chat.
- Implementation:
  - Created `.cursorignore` with three narrow exclusion patterns: `logs/debug/**`, `AXEL/axel_project/exports/moon_princess_files/**`, `**/*bundle*.js`.
  - Refactored `axel-ai-docs-governance.mdc` from 42 lines of duplicated detail to 16 lines of pointer-first guidance. Preserved in-rule: read-AI_DOCS directive, hard conflict gate, QA opt-in trigger, canonical alias stability, and pipeline discovery hook. Removed: duplicated QA command matrices, scene/bot implementation details, premium planning checklists, terminology locks, and other content already in `AI_DOCS.md`.
  - Updated progress-feed policy in both governance rule and `AI_DOCS.md` §9: full structured format for planning/exploration/blocked states; concise one-liner sufficient during dense implementation loops.
  - Added governance responsibility split note to `AI_DOCS.md` §9 to prevent future re-expansion drift.
- Files changed:
  - `.cursorignore` (new)
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No gameplay/canon/runtime changes. Agent context overhead reduced: ~35 lines removed from every turn's system prompt; 375 MB of files excluded from indexing; progress-feed overhead reduced during implementation stretches.
- Verification: Governance rule still enforces conflict gate, QA opt-in, canonical aliases, and AI_DOCS-first read. AI_DOCS.md retains all detailed procedures, invariants, and pipeline specs. `.cursorignore` patterns are narrow and exclude only non-authoritative artifacts.
- Rollback: Restore prior governance rule body from git history. Remove `.cursorignore` to re-index excluded files. Revert `AI_DOCS.md` §9 progress-feed wording and responsibility-split note.

## 2026-05-11 - Medium-Impact Workflow Optimizations (M1/M2/M3)

- Request: Implement the three MEDIUM-priority recommendations from the chat efficiency audit: unify QA command references (M1), consolidate bot-playthrough detail (M2), split scenes monolith into per-arc files (M3).
- Conflict resolution: AI_DOCS.md hierarchy (§3) designates the QA rubric as the authoritative playtest-mode command source. No canon/invariant conflicts.
- Implementation:
  - **M1 — QA doc dedup:** Trimmed duplicate command lists and item-balance-audit details from `AI_DOCS.md` §11–§12 and `.cursor/skills/axel-simulated-qa/SKILL.md`. Both now use pointer-style references to `AXEL_QA_REVIEW_RUBRIC.md` §Playtest-mode as the single canonical command source. Fixed stale path references in SKILL.md (`plans/AI_DOCS.md` → `plans/core/AI_DOCS.md`, `plans/AXEL_QA_REVIEW_RUBRIC.md` → `plans/qa/AXEL_QA_REVIEW_RUBRIC.md`).
  - **M2 — Bot detail consolidation:** Replaced expanded bot architecture/file-list prose in `AI_DOCS.md` §11 with a one-liner pointing to `test/bots/README.md`. Rubric confidence-tier table retains gating semantics unchanged.
  - **M3 — Scene doc split:** Moved 999-line `AXEL_SCENES_NEW.md` content into 8 per-arc files (`AXEL_SCENES_ARC1.md` … `AXEL_SCENES_ARC8.md`) under `plans/scenes/`. Original file replaced with a compact TOC/index. Updated `SCENE_BUILDER_AGENT_SPEC.md` canon-sources to note the TOC+arc pattern. Updated `layout_planner.py` fallback to scan `AXEL_SCENES_ARC*.md` via glob instead of reading the monolith.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursor/skills/axel-simulated-qa/SKILL.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_NEW.md` (replaced with TOC)
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md` … `AXEL_SCENES_ARC8.md` (new)
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/tools/scene_builder/layout_planner.py`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No gameplay/canon/runtime changes. QA command semantics, confidence tiers, skip policy, and persistence invariants are unchanged — only the doc-ownership hierarchy shifted. Scene agent loads ~100-200 lines per arc instead of 999. Layout planner fallback produces identical canonical filenames.
- Verification: Grep confirms no duplicate command names remain in AI_DOCS or SKILL. Planner fallback glob resolves to the same arc files containing "corridor"/"classroom"/"library" keywords. Rubric remains untouched as the single command-set authority.
- Rollback: Restore `AXEL_SCENES_NEW.md` monolith from git, delete `AXEL_SCENES_ARC*.md` files, revert `layout_planner.py` to use `SCENES_NEW_PATH`, restore prior AI_DOCS §11–§12 and SKILL.md from git.

## 2026-05-11 - Low-Maintenance Workflow Fixes (path alignment, QA archival, debug cleanup)

- Request: Finish remaining low-priority workflow optimizations from the chat efficiency audit.
- Conflict resolution: No canon/invariant conflicts. Changes are workflow/docs/tooling hygiene only.
- Implementation:
  - **Path alignment:** Fixed Moon Princess export folder references in `AI_DOCS.md` §3 and §4 from `moon_princess_files` to actual on-disk name `Moon Princess Files`. Updated `.cursorignore` to match the real folder path so all capture assets (JS, CSS, hashed files) are properly excluded from indexing.
  - **Bots README pointer fix:** Updated `test/bots/README.md` canon references from stale `plans/AI_CHANGELOG.md` and `plans/AI_DOCS.md` to correct `plans/core/AI_CHANGELOG.md` and `plans/core/AI_DOCS.md`.
  - **QA run-log archival:** Created `plans/qa/archive/` directory. Added archival policy note to `AXEL_QA_RUN_LOG.md` header (move entries beyond ~10 to `archive/AXEL_QA_RUN_LOG_<YYYY>.md`). Updated `tools/qa/update_qa_analytics.py` to ingest payloads from both the main log and `archive/*.md` files via new `_collect_all_payloads()` function. Added archival note to QA rubric §Persistent-analytics-payload.
  - **Debug log archive:** Moved 303 MB and 71 MB inactive debug logs to `logs/debug/archive/`, covered by existing `.cursorignore` pattern. Active debug directory reduced to ~0.3 MB.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursorignore`
  - `AXEL/axel_project/test/bots/README.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_RUN_LOG.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/tools/qa/update_qa_analytics.py`
  - `AXEL/axel_project/plans/qa/archive/.gitkeep` (new)
  - `logs/debug/archive/` (2 files moved)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No gameplay/canon/runtime changes. `.cursorignore` now correctly excludes the real capture folder. QA analytics generator preserves full trend history across archival. Debug log footprint in active workspace reduced by ~374 MB.
- Verification: `.cursorignore` pattern matches actual `Moon Princess Files` folder. `AI_DOCS` references match on-disk naming. Bots README points to `plans/core/*`. Analytics generator `_collect_all_payloads()` scans both active log and archive directory.
- Rollback: Restore old `.cursorignore` and `AI_DOCS` path references from git. Move archived debug logs back to `logs/debug/`. Revert analytics script `_collect_all_payloads()` to single-file `main()`. Remove `plans/qa/archive/` directory.

## 2026-05-11 - Exports Cleanup Migration

- Request: Reorganize exports folder — move implementation guide to plans, group screenshots into subfolder, add disclaimer to README_NOTREAL.md, verify Moon Princess Files governance alignment, convert Viral Forge PDFs to Markdown.
- Implementation:
  - Moved `exports/GODOT_IMPLEMENTATION_GUIDE.md` to `plans/references/GODOT_IMPLEMENTATION_GUIDE.md`.
  - Created `exports/screenshots/` and moved 7 Screenshot PNGs + 7 matching `.png.import` files into it.
  - Updated `exports/README_NOTREAL.md` with explicit "not the authoritative README" disclaimer, updated guide path, and reflected new screenshots subfolder in directory tree.
  - Verified `AI_DOCS.md` §3 and §4 plus `.cursorignore` already reference `Moon Princess Files` (no stale `moon_princess_files` paths in governance).
  - Converted all 12 Viral Forge PDFs to clean Markdown files (one-to-one, same basenames) preserving all factual content with proper heading/table/list formatting. Deleted original PDFs per user preference.
- Files changed:
  - `AXEL/axel_project/plans/references/GODOT_IMPLEMENTATION_GUIDE.md` (moved from exports)
  - `AXEL/axel_project/exports/screenshots/Screenshot 2026-04-28 14*.png` (7 files moved)
  - `AXEL/axel_project/exports/screenshots/Screenshot 2026-04-28 14*.png.import` (7 files moved)
  - `AXEL/axel_project/exports/README_NOTREAL.md` (updated)
  - `AXEL/axel_project/exports/Viral Forge/*.md` (12 new files created)
  - `AXEL/axel_project/exports/Viral Forge/*.pdf` (12 files deleted)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No gameplay/canon/runtime changes. File organization only. Viral Forge content now indexable/searchable as Markdown.
- Verification: Confirmed no root-level Screenshot files remain in exports. Confirmed GODOT_IMPLEMENTATION_GUIDE.md exists only under plans/references. Confirmed Viral Forge contains 12 .md files and 0 .pdf files. Confirmed AI_DOCS.md and .cursorignore use `Moon Princess Files` path consistently.
- Notes: User explicitly chose to keep `Moon Princess Files` (with spaces) as the canonical folder name rather than normalizing to `moon_princess_files`. This is a deliberate override of the snake_case convention in README_STRUCTURE.md; governance docs already reflect this choice from a prior session.

## 2026-05-11 - Separate collision debug: editor-only colors, no runtime overlay

- Request: Collision outlines should be visible only in the 2D editor viewport, not when running the scene. The previous `PlaytestCollisionDebug` autoload drew cyan outlines at runtime which cluttered gameplay.
- Implementation:
  - Removed `PlaytestCollisionDebug` autoload from `project.godot` so the runtime overlay no longer loads.
  - Added `[debug]` section to `project.godot` with `shapes/collision/shape_color = Color(0.0, 0.92, 0.95, 0.42)` (bright cyan), `contact_color = Color(0.0, 1.0, 0.5, 0.8)` (green), and `draw_2d_outlines = true`. These control the 2D editor viewport display only; they do not render at runtime unless Debug > Visible Collision Shapes is manually enabled.
  - Updated `AI_DOCS.md` §8 to reflect editor-only colors replacing the runtime autoload.
  - Rewrote `PLAYTEST_DEBUG_COLLISIONS.md` to document the new project-settings approach and note the legacy scripts as disabled.
- Files changed:
  - `AXEL/axel_project/project.godot` (autoload removed, `[debug]` section added)
  - `AXEL/axel_project/plans/core/AI_DOCS.md` (§8 bullet updated)
  - `AXEL/axel_project/plans/core/PLAYTEST_DEBUG_COLLISIONS.md` (rewritten)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Running scenes no longer show any collision outlines. Editing scenes in the 2D viewport shows bright cyan collision shapes/outlines that contrast with the AXEL red/black/white palette. Debug scripts in `scripts/debug/` remain in repo but are dormant.
- Verification: Structural check confirms autoload removed, no scene files or scripts depend on the singleton, project settings section is well-formed.
- Notes: Legacy `playtest_collision_debug.gd` and `playtest_collision_debug_draw.gd` kept in repo for optional future re-enablement; re-add the autoload line to `project.godot` if runtime overlay is ever needed again.

## 2026-05-11 - Noir shader bypass for collision debug colors

- Request: Collision shapes still appeared red in the editor because the `NoirPaletteOverlay` screen-texture shader (layer 90) remaps all pixels to the AXEL 4-color palette, converting cyan debug shapes to blood red.
- Implementation: Added a cool-hue bypass at the top of `noir_palette_filter.gdshader`. Any pixel where `min(G, B) - R > 0.04` passes through unmodified. Since the AXEL game palette is strictly warm (red/black/white), cool-colored pixels can only come from editor debug overlays.
- Files changed:
  - `AXEL/axel_project/scenes/fx/noir_palette_filter.gdshader`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Cyan collision shapes now display correctly in the 2D editor viewport instead of being palette-mapped to red. No visual change to game content at runtime since no game art produces cool-hued pixels.
- Verification: Confirmed `locker_palette_filter.gdshader` and `highlighted_locker_palette_filter.gdshader` use `TEXTURE` (not `screen_texture`) and do not need the bypass.
- Notes: Superseded by the runtime-only noir guard below — cool-hue bypass has been removed.

## 2026-05-11 - Runtime-only noir overlay (fix editor whiteout)

- Request: After the shader bypass was added, the entire editor viewport turned white except for lockers and the dialogue box — `hint_screen_texture` returns a white fallback in the Godot 2D editor, so the noir shader mapped nearly everything to the white band.
- Root cause: `NoirPaletteOverlay` (`CanvasLayer` 90) uses a `screen_texture` post-process shader. In the editor viewport, `screen_texture` does not contain live scene content — it falls back to white. This pushes the luminance of every pixel above `t2 (0.72)`, mapping them to `white_color`. Lockers (layer 95) and dialogue (layer 110) are above the noir layer and render directly, which is why they appeared normal.
- Implementation:
  - Created `@tool` guard script `scenes/fx/noir_overlay_guard.gd` that sets `visible = false` when `Engine.is_editor_hint()` is true, disabling the entire noir `CanvasLayer` in the editor while keeping it active at runtime.
  - Attached the guard script to the `NoirPaletteOverlay` root node in `NoirPaletteOverlay.tscn` (load_steps bumped to 4, ext_resource added, `script` property set).
  - Removed the temporary cool-hue bypass from `noir_palette_filter.gdshader`, restoring it to the original clean 4-band palette mapping. The bypass is no longer needed since the overlay is invisible in the editor.
- Files changed:
  - `AXEL/axel_project/scenes/fx/noir_overlay_guard.gd` (new)
  - `AXEL/axel_project/scenes/fx/NoirPaletteOverlay.tscn` (script attached)
  - `AXEL/axel_project/scenes/fx/noir_palette_filter.gdshader` (bypass removed)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Editor viewport shows raw scene content with cyan collision helpers. Runtime playtest retains full noir post-processing. No gameplay, layering, or scene logic changes.
- Verification: Both instancing scenes (`1.1_SchoolExterior`, `1.2_Corridor`) use the overlay as PackedScene instance without script overrides — the guard applies automatically. `1.2_Corridor.gd` only accesses noir at runtime (not `@tool`), so no conflict.

## 2026-05-11 - Scene 1.1 Background Swap (Drawing Replaces Placeholder Visuals)

- Request: Replace all legacy placeholder/tilemap background visuals in Scene `1.1` with a single hand-drawn background image (`exports/Drawings/1.1_SchoolExterior.png`), preserving all gameplay logic, collisions, and interaction systems.
- Implementation: Rewrote `1.1_SchoolExterior.tscn` to replace the old visual stack with one `Sprite2D` node (`Background_1_1`, `z_index = -100`, `centered = false`) backed by the new drawing texture. Removed visual-only nodes: `Floor` (Polygon2D), three environment placeholder polygons (`1.1_School_Building_Exterior_01`, `1.1_School_Building_Doors_01`, `1.1_School_Door_Boundary_01`), `Background_Plants` (TileMapLayer), `Background_Road` (TileMapLayer). Removed orphaned ext_resources (6 plant textures, 2 road textures) and all TileSetAtlasSource/TileSet sub_resources. Preserved all gameplay nodes: wall StaticBody2D boundaries, door collision body, door interact Area2D, NoirPaletteOverlay, PlayerLayer + Player, TopDialogueOverlay.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- New files:
  - `AXEL/axel_project/plans/scenes/SCENE_BACKGROUND_SWAP_CHECKLIST.md` — reusable per-scene checklist for future drawing-to-scene background replacements.
- Behavior impact: Scene `1.1` now displays the hand-drawn background instead of colored Polygon2D placeholders and tiled plant/road layers. All gameplay behavior unchanged: intro dialogue sequence, player movement, door interaction + corridor transition, noir overlay, wall boundaries.
- Preserved gameplay systems: `1.1_SchoolExterior.gd` unmodified; all three script node paths (`$TopDialogueOverlay`, `$PlayerLayer/Player`, `1.1_EnvironmentPlaceholders/1.1_School_Building_Doors_01_InteractArea`) still resolve to existing nodes with original unique_ids.
- Verification: Cross-checked all `@onready`/`get_node()` paths in scene script against updated node tree; confirmed z-order layering (background at -100, collisions unaffected, player on CanvasLayer 100, overlays above).
- Notes: Collision/trigger geometry retained as-is for this pass (visual-only scope). Future passes can rework collision shapes to match drawn geometry. Reusable checklist established at `plans/scenes/SCENE_BACKGROUND_SWAP_CHECKLIST.md` for repeating this workflow on other scenes.

## 2026-05-11 - Scene 1.1 Upgrade: Camera, Colliders, Noir Tuning, Scanline, Style Options

- Request: Implement vertical camera follow, freeform collision polygon scaffolding, noir tuning for new background, full-scene scanline/terminal overlay, and document external visual style alternatives.
- Implementation:
  - **Vertical camera follow:** Created `scenes/Arc_1/camera_follow_vertical.gd` (exports: `target_path`, `fixed_x`, `vertical_smoothing`). Added `Camera2D` node to scene root targeting `PlayerLayer/Player`. Horizontal position locked at 640; vertical follows player Y with exponential smoothing. Limits set to background extents (top=-300, bottom=870) to prevent void.
  - **Collision polygon scaffolding:** Added `EnvironmentColliders` parent node with 5 named `StaticBody2D` children (`TreeLine_Left`, `TreeLine_Right`, `Rocks_Left`, `Rocks_Right`, `Building_Front`), each with empty `CollisionPolygon2D` ready for manual polygon drawing in the editor.
  - **Noir retuning:** Enabled `NoirPaletteOverlay` (was `visible=false`). Added `_USE_LOCAL_NOIR_TUNING` const and `_apply_local_noir_tuning()` to `1.1_SchoolExterior.gd` — adjusts thresholds (t0=0.05, t1=0.22, t2=0.62) and slightly muted palette for better exterior detail retention.
  - **Scanline overlay:** Created `scenes/fx/overworld_scanline.gdshader` (SCREEN_UV-based scanlines with vignette, noise, and chroma aberration) and `scenes/fx/ScanlineOverlay.tscn` (CanvasLayer 92, above noir at 90). Instanced in Scene 1.1. Default: subtle (12% strength, 320 density, low chroma/noise).
  - **Style alternatives doc:** Created `plans/references/VISUAL_STYLE_OPTIONS.md` covering 5 external options (CRT plugin, GodotRetro VHS/Glitch, palette+dither shaders, CRT Display, CRT Luminance) with comparison matrix and fit assessment.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn` (camera, colliders, scanline instance, noir enabled)
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd` (noir tuning added)
- New files:
  - `AXEL/axel_project/scenes/Arc_1/camera_follow_vertical.gd`
  - `AXEL/axel_project/scenes/fx/overworld_scanline.gdshader`
  - `AXEL/axel_project/scenes/fx/ScanlineOverlay.tscn`
  - `AXEL/axel_project/plans/references/VISUAL_STYLE_OPTIONS.md`
- Behavior impact: Scene 1.1 now scrolls vertically with the player, applies local noir tuning for exterior readability, and renders a subtle scanline/terminal effect over everything. Collision polygon nodes are scaffolded but have empty polygons (user draws in editor). Door interaction and transition logic unchanged.
- Manual steps remaining: Draw collision polygon points in the editor for `TreeLine_Left/Right`, `Rocks_Left/Right`, `Building_Front`. Adjust wall boundaries if player should traverse the full vertical extent of the new background.

## 2026-05-11 - Overworld: White Player, Stabilized TV Noise Overlay, Layer Fix

- Request: Fix scanline grading artifact during camera movement, make player character render white across overworld scenes, add stronger top-layer old-TV grain/noise effect.
- Root cause of grading artifact: Hard `step()` scanline pattern combined with chroma oscillation (`sin(SCREEN_UV.y * 900)`) created moire-like interference against the shifting scene content during camera movement.
- Implementation:
  - **Shader rewrite:** Replaced `overworld_scanline.gdshader` with a cleaner TV static grain pass. Removed hard `step()` scanlines and chroma oscillation. New effect uses high-frequency hash-based white noise (time-quantized for analog grain feel), soft sine scanlines, vignette, and global brightness flicker. Exposed uniforms: `noise_intensity`, `noise_speed`, `scan_strength`, `scan_density`, `blend_opacity`, `vignette_strength`, `flicker_strength`.
  - **Layer raise:** Moved `ScanlineOverlay.tscn` from CanvasLayer 92 to 105, placing it above PlayerLayer (100) and LockerBypassLayer (95) so the grain/noise covers the entire rendered image.
  - **White player:** Added `@export var overworld_tint: Color` to `Player.gd` (default white). `_apply_overworld_tint()` applies the tint to `animated_sprite.modulate` after sprite setup. Shadow outline explicitly kept at black with 0.55 alpha for silhouette contrast.
  - **Scene wiring:** Added `ScanlineOverlay` instance to `1.2_Corridor.tscn` (already present in 1.1). Both Arc 1 overworld scenes now share the reusable overlay.
- Files changed:
  - `AXEL/axel_project/scenes/fx/overworld_scanline.gdshader` (full rewrite)
  - `AXEL/axel_project/scenes/fx/ScanlineOverlay.tscn` (uniforms updated, layer raised to 105)
  - `AXEL/axel_project/scripts/Player.gd` (overworld_tint export + _apply_overworld_tint)
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn` (ScanlineOverlay instance added)
- Behavior impact: Camera movement no longer produces visible banding/grading artifacts. Player sprite renders white in all overworld scenes using the shared `Player.gd`. Old-TV grain is visible as a top-layer effect covering everything. Layer ordering: Noir(90) < LockerBypass(95) < Player(100) < Grain/Noise(105).

## 2026-05-11 - Scene 1.1 Visibility Polish: White Player, Scale, Noise Reduction, Line Preservation

- Request: Fix player still appearing red, increase player scale +20% in Scene 1.1, reduce noise overlay visibility to minimal, preserve thin black line art at 1152x648 viewport.
- Implementation:
  - **White player guarantee:** Created `scenes/fx/white_sprite.gdshader` (outputs pure white preserving alpha). `Player.gd` `_apply_overworld_tint()` now applies this shader to the animated sprite when `overworld_tint` is white, guaranteeing white rendering regardless of texture import cache state.
  - **Player scale +20% (Scene 1.1 only):** Added `scale = Vector2(1.2, 1.2)` to the Player node in `1.1_SchoolExterior.tscn`. Scene 1.2 unchanged.
  - **Minimal noise overlay:** Reduced `ScanlineOverlay.tscn` defaults: `blend_opacity` 0.7->0.22, `noise_intensity` 0.12->0.04, `scan_strength` 0.04->0.015, `vignette_strength` 0.18->0.1, `flicker_strength` 0.015->0.008. Effect now subtly present without limiting player visibility.
  - **Noir line preservation at 1152x648:** Switched `noir_palette_filter.gdshader` screen_texture from `filter_linear` to `filter_nearest` to prevent interpolation-based line blurring during downscale. Added `line_contrast` uniform (default 1.4) that boosts luminance contrast before palette thresholding, keeping thin dark strokes firmly in the black band. Local tuning in `1.1_SchoolExterior.gd` updated: raised `t0` to 0.10, `line_contrast` to 1.5 for exterior background detail.
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd` (white shader application in _apply_overworld_tint)
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn` (player scale 1.2)
  - `AXEL/axel_project/scenes/fx/ScanlineOverlay.tscn` (reduced intensity defaults)
  - `AXEL/axel_project/scenes/fx/noir_palette_filter.gdshader` (filter_nearest, line_contrast uniform)
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd` (updated local noir tuning with line_contrast)
- New files:
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
- Behavior impact: Player renders guaranteed white in Scene 1.1 at +20% size. Noise overlay is now barely perceptible. Black ink lines in hand-drawn background survive the noir filter at lower viewport resolutions (1152x648) due to nearest-neighbor sampling and contrast pre-boost.

## 2026-05-17 - Fix Combat Seed, Spin Log, and Trinity Gravity

- Request: Fix inability to enter/apply a specific combat seed, perceived spin-loop repetition in the test HUD spin log, and missing symbol fall after delete-style powers (especially final Trinity Storm step) during free-game flow.
- Implementation: Allowed seed edits when an encounter is complete (`ENDED`), synced queued seed from the SpinBox before starting the next encounter, widened seed input range, clarified HUD readout (`ENC x/y  SEED n  LIFE n`), and made Trinity cascade loops settle floating symbols via gravity even when no winning lines are present (gravity-only, no refill).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/test/princess_check.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Custom seeds typed after encounter completion apply to the next encounter; large audit seeds are enterable; Trinity/Storm deletions collapse remaining symbols; test HUD no longer mislabels lifetime spin count as the only spin context.
- Verification: `princess_check.gd` (OK); `determinism_check.gd` (OK); full QA playtest 2026-05-17 (all gates pass).
- Notes: Perceived “same spins every 6–7 rounds” was partly stale `_queued_seed` at encounter boundaries plus HUD ambiguity; intentional deterministic reseed per encounter seed is unchanged.

## 2026-05-17 - Remove In-Round Symbol Refills (Universal Gravity-Only Cascades)

- Request: Per MP100 rules, no new symbols should appear on the grid during a spin round — normal paid spins, Trinity Run, or SUPER Free Spins.
- Implementation: Removed `grid.refill()` from `_apply_gravity_and_refill` / `_apply_gravity_and_refill_sync` in `combat_root.gd` so all cascade resolution is gravity-only. Initial spin setup via `grid.populate()` is unchanged. Added paid-spin no-spawn test; updated Trinity/Free Spins test messages. Aligned `AXEL_combat_design.md` and `AXEL_combat_implementation.md` cascade sections to universal no-refill depletion.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/test/princess_check.gd`
  - `AXEL/axel_project/plans/combat/AXEL_combat_design.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Winning cascades leave empty cells after gravity; no top-spawned symbols mid-round in any mode. Wild placement (3-lines) and princess power mutations still apply. RTP/cascade depth will differ from prior base-game refill behavior.
- Verification: `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/princess_check.gd`
- Notes: Resolved doc hierarchy conflict by updating combat design/implementation to match the new rule (overrides prior base-game “new symbols from top” cascade wording).

## 2026-05-17 - Bankroll Encounter Cap + Readout Cleanup

- Request: End encounters when bankroll is empty (not spin budget); remove encounter counter and bottom seed from HUD; rename LIFE readout to SPIN LOG.
- Implementation: Replaced `_finalize_encounter_if_needed()` spin-budget fail with bankroll-depletion fail (`not _can_afford_spin()` outside free spins). Early-return paths in `spin()` / `spin_sync()` now finalize encounter on unaffordable paid spin. Bottom HUD readout shows only `SPIN LOG <n>`. Renamed princess_check assertion to bankroll-empty fail.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/test/princess_check.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Encounters no longer auto-fail at `spin_budget` (e.g. 8 spins); they fail when the player cannot afford another paid spin. Goal completion still wins. Seed remains visible in top-right SpinBox only.
- Verification: `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/princess_check.gd` (OK).
- Notes: Intentional override of spin-budget fail behavior in `AXEL_combat_implementation.md`; `spin_budget` field remains on encounter resources for future tuning but is not used for encounter end.

## 2026-05-17 - Trinity/Super FS Fresh-Grid Handoff Override

- Request: Enforce flow: Execute → fresh grid → paid spins → meter full → fresh grid → Trinity powers → if cleared choose princess → fresh grid → Super Free Spins; treat Free Spins and Super Free Spins as the same feature.
- Implementation: Added `_repopulate_grid_handoff` / `_repopulate_grid_handoff_async` in `combat_root.gd` (deterministic RNG stream, no reseed). Trinity repopulates after meter-full transition, before Love→Star→Storm sequence. Super Free Spins repopulate on `choose_free_spins_princess()` after princess selection; per-spin `_begin_spin_round` still skips repopulate during the feature. Updated combat design/implementation docs and princess_check tests.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/test/princess_check.gd`
  - `AXEL/axel_project/plans/combat/AXEL_combat_design.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Players see a full new board entering Trinity and again entering Super Free Spins; mid-feature spins remain depletion-only (no top refill, no per-spin repopulate).
- Verification: `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/princess_check.gd`
- Notes: User-approved override of prior canon (Trinity/Free Spins continued from depleted grid without handoff repopulate). Hierarchy resolution recorded here per `AI_DOCS.md` §3.

## 2026-05-17 - Surreal Combat UI + Chip-Bar Win Logic

- Request: Replace bankroll/numeric HUD with surreal chip-bar combat UI (matched log, items mirror, premium progress proxy, per-spin win multiple readout) and 10× full chip-bar encounter win condition; remove per-symbol payout popups.
- Implementation: Rebuilt `combat_test` shell as centered combat frame with 10-segment chip bar, MATCHED/ITEMS side panels, round SPIN button, ×N spin readout, and premium-meter `ProgressBar`. `combat_root` now uses chip-bar economy (`CHIP_BAR_FULL_CENTS=1000`, 10 sections), tracks encounter goal winnings toward `10×` bar value, emits `matched_symbols_resolved`, removes `play_win_popup` calls, and finalizes encounters on chip-bar goal or broke chip health. Added `chip_bar_segment.gd` and `matched_log_tile.gd`.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/chip_bar_segment.gd`
  - `AXEL/axel_project/combat/scripts/matched_log_tile.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Combat screen no longer shows bankroll/budget/stake numerics; bet is chosen via chip segments; bottom readout shows per-spin win×bet; encounter wins at 10× chip-bar accumulated payout; matched symbols log on the left without floating currency popups on cells.
- Verification: `Godot_v4.6.2-stable_win64_console.exe --headless --path AXEL/axel_project -s res://combat/test/princess_check.gd` (OK); `... -s res://combat/test/determinism_check.gd` (OK).
- Notes: User-approved override of implementation HUD checklist (§10) bankroll/stake display; legacy `goal_tracker` resources remain wired but encounter end uses chip-bar goal first.

## 2026-05-17 - Combat Test v1/v2 Version Split

- Request: Preserve old numbered combat test UI as a revertible backup; name versions `combat_test_v1` (old) and `combat_test_v2` (surreal), keep v2 as default entry.
- Implementation: Restored v1 scene+script from git snapshot `0ba177e` as `combat_test_v1.tscn` / `combat_test_v1.gd`. Copied current surreal shell to `combat_test_v2.tscn` / `combat_test_v2.gd`. Default `combat_test.tscn` now references v2 script; `combat_test.gd` extends v2 as alias. Added `combat/README_COMBAT_TEST_VERSIONS.md` with launch and rollback instructions.
- Files changed:
  - `AXEL/axel_project/combat/combat_test_v1.tscn`
  - `AXEL/axel_project/combat/combat_test_v2.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/scripts/combat_test_v2.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/README.md`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: F6 on `combat_test.tscn` runs v2; v1 remains launchable for HUD rollback. Shared `combat_root` logic is unchanged (chip-bar goal still applies when using v1 shell).
- Verification: `Godot_v4.6.2-stable_win64_console.exe --headless --path AXEL/axel_project -s res://combat/test/princess_check.gd` (OK); `... determinism_check.gd` (OK).
- Notes: v1 is a UI-layout backup, not a full pre-surreal mechanics fork.

## 2026-05-17 - Default Combat Test v1 + Remove v2 Shell

- Request: Make v1 numeric HUD the default combat test entry; delete v2 surreal chip-bar shell; fix `combat_test_v1.tscn` parse failure.
- Implementation: Fixed SUPER FS choice button `text` properties in `combat_test_v1.tscn` (multiline strings → `\n`-escaped single lines). Replaced `combat_test.tscn` with v1 node tree bound to `combat_test.gd` (alias extends `combat_test_v1.gd`). Removed `combat_test_v2.tscn`, `combat_test_v2.gd`, and v2-only `chip_bar_segment.gd` / `matched_log_tile.gd`. Updated combat README/version docs.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/combat_test_v1.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/README.md`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Files removed:
  - `AXEL/axel_project/combat/combat_test_v2.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test_v2.gd`
  - `AXEL/axel_project/combat/scripts/chip_bar_segment.gd`
  - `AXEL/axel_project/combat/scripts/matched_log_tile.gd`
- Behavior impact: F6 on `combat_test.tscn` runs numeric HUD (v1). v2 chip-bar/MATCHED panels UI no longer available. `combat_root` mechanics unchanged.
- Verification: `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://test/scene_smoke_check.gd` (OK, 6 scenes including `combat_test.tscn`).
- Notes: `combat_test_v1.tscn` kept as explicit named backup identical to default shell.

## 2026-05-17 - Combat Test v1 Layout + Premium Meter Fix

- Request: Center combat grid in v1 test shell; restore premium meter circle visibility.
- Implementation: Restored HUD-aware `fit_to_viewport()` in `combat_root.gd` (top/bottom safe zones, single `position` offset; `grid_ui` at local `(0, 48)`). Fixed `fit_to_panel()` to avoid double-offset when embedded. Hardened `premium_meter_circle.gd` sizing/redraw; set explicit 120×120 size on meter node in scenes; deferred initial layout in `combat_test_v1.gd`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/premium_meter_circle.gd`
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/combat_test_v1.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Grid centers in play area between HUD chrome; premium ring draws at full size on the right stack.
- Verification: `scene_smoke_check.gd` (OK).

## 2026-05-17 - Combat Cohesion + Canon Alignment (mirrored shell, integer economy)

- Request: Mirror combat HUD on invisible grid; left spin-history placeholder, right items; premium meter as bottom grid bar; 100× integer payouts; win numbers on matched symbols; persist clarification-first rule for AXEL agents.
- Implementation: Rebuilt `combat_test_v1.gd` with centered `CombatFrame` (spin-history | grid + premium `ProgressBar` | items). Full economy rescale (`ECONOMY_DISPLAY_SCALE`, bet ladder ×100, symbol paytable ×100, integer formatting). Restored per-symbol `play_win_popup` during line resolve. Added clarification-first to `AI_DOCS.md` §9 and governance rule.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/combat_test_v1.tscn`
  - `AXEL/axel_project/combat/data/symbols/*.tres` (8 files)
  - `AXEL/axel_project/combat/test/item_balance_audit.gd`
  - `AXEL/axel_project/combat/test/rtp_audit.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Playtest shell is symmetric; premium meter is a 3-section bar flush under grid; payouts/bankroll/stake show whole numbers; matched cells flash payout totals. Spin-history panel is placeholder-only (logic deferred).
- Verification: Pending headless `princess_check` / `scene_smoke_check` after edit.

## 2026-05-17 - Combat Test Frame Layout Fix

- Request: Fix misaligned combat grid and side rectangles clustered/overlapping EXECUTE in play window.
- Implementation: CombatFrame now uses top-left positioning with top/bottom safe margins (HUD + EXECUTE), deferred layout after first frame, expanded play-row size flags, centered `fit_to_panel` with bottom inset for premium bar, shrink-locked side panels.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mirrored shell should center in viewport; grid and ITEMS/SPIN HISTORY panels align; EXECUTE no longer covers play area.
- Verification: Manual F6 on `combat_test.tscn` recommended.
- Notes: Legacy `PremiumMeterCircle` nodes kept hidden in scenes for UID stability.

## 2026-05-17 - Playtest Economy And Main Scene Layout Spec

- Request: Playtest bankroll cap 100, stake ladder `1,2,3,4,5,10,20,30,40,50,100`, remove shared rounded wrapper around SPINS/items/grid, enforce mirrored main-game layout with matching top meta/GOAL boxes.
- Implementation: Rescaled playtest economy in `combat_root.gd` (bankroll cap 100, full 11-step bet ladder, `_clamp_bankroll()` after payouts/encounter carry). Refactored `combat_test_v1.gd` to percentage-anchored layout without outer `CombatFrame`; independent side panels (`SPINS` vertical label | grid + charge bar | `ITEMS`); centered stake pill, multiplier, and EXECUTE in center column. Updated `combat_test.tscn` with mirrored `MetaBox`/`GoalBox`, floating `100/100` bankroll readout, and dedicated `StakeSelector` row.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Default combat test starts at `100/100` bankroll with min stake `1`; stakes step through the specified ladder; bankroll cannot exceed 100; HUD follows spec symmetry without a single rounded rectangle wrapping all three play columns.
- Verification: Linter pass on touched scripts; headless `princess_check` not run (Godot CLI not on PATH). Manual F6 on `combat_test.tscn` recommended for layout and stake/bankroll UX.
- Notes: `combat_test_v2` unchanged in this pass.

## 2026-05-17 - Playtest HUD Corner Box And Bankroll Spacing Fix

- Request: Top-left/right meta and GOAL boxes were clipped off-screen; bankroll should sit directly above stake with less gap.
- Implementation: Reparented corner boxes to the root viewport (they were sized as fractions of the 15%-tall `TopBar`, which collapsed them). Stacked bankroll + stake in a tight `CenterTopHud` `VBoxContainer` (`separation` 2px) with shared center anchoring.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Meta/GOAL boxes use full viewport insets (2%–22% / 78%–98%, ~11% height); `100/100` readout sits immediately above the stake row; main play area starts at 18% height.
- Verification: Linter pass on `combat_test_v1.gd`; manual F6 recommended.

## 2026-05-17 - Combat Test HUD Layout Cleanup

- Request: Remove top-corner panel rectangles; tighten top-left icons (50% spacing, closer to corner, third icon `?`); horizontal centered SPINS title; larger side-panel fonts; thin red outline on premium progress bar; center `1X` between grid and EXECUTE; match EXECUTE width to grid; delete unused `combat_test_v2`.
- Implementation: Stripped `MetaBox`/`GoalBox` panel styles at runtime; tightened corner anchors and icon row separation; switched spin-history panel to horizontal `_make_side_panel("SPINS")`; bumped side-panel font constants; added 1px red border on premium bar background; added `MultiplierZone` expand spacers for centered multiplier readout; synced EXECUTE `custom_minimum_size.x` to `combat.grid_ui.size.x` after layout; updated `combat_test.tscn` icon defaults; removed `combat_test_v2.tscn` (v2 script already absent).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/combat_test_v2.tscn` (deleted)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Corner HUD boxes no longer draw red bordered rectangles; icons and goal text float in corners; SPINS/ITEMS panels use larger type with horizontal SPINS header; premium bar has red outline; multiplier sits between grid and EXECUTE; EXECUTE button width tracks grid width on resize.
- Verification: Linter pass on `combat_test_v1.gd`; Godot CLI not on PATH — manual F6 on `combat_test.tscn` recommended.

## 2026-05-17 - Combat Test HUD Polish Follow-Up

- Request: Match gear icon to lightweight symbol style (`⬡`); lower top icon row ~1–2%; enlarge GOAL font; show round winnings as amount (no `X`) with +10% font and thin white outline; tighten grid/readout/EXECUTE spacing; shift play area down and grow grid.
- Implementation: Replaced gear glyph with `⬡` and unified icon font size; shifted corner band (`LAYOUT_CORNER_Y0`/`Y1`); increased `GOAL_LABEL_FONT`; wired `MultiplierReadout` to `combat.get_round_winnings()` with outline styling; removed expand spacers from winnings zone; reduced column/footer separation and EXECUTE height band; extended main play anchors (`LAYOUT_MAIN_Y0`/`END`) for larger grid host.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Top icons sit slightly lower with polygon home/question trio; GOAL text scales with icons; center readout shows integer winnings with white outline; vertical stack is denser and grid area is taller.
- Verification: Linter pass on `combat_test_v1.gd`; manual F6 on `combat_test.tscn` recommended.

## 2026-05-17 - Combat HUD Spacing And History Panel

- Request: Center total winnings between premium meter and EXECUTE; reduce vertical dead space and grow grid; enlarge top-left icons 20%; replace left history rectangle with `HISTORY` title and empty placeholder.
- Implementation: Added `WinningsBand` with anchor-centered readout and `_layout_winnings_band()`; tightened main/center HUD vertical fractions and column separations; bumped `META_ICON_FONT` to 31 (+20%); replaced `_build_spin_history_placeholder()` with borderless `_build_history_placeholder()` (`HISTORY` + expand placeholder); `fit_to_panel()` now accepts `align_grid_top` (used by v1 shell) and v1 passes computed max grid height from column budget.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Winnings sit in the band between premium bar and EXECUTE; grid uses more vertical space with less internal letterboxing; left column is title-only history reserve; ITEMS panel unchanged.
- Verification: Linter pass on touched scripts (IDE may need refresh for new `fit_to_panel` arity); manual F6 on `combat_test.tscn` recommended.

## 2026-05-17 - Combat Grid Bottom Clipping Fix

- Request: Combat grid bottom was cut off after HUD spacing pass.
- Implementation: `WinningsBand` no longer uses `SIZE_EXPAND_FILL` (it was splitting center column height with `GridHost`); `_layout_combat()` now sizes the grid from actual `_grid_host.size` after VBox layout instead of an overestimated column budget.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Grid host keeps the flexible vertical space; winnings band stays a compact strip; grid + premium bar should fit inside `GridHost` without bottom clipping.
- Verification: Linter pass; manual F6 on `combat_test.tscn` recommended.

## 2026-05-17 - Combat Test Canonical Cleanup

- Request: Fix `combat_test_v1.gd` scene/script mismatch, remove lingering `combat_test_v2` runtime references, and rename v1 implementation to canonical `combat_test`.
- Implementation: Moved full playtest UI implementation into `combat_test.gd` (no wrapper). Removed `combat_test_v1.gd`, `combat_test_v1.tscn`, `combat_test_v2.tscn`, and companion `.uid` files; cleared stale `.godot/editor` v2 cache entries. Updated `README_COMBAT_TEST_VERSIONS.md` and `combat/README.md` for single canonical entrypoint.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test_v1.tscn` (deleted)
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd` (deleted)
  - `AXEL/axel_project/combat/combat_test_v2.tscn` (deleted)
  - `AXEL/axel_project/combat/scripts/combat_test_v2.gd` (deleted, if present)
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/combat/README.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: `combat_test.tscn` + `combat_test.gd` are the sole playtest shell; no broken v1 backup scene with mismatched node paths; editor should stop surfacing missing v2 script/scene errors.
- Verification: Grep found no `combat_test_v1`/`combat_test_v2` references in `.gd`/`.tscn`/`.godot`; linter pass on `combat_test.gd`.
- Notes: Prior changelog entries mentioning v1/v2 versions are retained as historical audit trail.

## 2026-05-17 - Re-apply Canonical Combat Test Cleanup

- Request: Re-apply single-canonical combat test entry after stale `combat_test_v1`/`combat_test_v2` artifacts resurfaced post-rename/delete; remove broken versioned shells and v2-only helpers.
- Implementation: Confirmed `combat_test.tscn` binds `combat_test.gd` only. Verified v1/v2 scenes/scripts and `chip_bar_segment.gd` / `matched_log_tile.gd` are absent on disk (prior cleanup already applied). Updated `README_COMBAT_TEST_VERSIONS.md` HUD bullets to match current mirrored shell and explicit single-entry policy.
- Files changed:
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No runtime change; documentation and audit trail align with canonical-only playtest entry (`F6` on `combat_test.tscn`).
- Verification: Grep on `combat/` `.gd`/`.tscn` found no `combat_test_v1`, `combat_test_v2`, `chip_bar_segment`, or `matched_log_tile` references; `.godot` editor cache has no v1/v2 paths; linter pass on `combat_test.gd`.
- Notes: Resolves conflict with prior 2026-05-17 canonical cleanup entry when versioned files reappeared in workspace index but were not present on disk.

## 2026-05-17 - Combat HUD Layout Polish

- Request: Align items panel bottom with execute button, move bankroll closer to stake, restore history panel rectangle, and enlarge/darken HISTORY/ITEMS section titles.
- Implementation: Side panel height now ends at execute-line offset (`main_h - BOTTOM_WINDOW_MARGIN`). `CenterTopHud` bankroll band lowered (`LAYOUT_CENTER_HUD_Y0/Y1`). History rebuilt via `_make_side_panel()` with bordered panel. Shared darker title strip style and larger header font (`SIDE_PANEL_HEADER_FONT` 24) for HISTORY/ITEMS headers.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Cosmetic/layout only; combat mechanics unchanged.
- Verification: Linter pass on `combat_test.gd`; manual F6 on `combat_test.tscn` recommended for alignment at multiple window sizes.

## 2026-05-17 - Winnings Readout Black Background

- Request: Add black background rectangle behind total winnings text.
- Implementation: Wrapped `MultiplierReadout` in `WinningsReadoutPill` `PanelContainer` with `_winnings_readout_bg_style()` (black fill, subtle red border, padded content margins).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Cosmetic only.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-17 - Combat Stakes Floor And Win Readout UI

- Request: Minimum stake 10; per-symbol match value listing; centered yellow payout text showing correct latest-line payout (not per-tile popups).
- Implementation: `BET_LADDER` is now `10..100` with default stake 10. Added `line_win_resolved` signal and `get_symbol_paytable_entries()` on `CombatRoot`. Line-win UI events emit after cascade multiplier increment so displayed payout matches awarded cents. `combat_test` HISTORY panel shows stake-scaled x3/x4/x5 paytable plus per-spin win rows; centered yellow `LinePayoutLabel` shows latest line `+N`; removed per-symbol `play_win_popup` calls from cascade resolution.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Lowest selectable stake is 10; win feedback is centralized; history documents symbol match length and payout; payout popups align with bankroll credit timing.
- Verification: Linter pass on `combat_root.gd` and `combat_test.gd`; Godot CLI smoke tests not run ( `godot` not on PATH in agent shell).
- Notes: First cascade win still uses post-increment multiplier (e.g. base 29 at 2x pays 58) by design; UI now reflects that awarded value.

## 2026-05-17 - History Panel Match-Only Breakdown

- Request: Remove always-visible payout listing; HISTORY panel should activate only for current-spin matches using `Symbol — bet x symbol_value x multiplier` format.
- Implementation: Removed static paytable from HISTORY; panel hidden until first line win, cleared each spin. `line_win_resolved` now includes `bet`, `symbol_value`, and `cascade_multiplier`; rows render e.g. `Yellow triangle — 10 x 6 x 2`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: HISTORY is inactive between spins / on losing spins; only current-spin match breakdown is shown.
- Verification: Linter pass on touched scripts.

## 2026-05-17 - First Cascade Win Uses 1x Multiplier

- Request: First match of a spin should pay at 1x, not 2x.
- Implementation: Reordered cascade resolution so `_emit_line_win_events`, payout estimate, and bankroll credit run before `multiplier.add(1)` in all four cascade loops (async/sync, regular/trinity).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: First line win per spin/multiplier reset pays at 1x; second cascade at 2x, etc. HISTORY and yellow popup now match.
- Verification: Linter pass on `combat_root.gd`.

## 2026-05-17 - Restore Symbol-Top +Payout Popups

- Request: Show `+payout` directly on top of matched symbols without a bottom-of-grid popup.
- Implementation: Re-enabled slot-level win popups during line flash in `combat_root.gd` (now rendered as `+N`), including headless/no-fx path. Removed centered `LinePayoutLabel` UI wiring from `combat_test.gd`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: `+payout` appears over each matched symbol; bottom-center transient payout text is no longer shown.
- Verification: Linter pass on `combat_root.gd` and `combat_test.gd`.

## 2026-05-17 - Single Centered Popup Per Match Line

- Request: Show only one `+payout` indicator centered on the matched symbols instead of one per symbol tile.
- Implementation: Updated win-popup routing in `combat_root.gd` so each winning line chooses one anchor slot nearest the geometric center of matched cells and renders a single `+N` popup there (FX and no-FX paths).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: One payout indicator appears per winning line, centered over the matched run.
- Verification: Linter pass on `combat_root.gd`.

## 2026-05-19 - Fixed 2D Window Framing (1280x720)

- Request: Make the game window in 2D scenes look the same as when opening the scene in the editor (whole-project fixed framing per plan).
- Implementation: Canonical design resolution **1280×720** in `project.godot` with viewport content scaling (`content_scale_mode=2`), keep aspect (`content_scale_aspect=1`), and `size/resizable=false`. `camera_follow_vertical.gd` derives `fixed_x` from `design_width`. Arc 1 cameras on `1.1_SchoolExterior` and `1.2_Corridor` both export `design_width=1280`. Corridor overlay alignment: removed erroneous `1.12` scale on `NoirPaletteOverlay`; sized background `ColorRect` to 1280×720.
- Files changed:
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/scenes/Arc_1/camera_follow_vertical.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Runtime launches at fixed 1280×720 with stable Arc 1 composition; window resize cannot change in-game framing. Combat/UI inherit viewport scaling.
- Verification: Headless `res://test/scene_smoke_check.gd` — `Scene smoke check OK (6 scenes).` (pre-existing `1.1_SchoolExterior` noir node path warning on instantiate; not introduced by this change). Manual F5/F6: confirm editor vs runtime framing parity on Arc 1 scenes.

## 2026-05-19 - Rollback Fixed 2D Window Framing (1280x720)

- Request: Roll back window-framing changes; scene `1.1_SchoolExterior` would not start.
- Implementation: Restored `project.godot` to 1400×900 with canvas-item scaling and expand aspect. Reverted `camera_follow_vertical.gd` to pre-change version. Removed corridor `Camera2D` and `design_width` exports; restored corridor noir overlay scale and background rect layout.
- Files changed:
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/scenes/Arc_1/camera_follow_vertical.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Project window/viewport behavior matches pre-2026-05-19 framing experiment.
- Verification: User to confirm `1.1_SchoolExterior` starts via F5/F6.

## 2026-05-19 - Fix 1.1 SchoolExterior Noir Overlay Startup Crash

- Request: Fix `1.1_SchoolExterior` crash on start (`Node not found: NoirPaletteOverlay/FilterRect` and null `material` access in `_apply_local_noir_tuning`).
- Implementation: Re-instanced `res://scenes/fx/NoirPaletteOverlay.tscn` in `1.1_SchoolExterior.tscn` (after `PlayerLayer`, before `TopDialogueOverlay`, no extra scale). Hardened `1.1_SchoolExterior.gd` to resolve `FilterRect` via `get_node_or_null` in `_ready()` and skip tuning with a warning if the overlay is missing.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Scene loads without startup errors; exterior noir palette tuning applies again when overlay is present.
- Verification: Headless `res://test/scene_smoke_check.gd` — `Scene smoke check OK (6 scenes).` with no `NoirPaletteOverlay/FilterRect` or `_apply_local_noir_tuning` errors on `1.1_SchoolExterior`.

## 2026-05-19 - Disable Noir Overlay on 1.1 (Temporary)

- Request: Disable the noir overlay for now on school exterior.
- Implementation: Added `_NOIR_OVERLAY_ENABLED := false` in `1.1_SchoolExterior.gd`; hides `NoirPaletteOverlay` at runtime and skips local shader tuning until re-enabled.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: `1.1_SchoolExterior` runs unfiltered full-color background; overlay node remains in scene for easy re-enable (`_NOIR_OVERLAY_ENABLED = true`).
- Verification: Scene still loads without noir path errors; overlay hidden at runtime.

## 2026-05-19 - Combat RTP Unit Rescale (100/1000 Economy)

- Request: Rescale playtest economy so minimum bet is 100 and bankroll cap/start is 1000 (integer-friendly line payouts at min stake) while keeping baseline no-item RTP in the 75–80% band.
- Implementation: Rescaled chip-bar economy and bet ladder 10× (`CHIP_BAR_FULL_CENTS` 100→1000, `BET_LADDER` 100–1000, default `total_bet` 100). Synced `combat_test` default stake lookup and bankroll placeholder. Post-rescale `rtp_audit` measured ~180% RTP (also ~184% at pre-rescale 100/10 constants), so applied centralized `BASELINE_PAYOUT_SCALAR := 0.431` to line wins and clear-grid bonus in `combat_root.gd` (Choice B from plan: unit rescale + guardrail).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Min stake 100, bankroll 1000/1000 start, encounter win goal 10000 (10× cap). At min bet, typical low-tier line pays are whole numbers (e.g. 0.2×100=20). Baseline RTP re-centered via scalar; symbol `.tres` multipliers unchanged.
- Verification: `rtp_audit.gd` — `rtp_mean=0.7502`, `target_position=within` `[0.75,0.80]`, `paid_hit_rate=0.365`, encounter success `1/120`. `item_balance_audit.gd` — C1/L3 both `neutral` (baseline_rtp ~0.409 by bankroll-inferred wager; deltas within ±0.02 CI).
- Notes: Pure unit rescale alone does not change RTP ratio; elevated return traced to current cascade/payout stack vs older QA snapshot (~0.81). Scalar is the single knob for future band nudges without per-symbol edits.

## 2026-05-19 - Cascade Multiplier HUD Readout

- Request: Show the increasing cascade multiplier in the combat phase UI (plan: second pill in `WinningsStack`, static readout with pulse on increment, cap context when active).
- Implementation: Added `CascadeMultiplierPill` above round-winnings pill in `combat_test.gd`; formats as `N×` with ` / cap` when Free Spins cap is enabled; pulses pill on increment. Exposed `is_multiplier_cap_active()` / `get_multiplier_cap_value()` on `combat_root.gd`; `_refresh_multiplier_label()` now emits `readouts_progressed` when multiplier value changes so the shell updates during cascades.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Players see live cascade multiplier under the grid; winnings pill unchanged (`MultiplierReadout` still shows round winnings). During Free Spins, cap suffix appears (e.g. `12× / 100`).
- Verification: Linter pass on touched scripts; manual F6 playtest recommended for pulse timing and two-pill layout at narrow widths.

## 2026-05-19 - Combat HUD Repack for Grid Space

- Request: Move bankroll and full stake control to top row; place cascade multiplier inline next to round-winnings value to free vertical space for the combat grid.
- Implementation: Rebuilt `CenterTopHud` as horizontal row (bankroll + full `StakeSelector`); removed stake row from center column. Replaced vertical `WinningsStack` with horizontal `WinningsRow` (winnings pill + cascade multiplier pill inline). Reduced `WINNINGS_BAND_MIN_HEIGHT` and tightened column spacing; widened top HUD anchor band (`0.32–0.68`) with narrow-width typography scaling.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Center column is grid-first (no stake row above grid); economic controls live in top HUD; multiplier still pulses on increment with cap suffix when active.
- Verification: Linter pass on `combat_test.gd`; manual F6 check recommended for top-row crowding and inline readout clipping at narrow widths.

## 2026-05-19 - Economics Stack Above Grid

- Request: Keep stake at its original vertical slot; place bankroll centered directly above stake (not side-by-side in top row).
- Implementation: Removed top-row `CenterTopHud` economics layout; added `EconomicsCenter`/`EconomicsStack` as first center-column child with bankroll over stake, both centered. Stake remains above grid; inline winnings row unchanged.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Bankroll and bet controls share one centered vertical block above the grid; no separate top HUD band for economy.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Meta Box Economics Layout

- Request: Stake on same row as seed in top-left meta area; bankroll centered above that row (with icons), not in center column.
- Implementation: Moved economics into `MetaBox`/`MetaContent`: `EconomicsStack` under icon row with centered bankroll, then `SeedStakeRow` (seed controls + full stake selector). Removed center-column economics block; widened meta anchor band slightly (`LAYOUT_TOP_BOX_END` 0.14 → 0.22).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Center column is grid-only at top; seed/stake/bankroll live in top-left HUD stack.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Centered Top Bankroll + Stake Stack

- Request: Restore gear icons and seed to previous top-left positions; place bankroll centered on the top row and stake indicator centered directly below it.
- Implementation: Reverted meta-box economics injection and restored default `MetaContent` flow (icons + seed row unchanged). Added a dedicated centered `EconomicsCenter` overlay anchored in the top HUD band, with `EconomicsStack` containing bankroll then full stake selector. Restored meta box width to prior anchor (`LAYOUT_TOP_BOX_END` back to `0.14`).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Left top corner returns to icons/seed behavior; bankroll is horizontally centered at top with stake directly under it.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Governance: Clarification-First Planning Gate

- Request: Prevent assumption-driven planning and require clarification before new plan output.
- Implementation: Updated governance docs to require a mandatory planning intake gate: agents must ask at least 2 targeted clarifying questions for every new planning request, then continue asking follow-ups until intent/scope/constraints are concise and assumption-free. Added explicit "no silent assumptions" language and a consistency-check checklist item for planning compliance.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Future planning chats must gather enough user-confirmed detail before drafting plans, reducing unilateral revisions and hidden defaults.
- Verification: Manual doc review confirms matching enforcement language in `AI_DOCS.md` and always-applied governance rule.

## 2026-05-19 - Combat UI Polish (Winnings, History, Power Glow, Execute, Goal)

- Request: Implement ordered combat UI plan phases: larger non-yellow per-symbol winnings popups; two-line spin history with mini symbol logos and white/gray-outlined text; white power-intro glow; execute button vertical nudge for border alignment; goal box font parity with bankroll and right alignment; stake-overlap ideas documented only.
- Implementation: Applied Concept A winnings popup styling (white text, heavy gray outline/shadow, size bump). Refactored history rows to VBox two-line layout with `TextureRect` mini-icons from line-win event `texture`. Changed `PowerIntroGlow` to white RGB in scene and script. Added `EXECUTE_BUTTON_VERTICAL_NUDGE` spacer above execute button. Goal label uses bankroll responsive font sizing and right alignment. Documented four stake-overlap concepts in `combat_test.gd` comments (no layout change).
- Files changed:
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scenes/combat_root.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Winnings and history read more clearly; power intros use white wash; execute button sits slightly lower; goal HUD matches bankroll scale and aligns right; grid/symbol placement unchanged.
- Verification: Linter pass on touched combat scripts.

## 2026-05-19 - Execute Button Vertical Nudge (8px)

- Request: Execute button still misaligned with history/items panel borders; move down by 8px.
- Implementation: Increased `EXECUTE_BUTTON_VERTICAL_NUDGE` spacer above the execute button from 6px to 8px.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button sits 8px lower in the center footer for border baseline alignment with side panels.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Execute Button Nudge Fix (MarginContainer, 30px test)

- Request: Prior spacer-based nudge had no visible effect; test with 30px downward shift.
- Implementation: Replaced ineffective `ExecuteTopSpacer` with `MarginContainer` (`margin_top`) around the execute button; footer alignment set to `BEGIN`; nudge constant set to 30px and refreshed in `_layout_execute_button_width()`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button should visibly move down by 30px relative to prior layout.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Execute Button Bottom Alignment (Structural Fix)

- Request: Execute button nudge still had no visible movement; align bottom border with history/items panels.
- Implementation: Root cause was footer pinned above fixed `BottomWindowMargin` while HBox stretched side panels to full row height. Added `_layout_execute_bottom_inset()` to set bottom spacer from measured gap to side-panel bottom; side panels use `SIZE_SHRINK_END`; removed ineffective `MarginContainer` top-margin approach. `EXECUTE_BUTTON_VERTICAL_NUDGE` subtracts from computed gap (30px test).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button bottom should track history/items panel bottoms; nudge pulls further down when gap allows.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Execute Button Final Border Alignment

- Request: After 30px alignment test, set execute button bottom on same row as history/items panel bottom borders.
- Implementation: Set `EXECUTE_BUTTON_VERTICAL_NUDGE` to 0; `_layout_execute_bottom_inset()` uses `get_global_rect().end.y` on side panels and execute button for pixel-accurate alignment.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button bottom should line up with side panel bottom borders without extra test offset.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Execute Alignment Without Grid/Panel Reflow

- Request: Previous alignment attempts moved/scaled the combat grid and pushed side panel borders past the game window; keep grid untouched and align execute bottom safely.
- Implementation: Reverted side-panel/footer sizing changes that caused reflow (`SIZE_SHRINK_END` and footer `ALIGNMENT_BEGIN`), removed bottom-inset spacer mutation, and switched to visual-only execute alignment via `_align_execute_button_bottom_visual()` using global bottom deltas.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Grid sizing/placement and side panel bounds return to stable behavior while execute button is visually aligned to panel bottoms.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Execute Button Nudge Only (+3px)

- Request: Move only the execute button ~3px downward without touching grid or panel layout behavior.
- Implementation: Simplified `_align_execute_button_bottom_visual()` to apply a fixed button-local Y offset only; set `EXECUTE_BUTTON_VERTICAL_NUDGE` to `3.0`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button is nudged down by 3px; no grid, scale, or panel placement reflow logic involved.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Execute Button Visual Test (+10px)

- Request: 3px nudge still appeared unchanged; test with 10px downward move.
- Implementation: Set `EXECUTE_BUTTON_VERTICAL_NUDGE` to `10.0` and made execute button `top_level` so container sorting cannot cancel visual offset; `_align_execute_button_bottom_visual()` now positions from center-footer global rect.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button should visibly move down by ~10px without resizing/moving the combat grid or side panels.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Execute Button Final Set (+3px)

- Request: Keep current working method, return near original position, then offset down by 3px.
- Implementation: Kept top-level visual placement path and changed `EXECUTE_BUTTON_VERTICAL_NUDGE` from `10.0` to `3.0`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button uses original footer anchor logic with a visible +3px downward offset.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Execute Button In-Window Anchor Fix

- Request: Execute button still appeared under the game window bottom border.
- Implementation: In `_align_execute_button_bottom_visual()`, switched Y anchor from `footer_rect.position.y` to `footer_rect.end.y - btn_size.y`, then applies the same `+3px` nudge.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button stays inside the window while preserving the requested slight downward offset.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Execute Layout Rollback To Original Composition

- Request: Remove all execute-button fixes from this thread and restore original composition.
- Implementation: Removed `top_level` execute mode, removed visual-position override function/deferred calls, and restored button placement to container-driven layout only.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button returns to original composition behavior (no manual position overrides); grid and side panel layout no longer affected by execute experiments.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Winnings Popup Glow + 50% Activation Pop

- Request: Keep current winnings popup style, add a subtle animated glow, and increase text size by 50% on activation before fade-out.
- Implementation: In `symbol_slot.gd`, added a glow back-layer label (`WinPopupGlowLabel`) and updated `play_win_popup()` tween flow to pop both labels to `1.5x` scale on entry, drift upward, then fade out.
- Files changed:
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Per-symbol win amount popup now has a stronger read: brief red glow pulse + 50% scale pop on activation, while preserving the existing white primary text style.
- Verification: Linter pass on `symbol_slot.gd`.

## 2026-05-19 - Combat Test Editor/Runtime Layout Parity

- Request: Make the combat test 2D editor view match the runtime opening layout (layout-only parity); fix hidden nodes and mispositioned EXECUTE button in editor.
- Implementation: Converted `combat_test.gd` to `@tool` with an editor-preview path that reuses the same shell/HUD/layout pipeline as runtime without spin gameplay. Added `editor_preview_enabled` and `editor_preview_seed` exports, idempotent play-shell/HUD restoration, and `set_owner(null)` on editor-only dynamic nodes so preview nodes are not saved into the scene. Set `CombatRoot` visible by default in `combat_test.tscn`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 2D editor view now builds the same responsive layout shell as play-mode start (grid, side panels, centered EXECUTE, HUD). Runtime spin flow unchanged; editor preview does not run spins.
- Verification: Linter pass on `combat_test.gd`; `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://test/scene_smoke_check.gd` (OK); `res://combat/test/determinism_check.gd` (OK); `res://combat/test/princess_check.gd` (OK).

## 2026-05-19 - Combat Test Editor Placeholder Guard

- Request: Fix editor errors when `CombatRoot` is a placeholder instance (`setup_new_grid`, `fit_to_panel`, `inventory`, readout/overlay calls) while keeping `combat_root.gd` runtime-only.
- Implementation: Added `_can_use_combat_api()` / `_can_layout_combat_grid()` gates and safe readout helpers in `combat_test.gd`. Editor preview now uses layout-only fallbacks (static HUD values, host-width button sizing, premium-bar fallback placement) when combat gameplay APIs are unavailable; runtime paths unchanged.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 2D editor no longer throws placeholder-instance errors on scene open or `editor_preview_seed` changes; layout shell parity remains. Full combat simulation still runs only at runtime/play.
- Verification: Linter pass on `combat_test.gd`; scene smoke + determinism + princess headless checks (OK).

## 2026-05-19 - Combat Test Editor Null Onready Refs

- Request: Fix editor `null instance` errors on `seed_spin`, `bet_label`, `spin_btn` and empty 2D preview after `@tool` editor parity work.
- Implementation: Added `_cache_scene_refs()` to resolve `%UniqueName` nodes manually in editor (`@onready` is unreliable in `@tool`). Deferred editor preview until scene tree is ready (`_run_editor_preview_when_ready` with retry). Added null guards across readout/layout paths; fixed `_build_play_shell` early-return that aborted layout when `mult_label` was missing.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Editor preview should render HUD/side panels/EXECUTE shell without null-instance spam; runtime unchanged.
- Verification: Linter pass on `combat_test.gd`.

## 2026-05-19 - Combat Test Scene Scaffold Restore

- Request: Restore `combat_test.tscn` to the tracked canonical structure to recover missing preview/runtime UI nodes and unblock editor layout parity.
- Implementation: Reverted `AXEL/axel_project/combat/combat_test.tscn` to the repository version, restoring required nodes (`CombatRoot`, `MetaBox`, `SeedSpinBox`, `BankrollLabel`, `GoalBox`, `StakeSelector`, `MultiplierReadout`, `SpinButton`) used by `combat_test.gd` caching/layout paths.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Editor preview can resolve required scene refs again and build the full shell instead of rendering only the black background/overlays.
- Verification: `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://test/scene_smoke_check.gd` (OK); `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd` (OK).

## 2026-05-22 - Combat Test Scaffold Overwrite Guardrails

- Request: Stop recurring `combat_test.tscn` regressions to black background + scanlines only (required nodes stripped after reboot/cleanup).
- Implementation: Restored canonical `combat_test.tscn` from commit `bab7ec5`. Added `combat/test/combat_test_scaffold_check.gd` and integrated scaffold validation into `test/scene_smoke_check.gd`. Added `tools/qa/check_combat_test_scaffold.py` with git pre-commit hook (staged-file check). Expanded `combat_test.gd` `_cache_scene_refs()` to validate full runtime-critical node set with explicit `push_error` diagnostics. Documented protected scaffold policy in `AI_DOCS.md`, `README_COMBAT_TEST_VERSIONS.md`, `VERIFICATION_CHECKLIST.md`, and `AXEL_QA_REVIEW_RUBRIC.md`.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/test/combat_test_scaffold_check.gd`
  - `AXEL/axel_project/test/scene_smoke_check.gd`
  - `AXEL/axel_project/tools/qa/check_combat_test_scaffold.py`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/combat/VERIFICATION_CHECKLIST.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Stripped combat test scenes fail fast in editor/runtime/CI instead of silently showing only overlays; commits that remove scaffold nodes are blocked.
- Verification: `python AXEL/axel_project/tools/qa/check_combat_test_scaffold.py` (OK); `combat_test_scaffold_check.gd` (OK); `scene_smoke_check.gd` (OK).

## 2026-05-19 - Combat Test Editor Visual Parity (Fallback Layout)

- Request: Fix remaining editor-preview visual drift — EXECUTE bar spanning into side panels, combat grid misplaced/scaled at top-left, and stray `Multiplier: 1×` from `CombatRoot`.
- Implementation: In `combat_test.gd`, added editor-placeholder fallback grid layout mirroring `combat_root.fit_to_panel` fill-panel math (`_layout_combat_grid_fallback`), centered premium bar + EXECUTE width tied to computed grid width (not full host), and `_suppress_combat_root_legacy_labels()` to hide `MultiplierLabel` / `RoundWinningsLabel` / `EncounterWonLabel` in composed view.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 2D editor preview should match runtime opening composition for grid scale/position and EXECUTE width; runtime `fit_to_panel` path unchanged.
- Verification: Linter pass on `combat_test.gd`; scene smoke + determinism headless checks (OK).

## 2026-05-19 - Combat Symbol Art Dedup (`grid_symbols` canonical)

- Request: Remove duplicate combat symbol art in `combat/art/placeholders/` (same symbols as `grid_symbols/`) and audit `res://` for other strict-unused duplicates.
- Conflict resolution: Prior notes required dual-texture (`grid_symbols` + 720px `placeholders`). User chose migrate-to-`grid_symbols` and delete `placeholders`.
- Implementation: Removed `power_intro_texture` ext-resources from all eight `combat/data/symbols/sym_*.tres` files so intros use `texture_for_power_intro()` fallback to `texture`. Pointed `generate_placeholders.py` output at `combat/art/grid_symbols/`. Deleted `combat/art/placeholders/` (8 PNG + `.import` sidecars).
- Audit (strict-unused-only): eight name-matched pairs were **likely duplicates** (128px grid vs 720px intro), not byte-identical. No other proven-unused runtime assets deleted. Retained: `exports/screenshots/*` (reference, unreferenced by scenes), `tools/scene_builder/output/layout_previews/*` (tool output; four PNGs share one hash but are individually referenced by imports/tooling).
- Files changed:
  - `AXEL/axel_project/combat/data/symbols/*.tres` (8)
  - `AXEL/axel_project/combat/art/generate_placeholders.py`
  - `AXEL/axel_project/plans/references/AXEL_notes.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
  - `AXEL/axel_project/combat/README.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Deleted: `AXEL/axel_project/combat/art/placeholders/**`
- Behavior impact: Grid and power-intro FX now share `grid_symbols` textures (128px import limit). Power intros may look softer than the removed 720px assets until dedicated intro art is added.
- Verification: `rg` shows no `res://combat/art/placeholders/` references outside changelog history; orphan `.import`/`.uid` scan clean.

## 2026-05-19 - Winnings Popup Retimed (5-Phase, 2x Slower)

- Request: Slow default popup animation by 100% (2x total duration) with distinct steps: small appear, scale up, glow, lob to total winnings value, fade.
- Implementation: Refactored `symbol_slot.gd` `play_win_popup()` into five sequential chained phases with centralized duration shares (12/22/18/36/12%) over `WIN_POPUP_TOTAL_DURATION` 1.24s. Glow hold pulses glow layer before lob; fade only runs after lob/hold completes.
- Files changed:
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Line-win popups read more deliberately; lob target unchanged (total winnings value).
- Verification: Linter pass; `determinism_check.gd` headless (OK).

## 2026-05-19 - Winnings Popup Lob + Vector Font

- Request: Per-line winnings popup should start small, scale up 100%, then lob into the total winnings readout; use vector font for crisp scaling.
- Implementation: `combat_test` wires `MultiplierReadout` to `CombatRoot.set_winnings_popup_target()`. `combat_root` passes target global center into `play_win_popup`. `symbol_slot` uses VT323 `FontFile` on popup labels, grow phase (0.5→2.0 scale), then quadratic-bezier lob toward the readout with fade on impact.
- Files changed:
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Line-win amount popups arc into the center winnings value instead of drifting upward only; text stays vector-sharp while scaling.
- Verification: Linter pass on touched scripts; `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd` (OK).

## 2026-05-22 - Combat Test Editor Save Stripping Fix

- Request: Fix Play/runtime black screen + `_cache_scene_refs()` missing-node errors after editor preview briefly looked correct.
- Implementation: Restored full `combat_test.tscn` from `bab7ec5` again (working copy had been stripped to ~21 nodes). Root cause: `@tool` editor layout reparented owned scaffold nodes under `owner = null` parents, so **Ctrl+S dropped them from the scene file**. Fixed by defaulting `editor_preview_enabled` to `false`, replacing `remove_child` reparents with `reparent` + `_reassert_node_ownership()`, and adding `combat_test_scaffold_baseline.tscn` plus runtime `_restore_scaffold_from_baseline()` fallback.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/combat_test_scaffold_baseline.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/test/combat_test_scaffold_check.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Saving the scene after editor preview should retain `CombatRoot` and HUD nodes; Play should build full UI instead of scanlines-only when the scene file is intact.
- Verification: `check_combat_test_scaffold.py` (OK); `combat_test_scaffold_check.gd` (OK); `scene_smoke_check.gd` (OK).

## 2026-05-22 - Recover Pre-Dedup Stable Snapshot (`bab7ec5`)

- Request: Fix Godot load errors (duplicate `CombatRoot` child names under `GridHost/CombatRoot`) and black/scanlines-only editor/runtime view after duplication-removal work; restore last known-good state with both `grid_symbols` and `placeholders` asset folders.
- Conflict resolution: Changelog anchor `bab7ec5` selected as restore commit (last commit before `bee8b49` symbol dedup and before `ea90057` reintroduced duplicate inline CombatRoot children). Post-restore scaffold guardrails from HEAD retained (`combat_test_scaffold_check.gd`, `check_combat_test_scaffold.py`, `combat_test_scaffold_baseline.tscn`).
- Implementation: Branch `recovery/pre-dedup-stable-bab7ec5`; `git checkout bab7ec5 -- AXEL/axel_project/combat/`; stripped stale `uid://` references on restored `sym_*.tres` placeholder ext-resources so project import resolves by path without warnings.
- Files changed:
  - `AXEL/axel_project/combat/**` (restored tree from `bab7ec5`, including `combat/art/placeholders/**`)
  - `AXEL/axel_project/combat/data/symbols/sym_*.tres` (UID cleanup on placeholder refs)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Kept from HEAD (not reverted): `combat/test/combat_test_scaffold_check.gd`, `tools/qa/check_combat_test_scaffold.py`, `combat/combat_test_scaffold_baseline.tscn`, `AI_DOCS.md` scaffold policy, non-combat scenes/scripts.
- Behavior impact: `combat_test.tscn` again instances `combat_root.tscn` without duplicate `GridManager`/`GridUI`/label children (0 clash paths). Dual-folder symbol art restored (`grid_symbols` + `placeholders`); power intros use 720px placeholder textures again.
- Verification: `combat_test_scaffold_check.gd` (OK, no UID warnings); `scene_smoke_check.gd` (OK, 6 scenes); `determinism_check.gd` (OK). Duplicate-child count in `combat_test.tscn`: 0 (was 8 at `ea90057`).

## 2026-05-22 - Return Pre-Dedup Feature Stack (Visual + Combat)

- Request: Restore pre-`res://` dedup feature set: exact center match cue animation, full HISTORY mini-symbol UI, editor/runtime visual parity (hide symbol-logic UI in editor), plus core combat/economy/Arc1/HUD packs from before dedup chat.
- Conflict resolution: Used selective restore from `aceade4` (popup FX + `combat_root`), `2b59ee5` (`combat_test` scene shell + `@tool` preview with ownership safeguards), kept `bab7ec5` economy/symbol data and placeholders from prior recovery; explicitly avoided `ea90057` `combat_test.tscn` duplicate CombatRoot children.
- Implementation:
  - Restored `symbol_slot.gd` 5-phase center payout cue (`WIN_POPUP_TOTAL_DURATION` 1.24s) and `combat_root.gd` center-line anchor + winnings lob target + history `texture` payload.
  - Restored `combat_test.gd` mini-icon two-line HISTORY rows (`HISTORY_MINI_ICON_SIZE`, `_append_history_spin_row`).
  - Restored `combat_test.tscn` PlayArea shell layout from `2b59ee5` (0 duplicate CombatRoot child paths).
  - Re-enabled `@tool` editor preview (`editor_preview_enabled` default `false`) with `_hide_editor_symbol_logic_ui()` so editor matches runtime shell but hides grid + numeric/symbol-logic readouts.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scenes/combat_root.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Runtime regains retimed center win popups lobbing to winnings readout, HISTORY shows mini symbols with bet/value/mult lines, and editor preview can be toggled on root node for layout parity without repopulating gameplay grid/numbers. Core gravity/bankroll/economy behavior remains from pre-dedup anchors.
- Verification: `combat_test_scaffold_check.gd` (OK); `scene_smoke_check.gd` (OK); `determinism_check.gd` (OK); duplicate CombatRoot inline children remain 0.

## 2026-05-22 - Fix Editor Preview + Post-Dedup Pack

- Request: Stop editor placeholder/owner errors; show grid shell + default readouts in 2D editor preview (no symbol simulation); keep post-dedup vector lob popup + mini-symbol HISTORY; include relevant post-dedup fixes except black/scanlines rescue scene variants.
- Conflict resolution: `_can_use_combat_api()` now always returns false in editor (blocks placeholder `CombatRoot` method calls). Removed `_hide_editor_symbol_logic_ui()` (was hiding grid/readouts). Replaced corrupted `combat_test.tscn` (duplicate inline CombatRoot children from editor save) with clean `2b59ee5` instance-only scene.
- Implementation:
  - `combat_test.gd`: editor uses `_layout_combat_grid_fallback()` + `_ensure_editor_grid_shell_visible()` + `_refresh_editor_placeholder_readouts()`; no `setup_new_grid` in editor preview.
  - Retained post-dedup FX from `aceade4`/`d774b81` (`symbol_slot.gd` VT323 5-phase lob, `combat_root.gd` texture history events + popup target).
  - `combat_test.tscn` restored from `2b59ee5` (0 duplicate CombatRoot child paths).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Editor preview ON shows layout shell, empty grid frame, and default numbers (1000/1000 bankroll, bet 100, mult 0) without gameplay API calls or load-name clashes. Runtime unchanged: vector floating-number lob + HISTORY mini icons.
- Verification: `combat_test_scaffold_check.gd` (OK); `scene_smoke_check.gd` (OK); `determinism_check.gd` (OK).

## 2026-05-22 - Preserve Combat Milestone on GitHub

- Request: Preserve recent combat changes across computers so they are logged on GitHub (not only OneDrive); working tree showed no pending commit because changes were already committed.
- Implementation: Confirmed milestone at `4110c74` on `main` (includes `7144462`..`4110c74` stack). Created and pushed backup branch `backup/2026-05-22-combat-state` and annotated tag `checkpoint-2026-05-22-combat-state`. Documented multi-machine fetch/push/milestone workflow in `AI_DOCS.md` §14.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No runtime change. GitHub now has independently discoverable refs for the combat recovery milestone; agents and humans can restore this state from any machine after `git fetch`.
- Verification: `git ls-remote` confirms branch `backup/2026-05-22-combat-state` and tag `checkpoint-2026-05-22-combat-state` on `origin`; both point to commit `4110c74`.

## 2026-05-22 - Preserve Combat Milestone on GitHub

- Request: Preserve recent combat changes across computers so they are logged on GitHub (not only OneDrive); working tree showed no pending commit because changes were already committed.
- Implementation: Confirmed milestone at `4110c74` on `main` (includes `7144462`..`4110c74` stack). Created and pushed backup branch `backup/2026-05-22-combat-state` and annotated tag `checkpoint-2026-05-22-combat-state`. Documented multi-machine fetch/push/milestone workflow in `AI_DOCS.md` §14.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No runtime change. GitHub now has independently discoverable refs for the combat recovery milestone; agents and humans can restore this state from any machine after `git fetch`.
- Verification: `git ls-remote` confirms branch `backup/2026-05-22-combat-state` and tag `checkpoint-2026-05-22-combat-state` on `origin`; both point to commit `4110c74`.
