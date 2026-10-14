# Portrait layouts: menus + combat (plan, 2026-10-14)

## Why
On a phone held upright, the menus and the combat screen are the landscape layout shrunk into the middle of a tall screen. The user wants real portrait layouts: menus that fill the height, and a combat screen with its pieces rearranged for a tall screen. Landscape (PC) must look exactly as it does today.

## Rule
- **Portrait** = window width < window height. Every layout below only switches in portrait. At 1920×1280 nothing changes, so the existing checks keep passing as they are.
- **Safe bands** (portrait only): keep important things out of the top ~7% and bottom ~4% of the screen (iPhone Dynamic Island and home bar). On a real device, use `DisplayServer.get_display_safe_area()` when it returns a rect, and fall back to these bands otherwise.
- **Text** stays normal VT323. Letters get bigger, not stretched (user decision).

## Part 1: Menus (main, Saves, Options, Credits, Pause)
New shared helper `scenes/core/portrait_ui.gd`:
- `is_portrait(node)`
- `safe_rect(node)`, the screen minus the safe bands
- `font_px(node, base_px, portrait_boost)`, which uses `MenuLook.scaled_font` in landscape and a width-based size in portrait

What each screen does in portrait:
1. **Main menu** (`scenes/Main_Menu/MainMenu.gd`, `menu_look.gd` backdrop):
   - Backdrop: cover, with no 1.33 zoom-out, so the art fills the height.
   - Title: about 60% of the screen width, placed in the upper quarter.
   - Buttons: spread evenly down the remaining height (to ~85%), with a bigger font.
   - The overwrite prompt gets wider.
   - All of this re-runs on resize: the `size_changed` handler re-lays out the menu, not just the fonts.
2. **Saves** (`Saves.gd`): the column becomes 90% of the width, rows get taller with bigger fonts, and the seed hover stays on screen.
3. **Options** (`scenes/ui/options_panel.gd`): sliders get 60% of the width (today it's width/6), the fonts scale (they're hard-coded today), and the panel scrolls if it's too tall.
4. **Credits** (`Credits.gd`): the column becomes 90% of the width, the fonts are bigger, and it gets a resize handler.
5. **Pause** (`scenes/ui/pause_menu.gd`): stays centered (the pause contract requires that). It gets a bigger title, buttons and spacing in portrait, and the seed label moves above the home bar.

## Part 2: Combat, layout A ("spin at thumb")
How it works today: one 3508×2480 landscape picture (`HudCanvas`) is scaled to fit the screen. The pieces (`HudPieces/NEW_*`, plus `NEW_Execute` for the skull) sit at fixed spots on it. The real widgets (grid, buttons, labels) copy their position from their piece every frame (`hud_widget_layer.gd`), so moving a piece moves its widget too.

Portrait change, all in `combat/scripts/combat_test.gd` (`combat_test.tscn` is not edited):
1. `_fit_hud_canvas`, when portrait:
   - Switch the canvas to a tall 2480×4960 portrait plate, contain-fit and centered.
   - Hide the landscape background art (`HudArt`). The black background stays.
   - Apply a `PORTRAIT_LAYOUT` table: a position and a scale for each piece.
   - When the screen goes back to landscape, restore the authored positions and scales, which are saved once at startup.
2. The table, in plate units. It's a starting point that I'll tune with screenshots:
   - Top row (below the safe band): `NEW_Settings` X at the top-left; then `NEW_Goal`, `NEW_Multiplier` and `NEW_History` (shrunk) side by side.
   - Middle: `NEW_Grid` scaled up to about 90% of the width and centered. The win counter bar (`MOVE_PremiumBar` / `MOVE_SpinMoney`) moves and scales with the grid, so it stays under the grid.
   - Bottom row (above the home bar): `NEW_Items` on the left, `NEW_Bets` (balance and bet ±) in the middle, `NEW_Execute` (the skull spin button) on the right, sized for a thumb.
3. Things that ride along and need a check:
   - The spin bars follow the skull already.
   - `EncounterWinOverlay` gets resized to the portrait canvas.
   - The Free Spins choice layer, the item description layer and the tutorial glow (they use piece rects) get one look each, and a fix if they assume landscape.
4. Nothing about the rules changes. No RNG, economy or flow code is touched, so combat stays deterministic.

## Checks
- New `tools/qa/portrait_ui_check.gd`, running at 1179×2556:
  - Main menu: the title is at least 40% of the screen width, the buttons spread over at least 50% of the height, and everything is inside the safe rect.
  - Saves, Options, Credits and Pause: everything is inside the safe rect, and no text is clipped.
  - Combat: the portrait plate is active, the grid is at least 85% of the screen width, no two pieces overlap, every piece is inside the safe rect, and `%SpinButton` lies inside the skull.
  - Back at 1920×1280: every piece is exactly at its landscape spot.
- Run `combat_test_scaffold_check.gd` before and after. Also run all the standard checks, plus `hud_piece_placement_check`, `save_slots_check`, `menu_backdrop_glitch_check` and `narrow_zoom_check`.
- Visual: re-capture the menus, pause and combat at 1179×2556 and add them to the "AXEL Phone Shots" page for review.

## Order
Menus first, since they're small and low risk. Screenshot them and show the user. Then combat, then screenshots again. Nothing gets committed until the user says "commit and push".

## Status
Built 2026-10-14 (menus, then combat layout A). Documented in `AI_DOCS.md` (Style and FX, "Portrait (phone) layouts"). Not committed yet.
