# Phase D — Curses (plan, 2026-10-15)

Master plan: `2026-10-14_next_phase_master_plan.md` § Phase D. Builds on the Arc 6 work in `2026-10-15_arc6_roulette_gauntlet.md` (4 basement fights: door, chamber, dig, final). **Status: approved; D1 built (see Status).**

## Decisions (user, 2026-10-15)

| Topic | Decision |
|---|---|
| Item curse | Epic / Legendary from family X **weakens** family Y. The weakening varies per run (not only less power): chance, wilds off, an item off, and more |
| Gauntlet | **4 fights**: door (6.1), chamber (6.4), dig (6.7), final (6.8) |
| Gauntlet loss | **door** = normal loss (shatter, GONE, save deleted). **chamber** or **dig** = Ending 3 (`7.3`). **final** = Ending 4 (`7.4`) |
| Deep rooms (depth 3) | **No** curses |
| Rerolled item vs rank-up | Keeps its rarity, no boost (item 4 fix) |
| Legendary | Always carries a hex **and** one light fight curse |
| Ending 3 | "Disintegration": Mike's hands shake and burst at the seams; he dies on top of Axel. Two variants (chamber / dig). May reference the hexes |
| Who builds D1 | A separate chat (prompt given 2026-10-15) |

## 1. Fight curses (combat side)

New `CurseDef` resource (`combat/scripts/curse_def.gd`, data in `combat/data/curses/*.tres`): `id`, `name`, `description`, `effect_id`, `params`. Combat only gets a list of `{id, params}`. It never knows why.

| id | Name | Effect |
|---|---|---|
| `blind` | Blind | Cells show the back face until the line check |
| `no_vice` | No Vice | The skull meter never starts the Vice Round (so no Free Spins) |
| `sealed` | Sealed | 1–2 symbol types removed from the reel weights |
| `double_goal` | Double Goal | Goal × 2 |
| `item_jam` | Item Jam | Each paid spin, one equipped item is off for that spin |
| `heavy_meter` | Heavy Meter | +1 skull meter section |
| `short_fuse` | Short Fuse | At most N paid spins (fight is lost after that if GOAL is not met) |
| `thin_wallet` | Thin Wallet | Lowest bet is 200 |
| `ash` | Ash | Low symbols pay −25 % |

Random picks inside a fight (which item jams, which cell is blind) use the fight's `CombatRNG`, so it stays deterministic.

## 2. Gauntlet curses (narrative side picks, combat applies)

- `AxelWorld` picks curses per gauntlet fight from run seed + fight id: **door 1, chamber 1, dig 2, final 2**. No duplicates inside one fight.
- A card before the fight lists them (name + one line each).
- Passed to combat through `AxelRun.enter_world_encounter()` like the goal. Combat reads no story flags.
- **Loss routing:** on a lost `ending_gauntlet` fight, `AxelWorld` picks the destination: `door` → normal loss, `chamber` / `dig` → `7.3_Ending3`, `final` → `7.4_Ending4`. The loss shatter still plays; instead of GONE + buttons it fades into the ending. The save is handled the same way as reaching that ending today.

### Ending 3 — "Disintegration" (decided)

Replaces "His eyes won't return yours." / "It's not complete." White lines (Mike's conscience). `AxelWorld` saves which fight was lost (`chamber` or `dig`) before loading `7.3`; `ending_still.gd` picks the variant. Title card: **DISINTEGRATION**.

**Chamber lost** (reaching for the shovel):
1. "Your hands shake."
2. "The hexes want paying."
3. "Your hands split."
4. "You fall onto him."
5. "Together again."

**Dig lost** (as he starts to dig):
1. "One dig. Two."
2. "Your hands shake."
3. "The hexes come due."
4. "Your hands burst."
5. "Now you're buried too."

## 3. Item curses ("hexes")

- At New Game, a seeded `RunState.curse_table`: for each family (A–H, M), which other family it hexes and which hex. Never itself. Numbered baseline items (C1, U3, …) never hex and are never hexed (to be confirmed against the catalog).
- Equipping an **Epic or Legendary** of family X puts the hex on every equipped family-Y item. Unequip = hex gone.
- Two hexes on the same family both apply.

| Hex | Effect on family Y |
|---|---|
| Weak | Effects at 50 % power |
| Fickle | Effects only fire on 50 % of spins (`CombatRNG` roll) |
| Wildless | Y items cannot make wilds |
| Jammed | One Y item (seeded per spin) is off each paid spin |
| **Sleep** (my idea) | Y items do nothing for the first 3 paid spins of each fight |

- **Decided:** a Legendary always carries a hex **and** one light fight curse (`ash`, `heavy_meter` or `thin_wallet`, seeded). This replaces the old fixed L1 "+1 meter section" idea. Epic = hex only.
- Shown before pickup on the floor card and the wheel, and in the STATS tab: `Hex: Fickle on Diagonal items`.
- Combat gets a per-item mask (`potency`, `chance`, `wilds_off`, `jam`, `sleep_spins`) from `AxelRun`. `ItemEffectDispatcher` applies it.

## 4. Guide + sim

- New "Curses" page in `guide_pages.gd` (picture from existing art).
- **Tutorial cards (required, user 2026-10-15).** Add to `AxelTutorial.LESSONS`:
  - `items_hex` — "Hexes": "Epic and Legendary items carry a hex. Equipping one weakens another family of items. The card shows which before you take it." Request it the first time a floor card or the wheel shows a `Hex:` line (D3).
  - `fight_curse` — "Curses": "This fight is cursed. The card lists what is against you. Win anyway." Request it on the first gauntlet curse card (D2).
- The sim learns curses and hexes so balance can be re-measured (target ~64 % dead at the lowest bet still stands).

## Build order (each step: checks pass before the next)

1. **D1 – Curse framework + the 9 fight curses** in combat. Combat-related: run `combat_test_scaffold_check` first. New `combat/test/curse_modifiers_check.gd` (each curse alone, same seed twice = same result, Blind resolves correctly).
2. **D2 – Gauntlet curses + loss endings + Ending 3 text.** The Arc 6 roulette work is built (uncommitted); build on it.
3. **D3 – Hex table + item masks + card / STATS text.** Catalog plan gets a "Curse table" section.
4. **D4 – Guide page + sim run.**

## Files

`combat/scripts/curse_def.gd`, `combat/data/curses/`, `combat_root.gd` (hooks: weights, meter, goal, item mask, spin cap, blind), `item_effect_dispatcher.gd`, `run_state.gd` (`curse_table`), `axel_run.gd`, `axel_world.gd`, `greybox_choice.gd`, `ending_still.gd`, loss flow (`loss_shatter.gd` / loss menu), item card + STATS tab, `guide_pages.gd`, `AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.

## Checks

`curse_modifiers_check`, determinism, powers, scaffold, `item_synergy_smoke`, `guide_panel_check`, `basement_roulette_check`, `greybox_flow_check`, `basement_route_check`, `loss_menu_check`, the standard set, and the sim with curses.

## Status

Approved 2026-10-15. **D1 built 2026-10-15** (uncommitted). D2–D4 not started.

### D1 as built

- `CurseDef` (`combat/scripts/curse_def.gd`): `id`, `name`, `description`, `effect_id`, `params`. `describe(params)` fills `{key}` placeholders. Nine `.tres` in `combat/data/curses/` hold the default params.
- `combat/scripts/fight_curses.gd` holds the active list and answers the hooks. Passed params override the `.tres` defaults.
- Combat entry point: `CombatRoot.set_fight_curses([{id, params}, ...])`. Call it **before** `setup_new_grid()`, like the goal (Sealed is rolled there). Readers: `get_fight_curses()`, `get_active_curse_ids()`, `get_curse_name(id)`, `get_curse_description(id)` (Short Fuse fills `{left}` live), `get_curse_spins_left()` (-1 = no fuse), `is_curse_last_spin()`, `get_sealed_symbol_ids()`, `get_jammed_item_ids()`, `get_meter_section_count()`, `get_min_bet()`.
- No curses = no extra RNG draws, so fights play exactly as before.

| Curse | As built |
|---|---|
| `blind` | Cells dealt on a paid spin or a Free Spins handoff show a dark back face (placeholder art, generated in `symbol_slot.gd`). They flip face up (0.16s) right before the first line check. No RNG; results are identical to no curse |
| `no_vice` | Meter stops one section short and `is_full()` is always false (also blocks the dev Vice guarantee) |
| `sealed` | At fight start, `CombatRNG` seals 1–2 of the 3 vice symbols (cigarette, alcohol, bloody hand). They leave the spawn pool and the bloody hand morph pool |
| `double_goal` | Goal × `mult` (2.0) after the lore bonus, rounded up to the next 5. The head start follows |
| `item_jam` | Each paid spin, `CombatRNG` jams `count` (1) equipped item. `ItemEffectDispatcher` treats it as having no effect until the next spin starts. The item box dims it |
| `heavy_meter` | Meter has 3 + `extra_sections` (4) sections. The HUD skull fills in quarters |
| `short_fuse` | At most `spins` (8) paid spins, then the fight ends like running out of money. HUD shows **N SPINS LEFT** under the skull (red on the last one). A big **LAST CHANCE** banner plays on the grid before the last paid spin |
| `thin_wallet` | Lowest bet step becomes `min_bet` (200); auto-lower stops there and the fight ends below it |
| `ash` | LOW-tier symbols (3 lows + red heart) pay × `low_pay_mult` (0.75) |

- Debug: `AxelCombatDevTools` has a **CURSES** section, one toggle per curse. A toggle re-deals the current fight on the same seed and keeps the balance (`CombatRoot.debug_restart_fight()`, debug builds only, idle only).
- Check: `combat/test/curse_modifiers_check.gd` (each curse loads and fills its text; an empty list plays like no curses; each curse is repeatable on the same seed; per-curse effects; Blind resolves exactly like no curse). Screenshot helper: `tools/qa/curse_hud_capture.gd` via `run_quiet.ps1`.
- Checks passed 2026-10-15: curse_modifiers, determinism, powers, scaffold, item_synergy_smoke, dev_tools, combat_player_item_box, goal_bar_sync, and the standard set.
- For D2: `AxelRun` should call `set_fight_curses()` next to `set_goal_base_target_cents()`. The curse card can read `get_curse_name` / `get_curse_description`.
