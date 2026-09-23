# Plan: Power symbol resolution

Plan only. Do not implement in the planning chat.

## What you asked

Check whether the power symbols (the picture shown when a power starts) can be drawn sharper, or whether you need higher-definition art.

## Answer

You need new, higher-definition files. The game cannot invent detail by making the current pictures bigger.

## What the game does now

Each power intro uses the same PNG as the grid icon (`power_intro_texture` on the symbol resource):

| Power | File | Pixels |
| --- | --- | --- |
| Cigarette | `combat/art/grid_symbols/cigarette.png` | 128×128 |
| Alcohol | `combat/art/grid_symbols/booze.png` | 128×128 |
| Bloody hand | `combat/art/grid_symbols/bloody_hand.png` | 128×128 |

`combat/scripts/combat_root.gd` sizes the intro icon to 55% of the short side of the grid, then scales it to a peak of `1.8`. At the usual 1920×1280 window the grid cell is already clamped to 80px, so the grid is about 400px across. The intro picture is then drawn at about 400px from a 128px file (a bit more than 3× bigger).

`PowerIntroIcon` in `combat/scenes/combat_root.tscn` does not force nearest-neighbor. Godot smooths it when it is scaled up, so the pop looks soft. The little grid icons are fine: they are drawn smaller than 128.

## Locked choices

- Do not scale `PowerIntroIcon` any larger. That only makes the blur worse.
- Do not replace the 128px grid icons. Those are the right size for a cell.
- New intro art should be 512×512, same framing and the same hard pixels, one file per power. 512 covers the ~400px peak with a little room. 256 is still too small for that peak.
- Stretching the current 128px files up in an image editor is not a fix. It bakes the blur in.

## Steps

1. You (or the art pass) export three new PNGs, 512×512:
   - `combat/art/grid_symbols/cigarette_intro.png`
   - `combat/art/grid_symbols/booze_intro.png`
   - `combat/art/grid_symbols/bloody_hand_intro.png`
2. Point `power_intro_texture` on `sym_cigarette.tres`, `sym_booze.tres`, and `sym_bloody_hand.tres` at those files. Leave `texture` on the 128px grid file.
3. On `PowerIntroIcon`, set `texture_filter` to nearest (`TEXTURE_FILTER_NEAREST`) so the pixels stay crisp.
4. Until the new files exist, step 3 alone is allowed as a stopgap. The picture will look like bigger pixels, not like new detail. Say so in the changelog if that stopgap ships first.
5. No change to payouts, power order, or intro timing (`0.54` / `0.54` / `0.42` seconds).

## What you should see

When cigarette, alcohol, or bloody hand activates, the big symbol is sharp at the peak size. The symbols inside the grid cells look the same as today.

## How to test

1. Trigger each power once (Vice Round does all three in order).
2. At the biggest moment of the pop, edges should look like pixels, not a smear.
3. A normal spin’s grid icons should be unchanged.
4. Run the combat scaffold check and expect exit 0.

## Risks

- Nearest-neighbor on the old 128px art will look chunky on purpose. That is not the HD version.
- If a new file has a different crop, the glow box behind it will not match. Keep the symbol centered with similar padding to the 128px art.

## When this ships

Changelog only, after the new files are hooked up. No design-doc change for power rules.
