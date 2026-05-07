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
