# Phase B — Dread, steeper late goals (2026-10-14)

From `2026-10-14_next_phase_master_plan.md` Phase B. Built while the user was away; Claude picked the recommended option at each choice.

## Done

- **Glyph rule (Phase A leftover):** every M item multiplies only the matched line through its cell. No glyph adds to the global MULTIPLIER. `dest`, `win_frac`, `GLYPH_MULT_SPIN_CAP` and `glyph_mult_room()` removed. R-M / E-M / L-M descriptions updated. The last-item range quirk in `glyph_params` stays (user choice).
- **L-E buff (Phase A leftover):** a 4-long diagonal spawns a wild (`wild_lengths: [4]` in `diagonal_opts`, read in `combat_root._resolve_lines_impl`). 5-long diagonals do not.
- **Dread:** `RunState.dread_pct` (saved). `AxelRun.DREAD_BY_RANK` C 4 / U 5 / R 6 / E 8 / L 10 %, `DREAD_PER_MEMORY` 10 %. Added on floor pickup (`AxelWorld.take_item`) and on every memory (`AxelWorld.start_memory_fight`, even when fights are switched off). Combat still gets one plain number: `AxelRun.goal_bonus_pct()` = lore + Dread, sent through `set_lore_goal_bonus` (added, not multiplied).
- **Shown:** red `DREAD n%` in the item box footer (hidden at 0). The floor item card ends with `+X% Dread`. Guide Goal page explains Dread.
- **Steeper growth:** after the ladder, each fight multiplies by `1.5 + 0.02 × steps past the ladder` (`WORLD_GOAL_GROWTH_STEP`).
- **Sim:** `difficulty_curve_sim.gd` models Dread (`DIFF_DREAD_ITEM` scale, `DIFF_DREAD_MEMORY`) and `DIFF_GROWTH_STEP`. Set all three to 0 for the old rules.

- **Ticket machine:** a framed `TICKET MACHINE` panel bottom-left in `1.3_LockerHub` (`scenes/ui/ticket_machine.gd`, placeholder until drawn art exists; hidden during first-visit lines and while the map is open). Price 300, then ×1.5 per ticket bought (rounded to 5); refused if it would leave less than 100. `RunState.tickets`, `tickets_bought`, `tickets_used` are saved.
- **Reroll:** new InputMap action `reroll` (F, pad X). Near a floor item with a ticket, F calls `AxelWorld.reroll_item`: same rarity, from the same area's families and baseline lanes, never the current lane first, seeded by run seed + tickets used + room + slot. Combat items only. The floor card ends with `[F] Reroll (n)` when tickets > 0; the item box footer shows `TICKETS n`.
- Known edge: an item rerolled in an untouched area can be re-rolled again by the area rank-up when you first take from another area.
- Regression: `tools/qa/ticket_machine_check.gd`.

## Sim result (2026-10-15, 100 runs each)

Dead by the end, min bet: new rules 63–66 %, old rules 55–64 %. ⅕ bet: 90 %. The user wants items uncapped and ~64 % deaths, so this is on target. Data: `2026-10-14_sim_data.xlsx`.

## Not done yet

- Reroll items: designed 2026-10-15 as family T (Tickets) in the catalog plan; build plan `2026-10-15_new_item_families_plan.md`.
- Dread tutorial card `items_dread`: done 2026-10-15 (first floor card that shows `+X% Dread`).
- Dread line on the fight intro / goal panel.
- AI_DOCS update (wait for "update docs").
