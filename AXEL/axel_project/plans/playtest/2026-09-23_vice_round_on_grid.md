# Plan: VICE ROUND in the middle of the grid

Plan only. Do not implement in the planning chat.

## What you asked

The “VICE ROUND” text should appear in the middle of the grid.

## What the game does now

- The only live string is in `combat/scripts/combat_root.gd` `_play_meter_full_transition_async`: `_feel.play_banner("VICE ROUND", 1.8, 0.82)`.
- `combat/scripts/combat_feel.gd` draws that on `FeelBanner`, a full-screen label, VT323 size 96, dark red, with `offset_bottom = -180`. That shoves the words above the middle of the screen. The label is not attached to `GridUI`.
- The same banner is used for “FREE SPINS”. That call must stay where it is.
- The fast sync path (`_play_meter_full_transition_sync`) does not show the words. Leave that path alone.

## Locked choice

Only the VICE ROUND banner moves. It is centered on `GridUI` (the 5×5 symbol grid), not on the screen and not on the tall execute skull. Timing, color, font size, and the full-screen dim stay as they are.

## Steps

1. Add an optional anchor argument to `play_banner` (a `Control`). When it is null, keep today’s full-screen label and the `-180` offset.
2. When the anchor is set, copy that control’s global rectangle onto the banner label (position and size in the Feel layer), set `offset_bottom` to `0`, and keep center alignment so the words sit on the grid’s center.
3. Pass `grid_ui` from the VICE ROUND call only. Do not pass it for FREE SPINS or for the loss line.
4. Re-apply that rect if the window size changes while the banner is up (the grid already moves in `fit_to_viewport`).
5. No new art and no combat-randomizer change.

## What you should see

When Vice Round starts, “VICE ROUND” is centered on the symbol grid, then fades out as it does today. “FREE SPINS” does not jump to the grid.

## How to test

1. Fill the execute meter and enter Vice Round.
2. The words sit in the middle of the 5×5 grid, not high on the screen.
3. Reach Free Spins once. Those words stay in their old place.
4. Run the combat scaffold check: `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://combat/test/combat_test_scaffold_check.gd`. Expect exit 0.

## Risks

- A full-screen label with a grid-sized rect can clip a long string. “VICE ROUND” at size 96 fits a grid that is about 400px wide at 1920×1280. If a smaller window clips it, drop the font size for this banner only until the string fits the grid width. Do not shrink FREE SPINS.

## When this ships

One changelog line. The Vice Round order (bloody hand, then alcohol, then cigarette) does not change.
