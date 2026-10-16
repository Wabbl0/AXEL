# Goal card before Round Complete (2026-10-16)

## Problem
- The spin that reached the GOAL showed the Goal card as a freeze card and skipped The Skull card, even when that spin had power symbol lines.

## Rules now
- The last spin is treated like any other spin: if it has power symbol lines and The Skull is unseen, The Skull freeze card shows, time freezes and the power cells glow.
- The spin then finishes. After the goal bar has counted up (`await_victory_prelude`) and before the goal win burst and Round Complete, the Goal card shows (stacked, calm). This happens on every first win, power symbols or not.
- Round Complete waits until the Goal card closes (X, click, Esc, or the 6s calm fade). If the card cannot open within 2s, Round Complete goes on.

## Code
- `combat/scripts/combat_test.gd`: `_on_lines_found` no longer requests `fight_goal`; the Matches chain no longer appends it.
- `scripts/autoload/axel_tutorial.gd`: `is_pending(id)` (queued or showing).
- `scripts/autoload/axel_run.gd`: `_show_goal_lesson()` in `_show_round_complete_card`.

## Checks
All CLAUDE.md checks plus `tutorial_popup_check.gd` and `round_complete_overlay_check.gd` pass.
