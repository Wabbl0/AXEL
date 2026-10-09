# 2026-10-09 Combat skull feel

## Problem
The skull is the spin button, but it didn't look clickable. Its hover glow, hover grow and press squish never ran, because `combat_test.gd` makes it ignore the mouse so `NEW_Execute` can own the click. The skull also looked the same whether a spin was possible or not.

## Fix (punchy arcade intensity)
- `hud_piece.gd`: new `hover_changed(on)` and `press_changed(on)` signals.
- `combat_test.gd`:
  - forwards those signals to the skull;
  - sets `NEW_Execute` hover/press scale to 1.0;
  - `_sync_skull_ready()` runs every frame;
  - `play_fire()` runs when a spin really starts;
  - `_note_skull_input()` resets the idle timer.
- `premium_skull_meter.gd`: the new feel layer runs on the stage art and `Glow`. The `PremiumSkull` node keeps its fill scale, so the layout and Free Spins blocks don't move.
  - Ready: it breathes and its rim pulses like a heartbeat.
  - Busy: it fades to 0.5 alpha.
  - Hover:
    - grows to 1.1 and tilts toward the cursor;
    - jitters once and lights the rim;
    - shows the `[E] SPIN` chip.
  - Press: squash. Fire: punch, dark flash and embers.
  - Meter section up: a gulp (punch, rim flare, 24/40/70 embers) and a double shake. Full: a steady ember stream.
  - Idle 6s: a nudge, plus the chip for 1.6s.
- Under the inverted noir filter, dark reads bright red. So the rim, the flash and the embers use dark colours.

## Not done
- Hand cursor: `AxelCursor` is a single custom sprite with no hand variant.
- Global screen shake on press: left out so it doesn't stack with the spin's own shakes.

## Check
`tools/qa/skull_feel_check.gd`
