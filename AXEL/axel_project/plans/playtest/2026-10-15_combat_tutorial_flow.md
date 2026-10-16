# Combat tutorial flow rewrite (2026-10-15)

## Goal
A brand-new player should follow the first fight one idea at a time, with short cards.

## New flow
1. **Fights** (first idle): "Click the SKULL to spin." (touch: "Tap the SKULL to spin.")
2. **Matches** (first match found, time freezes before it pays): "3 or more of the same symbol in a row or column is a win." The symbols about to match pulse and glow above the freeze.
3. The line pays: the symbols vanish, the MULTIPLIER ticks to 2X, and the History row appears. Time freezes again, then these cards play in order:
   - **Matches**: "Each win pays your BET x the symbol's PAY % x the MULTIPLIER."
   - **Bets**: BALANCE / BET / lose below 100. The "+ / -" and "Q and R" line is removed.
   - **Multiplier**: glows the MULTIPLIER, which now shows 2X.
   - **History**
4. The player is free.
5. **The Skull**: only on the first winning power-symbol match that is not that first match. Freeze, power cells glow, text: "Cigarette, Alcohol and Bloody Hand are POWER SYMBOLS. Matching them fills the SKULL METER. When the SKULL METER is full, something worse begins."
6. **Goal**: freezes on the match that will fill the GOAL. Those cells glow. If that match is also the very first match, Goal joins the end of the step 3 chain.

## Wording
- SKULL METER, POWER SYMBOLS and NORMAL SYMBOLS are written in capitals in tutorial cards and the Guide. Item descriptions keep "Skull Meter".
- No ellipses in the first-fight cards: "Click the SKULL to spin." and the Matches cards spell out the full rule.

## Code
- `combat_root.gd`:
  - new `line_step_resolved` signal, plus a second lines-gate wait after each async cascade step;
  - `lines_reach_goal(lines)`;
  - `slot_icon_at(coord)`.
  - The sync path is unchanged, so determinism is unchanged.
- `combat_test.gd`:
  - `_on_lines_found` arms the chain and picks the glowing cells;
  - `_on_line_step_resolved` requests the chain as freeze cards;
  - the old after-match queue and the multiplier-on-second-match trigger are removed;
  - a bet click no longer pops the Bets card early.
- `combat/scripts/tutorial_cell_glow.gd` + `combat/shaders/tutorial_cell_glow.gdshader`: a colour copy of each matched symbol with a pulsing red halo, on layer 108 (above the freeze, below the cards).
- `axel_tutorial.gd`: new texts, new `slot_pays` lesson, `FIGHT_ORDER`.
- `guide_pages.gd`, `item_wording_check.gd`: capitals.

## Known limit
Superseded on 2026-10-16: the Goal card now shows before Round Complete on every first win, however the GOAL was filled. See `2026-10-16_goal_card_before_round_complete.md`.
