# Plan: Pause-menu Guide + cross-save profile (compendium, Free Spins unlock, tutorials)

## Context
Playtest feedback (AI_DOCS § Design ideology): "a win the player cannot explain feels empty." Tutorial cards teach each mechanic once, in the moment, but there is nowhere to re-read them. The user wants a **Guide** in the pause menu, unlocked after the first fight, with a few pages on symbols, payouts, RTP, matching, Vice Round, Free Spins and items.

Decisions made with the user:
- Free Spins page shows `???` until the player has reached Free Spins once. Then it explains fully. This keeps the "mystery" canon.
- Items page holds a **Compendium** of all 75 items. Each item is greyed out (name and effect `???`) until it has been picked up. It does not need to be equipped.
- The Compendium, the Free Spins unlock and the Guide unlock are kept **across save files**, including after death.
- **Canon change (user-requested):** tutorial cards become once per *player profile*, not once per save. They are on by default. After a card is cleared, a new save does not show it again.
- The RTP is shown as a number in plain words.
- Extra pages: Goal / balance / losing, Bets & multiplier, and Skull meter & powers.

There is only one pause menu (`scenes/ui/pause_menu.gd`), shared by rooms and combat (the combat gear calls `AxelPause.request_pause()`). "All pause menus" means that one menu.

## 1. New autoload `AxelProfile` (cross-save memory)
- New file `scripts/autoload/axel_profile.gd`, registered in `project.godot` after `AxelSaves`.
- It owns `user://axel_profile.cfg` through a `ConfigFile`, using the same pattern as `AxelSettings`. It is separate from the save slots, so deleting a slot or dying never touches it.
- Fields: `guide_unlocked: bool`, `free_spins_seen: bool`, `items_found: PackedStringArray`, `tutorials_seen: PackedStringArray`.
- API: `is_guide_unlocked()`, `unlock_guide()`, `has_seen_free_spins()`, `mark_free_spins_seen()`, `has_found_item(id)`, `mark_item_found(id)`, `has_seen_tutorial(id)`, `mark_tutorial_seen(id)`, `reset_profile()` (debug only), and `merge_from_run(state: RunState)`.
- Each mark writes the file right away (it changes rarely). Headless runs use an env override `AXEL_PROFILE_PATH` so checks never touch the real profile.
- `merge_from_run` migrates old saves. On `AxelSaves.load_slot` / `continue_last`, it copies `owned_item_ids` into `items_found` and `tutorial_seen` into `tutorials_seen`, and calls `unlock_guide()` if `tutorial_fight_done` is set. Existing playtest saves then keep their progress.

## 2. Hook points (write only, no reads inside combat logic)
- **Guide unlock:** `scripts/autoload/axel_run.gd` `_on_root_finished` (l.380), on both win and loss. `abort_encounter_as_loss` (l.250) also unlocks. The Guide is therefore not shown during the very first fight.
- **Item found:** `scripts/autoload/axel_world.gd` `take_item` (l.464), at the same moment the id is appended to `owned_item_ids` (l.478).
- **Free Spins seen:** `combat/scripts/combat_test.gd:4073`, right before `combat.choose_free_spins_power(power_id)`. That is the HUD layer, not `CombatRoot`, so RNG and determinism stay untouched, and combat still reads no story flags.
- **Tutorials:** `scripts/autoload/axel_tutorial.gd` `_is_seen` (l.288) and `_mark_seen` (l.304) read and write `AxelProfile`. `RunState.tutorial_seen` keeps working for old-save compatibility and is still written.

## 3. Guide UI
- New `scenes/ui/guide_panel.gd` (`class_name GuidePanel`). It is built in code and copies the `OptionsPanel` pattern: ScrollContainer → CenterContainer → column, `MenuLook` styling, VT323, `signal closed`, and a `BackButton` plus the `back` action.
- Layout: a page title (`? Matching ?` style, the same as the tutorial cards), a body Label (`custom_maximum_size` set, because wrapping Labels need it in 4.7), and a bottom row with `< Prev`, `n / N`, `Next >` and `Back`. Left and right (`move_left` / `move_right`) also flip pages.
- Page text lives in `scenes/ui/guide_pages.gd` (consts only). The paytable numbers are read live from `combat/data/symbols/sym_*.tres` so they never go stale.
- Pause menu (`scenes/ui/pause_menu.gd`):
  - Add a `Guide` button after `Options` (node `GuideButton`). It is visible only when `AxelProfile.is_guide_unlocked()`, refreshed in `show_menu` / `_show_main`.
  - Add `_guide` handling in `is_submenu_open`, `close_submenu` and `_show_main`, mirroring `_options`.

### Pages (draft content, plain words, game numbers from canon)
1. **The Fight**: reach GOAL before you run out of chips. Each paid spin costs your bet. Your balance carries between fights, starts at 1000 and has no cap. You lose when you cannot pay for another spin, and losing deletes that save. Goals go 100, 150, 225, then ×1.5 each fight, and lore items raise them.
2. **Matching**: 3, 4 or 5 of the same symbol in a row or column wins (diagonals only with certain items). There are no cluster wins. Winning symbols vanish, the rest fall down, and no new symbols drop in. A line of exactly 3 leaves a Wild (the skull) in its middle, which stands in for any symbol.
3. **Payouts**: icon plus 3/4/5 values for every symbol, read live. The history box shows `bet × value × multiplier`. A cleared grid pays no extra.
4. **Bets & Multiplier**: the bet steps (100 / 200 / 300 / 400 / 500 / 1000), when to bet higher, and how each cascade raises the multiplier.
5. **Skull Meter & Powers**: only cigarette, alcohol and bloody hand lines fill the meter (3 = 1 section, 4 = 2, 5 = 3). Bloody hand turns one symbol type into another. Alcohol adds wilds. Cigarette burns away two low symbol types. Powers can also fire at random on a losing spin.
6. **Vice Round**: a full meter starts it. Each vice fires once in order (bloody hand, alcohol, cigarette), and no new symbols appear. Clearing every non-wild symbol leads somewhere…
7. **Free Spins**: `???` until seen. Afterwards it covers Choose Your Vice (Bloody Hand 4, Alcohol 5, Cigarette 8 spins), autoplay, a fresh grid each spin, power on a losing spin, and meter fills adding spins (+4 / +3 / +2, up to 100).
8. **Odds (RTP)**: "On average a spin pays back about **X%** of its bet. That means over many spins you slowly lose chips, so GOAL comes from big moments: long lines, cascades, the Vice Round." X comes from running `combat/test/rtp_audit.gd` during implementation, rounded to a whole percent.
9. **Items**: floor items auto-equip into a free slot. Equip and unequip on the item wheel (Tab / Q / R / I). Covers the slot cap, the rarity order Common → Uncommon → Rare → Epic → Legendary with glyphs `◇◈◆★✦`, how the first pickup in an area raises every other area's rarity, and how icons pulse when they proc.
10. **Compendium**: a grid of all 75 item icons (from `AxelRun._ensure_catalog` / `load_item`), grouped by rarity. Found items are in full color. Unfound items are a dark grey silhouette with name and effect `???`. Hover or focus shows the name and description below the grid. A counter reads `Found n / 75`.

My extra recommendation, already folded in: the Odds page frames *why* the player usually loses chips on ordinary spins. That is the thing new slot players misread most.

## 4. Debug
- In `scripts/debug/axel_combat_dev_tools.gd`, add a **Reset Profile** button (debug builds only) that calls `AxelProfile.reset_profile()`. Without it, editor playtests would never see the tutorials again.

## 5. Docs
- `plans/core/AI_DOCS.md`:
  - Saves / menu / pause UI: add the Guide button and pages, and the new `AxelProfile` autoload and file.
  - Tutorial cards: change "once per save (`RunState.tutorial_seen`)" to "once per profile (`AxelProfile`)".
  - Note that the Free Spins page stays `???` until reached.
- Copy this plan to `plans/playtest/2026-10-06_pause_guide_plan.md`.

## 6. Verification
Run `tools\cmd\godot.cmd --headless --path AXEL/axel_project --import` once, then each CLAUDE.md check:
- `determinism_check`, `powers_check`, `combat_test_scaffold_check`, `scene_smoke_check`
- `audio_bus_layout_check`, `settings_persistence_check`, `pause_contract_check`, `menu_nav_check`
- `tutorial_popup_check` (updated for profile-based seen), `run_state_check`, `save_slots_check`, `item_wheel_check`

New check `tools/qa/guide_panel_check.gd` (root size 1920×1280, temp profile path). It verifies:
- `GuideButton` is hidden before unlock and visible after.
- The Guide opens with focus on a live control.
- Next and Prev flip pages, and Back / `back` returns to the pause column.
- The Free Spins page is `???` until `mark_free_spins_seen`.
- The Compendium shows 75 entries, greyed except found ones.
- The profile survives `AxelSaves.delete_slot` and a new game.
- A tutorial seen in one save does not reappear in a new save.

Manual check:
- On a new profile, pause during the first fight: no Guide.
- After that fight: the Guide appears.
- Pick up an item: it lights up in the Compendium.
- Die, then start a new game: the Compendium is kept and no tutorial cards show.
