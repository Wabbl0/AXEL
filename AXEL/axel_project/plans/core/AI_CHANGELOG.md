# AXEL AI Changelog

Append-only history for implemented AI-requested changes.

## Logging Policy

- Log entries only when a requested change is actually implemented.
- Do not log pure discussion, planning-only chats, or declined requests.
- Add new entries at the bottom under the correct **`## YYYY-MM-DD`** day section (ISO 8601, zero-padded). Create a new day section if needed.
- Do not edit older entries except to add a correction note as a new entry.
- **Primary history:** git commits. Append here when the user says `update docs` or at end of a substantive implement session.
- Older agent-governance entries remain below; canon workflow lives in `AI_DOCS.md` (lean, ~60 lines).

## Entry Template

Copy and fill:

```md
## YYYY-MM-DD

### Short Request Title

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

## 2026-05-06

### Create Persistent AI Docs System
- Request: Create persistent AI docs that unify plans, style/lore sources, exports (including moon princess files), engine logic context, and include a future implemented-changes changelog workflow.
- Implementation: Added canonical AI governance docs and rule wiring for always-on consistency across AXEL work.
- Files changed:
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
- Behavior impact: Future agent chats can consistently align with project canon and will append implemented changes to this changelog.
- Verification: Confirmed files created with cross-references and clear hierarchy/changelog procedure.
- Notes: Exported Moon Princess assets are documented as reference-only unless explicitly promoted.

### Require Live Progress Feed
- Request: Add a persistent rule so chats expose live execution progress (what is running, checked/read, and whether stuck).
- Implementation: Updated AXEL governance rule and canonical AI docs workflow to require a live progress feed for long or multi-step tasks, including a fixed status checklist.
- Files changed:
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Future AXEL task chats should provide clearer runtime visibility and progress transparency during execution.
- Verification: Verified both governance documents now explicitly include the live progress feed requirement and status fields.
- Notes: No source-hierarchy conflict; requirement was added consistently to both always-on rule and canonical docs.

### Reorganize commands, logs, and sprites
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

### Add AXEL structure taxonomy and scaffolding
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

## 2026-05-07

### Remove OAF and PixelLab Pipeline Artifacts
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

### Add Combat RTP Audit Harness
- Request: Audit current no-item combat RTP/win frequency against a 75-80% target and identify why winnings feel too frequent/easy.
- Implementation: Added per-spin telemetry exposure in combat orchestration (line payout vs clear-bonus payout) and created a deterministic headless Monte Carlo audit runner that reports RTP, hit rate, encounter success, and confidence intervals.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/test/rtp_audit.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Combat runtime behavior is unchanged for players; developers can now run repeatable RTP audits and attribute payout sources precisely.
- Verification: Executed `Godot_v4.6.2-stable_win64_console.exe --path AXEL/axel_project --headless -s res://combat/test/rtp_audit.gd` and captured JSON metrics from the run.
- Notes: RTP baseline measured far above target in this sample; follow-up balance tuning should focus first on line payout scale and multiplier growth effects before item-based difficulty layering.

### Baseline RTP Frequency Rebalance (Constrained Knobs)
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

### Paytable Reduction to 75-80 RTP
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

### Corridor Locker Noir Pass
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

### Scene Builder Agent Draft Pipeline
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

### Scene Builder Governance + Multi-Folder Asset Analysis
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

### Canonical Agent Alias: scene agent
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

### Simulated QA Reviewer workflow
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

### Canonical QA Alias Names
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

## 2026-05-08

### Corridor Canonical Filename Guard
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

### Corridor 1.2 Locker Row, Graffiti, Player Overlay
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

### Corridor Graffiti Filter Selection (Variant 05)
- Request: Apply the selected graffiti preview filter (fifth option, palette-crush) to the active corridor mascot wall graphic.
- Implementation: Promoted `graffiti_preview_05_palette_crush.png` from preview outputs into the live asset path by overwriting `corridor_christmas_graffiti_85.png`, preserving the existing scene texture reference.
- Files changed:
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Wall mascot now uses the selected subdued palette treatment, reducing floating/sticker-like contrast against corridor wall tones.
- Verification: Confirmed replacement copy completed to the live `res://assets/props/graffiti/` texture path used by `1.2_Corridor.tscn`.
- Notes: `.import` sidecar path remains unchanged; Godot will refresh imported cache content on next scene/project load.

### Corridor Graffiti Variant 05 Rebased To Monkey Source
- Request: Use option 1 after review: keep the Variant 05 palette-crush look but apply it to the original monkey graffiti source so wall graffiti reads as a full decal instead of sparse red dots.
- Implementation: Re-generated `corridor_christmas_graffiti_85.png` from `graffiti_monkey_deformed.png` using the same Variant 05 quantize/desaturate/darken recipe; preserved the existing live scene reference path.
- Files changed:
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor graffiti keeps subdued palette integration while restoring the full monkey silhouette and wall-presence read.
- Verification: Checked resulting live asset dimensions/alpha bounds are now `96x48` with monkey-shaped coverage (`bbox (8, 10, 85, 47)`), matching original silhouette footprint.
- Notes: No scene path updates required because `1.2_Corridor.tscn` already references `corridor_christmas_graffiti_85.png`.

### Corridor Graffiti Source Correction (Use User PNG)
- Request: Keep the user-provided replacement PNG as the graffiti source (not monkey geometry) and apply the selected Variant 05 filter on that asset.
- Implementation: Restored `corridor_christmas_graffiti_85.png` from the user-provided Christmas PNG path and re-applied the Variant 05 palette-crush recipe directly to that file.
- Files changed:
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor graffiti now uses the intended replacement geometry/shape with the selected subdued filter treatment.
- Verification: Confirmed live asset after filtering is `64x96` with alpha coverage `bbox (2, 15, 59, 75)`, matching the replacement PNG footprint rather than monkey source dimensions.
- Notes: `1.2_Corridor.tscn` texture reference remains unchanged and continues to target `corridor_christmas_graffiti_85.png`.

### Corridor Graffiti Opacity + Midtone Recovery
- Request: Address remaining red-blob look from interaction between local graffiti filter and corridor noir post-process, with a focus on higher opacity.
- Implementation: Reprocessed `corridor_christmas_graffiti_85.png` using a gentler palette crush (`8` colors, milder desaturation, near-neutral brightness) and restored full opaque alpha on all non-transparent pixels.
- Files changed:
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Graffiti keeps the replacement geometry while retaining more visible structure through the noir filter; non-transparent pixels no longer fade out from reduced alpha.
- Verification: Confirmed output remains `64x96`, alpha coverage unchanged (`bbox (2, 15, 59, 75)`), and alpha range now spans full opacity (`0..255`).
- Notes: If detail still collapses under scene noir thresholds, next step is to exempt `MonkeyGraffiti` from the full-screen noir layer (CanvasLayer above overlay) or tweak shader thresholds globally.

### Corridor Graffiti Filter Removed (Original Replacement Restored)
- Request: Remove all applied filter processing from corridor graffiti and use the original user-provided replacement PNG as-is.
- Implementation: Overwrote `corridor_christmas_graffiti_85.png` with the original source file from the provided external path, discarding prior palette/opacity processing passes.
- Files changed:
  - `AXEL/axel_project/assets/props/graffiti/corridor_christmas_graffiti_85.png`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor now renders the raw replacement graffiti art without additional local filter transformations.
- Verification: Confirmed live file replacement completed and asset remains loadable (`64x96`, alpha range `0..255`).
- Notes: Scene reference remains unchanged (`1.2_Corridor.tscn` still points to `corridor_christmas_graffiti_85.png`).

### Corridor 1.2 Locker + Wall Collision (Invisible Borders)
- Request: Add invisible borders so the player cannot walk through lockers or wall edges in Corridor 1.2.
- Implementation: Added `LockerColliders` under the scene root with one `StaticBody2D` + `CollisionShape2D` per locker sprite (`Locker01`–`Locker10` and `HighlightedLocker`), using a shared `RectangleShape2D` (`100x130`) centered at each locker’s X and `y = 387` so the block covers the locker lower/front band into the walkable floor (sprite-only collision at `y ≈ 274` does not intersect the player at `y ≈ 520`). Existing `TopWall` / `BottomWall` / `LeftWall` / `RightWall` `StaticBody2D` colliders left unchanged after review.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Player `CharacterBody2D` should now slide against locker fronts when moving toward the row; perimeter walls remain blocked as before.
- Verification: Confirmed scene structure and locker X alignment match `LockerRow`; default spawn `Player` at `(640, 520)` lies outside locker block AABB (`y ≈ 322–452`). In-editor run recommended: **Debug → Visible Collision Shapes** and walk-test along the row.
- Notes: If you add or move lockers in the editor, duplicate/reposition matching `LockerBlock*` nodes or widen the shared rectangle resource.

### Corridor Collision Simplification (Single Upper Block)
- Request: Remove individual locker colliders and replace with one large collision shape, starting from `y = -140` offset, so the player cannot walk on the wall zone.
- Implementation: Replaced per-locker `StaticBody2D` nodes under `LockerColliders` with a single `UpperWallBlock` using `CollisionShape2D` + `RectangleShape2D_upper_block` (`1280x90`) and shape offset `position = Vector2(0, -140)`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: A continuous blocker now spans corridor width near the locker/wall boundary, preventing entry into upper wall space and simplifying maintenance versus per-locker colliders.
- Verification: Confirmed `LockerColliders/UpperWallBlock` exists with requested `y` offset and full-width rectangle shape in scene file.
- Notes: Fine-tune by adjusting `RectangleShape2D_upper_block` height or `UpperWallBlock` base `position.y` if you want a tighter/looser walkable lane.

### Highlighted Locker Artifact Fix (No Animation/Filter)
- Request: Revert highlighted locker to original look, remove custom highlight filtering/animation behavior, and keep it only subtly darker while validating against the global noir filter so locker holes do not fill with black artifacts.
- Implementation: Removed highlighted-locker script modulation logic from `1.2_Corridor.gd` (no locker-specific runtime effects remain). Set `HighlightedLocker` to static scene-level `modulate = Color(0.78, 1, 1, 1)` in `1.2_Corridor.tscn`, which keeps original texture details while slightly darkening red.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker remains visually close to neighboring lockers, with reduced red intensity but without the black line/fill artifacts seen under the noir pass.
- Verification: Simulated noir threshold mapping against `locker_single_48.png` variants before applying; exact 25% red reduction (`0.75`) produced clipping artifacts, while `0.78` preserved hole/readability details in the mapped output.
- Notes: Because the full-scene noir pass quantizes luminance, exact 25% red reduction crosses the black threshold on some locker pixels.

### Highlighted Locker Threshold Tuning
- Request: Fix persistent black-fill artifacts in highlighted locker while keeping it darker than normal.
- Implementation: Tuned `HighlightedLocker` static modulate from `Color(0.78, 1, 1, 1)` to `Color(0.8, 1, 1, 1)` in `1.2_Corridor.tscn` to stay above noir threshold clipping for the locker interior details.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker remains subtly darker than neighbors but avoids hole/vent regions collapsing to black blobs under the global noir filter.
- Verification: Change targets the measured threshold edge where `0.75` clips and `0.8` stays in non-black bins in noir mapping.
- Notes: Exact 25% channel darken is incompatible with current noir thresholds for this texture; if exact 25% is mandatory, the locker must be rendered outside the noir pass or shader thresholds adjusted.

### Highlighted Locker Excluded From Global Noir
- Request: Exclude highlighted locker from global noir filter and apply a similar but slightly darker local treatment to avoid repeated black artifact blobs.
- Implementation: Hid in-row `LockerRow/HighlightedLocker` sprite and added `HighlightedLockerBypassLayer` (`CanvasLayer` layer 95) with `HighlightedLockerBypass` sprite rendered above `NoirPaletteOverlay` (layer 90). Added a local palette shader `highlighted_locker_palette_filter.gdshader` with noir-like thresholds/colors tuned slightly darker than baseline.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/fx/highlighted_locker_palette_filter.gdshader`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker remains stylistically consistent with scene palette but no longer passes through the full-screen noir quantization that caused vent/hole fill artifacts.
- Verification: Confirmed scene wiring places bypass locker on layer 95 (between global overlay and player layer), with original row highlight hidden.
- Notes: Since bypass uses `CanvasLayer`, keep its position/scale synced if locker layout changes in future scene edits.

### Highlighted Locker Local Filter Darkened 33%
- Request: Make the highlighted locker local filter even darker by 33%.
- Implementation: Added a `darken_factor` uniform to `highlighted_locker_palette_filter.gdshader` and applied it to mapped output (`COLOR.rgb = mapped.rgb * darken_factor`) with default value `0.67`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/highlighted_locker_palette_filter.gdshader`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker keeps the same local palette mapping but renders 33% darker overall while still bypassing global noir artifacts.
- Verification: Shader compiles structurally with unchanged thresholds/palette branches; only final output intensity scaling changed.
- Notes: You can tune darkness quickly by adjusting `darken_factor` in the material inspector.

### Scene Builder Output Cleanup + Completion Rule
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

### QA Agent Concise Output + Playtest Mode
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

### Premium-to-Auto Planning Guardrails
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

### Canonical Scene Placeholder Rollout
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

### Fix Godot Launcher Path + Re-run Scene Smoke
- Request: Run the pending scene smoke verification and fix `godot.cmd` launcher path (possibly still pointing at old location/version).
- Implementation: Corrected `tools/cmd/godot.cmd` root resolution from `tools/` to repo root so it launches the existing `Godot_v4.6.2-stable_win64.exe`, then reran the headless scene smoke command.
- Files changed:
  - `tools/cmd/godot.cmd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Repo-local `tools/cmd/godot.cmd` now resolves the Godot executable correctly and can run project verification scripts again.
- Verification: Ran `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://test/scene_smoke_check.gd`; result `Scene smoke check OK (6 scenes).`
- Notes: Version is `4.6.2` (not `4.6.1`); failure source was incorrect relative root path in the wrapper script.

### QA Persistent Analytics + Trend Graph Pipeline
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

### Corridor canonical recovery + Christmas graffiti
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

### Reapply Lost Corridor Layout/Layer/Collision Tuning
- Request: Reapply previously lost corridor settings: tuned locker scale/placement, player scale and render layer above noir/floor, and a full-width upper wall collision border.
- Implementation: Updated `1.2_Corridor.tscn` locker row to the prior tuned layout (`Locker01`..`Locker10` from `x=167` to `x=1134`, `y=274`, `scale=Vector2(2.06, 2.06)`), restored player render isolation via `PlayerLayer` (`CanvasLayer`, `layer=100`, `follow_viewport_enabled=true`) and moved `Player` under it with `scale=Vector2(2.06, 2.06)` and `speed=371.0`, and restored a single full-width upper blocker (`RectangleShape2D_upper_block` + `UpperWallBlock` with collision shape offset `Vector2(0, -140)`).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor locker composition and traversal feel are back to the tuned version, player now consistently renders above noir overlay/floor-space conflicts, and the upper wall lane is blocked by one maintainable collision border.
- Verification: Confirmed all restored node/property signatures in scene file (`Locker10`, `scale=2.06`, `PlayerLayer layer=100`, `follow_viewport_enabled`, `UpperWallBlock`, `RectangleShape2D_upper_block`, `speed=371.0`); scene smoke check rerun after patch.
- Notes: Root cause was canonical recovery being based on a stale legacy `Corridor.tscn` snapshot that lacked later tuning edits; keeping canonical scene as sole edit target plus pre-migration diff checks prevents recurrence.

### Locker Nearest Filtering + Highlight Noir Bypass Restore
- Request: Ensure all locker textures use nearest filtering (not inherit) and implement highlighted-locker exclusion from global noir with its own darker local filter.
- Implementation: Set explicit `texture_filter = 1` (nearest) on all locker sprites (`Locker01..Locker10` and `HighlightedLocker`). Restored highlighted-locker bypass wiring by hiding in-row `HighlightedLocker`, adding `HighlightedLockerBypassLayer` (`CanvasLayer layer=95`) with `HighlightedLockerBypass` sprite using `ShaderMaterial_highlighted_locker_local`, and binding `res://scenes/fx/highlighted_locker_palette_filter.gdshader` (`darken_factor = 0.67`) so it renders above global noir (`layer=90`) but below player layer (`layer=100`).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Locker art now consistently renders with nearest filtering; highlighted locker is no longer quantized by global noir and instead uses the dedicated darker local palette filter.
- Verification: Confirmed nearest filter flags and bypass nodes/material in scene file; ran headless scene smoke check `res://test/scene_smoke_check.gd` (OK 6 scenes).
- Notes: This restores the previously intended two-path render model (global noir for scene + local filtered highlighted locker bypass).

### Restore SchoolExterior Full Layout Without Timer/Key Gating
- Request: Revert `1.1_SchoolExterior` from generated empty placeholder to the older full scene with tilemaps/placeholders/player, but leave out timer, key pickup, and key-based door-unlock flow.
- Implementation: Restored the pre-placeholder full scene layout baseline (tilemap plants/road layers, environment placeholder polygons, world bounds, player setup, noir overlay) and removed gameplay-gating/UI wiring by stripping `GameController.gd` from root plus deleting `KeyArea`, `ExitArea`, `MemoryPickupArea`, and the full HUD/timer/objective/inventory/message/dialogue panel tree from `1.1_SchoolExterior.tscn`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Scene 1.1 is no longer an empty placeholder and again contains legacy visual layout + controllable player, without timer UI or key-required exit logic.
- Verification: Ran headless `res://test/scene_smoke_check.gd` (reports `Scene smoke check OK (6 scenes)`).
- Notes: The “empty scene” state came from placeholder regeneration that overwrote canonical scene content; this restore keeps canonical filename while restoring non-placeholder geometry/content.

### Arc 1 Top Dialogue Overlay (1.1 + 1.2)
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

### Scene 1.1 Noir Occlusion Layer Fix
- Request: Fix scene `1.1` noir filter behavior where visuals behind the overlay appeared hidden/overpowered.
- Implementation: Added `PlayerLayer` (`CanvasLayer`, `layer = 100`, `follow_viewport_enabled = true`) in `1.1_SchoolExterior.tscn` and reparented `Player` plus child nodes under `PlayerLayer/Player`, preserving existing player transform/speed/sprite settings. Kept `NoirPaletteOverlay` unchanged on its existing layer (`90`).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Scene world content continues through the global noir pass, while player readability is restored by rendering above the noir overlay layer model (matching corridor strategy).
- Verification: Ran headless `res://test/scene_smoke_check.gd` via `Godot_v4.6.2-stable_win64_console.exe`; output reports `Scene smoke check OK (6 scenes)`.
- Notes: Root cause was render-order mismatch (`z_index` on world node cannot outrank noir `CanvasLayer`), not shader threshold logic.

### Noir Palette Threshold Retune (Option A)
- Request: Keep the global noir overlay approach but reduce scene-black crush in exploration (starting with `1.1`) by retuning the existing shader defaults.
- Implementation: Retuned `noir_palette_filter.gdshader` defaults to reduce the black bucket and lift dark-red mapping: `dark_blood_color` `0.290 -> 0.36`, `t0` `0.22 -> 0.08`, `t1` `0.45 -> 0.30`, `t2` `0.74 -> 0.62`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/noir_palette_filter.gdshader`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: More low/mid luminance pixels map to dark-blood/blood-red bands instead of black, preserving silhouette/readability while keeping the same 4-band noir style pipeline.
- Verification: Ran headless `res://test/scene_smoke_check.gd` via `Godot_v4.6.2-stable_win64_console.exe`; output reports `Scene smoke check OK (6 scenes)`.
- Notes: This is a global shader default update (affects all scenes using `NoirPaletteOverlay`), intended as the first-pass calibration before any scene-specific local bypasses.

### Top dialogue: VT323, typewriter, black/white bar
- Request: Implement Arc 1 dialogue box upgrade: more impactful presentation, VT323, animated typewriter text, black panel with white text, keep non-blocking movement; retain `1.1` two-line timing and `1.2` spawn line only.
- Implementation: Updated `TopDialogueOverlay.tscn` with `StyleBoxFlat` black panel, dark-blood `1px` border (AXEL accent), white label text with black outline, and `VT323-Regular` from `combat/ui/fonts/`. Extended `TopDialogueOverlay.gd` with per-character typewriter after fade-in, optional **Tab** skip (`allow_skip` defaults true), then existing hold + fade-out; still uses `CanvasLayer` 110 and ignores mouse on all controls. Arc `1.1` / `1.2` scripts unchanged (`show_line(text, hold_duration)` only).
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Top narration reads as CRT-terminal style (white on black) with typewriter pacing; player movement and physics remain unlocked; Tab skips to full line during typing only.
- Verification: `ReadLints` on `TopDialogueOverlay.gd` (clean); headless `res://test/scene_smoke_check.gd` → `Scene smoke check OK (6 scenes).` (pre-existing tile load warnings from `1.1_SchoolExterior` tilemap unrelated to overlay).
- Notes: Canon resolution — narrative strip uses **white body text** per request; red stays as thin panel border only (`#4a0000`-aligned dark blood), consistent with `AI_DOCS.md` palette hierarchy.

### Scene 1.1 School Exterior Collision Boundary Alignment
- Request: Note the Scene `1.1` collision edits: moved the left-side collision border to match the school exterior polygon so the player cannot walk through the school, and set polygon coverage across the full right side of the scene.
- Implementation: Recorded the geometry/collision intent for `1.1_SchoolExterior` as a boundary-alignment pass to keep traversal constrained to valid walkable space and prevent clipping through school geometry.
- Files changed:
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Player movement in Scene `1.1` should now be blocked along the aligned left school edge and across the fully covered right-side polygon boundary.
- Verification: Changelog-only documentation update based on user-confirmed scene edit details.
- Notes: No source-hierarchy conflict; this entry documents the canonical numbered scene boundary update (`1.1_SchoolExterior`).

### Scene 1.1 Door Marker + Third Intro Dialogue Line
- Request: Place a white rectangular polygon at the school exterior/path boundary as a visible "door" marker, and restore the missing third intro dialogue iteration (`"pathetic"`).
- Implementation: Added `1.1_School_Door_Boundary_01` (`Polygon2D`, white rectangle) under `1.1_EnvironmentPlaceholders` aligned with the school door area at the path boundary, and extended `1.1_SchoolExterior.gd` intro flow with a third `TopDialogueOverlay.show_line("pathetic.", ...)` call after a short pause.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Scene `1.1` now visually indicates the school entry threshold using a white rectangular door marker, and intro dialogue sequence now runs in three beats instead of two.
- Verification: IDE lint check reports no errors in `1.1_SchoolExterior.gd`.
- Notes: Door marker is currently visual-only (`Polygon2D`); if you want it to also enforce collision at that exact rectangle, we can add a matching `StaticBody2D` + `CollisionShape2D`.

### Scene 1.1 Door Collision Matches Door Polygon
- Request: Place a collision boundary for `school_building_doors_01` exactly matching the door.
- Implementation: Added `1.1_School_Building_Doors_01_Collision` (`StaticBody2D`) under `1.1_EnvironmentPlaceholders` with `position = Vector2(-66, 13)` and a child `CollisionPolygon2D` using the same polygon points as `1.1_School_Building_Doors_01` (`1035,305` `1115,305` `1115,430` `1035,430`), so collision footprint matches door geometry 1:1.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Player can no longer pass through the door polygon area; collision now aligns exactly with the visual door placement.
- Verification: Scene-file structural check confirms matching position and polygon values between door visual node and collision node.
- Notes: No canon/source-hierarchy conflict; update targets canonical scene `1.1_SchoolExterior.tscn`.

### Scene 1.1 Door Interaction To Corridor Transition
- Request: Make the school door boundary interactable so when the player is close and presses interaction (`E`, `Space`, or `Enter`), they are teleported to the corridor scene.
- Implementation: Added door-proximity trigger `1.1_School_Building_Doors_01_InteractArea` (`Area2D`) reusing the same transform and polygon as `1.1_School_Building_Doors_01`. Extended `1.1_SchoolExterior.gd` with `_unhandled_input` key handling (`KEY_E`, `KEY_SPACE`, `KEY_ENTER`, `KEY_KP_ENTER`), overlap check against the player body via `get_overlapping_bodies()`, and guarded scene transition to `res://scenes/Arc_1/1.2_Corridor.tscn` using `change_scene_to_file`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Door area now supports explicit interaction-based progression from Scene `1.1` to Scene `1.2` rather than passive traversal alone.
- Verification: `ReadLints` reports no errors in `1.1_SchoolExterior.gd` after adding interaction logic.
- Notes: Transition is proximity-gated and one-shot guarded (`_is_transitioning`) to prevent duplicate scene-change calls on repeated keypress events.

### Dialogue overlay: bottom center + viewport padding
- Request: Position the dialogue box at the bottom center of the window with a small gap above the bottom edge.
- Implementation: Re-anchored `RootMargin` in `TopDialogueOverlay.tscn` from top-wide (`anchors_preset` 10) to bottom-wide (`12`): full width with `28px` side insets, `24px` offset above the bottom edge (`offset_bottom = -24`), bar height via `offset_top = -128`; inner `MarginContainer` theme margins cleared because spacing now comes from anchors. Updated script header comment to describe a bottom-centered bar.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Dialogue reads as a bottom cinematic bar on every scene that instances the overlay; horizontal alignment stays centered via full-width strip + centered label text.
- Verification: Headless `res://test/scene_smoke_check.gd` → `Scene smoke check OK (6 scenes).`
- Notes: Filename `TopDialogueOverlay` unchanged to avoid breaking instances; visual placement is now bottom-centered.

### Scene 1.2 Local Noir White-Balance Guardrail
- Request: Fix Scene `1.2` over-bright whites caused by the prior `NoirPaletteOverlay` retune, while avoiding broad cross-scene drift.
- Implementation: Applied Option B (scene-local override) in `1.2_Corridor.gd` by targeting `NoirPaletteOverlay/FilterRect` material at runtime and overriding shader uniforms for Scene `1.2` only: raised white-threshold cutoff (`t2 = 0.72`) and softened peak white mapping (`white_color = Color(0.93, 0.93, 0.93, 1.0)`).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Corridor lockers/graffiti/debris retain noir quantization but fewer mid-bright texels collapse to pure white, improving detail retention in Scene `1.2` without changing Scene `1.1` global grading.
- Verification: `ReadLints` reports no errors in `1.2_Corridor.gd`; repository search confirms only `1.2_Corridor.gd` now sets local `t2` and `white_color` overrides while `1.1_SchoolExterior.tscn` continues using the shared overlay instance unchanged.
- Notes: Canon-aligned with AXEL palette intent (controlled white highlights); this is a contained scene calibration with no global shader default edits.

### QA Default Upgraded To Combined Static + Playtest
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

### Option 1 Global Noir Rebalance Trial (Revert-Safe)
- Request: Implement Option 1 global white-balance trial so Scene `1.1` and `1.2` can be tested together, with a guaranteed path back to the current baseline state.
- Implementation: Created rollback anchors before edits (`rollback/option1-baseline-20260508-2038` branch pointer and `option1-baseline-20260508-2038` tag), then switched to `test/noir-option1-global` and tuned only `noir_palette_filter.gdshader` for first-pass global trial: `t2` `0.62 -> 0.72` and `white_color` `vec4(1.0,1.0,1.0,1.0) -> vec4(0.95,0.95,0.95,1.0)`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/noir_palette_filter.gdshader`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Global overlay now routes fewer mid-high luminance texels into the white bucket, reducing white clipping pressure across scenes that instance `NoirPaletteOverlay` (including `1.1` and `1.2`).
- Verification: `ReadLints` reports no shader lint errors; `git diff` confirms only the two intended uniform changes in `noir_palette_filter.gdshader`; validation criteria for user pass: (1) `1.2` locker vents/panel seams retain detail, (2) `1.2` graffiti no longer blooms as clipped white patch, (3) `1.1` door marker remains readable without harsh clipping, (4) `1.1` background separation remains intact.
- Notes: Trial is intentionally kept active on `test/noir-option1-global` for user testing; one-step baseline restore remains available via `git switch main` (or `git switch rollback/option1-baseline-20260508-2038`).

### Option 1 Test Unmasked In Scene 1.2
- Request: Make Option 1 global test visibly affect Scene `1.2` after user observed no practical difference.
- Implementation: Added a simple scene flag in `1.2_Corridor.gd` and disabled the local corridor override during this trial (`_USE_LOCAL_NOIR_TUNING := false`), so Scene `1.2` now reads global `noir_palette_filter.gdshader` uniforms directly.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Scene `1.2` no longer masks global palette-tuning with local `t2/white_color` values, enabling a true Option 1 side-by-side read against Scene `1.1`.
- Verification: `ReadLints` reports no errors in `1.2_Corridor.gd`; `_ready()` now gates `_apply_local_noir_tuning()` behind a disabled constant.
- Notes: Re-enable prior local behavior by setting `_USE_LOCAL_NOIR_TUNING := true` after trial if needed.

### Scene 1.2 Locker Detail Recovery via Bypass Layer
- Request: Replace ineffective global-threshold trial with a stronger Scene `1.2` approach that preserves locker vent/panel detail.
- Implementation: Added a full `LockerBypassLayer` (`CanvasLayer`, layer `95`) and moved visible locker rendering to bypass sprites (`Locker01Bypass..Locker10Bypass` + `HighlightedLockerBypass`) using a shared locker-local shader material. Hid original in-row lockers (`Locker01..Locker10` and `HighlightedLocker`) to prevent duplicate rendering under the global overlay. Introduced new shader `locker_palette_filter.gdshader` with noir-adjacent palette mapping plus controlled luminance variation (`detail_strength`) to preserve micro-contrast in locker linework.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/fx/locker_palette_filter.gdshader`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Scene `1.2` locker art now bypasses destructive full-screen quantization while still receiving a local noir-style grade; vent slots and panel outlines are expected to remain legible at play distance without introducing player-layer conflicts.
- Verification: `ReadLints` reports no diagnostics for touched scene/script/shader paths; scene diff confirms bypass nodes preserve original locker transforms and highlighted locker now uses the same shader family as the rest of the row with no duplicate visible sources.
- Notes: This is intentionally scene-scoped (`1.2` only) to contain drift; rollback remains low-risk by reverting `1.2_Corridor.tscn` and `locker_palette_filter.gdshader` on the current trial branch.

### Scene 1.2 Highlighted Locker Faint Glow Restore
- Request: Restore visible emphasis for the highlighted locker after bypass normalization by adding a faint glow.
- Implementation: Extended `locker_palette_filter.gdshader` with a `glow_strength` uniform and a soft luminance-gated glow term (`smoothstep(t1, t2, lum)`) so glow is constrained to brighter locker tones. In `1.2_Corridor.tscn`, kept base lockers on `ShaderMaterial_locker_local` (`glow_strength = 0.0`) and assigned `HighlightedLockerBypass` a dedicated `ShaderMaterial_highlighted_locker_glow` with subtle boost (`glow_strength = 0.12`) plus slightly lifted detail/darken tuning.
- Files changed:
  - `AXEL/axel_project/scenes/fx/locker_palette_filter.gdshader`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker regains faint visual emphasis while remaining stylistically aligned with the bypass locker row and avoiding strong bloom spill.
- Verification: `ReadLints` reports no diagnostics for touched shader/scene files.

### Highlighted Locker Glow Fallback Pulse (Runtime)
- Request: Re-apply highlighted locker emphasis after user reported no visible glow change during live playtesting.
- Implementation: Added a runtime fallback pulse in `1.2_Corridor.gd` that directly animates `LockerBypassLayer/HighlightedLockerBypass` each frame (`modulate` tint + tiny scale breathing), independent of shader hot-reload/material cache behavior. New toggles: `_USE_HIGHLIGHT_PULSE` (enabled) and `_update_highlight_pulse()` driven by `_flicker_time`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker now has an unmistakable but still faint animated glow/readability cue even if shader-only glow path is not visually updating in a live session.
- Verification: `ReadLints` reports no diagnostics for `1.2_Corridor.gd`.

### Highlighted Locker Standout Boost (Additive Aura)
- Request: Make highlighted locker stand out more because faint pulse motion was visible but no white glow separation was perceived.
- Implementation: Added `HighlightedLockerAura` sprite behind `HighlightedLockerBypass` in `1.2_Corridor.tscn` using `CanvasItemMaterial` additive blending (`blend_mode = 1`), larger base scale, and white-tinted alpha. Extended runtime pulse in `1.2_Corridor.gd` to animate both locker and aura: increased highlight tint range, slightly stronger locker scale pulse, and independent aura alpha/scale pulse for a clearer white halo read.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Highlighted locker now has explicit white-glow separation from the rest of the locker row while preserving noir tone and avoiding full-screen bloom.
- Verification: `ReadLints` reports no diagnostics for touched scene/script files.

## 2026-05-10

### Playtest cyan collision debug overlay (global)
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

### Overworld Real-Input Playthrough Bots (`bot playthrough`)
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

### Default QA Includes Bot Playthrough
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

### QA Analytics: Bots Aggregate Series On Trend SVG
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

### Combat item catalog: single-file edits only
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

### AXEL_COMBAT_ITEM_CATALOG_PLAN under axel_project/plans
- Request: Save the combat item list plan under `AXEL/axel_project/plans/` as well as the Cursor plan mirror.
- Implementation: Added [AXEL/axel_project/plans/AXEL_COMBAT_ITEM_CATALOG_PLAN.md](AXEL/axel_project/plans/AXEL_COMBAT_ITEM_CATALOG_PLAN.md) as the repo-canonical copy (relative links into combat scripts, note that Cursor plan may mirror). Updated [AXEL/axel_project/plans/AI_DOCS.md](AXEL/axel_project/plans/AI_DOCS.md) §5 reference to point at this path first.
- Files changed:
  - `AXEL/axel_project/plans/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Design documentation only; agents should prefer the `axel_project/plans` file over the Cursor-only plan path.
- Verification: File present with full 75-item catalog content.
- Notes: Optional next step: add one-line pointer in `.cursor/plans/combat_starter_item_catalog_fee3a6f1.plan.md` to the canonical file (not done unless user wants strict two-way sync).

### Combat item catalog plan + AI_DOCS item conventions
- Request: Use uppercase extended ids (`C-A`, `C-B`, …); remember that “add an item” defaults to five rarities; add sealed-grid (no top spawn) + payout items; add optional True-path passives that inflate encounter goal % and gate True Ending; persist convention for future chats.
- Implementation: Rewrote `.cursor/plans/combat_starter_item_catalog_fee3a6f1.plan.md` to **75** entries (30 baseline + **45** extended across nine family lanes **A–F, M, G, H** × five rarities). Documented **family G** (no top refill on base-game regular spins, payout trade) and **family H** (goal penalty passives + True Ending meta hook). Added **Combat item catalog (agent convention)** under `AI_DOCS.md` §5 with uppercase id pattern and default five-tier item specs.
- Files changed:
  - `.cursor/plans/combat_starter_item_catalog_fee3a6f1.plan.md`
  - `AXEL/axel_project/plans/AI_DOCS.md`
  - `AXEL/axel_project/plans/AI_CHANGELOG.md`
- Behavior impact: Design/agent guidance only; no gameplay code. Future “add an item” combat requests should assume **Common→Legendary** unless scoped narrower; extended ids documented as `TIER-FAMILY`.
- Verification: Manual read-back of plan structure (counts 19/17/15/13/11 per tier = 75 total).
- Notes: True Ending exact gate (`L-H` only vs full `*-H` set) left as implementation/design choice in the plan.

## 2026-05-11

### QA Agent Item-Bot Extension (Combat Balance Audit)
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

### Item System Infrastructure + C1 Ash Reroll Token
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

### Fix item_balance_audit.gd Unused Variable Warnings
- Request: Resolve the 4 linter warnings (UNUSED_VARIABLE) in `item_balance_audit.gd`.
- Implementation: Surfaced the four accumulated-but-unreturned locals (`total_wager_cents`, `total_payout_cents`, `free_spins`, `free_hit_spins`) in the `_run_item_audit()` return dictionary as additive fields, matching the parallel coverage in `_run_baseline()`.
- Files changed:
  - `AXEL/axel_project/combat/test/item_balance_audit.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Per-item metrics in `ITEM_BALANCE_JSON` output now include wager/payout totals and free spin counts; no behavioral change to Monte Carlo loops or classification logic.
- Verification: `ReadLints` reports 0 warnings/errors for `item_balance_audit.gd` after the fix.
- Notes: Additive-only schema change; existing downstream consumers (QA analytics parser) ignore unknown keys and are unaffected.

### Dynamic Inventory Capacity, Legendary Slot-Expander, Dev Picker UX, Synergy Tests, C1 Balance Tuning
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

### Chat Efficiency: Cursorignore, Governance Dedup, Progress Feed Policy
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

### Medium-Impact Workflow Optimizations (M1/M2/M3)
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

### Low-Maintenance Workflow Fixes (path alignment, QA archival, debug cleanup)
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

### Exports Cleanup Migration
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

### Separate collision debug: editor-only colors, no runtime overlay
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

### Noir shader bypass for collision debug colors
- Request: Collision shapes still appeared red in the editor because the `NoirPaletteOverlay` screen-texture shader (layer 90) remaps all pixels to the AXEL 4-color palette, converting cyan debug shapes to blood red.
- Implementation: Added a cool-hue bypass at the top of `noir_palette_filter.gdshader`. Any pixel where `min(G, B) - R > 0.04` passes through unmodified. Since the AXEL game palette is strictly warm (red/black/white), cool-colored pixels can only come from editor debug overlays.
- Files changed:
  - `AXEL/axel_project/scenes/fx/noir_palette_filter.gdshader`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Cyan collision shapes now display correctly in the 2D editor viewport instead of being palette-mapped to red. No visual change to game content at runtime since no game art produces cool-hued pixels.
- Verification: Confirmed `locker_palette_filter.gdshader` and `highlighted_locker_palette_filter.gdshader` use `TEXTURE` (not `screen_texture`) and do not need the bypass.
- Notes: Superseded by the runtime-only noir guard below — cool-hue bypass has been removed.

### Runtime-only noir overlay (fix editor whiteout)
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

### Scene 1.1 Background Swap (Drawing Replaces Placeholder Visuals)
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

### Scene 1.1 Upgrade: Camera, Colliders, Noir Tuning, Scanline, Style Options
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

### Overworld: White Player, Stabilized TV Noise Overlay, Layer Fix
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

### Scene 1.1 Visibility Polish: White Player, Scale, Noise Reduction, Line Preservation
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

## 2026-05-17

### Fix Combat Seed, Spin Log, and Trinity Gravity
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

### Remove In-Round Symbol Refills (Universal Gravity-Only Cascades)
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

### Bankroll Encounter Cap + Readout Cleanup
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

### Trinity/Super FS Fresh-Grid Handoff Override
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

### Surreal Combat UI + Chip-Bar Win Logic
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

### Combat Test v1/v2 Version Split
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

### Default Combat Test v1 + Remove v2 Shell
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

### Combat Test v1 Layout + Premium Meter Fix
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

### Combat Cohesion + Canon Alignment (mirrored shell, integer economy)
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

### Combat Test Frame Layout Fix
- Request: Fix misaligned combat grid and side rectangles clustered/overlapping EXECUTE in play window.
- Implementation: CombatFrame now uses top-left positioning with top/bottom safe margins (HUD + EXECUTE), deferred layout after first frame, expanded play-row size flags, centered `fit_to_panel` with bottom inset for premium bar, shrink-locked side panels.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mirrored shell should center in viewport; grid and ITEMS/SPIN HISTORY panels align; EXECUTE no longer covers play area.
- Verification: Manual F6 on `combat_test.tscn` recommended.
- Notes: Legacy `PremiumMeterCircle` nodes kept hidden in scenes for UID stability.

### Playtest Economy And Main Scene Layout Spec
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

### Playtest HUD Corner Box And Bankroll Spacing Fix
- Request: Top-left/right meta and GOAL boxes were clipped off-screen; bankroll should sit directly above stake with less gap.
- Implementation: Reparented corner boxes to the root viewport (they were sized as fractions of the 15%-tall `TopBar`, which collapsed them). Stacked bankroll + stake in a tight `CenterTopHud` `VBoxContainer` (`separation` 2px) with shared center anchoring.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Meta/GOAL boxes use full viewport insets (2%–22% / 78%–98%, ~11% height); `100/100` readout sits immediately above the stake row; main play area starts at 18% height.
- Verification: Linter pass on `combat_test_v1.gd`; manual F6 recommended.

### Combat Test HUD Layout Cleanup
- Request: Remove top-corner panel rectangles; tighten top-left icons (50% spacing, closer to corner, third icon `?`); horizontal centered SPINS title; larger side-panel fonts; thin red outline on premium progress bar; center `1X` between grid and EXECUTE; match EXECUTE width to grid; delete unused `combat_test_v2`.
- Implementation: Stripped `MetaBox`/`GoalBox` panel styles at runtime; tightened corner anchors and icon row separation; switched spin-history panel to horizontal `_make_side_panel("SPINS")`; bumped side-panel font constants; added 1px red border on premium bar background; added `MultiplierZone` expand spacers for centered multiplier readout; synced EXECUTE `custom_minimum_size.x` to `combat.grid_ui.size.x` after layout; updated `combat_test.tscn` icon defaults; removed `combat_test_v2.tscn` (v2 script already absent).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/combat_test_v2.tscn` (deleted)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Corner HUD boxes no longer draw red bordered rectangles; icons and goal text float in corners; SPINS/ITEMS panels use larger type with horizontal SPINS header; premium bar has red outline; multiplier sits between grid and EXECUTE; EXECUTE button width tracks grid width on resize.
- Verification: Linter pass on `combat_test_v1.gd`; Godot CLI not on PATH — manual F6 on `combat_test.tscn` recommended.

### Combat Test HUD Polish Follow-Up
- Request: Match gear icon to lightweight symbol style (`⬡`); lower top icon row ~1–2%; enlarge GOAL font; show round winnings as amount (no `X`) with +10% font and thin white outline; tighten grid/readout/EXECUTE spacing; shift play area down and grow grid.
- Implementation: Replaced gear glyph with `⬡` and unified icon font size; shifted corner band (`LAYOUT_CORNER_Y0`/`Y1`); increased `GOAL_LABEL_FONT`; wired `MultiplierReadout` to `combat.get_round_winnings()` with outline styling; removed expand spacers from winnings zone; reduced column/footer separation and EXECUTE height band; extended main play anchors (`LAYOUT_MAIN_Y0`/`END`) for larger grid host.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Top icons sit slightly lower with polygon home/question trio; GOAL text scales with icons; center readout shows integer winnings with white outline; vertical stack is denser and grid area is taller.
- Verification: Linter pass on `combat_test_v1.gd`; manual F6 on `combat_test.tscn` recommended.

### Combat HUD Spacing And History Panel
- Request: Center total winnings between premium meter and EXECUTE; reduce vertical dead space and grow grid; enlarge top-left icons 20%; replace left history rectangle with `HISTORY` title and empty placeholder.
- Implementation: Added `WinningsBand` with anchor-centered readout and `_layout_winnings_band()`; tightened main/center HUD vertical fractions and column separations; bumped `META_ICON_FONT` to 31 (+20%); replaced `_build_spin_history_placeholder()` with borderless `_build_history_placeholder()` (`HISTORY` + expand placeholder); `fit_to_panel()` now accepts `align_grid_top` (used by v1 shell) and v1 passes computed max grid height from column budget.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Winnings sit in the band between premium bar and EXECUTE; grid uses more vertical space with less internal letterboxing; left column is title-only history reserve; ITEMS panel unchanged.
- Verification: Linter pass on touched scripts (IDE may need refresh for new `fit_to_panel` arity); manual F6 on `combat_test.tscn` recommended.

### Combat Grid Bottom Clipping Fix
- Request: Combat grid bottom was cut off after HUD spacing pass.
- Implementation: `WinningsBand` no longer uses `SIZE_EXPAND_FILL` (it was splitting center column height with `GridHost`); `_layout_combat()` now sizes the grid from actual `_grid_host.size` after VBox layout instead of an overestimated column budget.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test_v1.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Grid host keeps the flexible vertical space; winnings band stays a compact strip; grid + premium bar should fit inside `GridHost` without bottom clipping.
- Verification: Linter pass; manual F6 on `combat_test.tscn` recommended.

### Combat Test Canonical Cleanup
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

### Re-apply Canonical Combat Test Cleanup
- Request: Re-apply single-canonical combat test entry after stale `combat_test_v1`/`combat_test_v2` artifacts resurfaced post-rename/delete; remove broken versioned shells and v2-only helpers.
- Implementation: Confirmed `combat_test.tscn` binds `combat_test.gd` only. Verified v1/v2 scenes/scripts and `chip_bar_segment.gd` / `matched_log_tile.gd` are absent on disk (prior cleanup already applied). Updated `README_COMBAT_TEST_VERSIONS.md` HUD bullets to match current mirrored shell and explicit single-entry policy.
- Files changed:
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No runtime change; documentation and audit trail align with canonical-only playtest entry (`F6` on `combat_test.tscn`).
- Verification: Grep on `combat/` `.gd`/`.tscn` found no `combat_test_v1`, `combat_test_v2`, `chip_bar_segment`, or `matched_log_tile` references; `.godot` editor cache has no v1/v2 paths; linter pass on `combat_test.gd`.
- Notes: Resolves conflict with prior 2026-05-17 canonical cleanup entry when versioned files reappeared in workspace index but were not present on disk.

### Combat HUD Layout Polish
- Request: Align items panel bottom with execute button, move bankroll closer to stake, restore history panel rectangle, and enlarge/darken HISTORY/ITEMS section titles.
- Implementation: Side panel height now ends at execute-line offset (`main_h - BOTTOM_WINDOW_MARGIN`). `CenterTopHud` bankroll band lowered (`LAYOUT_CENTER_HUD_Y0/Y1`). History rebuilt via `_make_side_panel()` with bordered panel. Shared darker title strip style and larger header font (`SIDE_PANEL_HEADER_FONT` 24) for HISTORY/ITEMS headers.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Cosmetic/layout only; combat mechanics unchanged.
- Verification: Linter pass on `combat_test.gd`; manual F6 on `combat_test.tscn` recommended for alignment at multiple window sizes.

### Winnings Readout Black Background
- Request: Add black background rectangle behind total winnings text.
- Implementation: Wrapped `MultiplierReadout` in `WinningsReadoutPill` `PanelContainer` with `_winnings_readout_bg_style()` (black fill, subtle red border, padded content margins).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Cosmetic only.
- Verification: Linter pass on `combat_test.gd`.

### Combat Stakes Floor And Win Readout UI
- Request: Minimum stake 10; per-symbol match value listing; centered yellow payout text showing correct latest-line payout (not per-tile popups).
- Implementation: `BET_LADDER` is now `10..100` with default stake 10. Added `line_win_resolved` signal and `get_symbol_paytable_entries()` on `CombatRoot`. Line-win UI events emit after cascade multiplier increment so displayed payout matches awarded cents. `combat_test` HISTORY panel shows stake-scaled x3/x4/x5 paytable plus per-spin win rows; centered yellow `LinePayoutLabel` shows latest line `+N`; removed per-symbol `play_win_popup` calls from cascade resolution.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Lowest selectable stake is 10; win feedback is centralized; history documents symbol match length and payout; payout popups align with bankroll credit timing.
- Verification: Linter pass on `combat_root.gd` and `combat_test.gd`; Godot CLI smoke tests not run ( `godot` not on PATH in agent shell).
- Notes: First cascade win still uses post-increment multiplier (e.g. base 29 at 2x pays 58) by design; UI now reflects that awarded value.

### History Panel Match-Only Breakdown
- Request: Remove always-visible payout listing; HISTORY panel should activate only for current-spin matches using `Symbol — bet x symbol_value x multiplier` format.
- Implementation: Removed static paytable from HISTORY; panel hidden until first line win, cleared each spin. `line_win_resolved` now includes `bet`, `symbol_value`, and `cascade_multiplier`; rows render e.g. `Yellow triangle — 10 x 6 x 2`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: HISTORY is inactive between spins / on losing spins; only current-spin match breakdown is shown.
- Verification: Linter pass on touched scripts.

### First Cascade Win Uses 1x Multiplier
- Request: First match of a spin should pay at 1x, not 2x.
- Implementation: Reordered cascade resolution so `_emit_line_win_events`, payout estimate, and bankroll credit run before `multiplier.add(1)` in all four cascade loops (async/sync, regular/trinity).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: First line win per spin/multiplier reset pays at 1x; second cascade at 2x, etc. HISTORY and yellow popup now match.
- Verification: Linter pass on `combat_root.gd`.

### Restore Symbol-Top +Payout Popups
- Request: Show `+payout` directly on top of matched symbols without a bottom-of-grid popup.
- Implementation: Re-enabled slot-level win popups during line flash in `combat_root.gd` (now rendered as `+N`), including headless/no-fx path. Removed centered `LinePayoutLabel` UI wiring from `combat_test.gd`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: `+payout` appears over each matched symbol; bottom-center transient payout text is no longer shown.
- Verification: Linter pass on `combat_root.gd` and `combat_test.gd`.

### Single Centered Popup Per Match Line
- Request: Show only one `+payout` indicator centered on the matched symbols instead of one per symbol tile.
- Implementation: Updated win-popup routing in `combat_root.gd` so each winning line chooses one anchor slot nearest the geometric center of matched cells and renders a single `+N` popup there (FX and no-FX paths).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: One payout indicator appears per winning line, centered over the matched run.
- Verification: Linter pass on `combat_root.gd`.

## 2026-05-19

### Fixed 2D Window Framing (1280x720)
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

### Rollback Fixed 2D Window Framing (1280x720)
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

### Fix 1.1 SchoolExterior Noir Overlay Startup Crash
- Request: Fix `1.1_SchoolExterior` crash on start (`Node not found: NoirPaletteOverlay/FilterRect` and null `material` access in `_apply_local_noir_tuning`).
- Implementation: Re-instanced `res://scenes/fx/NoirPaletteOverlay.tscn` in `1.1_SchoolExterior.tscn` (after `PlayerLayer`, before `TopDialogueOverlay`, no extra scale). Hardened `1.1_SchoolExterior.gd` to resolve `FilterRect` via `get_node_or_null` in `_ready()` and skip tuning with a warning if the overlay is missing.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Scene loads without startup errors; exterior noir palette tuning applies again when overlay is present.
- Verification: Headless `res://test/scene_smoke_check.gd` — `Scene smoke check OK (6 scenes).` with no `NoirPaletteOverlay/FilterRect` or `_apply_local_noir_tuning` errors on `1.1_SchoolExterior`.

### Disable Noir Overlay on 1.1 (Temporary)
- Request: Disable the noir overlay for now on school exterior.
- Implementation: Added `_NOIR_OVERLAY_ENABLED := false` in `1.1_SchoolExterior.gd`; hides `NoirPaletteOverlay` at runtime and skips local shader tuning until re-enabled.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: `1.1_SchoolExterior` runs unfiltered full-color background; overlay node remains in scene for easy re-enable (`_NOIR_OVERLAY_ENABLED = true`).
- Verification: Scene still loads without noir path errors; overlay hidden at runtime.

### Combat RTP Unit Rescale (100/1000 Economy)
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

### Cascade Multiplier HUD Readout
- Request: Show the increasing cascade multiplier in the combat phase UI (plan: second pill in `WinningsStack`, static readout with pulse on increment, cap context when active).
- Implementation: Added `CascadeMultiplierPill` above round-winnings pill in `combat_test.gd`; formats as `N×` with ` / cap` when Free Spins cap is enabled; pulses pill on increment. Exposed `is_multiplier_cap_active()` / `get_multiplier_cap_value()` on `combat_root.gd`; `_refresh_multiplier_label()` now emits `readouts_progressed` when multiplier value changes so the shell updates during cascades.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Players see live cascade multiplier under the grid; winnings pill unchanged (`MultiplierReadout` still shows round winnings). During Free Spins, cap suffix appears (e.g. `12× / 100`).
- Verification: Linter pass on touched scripts; manual F6 playtest recommended for pulse timing and two-pill layout at narrow widths.

### Combat HUD Repack for Grid Space
- Request: Move bankroll and full stake control to top row; place cascade multiplier inline next to round-winnings value to free vertical space for the combat grid.
- Implementation: Rebuilt `CenterTopHud` as horizontal row (bankroll + full `StakeSelector`); removed stake row from center column. Replaced vertical `WinningsStack` with horizontal `WinningsRow` (winnings pill + cascade multiplier pill inline). Reduced `WINNINGS_BAND_MIN_HEIGHT` and tightened column spacing; widened top HUD anchor band (`0.32–0.68`) with narrow-width typography scaling.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Center column is grid-first (no stake row above grid); economic controls live in top HUD; multiplier still pulses on increment with cap suffix when active.
- Verification: Linter pass on `combat_test.gd`; manual F6 check recommended for top-row crowding and inline readout clipping at narrow widths.

### Economics Stack Above Grid
- Request: Keep stake at its original vertical slot; place bankroll centered directly above stake (not side-by-side in top row).
- Implementation: Removed top-row `CenterTopHud` economics layout; added `EconomicsCenter`/`EconomicsStack` as first center-column child with bankroll over stake, both centered. Stake remains above grid; inline winnings row unchanged.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Bankroll and bet controls share one centered vertical block above the grid; no separate top HUD band for economy.
- Verification: Linter pass on `combat_test.gd`.

### Meta Box Economics Layout
- Request: Stake on same row as seed in top-left meta area; bankroll centered above that row (with icons), not in center column.
- Implementation: Moved economics into `MetaBox`/`MetaContent`: `EconomicsStack` under icon row with centered bankroll, then `SeedStakeRow` (seed controls + full stake selector). Removed center-column economics block; widened meta anchor band slightly (`LAYOUT_TOP_BOX_END` 0.14 → 0.22).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Center column is grid-only at top; seed/stake/bankroll live in top-left HUD stack.
- Verification: Linter pass on `combat_test.gd`.

### Centered Top Bankroll + Stake Stack
- Request: Restore gear icons and seed to previous top-left positions; place bankroll centered on the top row and stake indicator centered directly below it.
- Implementation: Reverted meta-box economics injection and restored default `MetaContent` flow (icons + seed row unchanged). Added a dedicated centered `EconomicsCenter` overlay anchored in the top HUD band, with `EconomicsStack` containing bankroll then full stake selector. Restored meta box width to prior anchor (`LAYOUT_TOP_BOX_END` back to `0.14`).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Left top corner returns to icons/seed behavior; bankroll is horizontally centered at top with stake directly under it.
- Verification: Linter pass on `combat_test.gd`.

### Governance: Clarification-First Planning Gate
- Request: Prevent assumption-driven planning and require clarification before new plan output.
- Implementation: Updated governance docs to require a mandatory planning intake gate: agents must ask at least 2 targeted clarifying questions for every new planning request, then continue asking follow-ups until intent/scope/constraints are concise and assumption-free. Added explicit "no silent assumptions" language and a consistency-check checklist item for planning compliance.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Future planning chats must gather enough user-confirmed detail before drafting plans, reducing unilateral revisions and hidden defaults.
- Verification: Manual doc review confirms matching enforcement language in `AI_DOCS.md` and always-applied governance rule.

### Combat UI Polish (Winnings, History, Power Glow, Execute, Goal)
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

### Execute Button Vertical Nudge (8px)
- Request: Execute button still misaligned with history/items panel borders; move down by 8px.
- Implementation: Increased `EXECUTE_BUTTON_VERTICAL_NUDGE` spacer above the execute button from 6px to 8px.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button sits 8px lower in the center footer for border baseline alignment with side panels.
- Verification: Linter pass on `combat_test.gd`.

### Execute Button Nudge Fix (MarginContainer, 30px test)
- Request: Prior spacer-based nudge had no visible effect; test with 30px downward shift.
- Implementation: Replaced ineffective `ExecuteTopSpacer` with `MarginContainer` (`margin_top`) around the execute button; footer alignment set to `BEGIN`; nudge constant set to 30px and refreshed in `_layout_execute_button_width()`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button should visibly move down by 30px relative to prior layout.
- Verification: Linter pass on `combat_test.gd`.

### Execute Button Bottom Alignment (Structural Fix)
- Request: Execute button nudge still had no visible movement; align bottom border with history/items panels.
- Implementation: Root cause was footer pinned above fixed `BottomWindowMargin` while HBox stretched side panels to full row height. Added `_layout_execute_bottom_inset()` to set bottom spacer from measured gap to side-panel bottom; side panels use `SIZE_SHRINK_END`; removed ineffective `MarginContainer` top-margin approach. `EXECUTE_BUTTON_VERTICAL_NUDGE` subtracts from computed gap (30px test).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button bottom should track history/items panel bottoms; nudge pulls further down when gap allows.
- Verification: Linter pass on `combat_test.gd`.

### Execute Button Final Border Alignment
- Request: After 30px alignment test, set execute button bottom on same row as history/items panel bottom borders.
- Implementation: Set `EXECUTE_BUTTON_VERTICAL_NUDGE` to 0; `_layout_execute_bottom_inset()` uses `get_global_rect().end.y` on side panels and execute button for pixel-accurate alignment.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button bottom should line up with side panel bottom borders without extra test offset.
- Verification: Linter pass on `combat_test.gd`.

### Execute Alignment Without Grid/Panel Reflow
- Request: Previous alignment attempts moved/scaled the combat grid and pushed side panel borders past the game window; keep grid untouched and align execute bottom safely.
- Implementation: Reverted side-panel/footer sizing changes that caused reflow (`SIZE_SHRINK_END` and footer `ALIGNMENT_BEGIN`), removed bottom-inset spacer mutation, and switched to visual-only execute alignment via `_align_execute_button_bottom_visual()` using global bottom deltas.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Grid sizing/placement and side panel bounds return to stable behavior while execute button is visually aligned to panel bottoms.
- Verification: Linter pass on `combat_test.gd`.

### Execute Button Nudge Only (+3px)
- Request: Move only the execute button ~3px downward without touching grid or panel layout behavior.
- Implementation: Simplified `_align_execute_button_bottom_visual()` to apply a fixed button-local Y offset only; set `EXECUTE_BUTTON_VERTICAL_NUDGE` to `3.0`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button is nudged down by 3px; no grid, scale, or panel placement reflow logic involved.
- Verification: Linter pass on `combat_test.gd`.

### Execute Button Visual Test (+10px)
- Request: 3px nudge still appeared unchanged; test with 10px downward move.
- Implementation: Set `EXECUTE_BUTTON_VERTICAL_NUDGE` to `10.0` and made execute button `top_level` so container sorting cannot cancel visual offset; `_align_execute_button_bottom_visual()` now positions from center-footer global rect.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button should visibly move down by ~10px without resizing/moving the combat grid or side panels.
- Verification: Linter pass on `combat_test.gd`.

### Execute Button Final Set (+3px)
- Request: Keep current working method, return near original position, then offset down by 3px.
- Implementation: Kept top-level visual placement path and changed `EXECUTE_BUTTON_VERTICAL_NUDGE` from `10.0` to `3.0`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button uses original footer anchor logic with a visible +3px downward offset.
- Verification: Linter pass on `combat_test.gd`.

### Execute Button In-Window Anchor Fix
- Request: Execute button still appeared under the game window bottom border.
- Implementation: In `_align_execute_button_bottom_visual()`, switched Y anchor from `footer_rect.position.y` to `footer_rect.end.y - btn_size.y`, then applies the same `+3px` nudge.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button stays inside the window while preserving the requested slight downward offset.
- Verification: Linter pass on `combat_test.gd`.

### Execute Layout Rollback To Original Composition
- Request: Remove all execute-button fixes from this thread and restore original composition.
- Implementation: Removed `top_level` execute mode, removed visual-position override function/deferred calls, and restored button placement to container-driven layout only.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Execute button returns to original composition behavior (no manual position overrides); grid and side panel layout no longer affected by execute experiments.
- Verification: Linter pass on `combat_test.gd`.

### Winnings Popup Glow + 50% Activation Pop
- Request: Keep current winnings popup style, add a subtle animated glow, and increase text size by 50% on activation before fade-out.
- Implementation: In `symbol_slot.gd`, added a glow back-layer label (`WinPopupGlowLabel`) and updated `play_win_popup()` tween flow to pop both labels to `1.5x` scale on entry, drift upward, then fade out.
- Files changed:
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Per-symbol win amount popup now has a stronger read: brief red glow pulse + 50% scale pop on activation, while preserving the existing white primary text style.
- Verification: Linter pass on `symbol_slot.gd`.

### Combat Test Editor/Runtime Layout Parity
- Request: Make the combat test 2D editor view match the runtime opening layout (layout-only parity); fix hidden nodes and mispositioned EXECUTE button in editor.
- Implementation: Converted `combat_test.gd` to `@tool` with an editor-preview path that reuses the same shell/HUD/layout pipeline as runtime without spin gameplay. Added `editor_preview_enabled` and `editor_preview_seed` exports, idempotent play-shell/HUD restoration, and `set_owner(null)` on editor-only dynamic nodes so preview nodes are not saved into the scene. Set `CombatRoot` visible by default in `combat_test.tscn`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 2D editor view now builds the same responsive layout shell as play-mode start (grid, side panels, centered EXECUTE, HUD). Runtime spin flow unchanged; editor preview does not run spins.
- Verification: Linter pass on `combat_test.gd`; `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://test/scene_smoke_check.gd` (OK); `res://combat/test/determinism_check.gd` (OK); `res://combat/test/princess_check.gd` (OK).

### Combat Test Editor Placeholder Guard
- Request: Fix editor errors when `CombatRoot` is a placeholder instance (`setup_new_grid`, `fit_to_panel`, `inventory`, readout/overlay calls) while keeping `combat_root.gd` runtime-only.
- Implementation: Added `_can_use_combat_api()` / `_can_layout_combat_grid()` gates and safe readout helpers in `combat_test.gd`. Editor preview now uses layout-only fallbacks (static HUD values, host-width button sizing, premium-bar fallback placement) when combat gameplay APIs are unavailable; runtime paths unchanged.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 2D editor no longer throws placeholder-instance errors on scene open or `editor_preview_seed` changes; layout shell parity remains. Full combat simulation still runs only at runtime/play.
- Verification: Linter pass on `combat_test.gd`; scene smoke + determinism + princess headless checks (OK).

### Combat Test Editor Null Onready Refs
- Request: Fix editor `null instance` errors on `seed_spin`, `bet_label`, `spin_btn` and empty 2D preview after `@tool` editor parity work.
- Implementation: Added `_cache_scene_refs()` to resolve `%UniqueName` nodes manually in editor (`@onready` is unreliable in `@tool`). Deferred editor preview until scene tree is ready (`_run_editor_preview_when_ready` with retry). Added null guards across readout/layout paths; fixed `_build_play_shell` early-return that aborted layout when `mult_label` was missing.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Editor preview should render HUD/side panels/EXECUTE shell without null-instance spam; runtime unchanged.
- Verification: Linter pass on `combat_test.gd`.

### Combat Test Scene Scaffold Restore
- Request: Restore `combat_test.tscn` to the tracked canonical structure to recover missing preview/runtime UI nodes and unblock editor layout parity.
- Implementation: Reverted `AXEL/axel_project/combat/combat_test.tscn` to the repository version, restoring required nodes (`CombatRoot`, `MetaBox`, `SeedSpinBox`, `BankrollLabel`, `GoalBox`, `StakeSelector`, `MultiplierReadout`, `SpinButton`) used by `combat_test.gd` caching/layout paths.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Editor preview can resolve required scene refs again and build the full shell instead of rendering only the black background/overlays.
- Verification: `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://test/scene_smoke_check.gd` (OK); `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd` (OK).

### Combat Test Editor Visual Parity (Fallback Layout)
- Request: Fix remaining editor-preview visual drift — EXECUTE bar spanning into side panels, combat grid misplaced/scaled at top-left, and stray `Multiplier: 1×` from `CombatRoot`.
- Implementation: In `combat_test.gd`, added editor-placeholder fallback grid layout mirroring `combat_root.fit_to_panel` fill-panel math (`_layout_combat_grid_fallback`), centered premium bar + EXECUTE width tied to computed grid width (not full host), and `_suppress_combat_root_legacy_labels()` to hide `MultiplierLabel` / `RoundWinningsLabel` / `EncounterWonLabel` in composed view.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 2D editor preview should match runtime opening composition for grid scale/position and EXECUTE width; runtime `fit_to_panel` path unchanged.
- Verification: Linter pass on `combat_test.gd`; scene smoke + determinism headless checks (OK).

### Combat Symbol Art Dedup (`grid_symbols` canonical)
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

### Winnings Popup Retimed (5-Phase, 2x Slower)
- Request: Slow default popup animation by 100% (2x total duration) with distinct steps: small appear, scale up, glow, lob to total winnings value, fade.
- Implementation: Refactored `symbol_slot.gd` `play_win_popup()` into five sequential chained phases with centralized duration shares (12/22/18/36/12%) over `WIN_POPUP_TOTAL_DURATION` 1.24s. Glow hold pulses glow layer before lob; fade only runs after lob/hold completes.
- Files changed:
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Line-win popups read more deliberately; lob target unchanged (total winnings value).
- Verification: Linter pass; `determinism_check.gd` headless (OK).

### Winnings Popup Lob + Vector Font
- Request: Per-line winnings popup should start small, scale up 100%, then lob into the total winnings readout; use vector font for crisp scaling.
- Implementation: `combat_test` wires `MultiplierReadout` to `CombatRoot.set_winnings_popup_target()`. `combat_root` passes target global center into `play_win_popup`. `symbol_slot` uses VT323 `FontFile` on popup labels, grow phase (0.5→2.0 scale), then quadratic-bezier lob toward the readout with fade on impact.
- Files changed:
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Line-win amount popups arc into the center winnings value instead of drifting upward only; text stays vector-sharp while scaling.
- Verification: Linter pass on touched scripts; `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd` (OK).

## 2026-05-22

### Combat Test Scaffold Overwrite Guardrails
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

### Combat Test Editor Save Stripping Fix
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

### Recover Pre-Dedup Stable Snapshot (`bab7ec5`)
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

### Return Pre-Dedup Feature Stack (Visual + Combat)
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

### Fix Editor Preview + Post-Dedup Pack
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

### Preserve Combat Milestone on GitHub
- Request: Preserve recent combat changes across computers so they are logged on GitHub (not only OneDrive); working tree showed no pending commit because changes were already committed.
- Implementation: Confirmed milestone at `4110c74` on `main` (includes `7144462`..`4110c74` stack). Created and pushed backup branch `backup/2026-05-22-combat-state` and annotated tag `checkpoint-2026-05-22-combat-state`. Documented multi-machine fetch/push/milestone workflow in `AI_DOCS.md` §14.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No runtime change. GitHub now has independently discoverable refs for the combat recovery milestone; agents and humans can restore this state from any machine after `git fetch`.
- Verification: `git ls-remote` confirms branch `backup/2026-05-22-combat-state` and tag `checkpoint-2026-05-22-combat-state` on `origin`; both point to commit `4110c74`.

## 2026-05-23

### HD Winnings Popup + Border-Touch Counter
- Request: Sharpen individual winnings popup font (keep VT323) and start total winnings readout count-up the moment the flying popup overlaps the readout border, stepping through every integer quickly with adaptive cap (~250ms).
- Implementation: Added geometric first-overlap detection in `symbol_slot.gd` (`win_popup_border_touched`), bridged via `combat_root.gd` (`winnings_popup_border_touched`), and implemented queued integer-by-integer counter in `combat_test.gd` tied to `MultiplierReadout`. Tuned popup scale/font/outline and VT323 import (no AA, oversampling 2.0) for crisper motion.
- Files changed:
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/ui/fonts/VT323-Regular.ttf.import`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Line-win popups read sharper during flight; total winnings pill stays at 0 until popup touches its border, then rapidly counts 0→N per line win (coalesced for bursts) and snaps to combat truth at spin end.
- Verification: Linter clean on touched scripts; Godot CLI not in PATH for headless playtest — manual F6 `combat_test.tscn` check recommended (single line win, multi-line burst, large payout).
- Notes: Option A (geometric border-touch event + queue counter) from approved plan.

### Fix Nested Combat Grid Overlay
- Request: Fix grid-within-grid visual in combat test scene.
- Implementation: Removed duplicate `*2` CombatRoot children and the full inline duplicate of `combat_root.tscn` subtree in `combat_test.tscn` (instance-only, matching scaffold baseline). Extended `combat_test_scaffold_check.gd` to require exactly one grid/readout node set under CombatRoot and fail on `*2` suffix duplicates.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/test/combat_test_scaffold_check.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Combat test shows a single red grid frame and one 5×5 symbol grid; layout still driven by `fit_to_panel()` at runtime.
- Verification: `combat_test_scaffold_check.gd` (OK).

### QA Agent Canon Consistency Extension (Default)
- Request: Extend default `qa agent` to detect visual/gameplay inconsistencies in combat test and player movement scenes (e.g. duplicate combat grid), and recommend improvements without blocking on audit findings alone.
- Implementation: Added `test/qa/qa_canon_validators.gd` (shared assertions) and `test/qa/canon_consistency_audit.gd` (`CANON_AUDIT_JSON`, always exit 0). Refactored `combat_test_scaffold_check.gd` and `scene_smoke_check.gd` to use shared validators. Wired audit into default QA command set (skill + rubric + `AI_DOCS.md`). Bots emit `BOT_METRICS_JSON` on success for QA evidence.
- Files changed:
  - `AXEL/axel_project/test/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/test/qa/canon_consistency_audit.gd`
  - `AXEL/axel_project/test/qa/README.md`
  - `AXEL/axel_project/plans/qa/AXEL_CANON_CONSISTENCY_AUDIT.md`
  - `AXEL/axel_project/combat/test/combat_test_scaffold_check.gd`
  - `AXEL/axel_project/test/scene_smoke_check.gd`
  - `AXEL/axel_project/test/bots/playthrough_arc1_exterior.gd`
  - `AXEL/axel_project/test/bots/playthrough_dialogue_loop.gd`
  - `AXEL/axel_project/test/bots/README.md`
  - `AXEL/axel_project/tools/qa/canon_validators_shared.py`
  - `AXEL/axel_project/tools/qa/check_combat_test_scaffold.py`
  - `AXEL/axel_project/tools/qa/update_qa_analytics.py`
  - `.cursor/skills/axel-simulated-qa/SKILL.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Default `qa` runs an eighth headless command that reports combat/movement canon drift as findings + recommendations; scaffold check and pre-commit Python guard remain hard gates for duplicate grids.
- Verification: `canon_consistency_audit.gd` exit 0 with 9 findings (7× duplicate CombatRoot grid, corridor speed/scale drift); `combat_test_scaffold_check.gd` exit 1; `check_combat_test_scaffold.py` exit 1 on instance+override duplicate grid in `.tscn`.
- Notes: Warn+recommend for audit; user-confirmed scope combat + movement every run.

### QA Progress vs Quality scoring overhaul
- Request: Redesign QA analytics so scores reflect game completion (not inflated quality/bot pass rates); dual Progress + Quality charting with hard milestone gates.
- Implementation: Added `QA_PROGRESS_CHECKLIST.md` (weighted milestones, gate caps 1.5–5.0, Option 2 formula). Extended rubric, run-log JSON schema, and `qa agent` skill to require separate **Progress** and **Quality** scores. Rewrote `update_qa_analytics.py` to plot Progress + Quality as primary SVG lines, axis scores and Bots as secondary; backward-compatible with legacy payloads (Progress gaps until next QA run logs `progress` object).
- Files changed:
  - `AXEL/axel_project/plans/qa/QA_PROGRESS_CHECKLIST.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_RUN_LOG.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_ANALYTICS.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_ANALYTICS.svg`
  - `AXEL/axel_project/tools/qa/update_qa_analytics.py`
  - `.cursor/skills/axel-simulated-qa/SKILL.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Future QA runs log completion progress capped by gates (~2.x expected today) independently of quality (~3.5–3.9). Analytics chart no longer treats bot pass=5 as “game done.”
- Verification: `python AXEL/axel_project/tools/qa/update_qa_analytics.py` — 10 payloads parsed; analytics MD/SVG regenerated with interpretation section.
- Notes: Historical run log entries lack `progress`; first post-change `run qa` should populate Progress line on chart.

### QA progress checklist expansion (content milestones)
- Request: Add milestones for map layout, assets, combat anim/VFX, items, shop, locker hub, audio, and menu screens to the progress checklist.
- Implementation: Expanded `QA_PROGRESS_CHECKLIST.md` to 149 total weight — new Gate 2 items (interact list, locker shell, scene visual style); Gate 3 items (multi-room maps, drawn assets, combat animations/VFX, item bar, full item integration/placements, shop, complete locker hub); Gate 4 items (game-wide SFX, title/credits/options/about). Added scope notes for combat animation and VFX implementation. Updated rubric total-weight reference and run-log template default `checklist_total_weight`.
- Files changed:
  - `AXEL/axel_project/plans/qa/QA_PROGRESS_CHECKLIST.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_RUN_LOG.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Progress scoring reflects full production scope; expected Progress band slightly lower until new milestones are completed.
- Verification: Checklist gate subtotals sum to 149 (15+23+35+62+14).
- Notes: None.

### QA checklist: plan-doc traceability + Viral Forge scope
- Request: Confirm milestone list covers prior plan docs; add relevant Viral Forge ideas only.
- Implementation: Added §Plan doc coverage and §Viral Forge relevance tables to `QA_PROGRESS_CHECKLIST.md`. New milestones for blueprint globals (HUD, GameState/SceneRouter, StoryBox/PuzzleInput, scene FX), `AXEL_notes` roguelite loop (six areas, combat triggers, memories, locker/Hole, run reset, 50/50), VF-adapted items (synergy framework, peak cascade moment, tutorial, seed UI, moral framing). Excluded VF spin-offs (ZERO web app, Resonance cosmic/Steam, Tilt heist). Total weight 149 → **200**.
- Files changed:
  - `AXEL/axel_project/plans/qa/QA_PROGRESS_CHECKLIST.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_RUN_LOG.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Progress scoring reflects full design surface; lower % completion for same shipped work until new milestones are done.
- Verification: Gate subtotals 15+30+40+95+20 = 200.
- Notes: Re-run `update_qa_analytics.py` optional until next QA payload with `checklist_total_weight: 200`.

### QA analytics expandable project-points chart
- Request: Analytics graph should not be fixed 0–5; Y-axis should grow as checklist milestones add weighted scope.
- Implementation: `update_qa_analytics.py` now plots **ProgressPoints** (`checklist_completed_weight`) on an auto-scaling left axis, **ScopeCeiling** (`checklist_total_weight`, dashed), and **Quality** on a fixed 0–5 right axis. Legacy `progress.score` approximates points when completed_weight is missing. Rubric + checklist docs updated.
- Files changed:
  - `AXEL/axel_project/tools/qa/update_qa_analytics.py`
  - `AXEL/axel_project/plans/qa/AXEL_QA_ANALYTICS.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_ANALYTICS.svg`
  - `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/qa/QA_PROGRESS_CHECKLIST.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Chart ceiling expands when checklist total weight increases; completed work trends upward in raw points instead of capping at 5.
- Verification: `python AXEL/axel_project/tools/qa/update_qa_analytics.py` exit 0.
- Notes: Historical runs without `progress` still show scope ceiling (200) and Quality; points line appears after first payload with `checklist_completed_weight`.

### Remove Bots line from QA analytics
- Request: Remove Bots trend line (always showed 5, not useful).
- Implementation: Removed dead bot-aggregate chart code and Bots snapshot line from `update_qa_analytics.py`; regenerated analytics artifacts.
- Files changed: `tools/qa/update_qa_analytics.py`, `plans/qa/AXEL_QA_ANALYTICS.md`, `plans/qa/AXEL_QA_ANALYTICS.svg`, `plans/core/AI_CHANGELOG.md`
- Behavior impact: Chart and snapshot no longer include Bots; bot playtests still run and log under `playtest_commands` in QA reports.
- Verification: Regenerated analytics; no `Bots` in `AXEL_QA_ANALYTICS.md`.

### QA analytics chart layout and readability
- Request: Scale up chart (less empty margin), shorten x-axis dates (R-index + table), multi-line tick labels, center Scope ceiling and Quality legend, smooth lines.
- Implementation: `update_qa_analytics.py` uses larger plot area (1200×680), short `R#` + `MM-DD` x-ticks, run index table in markdown, centered primary/secondary legends with two-line labels for scope/quality, quadratic-smoothed SVG paths.
- Files changed:
  - `AXEL/axel_project/tools/qa/update_qa_analytics.py`
  - `AXEL/axel_project/plans/qa/AXEL_QA_ANALYTICS.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_ANALYTICS.svg`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: SVG is denser and readable; full dates/scopes live in the run index table below the chart section.
- Verification: `python AXEL/axel_project/tools/qa/update_qa_analytics.py` exit 0; 11 runs parsed.

### Scene 1.1 visual style comparison sweep
- Request: Plan and run a deterministic Scene 1.1 screenshot pass for baseline plus all options in `VISUAL_STYLE_OPTIONS.md` (one image per variant for user selection).
- Implementation: Added test-only variant matrix, staged approximation shaders (A/B/C1–C4/D/E), overlay applier, and `capture_scene_1_1_style_sweep.gd` with scripted 120-frame walk + PNG export. Minimal `AXEL_SKIP_INTRO` hook on `1.1_SchoolExterior.gd`. Ran full 9-variant sweep; copies saved under `style_sweep_1_1/`.
- Files changed:
  - `AXEL/axel_project/test/visual_style/*`
  - `AXEL/axel_project/tools/visual_style/run_scene_1_1_style_sweep.ps1`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/style_sweep_1_1/*.png`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Production visuals unchanged unless a variant is chosen for integration; capture tooling is opt-in via `-s res://test/visual_style/capture_scene_1_1_style_sweep.gd`.
- Verification: Godot sweep exit 0; 9 PNGs at 1152×648 after 120-frame walk; shader compile clean on second pass.
- Notes: Staged shaders approximate external options for comparison; integrate chosen option from upstream repos when moving beyond look-dev.

### Global noir line-preservation parameter tune
- Request: Fix disappearing line art from baseline noir quantization while keeping Option A CRT direction; global parameter-only scope.
- Implementation: Retuned global `noir_palette_filter.gdshader` defaults (`line_contrast` 1.25, thresholds `t0/t1/t2` 0.07/0.31/0.78, warm highlight `white_color` instead of black crush). Disabled Scene 1.1 local noir overrides (`_USE_LOCAL_NOIR_TUNING := false`) and removed contradictory per-capture tuning in `style_overlay_applier.gd`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/noir_palette_filter.gdshader`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/test/visual_style/style_overlay_applier.gd`
  - `AXEL/axel_project/style_sweep_1_1_linefix/*.png`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: All scenes using `NoirPaletteOverlay` inherit line-safer quantization; thin strokes retain more continuity under noir+CRT stack.
- Verification: Captures `style_sweep_1_1_linefix/01_baseline.png` + `02_A_crt_plugin.png`; `scene_smoke_check.gd` OK (6 scenes).
- Notes: Go/no-go — adopt globally; optional next step is minor CRT intensity reduction if scanlines still compete with 1px art lines.

### Invert noir palette (red strokes on black ground) + adopt CRT on 1.1
- Request: Keep Option A CRT look but swap colors — red areas to black, black outlines to red.
- Implementation: Inverted luminance band mapping in `noir_palette_filter.gdshader` (dark -> red, mid/high -> black). Promoted CRT pass to `scenes/fx/crt_plugin_overlay.gdshader` + `CrtPluginOverlay.tscn`; enabled noir/scanline/CRT on `1.1_SchoolExterior` for runtime parity with chosen style.
- Files changed:
  - `AXEL/axel_project/scenes/fx/noir_palette_filter.gdshader`
  - `AXEL/axel_project/scenes/fx/crt_plugin_overlay.gdshader`
  - `AXEL/axel_project/scenes/fx/CrtPluginOverlay.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/test/visual_style/*`
  - `AXEL/axel_project/style_sweep_1_1_linefix/02_A_crt_plugin.png`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Global noir now renders black ground + red line art; Scene 1.1 plays with full noir+scanline+CRT stack.
- Verification: Re-captured `02_A_crt_plugin.png`; `scene_smoke_check.gd` OK (6 scenes).

### Style-sweep outline-aware Option A CRT
- Request: CRT plugin should detect art outlines and apply full CRT treatment to them (like player), style-sweep pipeline only.
- Implementation: Extended `test/visual_style/shaders/option_a_crt_plugin.gdshader` with 8-neighbor luminance edge mask, red/bright line bias, and boosted CRT pass on outlines. Pointed `variant_matrix` Option A back to test shader path.
- Files changed:
  - `AXEL/axel_project/test/visual_style/shaders/option_a_crt_plugin.gdshader`
  - `AXEL/axel_project/test/visual_style/variant_matrix.gd`
  - `AXEL/axel_project/test/visual_style/README.md`
  - `AXEL/axel_project/style_sweep_1_1_linefix/02_A_crt_plugin.png`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Style-sweep Option A only; production `crt_plugin_overlay.gdshader` unchanged.
- Verification: `A_crt_plugin` capture exit 0; outlines show stronger chroma/scanline treatment in updated PNG.

### Revert outline-aware CRT (style sweep)
- Request: Revert outline-aware Option A CRT; restore previous look.
- Implementation: Restored simple `option_a_crt_plugin.gdshader` (no outline mask). Pointed sweep Option A back to `crt_plugin_overlay.gdshader`. Removed outline README section. Re-captured `style_sweep_1_1_linefix/02_A_crt_plugin.png`.
- Files changed:
  - `AXEL/axel_project/test/visual_style/shaders/option_a_crt_plugin.gdshader`
  - `AXEL/axel_project/test/visual_style/variant_matrix.gd`
  - `AXEL/axel_project/test/visual_style/README.md`
  - `AXEL/axel_project/style_sweep_1_1_linefix/02_A_crt_plugin.png`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Style-sweep Option A uses standard CRT pass again (pre-outline experiment).

### Scene 1.1 edge-aware RGB-shadow CRT outlines
- Request: Replicate player-style RGB chroma shadowing on environment + character outlines in Scene 1.1 via global post-process; keep player `ShadowOutline` silhouette unchanged.
- Implementation: Extended production `crt_plugin_overlay.gdshader` with luminance edge mask (4- + diagonal-neighbor gradients), `smoothstep` thresholding, and edge-boosted horizontal R/G/B channel offsets (`outline_edge_threshold`, `outline_edge_strength`, `outline_rgb_offset`, `outline_softness`). Scene 1.1 applies conservative tuning in `_apply_local_crt_outline_tuning()` (`_USE_LOCAL_CRT_OUTLINE_TUNING`); layer stack unchanged (CRT stays at 108, dialogue at 110). No edits to `Player.gd` or `ShadowOutline`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/crt_plugin_overlay.gdshader`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Scene 1.1 env red ink lines and white player/character edges get stronger RGB fringe at high-contrast boundaries; base CRT chroma remains elsewhere. Other scenes using `CrtPluginOverlay` get shader defaults only until they opt into local tuning.
- Verification: `scene_smoke_check.gd` OK (6 scenes); style-sweep `A_crt_plugin` capture exit 0.
- Notes: Differs from reverted style-sweep outline experiment (edge-boosted chroma only, not full CRT stack duplication on outlines).

### Fix noir red-line RGB fringe (Scene 1.1 CRT)
- Request: CRT RGB-shadow not visible on environment red outlines (only player showed fringe).
- Root cause: Luminance-only edge chroma cannot fringe pure-red noir strokes — channel offsets sample R-only pixels so G/B stay zero.
- Implementation: Extended `crt_plugin_overlay.gdshader` with `red_ink_amount()` detection, RGB+ink edge metric, and `apply_red_ink_fringe()` that bleeds red ink into G/B channel halos. Added `outline_ink_fringe` uniform; lowered edge threshold and raised offsets in Scene 1.1 local tuning.
- Files changed:
  - `AXEL/axel_project/scenes/fx/crt_plugin_overlay.gdshader`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Red noir line art should show RGB separation similar in spirit to player CRT fringe; white sprite edges still use luminance/RGB edge boost.
- Verification: `scene_smoke_check.gd` OK (6 scenes).

### Revert Scene 1.1 outline CRT experiment
- Request: Return to previous CRT version and refresh style-sweep screenshot.
- Implementation: Restored simple `crt_plugin_overlay.gdshader` (global chroma only, no edge/ink outline uniforms). Removed Scene 1.1 `_apply_local_crt_outline_tuning()`. Reverted `style_overlay_applier.gd` to standard stack overlay path. Re-captured `02_A_crt_plugin.png`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/crt_plugin_overlay.gdshader`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/test/visual_style/style_overlay_applier.gd`
  - `AXEL/axel_project/style_sweep_1_1_linefix/02_A_crt_plugin.png`
  - `AXEL/axel_project/style_sweep_1_1/02_A_crt_plugin.png`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Scene 1.1 CRT is back to standard curvature/mask/vignette/chroma pass; no outline-specific RGB fringe tuning.
- Verification: Style-sweep `A_crt_plugin` capture exit 0.

### Reduce CRT on overworld player by 33%
- Request: Decrease CRT effect on the player model by 33%.
- Implementation: Added `player_crt_reduction` (default `0.33`) and `player_sprite_mask()` in `crt_plugin_overlay.gdshader` to detect white overworld sprite + dark silhouette shadow; CRT mix scales to 67% on those pixels (chroma, scanlines, mask, vignette, curvature).
- Files changed:
  - `AXEL/axel_project/scenes/fx/crt_plugin_overlay.gdshader`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Environment CRT unchanged; player body and shadow get ~33% less post-process CRT. Tweak via `player_crt_reduction` on `CrtPluginOverlay/FilterRect` material.
- Verification: `scene_smoke_check.gd` OK (6 scenes).

### Global post-FX autoload (non-combat only)
- Request: Global rule — noir + scanline + CRT applied everywhere except combat.
- Implementation: Added autoload `AxelPostFxStack` (`scripts/autoload/axel_post_fx_stack.gd`) hooked to `SceneTree.scene_changed`; attaches the three overlay packed scenes to non-combat scenes, skips `res://combat/*`, style-sweep (`AXEL_DISABLE_POST_FX=1`), and scenes with `StyleSweepOverlays`. Removed per-scene overlay instances from `1.1_SchoolExterior.tscn` and `1.2_Corridor.tscn`; simplified `1.1_SchoolExterior.gd`. Corridor noir tuning resolves filter via autoload. Documented in `AI_DOCS.md` §6 and governance rule §12.
- Files changed:
  - `AXEL/axel_project/scripts/autoload/axel_post_fx_stack.gd`
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/test/visual_style/capture_scene_1_1_style_sweep.gd`
  - `AXEL/axel_project/test/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Main menu, Arc 1+, and future overworld scenes get the full stack automatically; combat scenes unchanged. Corridor now includes CRT (was scanline+noir only).
- Verification: `scene_smoke_check.gd` OK (6 scenes).

### Remove style sweep output folders
- Request: Remove `style_sweep_1_1` and `style_sweep_1_1_linefix` folders.
- Implementation: Deleted both directories under `AXEL/axel_project/`. Style-sweep runner no longer copies PNGs back into the repo (captures remain under Godot `user://style_sweep_1_1` only when the sweep script is run).
- Files changed:
  - `AXEL/axel_project/style_sweep_1_1/` (removed)
  - `AXEL/axel_project/style_sweep_1_1_linefix/` (removed)
  - `AXEL/axel_project/tools/visual_style/run_scene_1_1_style_sweep.ps1`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No committed comparison PNGs in-repo; opt-in sweep tooling unchanged.

### Remove duplicate CombatRoot grid overrides in combat test scene
- Request: Fix pre-commit block reporting duplicate `CombatRoot` grid nodes in `combat_test.tscn`.
- Implementation: Kept `CombatRoot` as an instance of `combat_root.tscn` only; removed inline duplicate nodes under `CombatRoot` (`GridManager`, `GridFrame`, `GridUI`, `GridFlashOverlay`, `PowerIntroLayer` (+ children), `RoundWinningsLabel`, `EncounterWonLabel`) and removed now-unused grid manager ext resource from the scene file.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Prevents runtime duplicate grid hierarchy in combat test scaffold while preserving the required scaffold host/UI nodes.

### Clear scoped Godot `.gd` diagnostics (style sweep mirrors + capture script)
- Request: Fix the 40 listed Godot Problems diagnostics across style-sweep mirror test scripts and the canonical style-sweep capture runner.
- Implementation: Removed stale `style_sweep_1_1/test/` mirror scripts (orphaned duplicates of `res://test/*` after `style_sweep_1_1` output cleanup); refactored canonical `capture_scene_1_1_style_sweep.gd` to use global `class_name` helpers (`VisualStyleVariantMatrix`, `StyleOverlayApplier`, `InputEventDriver`, `BotScenarioRunner`), replaced non-constant `const _SCENE` with typed runtime `_scene_path`, and renamed shadowing `abs` local to `abs_path`.
- Files changed:
  - `AXEL/axel_project/test/visual_style/capture_scene_1_1_style_sweep.gd`
  - `AXEL/axel_project/style_sweep_1_1/test/` (removed stale mirror tree recreated during triage)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Style-sweep runner behavior unchanged; no duplicate test harness under deleted output folder. Close/reload any stale editor tabs pointing at `style_sweep_1_1/test/*.gd` so Problems clears the 38 mirror-path entries.
- Verification: IDE lints clean on canonical capture script; mirror paths removed from disk.

### Combat test editor placement + duplicate class collision cleanup
- Request: Fix recurring CombatRoot rename warning (`MultiplierLabel2`), combat grid editor placement drift, and duplicate `class_name` hiding diagnostics under `style_sweep_1_1/test/*`.
- Implementation: Removed injected duplicate `MultiplierLabel2` child from `combat_test.tscn` so `CombatRoot` uses only labels from `combat_root.tscn` instance; confirmed `editor_preview_enabled = true` for deterministic editor layout; verified `style_sweep_1_1/test/` mirror tree is absent on disk (close any stale editor tabs still pointing at mirror paths).
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Eliminates incoming-node rename churn on combat test load/save; editor preview layout remains centered by default via existing `combat_test.gd` layout path. Runtime combat behavior unchanged.
- Verification: `scene_smoke_check.gd` OK (6 scenes); no duplicate `MultiplierLabel*` nodes under `CombatRoot` in `combat_test.tscn`.

### Resolve style-sweep mirror class_name shadowing diagnostics
- Request: Fix Godot diagnostics reporting `Class "... " hides a global script class` for mirror scripts under `style_sweep_1_1/test/`.
- Implementation: Removed `class_name` declarations from mirror-only helper scripts in `style_sweep_1_1/test/` so they no longer register duplicate global script classes that collide with canonical `res://test/*` helpers.
- Files changed:
  - `AXEL/axel_project/style_sweep_1_1/test/visual_style/style_overlay_applier.gd`
  - `AXEL/axel_project/style_sweep_1_1/test/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/style_sweep_1_1/test/visual_style/variant_matrix.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mirror scripts remain usable via direct script references, but no longer pollute global class registry or shadow canonical classes.
- Verification: Targeted diagnostics source removed (`class_name` collisions).

### Remove regenerated mirror scripts causing stale duplicate-class diagnostics
- Request: Duplicate-class diagnostics persisted for files under `style_sweep_1_1/test/*` after `class_name` removal.
- Implementation: Removed regenerated mirror helper scripts and their `.uid` files from `style_sweep_1_1/test/` to eliminate duplicate test-script copies outside canonical `res://test/*`.
- Files changed:
  - `AXEL/axel_project/style_sweep_1_1/test/visual_style/style_overlay_applier.gd` (deleted)
  - `AXEL/axel_project/style_sweep_1_1/test/qa/qa_canon_validators.gd` (deleted)
  - `AXEL/axel_project/style_sweep_1_1/test/visual_style/variant_matrix.gd` (deleted)
  - `AXEL/axel_project/style_sweep_1_1/test/visual_style/style_overlay_applier.gd.uid` (deleted)
  - `AXEL/axel_project/style_sweep_1_1/test/qa/qa_canon_validators.gd.uid` (deleted)
  - `AXEL/axel_project/style_sweep_1_1/test/visual_style/variant_matrix.gd.uid` (deleted)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Only canonical test helpers under `AXEL/axel_project/test/*` remain for these classes; mirror-path diagnostics should not recur from duplicate script copies.
- Verification: Mirror files absent from disk.

### Delete style_sweep_1_1 folder per request
- Request: Remove `AXEL/axel_project/style_sweep_1_1` from the repository tree.
- Implementation: Deleted the full `style_sweep_1_1` directory tree (including the recreated empty `test/` subtree).
- Files changed:
  - `AXEL/axel_project/style_sweep_1_1/` (removed)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No in-repo style-sweep output/mirror folder remains at `style_sweep_1_1`.
- Verification: `Test-Path AXEL/axel_project/style_sweep_1_1` returned `False`.

### Clear stale Godot cache references after style_sweep deletion
- Request: Duplicate-class diagnostic for deleted `style_sweep_1_1/test/visual_style/variant_matrix.gd` still persisted.
- Implementation: Cleared stale Godot editor/class index caches that still tracked removed project paths by deleting:
  - `.godot/editor/filesystem_cache10`
  - `.godot/editor/filesystem_update4`
  - `.godot/global_script_class_cache.cfg`
- Files changed:
  - `AXEL/axel_project/.godot/editor/filesystem_cache10` (deleted)
  - `AXEL/axel_project/.godot/editor/filesystem_update4` (deleted)
  - `AXEL/axel_project/.godot/global_script_class_cache.cfg` (deleted)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Godot rebuilds filesystem/class caches on next project refresh; stale references to removed `res://style_sweep_1_1/*` paths are dropped.
- Verification: `Test-Path` confirms deleted cache files are absent and `style_sweep_1_1/test/visual_style/variant_matrix.gd` remains absent.

### Pre-commit auto-fix for recurring CombatRoot duplicate-grid commits
- Request: Stop recurring git pre-commit blocks on `combat_test.tscn` duplicate `CombatRoot` grid overrides.
- Root cause: `combat_test.tscn` instances `combat_root.tscn` (which already owns `GridManager`/`GridUI`/overlay stack) but editor saves sometimes write the same nodes again as inline children under `CombatRoot`, creating duplicate runtime grid nodes.
- Implementation: Added `sanitize_duplicate_combat_root_grid()` in `tools/qa/canon_validators_shared.py` to strip inline guarded node blocks (and descendants) from staged scene text. Upgraded `check_combat_test_scaffold.py --staged` to auto-fix, `git add`, and re-validate before blocking. Added editor-only `_validate_editor_combat_root_structure()` in `combat_test.gd` (preview-on) using `QaCanonValidators`. Cleaned current `combat_test.tscn` to instance-only `CombatRoot`.
- Files changed:
  - `AXEL/axel_project/tools/qa/canon_validators_shared.py`
  - `AXEL/axel_project/tools/qa/check_combat_test_scaffold.py`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/qa/AXEL_CANON_CONSISTENCY_AUDIT.md`
  - `AXEL/axel_project/test/qa/README.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Commits with accidental inline CombatRoot grid duplicates are auto-healed when the scene is staged; commit still blocks if scaffold markers are missing or duplicates remain after sanitize. Editor preview stays enabled and surfaces structure drift via `push_error` before save/commit.
- Verification: `python AXEL/axel_project/tools/qa/check_combat_test_scaffold.py` (OK); `check_combat_test_scaffold.py --staged` (OK); `combat_test_scaffold_check.gd` (OK).

### Combat scaffold dedup persistence (runtime guard + validation)
- Request: Implement Combat Scaffold Dedup + Persistence Fix Plan — remove duplicate `CombatRoot` grid children, prevent reintroduction, validate scaffold + smoke.
- Root cause: `combat_test.tscn` instances `combat_root.tscn`; inline sibling nodes under `CombatRoot` duplicate `GridManager`/`GridUI`/overlay stack at runtime (`CombatRoot has 2× …` scaffold FAIL).
- Implementation: Confirmed scene uses instanced `CombatRoot` only (no inline grid stack blocks). Removed stale unused `grid_manager.gd` `ext_resource` from `combat_test.tscn`. Added `_warn_duplicate_combat_root_children()` in `combat_test.gd` (runtime + editor preview) mirroring `QaCanonValidators.COMBAT_ROOT_GRID_UNIQUE`. Documented pre-commit sanitizer cross-ref in `qa_canon_validators.gd`.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/test/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Duplicate grid nodes under `CombatRoot` log `push_error` on playtest load/preview; pre-commit Python guard continues to strip accidental inline overrides on staged commits.
- Verification: `python tools/qa/check_combat_test_scaffold.py` (OK); `combat_test_scaffold_check.gd` (OK); `scene_smoke_check.gd` (OK, 6 scenes). Prior `2× GridManager` failure cleared.

### QA re-sanitize combat_test grid duplicates (regression)
- Request: Simulated QA after scaffold dedup plan (`qa` / user yes).
- Implementation: QA playtest found inline `CombatRoot` grid stack had regressed in `combat_test.tscn` (editor re-save). Re-ran `sanitize_duplicate_combat_root_grid()`, removed `MultiplierLabel`/`MultiplierLabel2` inline overrides, extended sanitizer + runtime guard to include `MultiplierLabel`. Post-fix: scaffold + canon combat findings cleared.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/tools/qa/canon_validators_shared.py`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Verification: `check_combat_test_scaffold.py` OK; `combat_test_scaffold_check.gd` OK; `canon_consistency_audit.gd` — 2 minor movement findings only (Corridor speed/scale).

### Fix combat UI mojibake (Unicode-safe)
- Request: Fix random symbols in combat top-left icons and item box labels; harden tooling to prevent re-corruption.
- Root cause: `combat_test.tscn` stored mojibake (`Ã¢…`, `â¬¡`, etc.) after UTF-8 scene text was read via `subprocess.run(..., text=True)` on Windows (locale codepage decode) and rewritten as UTF-8 by `check_combat_test_scaffold.py` staged auto-fix.
- Implementation: Restored canonical Unicode glyphs in scene (`⬡`, `⌂`, `◇`, `✦`, `×`, `…` ellipsis in metadata). Scaffold checker now reads git blobs as bytes + strict UTF-8 decode. Added `check_mojibake_signatures()` guard in `canon_validators_shared.py`.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/tools/qa/check_combat_test_scaffold.py`
  - `AXEL/axel_project/tools/qa/canon_validators_shared.py`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Combat shell shows correct meta icons and item rarity prefixes; pre-commit blocks reintroduction of mojibake in staged `combat_test.tscn`.
- Verification: `python AXEL/axel_project/tools/qa/check_combat_test_scaffold.py` (OK); `combat_test_scaffold_check.gd` (OK). Manual F6 on `combat_test.tscn` recommended for visual confirm.

### Persistent Beginner-Fix Explanations Governance
- Request: Require agents to explain each fix in simple beginner coding terms (no metaphors), short and concise, so the user learns project structure across future chats.
- Implementation: Added mandatory post-fix teaching rule to always-on governance and mirrored it in `AI_DOCS.md` workflow + consistency checklist. Format locked to 3 bullets: Cause, Fix, What to learn.
- Files changed:
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Future AXEL chats should include a brief learning note after every implemented fix, using the same 3-bullet structure.
- Verification: Confirmed governance rule item 13 and `AI_DOCS.md` §9 step 9 + §13 checklist item use matching language and format.
- Notes: Governance-only change; no gameplay/runtime behavior changed.

### Non-Combat Scanline/Glitch Comparison Sweep
- Request: Plan and prototype three free animated scanline/white-noise/glitch post-FX options (old TV / Pip-Boy feel) for non-combat scenes, run Scene 1.1 screenshot comparison, and deliver screenshots for selection.
- Implementation: Added three test-only comparison shaders (CRT TV, VHS glitch burst, terminal CRT) with shared theme tint include (`axel` / `green` / `mono white`). Narrowed `variant_matrix.gd` to baseline + 3 options, extended `style_overlay_applier.gd` for theme uniforms and production baseline stack, updated capture README/manifest. Ran deterministic sweep on `1.1_SchoolExterior`.
- Files changed:
  - `AXEL/axel_project/test/visual_style/shaders/theme_post_fx.gdshaderinc`
  - `AXEL/axel_project/test/visual_style/shaders/option_1_crt_tv.gdshader`
  - `AXEL/axel_project/test/visual_style/shaders/option_2_vhs_glitch.gdshader`
  - `AXEL/axel_project/test/visual_style/shaders/option_3_terminal_crt.gdshader`
  - `AXEL/axel_project/test/visual_style/variant_matrix.gd`
  - `AXEL/axel_project/test/visual_style/style_overlay_applier.gd`
  - `AXEL/axel_project/test/visual_style/capture_scene_1_1_style_sweep.gd`
  - `AXEL/axel_project/test/visual_style/README.md`
  - `AXEL/axel_project/tools/visual_style/output/scanline_glitch_comparison/*.png`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Production runtime unchanged (`AxelPostFxStack` / combat exclusion untouched). Test harness can capture baseline vs 3 candidate stacks; option shaders support runtime theme switching via `AXEL_STYLE_THEME`.
- Verification: `run_scene_1_1_style_sweep.ps1` exit 0; 4 PNGs written to `%APPDATA%/Godot/app_userdata/AXEL/style_sweep_1_1` and copied to `tools/visual_style/output/scanline_glitch_comparison/`.
- Notes: Option 2 screenshot captured during an active glitch burst (RGB split visible); re-run with `$env:AXEL_STYLE_THEME="green"` to preview Pip-Boy phosphor on any option.

### Test Folder To Tools Migration
- Request: Move all `AXEL/axel_project/test/*` into `AXEL/axel_project/tools/*` while preserving subfolder structure; update runtime references and active docs; optimize repeated shader paths.
- Implementation: Git-moved `scene_smoke_check.gd`, `bots/`, `qa/` GDScript harness, and `visual_style/` (scripts + shaders) into `tools/` beside existing Python/PS1 tooling and style-sweep output. Updated all `res://test/` preloads, `#include` paths, and QA/style launchers to `res://tools/`. Added `SHADER_ROOT` constant in `variant_matrix.gd`. Refreshed active docs/rubrics (`AI_DOCS.md`, QA rubric, README, verification checklist). Removed OneDrive-resurrected duplicate `test/` tree from disk and repointed Godot `global_script_class_cache.cfg` entries for moved `class_name` scripts.
- Files changed:
  - `AXEL/axel_project/tools/scene_smoke_check.gd`
  - `AXEL/axel_project/tools/bots/*`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/tools/qa/canon_consistency_audit.gd`
  - `AXEL/axel_project/tools/qa/run_default_playtest.ps1`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/tools/visual_style/*`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/test/combat_test_scaffold_check.gd`
  - `README.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/qa/AXEL_CANON_CONSISTENCY_AUDIT.md`
  - `AXEL/axel_project/plans/qa/AXEL_QA_RUN_LOG.md`
  - `AXEL/axel_project/combat/VERIFICATION_CHECKLIST.md`
  - `AXEL/axel_project/plans/references/README_STRUCTURE.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No gameplay changes. QA bots, scene smoke, canon audit, and visual-style sweep now resolve under `res://tools/...`. Historical changelog entries retain prior `test/` paths.
- Verification: `res://tools/scene_smoke_check.gd` → `Scene smoke check OK (6 scenes).`; `res://combat/test/combat_test_scaffold_check.gd` → OK; `res://tools/qa/canon_consistency_audit.gd` → `CANON_AUDIT_JSON` emitted; both bot playthrough scripts exit 0; no `res://test/` references remain in active GDScript/PS1/Python.
- Notes: If Godot reports duplicate `class_name` after pull, delete any resurrected `test/` folder and reopen project so class cache rescans (or update `.godot/global_script_class_cache.cfg` paths to `res://tools/...`).

### Combat HUD Polish Pass
- Request: Polish combat HUD typography/alignment — single-row history log with larger fonts and ellipsis, items font parity, goal/meta alignment to side panels, stake indicator cleanup (no circle, bankroll-sized value, non-overlapping +/-), and remove white highlight/glow from winnings/multiplier readouts.
- Implementation: Updated responsive layout anchors so MetaBox left aligns with history panel and GoalBox right aligns with items panel right edge. History rows now render as one truncated line; side-panel headers scaled ~33% (24→32). Removed StakePill wrapper from scaffold; stake value uses bankroll typography; stake +/- buttons use transparent bordered style with reduced size. Winnings and cascade multiplier readouts drop white outline/halo styling in favor of red accent text only.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Combat test HUD reads cleaner at multiple resolutions; history never wraps to a second line; corner HUD columns share vertical alignment guides with side panels; stake controls stay in header band without pill chrome.
- Verification: `python AXEL/axel_project/tools/qa/check_combat_test_scaffold.py` exit 0; lints clean on `combat_test.gd`.
- Notes: User confirmed history overflow should truncate with ellipsis and goal alignment reference is items panel right edge.

### Remove Deleted Placeholder/Data Path References
- Request: User deleted `axel_project/data/` and `combat/art/placeholders/`; update references to the canonical symbol folder `combat/art/grid_symbols`.
- Implementation: Updated all `combat/data/symbols/sym_*.tres` files to remove `res://combat/art/placeholders/*` ext-resources and point `power_intro_texture` to the canonical grid texture ext-resource. Updated `combat/art/generate_placeholders.py` output folder to `grid_symbols` and refreshed combat README wording.
- Files changed:
  - `AXEL/axel_project/combat/data/symbols/sym_bloody_hand.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_blue_star.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_booze.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_cigarette.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_green_circle.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_red_heart.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_satanic.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_yellow_triangle.tres`
  - `AXEL/axel_project/combat/art/generate_placeholders.py`
  - `AXEL/axel_project/combat/README.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Symbol resources no longer depend on deleted placeholder files; generated symbol PNGs now go directly to the canonical `grid_symbols` folder.
- Verification: `rg "res://combat/art/placeholders/" AXEL/axel_project/combat` returns no matches after update.

### QA Recommendations Batch Implementation
- Request: Implement all four QA recommendations from combat HUD polish follow-up (Corridor profile, post-FX detach, HUD anchor smoke, manual HUD checklist).
- Implementation: Tuned `1.2_Corridor` Player to speed 150 / scale 0.82. Hardened `AxelPostFxStack` detach/attach with untyped freed-ref-safe overlay cleanup. Added HUD anchor validators in `qa_canon_validators.gd`, wired into `combat_test_scaffold_check.gd` (1280×720 + 800×600 hard gate) and post-layout `canon_consistency_audit.gd`. Added manual combat HUD verification checklist to QA rubric.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scripts/autoload/axel_post_fx_stack.gd`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/combat/test/combat_test_scaffold_check.gd`
  - `AXEL/axel_project/tools/qa/canon_consistency_audit.gd`
  - `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Corridor movement matches layout profile; scene transitions no longer log post-FX TypedArray errors; combat HUD anchor drift is caught automatically at two viewport breakpoints.
- Verification: canon audit 0 findings; scaffold check pass (wide+narrow); bot playthroughs pass without post-FX script errors; princess/determinism/scene smoke/item synergy pass.
- Notes: Manual HUD typography checklist remains operator step per rubric (not automatable).

## 2026-05-24

### Dual-PC Cursor Account Cutover Readiness Prep
- Request: Prepare the workspace for deleting the current Cursor account and continuing with a new account across two PCs (same OneDrive folder, GitHub as source of truth).
- Implementation: Captured pre-cutover git/governance baseline, created a dated cursor-context backup bundle with SHA256 manifest, recorded a git parity checkpoint commit for cross-machine verification, and generated a concrete handoff checklist plus PC2 parity script under the run backup folder.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
  - `tools/account_migration_backups/dual_pc_cutover_2026-05-24_133553/pc1_pre_cutover_state.txt`
  - `tools/account_migration_backups/dual_pc_cutover_2026-05-24_133553/governance_snapshot_hashes.txt`
  - `tools/account_migration_backups/dual_pc_cutover_2026-05-24_133553/backup_manifest.txt`
  - `tools/account_migration_backups/dual_pc_cutover_2026-05-24_133553/NEW_ACCOUNT_CUTOVER_CHECKLIST.md`
  - `tools/account_migration_backups/dual_pc_cutover_2026-05-24_133553/pc2_git_parity_check.ps1`
- Behavior impact: Gameplay/runtime unchanged. This is migration safety and continuity documentation only.
- Verification: `git status -sb` shows `main...origin/main`; `git rev-list --left-right --count origin/main...main` = `0 0`; required commit for both PCs is `c99e410edd8d3580ae5ba4bc4d09d649bddb341a`.
- Notes: New-account validation on PC1/PC2 remains a manual gate after account creation/login succeeds.

### Combat UI layout and typography pass
- Request: Align History/grid/Items top borders, remove grid-to-winnings slack while maximizing grid size, increase History log font ~50% and Items font ~25% without clipping, and left-align Items rows to match History indentation.
- Implementation: Raised play band (`LAYOUT_MAIN_Y0` 0.145→0.12), changed `GridHost` to shrink-to-content after grid fit, computed footer stack height so grid uses remaining center-column space, matched vertical gaps via `CENTER_COLUMN_SEPARATION`, added width-aware font scaling helpers, tightened item checkbox left alignment, and synced scene baselines.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Combat shell panels and grid top-align higher; grid grows to fill available center height; grid→winnings gap matches winnings→Execute spacing; History/Items body text scales up when panel width allows.
- Verification: GDScript linter clean on touched scripts; manual F6 review recommended at default and narrow widths.
- Notes: Font targets cap dynamically per panel inner width to avoid clipping.

### Combat play band moved downward
- Request: Correct combat shell vertical direction because History/grid/Items were moved up and started clipping against top HUD.
- Implementation: Moved play band start downward by updating shared runtime + scene baseline (`LAYOUT_MAIN_Y0` and `PlayArea.anchor_top`) from `0.12` to `0.16`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: History panel, combat grid, and Items panel sit lower and no longer collide with top-level HUD row.
- Verification: GDScript linter clean on touched script file.
- Notes: Keeps prior spacing/typography improvements while correcting only vertical placement direction.

### Combat-only context routing (new-chat token reduction)
- Request: Implement concept-specific context routing so new chats load minimal relevant guidance (combat-only v1), ask on ambiguity, and avoid cross-domain context unless explicitly unlocked.
- Implementation: Added routing contract (`AGENT_CONTEXT_ROUTING.md`) with keyword triggers, confidence table, strict combat lock, and unlock phrases. Added compact combat pack (`context_packs/COMBAT_MIN_CONTEXT.md`). Wired always-on governance rule (new item 1: classify first message, load pack, clarify on low confidence). Registered workflow in `AI_DOCS.md` §9 Context routing subsection.
- Files changed:
  - `AXEL/axel_project/plans/core/AGENT_CONTEXT_ROUTING.md` (new)
  - `AXEL/axel_project/plans/core/context_packs/COMBAT_MIN_CONTEXT.md` (new)
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No gameplay/runtime changes. New chats should load combat min context instead of scene/narrative arc docs when combat keywords match; ambiguous prompts should trigger bundle clarification; cross-domain work requires explicit `unlock <bundle>`.
- Verification: Prompt-routing matrix (expected behavior):
  - `Fix wild spawn on 3-line wins in combat_root` → confident combat, load pack, no scene docs.
  - `Tune C1 ash reroll RTP` → confident combat (weak×2+), load pack.
  - `combat: reduce bankroll drain on stake` → fast-path combat, load pack.
  - `Make the schoolyard feel darker` → low confidence / not combat → ask bundle, no Arc_1 load.
  - `Update dialogue in 1.1 schoolyard` → not combat → ask bundle.
  - `After combat win, load 1.2 corridor` → cross-domain → combat primary + ask before `unlock scenes`.
  - `Run qa` → QA opt-in unchanged; full playtest not auto-loaded under combat lock unless requested.
  - `What is AXEL about?` → low confidence → ask bundle.
- Rollback: Remove governance rule item 1 and AI_DOCS Context routing subsection; delete routing doc and combat pack; restore prior governance numbering.
- Notes: Builds on 2026-05-11 chat-efficiency work (pointer-first governance, `.cursorignore`). Future bundles: scenes, narrative, qa_tools, visual_style per routing doc §9.

### Context routing phase 2: scenes/narrative/vfx packs + aggressive ignore
- Request: Extend routing with `scenes`, `narrative`, and visual-effects packs; add colon prefixes (`vfx:` → `visual_style`); aggressively expand `.cursorignore` while preserving canonical gameplay sources.
- Implementation: Added three min context packs (`SCENES_MIN_CONTEXT.md`, `NARRATIVE_MIN_CONTEXT.md`, `VISUAL_STYLE_MIN_CONTEXT.md`). Expanded `AGENT_CONTEXT_ROUTING.md` with per-bundle keyword tables, prefix fast-paths, strict locks, and indexing notes. Updated governance rule item 1 for all prefixes and unlock semantics. Updated `AI_DOCS.md` §9 context-routing bullets. Extended `.cursorignore` with migration backups, Godot cache/sidecars, tool previews, export captures, `logs/**`, and `AXEL/html/pictures/**`.
- Files changed:
  - `.cursorignore`
  - `AXEL/axel_project/plans/core/AGENT_CONTEXT_ROUTING.md`
  - `AXEL/axel_project/plans/core/context_packs/SCENES_MIN_CONTEXT.md` (new)
  - `AXEL/axel_project/plans/core/context_packs/NARRATIVE_MIN_CONTEXT.md` (new)
  - `AXEL/axel_project/plans/core/context_packs/VISUAL_STYLE_MIN_CONTEXT.md` (new)
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No gameplay/runtime changes. New chats route to one of four domain packs; `vfx:` loads visual_style pack; indexed noise reduced (~logs, cache, previews, drawings, html pictures). Narrative/scene tasks needing prototype art should `@`-mention excluded image paths.
- Verification: Prompt-routing matrix (expected behavior):
  - `scenes: layout 1.2 corridor path bands` → fast-path scenes pack.
  - `Position schoolyard interact near door in 1.1` → confident scenes, no combat catalog.
  - `narrative: fix true ending flag check` → fast-path narrative pack.
  - `Add memory for basement key in game_data` → confident narrative, no scene-builder drafts.
  - `vfx: reduce scanline intensity on overworld` → fast-path visual_style (`vfx:` alias).
  - `Tune noir palette on AxelPostFxStack` → confident visual_style, no combat RTP docs.
  - `Fix wild spawn in combat_root` → confident combat (unchanged).
  - `combat: tune C1 RTP` → fast-path combat (unchanged).
  - `Make it darker` → low confidence → ask bundle.
  - `Combat win then transition to 1.2 corridor` → cross-domain → primary + ask `unlock scenes`.
  - `What is AXEL?` → low confidence → ask bundle.
- Rollback: Restore prior `.cursorignore`; delete three new packs; revert routing doc, governance item 1, and AI_DOCS §9 bullets to combat-only v1.
- Notes: `qa_tools` bundle remains reserved. `exports/Drawings/**` and `html/pictures/**` excluded from index by design — use explicit file mentions when needed.

### Scene 1.2 corridor visual replacement
- Request: Replace Scene 1.2 corridor picture and decorative assets with `exports/Drawings/1.2_Corridor.png`; keep collision borders unchanged; defer background Y alignment.
- Implementation: Swapped `Background` to a `Sprite2D` using the exported drawing; removed locker/graffiti/debris/floor/light visual stacks; simplified `1.2_Corridor.gd` to layout + dialogue + push-in tween; exposed `BACKGROUND_Y` constant for follow-up tuning.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Corridor renders as a single full-scene drawing (2400×1500, cover-scaled to 1280×720); all wall/locker colliders and player/dialogue nodes unchanged; ceiling flicker and locker highlight effects removed.
- Verification: Headless `res://tools/scene_smoke_check.gd` — OK (6 scenes).
- Notes: Set `BACKGROUND_Y` in `1.2_Corridor.gd` when user provides correct vertical alignment.

### API usage optimization (lanes, meta routing, token budget)
- Request: Implement API usage optimization plan — reduce token burn while preserving agent effectiveness.
- Implementation: Added two-lane chat protocol and validation tracker; trimmed always-on governance rule to pointers; registered `meta_process` bundle with `meta:` prefix; added `AI_DOCS.md` §15 token budget/turn economy; minified all four domain context packs; linked compact handoff vs full premium template.
- Files changed:
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AGENT_CONTEXT_ROUTING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/CHAT_LANE_PROTOCOL.md` (new)
  - `AXEL/axel_project/plans/core/API_USAGE_VALIDATION_TRACKER.md` (new)
  - `AXEL/axel_project/plans/core/context_packs/COMBAT_MIN_CONTEXT.md`
  - `AXEL/axel_project/plans/core/context_packs/SCENES_MIN_CONTEXT.md`
  - `AXEL/axel_project/plans/core/context_packs/NARRATIVE_MIN_CONTEXT.md`
  - `AXEL/axel_project/plans/core/context_packs/VISUAL_STYLE_MIN_CONTEXT.md`
  - `AXEL/axel_project/plans/core/PREMIUM_TO_AUTO_HANDOFF_TEMPLATE.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No gameplay/runtime changes. Agents should use Lane A/B split, `meta:` for process chats, shorter governance injection, smaller packs, and §15 turn limits. User fills `API_USAGE_VALIDATION_TRACKER.md` over next 10 tasks to confirm quality.
- Verification: Routing matrix — `meta: reduce API usage` → §1b, no domain pack; `scenes: implement: …` → scenes pack + lane B; governance rule line count reduced (~29 → ~18 substantive lines).
- Notes: Rollback per tracker rollback triggers or restore pre-minification packs from git history.

## 2026-05-28

### Upgrade Godot editor to 4.6.3
- Request: Download and install Godot 4.6.3; update repo references for a seamless switch from 4.6.2.
- Implementation: Downloaded official `Godot_v4.6.3-stable_win64.exe.zip` from GitHub releases, extracted editor + console binaries to repo root, pointed `tools/cmd/godot.cmd` and VS Code Godot Tools paths at 4.6.3, removed 4.6.2 binaries and the zip artifact.
- Files changed:
  - `Godot_v4.6.3-stable_win64.exe` (new)
  - `Godot_v4.6.3-stable_win64_console.exe` (new)
  - `tools/cmd/godot.cmd`
  - `tools/Godot.code-workspace`
  - `.vscode/settings.json`
  - `AXEL/.vscode/settings.json`
  - `README.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: CLI wrappers and editor integration use Godot 4.6.3 maintenance build; no project script changes required (4.6.x compatible).
- Verification: `Godot_v4.6.3-stable_win64.exe --version` → `4.6.3.stable.official.7d41c59c4`; `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd` → `Determinism check OK`.
- Notes: Historical changelog entries still cite 4.6.2 console invocations where recorded at implementation time.

### Player alpha-channel collision from Mike sheet
- Request: Use sprite alpha as the player collision outline so the hitbox fits the visible model.
- Implementation: Extended `Player.gd` with runtime alpha extraction from the assigned sprite sheet (`mike_walking-Sheet.png` in Arc 1 scenes). On `_ready`, builds a `BitMap` from frame alpha (union of all 13 walk frames by default), converts to `ConvexPolygonShape2D` via `opaque_to_polygons`, replaces scene `CollisionShape2D` circle children, and anchors shapes to `AnimatedSprite` position with frame-center offset. Exports: `use_alpha_collision`, `collision_use_all_frames_union`, `collision_frame_index`, `collision_alpha_threshold`, `collision_polygon_epsilon`. Scene circle shapes remain as fallback if image read fails.
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Player physics outline matches Mike’s painted silhouette across walk animations; no per-scene hitbox hand-tuning required.
- Verification: Headless Godot test — `get_image()` on imported sheet (832×64), union bitmap → 1 polygon (~38 vertices) at 64×64 cell size.
- Notes: `mike_walking.png` is not in repo; collision uses the same sheet texture already assigned on `Player`. Toggle `collision_use_all_frames_union` off to use a single frame only.

### Smooth alpha collision to reduce wall snagging
- Request: Curved/smoothed player collision edges; raw alpha polygon gets stuck on environment borders.
- Implementation: Extended `Player.gd` alpha collision pipeline with (1) bitmap erosion (`collision_alpha_shrink_pixels`, default 2) before tracing, (2) higher default trace simplification (`collision_polygon_epsilon` 3.0), (3) Chaikin corner smoothing (`collision_smooth_iterations`, default 2) + `Geometry2D.convex_hull`, and (4) inward margin inset (`collision_inward_margin`, default 1.5 px) so the collider slides off sharp world geometry.
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Player hitbox stays alpha-derived but with rounded, slightly smaller outline; should snag less on rock/stump/door polygons while still blocking the visible body.
- Verification: `ReadLints` clean on `Player.gd`.
- Notes: Tune on `Player` inspector — increase `collision_alpha_shrink_pixels` / `collision_inward_margin` if still sticky; set `collision_smooth_iterations` to 0 to disable curve pass only.

### Harden alpha collision setup (editor crash guard)
- Request: Godot crashed after collision smoothing changes; re-verify and stabilize.
- Implementation: Deferred collision shape replacement to next frame (`call_deferred`), replaced `free()` with `remove_child` + `queue_free`, skip erosion when it empties the mask, validate polygon area/vertex count (decimate cap), circle fallback from bitmap bounds, and null-safe door `InteractArea` lookup in `1.1_SchoolExterior.gd` (node removed from scene).
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Safer collision rebuild at runtime; scene 1.1 no longer errors on missing door interact node (door E/Space transition inactive until Area2D restored).
- Verification: Headless `--scene res://scenes/Arc_1/1.1_SchoolExterior.tscn --quit-after 8` exits 0 without node errors.

### Lower-body-only player collision (waist cut)
- Request: Remove collision above the waist; keep roughly the lower half of the sprite for hitbox from current perspective.
- Implementation: Added `collision_lower_body_ratio` (default `0.5`) to `Player.gd`; alpha bitmap is clipped to the bottom portion of each frame before trace/smooth/apply.
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Player collides with legs/feet zone only; upper body and arms no longer snag on rocks/door borders.
- Notes: Raise toward `0.55`–`0.6` on `Player` if waist cut feels too high; lower toward `0.4` for feet-only.

### School exterior viewport black backdrop
- Request: Add black backdrop so grey default clear color does not show when camera moves past background PNG edges.
- Implementation: Added `BackdropLayer` (`CanvasLayer` -199, follow viewport) with fullscreen black `ColorRect` behind world content in `1.1_SchoolExterior.tscn`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Areas outside the scaled school drawing render black instead of grey; noir post-FX no longer remaps void edges into red fringe lines at bottom/right.
- Verification: Manual — pan camera to bottom/right limits with and without `AXEL_DISABLE_POST_FX=1`; void should stay black.

### School exterior camera limits (remove backdrop)
- Request: Remove black backdrop; tighten camera limits so viewport stays within background art bounds.
- Implementation: Removed `BackdropLayer`/`BlackFill`. Recomputed camera limits from scaled `1.1_SchoolExterior.png` bounds (3520² at ~0.335/0.321 scale): vertical limits `153`–`384`, horizontal locked at `fixed_x = 622` (background center; art narrower than 1400px viewport).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Camera no longer pans past top/bottom of background; horizontal position centered on art. Small side void may remain because drawing width (~1179px) is less than viewport width (1400px).
- Verification: Manual — walk to bottom/right; grey void below art should no longer appear.

### Restore camera follow + 10% tighter limits
- Request: Restore vertical camera follow; tighten original camera bounds by total 10% (5% per side); keep CRT vignette/fisheye screen-constant during movement.
- Implementation: Reverted hard-lock camera setup (`fixed_x`/`limit_left`/`limit_right` at 622, tight Y 153–384). Restored `fixed_x = 640` and set limits to `left=10`, `top=-241`, `right=1270`, `bottom=812`. Added Y clamp in `camera_follow_vertical.gd` so follow respects limits. Verified CRT uses `SCREEN_UV` in fullscreen overlay (screen-space, camera-independent).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/camera_follow_vertical.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Camera follows player vertically again within slightly tighter play bounds; CRT curve/vignette remain fixed to viewport while world scrolls.
- Verification: Headless `--quit-after 3` on `1.1_SchoolExterior.tscn` exits 0.

### School exterior right-edge crop (+5%)
- Request: Red line bar gone from bottom but still on right; tighten visible window from the right by another 5%.
- Implementation: Previous `limit_right` did not affect view because camera X is fixed. Shifted `fixed_x` from `640` to `500` (140px total / 10% of original 1400px range: prior 5% + extra 5% from right) and set `limit_right` to `1200` so visible right edge moves from ~1340 to ~1200.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Viewport shows ~70px less content on the right; vertical follow unchanged.
- Verification: Manual — check right edge no longer shows background void/red bar.

### School exterior left-edge crop (~7%)
- Request: After right crop, red void lines appeared on top-left/bottom-left; crop from the left by ~7% the same way.
- Implementation: Shifted `fixed_x` from `500` to `598` (+98px, 7% of original 1400px view width) and `limit_left` from `10` to `108`. Visible left edge moves from ~-200 to ~-102.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: ~98px less content visible on the left; vertical follow unchanged. Visible right edge shifts to ~1298.
- Verification: Manual — confirm left corner void/red lines are reduced.

### Balance horizontal camera crop (left/right)
- Request: Right red line returned after left crop; balance both sides.
- Implementation: Set `fixed_x` to midpoint `549` (between right-biased `500` and left-biased `598`); `limit_left` to `59`. Visible edges ~`-151` left / ~`1249` right.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Compromise crop hides void on both corners without fully favoring one side.
- Verification: Manual — check top-left, bottom-left, and right edges.

## 2026-05-29

### Unlink left/right wall collision shapes (1.1)
- Request: Left and right wall collision boundaries were linked; unlink so each can be positioned independently.
- Implementation: Duplicated shared `RectangleShape2D_wall_vertical` into `RectangleShape2D_wall_vertical_left` and `RectangleShape2D_wall_vertical_right`; each `CollisionShape2D` now references its own sub-resource (Godot edits to shape size no longer propagate across walls).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Runtime collision unchanged until shapes are edited in the editor; left/right wall shape/size can now be tuned separately.
- Verification: Manual — move or resize one wall collider in Godot; confirm the other does not follow.

### Arc 1 forced intro sequence (1.1 School Exterior)
- Request: Scripted pre-dialogue flow — glitch, walk to stones, Option 1 interface pulse, first dialogue, unlock player, second non-blocking dialogue after ~50px movement.
- Implementation: Replaced auto three-line intro with `IntroState` sequence in `1.1_SchoolExterior.gd` (glitch overlay → scripted walk to `Rocks_Right` → CRT TV interface pulse → first line → unlock → distance-triggered second line via `show_line_nonblocking`). Added `Player.gd` input lock/scripted velocity API. Added `IntroGlitchOverlay` (VHS) and `InterfacePulseOverlay` (Option 1 CRT TV) under `scenes/fx/`. Extended `TopDialogueOverlay.show_line_nonblocking`. Bot: phase A asserts intro unlock; phase B reloads with `AXEL_SKIP_INTRO` for door regression.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/fx/intro_glitch_overlay.gd`
  - `AXEL/axel_project/scenes/fx/IntroGlitchOverlay.tscn`
  - `AXEL/axel_project/scenes/fx/interface_pulse_overlay.gd`
  - `AXEL/axel_project/scenes/fx/InterfacePulseOverlay.tscn`
  - `AXEL/axel_project/tools/bots/playthrough_arc1_exterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: New game on 1.1 plays forced intro before player control; `AXEL_SKIP_INTRO=1` bypasses sequence. Second dialogue does not lock movement. Door interact still requires `1.1_EnvironmentPlaceholders/..._InteractArea` node in scene (not present in `.tscn` yet).
- Verification: Headless bot phase A — intro unlock OK (~586 frames). Phase B door overlap still fails until interact area is placed in editor.
- Notes: Tune `_STONES_STAND_OFFSET` / `_STONES_ARRIVE_DISTANCE` in editor if stand position needs adjustment.

### Arc 1 intro reorder (glitch → wait → distortion + short left walk)
- Request: Reorder intro to glitch → 1s wait → interface distortion during very short walk to left stones → dialogue; keep glitch and interface as separate effects; preserve unlock + movement-triggered second line.
- Implementation: Reordered `_run_forced_intro_sequence()` in `1.1_SchoolExterior.gd`; retargeted walk to `Rocks_Left` with shorter caps (`_SCRIPTED_WALK_MAX_FRAMES` 96, arrive 36px). Added `start_distortion()` / `stop_distortion()` on `interface_pulse_overlay.gd` so CRT TV pulse runs only during the walk and ends on arrival.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/fx/interface_pulse_overlay.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Intro is shorter; distortion is concurrent with left-stone walk, not a separate post-walk beat. Post-dialogue unlock + 50px second line unchanged.
- Verification: Headless bot phase A — intro unlock OK (~370 frames). Phase B door overlap unchanged (interact area node still absent in `.tscn`).

### Global Event FX system (AxelEventFx)
- Request: Implement global event FX — scene-transition glitch on all non-combat scenes, global API for events/jumpscares, interface pulse cadence (30–60s OR 40–90 walk steps, shared cooldown), and persist agent knowledge in canon docs.
- Implementation: Added `AxelEventFx` autoload owning `IntroGlitchOverlay` + `InterfacePulseOverlay`. Scene-enter glitch on non-combat transitions (1.1 intro opt-out). Public API: `play_glitch_burst`, `play_interface_pulse`, `start/stop_interface_distortion`, `play_jumpscare`, `set_cadence_enabled`, `register_walk_step`. Cadence scheduler with shared 30s cooldown. `Player.gd` reports walk steps (8px threshold, input-enabled only). Migrated `1.1_SchoolExterior` off embedded overlays to autoload API. Bot sets `AXEL_DISABLE_EVENT_FX=1` for deterministic passive FX. Added `plans/references/AXEL_OVERWORLD_EVENT_FX.md`; updated `AI_DOCS.md` §6, visual_style/scenes context packs, routing keywords, governance rule.
- Files changed:
  - `AXEL/axel_project/scripts/autoload/axel_event_fx.gd`
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/tools/bots/playthrough_arc1_exterior.gd`
  - `AXEL/axel_project/plans/references/AXEL_OVERWORLD_EVENT_FX.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/context_packs/VISUAL_STYLE_MIN_CONTEXT.md`
  - `AXEL/axel_project/plans/core/context_packs/SCENES_MIN_CONTEXT.md`
  - `AXEL/axel_project/plans/core/AGENT_CONTEXT_ROUTING.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: All non-combat scene transitions play a brief enter glitch. While exploring, interface CRT pulses fire randomly by time or walking. Scenes call `AxelEventFx` for scripted glitch/jumpscare beats. 1.1 intro unchanged in flow but uses global API; cadence paused during intro.
- Verification: Headless scene smoke + arc1 exterior bot (with `AXEL_DISABLE_EVENT_FX=1`).

## 2026-06-02

### 1.1 intro walk-in from off-screen left
- Request: Rework 1.1 starting animation so the player spawns hidden off the left edge, walks in at half speed, and stops between `Rocks_Left` `CollisionPolygon2D2` and `CollisionPolygon2D3`.
- Implementation: Moved player spawn to `(-200, 402)`. Scripted walk uses `_SCRIPTED_WALK_SPEED_SCALE` (0.5) and a higher frame cap. Stand target is the midpoint of the two named rock polygon centroids. `LeftWall` collider is disabled during the intro walk and re-enabled before dialogue unlock. Skip-intro (`AXEL_SKIP_INTRO=1`) teleports the player to the stand target.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Intro opens with the player entering from off-screen left at reduced speed, stopping between the two left rock colliders; normal wall collision resumes after the scripted beat.
- Verification: Manual playtest of `1.1_SchoolExterior` intro sequence recommended.

### Always-on interference wave (global)
- Request: Keep the CRT interference “wave” on at all times at a reduced level so it blends with the scene look; surges should rise from that baseline instead of popping in from zero. Reduce surge peak by ~20%. Apply globally to non-combat overworld.
- Implementation: `InterfacePulseOverlay` now supports ambient baseline (`BASELINE_ALPHA` 0.30) and surge peak (`SURGE_ALPHA` 0.80). `AxelEventFx` enables ambient on non-combat scene enter and disables on combat/disabled/style-sweep paths. Scripted intro and cadence pulses still fire but settle back to baseline.
- Files changed:
  - `AXEL/axel_project/scenes/fx/interface_pulse_overlay.gd`
  - `AXEL/axel_project/scripts/autoload/axel_event_fx.gd`
  - `AXEL/axel_project/plans/references/AXEL_OVERWORLD_EVENT_FX.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Non-combat overworld always shows a faint CRT interference wave. Intro walk and random cadence surges are softer and no longer visually separate from the baseline scene.
- Verification: Manual playtest of 1.1 intro walk + free movement cadence recommended.

### Scene 1.1 Pathetic line timing + dialogue font bump
- Request: Restore the third intro beat ("Pathetic.") so it arrives 1.5s after "Yet, here we are..." finishes typing; enlarge dialogue box font by 33%.
- Implementation: Added `TopDialogueOverlay.type_line()` — fade-in + typewriter that returns with the line still visible, enabling precise beat timing from scene scripts. `1.1_SchoolExterior.gd` chains line 2 (movement-gated) → 1.5s beat → "Pathetic." → tail hold → fade out via `_play_second_then_pathetic()`. Dialogue font size 24 → 32 (~33%), outline 3 → 4, bar height offset -128 → -148.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: After the player walks away from the unlock point, line 2 types, holds 1.5s, then "Pathetic." types on the same bar before fading out. All dialogue using `TopDialogueOverlay` renders at the larger font size.
- Verification: Manual playtest of 1.1 intro — walk away after line 1, confirm 1.5s beat before "Pathetic." and font legibility at 32px.

### TopDialogueOverlay FX suite + dev preview
- Request: Add independently toggleable dialogue-box effects (block typewriter cursor, slide-up entrance, two-layer panel chrome, line-swap micro-glitch, border pulse while typing) with easy per-effect fallback and a dev preview scene to test each in isolation.
- Implementation: Extended `TopDialogueOverlay.gd` with five `@export var fx_*` booleans (default ON, read at line-show time). Refactored fade-in into `_fade_in()`; added blinking block cursor (`_compose` + `_process`), slide-up tween on show/hide, `InnerPanel` inset chrome with `StyleBoxEmpty` fallback, ~0.12s scramble on line swap before typewriter, and looping border-alpha pulse during typing (stops on completion). Added dev-only `TopDialogueOverlayFxPreview.tscn` — keys 1–5 toggle effects live, Space replays the two-line sample sequence.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlayFxPreview.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlayFxPreview.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: All overworld dialogue using `TopDialogueOverlay` gets CRT-terminal polish by default. Any effect can be disabled per overlay instance via Inspector (`fx_* = false`) or toggled at runtime in the preview scene. Scene 1.1 inherits defaults unless overridden on its overlay instance.
- Verification: Play `TopDialogueOverlayFxPreview.tscn` directly — toggle keys 1–5 individually, Space to replay sample; confirm line-swap glitch fires between lines 2 and 3.

### Dialogue FX defaults + bottom anchor lock
- Request: Keep only line-swap glitch and two-layer chrome in production; restore bottom-of-screen placement with a small gap from the viewport edge.
- Implementation: Set `TopDialogueOverlay` defaults to `fx_chrome=true`, `fx_line_swap_glitch=true`; cursor, slide-up, and border-pulse default OFF. Added `_lock_bottom_layout()` (24px bottom gap, bottom-wide anchor, position reset) called from `_ready`, `_fade_in`, and `hide_line`. Removed redundant per-scene FX overrides from `1.1_SchoolExterior.tscn`.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlayFxPreview.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Dialogue bar sits at the bottom with 24px padding; only chrome inset and line-swap scramble run by default. Other FX remain available via Inspector or preview toggles.
- Verification: Play `1.1_SchoolExterior` or `TopDialogueOverlayFxPreview.tscn` — confirm bar hugs bottom edge; keys 1/2/5 OFF by default.

### Dialogue bar bottom anchor fix (ViewportRoot)
- Request: Dialogue box still appeared at top of screen; set bottom gap to 12px.
- Implementation: Added full-viewport `ViewportRoot` under `CanvasLayer` (matches FX overlay pattern). Rewrote `_lock_bottom_layout()` to use bottom-wide `offset_*` only — removed `position` writes and `PRESET_MODE_KEEP_SIZE`. Added `@export bottom_gap_px := 12.0`, deferred layout until after first frame, and `size_changed` hook. Slide-up (when enabled) tweens offsets instead of `position.y`. Set `follow_viewport_enabled = true` on the layer.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Dialogue bar pins to the bottom of the viewport with a 12px gap (tunable via Inspector). Resizes correctly with the window.
- Verification: Play `TopDialogueOverlayFxPreview.tscn` and `1.1_SchoolExterior` — bar at bottom, not top; resize window to confirm.

### Combat HUD white text + grey shadow
- Request: Off-white colors in combat phase should be fully white, with a small dark grey shadow behind them for separation from the background.
- Implementation: Added `_apply_white_hud_text_style()` in `combat_test.gd` (pure white fill, no outline, 1px dark-grey shadow) and applied it to bankroll/stake/goal readouts, spin history rows, and encounter-win overlay. Updated `symbol_slot` winnings popup to match (shadow only). Synced `EncounterWinLabel` / `EncounterWonLabel` scene overrides.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/combat_test_scaffold_baseline.tscn`
  - `AXEL/axel_project/combat/scenes/combat_root.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Combat HUD text that was pink-tinted off-white or light grey now reads as clean white with subtle grey depth on black panels; red text outlines on those elements are removed.
- Verification: Open `combat_test.tscn` — check bankroll/goal, history rows after spins, encounter-win overlay, and per-symbol win popups on the grid.

### TopDialogueOverlay screen anchor (follow_viewport revert)
- Request: Dialogue box clipped on the left (border hidden) and sitting too high above the bottom after the ViewportRoot bottom-anchor work.
- Implementation: Set `follow_viewport_enabled = false` on the `TopDialogueOverlay` `CanvasLayer`. Screen-space UI must not follow the world camera; `ViewportRoot` + `_lock_bottom_layout()` already pins the bar (28px side inset, 12px bottom gap).
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Overworld dialogue bar stays viewport-bottom-centered with visible borders; no longer drifts with `Camera2D` in scenes like `1.1_SchoolExterior`.
- Verification: Play `1.1_SchoolExterior` intro — bar ~12px from bottom, centered, left red border visible.

### Deferred AI docs flush at chat finish
- Request: Batch all AI memory-layer writes (changelog, canon/plan docs, governance, beginner teaching) until chat finish — triggered by `update docs` or equivalent wrap-up, not after each implement.
- Implementation: Added **Deferred docs flush** subsection to `AI_DOCS.md` §9 with Pending Docs Buffer schema, flush triggers, and carry-forward rules. Revised workflow steps, §13 checklist, and §15 turn economy. Updated governance rule item 5, `CHAT_LANE_PROTOCOL.md` (Lane B flow + handoff `Pending docs` / `Docs flush` fields), `AGENT_CONTEXT_ROUTING.md`, `AI_CHANGELOG.md` logging policy, and pointer lines in handoff/scene/FX specs.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/CHAT_LANE_PROTOCOL.md`
  - `AXEL/axel_project/plans/core/AGENT_CONTEXT_ROUTING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
  - `AXEL/axel_project/plans/core/PREMIUM_TO_AUTO_HANDOFF_TEMPLATE.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/plans/references/AXEL_OVERWORLD_EVENT_FX.md`
- Behavior impact: Agents queue memory-layer updates in chat during long sessions; flush on explicit ship phrases (`update docs`, `ship docs`, `flush docs`, `finish chat`, `meta: update docs`) or confirmed wrap-up. Reduces mid-chat doc churn and token burn. QA persistence unchanged.
- Verification: `rg "changelog on implement"` across `plans/` and `.cursor/rules/` — no active governance hits (historical changelog text only).
- Notes: User may waive with `skip docs`. Lane B handoff must carry `Pending docs:` block when buffer non-empty.

### Dialogue CRT power on/off + 1.1 stay-on intro
- Request: Dialogue box should CRT power on, play all lines, then shut off; scene 1.1 must not power off between line 1 and movement-gated lines 2–3.
- Implementation: Added `fx_crt_power` (default ON) with `_crt_power_on()` / `_crt_power_off()` — vertical scale expand/collapse on `BarPanel` plus additive `PowerBeam` flash. Routed `_fade_in()` / `hide_line()` through CRT when enabled. `1.1_SchoolExterior` uses `type_line()` for line 1 (stays on) instead of `show_line()` (auto shut-off). Preview key `6` toggles CRT.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlayFxPreview.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Overworld dialogue CRT-snaps on and collapses off at session end. Scene 1.1 holds the box through line 1 until the player walks away, then in-place line swap to lines 2–3, single shut-off after "Pathetic." tail hold.
- Verification: Play `TopDialogueOverlayFxPreview.tscn` (key 6 toggles CRT); headless arc1 exterior phase A; manual `1.1_SchoolExterior` intro.

### Dialogue CRT multi-stage turn-on + canon recolor
- Request: CRT power-on felt too simplistic; remove pinkish beam tint; use white/black/canon red for an authentic old-TV warm-up.
- Implementation: Replaced single scale pop with multi-stage `_crt_power_on()` (dot hold → horizontal streak → vertical open with BACK overshoot → red bloom settle → alpha flicker) and mirrored `_crt_power_off()` (collapse to line → bloom flash → shrink to dot → afterglow/dark). `PowerBeam` recolored to white; added additive red `Bloom` overlay on `BarPanel`. No SubViewport; layout anchors unchanged.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Dialogue box reads as CRT warming up (~0.55s on, ~0.46s off) with white scan line and red phosphor flash; pink beam removed.
- Verification: `TopDialogueOverlayFxPreview.tscn` (Space + key 6); headless arc1 exterior phase A.

### Changelog YYYY-MM-DD day sections
- Request: Make the changelog use a `YYYY-MM-DD` date format.
- Implementation: Regrouped 209 entries into 13 ISO date sections (`## YYYY-MM-DD` once per day, `###` per change). Updated logging policy, entry template, `AI_DOCS.md`, and governance rule.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
- Behavior impact: Easier scan by calendar day; new appends go under the matching `## YYYY-MM-DD` block (or add a new day section at the bottom).
- Verification: All 209 historical entries preserved; 13 unique `## YYYY-MM-DD` headings; template and policy match structure.

### Prompting cost cut (lean canon)
- Request: Collapse meta-governance to cut premium API use; drop QA prompting layer; archive heavy changelog workflow.
- Implementation: Rewrote `AI_DOCS.md` to lean canon (~60 lines) with chat workflow table. Trimmed `.cursor/rules/axel-ai-docs-governance.mdc`. Removed routing/lanes/context packs/handoff/API tracker docs, simulated QA skill + rubric/checklist/run-log/analytics, and `update_qa_analytics.py`. Kept headless `tools/qa/*` scripts and bots. Updated subsystem doc pointers (`VERIFICATION_CHECKLIST`, `README_gd_scripts`, bots README, `README_STRUCTURE`).
- **Pre-plan (removed):** Brief §Pre-plan + governance one-liner were added then dropped — explore is not agent-governed; the author uses a paste-in template on Auto instead (below).
- **Author explore template (going forward):** superseded by beginner template — see `### Beginner explore template` below (same day).
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - Deleted: `AGENT_CONTEXT_ROUTING.md`, `CHAT_LANE_PROTOCOL.md`, `PREMIUM_TO_AUTO_HANDOFF_TEMPLATE.md`, `API_USAGE_VALIDATION_TRACKER.md`, `context_packs/*`, `plans/qa/*` (LLM-facing QA docs), `.cursor/skills/axel-simulated-qa/`, `tools/qa/update_qa_analytics.py`
- Behavior impact: Agents load minimal always-on canon; no mandatory QA reports, docs flush buffers, or multi-turn planning intake gates. Explore step is user-templated on Auto, not a governance keyword. Manual playtest script unchanged.
- Verification: Grep confirmed no `.gd`/`.py` dependencies on deleted QA analytics; `run_default_playtest.ps1` contract intact.

### CRT interact prompt at 1.1 door
- Request: World-anchored `[E]` interact chip with dialogue-matching CRT power-on/off when player enters door interact area.
- Implementation: Extracted shared `crt_power_fx.gd` (`power_on` / `power_off` / `reset_visual`); refactored `TopDialogueOverlay` to use it. Added `InteractPromptOverlay` (CanvasLayer 111, VT323 chip, beam/bloom) with world-to-screen anchor tracking. Instanced in `1.1_SchoolExterior`; wired `DoorInteractArea` body_entered/exited and transition hide. Door interact area already on `EnvironmentColliders/Doors` polygon from prior session.
- Files changed:
  - `AXEL/axel_project/scenes/ui/crt_power_fx.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/ui/InteractPromptOverlay.gd`
  - `AXEL/axel_project/scenes/ui/InteractPromptOverlay.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/tools/bots/playthrough_arc1_exterior.gd`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
- Behavior impact: After intro unlock, walking into the door polygon shows `[E]` with CRT warm-up above the door centroid; leaving or transitioning runs CRT shut-off. Dialogue CRT behavior unchanged (shared module).
- Verification: `ReadLints` clean on touched scripts; headless arc1 exterior phase A OK; phase B door overlap still fails at x≈840 (pre-existing walk distance vs door polygon — not introduced by prompt).

### Interact prompt chip chrome (tight + 75% opacity)
- Request: Black frame around `[E]` should hug the glyph; panel and border at 75% opacity.
- Implementation: Reduced `StyleBoxFlat` content margins (3×1); inner panel uses `StyleBoxEmpty` (no second inset). Panel `bg_color` and border alpha set to `0.75`; label 26px / outline 2.
- Files changed:
  - `AXEL/axel_project/scenes/ui/InteractPromptOverlay.tscn`
- Behavior impact: Smaller, semi-transparent interact chip; CRT animation unchanged.
- Verification: Manual at 1.1 door.

### Interact CRT shut-off mirror + no white wash
- Request: Turn-off should reverse turn-on; avoid full-rectangle white flash during interact chip animation.
- Implementation: `crt_power_fx.power_off` no longer pre-spikes beam/bloom before collapse (true reverse from settled post-on state). Added `Options` + `compact_chip_options()` for interact: white `PowerBeam` disabled, capped red bloom surge/flash. `InteractPromptOverlay` uses compact opts; dialogue keeps defaults.
- Files changed:
  - `AXEL/axel_project/scenes/ui/crt_power_fx.gd`
  - `AXEL/axel_project/scenes/ui/InteractPromptOverlay.gd`
  - `AXEL/axel_project/scenes/ui/InteractPromptOverlay.tscn`
- Behavior impact: `[E]` powers off as mirrored warm-down without opening white fill; on uses subtler red phosphor only on the small chip.
- Verification: Manual door enter/exit; `TopDialogueOverlay` dialogue CRT unchanged (default options).

### Consolidate `.cursorignore` export and cache fences
- Request: Extend `.cursorignore` for stale/low-value paths (whole `exports/` except narrative canon; other generated artifacts) — docs flush after audit chat.
- Implementation: Replaced per-subfolder export rules with `AXEL/axel_project/exports/**` plus `!game_data.json` and `!GameManager.gd` negations. Added `**/__pycache__/**`, `**/*.pyc`, `**/*.aseprite`, and `plans/qa/archive/**`. Documented indexing contract in `AI_DOCS.md` optional references and `AGENT_CONTEXT_ROUTING.md` §12.
- Files changed:
  - `.cursorignore`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AGENT_CONTEXT_ROUTING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No runtime change. Cursor index drops export captures, Python cache, Aseprite sources, and archived QA logs; narrative agents still discover `game_data.json` / `GameManager.gd` via search.
- Verification: On-disk `exports/` subfolders (Moon Princess, screenshots, Drawings, PDF) covered by single `exports/**` rule; negated paths remain the two GDScript/JSON canon files per `AI_DOCS.md` architecture §.
- Notes: Excluded export assets (e.g. `exports/Drawings`) remain reachable with `@` paths per routing weak-signal note.

### Split player CRT chroma + tighter fringe + white boost
- Request: Plan B — keep env CRT chroma unchanged; lower chroma on overworld player only; step 3 neighbor mask for silhouette fringe; white player body should stand out more.
- Implementation: Added `player_chroma` with per-pixel `mix(chroma, player_chroma, p_chroma)`; step 3 expands chroma mask via ±`chroma` neighbor samples. Added `player_white_boost` — after CRT mix, white body pixels lerp toward pure white (`player_white_body_mask`). Env `chroma` stays `0.001`; `player_crt_reduction` at `0.33`. **Shipped defaults:** `player_chroma` `0.0002`, `player_white_boost` `0.8`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/crt_plugin_overlay.gdshader`
  - `AXEL/axel_project/scenes/fx/CrtPluginOverlay.tscn`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Environment CRT fringe unchanged; player RGB separation tighter at body and silhouette edge; white sprite reads brighter against noir env.
- Verification: `res://tools/scene_smoke_check.gd` OK (6 scenes); manual 1.1 + 1.2 player fringe/brightness check recommended.
- Notes: Tune on `CrtPluginOverlay.tscn` → `FilterRect` (Inspector → Material → Shader Parameters). Remote-tree instance while playing is read-only and does not persist edits.

### Beginner explore template
- Request: Replace subsystem-first explore snippet with a beginner-friendly paste-in; author does not need to know file paths or combat vs scenes up front.
- Implementation: Documented canonical explore prompt in changelog; pointed `AI_DOCS.md` workflow table at this entry. No new governance § — user pastes template on Auto only.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Explore chats expect plain game-language goals; Auto classifies subsystem, lists paths, and asks simple A/B questions.
- Verification: Template copy-paste ready below.

**Paste on Auto (fill the three lines; use `not sure` where optional):**

```text
AXEL — explore only. Do not implement or edit files.

What I want (player/game terms):
<What should happen? When? Example: first night in school yard → one glitch + one line, once per run.>

Where I think it happens (optional — skip if unsure):
<school outside / combat screen / dialogue box / not sure>

What exists today (optional):
<what already works or "nothing yet" / not sure>

Please figure out for me:
1. Which area (combat / scenes / narrative / vfx-overworld) and why.
2. Where handled today — plain English, then 3–5 file paths.
3. Canon risks (per AI_DOCS).
4. Simple recommended approach (beginner-friendly steps).
5. Questions for me — one bullet list; yes/no or A/B where possible.

Keep explanations non-jargon; define Godot terms briefly when used.

End your reply with this block (fill every field; quote line refs or node names where you read code):

--- EXPLORATION ARTIFACT ---
Area: <combat | scenes | narrative | vfx-overworld>
Symptom: <what the player sees>
Likely cause: <1–2 sentences>
Files (verified):
  - <path> — <role> — <relevant lines, nodes, or values>
  - ...
Canon risks: <from AI_DOCS, or "none">
Draft approach: <3–5 beginner steps; no code yet>
Open questions: <A/B or yes/no bullets>
Do-not-touch: <what must stay as-is>
--- END ARTIFACT ---
```

### Premium plan template
- Request: Stop Premium Plan chats from re-exploring the repo (expensive reads/greps) when Explore on Auto already ran.
- Implementation: Documented plan-only paste-in with explicit no-tool rule; Explore template now requires `EXPLORATION ARTIFACT` handoff block; `AI_DOCS.md` workflow table updated (new chat per step).
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Plan step consumes artifact text only; author starts a **new** Premium chat instead of saying "plan this fix" in the Explore thread.
- Verification: Templates copy-paste ready below.

**Paste on Premium in a new chat (Plan mode optional; paste artifact from Explore):**

```text
AXEL — plan only. Do not implement or edit files.

Tool rule: Do NOT read, grep, search, or explore the codebase.
Use ONLY the EXPLORATION ARTIFACT below. If a path, line, or behavior is missing or unclear, ask me in one batched question list — do not verify in the repo yourself.

@AXEL/axel_project/plans/core/AI_DOCS.md (canon only — no file hunting)

--- EXPLORATION ARTIFACT ---
<paste block from Auto explore chat>
--- END ARTIFACT ---

Deliver:
1. Numbered implementation steps (file + concrete change; no full code unless one line is essential)
2. Acceptance criteria (what I should see in-game after the fix)
3. Manual test checklist (≤5 steps)
4. Residual risks / rollback note

Keep scope minimal. One batched question list only if truly blocked.
```

### Fix 1.1 door transition crash + missing post-FX
- Request: Fix scene transition from `1.1_SchoolExterior` to `1.2_Corridor` — pressing **E** at the door caused debugger errors; play stayed on 1.1 with noir/scanline/CRT stack gone.
- Implementation: Door transition no longer awaits animated `hide_prompt()`; uses `hide_prompt_immediate()` and ignores `body_exited` hide while `_is_transitioning`. `InteractPromptOverlay` cancels CRT via `_anim_token` + `tree_exiting`; `crt_power_fx.gd` guards `power_on`/`power_off` when host tree is invalid. `AxelPostFxStack` attaches new overlays before freeing old ones on `scene_changed`, adds `ensure_attached_to_current_scene()` (deferred reconcile), and `1.1_SchoolExterior.gd` calls `apply_to_scene` if `change_scene_to_file` fails.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/ui/InteractPromptOverlay.gd`
  - `AXEL/axel_project/scenes/ui/crt_power_fx.gd`
  - `AXEL/axel_project/scripts/autoload/axel_post_fx_stack.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: **E** at the school door should reach `1.2_Corridor` with baseline post-FX intact; aborted swaps or failed scene load restore noir/CRT on the current scene instead of leaving 1.1 full-color.
- Verification: Headless `res://tools/bots/playthrough_arc1_exterior.gd` exit 0, transition to `1.2_Corridor.tscn`, no `crt_power_fx` null-tree errors. Manual editor: intro complete → door → **E** (no debugger stop; post-FX on 1.2).
- Notes: Canon unchanged — baseline post-FX remain autoload-only, not re-embedded in Arc `.tscn`.

## 2026-06-03

### Docs sync — 1.2 corridor canon matches editor-tuned runtime
- Request: `update docs` after corridor scale/layout pass.
- Implementation: Reconciled `corridor_large` profile across layout rules, QA validators, scene-builder tools, blueprint §1.2, and `scene_2_draft.json` to current scene values (`Player` scale `3`, speed `540`, spawn ~`(73, 271)`). Documented `WalkableWorld` parent for bg/colliders and `vertical_view_follow_*` scroll in blueprint.
- Files changed:
  - `AXEL/axel_project/plans/scenes/SCENE_LAYOUT_RULES.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/tools/scene_builder/layout_planner.py`
  - `AXEL/axel_project/tools/scene_builder/path_validator.py`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/scene_2_draft.json`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs/QA only; runtime unchanged.
- Verification: Profile bounds match `1.2_Corridor.tscn` `Player` exports.
- Notes: Supersedes interim `6.56` / `1180` canon from the push-in removal pass; user tuned scale down in editor.

### Scene 1.2 corridor — remove push-in zoom, scale player, retune collisions
- Request: Remove unnecessary background zoom on 1.2 load; scale player ~8× for screen readability; retune collisions; update corridor_large canon.
- Implementation: Removed push-in tween from `1.2_Corridor.gd`; background cover-fit uses viewport visible rect. Player `scale` 6.56, `speed` 1180, spawn `(80, 520)`, tighter alpha-collision exports and smaller fallback circle radius. Updated `SCENE_LAYOUT_RULES`, `qa_canon_validators`, blueprint, scene_builder profiles, and `scene_2_draft.json`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/scenes/SCENE_LAYOUT_RULES.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/tools/scene_builder/layout_planner.py`
  - `AXEL/axel_project/tools/scene_builder/path_validator.py`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/scene_2_draft.json`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 1.2 loads with static full-bleed background (no 3.2s scale tween); Mike renders ~8× larger with proportionally faster walk; collision tuned for large scale (user may fine-tune scale/speed/spawn in editor).
- Verification: Headless `res://tools/scene_smoke_check.gd` OK (6 scenes); `res://tools/qa/canon_consistency_audit.gd` OK (0 findings on 1.2).
- Notes: Wall `StaticBody2D` nodes unchanged. Manual F7 collision pass recommended after visual scale tweak.

### Explore artifact + Premium plan template (API cost)
- Request: Add handoff templates so Explore stays on Auto and Premium Plan does not re-read/grep the repo.
- Implementation: Beginner explore template now ends with `EXPLORATION ARTIFACT` block; added Premium plan template with explicit no-tool rule; `AI_DOCS.md` chat workflow table documents new-chat-per-step handoff.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Author copies artifact block only into a new Premium chat; thin artifacts go back to Auto for line refs instead of Premium exploration.
- Verification: Templates under `### Beginner explore template` and `### Premium plan template` in this file.

### Scene 1.2 — corridor_large 4× profile and spawn fix (docs)
- Request: Explore handoff — player clipped off-screen at 6.56×; reduce to 4×, move spawn inside walkable bounds (full body visible, left ~X 80 below lockers), update `corridor_large` canon, collision pass.
- Implementation: Documented `corridor_large` as scale `4.0` / speed `720` (`180 × scale`) in `SCENE_LAYOUT_RULES.md`, `qa_canon_validators.gd`, `layout_planner.py`, `path_validator.py`, `scene_2_draft.json`, and `AXEL_SCENES_BLUEPRINT.md`. Scene work: `1.2_Corridor.tscn` — spawn raised, `WalkableWorld` grouping, collision shapes aligned to cover-fit background (editor-tuned values may differ until Player matches profile).
- Files changed:
  - `AXEL/axel_project/plans/scenes/SCENE_LAYOUT_RULES.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/tools/scene_builder/layout_planner.py`
  - `AXEL/axel_project/tools/scene_builder/path_validator.py`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/scene_2_draft.json`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Canon expects Mike at 4× / 720 on 1.2 with left-floor spawn below locker collision; replaces prior 6.56× / 1180 profile from same-day push-in removal entry.
- Verification: Align `PlayerLayer/Player` in `1.2_Corridor.tscn` to scale `(4, 4)` and speed `720`, then manual F7 collision pass; run `res://tools/qa/canon_consistency_audit.gd` on 1.2.
- Notes: Supersedes `### Docs sync — 1.2 corridor canon matches editor-tuned runtime` (3.0 / 540) and `### Scene 1.2 corridor — remove push-in zoom` (6.56 / 1180). Wall `StaticBody2D` positions unchanged per explore artifact.

## 2026-06-04

### Scene 1.1 — tree leaf fade behind zones (per-pixel soft gate)
- Request: Mike looked half-faded at the trunk line when only partly under leaves; fade should apply only when behind the trunk. Follow-up: whole-body on/off clip at zone edge — need gradual per-pixel fade when straddling the behind zone.
- Implementation: Added `TreeLine_Bottom_Behind` / `TreeLine_Top_Behind` `Area2D` zones under `EnvironmentColliders` (editor polygons past trunk, under canopy). `1.1_SchoolExterior.gd` fits `behind_mask_0/1` ellipses from behind polygons (tighter padding) into `configure_leaf_occlusion_masks`. `white_sprite.gdshader` multiplies leaf ellipse × behind-zone ellipse per fragment (`behind_edge_softness` linear edge); defaults `Vector4.ZERO` disable behind on other scenes. Removed boolean `leaf_behind_*` / `_physics_process` overlap polling. `ShadowOutline` unchanged; combat and post-FX untouched.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Opaque in front of trunk; leaf fade (`0.2`) ramps per pixel inside behind-zone ellipses under canopy (soft edge, partial body fade when straddling zone). Other scenes without behind masks: no fade.
- Verification: Manual F5 on `1.1_SchoolExterior` — trunk front opaque, behind canopy whole-sprite fade, both trees; `1.2_Corridor` no fade. Tune behind polygons in editor if boundary feels early/late.
- Notes: Supersedes per-pixel Y cutoff behavior from `### Scene 1.1 — tree leaf occlusion Y cutoff` for fade gating; Y cutoffs still passed but unused in shader.

### Scene 1.2 corridor — root rename, collision tree, camera follow
- Request: Fix Mike walking through corridor borders; align 1.2 scene tree with 1.1 (root name, `EnvironmentColliders`, `Camera2D` vertical follow); keep `corridor_large` profile at scale `3.0` / speed `540`.
- Implementation: Renamed scene root `1.2_Corridor1` → `1.2_Corridor`. Confirmed border colliders nested under `EnvironmentColliders/*` → `StaticBody2D` → `CollisionShape2D` (no orphan shapes at root). Vertical follow uses `Camera2D` + `camera_follow_vertical.gd` (same pattern as 1.1); `1.2_Corridor.gd` retains cover-fit background only (no `WalkableWorld` scroll). Synced `AI_DOCS.md` with Arc 1 scene-tree and `corridor_large` profile canon.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike should collide with top/bottom/side corridor borders; camera follows vertically without world scroll jitter; player remains scale `3.0` / speed `540`.
- Verification: Scene tree matches 1.1 pattern (`Camera2D`, `EnvironmentColliders/*`); QA `corridor_large` profile bounds cover 540 / 3.0. Manual F7 play recommended for border collision and camera follow.
- Notes: Filenames unchanged; no post-FX, props, or background edits. Supersedes conflicting 4× / 720 docs entry from 2026-06-03 when scene values differ — runtime canon is 3.0 / 540 per editor-tuned scene.

### Scene 1.2 corridor — left/right wall collision alignment
- Request: Mike could walk through the left and right corridor borders.
- Implementation: Repositioned `LeftWall` and `RightWall` `StaticBody2D` nodes to the `corridor_large` path band (`x` 320 / 960) with zeroed shape offsets so vertical colliders align with the visible side walls under cover-fit background. Top/bottom/upper block colliders unchanged.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike should be blocked when walking into either side wall of the corridor floor lane.
- Verification: Headless `canon_consistency_audit.gd` on 1.2; manual F7 play — walk into left and right borders.
- Notes: Prior side walls sat near viewport edges (`x` ≈ −7 / 1298), outside the walkable band.

### Scene 1.2 corridor — colliders follow cover-fit background
- Request: After manually moving border colliders to the correct visual positions, Mike could walk through them again.
- Implementation: Root cause was twofold: (1) `_apply_background_layout()` rescales/repositions the background at runtime while root-level colliders stayed fixed in editor world space; (2) large `CollisionShape2D` offsets meant the StaticBody2D gizmo did not match the actual shape. Moved `EnvironmentColliders` under `WalkableWorld`, authored walls in texture-pixel space with shapes at `(0,0)`, and sync collider `position`/`scale` to the cover-fit background each layout pass (deferred wake on `StaticBody2D` transforms). Left/right centers restored to prior tuned world positions (~`(21, 415)` / `(1291, 416)` at play).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/tools/qa/corridor_collision_probe.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Side/top/bottom borders should stay aligned with the drawing after play/rescale; Mike should be blocked at the visible walls.
- Verification: Headless `corridor_collision_probe.gd` stops at `LeftWall` from `x=100`; canon audit paths updated for `WalkableWorld/EnvironmentColliders/*`.
- Notes: In editor, tune `StaticBody2D` positions under `WalkableWorld/EnvironmentColliders` (texture coords); do not rely on large shape offsets or root-level world coords.

### Scene 1.2 corridor — camera crop (edge void / post-FX red bands)
- Request: Remove reddish blocky edge bands on top, bottom, and right when the camera pans vertically (same approach as scene 1.1); camera-only, scene 1.2 only; do not crop the left.
- Implementation: Tightened `Camera2D` in `1.2_Corridor.tscn` so the viewport stays on cover-fit art: `fixed_x = 560` (~5.7% right crop on 1400px window), `limit_top = -55` (~3.9% top), `limit_bottom = 750` (~10% bottom from prior 840), `limit_left = 0` unchanged. Mirrors 1.1 pattern (`fixed_x` + vertical limits); no post-FX, collider, or script edits.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Vertical follow shows less void outside the corridor drawing at pan extremes; noir/CRT should no longer remap grey void into red fringe on top/bottom/right. Left framing unchanged.
- Verification: Godot not on PATH in implement session — manual F6 on `1.2_Corridor`: walk floor to ceiling and confirm no red blocks on top/bottom/right; optional `AXEL_DISABLE_POST_FX=1` before/after. Colliders and `1.2_Corridor.gd` cover-fit unchanged.
- Notes: If a edge still shows void, nudge `fixed_x` down (~10–15), `limit_top` more negative, or `limit_bottom` lower per explore plan; do not change `limit_left` unless left art is intentionally cropped.

### Scene 1.2 corridor — camera crop top/bottom tighten
- Request: Sides are good; remove ~20px red void on top and ~10px on bottom.
- Implementation: `limit_top` `-55` → `-75`; `limit_bottom` `750` → `740`. `fixed_x` / horizontal limits unchanged.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Slightly less vertical play area visible at pan extremes; top/bottom void bands should be gone.
- Verification: Manual F6 — pan floor to ceiling; confirm top/bottom edges clean; sides unchanged.

### Scene 1.2 corridor — camera crop top/bottom direction fix
- Request: After `limit_top` `-75` / `limit_bottom` `740`, top red increased and bottom unchanged.
- Implementation: Corrected limit direction: in Godot 2D a **less negative** `limit_top` stops the camera from panning as far upward (hides top void); a **lower** `limit_bottom` stops downward pan. Set `limit_top` `-75` → `-35` (~20px stricter than pre-tweak `-55`); `limit_bottom` `740` → `730` (~20px stricter than original `750`). `fixed_x` unchanged.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Top void band should shrink; bottom should tighten if walk range hits `limit_bottom`.
- Verification: Manual F6 — walk to top and bottom; compare to prior build. If bottom band persists, next step is small `BACKGROUND_Y` nudge in `1.2_Corridor.gd` (limits may not bind on floor walk).

### Scene 1.2 corridor — camera crop top-left (~20px)
- Request: Bottom fixed; ~20px red void remains at top-left.
- Implementation: `limit_top` `-35` → `-15` (~20px less upward pan). `fixed_x`, `limit_bottom`, and `limit_left` unchanged.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Top / top-left void band should shrink when walking to the upper corridor.
- Verification: Manual F6 — walk to top; confirm top-left clean; bottom and sides unchanged.

### Background-derived camera bounds — shared exploration helpers
- Request: Plan-only premium spec — future PNG exploration scenes must derive Camera2D limits from cover/contain layout instead of hand-tuned numbers; 1.1/1.2 unchanged.
- Implementation: Added `BackgroundLayout` (cover/contain math → `world_rect`) and `BackgroundCamera` controller (`static_locked` default, `movable_follow` with auto-zoom when art is smaller than window). Documented mandatory pipeline in `SCENE_BUILDER_AGENT_SPEC.md` and `AI_DOCS.md`; QA smoke via `QaCanonValidators.collect_background_camera_findings`. Deferred migration note for 1.1/1.2 (world-space player, render order, camera rewire).
- Files changed:
  - `AXEL/axel_project/scenes/core/background_layout.gd`
  - `AXEL/axel_project/scenes/core/background_camera_controller.gd`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No runtime change to 1.1/1.2. New exploration scenes wire `BackgroundCamera` on `Camera2D` with `background_path` — limits auto-derived from PNG size; view should not slide past art edges (no clear-color / post-FX red fringe).
- Verification: Wire a throwaway scene with helper; manual F6 edge walk; optional `collect_background_camera_findings` in scene smoke. Confirm 1.1/1.2 unchanged.
- Notes: `fit_mode` and `camera_mode` are per-scene exports. `margin_px` optional for CRT trim. Player for new scenes: `WalkableWorld/Player` in world space.

### Scene 1.1 — tree leaf occlusion Y cutoff
- Request: Leaf opacity fade behind trees should apply only above the trunk line (`TreeLine_Top` / `TreeLine_Bottom`), not when standing in front of the trunk.
- Implementation: Added `leaf_y_cutoff_0/1` uniforms to `white_sprite.gdshader` (per-pixel gate: fade only when `world_pos.y < cutoff`). Extended `Player.configure_leaf_occlusion_masks` with optional Y cutoffs (default `1e9` for other scenes). `1.1_SchoolExterior.gd` derives cutoffs from trunk `StaticBody2D` collision polygons (`max` world Y minus `_LEAF_Y_CUTOFF_MARGIN`).
- Files changed:
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Player stays fully opaque at tree trunk; fades inside leaf ellipses only when visually above each trunk-top line. Other overworld scenes unchanged.
- Verification: Manual F5 on `1.1_SchoolExterior` — stand at trunk (opaque), walk up into canopy (fade). Headless scene load if Godot available.

### Docs sync — background-derived camera bounds
- Request: `update docs` after shared exploration background/camera helpers landed.
- Implementation: Cross-linked `SCENE_LAYOUT_RULES.md` (background/camera pipeline section), `SCENE_BUILDER_AGENT_SPEC.md` (`static_center` export + minimum art size note), `README_gd_scripts.md` (exploration camera smoke). Primary canon already in `AI_DOCS.md` and changelog entry `### Background-derived camera bounds — shared exploration helpers`.
- Files changed:
  - `AXEL/axel_project/plans/scenes/SCENE_LAYOUT_RULES.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Documentation only; no runtime change.
- Verification: N/A.
- Notes: Legacy 1.1/1.2 migration remains deferred per `SCENE_BUILDER_AGENT_SPEC.md`.

### Scene 1.2 corridor — collider sync parser fix
- Request: `1.2_Corridor` failed to start with parser error: `_sync_environment_colliders()` argument 1 should be `float` but is `Vector2`.
- Implementation: `_apply_background_layout()` passed `fit_scale` (`Vector2`) instead of `cover_scale` (`float`) to `_sync_environment_colliders(cover_scale, bg_position)`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Scene loads; border colliders sync with cover-fit background again after play.
- Verification: Open/play `1.2_Corridor` — no parser error; F7 collision shapes track drawing edges.

### Docs sync — 1.2 corridor collider canon
- Request: `update docs` after collider follow-background work and parser fix.
- Implementation: Aligned `AXEL_SCENES_BLUEPRINT.md` §1.2 collider path/sync; `SCENE_LAYOUT_RULES.md` legacy 1.2 sync note; `README_gd_scripts.md` corridor probe + validator paths; `PLAYTEST_DEBUG_COLLISIONS.md` editor tuning guide for texture-pixel borders.
- Files changed:
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/scenes/SCENE_LAYOUT_RULES.md`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/plans/core/PLAYTEST_DEBUG_COLLISIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Documentation only.
- Verification: Cross-refs match `1.2_Corridor.gd`, `qa_canon_validators.gd` `WalkableWorld/EnvironmentColliders/*` paths, and changelog `### Scene 1.2 corridor — colliders follow cover-fit background`.

### Docs sync — 1.1 tree leaf behind-zone fade
- Request: `update docs` only — cross-link implemented 1.1 leaf occlusion (behind-zone per-pixel fade); no code changes.
- Implementation: Documented `TreeLine_*_Behind` + `behind_mask_*` pipeline in `AXEL_SCENES_BLUEPRINT.md` §1.1, `SCENE_LAYOUT_RULES.md` legacy section, `AI_DOCS.md` Arc 1 bullet; QA README notes manual F5 for 1.1. Recorded legacy 1.2 manual camera crop values in blueprint §1.2. Canon for fade gating is behind-mask ellipses (`### Scene 1.1 — tree leaf fade behind zones`); `### Scene 1.1 — tree leaf occlusion Y cutoff` is superseded (Y uniforms still passed; shader does not use them for fade).
- Files changed:
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/scenes/SCENE_LAYOUT_RULES.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Documentation only.
- Verification: Cross-refs match `1.1_SchoolExterior.gd`, `Player.configure_leaf_occlusion_masks`, `white_sprite.gdshader`.

## 2026-06-05

### Exploration background editor lock + 1.1 playtest scene
- Request: Lock background images in all scenes (current and future) so accidental editor drags do not nudge cover-fit art; add a `1.1_SchoolExterior` variant that skips the intro for playtesting.
- Implementation: Added `@tool` `locked_exploration_background.gd` and `BackgroundLayout.ensure_editor_locked()` (re-applied from `apply_to_sprite`). Wired lock script + `metadata/_edit_lock_` on `1.1`/`1.2` background sprites. Added `@export var skip_intro` on `1.1_SchoolExterior.gd` (also honors env `AXEL_SKIP_INTRO=1`). Created inherited `1.1_SchoolExterior_Playtest.tscn` with `skip_intro = true`. QA: `collect_background_editor_lock_findings` in `qa_canon_validators.gd`.
- Files changed:
  - `AXEL/axel_project/scenes/core/locked_exploration_background.gd`
  - `AXEL/axel_project/scenes/core/background_layout.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior_Playtest.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: Background sprites show editor lock icon; runtime unchanged. Playtest scene spawns player at stones with control immediately. Canonical `1.1_SchoolExterior.tscn` still runs full intro.
- Verification: Manual — open scenes in editor (lock visible); F6 playtest scene (no intro). Headless smoke not run (Godot CLI not in PATH).
- Notes: Playtest inherits base scene — edit base for layout; child only for playtest-only overrides.

### Docs sync — background lock + 1.1 playtest inheritance
- Request: `update docs` after background lock and playtest scene work; clarify inherited-scene edit workflow.
- Implementation: Expanded `AI_DOCS.md` Arc 1 bullet (playtest path, inheritance rule, `skip_intro` export). Added playtest variant + unlock note to `AXEL_SCENES_BLUEPRINT.md` §1.1. Added playtest-variant pattern to `SCENE_BUILDER_AGENT_SPEC.md`.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Documentation only.
- Verification: Cross-refs match `1.1_SchoolExterior_Playtest.tscn`, `locked_exploration_background.gd`, `1.1_SchoolExterior.gd` `skip_intro`.

### 1.1 leaf fade — polygon feather zones + feet anchor
- Request: Fix Mike head fading in front of tree trunks; tighten fade boundary; linear Y-axis transition; editor-tunable polygon feather mask; rename leaf zones to `TreeLine_*_Behind`; update docs after manual editor tuning.
- Implementation: Replaced ellipse/AABB masks with `leaf_occlusion_zone.gd` (`LeafOcclusionZone`, `@export feather_px`, editor polygon preview) on `TreeLine_Bottom_Behind` / `TreeLine_Top_Behind`. `white_sprite.gdshader` uses feathered polygon mask (max 32 verts) × trunk Y gate with `player_anchor_y` feet anchor and smooth depth exit. `Player.configure_leaf_occlusion_polygons` pads arrays for shader; `1.1_SchoolExterior.gd` resolves `TreeLine_*_Behind` (legacy `*_Leaves` fallback). Renamed leaf `Area2D` nodes from `TreeLine_*_Leaves` to `TreeLine_*_Behind`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/leaf_occlusion_zone.gd`
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/scenes/SCENE_LAYOUT_RULES.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: `1.1` only — player fades inside hand-authored behind polygons under canopy; solid in front of trunk (head included); smooth Y-axis exit/entry. `1.2` and combat unchanged. `ShadowOutline` shares fade material.
- Verification: Manual F5/F6 on `1.1` / playtest — in front (head solid), behind (fade), straddle, diagonal exit; `1.2` no fade.
- Notes: **Designer hand-tuning in editor (preserve):** both `TreeLine_*_Behind` zones set to `feather_px = 12.0`; behind-zone `CollisionPolygon2D` shapes adjusted manually in `1.1_SchoolExterior.tscn`. Do not overwrite polygon/feather values without playtest. Stale doc refs to `behind_mask_*` / `TreeLine_*_Leaves` ellipses removed.

## 2026-06-09

### Per-scene exploration viewport + corridor_large speed (1.1 / 1.2)
- Request: Fix 1.2 window/background aspect mismatch (side crop, post-FX void bands); stable per-scene design viewport; slower corridor walk; update corridor_large canon; wire 1.1 square viewport.
- Implementation: Added `scenes/core/exploration_viewport.gd` — applies `@export design_viewport` on scene enter via `DisplayServer.window_set_size`, restores previous size on `_exit_tree`; debug scale via `@export debug_scale` or env `AXEL_DEBUG_VIEWPORT_SCALE`. Wired into `1.2_Corridor.tscn` (`1920×1200`, matches 2400×1500 art aspect) and `1.1_SchoolExterior.tscn` (`1400×1400`). `1.2_Corridor.gd` layout now deferred-only so cover-fit runs after resize. Player speed `540` → `362` in `1.2_Corridor.tscn`. Synced `corridor_large` speed band (~350–375) across QA, layout rules, blueprint, scene-builder tools, and `AI_DOCS.md`. Global `project.godot` viewport unchanged; `BackgroundCamera` migration on 1.2 deferred.
- Files changed:
  - `AXEL/axel_project/scenes/core/exploration_viewport.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_LAYOUT_RULES.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/tools/scene_builder/layout_planner.py`
  - `AXEL/axel_project/tools/scene_builder/path_validator.py`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/scene_2_draft.json`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Entering 1.2 resizes window to 1920×1200 (1:1 cover-fit with corridor art — no side crop); exiting restores prior size. 1.1 uses 1400×1400 square window. Mike walks slower in corridor (362). Manual camera limits on 1.2 unchanged (`limit_left = 0`).
- Verification: Manual F6 on 1.2 — full background width visible, no red side void; walk speed feels slower; exit to menu/combat restores 1400×900. F6 on 1.1 — square window, no global project.godot change.
- Notes: Optional `BackgroundCamera` on 1.2 not wired this pass. User-facing resolution settings autoload deferred to later task.

### Docs sync — per-scene exploration viewport + corridor_large speed
- Request: `update docs` after viewport helper and corridor speed implementation.
- Implementation: Added Arc 1 viewport section to `SCENE_LAYOUT_RULES.md`. Documented `ExplorationViewport` on blueprint §1.1/§1.2. Fixed stale `corridor_large` JSON example in `SCENE_BUILDER_AGENT_SPEC.md` (3.0 / 362); added approved legacy viewport subsection and clarified deferred migration checklist. Updated `tools/qa/README_gd_scripts.md` audited-scene notes and corridor probe window caveat.
- Files changed:
  - `AXEL/axel_project/plans/scenes/SCENE_LAYOUT_RULES.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Documentation only.
- Verification: Cross-refs match `exploration_viewport.gd`, `1.2_Corridor.tscn` (`1920×1200`, speed `362`), `1.1_SchoolExterior.tscn` (`1400×1400`).

## 2026-06-17

### CRT freeze — locker hub load and map click skip
- Request: Play freezes after pressing E at 1.2 locker (hub load) or clicking map polygon in 2.1 while dialogue CRT is animating; debug view stays open, post-FX wave keeps moving.
- Implementation: Added `CrtPowerFx.cancel()` with per-host session tokens and frame-polling `_await_tween()` (killed tweens never emit `finished`). `InteractPromptOverlay.hide_prompt_immediate()` and `TopDialogueOverlay` skip/dismiss paths call cancel. `2.1_LockerHub` MapHotspot `background_path` set to `../Background`; first-visit dialogue gates map clicks until sequence ends.
- Files changed:
  - `AXEL/axel_project/scenes/ui/crt_power_fx.gd`
  - `AXEL/axel_project/scenes/ui/InteractPromptOverlay.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_LockerHub.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_LockerHub.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Interrupting CRT power-on/off (locker E, dialogue skip click) no longer hangs the session; map polygon tracks background art; map ignores clicks during first-visit dialogue.
- Verification: Manual F6 — 1.2 locker E mid-CRT and settled; 2.1 map click during and after first-visit dialogue; X return to corridor. User-confirmed working.

### CRT freeze regression — restore line-swap scramble glitch
- Request: After CRT freeze fix, smell→locker (and similar) in-bar swaps use full CRT power off/on instead of scramble letter glitch.
- Implementation: Removed `_cancel_crt_power()` from `cancel_pending_line()` — that path must keep the bar visible and at full opacity so `type_line()` can detect `is_swap` and run `_scramble_glitch()`; CRT cancel remains on `skip_current_line()`, `_dismiss_bar_immediate()`, and `interrupt_line()`.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Entering locker zone while spawn line is still up swaps to locker text with scramble glitch again, not CRT reboot.
- Verification: F6 `1.2_Corridor` — walk to locker while smell line is visible; confirm letter scramble, not bar power off/on. User-confirmed working.

### Docs — CRT cancel + line-swap canon
- Request: `update docs` after CRT freeze fix and scramble-glitch regression fix verified in play.
- Implementation: `AI_DOCS.md` § Style and FX — `CrtPowerFx.cancel()` API, which overlay paths call it (`hide_prompt_immediate`, skip/dismiss/interrupt; **not** `cancel_pending_line`), `UiPolygonHotspot.background_path`, hub first-visit map-click gate. `AXEL_SCENES_ARC2.md` + `AXEL_SCENES_BLUEPRINT.md` §2.1 aligned.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Documentation only.
- Verification: Cross-refs match `crt_power_fx.gd`, `TopDialogueOverlay.gd`, `2.1_LockerHub.gd` / `.tscn`.

### UiPolygonHotspot — fix duplicate editor green polygon
- Request: After moving the map collision polygon in 2.1, a second green polygon stayed off-screen in the editor.
- Implementation: `_get_screen_polygon()` now uses the collision shape’s full global transform (matches Godot’s gizmo). Default `show_editor_preview = false` so only the `CollisionPolygon2D` handles show in editor (no script-drawn ghost). Re-seeded 2.1 map quad over the MAP paper on the art.
- Files changed:
  - `AXEL/axel_project/scenes/ui/ui_polygon_hotspot.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_LockerHub.tscn`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: One visible polygon in editor; tune by dragging **vertex handles** on `CollisionPolygon2D` (keep node at origin). Runtime hover/click follow the same shape.
- Verification: Open `2.1_LockerHub.tscn` — no stray green shape in gray margins; F6 hover/click on MAP only.

### Scene 2.1 locker hub — map polygon hotspot
- Request: Map should open only when clicking the map area on the locker art, with subtle hover feedback; polygon editable in the editor.
- Implementation: Added reusable `UiPolygonHotspot` (`scenes/ui/ui_polygon_hotspot.gd`) — texture-pixel `CollisionPolygon2D`, cover-fit sync to `TextureRect`, custom `_has_point` hit test, hover tint, and `activated` signal. Wired `2.1_LockerHub` to use `MapHotspot` instead of full-screen background clicks; background mouse filter set to ignore.
- Files changed:
  - `AXEL/axel_project/scenes/ui/ui_polygon_hotspot.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_LockerHub.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_LockerHub.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Hovering the map polygon shows a faint red wash and pointing-hand cursor; click opens `map.png`. Clicks elsewhere on the art do nothing. Hotspot disables after the map is shown.
- Verification: F6 on `2.1_LockerHub` — tune `MapHotspot/PolygonAnchor/CollisionPolygon2D` vertex handles in editor; confirm hover/click only inside polygon.

### Scene 1.2 corridor — camera crop top/bottom (~5%)
- Request: Trim thin red lines at top and bottom while walking in 1.2 only; camera-only, no viewport/layout changes.
- Implementation: Nudged `Camera2D` vertical limits in `1.2_Corridor.tscn` by ~45px (~5% of ~900px visible height): `limit_top` `-15` → `30`, `limit_bottom` `730` → `685`. `fixed_x`, `limit_left`, and `limit_right` unchanged.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Slightly less vertical pan range at walk extremes; should hide thin noir void fringe on top/bottom without affecting 1.1 or layout math.
- Verification: Manual F6 on `1.2_Corridor` — walk floor to ceiling; confirm top/bottom red lines gone. If a band remains, nudge limits ±5–10 only.

### Scene 1.2 corridor — camera crop loosen (~10px, reduce clamp click)
- Request: After ~5% crop, camera “clicks” slightly when moving up/down at pan limits.
- Implementation: Loosened vertical limits by 10px to ease clamp transition: `limit_top` `30` → `20`, `limit_bottom` `685` → `695`. `fixed_x` / horizontal limits unchanged.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Slightly more vertical pan before limits bind; should feel smoother with minimal red fringe return.
- Verification: Manual F6 — walk full corridor; confirm no click at pan extremes and no visible red band.

### Exploration viewport — fix debug scale (content_scale_size + window)
- Request: Debug scale did not enlarge in-editor play view; changing global project resolution broke player/colliders/background.
- Implementation: `exploration_viewport.gd` now sets `get_tree().root.content_scale_size` and `root.size` together (same target), and restores both on exit. Previously only `DisplayServer.window_set_size` ran, so game coords stayed at project default 1400×900 while the OS window grew — upscaling only, no layout change. Embedded editor play still ignores window resize; use floating/external game window.
- Files changed:
  - `AXEL/axel_project/scenes/core/exploration_viewport.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: F6 on 1.1/1.2 in a floating window — debug scale changes actual game resolution per scene; menu/combat restore 1400×900 on exit. Do not change global Project Settings viewport for per-scene debug.
- Verification: F6 corridor with debug_scale 1.33 in floating window — sharper/larger play area; background/colliders/player stay aligned. Stop play — window returns to prior size.

### Dialogue skip — click / E / Space / Enter ends line
- Request: Anywhere in the game, clicking the screen or pressing E, Enter, or Spacebar while dialogue is playing should fast-forward and end it.
- Implementation: Extended `TopDialogueOverlay.gd` skip input from Tab-only typewriter skip to full line dismiss on Tab, E, Space, Enter, and left-click/touch; added `skip_current_line()`, `await_hold()`, and skip-state helpers for multi-beat scene scripts. Updated Arc 1 exterior pathetic sequence, corridor locker line, locker hub first-visit lines, and FX preview to use skippable holds.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_LockerHub.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlayFxPreview.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/tools/bots/README.md`
  - `AXEL/axel_project/tools/bots/playthrough_dialogue_loop.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: While the bottom dialogue bar is visible, skip input shows the full line instantly, skips the hold, hides the bar, and aborts chained multi-line sequences; skip input is consumed so it does not trigger door/locker interact on the same press.
- Verification: Manual F6 on scenes with dialogue; optional headless `playthrough_dialogue_loop.gd` (Tab skip path still valid).

### Dialogue advance — two-step press (5× type then advance)
- Request: Refine dialogue skip — first press should 5× the typewriter; only when text is complete should a second press scramble to the next line or play CRT off (not instant dismiss).
- Implementation: Replaced instant `skip_current_line()` with `LinePhase` state machine in `TopDialogueOverlay.gd`: typing press sets 5× speed; ready press sets advance (scramble via `show_lines()` or `hide_line()` CRT off). Added `show_lines()`, `await_line_advance()`, `is_line_ready()`. Removed `skip_current_line`, `await_hold`, `was_dialogue_skipped`, `reset_dialogue_skip`. Updated Arc 1 exterior pathetic beat, corridor locker line, locker hub first visit, FX preview. Docs aligned in `AI_DOCS.md` and `SCENE_BUILDER_AGENT_SPEC.md`.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_LockerHub.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlayFxPreview.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Each line is player-paced — boost typing, then advance. Multi-line sequences use scramble between lines and CRT off only on the last line. No automatic hold timers between beats.
- Verification: Manual F6 — school exterior pathetic sequence, corridor spawn/locker lines, locker hub first visit; FX preview Space replay.

### Corridor locker hub — 1.2 interact + 2.1 hub scene
- Request: Implement corridor → locker hub flow (plan: locker interact, real hub, map click, four destinations, X exit, persistence); follow-up fixes for dialogue timing, debug saves, line swap, and exit button visibility.
- Implementation: Registered `GameManager` autoload with `user://axel_game_state.json` persistence (`memoryScenes`, corridor once-ever flags, transient `corridor_return_pos`). Additive `1.2_Corridor` — `LockerInteractArea`, `InteractPromptOverlay`, smell + locker once-ever lines, `[E]` opens hub. Replaced `2.1_LockerHub` placeholder with no-player hub (`2.1_Locker.png`, map click-swap, four destination buttons, red enlarged `X`). `TopDialogueOverlay` gained `cancel_pending_line()` / `is_bar_visible()` for smell→locker `type_line()` glitch swap without CRT off/on. Debug builds skip save load/write for playtest. `[E]` shows on zone enter (may stack over dialogue bar).
- Files changed:
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_LockerHub.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_LockerHub.tscn`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/exports/Drawings/map.png`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Player can open locker hub from corridor; first hub visit plays ARC2 rewrite + memory; map swap and destinations work; `X` returns to corridor at saved spot. Release builds persist once-ever lines; editor F6 always starts fresh narrative flags.
- Verification: Manual F6 — corridor locker interact, hub first-visit dialogue, map click, destination buttons, `X` return position; quit/relaunch in exported build for persistence.
- Notes: Basement hub entry still deferred. `LockerInteractArea` polygon may need art tuning in editor.

### Scene 1.2 corridor — static BackgroundCamera (no vertical dip)
- Request: Fix downward camera dip and red top/bottom bands in 1.2 only; full corridor edge-to-edge, no letterbox.
- Implementation: Replaced `camera_follow_vertical.gd` + hand-tuned `limit_top`/`limit_bottom` with `background_camera_controller.gd` (`STATIC_LOCKED`, `COVER`). Removed duplicate cover-fit math from `1.2_Corridor.gd`; colliders sync via `Camera2D.layout_applied`. Preserved horizontal framing with `static_center.x = 560` (legacy `fixed_x`). Reverses deferred BackgroundCamera migration for 1.2 only.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Camera stays locked; whole corridor visible at once; no vertical pan/clamp dip; limits derived from PNG `world_rect`.
- Verification: Manual F6 on `1.2_Corridor` — walk full corridor; confirm no dip, no red bands, edge-to-edge fill, colliders aligned.

## 2026-07-14

### Upgrade Godot editor to 4.7

- Request: User downloaded Godot 4.7 into the repo root alongside the 4.6.3 executable; update repo references to the new version and note any 4.7 changes relevant to AXEL.
- Implementation: Pointed `tools/cmd/godot.cmd`, `tools/Godot.code-workspace`, `.vscode/settings.json`, `AXEL/.vscode/settings.json`, and `README.md` at `Godot_v4.7-stable_win64.exe` (console variant too). Left the 4.6.3 binaries in place (user did not ask for removal). `project.godot` `config/features` still lists `"4.6"`; left as-is since 4.7 opens/runs 4.6-tagged projects without issue.
- Files changed:
  - `tools/cmd/godot.cmd`
  - `tools/Godot.code-workspace`
  - `.vscode/settings.json`
  - `AXEL/.vscode/settings.json`
  - `README.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: CLI wrappers and editor integration now launch Godot 4.7; no AXEL script/shader changes required. Reviewed 4.7 breaking-change list (audio spectrum analyzer API, keyboard/mouse device ID renumbering, shader preprocessor macro restrictions, particle angular velocity, Android OBB removal) — AXEL uses none of these (no `AudioEffectSpectrumAnalyzer`, no hardcoded input device IDs, no 3D particles with rotation, not exporting Android OBB). One project shader (`white_sprite.gdshader`) uses a simple `#define` constant, which is unaffected.
- Verification: `Godot_v4.7-stable_win64_console.exe --version` → `4.7.stable.official.5b4e0cb0f`; `tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd` → `Determinism check OK (100 spins, seed 12345)`.
- Notes: Historical changelog entries still cite 4.6.2/4.6.3 console invocations where recorded at implementation time. No AXEL-specific new features from 4.7 (HDR output, AreaLight3D, VirtualJoystick, MeshLibrary editor, Asset Store redesign) are directly applicable, since AXEL is a 2D Windows-focused project without 3D lighting, mobile touch controls, or GridMap usage.

### Corridor camera re-checks viewport size on resize

- Request: Fix 1.2 Corridor camera framing in the docked editor Game panel — corridor art appeared in a small bottom-right rectangle with large red/dark-red borders; movement still worked.
- Implementation: Ported only the resize-recheck line from `cursor/mobile-portrait-touch-ef45` into `background_camera_controller.gd` — `get_viewport().size_changed.connect(_run_pipeline)` in `_ready()` so zoom/limits recompute when the viewport size changes (e.g. after embedded Game panel settles). No portrait follow/zoom behavior brought over; pipeline still derives limits from `Layout.get_viewport_size()` — no manual `limit_*` / `fixed_x` tuning.
- Files changed:
  - `AXEL/axel_project/scenes/core/background_camera_controller.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: BackgroundCamera scenes (including 1.2 Corridor) should fill the window correctly in docked and floating Play modes; resizing the window keeps framing correct. Desktop behavior unchanged aside from resize recalculation.
- Verification: Headless smoke — `tools\cmd\godot.cmd --headless --path AXEL/axel_project --quit-after 2 res://scenes/Arc_1/1.2_Corridor.tscn` exits 0. Manual: F6 docked + floating Play on `1.2_Corridor` — confirm full-window fill, movement, no portrait UI/zoom.
- Notes: `exploration_viewport.gd` resize caveat (embedded panel ignores design size) unchanged; fix is camera-side recheck only. Mobile branch left untouched.

### Flexible window resolution + 3:2 aspect (Phase 1 — global)

- Request: Game window should support any resolution/size the player picks, always keeping a 3:2 gameplay aspect (letterboxed), instead of the old per-scene fixed window size. Prepare for a future resolution settings screen (do not build the screen now). Playtest at 1920x1280.
- Implementation: Switched window sizing from per-scene OS-window forcing to Godot's project-wide Keep-aspect scaling. `project.godot` `[window]`: base `size/viewport_width/height` = `1920x1280` (true 3:2, was 1400x900), `content_scale_aspect=1` (Keep, was 4/Expand); left `content_scale_mode=1` (CanvasItems) and resizability unchanged (single-lever change vs the reverted 2026-05-19 attempt that also changed scale mode + resizable and broke 1.1). Gutted `exploration_viewport.gd` to an inert stub — removed `_ready()`/`_exit_tree()` window/content-scale overrides and helper funcs; kept the node + `design_viewport`/`debug_scale` exports so 1.1/1.2 still load without `.tscn` edits. `background_camera_controller.gd` unchanged (its `size_changed` listener from the prior entry already recomputes cover-fit at any window size).
- Files changed:
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/scenes/core/exploration_viewport.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_LAYOUT_RULES.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Window is now freely resizable; gameplay stays 3:2 with automatic letterbox bars when the window is a different shape. 1.2 Corridor (and future BackgroundCamera scenes) fill the 3:2 area at any window size. Combat/menus inherit the same global Keep-aspect (may show letterbox bars off-3:2). Supersedes the "global stays 1400x900, resize per scene" rule; overrides the AI_DOCS legacy per-scene window note with approval.
- Verification: Headless smoke on 1.2 Corridor (see Phase 2 entry for combined run); manual F6 docked + floating at multiple window sizes.
- Notes: 1.1 School Exterior handled separately in Phase 2 (older `camera_follow_vertical.gd` camera needed migration first, since this exact global-resolution area broke 1.1 before). No settings-screen UI built yet — global Keep-aspect + resizable window prepares for it.

### Flexible window resolution + 3:2 aspect (Phase 2 — 1.1 camera migration)

- Request: With the new global 3:2 aspect (Phase 1), make 1.1 School Exterior zoom so no area outside the background art is ever visible. User approved the camera swap and accepted that hand-placed colliders will need manual editor re-alignment afterward.
- Implementation: Migrated `1.1_SchoolExterior.tscn` `Camera2D` from `camera_follow_vertical.gd` (fixed X + manual `limit_left/top/right/bottom`) to `background_camera_controller.gd` (`BackgroundCamera`): `camera_mode=1` (MOVABLE_FOLLOW), `fit_mode` default COVER, `background_path=../Background_1_1`, `target_path=../PlayerLayer/Player`; removed the hand-tuned `fixed_x`/`limit_*`. COVER + auto-zoom guarantees the art always fills the 3:2 view (no void fringe). Kept `camera_follow_vertical.gd` on disk (now unreferenced) for rollback. Did NOT reparent the player to `WalkableWorld/Player` — the working 1.2 scene keeps the `PlayerLayer` CanvasLayer (layer=100, follow_viewport) to stay drawn above noir, so 1.1 keeps the same proven structure; the deferred "world-space player" migration remains deferred.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 1.1 now uses art-derived camera limits and auto-zoom (COVER), following the player in X and Y (previously fixed-X, vertical-only). Because `BackgroundCamera` re-fits `Background_1_1` at runtime (cover-fit scale/position) and 1.1's colliders are NOT auto-synced to the background (unlike 1.2), walls/tree/rock/door colliders and the player spawn/intro-walk targets will be misaligned until re-tuned by hand in the editor. Expected and accepted.
- Verification: Headless — `1.1_SchoolExterior.tscn` (with `AXEL_SKIP_INTRO=1`) and `1.1_SchoolExterior_Playtest.tscn` both start clean, exit 0, no errors/null warnings (no repeat of the prior "would not start"). `1.2_Corridor.tscn` also exits 0 under the new global settings.
- Follow-up (manual, user): verify leaf-occlusion fade near trees and that the player still draws above the noir overlay; confirm no background edge/void is visible at various window sizes and 3:2.

### Flexible window resolution + 3:2 aspect (Phase 2b — 1.1 collider auto-sync)

- Request: After the Phase 2 camera swap, player couldn't walk all the way down (blocked by something), and the spawn point/background looked vertically offset — user wants the new global resize system to fully work on 1.1, not a one-time manual drag fix.
- Root cause: `Background_1_1` was hand-placed (`position=(32,-297)`, `scale≈(0.335,0.321)`) for the old fixed-window setup. `background_camera_controller.gd` now repositions/rescales that sprite live (cover-fit) every run, but `EnvironmentColliders` (walls, tree lines, rocks, stump, doors — all hand-placed to match the *old* sprite placement) never moved, so colliders no longer lined up with the new, bigger/shifted art — the old `BottomWall` sat partway inside the new (larger) art instead of at its true bottom edge.
- Implementation: Ported `1.2_Corridor.gd`'s `layout_applied` collider-sync pattern into `1.1_SchoolExterior.gd`, generalized for 1.1's non-zero old baseline. On `Camera2D.layout_applied` (and once synchronously in `_ready()` using the background's already-applied transform, so the skip-intro spawn calculation isn't stale), computes `env_scale = new_scale_factor / _OLD_BG_SCALE` and `env_position = new_bg_position - env_scale * _OLD_BG_POSITION`, then applies to `EnvironmentColliders` as a single container transform — this remaps the entire hand-placed collider subtree (which was baked in "old-world-space") into the live cover-fit space without editing any individual wall/tree/door coordinate. Stays correct at any future window size/resolution, matching the point of the flexible-resolution system (not just today's fixed values).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Walls/trees/rocks/doors and the `_left_stones_stand_target()` intro-walk target now track the live background placement; player should no longer be blocked short of the true map edges, and ground should sit under the spawn point correctly.
- Verification: Wrote and ran a temporary headless diagnostic (instantiate scene, read `Background_1_1`/`EnvironmentColliders` transforms and key collider global positions after a few frames, deleted after use) — confirmed `BottomWall` lands within ~0.6px of the background's computed `world_rect` bottom edge and `TopWall` within ~0.7px of the top edge, proving the remap formula is correct and scale-independent. Headless scene load also exits 0 with no errors.
- Notes: The player's raw off-screen starting position (used only as a walk-FROM point during the non-skip intro, before scripting a walk to `_left_stones_stand_target()`) was left unconverted — low priority since it's immediately walked away from; flag if it looks visually wrong on a fresh (non-skip-intro) playthrough.

### 1.1 player walks a fixed-height road

- Request: Camera follow behavior in 1.1 is good; player should instead walk straight along the road left/right, with the character's feet fixed at world Y=385 (not free vertical movement).
- Implementation: Added a reusable `@export var locked_feet_y: float = -1.0` to `scripts/Player.gd` (default disabled). When set, `_apply_locked_feet_y()` runs after `move_and_slide()` in `_physics_process()` (both normal input and scripted-velocity paths) — computes the current feet-to-body offset via the existing `_get_collision_feet_anchor_y()` helper and snaps `global_position.y` so the feet land exactly on `locked_feet_y` every frame, while horizontal movement is untouched. Set `locked_feet_y = 385.0` on `1.1_SchoolExterior.tscn`'s `Player` node only; no change for 1.2 or other scenes (defaults stay off).
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: In 1.1, pressing up/down no longer moves the player visually — feet stay glued to Y=385 while left/right movement works normally. Applies uniformly to both free-roam and the scripted intro walk-to-stones.
- Verification: Headless smoke on `1.1_SchoolExterior.tscn` and `1.2_Corridor.tscn` — both exit 0, no errors.
- Notes: If the scripted intro walk to the rocks looks odd sliding at a fixed height, flag it — may want to disable the lock during that one sequence.

## 2026-07-15

### Dialogue bar: skip-to-reveal + auto-advance timer (doc backfill)

- Request: Catch up docs/changelog for AXEL changes made in earlier chats that were never logged.
- Implementation: Found `TopDialogueOverlay.gd` already had an unlogged behavior change in the working tree — replaced the old "5× typewriter speed boost" skip with an instant full-line reveal (`_skip_requested` breaks the per-character loop). Added an auto-advance deadline (`_compute_advance_deadline_ms()`): normally `AUTO_ADVANCE_READING_BASE_SEC` (3s) + `AUTO_ADVANCE_READING_SQRT_COEFFICIENT` (0.5774) × sqrt(extra words), capped at `AUTO_ADVANCE_READING_MAX_SEC` (20s); after an instant skip-reveal, a flat `AUTO_ADVANCE_SKIP_GRACE_SEC` (2s) grace instead. `_wait_for_advance()` now breaks on either a manual advance press or this deadline, so a line can never block forever. `allow_skip=false` still ignores skip-reveal + manual advance input entirely, but the reading-timer auto-advance still applies. No gameplay code was changed in this pass — only the docs were brought in sync with the existing code.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: None (docs only) — the running behavior (auto-advance + instant skip-reveal) was already live; this just documents it.
- Verification: Re-read `TopDialogueOverlay.gd` end-to-end and confirmed the description above matches the current implementation.
- Notes: Recommend a manual check next playtest: let a line sit untouched and confirm it auto-advances; press advance mid-type and confirm it snaps straight to the full line.

### Corridor 1.2: fix Camera2D background_path (camera framing)

- Request: Fix scene 1.2 showing flat dark-red empty area — only a sliver of corridor art visible bottom-right.
- Implementation: Corrected `Camera2D.background_path` from `WalkableWorld/Background` to `../WalkableWorld/Background` so the sibling-relative path resolves; restores auto-framing via `background_camera_controller.gd` and `layout_applied` wall resync.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
- Behavior impact: Corridor background should fill and center the screen (like 1.1); colliders may resync live for the first time — nudge only if misaligned.
- Verification: Headless load `res://scenes/Arc_1/1.2_Corridor.tscn` exit 0, no errors; visual framing + collider walk-through still needs in-editor check.
- Notes: Legacy scene — scoped wiring fix only; no script or collider changes unless recheck finds mismatch.

### Corridor 1.2: right exit + walkable 2.2 Basement Door room

- Request: Open the Corridor's right side so the player can walk off-screen into a real walkable basement door room (replacing the black-popup placeholder); door shows `"Not yet."` once on `[E]`; left-edge return to Corridor.
- Implementation: Moved `RightWall` right in `1.2_Corridor.tscn` and added `ExitTrigger` `Area2D`; `1.2_Corridor.gd` auto-transitions to `2.2_BasementDoor.tscn` on player entry (shared `_begin_scene_transition()` with locker hub). Built new walkable `2.2_BasementDoor.tscn` + `2.2_BasementDoor.gd` with placeholder background, chained-door polygons, floor divider line + collision, door `[E]` interact gated by `GameManager.basement_door_line_seen`, left `ExitTrigger` return to corridor at saved `corridor_return_pos`. Renamed/replaced `2.2_BasementBlockedTemp.tscn`. Added `basement_door_line_seen` persistence to `GameManager.gd`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.2_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.2_BasementDoor.gd`
  - `AXEL/axel_project/exports/Drawings/2.2_BasementDoor.png`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Walking right in Corridor auto-loads the basement room; `[E]` at chained door plays `"Not yet."` once; walking left returns to Corridor at prior position. Locker Hub unchanged (still no basement button).
- Verification: Headless scene load on `1.2_Corridor.tscn` and `2.2_BasementDoor.tscn`; manual walk-through per acceptance checklist.
- Notes: Placeholder flat-grey background; swap `2.2_BasementDoor.png` for final art later. Approved legacy change to `1.2_Corridor.tscn` `RightWall` only.

## 2026-07-16

### Renumber scenes: Locker Hub/Basement Door fold into Arc 1, later arcs shift down

- Request: Make the in-editor scene numbering match the story order used in the docs — fold Locker Hub / Basement Door into Arc 1 (as `1.3`/`1.4`) and shift every later arc down by one, so `Arc_2`..`Arc_7` become `Arc_1`..`Arc_6` and `Endings` become `7.1`–`7.6` instead of `8.1`–`8.6`.
- Implementation: Renamed (via `git mv`, preserving history) every numbered scene file and its `.gd`/`.uid` sidecars into the new arc folders: `2.1_LockerHub` → `1.3_LockerHub`, `2.2_BasementDoor`/`2.2_BasementBlockedTemp` → `1.4_BasementDoor`/`1.4_BasementBlockedTemp` (all into `Arc_1`); `Arc_3` (Cafeteria) → `Arc_2`; `Arc_4` (Backyard) → `Arc_3`; `Arc_5` (Teachers' Lounge) → `Arc_4`; `Arc_6` (Classroom) → `Arc_5`; `Arc_7` (Basement) → `Arc_6`; `Endings` `8.1`–`8.6` → `7.1`–`7.6`. Updated the self-referencing `ext_resource` script path and root node name inside each moved `.tscn`, the `scene_id` placeholder property on the placeholder/ending scenes, and the hardcoded path constants in `1.2_Corridor.gd` (locker hub / basement door targets), `1.3_LockerHub.gd` (four destination-button paths), and `tools/scene_smoke_check.gd`. Cafeteria/Backyard/Teachers'/Classroom/Basement placeholder scenes have no scene-to-scene script wiring yet, so no other `.gd`/`.tscn` edits were needed there. Renumbered all narrative docs to match: `AXEL_SCENES_ARC1.md` (gains 1.3/1.4 sections), `AXEL_SCENES_ARC2.md`–`ARC7.md` (shifted content, `ARC8.md` deleted — its content is now `ARC7.md`), `AXEL_SCENES_NEW.md` index, `AXEL_SCENES_BLUEPRINT.md`, `ARTIST_BACKGROUND_LIST.md`, `SCENE_BUILDER_AGENT_SPEC.md` example filenames, and `tools/scene_builder/layout_planner.py` (`CANONICAL_BY_SCENE_ID` classroom entries + the `8.` → `Endings` section-prefix rule, now `7.`) plus its 4 stale `layout_drafts/*.json` header fields. Reapplied the earlier CRT red-edge fix on top of the move: removed `RoomOutline` from `1.4_BasementDoor.tscn` and set `Camera2D.margin_px = 12` (same root cause/fix as before — see the two entries above this one — just re-landed after the scene renumbering had reverted them).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/*` through `Arc_6/*` (renamed/renumbered contents), `AXEL/axel_project/scenes/Endings/*` (renumbered `7.1`–`7.6`)
  - `AXEL/axel_project/tools/scene_smoke_check.gd`
  - `AXEL/axel_project/tools/scene_builder/layout_planner.py`
  - `AXEL/axel_project/tools/scene_builder/output/layout_drafts/loc_classroom_draft.json`, `loc_desk_draft.json`, `loc_board_draft.json`, `loc_board_success_draft.json`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md` through `ARC7.md` (`ARC8.md` deleted)
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_NEW.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/scenes/ARTIST_BACKGROUND_LIST.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Same runtime behavior as before (all scene transitions re-wired to the new paths); Basement Door's CRT red edge-frame fix is back in place. Background art PNG filenames under `exports/Drawings/` were deliberately left on their old numbers (e.g. `2.1_Locker.png`, `2.2_BasementDoor.png`) — renaming art assets was out of scope and existing `path=` references to them still resolve.
- Verification: Headless `scene_smoke_check.gd` exit 0 (loads `0.1_MainMenu`, `1.1_SchoolExterior`, `1.2_Corridor`, `1.3_LockerHub`); `git status` clean rename detection (no orphaned old-path files); repo-wide grep for old `Arc_2/2.`–`Arc_7/7.`/`Endings/8.` path strings returns no hits outside this changelog's historical entries above.
- Notes: If Godot's editor has any of the old-numbered scenes open in tabs from before this rename, close them without saving before reloading the project — resaving a stale tab path can recreate the old duplicate file on disk (this is what broke the previous attempt at this same rename).

### Renumber Drawings art to match the Arc 1 fold-in (follow-up)

- Request: The prior "Renumber scenes" entry above deliberately left `exports/Drawings/` art filenames on their pre-move numbers; user asked to finish the job and bring the pictures in line with the new scene numbering, then double-check the whole renumbering had landed everywhere.
- Implementation: Renamed `exports/Drawings/2.1_Locker.png` → `1.3_Locker.png`, `2.2_BasementDoor.png` → `1.4_BasementDoor.png`, `3.1_Cafeteria.png` → `2.1_Cafeteria.png` (plus each `.png.import` sidecar, updating its `source_file=` field to the new name; `uid=` values kept unchanged). Updated the two live references to the renamed art: `1.3_LockerHub.gd`'s `HUB_BG_PATH` const and `1.3_LockerHub.tscn`'s `ext_resource` path (Locker), and `1.4_BasementDoor.tscn`'s `ext_resource` path (Basement Door); `2.1_Cafeteria.tscn` is still a bare placeholder with no background wired in yet, so no scene edit was needed for the Cafeteria art. Re-audited the rest of the prior renumbering pass and fixed the pieces that were still stale: the on-screen `scene_id` placeholder label in 25 placeholder scenes across `Arc_2`–`Arc_6` (e.g. `Arc_2/2.1_Cafeteria.tscn` still showed `"3.1"`) now matches each scene's real file number; three leftover mentions of the old `2.1_LockerHub.tscn`/`2.1_Locker.png`/`2.2_BasementDoor.png` paths inside `AXEL_SCENES_BLUEPRINT.md`'s prose and its frontmatter todo list. `layout_planner.py`, its 4 `layout_drafts/*.json` outputs, and `ARTIST_BACKGROUND_LIST.md` were already correct by the time of this pass (fixed either by the prior entry above or by Godot's own editor re-saving open scene tabs mid-session, per that entry's closing note).
- Files changed:
  - `AXEL/axel_project/exports/Drawings/1.3_Locker.png`, `.png.import` (renamed from `2.1_Locker.*`)
  - `AXEL/axel_project/exports/Drawings/1.4_BasementDoor.png`, `.png.import` (renamed from `2.2_BasementDoor.*`)
  - `AXEL/axel_project/exports/Drawings/2.1_Cafeteria.png`, `.png.import` (renamed from `3.1_Cafeteria.*`)
  - `AXEL/axel_project/scenes/Arc_1/1.3_LockerHub.gd`, `1.3_LockerHub.tscn`, `1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`, `2.2_CafeteriaMemory.tscn`, `2.3_Kitchen.tscn`, `2.4_KitchenFlashlightPickup.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`, `3.1b_BackyardClickStep1.tscn`, `3.1c_BackyardNameReveal.tscn`, `3.1d_BackyardNamedScene.tscn`, `3.2_BackyardHint.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`, `4.2_TeachersMemory.tscn`, `4.3_TeachersKeyWall.tscn`, `4.4_TeachersKeyPickup.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`, `5.2_ClassroomDesk.tscn`, `5.3_ClassroomBoard.tscn`, `5.4_ClassroomBoardSuccess.tscn`
  - `AXEL/axel_project/scenes/Arc_6/6.1_BasementDoor.tscn` through `6.8_BasementCorpse.tscn` (all 8)
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Locker Hub and Basement Door now load their background art from the renamed paths (same images, same look) — purely a filename/label consistency fix, no gameplay or visual change. The 25 placeholder screens now display their correct scene number instead of a leftover one.
- Verification: Re-read every renamed `.png.import` to confirm `source_file=` matches the new filename; spot-checked 10 of the 25 `scene_id` fixes with `Select-String`; repo-wide `rg` for the old Drawings filenames and old `scene_id` values returns no hits outside this changelog's historical entries.
- Notes: `exports/Drawings/` still only has art for `1.1`, `1.2` (+ an alt `1.2_Corridor_New.png`), `1.3`, `1.4`, and `2.1` — the rest of the arcs have no art yet, per `ARTIST_BACKGROUND_LIST.md`.

### CRT red fringe on Basement Door — per-scene `margin_px` (backfill)

- Request: Fix red CRT edge outlines on the Basement Door room without changing global camera/CRT settings for every scene (same class of issue previously tuned on 1.1/1.2).
- Implementation: On `1.4_BasementDoor.tscn` only — set `Camera2D.margin_px = 12` so `BackgroundCamera` insets art-derived limits (hides the CRT red fringe), and removed the decorative `RoomOutline` `Line2D` that was reading as an extra red frame under post-FX. No change to `background_camera_controller.gd` defaults (`DEFAULT_MARGIN_PX` stays `0`) and no CRT shader edits.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
- Behavior impact: Basement Door framing no longer shows a red CRT edge band; other scenes unchanged unless they set their own `margin_px`.
- Verification: Visual check in editor/play; headless scene load still OK after renumber re-apply.
- Notes: Same `margin_px=12` pattern later reused on `2.1_Cafeteria.tscn`. Logged here because the Jul 16 renumber entry referred to "two entries above" that were never written.

### Build walkable 2.1 Cafeteria (new-scene pattern)

- Request: Create the next scene under the new numbering, using new-scene parameters / global settings and `2.1_Cafeteria.png` as the background.
- Implementation: Replaced the `ScenePlaceholder` stub with a full walkable exploration scene: `WalkableWorld/Background` (`2.1_Cafeteria.png` + locked-background script), texture-pixel wall colliders + three `[E]` interact zones (table / kitchen / return), `WalkableWorld/Player` (scale `3`, speed `253`), `BackgroundCamera` `STATIC_LOCKED`/`COVER` with `margin_px=12`, collider + spawn sync on `layout_applied`. Enter dialogue once (`TopDialogueOverlay`); zones load `2.2_CafeteriaMemory` / `2.3_Kitchen` (still placeholders) or return to `1.3_LockerHub`. Added `2.1_Cafeteria.tscn` to `tools/scene_smoke_check.gd`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/tools/scene_smoke_check.gd`
- Behavior impact: Hub → Cafeteria is now a walkable room with the real cafeteria art; Memory/Kitchen targets still open placeholder scenes until those are built.
- Verification: Headless `scene_smoke_check.gd` includes `2.1_Cafeteria.tscn` and passes (7 scenes).
- Notes: Ghostly-figure idle float from the HTML blueprint is still TODO; zone rectangles are first-pass — nudge in editor if needed.

### Docs catch-up after renumber + Cafeteria ship

- Request: Update all docs from previous chats.
- Implementation: Brought canon and scene plans in sync with shipped code — `AI_DOCS.md` (1.1 collider auto-sync + `locked_feet_y`, 1.2 right exit → 1.4, 1.3/1.4 hub/door notes, new-scene `margin_px` CRT trim, 2.1 Cafeteria walkable); ARC1/ARC2 Implemented notes; BLUEPRINT todos for locker/basement/cafeteria marked completed; artist list marks 1.4 Drawn.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/scenes/ARTIST_BACKGROUND_LIST.md`
- Behavior impact: None (docs only).
- Verification: Cross-checked against current `2.1_Cafeteria.gd`/`.tscn`, `1.4_BasementDoor.tscn`, and prior Jul 15–16 changelog entries.
- Notes: Corridor/locker/basement renumber path wiring was already logged earlier today; this pass fills the gaps those entries left in canon.

### 1.4 door dialogue replay + right-edge corridor return

- Request: Door `[E]` should reopen `"Not yet."` after the player leaves and returns, but not restart the line while the dialogue bar is still visible (skip/advance as normal). Walking left from 1.4 should always spawn on the right edge of 1.2 with only a sliver of the player visible.
- Implementation: Removed the `basement_door_line_seen` interact gate in `1.4_BasementDoor.gd` (still set for save compat); if the bar is visible, scene input returns so `TopDialogueOverlay` handles skip/advance. Leaving 1.4 sets transient `GameManager.corridor_spawn_side="basement_right"`; `1.2_Corridor.gd` places a right-edge peek from the live `ExitTrigger` (after layout) and arms a short exit-trigger grace so peek cannot bounce back into 1.4.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Door line is replayable when the bar is closed; 1.4→1.2 always peeks from the right. Locker-hub return path unchanged.
- Verification: Manual playtest of door re-interact + left exit spawn; no headless bot covering this path.
- Notes: User said “1.3” for the return target; left exit loads 1.2 Corridor (1.3 is the non-walkable hub).

## 2026-07-17

### 1.4 door E-spam crash — busy gate + token-safe hide
- Request: Scene 1.4 often crashes when spamming `E` on the door after the replayable-door fix; keep replay, do not roll back the once-ever gate removal.
- Implementation: `1.4_BasementDoor.gd` uses `_door_dialogue_busy()` (`_door_line_running` / `is_sequence_busy()` / bar visible) so spam only snap-hides the chip and never stacks a second `show_line`; chip show is blocked while busy. `TopDialogueOverlay` adds `is_sequence_busy()` (`_sequence_active` for whole show/hide) and token-guards `hide_line()` so a stale CRT-off cannot blank a newer line.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Door line still replays when idle; spam `E` during a line only skips/advances; no stacked CRT sequences.
- Verification: Manual — mash `E` at 1.4 door through several open/close cycles; confirm no freeze and replay after bar closes.
- Notes: InteractPromptOverlay mid-open/close snap from prior spam visual fix left unchanged.

### CRT cancel — stop using Tween.get_bound_node
- Request: Spamming door `E` still errored with `Nonexistent function 'get_bound_node' in base 'Tween'`.
- Implementation: `CrtPowerFx` now tracks CRT tweens per host via `_make_tween` / `_crt_tweens` and kills that list on `cancel()`, so cancel no longer calls `Tween.get_bound_node()` (not exposed in this project's Godot bindings).
- Files changed:
  - `AXEL/axel_project/scenes/ui/crt_power_fx.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Chip/dialogue CRT cancel on spam no longer throws; visuals still snap via existing cancel reset.
- Verification: Mash `E` at 1.4 door; Output should stay clear of `get_bound_node` errors.

### Scene swap 1.2↔1.4 — null process_frame / stuck enter glitch
- Request: Walking between 1.4 and 1.2 errored `Invalid access to property or key 'process_frame' on a base object of type 'null instance'` and left the screen as white-noise glitch.
- Implementation: `CrtPowerFx` awaits via `_await_process_frame()` (null-safe tree). `InteractPromptOverlay` / `TopDialogueOverlay` cancel/interrupt on `tree_exiting`. 1.2/1.4 transitions call `interrupt_line()` before `change_scene_to_file`.
- Files changed:
  - `AXEL/axel_project/scenes/ui/crt_power_fx.gd`
  - `AXEL/axel_project/scenes/ui/InteractPromptOverlay.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Scene exit no longer crashes mid CRT/dialogue await; enter glitch should finish normally.
- Verification: Walk 1.2↔1.4 repeatedly with `[E]` chip visible; no `process_frame` null error, no stuck static screen.

### Fix 2.1 Cafeteria crop + missing player
- Request: Cafeteria background cropped the upper foodline/kitchen entrance; player did not appear and should be ~2× smaller than 1.4 with speed scaled to match.
- Implementation: Top-biased `static_center=(960,0)` on `BackgroundCamera` so COVER framing keeps the top of `2.1_Cafeteria.png` in view. Reparented Mike to `PlayerLayer` (layer 100, above noir) matching 1.4; scale `1.5` / speed `126.5`; spawn sync via `PlayerLayer/Player`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Foodline/kitchen entrance visible on enter; Mike visible above noir at half 1.4 size/speed.
- Verification: Manual — hub → cafeteria; confirm top framing, player visible, `[E]` zones still work.

## 2026-07-20

### 2.1 cafeteria — wire ChairBlockTop/Bottom fade zones
- Request: `ChairBlockTop_Behind` opacity filter not applying where its `CollisionPolygon2D` is placed.
- Implementation: `_configure_table_occlusion_masks` was looking for leftover names `ChairBlockLeft_Behind` / `ChairBlockRight_Behind` (missing nodes → empty shader slots). Pointed it at the real zones `ChairBlockBottom_Behind` and `ChairBlockTop_Behind`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Walking behind the top/bottom chair fade polygons should fade Mike like the left table zone.
- Verification: Not run; confirm in editor by walking into `ChairBlockTop_Behind`.

### 2.1 cafeteria — spawn from Player node position
- Request: Use wherever the `Player` node is placed in the editor as the spawn point, instead of a hardcoded constant.
- Implementation: Removed `PLAYER_SPAWN_TEX`. Scene captures `PlayerLayer/Player.position` in `_ready()` (texture-pixel space, same as colliders) and applies it via `env.to_global` on first `layout_applied`. Set Player editor position to `(142, 1368)` so current spawn is unchanged until moved.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Drag `PlayerLayer/Player` in the editor to choose spawn; play still remaps that point through cover-fit like the walls.
- Verification: Not run (small spawn-source change; confirm in editor by moving Player and F6).

### Upgrade Godot editor to 4.7.1
- Request: Update all references for the new Godot 4.7.1 executable already present in the repo root.
- Implementation: Pointed `tools/cmd/godot.cmd`, `tools/Godot.code-workspace`, `.vscode/settings.json`, `AXEL/.vscode/settings.json`, `README.md`, and `AGENTS.md` at `Godot_v4.7.1-stable_win64.exe` (console variant too). Removed the previous `Godot_v4.7-stable_*` binaries. Left `project.godot` `config/features` as `"4.7"` (maintenance release of 4.7).
- Files changed:
  - `tools/cmd/godot.cmd`
  - `tools/Godot.code-workspace`
  - `.vscode/settings.json`
  - `AXEL/.vscode/settings.json`
  - `README.md`
  - `AGENTS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: CLI wrappers and editor integration use Godot 4.7.1; no AXEL script/shader changes required (4.7.x compatible maintenance build).
- Verification: `Godot_v4.7.1-stable_win64.exe --version` → `4.7.1.stable.official.a13da4feb`; `tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd` → `Determinism check OK (100 spins, seed 12345)`.
- Notes: Historical changelog entries still cite older console invocations where recorded at implementation time.

### Fix player size when resizing the game window
- Request: Player sprite stayed fixed size when resizing the Game window, while the rest of the scene scaled.
- Implementation: First attempt (`canvas_items` + `keep` stretch) shrank dialogue UI/fonts and player — reverted stretch to `disabled`. Added `PlayerCoverSync` so exploration scenes scale Mike (and speed / `locked_feet_y`) with cover-fit on `layout_applied`, remapping position through `EnvironmentColliders` on later resizes.
- Files changed:
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/scenes/core/player_cover_sync.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Dialogue/UI keep prior pixel sizing; Mike grows/shrinks with the background when the Game window resizes.
- Verification: Headless scene smoke + `PlayerCoverSync` scale ratio check.
- Notes: Authored player scale at the first layout is the reference; later covers use `cover / reference`.

### 2.1 cafeteria — separate TableBlockLeft/Right shapes
- Request: Changing TableBlockLeft or Right width should not change the other table.
- Implementation: Split shared `RectangleShape2D_table_block` into `RectangleShape2D_table_block_left` and `RectangleShape2D_table_block_right`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
- Behavior impact: Editing one table collider size no longer affects the other.
- Verification: Scene file inspection (each CollisionShape2D points at its own SubResource).

### 2.1 cafeteria — LeftDoorBlock collider
- Request: Extra collision border for the left door around `(1500, 500)`.
- Implementation: Added `EnvironmentColliders/LeftDoorBlock` StaticBody2D at `(1500, 500)` with its own `RectangleShape2D_left_door` (default `120×280`; designer may nudge child shape).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
- Behavior impact: Extra solid blocker near the left-door art; tune in editor.
- Verification: Not run (collider add only).

### Docs sync — PlayerCoverSync, stretch, 2.1 cafeteria, prior chats
- Request: `update docs`, including previous two agent chats (Godot 4.7.1 upgrade; 2.1 chair fade + Player-node spawn).
- Implementation: Synced canon — `AI_DOCS.md` (stretch `disabled`, `PlayerCoverSync`, interact chip `screen_offset` / shape center anchor, 2.1 scale/speed/spawn/fade/table shapes/`LeftDoorBlock`); `AXEL_SCENES_ARC2.md` Implemented note. Prior chats already had changelog entries (`Upgrade Godot editor to 4.7.1`, `2.1 cafeteria — wire ChairBlockTop/Bottom fade zones`, `2.1 cafeteria — spawn from Player node position`).
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only.
- Verification: Cross-checked against `project.godot`, `2.1_Cafeteria.tscn`, and existing 2026-07-20 changelog titles.

## 2026-07-21

### 2.3 Kitchen — walkable room + flashlight pickup
- Request: Replace placeholder 2.3_Kitchen.tscn with a real walkable room (Basement Door template), [E] door back to cafeteria with kitchen-door peek, one-time flashlight pickup, delete unused 2.4.
- Implementation: Built 2.3_Kitchen.tscn/.gd with flat 2.3_Kitchen.png placeholder, walls, prep/center/fridge/shelves/door placeholders, door [E] exit (kitchen_spawn_side), flashlight [E] (hasFlashlight + inventory + "Let there be light!"), once-ever enter line. Additive GameManager kitchen spawn/enter helpers. Cafeteria peeks beside KitchenInteractArea on return. Removed stub 2.4_KitchenFlashlightPickup.tscn.
- Files changed:
  - AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn
  - AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.gd
  - AXEL/axel_project/exports/Drawings/2.3_Kitchen.png
  - AXEL/axel_project/exports/GameManager.gd
  - AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd
  - AXEL/axel_project/scenes/Arc_2/2.4_KitchenFlashlightPickup.tscn (deleted)
  - AXEL/axel_project/plans/core/AI_CHANGELOG.md
- Behavior impact: Cafeteria kitchen doorway loads a walkable kitchen; flashlight is found in-room; return peeks at the cafeteria kitchen door.
- Verification: Headless import + scene smoke if available; manual playtest of enter/pickup/return recommended.

## 2026-07-21

### 2.3 Kitchen — placeholder colors match black/red visual style
- Request: Kitchen background read as red/white under the CRT vfx instead of black; placeholder block fills/outlines did not follow the game's black-outline style.
- Implementation: Regenerated 2.3_Kitchen.png as pure black (renders correctly under the red-tint CRT shader). Changed all placeholder block fills (prep table, center table, fridge, shelves, door, flashlight) to a 10% grey shade (Color(0.9,0.9,0.9,1)) and added/kept black (Color(0,0,0,1)) Line2D outlines on every block, matching the existing DoorOutline convention. Preserved the user's manually repositioned block coordinates.
- Files changed:
  - AXEL/axel_project/exports/Drawings/2.3_Kitchen.png
  - AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn
  - AXEL/axel_project/plans/core/AI_CHANGELOG.md
- Behavior impact: Kitchen background now renders black (red under CRT) instead of red/white; all placeholder shapes show light-grey fill with black outlines.
- Verification: Headless reimport + scene_smoke_check.gd OK (7 scenes).

## 2026-07-21

### 2.3 Kitchen — background flipped to white (vfx inverts to black)
- Request: Correction — kitchen background should be white, not black; the CRT/vfx shader inverts white to black.
- Implementation: Regenerated `2.3_Kitchen.png` as pure white so it renders black under the vfx shader (previous black fill was rendering red/white).
- Files changed:
  - `AXEL/axel_project/exports/Drawings/2.3_Kitchen.png`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Kitchen background now renders black under the CRT vfx as intended.
- Verification: Headless reimport run.

### 2.1 cafeteria — kitchen return peek shifted up 100px
- Request: Offset the player's re-spawn point (returning from 2.3 Kitchen to 2.1 Cafeteria) upward by ~100px.
- Implementation: `_kitchen_door_peek_global()` places the player via `KITCHEN_PEEK_MARGIN_PX` below `KitchenInteractArea`'s bottom edge; changed constant from `12.0` to `-88.0` (12 − 100; Y increases downward in Godot).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
- Behavior impact: Returning from the Kitchen now spawns the player 100px higher (closer to the doorway) than before.
- Verification: Not run (constant tweak only).

### AXEL docs canon sync + cleanup
- Request: Review all `plans/` docs for redundant/stale info; confirm `exports/` and `html/` are gitignored; update ARC2 docs; flag `GODOT_IMPLEMENTATION_GUIDE.md` / `AXEL_SCENES_BLUEPRINT.md` as historical; resolve canon ambiguities; consolidate scene-build docs; remove dead files and leftover debug logging.
- Implementation:
  - Rewrote all `AXEL_SCENES_ARC1–7.md` to locked rewrite dialogue only (dropped old HTML `SOURCE` blocks); folded Arc 2's `2.4` flashlight pickup into `2.3` (in-room pickup, no separate scene).
  - Aligned in-code dialogue strings (`2.3_Kitchen.gd`, `1.2_Corridor.gd`, `1.1_SchoolExterior.gd`) with the locked rewrite lines.
  - Created `plans/scenes/SCENE_BUILDING.md` (merged `SCENE_BUILDER_AGENT_SPEC.md` + `SCENE_LAYOUT_RULES.md` + `SCENE_BACKGROUND_SWAP_CHECKLIST.md`); routed `AI_DOCS.md` and `AXEL_SCENES_NEW.md` to it.
  - Added "historical reference only" banners + canon fixes (shipped-scene flags, `GameManager` autoload) to `AXEL_SCENES_BLUEPRINT.md` and `GODOT_IMPLEMENTATION_GUIDE.md`.
  - Moved stale docs to new `plans/archive/` (`GODOT_IMPLEMENTATION_GUIDE.md`, `AXEL_analysis.md`, `VISUAL_STYLE_OPTIONS.md`, `SCENE_PATCH_INTERFACE.md`, `ARTIST_BACKGROUND_LIST.md`) and added that folder to `.cursorignore`; deleted the dead `AGENT_CONTEXT_ROUTING.md`.
  - Added `/AXEL/axel_project/exports/` and `/AXEL/html/` to `.gitignore`.
  - Deleted dead code/scenes: `1.4_BasementBlockedTemp.tscn`, `camera_follow_vertical.gd`, `combat/scripts/cluster_detector.gd`, Arc 3 split stubs (`3.1b/c/d_*.tscn`), `tools/scene_builder/`, `ScriptReloadMarker.gd` (+ removed its autoload entry from `project.godot`).
  - `MainMenu.gd` Start button now always goes to `1.1_SchoolExterior.tscn` (dropped the corridor-test-scene fallback).
  - Stripped hardcoded agent debug-logging blocks/helpers from `GameManager.gd` and `combat/scripts/*.gd`; fixed a parse error this introduced in `line_detector.gd`.
  - Updated `combat/VERIFICATION_CHECKLIST.md` script inventory (removed `cluster_detector.gd`, added test scripts) and marked `run_state.gd` as planned/not built yet in `AXEL_combat_implementation.md`.
- Files changed (highlights):
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md` … `AXEL_SCENES_ARC7.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md` (new)
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_BLUEPRINT.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`, `AXEL/axel_project/plans/combat/AXEL_combat_design.md`
  - `AXEL/axel_project/combat/VERIFICATION_CHECKLIST.md`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.gd`, `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`, `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Main_Menu/MainMenu.gd`
  - `AXEL/axel_project/exports/GameManager.gd`, `AXEL/axel_project/combat/scripts/combat_root.gd`, `combat_test.gd`, `line_detector.gd`, `free_spins.gd`
  - `AXEL/axel_project/project.godot`, `.gitignore`, `.cursorignore`
  - Deleted: `AXEL/axel_project/plans/core/AGENT_CONTEXT_ROUTING.md`, `AXEL/axel_project/scenes/Arc_1/1.4_BasementBlockedTemp.tscn`, `AXEL/axel_project/scenes/Arc_1/camera_follow_vertical.gd`, `AXEL/axel_project/combat/scripts/cluster_detector.gd`, `AXEL/axel_project/scenes/Arc_3/3.1b_BackyardClickStep1.tscn`, `3.1c_BackyardNameReveal.tscn`, `3.1d_BackyardNamedScene.tscn`, `AXEL/axel_project/tools/scene_builder/`, `AXEL/axel_project/ScriptReloadMarker.gd`
- Behavior impact: No gameplay change intended beyond Main Menu Start target and removal of debug-log side effects; docs now route to one current scene-building guide instead of three overlapping/outdated ones.
- Verification: Headless `determinism_check.gd`, `princess_check.gd`, `combat_test_scaffold_check.gd`, `scene_smoke_check.gd` all OK after fixing a debug-log-removal parse error in `line_detector.gd`.
- Note: `AXEL_SCENES_BLUEPRINT.md` was later archived under `plans/archive/` (see entry below).

### Archive AXEL_SCENES_BLUEPRINT
- Request: Archive the stale scene Blueprint (mostly HTML-era; not live canon).
- Implementation: Moved `plans/scenes/AXEL_SCENES_BLUEPRINT.md` ? `plans/archive/AXEL_SCENES_BLUEPRINT.md` (already covered by `.cursorignore`). Strengthened archived banner. Removed live pointers from `AI_DOCS.md`, `SCENE_BUILDING.md`, `AXEL_SCENES_NEW.md`, `AXEL_notes.md`, QA README/validators; endings references now point at `AXEL_SCENES_ARC7.md`.
- Files changed:
  - `AXEL/axel_project/plans/archive/AXEL_SCENES_BLUEPRINT.md` (moved)
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_NEW.md`
  - `AXEL/axel_project/plans/references/AXEL_notes.md`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
- Behavior impact: None (docs/routing only). Live scene intent is ARC docs + `SCENE_BUILDING.md` + code.
- Verification: Not run (docs move + pointer updates only).

## 2026-07-22

### 2.3 Kitchen — wire in real hand-drawn background
- Request: Swap in the new hand-drawn `2.3_Kitchen.png` (3508×2480, replacing the flat 2400×1500 placeholder), remove the old debug placeholders, and keep exactly 3 collision borders (table, right shelves, top-left shelves).
- Implementation: Measured the new art's pixel layout (grid-annotated crops) to place 3 furniture colliders sized from the drawing; removed all placeholder `Polygon2D`/`Line2D`/`Label` visuals and their now-unused colliders (`PrepTableBlock`, `FridgeBlock`); resized the 4 room-boundary walls to the new texture bounds; the new art has no door/fridge/flashlight drawn, so those functional zones (door exit, flashlight pickup, player spawn) were relocated to sensible open-floor spots rather than removed. Follow-up pass removed a leftover dead `get_node_or_null("...FlashlightVisual")` lookup in `_apply_flashlight_visibility()` now that the node no longer exists.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.gd`
  - `AXEL/axel_project/exports/Drawings/2.3_Kitchen.png`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Kitchen now shows the real hand-drawn room; player still blocked by 4 walls + table/right-shelves/top-left-shelves; door `[E]` and flashlight `[E]` still work, just at new floor positions; spawn point moved next to the new door.
- Verification: Headless `scene_smoke_check.gd` OK after both passes; manual in-editor walk-test still recommended (no local Godot binary in this session to render it).

### Memory indicator — reusable glow asset + Cafeteria test placement
- Request: Turn the `Memory.png` flame spritesheet into a reusable "memory marker" asset (recolored to shades of white so it survives the global CRT filter) that sits in the middle of a memory's InteractArea, and place a test instance in the Cafeteria (2.1) table zone.
- Implementation: Converted `exports/Drawings/Memory.png` (5×48px frames) to a luminance-preserving grayscale sheet at `assets/sprites/memory_glow-Sheet.png` (kept as light grays, not flattened to pure white, so internal shading survives). Built a reusable `scenes/fx/MemoryIndicator.tscn` + `memory_indicator.gd` (runtime `AtlasTexture` slicing/looping, exported `indicator_scale` default `1.5`, exported `visual_offset` for cosmetic nudging). Instanced it under `2.1_Cafeteria.tscn`'s `PlayerLayer` (must be above `NoirPaletteOverlay`, layer 100, or it gets crushed to black/red like the rest of the room — no shader changes needed once art is above that layer). First placement used a hardcoded editor position and didn't track the table's real runtime position (table coordinates are texture-pixel space, remapped by cover-fit at runtime); fixed by adding `_sync_memory_indicator()` in `2.1_Cafeteria.gd`, called on every `layout_applied`, which re-derives the indicator's `global_position` from `TableInteractArea`'s live `CollisionShape2D.global_position` (same pattern as the existing player-spawn remap).
- Files changed:
  - `AXEL/axel_project/assets/sprites/memory_glow-Sheet.png`
  - `AXEL/axel_project/scenes/fx/MemoryIndicator.tscn`
  - `AXEL/axel_project/scenes/fx/memory_indicator.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Visual-only — a small white looping glow now appears at the Cafeteria table's memory zone, correctly tracking the table's on-screen position through cover-fit scaling. No memory-collection/pickup logic wired; existing table `[E]` → `2.2_CafeteriaMemory.tscn` transition unchanged.
- Verification: Headless scene load after texture (re)import — no errors/warnings. No local Godot binary available in this session to visually confirm the glow's exact on-screen alignment; user to eyeball via `visual_offset` in the editor if it needs a nudge.

### 2.1 Cafeteria — fix skewed [E] interact prompt over the memory table
- Request: The `[E]` interact-button indicator over the Cafeteria memory/table zone appeared skewed right and too high relative to the `TableInteractArea`'s actual center; first pass misdiagnosed this as the memory glow marker instead of the `[E]` chip.
- Implementation: Confirmed all scenes share one global `InteractPromptOverlay.screen_offset` default (`(0, -52)`, no per-scene overrides), so this was not a global bug. Added a small per-zone cosmetic-only constant, `TABLE_PROMPT_VISUAL_OFFSET := Vector2(-15, 12)`, applied inside `_interact_anchor()` only when `_active_zone == "table"` — nudges just the visible chip; the actual `TableInteractArea` collision box (player trigger zone + memory-glow anchor) is untouched, and the kitchen/return-to-locker prompts are unaffected.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: `[E]` chip over the Cafeteria table/memory zone shifts 15px left / 12px down from its previous position; no other interact prompt in the game is affected.
- Verification: Not run in-engine this session (no local Godot binary); user to confirm in-game and report if `TABLE_PROMPT_VISUAL_OFFSET` needs further tuning.

## 2026-07-30

### 2.3 Kitchen — spawn from Player node position
- Request: Make the Kitchen's player spawn point always match wherever the `Player` node is placed, instead of a hardcoded constant (same pattern already used in 2.1 Cafeteria).
- Implementation: Removed `PLAYER_SPAWN_TEX`. Scene now captures `PlayerLayer/Player.position` in `_ready()` (texture-pixel space, same as colliders) into `_player_spawn_tex`, and applies it via `env.to_global()` on the first `layout_applied`, exactly mirroring the Cafeteria fix.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Drag `PlayerLayer/Player` in the editor to choose the Kitchen spawn point; it is remapped through the cover-fit background scaling at runtime like the colliders, so the spawn always lines up with the node's editor position.
- Verification: Not run (no local Godot binary in this session); logic mirrors the already-verified 2.1 Cafeteria spawn fix.

### Scene Building — codify "spawn from own editor position" as a mandatory rule
- Request: Make sure new scenes follow the pattern above (player spawn point always matches wherever the node sits in the editor); also fix the 2.1 Cafeteria memory indicator, which was snapping onto `TableInteractArea`'s shape every frame instead of following its own editor position.
- Implementation: Added a "Rule: any node placed against the background must spawn from its own editor position" section to `SCENE_BUILDING.md` (capture `position` pre-layout → `env.to_global()` on `layout_applied`; never hardcode, never re-derive from a different node). Fixed `2.1_Cafeteria.gd`'s `_sync_memory_indicator()` to capture `_memory_indicator_tex` from `MemoryIndicator`'s own `position` in `_ready()` and remap that instead of copying `TableInteractArea`'s live shape position. Updated the memory-indicator notes in `AI_DOCS.md` and `AXEL_SCENES_ARC2.md` to match.
- Files changed:
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Dragging `PlayerLayer/MemoryIndicator` in the Cafeteria editor now actually moves where the glow renders in-game; previously any edit to that node's position was silently discarded at runtime. New scenes following `SCENE_BUILDING.md` will use the same spawn-from-own-position pattern for the player and any similar background-anchored markers.
- Verification: Not run (no local Godot binary in this session); logic mirrors the already-verified Player spawn pattern.

### Cafeteria doors + Arc 3/4/5 walkable shells
- Request: Activate the dead Backyard and Classrooms doors in `2.1_Cafeteria` and give them destinations — a new `2.4_ClassroomsCorridor` plus walkable shells for Backyard, Teachers' Lounge, and Classroom (structure/doors/enter-line only; mini-games deferred).
- Implementation: Wired InteractArea + DoorBlock pairs on the cafeteria's right and bottom placeholder doors with kitchen-style doorway peeks. Replaced Arc 3/4/5 ScenePlaceholder stubs in place with flat-placeholder walkable shells (Kitchen player profile, art-derived camera pipeline). Built L-shaped `2.4_ClassroomsCorridor` with `MOVABLE_FOLLOW` camera, doors to Cafeteria/Lounge/Classroom, and a drawn-only future-1.2 door. Added GameManager spawn-side flags and once-ever enter-line keys. Back doors always return to the fixed neighbour. `1.2_Corridor` untouched.
- Files changed:
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn` (new)
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd` (new)
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd` (new)
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.gd` (new)
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd` (new)
  - `AXEL/axel_project/exports/Drawings/3.1_Backyard.png` (flat placeholder)
  - `AXEL/axel_project/exports/Drawings/2.4_ClassroomsCorridor.png` (flat placeholder)
  - `AXEL/axel_project/exports/Drawings/4.1_TeachersLounge.png` (flat placeholder)
  - `AXEL/axel_project/exports/Drawings/5.1_Classroom.png` (flat placeholder)
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC4.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: From the Cafeteria the player can walk to Backyard (right door) and the Classrooms corridor (bottom door), then into Teachers' Lounge / Classroom. Enter lines play once. Mini-game content (cigarette memory, key pickup, desk/board puzzle) is still deferred — these are shells only, not arc-complete.
- Verification: Not run (no local Godot binary in this session); follow the manual test checklist in the plan.

### Interact-prompt "[E]" chip offset — off by default going forward
- Request: In `2.1_Cafeteria`, the shared upward chip nudge doesn't make sense for vertically-placed door interact areas; `ReturnInteractArea`, `BackyardInteractArea`, `KitchenInteractArea`, and the table/memory zone should show the "[E]" chip with no offset at all. Make "no offset by default, opt-in only" a rule for future scenes.
- Implementation: `InteractPromptOverlay.gd`'s `screen_offset` export default changed from `Vector2(0, -52)` to `Vector2.ZERO` (was silently applied to every interact chip in every scene since no `.tscn` overrode it). To preserve current on-screen behavior everywhere except Cafeteria, added an explicit `screen_offset = Vector2(0, -52)` override on the `InteractPromptOverlay` node in every other walkable scene's `.tscn` (`1.1_SchoolExterior`, `1.2_Corridor`, `1.4_BasementDoor`, `2.3_Kitchen`, `2.4_ClassroomsCorridor`, `3.1_Backyard`, `4.1_TeachersLounge`, `5.1_Classroom`). `2.1_Cafeteria.tscn` gets no override, so all five of its interact zones (table/memory, kitchen, return, backyard, classrooms) now use the new zero default. Also removed `2.1_Cafeteria.gd`'s `TABLE_PROMPT_VISUAL_OFFSET` world-space nudge on the table/memory anchor, per the same "memory zone should have no offset" request. Documented the rule in `SCENE_BUILDING.md` (new "chip has no offset by default" section) so future scenes/agents don't reintroduce a blanket offset.
- Files changed:
  - `AXEL/axel_project/scenes/ui/InteractPromptOverlay.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: In `2.1_Cafeteria`, the "[E]" chip for the table/memory, kitchen, return, backyard, and classrooms doors now centers exactly on each interact area's collision shape instead of floating 52px above it. Every other scene's chip position is unchanged (explicit override matches the old default).
- Verification: Not run (no local Godot binary in this session); visual check recommended in-editor for `2.1_Cafeteria`'s five interact zones.

## 2026-08-03

### 2.4 Classrooms Corridor — white bg, L stretch, future-door stub
- Request: Make `2.4` background white; stretch the L-corridor much longer (not wider), then widen the whole corridor ~1.5× and cut the second leg length in half; wire the future/1.2 stub door; stop lounge/cafeteria interact areas from scaling with the stretch.
- Implementation: Replaced the flat corridor placeholder art with a white texture (gitignored under `exports/Drawings/`). Rescaled `2.4_ClassroomsCorridor.tscn` geometry (walls, fills, doors, spawns) for a long L layout with follow-up width/leg tweaks. Added `FutureDoorInteractArea` + once line `"Not yet."` (no scene change). Lounge/cafeteria interact shapes use dedicated sizes (not shared stretch sync). Small cafeteria door/interact collider nudges for the new corridor link.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/exports/Drawings/2.4_ClassroomsCorridor.png` (gitignored local art)
- Behavior impact: Classrooms corridor is a large walkable L; future door only shows dialogue; cafeteria link colliders match the new sizes.
- Verification: Manual editor/play checks during the session; temporary geom helper uid added in the ship commit.
- Notes: Shipped with related 08-03 work in commit `ebed207` (2026-08-04).

### 8-band overworld noir test (not production)
- Request: Test an overworld noir filter with more bands (2 black, 2 grey, 4 red) without replacing production 3-band canon; make it easy to toggle before play.
- Implementation: Added test shader `noir_palette_8band_test.gdshader`. `AxelPostFxStack` can swap noir to 8-band via `DEBUG_USE_NOIR_8BAND_TEST` or env `AXEL_NOIR_8BAND=1`. Registered a `noir_8band_test` row in the visual-style variant matrix. Production overlay scene stays on 3-band unless the debug flag/env is on.
- Files changed:
  - `AXEL/axel_project/tools/visual_style/shaders/noir_palette_8band_test.gdshader`
  - `AXEL/axel_project/scripts/autoload/axel_post_fx_stack.gd`
  - `AXEL/axel_project/tools/visual_style/variant_matrix.gd`
- Behavior impact: Overworld can preview 8-band noir for playtests; 3-band remains production canon until explicitly promoted.
- Verification: Manual F5/F6 overworld preview during the session.
- Notes: At ship time `DEBUG_USE_NOIR_8BAND_TEST` was left `true` for ongoing playtest — flip to `false` (or unset env) for production 3-band. Shipped in `ebed207`.

### Stop automatic changelog appends (end-of-day only)
- Request: Stop agents from auto-writing the changelog; user will ask a separate agent to update docs at end of day.
- Implementation: Removed the AI_DOCS line that told agents to optionally append the changelog on `update docs`. Git commits remain the primary history; this changelog is updated only when asked.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: Agents no longer treat changelog append as a routine wrap-up step unless the user asks.
- Verification: Doc text check only.
- Notes: Shipped in `ebed207`.

### 1.1 / 1.2 player scale baseline + cover void / intro walk
- Request: Fix Mike rendering too small vs background after viewport edits; never show red void at edges (zoom/cover instead); retire road `locked_feet_y` for the intro; shorten intro wait to 1s; camera tilt then horizontal walk-in (no diagonal); cut move speed ~33%.
- Implementation: Extended `PlayerCoverSync` with `authored_bg_baseline` / position so 1.1 and 1.2 remap from pre-migration hand-tuned background scale. Camera limits use `Layout.compute_global_world_rect` so scene-root offsets cannot open post-FX void. Added `follow_enabled` + `place_center_clamped` for intro: camera starts lifted, waits `INTRO_START_WAIT_SEC` (1s), then follows; Mike spawns fully off-screen left and walks horizontally on a fixed road Y. Removed intro glitch-burst wait and old diagonal walk helpers. Tuned 1.1 player speed `180→120`, collider tweaks, playtest overrides; 1.2 player/locker interact positions + baseline. Set `window/stretch/mode="disabled"` explicitly in `project.godot`.
- Files changed:
  - `AXEL/axel_project/scenes/core/player_cover_sync.gd`
  - `AXEL/axel_project/scenes/core/background_layout.gd`
  - `AXEL/axel_project/scenes/core/background_camera_controller.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior_Playtest.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/project.godot`
- Behavior impact: 1.1 intro is a short wait → tilt-down → straight walk to the stones; player size tracks cover-fit; edges stay filled by art instead of red void; 1.2 scale stays correct on resize.
- Verification: Iterative manual play of 1.1 intro during the session.
- Notes: Shipped in `ebed207`.

## 2026-08-04

### AI_DOCS Q&A log + first rulebook rewrite (S0–S7)
- Request: Interactive point-by-point check of `AI_DOCS.md` against the live game (game wins on conflict); start rewriting canon docs from those verdicts.
- Implementation: Created `AI_DOCS_QA_LOG.md` and recorded verdicts through section S7. Rewrote much of `AI_DOCS.md` toward a lean rulebook (scope, hierarchy, architecture, combat naming notes, style/FX layer order, lore, workflow). Game/runtime scene work from 2026-08-03 was committed in the same ship.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS_QA_LOG.md` (new)
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - (same commit also includes 2026-08-03 scene/VFX files — see that day section)
- Behavior impact: Agents start from the rewritten AI_DOCS foundation; full cascade to linked docs/runtime finished on 2026-08-06.
- Verification: Doc review in-session; no full headless suite required for docs-only portion.
- Notes: Commit `ebed207`. S8 Q&A + GameManager/UI/combat cascade completed under 2026-08-06.

---

## 2026-08-06

### AI_DOCS interactive canon overhaul — cascade complete
- Request: Finish the AI_DOCS point-by-point overhaul against live game; cascade linked docs/rules and runtime cleanup (game wins when docs disagree).
- Implementation: Extended `AI_DOCS_QA_LOG.md` with S8 (+ rulebook-not-catalog principle). Finished AI_DOCS as a rulebook (not a shipped-scene catalog). Cascaded governance rule, `SCENE_BUILDING.md`, `README_STRUCTURE.md`, event-FX layer order, combat design/notes terminology (Trinity → Free Spins; alcohol not booze in docs/UI). Stripped HTML/JSON narrative UI from `GameManager.gd`. Deleted `PLAYTEST_DEBUG_COLLISIONS.md`. Swapped dialogue/prompt canvas layers so dialogue draws above `[E]`; renamed SUPER Free Spins UI copy to Free Spins.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_DOCS_QA_LOG.md` (extended; created 2026-08-04)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
  - `AXEL/axel_project/plans/core/PLAYTEST_DEBUG_COLLISIONS.md` (deleted)
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/references/README_STRUCTURE.md`
  - `AXEL/axel_project/plans/references/AXEL_OVERWORLD_EVENT_FX.md`
  - `AXEL/axel_project/plans/references/AXEL_notes.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_design.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd` / `.tscn`
  - `AXEL/axel_project/scenes/ui/InteractPromptOverlay.gd` / `.tscn`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/combat_test_scaffold_baseline.tscn`
  - `AXEL/axel_project/combat/data/symbols/sym_booze.tres`
- Behavior impact: Agents treat AI_DOCS as foundation rulebook; live scenes define what exists. Dialogue draws above interact prompt. GameManager is overworld-state only. Combat UI says Free Spins.
- Verification: GameManager overworld smoke reported OK by implement subagent; full playtest not re-run after layer swap.
- Notes: Internal combat symbol id may still be `booze` while user-facing/docs prefer alcohol. Further SUPER→Free Spins string cleanup may remain in older combat plans/tests.

### SCENE_BUILDING — post-FX white/black authoring colors
- Request: Document that new-scene clear/empty fill must be white (not black — filter turns black red); placeholders/polygons/shapes and all outlines must be black (filter turns them red).
- Implementation: Added “Rule: post-FX colors — white ground, black shapes/outlines” to `SCENE_BUILDING.md` and mirrored it in the background-swap checklist. Pointed `AI_DOCS.md` new-PNG / scene-building bullets at the same rule.
- Files changed:
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: None at runtime; agents/builders author colors against the noir remap.
- Verification: Docs-only.

### 3.1 Backyard — background PNG to white
- Request: Change 3.1 texture to the same white as the previous scene (2.4).
- Implementation: Replaced solid dark `(18,8,8)` `3.1_Backyard.png` with solid white `(255,255,255)` at the same `2800×2000` size so noir post-FX does not read the ground as red.
- Files changed:
  - `AXEL/axel_project/exports/Drawings/3.1_Backyard.png`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Backyard empty fill matches 2.4 white authoring; under noir it reads as dark void instead of red.
- Verification: PNG pixel check (solid white); Godot reimport may be needed in editor.

---

## 2026-08-09

### 1.1 School Exterior — stop sudden intro camera race
- Request: Intro camera starts at a good speed, then suddenly accelerates into a very fast tilt until Mike enters view; remove that spike.
- Implementation: Keep camera follow off during the intro tilt. After the 1s wait, run a controlled smoothstep tilt (`INTRO_CAMERA_TILT_DURATION_SEC` 3.4s) onto the stones stand point with position smoothing temporarily disabled; only then walk Mike in horizontally and re-enable follow. Previously enabling follow while Mike was still off-screen left raced the camera toward him.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
- Behavior impact: Intro tilt stays even; no sudden pan/tilt spike before the walk-in.
- Verification: Manual play of 1.1 intro during the session.

### 1.3 Locker Hub — separate school map scene + X above CRT
- Request: Red hub `X` washed out by post-FX; remove “YOUR LOCKER”; hide travel choices until the map is opened; open a separate empty map scene (no map art yet) with the travel buttons.
- Implementation: Stripped hub chrome (location label + choices). Hub `MapHotspot` now `change_scene_to_file` → new `1.3_SchoolMap.tscn` (flat black placeholder, four destinations + locked red basement, red `X` back to hub). Hub and map red `X` live on CanvasLayer 110 so CRT/noir do not cover them. First-visit dialogue + `scene_3` memory gate kept. Smoke list includes the new map scene. `AXEL_SCENES_ARC1.md` §1.3 updated to match.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.3_LockerHub.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.3_LockerHub.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.3_SchoolMap.gd` (new)
  - `AXEL/axel_project/scenes/Arc_1/1.3_SchoolMap.tscn` (new)
  - `AXEL/axel_project/tools/scene_smoke_check.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: Locker hub is locker-view only; fast travel is only on the school map scene; exit buttons stay above CRT.
- Verification: Headless `scene_smoke_check.gd` reported OK (8 scenes) in the implement session.

### 1.2 Corridor — “This was your locker.” once-ever on start
- Request: Corridor locker line must only play once, even if the player leaves mid-line or enters the locker hub and returns.
- Implementation: Call `GameManager.set_corridor_locker_line_seen(true)` as soon as the locker zone starts the line (no longer wait for line finish + still-in-zone). Leaving early can no longer re-trigger it in the same save/session (debug builds still reset flags each editor run by design).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
- Behavior impact: Locker once-ever line cannot replay after a mid-line exit.
- Verification: Logic review in-session; editor debug reset behavior unchanged.

### TopDialogueOverlay — 2/3-width banner playtest (easy rollback)
- Request: Try a shorter dialogue banner (~2/3 current width) for playtest only, with a clear rollback.
- Implementation: Added `@export_range bar_width_fraction` (default `2.0/3.0`) and `BAR_WIDTH_FRACTION_FULL := 1.0`. `_lock_bottom_layout()` centers the bar using that fraction of the old nearly-full width. Scene offsets updated to match the narrower default. Rollback: set **Bar Width Fraction** to `1.0` in the Inspector (or ask to revert files).
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: All dialogue bars are narrower and centered until rolled back or promoted.
- Verification: Not run headlessly; visual playtest left to user.
- Notes: Temporary playtest — not locked production canon until confirmed.

## 2026-08-10

### Unlink 2.4 Classroom/Lounge door collision shapes
- Request: `Classroom_CollisionShape2D` and `Lounge_CollisionShape2D` were scaling together; stop that and prevent recurrence.
- Implementation: Gave every door/interact collider in `2.4_ClassroomsCorridor.tscn` its own `RectangleShape2D` SubResource (no shared `door_h` / `door_v` / `interact_v`). Nested lounge/classroom door shapes under `LoungeDoorBlock` / `ClassroomDoorBlock` `StaticBody2D` parents (they were orphaned under `EnvironmentColliders`). Documented “Make Unique / one SubResource per independently tuned CollisionShape2D” in `SCENE_BUILDING.md`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Resizing lounge or classroom door colliders in the editor no longer changes sibling door/interact shapes; lounge/classroom door blocks now collide as real `StaticBody2D`s.
- Verification: Scene file inspection — each door/interact `CollisionShape2D` references a distinct SubResource.

### Scene colors — white ground / black outlines (4.1 fix)
- Request: Canon must say every new scene uses a white background PNG and black placeholder outlines; `4.1_TeachersLounge` had a black flat texture (wrong under VFX).
- Implementation: Strengthened the mandatory white-bg / black-outline rule in `SCENE_BUILDING.md` and `AI_DOCS.md`. Regenerated `4.1_TeachersLounge.png` as pure white. Set lounge `WallOutline` / door / couch placeholder colors to black.
- Files changed:
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/exports/Drawings/4.1_TeachersLounge.png`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Teachers' Lounge ground should read as the intended dark void under VFX (not a red field); placeholders outline/fill as black→red.
- Verification: PNG pixel check — full white `(255,255,255)`; scene placeholder colors set to `Color(0,0,0,…)`.
- Notes: `5.1_Classroom.png` is still the same near-black flat fill if you want that fixed next.

### Explore/Plan artifact handoff — never edit template files
- Request: When pasting an exploration artifact into a new chat with `@PREMIUM_Artifact`, never insert the artifact into that file; Explore replies should be only the artifact block for easy copy-paste.
- Implementation: Clarified both template files and `AI_DOCS.md` chat-workflow table: Explore final reply = artifact only; Plan uses pasted chat artifact + `@PREMIUM_Artifact` as instructions; templates are never storage for artifacts.
- Files changed:
  - `AXEL/axel_project/plans/PRE-PLAN_Artifact`
  - `AXEL/axel_project/plans/PREMIUM_Artifact`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: Agent workflow only — no runtime change.
- Verification: Doc/template review in-session.

### TopDialogueOverlay — playtest banner retune (wider + slight lift)
- Request: After the first 2/3-width banner test, try a middle width and a smaller bottom lift.
- Implementation: Default `bar_width_fraction` is now `BAR_WIDTH_FRACTION_PLAYTEST` (~0.88 = midpoint of full vs 2/3, then +5%). Added `@export bottom_gap_viewport_fraction` (default `0.03`; `0` uses fixed `bottom_gap_px`). Scene offsets updated to match. Rollback still `bar_width_fraction = 1.0` and gap fraction `0` / `12px`.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: Dialogue bar is wider than the first 2/3 playtest and sits slightly above the bottom edge.
- Verification: Visual playtest left to user.
- Notes: Still temporary playtest — not locked production canon until confirmed.

### TopDialogueOverlay — per-char scramble + `|beat:N|` pauses
- Request: Implement exploration/plan for cryptic per-letter flash (default ON) and opt-in mid-line `|beat:<seconds>|` pauses; first consumer on 1.2 corridor spawn line.
- Implementation: Extended `_run_typewriter` with segment parser (markers never shown), `fx_char_scramble` (~40% of letters/digits, 30–50 ms flash), beat pauses (advance ends pause only), display-length line-swap glitch, default CPS `35` (offset scramble delay), and auto-advance clock starting after the line is fully shown. Wired `|beat:1.5|` into 1.2 spawn line (space after marker preserved). FxPreview key **7** toggles char scramble. Documented in `AI_DOCS.md` / `SCENE_BUILDING.md`.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlayFxPreview.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
- Behavior impact: All dialogue can flash cryptic glyphs while typing; only lines with `|beat:N|` pause mid-line (1.2 spawn is the first). Skip still jumps to the clean full line.
- Verification: Logic review + string spacing fix in-session; playtest left to user.
- Notes: Other scene dialogue strings unchanged (no beats until authored).

## 2026-08-17

### Promote 8-band inverted noir to production canon
- Request: Confirm the playtested multi-color (8-band) VFX noir as the new canon palette; update AI_DOCS, the governance rule, and any other plans/docs that still called 3-band production.
- Implementation: Rewrote palette canon to 8-band inverted noir (4 red / 2 warm grey / 2 black). Marked old 3-band as retired. Left runtime wiring as-is (`DEBUG_USE_NOIR_8BAND_TEST` already true).
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_design.md`
  - `AXEL/axel_project/plans/references/AXEL_OVERWORLD_EVENT_FX.md`
  - `AXEL/axel_project/tools/visual_style/README_gd_scripts.md`
  - `AXEL/axel_project/plans/core/AI_DOCS_QA_LOG.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only — overworld already ran 8-band when the debug flag was on. Agents must now document and ship against 8-band, not 3-band.
- Verification: Searched plans/docs for leftover “3-band production / 8-band test-only” wording.
- Notes: Shader path and flag names still say `test`; that is leftover wiring, not a canon status. Combat stays excluded from the post-FX stack (black/red placeholder art).

### 3.1 Backyard + 5.1 Classroom — wire hand-drawn backgrounds
- Request: Use the new drawings in `exports/Drawings` as the 3.1 and 5.1 scene backgrounds; remove placeholder graphics; leave collision borders for manual placement. Check that `3.1_Backyard_v2` (already red/black) uses the correct production red.
- Implementation: Copied `5.1_Classroom_v2.png` over canonical `5.1_Classroom.png` (already white fill + black ink). Converted `3.1_Backyard_v2.png` from red-on-black (artist used `#FF0000`, 25 above canon red1 `#E60000` / `0.90`) to white fill + black ink so 8-band noir shows the production reds instead of double-inverting a pre-colored plate. Both scenes already pointed at the canonical PNG paths; removed visual-only `Placeholders` (`Line2D`/`Polygon2D`); resized the 4 outer walls to the new `3508×2480` texture bounds. Door/interact colliders and player spawn were left in place for the user to move.
- Files changed:
  - `AXEL/axel_project/exports/Drawings/3.1_Backyard.png`
  - `AXEL/axel_project/exports/Drawings/5.1_Classroom.png`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 3.1 and 5.1 show the new drawings; under post-FX the backyard reads as red-on-black with canon reds. Placeholder shapes are gone. Outer walls match the new art size; inner collisions still need a manual pass.
- Verification: PNG color check (3.1 converted to white/black; 5.1 already authoring-correct). Headless import + scene smoke after reimport.
- Notes: Artist originals `3.1_Backyard_v2.png` and `5.1_Classroom_v2.png` were left in `exports/Drawings/`.

### 2.2 Cafeteria Memory — wire hand-drawn background
- Request: Scene 2.2 now has its drawn version; include it as the scene background like 3.1/5.1.
- Implementation: Replaced the `ScenePlaceholder` stub with a still-image memory scene (`2.2_Cafeteria_Memory.png` + locked background + `BackgroundCamera` cover/static). Converted the art from red-on-black to white fill + black ink so 8-band noir shows production reds. Plays canon memory lines once, then E returns to the cafeteria table. No player or placeholder graphics (POV table drawing is not a walkable room).
- Files changed:
  - `AXEL/axel_project/exports/Drawings/2.2_Cafeteria_Memory.png`
  - `AXEL/axel_project/scenes/Arc_2/2.2_CafeteriaMemory.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.2_CafeteriaMemory.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Table `[E]` in 2.1 now opens the drawn memory instead of a black text placeholder. Dialogue plays once; E returns you to the table. Under post-FX the art reads as red-on-black.
- Verification: Headless import + load of `2.2_CafeteriaMemory.tscn`.
- Notes: No collision borders to move — this scene has no player.

### 2.1 Cafeteria — player 5% larger
- Request: Increase the player model size in scene 2.1 by 5%.
- Implementation: Raised authored `PlayerLayer/Player` scale from `2.25` to `2.3625` (`2.25 × 1.05`). Speed left at `189.75`. `PlayerCoverSync` still uses the scene scale as the first-layout reference.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike appears 5% larger in the cafeteria. Collision grows with the node. Walk speed is unchanged.
- Verification: Scene file scale check.
- Notes: Visual-only size tweak; no spawn or collider retune.

### 2.1 Cafeteria — player scale 2.5
- Request: Make the player scale 2.5 in scene 2.1.
- Implementation: Set authored `PlayerLayer/Player` scale from `2.3625` to `2.5`. Speed left at `189.75`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike is a bit larger than the 5% bump. Walk speed is unchanged.
- Verification: Scene file scale check.
- Notes: Follow-up to the 5% increase in the same session.

### 2.1 Cafeteria — player scale 3.0
- Request: Bump the player scale in scene 2.1 to 3.
- Implementation: Set authored `PlayerLayer/Player` scale from `2.5` to `3`. Speed left at `189.75`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike is larger again in the cafeteria. Walk speed is unchanged.
- Verification: Scene file scale check.
- Notes: Follow-up size tweak in the same session.

### 2.2 Cafeteria Memory — AXEL lines bright red
- Request: Cafeteria memory 2.2 other-speaker texts (`AXEL:`) should type in bright red instead of white.
- Implementation: Restored canon `AXEL:` prefixes on those memory lines. `TopDialogueOverlay` now colors any ALL-CAPS speaker-tag line (`AXEL: ...`) bright red; player/narration stays white.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.2_CafeteriaMemory.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: In 2.2, Axel's three lines are red; "You answer / energy / Sorry" stay white. Future `NAME:` lines anywhere will use the same red.
- Verification: Logic review of speaker-tag detect + color apply/reset on show/hide.
- Notes: Dialogue sits above noir, so authored `#FF0000` shows as bright red.

### 2.2 Cafeteria Memory — match ARC2 canon quotes
- Request: Check that the 2.2 scene script matches current `AXEL_SCENES_ARC2.md` dialogue.
- Implementation: Added the missing wrapping quotes on the two player lines (`"I just - don't have the energy..."` and `"Sorry."`). AXEL lines and `[beat]` splits were already correct. 2.1 / 2.3 lines already matched.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.2_CafeteriaMemory.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Those two player lines now show with quotes, matching locked canon.
- Verification: Line-by-line compare of Arc 2 scripts vs `AXEL_SCENES_ARC2.md`.

### 2.2 Cafeteria Memory — 1.85:1 frame above dialogue
- Request: Crop 2.2 from the top to 1.85:1 with black around the still (taller top/bottom, thinner sides). Do not move or scale the dialogue bar. Follow-ups in the same chat: shrink 25% and center; drop overlay bars that showed red edges; raise the still; then fill the play area marked by arrows (some black on all sides, still above the bar).
- Implementation: Added scene-local `2.2_cafeteria_memory_frame.gd`. Runtime top-crop via Sprite `region_rect` to 1.85:1 (bottom of the drawing stays). Camera `CONTAIN` + `max_auto_zoom=1`. Final fit fills a content box above the dialogue bar (side ~2.5%, top ~4.5%, small gap above the bar). Overlay ColorRect letterbox was tried then removed (post-FX turned the bar edges red). World-space white `VoidFill` (hidden in the editor) keeps empty areas dark under 8-band noir. Dropped the 75% shrink after playtest. Removed invalid `region_filter_clip` (not on Sprite2D in Godot 4.7) so the scene starts.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.2_cafeteria_memory_frame.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.2_CafeteriaMemory.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 2.2 shows a widescreen slice of the drawing, large, with a little black around it and the hand above the dialogue bar.
- Verification: Playtest screenshots in session; crash fix confirmed by reload.
- Notes: 2.2-only framing. PNG on disk unchanged. Shared camera helpers unchanged.

### 2.2 Cafeteria Memory — hide AXEL: tags (`|other|`)
- Request: Remove on-screen `AXEL:` from 2.2 lines; color is enough to mark other speakers.
- Implementation: 2.2 `MEMORY_LINES` use `|other|` instead of `AXEL:`. `TopDialogueOverlay` strips `|other|` from display (same parser as `|beat:N|`) and still types those lines bright red. ALL-CAPS `NAME:` tags still work.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.2_CafeteriaMemory.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Axel’s three 2.2 lines are red with no speaker name. Player/narration stays white.
- Verification: Logic review of marker strip + other-speaker color.
- Notes: Follow-up to the same-day “AXEL lines bright red” entry. Use `|other|` when the name should not appear.

### 2.2 Cafeteria Memory — exit [X], return spot, collection
- Request: Scene 2.2 had no red `[X]`, keyboard leave felt stuck, return snapped to the table-zone center, and the 2.1 glow/`[E]` stayed after the memory.
- Implementation: Copied locker-hub `ExitLayer`/`ExitButton` (CanvasLayer 110, VT323 red `X`) onto 2.2. Leave (X and E/Space/Enter) waits for `_can_exit` after `show_lines` finishes. 2.1 saves the exact standing spot in texture-pixel space (`cafeteria_table_return_pos`) and restores it on return. First successful leave calls `add_memory_once("cafeteria_memory")`; 2.1 then hides `MemoryIndicator` and disables `TableInteractArea`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.2_CafeteriaMemory.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.2_CafeteriaMemory.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/tools/scene_smoke_check.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: After the memory lines finish, `[X]` and E return to 2.1 at the same table standing spot. Glow and table `[E]` are gone for the rest of that run. Counts toward 5/5 memories.
- Verification: Headless scene smoke including 2.2.
- Notes: Debug builds skip save load, so the glow returns each editor run. 2.2 art/crop/`MEMORY_LINES` unchanged.

## 2026-08-18

### 3.1 Backyard — DoorSideRight and DoorBottom colliders
- Request: Add 3 collision borders for the 3.1 building front and side, placed in order next to `DoorSideLeft`, named `DoorSideRight` and `DoorBottom`.
- Implementation: Renamed leftover `DoorWall` to `DoorSideLeft`. Inserted sibling `DoorSideRight` (vertical) and `DoorBottom` (horizontal) immediately after it, each with its own `RectangleShape2D` so resizing one does not change the others. Starter positions sit next to the old door block for editor dragging.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Three solid building blockers exist in 3.1. They still need a manual drag onto the drawn walls; `[E]` door interact is unchanged.
- Verification: Scene file node order check (`DoorSideLeft`, `DoorSideRight`, `DoorBottom`, then `DoorInteractArea`).
- Notes: User named two new nodes. The third border is the renamed `DoorSideLeft`. Ask if a fourth named collider is needed.

### Rollback editor dialogue bar + 2D camera fit
- Request: Roll back the editor overlay/fit work; the fixes were not working and reload crashed Godot.
- Implementation: Restored `TopDialogueOverlay.gd` and `project.godot`. Removed the editor-fit addon, preview helper, and QA check.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd` (restored)
  - `AXEL/axel_project/project.godot` (restored)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Editor 2D tab is back to the previous state (dialogue bar at origin). Play-time dialogue is unchanged.
- Verification: Restored overlay script has no `@tool` / editor preview path; plugin enable line is gone.
- Notes: Close Godot if it is still open from a crash, then open the project again.

### 3.1 Backyard — Wall_Behind fade zone
- Request: Add a behind filter to scene 3.1 named `Wall_Behind` for editor configuration.
- Implementation: Added `Wall_Behind` `Area2D` (`leaf_occlusion_zone.gd`) under `EnvironmentColliders` with a starter polygon and `feather_px = 12`. `3.1_Backyard.gd` sends that polygon to `Player.configure_leaf_occlusion_polygons` after background layout, same fade as 2.1 table/chair behind zones.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike fades when standing inside the `Wall_Behind` polygon. Drag the polygon vertices in the editor to match the wall; `feather_px` softens the edge.
- Verification: Scene node `Wall_Behind` present; script wires the zone after layout.
- Notes: Starter box is near the top wall so the green editor preview is visible. Reshape before treating the fade as final.

### 3.1 Backyard — keep Wall_Behind fade above TopWall
- Request: In 3.1 only, the behind filter should still work when the player model is above the `TopWall` collision border.
- Implementation: 3.1 now fades from feet position inside `Wall_Behind` and skips the trunk Y-gate (`leaf_mask_use_anchor_y`). Head/body pixels that stick above `TopWall` stay faded. 1.1 / 2.1 still use per-pixel Y-gate fade.
- Files changed:
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Standing in `Wall_Behind` fades all of Mike, even if his sprite crosses above `TopWall`. Other scenes unchanged.
- Verification: Shader default `leaf_mask_use_anchor_y = 0`; only 3.1 passes `true`.
- Notes: If fade still cuts off after feet leave the polygon, extend `Wall_Behind` in the editor.

### 3.1 Backyard — Bush_Behind and Well_Behind fade zones
- Request: Add two more behind filters for bush and well.
- Implementation: Added `Bush_Behind` and `Well_Behind` `Area2D` zones next to `Wall_Behind`. `_configure_behind_occlusion_masks` fills the three shader polygon slots (wall, bush, well). Same feet-in-zone fade as the wall; starter boxes sit in the lower yard for editor dragging.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike also fades inside the bush and well polygons. Drag those shapes onto the drawing; `feather_px` still starts at `12`.
- Verification: Scene nodes `Bush_Behind` and `Well_Behind` present; script maps them to shader slots 1 and 2.
- Notes: Wall polygon/scale left as already tuned. Bush/well starters are separate so they do not sit on the wall box.

### All behind filters — feather 2 px
- Request: Make every behind filter in all scenes use a feather of 2 px.
- Implementation: Set `feather_px = 2.0` on all `*_Behind` zones (1.1 trees, 2.1 table/chairs, 3.1 wall/bush/well). Default on `leaf_occlusion_zone.gd` and `white_sprite.gdshader` is now `2.0` so new zones match.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/fx/leaf_occlusion_zone.gd`
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Behind fade edges are a tight 2 px blend in every walkable scene that has these zones.
- Verification: Grep shows all `feather_px` values on behind nodes are `2.0`.
- Notes: Replaces older per-scene feathers (1.1 was 4, 2.1 table 12 / chairs 0, 3.1 wall/bush 12).

### 3.1 Bush_Behind — match drawn polygon
- Request: Bush behind filter was activating far from the actual polygon.
- Implementation: Bush/well now fade per pixel against the real polygon (no feet-Y stretch). Raised shader polygon cap from 32 to 64 so the bush's extra vertices are not dropped. Wall still uses feet-Y so fade can cross `TopWall`.
- Files changed:
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/scenes/fx/leaf_occlusion_zone.gd`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Standing next to the bush should fade only where the green polygon is, not a vertical slab beside it.
- Verification: Bush polygon has 45 points; cap is 64. Shader samples bush/well with `world_pos`.
- Notes: If a future behind polygon exceeds 64 points, extra verts are still ignored.

### 3.1 / 3.2 Backyard Memory — graffiti glow, still, cigarette after
- Request: In the backyard the player should see a memory glow on the graffiti wall, press [E], watch a still-image memory (empty white picture for now) with the Axel talk, leave with X or E, then hear the cigarette lines back in the yard. After that the glow and [E] go away. No hint screen. No “remember the name.”
- Implementation: Rewrote Arc 3 canon to 3.1 walkable yard + 3.2 still (like 2.2). Added GameManager flags (`backyard_memory` via `add_memory_once`, `backyard_memory_line_seen`, `backyard_cigarette_line_seen`, transient `backyard_memory_return_pos`). New `3.2_BackyardMemory` scene copied from 2.2 (local frame script, white placeholder PNG, CanvasLayer 110 red X). 3.1 instances `MemoryIndicator` under `PlayerLayer`, adds `MemoryInteractArea` on the graffiti wall, remaps the glow, restores the standing spot, hides glow/[E] after collect, and plays the cigarette three-liner once on return. Deleted hint / click-step / “remember the name” from the Arc 3 write-up. Did not edit live 2.2 files or 3.1 behind filters.
- Files changed:
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_NEW.md`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/scenes/Arc_3/3.2_BackyardMemory.tscn` (new)
  - `AXEL/axel_project/scenes/Arc_3/3.2_BackyardMemory.gd` (new)
  - `AXEL/axel_project/scenes/Arc_3/3.2_backyard_memory_frame.gd` (new)
  - `AXEL/axel_project/exports/Drawings/3.2_Backyard_Memory.png` (new, white placeholder)
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`
  - `AXEL/axel_project/tools/scene_smoke_check.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Graffiti glow + [E] opens 3.2. After the Axel talk, X/E returns to 3.1 at the same spot, cigarette lines play once, then glow and [E] are gone. Counts toward 5/5 memories.
- Verification: Headless scene smoke including 3.2.
- Notes: Debug builds skip save load, so the glow returns each editor run. Old unused `3.2_BackyardHint.tscn` was left unwired. Glow/[E] starters may need a drag onto the real graffiti.

### 3.1 Backyard — sync memory glow and [E], no default chip offset
- Request: MemoryInteractArea and the memory glow spawn were offset. That offset should not be on by default (AI_DOCS / SCENE_BUILDING).
- Implementation: Moved `MemoryInteractArea` so its shape center matches `PlayerLayer/MemoryIndicator` at the current graffiti editor pos `(3056, 1824)`. Removed the scene-wide `InteractPromptOverlay.screen_offset = (0, -52)` so 3.1 uses the shared zero default like 2.1. Glow still remaps from its own editor position; no per-zone chip nudge.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Glow, walk-up `[E]` zone, and the `[E]` chip share the same graffiti point. Door `[E]` also has no chip offset now.
- Verification: Scene positions match; overlay has no `screen_offset` override.
- Notes: Drag both nodes together if you move the graffiti hotspot. Add a door-only chip nudge later only if asked.

### Canon — no visual offset from nodes (player, memory, [E])
- Request: By default no indicator, memory, interact button, or player model should have any offset from their nodes. The 3.1 player also looked skewed from the scene nodes.
- Implementation: Wrote the default into `AI_DOCS.md` (Style/FX + optional refs), the always-on Cursor rule, and `SCENE_BUILDING.md`. Player sprite/collision children, `MemoryIndicator.visual_offset`, and `[E]` `screen_offset` stay at zero unless asked. Cover-fit remap from a node’s own editor position is not an offset. 3.1 player children were already at `(0, 0)`; did not strip existing 2.1 sprite child offsets.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/scenes/fx/memory_indicator.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: New scenes and future edits default to no extra offset. 3.1 glow/[E] already matched; 3.1 player spawn still uses its own editor position via cover-fit.
- Verification: Doc + rule text review.
- Notes: If Mike still looks off in 3.1 at play, that is cover-fit / camera framing (`static_center`), not a child offset. Drag the Player node to move spawn.

### 3.1 Backyard — mid-line beat before “Nice graffiti”
- Request: There should be a [beat] before the “nice graffiti” line. Only a wait; do not put it on a different dialogue box or line.
- Implementation: First enter line is now `The spirit of rebellion is still present here.|beat:1.5| Nice graffiti.` (same bar, same `show_lines` entry). Second line unchanged. Arc 3 write-up matches.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: After “here.” the bar pauses ~1.5s, then types “Nice graffiti.” Advance during the wait skips the pause and continues typing. Then the second line still plays in the next box.
- Verification: Line matches 1.2’s `|beat:1.5|` pattern.
- Notes: Marker is never shown on screen.

### 3.2 Backyard Memory — drop wrapping quote marks
- Request: Check Arc 3 write-up and update the scene script to remove `""` marks.
- Implementation: 3.1 enter/cigarette lines already had no wrapping quotes. Matched `3.2_BackyardMemory.gd` to the write-up: spoken lines no longer wrap in quotes; first Axel line no longer has `, they say.`
- Files changed:
  - `AXEL/axel_project/scenes/Arc_3/3.2_BackyardMemory.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 3.2 types `Oh. Sorry. I'll go.` (and the rest) without quote marks. Axel lines stay red via `|other|`.
- Verification: Line-by-line compare vs `AXEL_SCENES_ARC3.md` §3.2.
- Notes: 3.1 script unchanged.

### Scene 1.1 — wire RightWall_Behind fade
- Request: Wire the placed `RightWall_Behind` zone in scene 1.1.
- Implementation: Added `RightWall_Behind` to 1.1’s behind-zone list as shader slot 2 (trees stay 0–1). Passes the wall polygon after cover-fit layout. Wall uses no trunk Y-gate (`1e9`) so fade follows the authored polygon. Did not enable feet-Y (`use_anchor_y`) so tree fade stays per-pixel.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike fades inside the `RightWall_Behind` polygon as well as the two tree behind zones.
- Verification: Scene node `RightWall_Behind` present under `EnvironmentColliders` with `leaf_occlusion_zone.gd`; script lists that name and fills slot 2.
- Notes: Polygon shape is the user’s editor placement. Shader still maxes out at 3 behind zones.

### Scene 1.1 — RightWall_Behind fade actually on
- Request: `RightWall_Behind` was wired but Mike would not fade.
- Implementation: The wall uses “no trunk line” (`leaf_y_cutoff_2 = 1e9`). The shader treated that as gate=off, so slot 2 never faded. Unused/no-cutoff now means gate=on; empty polygons still fade nothing.
- Files changed:
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Standing inside `RightWall_Behind` fades Mike. Tree behind zones unchanged (they still use real trunk Y-gates). 2.1 / 3.1 unchanged.
- Verification: Shader `_trunk_line_gate` returns 1.0 when cutoff `> 1e8`.
- Notes: Fade is per-pixel inside the green polygon, same as bush/well — not the 3.1 wall “feet in zone” stretch.

### Scene 2.3 — flashlight drawing + faint glow
- Request: Place `exports/Drawings/Flashlight.png` in 2.3 around the flashlight interact, with a faint glow, through the color filter; hide it after pickup.
- Implementation: Added world-space `FlashlightVisual` under `EnvironmentColliders` (cover-fit with the room, so noir remaps the black ink). Soft pulsing halo via `prop_ink_halo.gdshader` (authored black → faint red after 8-band). `_apply_flashlight_visibility()` now hides the drawing as soon as `hasFlashlight` is set.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.gd`
  - `AXEL/axel_project/scenes/fx/prop_ink_halo.gdshader`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: The flashlight drawing is visible on the interact spot until picked up, then it disappears. Glow is faint and follows the production noir look.
- Verification: Scene tree has `FlashlightVisual` at the interact-zone center; pickup path sets `hasFlashlight` then hides the node before the line plays.
- Notes: Drag `FlashlightVisual` in the editor to nudge placement. Scale is `0.2` of the cropped drawing.

### Combat item catalog — playtest picker + full effects
- Request: Ship all 75 playable catalog items (drop L-A), family C→E rank rows, Ignore-cap debug, playtest Used/Budget and Goal Base/Progress, and make every listed effect actually change combat.
- Implementation: Added one `.tres` per catalog id with icons; `ItemEffectDispatcher` walks inventory in tick order; CombatRoot setters for paid-reroll Used and encounter goal (Family H % on Base). ITEMS picker is runtime UI only (protected unique nodes untouched). C1 stays 0.06/0.36. SUPER copy renamed to Free Spins. Cascade refill stays off; G is regular-spin payout + skip-guard.
- Files changed:
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/combat/scripts/item_def.gd`
  - `AXEL/axel_project/combat/scripts/item_inventory.gd`
  - `AXEL/axel_project/combat/scripts/item_effect_dispatcher.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/line_detector.gd`
  - `AXEL/axel_project/combat/scripts/meter.gd`
  - `AXEL/axel_project/combat/scripts/princess_controller.gd`
  - `AXEL/axel_project/combat/scripts/free_spins.gd`
  - `AXEL/axel_project/combat/scripts/grid_manager.gd`
  - `AXEL/axel_project/combat/scripts/rng.gd`
  - `AXEL/axel_project/combat/data/items/`
  - `AXEL/axel_project/combat/art/item_icons/`
  - `AXEL/axel_project/combat/test/item_synergy_smoke.gd`
  - `AXEL/axel_project/tools/combat/bake_item_icons.gd`
  - `AXEL/axel_project/tools/combat/generate_item_resources.py`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: F6 combat test lists the full catalog. Tick order is activation order. Used=6 + C1 is already at cap +0.36×. Base 10000 + H Epic → Effective 12500.
- Verification: `combat_test_scaffold_check.gd`, `item_synergy_smoke.gd` (44 pass), `determinism_check.gd`, `princess_check.gd`.
- Notes: Icon baker accepts an optional source-root CLI arg; placeholders are 8-band+white 48×48 if sources are missing. L-A is not in playtest.

### 2.4 / 4.1 / 3.1 memory — wire hand-drawn backgrounds
- Request: Integrate new drawings in `exports/Drawings` for 2.4, 4.1, and 3.1 into the live scenes per `SCENE_BUILDING.md`.
- Implementation: All three plates were already white fill + black ink (no color convert). 2.4: removed placeholder `Line2D`/`Polygon2D`, resized the L-corridor colliders to `7016×4960`, placed cafeteria/lounge/classroom/future doors on the ink, classroom return peek is now above the south-wall door. 4.1: removed placeholders, outer walls to `3508×2480`, furniture colliders on cabinet/table/chair/key-bench/right clutter, door stays on the north wall; camera is art-centered. 3.1 walkable already used `3.1_Backyard.png`; wired artist file `3.1_Backyard_Memory.png` into 3.2’s still (same 1.85:1 top-crop frame as 2.2). Key pickup / 1.2 loop still not wired.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.2_BackyardMemory.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC4.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 2.4 and 4.1 show the new room drawings instead of flat placeholders; 3.2 shows the backyard memory still. Doors and movement still work; colliders may need an editor nudge against the ink.
- Verification: PNG color check (white fill, no red plate). Scene files point at the new textures; 3.2 `region_rect` matches 3508×1896 top-crop. Headless smoke not run (no Godot in this pass).
- Notes: Artist named the memory `3.1_Backyard_Memory.png` (3.1’s memory, shown in scene 3.2). Tune door/furniture boxes in the editor if a hotspot feels off.

### Docs sync — 2026-08-18 live scenes
- Request: `update docs` after today’s backyard memory, behind fades, flashlight drawing, combat catalog playtest, and new 2.4 / 4.1 / 3.2 plates.
- Implementation: Scene write-ups now match live files. 3.1 colliders and behind polygons are authored on the drawing (not “starter boxes”). Index lists 2.4. 1.1 notes `RightWall_Behind`. 2.4 / 4.1 note the shared zero `[E]` chip offset.
- Files changed:
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC4.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_NEW.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only. Gameplay unchanged.
- Verification: Compared write-ups to live `.tscn` / `.gd` (3.2 uses `3.1_Backyard_Memory.png`; 2.3 `FlashlightVisual`; catalog playtest HUD already in the catalog plan).
- Notes: Changelog already had today’s implement entries (behind fades, 3.1+3.2 memory, no-offset canon, 1.1 wall fade, flashlight, full item catalog, new plates).

## 2026-08-20

### Player / room shared cover scale
- Request: Mike looked a different size on another computer / Game-window resolution (especially 2.1). Scale player, background, and collisions the same amount on every window size and aspect — do not keep making per-computer `.tscn` scale tweaks.
- Implementation: `PlayerCoverSync` now uses a stable baseline (this PNG’s cover-fit at 1920×1280, or 1.1/1.2 `_OLD_BG_SCALE`) on the **first** layout, not the first Game-window size. Empty-viewport fallback in `BackgroundLayout` is 1920×1280 (was 1280×720). Every walkable scene calls `bind_design_from_background`; 2.1 / 3.1 memory glows use `bind_extra_node`. QA movement checks read authored scale/speed metas so live cover-sync values do not fail profiles. Locked into `AI_DOCS.md`, `SCENE_BUILDING.md`, and `.cursor/rules/axel-ai-docs-governance.mdc`. Stretch stays disabled.
- Files changed:
  - `AXEL/axel_project/scenes/core/player_cover_sync.gd`
  - `AXEL/axel_project/scenes/core/background_layout.gd`
  - `AXEL/axel_project/scenes/core/test/player_cover_sync_check.gd`
  - `AXEL/axel_project/scenes/core/test/mock_cover_player.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike, walls, and room art stay the same size relative to each other on any Game tab / monitor. Do not retune Player `.tscn` scale to “fix” another computer.
- Verification: `scenes/core/test/player_cover_sync_check.gd` (scale/cover constant across two covers, including first apply).
- Notes: 1.1 / 1.2 keep `_OLD_BG_SCALE` as baseline (legacy; do not migrate without approval).

### Upgrade Godot editor to 4.7.2
- Request: Update all references for the new Godot 4.7.2 executable already present in the repo root, then check the game still runs.
- Implementation: Pointed `tools/cmd/godot.cmd`, `tools/Godot.code-workspace`, `.vscode/settings.json`, `AXEL/.vscode/settings.json`, `README.md`, and `AGENTS.md` at `Godot_v4.7.2-stable_win64.exe` (console variant too). Removed the previous `Godot_v4.7.1-stable_*` binaries. Left `project.godot` `config/features` as `"4.7"` (maintenance release of 4.7).
- Files changed:
  - `tools/cmd/godot.cmd`
  - `tools/Godot.code-workspace`
  - `.vscode/settings.json`
  - `AXEL/.vscode/settings.json`
  - `README.md`
  - `AGENTS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: CLI wrappers and editor integration use Godot 4.7.2; no AXEL script/shader changes required (4.7.x compatible maintenance build, no known incompatibilities with 4.7.1).
- Verification: `Godot_v4.7.2-stable_win64_console.exe --version` → `4.7.2.stable.official.ed1daf0bf`; `tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd` → `Determinism check OK (100 spins, seed 12345)`. Princess, scaffold, scene smoke (10 scenes), player-cover-sync, and main-menu `--quit-after 90` also exit 0. Arc 1 exterior bot still times out on intro unlock on both 4.7.1 and 4.7.2 (pre-existing; not a 4.7.2 regression).
- Notes: Historical changelog entries still cite older console invocations where recorded at implementation time.

### Multi-scene playtest fixes
- Request: Wire 1.1 left-road Ending 1 (100× `"Coward."` → main menu) and 1.2 `[E]` back to 1.1; show 1.4 chain placeholder through noir; match 1.4 Mike to 1.2; carry walk-off Y on side exits (1.2 ↔ 1.4); strip 2.2 quotes/action lines; 2.1 enter line once only; raise 2.1 kitchen `[E]` 220px; grow 2.3 Mike 150%.
- Implementation: 1.1 left `ExitTrigger` stays open after intro → `7.1_Ending1.tscn` (`7.1_Ending1.gd` plays 100 `"Coward."` then main menu). 1.2 `ExteriorInteractArea` at spawn returns to 1.1 doors (`exterior_spawn_side="corridor_door"`, skips intro). 1.4: hide grey door-wall poly, black door body, raise `DoorVisuals`; sprite/collision children match 1.2 (scale still 3.0). `GameManager.walkoff_floor_offset_y` carries floor-relative height 1.2 ↔ 1.4; 1.4 floor line nudged to y `790`. 2.2 lines match ARC2 rewrite. `cafeteria_enter_line_seen` gates 2.1 chatter. `KitchenInteractArea` `(3000, 880)`. 2.3 authored scale `3.0` → `5.0`.
- Files changed:
  - `AXEL/axel_project/scenes/Endings/7.1_Ending1.tscn`
  - `AXEL/axel_project/scenes/Endings/7.1_Ending1.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.2_CafeteriaMemory.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC7.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Turning left after the 1.1 intro is Ending 1. 1.2 spawn `[E]` returns to the school doors. 1.4 chains read through noir; Mike matches 1.2. Walking 1.2 ↔ 1.4 keeps floor height. 2.1 chatter plays once. Kitchen hotspot is higher. Kitchen Mike is larger.
- Verification: Headless scene smoke (10 scenes, exit 0). Walk-off floor seam still needs a visual check in play (high and low on the 1.2 ↔ 1.4 edge).
- Notes: 1.4 chain art is still a placeholder. Walk-off Y is for side `ExitTrigger`s only, not `[E]` doors.

### Docs sync — 2026-08-20 live scenes
- Request: `update todays docs` after cover-scale, Godot 4.7.2, and the multi-scene playtest list.
- Implementation: Scene write-ups and canon now match live files. `AI_DOCS.md` notes first-visit enter lines and walk-off Y. `SCENE_BUILDING.md` adds those two rules. ARC1/ARC2/ARC7 Implemented notes cover Ending 1, 1.2 return, 1.4 chains + Mike match + floor Y, 2.1 kitchen zone / once-ever enter, 2.2 rewrite lines, 2.3 scale `5.0`.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC7.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only. Gameplay unchanged.
- Verification: Compared write-ups to live `.tscn` / `.gd` (7.1 `COWARD_COUNT=100`; 2.1 `KitchenInteractArea` y `880`; 2.3 Player scale `5.0`; `walkoff_floor_offset_y` on 1.2/1.4).
- Notes: Implement entries for today are the three sections above. Walk-off floor alignment still wants a playtest look.

### Scene 1.4 — Mike size matches 1.2 cover baseline
- Request: 1.4 player model was quite wrong; make it exactly the same size as 1.2 (background texture same size as 1.2).
- Implementation: Both plates were already 2400×1500. 1.4 was using 1920×1280 cover as PlayerCoverSync baseline (~0.853) while 1.2 uses `_OLD_BG_SCALE` `0.546`, so Mike looked ~56% smaller in 1.4. 1.4 now shares 1.2’s `0.546` baseline (bind_design no-ops). Background + `EnvironmentColliders` authored scale set to `0.546` like 1.2. Placeholders left as-is.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Walking 1.2 → 1.4, Mike stays the same size vs the room. Door placeholders unchanged.
- Verification: PNG sizes 2400×1500 both files; 1.4 `_OLD_BG_SCALE` equals 1.2’s `0.546`.
- Notes: Do not switch 1.4 back to 1920×1280 `bind_design` or Mike will shrink again.

### Player node is the spawn (no scene overwrite)
- Request: Player model spawn must be exactly the Player node in real time; no scene may overwrite that spawn. Fix 1.2 and 1.4. Make the rule permanent in AI_DOCS, SCENE_BUILDING, and governance.
- Implementation: Added `PlayerSpawnSync` (`env.to_local` before cover-fit, `env.to_global` after, including first layout). Removed 1.4 hardcoded `(250, 950)`. 1.2 now remaps on first layout. 1.1 skip-intro and intro walk use the Player node (not stones). All other walkable rooms use the same helper for default spawn; peek/return from another room still allowed. Zeroed Player visual child offsets; shared `mike_sprite_frames.tres` so Mike is visible on the node in the editor.
- Files changed:
  - `AXEL/axel_project/scenes/core/player_spawn_sync.gd`
  - `AXEL/axel_project/scenes/core/test/player_spawn_sync_check.gd`
  - `AXEL/axel_project/assets/sprites/mike_sprite_frames.tres`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior_Playtest.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Drag the Player node to set spawn. Play starts there (cover-fit remaps it). 1.4 no longer ignores the node. 1.2 no longer misses the first remap. 1.1 intro/skip use that node.
- Verification: Headless `player_spawn_sync_check.gd`, `player_cover_sync_check.gd`, `scene_smoke_check.gd`.
- Notes: Peek/return from another room still places at the door/edge. Walk-off Y still adjusts height after spawn.

## 2026-08-23

### Classroom 5.1 furniture, desk [E], and real 5.2

- Request: Fill classroom 5.1 with furniture blockers, one-shot desk [E], board memory glow; rebuild 5.2 as timed empty→hand→desk still-scene; return disables desk [E].
- Implementation: Added `classroom_desk_seen` + transient `classroom_desk_return_pos` on GameManager (no memory credit). Extended 5.1 with nine starter furniture polygons, DeskInteractArea, MemoryIndicator remap, zero chip offset. Rebuilt 5.2 from 2.2 still shell with local shake/dim and canon lines.
- Files changed:
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.2_ClassroomDesk.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.2_ClassroomDesk.gd`
  - `AXEL/axel_project/exports/Drawings/desk_empty.png`
  - `AXEL/axel_project/exports/Drawings/desk_hand.png`
  - `AXEL/axel_project/exports/Drawings/desk.png`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike can be blocked by classroom furniture once polygons are dragged; desk [E] plays 5.2 once then vanishes; board glow loops for later 5.3 wiring.
- Verification: Scripted file checks; drag furniture/desk/glow in editor then Play.
- Notes: 5.3/5.4 board puzzle deferred. Desk is not a 5/5 memory.

### 2.4 extra door interact stubs
- Request: Add 3 extra interact areas on the unused 2.4 doors, with dialogue "Try the next one." / "No, the next one." / "You missed it."
- Implementation: Added `ExtraDoor1/2/3InteractArea` under `EnvironmentColliders` (same `[E]` + `TopDialogueOverlay` stub pattern as the future door). Door 1 is the south-wall extra between future and classroom; door 2 is the east-wall extra between lounge and cafeteria; door 3 is the north-end extra right of the cafeteria door. No scene changes.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: The three extra doors show an `[E]` chip and the matching one-line stub. Live cafeteria / lounge / classroom doors and the future `"Not yet."` stub are unchanged.
- Verification: Scene nodes and stub line map reviewed in source.
- Notes: Drag the new Area2D nodes in the editor if a box sits off the ink.

### New Mike walk sheet (12-cell front/back/side)
- Request: Pack hand-drawn `kävely_etu` / `kävely_sivu` into a Play-ready strip with solid head plate, real front/back/side walks, left via flip, last-facing idle, same on-screen height.
- Implementation: Baked a 12-cell horizontal strip (430×968 cells) from ink-box cuts (not grid slice), filled a white head plate behind scribble/eye holes, flattened soft charcoal, and overwrote `mike_walking-Sheet.png` (legacy 13-frame backup kept). `Player.gd` now uses walk_down / walk_up / walk_right + flip_h for left, with idle / idle_back / idle_side. Authored Player scales retuned by `old × 64/968` on walkable rooms.
- Files changed:
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.py`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.gd`
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet.png`
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet_legacy13.png`
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet_meta.txt`
  - `AXEL/axel_project/assets/sprites/mike_sprite_frames.tres`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: S = front walk, W = back walk, A/D = side (left mirrored). Idle keeps last facing. Head reads as solid white after the overworld filter; empty around Mike stays transparent.
- Verification: Headless smoke / cover / spawn checks (see implement session).
- Notes: Re-bake with `python AXEL/axel_project/tools/pack_mike_walk_sheet.py` (ASCII copies `kavely_*.png` under Drawings). Rollback: restore legacy13 over the live sheet and revert Player + scales.

### 4.1 collision borders → polygons
- Request: 4.1 collision borders should be polygons because the debris is more defined.
- Implementation: Replaced lounge wall/furniture `CollisionShape2D` boxes with `CollisionPolygon2D` traced from the ink. Added `LeftUpperBlock` for the thin left strip. Floor papers stay walkable. Door `[E]` zone stays a rectangle.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC4.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike stops on the tilted table, chair, bench, cabinet, and right clutter instead of their old boxes. Papers on the floor are still walkable.
- Verification: Polygon vertices overlaid on `4.1_TeachersLounge.png`; scene file parsed for `CollisionPolygon2D` on each former box.
- Notes: Drag polygon vertex handles in the editor if one edge sits off the ink.

### 2.4 vertical walk size ramp
- Request: On the first (vertical) leg of 2.4, Mike should grow from 100% near the cafeteria to 150% at the corner so he matches the zooming perspective; keep last size after leave; lounge/classroom enter at 150%.
- Implementation: Added `VerticalSizeRampArea` (walk-through `Area2D` in texture-pixel space under `EnvironmentColliders`). 2.4 script tracks `_depth_factor` from walk Y inside the box, seeds from spawn side, and after every `PlayerCoverSync.apply()` multiplies scale + speed by that factor. Export `vertical_far_scale` (default 1.5). Shared cover-sync helper unchanged.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Walking down the vertical arm grows Mike (and walk speed); past the corner he stays large; walking back up shrinks him. Fresh/cafeteria start at 100%; lounge/classroom at 150%.
- Verification: Headless `player_cover_sync_check.gd`; manual walk of vertical leg + corner + return peeks.
- Notes: Drag `VerticalSizeRampArea` in the editor if growth starts too early/late. Grow is around the Player node (same as window resize), not feet-plant.

### Mike head hole-fill black (not white)
- Request: Empty spaces in Mike's head (eyes, scribble gaps) were solid white; they should be black so the in-game model is white with black eyes. Player is not noir-inverted.
- Implementation: Head plate fill is now black; ink flattens to white. `white_sprite.gdshader` keeps dark texels black instead of forcing every opaque pixel white. Re-baked `mike_walking-Sheet.png`.
- Files changed:
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.py`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.gd`
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet.png`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Overworld Mike is a white figure with black eyes/holes. Transparent pixels around him are unchanged.
- Verification: Re-bake counts match old white-fill pixel counts now as black; front/side head crops show black eye holes.
- Notes: Re-bake with `python AXEL/axel_project/tools/pack_mike_walk_sheet.py`. Godot may need to reimport the sheet if the editor is already open.

### Mike face keep brush gaps (less filter crush)
- Request: In-game face was a blown-out white blob vs the original charcoal PNG; decrease the filter so brushes stay defined.
- Implementation: Removed the solid head plate (it filled every gap between strokes). Pack now inverts charcoal to white and keeps source alpha. `white_sprite` no longer 1-bit thresholds the face. CRT player white-boost dropped 0.8→0.2 and player CRT reduction raised 0.33→0.7 so scan/chroma smear the head less.
- Files changed:
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.py`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.gd`
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/scenes/fx/crt_plugin_overlay.gdshader`
  - `AXEL/axel_project/scenes/fx/CrtPluginOverlay.tscn`
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet.png`
  - `AXEL/axel_project/assets/sprites/mike_sprite_frames.tres`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike’s head shows white brush strokes with dark gaps (eyes/scribble holes). Still a white figure; empty gaps stay dark because they are not filled.
- Verification: Re-baked sheet; front head crop shows stroke texture and open eye holes instead of a solid plate.
- Notes: Stop Play and Play again so Godot reimports the sheet. CRT knobs are on `CrtPluginOverlay.tscn` → `FilterRect` if you want even less glow.

### Mike solid body + black head plate
- Request: Body from the chin down was too see-through (restore the older solid look). Eye sockets / face holes showed the room; they need a head-only fill so the in-game look is white body, black eyes.
- Implementation: Detect the chin (widest head row, then neck). Black convex plate only on the head, with white brush strokes drawn on top so holes stay black and opaque. From the chin down, ink is hard opaque white again (no plate).
- Files changed:
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.py`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.gd`
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet.png`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Face keeps brush detail on a black backing (no room through the eyes). Neck/arms/legs are solid white lines.
- Verification: Re-bake; eye crop on a red test background stays black, not red.
- Notes: Stop Play and Play again so Godot reimports the sheet.

### 5.1 classroom Mike +50%
- Request: 5.1 player model size should be increased by 50%.
- Implementation: Raised authored `PlayerLayer/Player` scale from `0.198347` to `0.2975205`. Speed left at `253.4`. Shared cover-sync / other rooms unchanged.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike is 50% larger in the classroom only.
- Verification: Scene file scale confirmed.
- Notes: Tune further in the `.tscn` if the room still looks off at 1920×1280.

### Docs sync — 2026-08-23 live scenes + Mike sheet
- Request: `update docs` after today’s classroom furniture/5.2, 2.4 door stubs + size ramp, 4.1 polygons, new Mike walk sheet, head/body pack passes, and 5.1 +50% size.
- Implementation: Canon now matches live files. `AI_DOCS.md` notes overworld Mike (white body, black eyes, not noir-inverted) and shipped CRT player knobs. `SCENE_BUILDING.md` lists live authored scales, pack rules, and the 2.4 walk-position size ramp. Arc write-ups no longer cite old 64 px scales (`3.0` / `5.0`).
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC4.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only. Gameplay unchanged.
- Verification: Compared write-ups to live `.tscn` Player scales and today’s implement chats.
- Notes: Changelog already had most of today’s implement entries; this pass added the missing 5.1 +50% log and synced stale scale/FX text.

### Dialogue typewriter audio
- Request: Play `axel_typewriter_open.wav` when the dialogue bar turns on, that clip backwards when it turns off, and `axel_typewriter_v4.wav` looping only while letters type (skip jumps the loop, then pause).
- Implementation: Copied the two WAVs into `assets/audio/`. Added `OpenClosePlayer` and `TypeLoopPlayer` on `TopDialogueOverlay` so every room that already instances the bar gets the sounds. Open plays at CRT on / fade-in. Real `hide_line` plays a cached reverse of the open clip. Type loop uses a static tape position across rooms; pauses on beats / full line; skip jumps leftover letters÷CPS then pauses. `interrupt_line` stops both with no reverse. User later set open/close volume to `-12` dB.
- Files changed:
  - `AXEL/axel_project/assets/audio/axel_typewriter_open.wav`
  - `AXEL/axel_project/assets/audio/axel_typewriter_v4.wav`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: First game audio. Opening a line clicks, typing ticks, closing clicks in reverse. New rooms keep the typewriter tape where it left off.
- Verification: Overlay hook points reviewed in source. Headless cannot prove sound — listen in the editor.
- Notes: Volume is Inspector `Volume Db` on the two players (`OpenClosePlayer` live `-12`, `TypeLoopPlayer` live `0`). No G:\\ paths. Skip stays instant full-line reveal.

### Shared player facing hitboxes
- Request: Manual corridor Front / Side / Back shapes should work on every room and stay the default for new scenes.
- Implementation: Saved the 1.2 polygons as `scenes/player/hitbox_front.tres` / `hitbox_side.tres` / `hitbox_back.tres`. Pointed every walkable room at those same files (`CollisionFront` / `CollisionSide` / `CollisionBack`). `Player.gd` applies Front toward camera, Side for A/D (flips left), Back walking away, and creates the three nodes if a new scene is missing them. `use_alpha_collision` is now opt-in (cyan editor preview still exists for that path).
- Files changed:
  - `AXEL/axel_project/scenes/player/hitbox_front.tres`
  - `AXEL/axel_project/scenes/player/hitbox_side.tres`
  - `AXEL/axel_project/scenes/player/hitbox_back.tres`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: One shared hitbox set for all rooms. Edit a `.tres` (or any room’s matching shape and save the resource) and every room updates. New rooms only need `Player.gd`.
- Verification: Scene nodes and shared ExtResources reviewed; QA child-name list includes the three facing shapes.
- Notes: Do not Make Unique the player `.tres` files. Alpha trace is opt-in only.

### Docs sync — rest of 2026-08-23
- Request: `update rest of the days docs` after the morning docs pass (typewriter audio + shared facing hitboxes).
- Implementation: Logged the two afternoon builds. Canon / how-to / folder map now name the audio players, volume knobs, shared hitboxes, and the “do not Make Unique” exception. Governance rule adds the hitbox line. 2.4 write-up no longer says “Kitchen profile.”
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/references/README_STRUCTURE.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only. Gameplay unchanged.
- Verification: Compared write-ups to live overlay players, `hitbox_*.tres`, and `Player.gd` facing switch.
- Notes: No Aug 21 or Aug 22 implement chats to backfill. Morning Aug 23 work was already in the earlier docs sync.

### Tighter CRT chroma on new Mike
- Request: RGB CRT ghosts on the new walk-sheet Mike sat too far off the body; pull them in.
- Implementation: First pass widened the chroma mask. Follow-up (still too far / intro looked like two Mikes): drop spatial player chroma to `0`, use a 16px halo, skip barrel warp + edge vignette on Mike, and stop mixing uncurved `src` with curved CRT (that mix doubled him at the bezel). Scanlines still run on the body. Env CRT unchanged.
- Files changed:
  - `AXEL/axel_project/scenes/fx/crt_plugin_overlay.gdshader`
  - `AXEL/axel_project/scenes/fx/CrtPluginOverlay.tscn`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: One Mike. CRT lines sit on his ink. Intro walk-in from the screen edge should not spawn a second copy. Room CRT split is the same.
- Verification: Shader + overlay uniforms reviewed. Stop Play and Play again so the CRT overlay reloads.
- Notes: Tune on `CrtPluginOverlay.tscn` → `FilterRect` (`player_chroma` / `player_chroma_spread_px`). Remote tree while playing does not save.

### Intro Mike stray-stroke debris
- Request: After CRT chroma was pulled in, intro still showed broken brush-stroke “debris” around Mike (not one line on the body).
- Implementation: Stripped disconnected ink islands off `mike_walking-Sheet.png` (side walk frames had leftover specks by the head/legs). Pack now drops extra islands under 120 px after the head plate. Intro `InterfacePulseOverlay` no longer chroma-splits, glitch-shifts, or grains Mike — those were turning specks into RGB spray.
- Files changed:
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet.png`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.py`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.gd`
  - `AXEL/axel_project/tools/visual_style/shaders/option_1_crt_tv.gdshader`
  - `AXEL/axel_project/scenes/fx/InterfacePulseOverlay.tscn`
  - `AXEL/axel_project/plans/references/AXEL_OVERWORLD_EVENT_FX.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Intro walk-in should show one clean Mike. Room interference wave still runs; it just does not shatter him.
- Verification: All 12 sheet cells are a single ink island. Stop Play and Play again so the sheet and pulse shader reload.
- Notes: Face brush gaps on the head plate are kept. Only detached specks were removed.

### Restore original CRT + smaller Mike RGB split
- Request: Broken CRT around Mike after zero-chroma / unwarped-UV experiments; keep the original CRT look but pull red/blue closer to the body.
- Implementation: Restored baseline `crt_plugin_overlay.gdshader` and `option_1_crt_tv.gdshader` structure (one curved UV pass, `mix(src, col, crt_mix)`). Only tightened offset: baseline CRT `player_chroma` `0.0004` (env stays `0.001`), looser white-stroke lum gate (`0.32`), ±`2*chroma` neighbor taps. Intro pulse keeps full CRT but uses `player_chroma` `0.001` on Mike via the same mask. Removed unwarped-UV mix, 16px halo, and zero-chroma path. Sheet speck cleanup kept.
- Files changed:
  - `AXEL/axel_project/scenes/fx/crt_plugin_overlay.gdshader`
  - `AXEL/axel_project/scenes/fx/CrtPluginOverlay.tscn`
  - `AXEL/axel_project/tools/visual_style/shaders/option_1_crt_tv.gdshader`
  - `AXEL/axel_project/scenes/fx/InterfacePulseOverlay.tscn`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/references/AXEL_OVERWORLD_EVENT_FX.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike gets the same CRT treatment as the room; RGB fringe sits closer than before but is not zero. Intro walk-in should no longer show a split/doubled figure.
- Verification: Shaders match original pass structure; shipped knobs on overlay `.tscn` files. Stop Play and Play again to reload.
- Notes: Tune only `player_chroma` on `CrtPluginOverlay.tscn` → `FilterRect` if the fringe needs a nudge.

## 2026-08-24

### Scene 1.1 — stump / rocks behind filters
- Request: Create a behind filter for scene 1.1 stump left, rocks left, and rocks right.
- Implementation: Added `Stump_Left_Behind` / `Rocks_Left_Behind` / `Rocks_Right_Behind` `Area2D` zones (`leaf_occlusion_zone.gd`, `feather_px = 2`) with starter boxes on the colliders for editor dragging. Raised the Mike fade shader from 3 to 6 polygon slots so trees + right wall stay wired. Stump/rocks use no trunk Y-gate (`1e9`), same as the right wall.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike fades inside the new stump/rocks polygons as well as the existing tree and right-wall behind zones. 2.1 / 3.1 still use only the first 3 slots.
- Verification: Scene nodes present under `EnvironmentColliders`; 1.1 script lists all six names after cover-fit layout.
- Notes: Starter boxes sit on the collision clusters — drag the polygon vertices in the editor to match the drawing. Shader max is now 6 behind zones.

### Scene 1.1 — stump / rocks behind filter front gate
- Request: Walking from the front of the new 1.1 behind filters (at least left rocks and stump) still applied the fade. Tree behind filters already worked.
- Implementation: Stump and both rock behind slots now use the same collision-front Y-gate as the trees (`Stump_Left` / `Rocks_Left` / `Rocks_Right` max collision Y). Fade only when standing behind that front line. `RightWall_Behind` stays polygon-only (`1e9`). Rock clusters scan every `CollisionPolygon2D` child so the gate uses the true front of the pile.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Approaching stump / left rocks / right rocks from the camera side stays opaque even if the body overlaps the object. Walking behind those objects still fades. Trees and right wall unchanged.
- Verification: Manual F6 on `1.1_SchoolExterior` — walk into left rocks and stump from the front (no fade), then go behind (fade). Trees still fade only past the trunk.
- Notes: Right wall is still polygon-only on purpose (building wall, not a ground object with a front line).

### Scene 1.1 — extra behind polygons under one zone
- Request: Duplicating `Rocks_Left_Behind` into `CollisionPolygon2D2` behind another rock did not activate the fade.
- Implementation: Behind zones now send every `CollisionPolygon2D` child to the Mike fade shader (up to 4 per zone, 64 verts total). Extra polygons keep their own front gate from the nearest matching collision shape, so a second rock does not share the first rock’s line.
- Files changed:
  - `AXEL/axel_project/scenes/fx/leaf_occlusion_zone.gd`
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: `CollisionPolygon2D2` (and 3 / 4) under `Rocks_Left_Behind` now fade like the first polygon. Same for stump / right rocks if more children are added. 2.1 / 3.1 still use one polygon per zone unless they also add children and get the packed path later.
- Verification: Stop Play and Play again on `1.1_SchoolExterior` so the shader reloads. Stand behind the second left rock inside `CollisionPolygon2D2` — fade on; walk in from that rock’s front — fade off.
- Notes: Godot’s red collision debug can show you inside a shape even when the fade is off (front-gate). Duplicate under the same `*_Behind` Area2D; do not make a new Area2D unless a new shader slot is added.

### Shared Mike ShadowOutline fit from 1.2
- Request: Copy the manual 1.2 `ShadowOutline` position/scale to every other walkable scene.
- Implementation: Applied 1.2’s authored silhouette (`position` `(-5.0416956, -5.041732)`, `scale` `(1.0335996, 0.9969109)`) on all other Player rooms. `Player.gd` reapplies the same fit at Play so a missed `.tscn` still matches. QA now checks this shared fit instead of requiring `ShadowOutline` at `(0, 0)`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike’s black outline sits in the same place relative to the sprite in every walkable room (same as 1.2). Combat unchanged.
- Verification: Confirmed every `ShadowOutline` in walkable `.tscn` files now has the 1.2 position and scale.
- Notes: This is the allowed exception to the default “no child offset” rule. AnimatedSprite and facing hitboxes stay at `(0, 0)`.

### Mike side-walk waist dust
- Request: First sideways walk frames showed leftover “dust” just off the waist; only visible in-game.
- Implementation: Wiped the stray pixels from `mike_walking-Sheet.png` and the source side-walk drawing. Packer now drops far-off blobs (`FAR_BLOB_DIST`) as well as extra islands under 120 px (later intro-debris pass).
- Files changed:
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet.png`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.py`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Left/right walk no longer flickers a stray stroke beside the waist.
- Verification: Side-frame component check after wipe; leftover dust boxes had 0 opaque pixels.
- Notes: Follow-up intro-debris pass on the same sheet is logged under 2026-08-23 (same morning).

### 1.1 intro stand raised off left rocks
- Request: Intro walk stuck on the left rocks (new hitbox sits lower than the old one).
- Implementation: Moved the 1.1 `Player` node from `(227, 430)` to `(227, 405)`. Intro still walks to that node, not a separate stones target.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Fresh Play intro can reach the stand point without snagging the left rock pile.
- Verification: Player node Y in the scene file.
- Notes: Player node remains the spawn. Nudge the node in the editor if a later hitbox change snags again.

### Synced soundtrack (menu p1 → overworld p2)
- Request: Add `B_Goes_Down` stems; p1 loops on the title; New Game should continue into p2 without a gap; music must keep playing across later rooms.
- Implementation: Autoload `AxelMusic` plays p1 + p2 in one `AudioStreamSynchronized`. Menu: p1 loops with a 10s fade-in. New Game: p1 finishes the current loop, then hard-cuts to p2 (no crossfade). `MainMenu.gd` calls `to_overworld()` before the scene swap. Later rooms stay on p2. `Music` bus ~`-12` dB. Env `AXEL_DISABLE_MUSIC=1` mutes BGM.
- Files changed:
  - `AXEL/axel_project/scripts/autoload/axel_music.gd`
  - `AXEL/axel_project/assets/audio/music/B_Goes_Down_p1.wav`
  - `AXEL/axel_project/assets/audio/music/B_Goes_Down_p2.wav`
  - `AXEL/axel_project/scenes/Main_Menu/MainMenu.gd`
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/default_bus_layout.tres`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Title has music. New Game keeps p1 until that loop ends, then p2 runs for the rest of the overworld.
- Verification: Code path reviewed; listen in the editor (headless cannot prove sound).
- Notes: Archive stems p3–p6 and `casino_*` were not copied in. Early crossfade versions were replaced by the hard cut.

### Typewriter audio buses
- Request: Typewriter effects on their own bus; later, pan only the open click (not the typing ticks).
- Implementation: `default_bus_layout.tres` now has `Typewriter` (loop) and `TypewriterOpen` (open/close + Panner `pan = 0.5`). Overlay players route there. Overall typewriter loudness is those buses; per-clip mix stays on `OpenClosePlayer` (`-16`) / `TypeLoopPlayer` (`0`).
- Files changed:
  - `AXEL/axel_project/default_bus_layout.tres`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.tscn`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Bar click can be panned without moving the typing ticks. Music stays on the `Music` bus.
- Verification: Overlay `bus` fields and bus layout names reviewed.
- Notes: Pan the `TypewriterOpen` Panner in the Audio bus editor, not `Typewriter`.

### Delete scratch `_sprite_preview/`
- Request: Confirm whether `_sprite_preview/` can be deleted (user then deleted it).
- Implementation: Folder was look-dev crops only (not loaded by the game). User deleted the tracked files.
- Files changed:
  - `_sprite_preview/` (removed)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: None. Live Mike sheet is still `assets/sprites/mike_walking-Sheet.png`.
- Verification: No gameplay path referenced `_sprite_preview/`.
- Notes: Do not copy those crops into `assets/sprites/` — Godot would import them as extra sprites.

### Docs sync — 2026-08-24
- Request: `update todays docs` after soundtrack, typewriter buses, 1.1 behind filters, shared ShadowOutline, sheet dust, and intro stand nudge.
- Implementation: Canon now matches live audio and 1.1 spawn. Behind-filter / ShadowOutline write-ups were already current from the implement chats. CRT Mike chroma / intro debris / restore-original-CRT were logged under 2026-08-23 (same morning).
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/references/README_STRUCTURE.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only. Gameplay unchanged.
- Verification: Compared write-ups to `axel_music.gd`, `default_bus_layout.tres`, overlay buses, 1.1 Player Y `405`, and today’s implement chats.
- Notes: 1.1 stump/rocks behind filters and shared ShadowOutline were already in this day’s changelog before this pass.

### Menu p2 + New Game crossfade to p1
- Request: Refresh the `B_Goes_Down` WAVs from the archive; play p2 on the Main Menu; start a long p2→p1 crossfade (at least 10s) when pressing New Game, with both stems overlapping.
- Implementation: Copied the new `B_Goes_Down_p1.wav` / `B_Goes_Down_p2.wav` (same names, new audio). Swapped live roles: menu layer is p2, overworld layer is p1. `to_overworld()` now starts a 10s linear-amplitude crossfade immediately instead of waiting for a loop point / hard-cut. Typewriter WAVs in the archive matched the project, so they were left alone. Extra archive stems (`Drums_*`, p3, p4, `casino_*`) were not copied in.
- Files changed:
  - `AXEL/axel_project/assets/audio/music/B_Goes_Down_p1.wav`
  - `AXEL/axel_project/assets/audio/music/B_Goes_Down_p2.wav`
  - `AXEL/axel_project/scripts/autoload/axel_music.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/references/README_STRUCTURE.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Title plays p2. New Game fades p2 out and p1 in together over 10s, then p1 stays on in later rooms.
- Verification: Archive hashes matched after copy; music script path reviewed. Listen in the editor (headless cannot prove sound). Godot must reimport the new WAVs on next Play.
- Notes: This replaces the old p1-on-menu / wait-for-loop / hard-cut-to-p2 rule.

### Casino combat music layers
- Request: Copy new `B_Goes_Down` + casino WAVs; casino music only in combat — fade out scene music, start synced casino stems; first win → finish drums loop → `like_that` solo once → drums_p1+p1; Trinity → drums_p2+p1+p2 immediately.
- Implementation: Copied archive stems into `assets/audio/music/` (including unused `B_Goes_Down_Drums_*` / p3 / p4). Extended `AxelMusic` with a second synced player for five casino layers. Combat scenes fade overworld (~2s) then intro drums. `combat_root` calls `notify_first_win` / `notify_trinity` / `reset_combat_encounter` without awaiting audio. Trimmed `casino_like_that` trailing silence and padded to drums loop length (6.857s) so the regular mix returns on the beat. `to_combat()` ready for a future overworld door.
- Files changed:
  - `AXEL/axel_project/assets/audio/music/B_Goes_Down_p1.wav`
  - `AXEL/axel_project/assets/audio/music/B_Goes_Down_p2.wav`
  - `AXEL/axel_project/assets/audio/music/B_Goes_Down_Drums_p1.wav`
  - `AXEL/axel_project/assets/audio/music/B_Goes_Down_Drums_p2.wav`
  - `AXEL/axel_project/assets/audio/music/B_Goes_Down_p3.wav`
  - `AXEL/axel_project/assets/audio/music/B_Goes_Down_p4.wav`
  - `AXEL/axel_project/assets/audio/music/casino_Drums_p1.wav`
  - `AXEL/axel_project/assets/audio/music/casino_Drums_p2.wav`
  - `AXEL/axel_project/assets/audio/music/casino_p1.wav`
  - `AXEL/axel_project/assets/audio/music/casino_p2.wav`
  - `AXEL/axel_project/assets/audio/music/casino_like_that.wav`
  - `AXEL/axel_project/scripts/autoload/axel_music.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/references/README_STRUCTURE.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: F6 `combat_test` plays casino drums; first win triggers like_that then drums+p1; Trinity switches to drums_p2+p1+p2. Overworld no longer incorrectly gets B_Goes_Down when opening combat.
- Verification: WAV lengths checked (casino loops 6.857s; like_that padded to match). Headless combat tests should stay deterministic (no awaits on music). Listen in editor for mix timing.
- Notes: No overworld combat interactable yet — `to_combat()` is the future entry API.

## 2026-08-24

### ShadowOutline visible in editor + same fit on every pose
- Request: In 1.4 the `ShadowOutline` eye was off and could not be turned on. Also confirm the silhouette stays the same on every spritesheet pose after the recent Mike-sheet / pose-nudge work.
- Implementation: Editor tool was forcing `ShadowOutline.visible = false` every frame (and saving that into 1.2 / 1.4). It now keeps the node on and syncs the current pose. Pose-stack faded poses draw the same black copy. `white_sprite.gdshader` now multiplies `COLOR.rgb` so Play’s black modulate is actually black (it was drawing a faint white copy). Shadow `offset` is divided by the outline scale so Back/Side nudges no longer shift the silhouette relative to Front.
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/fx/white_sprite.gdshader`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Editor 2D view shows the black outline on Front, Back, and Side. Play shows a real black silhouette in every room. Outline alignment matches across walk/idle facings.
- Verification: 1.4 / 1.2 ShadowOutline no longer authored `visible = false`. Click the 1.4 Player in the 2D view — the eye on `ShadowOutline` should stay on; switch Pose Nudge preview Front/Back/Side.
- Notes: The extra head plate stays gone. A thin black fringe around the head is the scaled copy, not a new fill.

### Restore Mike ShadowOutline during Play
- Request: Shadow outline missing on the player model in scene 1.4.
- Implementation: `Player.gd` shows `ShadowOutline` again at Play (it had been hidden after the no-head-plate sheet so the larger black copy would not spill past the head). Fixed 1.4’s authored silhouette Y (was flipped positive) back to the shared 1.2 fit, and zeroed `AnimatedSprite` position. Editor still hides the node and draws the pose stack instead.
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Overworld Mike has the black silhouette outline again in every room, including 1.4. The extra head plate stays gone; a thin black fringe can still peek around the head because the outline is a slightly larger copy.
- Verification: 1.4 ShadowOutline position/scale matches 1.2; Play sets `shadow_outline.visible = true` after sprite setup.
- Notes: If the head fringe is too strong, retune shared scale — do not hide the node again.

### Combat Dev Tools wrench menu

- Request: Debug-only top-left wrench menu for combat playtest (guarantee Trinity / Free Spins / 1000× payout, bankroll & goal +/−, skip current spin FX).
- Implementation: Added autoload `AxelCombatDevTools` (CanvasLayer 2100, combat scenes only, `OS.is_debug_build()` gate). Extended `CombatRoot` with debug-guarded bankroll setter, guarantee flags, skippable `_pause_visual`, and Trinity/FS-clear/payout hooks on both async and sync spin paths. Hid duplicate GOAL SpinBoxes from the item-picker PlaytestTuning panel.
- Files changed:
  - `AXEL/axel_project/scripts/debug/axel_combat_dev_tools.gd`
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: F6 combat test shows a wrench menu for playtest guarantees; release builds unchanged. Trinity → Free Spins sequence still walks the real handoff UI.
- Verification: Headless scaffold, determinism, and princess checks.
- Notes: 1000× is a payout override vs total bet (not chip-bar / FS cascade caps). Skip only short-circuits visuals of the in-flight spin — never starts a second spin.

### Mike — no extra head fill (use painted `kävely_*`)
- Request: Black fill behind Mike spilled over the head on red/white backgrounds. Source `kävely_etu` / `kävely_sivu` already have white on the face, so stop adding fill and keep usual CRT/noir.
- Implementation: Packer no longer draws a convex black head plate. Face uses inverted source pixels (painted white → black holes); chin-down stays solid white. Straight-alpha paste so soft edges are not baked onto black. Play hides `ShadowOutline` (the larger black copy was still spilling past the head). CRT + noir stack unchanged.
- Files changed:
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.py`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.gd`
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet.png`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Overworld Mike is still a white figure with black eyes. No extra black plate/outline around the head. Room CRT and noir are the same.
- Verification: Re-baked 12-cell sheet; front-cell top edge has 0 dark pixels on a red composite. Stop Play and Play again so Godot reimports the sheet.
- Notes: `ShadowOutline` node and 1.2 fit stay in scenes for editor/QA; it is only hidden during Play.

### Explore template — librarian only (no draft approach)
- Request: PRE-PLAN on Composer must not plan or implement. “Create PRE-PLAN_Artifact” after a list of wants means those are artifact topics, not fixes in that chat. Composer never touches game files; Premium invents the approach from a fact pack.
- Implementation: Rewrote `PRE-PLAN_Artifact`: hard no-write rules, Create-PRE-PLAN topic rule, facts-only fields (current flow / possible causes / gap / similar / canon quotes / research notes / questions for Plan). Dropped recommended approach, likely-cause winner, and draft approach. PREMIUM now treats Possible causes / Questions for Plan as its choices. AI_DOCS Explore row + handoff note updated.
- Files changed:
  - `AXEL/axel_project/plans/PRE-PLAN_Artifact`
  - `AXEL/axel_project/plans/PREMIUM_Artifact`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs/templates only. Gameplay unchanged.
- Verification: Templates read as explore-only; artifact fields no longer include Draft approach.
- Notes: AskQuestion in Explore is player-intent only (when / how often / which room), not architecture.

### Restore 1.1 circle hitboxes (2.1 table slide)

- Request: After walking into a 2.1 table with D, W / W+D should slide along the edge instead of sticking until A. Keep the user’s 1.1 circle placements as the shared hitbox (not origin-centered).
- Implementation: Confirmed `Player.gd` already reapplies shared 1.1 Collision* positions on Play (`HITBOX_FRONT_POS` / `HITBOX_BACK_POS` / `HITBOX_SIDE_POS`); `hitbox_*.tres` stay radius-only circles; all walkable rooms already copy those placements. Updated canon so facing hitboxes are an allowed child-offset exception (same pattern as ShadowOutline). Left table/wall geometry and Player cover-fit scale alone.
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd` (already had 1.1 positions — kept)
  - `AXEL/axel_project/scenes/player/hitbox_front.tres` / `hitbox_back.tres` / `hitbox_side.tres` (radius-only — kept)
  - Walkable room `Collision*` nodes (1.1 placements — kept)
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike’s feet circles stay where authored in 1.1 across every room, so rectangular tables should allow edge slide (FLOATING + safe_margin 0.1). Docs no longer tell agents to zero Collision*.
- Verification: Grep confirmed positions/radii on Player.gd, `.tres`, and nine walkable scenes. Headless scene smoke OK. Headless cafeteria slide probe: D into TableBlockLeft then W slid (dy≈6.7); A backed off (dx≈3.0). Manual: Play 2.1 → D into first table → W / W+D must slide; Debug Visible Collision Shapes match 1.1 editor.
- Notes: If a specific table still snags after this, tune that table’s collider — not Mike’s scale.

### Slim always-on governance rule (pointer only)
- Request: `.cursor/rules/axel-ai-docs-governance.mdc` should only hold global defaults — always read `AI_DOCS` then the matching plan — not music/VFX/cover-scale specifics.
- Implementation: Replaced duplicated Style/FX bullets with a read-then-route pointer (`AI_DOCS` always; `SCENE_BUILDING` for rooms/player; combat plans when asked; changelog only for recent history). Kept ask-before-large, no layer-blur, combat determinism, and Explore librarian-only. Noted in `AI_DOCS` How to work that the `.mdc` is not the rulebook.
- Files changed:
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs/rules only. Gameplay unchanged. Spawn, hitboxes, cover-fit, music, and post-FX stay in `AI_DOCS` / `SCENE_BUILDING`.
- Verification: `.mdc` no longer contains `0.546`, hitbox paths, or music/VFX recipes.
- Notes: New chats pick up the slim rule; this thread may still show the old always-on text until a new chat.

### Player pose nudge fields (shared Front/Back/Side)

- Request: Add Inspector fields so poses can be nudged by hand and stay lined up (SpriteFrames overlay does not persist).
- Implementation: Shared `pose_nudge.tres` (Front/Back/Side Vector2) applied as `AnimatedSprite.offset` on facing change. Player Inspector group **Pose Nudge** plus editor preview dropdown. Node `position` stays `(0, 0)`. Nudges are not saved per room.
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/player/mike_pose_nudge.gd`
  - `AXEL/axel_project/scenes/player/pose_nudge.tres`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Changing Pose Nudge Front/Back/Side on any Player moves that facing’s drawing in every room. Hitboxes are unchanged. Left-facing side flips the X nudge.
- Verification: Script parse of new exports/helpers; editor path is Player → Inspector → Pose Nudge.
- Notes: Do not drag SpriteFrames frames. Ctrl+S after nudging so `pose_nudge.tres` is written.

### Retire CollisionBack / CollisionSide (one Front hitbox)

- Request: After lining up poses with nudges in 1.4, remove CollisionBack and CollisionSide so they do not come back.
- Implementation: `Player.gd` keeps only `CollisionFront` (`hitbox_front.tres` at 1.1 Front). On load it deletes CollisionBack / CollisionSide instead of recreating them. Facing no longer swaps or flips extra circles. Locked 1.4 nudges into `pose_nudge.tres` (back `-114.725, 2.49`, side `41.76, -15.86`).
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd`
  - Walkable room `.tscn` Player trees (Back/Side nodes + ext_resources removed)
  - `AXEL/axel_project/scenes/player/pose_nudge.tres`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/references/README_STRUCTURE.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: One circle for every facing. Drawings use pose nudge to sit on that circle. Back/Side nodes no longer appear in the editor or at Play.
- Verification: Grep found no remaining CollisionBack/CollisionSide in `scenes/`. Player.gd lints clean.
- Notes: Unused `hitbox_back.tres` / `hitbox_side.tres` files remain on disk but are not wired.

### Mirror Front hitbox when walking left

- Request: Left-walk hitbox sat off the model; right-walk was correct. Left should be a copy of right.
- Implementation: `CollisionFront` now flips its X with A (same authored Front, mirrored) so it stays on the flipped side pose. D / front / back keep the authored placement.
- Files changed:
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Holding A puts the cyan circle on Mike the same way D does.
- Verification: Logic mirrors `_last_side_is_right`; pose nudge already negated X for left.
- Notes: No second Side hitbox. One Front circle, flipped on left.

### Memory still leave — click / tap / interact
- Request: After any memory ends, pressing the screen or any interact button should quit the memory, not only the red X.
- Implementation: After `_can_exit`, 2.2 / 3.2 / 5.2 now treat left-click, tap, and Tab/E/Space/Enter the same as the X button. Those keys still skip/advance while lines are playing; leave waits until the bar is closed.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.2_CafeteriaMemory.gd`
  - `AXEL/axel_project/scenes/Arc_3/3.2_BackyardMemory.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.2_ClassroomDesk.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: After the last line, click/tap/E also returns to the room. X still works.
- Verification: Shared `_is_interaction_event` on the three still scripts; leave still gated on `_can_exit`.
- Notes: No extra glitch; same scene-change as X.

### Combat test ITEMS list rebuilds from catalog
- Request: New catalog items were missing from the combat_test ITEMS panel while using the wrench menu.
- Implementation: The panel was a saved snapshot (Ash Reroll Token + Void Satchel). Play now rebinds live ScrollContainer children and rebuilds FAMILIES + uniques from `combat/data/items/`. There is no separate “real combat” item list.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: F6 `combat_test` shows the full catalog (54 rows at the time of the check). Wrench menu unchanged.
- Verification: Temporary headless picker count found 54 items, then the check script was deleted.
- Notes: Stop Play and F6 again so the rebuilt list appears.

### Docs sync — rest of 2026-08-24
- Request: `update rest of todays docs` after the morning docs pass (soundtrack / typewriter / 1.1 behind filters).
- Implementation: Canon now matches work after that pass: menu p2→p1 crossfade, casino combat music, combat wrench, Mike no-head-plate + ShadowOutline, pose nudge, one Front hitbox (left-walk mirror), Explore librarian-only, slim `.mdc`, memory click-leave, and ITEMS picker rebuild. Scene write-ups no longer say 1.4 collision children sit at `(0, 0)`.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/references/README_STRUCTURE.md`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only. Gameplay unchanged.
- Verification: Compared write-ups to live memory scripts, `combat_test.gd` picker, `pose_nudge.tres`, `project.godot` autoloads, and today’s implement chats after 11:34.
- Notes: Morning changelog already had later implement entries; this pass filled the two missing logs (memory leave, ITEMS picker) and leftover stale scene/structure text.

## 2026-08-25

### 2.1 cafeteria — Mike 50% larger (cover-sync unchanged)
- Request: After the new player model, Mike in 2.1 was a bit too small; increase size by 50%. Also re-check that scale stays the same vs the room on another computer / resolution.
- Implementation: Raised authored Player scale in `2.1_Cafeteria.tscn` from `0.198347` to `0.2975205` (same 50% bump as 5.1). Walk speed stayed `189.75`. Did **not** retune for a window or monitor — `PlayerCoverSync` still multiplies authored scale by `live_cover / 1920×1280 baseline`. Stretch stays disabled.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: In the cafeteria only, Mike is 50% taller vs the drawing at 1920×1280. Other rooms unchanged. Any Game tab / OS window still keeps the same Mike-to-room ratio.
- Verification: `player_cover_sync_check.gd`; 2.1 still binds `bind_design_from_background`; `project.godot` has no canvas stretch.
- Notes: If Mike only looked small on one monitor, the fix would be the scaler, not this number. This change is the authored 1920×1280 look vs the cafeteria furniture.

### Walk speed from player scale
- Request: Speed felt too slow vs the larger 2.1 Mike; add a global scale→speed equation so stride feels constant, with extra speed when scale is below 0.3 (more extra the further below).
- Implementation: Added `PlayerWalkSpeed.from_scale` (`K = 253.4 / 0.198347`; below 0.3 add linear extra so 1.1 gets +50). `PlayerCoverSync.bind_from_player` sets authored speed from scale. Baked Inspector speeds on all walkable Players. 2.4 depth ramp still multiplies live scale+speed after cover-sync (formula not re-run).
- Files changed:
  - `AXEL/axel_project/scenes/core/player_walk_speed.gd`
  - `AXEL/axel_project/scenes/core/player_cover_sync.gd`
  - `AXEL/axel_project/scenes/core/test/player_walk_speed_check.gd`
  - `AXEL/axel_project/scenes/core/test/player_cover_sync_check.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md` … `ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Bigger Mike walks faster in proportion; tiny Mike (1.1) gets the largest below-0.3 boost; shared rooms get a small boost; kitchen (scale > 0.3) has none.
- Verification: `player_walk_speed_check.gd`, `player_cover_sync_check.gd`.
- Notes: Tune `SMALL_ANCHOR_ADD` / `SMALL_SCALE` in `player_walk_speed.gd` if the below-0.3 feel needs a later pass.

### `[E]` door arrival maps along InteractAreas
- Request: 2.1→1.4 from the top of the return InteractArea spawned Mike outside 1.4’s walls. Arrival should map along each scene’s InteractArea (top→top), then keep the Front hitbox inside walls. Apply to all `[E]` room doors; keep walk-off Y for 1.2↔1.4.
- Implementation: Added `InteractArrival` helper + transient `GameManager.interact_arrival_t`. Leave paths save 0..1 along the source box; arrive paths place on the dest box with the existing into-room peek, then deferred `clamp_hitbox_to_walls`. Wired 1.4↔2.1, 2.1↔2.3/3.1/2.4, 2.4↔4.1/5.1, 1.1↔1.2 (`exterior_door` corridor spawn). Kitchen now peeks on its door when entering from cafeteria.
- Files changed:
  - `AXEL/axel_project/scenes/core/interact_arrival.gd`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md` … `ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Standing high/low in an `[E]` door lands at the matching spot on the other room’s door box, without sticking Mike into walls. Walk-off 1.2↔1.4 and memory still returns unchanged. Fresh Play still uses the Player node.
- Verification: `scene_smoke_check.gd` OK (10 scenes). Manual: 2.1 top/bottom of left door → 1.4; reverse; spot-check other `[E]` links.
- Notes: Prefer clamp over redrawing 1.4’s cafeteria box; shrink that box only if clamp still fails in play.

### 1.4 walk animation FPS matches 1.2
- Request: 1.2–1.4 walk speed/size were already the same, but 1.4 looped the walk sheet much faster than 1.2. Use 1.2 as the correct loop.
- Implementation: 1.4 had no `animation_fps`, so `Player.gd` rebuilt the sheet at the old default **10** FPS (1.2 uses **5**). Set 1.4 `animation_fps = 5.0` and wired the same walk sheet as 1.2. Changed `Player.gd` default `animation_fps` from `10` to `5` so a missing override no longer doubles the loop.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 1.4 walk cycle should now match 1.2. Authored scale/speed were already the shared pair.
- Verification: Compared Player exports; only 1.4 was missing `animation_fps`.
- Notes: Size/speed formula was not the cause — animation FPS was independent.

### Combat ITEMS list alignment + L2 icon bake
- Request: ITEMS list rows were stair-stepped; all icons were the same hatch placeholder. Icons should come from LimeZu singles (L2 clock seeded); interiors numbered files are mixed objects — cluster by shape, not consecutive numbers.
- Implementation: Fixed item-row checkbox columns (no expand) and natural-sort uniques (`C1`…`C10`). Added `item_icon_sources.json` + dual-root baker; baked L2 from bedroom clock 387. Added `cluster_item_tiles.gd` (gitignored `.icon_scan/` sheets). Catalog Playtest HUD notes updated.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/tools/combat/bake_item_icons.gd`
  - `AXEL/axel_project/tools/combat/item_icon_sources.json`
  - `AXEL/axel_project/tools/combat/cluster_item_tiles.gd`
  - `AXEL/axel_project/combat/art/item_icons/L2.png`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `.gitignore`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: ITEMS rows line up; Common uniques sort C1…C10; L2 shows noir-remapped clock. Other ids stay placeholders until more JSON mappings.
- Verification: `combat_test_scaffold_check.gd`; bake prints `from_source=1`.
- Notes: Remaining icons via Composer/Auto + labeled cluster sheets. Do not re-run `generate_item_resources.py` (overwrites placeholders).

### Walk speed constant ~33% slower
- Request: Globally make the walk-speed constant a little slower (~33%). Put the scale/speed table in canon docs.
- Implementation: Multiplied `PlayerWalkSpeed` `REF_SPEED` (`253.4` → `169.778`) and the below-0.3 extra (`+50` → `+33.5`) by `0.67`. Rebaked all walkable Inspector speeds. Table lives in `SCENE_BUILDING.md` § Player scale profiles; `AI_DOCS.md` points there.
- Files changed:
  - `AXEL/axel_project/scenes/core/player_walk_speed.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md` … `ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Every room walks ~33% slower. Size and walk-loop FPS unchanged.
- Verification: `player_walk_speed_check.gd`, `player_cover_sync_check.gd`.
- Notes: Shared rooms are now `185.21` (was `276.43`).

### Round authored scale / speed
- Request: Round scale to three decimals (`0.00X`) and speed to one decimal (`0.X`).
- Implementation: `PlayerWalkSpeed` now uses `REF_SCALE` `0.198`, `REF_SPEED` `169.8`, `SMALL_ANCHOR_SCALE` `0.079`; `from_scale` snaps to `0.1`. Rebaked every walkable Player. Table in `SCENE_BUILDING.md` updated.
- Files changed:
  - `AXEL/axel_project/scenes/core/player_walk_speed.gd`
  - `AXEL/axel_project/scenes/core/test/player_walk_speed_check.gd`
  - walkable `Player` nodes in `1.1` / `1.2` / `1.4` / `2.1` / `2.3` / `2.4` / `3.1` / `4.1` / `5.1`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md` … `ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Size/speed feel unchanged; numbers are just shorter.
- Verification: `player_walk_speed_check.gd`, `player_cover_sync_check.gd`.
- Notes: Shared rooms are `0.198` / `185.3`.

### `[E]` arrival t taken once; 2.1→1.4 Y mapping
- Request: 2.1→1.4 still spawned Mike in the same 1.4 spot whether he used the top or bottom of `ReturnInteractArea`.
- Implementation: Camera cover-fit runs twice; each `take_interact_arrival_t` after the first returned `0.5` (box center). Destination rooms now cache `t` in `_ready`. Helper measures/places the Front hitbox in `EnvironmentColliders` texture space (circle sits below the Player node). Place after `PlayerCoverSync.apply` so the offset matches live scale.
- Files changed:
  - `AXEL/axel_project/scenes/core/interact_arrival.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Top of 2.1’s left `[E]` box maps to the top of 1.4’s cafeteria box (clamped onto the floor); bottom maps lower. Other `[E]` doors use the same cache. Walk-off 1.2↔1.4 unchanged.
- Verification: `interact_arrival_check.gd` (2.1 t top≈0.12 / bot=1.0; 1.4 tex.y ~854 vs ~1376). `scene_smoke_check.gd`.
- Notes: Prefer clamp over redrawing 1.4’s cafeteria collider.

### 1.2↔1.4 spawn maps along ExitTrigger boxes
- Request: Walking 1.2→1.4 from the top of 1.2’s leave zone did not place Mike as high in 1.4. Spawn must be relative to each scene’s InteractArea / ExitTrigger, not scene size or floor-line Y.
- Implementation: Stopped copying `walkoff_floor_offset_y` (1.4 then clamped to floor+8, which pulled Mike down). 1.2 and 1.4 now save/restore `interact_arrival_t` along each `ExitTrigger` (same helper as `[E]` doors). 1.4 uses `basement_spawn_side="corridor_left"` for this peek.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/core/interact_arrival.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Top of 1.2’s right `ExitTrigger` maps to the top of 1.4’s left `ExitTrigger` (hitbox nudged out of walls only). Reverse path matches. `[E]` doors unchanged.
- Verification: `interact_arrival_check.gd` (1.4 corridor t=0 vs t=1 Y gap). `scene_smoke_check.gd`.
- Notes: `walkoff_floor_offset_y` remains on GameManager but is unused.

### Combat item descriptions wrap beside ITEMS
- Request: Item descriptions in the combat playtest UI were one long line over the grid. Move them next to the ITEMS list, wrap onto multiple lines, and fit them symmetrically to that list.
- Implementation: Replaced native tooltips with a hover card (`ItemDescOverlay`). Same width as the ITEMS panel when the gutter allows, wraps with word-smart autowrap, sits just left of the list, and stays vertically aligned with the hovered row inside the list bounds so it does not cover the grid.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Hovering an ITEMS row shows a wrapped description plaque next to the list. Combat rules, RNG, and scaffold nodes are unchanged.
- Verification: `combat_test_scaffold_check.gd`.
- Notes: Overlay is created at runtime (not saved in the scene).

### 1.2↔1.4 is the approved spawn-mapping example
- Request: 1.2→1.4 feel is exactly right; use it as the example for other rooms.
- Implementation: Canon now names `1.2`↔`1.4` `ExitTrigger` as the approved `InteractArrival` example. Other `[E]` / walk-off pairs should match that (top of leave box → top of arrive box; not scene size / floor Y).
- Files changed:
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/scenes/core/interact_arrival.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: None this pass — docs/helper comment only. Playtest other rooms against 1.2↔1.4.
- Verification: Docs updated; no runtime change.
- Notes: If another pair feels wrong, fix that pair to match 1.2↔1.4, do not change 1.2↔1.4.

### Combat item description hover polish
- Request: Keep wrapped item descriptions, but put the box to the right of the cursor, use an 80% black background, wrap less tightly, and fade in quickly instead of popping on.
- Implementation: Hover card now follows just right of the mouse, uses a wider wrap width, draws black at 80% opacity, and fades in over 0.08s (text swap while already open stays instant).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Description tooltip sits on the cursor’s right, reads as a see-through black box, and appears with a short fade. Combat rules unchanged.
- Verification: `combat_test_scaffold_check.gd`.
- Notes: If the box would go off the right edge of the window, it is clamped on-screen.

### Combat item description stays in ITEMS box
- Request: Description sat on top of the hovered item. Keep it below the cursor and that item, and do not draw outside the ITEMS panel.
- Implementation: Tooltip now opens under the cursor and under the hovered row. A clip layer matching the ITEMS panel keeps it inside that rectangle; width is capped to the panel so it cannot spill left or right.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Hover text no longer covers the item name. Near the bottom of the list, extra lines are clipped at the ITEMS edge instead of leaving the box.
- Verification: `combat_test_scaffold_check.gd`.
- Notes: ITEMS is a UI panel, not a `RectangleShape2D`; the clip uses that panel’s rectangle.

### Remaining LimeZu item icons baked
- Request: Pick LimeZu 48×48 icons for every remaining combat item, update `item_icon_sources.json`, then bake. Keep L2’s bedroom clock. Family A must not reuse that clock. `L-A` unused.
- Implementation: Mapped the rest of the catalog (families A–H plus uniques C1–C10 / U1–U8 / R1–R6 / E1–E4 / L1 / L3). Same path shared across C–E of one family. Baked noir 48×48 PNGs into `combat/art/item_icons/`.
- Files changed:
  - `AXEL/axel_project/tools/combat/item_icon_sources.json`
  - `AXEL/axel_project/combat/art/item_icons/*.png`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: ITEMS rows show distinct LimeZu icons instead of hatch placeholders. Combat rules unchanged.
- Verification: Bake from JSON; `L-A` still absent.
- Notes: Cluster sheets stay gitignored under `tools/combat/.icon_scan/`. Do not re-run `generate_item_resources.py`.

### Restore premium symbols + hollow red suits
- Request: First pass filled suits white and overwrote bottle/hand/skull/cigarette. Restore those four. Redraw square/triangle/star/heart as same-size simple outlines with no fill, matching stroke, from Unicode. Then make those outlines red and add a faint white halo on the premium/wild icons.
- Implementation: Restored the four 128×128 premium/wild PNGs from git. Rewrote `generate_placeholders.py` to carve hollow red rings from Unicode silhouettes (■ ▲ ★ ♥, stroke 7) for the four suit files only, then paint a 1px faint white halo on cigarette / bottle / hand / skull without redrawing them.
- Files changed:
  - `AXEL/axel_project/combat/art/generate_placeholders.py`
  - `AXEL/axel_project/combat/art/grid_symbols/green_circle.png`
  - `AXEL/axel_project/combat/art/grid_symbols/yellow_triangle.png`
  - `AXEL/axel_project/combat/art/grid_symbols/blue_star.png`
  - `AXEL/axel_project/combat/art/grid_symbols/red_heart.png`
  - `AXEL/axel_project/combat/art/grid_symbols/cigarette.png`
  - `AXEL/axel_project/combat/art/grid_symbols/booze.png`
  - `AXEL/axel_project/combat/art/grid_symbols/bloody_hand.png`
  - `AXEL/axel_project/combat/art/grid_symbols/satanic_wild.png`
  - `AXEL/axel_project/combat/README.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_design.md`
  - `AXEL/axel_project/plans/references/AXEL_notes.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Grid suits are hollow red. Premium/wild look as before, with a faint white edge. Combat RNG unchanged.
- Verification: Generator run; premium file sizes match restored art plus halo.
- Notes: Re-running the script is safe for premium/wild (halo is idempotent). It still overwrites the four suit PNGs.

### Thicken thin room-edge walls
- Request: Mike’s drawing walked through kitchen 2.3 `LeftWall` and other thin room-edge walls. Compute the minimum inset from the Front circle + walk sprite (scale per room). Thicken only walls that are too thin. Skip 2.4 (already fixed) and walk-off / Ending-1 exits.
- Implementation: Added `wall_sprite_clearance_check.gd`. Grew too-thin `LeftWall` / `RightWall` / `TopWall` / `BottomWall` from the PNG edge inward with unique shapes. Kitchen LeftWall was the first fix, then the same pass on 1.1 (Top only), 1.2, 1.4, 2.1, 2.3, 3.1, 4.1, 5.1.
- Files changed:
  - `AXEL/axel_project/tools/qa/wall_sprite_clearance_check.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.tscn`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike’s feet still stop at the wall; his drawing no longer sticks past the room edge. Walk-off 1.2↔1.4 and 1.1 left exit unchanged. 2.4 untouched.
- Verification: `wall_sprite_clearance_check.gd` → `WALL_SPRITE_CLEARANCE OK`.
- Notes: The circle was never missing — the sprite is larger than the circle. Furniture blockers are not this rule.

### Docs sync — rest of 2026-08-25
- Request: `update todays docs` after the afternoon implement chats (icons, spawn mapping, item hover, symbols, walls).
- Implementation: Canon now matches the later passes: remaining LimeZu icons, ITEMS hover card, hollow red suit symbols + premium halo, and room-edge wall clearance (checker + skip list). Scale/speed, `InteractArrival`, and 1.2↔1.4 as the spawn example were already in the morning changelog.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_design.md`
  - `AXEL/axel_project/plans/references/AXEL_notes.md`
  - `AXEL/axel_project/combat/README.md`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only. Gameplay unchanged.
- Verification: Compared write-ups to live `item_icon_sources.json`, `generate_placeholders.py`, `wall_sprite_clearance_check.gd`, `combat_test.gd` hover overlay, and today’s chats after the last morning changelog entries.
- Notes: Morning changelog already had scale/speed, `[E]` arrival, and ITEMS hover polish; this pass logged the three missing afternoon ships and leftover stale combat/scene text.

### 2.1 kitchen return — spawn below TopWall
- Request: Leaving kitchen 2.3 into cafeteria 2.1 spawned Mike outside the top wall. Move the landing down to around `KitchenInteractArea`.
- Implementation: Kitchen return still maps onto `KitchenInteractArea` via `InteractArrival`. `KITCHEN_PEEK_MARGIN_PX` went from `-88` (pulled up through `TopWall`) back to `12` (just below the interact box, same into-room peek as the other 2.1 doors).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Returning from 2.3 places Mike on the cafeteria floor at the kitchen door, not above `TopWall`. Fresh Play / F6 still uses the Player node.
- Verification: `interact_arrival_check.gd` (room-to-room mapping unchanged; this is a peek-margin tweak).
- Notes: The old `-88` was a 100px-up tweak from before thicker walls and the larger 2.1 Mike.

## 2026-08-27

### Combat piece art inverted to canon colors
- Request: Piece PNGs were painted white-on-black, so under room noir the lines went black and the fill went red. Wanted: red lines, black fill.
- Implementation: Added `tools/invert_drawing_colors.gd` — backs up originals to `exports/Drawings/backup_pre_invert/` (with `.gdignore`), skips already-bright files, inverts RGB where alpha > 0. Ran once on the ten combat drawings (grid/history/items/bets/goal/multiplier/exit + skulls 1–3). No scene edits. White plate and retired `axel_ui.png` untouched.
- Files changed:
  - `AXEL/axel_project/tools/invert_drawing_colors.gd`
  - `AXEL/axel_project/exports/Drawings/axel_combat_*.png` / `axel_skull_*.png` (in place)
  - `AXEL/axel_project/exports/Drawings/backup_pre_invert/` (pre-invert copies)
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Look only under FX. Fight math/widgets unchanged. Editor (no FX) now shows black ink on white fill — correct authoring.
- Verification: `combat_test_scaffold_check.gd`; second invert run skipped all 10.
- Notes: HUD text still left as-is (dim under noir). Re-run the invert tool if a new white-on-black export lands in `exports/Drawings/`.

### Combat HUD piece drawings + room FX test flag
- Request: Replace the single `axel_ui.png` combat background with a white plate + one node per drawing from `exports/Drawings`, keep live widgets on top, place three skull stages for a feel-only premium meter, and turn on overworld room FX for combat behind a flip-off flag.
- Implementation: Added `axel_combat_plate_white.png` (3508×2480) and pointed `HudArt` at it. Inserted `HudPieces` (ArtGrid/History/Items/Bets/Goal/Multiplier/Exit) and `PremiumSkull` (Glow + SkullStage1/2/3 + `premium_skull_meter.gd`). Side bars white. `AxelPostFxStack.COMBAT_ROOM_FX_TEST` gates room post-FX + event FX on `res://combat/*`; local `ScanlineOverlay` hides when the flag is on. Hid `GridFrame` so it does not double the drawn grid. `AI_DOCS` combat FX exclude rule unchanged (flag is temporary).
- Files changed:
  - `AXEL/axel_project/exports/Drawings/axel_combat_plate_white.png`
  - `AXEL/axel_project/tools/make_white_plate.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/premium_skull_meter.gd`
  - `AXEL/axel_project/combat/scenes/combat_root.tscn`
  - `AXEL/axel_project/scripts/autoload/axel_post_fx_stack.gd`
  - `AXEL/axel_project/scripts/autoload/axel_event_fx.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Look + FX test only. Spin/items/score/RNG unchanged. Skull not wired to meter or EXECUTE. Flip `COMBAT_ROOM_FX_TEST := false` to restore the old combat-only scanline.
- Verification: `combat_test_scaffold_check.gd`
- Notes: Piece sizes do not match widget boxes yet — drag-align in the editor. Frame PNG black insides will invert to red under room FX (expected).

### Combat HUD on axel_ui drawing
- Request: Keep combat fight rules the same, but put the HUD on the combat drawing and make widgets drag-placeable in the editor. See-through computer chrome; show the whole drawing (empty bars OK).
- Implementation: Added `%HudCanvas` (3508×2480) + `HudArt` under `combat_test.tscn` using `res://exports/Drawings/axel_ui.png`. Reparented HUD widgets under the canvas; converted `PlayRow` / `CenterColumn` / `CenterFooter` to plain Controls so editor offsets stick. Removed percentage `LAYOUT_*` placement and EXECUTE width-to-grid resize. Runtime only scales/centers `HudCanvas`. HISTORY/ITEMS/EXECUTE chrome is see-through. QA checks HudCanvas containment + fit instead of old percentage anchors.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/test/combat_test_scaffold_check.gd`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Look + editor placement only. Spin/items/score/RNG unchanged. Drag widgets inside `HudCanvas` in the 2D editor; Play keeps them.
- Verification: `combat_test_scaffold_check.gd`, `determinism_check.gd`, `scene_smoke_check.gd`
- Notes: Drawing file is `axel_ui.png` (middle/bottom skull variants removed).

### 2.1 kitchen return — drawing below TopWall
- Request: 2.3 → 2.1 still spawned Mike outside the top collision border (the Aug 25 peek-margin revert did not hold visually).
- Implementation: `KitchenInteractArea` sits in the ceiling band, so `BOTTOM+12` lands the feet circle inside the room but Mike’s tall drawing still crosses `TopWall`. After kitchen place, `InteractArrival.nudge_drawing_below_top_wall` pushes him down until sprite/shadow sit below the wall (geometry, not physics). Same nudge on other 2.1 door clamps. Peek margin stays `12`.
- Files changed:
  - `AXEL/axel_project/scenes/core/interact_arrival.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Returning from the kitchen places Mike on the cafeteria floor at the kitchen door, with the walk drawing below `TopWall`. Fresh Play / F6 still uses the Player node.
- Verification: `interact_arrival_check.gd` (new 2.3→2.1 TopWall drawing/hitbox check at t=0 / 0.5 / 1).
- Notes: Aug 25 only changed `KITCHEN_PEEK_MARGIN_PX` `-88` → `12`. That was already in git; the box is still too high for this Mike size.

### 3.1 backyard — player 40% larger
- Request: Increase player scale in scene 3.1 by 40%, and update `SCENE_BUILDING.md`.
- Implementation: Authored Player scale `0.198` → `0.277` (40% larger, three decimals). Baked speed from `PlayerWalkSpeed.from_scale` to `241.0`. Grew 3.1 `LeftWall` / `RightWall` / `BottomWall` from the PNG edge inward so the larger drawing stays on the room (`TopWall` already passed). Scale table in `SCENE_BUILDING.md` updated.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike is 40% larger in the backyard; walk speed scales with him. Other rooms unchanged. Cover-sync still uses the 1920×1280 baseline (not retuned for a window).
- Verification: `wall_sprite_clearance_check.gd` — 3.1 Left/Right/Top/Bottom all `PASS` at the new scale.
- Notes: Shared rooms stay `0.198` / `185.3`. 2.1 / 5.1 stay 50% larger.

### 4.1 lounge — Mike +30% size
- Request: Increase 4.1 player model size by 30% and update `SCENE_BUILDING.md`.
- Implementation: Raised authored Player scale in `4.1_TeachersLounge.tscn` from `0.198` to `0.257` (`0.198 × 1.3`, three decimals). Walk speed from `PlayerWalkSpeed.from_scale` is `226.9` (still below `0.3`, so the small-scale extra applies). Grew 4.1 edge-wall polygons inward to the new required inset (Left 128, Right 123, Top 269, Bottom 150) so the bigger drawing stays on the PNG. Other rooms unchanged. Cover-sync still multiplies authored scale by `live_cover / 1920×1280 baseline`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC4.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Mike is 30% larger in the teachers’ lounge; walk speed scales with him. Edge walls are a bit thicker. Fresh Play / F6 spawn is still the Player node.
- Verification: `player_walk_speed_check.gd`, `wall_sprite_clearance_check.gd` (4.1 walls)
- Notes: Did not retune for a window or monitor. Full wall checker still reports other rooms (missing 1.2/5.1 drawings, pre-existing 2.1/2.3 insets).

### Independent CollisionShape2D (no linked resize)
- Request: 3.1 `DoorSideRight` and `DoorSideLeft` resized together; add a SCENE_BUILDING rule that every `CollisionShape2D` must work as an individual, and fix it.
- Implementation: Gave 3.1 left/right door blockers their own `RectangleShape2D` SubResources (they had been sharing `RectangleShape2D_door_side_right`). Same split for 1.4 `LeftWall` / `RightWall` (`wall_vertical` was shared). Strengthened the SCENE_BUILDING independent-collider rule and added a headless scan.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.tscn`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.tscn`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/tools/qa/collision_shape_unique_check.gd`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Editor size/scale on one door or wall no longer changes the other. Play collision sizes stay as they were at the split. Mike `hitbox_front.tres` still shared on purpose.
- Verification: `collision_shape_unique_check.gd`
- Notes: After duplicating a collider, Inspector → shape → **Make Unique**.

### Combat editor-only axel_ui placement guide
- Request: Insert `exports/Drawings/axel_ui.png` into the combat editor as a phase background, but disable it in game so it is only used to place art nodes.
- Implementation: Added `%HudArtGuide` under `HudCanvas` (behind `HudPieces`, same 3508×2480 size as the white plate). `combat_test.gd` hides it whenever Play / headless runs (`Engine.is_editor_hint()` false). Fight widgets and piece nodes unchanged.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 2D editor shows the composite drawing for lining up pieces. F6 / shipped combat still uses the white plate + individual drawings only.
- Verification: `combat_test_scaffold_check.gd` still flags a pre-existing `%SpinButton` origin outside HudCanvas (layout in progress; not caused by this guide).
- Notes: Guide is a background under the piece nodes. Hide `HudPieces` in the scene tree if you need to see the full composite first.

### 1.3 locker hub / school map — Esc, Backspace, Delete exit
- Request: In 1.3, Esc, Backspace (`←`), and Delete should leave the scene the same way as the red `X` (not only the button).
- Implementation: Hub and school map now listen for those keys in `_input` and call the existing exit path. Hub interrupt-stops first-visit dialogue if you leave mid-line. Red `X` is unchanged.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.3_LockerHub.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.3_SchoolMap.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Locker hub: Esc / Backspace / Delete returns to the corridor. School map: same keys return to the locker hub. Travel buttons still go to their rooms.
- Verification: Manual — F6 `1.3_LockerHub.tscn` / `1.3_SchoolMap.tscn` and press Esc, Backspace, Delete, and click `X`.
- Notes: Keys are handled in `_input` so they still work if a travel button has focus.

### 2.1 kitchen return — stand at door (~2040×180)
- Request: After the TopWall drawing nudge, 2.3 → 2.1 placed Mike too low. Spawn should be around texture `2040×180`.
- Implementation: Kitchen return now stands the Player node on `KitchenInteractArea`’s center (that point is ~2044×181) and maps X from leave `t`. Removed `nudge_drawing_below_top_wall` and the kitchen wall clamp (those were the extra downward push). Fresh Play / F6 still uses the Player node.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/core/interact_arrival.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Returning from 2.3 puts Mike at the cafeteria kitchen door, not on the floor below it.
- Verification: `interact_arrival_check.gd` (2.3→2.1 node tex y~180, x follows t).
- Notes: Not a hardcoded `Vector2` — the number matches the kitchen `[E]` box center. Sprite may overlap `TopWall`; that is the requested stand spot.

### 2.1 kitchen return — raise stand to ~2040×150
- Request: Raise the 2.3 → 2.1 stand from ~2040×180 to ~2040×150.
- Implementation: Kitchen return still maps X along `KitchenInteractArea` from leave `t`, then sets Player node texture Y to `150`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Returning from the kitchen puts Mike a bit higher at the doorway.
- Verification: `interact_arrival_check.gd` (2.3→2.1 node tex y=150).
- Notes: Fresh Play / F6 still uses the Player node.

### 5.1 Classroom — restore missing drawing (red CRT field)
- Request: Opening 5.1 showed a solid dark-red CRT field instead of the classroom drawing (same missing-file pattern as 1.2).
- Implementation: Copied `5.1_Classroom_v2.png` back onto the canonical `5.1_Classroom.png`, reimported, and wrote the new texture uid into the scene. Cleared `Camera2D.static_center = (560, 0)` so the room art-centers like 4.1. Also `git restore`d tracked `1.2_Corridor.png` + `.import` (did not promote `_New`). Left thinned edge walls as the user last saved them.
- Files changed:
  - `AXEL/axel_project/exports/Drawings/5.1_Classroom.png` (+ `.import` via reimport)
  - `AXEL/axel_project/exports/Drawings/1.2_Corridor.png` (+ `.import`)
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 5.1 cover-fit and camera limits work again; Play shows the classroom plate, not an empty red field. 1.2 corridor drawing is back. Camera no longer pins to the top-left of the plate.
- Verification: `wall_sprite_clearance_check.gd` loads 5.1/1.2 backgrounds (no longer “missing nodes”); `scene_smoke_check.gd` OK (includes 1.2). Wall inset FAILs on 5.1 remain from the saved thinner walls — out of scope.
- Notes: Drawings under `exports/` are gitignored (except force-tracked 1.2). F6 5.1 in the editor to confirm the live view.

### Combat HudArtGuide 50% editor opacity
- Request: `%HudArtGuide` in `combat_test` should be 50% opacity live in the Godot editor.
- Implementation: Set `HudArtGuide.self_modulate` alpha to `0.5` in the scene so the 2D viewport shows it immediately. The `@tool` script keeps that 50% while editing and still hides the guide on Play / headless.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: 2D editor shows a see-through composite for lining up pieces. F6 / shipped combat still hide the guide.
- Verification: `combat_test_scaffold_check.gd`
- Notes: Guide stays behind `HudPieces`. Opacity is editor-only; Play does not draw it.

### Non-frozen [E] arrivals land inside the dest box
- Request: 2.1 → 2.4 spawned Mike outside `CafeteriaInteractArea` / through `TopWall`. Want: keep t-slide along the dest `[E]` box, stay inside that live box, keep the whole walk drawing on the floor. Frozen trips unchanged. Map/hub still use the Player node.
- Implementation: Added `place_in_area` / `apply_arrival_inside` / `resolve_inside_clearance` / `_sprite_blocked` to `InteractArrival` (frozen `place_on_area` + `clamp_hitbox_to_walls` untouched). Swapped non-frozen doors onto inside-box: 2.4 (cafeteria/lounge/classroom), 2.1 (classrooms/backyard), 3.1, 4.1, 5.1. 2.4 no longer re-applies cover/depth after place. Headless lock covers 2.1↔2.4 in-box + TopWall drawing clear + t monotonic. Canon: `AI_DOCS.md` / `SCENE_BUILDING.md` — frozen peek kept for 1.2→1.4 / 1.4→2.1 / 2.1→2.3; non-frozen = inside box. Kitchen return stays Player-node Y `150` / skip clamp (live; earlier ~180 write-up is historical).
- Files changed:
  - `AXEL/axel_project/scenes/core/interact_arrival.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Non-frozen door arrivals follow the live `[E]` box (editor drags work on Play). 2.1→2.4 keeps Mike inside the cafeteria door box with the drawing below TopWall. 4.1 may sit just below its box when that box is buried in TopWall (Option B).
- Verification: `interact_arrival_check.gd` (includes 2.1↔2.4); manual 2.1↔2.4 left/mid/right + one frozen trip.
- Notes: Press-E doors already use zone grace; no walk-off bounce. Rollback = switch one room back to `apply_arrival` / `place_on_area`.

### Combat HUD: one movable piece per drawing
- Request: Each combat playtest readout (settings, goal, items, history, bets, execute/skull, multiplier, spin-money, premium-bar) should be its own easy-to-move/scale/animate piece with text inside the shape; wire Settings (Dev Tools only), sliding bet strip, skull-starts-spin, real skull meter, spin-money + color premium bar.
- Implementation: Added `CombatHudPiece` (`hud_piece.gd`) with clipped `TextBox`, alpha hit, `attach()` / `pop()`. Wrapped drawings in `combat_test.tscn`. Runtime `_bind_widgets_to_pieces()` re-homes protected widgets. Settings panel scene (layer 200); Dev Tools calls `AxelCombatDevTools.open_dev_menu()`. Pass B: sliding `|` bet strip, guarded `_request_spin()` from button/skull/piece, skull fill + `0/3` from meter, `1X` multiplier, `PiecePremiumBar` / `PieceSpinMoney`, legacy `PremiumProgressBar` hidden.
- Files changed:
  - `AXEL/axel_project/combat/scripts/hud_piece.gd`
  - `AXEL/axel_project/combat/scripts/combat_settings_panel.gd`
  - `AXEL/axel_project/combat/scenes/combat_settings_panel.tscn`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/premium_skull_meter.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd` (`get_bet_index`)
  - `AXEL/axel_project/scripts/debug/axel_combat_dev_tools.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Designer drags pieces; live text follows. Spin/RNG/determinism unchanged aside from HUD input routing (busy guard).
- Verification: `combat_test_scaffold_check.gd`, `determinism_check.gd`, `qa_canon_validators` via scaffold.
- Notes: Text uses inner rectangle + clip (not polygon wrap). Drag each piece’s `TextBox` to fit angled art.

### First [E] after a door always bounces you back
- Request: After an `[E]` door takes you into a new room, the first `[E]` should send you straight back if you are still on that door (every room-to-room pair). If arriving starts a talk bar, the `[E]` chip stays off until the bar is fully finished.
- Implementation: Added shared `InteractZoneGate` (`body_in_area`, `dialogue_busy`, `movement_pressed`). Rooms poll live overlap instead of trusting `body_entered` after teleport; arrival latch keeps the land door active until first WASD (covers frozen peeks outside the box). 0.15s grace is press-only (chip may show). Chip + door `[E]` gated on talk busy / enter-dialogue pending. Kitchen/cafeteria/1.4 peeks wait two physics frames before place (like 2.4). Arrival check asserts Front inside `KitchenInteractArea` on 2.3→2.1.
- Files changed:
  - `AXEL/axel_project/scenes/core/interact_zone_gate.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Stand on the arrival door and press `[E]` once to go back. No chip / no door leave while enter lines (or CRT) are still running. Frozen peeks unchanged.
- Verification: Godot binary not on PATH this session — run `interact_arrival_check.gd` + manual door pairs locally.
- Notes: Rollback = delete `interact_zone_gate.gd` and revert per-room scripts. No `.tscn` / geometry changes.

### Combat HUD: hide leftover computer indicators
- Request: After the piece HUD, remove the old indicators (black number pills, thin meter bar, CombatRoot multiplier/winnings labels, gear/home/? row, boxed +/-).
- Implementation: Hid `PremiumProgressBar`, `WinningsCenter`, CombatRoot `MultiplierLabel` / `RoundWinningsLabel`. Bind attaches the labels themselves (not the black pills). +/- stay empty-styled when bet pieces exist. Old bar is no longer laid out when `PiecePremiumBar` is present.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scenes/combat_root.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Look only. Protected unique nodes stay in the tree. Fight math unchanged.
- Verification: `combat_test_scaffold_check.gd`
- Notes: Scaffold names were hidden, not deleted.

### Chat workflow: Implement uses the chat-picked model
- Request: Apply the Plan **Build** model rule in `AI_DOCS.md` — Implement should use the model currently picked in chat, not Auto / Cursor Grok.
- Implementation: Changed the Chat workflow Implement row to **Model currently picked in chat**, and noted that Plan **Build** should use that same picker (not Inherit if the chat picker flipped to Auto).
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only. Implement / Build should follow the chat model, not a hardcoded Auto / Grok default.
- Verification: Read the Chat workflow table after the edit.
- Notes: Cursor can still flip the chat picker to Auto after a plan; pick the model again on the Build row.


### Arc 4: key pickup, teachers memory, grey police voice
- Request: In 4.1, walk-near key plays 4.3 once; smaller `[E]` picks up key like kitchen flashlight; memory glow + `[E]` opens 4.2 white still with light-grey police lines; after leaving 4.2 play `Liar.` back in the lounge. Key and memory either order. Keep bench ink for now.
- Implementation: Added `|grey|` marker + light-grey color to `TopDialogueOverlay` (wins over red). GameManager once-ever `teachers_key_line_seen` / `teachers_memory_line_seen` / `teachers_liar_line_seen` plus `teachers_lounge_memory_return_pos`. Rebuilt 4.2 as a 2.2/3.2-style still on a white plate. Wired 4.1 `KeyNearArea` / `KeyInteractArea` / `MemoryInteractArea` / `MemoryIndicator` (`hasKey` + inventory `Teacher Key`; `add_memory_once("teachers_memory")`).
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.2_TeachersMemory.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.2_TeachersMemory.tscn`
  - `AXEL/axel_project/scenes/Arc_4/4.2_teachers_memory_frame.gd`
  - `AXEL/axel_project/exports/Drawings/4.2_Teachers_Memory.png`
  - `AXEL/axel_project/tools/make_teachers_memory_white_plate.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC4.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Lounge key + memory loop works end-to-end; police voice is light grey without a `POLICE:` tag; enter glitch stays shared 0.65s.
- Verification: Godot binary not on PATH this session — drag Key/Memory zones in editor, then F6 4.1; run `collision_shape_unique_check.gd` + `scene_smoke_check.gd` locally when Godot is available.
- Notes: Follow-up — `KeyVisual` overlay to hide bench ink after pickup. Zone/glow positions are starting guesses for the player to drag.

### Combat HUD: hide old indicators again
- Request: Old bar / number pills came back after an editor save. Hide them again. Also stop forcing `%HudArtGuide` on in the 2D editor.
- Implementation: Set `PremiumProgressBar`, `WinningsCenter`, winnings/multiplier pills, and `MetaIconsRow` to `visible = false` in the scene. Play re-hides them after layout. `%HudArtGuide` starts hidden; the `@tool` script no longer turns the eye back on.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Editor and Play show piece drawings without the leftover computer bar/pills. Toggle the HudArtGuide eye if you want the composite overlay.
- Verification: Scene flags; Play still re-hides after layout.
- Notes: Saving the scene in Godot can restore `visible` if those nodes are selected and shown — keep the eye off on the old bar and `WinningsCenter`.

### Combat HUD: NEW_ names for movable pieces
- Request: Name the nodes the designer should drag with a `NEW_` prefix.
- Implementation: Renamed piece frames in `combat_test.tscn` (`NEW_Goal`, `NEW_Items`, `NEW_History`, `NEW_Bets` + bet sub-pieces, `NEW_Multiplier`, `NEW_Settings`, `NEW_PremiumBar`, `NEW_SpinMoney`, `NEW_Execute`, `NEW_Grid`). Lookups in `combat_test.gd` follow the new names.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Scene tree only. Drag `NEW_*`, not the old widget names.
- Verification: Name lookups only; protected unique names (`%SpinButton`, …) unchanged.
- Notes: Inner `TextBox` is still the text-fit box under each `NEW_` piece.

### Combat HUD: MOVE_ names for interactables
- Request: Art `NEW_` pieces are placed; name the interactable nodes the designer should still drag with `MOVE_`.
- Implementation: Renamed text boxes to `MOVE_TextBox`, bet overlays to `MOVE_BetMinus` / `Plus` / `BetStrip` / `Balance`, `MOVE_PremiumBar`, `MOVE_SpinMoney`, `MOVE_MeterCount`. `hud_piece.gd` looks up `MOVE_TextBox`. Art `NEW_` names unchanged.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/hud_piece.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Scene tree labels only. Drag `MOVE_*` to line up clicks/text; leave `NEW_*` art where it is.
- Verification: Lookups follow `MOVE_` names; protected unique names unchanged.
- Notes: `NEW_Settings` / `NEW_Execute` stay `NEW_` because they are the art frames (clicks are on those pieces).

### Scene 5.1 — furniture 6–9 behind filters
- Request: FurnitureBlocks 6 to 9 need a behind filter in scene 5.1.
- Implementation: Added `FurnitureBlock6_Behind` … `FurnitureBlock9_Behind` (`leaf_occlusion_zone.gd`, `feather_px = 2`) under `EnvironmentColliders`, starter polygons copied from those four furniture blockers. `5.1_Classroom.gd` fills four shader slots after cover-fit. Y-gate uses each FurnitureBlock collision front so fade happens only when standing behind, not in front.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Walking behind furniture 6–9 fades Mike through the desks. Drag the green behind polygons in the editor to match the drawing; walk-blockers stay separate.
- Verification: Scene node names + script slot wiring. Drag polygons in 5.1, then F6 and walk behind those four desks.
- Notes: Furniture 1–5 have no behind filter yet. Shader max is 6 slots.

### Scene 5.1 — board glow is a kitchen-style outline, not the memory blob
- Request: The board should not use the MemoryIndicator blob. It should glow like the 2.3 kitchen flashlight. Add a faint glow outlines node to set up around the board by hand.
- Implementation: Removed `PlayerLayer/MemoryIndicator`. Added `WalkableWorld/EnvironmentColliders/BoardGlow/Outline` (`Line2D`, closed, black ink, `prop_line_halo.gdshader`) so noir remaps it to a faint red pulse like `FlashlightVisual`. Starter rectangle sits on the back wall; drag the line points in the 2D view onto the painted board. Covers with the room (no PlayerLayer scaler).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/scenes/fx/prop_line_halo.gdshader`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Classroom no longer shows the white memory blob. A faint pulsing outline is there to drag around the board. Board `[E]` / 5.3 still not wired.
- Verification: Scene tree `BoardGlow/Outline`; Play shows a slow alpha pulse. Drag points in the editor onto the chalkboard.
- Notes: Line2D does not need a board PNG. Hide this node later when the Name item is collected.

### Combat HUD: live widgets above room FX, aligned to MOVE_TextBox
- Request: Numbers / lists / +/− / symbol squares and click targets should sit on the MOVE_TextBox boxes. Live computer widgets above invert/CRT/pulse; drawings stay under FX. Spinning squares follow the drawn grid. Skull click = TextBox + editable polygon.
- Implementation: Added `WidgetLayer` (`CanvasLayer` 115) + `hud_widget_layer.gd` follower hosts. Bind reparents widgets into hosts that copy each `MOVE_TextBox` global rect. `NEW_Grid` got `MOVE_TextBox` + piece script; `GridHost`/`%CombatRoot` live under `WidgetRoot`. Clickable pieces hit only the TextBox rect; skull Control is mouse-ignore; `SkullClickPolygon` + shared spin guard. `COMBAT_ROOM_FX_TEST` stays on (temporary; AI_DOCS still excludes combat from production post-FX).
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/hud_piece.gd`
  - `AXEL/axel_project/combat/scripts/hud_widget_layer.gd`
  - `AXEL/axel_project/combat/scripts/skull_click_polygon.gd`
  - `AXEL/axel_project/combat/scripts/premium_skull_meter.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/tools/qa/qa_canon_validators.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Widgets stay readable above noir/CRT; grid fills the drawn grid box; Settings/Execute clicks use TextBox (+ skull polygon). Drag `NEW_Grid/MOVE_TextBox` and `SkullClickPolygon/Polygon` vertices to refine.
- Verification: F6 combat test; resize window; scaffold / determinism / princess headless checks.
- Notes: Widgets are clean (no grain) by design for now. Production post-FX still excludes `res://combat/*`.

### Round-TV CRT — glued fringe, dark glass rim, flat combat
- Request: When Mike or room ink sits near the left/right of the window, CRT red/green/blue copies stretch off the drawing; center looks fine. Wanted: same window (no crop/zoom/view move); sides/top/corners feel like a round TV with a dark glass rim; fringe stays glued. Combat gets the edge fix but must stay flat (no TV vignette).
- Implementation: Reworked `crt_plugin_overlay.gdshader` — one aspect-corrected shared barrel; masks/RGB split at the warped UV; mix uses bent source (no unbent/bent double); edge-reflected chroma taps (no clamp smear); darkening last from raw window position + soft rim fade. New knobs `edge_fade_px` / `corner_darkness` / `corner_radius` (inert at `0`). Overworld `CrtPluginOverlay.tscn` obvious preset (`curvature` `0.16`, `vignette` `0.4`, `edge_fade_px` `26`, `corner_darkness` `0.65`, `corner_radius` `0.55`). New flat `CrtCombatOverlay.tscn` (all geometry/darkening `0`); `AxelPostFxStack` picks it for `res://combat/*`. Pulse overlay zeros curvature/chroma/vignette; `option_1_crt_tv` clamps lookups instead of painting black outside 0..1.
- Files changed:
  - `AXEL/axel_project/scenes/fx/crt_plugin_overlay.gdshader`
  - `AXEL/axel_project/scenes/fx/CrtPluginOverlay.tscn`
  - `AXEL/axel_project/scenes/fx/CrtCombatOverlay.tscn`
  - `AXEL/axel_project/scripts/autoload/axel_post_fx_stack.gd`
  - `AXEL/axel_project/scenes/fx/InterfacePulseOverlay.tscn`
  - `AXEL/axel_project/tools/visual_style/shaders/option_1_crt_tv.gdshader`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/references/AXEL_OVERWORLD_EVENT_FX.md`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Overworld/menu read as a round TV with darker corners and a soft dark rim; Mike and room ink keep one silhouette with glued RGB fringe. Combat stays square and flat but loses the stretched side color bars. Pulse still adds scan/roll/noise without a second warp.
- Verification: Headless scene smoke + combat scaffold. Eyeball 1.1 edges/center/corners, cadence surge, menu, a `margin_px` room, and combat flat + clean edges.
- Notes: Subtle overworld preset (dial back later via `.tscn` only): `curvature` `0.08`, `vignette` `0.3`, `corner_darkness` `~0.3`, `edge_fade_px` `~16`, `corner_radius` `0.55`. Keep `chroma`/`player_chroma`/`player_crt_reduction`/`player_white_boost` as shipped.

### Fix white CRT screen (shader compile + darkening scale)
- Request: Scene 1.1 (and every other scene) opened to a full white window with only faint CRT scanlines.
- Implementation: Root cause — `crt_plugin_overlay.gdshader` read `SCREEN_PIXEL_SIZE` inside `curve_uv()` / `rim_fade()`, which Godot forbids outside `fragment()`, so the shader failed to compile and the full-screen `FilterRect` fell back to its white `color`. Pass `aspect` / `px` into those helpers from `fragment()`. Also normalize darkening to radius 0 at centre / 1 at corners (old aspect-corrected `dot(d,d)*4` crushed sides/corners to black). Retuned overworld to `vignette` `0.45`, `corner_darkness` `0.45`, `corner_radius` `0.7`. Both CRT overlays use transparent `FilterRect` color so a future compile failure blanks the effect instead of painting the window white. Added `tools/qa/shader_builtin_scope_check.gd` (headless static guard); documented that `--headless` never compiles shaders.
- Files changed:
  - `AXEL/axel_project/scenes/fx/crt_plugin_overlay.gdshader`
  - `AXEL/axel_project/scenes/fx/CrtPluginOverlay.tscn`
  - `AXEL/axel_project/scenes/fx/CrtCombatOverlay.tscn`
  - `AXEL/axel_project/tools/qa/shader_builtin_scope_check.gd`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Rooms and menu show the picture again with round-TV CRT; combat stays flat. Corners darken softly instead of going pure black.
- Verification: `SHADER_BUILTIN_SCOPE OK`; windowed `--quit-after` on menu / 1.1 / combat_test with no `SHADER ERROR`; scene smoke OK; combat scaffold OK.
- Notes: Subtle preset on the corrected scale: `curvature` `0.08`, `edge_fade_px` `16`, `vignette` `0.3`, `corner_darkness` `0.2`, `corner_radius` `0.75`.

## 2026-08-27

### 1.1→1.2 door spawn maps along InteractAreas
- Request: Pressing `[E]` in 1.1’s door InteractArea always spawned Mike at the same 1.2 spot. Standing higher in 1.1’s box should land higher in 1.2’s `ExteriorInteractArea` (same mapping as other `[E]` rooms).
- Implementation: 1.2 was placing the exterior arrival with frozen peek (`place_on_area`) and clearing the pending flag before cover-fit finished, so height `t` was lost and spawn stuck on the Player node. Cache `t` in `_ready`, keep pending until layout, then `apply_arrival_inside` on the live `ExteriorInteractArea` (Y follows `t`, into-room edge RIGHT). Frozen 1.2↔1.4 walk-off unchanged. Reverse 1.2→1.1 still peeks.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Top of 1.1’s door `[E]` box maps to the top of 1.2’s left `[E]` box; bottom maps lower. Fresh Play / F6 still uses the Player node.
- Verification: `interact_arrival_check.gd` (1.1 door t span + 1.1→1.2 Y follows t).
- Notes: 1.2→1.1 not changed this pass.

### Re-derive combat HUD piece placement from the mockup
- Request: After the previous “move combat phase items” pass, every HUD element was wrongly placed in the game window; find the easiest correct fix, recreating pieces if that gives the best quality.
- Implementation: Root cause was a single node — `%HudArtGuide` was offset ~-105px and stretched ~6% wide, and every `NEW_*` piece had been eyeballed against that bad guide, so the whole HUD inherited the same shift and scale error. Instead of re-dragging by hand, template-matched each piece PNG against `exports/Drawings/axel_ui.png` at 1:1 to recover exact plate rects, then rewrote them in `combat_test.tscn`. Guide and `HudPieces` reset to `0,0` / `3508×2480`; every piece put back at its native texture size (stretch was blurring the line work); `MOVE_TextBox` insets, bet `+`/`-`/strip/balance, premium bar and spin money re-measured from the drawn artwork; `NEW_Execute` rejoined to the 692×922 skull frame with all three `SkullStage` children at `0,0` and the click polygon retraced on the `axel_skull_3` silhouette. In `combat_root.gd`, dropped the `PANEL_FILL_CELL_MAX = 128` cap and taught `fit_to_panel` / `_apply_slot_min_size` to use per-axis `Vector2` cell sizes so the 5×5 fills the rectangular cell area actually drawn on `axel_combat_grid.png` (`combat_test.gd`’s fallback path mirrors this). Bet strip now full-rects after reparent and centers via `_animate_bet_strip()` on bind, so it is no longer blank on first frame.
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/tools/qa/hud_piece_placement_check.gd`
  - `AXEL/axel_project/tools/qa/hud_layout_probe.gd`
  - `AXEL/axel_project/tools/qa/hud_capture.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/tools/qa/README_gd_scripts.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: The combat HUD matches `axel_ui.png` 1:1 — goal, items, bets, balance, grid, multiplier, history and skull all sit on their drawings, symbols fill the drawn cells, and the bet strip reads `100 | 200 | 300` from the first frame.
- Verification: New `hud_piece_placement_check.gd` OK (8 pieces on plate) and confirmed to fail when the guide is nudged -105px; scaffold, determinism, princess and scene smoke checks all exit 0; `hud_capture.gd` render overlaid against `axel_ui.png` line art shows every mockup stroke landing on the rendered art.
- Notes: Two elements sit outside the drawings by design, not by drift — the `*` dev-tools wrench (debug-only autoload button at screen `8,8`) and `MOVE_MeterCount` (`0/3`), which is authored below the skull and is only covered by ink once the meter reaches stage 3.

### 5.1 classroom enter lines + desk [E]
- Request: 5.1 still did not play enter dialogue on F6 or when coming from the corridor, and the desk InteractArea did not work.
- Implementation: The talk bar CanvasLayer was hidden with the editor eye (`visible = false`), so `show_lines` ran but never drew — and while it was “busy,” desk `[E]` stayed off. Force the overlay layer on in `TopDialogueOverlay._ready` / `show_lines` (only the inner bar starts hidden). Unhid 5.1 and 2.1 instances. Desk: keep monitoring on until seen, wake Area2Ds after cover-fit, and `InteractZoneGate` now also tests the Front circle against the live box if physics overlap is empty.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.tscn`
  - `AXEL/axel_project/scenes/core/interact_zone_gate.gd`
  - `AXEL/axel_project/scenes/ui/crt_power_fx.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: First visit to 5.1 (Start Scene or from 2.4) plays the three enter lines. Standing in the desk box shows `[E]` and opens 5.2. Cafeteria enter line also shows if that overlay had been hidden the same way.
- Verification: Headless 5.1 probe (overlay visible, enter flag set, Front circle overlaps desk box); `interact_arrival_check.gd`.
- Notes: Enter lines still play only once per playtest (`classroom_enter_line_seen`). Do not hide `TopDialogueOverlay` with the editor eye — hide the bar via the overlay script, not the CanvasLayer.

### Mike walk — invert whole figure (body matches head)
- Request: Head and torso color/texture did not match (sketchy gray head vs solid white body). Chose option A: invert the whole walk figure so the body uses the same charcoal look as the head.
- Implementation: Packer no longer flattens chin-down ink to solid white. Every opaque pixel is inverted like the face (painted white → black holes; brush gaps stay). Re-baked `mike_walking-Sheet.png`. CRT knobs unchanged.
- Files changed:
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.py`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.gd`
  - `AXEL/axel_project/assets/sprites/mike_walking-Sheet.png`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Overworld Mike is one charcoal-inverted figure from head through limbs. Thin limbs can show brush gaps (not a solid white stick).
- Verification: Re-bake 12-cell sheet from `kävely_etu` / `kävely_sivu`.
- Notes: Stop Play and Play again so Godot reimports the sheet. Rollback of the old chin flatten is the previous packer + sheet.

### 2.1 kitchen return — raise stand to ~2040×90
- Request: Raise the 2.3 → 2.1 spawn from texture Y `150` to Y `90`.
- Implementation: Kitchen return still maps X along `KitchenInteractArea` from leave `t`, then sets Player node texture Y to `90`. Wall clamp still skipped. Fresh Play / F6 still uses the Player node.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Leaving the kitchen lands Mike 60px higher in the cafeteria door (texture ~2040×90).
- Verification: `interact_arrival_check.gd` (2.3→2.1 node tex y=90).
- Notes: Same kitchen-return exception as before (hardcoded Y, not default spawn).

### 2.1↔2.4 cafeteria doors always land at InteractArea center
- Request: 2.4 spawn from 2.1 (and 2.4→2.1) should always be the dest InteractArea center. Use the same inside-box pattern already on 4.1 / 5.1.
- Implementation: Those two doors no longer save leave `t`. Arrival uses `apply_arrival_inside` with `DEFAULT_T` (box center on the long axis). `2.1` classrooms uses `depth_frac` `0.5` like `4.1` / `5.1`; `2.4` cafeteria keeps `BOTTOM` depth `0.0` so the walk drawing stays below `TopWall`. Consume leftover `t` so it cannot leak. Lounge/classroom/backyard still slide `t`. Fresh Play / F6 still uses the Player node.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: `[E]` between cafeteria and classrooms always puts Mike in the middle of that door box, no matter where he stood when leaving.
- Verification: `interact_arrival_check.gd` (2.1↔2.4 X locked to box center).
- Notes: Other `[E]` pairs still map along the box. Wall clearance may still nudge a little off the box if the drawing overlaps TopWall.

### 2.1→2.4 land on live CafeteriaInteractArea center (~5856×352)
- Request: 2.4 spawn from 2.1 was still far too low; `[E]` looked right of the door box. Correct center is ~5856×352.
- Implementation: Previous pass only locked X, then used `BOTTOM` depth `0.0` plus wall clearance, which parked Front at ~Y 815. That ignored the live shape center (`CafeteriaInteractArea` `(5933, 280)` + shape `(-77, 72.5)`). Both directions now `place_in_area` at box center and skip `resolve_inside_clearance`. `[E]` already anchors to the shape center — it looked offset because Mike was standing hundreds of pixels below the box. Fresh Play / F6 still uses the Player node. No hardcoded `5856×352`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Leaving 2.1 for 2.4 (and back) stands Mike on the live door-box center. Drawing may overlap TopWall; that is intended for this pair.
- Verification: `interact_arrival_check.gd` (2.1↔2.4 Front at box center X and Y).
- Notes: Other `[E]` doors still slide `t` and may still wall-nudge.

### Scene 5.1 — desk MemoryIndicator glow
- Request: Create a memory indicator visual on 5.1.
- Implementation: Instanced `PlayerLayer/MemoryIndicator` on the desk (editor pos `(2712, 2160)`, same as `DeskInteractArea` shape center). Cover-fit remap from the node’s own editor position + `PlayerCoverSync.bind_extra_node`. Hides after `classroom_desk_seen`. Board stays on `BoardGlow/Outline` (not the blob).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Classroom desk shows the looping white/gray memory glow until 5.2 is left. Drag `PlayerLayer/MemoryIndicator` to move it. Board outline glow is unchanged.
- Verification: Scene tree `PlayerLayer/MemoryIndicator`; script remaps + hides on `classroom_desk_seen`.
- Notes: Desk still does not count toward 5/5 memories (`add_memory_once` not called).

### Scene 5.1 — BoardInteractArea
- Request: Add the missing board InteractArea so the player can interact with the classroom chalkboard (it was supposed to already be in the scene).
- Implementation: Added `WalkableWorld/EnvironmentColliders/BoardInteractArea` with its own `RectangleShape2D` (starter `(1790, 420)` / `1380×760`, chalkboard-centered and tall enough to stand in). `[E]` plays the 5.3 board lines in 5.1. Did not open the 5.3 placeholder Control or the AXEL text puzzle.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.tscn`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Walking up to the board shows `[E]` and plays the board inspect lines. Drag `BoardInteractArea` to match the painted chalkboard. Desk / door / board glow unchanged.
- Verification: Scene tree `BoardInteractArea` + unique board shape id; script zone `"board"`.
- Notes: 5.3 still-scene + answer field (`AXEL`) still deferred.

### Live dest box — write the arrival rule so agents re-measure every Play
- Request: Document that door arrival must always read the live InteractArea this Play (not chat/old `.tscn` numbers), including 2.1→3.1, 2.1→2.3, 2.1→2.4, and all 1.x, unless a pair already has a hard spawn.
- Implementation: Added a dedicated live-box rule in `SCENE_BUILDING.md` (forbidden: stale coords, skip re-read, BOTTOM+clearance instead of the live box). Listed hard spawns (F6 / hub / memory / kitchen Y `90`). Clarified frozen peek still uses the live dest box. Mirrored the rule in `AI_DOCS.md` (Narrative + How to work + Optional refs) and the `InteractArrival` file header.
- Files changed:
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/scenes/core/interact_arrival.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No gameplay change this pass — 2.1↔2.4 already lands on live center; other listed doors already call `InteractArrival` on the live shape. Agents must not “fix” that with a remembered Vector2.
- Verification: Docs only.
- Notes: Frozen `1.2`→`1.4` / `1.4`→`2.1` / `2.1`→`2.3` peek mode unchanged. Kitchen Y `90` stays the hard spawn.

### 5.2 desk still — slower sequence, white fill
- Request: Desk animation was too fast; open on empty desk with “this was their desk”, beat, hand plate for one second, then final plate for “I'd spit on you…”; surround should read black after noir (author white).
- Implementation: Retimed 5.2 off the old 1.3s clock. Empty plate holds through the opening line + 1.5s beat, `desk_hand.png` holds 1.0s (shake + white dim), then `desk.png` with the remaining lines. Flattened desk PNG empty fill to white and added a white `VoidFill` (noir → black). Opening line is now `This was their desk.` (replaces `It's THEIR desk.`).
- Files changed:
  - `AXEL/axel_project/scenes/Arc_5/5.2_ClassroomDesk.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.2_ClassroomDesk.tscn`
  - `AXEL/axel_project/exports/Drawings/desk_empty.png`
  - `AXEL/axel_project/exports/Drawings/desk_hand.png`
  - `AXEL/axel_project/exports/Drawings/desk.png`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: First desk visit plays empty → line → pause → one-second hand scare → graffiti + remaining lines. Letterbox/empty around the desk is black in-game.
- Verification: Sequence constants and white `VoidFill` / dim reviewed in source. PNG corners sampled white. Play 5.1 desk `[E]` to confirm timing.
- Notes: Kept `You said it was a dare.` on the final plate as remaining locked 5.2 text.

### 5.2 desk still — dare then spit after final plate
- Request: `You said it was a dare.` should play after the final picture is up, then `I'd spit on you…`
- Implementation: Final plate is shown and undimmed, the opening line hides, then `You said it was a dare.` waits for advance, then `I'd spit on you if I could.`
- Files changed:
  - `AXEL/axel_project/scenes/Arc_5/5.2_ClassroomDesk.gd`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Graffiti is on screen before the dare line. Spit line only after the dare line is done.
- Verification: Sequence order reviewed in `5.2_ClassroomDesk.gd`.
- Notes: Opening empty-desk line is unchanged.

### Combat HUD — mouse clicks match MOVE_TextBox
- Request: Combat interactable clicks were offset and smaller than the TextBoxes they belong to. Clicks should work anywhere on the matching TextBox.
- Implementation: Root cause was mixing Godot 4.7 `get_global_rect()` (already multiplied by HudCanvas window-fit scale, about 0.5) with `_has_point`'s unscaled local mouse point, then further shrinking Execute with `SkullClickPolygon`. Click tests now use the TextBox in the piece's own local pixels. Skull polygon no longer steals clicks. Clickable `+`/`−` widgets fill the TextBox (no 8px inset).
- Files changed:
  - `AXEL/axel_project/combat/scripts/hud_piece.gd`
  - `AXEL/axel_project/combat/scripts/skull_click_polygon.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/test/hud_click_rect_check.gd`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Settings, Execute, and bet `+`/`−` click on the full TextBox. Hover/hand cursor follows that same box.
- Verification: `hud_click_rect_check.gd` OK (synthetic scaled parent + live Settings/Execute/`+`/`−` TextBox corners). `combat_test_scaffold_check.gd` OK. `hud_piece_placement_check.gd` OK.
- Notes: `use_alpha_hit` is unused; kept on the piece so `combat_test.tscn` still loads. `SkullClickPolygon` remains in the tree for editor tracing only.

### Memory indicator — +50% size and white outer glow
- Request: Globally increase all memory_indicator sizes by 50% and add an extra glow (research Godot Asset Library / online for a glow type that fits this sprite).
- Implementation: Bumped shared `indicator_scale` default from `1.5` to `2.25` so all four room instances grow without per-scene overrides. Added white outer-glow silhouette halo (`memory_outer_glow.gdshader` — same family as ShaderV2 OuterGlow / Godot demo aura / kitchen `prop_ink_halo`, but white + additive because memory sits above noir). Wired a `Halo` AnimatedSprite2D behind the sharp pixel blob in `MemoryIndicator.tscn`; both share frames and `visual_offset`. UV clamp prevents atlas bleed. Did not install ShaderV2 (VisualShader pack; broken on Godot 4.7). Rejected WorldEnvironment bloom (would glow Mike/rooms/UI).
- Files changed:
  - `AXEL/axel_project/scenes/fx/memory_indicator.gd`
  - `AXEL/axel_project/scenes/fx/MemoryIndicator.tscn`
  - `AXEL/axel_project/scenes/fx/memory_outer_glow.gdshader`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Cafeteria / Backyard / Teachers Lounge / Classroom memory markers are 50% larger and show a soft white aura around the looping blob. Still remaps from own editor position; still hides after collect.
- Verification: `shader_builtin_scope_check.gd`; short windowed Godot pass for shader compile; eyeball any of the four rooms.
- Notes: Halo starting look: spread `10`, intensity `0.42`, white. Tunable on the Halo material in Inspector.

### 2.4 ExtraDoor1 [E] sits on ExtraDoor1
- Request: ExtraDoor1 InteractArea’s `[E]` was offset from the shared chip rule (scene 2.4).
- Implementation: ExtraDoor1’s `CollisionShape2D` had a leftover thousands-of-pixel offset from duplicating ExtraDoor3, so the chip followed that far box (on ExtraDoor3’s door). Reset ExtraDoor1 and ExtraDoor3 shapes onto their own Area2D nodes (`position` default `(0, 0)`). ExtraDoor2’s small ink nudge `(4, -116.5)` stays. No overlay `screen_offset`. Documented: after duplicating an InteractArea, reset the child shape position.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: ExtraDoor1’s `[E]` sits in the middle of ExtraDoor1 (south wall, between future and classroom). ExtraDoor3’s chip sits on ExtraDoor3.
- Verification: Scene text — ExtraDoor1/3 CollisionShape2D have no leftover position; ExtraDoor2 still has the small nudge.
- Notes: Drag ExtraDoor1 itself to move the box; do not offset the child shape by thousands of pixels.

### Docs catch-up — ARC2 door spawns match live rules
- Request: Update docs.
- Implementation: Arc 2 implemented notes were still describing old peeks / t-slide on the cafeteria–classrooms pair. Wrote the live rules: `2.1`↔`2.4` always dest-box center (skip clearance); `2.3`→`2.1` kitchen stand texture Y `90`; other 2.4 doors (lounge/classroom) still map `t`. Fixed the stale SCENE_BUILDING line that said 2.4 cafeteria arrival uses wall clearance.
- Files changed:
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only (gameplay already matched `SCENE_BUILDING.md` / `AI_DOCS.md`).
- Verification: Cross-checked against `2.1_Cafeteria.gd`, `2.4_ClassroomsCorridor.gd`, and `InteractArrival` header.
- Notes: Memory-indicator size/glow and combat HUD click-rect were already logged earlier today.

## 2026-09-03

### 1.2 locker line E-spam stuck + combat UI polish
- Request: 1.2 "This was your locker." stuck when spamming E; combat DevTools only from Settings; VT323 ~2x text (balance/bets unchanged); delete premium  /3; grow item list; strip white halo on cigarette/hand/alcohol; shake should move grid symbols and HUD text with the frames. 2.2 visibility = drawing tips only (no code).
- Implementation: 1.2 never orphans the dialogue bar on abort (interrupt_line); _locker_line_running gates hub trips like 1.4; 	ype_line sets _sequence_active so CRT fade alpha~0 gaps count as busy. Removed DevTools wrench (Settings ? DEV TOOLS only). Put 	erminal_theme.tres on WidgetRoot + Settings panel (CanvasLayer broke theme inheritance). COMBAT_TEXT_SCALE 2.0 for combat readouts; goal split from bankroll font; win popup 40. Deleted MOVE_MeterCount. Stripped halo on three premium icons; generator keeps halo on wild only. WidgetLayer 115?106 so symbols/text sit under glitch/CRT/pulse. Fixed Settings TextBox/ArtExit bad offsets that failed placement check.
- Files changed:
  - AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd
  - AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd
  - AXEL/axel_project/scripts/debug/axel_combat_dev_tools.gd
  - AXEL/axel_project/combat/scripts/hud_widget_layer.gd
  - AXEL/axel_project/combat/scripts/combat_settings_panel.gd
  - AXEL/axel_project/combat/scripts/combat_test.gd
  - AXEL/axel_project/combat/scripts/symbol_slot.gd
  - AXEL/axel_project/combat/combat_test.tscn
  - AXEL/axel_project/combat/art/grid_symbols/cigarette.png
  - AXEL/axel_project/combat/art/grid_symbols/booze.png
  - AXEL/axel_project/combat/art/grid_symbols/bloody_hand.png
  - AXEL/axel_project/combat/art/generate_placeholders.py
  - AXEL/axel_project/tools/combat/strip_premium_halo.gd
  - AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md
  - AXEL/axel_project/plans/references/README_STRUCTURE.md
  - AXEL/axel_project/plans/combat/AXEL_combat_implementation.md
  - AXEL/axel_project/plans/core/AI_CHANGELOG.md
- Behavior impact: Locker line can be skipped/advanced with E without getting stuck; hub [E] works after the line. Combat: no * wrench; bigger VT323 HUD; no  /3; icons without white edge; enter glitch shakes symbols with frames. 2.2 unchanged in code.
- Verification: combat_test_scaffold_check.gd, determinism_check.gd, princess_check.gd, hud_piece_placement_check.gd, hud_click_rect_check.gd, strip_premium_halo.gd OK.
- Notes: 2.2 tips for redraw stay white fill + thicker black ink. Wild icon keeps halo. COMBAT_TEXT_SCALE retunes size in one place.

### Fullscreen framing, dialogue size, and spawn fixes

- Request: Fix four fullscreen-only exploration issues: 1.1 intro spawn/walk target drifting in a separate window, dialogue text reading too small in fullscreen, static rooms cropping too much of the drawing, and 2.4 corridor returns from the lounge/classroom coming back at the wrong size.
- Implementation: `TopDialogueOverlay` now scales its dialogue font/outline from viewport height and grows the bar height to fit larger text without re-enabling project stretch. Static locked `cover` rooms gained a shared `edge_reveal` budget in the background layout/camera helpers so wide monitors can show more art with a thin white clear-color strip that the CRT stack darkens. `2.4_ClassroomsCorridor.gd` now keeps the seeded depth multiplier alive until door arrival placement completes, so lounge/classroom returns land at 150%. `1.1_SchoolExterior.gd` now captures the intro target in texture space, re-resolves it during the sequence, and scales the fixed intro distances by live cover ratio so fullscreen resizes cannot stale the walk target. Added headless checks for the new framing math and the 2.4 depth-seed regression, and updated scene canon/docs to match.
- Files changed:
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/core/background_layout.gd`
  - `AXEL/axel_project/scenes/core/background_camera_controller.gd`
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`
  - `AXEL/axel_project/scenes/core/test/background_fit_check.gd`
  - `AXEL/axel_project/scenes/core/test/corridor_depth_seed_check.gd`
  - `AXEL/axel_project/tools/qa/run_default_playtest.ps1`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/scenes/core/exploration_viewport.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Fullscreen dialogue keeps the same screen-height ratio as the authored baseline while staying sharp; static rooms show more drawing on wide monitors with a thin darkened edge strip; 2.4 lounge/classroom returns restore Mike at 150%; and the 1.1 intro stays locked to the Player node's live remapped spawn even if the viewport settles after startup.
- Verification: `background_fit_check.gd`, `player_cover_sync_check.gd`, `player_walk_speed_check.gd`, `player_spawn_sync_check.gd`, `interact_arrival_check.gd`, `corridor_depth_seed_check.gd`, plus the standard `princess_check.gd`, `determinism_check.gd`, `scene_smoke_check.gd`, `combat_test_scaffold_check.gd`, and `tools/qa/run_default_playtest.ps1`.
- Notes: Stretch stays disabled per canon; the new edge strip depends on the exploration clear color staying pure white and still needs a real windowed pass because `--headless` does not render the CRT shader.

### Master Build Plan Phase 0 — foundations (capture tool, InputMap, settings, audio buses, pause, resolution sweep)

- Request: Build AXEL from `plans/core/AXEL_MASTER_BUILD_PLAN.md` starting at Phase 0 — capture tool first, verify every acceptance criterion, gate on `tools/qa/run_default_playtest.ps1`.
- Implementation:
  - **Gate repair:** `tools/bots/playthrough_arc1_exterior.gd` was failing on Windows because the headless dummy display reports a 64×64 viewport; it now forces `root.size = 1920×1280` like every other check and walks 420 frames (first door overlap lands ~frame 370 at design scale; the wall pins Mike inside the door area so overshoot is safe).
  - **0.1 capture tool:** `tools/qa/capture_scene.gd` + `capture_scene.ps1` (generic scene→PNG: any size, windowed/borderless/fullscreen, console exe, clean `--headless` rejection), plus `capture_matrix.ps1` (18 scenes × 5 sizes) and `scan_captures.ps1` (blank-frame scan).
  - **0.2 InputMap:** named actions written into `project.godot` (`move_*`, `interact`, `dialogue_advance`, `back`, `pause`; physical keycodes, `device:-1`, gamepad stick/d-pad/A/B/Start). Migrated `scripts/Player.gd` (`Input.get_vector`), `interact_zone_gate.gd`, 9 room interact handlers, 4 memory stills + `TopDialogueOverlay` advance, hub/map exits, and the combat settings panel close. Memory stills now accept gamepad A (the old key-type gate blocked joypad events). Debug tools (`axel_combat_dev_tools.gd`, `playtest_collision_debug.gd`, `TopDialogueOverlayFxPreview.gd`) intentionally stay raw; `GameController.gd` is orphaned legacy and untouched.
  - **0.4 settings:** new autoload `AxelSettings` (`user://axel_settings.cfg`, loads in `_enter_tree`, debounced saves, change signal, rebind storage under `[controls]`, applies window mode / vsync / FPS cap / bus volumes at boot).
  - **0.5 audio buses:** `default_bus_layout.tres` now Master ← Music + Effects; Effects ← Typewriter, TypewriterOpen, CombatSfx, UiSfx (names unchanged, so scene bus references hold; typewriter net gain unchanged through the 0 dB Effects hop).
  - **0.6 pause:** new autoload `AxelPause` — sole writer of `get_tree().paused`, `pause` action via `_unhandled_input` (scene handlers consume Esc first), refuses while dialogue busy or on the main menu, promotes `AxelMusic` to `PROCESS_MODE_ALWAYS`, placeholder `PAUSED` scrim on CanvasLayer 120 until the Phase 1.5 menu.
  - **0.3 resolution sweep:** 90-capture matrix (18 scenes × 1366×768 / 1920×1080 / 1920×1200 / 2560×1440 / 3840×2160) reviewed plus borderless and native-fullscreen (2240×1400) spot checks. Fixed the gaps it exposed: new `scenes/core/ui_viewport_scale.gd` (`UiViewportScale.factor` = live height ÷ 1280, clamp 0.5–2.5, × `ui_scale` setting) now scales the hub/map/memory `X` buttons, the 1.3 map travel buttons (also switched to VT323 per typography canon), the `[E]` chip, and the pause label; `ui_scale` composes into `TopDialogueOverlay._dialogue_window_scale`.
- Files changed:
  - `AXEL/axel_project/project.godot` (input map + AxelSettings/AxelPause autoloads)
  - `AXEL/axel_project/default_bus_layout.tres`
  - `AXEL/axel_project/scripts/autoload/axel_settings.gd` (new)
  - `AXEL/axel_project/scripts/autoload/axel_pause.gd` (new)
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/scenes/core/interact_zone_gate.gd`
  - `AXEL/axel_project/scenes/core/ui_viewport_scale.gd` (new)
  - `AXEL/axel_project/scenes/Arc_1/1.1_SchoolExterior.gd`, `1.2_Corridor.gd`, `1.3_LockerHub.gd`, `1.3_SchoolMap.gd`, `1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.1_Cafeteria.gd`, `2.2_CafeteriaMemory.gd`, `2.3_Kitchen.gd`, `2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_3/3.1_Backyard.gd`, `3.2_BackyardMemory.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.gd`, `4.2_TeachersMemory.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`, `5.2_ClassroomDesk.gd`
  - `AXEL/axel_project/scenes/ui/TopDialogueOverlay.gd`, `InteractPromptOverlay.gd`
  - `AXEL/axel_project/combat/scripts/combat_settings_panel.gd`
  - `AXEL/axel_project/tools/bots/playthrough_arc1_exterior.gd`
  - `AXEL/axel_project/tools/qa/capture_scene.gd` (new), `capture_scene.ps1` (new), `capture_matrix.ps1` (new), `scan_captures.ps1` (new), `audio_bus_layout_check.gd` (new), `settings_persistence_check.gd` (new), `pause_contract_check.gd` (new), `run_default_playtest.ps1`
  - `AGENTS.md`, `plans/core/AI_DOCS.md`, `plans/scenes/SCENE_BUILDING.md`, `.gitignore` (`/out/`)
- Behavior impact: identical keyboard feel; controllers now move Mike, interact, advance dialogue, back out, and pause; Esc pauses everywhere outside the menu (placeholder scrim until Phase 1.5); settings persist across restarts separately from saves; Master/Music/Effects volumes have live plumbing; fixed-pixel chrome stays readable at 4K.
- Verification: full gate 18/19 pass (`bot_dialogue_loop` is the documented headless-expected failure) including the three new checks; 90-capture matrix with zero failures/blank frames; before/after captures reviewed for the map, hub, chip, pause scrim, dialogue at extremes.
- Notes: Rebinding UI intentionally lands with the Phase 1.3 Options screen (storage/apply layer already live). New `class_name` scripts need a warm `--import` before headless/console runs pick them up (stale `global_script_class_cache` otherwise).

## 2026-09-06

### 2.1→2.4 spawn on live CafeteriaInteractArea; swap ExtraDoor1/3
- Request: Coming from 2.1, 2.4 spawned the player model outside the world borders. Spawn must always follow the live 2.4→2.1 InteractArea. Also ExtraDoor1 and ExtraDoor3 had each other's dialogues.
- Implementation: `2.1`→`2.4` now stands the Player node on the live `CafeteriaInteractArea` center (`InteractArrival.place_node_on_area_center`) after cover-fit — not Front-on-center (that shoved the tall walk drawing out the top of the PNG). Skip wall clearance; no stored Vector2. The 2.4 PNG import had `process/size_limit=2048` while colliders are authored on the real `7016×4960` drawing, so the live door box sat off the right of the room; size limit is now `0` and Background scale is `1`. ExtraDoor1 and ExtraDoor3 swapped places so "Try the next one." is at the cafeteria-end door and "You missed it." is at the classroom-end door. 2.4 no longer re-applies cover/depth after door place.
- Files changed:
  - `AXEL/axel_project/scenes/core/interact_arrival.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.tscn`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Leaving 2.1 for 2.4 puts Mike on the current cafeteria-door `[E]` box, inside the room art. Drag that box in the editor and the land point follows. Extra door lines now match walking from the cafeteria. Fresh Play / F6 still uses the Player node.
- Verification: `interact_arrival_check.gd`, `corridor_depth_seed_check.gd`, plus the AGENTS.md headless suite.
- Notes: `2.4`→`2.1` still lands Front on the live cafeteria `ClassroomsInteractArea` center.

### 2.4→5.1 spawn on live DoorInteractArea
- Request: Walking 2.4 → 5.1 spawned the player model outside the collision borders at the top-right (same class of bug as 2.1→2.4).
- Implementation: Leave `t` no longer slides onto 5.1 `DoorInteractArea` Y (that parked Front inside `DoorWall`). Arrival now stands the Player node on the live door-box center (`place_node_on_area_center`) and skips clearance. 2.4 no longer saves leave `t` when going to the classroom.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_5/5.1_Classroom.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.4_ClassroomsCorridor.gd`
  - `AXEL/axel_project/scenes/core/interact_arrival.gd`
  - `AXEL/axel_project/scenes/core/test/interact_arrival_check.gd`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Leaving the classrooms corridor for 5.1 puts Mike on the classroom door `[E]` box, on the walkable floor, not in the top-right wall.
- Verification: `interact_arrival_check.gd` (2.4→5.1 node at live door center, not in DoorWall).
- Notes: 5.1→2.4 still uses inside-box `t` on the corridor classroom door.

## 2026-09-06

### School to fight loop (walk / pickup / memory), world items, visited-room map
- Request: Put the rest of the master-plan work in the live game plus a real school -> fight loop: memories start a fight after the still, lore and combat-item pickups start a fight, rare indoor walking fights (~0.1% per step early, ~1% late), combat items scattered in rooms, item ranks start Common and untouched areas improve, locker loses START RUN, the school map hides unvisited rooms, and a Pokemon-like wipe plays into every fight.
- Implementation: New autoload `AxelWorld` owns the narrative side of the loop (six areas mapped onto the live rooms, floor-item scatter and rank tiers, walk-step roll with a 200-step cooldown and a 2-per-visit cap, one-fight-per-lore-item guard, visited-room marking, return-to-spot after a win). `AxelRun.enter_world_encounter()` is a second, single-encounter door that never moves the act pointer and returns to the room it started in; the old three-act `enter_combat()` stays in the file but is unreachable. New red-bar wipe overlay lives on `AxelEventFx` so it survives the scene change, with a 4s safety clear. Floor pickups are spawned under `EnvironmentColliders` so they share cover-fit.
- Files changed:
  - `AXEL/axel_project/scripts/autoload/axel_world.gd` (new)
  - `AXEL/axel_project/scenes/world/world_item_pickup.gd` (new)
  - `AXEL/axel_project/scenes/fx/combat_wipe_overlay.gd` (new)
  - `AXEL/axel_project/tools/qa/world_combat_loop_check.gd` (new)
  - `AXEL/axel_project/tools/qa/world_item_scatter_check.gd` (new)
  - `AXEL/axel_project/tools/qa/world_combat_roundtrip_check.gd` (new)
  - `AXEL/axel_project/plans/core/AXEL_WORLD_COMBAT_LOOP_PLAN.md` (new)
  - `AXEL/axel_project/project.godot`
  - `AXEL/axel_project/scripts/autoload/axel_run.gd`
  - `AXEL/axel_project/scripts/autoload/axel_event_fx.gd`
  - `AXEL/axel_project/scripts/Player.gd`
  - `AXEL/axel_project/combat/scripts/run_state.gd`
  - `AXEL/axel_project/combat/scripts/combat_run.gd`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/scenes/ui/locker_interior.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.3_LockerHub.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.3_SchoolMap.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.2_CafeteriaMemory.gd`
  - `AXEL/axel_project/scenes/Arc_3/3.2_BackyardMemory.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.2_TeachersMemory.gd`
  - `AXEL/axel_project/scenes/Arc_5/5.2_ClassroomDesk.gd`
  - `AXEL/axel_project/scenes/Arc_2/2.3_Kitchen.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.gd`
  - `AXEL/axel_project/scenes/core/greybox_choice.gd`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Fights now start out in the school instead of from the locker. Walking indoors can trigger one; `1.1` and `3.1` never do. Every memory still, every lore item, and every floor combat item starts exactly one fight. Winning returns to the same room and standing spot; losing still writes the tombstone. The locker panel is equip-only. The school map shows `?????` dark cards for rooms never walked in.
- Verification: `world_combat_loop_check.gd` and `world_combat_roundtrip_check.gd` (new, both exit 0), plus determinism, princess, combat scaffold, scene smoke, audio bus, settings persistence, pause contract, spawn sync, cover sync, walk speed, interact arrival, collision-shape-unique, and the arc1 playthrough bot. `wall_sprite_clearance_check.gd` fails identically with `AXEL_WORLD_COMBAT=0`, so it is pre-existing and unrelated.
- Fixed while building: player repositioning (spawn placement, cover-fit, post-fight return) was feeding the walk-step counter, so entering a room banked hundreds of steps at once and could start a fight on arrival. `Player.gd` now drops any jump of 64 px or more; this also fixes the same flaw in the existing CRT pulse cadence. Also: an area now grants only one rank upgrade to the untouched areas (first pickup there or clearing it, whichever comes first) instead of one for each, and floor spots are searched on both axes and dodge interact zones as well as walls.
- Notes: Replaces master-plan **D7** (locker is the only door) and the old `AXEL_notes` line "memories do not trigger combat" - both confirmed by the user before implementing. Shop / The Hole / 50/50 (master plan section 7 Q3) stay out until asked. `5.2` desk starts a fight but is still not a 5/5 memory. Rollback: `AXEL_WORLD_COMBAT=0`.

## 2026-09-09

### Pentacle floor marker, locker tutorial fight, and world goal ladder

- Request: Make every random floor item show one shared animated pentacle instead of its own catalog picture, and show that item's real name, description and icon when you walk near it. Remove floor items from `1.1` and `1.2`. Add a first-fight tutorial: after opening the locker and then leaving the hub yourself (red X), a low-goal ~99% fight with no items plays on arrival in the corridor. After that tutorial plus one fight in another room, `1.1` and `1.2` may start walk-only random fights. Base the tutorial goal on a real difficulty curve.
- Implementation:
  - Copied the itch sheet to `assets/sprites/animated_pentacle_48x48.png` and added `PentacleMarker.tscn` + `pentacle_marker.gd`. **The sheet is 12 frames of 48x96, not 48x48** (576x96 total; the disc fills the lower half and the last three frames add a glow above it), verified by inspecting the PNG. The sprite is lifted a quarter cell so the disc sits on the marker node. Hosted under `EnvironmentColliders`, so live `AxelPostFxStack` noir + scanline + CRT apply.
  - `world_item_pickup.gd` no longer builds a catalog `Icon` sprite or the black `Blob` diamond; it instantiates the shared marker. Added `description()` next to the previously dead `display_name()`.
  - New `scenes/ui/world_item_info_card.gd` (CanvasLayer 109 - above CRT 108, below the `[E]` chip 110 and dialogue 111): shows the item's real `display_name`, `description` and `icon` on the existing radius-220 walk-in, hidden on walk-out. One card per room, created by `AxelWorld._ensure_info_card`.
  - `axel_world.gd`: `1.2_Corridor` floor items `2 -> 0`; new `GATED_WALK_SCENES` (`1.1`, `1.2`) + `can_walk_fight()` + `walk_fights_unlocked()`; `register_walk_step` now calls `can_walk_fight` instead of `is_indoor_scene`. `1.1` is deliberately still absent from `AREAS`, which is what keeps scatter off it. Added `queue_locker_tutorial_fight()`, `_start_locker_tutorial()`, `_record_fight_room()` and reason `locker_tutorial`.
  - `run_state.gd`: added `world_fight_count`, `tutorial_fight_pending`, `tutorial_fight_done`, `fought_rooms`, all serialised.
  - `1.3_LockerHub.gd`: the red X / Esc exit asks `AxelWorld` for the tutorial before changing scene. No fight logic in the exploration scene.
  - `axel_run.gd`: `WORLD_GOAL_LADDER_CENTS` = 3000 / 5000 / 7500 / 10000 / 15000 / 20000 / 30000 (3x - 30x of the 1000-cent chip bar), then x1.5 per further fight rounded to 100. Fed to combat through the pre-existing but unused `set_goal_base_target_cents()`. The tutorial also gets an empty items array, zero lore bonus, and `set_final_spin_goal_assist(0.99)`.
  - `combat_root.gd`: new `set_final_spin_goal_assist(p)` (default `0.0`) and `_try_final_spin_goal_assist()`, hooked into the two loss branches of `_finalize_encounter_if_needed()`. Rolls once per encounter and only when `p > 0`, so no normal fight draws RNG here.
- Files changed:
  - `AXEL/axel_project/assets/sprites/animated_pentacle_48x48.png` (new)
  - `AXEL/axel_project/scenes/world/PentacleMarker.tscn` (new)
  - `AXEL/axel_project/scenes/world/pentacle_marker.gd` (new)
  - `AXEL/axel_project/scenes/ui/world_item_info_card.gd` (new)
  - `AXEL/axel_project/scenes/world/world_item_pickup.gd`
  - `AXEL/axel_project/scripts/autoload/axel_world.gd`
  - `AXEL/axel_project/scripts/autoload/axel_run.gd`
  - `AXEL/axel_project/combat/scripts/run_state.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.3_LockerHub.gd`
  - `AXEL/axel_project/tools/qa/world_item_scatter_check.gd`
  - `AXEL/axel_project/tools/qa/world_combat_loop_check.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AXEL_WORLD_COMBAT_LOOP_PLAN.md`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/references/AXEL_notes.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Floor items are no longer readable from across the room - they all look like the same pentacle, and you learn what one is by standing on it. `1.1` and `1.2` hold no items and are completely silent on a fresh save; the first fight of a run is the locker tutorial (3x goal, empty loadout, ~99% winnable). After the tutorial plus one other-room fight, `1.1` and `1.2` can walk-fight. `3.1` still never fights. World fight goals now climb 3x / 5x / 7.5x / 10x / 15x / 20x / 30x instead of a flat 10x; act fights are unchanged.
- Verification: determinism (OK, 100 spins seed 12345), princess, combat scaffold, item synergy smoke (44/44), world combat loop (extended with gate + ladder assertions), world item scatter (extended for zero-item rooms and a pentacle/no-icon assertion), world combat roundtrip, scene smoke (21 scenes) - all exit 0. Windowed captures confirmed the three cafeteria pentacles render through noir + CRT, and that the walk-near card shows a real item name, description and icon.
- Fixed while building: `world_encounter_index` wraps at 3 (`% WORLD_ENCOUNTER_PATHS.size()`), so it cannot index a 7-rung ladder. Added the monotonic `world_fight_count` instead - using the existing index would have made fight 4 read rung 0.
- Notes: Overrides three written lines, all flagged to the user first and confirmed. (1) `AXEL_WORLD_COMBAT_LOOP_PLAN.md` "`1.1` and `3.1` never [step-fight]" - `1.1` is now gated, `3.1` unchanged. (2) `AXEL_notes` 8.3 "no minimum payout safety net" - now carries one documented tutorial-only carve-out. (3) `AXEL_MASTER_BUILD_PLAN.md` section 7 Q2 "do not guess the difficulty curve" - answered by the ladder, but that file was moved to `plans/core/archive/` by another session mid-work, so the ladder canon was recorded in `AI_DOCS.md` and the world-loop plan instead of editing the archived copy. Per the user's choice, D10's in-fiction warning does not fire and `first_encounter_warned` stays unwired. A lost tutorial still deletes the save (D8). Rollback: `AXEL_WORLD_COMBAT=0`, or set the assist to `1.0` if the ~1% tutorial loss feels wrong.

### Combat HUD Cleanup + Paid-Spin Board Swap

- Request: Remove the three leftover faded princess icons; make the item rows and their hover description bigger / on top / 90% opaque; auto-fit BALANCE and BETS to their bars; give GOAL, the spin-rewards number and the multiplier one shared big size; make HISTORY as large as its box allows; hand cursor on bet `+`/`-`; and replace the paid-spin board refresh with symbols falling off the bottom (rightmost column first) followed by the new board streaming in column by column from the left, each column one row behind, all under 2 seconds.
- Implementation:
  - `combat_feel.gd`: dropped `FeelPrincessHud` and its three symbol preloads. `highlight_princess()` stays as a documented no-op so Trinity call sites keep working; the win-line refresh was always a separate `show_win_lines()` call, so nothing was lost. The center `PowerIntroIcon` already names the acting princess.
  - `combat_test.gd` typography: `ITEM_ICON_DRAW_SIZE` `48 -> 72`; items body ceiling `45 -> 64` with a new floor of `40`; new `COMBAT_HUD_MAJOR_FONT` `96` (narrow `75`) now drives `GOAL_READOUT_FONT`, `WINNINGS_READOUT_FONT` and `CASCADE_MULT_READOUT_FONT` so GOAL and the multiplier match; HISTORY ceiling `54 -> 108` with a largest-that-fits search whose mini-icon column is re-measured per candidate size (lands at `89`); BALANCE and the bet strip share `_fitted_balance_bet_font()`, sized off the shorter of the two drawn bars and capped by the widest `BALANCE: 0000/0000` string (lands at `90`, up from `36`), replacing the hardcoded `36`/`32`/`28`.
  - `combat_test.gd` layout fixes found while testing: `_side_panel_inner_width()` now measures the fixed piece host instead of the panel. A `PanelContainer` grows to fit its content, so the old code fed the font fitters their own output - at 64 px the ITEMS panel inflated to `773` inside a `718` clipped host and cut the rank buttons to "Commo". The items fitter now measures the widest **real** row name (family and unique rows tracked apart, since only family rows carry a rank button), and row names clip with an ellipsis as a backstop.
  - `combat_test.gd` hover card: `ItemDescClip` moved onto a new `ItemDescLayer` (`CanvasLayer`, layer `107` - above `WidgetLayer` 106, below CRT 108) so it draws over the rows; panel background and border alpha raised to `1.0` and the fade target lowered to `0.9`, so the whole card is uniformly 90% opaque. Its font is pinned to the old `1.25` scale because the card is drawn unscaled, outside the HudCanvas.
  - `combat_test.gd`: `_style_stake_buttons()` sets `CURSOR_POINTING_HAND` on both stake buttons - they are the live click targets above the drawings.
  - `symbol_slot.gd`: new `play_fall_off()`, `play_tube_in()` and `has_visible_symbol()`. Both animations are LINEAR and move the icon's local offset, not the slot, so grid layout is untouched. `play_drop()` is unchanged and still owns the gravity cascade.
  - `combat_root.gd`: `_play_initial_grid_drop_fx()` replaced by `_play_board_swap_fx()` (+ `_play_board_fall_off_fx`, `_play_board_stream_in_fx`, `_await_board_swap_fx`, `_row_pitch_px`). Four new exports: `board_swap_fall_cell_sec` `0.08`, `board_swap_fall_column_step_sec` `0.08`, `board_swap_fill_cell_sec` `0.13`, `board_swap_fall_overshoot_cells` `0.5`. Travel is measured in row *pitch* (cell + separation) so "one column behind" lands exactly one row. `GridUI.clip_contents` is switched on for the swap and off again by the newest run only, so a restarted swap cannot leave it stuck. Every `grid.populate()` site now animates, including `_repopulate_grid_handoff()` (Free Spins entry), which previously repopulated with no visual refresh at all.
  - `combat_root.gd`: paid-spin start now awaits the swap instead of the flat `pause_at_spin_start_sec`; Free Spins keep the pause because they reuse the entry board.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_feel.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Fall-off `0.76 s` + stream-in `1.17 s` = `1.93 s` per fresh board, replacing the old `1.275 s` flat pause, so a paid spin starts ~`0.66 s` later. Mid-round cascade is untouched: `_on_cells_cleared` is still empty, `refill()` is still uncalled, nothing spawns from the top during a round. Item rows land at `72 px` icons + `57 px` text (up from `48`/`45`), so the list scrolls further. No faded icons anywhere.
- Verification: All eight headless gates exit 0 (determinism 100 spins seed 12345, princess, combat scaffold, scene smoke 21 scenes, RTP audit, audio bus, settings persistence, pause contract). Windowed captures at 1920x1280 and 3840x2560 confirmed the readouts and that no item row overflows its host. A scripted spin logged the live icon offsets: fall-off staggered right-to-left, then all five slots of a column sharing one offset with exactly `408 px` (one row pitch) between neighbouring columns, reaching zero by `2.0 s`, with `GridUI.clip_contents` back to `false` and all 25 slots holding a texture at rest.
- Notes: **RNG stream shift (accepted).** The old drop FX drew `rng.randf()` per cell for a random lift height; the new animation has no randomness and draws nothing, so a given seed no longer reproduces the boards it produced before this change. Same-seed replay inside the new build is still exact, which is why `determinism_check.gd` still passes. `AXEL_combat_implementation.md` §10 now records the swap as the one documented exception to the "≤200 ms per step" animation guideline, and drops "active princess portrait" from the HUD list. Item-list changes only show on the F6 test path and wherever the picker appears - `combat_run.gd` hides `NEW_Items` for world encounters. Rollback: the four `board_swap_*` exports are the whole timing surface; restoring the flat `pause_at_spin_start_sec` wait reverts spin pacing without touching the HUD work.

## 2026-09-10

### ITEMS playtest type sizes + VT323 on item text

- Request: Make Ignore slot cap / Limit spins check squares at least 200% larger so they match the text; grow REROLLS, Used, Budget, FAMILIES, and rarity titles the same way; restore the item hover description to its size from before the HUD-layer move; use VT323 for all item text in combat and the overworld (size may differ).
- Implementation: Playtest checkboxes now use drawn red-on-black check textures at `max(font, 72)` because Godot `icon_max_width` cannot enlarge the default icon. REROLLS / Used / Budget / FAMILIES / rarity headers and the Used/Budget spin boxes share a chrome size of at least 56 (2× the old 28). The hover card applies VT323 and multiplies its fitted font by HudCanvas scale so it reads at the old on-screen size. Locker buttons no longer set a native tooltip (hover line already shows the description in VT323).
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/scenes/ui/locker_interior.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: F6 ITEMS chrome is much larger. Hover descriptions are smaller and in VT323. World fights still hide the picker. Floor cards were already VT323.
- Verification: determinism (OK, 100 spins seed 12345), princess, combat scaffold, scene smoke (21 scenes) — all exit 0.
- Notes: World item card sizes (name 26 / desc 20) were left unchanged. Family/unique row checkboxes stay at the old column width so names still fit.

### Board-swap fall-off starts on the left

- Request: After Spin, the old icons falling off should go left-to-right (left column first), reversing the previous right-to-left leave order.
- Implementation: `_play_board_fall_off_fx` delay is now `c * board_swap_fall_column_step_sec` instead of `(COLS - 1 - c) * …`. Stream-in was already left-first and is unchanged. Timing totals stay the same.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Visual only. Old board tubes now drop left column, then the next, then the right. New board still lands left-first.
- Verification: determinism, princess, combat scaffold, scene smoke.
- Notes: Corrects the leave order from the HUD-cleanup board-swap request. Cascade gravity (`play_drop`) was already left-to-right and was not touched.

### Remove combat match win-line overlay

- Request: When icons match in combat, a red line stays on the grid. Remove it completely.
- Implementation: Deleted the `FeelWinLines` overlay and `show_win_lines` / `clear_win_lines` from `combat_feel.gd`. `_feel_on_line_wins` no longer builds cell-center point sets or draws `Line2D` connectors. Shake, glitch, wobble, goal grime, and payout popups are unchanged.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_feel.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Matching rows/cols no longer draw or leave a red line. Line wins, payouts, and cascades are the same.
- Verification: determinism, princess, combat scaffold, scene smoke.
- Notes: The line was visual-only and was never cleared except when a later match replaced it.

### Combat spin on Space / E

- Request: Pressing Space or E during combat should start a spin.
- Implementation: Combat HUD `_input` treats the named `interact` action (E / Space / Enter / pad A) as Execute. Same path as the spin button. Skips while a spin is running, while the Free Spins princess picker is up, while settings or debug tools are open, and while a visible text box or checkbox has focus. World fights also drop focus from hidden playtest widgets so a leftover seed box cannot swallow the key.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/combat_run.gd`
  - `AXEL/axel_project/scripts/debug/axel_combat_dev_tools.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Space or E now spins. Clicking Execute still works. Pause, settings, and Free Spins choice are unchanged.
- Verification: determinism, princess, combat scaffold, scene smoke.
- Notes: Uses `interact`, not raw keycodes, so player rebinds still apply.

### ITEMS box 33% larger, wrap, left icons

- Request: Make all text and icons in the ITEMS rectangle 33% larger; wrap names that hit the edge; sit icons on the left, almost touching the box.
- Implementation: One `ITEM_BOX_SIZE_MUL` `1.33` scales item fonts, icons, checkboxes, and rank buttons. Names wrap (`AUTOWRAP_WORD_SMART`) instead of ellipsis. Icons are the first child in each row. The ITEMS text box left inset is `28 → 6` and the attached list left offset is `2` so icons sit on the left edge.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: F6 ITEMS list is bigger, wraps long names, and lines icons up on the left. World fights still hide this panel. Combat RNG is unchanged.
- Verification: determinism, princess, combat scaffold, scene smoke.
- Notes: Hover description size was left as-is. Rollback: set `ITEM_BOX_SIZE_MUL` to `1.0` and restore `MOVE_TextBox` `offset_left` `28`.

### Sync combat item catalog plan to the live game

- Request: Update `AXEL_COMBAT_ITEM_CATALOG_PLAN.md` to match the live game and include all icons in the list.
- Implementation: Rewrote the catalog as the live 75-item roster (31 baseline + 44 extended). Every row now shows its 256×256 icon at 48 px. Counts, G/H/M/F numbers, playtest HUD, and icon notes match shipped code. `L-A` stays unused (Overclock is `L2` only). The old C2–C10 40% cut is marked history — it did not ship.
- Files changed:
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only. Combat items, icons, and RNG are unchanged.
- Verification: Plan icon `src` paths match all 75 live `.tres` ids and `combat/art/item_icons/{id}.png` files. No `L-A` row.
- Notes: `.tres` description strings were left as-is (some H items still say “playtest Base target”; the plan records that the code also applies on world fights).

### Two combat scenes: playtest picker vs player item box

- Request: Keep the F6 playtest scene as the Godot-only all-items tool. Overworld fights should show the item rectangle: first fight empty with a DVD mill + “Nothing but us chickens.” ticker; later fights show equipped icons only.
- Implementation: `combat_run.tscn` no longer hides `NEW_Items`. Hosted `combat_test` skips the catalog picker. Tutorial / F6 preview attach a visual-only DVD mill (red/white/grey bounce, rare corner flame burst). Later world fights attach a read-only equipped list. Combat RNG is unchanged.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_run.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/empty_item_dvd.gd`
  - `AXEL/axel_project/combat/scripts/player_item_panel.gd`
  - `AXEL/axel_project/combat/test/combat_player_item_box_check.gd`
  - `AXEL/axel_project/assets/sprites/combat/wind_mill_blades_48x48.png`
  - `AXEL/axel_project/assets/sprites/combat/flame_1_48x48.png`
  - `AXEL/axel_project/combat/README_COMBAT_TEST_VERSIONS.md`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: World fights show the drawn item box. First fight is the chickens easter egg. Later fights show locker loadout icons. F6 `combat_test.tscn` is unchanged as a catalog tool.
- Verification: combat_test_scaffold_check OK (exit 0); determinism OK (exit 0, 100 spins seed 12345); princess OK (exit 0); scene smoke OK (exit 0, 21 scenes); combat_player_item_box_check OK (exit 0). Windowed F6 look was not run here.
- Notes: Corner hit is rare on purpose. Visual RNG is time-seeded and never touches the combat seed.

### ITEMS list names wrap; icons stay inside the box

- Request: After the 33% size-up, item names vanished and icons sat on the red rectangle edge. Wrap long names onto a second row and keep icons a few pixels inside the left ink.
- Implementation: Godot 4.7 wrap now uses `custom_maximum_size` plus `propagate_maximum_size` (not the old 1px minimum + `clip_text`). Name column width is leftover space after icon, checkbox, and rank button. Rows can be two lines tall. ITEMS `MOVE_TextBox` left inset is `6 → 20`; attached list left offset is `4`. Same wrap/inset on the world-fight equipped list. Headless layout asserts visible lines and host containment.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/scripts/player_item_panel.gd`
  - `AXEL/axel_project/combat/scripts/combat_run.gd`
  - `AXEL/axel_project/combat/test/combat_player_item_box_check.gd`
  - `.cursor/rules/max-effort-temporary.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: F6 ITEMS names show again and wrap to a second line when needed. Icons sit just inside the left edge. World-fight equipped names use the same wrap. Combat RNG is unchanged.
- Verification: combat_player_item_box_check OK (exit 0); determinism OK (exit 0, 100 spins seed 12345); princess OK (exit 0); combat scaffold OK (exit 0); scene smoke OK (exit 0, 21 scenes).
- Notes: The last size-up missed this because mechanic headless scripts do not measure Label rects, and 4.7 wrap needs a max width.

## 2026-09-10

### ITEMS list gap, rarity marks, description size

- Request: Icons still touched the ITEMS rectangle; rarity diamond prefixes were redundant with colored names; hover descriptions should grow 33%.
- Implementation: Attached list left inset is `4 → 12` on F6 picker and world-fight equipped list. Unique/equipped names drop `◇◈◆★✦` prefixes and keep rarity colors. Hover description scale is `1.25 × 1.33`; player hover font is `22 → 29`.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/combat_run.gd`
  - `AXEL/axel_project/combat/scripts/player_item_panel.gd`
  - `AXEL/axel_project/combat/test/combat_player_item_box_check.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: ITEMS icons sit farther from the left ink. Rarity is color-only on names. Hover text is larger. Combat RNG is unchanged.
- Verification: combat_player_item_box_check OK (exit 0); determinism OK (exit 0, 100 spins seed 12345); princess OK (exit 0); combat scaffold OK (exit 0); scene smoke OK (exit 0, 21 scenes).
- Notes: Did not move `MOVE_TextBox`. Catalog markdown rarity key is unchanged.

### Combat item icons at 1024

- Request: Make AI icons for the 51 glyph placeholders, keep every live icon at 1024×1024, and copy the existing 24 staged originals into the live folder at 1024 (no shrink).
- Implementation: Generated 51 noir locker-object icons and staged them in `tools/combat/ai_icon_src`. Remap now posterizes at 1024 and never downscales. QA requires 75 × 1024. The old 24 staged files were remapped into the live folder at 1024. `L-A` stays unused. Combat rules, `.tres` effects, and RNG are unchanged.
- Files changed:
  - `AXEL/axel_project/tools/combat/remap_item_icons_noir.gd`
  - `AXEL/axel_project/tools/qa/item_icons_check.gd`
  - `AXEL/axel_project/tools/combat/bake_item_icons_256.gd`
  - `AXEL/axel_project/tools/combat/ai_icon_src/*.png`
  - `AXEL/axel_project/combat/art/item_icons/*.png`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Locker shelves and item lists show sharper 1024 icons. No combat math change.
- Verification: item_icons_check OK (exit 0, 75 × 1024); determinism OK (exit 0, 100 spins seed 12345); princess OK (exit 0); combat scaffold OK (exit 0); scene smoke OK (exit 0, 21 scenes).
- Notes: GenerateImage wrote JPEGs named `.png`; they were converted to real PNGs before remap. Do not run `bake_item_icons_256.gd`.

## 2026-09-03

### 4.1 lounge — table/chair behind fade (docs catch-up)

- Request: Walking behind the lounge table and chair should fade Mike the same way other rooms fade behind furniture.
- Implementation: Added `TableBlock_Behind` and `ChairBlock_Behind` (`leaf_occlusion_zone.gd`) under `EnvironmentColliders`. After cover-fit, `4.1_TeachersLounge.gd` sends those polygons to `Player.configure_leaf_occlusion_polygons`. Also wakes `Area2D` colliders after layout, not only `StaticBody2D`.
- Files changed:
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.gd`
  - `AXEL/axel_project/scenes/Arc_4/4.1_TeachersLounge.tscn`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Standing behind the lounge table or chair fades Mike. Drag the green behind polygons in the editor to match the drawing.
- Verification: Scene node names + script slot wiring (shipped in `079a6ac`). No extra headless check this catch-up.
- Notes: Catch-up — this shipped in the Sep 3 locker-line / combat-UI commit and was never logged. Key / memory loop was already logged on Aug 27.

## 2026-09-04

### Master Build Plan Phase 1–3 — saves, menu, pause, locker, combat run (docs catch-up)

- Request: Put the rest of the master-plan shell in the live game after Phase 0: three save slots, a real title menu, Options, Credits, a real pause menu, locker loadout, a player combat scene, combat juice, and playable grey-box rooms / endings.
- Implementation:
  - **Saves (D2 / D3 / D9):** new autoload `AxelSaves` — three slots under `user://saves/`, separate from `AxelSettings`. A slot turns on only after New Game / Load / Continue, so editor F6 of a room still starts fresh. Playtime ticks only while a slot is active and the tree is unpaused.
  - **Title menu:** Continue / New Game / Load / Options / Credits / Quit. Shared `menu_look.gd` chrome. New Game and Load open `Saves.tscn`. Continue uses the last living slot.
  - **Options (D4 / Phase 1.3):** `options_panel.gd` on the title Options scene and inside pause — window mode / size, vsync, FPS cap, CRT, quality, UI scale, volumes, text speed, auto-advance, reduce flashing, shake, glitch, and key rebinds. Writes through `AxelSettings`.
  - **Pause (D6 / Phase 1.5):** `AxelPause` dropped the placeholder `PAUSED` scrim and now draws `pause_menu.gd` — Resume / Options / Inventory / Map / Quit to Title / Quit to Desktop. `AxelPause` is still the only writer of `tree.paused`.
  - **Run owner (Phase 2):** new autoload `AxelRun` — combat run state, lore goal bonus as a number (no story flags in combat), `enter_combat()` into `combat/combat_run.tscn`. That day the locker still had **START RUN** and opening it granted `C1`/`C2`/`C3` once.
  - **Locker (D7 / D11):** `locker_interior.gd` shelf grid — click to equip, plus START RUN. Hub opens this panel.
  - **Player combat scene:** `combat_run.tscn` / `combat_run.gd` hosts the protected scaffold and hides playtest chrome. `combat_feel.gd` is visual-only juice (shake, banner, goal grime) and never touches combat RNG. Skull meter gained a feel-only rotation. `combat_root` grew named SFX / feel signals.
  - **School map thumbs:** baked room cards in `assets/map_thumbs/` via `bake_map_thumbs.gd`.
  - **Grey-box rooms / endings (D18):** `greybox_choice.gd` on remaining stub rooms (board puzzle, basement chain). `ending_still.gd` plays locked ending lines, then returns to title (true ending goes to the epilogue).
  - **Assets / export:** first noir item-icon remap + 256 bake tools; overworld/combat music converted to `.ogg`; Windows `export_presets.cfg`.
- Files changed:
  - `AXEL/axel_project/scripts/autoload/axel_saves.gd` (new)
  - `AXEL/axel_project/scripts/autoload/axel_run.gd` (new)
  - `AXEL/axel_project/scripts/autoload/axel_pause.gd`, `axel_settings.gd`, `axel_music.gd`, `axel_event_fx.gd`, `axel_post_fx_stack.gd`
  - `AXEL/axel_project/scenes/Main_Menu/MainMenu.gd`, `0.1_MainMenu.tscn`
  - `AXEL/axel_project/scenes/Main_Menu/Saves.gd` / `Saves.tscn`, `Options.gd` / `Options.tscn`, `Credits.gd` / `Credits.tscn`, `menu_look.gd` (new)
  - `AXEL/axel_project/scenes/ui/pause_menu.gd`, `options_panel.gd`, `locker_interior.gd` (new)
  - `AXEL/axel_project/combat/combat_run.tscn`, `combat/scripts/combat_run.gd`, `combat/scripts/combat_feel.gd` (new)
  - `AXEL/axel_project/combat/scripts/combat_root.gd`, `run_state.gd`, `premium_skull_meter.gd`, `symbol_slot.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.3_LockerHub.gd`, `1.3_SchoolMap.gd` / `.tscn`, `1.1_SchoolExterior.gd`, `1.4_BasementDoor.gd`
  - `AXEL/axel_project/scenes/core/greybox_choice.gd` (new)
  - `AXEL/axel_project/scenes/Endings/ending_still.gd` (new) + ending / basement / board stub `.tscn`
  - `AXEL/axel_project/exports/GameManager.gd`, `project.godot`, `export_presets.cfg`
  - `AXEL/axel_project/assets/map_thumbs/*.png`, `assets/audio/music/*.ogg`, `combat/art/item_icons/*.png`
  - `AXEL/axel_project/tools/qa/save_slots_check.gd`, `corrupt_save_check.gd`, `run_state_check.gd`, `greybox_flow_check.gd`, `item_icons_check.gd`, `graphics_preset_check.gd`, `bake_map_thumbs.gd`, `convert_music_to_ogg.ps1` (new)
  - `AXEL/axel_project/tools/combat/remap_item_icons_noir.gd`, `bake_item_icons_256.gd` (new)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: You can start / load / continue a run from the title, pause into a real menu, rebind keys, and open the locker. That day, locker START RUN was still the door into a fight. Grey-box rooms and endings play their locked lines. Combat juice is look-only.
- Verification: New checks from that commit — `save_slots_check.gd`, `corrupt_save_check.gd`, `run_state_check.gd`, `greybox_flow_check.gd`, `item_icons_check.gd`, `graphics_preset_check.gd` — plus the existing playtest gate. This catch-up did not re-run them.
- Notes: Catch-up — commit `1cc3ea3` never wrote a changelog day. **Later the same week:** Sep 6 removed locker START RUN and added the school → fight loop; Sep 9 made opening the locker a tutorial flag only (no `C1`/`C2`/`C3` grant). `enter_combat()` is still in the file but unused for world fights. `AI_DOCS` got the Saves / menu / pause UI line in the 2026-09-10 catch-up below.

## 2026-09-10

### Settings must not unmute author-muted buses (docs catch-up)

- Request: Boot / first volume apply was turning buses back on even when they were muted in the Godot Audio panel (author work-mute).
- Implementation: `AxelSettings._apply_bus_volumes` now respects an already-muted bus on the first apply. Later Options slider moves can still unmute when the saved volume is above zero. `audio_bus_layout_check.gd` asserts that boot apply cannot unmute Master, and that Master must not ship muted in `default_bus_layout.tres`.
- Files changed:
  - `AXEL/axel_project/scripts/autoload/axel_settings.gd`
  - `AXEL/axel_project/default_bus_layout.tres`
  - `AXEL/axel_project/tools/qa/audio_bus_layout_check.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: A bus you muted while authoring stays muted after Play. Options sliders still work after that first apply.
- Verification: `audio_bus_layout_check.gd` (shipped in `ace3506`). This catch-up did not re-run it.
- Notes: Catch-up — the same Sep 10 commit logged ITEMS type sizes, not this mute rule. Canon line was already in `AI_DOCS.md`.

### Baseline item lines + family tags (docs catch-up)

- Request: World scatter and the F6 ITEMS picker should group baseline items by effect (reroll, normal payout, …), not by matching digits (`C1` is not `L1`). Empty `family` fields on those `.tres` files needed filling.
- Implementation: New `combat/scripts/item_lines.gd` holds the eight effect lines plus Common-only uniques `C3`/`C5`/`C9`/`C10`. Scatter and the picker read those rungs. Baseline `.tres` files got `family` tags (`reroll`, `normpay`, `pwrwgt`, …) and a few description cleanups. `AxelWorld` uses the same table for floor rolls.
- Files changed:
  - `AXEL/axel_project/combat/scripts/item_lines.gd` (new)
  - `AXEL/axel_project/combat/data/items/*.tres` (baseline family + some descriptions)
  - `AXEL/axel_project/scripts/autoload/axel_world.gd`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/core/AXEL_WORLD_COMBAT_LOOP_PLAN.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Floor pentacles and the F6 picker step along the same effect lines. Pairing is by effect, not by digit. Combat math / RNG streams are unchanged.
- Verification: Catalog plan paths match live ids; `item_lines.gd` is the source listed in `AI_DOCS.md` / the catalog plan. This catch-up did not re-run headless scripts.
- Notes: Catch-up — shipped in `01a3160` with the ITEMS box / 1024-icon work, but never given its own changelog row. `L-A` stays unused.

### AI_DOCS — name saves, menu, and pause UI (docs catch-up)

- Request: Log the missed last-two-weeks work and put saves / menu / pause in canon so later chats can find them.
- Implementation: Added an Architecture bullet for `AxelSaves`, the title menu, `pause_menu.gd`, and `AxelRun`. Added the matching headless checks to the optional list.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Docs only. Gameplay already matched.
- Verification: Read the new Architecture bullet against `axel_saves.gd`, `MainMenu.gd`, and `axel_pause.gd`.
- Notes: This is the catch-up session that wrote the Sep 3 / Sep 4 / Sep 10 rows above.

## 2026-09-17

### First-pass leftover archive (approved list only)

- Request: Archive ONLY the approved leftover list from the first-pass cleanup chat into `AXEL/axel_project/archive/<dated>/` with `.gdignore`. Do not delete from disk, strip comments, or unmute Master. Then re-run `run_default_playtest.ps1`.
- Implementation: Copied approved leftovers into `archive/2026-09-17/` (empty `.gdignore` in `archive/` and the dated folder so Godot will not import them — official project-organization rule). Removed them from live paths after the copy verified. Kept live `option_2_vhs_glitch.gdshader` because `IntroGlitchOverlay.tscn` still uses it. Did not archive music, logs, item bakers, `ScenePlaceholder.gd`, `GameManager.gd`, or live room drawings. `default_bus_layout.tres` Master mute is unchanged. Recreated empty repo `out/` for later captures.
- Files changed:
  - `AXEL/axel_project/archive/.gdignore` (new)
  - `AXEL/axel_project/archive/2026-09-17/` (approved leftovers)
  - `.gitignore`, `.cursorignore`
  - `AXEL/axel_project/plans/references/README_STRUCTURE.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Unused leftover scenes/scripts/art are no longer on live `res://` paths. Play behavior should match the keep list. Style-sweep option_3 path is now in archive only.
- Verification: `tools/qa/run_default_playtest.ps1` after the archive.
- Notes: Source chat: first-pass cleanup. Skipped `option_2` on purpose. Comment-strip and hidden combat ring meter stay for later chats.

### White pointing-hand floor markers

- Request: Replace the overworld floor-item pentacle with a new pointing-hand animation, drawn white like the memory indicator, with a drop shadow and faint red outline. Place items only where the interact circle does not touch collision.
- Implementation: Packed the 5-frame 48×48 hand strip to white-on-transparent `item_hand-Sheet.png`. New `ItemMarker.tscn` (white hand + drop shadow + red `memory_outer_glow`) lives on `PlayerLayer` so noir does not crush it; the pickup `Area2D` stays under `EnvironmentColliders`. Scatter now uses a shape query of the 220 px interact circle plus pad, never falling back onto a blocked spot, and re-rolls saved spots that overlap walls.
- Files changed:
  - `AXEL/axel_project/assets/sprites/item_hand-Sheet.png` (new)
  - `AXEL/axel_project/scenes/world/ItemMarker.tscn` (new)
  - `AXEL/axel_project/scenes/world/item_marker.gd` (new)
  - `AXEL/axel_project/scenes/world/world_item_pickup.gd`
  - `AXEL/axel_project/scripts/autoload/axel_world.gd`
  - `AXEL/axel_project/tools/qa/world_item_scatter_check.gd`
  - `AXEL/axel_project/scenes/ui/world_item_info_card.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AXEL_WORLD_COMBAT_LOOP_PLAN.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
  - Removed `PentacleMarker.tscn`, `pentacle_marker.gd`, `animated_pentacle_48x48.png`
- Behavior impact: Floor items look like the same white pointing hand from across the room (not a pentacle, not a catalog icon). Interact circles sit fully off walls and furniture. Walk-near card, `[E]`, and fight-on-take are unchanged. `1.1` / `1.2` / `3.1` still hold no floor items.
- Verification: `world_item_scatter_check.gd` OK; `world_combat_loop_check.gd` OK; `world_combat_roundtrip_check.gd` OK; determinism OK (100 spins, seed 12345); princess OK; combat scaffold OK; scene smoke OK (21 scenes). All exit 0.
- Notes: This is the approved canon change from the pentacle-under-noir rule: item pictures now skip noir like memory glows, and stay distinct via shadow + red outline.

### No `##` comments in source code

- Request: Agents must not add any `##` comments to game scripts or other project code from here on.
- Implementation: New always-on Cursor rule. Pointer in the AI docs governance file and a How-to-work line in `AI_DOCS.md`. Regular `#` comments are still allowed. Markdown headings are unchanged. Existing `##` lines are left in place unless the user asks to strip them.
- Files changed:
  - `.cursor/rules/no-double-hash-comments.mdc` (new)
  - `.cursor/rules/axel-ai-docs-governance.mdc`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: None at runtime. Agents stop writing GDScript docs comments (`##`) and other `##` comments in source.
- Verification: Read back the new rule and the two pointer edits.
- Notes: Code only. Plans and `.mdc` files may still use `##` headings.

### First-pass leftover archive (finish live leftovers)

- Request: Finish the approved archive list: leftovers still on live paths after the first copy, plus the tiny path/docs follow-ups. Do not strip comments.
- Implementation: Most approved leftovers were already under `archive/2026-09-17/`. Moved leftover `tools/qa/_mike_look_preview/` PNGs into the dated archive, dropped the stale `game_data.json` Cursor index exception, removed archived `option_3` from the style-sweep matrix, and stopped Mike packers from recreating a live `legacy13` sheet. Kept `option_2`, item bakers, live drawings, music, and Master mute.
- Files changed:
  - `AXEL/axel_project/archive/2026-09-17/` (mike look previews + MANIFEST)
  - `.cursorignore`
  - `AXEL/axel_project/tools/visual_style/variant_matrix.gd`
  - `AXEL/axel_project/tools/visual_style/README_gd_scripts.md`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.gd`
  - `AXEL/axel_project/tools/pack_mike_walk_sheet.py`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Play is unchanged. Style sweep no longer names archived `option_3`. Re-packing Mike does not write a live 13-frame backup.
- Verification: `tools/qa/run_default_playtest.ps1` — required gates exit 0 (princess, determinism, scaffold, scene smoke, item icons). `bot_dialogue_loop` still fails under `--headless` (known). Master `bus/0/mute = true`.
- Notes: Correction to the earlier 2026-09-17 archive row: playtest was re-run in this finish pass. Ring meter, 48/1024 icons, and comment-strip stay later in this same implement chat.

### Hidden leftover ring + 48px combat / 1024px locker icons

- Request: Delete the leftover combat ring widgets. Draw combat item icons at 48px. Draw locker shelf icons at 1024px on screen. Keep Trinity math and the skull. Do not re-bake icon files. Do not strip comments yet.
- Implementation: Removed `RightMeterStack` / `PremiumMeterCircle` / `PremiumProgressBar` and `premium_meter_circle.gd`. Skull + `meter.gd` stay. Combat ITEMS and equipped panel draw at 48px from the live 1024 files. Locker is a one-column full-window scroller with 1024px buttons (`expand_icon` off).
- Files changed:
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/combat_test_scaffold_baseline.tscn`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/player_item_panel.gd`
  - `AXEL/axel_project/scenes/ui/locker_interior.gd`
  - `AXEL/axel_project/tools/qa/item_icon_draw_size_check.gd` (new)
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/combat/VERIFICATION_CHECKLIST.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: No red ring. Trinity still fills the skull. Combat lists show 48px icons. Locker buttons are 1024px and scroll. Icon files stay 75 × 1024.
- Verification: `item_icon_draw_size_check.gd` OK; princess OK; determinism OK; scaffold OK; `item_icons_check.gd` OK (75 × 1024). All exit 0.
- Notes: Walk-near card stays 64px. Did not run `bake_item_icons.gd`.

### Strip every `#` / `##` comment from live `.gd` files

- Request: Remove every `#` and `##` comment from live GDScript, including Inspector docs. Skip `archive/`. Do not change combat math.
- Implementation: Added a string-aware Python stripper and ran it on `AXEL/axel_project` (`132/151` files changed). Quotes and triple-quoted strings kept their `#` characters. Archive copies were not touched.
- Files changed:
  - `AXEL/axel_project/tools/qa/strip_gd_comments.py` (new)
  - Most live `*.gd` under `AXEL/axel_project` (comments only)
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Runtime logic is unchanged. Inspector `@export` descriptions from `##` are gone. Master mute is unchanged.
- Verification: `item_icon_draw_size_check.gd` OK; princess OK; determinism OK; scaffold OK; item icons OK; scene smoke OK (21 scenes); pause/settings/world-loop/cover-sync OK. `audio_bus_layout_check.gd` still fails because Master ships muted (kept on purpose).
- Notes: This is the user-asked mass strip. The no-`##` rule still applies for new comments going forward.

## 2026-09-10

### Player-facing item copy: "more likely to appear" (docs catch-up)

- Request: Rewrite player-facing "spawn weight" blurbs so they say the symbol is more likely to appear. Keep item names.
- Implementation: Updated the five weight-item descriptions and the catalog / generator strings. Combat math and `base_weight` fields are unchanged.
- Files changed:
  - `AXEL/axel_project/combat/data/items/C3_locker_map_pin.tres`
  - `AXEL/axel_project/combat/data/items/U3_weighted_trinity_die.tres`
  - `AXEL/axel_project/combat/data/items/R2_gilded_commons.tres`
  - `AXEL/axel_project/combat/data/items/R3_triune_sigil.tres`
  - `AXEL/axel_project/combat/data/items/E1_ash_crown.tres`
  - `AXEL/axel_project/tools/combat/generate_item_resources.py`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Locker hover, floor walk-near card, and ITEMS hover show wording like "Makes Normal-symbols 8% more likely to appear." Names (including Weighted Trinity Die) stay.
- Verification: Read live `.tres` `description` fields and the catalog table rows. Shipped in `01a3160`.
- Notes: Catch-up — the Sep 10 item-lines row only said "a few description cleanups." Chat: [Simplify spawn weight copy](ee923fd5-56d7-4610-a581-14f6bbac184a).

### Unused-name cleanup in `combat_root.gd` (docs catch-up)

- Request: Clear Godot unused-name warnings in `combat_root.gd`.
- Implementation: Deleted unused `before_snapshot` and `spawn_index`. Renamed `handoff` → `_handoff` (callers still pass the label). Mixed into the later comment-strip working tree; HEAD `01a3160` still has the old names.
- Files changed:
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Play and RNG unchanged. Editor unused-name warnings on those locals go away.
- Verification: Read `combat_root.gd` — no `before_snapshot` / `spawn_index`; `_repopulate_grid_handoff(_handoff: String)` is the live signature.
- Notes: Catch-up — chat [Unused-name cleanup](ac2c8cba-c2fb-4558-bb61-f9e1dcd1c032). Not a combat-math change.

### Ask before Other Models (docs catch-up)

- Request: Grok and Composer must ask before ImageGenerating, screenshotting, or any Other Model subagent, because that quota is limited.
- Implementation: Added the **Ask before Other Models** block to `.cursor/rules/max-effort-temporary.mdc`. Default is inherit / same model. If the user has not said yes, skip that step and say so.
- Files changed:
  - `.cursor/rules/max-effort-temporary.mdc`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: None at runtime. Agents stop spending Other Models quota unless asked.
- Verification: Read the rule block in `max-effort-temporary.mdc`.
- Notes: Catch-up — the Sep 10 ITEMS-wrap row listed this file only for HUD-measure notes. The file is under `.cursor/` (often gitignored). Chat: [Ask before Other Models](804d2d4d-aa80-4009-9a69-3566994f6219).

## 2026-09-17

### Docs catch-up — unlogged week + stale canon

- Request: Check what updates from the past ~week were not in the changelog, then update docs.
- Implementation: Logged the three missed Sep 10 items above. Pointed canon at live paths: HTML prototype is archive-only; music stems are `.ogg`; 1.1 playtest skip is Inspector / `AXEL_SKIP_INTRO=1` (inherited playtest scene archived); icon on-screen QA is `item_icon_draw_size_check.gd`; combat implementation tree no longer names `goal_hud.tscn` or "RunState not built"; README autoload / `scenes/world/` lists match disk.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/references/README_STRUCTURE.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
- Behavior impact: Docs only. Gameplay already matched.
- Verification: Compared git history since `01a3160` (2026-09-10), uncommitted diffs, and Sep 10–17 chats against existing changelog rows. Read live `axel_music.gd` preloads, archive `html/` + `goal_hud.tscn`, and `run_state.gd`.
- Notes: Already logged this week (do not repeat): Sep 10 ITEMS / board-swap / win-lines / Space-E spin / wrap / catalog / DVD mill / 1024 files / mute / item_lines / saves-menu; Sep 17 leftover archive, pointing-hand `ItemMarker`, no-`##` rule, leftover archive finish, ring delete + 48/1024 draw sizes, mass `#` strip. Did not log: file-by-file cleanup inventory, C9–C12 read-only audits, discussion chats, or `2.1_Cafeteria.tscn` `TopDialogueOverlay.visible = false` (looks like an editor save; 4.1 already had the same flag).

### Title menu WASD / interact / back

- Request: WASD should navigate the main menu, E/Enter/Space should confirm, Esc/Backspace should go back a page.
- Implementation: `AxelSettings` copies live `move_*` / `interact` / `back` binds onto Godot’s `ui_up/down/left/right` / `ui_accept` / `ui_cancel` so Control focus uses the same keys as the rest of the game (and follows rebinds). Title, saves, options, credits, and pause now grab a real control on open; disabled Continue/Load/slot/Delete buttons are taken out of the focus chain. Options scroll follows focus and no longer eats WASD.
- Files changed:
  - `AXEL/axel_project/scripts/autoload/axel_settings.gd`
  - `AXEL/axel_project/scenes/Main_Menu/menu_look.gd`
  - `AXEL/axel_project/scenes/Main_Menu/MainMenu.gd`
  - `AXEL/axel_project/scenes/Main_Menu/Saves.gd`
  - `AXEL/axel_project/scenes/Main_Menu/Credits.gd`
  - `AXEL/axel_project/scenes/ui/options_panel.gd`
  - `AXEL/axel_project/scenes/ui/pause_menu.gd`
  - `AXEL/axel_project/tools/qa/menu_nav_check.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AGENTS.md`
- Behavior impact: W/S move up and down the title list, A/D move sideways on Load Game rows, E/Enter/Space press the highlighted button, Esc/Backspace leave Saves/Options/Credits (title Esc still quits). Pause uses the same keys.
- Verification: `menu_nav_check.gd` OK (exit 0). Also OK: determinism, princess, combat scaffold, scene smoke, settings persistence, pause contract, save slots. `audio_bus_layout_check.gd` still fails on the existing Master mute — unrelated.
- Notes: Gameplay code still must not *check* `ui_*`; Godot’s Control widgets are what read those built-ins. Source: Godot 4.7 keyboard/controller focus docs.

### Menu focus outline hugs the label

- Request: The keyboard highlight on main-menu / pause buttons should wrap the words, not stretch across the whole row.
- Implementation: `MenuLook.apply_button` now shrinks each button to its text and draws a tight 1px focus box around that label. Load Game keeps Slot on the left and Delete on the right with a spacer, so those outlines stay on the words too.
- Files changed:
  - `AXEL/axel_project/scenes/Main_Menu/menu_look.gd`
  - `AXEL/axel_project/scenes/Main_Menu/Saves.gd`
  - `AXEL/axel_project/scenes/Main_Menu/Credits.gd`
  - `AXEL/axel_project/scenes/ui/options_panel.gd`
  - `AXEL/axel_project/tools/qa/menu_nav_check.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: Focused Continue / Back / pause Resume (and the other menu buttons) show a small box around the text instead of a full-width bar.
- Verification: `menu_nav_check.gd` OK (exit 0). `save_slots_check.gd` OK.
- Notes: Options checkboxes stay left-aligned so the settings list does not jump to the center.

### Paid spin wording for C1 line

- Request: Use only **Paid Spin** or **Spin** in names, descriptions, and HUD. C1 is Ash Spin Token; descriptions say "each paid spin."
- Implementation: Player-facing names and descriptions now use **paid spin**. Playtest HUD header is **PAID SPINS**. Effect ids are `paid_spin_payout_scalar` / `first_paid_spin_refund`. Baseline line key is `spinpay`. Renamed `C1_ash_spin_token.tres` and `U1_filtered_spinner.tres`. U1 display name is Filtered Spinner. C10 refunds 25% of the bet on the first paid spin. Older changelog rows stay as written (append-only).
- Files changed:
  - `AXEL/axel_project/combat/data/items/C1_ash_spin_token.tres`
  - `AXEL/axel_project/combat/data/items/U1_filtered_spinner.tres`
  - `AXEL/axel_project/combat/data/items/C10_tarnished_coin.tres`
  - `AXEL/axel_project/combat/data/items/R1_fractured_reel.tres`
  - `AXEL/axel_project/combat/data/items/E4_overflow_ledger.tres`
  - `AXEL/axel_project/combat/scripts/item_lines.gd`
  - `AXEL/axel_project/combat/scripts/item_effect_dispatcher.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/test/item_synergy_smoke.gd`
  - `AXEL/axel_project/combat/test/combat_player_item_box_check.gd`
  - `AXEL/axel_project/tools/qa/item_icon_draw_size_check.gd`
  - `AXEL/axel_project/tools/combat/generate_item_resources.py`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_design.md`
  - `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
  - `AXEL/axel_project/plans/references/AXEL_notes.md`
  - `AXEL/axel_project/plans/core/AI_CHANGELOG.md`
- Behavior impact: Math is the same. Players and the ITEMS list now read paid spin instead of the old word. Shop floor-item redraw tickets in notes are still not live.
- Verification: determinism OK (exit 0); princess OK; scaffold OK; scene smoke OK (21 scenes); item_synergy_smoke 44/44; combat_player_item_box_check OK; item_icon_draw_size_check OK; world_combat_loop_check OK.
- Notes: Catalog is the item source of truth. Internal `spinpay` key is not shown as player text.

### Menu focus padding and key-only outline

- Request: Leave space between the button text and the focus box, and only show that box after using keys to navigate.
- Implementation: Padding now lives on the button’s empty style (16×10 px) so the outline sits off the letters. Opening a menu uses `grab_focus(true)` (hidden focus); WASD / arrows reveal the box the same way Godot does after keyboard navigation.
- Files changed:
  - `AXEL/axel_project/scenes/Main_Menu/menu_look.gd`
  - `AXEL/axel_project/scenes/Main_Menu/MainMenu.gd`
  - `AXEL/axel_project/scenes/Main_Menu/Credits.gd`
  - `AXEL/axel_project/tools/qa/menu_nav_check.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: Title / saves / pause start with no white box. After W/S the box appears around the selected label with a gap. Mouse clicks still do not show it.
- Verification: `menu_nav_check.gd` OK (exit 0).
- Notes: Godot 4.7 `Control.grab_focus(hide_focus)` / `has_focus(ignore_hidden_focus)`.

### Red pixel menu focus box

- Request: Make the focus indicator the same red as the font, pixelated like the letters, and a handful of pixels thicker.
- Implementation: Focus StyleBox is now `MenuLook.ACCENT` red, 4 px thick (scales with UI), sharp corners, antialiasing off, nearest filtering — same red block look as VT323.
- Files changed:
  - `AXEL/axel_project/scenes/Main_Menu/menu_look.gd`
  - `AXEL/axel_project/tools/qa/menu_nav_check.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: The keyboard box matches the selected red label instead of a thin white line.
- Verification: `menu_nav_check.gd` OK (exit 0).
- Notes: Godot 4.7 StyleBoxFlat `anti_aliasing` off + `corner_detail` 1 for crisp edges.

## 2026-09-17

### Playtest loop: fights, tutorial, chips, arrow, skull, HUD

- Request: Build all six playtest plans together (loss exit, world loop, overworld [E], 1.2 arrow, skull UX, HUD feel).
- Implementation: Live fights no longer turn on Limit spins. Finalize skips Vice Round / Free Spins choice. GONE waits `WIN_RETURN_SEC` then title, and `_starting_fight` clears on loss. First hub→1.2 leave queues the tutorial without opening LOCKER; floor pickups auto-equip; GOAL ladder is 500 / 750 / 1000 / 1500 / 2000 / 3000 / 5000. Door `[E]` stays up during lines. Item chip is +3px X with the card under it. 1.2 shows a right-arrow after locker or 10s. Keyboard Execute squashes like the mouse; first idle glows the skull; PremiumSkull is 85%. Grid scores are 70px, cascade waits are shorter, multiplier bounces in-circle.
- Files changed:
  - `AXEL/axel_project/scripts/autoload/axel_run.gd`
  - `AXEL/axel_project/scripts/autoload/axel_world.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/scripts/combat_test.gd`
  - `AXEL/axel_project/combat/scripts/hud_piece.gd`
  - `AXEL/axel_project/combat/scripts/premium_skull_meter.gd`
  - `AXEL/axel_project/combat/scripts/symbol_slot.gd`
  - `AXEL/axel_project/combat/scripts/player_item_panel.gd`
  - `AXEL/axel_project/combat/combat_test.tscn`
  - `AXEL/axel_project/combat/ui/terminal_theme.tres`
  - `AXEL/axel_project/scenes/Arc_1/1.3_LockerHub.gd`
  - `AXEL/axel_project/scenes/ui/locker_interior.gd`
  - `AXEL/axel_project/exports/GameManager.gd`
  - `AXEL/axel_project/scenes/Arc_1/1.2_Corridor.gd`
  - `AXEL/axel_project/scenes/fx/DirectionHint.tscn`
  - `AXEL/axel_project/scenes/fx/direction_hint.gd`
  - `AXEL/axel_project/assets/sprites/direction_arrow.png`
  - `AXEL/axel_project/tools/qa/corridor_right_hint_check.gd`
  - `AXEL/axel_project/tools/qa/playtest_hud_interact_check.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: First fight is `GOAL: 0 / 500`. Vice Round with chips left stays in combat. Real broke loss shows GONE, then title. Standing in a door during a line still shows `[E]`. After the locker, a white arrow points right in 1.2.
- Verification: determinism OK (exit 0); princess OK; scaffold OK; scene smoke OK (21 scenes); pause contract OK; menu nav OK; world_combat_loop_check OK; world_combat_roundtrip_check OK; run_state_check OK; hud_piece_placement_check OK; hud_click_rect_check OK; combat_player_item_box_check OK; corridor_right_hint_check OK; playtest_hud_interact_check OK. Replaced the invalid `direction_arrow.png` (escaped-text bytes) with a real 48×48 PNG and reimported. Settings `MOVE_TextBox` now matches the 162×167 click plate so the HUD checks pass.
- Notes: Do not scale `NEW_Execute`. `corridor_from_locker` survives the tutorial fight; `corridor_return_pos` does not.

### Vice names on items and symbols

- Request: Player-facing combat copy should say Vice Round and the real power names, not Trinity / Storm / Star / Love.
- Implementation: Display names now use Vice (Vice Ash, Vice Matchbook, Weighted Vice Die, Cigarette Charm, Alcohol Charm, Bloody Hand Charm, …). Item descriptions say Vice Round and cigarette / alcohol / bloody hand. Princess symbol labels are just Bloody Hand / Alcohol / Cigarette. File stems and `effect_id` `trinity_run` stay. Catalog / generator strings match.
- Files changed:
  - `AXEL/axel_project/combat/data/items/` (family-C, charms, U3, R6, L2, E-A, C-G, E1)
  - `AXEL/axel_project/combat/data/symbols/sym_bloody_hand.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_booze.tres`
  - `AXEL/axel_project/combat/data/symbols/sym_cigarette.tres`
  - `AXEL/axel_project/tools/combat/generate_item_resources.py`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
- Behavior impact: ITEMS, locker hover, and the floor walk-near card show the new names. Combat math is unchanged except U-C (next row).
- Verification: Read live `.tres` `display_name` / `description` fields against the catalog tables.
- Notes: Catch-up for `0c6ffa6`. The paid-spin changelog row only covered C1 / U1 / C10 / R1 / E4. Older rows that still say Weighted Trinity Die stay as written (append-only).

### Vice Matchbook extra spin on first miss

- Request: U-C should not always add a Vice Round spin at the start.
- Implementation: `U-C` `effect_params` is now `first_miss_extra_spins`. Combat grants the extra spin only when the opening Vice Round board has no matches, then fills a new board. Princess check covers both the miss and the already-matching cases.
- Files changed:
  - `AXEL/axel_project/combat/data/items/U-C_trinity_matchbook.tres`
  - `AXEL/axel_project/combat/scripts/item_effect_dispatcher.gd`
  - `AXEL/axel_project/combat/scripts/combat_root.gd`
  - `AXEL/axel_project/combat/test/princess_check.gd`
  - `AXEL/axel_project/tools/combat/generate_item_resources.py`
  - `AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`
- Behavior impact: Equipped Vice Matchbook gives `+1` extra Vice Round spin only after a first spin with no matches.
- Verification: `princess_check.gd` OK (includes `_assert_uc_grants_extra_trinity_spin_only_on_first_miss`).
- Notes: Shipped in `0c6ffa6`. Internal function names still say trinity.

### Load Game delete and tombstone Load

- Request: Load Game should delete a slot (press again to confirm), including dead runs. Load should stay available when only tombstones exist.
- Implementation: `AxelSaves.delete_slot()` removes living slots and tombstones. `has_any_slot()` drives the title Load button; Continue still needs a living slot. Load Game shows Delete on the right; New Game does not. Confirm copy is “Press again to delete this slot.”
- Files changed:
  - `AXEL/axel_project/scripts/autoload/axel_saves.gd`
  - `AXEL/axel_project/scenes/Main_Menu/Saves.gd`
  - `AXEL/axel_project/scenes/Main_Menu/MainMenu.gd`
  - `AXEL/axel_project/tools/qa/save_slots_check.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: After a loss you can still open Load Game and wipe the tombstone. Deleting a slot does not reset volume.
- Verification: `save_slots_check.gd` OK (exit 0).
- Notes: Catch-up for `0c6ffa6`. The menu-focus row mentioned the Delete button layout, not this behavior.

### Title menu pre-graded backdrop

- Request: Title art should stay black/red and not get rematched by noir.
- Implementation: New `assets/ui/title_backdrop.png` on CanvasLayer 100 (above noir 90, below scanline 105 / CRT 108). `MenuLook` draws it behind title / saves / credits / options. Buttons stay on chrome 110.
- Files changed:
  - `AXEL/axel_project/assets/ui/title_backdrop.png`
  - `AXEL/axel_project/scenes/Main_Menu/menu_look.gd`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: Main menu background is the pre-graded title picture. Keyboard focus and WASD are unchanged.
- Verification: `save_slots_check.gd` asserts backdrop layer 100 and a live texture. `menu_nav_check.gd` OK.
- Notes: Catch-up for `0c6ffa6`. Already described in `AI_DOCS.md` layer order; this is the changelog row.

### Shared scene building blocks

- Request: Share exploration building blocks the way floor items use `world_item_pickup.gd`, with per-room leaves (lines, flags, dest scenes) and no behavior change on working rooms.
- Implementation: Added `ExplorationRoom`, `ExplorationTransition`, `LorePickup`, `InteractSpot`, `MemoryStill`, `MemoryFrame`, and `Player.tscn`. Memory glow now remaps/hides itself from instance exports. Walkable rooms and memory stills call those trunks instead of copied functions. 1.1 intro, 1.2 arrow, 2.4 depth, frozen peeks, and kitchen Y `90` stay local.
- Files changed:
  - `AXEL/axel_project/scenes/core/exploration_room.gd`
  - `AXEL/axel_project/scenes/core/exploration_transition.gd`
  - `AXEL/axel_project/scenes/core/lore_pickup.gd`
  - `AXEL/axel_project/scenes/core/interact_spot.gd`
  - `AXEL/axel_project/scenes/core/memory_still.gd`
  - `AXEL/axel_project/scenes/core/memory_frame.gd`
  - `AXEL/axel_project/scenes/player/Player.tscn`
  - `AXEL/axel_project/scenes/fx/memory_indicator.gd`
  - `AXEL/axel_project/scenes/Arc_1/` `1.1` `1.2` `1.4`
  - `AXEL/axel_project/scenes/Arc_2/` `2.1` `2.2` `2.3` `2.4`
  - `AXEL/axel_project/scenes/Arc_3/` `3.1` `3.2`
  - `AXEL/axel_project/scenes/Arc_4/` `4.1` `4.2`
  - `AXEL/axel_project/scenes/Arc_5/` `5.1` `5.2`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
- Behavior impact: Same doors, pickups, stills, and peeks; new rooms should instance the shared blocks instead of pasting functions.
- Verification: `scene_smoke_check.gd` OK (21 scenes). `interact_arrival_check.gd` OK. `player_cover_sync_check.gd` / `player_spawn_sync_check.gd` / `player_walk_speed_check.gd` OK. `corridor_depth_seed_check.gd` OK. `world_combat_loop_check.gd` / `world_combat_roundtrip_check.gd` OK. `determinism_check.gd` / `princess_check.gd` / `combat_test_scaffold_check.gd` OK.
- Notes: Room scripts still hold peek/occlusion leaves. Do not merge frozen peek policies.

### Shared-block how-to catch-up

- Request: Update docs so how-to matches the shared exploration blocks.
- Implementation: Canon how-to now says new rooms `extends ExplorationRoom`, instance `Player.tscn`, set glow exports, and use `LorePickup` / `MemoryStill`. Per-arc Implemented notes no longer tell you to copy `_sync_memory_indicator` or paste Front/ShadowOutline. Frozen peeks, kitchen Y `90`, 1.1 intro, 1.2 arrow, and 2.4 depth stay local.
- Files changed:
  - `AXEL/axel_project/plans/core/AI_DOCS.md`
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDING.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC1.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC2.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC3.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC4.md`
  - `AXEL/axel_project/plans/scenes/AXEL_SCENES_ARC5.md`
  - `AXEL/axel_project/plans/references/README_STRUCTURE.md`
- Behavior impact: None (docs only).
- Verification: Read-back of how-to vs live `extends ExplorationRoom` / `MemoryStill` / `Player.tscn` / glow exports. No game scripts changed in this pass.
- Notes: Does not rewrite the Shared scene building blocks row above. Do not copy `_begin_scene_change` / `_show_interact_prompt` into a new room.


