# AXEL QA Run Log

Optional **append-only** log for simulated QA runs. Use when you want historical analytics across sessions.

- **Do not** use this file instead of `../core/AI_CHANGELOG.md` for implemented work; changelog remains for shipped changes only.
- Each run is one `##` entry at the **bottom**.
- Keep entries **compact** to match concise `qa agent` chat output.

### Archival policy

When this file grows beyond ~10 entries, move older entries (keeping the template and header) to `archive/AXEL_QA_RUN_LOG_<YYYY>.md` under the same `plans/qa/archive/` directory. The analytics generator (`tools/qa/update_qa_analytics.py`) ingests both this file and any `*.md` files in `archive/`, so trend data is preserved after archival.

---

## How to append an entry

Copy the template block, fill values, paste **below** the last entry.

```md
## YYYY-MM-DD — <short scope title>

- **Mode:** <static | playtest>
- **Scope:** <one line: feature, scene list, or paths reviewed>
- **Trigger:** <user request | post-change agreed QA>
- **Playtest commands:** princess_check=<pass|fail|skip> determinism=<pass|fail|skip> rtp_audit=<captured|skip> scene_smoke=<pass|fail|skip> bot_arc1_exterior=<pass|fail|skip> bot_dialogue_loop=<pass|fail|skip> item_balance_audit=<captured|skip>
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
  "bugs_or_regressions": [],
  "item_balance": null,
  "item_metrics": null
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
- Allowed `playtest_commands` keys: `princess_check`, `determinism`, `rtp_audit`, `scene_smoke`, `bot_arc1_exterior`, `bot_dialogue_loop`, `item_balance_audit`. Allowed values: `pass`, `fail`, `captured`, `skip` (`captured` is for `rtp_audit` and `item_balance_audit` metrics; the rest are pass/fail gates that may also be `skip`).
- Optional `item_balance` object: present when `item_balance_audit=captured`. Contains `schema_version`, `items_tested`, and per-classification item id lists.
- Optional `item_metrics` array: per-item detail objects with RTP/hit-rate/encounter deltas and confidence intervals.
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

## 2026-05-11 — Combat baseline QA (full playtest + item audit)

- **Mode:** playtest
- **Scope:** Full combined run — combat system as-is, all 7 headless commands + static review
- **Trigger:** user request
- **Playtest commands:** princess_check=fail determinism=pass rtp_audit=captured scene_smoke=pass bot_arc1_exterior=pass bot_dialogue_loop=pass item_balance_audit=skip
- **Scores:** S=4 N=4 I=4 E=3 C=4 R=3 **Total=3.68** Band=C
- **Findings count:** blocker=1 major=0 minor=2 nit=1
- **By category:** STYLE=0 LORE=0 IMMERSION=0 TENSION=0 CLARITY=0 COMBAT=3 ARCH=0 REGRESSION=0 BUG=1 TOOL=0
- **Recommendations (logged):** Set girl_power_chance to 0.01; fix TileSetAtlasSource errors; review encounter goal thresholds; add items for balance pipeline
- **Bug / regression notes:** princess_check exit 1 — girl_power_chance=0.0 vs expected 0.01; item_balance_audit.gd had missing await keywords (fixed); TileSet atlas coord errors in SchoolExterior tilemap
- **Trend vs previous run:** down — new blocker (princess_check fail) vs previous run's clean pass
- **Link / notes:** Combat baseline before item implementation begins

<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "2026-05-11T16:25:00+03:00",
  "scope": "combat baseline full playtest + item balance audit",
  "trigger": "user request",
  "scores": {"S": 4, "N": 4, "I": 4, "E": 3, "C": 4, "R": 3, "Total": 3.68, "Band": "C"},
  "findings_count": {"blocker": 1, "major": 0, "minor": 2, "nit": 1},
  "by_category": {"STYLE": 0, "LORE": 0, "IMMERSION": 0, "TENSION": 0, "CLARITY": 0, "COMBAT": 3, "ARCH": 0, "REGRESSION": 0, "BUG": 1, "TOOL": 0},
  "playtest_commands": {"princess_check": "fail", "determinism": "pass", "rtp_audit": "captured", "scene_smoke": "pass", "bot_arc1_exterior": "pass", "bot_dialogue_loop": "pass", "item_balance_audit": "skip"},
  "bugs_or_regressions": ["princess_check fail: girl_power_chance=0.0 vs expected 0.01", "item_balance_audit.gd parse error (fixed: missing await)", "TileSetAtlasSource coord errors in SchoolExterior tilemap"],
  "rtp_snapshot": {"mean": 0.78928, "ci95": [0.59157, 0.98699], "target_band": [0.75, 0.80], "target_position": "within", "paid_hit_rate": 0.415, "encounter_success_rate": 0.00833, "trinity_entries": 0},
  "item_balance": null,
  "item_metrics": null
}
<!-- QA_ANALYTICS_JSON_END -->

## 2026-05-11 — Item system infrastructure + C1 Ash Reroll Token

- **Mode:** playtest
- **Scope:** Item system infrastructure (ItemDef, ItemInventory, CombatRoot equip API, dev picker UI) + first item C1 implementation + full combined playtest
- **Trigger:** user request
- **Playtest commands:** princess_check=pass determinism=pass rtp_audit=captured scene_smoke=pass bot_arc1_exterior=pass bot_dialogue_loop=pass item_balance_audit=captured
- **Scores:** S=4 N=4 I=4 E=3 C=4 R=4 **Total=3.85** Band=B
- **Findings count:** blocker=0 major=0 minor=2 nit=1
- **By category:** STYLE=0 LORE=0 IMMERSION=0 TENSION=0 CLARITY=1 COMBAT=2 ARCH=0 REGRESSION=0 BUG=0 TOOL=0
- **Recommendations (logged):**
  - Tune C1 per_reroll/cap values down to bring delta_rtp closer to neutral (+/-0.02 target band)
  - Add rarity color indicators to dev picker checkboxes for visual hierarchy
  - Add a deterministic synergy smoke test in combat/test/ that verifies multi-item stacking
  - Implement item persistence display refresh when encounter resets via dev picker
- **Bug / regression notes:** C1 classified overpowered (delta_rtp=+0.465, CI [0.121, 0.808]); pre-existing TileSetAtlasSource coord errors in SchoolExterior tilemap unchanged
- **Trend vs previous run:** up — all pass/fail gates pass (princess_check now passes vs prior fail); first item balance audit with real data
- **Link / notes:** Item-by-item workflow proof-of-concept; first item implemented with stacking infrastructure

<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "2026-05-11T16:55:00+03:00",
  "run_title": "Item system infrastructure + C1 Ash Reroll Token",
  "mode": "playtest",
  "scope": "Item system infra (ItemDef, ItemInventory, CombatRoot equip API, dev picker) + C1 implementation + full combined playtest",
  "trigger": "user request",
  "scores": {"S": 4, "N": 4, "I": 4, "E": 3, "C": 4, "R": 4, "Total": 3.85, "Band": "B"},
  "findings_count": {"blocker": 0, "major": 0, "minor": 2, "nit": 1},
  "by_category": {"STYLE": 0, "LORE": 0, "IMMERSION": 0, "TENSION": 0, "CLARITY": 1, "COMBAT": 2, "ARCH": 0, "REGRESSION": 0, "BUG": 0, "TOOL": 0},
  "playtest_commands": {"princess_check": "pass", "determinism": "pass", "rtp_audit": "captured", "scene_smoke": "pass", "bot_arc1_exterior": "pass", "bot_dialogue_loop": "pass", "item_balance_audit": "captured"},
  "bugs_or_regressions": ["C1 classified overpowered (delta_rtp=+0.465, CI [0.121, 0.808])", "Pre-existing TileSetAtlasSource coord errors in SchoolExterior tilemap"],
  "rtp_snapshot": {"mean": 0.79293, "ci95": [0.60944, 0.97642], "target_band": [0.75, 0.80], "target_position": "within", "paid_hit_rate": 0.417, "encounter_success_rate": 0.00833, "trinity_entries": 0},
  "item_balance": {"schema_version": 1, "items_tested": 1, "items_overpowered": ["C1_ash_reroll_token"], "items_underpowered": [], "items_neutral": [], "items_insufficient_data": []},
  "item_metrics": [{"item_id": "C1_ash_reroll_token", "label": "overpowered", "baseline_rtp": 0.79293, "item_rtp": 1.2577, "delta_rtp": 0.46477, "delta_rtp_ci95": [0.12106, 0.80848], "baseline_hit_rate": 0.417, "item_hit_rate": 0.417, "delta_hit_rate": 0.0, "baseline_encounter_success": 0.01667, "item_encounter_success": 0.03333, "delta_encounter_success": 0.01667, "seeds_used": 20}]
}
<!-- QA_ANALYTICS_JSON_END -->

## 2026-05-11 — Post low-maintenance workflow fixes QA

- **Mode:** playtest
- **Scope:** Full combined run after workflow hygiene (path alignment, QA archival, debug cleanup). All 7 headless commands + static review.
- **Trigger:** user request (included in implementation plan)
- **Playtest commands:** princess_check=pass determinism=pass rtp_audit=captured scene_smoke=pass bot_arc1_exterior=pass bot_dialogue_loop=pass item_balance_audit=captured
- **Scores:** S=4 N=4 I=4 E=3 C=4 R=4 **Total=3.85** Band=B
- **Findings count:** blocker=0 major=0 minor=1 nit=1
- **By category:** STYLE=0 LORE=0 IMMERSION=0 TENSION=0 CLARITY=0 COMBAT=0 ARCH=0 REGRESSION=0 BUG=0 TOOL=2
- **Recommendations (logged):**
  - Fix pre-existing TileSetAtlasSource coord errors in SchoolExterior tilemap
  - Register item_synergy_smoke.gd in QA default command set for routine equip-limit regression coverage
  - Begin using QA run-log archival now that pipeline supports it
- **Bug / regression notes:** Pre-existing TileSetAtlasSource errors unchanged; no new bugs from workflow changes
- **Trend vs previous run:** flat — same Total=3.85; all gates passing; C1 now neutral after tuning
- **Link / notes:** QA run as final step of low-maint workflow fix plan

<!-- QA_ANALYTICS_JSON_BEGIN -->
{"timestamp":"2026-05-11T18:25:00+03:00","run_title":"Post low-maintenance workflow fixes QA","mode":"playtest","scope":"Full combined run after workflow hygiene changes","trigger":"user request","scores":{"S":4,"N":4,"I":4,"E":3,"C":4,"R":4,"Total":3.85,"Band":"B"},"findings_count":{"blocker":0,"major":0,"minor":1,"nit":1},"by_category":{"STYLE":0,"LORE":0,"IMMERSION":0,"TENSION":0,"CLARITY":0,"COMBAT":0,"ARCH":0,"REGRESSION":0,"BUG":0,"TOOL":2},"playtest_commands":{"princess_check":"pass","determinism":"pass","rtp_audit":"captured","scene_smoke":"pass","bot_arc1_exterior":"pass","bot_dialogue_loop":"pass","item_balance_audit":"captured"},"bugs_or_regressions":["Pre-existing TileSetAtlasSource coord errors in SchoolExterior tilemap"],"rtp_snapshot":{"mean":0.79293,"ci95":[0.60944,0.97642],"target_band":[0.75,0.80],"target_position":"within","paid_hit_rate":0.417,"encounter_success_rate":0.00833,"trinity_entries":0},"item_balance":{"schema_version":1,"items_tested":2,"items_overpowered":[],"items_underpowered":[],"items_neutral":["C1_ash_reroll_token","L3_void_satchel"],"items_insufficient_data":[]},"item_metrics":[{"item_id":"C1_ash_reroll_token","label":"neutral","baseline_rtp":0.79293,"item_rtp":1.06928,"delta_rtp":0.27635,"delta_rtp_ci95":[-0.03199,0.58469],"baseline_hit_rate":0.417,"item_hit_rate":0.417,"delta_hit_rate":0.0,"baseline_encounter_success":0.01667,"item_encounter_success":0.03333,"delta_encounter_success":0.01667,"seeds_used":20},{"item_id":"L3_void_satchel","label":"neutral","baseline_rtp":0.79293,"item_rtp":0.79293,"delta_rtp":0.0,"delta_rtp_ci95":[-0.25949,0.25949],"baseline_hit_rate":0.417,"item_hit_rate":0.417,"delta_hit_rate":0.0,"baseline_encounter_success":0.01667,"item_encounter_success":0.01667,"delta_encounter_success":0.0,"seeds_used":20}]}
<!-- QA_ANALYTICS_JSON_END -->
