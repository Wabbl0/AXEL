# Plan: Round win skulls, fireworks, and jumping text

Plan only. Do not implement in the planning chat.

## What you asked

When you win a round:

- Every grid icon flips to the skull, then glows.
- The skulls explode into the same fireworks as the empty item box when the disc hits a corner, but exponential.
- The same fireworks also go off behind the “Round Complete!” text.
- That text jumps up and down.
- Every second character switches between red and white.

## Canon note

`AI_DOCS.md` says wins should feel uneasy, not like a party. This note replaces that for the Round Complete moment. When this ships, update that sentence so the fireworks are the new rule.

## What the game does now

- A goal win calls `AxelEventFx.show_round_complete_card` (`scripts/autoload/axel_event_fx.gd`). Layer 220. White VT323, size 64, no motion. Black see-through card (alpha `0.72`). Interact or click (after 0.4s) fades back to the room.
- Grid data is never replaced with skulls on a win.
- The white skull on the grid is `combat/art/grid_symbols/satanic_wild.png` (`sym_satanic`, 128×128). The tall skulls on the execute meter (`exports/Drawings/axel_skull_1.png`, 692×922) are a different picture. Use the grid skull.
- The “fireworks” are not particles. In `combat/scripts/empty_item_dvd.gd`, a corner hit spawns 16 flame sprites from `assets/sprites/combat/flame_1_48x48.png`, drawn at 48×48, nearest-neighbor, and they bounce inside the item box.

## Locked choices

- Visual only. Do not write skulls into the grid’s symbol data or the combat randomizer.
- Fireworks reuse those flame sprites. “Exponential” means the count doubles each wave, size stays 48px:
  - On the grid: 8, then 16, then 32 (56 flames).
  - Behind the text: 8, then 16 (24 flames).
  - Hard cap 96 live flames. Free them after about 1.2s.
- They are not trapped in the item box. They burst outward from the grid, and a second burst sits behind the words.
- Alternating color counts every character, including spaces. First character is white, the next is red, and so on.
- The whole phrase jumps together (about 24px up and back, one hop about every 0.45s) until the player continues.
- Interact or click still leaves the fight, same as today.
- If combat dev-skip visuals is on, skip the skulls and flames and show the card immediately.

## Steps

1. After the winning spin’s animations finish, and before the card, in the live win path (`axel_run.gd` `_show_round_complete_card` / `combat_root.gd` goal end): set each visible slot icon texture to `satanic_wild.png`. Pulse each slot’s existing white flash overlay for about 0.4s (glow). Do not call `GridManager` setters.
2. Add a small flame-burst helper (new script under `combat/scripts/`, or a function next to the DVD burst) that spawns the doubling waves. Call it from the grid center, staggered about 0.18s per wave. Use a local `RandomNumberGenerator`, not `CombatRNG`.
3. Then show the Round Complete card as today.
4. Replace the single-color Label with per-character coloring (a `RichTextLabel` with BBCode, or one label per character in an `HBox`). Font stays VT323, size 64. Colors are white and pure red.
5. Put the text-flame burst on `RoundRoot`, after the scrim and before the text, so the flames draw behind the words and above the dark card.
6. Tween the text node’s vertical position in a loop until `play_round_complete_fade` starts, then stop the tween and free leftover flames.
7. Update `tools/qa/round_complete_overlay_check.gd` so it still finds the words “Round Complete” and the full-screen scrim. It should not require one flat white font color.

## What you should see

The grid turns into glowing skulls, they burst into a growing cloud of the same corner flames, then “Round Complete!” appears over its own flames, hopping, with red and white letters. Interact or click still returns you to the room.

## How to test

1. Win a live fight (goal met).
2. Confirm skulls, then flames, then the hopping two-color line, with flames behind the words.
3. Press E, Space, or Enter, or click. You return to the room. The chip balance still includes the win.
4. Run `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/round_complete_overlay_check.gd` and the combat determinism check. Both exit 0. Spin results must match the old check (the new randomizer is display-only).

## Risks

- Too many flame nodes will hitch. The cap of 96 is there on purpose.
- The dark card must not be up before the grid burst, or the skulls will be hidden.
- Headless play will not show shaders or a pretty burst. Judge the look in a window.

## When this ships

Update the Round Complete sentence in `AI_DOCS.md` and add a changelog entry.
