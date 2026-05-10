# AXEL QA Run Log

Optional **append-only** log for simulated QA runs. Use when you want historical analytics across sessions.

- **Do not** use this file instead of `AI_CHANGELOG.md` for implemented work; changelog remains for shipped changes only.
- Each run is one `##` entry at the **bottom**.
- Keep entries **compact** to match concise `qa agent` chat output.

---

## How to append an entry

Copy the template block, fill values, paste **below** the last entry.

```md
## YYYY-MM-DD — <short scope title>

- **Mode:** <static | playtest>
- **Scope:** <one line: feature, scene list, or paths reviewed>
- **Trigger:** <user request | post-change agreed QA>
- **Playtest commands:** princess_check=<pass|fail|skip> determinism=<pass|fail|skip> rtp_audit=<captured|skip> scene_smoke=<pass|fail|skip> bot_arc1_exterior=<pass|fail|skip> bot_dialogue_loop=<pass|fail|skip>
- **Scores:** S=_ N=_ I=_ E=_ C=_ R=_ **Total=_._** Band=_
- **Findings count:** blocker=_ major=_ minor=_ nit=_
- **By category:** STYLE=_ LORE=_ IMMERSION=_ TENSION=_ CLARITY=_ COMBAT=_ ARCH=_ REGRESSION=_ BUG=_ TOOL=_
- **Recommendations (logged):** <3–5 short bullets mirroring the chat report>
- **Bug / regression notes:** <optional: IDs, failing test names, suspected root cause>
- **Trend vs previous run:** <up | down | flat | n/a first run> — <one line why>
- **Link / notes:** <optional: PR, commit, or chat id>

<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "YYYY-MM-DDTHH:MM:SSZ",
  "run_title": "<short scope title>",
  "mode": "static",
  "scope": "<one line scope>",
  "trigger": "user request",
  "scores": {"S": 0, "N": 0, "I": 0, "E": 0, "C": 0, "R": 0, "Total": 0.0, "Band": "F"},
  "findings_count": {"blocker": 0, "major": 0, "minor": 0, "nit": 0},
  "by_category": {"STYLE": 0, "LORE": 0, "IMMERSION": 0, "TENSION": 0, "CLARITY": 0, "COMBAT": 0, "ARCH": 0, "REGRESSION": 0, "BUG": 0, "TOOL": 0},
  "playtest_commands": {"princess_check": "skip", "determinism": "skip", "rtp_audit": "skip", "scene_smoke": "skip", "bot_arc1_exterior": "skip", "bot_dialogue_loop": "skip"},
  "bugs_or_regressions": []
}
<!-- QA_ANALYTICS_JSON_END -->

## 2026-05-08 — Arc 1.1 door interaction follow-up QA

- **Mode:** static
- **Scope:** `scenes/Arc_1/1.1_SchoolExterior.gd` and `scenes/Arc_1/1.1_SchoolExterior.tscn` door interaction trigger, key handling, and corridor transition path
- **Trigger:** user request
- **Playtest commands:** princess_check=skip determinism=skip rtp_audit=skip scene_smoke=skip
- **Scores:** S=4 N=4 I=4 E=3 C=4 R=4 **Total=3.85** Band=B
- **Findings count:** blocker=0 major=0 minor=1 nit=1
- **By category:** STYLE=0 LORE=0 IMMERSION=0 TENSION=1 CLARITY=1 COMBAT=0 ARCH=0 REGRESSION=0 BUG=0 TOOL=0
- **Recommendations (logged):**
  - Add a contextual prompt near the door (`E / Space / Enter`) while inside interact range to improve affordance clarity.
  - Optionally migrate interaction keys into an InputMap action (for example `interact`) to keep future remapping centralized.
  - Add a headless scene smoke pass (`res://test/scene_smoke_check.gd`) after future scene-transition edits for faster regression detection.
- **Bug / regression notes:** none observed in static review; user-confirmed manual interaction flow works after interact-area reposition
- **Trend vs previous run:** up — progression gate in Arc 1.1 is now implemented and no blockers remain in reviewed paths
- **Link / notes:** follow-up QA after door trigger placement adjustment
<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "2026-05-08T17:27:00Z",
  "run_title": "Arc 1.1 door interaction follow-up QA",
  "mode": "static",
  "scope": "scenes/Arc_1/1.1_SchoolExterior.gd and scenes/Arc_1/1.1_SchoolExterior.tscn door interaction trigger, key handling, and corridor transition path",
  "trigger": "user request",
  "scores": {"S": 4, "N": 4, "I": 4, "E": 3, "C": 4, "R": 4, "Total": 3.85, "Band": "B"},
  "findings_count": {"blocker": 0, "major": 0, "minor": 1, "nit": 1},
  "by_category": {"STYLE": 0, "LORE": 0, "IMMERSION": 0, "TENSION": 1, "CLARITY": 1, "COMBAT": 0, "ARCH": 0, "REGRESSION": 0, "BUG": 0, "TOOL": 0},
  "playtest_commands": {"princess_check": "skip", "determinism": "skip", "rtp_audit": "skip", "scene_smoke": "skip"},
  "bugs_or_regressions": []
}
<!-- QA_ANALYTICS_JSON_END -->
## 2026-05-08 — Arc 1.1 first scene QA

- **Mode:** static
- **Scope:** `scenes/Arc_1/1.1_SchoolExterior.tscn` placeholder behavior/dialogue plus shared `scenes/core/ScenePlaceholder.gd`
- **Trigger:** user request
- **Playtest commands:** princess_check=skip determinism=skip rtp_audit=skip scene_smoke=pass
- **Scores:** S=2 N=3 I=2 E=2 C=1 R=1 **Total=1.95** Band=F
- **Findings count:** blocker=1 major=1 minor=2 nit=0
- **By category:** STYLE=1 LORE=0 IMMERSION=1 TENSION=0 CLARITY=1 COMBAT=0 ARCH=0 REGRESSION=1 BUG=1 TOOL=0
- **Recommendations (logged):**
  - Add explicit transition interaction in `1.1` to route to `1.2_Corridor`.
  - Set a non-empty location label for first-scene HUD/dialogue context.
  - Add minimal scene-specific dread FX (flicker/glitch/timing beats) to restore intro tension.
  - Wire VT323 (or project typography defaults) into placeholder dialogue controls.
- **Bug / regression notes:** first scene currently has no navigation/interaction path, so progression to `1.2` cannot happen from this placeholder alone
- **Trend vs previous run:** down — first-scene placeholder pass regressed progression and clarity versus synthetic baseline
- **Link / notes:** focused QA run requested for first scene only
<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "2026-05-08T15:50:00Z",
  "run_title": "Arc 1.1 first scene QA",
  "mode": "static",
  "scope": "scenes/Arc_1/1.1_SchoolExterior.tscn placeholder behavior/dialogue plus shared scenes/core/ScenePlaceholder.gd",
  "trigger": "user request",
  "scores": {"S": 2, "N": 3, "I": 2, "E": 2, "C": 1, "R": 1, "Total": 1.95, "Band": "F"},
  "findings_count": {"blocker": 1, "major": 1, "minor": 2, "nit": 0},
  "by_category": {"STYLE": 1, "LORE": 0, "IMMERSION": 1, "TENSION": 0, "CLARITY": 1, "COMBAT": 0, "ARCH": 0, "REGRESSION": 1, "BUG": 1, "TOOL": 0},
  "playtest_commands": {"princess_check": "skip", "determinism": "skip", "rtp_audit": "skip", "scene_smoke": "pass"},
  "bugs_or_regressions": ["Arc 1.1 placeholder has no transition interaction to 1.2_Corridor"]
}
<!-- QA_ANALYTICS_JSON_END -->
```

### Machine-readable analytics payload (required)

- Add exactly one JSON block per run wrapped by:
  - `<!-- QA_ANALYTICS_JSON_BEGIN -->`
  - `<!-- QA_ANALYTICS_JSON_END -->`
- Keep key names stable so `tools/qa/update_qa_analytics.py` can parse history safely.
- Allowed `mode`: `static`, `playtest`.
- Allowed `playtest_commands` keys: `princess_check`, `determinism`, `rtp_audit`, `scene_smoke`, `bot_arc1_exterior`, `bot_dialogue_loop`. Allowed values: `pass`, `fail`, `captured`, `skip` (`captured` is for `rtp_audit` metrics; the rest are pass/fail gates that may also be `skip`).
- `scores.Total` must be numeric and rounded to 2 decimals.
- `bugs_or_regressions` should list short strings (IDs or concise notes) for discovered bugs/problems.

---

## Entries

## 2026-05-08 — Synthetic validation static

- **Mode:** static
- **Scope:** validation run for analytics parser and trend generation
- **Trigger:** user request
- **Playtest commands:** princess_check=skip determinism=skip rtp_audit=skip scene_smoke=skip
- **Scores:** S=3 N=3 I=2 E=2 C=3 R=3 **Total=2.70** Band=D
- **Findings count:** blocker=0 major=2 minor=1 nit=0
- **By category:** STYLE=0 LORE=1 IMMERSION=1 TENSION=1 CLARITY=0 COMBAT=0 ARCH=0 REGRESSION=1 BUG=0 TOOL=0
- **Recommendations (logged):**
  - Improve immersion and tension beats for middle-game scenes.
  - Add lore consistency check for recent branching changes.
  - Add regression smoke for critical scene transitions.
- **Bug / regression notes:** regression-risk note for branch flag handling
- **Trend vs previous run:** n/a first run — baseline synthetic validation sample
- **Link / notes:** synthetic validation entry for analytics pipeline
<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "2026-05-08T15:40:00Z",
  "run_title": "Synthetic validation static",
  "mode": "static",
  "scope": "validation run for analytics parser and trend generation",
  "trigger": "user request",
  "scores": {"S": 3, "N": 3, "I": 2, "E": 2, "C": 3, "R": 3, "Total": 2.70, "Band": "D"},
  "findings_count": {"blocker": 0, "major": 2, "minor": 1, "nit": 0},
  "by_category": {"STYLE": 0, "LORE": 1, "IMMERSION": 1, "TENSION": 1, "CLARITY": 0, "COMBAT": 0, "ARCH": 0, "REGRESSION": 1, "BUG": 0, "TOOL": 0},
  "playtest_commands": {"princess_check": "skip", "determinism": "skip", "rtp_audit": "skip", "scene_smoke": "skip"},
  "bugs_or_regressions": ["Branch flag regression-risk note"]
}
<!-- QA_ANALYTICS_JSON_END -->


## 2026-05-08 — Synthetic validation playtest

- **Mode:** playtest
- **Scope:** validation run with playtest command outcomes and trend deltas
- **Trigger:** user request
- **Playtest commands:** princess_check=pass determinism=pass rtp_audit=captured scene_smoke=pass
- **Scores:** S=4 N=4 I=3 E=3 C=4 R=4 **Total=3.65** Band=C
- **Findings count:** blocker=0 major=1 minor=1 nit=1
- **By category:** STYLE=0 LORE=0 IMMERSION=1 TENSION=1 CLARITY=0 COMBAT=0 ARCH=0 REGRESSION=0 BUG=1 TOOL=0
- **Recommendations (logged):**
  - Keep deterministic checks in CI for every scene-heavy merge.
  - Investigate the reported minor BUG before content lock.
  - Raise immersion score by improving diegetic transition cues.
- **Bug / regression notes:** minor interaction bug observed in one tested flow
- **Trend vs previous run:** up — improved overall and axis scores after playtest checks
- **Link / notes:** synthetic validation entry for analytics pipeline
<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "2026-05-08T15:41:00Z",
  "run_title": "Synthetic validation playtest",
  "mode": "playtest",
  "scope": "validation run with playtest command outcomes and trend deltas",
  "trigger": "user request",
  "scores": {"S": 4, "N": 4, "I": 3, "E": 3, "C": 4, "R": 4, "Total": 3.65, "Band": "C"},
  "findings_count": {"blocker": 0, "major": 1, "minor": 1, "nit": 1},
  "by_category": {"STYLE": 0, "LORE": 0, "IMMERSION": 1, "TENSION": 1, "CLARITY": 0, "COMBAT": 0, "ARCH": 0, "REGRESSION": 0, "BUG": 1, "TOOL": 0},
  "playtest_commands": {"princess_check": "pass", "determinism": "pass", "rtp_audit": "captured", "scene_smoke": "pass"},
  "bugs_or_regressions": ["Minor interaction bug in tested flow"]
}
<!-- QA_ANALYTICS_JSON_END -->
