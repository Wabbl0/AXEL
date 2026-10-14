# AXEL — Next phase master plan (2026-10-14)

One file, one section per phase. A new session can start any phase from here without re-reading the old chat. Read `plans/core/AI_DOCS.md` first as usual. This file is the design intent for the next phase, and AI_DOCS still wins on any conflict until the user says "update docs".

---

## 0. Shared context (read for every phase)

### Why this phase exists

AXEL is a roguelike. It must be replayable many times, **including after the true ending**. Playtest problems the user reported:
1. A few items are far too strong, Legendaries above all (Twin Pentagram).
2. The game is too easy. After about 5 items, losing becomes very hard whatever the playstyle.
3. The locker has no job except showing the map, and the map is always available anyway.
4. Fast travel removes the point of choosing a route. The map shows every item and its rarity from the start, so there is no surprise.
5. The map is small (10 walkable rooms, 13 floor items per run), so replays feel the same.
6. The ending path (Arc 6) has no fights except the shovel lore fight.

### The user's ideas (all of them, as prompted)

- Find which items are too strong and nerf them by testing.
- Should the goal grow faster after each item pickup?
- **Locker:** stop showing items. Show only a faint glimmer where a Legendary spawned and/or where memories and true-ending items are.
- **Fast travel and the full-reveal map defeat routing.** Randomize all items by rarity, with far areas more likely to hold higher rarities. Far areas may have bigger goals. How do we show that to the player?
- Every memory and every picked-up item should raise the goal by some % (the user first said secretly; it was then decided to make it visible, see Decisions).
- **More map variety without drawing many scenes.**
  - Stitch room parts together, or move the drawn doors.
  - If stitching fails: the user will **draw extra doors** into rooms. Per seed, each door is sometimes *unavailable* and sometimes *leads somewhere else*. There could be more than 10 layouts. **Claude must generate the matching map for every layout itself, using the current `axel_map_v2.png` as the style reference.**
- **Reroll tokens.** A "ticket machine" eats balance, costs more each use, and gives reroll tickets, so the player gets another chance at the item they want.
- **Reroll items** (items that give or improve tickets), after the ticket machine exists.
- **Ending:** each ending scene gets its own fight with random rules. Examples: play blind; no Vice Round / Free Spins; some symbols disabled; double goal; item X disabled each spin.
- **Keep Diagonal Covenant.** Keep at least one Legendary that allows diagonal matches; it can require 4+ in a row. Items are never deleted, only made weaker.
- **Late game should get harder almost exponentially**, so the player feels urgency to gather everything and reach the basement before the goal gets too high.
- **Curses on items from Epic up.** Using an item from one family puts a curse on other families, and so on. **The curses are randomized each run**, so every seed differs more.
- Players tend to build around **one family plus a high-rarity item that fits**. Simulate that (done: `DIFF_PICK=synergy`).

### Claude's extra ideas (accepted into the plan)

1. **Dread Levels after the true ending.** These work like "stakes" or "ascension": each level adds one curse to every run, and winning on a level unlocks the next.
2. **Seed entry / daily seed.** The seed is already shown in pause and on the Load buttons.
3. **Cursed Legendaries.** Each has a big upside with a real downside. This merges with the user's Epic+ curse idea in Phase D.
4. **Loadout changes only at the locker.** You can view items anywhere but only equip or unequip at the locker. **Not scheduled; ask the user in Phase C.**
5. **One shared Curse system** used in three places: item curses, the ending gauntlet and deep or Legendary rooms, and Dread Levels.

### Decisions the user confirmed

| Topic | Decision |
|---|---|
| Goal reaction to items/memories | **Visible "Dread"** (not secret) |
| Fast travel | **Stays, but costs balance** |
| Ticket machine | **Physical machine at the locker** |
| Order | **Phase A first** (done), then B, C, D, E |
| Nerfs in Phase A | **Approved and applied** (see Phase A) |
| Diagonal Covenant | Keep it; diagonals need **4+ in a row** |
| Stitching | Try later (Phase E). If it fails, use extra drawn doors + door shuffle + a generated map |

### Verified facts about the current code (2026-10-14)

- **Goal:** `AxelRun.world_goal_base_cents()` (`scripts/autoload/axel_run.gd` ~171) is indexed only by `RunState.world_fight_count`. The ladder is `WORLD_GOAL_LADDER_CENTS`, then `×WORLD_GOAL_LADDER_GROWTH` (1.5), rounded to 5.
  - The lore bonus is +15% for each of `hasFlashlight/hasKey/hasShovel/hasName` (`LORE_GOAL_BONUS`, `lore_goal_bonus()`).
  - The final goal is `ceil5(round(base × (1 + lore)))` (`combat_root.gd` `get_effective_goal_target_cents()` ~336).
  - **No item pickup and no memory raises the goal today.**
- **Balance:** a new save starts at 3000. Wins add to the balance for the whole save with no cap. A fight is lost only when you cannot pay for a spin (minimum bet 100). The bet steps are 100/200/300/400/500/1000.
- **Item caps** (`combat/scripts/item_effect_dispatcher.gd` top): `PAID_SPIN_SCALAR_TOTAL_CAP 2.0`, `EXTRA_WILDS_PER_CREATE_CAP 1`, `HEAD_START_CAP 0.5`. The new caps from Phase A are listed below.
- **Slots:** 7, or 9 with L3 (`combat/scripts/item_inventory.gd`).
- **Floor items:** `AxelWorld.AREAS` (`scripts/autoload/axel_world.gd` ~31). There are 7 areas and 13 items:

  | Area | Items |
  |---|---|
  | halls (2.4) | 1 |
  | cafeteria | 3 |
  | kitchen | 2 |
  | lounge | 2 |
  | classroom | 2 |
  | basement (1.4) | 1 |
  | backyard | 2 (no walk fights) |

  - `plan_floor_items(run_seed)` (~784) puts every item at Common.
  - `_upgrade_untouched_areas` (~533): the first pickup in an area ranks up every untouched area by 1, so the last area can be Legendary.
  - `_retier_open_areas` (~990) re-rolls those areas from the same seed and the same spots. `_roll_item` (~1675) builds `L-<family>` ids and walks down a rank if the file is missing. World scatter never rolls L2, L3 or R6.
  - Area families live in the catalog plan, in "Area / Rarity Progression Plan".
- **Map:** `scenes/ui/locker_map_overlay.gd`:
  - `_refresh_pins` (~656) draws every floor item, and `_pin_glyph` (~646) adds its rarity glyph.
  - `_refresh_cards` (~717) and `_make_item_card` (~759) show the hover cards.
  - `_on_part_gui` (~381) starts travel through `AxelWorld.map_can_travel` (~242), which needs the room visited and, if it has items, one item taken.
  - Hosts: `scenes/Arc_1/1.3_SchoolMap.gd` (pause map, through `AxelPause.open_map`) and `scenes/Arc_1/1.3_LockerHub.gd` `_on_map_travel` (~78).
- **Locker:** `scenes/Arc_1/1.3_LockerHub` + `locker_shelves.gd` show the flashlight, key and name tag pictures only.
- **Memories:** 2.2, 3.2, 4.2 and 5.2 (`MemoryStill`, `scenes/core/memory_still.gd` `begin_leave` ~85). Each adds a memory, then calls `AxelWorld.start_memory_fight`. No item is given.
- **Lore items:** `scenes/core/lore_pickup.gd`. Flashlight in 2.3, Key in 4.1, Name via the 5.1 board, Shovel in 6.5 (`greybox_choice.gd` ~286). Each starts one lore fight.
- **Ending path:**
  - Arc 6 scenes are greybox choice menus (`scenes/core/greybox_choice.gd` `_def` ~237): 6.1 door (key) → 6.3 stairs (flashlight) → 6.4 → 6.5 shovel / 6.7 dig → 6.8 corpse.
  - "Face it" leads to `7.5_EndingTrue` if `AxelWorld.answered_item_equipped()`, otherwise to `7.4_Ending4`.
  - The Arc 6 rooms are not in `AREAS`, so there are no walk fights.
- **Rooms:** each room is one painted PNG with the doors drawn in (for example `exports/Drawings/2.1_Cafeteria.png` 3508×2480, `1.2_Corridor.png` 2400×1500). Doors are `Area2D` boxes (`InteractArea` / `ExitTrigger`). Colliders are `StaticBody2D` rectangles. The 10 walkable rooms are 1.1, 1.2, 1.4, 2.1, 2.3, 2.4, 3.1, 4.1 and 5.1 (+ the 1.3 hub UI).
- **Simulator** `combat/test/difficulty_curve_sim.gd` (stdout only; save the output to the scratchpad):
  - `DIFF_RUNS`, `DIFF_BET=min|fifth`, `DIFF_LADDER`, `DIFF_GROWTH`, `DIFF_LORE`, `DIFF_BANKROLL`, `DIFF_FIGHTS`.
  - `DIFF_SOLO=<id;id,id>` with `DIFF_SOLO_SPINS` and `DIFF_SOLO_SEEDS`.
  - **New:** `DIFF_PICK=synergy`, `DIFF_CHOICES=3`, `DIFF_LANE=<family>`.
  - Gaps: `MAX_EQUIPPED` is fixed at 7, and the route is fixed at 21 fights (no Dread, no travel).

### Rules every phase must keep (from CLAUDE.md / AI_DOCS)

- No comments in any script. InputMap actions only. `CombatPace`, never `Engine.time_scale`. Don't restart the music player. No machine-absolute paths.
- Keep the two layers apart. **Combat reads no story flags.** Anything the world wants combat to know (goal, Dread, curses) goes in as a plain value through `AxelRun` (like `set_goal_base_target_cents`, `set_lore_goal_bonus`). Combat stays deterministic: every new random roll uses the fight's seeded RNG or a separately seeded RNG, never `randf()`.
- Only `AxelRun` starts a fight. Item catalog edits go only in `plans/combat/AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.
- Before combat edits, run `combat/test/combat_test_scaffold_check.gd`.
- Door arrivals: re-measure the live destination box (SCENE_BUILDING.md). Every room collider needs a unique Shape2D.
- Names: Vice (not Trinity), alcohol (not booze), Free Spins (not SUPER), and the Vice Round is never "Free Spins".
- Screenshots only through `tools/qa/capture_scene.ps1`.
- "Update docs" means AI_DOCS + the matching plans. Do not commit until the user says "commit and push".

### Checks after any GDScript change

From the repo root: `tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://<script>`. Run `--import` once first.

- **Standard set:** `combat/test/determinism_check.gd`, `combat/test/powers_check.gd`, `combat/test/combat_test_scaffold_check.gd`, `tools/scene_smoke_check.gd`, `tools/qa/audio_bus_layout_check.gd`, `tools/qa/settings_persistence_check.gd`, `tools/qa/pause_contract_check.gd`, `tools/qa/menu_nav_check.gd`.
- **Plus, depending on the area:** `combat/test/item_synergy_smoke.gd`, `tools/qa/world_combat_loop_check.gd`, `tools/qa/world_item_scatter_check.gd`, `tools/qa/locker_map_travel_check.gd`, `tools/qa/guide_panel_check.gd`, `combat/test/goal_bar_sync_check.gd`, `tools/qa/item_wheel_check.gd`, `tools/qa/pause_map_restore_check.gd`.

---

## Phase A — Measure + nerf (DONE 2026-10-14, uncommitted)

Full data: `plans/playtest/2026-10-14_item_power_audit.md`.

### What the measuring showed (before the nerfs)

- **It was a wall, then a flat line.**
  - At minimum bet, 35–45% of runs died at fights 6–9; at a ⅕ bet, about 75%. This is where the old ladder jumped (110 → 175 → 300 → 550, plus the flashlight +15%).
  - After about 7 items the payout rate passed 100% (a slot with no items pays back about 40–50%). Each spin made money, so nobody died after fight 10.
- **Synergy picks** (one family + a fitting high rarity) made the late game 2–4× richer, with payout rates up to 5,000%. Every family became unloseable by fight 14, so the problem was global.
- **Strongest items alone:**
  - L1 Twin Pentagram ~404%
  - L-E Diagonal Covenant 266–368%
  - R5 Chain Wildseed 125–160%
  - E-B Meter Furnace ~130%
  - E4 ~110–136%
  - E3 ~110%
  - U5 ~95%
  - the M glyph items ~82–103% at every rank
- **No effect alone:** all D (Free Spins) items, all H items (head start, expected), C9, C10, E-C, L3.

### Applied

- **Items** (descriptions updated in each `.tres`):
  - U5 25% → 15%. R5 every 3rd → every 5th wild.
  - E3 and L1 now 50% chance (`"chance": 0.5`, read by the new `_roll_item_chance`).
  - L-E keeps mode `all` but adds `"min_length": 4`. Diagonals of length 3 no longer count, so diagonal 3-lines no longer spawn wilds.
  - E-B: any Power win now fills 2 sections instead of 3 (`any_line_fill_amount`).
  - U-M x2–3 → x1.5–2.5. R-M 3 → 2 cells. E-M 4 → 3 cells.
- **New global caps** in `item_effect_dispatcher.gd`:
  - `LINE_PAYOUT_BONUS_CAP 1.0` (+100% line bonus)
  - `GLYPH_MULT_SPIN_CAP 4` (the most glyphs can add to the MULTIPLIER per spin; `glyph_mult_room()`, used in `combat_root._apply_glyph_payouts`)
  - `FREE_SPINS_EXTRA_CAP 4`
- **Diagonal minimum length:** `line_detector.gd` `find_lines` drops diagonal lines shorter than `opts.min_length`. `diagonal_opts` passes `min_length`.
- **Ladder:** `50, 60, 70, 80, 95, 115, 145, 190, 250, 330`, then ×1.5. Updated in `axel_run.gd`, `guide_pages.gd`, `world_combat_loop_check.gd` and `chip_floor_sim.gd`.
- **Tests:** `powers_check.gd` now reads glyph cell counts from the item files. All checks above pass (determinism, powers, scaffold, synergy smoke, world loop, scatter, guide, goal bar sync, scene smoke, audio, settings, pause, menu).

### Still to do in Phase A (first thing next session)

1. After-nerf numbers are in the audit file ("After-nerf numbers").
   - **L1:** 404% → 139–178%.
   - **L-E is over-nerfed (42–59%, about no items).** Pick a fix: diagonal wins ×1.5, or 4-long diagonals may spawn a wild. Then re-balance the Legendaries as a group (L-M is now weaker than R5).
   - **Late pay is still 200–500%**, passing 100% from about item 6–7. Late deaths are back (64.5% dead at the end at minimum bet), but Phase B growth and Dread are still needed.
   - **RTP stays 51%** (no Guide change).
2. ~~Update `AXEL_COMBAT_ITEM_CATALOG_PLAN.md`.~~ Done 2026-10-14 (rows + "Nerf pass (2026-10-14)" section). Edit the rows for U5, R5, E3, L1, L-E, E-B, U-M, R-M and E-M, and add a "Nerf pass 2026-10-14" section listing the new caps.
3. ~~RTP check~~ done: baseline 51.3%, Guide stays 51.
4. ~~Change the AI_DOCS ladder line, the caps line and the L-E diagonal note.~~ Done 2026-10-14.
5. Known leftover: `glyph_params` uses the **last** glyph item's `mult_min/mult_max` for every glyph cell (mixing L-M with U-M makes all cells x2.5–3.5). Decide whether each cell should use its own item's range.

---

## Phase B — Dread, exponential late game, money sinks

### Goal

The late game gets harder almost exponentially, so the player feels urgency to gather items and reach the basement before the goal runs away. The bankroll stops snowballing.

### Design

1. **Dread (visible).**
   - What it is: a run value, `RunState.dread_pct`, saved with the run.
   - What raises it:
     - Every combat item picked up: about +6% (by rarity: C +4, U +5, R +6, E +8, L +10; tune with the sim).
     - Every memory finished: +10%.
     - Lore flags keep their own +15% (do not double-count).
   - How it reaches combat: `AxelRun` passes it like the lore bonus. Goal = `ceil5(round(base × (1 + lore) × (1 + dread)))`, or added to lore; pick one and test it.
   - Where it shows:
     - a `DREAD n%` line in the item box footer next to BALANCE
     - a small line on the fight intro or goal panel
     - the walk-near item card: "+X% Dread" under the description, so the cost is known before picking up
   - Feel: noir red / glitch intensity can rise slightly with Dread (style only, optional).
2. **Exponential late curve.**
   - Keep the gentle early ladder from Phase A.
   - After the ladder, raise `WORLD_GOAL_LADDER_GROWTH` from 1.5 to about 1.6–1.75, or make it grow by itself (for example 1.5 + 0.02 × fights past the ladder).
   - Optional "time pressure": walk fights already rise with cleared areas (`STEP_CHANCE_BY_CLEARED`), so dawdling = more fights = higher goals. That is already the urgency loop, and it gets stronger with steeper growth.
   - Target (update AI_DOCS line 61): ≤2% dead by item 3, ≤7% by item 4, 20–30% by item 6, 50–65% by item 9, 10–20% survive all 21. Also the new one: **the payout rate stays under ~100% until about item 9 in synergy mode**.
3. **Ticket machine (physical, at the locker).**
   - Where: a new interactable in `1.3_LockerHub` (or next to the locker in `1.2_Corridor`; place it in 1.3 if possible so the Arc 1 corridor is not touched; 1.2 is a legacy Arc 1 scene and needs approval).
   - Price: each ticket costs more, for example 300, 450, 675… (×1.5, rounded to 5), saved in `RunState.tickets_bought`.
   - Use: on a floor item's walk-near card, spend 1 ticket to re-roll that item's identity at the same rarity and from the same area families. Use a seeded RNG (run seed + ticket count), so the same choices give the same results.
   - Card UI: the card already shows `[E]`. Add a second key line (a named InputMap action, for example `reroll`) shown only when tickets > 0.
   - Tickets count in the item box footer.
4. **Reroll items** (after tickets are playtested): add as a new extended family in the catalog plan (5 rarities by default, or a subset if the user says), for example "first ticket each area free", "tickets 25% cheaper", "reroll may go up one rarity at 10%". These are catalog edits.
5. **Sim support:**
   - `difficulty_curve_sim.gd`: add `DIFF_DREAD_ITEM`, `DIFF_DREAD_MEMORY` and a growth curve option.
   - Model memory fights giving Dread (the SCHEDULE already marks memories).

### Files

`scripts/autoload/axel_run.gd` (goal and Dread pass-through), the RunState script (find where `world_fight_count` lives), `scripts/autoload/axel_world.gd` (pickup/memory hooks: `LorePickup`, `start_memory_fight`, the floor pickup path), `scenes/core/memory_still.gd`, `scenes/ui/item_wheel.gd` (footer), `scenes/ui/world_item_info_card.gd`, `scenes/Arc_1/1.3_LockerHub.gd/.tscn`, `combat/scripts/combat_root.gd` (goal effective, read only a plain number), saves (`AxelSaves`, state serialization), `guide_pages.gd` (Goal page text: Dread, growth).

### Checks

Standard set, plus `world_combat_loop_check` (update the ladder/growth test), `run_state_check`, `save_slots_check`, `item_wheel_check`, `world_item_info_card` checks, `guide_panel_check`, the sim targets, and a new `ticket_machine_check.gd` (price steps, deterministic reroll, same-rarity guarantee).

### Open questions for the user

- Dread per item: flat or by rarity?
- Can tickets reroll a memory or lore item? (Suggest no.)

---

## Phase C — Routing: paid travel, hidden rarity, locker glimmers

### Goal

Choosing a route matters again. Items are a surprise until you're close. The locker has a job.

### Design

1. **Map shows layout only.** Remove item pins and item cards from `locker_map_overlay.gd` (`_refresh_pins`, `_refresh_cards`, `_make_item_card`) for the pause map, `1.3_SchoolMap`. Room hover still fills red with the name.
2. **Paid travel.**
   - Travel keeps the `map_can_travel` rules but costs balance.
   - Suggested cost: base 150 × (1 + 0.5 × uses so far) × a distance factor (1 for neighbor rooms, 1.5 for far ones), rounded to 5.
   - Show the price in the hover. Refuse (red flash, "Not enough") if the balance after paying would be below the lowest bet + a margin (never let travel kill a run).
   - Save `RunState.travel_uses`.
3. **Hidden, depth-weighted rarity** (replaces the open rank-up being visible).
   - Each area gets a depth (for example halls 0, cafeteria 1, kitchen 1, backyard 2, lounge 2, classroom 3, basement 3; confirm with the user).
   - Roll each floor item's rarity from seeded weights by depth, for example depth 0: C 70 / U 25 / R 5; depth 3: R 35 / E 40 / L 10. Keep the "untouched areas rank up" pull as +1 weight shift.
   - The floor marker looks the same until you're near. The walk-near card still reveals the item (as now).
   - In the room you're in, a Legendary marker could add a faint glimmer (shader pulse), so it's tempting once you're there.
4. **Far areas = bigger goals.** A goal multiplier by area depth (for example ×1.0 / 1.1 / 1.25 / 1.4), passed as a plain number with the goal. Shown in the world: a deep room gets stronger CRT/glitch and red, plus a 1-line enter text the first time ("The air is heavier here."). The goal panel can show the multiplier.
5. **Locker = rumors.**
   - The locker map paper (`1.3_LockerHub` map) shows **no items**. It shows a faint pulsing glimmer on rooms that hold a Legendary, an unseen memory or a true-ending item (flashlight/key/name board), with no exact spot and no item name.
   - The pause map never shows glimmers, so walking back to the locker is worth it.
   - The glimmer can be fuzzy: a room-sized soft glow, not a pin.
6. **Ask the user:** loadout changes only at the locker (Claude idea 4)?

### Files

`scenes/ui/locker_map_overlay.gd`, `scenes/Arc_1/1.3_SchoolMap.gd`, `1.3_LockerHub.gd`, `scripts/autoload/axel_world.gd` (`plan_floor_items`, `_roll_item`, `_upgrade_untouched_areas`, `map_can_travel`, a new `area_depth`), `axel_run.gd` (area goal mult), the room enter text, `item_wheel.gd` AREAS tab (it shows `taken/placed`; keep it, but don't reveal rarity).

### Checks

`locker_map_travel_check` (update for price + no pins), `pause_map_restore_check`, `world_item_scatter_check` (depth weights, determinism per seed), `world_item_pickup_nearest_check`, `world_combat_loop_check`, the standard set, and a capture of the locker map with glimmers via `capture_scene.ps1`.

---

## Phase D — Curse system (items Epic+, ending gauntlet, deep rooms)

### Goal

One modifier system adds trade-offs to strong items and variety to every seed, and gives the ending real fights.

### Design

1. **Curse definitions.** `combat/data/curses/*.tres` (a new `CurseDef` resource: id, name, description, `effect_id`, params). Combat only receives a list of active curse ids/params. It never knows why they are active.
   - **Starter list (the user's examples first):**
     - **Blind:** symbols are hidden until the spin resolves (cells show the back face until line check).
     - **No Vice:** the skull meter does not trigger the Vice Round (so no Free Spins).
     - **Sealed symbols:** 1–2 symbol types are removed from the reel weights.
     - **Double goal.**
     - **Item jam:** each paid spin, one equipped item (seeded pick) is disabled for that spin.
     - **Heavy meter:** +1 section needed.
     - **Short fuse:** at most N paid spins this fight.
     - **Thin wallet:** minimum bet is 200.
     - **Ash:** low symbols pay −25%.
2. **Item curses (user idea): Epic and Legendary items carry a curse.**
   - Rule: equipping an Epic+ item from family X **curses another family Y** (Y's items work at reduced power, for example −50% potency, or are disabled), and/or adds one fight curse from the list.
   - **Randomized per run:** at New Game, build a seeded curse table, `RunState.curse_table`: for each family, which family it curses and which fight curse its Epic/Legendary carries.
   - Show it on the item card and in the STATS tab: "Cursed: weakens Diagonal items" / "Curse: Item jam". Do this before pickup, so it's a choice.
   - This replaces the fixed curse idea on L1 (a +1 meter section) from Phase A. L1 instead gets a seeded curse like every other Legendary.
   - The sim needs curse support so balance can be re-measured.
3. **Ending gauntlet.** Each Arc 6 step (6.1 door, 6.3 stairs, 6.4 chamber, 6.7 dig) starts one fight with 1–2 seeded curses (more curses deeper in). This uses `AxelRun.enter_world_encounter()` with a new reason (`ending_gauntlet`), from `greybox_choice.gd` through `AxelWorld` (AxelWorld decides, AxelRun starts). The curses are shown on a card before the fight. Losing = a normal loss.
4. **Deep or Legendary rooms** (optional): a fight in a depth-3 room has a 1-curse chance.
5. **Determinism:** curse picks use run seed + fight index. Combat-side random effects (item jam pick, blind) use the fight's `CombatRNG`.

### Files

New `combat/scripts/curse_def.gd`, `combat/data/curses/`, `combat/scripts/combat_root.gd` (apply curse hooks: weights, meter, goal, item enable mask, spin cap), `item_effect_dispatcher.gd` (family potency mask), `axel_run.gd` (pass curses), `axel_world.gd` (curse table, gauntlet starts), `scenes/core/greybox_choice.gd`, item card + STATS tab, `guide_pages.gd` (a new "Curses" page with a picture from existing art), the catalog plan (curse table section).

### Checks

A new `combat/test/curse_modifiers_check.gd`: each curse alone, the same seed twice gives the same result, and Blind still resolves correctly. Plus determinism, powers, scaffold, synergy smoke, `guide_panel_check`, the standard set, and the sim with curses.

### Open questions

Disable the cursed family fully, or weaken it? How many gauntlet fights (4 suggested)? Does the true ending need all of them won?

---

## Phase E — Replayability after the true ending

### Design

1. **Dread Levels.**
   - After the first true ending, New Game offers Dread Level 1. Each level adds one permanent curse (from the Phase D list) and/or Dread % to every run. Winning (true ending) on level N unlocks N+1. About 8 levels.
   - Store the unlock in `AxelProfile`, not in the save slot.
2. **Seed entry.** A text box on New Game for a seed (the digits, shown already on Load and pause). Optional daily seed = date-based.
3. **Seeded room states** (cheap variety from current art):
   - A door blocked by debris (a sprite overlay + collider + "Blocked." line).
   - A dark room that needs the flashlight (darkness overlay; walk fights there use the Blind curse).
   - A locked room needing the key.
   - Rolled per seed. The door graph must stay connected (a check script verifies this for many seeds).
4. **Stitching test** (the user's question; answer: technically possible, visual risk):
   1. Pick one room.
   2. With a script (Python PIL), cover one drawn door with a wall patch cloned from the same room, and paste a door elsewhere.
   3. Rebuild that variant's colliders and door boxes.
   4. Capture with `capture_scene.ps1`.
   5. The user judges whether it reads as hand-drawn. If yes, make more variants; if no, go to step 5.
5. **Door shuffle (the user's preferred fallback):**
   - The user draws **extra doors** into room art. Each door gets an `Area2D` like today.
   - Per seed (and especially on Dread Level 2+), a seeded door table decides for each door: *unavailable* (locked/blocked line) or *leads to room X*.
   - There could be more than 10 layouts.
   - Constraints:
     - The graph is always connected.
     - Key/flashlight gates stay reachable before they are needed.
     - The basement stays the end.
     - Every door pair uses the live destination box rules in SCENE_BUILDING (arrival on the destination door's live box).
   - **Map for every layout, built by Claude (user requirement).** Don't hand-draw one map per layout. Build the map **at runtime**:
     - Cut each room's shape out of `axel_map_v2.png` as its own piece (one-time asset prep with a script).
     - Arrange the pieces from the seed's door table.
     - Draw the connections as door lines in the same ink style.
     - Keep the existing overlay behavior (hover red fill, name, travel price from Phase C).
   - A test renders the map for 20+ seeds and checks that every reachable room appears.
6. **Ending variety:** the gauntlet curses differ per seed, and Dread Levels add more.

### Files

`AxelProfile` (levels), Main Menu New Game flow (`scenes/Main_Menu/`), a door table in `axel_world.gd` (or a new `school_layout.gd`), each room scene's door `Area2D`s (any edits to legacy Arc 1 scenes need user approval), `locker_map_overlay.gd` (runtime map), new map piece assets under `exports/Drawings/map_pieces/`, `SCENE_BUILDING.md` (door-table rules).

### Checks

A new `tools/qa/school_layout_check.gd` (connected graph and gates for 500 seeds), a map render capture for several seeds, `locker_map_travel_check`, scene smoke, `pause_map_restore_check`, and the standard set.

---

## Order and session tips

1. Finish Phase A's leftover list (numbers, catalog rows, RTP).
2. Phase B (Dread + growth + ticket machine), then re-sim.
3. Phase C (routing).
4. Phase D (curses, item curses, ending gauntlet).
5. Phase E (Dread Levels, seed entry, room states, stitching test, door shuffle + generated map).

For each phase:
- Write a short `plans/playtest/<date>_<phase>.md` from its section here.
- Ask the open questions first.
- Implement, then run the checks.
- Playtest in Godot before any export.

Combat-touching phases (A, B goal hooks, D) count as combat-related, so the combat plans may be opened.
