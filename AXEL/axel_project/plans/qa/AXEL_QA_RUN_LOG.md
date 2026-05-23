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
- **Playtest commands:** princess_check=<pass|fail|skip> determinism=<pass|fail|skip> rtp_audit=<captured|skip> scene_smoke=<pass|fail|skip> combat_test_scaffold=<pass|fail|skip> canon_consistency_audit=<captured|skip> bot_arc1_exterior=<pass|fail|skip> bot_dialogue_loop=<pass|fail|skip> item_balance_audit=<captured|skip>
- **Progress:** **_._** (gate _ cap _._; checklist _%)
- **Quality:** S=_ N=_ I=_ E=_ C=_ R=_ **Total=_._** Band=_
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
  "quality": {"S": 0, "N": 0, "I": 0, "E": 0, "C": 0, "R": 0, "Total": 0.0, "Band": "F"},
  "progress": {
    "score": 0.0,
    "scoring_mode": "option2",
    "progress_raw": 0.0,
    "gate_cap": 1.5,
    "gate_state": 0,
    "checklist_completion": 0.0,
    "checklist_completed_weight": 0,
    "checklist_total_weight": 200,
    "coverage_factor": 0.5,
    "defect_penalty": 1.0,
    "milestones_completed": []
  },
  "findings_count": {"blocker": 0, "major": 0, "minor": 0, "nit": 0},
  "by_category": {"STYLE": 0, "LORE": 0, "IMMERSION": 0, "TENSION": 0, "CLARITY": 0, "COMBAT": 0, "ARCH": 0, "REGRESSION": 0, "BUG": 0, "TOOL": 0},
  "playtest_commands": {"princess_check": "skip", "determinism": "skip", "rtp_audit": "skip", "scene_smoke": "skip", "combat_test_scaffold": "skip", "canon_consistency_audit": "skip", "bot_arc1_exterior": "skip", "bot_dialogue_loop": "skip"},
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
  - Add a headless scene smoke pass (`res://tools/scene_smoke_check.gd`) after future scene-transition edits for faster regression detection.
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
- Allowed `playtest_commands` keys: `princess_check`, `determinism`, `rtp_audit`, `scene_smoke`, `combat_test_scaffold`, `canon_consistency_audit`, `bot_arc1_exterior`, `bot_dialogue_loop`, `item_balance_audit`, `item_synergy_smoke`. Allowed values: `pass`, `fail`, `captured`, `skip` (`captured` for metrics-only commands).
- Required `quality` object and `progress` object — see `AXEL_QA_REVIEW_RUBRIC.md` §Persistent analytics payload. Mirror axis values in `scores` for backward compatibility.
- Score **Progress** from `QA_PROGRESS_CHECKLIST.md` (not from quality axes).
- Optional `item_balance` object: present when `item_balance_audit=captured`. Contains `schema_version`, `items_tested`, and per-classification item id lists.
- Optional `item_metrics` array: per-item detail objects with RTP/hit-rate/encounter deltas and confidence intervals.
- Optional `canon_audit` object when `canon_consistency_audit=captured`.
- `scores.Total` / `quality.Total` must be numeric and rounded to 2 decimals; `progress.score` likewise.
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

## 2026-05-17 — Combat seed / Trinity gravity fix QA

- **Mode:** playtest
- **Scope:** Post-fix QA for combat seed queue, HUD spin context, Trinity gravity-after-delete; full default command set + item audit + synergy smoke
- **Trigger:** user request (`run qa`)
- **Playtest commands:** princess_check=pass determinism=pass rtp_audit=captured scene_smoke=pass bot_arc1_exterior=pass bot_dialogue_loop=pass item_balance_audit=captured item_synergy_smoke=pass
- **Scores:** S=4 N=4 I=4 E=3 C=4 R=4 **Total=3.85** Band=B
- **Findings count:** blocker=0 major=0 minor=2 nit=1
- **By category:** STYLE=0 LORE=0 IMMERSION=0 TENSION=0 CLARITY=1 COMBAT=1 ARCH=0 REGRESSION=0 BUG=1 TOOL=0
- **Recommendations (logged):**
  - Guard or restore `NoirPaletteOverlay/FilterRect` in `1.1_SchoolExterior` to stop headless script errors on scene load
  - Re-check baseline RTP (mean 0.8126) if economy tuning is in scope — currently above 75–80% target band
  - Manual spot-check Trinity Storm collapse with symbol FX enabled in `combat_test.tscn`
  - Append `AI_CHANGELOG.md` entry for 2026-05-17 combat fix if not already present
- **Bug / regression notes:** New princess_check tests pass; determinism holds; pre-existing 1.1 noir overlay node path errors during smoke/bots (non-fatal)
- **Trend vs previous run:** flat — Total=3.85; all gates pass; combat fix regressions not detected
- **Link / notes:** Validates seed/gravity patch in `combat_test.gd`, `combat_root.gd`, `princess_check.gd`

<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "2026-05-17T13:10:00+03:00",
  "run_title": "Combat seed / Trinity gravity fix QA",
  "mode": "playtest",
  "scope": "Post-fix QA for combat seed queue, HUD spin context, Trinity gravity-after-delete",
  "trigger": "user request",
  "scores": {"S": 4, "N": 4, "I": 4, "E": 3, "C": 4, "R": 4, "Total": 3.85, "Band": "B"},
  "findings_count": {"blocker": 0, "major": 0, "minor": 2, "nit": 1},
  "by_category": {"STYLE": 0, "LORE": 0, "IMMERSION": 0, "TENSION": 0, "CLARITY": 1, "COMBAT": 1, "ARCH": 0, "REGRESSION": 0, "BUG": 1, "TOOL": 0},
  "playtest_commands": {"princess_check": "pass", "determinism": "pass", "rtp_audit": "captured", "scene_smoke": "pass", "bot_arc1_exterior": "pass", "bot_dialogue_loop": "pass", "item_balance_audit": "captured", "item_synergy_smoke": "pass"},
  "bugs_or_regressions": ["1.1_SchoolExterior NoirPaletteOverlay/FilterRect missing — script errors on load (pre-existing)"],
  "rtp_snapshot": {"mean": 0.81259, "ci95": [0.62389, 1.00129], "target_band": [0.75, 0.80], "target_position": "above", "paid_hit_rate": 0.417, "encounter_success_rate": 0.00833, "trinity_entries": 0},
  "item_balance": {"schema_version": 1, "items_tested": 2, "items_overpowered": [], "items_underpowered": [], "items_neutral": ["C1_ash_reroll_token", "L3_void_satchel"], "items_insufficient_data": []},
  "item_metrics": [
    {"item_id": "C1_ash_reroll_token", "label": "neutral", "baseline_rtp": 0.81259, "item_rtp": 1.09567, "delta_rtp": 0.28308, "delta_rtp_ci95": [-0.03396, 0.60012], "baseline_hit_rate": 0.417, "item_hit_rate": 0.417, "delta_hit_rate": 0.0, "baseline_encounter_success": 0.01667, "item_encounter_success": 0.03333, "delta_encounter_success": 0.01667, "seeds_used": 20},
    {"item_id": "L3_void_satchel", "label": "neutral", "baseline_rtp": 0.81259, "item_rtp": 0.81259, "delta_rtp": 0.0, "delta_rtp_ci95": [-0.26686, 0.26686], "baseline_hit_rate": 0.417, "item_hit_rate": 0.417, "delta_hit_rate": 0.0, "baseline_encounter_success": 0.01667, "item_encounter_success": 0.01667, "delta_encounter_success": 0.0, "seeds_used": 20}
  ]
}
<!-- QA_ANALYTICS_JSON_END -->

## 2026-05-19 — Combat 100/1000 economy RTP QA (win/loss amounts)

- **Mode:** playtest
- **Scope:** Post-rescale combat economy (`min bet 100`, `bankroll 1000`, `BASELINE_PAYOUT_SCALAR 0.431`); emphasis on encounter win/loss counts and wager/payout totals
- **Trigger:** user request (`run qa` — wins/losses and how much)
- **Playtest commands:** princess_check=pass determinism=pass rtp_audit=captured scene_smoke=pass bot_arc1_exterior=pass bot_dialogue_loop=pass item_balance_audit=captured item_synergy_smoke=pass
- **Scores:** S=4 N=4 I=3 E=3 C=4 R=4 **Total=3.67** Band=B
- **Findings count:** blocker=0 major=0 minor=1 nit=1
- **By category:** STYLE=0 LORE=0 IMMERSION=0 TENSION=1 CLARITY=0 COMBAT=1 ARCH=0 REGRESSION=0 BUG=0 TOOL=1
- **Recommendations (logged):**
  - Report encounter win/loss and chip totals in `rtp_audit.gd` stdout summary (not only JSON) for faster human QA scans
  - If encounter feel should be >1% win rate, lower `CHIP_BAR_GOAL_MULTIPLE` or raise starting bankroll — current 1/120 wins at 10× goal
  - Align `item_balance_audit.gd` wager accounting with `rtp_audit` explicit-stake method so item RTP deltas match baseline RTP scale
  - Manual F6 spot-check: min-stake line pays show integers (e.g. 20, 35) at bet 100
- **Bug / regression notes:** All gates pass; determinism 100 spins OK; RTP within band after scalar
- **Trend vs previous run:** up on RTP compliance (0.75 vs prior 0.81 above band); encounter win rate flat (~1/120)
- **Link / notes:** User-requested win/loss + amount focus; see report for chip breakdown

<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "2026-05-19T12:10:00+03:00",
  "run_title": "Combat 100/1000 economy RTP QA (win/loss amounts)",
  "mode": "playtest",
  "scope": "Post-rescale combat economy; win/loss and wager/payout totals",
  "trigger": "user request",
  "scores": {"S": 4, "N": 4, "I": 3, "E": 3, "C": 4, "R": 4, "Total": 3.67, "Band": "B"},
  "findings_count": {"blocker": 0, "major": 0, "minor": 1, "nit": 1},
  "by_category": {"STYLE": 0, "LORE": 0, "IMMERSION": 0, "TENSION": 1, "CLARITY": 0, "COMBAT": 1, "ARCH": 0, "REGRESSION": 0, "BUG": 0, "TOOL": 1},
  "playtest_commands": {"princess_check": "pass", "determinism": "pass", "rtp_audit": "captured", "scene_smoke": "pass", "bot_arc1_exterior": "pass", "bot_dialogue_loop": "pass", "item_balance_audit": "captured", "item_synergy_smoke": "pass"},
  "bugs_or_regressions": [],
  "rtp_snapshot": {
    "mean": 0.75019,
    "ci95": [0.37743, 0.94218],
    "target_band": [0.75, 0.80],
    "target_position": "within",
    "paid_hit_rate": 0.365,
    "encounter_success_rate": 0.00833,
    "encounter_wins": 1,
    "encounter_losses": 119,
    "encounter_count": 120,
    "total_wager_cents": 30800,
    "total_payout_cents": 23106,
    "net_house_cents": 7694,
    "trinity_entries": 0
  },
  "item_balance": {"schema_version": 1, "items_tested": 2, "items_overpowered": [], "items_underpowered": [], "items_neutral": ["C1_ash_reroll_token", "L3_void_satchel"], "items_insufficient_data": []},
  "item_metrics": [
    {"item_id": "C1_ash_reroll_token", "label": "neutral", "baseline_rtp": 0.40883, "item_rtp": 0.41466, "delta_rtp": 0.00583, "delta_rtp_ci95": [-0.15697, 0.16862], "baseline_hit_rate": 0.365, "item_hit_rate": 0.322, "delta_hit_rate": -0.043, "baseline_encounter_success": 0.01667, "item_encounter_success": 0.01667, "delta_encounter_success": 0.0, "seeds_used": 20},
    {"item_id": "L3_void_satchel", "label": "neutral", "baseline_rtp": 0.40883, "item_rtp": 0.40883, "delta_rtp": 0.0, "delta_rtp_ci95": [-0.16347, 0.16347], "baseline_hit_rate": 0.365, "item_hit_rate": 0.365, "delta_hit_rate": 0.0, "baseline_encounter_success": 0.01667, "item_encounter_success": 0.01667, "delta_encounter_success": 0.0, "seeds_used": 20}
  ]
}
<!-- QA_ANALYTICS_JSON_END -->

## 2026-05-19 — Retimed winnings popup (5-phase lob) QA

- **Mode:** playtest
- **Scope:** `symbol_slot.gd` retimed win popup (appear/scale/glow/lob/fade, 1.24s), `combat_root`/`combat_test` lob target wiring to `MultiplierReadout`
- **Trigger:** user request (`qa`)
- **Playtest commands:** princess_check=pass determinism=pass rtp_audit=captured scene_smoke=pass bot_arc1_exterior=pass bot_dialogue_loop=pass item_balance_audit=captured item_synergy_smoke=pass
- **Scores:** S=4 N=4 I=3 E=4 C=3 R=3 **Total=3.57** Band=C
- **Findings count:** blocker=0 major=0 minor=1 nit=2
- **By category:** STYLE=0 LORE=0 IMMERSION=1 TENSION=0 CLARITY=1 COMBAT=0 ARCH=0 REGRESSION=0 BUG=0 TOOL=1
- **Recommendations (logged):**
  - Extend `_play_count_flash_for_lines` await to `popup_delay + WIN_POPUP_TOTAL_DURATION` so cascade does not start before lob/fade finish
  - Remove or wire unused `_duration` arg in `play_win_popup` to avoid caller/tween drift
  - Manual F6: multi-line win — confirm five phases read distinctly before gravity settle
- **Bug / regression notes:** All playtest gates pass; determinism 100 spins OK; RTP mean 0.75 within band
- **Trend vs previous run:** flat on gates; new minor pacing coupling between popup length and cascade wait
- **Link / notes:** Post retimed-winnings-popup-steps implementation

<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "2026-05-19T20:30:00+03:00",
  "run_title": "Retimed winnings popup (5-phase lob) QA",
  "mode": "playtest",
  "scope": "symbol_slot.gd retimed win popup; combat_root/combat_test lob target wiring",
  "trigger": "user request",
  "scores": {"S": 4, "N": 4, "I": 3, "E": 4, "C": 3, "R": 3, "Total": 3.57, "Band": "C"},
  "findings_count": {"blocker": 0, "major": 0, "minor": 1, "nit": 2},
  "by_category": {"STYLE": 0, "LORE": 0, "IMMERSION": 1, "TENSION": 0, "CLARITY": 1, "COMBAT": 0, "ARCH": 0, "REGRESSION": 0, "BUG": 0, "TOOL": 1},
  "playtest_commands": {"princess_check": "pass", "determinism": "pass", "rtp_audit": "captured", "scene_smoke": "pass", "bot_arc1_exterior": "pass", "bot_dialogue_loop": "pass", "item_balance_audit": "captured", "item_synergy_smoke": "pass"},
  "bugs_or_regressions": [],
  "rtp_snapshot": {
    "mean": 0.75019,
    "ci95": [0.37743, 0.94218],
    "target_band": [0.75, 0.80],
    "target_position": "within",
    "paid_hit_rate": 0.365,
    "encounter_success_rate": 0.00833,
    "encounter_wins": 1,
    "encounter_count": 120
  },
  "item_balance": {"schema_version": 1, "items_tested": 2, "items_overpowered": [], "items_underpowered": [], "items_neutral": ["C1_ash_reroll_token", "L3_void_satchel"], "items_insufficient_data": []},
  "item_metrics": [
    {"item_id": "C1_ash_reroll_token", "label": "neutral", "baseline_rtp": 0.40883, "item_rtp": 0.41466, "delta_rtp": 0.00583, "delta_rtp_ci95": [-0.15697, 0.16862], "baseline_hit_rate": 0.365, "item_hit_rate": 0.322, "delta_hit_rate": -0.043, "baseline_encounter_success": 0.01667, "item_encounter_success": 0.01667, "delta_encounter_success": 0.0, "seeds_used": 20},
    {"item_id": "L3_void_satchel", "label": "neutral", "baseline_rtp": 0.40883, "item_rtp": 0.40883, "delta_rtp": 0.0, "delta_rtp_ci95": [-0.16347, 0.16347], "baseline_hit_rate": 0.365, "item_hit_rate": 0.365, "delta_hit_rate": 0.0, "baseline_encounter_success": 0.01667, "item_encounter_success": 0.01667, "delta_encounter_success": 0.0, "seeds_used": 20}
  ]
}
<!-- QA_ANALYTICS_JSON_END -->

## 2026-05-23 — QA agent readiness smoke (canon audit extension)

- **Mode:** playtest
- **Scope:** Default 8-command playtest + canon consistency audit
- **Trigger:** user request
- **Playtest commands:** princess_check=pass determinism=pass rtp_audit=captured scene_smoke=pass combat_test_scaffold=fail canon_consistency_audit=captured bot_arc1_exterior=pass bot_dialogue_loop=pass item_balance_audit=skip item_synergy_smoke=skip
- **Progress:** **1.2** (gate 0 cap 1.5)
- **Quality:** S=3 N=4 I=3 E=3 C=3 R=2 **Total=3.10** Band=C
- **Findings count:** blocker=1 major=7 minor=2 nit=0
- **Recommendations (logged):** Remove duplicate CombatRoot grid; tune Corridor player profile; re-run playtest after fix
- **Trend vs previous run:** down — scaffold gate fail

<!-- QA_ANALYTICS_JSON_BEGIN -->
{"timestamp":"2026-05-23T16:45:00+03:00","run_title":"QA agent readiness smoke","mode":"playtest","scope":"Default playtest + canon audit","trigger":"user request","scores":{"S":3,"N":4,"I":3,"E":3,"C":3,"R":2,"Total":3.10,"Band":"C"},"quality":{"S":3,"N":4,"I":3,"E":3,"C":3,"R":2,"Total":3.10,"Band":"C"},"progress":{"score":1.2,"gate_cap":1.5,"gate_state":0,"checklist_completion":0.12},"findings_count":{"blocker":1,"major":7,"minor":2,"nit":0},"by_category":{"STYLE":1,"CLARITY":1,"COMBAT":7,"REGRESSION":1,"BUG":1},"playtest_commands":{"princess_check":"pass","determinism":"pass","rtp_audit":"captured","scene_smoke":"pass","combat_test_scaffold":"fail","canon_consistency_audit":"pass","bot_arc1_exterior":"pass","bot_dialogue_loop":"pass","item_balance_audit":"skip","item_synergy_smoke":"skip"},"canon_audit":{"schema_version":1,"findings_count":{"major":7,"minor":2},"findings":[{"id":"combat.grid_duplicate","severity":"major","category":"COMBAT","evidence":"CombatRoot has 2x GridUI"}]},"bugs_or_regressions":["combat_test_scaffold_check duplicate grid"]}
<!-- QA_ANALYTICS_JSON_END -->

## 2026-05-23 — Combat scaffold dedup post-fix QA

- **Mode:** playtest
- **Scope:** Combat scaffold dedup + persistence guards; full default playtest; in-session re-sanitize when duplicates regressed
- **Trigger:** user request (`qa` after dedup plan)
- **Playtest commands:** princess_check=pass determinism=pass rtp_audit=captured scene_smoke=pass combat_test_scaffold=fail→pass (remediated) canon_consistency_audit=captured bot_arc1_exterior=pass bot_dialogue_loop=pass item_balance_audit=captured item_synergy_smoke=pass
- **Progress:** **0.39** (gate 0 cap 1.5; checklist 12%; coverage 1.0; defect penalty 0.65)
- **Quality:** S=3 N=4 I=3 E=3 C=3 R=2 **Total=3.10** Band=C
- **Findings count:** blocker=1 major=8 minor=2 nit=0
- **By category:** STYLE=1 LORE=0 IMMERSION=0 TENSION=0 CLARITY=1 COMBAT=8 REGRESSION=1 BUG=1 ARCH=0 TOOL=0
- **Recommendations (logged):** Re-sanitize after Godot saves combat_test; extend pre-commit to MultiplierLabel; tune Corridor speed/scale; fix AxelPostFxStack TypedArray detach on scene change
- **Bug / regression notes:** Inline CombatRoot grid stack reappeared in combat_test.tscn; sanitized + MultiplierLabel2 removed; post-fix scaffold/canon combat clear
- **Trend vs previous run:** up on combat canon — scaffold remediated in-session; movement minors unchanged
- **Link / notes:** `sanitize_duplicate_combat_root_grid` + MultiplierLabel in sanitizer list

<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "2026-05-23T22:20:00+03:00",
  "run_title": "Combat scaffold dedup post-fix QA",
  "mode": "playtest",
  "scope": "Combat scaffold dedup guards; default playtest; in-session sanitize on regression",
  "trigger": "user request",
  "scores": {"S": 3, "N": 4, "I": 3, "E": 3, "C": 3, "R": 2, "Total": 3.10, "Band": "C"},
  "quality": {"S": 3, "N": 4, "I": 3, "E": 3, "C": 3, "R": 2, "Total": 3.10, "Band": "C"},
  "progress": {
    "score": 0.39,
    "scoring_mode": "option2",
    "progress_raw": 0.6,
    "gate_cap": 1.5,
    "gate_state": 0,
    "checklist_completion": 0.12,
    "checklist_completed_weight": 24,
    "checklist_total_weight": 200,
    "coverage_factor": 1.0,
    "defect_penalty": 0.65,
    "milestones_completed": []
  },
  "findings_count": {"blocker": 1, "major": 8, "minor": 2, "nit": 0},
  "by_category": {"STYLE": 1, "LORE": 0, "IMMERSION": 0, "TENSION": 0, "CLARITY": 1, "COMBAT": 8, "ARCH": 0, "REGRESSION": 1, "BUG": 1, "TOOL": 0},
  "playtest_commands": {
    "princess_check": "pass",
    "determinism": "pass",
    "rtp_audit": "captured",
    "scene_smoke": "pass",
    "combat_test_scaffold": "fail_then_pass",
    "canon_consistency_audit": "captured",
    "bot_arc1_exterior": "pass",
    "bot_dialogue_loop": "pass",
    "item_balance_audit": "captured",
    "item_synergy_smoke": "pass"
  },
  "canon_audit": {
    "schema_version": 1,
    "findings_count": {"blocker": 0, "major": 0, "minor": 2, "nit": 0},
    "findings": [
      {"id": "movement.speed_profile", "severity": "minor", "category": "CLARITY", "evidence": "Player.speed=371.0 outside profile [130,175] corridor"},
      {"id": "movement.scale_profile", "severity": "minor", "category": "STYLE", "evidence": "Player scale avg=2.06 outside profile [0.75,0.95] corridor"}
    ]
  },
  "rtp_snapshot": {
    "mean": 0.75019,
    "ci95": [0.37743, 0.94218],
    "target_band": [0.75, 0.8],
    "target_position": "within",
    "paid_hit_rate": 0.365,
    "encounter_success_rate": 0.00833,
    "encounter_wins": 1,
    "encounter_count": 120
  },
  "item_balance": {
    "schema_version": 1,
    "items_tested": 2,
    "items_overpowered": [],
    "items_underpowered": [],
    "items_neutral": ["C1_ash_reroll_token", "L3_void_satchel"],
    "items_insufficient_data": []
  },
  "item_metrics": [
    {"item_id": "C1_ash_reroll_token", "label": "neutral", "baseline_rtp": 0.40883, "item_rtp": 0.41466, "delta_rtp": 0.00583, "delta_rtp_ci95": [-0.15697, 0.16862], "baseline_hit_rate": 0.365, "item_hit_rate": 0.322, "delta_hit_rate": -0.043, "baseline_encounter_success": 0.01667, "item_encounter_success": 0.01667, "delta_encounter_success": 0.0, "seeds_used": 20},
    {"item_id": "L3_void_satchel", "label": "neutral", "baseline_rtp": 0.40883, "item_rtp": 0.40883, "delta_rtp": 0.0, "delta_rtp_ci95": [-0.16347, 0.16347], "baseline_hit_rate": 0.365, "item_hit_rate": 0.365, "delta_hit_rate": 0.0, "baseline_encounter_success": 0.01667, "item_encounter_success": 0.01667, "delta_encounter_success": 0.0, "seeds_used": 20}
  ],
  "bugs_or_regressions": [
    "combat_test_scaffold_check duplicate CombatRoot grid (remediated in-session)",
    "AxelPostFxStack TypedArray invalid object on scene change (bot runs)"
  ]
}
<!-- QA_ANALYTICS_JSON_END -->

## 2026-05-23 — Combat HUD polish QA

- **Mode:** playtest
- **Scope:** Post HUD polish (`combat_test.gd` / `combat_test.tscn`); full default playtest + item audits
- **Trigger:** user request (`run qa`)
- **Playtest commands:** princess_check=pass determinism=pass rtp_audit=captured scene_smoke=pass combat_test_scaffold=pass canon_consistency_audit=captured bot_arc1_exterior=pass bot_dialogue_loop=pass item_balance_audit=captured item_synergy_smoke=pass
- **Progress:** **0.60** (gate 0 cap 1.5; checklist 12%; coverage 1.0; defect penalty 1.0)
- **Quality:** S=4 N=4 I=4 E=3 C=4 R=4 **Total=3.85** Band=B
- **Findings count:** blocker=0 major=0 minor=3 nit=1
- **By category:** STYLE=1 CLARITY=1 REGRESSION=1 TOOL=1
- **Recommendations (logged):** Tune Corridor player profile; fix AxelPostFxStack detach; manual HUD resize pass; optional layout anchor smoke test
- **Trend vs previous run:** up — scaffold gate clean; combat canon audit clear; Quality +0.75 vs prior dedup run
- **Link / notes:** Combat HUD typography/alignment/stake/winnings polish; no combat canon audit findings on `combat_test.tscn`

<!-- QA_ANALYTICS_JSON_BEGIN -->
{
  "timestamp": "2026-05-23T23:45:00+03:00",
  "run_title": "Combat HUD polish QA",
  "mode": "playtest",
  "scope": "Combat HUD polish pass; full default playtest + item audits",
  "trigger": "user request",
  "scores": {"S": 4, "N": 4, "I": 4, "E": 3, "C": 4, "R": 4, "Total": 3.85, "Band": "B"},
  "quality": {"S": 4, "N": 4, "I": 4, "E": 3, "C": 4, "R": 4, "Total": 3.85, "Band": "B"},
  "progress": {
    "score": 0.60,
    "scoring_mode": "option2",
    "progress_raw": 0.6,
    "gate_cap": 1.5,
    "gate_state": 0,
    "checklist_completion": 0.12,
    "checklist_completed_weight": 24,
    "checklist_total_weight": 200,
    "coverage_factor": 1.0,
    "defect_penalty": 1.0,
    "milestones_completed": []
  },
  "findings_count": {"blocker": 0, "major": 0, "minor": 3, "nit": 1},
  "by_category": {"STYLE": 1, "LORE": 0, "IMMERSION": 0, "TENSION": 0, "CLARITY": 1, "COMBAT": 0, "ARCH": 0, "REGRESSION": 1, "BUG": 0, "TOOL": 1},
  "playtest_commands": {
    "princess_check": "pass",
    "determinism": "pass",
    "rtp_audit": "captured",
    "scene_smoke": "pass",
    "combat_test_scaffold": "pass",
    "canon_consistency_audit": "captured",
    "bot_arc1_exterior": "pass",
    "bot_dialogue_loop": "pass",
    "item_balance_audit": "captured",
    "item_synergy_smoke": "pass"
  },
  "canon_audit": {
    "schema_version": 1,
    "findings_count": {"blocker": 0, "major": 0, "minor": 2, "nit": 0},
    "findings": [
      {"id": "movement.speed_profile", "severity": "minor", "category": "CLARITY", "evidence": "Player.speed=371.0 outside profile [130,175] corridor_large"},
      {"id": "movement.scale_profile", "severity": "minor", "category": "STYLE", "evidence": "Player scale avg=2.06 outside profile [0.75,0.95] corridor_large"}
    ]
  },
  "rtp_snapshot": {
    "mean": 0.75019,
    "ci95": [0.37743, 0.94218],
    "target_band": [0.75, 0.8],
    "target_position": "within",
    "paid_hit_rate": 0.365,
    "encounter_success_rate": 0.00833,
    "encounter_wins": 1,
    "encounter_count": 120
  },
  "item_balance": {
    "schema_version": 1,
    "items_tested": 2,
    "items_overpowered": [],
    "items_underpowered": [],
    "items_neutral": ["C1_ash_reroll_token", "L3_void_satchel"],
    "items_insufficient_data": []
  },
  "item_metrics": [
    {"item_id": "C1_ash_reroll_token", "label": "neutral", "baseline_rtp": 0.40883, "item_rtp": 0.41466, "delta_rtp": 0.00583, "delta_rtp_ci95": [-0.15697, 0.16862], "baseline_hit_rate": 0.365, "item_hit_rate": 0.322, "delta_hit_rate": -0.043, "baseline_encounter_success": 0.01667, "item_encounter_success": 0.01667, "delta_encounter_success": 0.0, "seeds_used": 20},
    {"item_id": "L3_void_satchel", "label": "neutral", "baseline_rtp": 0.40883, "item_rtp": 0.40883, "delta_rtp": 0.0, "delta_rtp_ci95": [-0.16347, 0.16347], "baseline_hit_rate": 0.365, "item_hit_rate": 0.365, "delta_hit_rate": 0.0, "baseline_encounter_success": 0.01667, "item_encounter_success": 0.01667, "delta_encounter_success": 0.0, "seeds_used": 20}
  ],
  "bugs_or_regressions": [
    "AxelPostFxStack TypedArray invalid object on scene change during bot playthroughs"
  ]
}
<!-- QA_ANALYTICS_JSON_END -->
