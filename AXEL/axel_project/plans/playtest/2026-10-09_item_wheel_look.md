# Plan: Item wheel look

Shipped. The layout and behavior from [Item wheel](2026-09-23_item_wheel.md) are unchanged. Only the look changed.

## What you asked

Keep the structure of the item wheel and give it a visual revamp.

## What the game does now

All of this lives in `scenes/ui/item_wheel.gd`.

- **Rank reds.** Each band's outline uses one of 4 palette reds, from dim (Common) to bright (Epic). The rarity glyph (`◇◈◆★`) sits under each band's left end in that band's red.
- **Band depth.** The fill is a radial gradient, blacker inside and warm-black outside. A faint groove sits 4px inside each edge, and two very faint scanline arcs run through each band. The drop shadow stays.
- **Sockets.** Each icon sits on a drawn circle.
  - **Equipped:** a dark-red disc with a red ring and a slow, faint glow pulse.
  - **Unequipped:** a near-black disc with a warm-grey ring.
  - **Hover:** the ring grows 2px and brightens.
  - **Click:** the socket flashes white for 0.15s.
- **Arrows.** The arrows are outlined chevrons in the band's red. They lighten under the mouse and turn dim warm grey when the band has 3 or fewer items, since it cannot scroll then.
- **Open and close.**
  - **Open:** bands sweep open from left to right in 0.18s, each band starting 0.04s after the one inside it. Icons fade in as the sweep passes. There is a 1–2px glitch jitter for the first 0.05s, using its own random generator, never combat RNG.
  - **Close:** Esc, Tab, or clicking Mike collapses the wheel in 0.1s. Pause, a scene change, or a fight starting closes it instantly. `is_wheel_open()` turns false at once either way.
- **Cap pips.** One small pip per equip slot sits under the `n/cap` label. Filled slots are red and empty ones are a warm-grey outline. The label turns red at full cap. The label text is unchanged.

## Checks

`tools/qa/item_wheel_check.gd` also checks two things:

- After a reopen, `open_progress()` reaches 1.0.
- `band_can_scroll()` is true for a band with 4 items and false for an empty band.

## How to test

1. Open the wheel with Tab and watch the sweep.
2. With items of several ranks, check that each band has its own red and glyph.
3. Equip and unequip items. Check the sockets and the click flash.
4. Hover the arrows on a band with 4 or more items, then on a band with fewer.
5. Fill the cap. Check that all the pips go red and the label turns red.
6. Press Esc. The wheel collapses fast and pause does not open.
