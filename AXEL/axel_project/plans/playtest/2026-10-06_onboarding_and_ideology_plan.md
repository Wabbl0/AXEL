# Plan: onboarding, difficulty ideology, paytable x10, rarer walk fights

## Context
A senior developer playtested AXEL, did not know Moon-Princess-style slots, and when he won the first round "felt empty" because he did not understand why. Goal: teach the slot mechanics step by step, keep early game easy and linear, and make the difficulty spike only after everything is explained. Paths are under `AXEL/axel_project/`.

Decisions already made with the user:
- x10 = **paytable only** (not bets/balance/goals).
- Walk fights: **lower base, slower ramp**.
- Scripted spins: **first 3 spins of the locker tutorial fight**, plus the tutorial fight also triggers when the player first walks past the locker.

## 1. Record the ideology (docs only)
- Add a short `## Design ideology` section to `plans/core/AI_DOCS.md` (after "Combat invariants"): roguelike balances on the line between difficult and replayable; difficulty curve near-exponential, first third linear and easy; the spike comes only after every technique is explained and understood; a win the player cannot explain feels empty, so every first-time mechanic must be explained at the moment it happens.
- No `AI_CHANGELOG.md` entry (retired).

## 2. Tutorial cards close on the action (or X)
File: `scripts/autoload/axel_tutorial.gd` (LESSONS l.29-54, timer in `_process` l.256, `_begin_wait` l.329, `_reading_duration_sec` l.338, `_dismiss_one_card` l.348, X handler l.361).
- Remove the reading timer auto-close (`_begin_wait`/`_reading_duration_sec`/`AUTO_SKIP_GRACE_SEC` path). Cards close only on X, or when the lesson's required action happens.
- Add to each lesson a `done_signal`/`complete(id)` API: `AxelTutorial.complete_lesson(id)` closes that card and marks it seen.
  - `move_walk`: first player movement (call from `1.1_SchoolExterior.gd:~214`).
  - `fight_spin`: first spin started. **Conflict:** `blocks_spin` (l.143, used at `combat_test.gd:1717,1756`) currently locks spinning until the fight cards close. `fight_spin` must stop blocking the spin and be completed by spinning. The stakes and items cards must not block either.
  - `fight_stakes`: bet changed (plus/minus) or X. `fight_items`: an item hover. `items_hand`: pickup (`world_item_pickup.gd:~203`). `items_wheel`: wheel opened (`item_wheel.gd:103`).
- Keep the 2-slot stacking and the HUD glow.
- Update `tools/qa/tutorial_popup_check.gd` (timer and dismiss cases).

## 3. Scripted first three spins (locker tutorial fight)
Existing hook: `combat/scripts/combat_root.gd` `_maybe_reseed_tutorial_last_spin` (l.1695-1704, called from `_start_spin_with_new_grid` l.1611) with `TUTORIAL_LAST_SPIN_SEED := 12` (l.99), gated by `AxelRun.is_tutorial_last_spin_lock` (`axel_run.gd:86-89`). Reuse this reseed mechanism instead of inventing a new one.
- Add `TUTORIAL_SCRIPT_SEEDS` (one seed per spin 1-3) used while the fight is the locker tutorial and spins_used < 3.
  1. Spin 1: normal symbols match, no power/vice. Card `slot_match`: how the line matched, how its points are worked out (bet x symbol value), and the **history box** (`NEW_History` / `HistoryPanel`, `HistorySpinList`).
  2. Spin 2: power symbols match and the premium meter (`PremiumSkull`, `premium_skull_meter.gd`, signal `premium_meter_changed`) fills. Card `slot_power`: skull meter.
  3. Spin 3: Vice Round (`_in_trinity_round`, combat_root l.2280-2323). Card `slot_vice`: explains the Vice Round. **Free Spins get no card (stay a mystery).**
- Find the seeds with a new headless script `combat/test/tutorial_script_seeds_check.gd` (scan seeds, assert each spin's outcome). Fixed seeds keep determinism.
- **Open risk to verify first:** whether the meter can fill and trigger the Vice Round in 2 spins. If not, pre-fill the meter on spin 2 through the existing meter setter for this fight only.
- New cards go in `LESSONS` (title style `? ... ?`, VT323 text) and glow `NEW_History` / `PremiumSkull` via `GLOW_PIECES`; trigger points near `_maybe_queue_fight_tutorials` (`combat_test.gd:2688`), completed by the spin result.
- Reminder (canon): combat reads no story flags, so the script keys only on `AxelRun` tutorial state, never on `GameManager`.

## 4. Tutorial fight when the player first passes the locker
- `1.2_Corridor.tscn` `LockerInteractArea` (Area2D at (1172, 620); polygon right edge ~ x 1745 in editor coords). Add a new `Area2D` "LockerPassTrigger" (own unique `Shape2D`, Make Unique) just right of that edge, with a margin. **Re-measure the live box after cover-fit this session** (canon rule).
- On first `body_entered` by the player, if `tutorial_fight_done` and `tutorial_fight_pending` are both false: call `AxelWorld.queue_locker_tutorial_fight()` (l.383) and then start it right away (the existing start path is `_start_locker_tutorial`, l.401, today called on arrival in 1.2).
- **Canon conflict to confirm:** AI_DOCS says "Do not start this fight from `1.2_Corridor.gd`". The corridor script would only queue and signal; `AxelWorld` still owns starting it (add a small public method such as `AxelWorld.start_pending_locker_tutorial()`). This changes that AI_DOCS line, which I will update.
- Keep the existing path (leave the hub back to 1.2) so entering the locker first still works. Do not use `corridor_return_pos` or the `1.2` right-arrow hint logic.
- Regression: extend `tools/qa/world_combat_loop_check.gd` and `corridor_right_hint_check.gd`.

## 5. Paytable x10
- Multiply `payout_x3/x4/x5` x10 in `combat/data/symbols/sym_*.tres` (e.g. green_circle 0.2/0.35/1.5 -> 2/3.5/15, satanic 1.5/2.5/28 -> 15/25/280). To show no decimals, 0.35 -> 3.5 still has one decimal; ask if x4 values should be rounded (e.g. 0.35 -> 3 or 4) or if x100 is wanted.
- Compensate in `combat_root.gd:98`: `BASELINE_PAYOUT_SCALAR 0.431 -> 0.0431` so payouts stay identical (`_line_payout_cents`, l.1854-1868). Leave the hard-coded `* 0.3` (l.2846) alone.
- Because real payouts do not change, **goals, bets, balance, ladder (100/150/225), saves and item percentages stay as they are**. (The user expected goals to move; they only move if payouts change.)
- Grep all readers of `payout_multiplier_for_length` / `payout_x*` (symbol_def.gd:13-27, rtp_audit, item_balance_audit, any paytable UI) and fix any that assume the old scale.
- Verify with `combat/test/rtp_audit.gd`, `determinism_check.gd`, `powers_check.gd`, `item_synergy_smoke.gd`.

## 6. Rarer walk fights
File: `scripts/autoload/axel_world.gd`: `STEP_CHANCE_BASE` (l.25), `STEP_CHANCE_PER_CLEARED_AREA`, `STEP_CHANCE_MAX`, `step_chance()` (l.290-292), `cleared_area_count()` (l.282).
- Replace the linear formula with a lookup by cleared areas: 0-1: 0.0002 (0.02%), 2: 0.0005, 3: 0.001, 4: 0.004, 5: 0.007, 6: 0.01 (1%). Keep cooldown 200 steps and the per-visit cap of 2; consider a cap of 1 early.
- Update the "Numbers" section of `plans/core/AXEL_WORLD_COMBAT_LOOP_PLAN.md` (l.144-148) and any AI_DOCS mention.
- Update `tools/qa/world_combat_loop_check.gd` l.133, 138.

## Docs
Update `AI_DOCS.md` (ideology, tutorial close rule, scripted spins, locker trigger, walk chance, paytable scale) and the matching plans. Put a copy of this plan in `plans/playtest/` as CLAUDE.md asks.

## Verification (run from repo root, `tools\cmd\godot.cmd`)
Run `--import` first, then `godot --headless --path AXEL/axel_project -s res://<script>` for: `combat/test/determinism_check.gd`, `powers_check.gd`, `combat_test_scaffold_check.gd`, `tools/scene_smoke_check.gd`, `tools/qa/audio_bus_layout_check.gd`, `settings_persistence_check.gd`, `pause_contract_check.gd`, `menu_nav_check.gd`, plus `tools/qa/tutorial_popup_check.gd`, `world_combat_loop_check.gd`, `combat/test/rtp_audit.gd` and the new seeds check. Then play-test by hand: new game, walk past the locker without opening it, confirm the scripted 3 spins and card behaviour.
