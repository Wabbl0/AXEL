# Combat tutorial order, freeze timing and closing (2026-10-13)

## Problem (playtest)
- The Matches card froze time only after the match had already paid.
- The "Fights / BALANCE" card was a gate card, so it jumped to the front of the queue and blocked spinning.
- Spamming E closed freeze cards.
- Round Complete did not wait for open cards.

## Rules now
- **Default order:** Spin → (spin 1 finds a match, time freezes) Matches → the line pays → History → The Skull → Bets → Goal.
- **Freeze cards** (Matches, Multiplier, The Skull on a power line, Vice): time stops before the line resolves. They never time out.
- **Calm cards** (History, The Skull in order, Bets, Goal, Items): no freeze, no spin block. They fade 6s after typing, and that clock only runs while a spin plays or the fight is ending.
- **Stacking:** a bet click shows Bets at once, and a power line shows The Skull at once, both over the current card. Otherwise one card at a time.
- **Closing:** X, a click on the card, Esc/Backspace/Delete, or doing the action. 0.8s read lock after typing. `interact` never closes a card.
- **Round Complete** waits for open fight cards (not Guide). Queued, unshown fight cards are dropped and come back next fight.

## Code
- `scripts/autoload/axel_tutorial.gd`:
  - `request(id, {freeze, stack})`, `FIGHT_ORDER`, `READ_LOCK_SEC`, `CALM_WAIT_SEC`.
  - `set_playing_along`, `has_blocking_fight_card`, `drop_queued_fight_lessons`.
  - `fight_stakes` is retitled "Bets" and no longer gates.
- `combat/scripts/combat_root.gd`: `lines_found` signal, `lines_gate_open`, `is_power_symbol`. Async cascade only, so determinism is unchanged.
- `combat/scripts/combat_test.gd`:
  - `_on_lines_found` requests Matches / Skull / Multiplier as freeze cards and closes the lines gate.
  - The bet buttons show or complete Bets.
  - E does nothing while frozen.
- `scripts/autoload/axel_run.gd`: `_await_fight_cards_closed` before the Round Complete card.

## Checks
`tutorial_popup_check.gd`, `determinism_check.gd`, `powers_check.gd`, `tutorial_script_seeds_check.gd`, `combat_test_scaffold_check.gd`, `round_complete_overlay_check.gd`, `scene_smoke_check.gd`, `pause_contract_check.gd`, `menu_nav_check.gd`, `settings_persistence_check.gd`, `audio_bus_layout_check.gd`.
