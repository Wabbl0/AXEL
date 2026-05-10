# AXEL Simulated QA Review Rubric

Scoring reference for **`qa agent` / `qa`** (`.cursor/skills/axel-simulated-qa/SKILL.md`). Canon order: `AI_DOCS.md` wins on conflicts.

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

Plain `qa` / `run qa` / `qa agent` runs **all six** commands below in one pass. Run from **repo root** (Windows uses `tools/cmd/godot.cmd`):

```bat
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/princess_check.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/determinism_check.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/rtp_audit.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://test/scene_smoke_check.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://test/bots/playthrough_arc1_exterior.gd
tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://test/bots/playthrough_dialogue_loop.gd
```

The two bot scripts are documented in `AXEL/axel_project/test/bots/README.md`.

- **Pass/fail gates:** `princess_check`, `determinism_check`, `scene_smoke_check`, `playthrough_arc1_exterior`, `playthrough_dialogue_loop` — non-zero exit = report as **blocker** / `BUG` or `REGRESSION`.
- **`rtp_audit.gd`:** always exits 0 — parse stdout for `RTP_AUDIT_JSON` (or printed metrics) and record in analytics; do not fail the run on RTP alone unless thresholds are specified.
- **Skip policy:** if any command cannot run (missing tooling, unavailable Godot binary, etc.), name every skipped command explicitly in the report and downgrade confidence one tier per missing gate (drop bots first → `combat + scene smoke`; drop scene smoke → `combat simulated`; drop combat → `static review`).

### When user says “playtest” or “high confidence”

1. Run the full default command set above (six commands) — same as plain `qa` — and report which (if any) failed or were skipped.
2. Set **Confidence:** to `combat + scene smoke + bot playthrough` only if **all** pass/fail gates passed and metrics captured. Otherwise pick the highest tier still satisfied by the evidence (see Skip policy above).
3. Prioritize **bugs, regressions, and fix recommendations** over subjective feel.

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

## Violation taxonomy (categories)

Use these `category` labels in findings and analytics:

| Code | Category | Typical evidence |
| ---- | -------- | ---------------- |
| `STYLE` | Palette / CRT / typography | Wrong hues, missing scanlines where blueprint requires them |
| `LORE` | World / plot / items | Contradicts anchors or ending logic |
| `IMMERSION` | Pacing / diegesis / FX | Breaks mood or reads as generic |
| `TENSION` | Peaks / cheap tricks | Whiplash, unmotivated scare, flat middle |
| `CLARITY` | UX / goals / feedback | Confusing gates, unclear affordances |
| `COMBAT` | Grid / RNG / invariants | Violates `AI_DOCS.md` §5 |
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
- `scores` with numeric `S/N/I/E/C/R/Total` and string `Band`
- `findings_count` with `blocker/major/minor/nit`
- `by_category` with taxonomy counts from this rubric
- `playtest_commands` with `princess_check/determinism/rtp_audit/scene_smoke/bot_arc1_exterior/bot_dialogue_loop`
- `bugs_or_regressions` as short list entries

This payload is the source of truth for historical analytics and Mermaid trend lines. `tools/qa/update_qa_analytics.py` auto-discovers any `playtest_commands` key prefixed `bot_*` and aggregates them into a single dashed `Bots` line on `AXEL_QA_ANALYTICS.svg` (mapping: `pass=5`, `fail=0`, `skip`/missing = gap). New bot scripts that use the same key prefix automatically join the aggregate without further code changes.

## Player experience (optional)

Not required by default. If the user explicitly asks for player-feel, add **one short paragraph** (see skill). Do not replace technical findings.
