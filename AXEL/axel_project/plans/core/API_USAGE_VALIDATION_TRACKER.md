# API Usage Validation Tracker

Measure whether token optimizations hold quality. **Baseline policy date:** 2026-05-24 (chat lanes, meta routing, min packs, governance trim).

## How to use

After each completed AXEL task (any bundle), add one row. Score quality 1–5 (5 = same as pre-optimization). **Keep policy** if median quality ≥ 4 and turns/tool calls trend down over 10 rows.

## Metrics per task

| Field | Record |
|-------|--------|
| Date | YYYY-MM-DD |
| Bundle | combat / scenes / narrative / vfx / meta |
| Lane | A only / A→B / B direct |
| Prefix used? | yes / no |
| Turns (approx) | user+assistant pairs |
| Tool calls (approx) | read/grep/shell/subagent count |
| Quality (1–5) | your rating |
| Notes | regressions, saves, blockers |

## Sample log (fill as you work)

| # | Date | Bundle | Lane | Prefix | Turns | Tools | Q | Notes |
|---|------|--------|------|--------|-------|-------|---|-------|
| 1 | | | | | | | | |
| 2 | | | | | | | | |
| 3 | | | | | | | | |
| 4 | | | | | | | | |
| 5 | | | | | | | | |
| 6 | | | | | | | | |
| 7 | | | | | | | | |
| 8 | | | | | | | | |
| 9 | | | | | | | | |
| 10 | | | | | | | | |

## Rollback triggers

- Median quality &lt; 4 after 10 tasks → restore verbose packs for affected bundle only.
- Repeated canon misses → require premium Lane B for that bundle until stable.
- Cross-domain bugs → enforce `unlock` + two-chat split (A per domain, B per domain).

## Policy reference

- Lanes: `CHAT_LANE_PROTOCOL.md`
- Token limits: `AI_DOCS.md` §15
- Routing: `AGENT_CONTEXT_ROUTING.md` §1b meta-process
