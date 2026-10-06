# Item proc check (2026-10-06)

## Why
In the 1.4 pickup fight, Cigarette Stub (C6) seemed not to glow after cigarettes matched. We wanted a check that proves each item's icon pulse can fire.

## What it does
`combat/test/item_proc_check.gd` checks every item.
- Each item is equipped alone in a fresh `CombatRoot`, together with a real `PlayerItemPanel`.
- It plays up to 300 seeded spins: 12 fights × 25 spins. Free Spins choices are picked in rotation.
- For each item it counts:
  - **procs**: `note_proc` calls, counted by a counting dispatcher subclass.
  - **pulses**: `PlayerItemPanel.pulse_play_count`, meaning the glow actually played.
- Each item gets a status:
  - `OK`: it activated and glowed.
  - `NO PULSE`: it activated, but no glow played.
  - `NEVER`: it never activated.
  - `MISMATCH`: the proc and pulse counts differ.
- The C6 repro forces a 3-cigarette line, with and without a wild in it, on both the sync and async resolve paths. It asserts one proc and one pulse each time.

Flags (after `--`):
- `--async`: use live-style async spins. Slow, about 50 s per item.
- `--only=<id>`: check one item only.
- `--verbose`: keep spinning after the first proc.

## First result
- C6 already worked on the sync path, the async path and the wild line. A cigarette **power** activation (burning cells) is not a line win, so C6 does not glow then. That is by design.
- 32 items could never glow, because their effects never called `note_proc`.

## Glow moments added (rule: glow when the item visibly changes something)
| Group | Items | Glows when |
|---|---|---|
| Skull meter | C-B, U-B, R-B, E-B, L-B | Its modifier changed how much a line filled the meter (`_apply_meter_from_lines`) |
| Free Spins start | C-D, U-D | Free Spins begin: extra spins or the payout burst (`choose_free_spins_power`) |
| Free Spins during | R-D, E-D, L-D | Extra cascade payout step, wild placed, chained extra power |
| Diagonal | C-E, U-E, R-E, E-E, L-E | A diagonal line pays (`_note_paid_line_procs`) |
| Goal | C-H, U-H, R-H, E-H, L-H | Fight start (`setup_new_grid`, `begin_next_playtest_encounter`) |
| Charms | U6, U7, U8 | The power's extra charm roll hits. `power_controller.gd` sets `ctx.charm_hit` |
| Vice Round | U-C, R-C, E-C, L-C | Extra spin granted, winning Vice spin, guaranteed power, extra random power |
| Power helpers | C5, C9, E2, R6 | Bonus armed (C5, C9), forced power (E2), echo power (R6) |
| None | L3 | Never. It only adds slots, and it is on the check's skip list |

`PlayerItemPanel` now queues a pulse whose row does not exist yet and plays it when the row appears, so the fight-start goal glow is not lost.

Helpers: `ItemEffectDispatcher.note_param(items, effect_id, key)` and `note_charm(items, power_id)`.

The check forces Free Spins for `free_spins` items and sets `girl_power_chance = 1.0` for R6. Result: 74 OK and 1 SKIP, exit 0.
