# Arc 6 — basement roulette + ending fights (2026-10-15)

HANDOFF item 6. Decisions by the user on 2026-10-15.

## Decisions

| Topic | Decision |
|---|---|
| Wheel spot | `6.4` main chamber, first visit only (after the stairs; you cannot go back up from 6.4) |
| Wheel pool | Any family (A–H, M, plus the baseline lines). Odds C/U/R/E/L = `0/15/40/35/10`. Never an item you own or one still on the floor |
| Spin rule | You may refuse to spin at all (no item, no Dread, cannot come back). The first spin is free. Once spun, you must take the result. Each respin costs 1 reroll ticket and replaces the result |
| Taking | Same as a floor pickup: owned, auto-equipped if a slot is free, Compendium, `+Dread` by rarity |
| Fights | 4 new fights, once each per save: **door** (6.1 "Unlock with key"), **chamber** (6.4, right after the wheel), **dig** (6.7), **final** (6.8, before the symbol choice). The shovel lore fight (6.5) stays |
| Goal | Arc 6 is depth 4: goal × **2.1** for every fight that returns to an Arc 6 room (the shovel fight too). Guess, playtest it |
| Curses | None yet. Phase D can add them to these 4 fights later |

## Build

- `AxelWorld`:
  - `DEPTH_GOAL_MULT` gets a 5th value `2.1`; `depth_goal_mult_for_scene()` treats any `res://scenes/Arc_6/` scene as depth 4.
  - `REASON_GAUNTLET = "ending_gauntlet"`, `start_gauntlet_fight(id, return_scene)` (once per id, saved in `gauntlet_fights`).
  - Roulette: `roulette_state()` (`""`, `pending`, `taken`, `declined`), `roulette_item()`, `roulette_spin()`, `roulette_respin()`, `roulette_take()`, `roulette_decline()`, `roulette_roll_id(spin)`, `roulette_reel_ids()`. Seed = run seed + spin index. Saved in `roulette`.
  - Floor pickup grant code moved to `_grant_item()` so the wheel gives items the same way.
- `scenes/ui/basement_roulette.gd`: dark full-screen wheel (8 slices, item icons), red pointer, result card, buttons Spin / Leave it, then Take / Respin. Keys: `interact` on the focused button, `reroll` = Respin, `back` = Leave it (only before the first spin). Placeholder look.
- `greybox_choice.gd`: `"roulette": true` and `"fight": id` in the room defs; a choice may carry `"fight"` (6.1 door).

## Not built

- Curses on these fights (Phase D).
- Real wheel art and sounds.
- The sim does not model Arc 6.

## Checks

New `tools/qa/basement_roulette_check.gd`. Plus `greybox_flow_check`, `basement_route_check`, `routing_check`, `ticket_machine_check`, `world_combat_loop_check`, and the standard set.
