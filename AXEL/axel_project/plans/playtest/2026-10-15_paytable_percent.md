# Paytable as percent of bet (2026-10-15)

## Problem

The history box showed `bet x value x multiplier` (100 x 3 x 1), but a hidden `0.431 / 10` scalar made the real payout 13, not 300.

## Decision (user)

- No decimal values anywhere (canon).
- Bets, balance and goal ladder stay the same (min bet 100).
- Symbol values become whole-number percents of the bet, with the old hidden scalar baked in (`old value x 4.31`, rounded).
- Payout = `bet x pay% x multiplier / 100`. Items and curses change the pay % first (rounded to a whole percent), so the shown row always adds up.
- History box: row 1 `100 x 13% x 1`, row 2 `= 13` under it.

## New paytable (3 / 4 / 5 in a line)

| Symbol | Old | New % |
|---|---|---|
| Low (star, circle, triangle) | 2 / 4 / 15 | 9 / 17 / 65 |
| Red heart | 3 / 5 / 20 | 13 / 22 / 86 |
| Cigarette, alcohol, bloody hand | 5 / 12 / 50 | 22 / 52 / 216 |
| Satanic | 15 / 25 / 280 | 65 / 108 / 1207 |

## Files

- `combat/data/symbols/sym_*.tres`: new values.
- `combat_root.gd`: `PAYTABLE_SCALE` removed, `_line_pay_percent`, line event carries the percent. `BASELINE_PAYOUT_SCALAR` stays only for the `bonus_stake` rule.
- `combat_test.gd`: history rows.
- `item_wheel.gd`, `guide_panel.gd`, `guide_pages.gd`, `axel_tutorial.gd`: show `%`, wording.

## Not done

- ~~`AI_DOCS.md` paytable line~~ updated 2026-10-16.
- ~~Rounding raises RTP slightly. Re-run `difficulty_curve_sim.gd` to confirm.~~ Rerun 2026-10-16 on the committed 2.0.2 code:
  - `rtp_audit.gd` (defaults): RTP 51.8 % (95 % range 33–62 %), hit rate 44 %. `GuidePages.RTP_PERCENT` 51 -> 52.
  - `difficulty_curve_sim.gd` (200 runs, min bet), dead by fight 4 / 6 / 9 / 13 / 17 / 21:
    - Random picks: 3.5 / 17 / 42.5 / 51.5 / 56 / **61 %** (2 stalls).
    - One-family picks: 4.5 / 19 / 47.5 / 55.5 / 58 / **59 %** (0 stalls).
  - Same as before the rounding (61 / 60 % in `2026-10-15_balance_stage5.md`), within run-to-run noise. No balance change needed.
