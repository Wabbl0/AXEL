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
- **Global post-FX stack (non-combat):** Autoload `AxelPostFxStack` (`res://scripts/autoload/axel_post_fx_stack.gd`) applies `NoirPaletteOverlay` + `ScanlineOverlay` + `CrtPluginOverlay` on every scene change. **Excluded:** any scene whose `scene_file_path` begins with `res://combat/`. Do not embed those three overlays in narrative/overworld `.tscn` files — add per-scene tuning via `AxelPostFxStack.get_noir_filter_rect()` or shader defaults. Style-sweep / isolated tests: set env `AXEL_DISABLE_POST_FX=1` to avoid double stacks.
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
- **Protected combat test scaffold:** `AXEL/axel_project/combat/combat_test.tscn` is canonical and must keep required nodes (`%CombatRoot`, `%MetaBox`, `%SeedSpinBox`, `%SpinButton`, `%BankrollLabel`, stake row, SUPER FS choice buttons, etc.). Duplicate/cleanup/refactor tasks must **not** delete or “simplify away” this scaffold. Run `res://combat/test/combat_test_scaffold_check.gd` (also gated inside `scene_smoke_check.gd`) before combat changes; pre-commit runs `tools/qa/check_combat_test_scaffold.py --staged`.

## 9) Agent Workflow Requirements

For substantive AXEL requests:

1. Read this file first.
2. Check relevant source docs for the touched subsystem.
3. For long or multi-step work, provide a live progress feed in chat while executing.
4. Progress feed verbosity policy:
   - **Planning, exploration, or blocked states:** use the full structured format (current step, command/tool in use, files being checked/read, result/status so far, next step, stuck/not stuck).
   - **Dense implementation loops** (editing files, fixing lints, iterating on code): a concise one-liner status is sufficient.
5. **Clarification-first (mandatory):** If requirements, scope, or implementation details are ambiguous, ask the user targeted questions before assuming defaults. Do not infer unstated layout, economy, or behavior choices without confirmation.
6. **Planning intake gate (mandatory for new planning requests):**
   - Ask at least **2 targeted clarifying questions** before drafting/creating a plan.
   - After the first two answers, continue asking additional targeted questions whenever ambiguity remains.
   - Do not proceed to plan output until scope, expected behavior, and constraints are clear enough to summarize concisely without assumptions.
   - Convert potential assumptions into explicit user-confirmed decisions; do not assume hidden defaults.
7. Implement changes.
8. Verify behavior (tests or explicit manual checks).
9. **Beginner fix teaching (mandatory when a fix was implemented):** After fixing a problem, explain it in simple beginner coding terms (no metaphors). Keep it short. Use exactly 3 bullets:
   - **Cause:** what code/state was wrong and why it broke behavior.
   - **Fix:** what files/functions were changed and what the new behavior is.
   - **What to learn:** one practical takeaway about project structure or coding pattern.
10. Append one entry to `AXEL/axel_project/plans/core/AI_CHANGELOG.md` if change was implemented.
11. If a task introduces or updates a reusable workflow/agent pipeline (scripts, specs, rules, runner contracts), record it in this file and in `.cursor/rules/axel-ai-docs-governance.mdc` so future chats can reference it directly.

**Governance rule / AI_DOCS responsibility split:** The always-applied rule (`.cursor/rules/axel-ai-docs-governance.mdc`) is intentionally concise — it directs agents to read this file and enforces the hard conflict gate, QA opt-in trigger, and canonical alias stability. All detailed procedures, command sets, invariants, and pipeline specs live here in `AI_DOCS.md` and in the referenced subsystem docs (rubric, skill, specs). Do not re-duplicate detailed content into the governance rule.

### Context routing (token-efficient new chats)

- **Contract:** `plans/core/AGENT_CONTEXT_ROUTING.md` — keyword classification, confidence rules, strict bundle locks, unlock phrases, prefix fast-paths.
- **Active packs:** `COMBAT_MIN_CONTEXT.md`, `SCENES_MIN_CONTEXT.md`, `NARRATIVE_MIN_CONTEXT.md`, `VISUAL_STYLE_MIN_CONTEXT.md` under `plans/core/context_packs/`.
- **Prefixes:** `combat:`, `scenes:`, `narrative:`, `vfx:` (`vfx:` maps to `visual_style` bundle; no `visual_style:` prefix).
- **Startup:** Governance rule item 1 runs routing before loading full unrelated canon (skip irrelevant `AI_DOCS.md` sections per active lock).
- **Ambiguous first message:** Ask which bundle applies; do not assume a domain.
- **Cross-domain:** Primary bundle only until user sends `unlock <bundle>` for a second domain.
- **Indexing:** `.cursorignore` aggressively excludes caches, tool previews, `exports/Drawings/**`, and `AXEL/html/pictures/**`; `@`-mention those files when a task needs visual prototype references.
- **Hierarchy unchanged:** §3 conflict resolution and §10 hard conflict gate still apply; routing does not override invariants.
- **Future bundles:** Add `context_packs/*_MIN_CONTEXT.md`, register in routing doc, update governance + changelog together (`qa_tools` reserved).
- **Meta-process:** `meta:` prefix — no domain pack; see `AGENT_CONTEXT_ROUTING.md` §1b and `CHAT_LANE_PROTOCOL.md`.
- **Chat lanes:** `CHAT_LANE_PROTOCOL.md` — Lane A (discovery) vs Lane B (implementation); compact handoff between chats.

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
  - Progress checklist (completion milestones + hard gates): `AXEL/axel_project/plans/qa/QA_PROGRESS_CHECKLIST.md`
  - Canon consistency audit contract: `AXEL/axel_project/plans/qa/AXEL_CANON_CONSISTENCY_AUDIT.md`
  - Run log: `AXEL/axel_project/plans/qa/AXEL_QA_RUN_LOG.md`
  - Analytics: `AXEL/axel_project/plans/qa/AXEL_QA_ANALYTICS.md` (+ `AXEL_QA_ANALYTICS.svg` — **Progress** vs **Quality** dual primary)
  - Generator: `AXEL/axel_project/tools/qa/update_qa_analytics.py`
  - **Default execution:** combined static + full playtest (includes `canon_consistency_audit.gd` for combat/movement visual+gameplay drift). See rubric §Playtest-mode for exact commands, gate/metrics semantics, canon audit (warn+recommend), item balance audit, and skip policy.
  - **Persistence invariant (mandatory):** every run appends a payload to the run log and refreshes analytics via the generator script. See rubric §Persistent-analytics-payload for required keys.
  - **Static-only override:** `qa static` skips all headless commands.
  - **Output:** concise, **technical-first**; **Recommendations** required every run (minimum 3).
- `bot playthrough` = headless overworld input bots. Architecture and authoring guide: `AXEL/axel_project/tools/bots/README.md`. Included by default in the `combat + scene smoke + bot playthrough` confidence tier (see rubric §Playtest-mode).
- If this agent is updated, refresh `AI_DOCS.md`, `.cursor/rules/axel-ai-docs-governance.mdc`, and `AI_CHANGELOG.md` together.

## 12) Simulated QA Reviewer

- **Purpose:** Opt-in simulated QA with concise **technical-first** reports and **mandatory recommendations** (≥3). Default run is combined static + full playtest, including canon consistency audit (`res://tools/qa/canon_consistency_audit.gd`) for combat test + movement scenes; see rubric §Playtest-mode for details.
- **Invocation:** On `qa agent`, `qa`, `run qa`, `qa playtest`, or user agreement after a substantive change, read and apply `.cursor/skills/axel-simulated-qa/SKILL.md`.
- **Artifacts:** listed under `qa agent` in §11 above.
- **Governance:** Agents should **ask** after substantial AXEL edits whether to run QA; see `.cursor/rules/axel-ai-docs-governance.mdc`.

## 13) Consistency Checklist (Quick)

Before finishing:

- [ ] Terminology and mechanics match current canon.
- [ ] No architecture-layer mixing without intent.
- [ ] Style/lore choices align with AXEL identity.
- [ ] Conflicts were resolved using hierarchy and documented.
- [ ] New planning requests asked at least 2 clarifying questions and continued clarification until assumption-free plan readiness.
- [ ] Implemented request was appended to `AI_CHANGELOG.md`.
- [ ] If a fix was implemented, user received a concise beginner explanation (Cause / Fix / What to learn; no metaphors).

## 14) Multi-Machine Git Preservation

Use GitHub as the source of truth across computers. OneDrive sync is not a substitute for version control.

### Milestone refs (2026-05-22 combat recovery)

- Branch: `backup/2026-05-22-combat-state` → commit `4110c74`
- Tag: `checkpoint-2026-05-22-combat-state` → same commit (annotated)
- Commit range preserved: `7144462` through `4110c74` (pre-dedup feature stack + editor preview guards)

### Before starting work on a new machine

1. `git fetch --all --prune`
2. `git status -sb` — confirm branch and whether you are ahead/behind `origin`
3. `git pull --ff-only` on `main` (or your feature branch) when behind

### Before leaving a machine

1. `git status -sb` — ensure intentional changes are committed
2. `git push` (branch) and `git push --tags` if you created tags locally
3. For major milestones, create durable refs and push them:
   - `git branch backup/YYYY-MM-DD-short-name <commit>`
   - `git tag -a checkpoint-YYYY-MM-DD-short-name <commit> -m "reason"`
   - `git push origin backup/YYYY-MM-DD-short-name`
   - `git push origin checkpoint-YYYY-MM-DD-short-name`

### Recovering a milestone on any machine

```bash
git fetch --all --prune
git checkout backup/2026-05-22-combat-state
# or
git checkout checkpoint-2026-05-22-combat-state
```

### Why "Changes" may be empty in the IDE

- If edits are already committed and pushed, the working tree is clean — nothing left to stage.
- Check recent history: `git log --oneline -n 10`
- Check remote parity: `git status -sb` should not show unpushed commits before switching machines

## 15) Token Budget and Turn Economy

Default limits to reduce API burn while preserving canon quality. Full lane workflow: `CHAT_LANE_PROTOCOL.md`. Validation: `API_USAGE_VALIDATION_TRACKER.md`.

### Per-chat defaults

| Chat type | Max doc load | Tool discipline | QA |
|-----------|--------------|-----------------|-----|
| Lane A discovery | Routed pack OR meta §3+§15 only | One batched search before follow-ups | Off |
| Lane B implement | Active pack + files in handoff | No re-read unchanged canon same chat | User-requested only |
| Meta-process | §3, §15, lane protocol | Edit only cited governance files | Off |

### Turn rules

- **Prefix first:** Start new chats with `combat:`, `scenes:`, `narrative:`, `vfx:`, or `meta:` — skips ambiguity turns.
- **One domain:** No second pack without `unlock <bundle>`.
- **No duplicate reads:** Do not re-open `AI_DOCS.md` or the active pack if already loaded this chat unless task scope changed.
- **Plan skip:** If handoff has task, files, and acceptance criteria → implement directly (no separate plan phase).
- **Progress:** One-liner during dense edits; full structured feed only when planning, exploring, or blocked (§9).
- **Planning intake:** Still ≥2 clarifying questions for **new** ambiguous planning requests; skip when user supplied Lane B handoff.

### Exceptions (allow extra depth)

- Hard conflict gate (§10) — full options required.
- User says `unlock <bundle>`, `run qa`, or `deep dive`.
- Scaffold/combat canon risk — read `combat_test` scaffold paths before combat edits.
- Quality regression in tracker — restore bundle-specific depth until median ≥ 4.
