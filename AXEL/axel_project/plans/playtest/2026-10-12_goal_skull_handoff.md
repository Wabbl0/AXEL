# 2026-10-12 Goal skull fill → Round Complete handoff

## Problem
The grid-to-skulls animation at GOAL felt flat next to the Round Complete banner. Every cell flipped at the same moment, and the banner then cut in with no link to the board.

## New flow
1. **Ripple flip.** Cells turn into skulls in rings from the grid center (0.07s per ring). Each one squashes, plays the alcohol eat, then pops (1.22 → 1.0) with a white flash. There is one `skull` cue per ring.
2. **Charge.** All skulls pulse twice and the outer 16 cells run a marquee chase (every 0.09s, same rhythm as the banner bulbs). The grid frame flickers white/red and the shake builds.
3. **Gather and slam.** The Round Complete layer opens and the scrim fades to dark red. The board skulls lift off and are pulled to screen center, outer ring first. The title slam lands as they meet, and the skull burst fires with the same number of skulls.

Reduce flashing: plain swap with a small pop, no charge, and the gather has no spin and a black scrim.
Grid flames are gone (canon already said there are no flames on the grid).

## Code
- `combat_root.gd`: `_play_goal_win_burst`, `_play_goal_charge`, `goal_skull_points`, `hide_goal_skulls`.
- `symbol_slot.gd`: `play_goal_flip`, `play_pulse`.
- `round_jackpot_fx.gd`: `play_gather`, `set_skull_count`.
- `axel_event_fx.gd`: `show_round_complete_card(bets, balance, gather)` returns true when it gathers.
- `axel_run.gd`: passes the cell points and hides the grid skulls in the same frame.

## Checks
`round_complete_overlay_check.gd` (+ gather and burst count) and all CLAUDE.md checks.
