# Difficulty curve: gentler start, unique fight seeds, item nerfs

## Context
Playtesters die far too early. I simulated 300–400 full runs along a normal route (tutorial → 1.4 → 2.1 + 2.2 memory → 2.3 + flashlight → 2.4 → …) with the new tool `combat/test/difficulty_curve_sim.gd`. The results:
- **Today:** 44% of runs are dead by the 2nd item, 85% by the 4th. A 1000 balance is only 4–5 fights of room, because a normal line on a 100 bet pays about 9–20.
- **Late game:** from about the 5th item, Rare/Epic/Legendary items push the payout rate (RTP) to 150–2000%. Nobody dies late, whatever the goals are. The main cause is the uncapped "+payout per paid spin" items (R1, E4): long late fights snowball.
- **Seeds repeat:** `encounter_seed()` uses `world_encounter_index`, which wraps at 3. Fights 2, 5, 8… in one save start from the same random numbers.

Goal: losing before about 4 items is very unlucky, deaths rise from items 5–6, and the late game can be lost again. The user allowed canon changes.

## Part A: unique seed for every fight
In `scripts/autoload/axel_run.gd`:
- `enter_world_encounter` (~206): `world_encounter_index += 1` with **no wrap**.
- `current_encounter_path()` (~141): pick `WORLD_ENCOUNTER_PATHS[world_encounter_index % size]`.
- `encounter_seed()` (~188): stays `seed + 500009 + world_encounter_index * 10007`. Every fight in a save now gets a new seed.
- Old saves (index 0–2) just keep counting up. `run_state.gd` load stays as is.
- Note: the encounter def's goal type does not change the win (`_finalize_encounter_if_needed` only checks chip GOAL). So the modulo choice is harmless.

## Part B: 3000 start balance, strictly rising ladder
`scripts/autoload/axel_run.gd`:
- `STARTING_BANKROLL_CENTS` 1000 → **3000**
- `WORLD_GOAL_LADDER_CENTS` → **`50, 60, 70, 80, 90, 110, 175, 300, 550`**. Fight 1 is the tutorial (50), then each fight is higher. After that, ×1.5 per fight.
- `WORLD_GOAL_LADDER_ROUNDING` 25 → **5**

`combat/scripts/combat_root.gd`:
- `get_effective_goal_target_cents` (~319): `_ceil_to_multiple(raw, 25)` → 5. Otherwise 60 shows as 75 and 80/90 as 100, and the goal stops rising each fight.
- `STARTING_BANKROLL_CENTS` (~86, F6 fallback only) → 3000. Leave `CHIP_BAR_FULL_CENTS` alone; nothing reads its health ratio.

The tutorial still works with goal 50. Its scripted seeds `10, 1, 12` reach spin 3 (Vice Round) before 50 is paid; the sim shows 3 spins. The last-spin lock only checks `is_chip_bar_goal_complete()`, with no hardcoded 100.

Sim result (min bet, rounding 25; rounding 5 is slightly easier): dead 0.8% by item 3, 6% by item 4, 11% at the flashlight, 20% by item 5, 30% by item 6.

## Part C: item nerfs (catalog plan first, then `.tres`)
Record every change in `plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md` (the only place for catalog edits), then mirror it in `combat/data/items/*.tres` `effect_params`.

| Item | Now | Recommended | Why |
|---|---|---|---|
| R1 Fractured Reel | +0.20/paid spin, cap 99 | +0.10, **cap 1.0** | uncapped growth is the late-game snowball |
| E4 Overflow Ledger | +0.30/paid spin, cap 99, +5% power | +0.15, **cap 1.5**, keep 5% | same |
| U1 Filtered Spinner | +0.15, cap 0.9 | +0.10, cap 0.6 | stacks with R1/E4 |
| R5 Chain Wildseed | every 2nd wild +1 | every **3rd** | wild chains |
| E3 Echo Loom | first wild each spin duplicates | keep | ok alone |
| L1 Twin Pentagram | every wild +1 | keep (Legendary) | capped by global rule below |
| R-E Diagonal Grid Lens | both diagonals, wilds | **major diagonal only**, keep wilds | both diagonals + wilds too strong; wilds false would copy U-E |
| E-B Meter Furnace | any line fills, wild_extra 1 | wild_extra **0** | Vice/Free Spins too often |
| L-E Diagonal Covenant | all diagonals, full lines, wilds | keep (full lines always spawn wilds by design) | Legendary; global wild cap applies |
| L-F Threshold Dominion | threshold 6 | threshold **8** | |

Global caps in `combat/scripts/item_effect_dispatcher.gd`:
- `paid_spin_payout_scalar` (137–146): clamp the **sum** across items to **+2.0**.
- `extra_wilds_for_create` (518–544): at most **+1** extra wild per created wild across all items.

## Part D: retune the late ladder after the nerfs
Rerun the sim with the nerfed items. Then adjust only rungs 7–9 (`175, 300, 550`) and the 1.5 growth until min-bet runs hit:
| Point | Target dead total |
|---|---|
| item 3 (fight 4) | ≤ 2% |
| item 4 (fight 6) | ≤ 7% |
| item 6 (fight 9) | 20–30% |
| item 9 (fight 13) | 50–65% |
| all 21 fights | 10–20% survive |

Also report the "bet 1/5 of balance" style (`DIFF_BET=fifth`). It will stay harsher; that is accepted.

## Part E: tests, sim, docs
- `tools/qa/world_combat_loop_check.gd:492`: expect the new ladder and strict increase for 30 fights. Add a check that 30 consecutive `encounter_seed()` values are all different.
- `tools/qa/play_scene_save_check.gd:113`: 1000 → 3000.
- `combat/test/chip_floor_sim.gd:12`: update its ladder copy.
- `combat/test/difficulty_curve_sim.gd`: keep it (new tool). Make the item pick use the real area rank flow it already models. Its `_source_const` must still parse the new constants.
- `scenes/ui/guide_pages.gd:41,48`: "starts with 3000", "Goals grow every fight: 50, 60, 70 …, then ×1.5". Rerun `rtp_audit.gd` and update `RTP_PERCENT` if it moves.
- Docs: `AI_DOCS.md` (World goal ladder paragraph: ladder, rounding 5, 3000 start, unique seeds), `CLAUDE.md` line 41, `AXEL_WORLD_COMBAT_LOOP_PLAN.md:79,81,157,220`.
- Save this plan as `plans/playtest/2026-10-09_difficulty_curve.md`. No comments in any script.

## Verification
1. `tools\cmd\godot.cmd --headless --path AXEL/axel_project --import`, then every CLAUDE.md check, plus `world_combat_loop_check.gd`, `play_scene_save_check.gd`, `playtest_fix_groups_check.gd`, `tutorial_script_seeds_check.gd`, `free_spins_round_check.gd`, `guide_panel_check.gd`, `run_state_check.gd`.
2. `item_balance_audit.gd`: no item over +0.5 delta RTP alone.
3. `difficulty_curve_sim.gd` with `DIFF_RUNS=400` (min and fifth): meets the Part D table.
4. Manual: new game shows `BALANCE: 3000`, tutorial goal 50 still reaches the Vice Round on spin 3, goals rise every fight.
