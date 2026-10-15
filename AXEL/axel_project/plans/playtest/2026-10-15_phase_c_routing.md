# Phase C — Routing: paid travel, hidden rarity, locker glimmers (2026-10-15)

From `2026-10-14_next_phase_master_plan.md` Phase C. Decisions confirmed by the user on 2026-10-15.

## Decisions

| Topic | Decision |
|---|---|
| Map item info | Hidden on the pause map and the locker map (done: `LockerMapOverlay.show_items` defaults to `false`) |
| Travel price | Flat **10 % of current balance**, rounded to 5, minimum 50. Refused if it would leave less than 100 |
| Area depth | Halls 0 · Basement door `1.4` 0 · Cafeteria 1 · Kitchen 1 · Backyard 2 · Lounge 3 · Classroom 3 |
| Depth 4 | The Arc 6 basement (after the stairs). Not a floor area. A dark-screen roulette wheel gives one item (one spin, respin with reroll tickets). How many Arc 6 fights: not decided. **Later task, not Phase C** |
| Depth goal multiplier | ×1.0 / 1.25 / 1.5 / 1.8 for depth 0–3 (tuned by sim from the plan default 1.0 / 1.1 / 1.25 / 1.4) |
| Loadout | Equip and unequip stay possible anywhere |
| Locker glimmers | Rooms that still hold a Legendary floor item, an unseen memory, or a true-ending item (flashlight, key, name board). Locker map only, never the pause map. Soft room-sized glow, no pin, no name |

## Built (2026-10-15)

- **Depth:** `AxelWorld.AREA_DEPTH` + `area_depth()`.
- **Hidden depth-weighted rarity:** `_roll_item` now rolls each floor item's rarity with `_roll_rarity` from `DEPTH_RARITY_WEIGHTS` (C/U/R/E/L): depth 0 `100/0/0/0/0`, 1 `80/20/0/0/0`, 2 `55/35/10/0/0`, 3 `30/40/25/5/0` (tuned by sim, see below). Each area rank-up (the old "untouched areas" rule) shifts the weights one tier up (`rarity_weights()`). Same seed → same items. The floor marker hides its rarity mark until Mike walks into the item's range (`world_item_pickup._reveal_rarity`); the walk-near card still shows everything.
- **Paid travel:** `AxelRun.travel_price()` = 10 % of balance rounded to 5, min 50; `pay_travel()` refuses below 100 left; `RunState.travel_uses` saved. The map hover shows `ROOM  price`; clicking a room you cannot afford flashes `Not enough`. Clicking the room you are in is free.
- **Depth goal:** `AxelRun.world_goal_cents_for_fight()` = ladder base × `DEPTH_GOAL_MULT` of the fight's room (×1.0 / 1.25 / 1.5 / 1.8, tuned by sim), ceiled to 5; the tutorial keeps its base. Combat still gets one plain number.
- **Deep-room line:** the first time you enter a depth-3 area (Lounge, Classroom) the bar says "The air is heavier here." once it is free (saved in `AxelWorld` `deep_air_seen`).
- **Locker glimmers:** `AxelWorld.room_glimmers(scene)` (open Legendary floor item, unseen memory, or missing flashlight / key / name). `LockerMapOverlay.show_glimmers` draws a soft pulsing red radial glow over those rooms; only `1.3_LockerHub` turns it on.
- **Sim:** `difficulty_curve_sim.gd` rolls depth rarity and applies the depth goal (`DIFF_DEPTH=0` turns it off). Travel is not modelled.

## Sim tuning (2026-10-15)

Target: ~64 % of runs dead by the end at the lowest bet (user, items uncapped). Phase B alone: 63–66 %.

| Setting | Random picks | One-family picks |
|---|---|---|
| Plan weights (`70/25/5…` → `0/15/35/40/10`) + goals 1.0–1.4 | 46 % | 43 % |
| Same weights + goals 1.0–2.2 | 49 % | 44 % |
| Softer weights w1 | 50 % | 55 % |
| Softest weights w3 (shipped) | 55 % | 61 % |
| **w3 + goals 1.0 / 1.25 / 1.5 / 1.8 (shipped, 200 runs)** | **56.5 %** | **59 %** |

Deaths happen in fights 4–9; later goals barely matter because survivors get too rich to lose. Early rarity is the real lever. ⅕ bet: 84.5 % dead. Data: `2026-10-14_sim_data.xlsx`.

## Not built

- Stronger CRT/glitch in deep rooms (visual tuning, needs a playtest).
- Glimmer pulse on a Legendary floor marker in the room you are in.
- Arc 6 basement roulette (depth 4) — later task.

## Checks

`routing_check` (new: depths, weights, travel price, depth goal, glimmers), `locker_map_travel_check` (price, no pins by default), `pause_map_restore_check`, `world_item_scatter_check` (depth weights, same per seed), `world_item_pickup_nearest_check`, `world_combat_loop_check`, `ticket_machine_check`, the standard set, and a locker map capture with glimmers via `capture_scene.ps1`.
