# AXEL AI Docs

Persistent guidance for AI agents working in this repository. This file is the canonical memory layer for consistency across chats.

## 1) Purpose

- Keep implementation decisions consistent across exploration, narrative, and combat work.
- Prevent drift between design intent, code behavior, and visual/lore direction.
- Provide a stable hierarchy for conflict resolution when multiple docs differ.

## 2) Scope

Applies to changes in:

- `AXEL/axel_project/plans/*`
- `AXEL/axel_project/combat/*`
- `AXEL/axel_project/exports/*`
- `AXEL/html/*`
- `AXEL/axel_project/scenes/*`
- `AXEL/axel_project/scripts/*`

## 3) Canonical Source Hierarchy

When two sources conflict, resolve in this order:

1. This file: `AXEL/axel_project/plans/core/AI_DOCS.md`
2. `AXEL/axel_project/plans/combat/AXEL_combat_implementation.md`
3. `AXEL/axel_project/plans/combat/AXEL_combat_design.md`
4. `AXEL/axel_project/plans/references/AXEL_notes.md`
5. Prototype style/lore evidence in `AXEL/html/game.html`, `AXEL/html/styles_game.css`, `AXEL/html/styles.css`
6. Exported references in `AXEL/axel_project/exports/*` and `AXEL/axel_project/exports/Moon Princess Files/*`

If you intentionally choose a lower-priority source for a task, record the reason in `AI_CHANGELOG.md`.

## 4) Architecture Split (Do Not Blur Layers)

### Narrative/prototype layer

- `AXEL/html/game.html` + `AXEL/axel_project/exports/game_data.json` define choice-based story flow, flags, memories, and ending logic.
- `AXEL/axel_project/exports/GameManager.gd` is the narrative runner model/reference.

### Combat layer

- `AXEL/axel_project/combat/scripts/combat_root.gd` orchestrates combat state and spin lifecycle.
- Combat is Moon Princess inspired, but implemented as native Godot scripts/resources.
- Files in `AXEL/axel_project/exports/Moon Princess Files/*` are reference captures only, not authoritative runtime logic.

## 5) Combat Invariants

Keep these rules stable unless explicitly asked to redesign:

- Combat grid is 5x5 and driven through deterministic RNG patterns.
- Wins are line-based row/column runs of 3+ contiguous symbols (no flood-fill cluster wins for main resolution).
- Wild spawn rule: only winning lines of exactly 3 can spawn a wild in the middle cell.
- Multiplier progression is tied to cascade/drop progression, not arbitrary per-line increments.
- `combat_root.gd` remains the orchestration point for spin -> resolve -> cascade -> power -> checks.
- Princess/premium alias map is fixed:
  - `cigarette` -> Storm
  - `booze`/`alcohol` -> Star
  - `bloody hand` -> Love
- Terminology lock from notes:
  - Regular Free Spins = Trinity Run
  - SUPER Free Spins = later bonus mode
  - If a request says only "Free Spins", clarify intended mode before changing behavior.

### Combat item catalog (agent convention)

- Extended item ids in plans follow **`TIER-FAMILY`** with **uppercase** letters (e.g. `C-A`, `U-M`, `L-H`); baseline items keep **digit** suffixes (`C1`, `R3`, `E2`, `L1`).
- When the author says **add an item** (new mechanic) without narrowing scope, default spec is **five variants** (**Common → Legendary**). Single-tier items only when explicitly requested.
- Reference catalog (single source): **`AXEL/axel_project/plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`** — edit only this file for roster changes. `.cursor/plans/combat_starter_item_catalog_fee3a6f1.plan.md` is a stub pointer, not a duplicate catalog.

## 6) Style and Tone Canon

Primary style direction:

- Palette baseline: black + blood red (`#ff0000`) + dark blood (`#4a0000`).
- CRT/scanline/glitch/shake aesthetics are core identity, not optional decoration.
- Typography center: VT323 (Space Mono may be used for supporting text where explicitly needed).
- UI and narrative mood: dread, guilt, memory corruption, morally uneasy wins.
- Big wins should read as unsettling/intrusive, not purely celebratory.

Known source conflict guidance:

- If symbol gameplay needs additional colors for readability, keep broader UI frame in AXEL palette and note exceptions.
- If any title strings differ (for example AXEL vs GUILT in legacy exports), prefer current project naming in active gameplay files and document transitional naming in changelog entries.

## 7) Lore/World Consistency

Keep these narrative anchors coherent across edits:

- Setting: decaying school, guilt-driven return, locker as hub/sanctuary.
- Core progression motifs: memories, key items (Flashlight/Key/Shovel/Name), basement confrontation.
- Axel identity reveal and ending logic remain central to branching outcomes.
- Cigarettes/lighter ritual and memory cues are recurring thematic devices.

## 8) Implementation Guardrails

- Treat plans as design truth; treat code as behavior truth; reconcile both before changing mechanics.
- Avoid introducing machine-absolute paths in shared gameplay code.
- Keep deterministic behavior for systems intended to be replayable/testable.
- Prefer additive, scoped changes over broad rewrites.
- When changing one subsystem, verify cross-effects on:
  - story flags/memories/endings
  - combat goals/economy
  - style/thematic presentation
- **Editor collision colors:** cyan/teal fill and outlines for 2D collision shapes via `debug/shapes/collision/` project settings — visible in the editor viewport only, invisible at runtime unless Debug > Visible Collision Shapes is manually toggled. This is a readability exception to the AXEL palette. Legacy runtime overlay scripts remain in `scripts/debug/` but the autoload is disabled. See `AXEL/axel_project/plans/core/PLAYTEST_DEBUG_COLLISIONS.md`.

## 9) Agent Workflow Requirements

For substantive AXEL requests:

1. Read this file first.
2. Check relevant source docs for the touched subsystem.
3. For long or multi-step work, provide a live progress feed in chat while executing.
4. Progress feed verbosity policy:
   - **Planning, exploration, or blocked states:** use the full structured format (current step, command/tool in use, files being checked/read, result/status so far, next step, stuck/not stuck).
   - **Dense implementation loops** (editing files, fixing lints, iterating on code): a concise one-liner status is sufficient.
5. **Clarification-first (mandatory):** If requirements, scope, or implementation details are ambiguous, ask the user targeted questions before assuming defaults. Do not infer unstated layout, economy, or behavior choices without confirmation.
6. Implement changes.
7. Verify behavior (tests or explicit manual checks).
8. Append one entry to `AXEL/axel_project/plans/core/AI_CHANGELOG.md` if change was implemented.
9. If a task introduces or updates a reusable workflow/agent pipeline (scripts, specs, rules, runner contracts), record it in this file and in `.cursor/rules/axel-ai-docs-governance.mdc` so future chats can reference it directly.

**Governance rule / AI_DOCS responsibility split:** The always-applied rule (`.cursor/rules/axel-ai-docs-governance.mdc`) is intentionally concise — it directs agents to read this file and enforces the hard conflict gate, QA opt-in trigger, and canonical alias stability. All detailed procedures, command sets, invariants, and pipeline specs live here in `AI_DOCS.md` and in the referenced subsystem docs (rubric, skill, specs). Do not re-duplicate detailed content into the governance rule.

## 10) Premium-to-Auto Planning Protocol

For all substantive AXEL tasks, planning outputs must be implementation-ready for later auto-model execution.

- Run an intent-deduction pass before proposing implementation:
  - infer likely meaning beyond literal prompt wording
  - correlate request to AXEL architecture boundaries (combat, scenes, narrative, tools, reusable agents)
  - call out cross-system effects and pipeline touch points
- Run a canon/guideline alignment check against this file's hierarchy and invariants.
- Use a stable handoff format for high-detail plans (see `AXEL/axel_project/plans/core/PREMIUM_TO_AUTO_HANDOFF_TEMPLATE.md`) that includes:
  - inferred intent
  - alignment/conflict result
  - impact map with concrete file candidates
  - ordered implementation tasks
  - validation and acceptance criteria
  - risk flags and fallback/rollback guidance
  - explicit blockers needing user decisions
- **Hard conflict gate:** if a request conflicts with canon/invariants, stop immediately and present 2-4 explicit options (strict-canon path, adapted variant, explicit override path with trade-offs). Do not continue planning or implementation until user selects an option.

## 11) Reusable Agent Names

- `scene agent` = the scene-building draft pipeline centered at:
  - `AXEL/axel_project/plans/scenes/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/tools/scene_builder/*`
  - **Canonical filename invariant:** `scene agent` outputs MUST target the
    canonical numbered scene file (e.g. `1.2_Corridor.tscn` under
    `scenes/Arc_1/`), overwriting the existing placeholder. It MUST NEVER
    create or overwrite a non-canonical alias such as `Corridor.tscn`. See
    "Canonical Filename Invariant" in `scenes/SCENE_BUILDER_AGENT_SPEC.md`.
  - **Completion cleanup invariant:** once the user says a scene is complete,
    `scene agent` MUST clean up non-pipeline temporary artifacts created during
    look-dev (for example filter-preview folders/comparison renders) under
    `tools/scene_builder/output/`, while keeping canonical draft contracts
    unless the user explicitly asks for a full purge.
- `qa agent` (short forms: `qa`, `run qa`) = simulated QA review workflow.
  - Skill: `.cursor/skills/axel-simulated-qa/SKILL.md`
  - Rubric (canonical command set, confidence tiers, scoring, analytics payload): `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
  - Run log: `AXEL/axel_project/plans/qa/AXEL_QA_RUN_LOG.md`
  - Analytics: `AXEL/axel_project/plans/qa/AXEL_QA_ANALYTICS.md`
  - Generator: `AXEL/axel_project/tools/qa/update_qa_analytics.py`
  - **Default execution:** combined static + full playtest. See rubric §Playtest-mode for exact commands, gate/metrics semantics, item balance audit, and skip policy.
  - **Persistence invariant (mandatory):** every run appends a payload to the run log and refreshes analytics via the generator script. See rubric §Persistent-analytics-payload for required keys.
  - **Static-only override:** `qa static` skips all headless commands.
  - **Output:** concise, **technical-first**; **Recommendations** required every run (minimum 3).
- `bot playthrough` = headless overworld input bots. Architecture and authoring guide: `AXEL/axel_project/test/bots/README.md`. Included by default in the `combat + scene smoke + bot playthrough` confidence tier (see rubric §Playtest-mode).
- If this agent is updated, refresh `AI_DOCS.md`, `.cursor/rules/axel-ai-docs-governance.mdc`, and `AI_CHANGELOG.md` together.

## 12) Simulated QA Reviewer

- **Purpose:** Opt-in simulated QA with concise **technical-first** reports and **mandatory recommendations** (≥3). Default run is combined static + full playtest; see rubric §Playtest-mode for details.
- **Invocation:** On `qa agent`, `qa`, `run qa`, `qa playtest`, or user agreement after a substantive change, read and apply `.cursor/skills/axel-simulated-qa/SKILL.md`.
- **Artifacts:** listed under `qa agent` in §11 above.
- **Governance:** Agents should **ask** after substantial AXEL edits whether to run QA; see `.cursor/rules/axel-ai-docs-governance.mdc`.

## 13) Consistency Checklist (Quick)

Before finishing:

- [ ] Terminology and mechanics match current canon.
- [ ] No architecture-layer mixing without intent.
- [ ] Style/lore choices align with AXEL identity.
- [ ] Conflicts were resolved using hierarchy and documented.
- [ ] Implemented request was appended to `AI_CHANGELOG.md`.
