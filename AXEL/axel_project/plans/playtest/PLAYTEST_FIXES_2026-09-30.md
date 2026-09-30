# Playtest fixes 2026-09-30 (Windows build)

## 1. Options volume bars
Filled part is strong red (`MenuLook.ACCENT`), empty part is faint red. File: `scenes/Main_Menu/menu_look.gd`.

## 2. Combat entry sound
`assets/audio/sfx/combat_transition.wav` plays on the UiSfx bus when the world-encounter wipe closes (`AxelEventFx.play_combat_wipe`, cue `combat_transition` in `AxelSfx`).

## 3. Round Complete card
- Bets used and current balance numbers are red (RichTextLabel bbcode).
- Letter slam entrance: letters appear one by one with a small punch and red flash, the finished title slams, the scrim flashes red and the text shakes/flickers, then hop and flames start. Stats fade in and their numbers count up.
- Reduce flashing skips the red flashes, shake and flicker. Headless shows the final card at once.

## 4. Item pulse timing
Item icons pulse when their effect shows on the grid, not at spin start or after the line is gone:
- Spin-start passives, refund and glyph roll: when the new board has landed.
- Line payout bonuses and glyph payouts: when the winning line starts to flash.
- Power chains and echoes: when the power effect starts on the grid.
Presentation only. RNG and payouts are unchanged.

## 5. Combat white in the exported game
`AxelPostFxStack` turned the combat post-FX and the 8-band noir palette off in release builds (`OS.is_debug_build()`). Both are now on in every build.
