# New item families — combat plan (2026-10-15)

Design source: `plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md` § "Planned items". Icons are done (`plans/combat/AXEL_NEW_ITEM_ICON_PROMPTS.md`). Reference sheet: `AXEL/item_icons_reference.pdf` (items 76–93). **Status: plan only, waiting for approval.**

18 items: families **T** (Tickets), **X** (Hexes), **N** (Dread), plus the Common uniques **C11 Hall Pass**, **C12 Homeroom Bell** and **C13 Last Cigarette**.

## Rules every item follows

- **Two layers.** Combat never reads tickets, Dread, hexes or travel itself. `AxelRun` hands combat plain numbers before the fight (like `set_lore_goal_bonus`, `set_fight_curses`). Combat hands back plain results after the fight (like `on_encounter_finished`).
- **No caps** except the Wild limit (`EXTRA_WILDS_PER_CREATE_CAP`). Every number is a multiple of 5.
- **Deterministic.** Any roll inside a fight uses the fight's `CombatRNG`. Any roll in the world uses the run seed (like `reroll_item`).
- **Pulse rule:** an item pulses only on the spin where it changed something. Passive "fight start" items pulse once at fight start.

## New plain values `AxelRun` → combat

One new setter on `CombatRoot`: `set_run_context(ctx: Dictionary)`, called in `AxelRun.enter_world_encounter()` next to the goal and curses. Keys:

| Key | From | Used by |
|---|---|---|
| `tickets_held` | `AxelRun.ticket_count()` | `E-T` |
| `dread_pct` | `AxelRun.dread_pct()` | `C-N`, `R-N`, `E-N`, `L-N` |
| `hex_count` | count of active hexes on the loadout (Phase D3) | `R-X` |
| `curse_count` | size of the fight curse list | `L-X` |

F6 playtest: the dev tools get sliders for these four, so each item can be tested without the world.

## Family T — Tickets

| ID | Side | How it works |
|---|---|---|
| `C-T` Torn Stub | world | `AxelRun.ticket_price()` multiplies by `1 - 0.15` per equipped `ticket_discount` item (additive: 2 items = −30%, floor at 0), rounded to 5 |
| `U-T` Punch Card | combat → world | Combat already counts `won_spins` (paid spins that win; added for Ash Spin Token). At fight end `AxelRun` reads it and adds it to a saved `RunState.ticket_win_progress`. Every 10 → +1 ticket. A toast: `+1 TICKET` |
| `R-T` Lucky Strip | world | In `AxelWorld.reroll_item`, a seeded roll (run seed + tickets used + room + slot). At ≤ 15% the new item rolls one rarity higher (cap Legendary). Bypasses the "rerolled item keeps its rarity" rule only for this upgrade |
| `E-T` Hoarder's Roll | combat | New `effect_id` `ticket_payout` `{per_ticket: 0.05}`. Adds `tickets_held × 0.05` to the item payout scalar in `_get_item_payout_scalar()`. Pulses when it added something |
| `L-T` Twin Ticket | world | `reroll_item` rolls two candidates. The floor card shows both side by side; E picks left/right with `move_left` / `move_right`, `interact` confirms. The other one is thrown away. Needs a small card UI change |

## Family X — Hexes (build after Phase D3)

Phase D3 gives combat a per-item mask (`potency`, `chance`, `wilds_off`, `jam`, `sleep_spins`). These items **edit that mask in `AxelRun` before it is sent**, so combat needs no new hex code (except `R-X`, `L-X`).

| ID | Side | How it works |
|---|---|---|
| `C-X` Bent Nail | world | Weak hex potency 0.5 → 0.6 (more of these stack: +0.10 each) |
| `U-X` Knotted Cord | world | Sleep `sleep_spins` −1 (floor 0); Fickle `chance` 0.5 → 0.65 |
| `R-X` Scratched Cross | combat | `effect_id` `hex_payout` `{per_hex: 0.10}`: `hex_count × 0.10` added to the payout scalar |
| `E-X` Burnt Rosary | world | Drops one hex from the list before building the mask. "Worst" = fixed order: Jammed > Sleep > Wildless > Fickle > Weak; tie → the hex hitting more equipped items |
| `L-X` Hex Crown | combat | `effect_id` `curse_payout` `{per_curse_win: 0.20, per_curse_goal: 0.05}`: payout scalar `+0.20 × curse_count`; GOAL × `(1 − 0.05 × curse_count)` (floor 5) applied in `get_effective_goal_target_cents()`. Mostly matters in the basement gauntlet |

## Family N — Dread

| ID | Side | How it works |
|---|---|---|
| `C-N` Ink Drop | combat | `effect_id` `dread_payout` `{step: 0.20, per_step: 0.05}`: `floor(dread_pct / 0.20) × 0.05` to the payout scalar |
| `U-N` Faded Photo | world | `AxelRun.add_memory_dread()` uses 0.05 instead of `DREAD_PER_MEMORY` (0.10) while equipped. Equipped at the moment the memory is seen; not retroactive |
| `R-N` Cracked Inkwell | combat | `effect_id` `dread_power_chance` `{min_dread: 0.40, amount: 0.10}`: adds to the random power chance (same path as Static Spark) while `dread_pct ≥ 0.40`. Pulses like Static Spark |
| `E-N` Stained Report | combat | Adds `dread_pct / 2` to `head_start_percent()` (same path as the H family; stacks with it). Still never pays the full goal |
| `L-N` Swelling Stain | combat | `effect_id` `dread_payout` `{linear: 1.0}`: `dread_pct × 1.0` to the payout scalar. No limit |

## Common uniques

| ID | Side | How it works |
|---|---|---|
| `C11` Hall Pass | world | Saved flag `RunState.free_trip_ready`. Set to true when a fight is won. `AxelRun.travel_price()` returns 0 while it is true and Hall Pass is equipped; `pay_travel()` clears it. Map hover shows `FREE` |
| `C12` Homeroom Bell | combat | `effect_id` `first_spin_boost` `{mult: 2.0, meter_steps: 1}`. On the paid spin where `_spins_used == 0` at spin start: wins that spin × 2, and +1 Skull Meter step after the spin. Pulses on that spin. Free first spin from Fractured Reel still counts as the first paid spin |
| `C13` Last Cigarette | combat | `effect_id` `last_spin_boost` `{wilds: 2, mult: 3.0}`. "Last paid spin" = `is_curse_last_spin()` (Short Fuse) **or** BALANCE after paying this BET can no longer pay another BET (the same check that ends the fight). Before the drop: 2 Wilds placed on 2 seeded random non-Wild cells (fight `CombatRNG`), then wins × 3 that spin. Shows the existing `LAST_CHANCE` banner. Only paid spins; never Vice Round or Free Spins. Respects the Wild limit only for extra wilds made *from* these two |

## Where the multipliers go

- `E-T`, `R-X`, `L-X`, `C-N`, `L-N` add to the **item payout scalar** (`_get_item_payout_scalar()`), like the paid-spin line. Simple and uncapped.
- `C12` and `C13` multiply that spin's **total win** after cascades (like a spin-wide MULTIPLIER bonus), not the line values.

## Data, text, docs

- 18 `ItemDef` `.tres` in `combat/data/items/` (ids, names, rarity, `family` lane `T` / `X` / `N`, description from the reference PDF, `effect_id`, params, icon).
- Mirror the descriptions in `tools/combat/generate_item_resources.py` (do not rerun it).
- `item_lines.gd`: no change (uniques stay unique; families are lanes).
- World scatter: add `T`, `X`, `N` to `AxelWorld` area families. Suggestion: `T` → Halls + Cafeteria, `N` → Lounge + Classroom (deep rooms, more Dread), `X` → Basement + Classroom. Uniques `C11`–`C13` join the Common unique pool.
- Item box pulse table and glossary rows in the catalog plan.
- `item_icons_check.gd`: expected count 75 → 93.

## Build order (checks pass before the next step)

1. **Uniques + combat-only Dread:** `C12`, `C13`, `C-N`, `R-N`, `E-N`, `L-N` + `set_run_context`. Test in F6 with the dev sliders.
2. **Tickets:** `E-T` (combat), then `C-T`, `U-T`, `R-T` (world), then `L-T` (card UI).
3. **World-only:** `U-N`, `C11`.
4. **Hexes:** after Phase D3 lands: `C-X`, `U-X`, `E-X` (mask edits), `R-X`, `L-X` (combat).
5. Scatter families, catalog count 93, guide text if needed.
6. **Sim run** (`difficulty_curve_sim.gd`) with the new items and no caps; target ~64% dead at the lowest bet.

## Checks

New `combat/test/new_items_check.gd`: each combat item alone on a fixed seed (same seed twice = same result), Homeroom Bell only on the first paid spin, Last Cigarette only on the last paid spin and only once, Dread items at 0 / 20 / 40 / 100% Dread, Hoarder's Roll at 0 / 3 / 10 tickets. Plus `ticket_machine_check` (discount, Punch Card progress), `routing_check` (Hall Pass free trip), `world_item_scatter_check`, `item_wording_check`, `item_icons_check`, `item_synergy_smoke`, determinism, powers, scaffold and the standard set.

## Open questions

1. Punch Card: count only paid spins that win (planned), or Vice Round / Free Spins wins too?
2. Twin Ticket: is pick-one-of-two on the floor card OK, or should it be a separate pop-up?
3. Last Cigarette: if the first paid spin is also the last, Homeroom Bell and Last Cigarette both apply (×2 × ×3 = ×6). OK?
4. Area families for `T`, `X`, `N` (suggestion above).
