# Double or Nothing (combat gamble)

**Status (2026-10-16):** built, all checks pass, needs a playtest in Godot. Differences from the plan below: the gamble screen sits on its own `CanvasLayer` 117 created by `combat_test.gd` (`DoubleOrNothingLayer`, like the Choose Your Vice card on 116), not on the CombatFeel layer, so `combat_feel.gd` is unchanged. The offer is off in headless runs unless `CombatRoot.gamble_force_enabled` is set, so old headless checks still end fights at GOAL. Screenshots: `tools/qa/double_or_nothing_capture.gd` (run through `run_quiet.ps1`, `--out-dir=`, `--pick=`). Not built: keyboard / gamepad picking (mouse and touch only; `interact` collects).


## Context
After a winning spin the player can gamble the win. A belt of power symbols (alcohol, cigarette, bloody hand) scrolls past a needle like a CS case opening, then stops on one. If it stops on your pick, the win is multiplied and you can gamble again. If not, the win is gone. This is a combat task; combat stays deterministic.

## Decisions (user, 2026-10-15)
- Offered after a winning **paid** spin. If that spin leads into the Vice Round or Free Spins, the bonus plays out first, then one offer is made on the whole total (paid spin + Vice + Free Spins).
- Picks: alcohol 2x, cigarette 2x, bloody hand 15x. One pick per round.
- Belt odds: alcohol 47%, cigarette 47%, bloody hand 6%.
- No cap. Each win offers again on the new pot.
- GOAL: if the win reached GOAL, the fight waits until you collect. A lost gamble takes the pot back off GOAL and off balance, so the fight goes on (or is lost if you can't afford a spin any more).
- Skip / collect: `interact`, or clicking the skull. That keeps the pot and spins as normal. If GOAL is met, it goes to Round Complete instead.
- Not offered in the locker tutorial fight (its spins are scripted).
- Curses (2026-10-16 code): the end-of-fight check (GOAL, cannot afford, curse spin cap) waits until the offer is collected or lost.

## How it works (plain)
1. A spin wins. The bar shows the total as today. A small red **DOUBLE OR NOTHING** chip appears on the winnings row, next to `MultiplierReadout`.
2. Click the chip to open the gamble. Press E/Space or click the skull to ignore it and spin on.
3. The gamble opens over the fight: a faint dark scrim (about 45%), and the same red bars with chasing bulbs as the Vice Round / Free Spins intro, one above and one below. Between them: the pot (`POT: 240`) and three choices: alcohol `x2`, **bloody hand `x15`** in the middle, cigarette `x2`. Hovering a choice grows its icon, like the Choose Your Vice card. **COLLECT** button underneath.
4. After a pick, the choices fade and the belt appears between the bars. It is a row of dark tiles, each with a symbol icon and a colored bottom edge (grey for alcohol and cigarette, red for the hand), with a white needle in the middle and the ends fading to black. It scrolls fast, then slows with an ease-out over ~4s and settles on a tile. A tick plays for each tile that passes. Some near-miss hands sit next to the landing tile on purpose.
5. Win: the tile flashes, the pot counts up, and balance and GOAL tick up together. The three choices come back for another round. Lose: a red glitch hit, the pot drops to 0, and balance and GOAL tick back down. The banner closes.
6. `interact` during the belt only speeds it up (4x, `CombatPace.rush_beat()`), like other combat animations.

## Determinism
- The roll never touches the spin RNG (`CombatRoot.rng`). It uses its own `CombatRNG` (`combat/scripts/rng.gd`) seeded from `hash([_current_seed, gamble_step])`. Gambling or not leaves the next spins the same, so `determinism_check.gd` is unaffected.
- The belt layout (which tiles, the landing slot, the small offset inside the landing tile) comes from that same stream, so a replay shows the same belt.

## Files
**New**
- `combat/scripts/double_or_nothing.gd`: logic only (RefCounted). Holds the weights, `roll(seed, step) -> StringName`, `multiplier_for(pick)`, `build_belt(seed, step, result) -> Array[StringName]` (about 60 tiles, landing at about 48).
- `combat/scripts/double_or_nothing_ui.gd`: Control on the CombatFeel layer (same layer as `BonusIntroFx`). Draws the scrim, bars, choices, pot, belt and needle. Signals `picked(power_id)` and `collected()`. Uses `CombatPace` for all tweens and waits.
- `combat/scripts/marquee_bars.gd`: a small static helper holding `draw_bar(...)`, moved out of `bonus_intro_fx.gd` `_draw_bar` so the gamble and the Vice intro share one look.
- `combat/test/double_or_nothing_check.gd`: regression test (see Verification).

**Changed**
- `combat/scripts/combat_root.gd`
  - New `_gamble_pot_cents` (reset at paid spin start, `spin()` ~652). Add each spin's payout to it, plus the Free Spins enter burst.
  - At the end of `spin()`: when the pot is above 0, there is no Free Spins and no choice pending, and this is not the tutorial, set `_gamble_offer_open` and **skip** `_finalize_encounter_if_needed()` until the player collects or loses.
  - New public API: `has_gamble_offer()`, `get_gamble_pot()`, `gamble(pick) -> Dictionary` (result, belt, new pot), `collect_gamble()`. A new `State.GAMBLE` blocks `spin()` while the belt runs.
  - A win adds `pot × (mult − 1)` through the same path as `_add_round_winnings` plus `_bankroll_cents`. A loss subtracts the pot from `_bankroll_cents`, `_encounter_goal_winnings_cents` (never below the head start) and `_round_winnings_cents`, then calls `_finalize_encounter_if_needed()`.
  - `spin_sync()` and headless runs never open an offer.
- `combat/scripts/combat_test.gd`: shows and hides the chip on the winnings row. It routes the chip click to open the UI. When an offer is open, `interact` and the skull call `collect_gamble()` first, then the normal spin. It keeps `_spin_busy` set while the gamble UI is open. The winnings bar and GOAL readout follow `readouts_progressed` as today, so the count up and down reuses the existing ticker.
- `combat/scripts/combat_feel.gd`: builds the gamble UI next to `_bonus_fx` and exposes `play_gamble(...)`.
- `combat/scripts/bonus_intro_fx.gd`: `_draw_bar` calls the shared `marquee_bars.gd` helper. The look stays the same.

`combat_test.tscn` is not edited (everything is built in code), so the protected scaffold is untouched.

## Docs (only when you say "update docs")
`AI_DOCS.md` combat section: the gamble, its odds, that GOAL can go back down after a lost gamble, and its own RNG stream.

## Verification
1. Run `--import` once, then run every check from CLAUDE.md (determinism, powers, scaffold, scene smoke, audio bus, settings, pause, menu nav), plus `goal_bar_sync_check.gd`, `combat_pace_check.gd` and `free_spins_choice_ui_check.gd`.
2. Run the new `double_or_nothing_check.gd`:
   - Over 100k rolls the odds come out near 47/47/6.
   - The same seed and step always give the same result and belt, and the belt's landing tile matches the result.
   - A win raises balance, GOAL and the pot by the right amount. A loss removes the pot from all three.
   - A spin that met GOAL does not end the fight until collect. A loss below GOAL keeps it going.
   - Gambling does not change the next spin's grid, compared with collecting.
   - No offer in the tutorial or in `spin_sync`.
3. Take a screenshot with `tools/qa/capture_scene.ps1` while the offer is open and while the belt is mid-scroll, and check the look at 1920×1280.
