# First-fight tutorial polish (7 playtest fixes)

## Context
Playtest of the locker tutorial fight. Six problems:
1. The first card (`fight_spin`) pops up the moment the grid is idle. You want the grid to settle, a few seconds of calm, then the card.
2. The grey freeze effect covers the whole `NEW_Grid` plate art (frame included), so it slips past the symbol grid edges toward the winnings bar.
3. Every card opens in the same spot, so `slot_match` sits on the history box, which is exactly what it tells you to read.
4. Highlights vanish instead of fading. The glow already fades over 0.6 s (wall clock, `axel_tutorial.gd:742-749`), but the grey freeze overlay snaps off in 0.15 s (`combat_test.gd:2824`). That is the "just disappears".
5. `slot_match` is requested on `line_win_resolved` (`combat_test.gd:2073`). The freeze then stops the `+13` popup mid-flight and the bar counter (both run on `CombatPace`), so points have not reached the winnings bar yet.
6. On GOAL, `_play_goal_win_burst` (`combat_root.gd:1398`) fires its own 8/16/32 flame waves over the grid before the Round Complete card, which has its own flames (`axel_event_fx.gd:670`).

This is combat UI only. Combat RNG and payouts do not change. Builds on the uncommitted one-card-at-a-time work already in the tree (`plans/playtest/2026-10-06_tutorial_sequence_plan.md`).

## Changes

### 1. Delay the first card: `combat/scripts/combat_test.gd` `_maybe_queue_fight_tutorials` (l.2836)
- Add `const FIRST_TUTORIAL_DELAY_SEC := 2.5` and `var _first_tutorial_idle_sec := 0.0`.
- Change `_maybe_queue_fight_tutorials()` to take `delta`, called from `_process(delta)`. While all the existing conditions hold (idle, 0 spins, no choice), add `delta`. Reset to 0 whenever they fail. Request the cards only once the timer passes 2.5 s.
- `_process` does not run while paused, so pause time does not count.

### 2. Freeze only the symbol grid: `combat_test.gd` `_layout_freeze_overlay` (l.2787)
- Size the rect from `combat.grid_ui` (the 5×5 `GridContainer`), not the `_piece_grid` plate.
- Use `grid_ui.get_global_transform_with_canvas()` for position and scale (the overlay lives on its own CanvasLayer 40), so it lines up even if the HUD canvas is scaled.
- Fall back to `_piece_grid` only if `grid_ui` is missing.

### 3. Later cards open below the first: `scripts/autoload/axel_tutorial.gd` `_layout_cards` (l.582)
- Remember the bottom edge of the first card laid out in this scene (`_first_card_bottom`; reset in `_on_scene_changed`, l.553).
- Every later card in that scene opens at `_first_card_bottom + STACK_GAP_PX*scale`. That is where the old stacked second slot sat.
- If that card would still overlap the `NEW_History` rect from `_hud_rects`, move it below the history box.
- Clamp so its bottom stays inside `vp.y - margin`.
- Result: `fight_spin` stays where it is now; `slot_match` and the rest sit lower and the history box stays readable.

### 4. Smooth fade-out of the freeze grey: `combat_test.gd` `_hide_freeze_overlay` (l.2817)
- Fade `amount` 1 → 0 over 0.6 s with ease-out (`set_trans(TRANS_SINE).set_ease(EASE_OUT)`), matching the 0.6 s glow fade.
- Fade-in stays at 0.18 s. The glow fade (`axel_tutorial.gd`) is already 0.6 s; I'll confirm it in Godot and only touch it if it still pops.

### 5. Points land in the bar before a freeze: `combat_test.gd`
- New `var _held_freeze_lessons: Array[String]` and `var _held_freeze_sec := 0.0`.
- `_tutorial_request(id)`: if `id` is a freeze lesson (`slot_match`, `slot_power`, `slot_vice`), add it to the held list instead of requesting it now.
- In `_process`: release the held lessons (in order) once the bar has caught up: `_displayed_round_winnings == _target_round_winnings == int(_safe_get_round_winnings())`, the same check as l.1857, and no counter running.
- Add a 0.2 s beat after that, and a 2 s safety timeout so a lesson is never lost.
- Clear the held list on scene exit.
- The grid may move a little (a cascade step) during that short wait. That is the trade-off for "points first".

### 6. Remove the grid flames on GOAL: `combat/scripts/combat_root.gd` `_play_goal_win_burst` (l.1398)
- Delete the `GoalFlameLayer` / `GoalFlameBurst` part (l.1428-1451): the 8, 16, 32 waves.
- Keep the alcohol eat into white skulls and the count flash, then the 0.4 s and 0.25 s beats.
- The Round Complete card keeps its own flames unchanged.
- Keep `FLAME_BURST_SCRIPT` only if it is still used in that file; otherwise remove the const.

### 7. Guide card: closes when the Guide opens, and "Guide" is a link
Problem: the `guide_pause` card (`axel_tutorial.gd:67`) only closes on its X. Opening the Guide from pause does not tell the tutorial anything.
- `scenes/ui/pause_menu.gd` `_open_guide()` (l.152): after `_guide.open()`, call `AxelTutorial.complete("guide_pause")`. So any route into the Guide closes the card, or marks it seen if it was only queued.
- Add a public `open_guide()` in `pause_menu.gd` that calls `_open_guide()`.
- `scripts/autoload/axel_pause.gd`: add `open_guide() -> bool`. If not paused, it calls `request_pause()` and returns false if that is refused. Then it calls `_menu.open_guide()`. `AxelPause` stays the only writer of `paused`.
- `axel_tutorial.gd`, card body becomes a `RichTextLabel`:
  - Settings: `bbcode_enabled`, `fit_content`, word-smart autowrap, VT323, white text, black outline. In `_apply_chrome`, use the RTL theme keys `normal_font_size` / `outline_size` / `default_color`.
  - Typewriter: set the full BBCode once when the card opens, then drive `visible_characters = slot.typed` instead of `substr`. `body_text` stays plain text, so typing speed, length and `_measured_height` do not change.
  - The lesson entry gets `"link": {"word": "Guide", "target": "guide"}`. When building the BBCode, that word becomes `[url=guide][u]Guide[/u][/url]`, tinted a lighter red so it reads as a link.
  - On `meta_clicked("guide")`: `complete("guide_pause")`, then `AxelPause.open_guide()`.
  - Body `mouse_filter` becomes `STOP`, so the click reaches the link. A click while still typing keeps today's behavior: the first click reveals the rest of the text.
- Test: in `tools/qa/tutorial_popup_check.gd`, add a case:
  - show `guide_pause`; the body contains the `[url=guide]` link;
  - calling the meta handler closes the card;
  - after that, `AxelPause` is paused with the Guide panel visible (only if the profile has the Guide unlocked; set that in the check);
  - separately, `pause_menu._open_guide()` closes an open `guide_pause` card.

### 8. Docs
- `plans/core/AI_DOCS.md`:
  - Combat § Round Complete text: drop the "bursts into doubling waves of the empty-item corner flames (8, 16, 32) … grid flames finish and are removed" sentences. It becomes "leftover icons are eaten into white skulls and glow, then the Round Complete card shows; its own flames are the only flames".
  - Tutorial cards §: 2.5 s calm before the first fight card; later cards open below the first and never over the history box; freeze lessons wait until the winnings bar has counted up; freeze grey covers only the 5×5 symbol grid and fades out over 0.6 s; the `guide_pause` card's "Guide" word is an underlined link that pauses and opens the Guide, and opening the Guide any way closes that card.
- `plans/playtest/2026-10-06_tutorial_polish_plan.md`: a copy of this plan.

## Verification
1. Run `combat/test/combat_test_scaffold_check.gd` before the combat edits.
2. After the edits, run `--import`, then the standard list: `determinism_check`, `powers_check`, `combat_test_scaffold_check` (all in `combat/test/`), `tools/scene_smoke_check.gd`, `audio_bus_layout_check`, `settings_persistence_check`, `pause_contract_check` and `menu_nav_check` (all in `tools/qa/`).
3. Also run `tools/qa/tutorial_popup_check.gd`, `combat/test/tutorial_script_seeds_check.gd`, `tools/qa/round_complete_overlay_check.gd`, `tools/qa/combat_pace_check.gd` and `tools/qa/play_scene_profile_check.gd`. Update `tutorial_popup_check` if it asserts card y positions.
4. Manual: F6 on `1.2`, walk past the locker.
   - The grid settles and about 2.5 s later `fight_spin` opens.
   - Spin 1: `+13` reaches the bar and counts up, then freeze. The grey covers only the 5×5 cells, and `slot_match` sits below where the first card was, with the history box readable.
   - Close the card: the grey fades out smoothly.
   - Win the fight: skulls glow, no grid flames, then Round Complete with its flames.
   - Guide card: click the underlined "Guide" and the game pauses with the Guide open, and the card is gone. Second try (Reset Profile): open the Guide via Esc → Guide, and the card closes.
