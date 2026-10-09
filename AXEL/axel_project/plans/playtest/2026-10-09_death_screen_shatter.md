# Plan: Death screen shatter

Shipped 2026-10-09. Replaces [2026-09-23_combat_loss_collapse.md](2026-09-23_combat_loss_collapse.md).

## What you asked

- Make the death screen more dynamic.
- Pieces **break**, then fall, in a satisfying and clear order.
- Center the text.

## What the game does now

- `CombatFeel.show_game_over_menu` (`combat/scripts/combat_feel.gd:185`) runs the whole death screen. `AxelRun._open_permadeath_menu` (`scripts/autoload/axel_run.gd:480`) calls it after the save is deleted.
- `_play_loss_collapse` (`combat_feel.gd:229`) moves every piece onto a new `LossFallLayer` (layer 114), then drops them all at once. Each piece starts 0.04s after the previous one, so the whole drop is a blur that lasts under half a second. The pieces never break.
- Problems found while reading the code:
  1. **The fall is hidden.** The 85% black scrim (layer 115) goes up *before* the fall starts, and it sits above the falling pieces (layer 114). You see the pieces at about 15% brightness.
  2. **The pieces likely jump in size.** HUD pieces live under `HudCanvas`, which is scaled to about 0.55 (`combat_test.gd:3449 _fit_hud_canvas`). The new layer has no scale, so each piece probably pops to almost twice its size when the fall starts. I think this is happening but have not confirmed it on screen.
  3. **The pieces change color mid-fall.** Layer 114 is above the noir palette (90), the scanline (105) and the CRT (108). The falling art skips those filters, so it looks different from the HUD a moment earlier.
  4. **Drop shadows stay behind.** `hud_drop_shadow.gd` follows its art every frame but never checks if the art is hidden, so a hidden piece can leave its shadow on screen.
  5. **The text sits off-center.** The banner uses `offset_bottom = -180`, so "GONE" is about 90px above the middle of the screen. The buttons are below the middle.

## The new sequence (about 2.4s, rushable)

Think of a pane of glass taking a hit. First you see it crack, then it breaks, then the pieces fall. Each beat has one clear focus.

| Time | Beat | What you see |
|---|---|---|
| 0.00 | **Hit** | A short red glitch flash and a medium screen shake (existing `glitch_flash` and `shake`). The scrim stays clear. |
| 0.10–0.55 | **Reels drain** | The 25 symbols drop whole, one column at a time from left to right, 0.07s apart. Inside a column the bottom row goes first. This works like a reel stop played backwards. |
| 0.65 | **Grid breaks** | The big grid frame `NEW_Grid` cracks: dark-red crack lines spread from its center over 0.18s and it shakes ±4px. Then it shatters into about 16 shards, with a small flame pop and a bigger shake. This is the biggest moment. |
| 1.05 / 1.27 / 1.49 | **Panels break in mirrored pairs, top to bottom** | Pair 1: `NEW_Goal` + `NEW_Multiplier`. Pair 2: `NEW_Items` + `NEW_History`. Pair 3: `NEW_Bets` + `NEW_Execute` (skull). Each piece cracks for 0.12s, then shatters into about 10 shards. Left and right break together, so the pairs read as a symmetric wave going down. |
| 1.75 | **Last bit** | The settings cog (`NEW_Settings`) and the empty-item disc fall whole, with no shards. |
| 1.6–2.2 | **Darkness** | The scrim fades from 0 to 0.85 while the last shards are still falling, so the pieces stay visible the whole time. |
| ~2.3 | **Line** | **GONE** or **IT TAKES YOU** fades in at the exact center of the screen (0.5s). |
| +3s, or a click / interact | **Buttons** | The line glides up and the buttons fade in below it, so the line and the buttons together sit centered on the screen. |

Shard motion: each shard flies out a little from the crack point, gets a small upward kick, then gravity pulls it down. It spins slowly and is removed once it is below the screen. Pressing interact during the collapse still rushes it, because everything runs on `CombatPace.multiplier()`.

## How it works

### 1. New helper `combat/scripts/loss_shatter.gd` (a plain Node, modeled on `flame_burst.gd`)

- `crack(art, impact, seed)`: draws a few `Line2D` cracks in dark red over the art, then shakes it.
- `shatter(art, impact, seed)`: splits the art's rectangle into shards that radiate from the impact point, like broken glass. There are two rings: inner triangles and outer four-sided pieces.
  - Each shard is a `Polygon2D` that uses the art's own texture with matching UVs. Filtering is nearest and there is no antialiasing, so the pixel art stays crisp.
  - It then hides the piece.
  - For pieces whose art is not a `TextureRect` with a stretch-to-fit texture (it may be painted in code), it falls back to `drop_whole`.
- `drop_whole(node)`: the piece falls without breaking. It is used for the symbols, the cog and the disc.
- `_process`: one loop moves every shard, the same way `flame_burst.gd` moves its flames. It multiplies delta by `CombatPace.multiplier()` and frees each shard once it is below the screen.
- The shard pattern uses its own RNG, seeded from the piece's name. Every death breaks the same way, so it is easy to tune and test. It never touches the spin RNG, so combat stays deterministic.

### 2. Shards stay in the same space as their piece

- HUD pieces: each shard goes into a `LossShards` Control added under `HudPieces`, next to the pieces. That keeps the same scale, the noir palette, the scanlines and the CRT, so nothing jumps in size or changes color.
- Grid symbols: they move into a plain `LossSymbols` Control under `CombatRoot`, next to `GridUI`, with their screen position kept. Leaving the `GridContainer` stops it from snapping the symbols back into place, and this fixes the size jump.
- `LossFallLayer` (114) is removed. Only the flame pops keep a small layer of their own on 114, as they do today.

### 3. `combat_feel.gd` changes

- `show_game_over_menu`: the scrim starts at 0, not 0.85, and fades in near the end of the collapse.
- `_play_loss_collapse`: becomes a timed list of beats (the table above), built by a new `_loss_beats()` that finds pieces by the same names `_loss_pieces()` uses today. If a piece is missing, its beat is skipped.
- Banner: a new loss placement centers the banner on the screen (full rect, no −180 offset).
- `_reveal_loss_buttons`: measures the button column's height, then tweens the banner up and the column in (alpha 0 to 1, 0.25s) so the two together are centered on the screen. The existing rule that the reveal click must not also press Retry stays.

### 4. `hud_drop_shadow.gd` change

`_sync()` also hides the shadow when the art is not visible in the tree, so broken pieces leave no shadow behind.

### 5. Settings

- **Reduce flashing:** no glitch flash, no flames and no shake. The cracks, shards and fall still play, because they are motion, not flashing.
- **Screen shake:** scales the shakes, as it does now.

## Files

- New: `combat/scripts/loss_shatter.gd`
- Edit: `combat/scripts/combat_feel.gd`, `combat/scripts/hud_drop_shadow.gd`
- Edit test: `tools/qa/loss_menu_check.gd`
- New test: `tools/qa/loss_shatter_check.gd`
- Do not touch: `combat_test.tscn` (the protected scaffold), `axel_run.gd` (the save is still deleted first, and the callbacks stay the same).

## Checks

1. `tools/qa/loss_menu_check.gd`, extended:
   - The banner's center is the viewport center (±2px) once the line is shown.
   - After the reveal, the banner and the buttons together are centered (±4px).
   - The captions and the rule that Retry is not pressed by the reveal stay the same.
2. New `tools/qa/loss_shatter_check.gd`:
   - Shatter a 200×120 test `TextureRect`.
   - Expect 8–20 shards whose areas add up to the rectangle (±1%).
   - Expect the art to be hidden.
   - The same seed must give the same shards.
   - After 3 simulated seconds no shards are left.
   - Run `_loss_beats()` on a fake scene with the named pieces and check the order: symbols, Grid, Goal+Multiplier, Items+History, Bets+Execute, Settings/disc.
3. Usual checks: `combat_test_scaffold_check.gd`, `determinism_check.gd`, `powers_check.gd`, `scene_smoke_check.gd`, `pause_contract_check.gd`, `menu_nav_check.gd`.
4. By hand, in Godot:
   - Lose a fight (Dev Tools → set balance low).
   - Watch the beats run in order, with nothing changing size or color.
   - Check the line is centered and the buttons appear centered under it.
   - Try again with reduce flashing on, and with interact held to rush.

## Choices I made (tell me to change any)

- **Order:** pairs from top to bottom, after the grid. The other option is a ripple outward from the grid by distance. Top to bottom reads more clearly with gravity.
- **Panel numbers die with the panel.** The shards come only from the panel art, so the balance and goal text disappear at the moment the panel breaks. It looks like the panel's memory is wiped.
- **Symbols fall whole.** Breaking 25 small symbols would turn into noise.
- **Length about 2.4s** (now about 1.3s). Interact still rushes it.

## When this ships

Update the loss sentence in `AI_DOCS.md`: the grid cracks and shatters, the panels break in mirrored pairs from top to bottom, the line is centered, and the line and buttons are centered together.

## Found while building

- Panel text (GOAL, BALANCE, 1X…) lives on `WidgetLayer` (106), not inside the panels. `hud_widget_layer.gd` now has `release_for(piece)`, so a broken panel's text stops following it and falls with its shards. The host that holds `CombatRoot` is never dropped.
- `GridHost` clips its contents, so falling symbols were cut off at the grid's bottom edge. The symbols now move to an unclipped `LossSymbols` holder at the top of their canvas.
- `MOVE_SpinMoney` (the winnings bar text) falls with `NEW_Grid`, and `MOVE_PremiumBar` falls with `NEW_Execute` (`LOSS_COMPANIONS`).
