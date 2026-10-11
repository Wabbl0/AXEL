# Round Complete: arcade jackpot overhaul (2026-10-11)

## Problem
- The win card was one 64px title. It typed in, hopped 24px forever and puffed 24 flames.
- After the loss screen rebuild (`b633514`), the win looked flat by comparison. Nothing had been overwritten; it was just the older, smaller design.

## What it does now
1. **Board** (`combat_root._play_goal_win_burst`):
   - Symbols are eaten into skulls, as before.
   - Light ripples outward and then inward through the grid rings (`play_count_flash` with a delay per ring).
   - A flame pop comes from the grid center (`combat_feel.play_win_flames`).
   - The board gives a small shake.
2. **Card slam** (`AxelEventFx`):
   - The screen flashes deep red.
   - The title drops from 3.2× to 0.92× in 0.14s, then squashes and settles.
   - On impact: a white and red shockwave, three flame waves (16/32/16), a 14px stage shake and the `power` sfx.
3. **Jackpot show** (`scenes/fx/round_jackpot_fx.gd`):
   - 16 turning red rays and a center glow.
   - Two marquee bars shoot in from opposite edges, with white chase lights.
   - 4 firework volleys, then one every 0.9s while waiting.
   - 26 falling skulls (`satanic_wild.png`, recolored white/red because the overlay sits above the noir filter).
4. **Title**:
   - The title is 104px with a black outline and a dark red shadow.
   - The `[jackpot]` RichTextEffect (`scenes/fx/jackpot_text_effect.gd`) makes each letter bob 6px out of phase with the others, and the red/white colors chase along the word.
5. **Stats**:
   - The stats slide up and count up.
   - The balance number lands with a punch: scale 1.3, a red flash, a spark burst and the `round_winnings` sfx.
6. **Skip**:
   - `AxelRun._await_round_intro`: the first press calls `skip_round_intro()`, which snaps to the end state. Fireworks keep going.
   - The next press continues, as before.
7. **Exit**:
   - The fade to black also fades the FX and stops spawning.
   - Hiding the card frees the FX nodes.

## Modes
- **Reduce flashing**:
  - No red flash, shake, chase or ray spin.
  - Rays are dimmer.
  - 2 volleys, 10 skulls and no idle fireworks.
- **Headless**: snaps to the end state with no particles.

## Checks
- All CLAUDE.md checks pass, plus `round_complete_overlay_check.gd`, which now also covers the FX node, the title size, skip and cleanup, and `combat_pace_check.gd`.
- Windowed 1920×1280 captures at 0.08s, 0.2s, 0.5s, 1.0s, 2.2s and 3.4s look correct.

## Known
- `flame_burst.gd` flames show their raw yellow/orange on layers above the noir filter. This was already true for the old card and the loss flames.
- There is no dedicated jackpot sound yet. The card reuses `power` and `round_winnings`.
