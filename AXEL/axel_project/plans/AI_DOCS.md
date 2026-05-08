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

1. This file: `AXEL/axel_project/plans/AI_DOCS.md`
2. `AXEL/axel_project/plans/AXEL_combat_implementation.md`
3. `AXEL/axel_project/plans/AXEL_combat_design.md`
4. `AXEL/axel_project/plans/AXEL_notes.md`
5. Prototype style/lore evidence in `AXEL/html/game.html`, `AXEL/html/styles_game.css`, `AXEL/html/styles.css`
6. Exported references in `AXEL/axel_project/exports/*` and `AXEL/axel_project/exports/moon_princess_files/*`

If you intentionally choose a lower-priority source for a task, record the reason in `AI_CHANGELOG.md`.

## 4) Architecture Split (Do Not Blur Layers)

### Narrative/prototype layer

- `AXEL/html/game.html` + `AXEL/axel_project/exports/game_data.json` define choice-based story flow, flags, memories, and ending logic.
- `AXEL/axel_project/exports/GameManager.gd` is the narrative runner model/reference.

### Combat layer

- `AXEL/axel_project/combat/scripts/combat_root.gd` orchestrates combat state and spin lifecycle.
- Combat is Moon Princess inspired, but implemented as native Godot scripts/resources.
- Files in `AXEL/axel_project/exports/moon_princess_files/*` are reference captures only, not authoritative runtime logic.

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

## 9) Agent Workflow Requirements

For substantive AXEL requests:

1. Read this file first.
2. Check relevant source docs for the touched subsystem.
3. For long or multi-step work, provide a live progress feed in chat while executing.
4. Live progress feed should include:
   - current step
   - command/tool in use
   - files being checked/read
   - result/status so far
   - next step
   - stuck/not stuck
5. Implement changes.
6. Verify behavior (tests or explicit manual checks).
7. Append one entry to `AXEL/axel_project/plans/AI_CHANGELOG.md` if change was implemented.
8. If a task introduces or updates a reusable workflow/agent pipeline (scripts, specs, rules, runner contracts), record it in this file and in `.cursor/rules/axel-ai-docs-governance.mdc` so future chats can reference it directly.

## 10) Premium-to-Auto Planning Protocol

For all substantive AXEL tasks, planning outputs must be implementation-ready for later auto-model execution.

- Run an intent-deduction pass before proposing implementation:
  - infer likely meaning beyond literal prompt wording
  - correlate request to AXEL architecture boundaries (combat, scenes, narrative, tools, reusable agents)
  - call out cross-system effects and pipeline touch points
- Run a canon/guideline alignment check against this file's hierarchy and invariants.
- Use a stable handoff format for high-detail plans (see `AXEL/axel_project/plans/PREMIUM_TO_AUTO_HANDOFF_TEMPLATE.md`) that includes:
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
  - `AXEL/axel_project/plans/SCENE_BUILDER_AGENT_SPEC.md`
  - `AXEL/axel_project/tools/scene_builder/*`
  - **Canonical filename invariant:** `scene agent` outputs MUST target the
    canonical numbered scene file (e.g. `1.2_Corridor.tscn` under
    `scenes/Arc_1/`), overwriting the existing placeholder. It MUST NEVER
    create or overwrite a non-canonical alias such as `Corridor.tscn`. See
    "Canonical Filename Invariant" in `SCENE_BUILDER_AGENT_SPEC.md`.
  - **Completion cleanup invariant:** once the user says a scene is complete,
    `scene agent` MUST clean up non-pipeline temporary artifacts created during
    look-dev (for example filter-preview folders/comparison renders) under
    `tools/scene_builder/output/`, while keeping canonical draft contracts
    unless the user explicitly asks for a full purge.
- `qa agent` (short form: `qa`) = simulated QA review workflow centered at:
  - `.cursor/skills/axel-simulated-qa/SKILL.md`
  - `AXEL/axel_project/plans/AXEL_QA_REVIEW_RUBRIC.md`
  - `AXEL/axel_project/plans/AXEL_QA_RUN_LOG.md`
  - `AXEL/axel_project/plans/AXEL_QA_ANALYTICS.md`
  - `AXEL/axel_project/tools/qa/update_qa_analytics.py`
  - **Default output:** concise, **technical-first** (evidence, scores, data); **Recommendations** required every run (minimum 3).
  - **Playtest mode** (`qa playtest` / high-confidence): run headless checks documented in rubric §Playtest-mode, including `res://test/scene_smoke_check.gd`.
  - **Persistence invariant:** every `qa` run appends one structured payload to `AXEL_QA_RUN_LOG.md`, then refreshes `AXEL_QA_ANALYTICS.md` via `tools/qa/update_qa_analytics.py` so score trends remain continuous over production.
- If this agent is updated, refresh `AI_DOCS.md`, `.cursor/rules/axel-ai-docs-governance.mdc`, and `AI_CHANGELOG.md` together.

## 12) Simulated QA Reviewer

- **Purpose:** Opt-in simulated QA: concise **technical-first** reports (findings, scores, analytics), **mandatory recommendations** (≥3), optional short player-feel only when explicitly requested. **Playtest mode** adds headless combat + scene smoke simulations for higher confidence (see rubric §Playtest-mode).
- **Invocation:** If the user requests `qa agent`, `qa`, or `qa playtest` / playtest-level confidence, read and apply `.cursor/skills/axel-simulated-qa/SKILL.md`. Also use when the user agrees to run QA after a substantive change.
- **Artifacts:**
  - `AXEL/axel_project/plans/AXEL_QA_REVIEW_RUBRIC.md` — axes, weights, taxonomy, **Playtest-mode** command set and confidence tiers
  - `AXEL/axel_project/plans/AXEL_QA_RUN_LOG.md` — append-only run history with machine-readable payloads (scores/findings/categories/playtest outcomes/bugs)
  - `AXEL/axel_project/plans/AXEL_QA_ANALYTICS.md` — auto-generated historical dashboard with Mermaid trends for `Total` + `S/N/I/E/C/R`
  - `AXEL/axel_project/tools/qa/update_qa_analytics.py` — parser/generator that rebuilds analytics from run-log payloads
  - `AXEL/axel_project/test/scene_smoke_check.gd` — headless canonical scene smoke (used by playtest mode)
- **Governance:** Agents should **ask** after substantial AXEL edits whether to run this QA; see `.cursor/rules/axel-ai-docs-governance.mdc`.

## 13) Consistency Checklist (Quick)

Before finishing:

- [ ] Terminology and mechanics match current canon.
- [ ] No architecture-layer mixing without intent.
- [ ] Style/lore choices align with AXEL identity.
- [ ] Conflicts were resolved using hierarchy and documented.
- [ ] Implemented request was appended to `AI_CHANGELOG.md`.
