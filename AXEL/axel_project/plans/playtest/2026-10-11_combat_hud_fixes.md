# Combat HUD playtest fixes (2026-10-11)

## 1. Highlight ghosts
- **Problem:** tutorial highlights drew offset copies behind the art (doubled grid lines, ghost skull).
- **Cause:** `piece_highlight_glow.gd` had an `Echo` copy that scaled to 112% and faded. It also had a 2px flicker jump on the main copy.
- **Fix:**
  - Echo and flicker are removed. Halo, bloom and the sweep stay.
  - The glow now follows the art's drawn rect (keep-aspect modes) and its flip settings.
  - The shader's echo branch (`mode == 2`) is gone.

## 2–3. BALANCE card (`fight_stakes`)
- **Problem:** it came back after the Multiplier card, and it returned every fight until the bet was changed.
- **Cause:**
  - Freeze cards bumped it (closed it unseen, then re-queued it).
  - Scene change closed it unseen.
  - Held freeze lessons were also released before it.
- **Fix:** the lesson has `"gate": true`.
  - It goes first in the queue and is never bumped.
  - Any close marks it seen: X, Esc, bet + / − or Q / R, or a scene change. It shows once per profile.
  - While it is open, it sits over the skull and spinning is blocked (`blocks_spin`). E and clicks on the card body do not close it.
  - `combat_test` holds freeze lessons until BALANCE is done, so the order is BALANCE → Multiplier → Powers → Vice Round.

## 4. Skull press burst
- The ember burst now starts where the mouse pressed the skull, or at its center for E.

## 5. Item descriptions
- All 75 descriptions are rewritten in plain words, in the `.tres` files and in the generator.
- The rules are in the catalog plan under "Player-facing descriptions".
- Sealed-grid items: refill is never run in the live game, so they read as "Normal spins: wins pay X% more".

## 6. Item tooltip
- **Equipped list:**
  - Background is near solid (0.96).
  - 2px red border.
  - Text is fully opaque, 58px (was 48).
  - Absolute z 60.
- **Walk-near card:** 34px text (was 28), panel alpha 0.92.

## 7. Skull hover outline
- `RIM_COLOR` is now white.

## 8. GOAL dropped (60 → 26)
- **Cause:**
  - Win popups can reach the bar after `_on_spin_finished` has already synced the bar to the real total.
  - The late popups were counted again, so GOAL showed real + extra (26 + 34 = 60).
  - The next spin snapped it back to the real 26.
- **Fix (`combat_test.gd`):**
  - The sync stores a popup credit, and late popups use it up instead of being counted again.
  - The GOAL readout is now `clamp(truth - lag, last_shown, truth)`. It never goes down and never runs ahead of the real value.
  - `goal_bar_sync_check.gd` has a late-popup case. It fails on the old code and passes now.

## 9. Wild on 4/5 lines (answer only, canon unchanged)
- **Today:** wilds come only from exactly-3 lines. 4- and 5-lines give none.
- **Test switch:** `CombatRoot.wild_line_lengths` (default `[3]`). The audit takes these overrides:
  - `AXEL_RTP_WILD_LENGTHS`
  - `AXEL_RTP_SEEDS`
  - `AXEL_RTP_ENCOUNTERS`
- **Results** from `rtp_audit.gd`: 200 seeds × 50 paid spins with no items, plus 300 audit fights.

| Rule | RTP | Vice Rounds | Audit fights won |
| --- | --- | --- | --- |
| 3 only (canon) | 0.457 | 3 | 4 / 300 |
| 3 and 5 | 0.477 | 7 | 3 / 300 |
| 3, 4 and 5 | 0.635 | 12 | 29 / 300 |

- **Reading:**
  - A wild on 5-lines adds about 2 RTP points, which is barely above the noise.
  - Adding 4-lines adds about 18 points and quadruples Vice Rounds.
- **Not changed:** this is a rule change, so it waits for a decision.
