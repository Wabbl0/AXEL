# Playtest batch D (2026-10-12): 10 fixes

## Context
These fixes come from the playtest after release 0.1.5. They cover the combat tutorial, three combat visuals, and the overworld (map key, room border). Before editing, copy this plan into the repo as `plans/playtest/2026-10-12_playtest_batch_d.md`.

## A. Tutorial (`scripts/autoload/axel_tutorial.gd`, `combat/scripts/combat_test.gd`)

### 1. First fight highlights only the skull
In `GLOW_PIECES`, change `fight_spin` to `["NEW_Execute"]`.

### 2. Q/R bet keys blocked during the bets card
- **Cause:** `_wants_freeze()` (axel_tutorial.gd:270) also counts *queued* freeze lessons. The bets card opens after the first match, while a `slot_*` freeze card waits behind it. That turns freeze on, and then `_bet_hotkey_allowed()` (combat_test.gd:1730) refuses Q/R.
- **Fix:** in `_bet_hotkey_allowed()`, allow bet changes while the open card is `fight_stakes` (use `tutorial.is_showing("fight_stakes")`). Keep every other check as it is.
- **Also:** check that the +/- buttons are not disabled in the same state. If they are, apply the same exception.

### 3. One highlight per card, with History and Goal on their own cards
- `fight_stakes` → `["NEW_Bets"]`. Rewrite its body to cover only BALANCE and BET.
- New lesson `fight_goal` (not a freeze card) → `["NEW_Goal"]`. Body: fill GOAL to win.
  - Queue it right after `fight_stakes` in `_after_match_lessons` (combat_test.gd ~2983).
- `slot_match` → `["NEW_Grid"]`.
- New lesson `slot_history` (freeze card) → `["NEW_History"]`. Body: wins are listed in HISTORY.
  - Request it right after `slot_match` wherever `slot_match` is requested.
- `slot_vice` → `["NEW_Execute"]` (your choice: skull only).
- Update the expectations in `tools/qa/tutorial_popup_check.gd` (lines ~130-135) and add the two new ids.

### 4. Time freeze: grey filter and a running glitch, no red
- Make the grey stronger in `combat/shaders/tutorial_freeze.gdshader`.
  - Use a neutral grey: luminance × ~0.6 plus a slight lift, so the red symbols read as grey.
  - Keep the scanline.
- Keep the time glitch running for the whole freeze. Today `burst` tweens to 0 after 0.5 s.
  - Keep a low steady `jitter`/`burst` (e.g. 0.35), with occasional bigger ticks.
  - Keep both at 0 when `reduce_flashing` is on.
- The red during a freeze most likely comes from the red highlight glow (CanvasLayer 93). It draws above the freeze layer (layer 40) and pulses red on the grid.
  - While a freeze card is open, don't put the red glow on `NEW_Grid`. Let the grey and glitch overlay mark it.
  - With fix 3 in place, no freeze card highlights the grid anyway.
- Confirm with `tools/qa/tutorial_glow_capture.gd --lesson=slot_match`.

## B. Combat visuals

### 5. Skull hover white outline doesn't cover the red rim
- `premium_skull_meter.gd` has a red `_glow` layer. `piece_highlight_glow.gd:_collect_child_arts` skips it, so the white ring sits inside the red bloom.
- The outline shader (mode 2) also skips soft rim pixels (alpha 0.3-0.7) and gets no padding, so the ring is clipped at the edge of the texture.
- **Fix:**
  - (a) Fade the skull's `_glow` out while `_outline_alpha` goes up (`_tick_hover_outline`).
  - (b) In the `mode == 2` branch, draw white over semi-transparent rim pixels too: change `own` smoothstep to 0.85-1.0.
  - (c) Give outline overlays the same `pad_uv` padding the bloom uses, so the ring is never clipped.
- Verify with a capture of the hovered skull.

### 6. Round Complete skulls behind the banner text
In `axel_event_fx.gd:_spawn_jackpot` (~771), after adding `_jackpot_front`, move it to just before `_round_label`: `_round_stage.move_child(_jackpot_front, _round_label.get_index())`. The skulls, sparks and flames then all draw behind the title, bets and balance labels.

### 7. Matched-cell glyph marks: sit in the cell corner, a few px from the edges
- In `symbol_slot.gd:set_glyph_mark` (73-96), the Label uses a 60 px font with offsets 6/-2. The real ink of the glyph lands far from the corner, close to the symbol.
- **Fix:**
  - Size the font to the cell (about 22% of the cell size).
  - Measure the glyph with `font.get_string_size` and `get_ascent`.
  - Place it so its drawn box sits 4 px from the cell's left and bottom edges.
  - Re-place it on resize.
- Check with `tools/qa/glyph_mark_capture.gd`.

## C. Overworld

### 8. M opens the map
- Add an InputMap action `open_map` bound to M in `project.godot`.
- Move `_open_map()` from `scenes/ui/pause_menu.gd` into `AxelPause` as `open_map()`. The pause menu button then calls it.
- In `AxelPause._unhandled_input`, on `open_map`, open the map only when:
  - the game is not paused,
  - `_can_pause_here()` is true,
  - `AxelSaves.has_map()` is true,
  - the player is not mid-encounter.
- In `1.3_SchoolMap.gd:_is_exit_key`, also accept `open_map`, so M closes the map too.

### 9. Direction arrow stays inside the red border
- Add static `AxelRoomEdge.inner_screen_rect(scene) -> Rect2`. It returns the border rect in screen pixels, inset by the line width.
- In `_sync_direction_hint` (1.2_Corridor.gd ~457, 1.4_BasementDoor.gd ~231), clamp the arrow's x to `min(viewport right, border right) - half_w - 8`.
- Cafeteria (2.1, ~400) places it in the world. Clamp it the same way.

### 10. Player hidden behind the border, with a 2 px feather
- In `axel_room_edge.gd`, move `EdgeLine` above the Player and keep it below `DirectionHint` (`move_child` to just after Player).
- `EdgeLine._draw` then draws, in order:
  1. Opaque black over everything outside the rect, covering the visible canvas area.
  2. A 2 px black→transparent gradient just inside the line (`draw_polygon` with vertex colors).
  3. The red line on top.
- The player then disappears behind the border and fades over 2 px. Sizes are in screen px (divided by zoom, as now).

## Verification
Run from the repo root with `tools\cmd\godot.cmd --headless --path AXEL/axel_project`. Run `--import` first.
- Combat:
  - `combat/test/combat_test_scaffold_check.gd` (before and after)
  - `determinism_check.gd`
  - `powers_check.gd`
  - `tools/qa/combat_pace_check.gd`
  - `tools/qa/tutorial_popup_check.gd`
- General:
  - `tools/scene_smoke_check.gd`
  - `pause_contract_check.gd`
  - `menu_nav_check.gd`
  - `settings_persistence_check.gd`
  - `audio_bus_layout_check.gd`
- Captures:
  - `tutorial_glow_capture.gd` for `fight_spin`, `fight_stakes`, `fight_goal`, `slot_match`, `slot_history`
  - `glyph_mark_capture.gd`
- Manual playtest in Godot: Q/R on the bets card, M in the Corridor, the edge arrow, walking into the border, hovering the skull, Round Complete.
- Afterwards: update `AI_DOCS.md` (tutorial lesson list, M = map, border masks player).
