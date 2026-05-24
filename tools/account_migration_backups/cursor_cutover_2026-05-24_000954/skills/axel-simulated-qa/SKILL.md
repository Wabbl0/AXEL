---
name: axel-simulated-qa
description: >-
  Concise technical-first QA for AXEL: canon/combat checks, scored rubric,
  analytics, mandatory recommendations (min 3). Default playtest runs headless
  combat + scene smoke + overworld bot playthrough simulations for
  high-confidence reports. Use when the user asks for qa, run qa, qa agent,
  QA simulation, or post-substantive-change review.
---

# AXEL Simulated QA Reviewer (`qa agent` / `qa`)

## Canonical call names

- `qa agent`, `qa`, or `run qa` — same workflow; **default run is combined static + full playtest (combat + scene smoke + canon consistency audit + bot playthrough)**.
- `qa static` — static-only override when explicitly requested (skips all headless commands, including bots).
- `qa playtest` — playtest emphasis alias; same default command set as plain `qa`, still include the static review in the same run.

## Default voice (technical-first)

- Lead with **evidence, findings, scores, and data** — not player-feel prose.
- **Brevity:** keep the whole report skimmable (short bullets; avoid long paragraphs).
- **Player feel:** only if the user explicitly asks for it — then add **one short paragraph** (max ~3 sentences) after the technical block; otherwise omit.

## Modes

| Mode | When | Confidence |
|------|------|------------|
| **Combined (default)** | User asks `qa`, `run qa`, or `qa agent` | `combat + scene smoke + bot playthrough` when all gates pass; otherwise cite achieved tier + static evidence and list every skipped command |
| **Static** | User explicitly asks `qa static` | Lower — cite `static review` |
| **Playtest emphasis** | User asks `qa playtest` / high-confidence | Same default command set as Combined (combat + scene smoke + bot playthrough) plus static review |

## Before you write (static)

1. `AXEL/axel_project/plans/core/AI_DOCS.md`
2. `AXEL/axel_project/plans/qa/AXEL_QA_REVIEW_RUBRIC.md`
3. `AXEL/axel_project/plans/qa/QA_PROGRESS_CHECKLIST.md` (for **Progress** scoring)
4. Subsystem docs as needed (combat plans, scene blueprints, `SCENE_LAYOUT_RULES.md`, scene_builder outputs).

## Before you write (playtest)

1. Same reads as static.
2. Run the **default command set** from rubric §Playtest-mode (repo root, `tools/cmd/godot.cmd` on Windows). See rubric for exact commands, pass/fail gate semantics, metrics-only rules, item balance audit conditions, and skip policy.

## Default execution contract

- For plain `qa`, `run qa`, or `qa agent`, do **both** in one run: static review **and** full playtest command set from rubric §Playtest-mode (combat + scene smoke + bot playthrough + **canon consistency audit** + conditional item balance audit).
- **Canon consistency audit:** parse `CANON_AUDIT_JSON` from `canon_consistency_audit.gd` stdout. Map findings to **Technical findings** and **Recommendations** (warn+recommend; audit always exits 0). Include at least one combat- and one movement-scoped recommendation when findings exist.
- Only skip playtest commands when environment/tooling is unavailable; report **every** skipped command explicitly and downgrade confidence per rubric §Skip-policy.
- `qa static` is the only documented opt-out from the playtest command set.
- **Persistence footer (all modes):** After generating the report, always: (1) append machine-readable payload to `AXEL_QA_RUN_LOG.md`, (2) run `python AXEL/axel_project/tools/qa/update_qa_analytics.py`, (3) verify both `AXEL_QA_ANALYTICS.md` and `AXEL_QA_ANALYTICS.svg` were regenerated.

## Brevity caps (hard)

- **Scope:** 1–2 lines.
- **Technical findings:** max **8** bullets total; each finding one line (`severity | category | evidence`).
- **Canon / style:** max **5** bullets (merge into findings if space tight).
- **Scores:** **Progress** (one line: score, gate, checklist %) + **Quality** (axes + Total + Band). Never conflate them.
- **Analytics snapshot:** max **6** lines (counts + confidence).
- **Recommendations:** **required every run**, **minimum 3**, max **5** bullets — never omit.

## Required output sections (in order)

Use these exact headings:

1. **Scope** — What was reviewed / commands run (playtest).
2. **Technical findings** — Bugs, regressions, spec violations, test failures, and **canon audit** inconsistencies (`severity | category | evidence`). Canon audit uses warn+recommend unless a separate gate command failed.
3. **Canon / style alignment** — Short bullets vs `AI_DOCS.md` §5–§7 (optional if none: one line “No canon issues noted.”).
4. **Scores** — **Progress** (completion, gated) then **Quality** (`S N I E C R` + Total + Band). See `QA_PROGRESS_CHECKLIST.md`.
5. **Analytics snapshot** — Progress + Quality values; severity/category counts; **Confidence:** `<tier>` per rubric.
6. **Recommendations** — **≥3** prioritized actions (fixes, tests, doc updates). When canon audit findings exist, use **evidence → impact → fix** per bullet; include ≥1 combat and ≥1 movement recommendation when both areas have findings.

Optional last line: **Player note** — only if requested (see Default voice).

## Mandatory persistence

After **every** QA report (all modes: `qa`, `run qa`, `qa agent`, `qa playtest`, `qa static`), do both:

1. Append one run entry to `AXEL/axel_project/plans/qa/AXEL_QA_RUN_LOG.md` using the template, including the required machine-readable payload between:
   - `<!-- QA_ANALYTICS_JSON_BEGIN -->`
   - `<!-- QA_ANALYTICS_JSON_END -->`
2. Refresh trend analytics by running:
   - `python AXEL/axel_project/tools/qa/update_qa_analytics.py`
   - Verify both `AXEL_QA_ANALYTICS.md` and `AXEL_QA_ANALYTICS.svg` were regenerated.

If the analytics refresh fails, keep the run-log entry intact and report the failure explicitly.

## Item combat simulation (balance gate)

When item definitions exist under `combat/data/items/`, playtest runs include an item balance audit. See rubric §Item-combat-simulation-command for the exact command, metric semantics, classification thresholds, and payload keys.

## Do not

- Treat `exports/moon_princess_files/*` as gameplay canon unless promoted.
- Misuse Trinity Run / SUPER Free Spins terminology.
- Skip **Scores** (Progress + Quality), **Analytics snapshot**, or **Recommendations** (≥3).
- Report Quality alone as “progress” or imply ship-ready from high Quality / passing bots.
- Write long player-opinion essays unless explicitly asked.
