# AXEL QA Analytics

Auto-generated from `AXEL_QA_RUN_LOG.md` by `tools/qa/update_qa_analytics.py`.

- Last generated (UTC): `2026-05-19T09:06:11.790160+00:00`
- Runs parsed: `9`

## Latest snapshot

- Mode: `playtest`
- Scope: `Post-rescale combat economy; win/loss and wager/payout totals`
- Trigger: `user request`
- Findings: `blocker=0 major=0 minor=1 nit=1`
- Categories: `STYLE=0 LORE=0 IMMERSION=0 TENSION=1 CLARITY=0 COMBAT=1 ARCH=0 REGRESSION=0 BUG=0 TOOL=1`
- Bugs/problems: `none`
- Bots: `bot_arc1_exterior=pass bot_dialogue_loop=pass`
- Item balance audit: `captured`

## Latest deltas vs previous run

- `Total`: `3.67` (`-0.18` vs previous)
- `S`: `4.00` (`+0.00` vs previous)
- `N`: `4.00` (`+0.00` vs previous)
- `I`: `3.00` (`-1.00` vs previous)
- `E`: `3.00` (`+0.00` vs previous)
- `C`: `4.00` (`+0.00` vs previous)
- `R`: `4.00` (`+0.00` vs previous)
- `Bots`: `5.00` (`+0.00` vs previous)

## Trend chart (Total + S/N/I/E/C/R + Bots)

![AXEL QA Score Trends](AXEL_QA_ANALYTICS.svg)

Fallback Mermaid view:

```mermaid
xychart-beta
  title "AXEL QA Score Trends"
  x-axis ["2026-05-08#1", "2026-05-08#2", "2026-05-08#3", "2026-05-08#4", "2026-05-11#5", "2026-05-11#6", "2026-05-11#7", "2026-05-17#8", "2026-05-19#9"]
  y-axis "Score" 0 --> 5
  line [2.7, 3.65, 1.95, 3.85, 3.68, 3.85, 3.85, 3.85, 3.67]
  line [3, 4, 2, 4, 4, 4, 4, 4, 4]
  line [3, 4, 3, 4, 4, 4, 4, 4, 4]
  line [2, 3, 2, 4, 4, 4, 4, 4, 3]
  line [2, 3, 2, 3, 3, 3, 3, 3, 3]
  line [3, 4, 1, 4, 4, 4, 4, 4, 4]
  line [3, 4, 1, 4, 3, 4, 4, 4, 4]
```

- Series order: Total, S, N, I, E, C, R. The dashed `Bots` aggregate (pass=5, fail=0; gaps for skip/missing) appears in the SVG only — Mermaid `xychart-beta` cannot render gaps cleanly so it is omitted from the fallback view.

## Item Balance Summary

Runs with item data: `4`

- Items tested (latest): `2`
- Overpowered: `none`
- Underpowered: `none`
- Neutral: `2`
- Insufficient data: `0`

### Latest per-item deltas

| Item | Label | ΔRTP | CI95 | ΔHit Rate | ΔEnc. Success |
|------|-------|------|------|-----------|---------------|
| `C1_ash_reroll_token` | **neutral** | `+0.0058` | `[-0.1570, +0.1686]` | `-0.0430` | `+0.0000` |
| `L3_void_satchel` | **neutral** | `+0.0000` | `[-0.1635, +0.1635]` | `+0.0000` | `+0.0000` |
