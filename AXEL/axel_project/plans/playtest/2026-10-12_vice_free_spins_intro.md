# Vice Round and Free Spins arcade intro (2026-10-12)

## Why
The old VICE ROUND and FREE SPINS starts were a plain dark-red fade (`CombatFeel.play_banner`), with no sound. They felt flat next to Round Complete and the loss shatter.

## What
- `combat/scripts/bonus_intro_fx.gd` draws the shared intro on `FeelLayer` (115): a hit flash and shake, turning red rays, chase-light bulb bars, shockwaves, sparks, and letters that wave and chase red and white, then zoom out and fade. It runs about 2.15s at 1×, with E-rush, freeze and combat speed through `CombatPace`.
- **VICE ROUND** (on the grid): "VICE" slams in, then "ROUND" slams in from the right. The bloody hand, alcohol and cigarette icons pop in under the title, in firing order.
- **FREE SPINS** (full screen, lifted 90px): the letters spin like slot reels and lock left to right. A white skull rain falls during the hold.
- **Vice power pops**: at each power icon's peak there is a shockwave, sparks, a small shake, the power name in red under the icon, and a **1/3**, **2/3** or **3/3** tag above it. Power activation timing stays 1.75s. Normal-spin powers only get a ring.
- After the Vice intro the grid flashes white once (it used to flash twice).
- Sound: `trinity` and `free_spins` play the skull clip. `bonus_slam` (the second slam, or the last reel lock) plays the round-winnings clip.
- Reduce flashing: no flash, shake, rays, bars, sparks or rain; only a plain pop-in and fade.

## Regression
`combat/test/bonus_intro_fx_check.gd`
