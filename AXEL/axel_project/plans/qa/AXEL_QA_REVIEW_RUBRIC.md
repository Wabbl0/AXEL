# AXEL Simulated QA Review Rubric

Scoring reference for **`qa agent` / `qa`** (`.cursor/skills/axel-simulated-qa/SKILL.md`). Canon order: `../core/AI_DOCS.md` wins on conflicts.

## Playtest-mode criteria

Use this section to set **confidence** and required **evidence**. Default `qa` voice is **technical-first** and **concise**; playtest mode adds **simulated runs** for higher confidence.

### Confidence tiers

| Tier | Meaning | Required evidence |
|------|---------|-------------------|
| `static review` | Code/docs/drafts only | File pointers; no automated runs |
| `combat simulated` | Headless combat checks passed | `princess_check.gd` + `determinism_check.gd` exit 0; optional `rtp_audit.gd` stdout captured |
| `combat + scene smoke` | Mid-tier playtest (subset of default; report only when bot scripts had to be skipped) | All of **combat simulated** **plus** `scene_smoke_check.gd` exit 0 **plus** `rtp_audit.gd` metrics line captured (metrics only; not a pass/fail gate unless user defines thresholds) |
| `combat + scene smoke + bot playthrough` | **Default tier for plain `qa` / `run qa` / `qa agent`** — full default playtest, exercises real-input paths | All of **combat + scene smoke** **plus** `playthrough_arc1_exterior.gd` + `playthrough_dialogue_loop.gd` exit 0 (synthesized `InputEventKey` traversal of `Player.gd` polling, `_unhandled_input` interaction, and `TopDialogueOverlay._input` Tab-skip) |

### Default command set (playtest: combat + scene smoke + bot playthrough)

Plain `qa` / `run qa` / `qa agent` runs **all eight** commands below in one pass. Prefer the canonical runner `AXEL/axel_project/tools/qa/run_default_playtest.ps1` (same script paths). Run from **repo root** (Windows uses `tools/cmd/godot.cmd`):

```bat
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/princess_check.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/rtp_audit.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/scene_smoke_check.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/combat_test_scaffold_check.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/canon_consistency_audit.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/bots/playthrough_arc1_exterior.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/bots/playthrough_dialogue_loop.gd
```

The two bot scripts are documented in `AXEL/axel_project/tools/bots/README.md`.

- **Pass/fail gates:** `princess_check`, `determinism_check`, `scene_smoke_check`, `combat_test_scaffold_check`, `playthrough_arc1_exterior`, `playthrough_dialogue_loop` — non-zero exit = report as **blocker** / `BUG` or `REGRESSION`.
- **`canon_consistency_audit.gd`:** always exits 0 — parse stdout for `CANON_AUDIT_JSON`. Full schema and severity mapping: `AXEL_CANON_CONSISTENCY_AUDIT.md`. Report each finding in **Technical findings** (severity/category/evidence) and fold into **Recommendations** (evidence → impact → fix). Duplicate combat grid nodes, missing movement contracts, and profile drift (speed/scale) are typical signals. Do not block the QA run on audit findings alone unless a separate gate command failed.
- **`rtp_audit.gd`:** always exits 0 — parse stdout for `RTP_AUDIT_JSON` (or printed metrics) and record in analytics; do not fail the run on RTP alone unless thresholds are specified.
- **`item_balance_audit.gd` (conditional):** run after the eight default commands when item definitions exist under `combat/data/items/`. Always exits 0. If no items found or item API not implemented, record `item_balance_audit=skip` in payload. If items are tested, parse `ITEM_BALANCE_JSON` stdout and include `item_balance` + `item_metrics` in the analytics payload.
- **Skip policy:** if any command cannot run (missing tooling, unavailable Godot binary, etc.), name every skipped command explicitly in the report and downgrade confidence one tier per missing gate (drop bots first → `combat + scene smoke`; drop scene smoke → `combat simulated`; drop combat → `static review`).

### Manual combat HUD verification (operator checklist)

When combat HUD layout changes (or after `combat_test_scaffold_check` passes but visual polish is requested), complete this quick F6 pass and note results in the QA run log **Recommendations / notes**:

| Check | Wide (1280×720) | Narrow (800×600) |
|-------|-----------------|------------------|
| History rows stay single-line with ellipsis | [ ] | [ ] |
| Goal title + value right-align to ITEMS panel right edge | [ ] | [ ] |
| Seed + meta icons left-align with HISTORY panel left edge | [ ] | [ ] |
| Stake +/- backgrounds do not overlap combat grid top | [ ] | [ ] |
| Winnings + cascade multiplier have no white halo/outline | [ ] | [ ] |

Automated anchor coverage lives in `combat_test_scaffold_check.gd` (hard gate) and `canon_consistency_audit.gd` (warn+recommend). This checklist covers typography/overflow cases anchors cannot detect.

### Item combat simulation command (conditional)

When item definitions exist under `combat/data/items/`, playtest and high-confidence runs also execute:

```bat
tools\\cmd\\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/item_balance_audit.gd
```

- **Not a pass/fail gate** — always exits 0. Parse stdout for `ITEM_BALANCE_JSON` and record in analytics.
- If no items exist, prints `ITEM_BALANCE_SKIP no_items_found` and exits 0. Report as `item_balance_audit=skip` in the payload.
- Per-item metrics: delta RTP, encounter success delta, hit-rate delta, avg payout delta, 95% CI, classifier label (`overpowered` / `neutral` / `underpowered` / `insufficient_data`).
- Items classified as `overpowered` or `underpowered` should appear in **Technical findings** as `minor | COMBAT | <item_id> classified <label>`.
- **Over/underpower classification** uses confidence-aware thresholds: item is `overpowered` when 95% CI lower bound of RTP delta > +0.02; `underpowered` when 95% CI upper bound < -0.02; `insufficient_data` when sample count < minimum seed budget; `neutral` otherwise.

### Item synergy smoke test (conditional)

When item definitions exist under `combat/data/items/`, also run:

```bat
tools\\cmd\\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/item_synergy_smoke.gd
```

- **Pass/fail gate** — exits non-zero on any assertion failure. Report failures as `minor | COMBAT | synergy smoke failure`.
- Verifies: single-item equip, duplicate-id rejection, base slot limit (7), dynamic slot-expander cap (+2 legendary), deterministic payout across identical seeds/loadouts, graceful over-cap behavior on expander removal, C1+L3 coexistence.

### When user says “playtest” or “high confidence”

1. Run the full default command set above (eight commands) — same as plain `qa` — and report which (if any) failed or were skipped.
2. Run the item balance audit command if item definitions exist.
3. Set **Confidence:** to `combat + scene smoke + bot playthrough` only if **all** pass/fail gates passed and metrics captured. Otherwise pick the highest tier still satisfied by the evidence (see Skip policy above).
4. Prioritize **bugs, regressions, and fix recommendations** over subjective feel.

---

## Axes (0–5 each)

Use **integers 0–5**. Anchor meanings:

| Score | Meaning |
| ----- | ------- |
| 0 | Broken / fundamentally wrong for AXEL |
| 1 | Severe misalignment or player-hostile |
| 2 | Major issues; playable but damaging to identity or flow |
| 3 | Acceptable; noticeable gaps |
| 4 | Strong; minor polish only |
| 5 | Excellent; exemplifies intent |

### 1) Style / tone fidelity (`S`) — weight **0.22**

- Black + blood red (`#ff0000`) + dark blood (`#4a0000`) baseline; exceptions documented if needed for readability.
- CRT / scanline / glitch / shake as **core identity**, not optional chrome.
- Typography: VT323 primary; Space Mono only where appropriate.
- Mood: dread, guilt, memory corruption; wins feel **morally uneasy or intrusive**, not purely celebratory.

### 2) Narrative / lore consistency (`N`) — weight **0.20**

- Decaying school, guilt-driven return, locker as hub/sanctuary.
- Memories, items (Flashlight / Key / Shovel / Name), basement arc coherence.
- Axel identity / endings / ritual motifs (lighter, cigarettes) stay coherent with plans and prototype where applicable.

### 3) Player immersion continuity (`I`) — weight **0.18**

- Pacing, UI chrome, diegetic hooks (e.g. memory counter, location read) support sustained focus.
- FX and copy signal “psyche event” vs generic feedback.

### 4) Excitement / tension progression (`E`) — weight **0.15**

- Curiosity and unease build; hub-and-spoke or combat beats do not flatten into noise.
- Peaks feel earned; cheap jump-scares or tone whiplash reduce this score.

### 5) Clarity / friction (`C`) — weight **0.15**

- Player understands goals, gates, and feedback without lore dumps or opaque UI.
- Friction that **serves** dread is fine; friction from bugs or confusion is not.

### 6) Regression risk vs prior intent (`R`) — weight **0.10**

- Likelihood this change breaks flags, combat invariants, scene graph, or documented blueprint intent.

## Weighted total

```
Total = 0.22*S + 0.20*N + 0.18*I + 0.15*E + 0.15*C + 0.10*R
```

Round **Total** to **two decimal places**. Optionally map to letter band:

| Total   | Band   |
| ------- | ------ |
| ≥ 4.50  | A      |
| ≥ 3.75  | B      |
| ≥ 3.00  | C      |
| ≥ 2.00  | D      |
| < 2.00  | F      |

This weighted **Total** is the **Quality Score** (build quality / readiness). It is **not** game completion progress.

---

## Progress Score (game completion)

Source checklist: `QA_PROGRESS_CHECKLIST.md`. Progress and Quality are reported **separately** every run.

### Definitions

| Metric | Meaning |
|--------|---------|
| **Progress** | How much of the game is built (milestone completion), hard-capped by gates |
| **Quality** | How good the current build is (`scores.Total` from axes above) |

Neither score alone means ship-ready. High Quality with low Progress = polished slice, not a finished game.

### Formula (Option 2 — default)

1. `checklist_completion = completed_weight / total_weight` (from checklist; current total weight = **200** — see `QA_PROGRESS_CHECKLIST.md`).
2. `ProgressRaw = 5 × checklist_completion`.
3. `CoverageFactor = 0.5 + 0.5 × (passed_required_checks / total_required_checks)` — only **gate** commands that ran (not `skip`); `canon_consistency_audit=captured` counts as pass for coverage; exclude conditional audits when `skip`.
4. `DefectPenalty = 1.0 - min(0.35, 0.12×blockers + 0.05×majors)` from `findings_count`.
5. `gate_state` = highest gate with **all** its milestones marked done (0–4). `gate_cap` from checklist table (1.5 / 2.5 / 3.5 / 4.5 / 5.0).
6. **`Progress = min(gate_cap, ProgressRaw × CoverageFactor × DefectPenalty)`** — round to **two decimals**.

### Formula (Option 1 — fallback)

Set `progress.scoring_mode` to `"gate_only"` in the payload:

`Progress = min(gate_cap, ProgressRaw)` — no coverage or defect multipliers.

### Gate caps (hard)

| `gate_state` | Cap |
|--------------|-----|
| 0 | 1.5 |
| 1 | 2.5 |
| 2 | 3.5 |
| 3 | 4.5 |
| 4 | 5.0 |

Until Gate 2 milestones are done, Progress **cannot** exceed **3.5**, even if Quality is ~4.

### Scoring output (report)

Report both lines in **Scores**:

- **Progress:** `<value>` — gate `<n>` cap `<cap>`; checklist `<pct>%`; coverage `<factor>`; defect penalty `<penalty>`
- **Quality:** `S N I E C R` + **Total** + Band (as today)

## Violation taxonomy (categories)

Use these `category` labels in findings and analytics:

| Code | Category | Typical evidence |
| ---- | -------- | ---------------- |
| `STYLE` | Palette / CRT / typography | Wrong hues, missing scanlines where blueprint requires them |
| `LORE` | World / plot / items | Contradicts anchors or ending logic |
| `IMMERSION` | Pacing / diegesis / FX | Breaks mood or reads as generic |
| `TENSION` | Peaks / cheap tricks | Whiplash, unmotivated scare, flat middle |
| `CLARITY` | UX / goals / feedback | Confusing gates, unclear affordances |
| `COMBAT` | Grid / RNG / invariants | Violates `../core/AI_DOCS.md` §5 |
| `ARCH` | Layer mixing | Narrative vs combat boundaries blurred without intent |
| `REGRESSION` | Prior spec / flags | Blueprint or state machine drift |
| `BUG` | Crashes / failed smoke or tests | Non-zero test exit, load errors, exceptions |
| `TOOL` | Pipeline / drafts | `layout_validation`, quarantine, approval gates only (when reviewing scene_builder output) |

## Severity definitions

| Severity | Meaning |
| -------- | ------- |
| **blocker** | Ship-stop: breaks canon, progression, or combat invariants |
| **major** | Material player confusion or identity damage |
| **minor** | Polish or consistency issue |
| **nit** | Optional improvement |

## Analytics snapshot (minimum)

In every QA report, include (keep **≤6 lines** total per skill brevity caps):

- Count of findings per **severity**
- Count of findings per **category**
- One line **Confidence:** `static review` | `combat simulated` | `combat + scene smoke` | `combat + scene smoke + bot playthrough` (must match evidence from §Playtest-mode)
- Playtest runs: **pass/fail** per gate command, including `bot_arc1_exterior` and `bot_dialogue_loop` (if playtest mode)

## Persistent analytics payload (for trend graphing)

In addition to the concise report, each run should append one machine-readable JSON payload to `AXEL_QA_RUN_LOG.md` between:

- `<!-- QA_ANALYTICS_JSON_BEGIN -->`
- `<!-- QA_ANALYTICS_JSON_END -->`

Required keys:

- `timestamp`, `run_title`, `mode`, `scope`, `trigger`
- `scores` with numeric `S/N/I/E/C/R/Total` and string `Band` (legacy; mirror `quality` for backward compatibility)
- `quality` object: `{ "S", "N", "I", "E", "C", "R", "Total", "Band" }` — same values as `scores`
- `progress` object:
  - `score` (float) — final Progress 0..5
  - `scoring_mode` (string) — `"option2"` (default) or `"gate_only"`
  - `progress_raw`, `gate_cap`, `gate_state` (int 0–4)
  - `checklist_completion` (float 0..1)
  - `checklist_completed_weight`, `checklist_total_weight` (int)
  - `coverage_factor`, `defect_penalty` (float)
  - `milestones_completed` (array of milestone IDs, e.g. `"M1.1"`)
- `findings_count` with `blocker/major/minor/nit`
- `by_category` with taxonomy counts from this rubric
- `playtest_commands` with `princess_check/determinism/rtp_audit/scene_smoke/combat_test_scaffold/canon_consistency_audit/bot_arc1_exterior/bot_dialogue_loop/item_balance_audit`
- `bugs_or_regressions` as short list entries

Optional keys (include when item data is available):

- `canon_audit` object: `schema_version`, `findings_count` (severity map), `by_category`, short `findings` list (`id`, `severity`, `category`, `evidence`) — sourced from `CANON_AUDIT_JSON` stdout
- `item_balance` object with `schema_version` (int, currently `1`), `items_tested` (int), `items_overpowered` (list of item ids), `items_underpowered` (list of item ids), `items_neutral` (list of item ids), `items_insufficient_data` (list of item ids)
- `item_metrics` array of per-item objects: `{ "item_id", "label", "baseline_rtp", "item_rtp", "delta_rtp", "delta_rtp_ci95", "baseline_hit_rate", "item_hit_rate", "delta_hit_rate", "baseline_encounter_success", "item_encounter_success", "delta_encounter_success", "seeds_used" }`

This payload is the source of truth for historical analytics and trend charts. `tools/qa/update_qa_analytics.py` plots **Progress points** (`checklist_completed_weight`) on an **auto-scaling** left axis (grows when the checklist adds milestone weight). A dashed **Scope ceiling** line shows `checklist_total_weight` per run (project definition size). **Quality** (0–5) uses the right axis only. Legacy runs without `progress` may omit points until the next logged run. Rubric axis scores (`S`–`R`) stay in the markdown delta table, not the SVG.

**Archival:** When the main run log exceeds ~10 entries, older entries may be moved to `plans/qa/archive/AXEL_QA_RUN_LOG_<YYYY>.md`. The analytics generator ingests both the main log and archived `*.md` files, so trend continuity is preserved.

## Player experience (optional)

Not required by default. If the user explicitly asks for player-feel, add **one short paragraph** (see skill). Do not replace technical findings.
