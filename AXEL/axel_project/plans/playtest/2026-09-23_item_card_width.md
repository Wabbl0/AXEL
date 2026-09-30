# Plan: One width for the overworld item card

Plan only. Do not implement in the planning chat.

## What you asked

In the overworld, every item description bar has the same max width, a wide landscape shape. The icon sits at the top-left, beside the title, in its own box, so a title that wraps to a second line does not run into the icon.

## What the game does now

- `scenes/ui/world_item_info_card.gd` sets the description width to the title string width (`_apply_wrap_sizes`). A short name such as Locker Tape makes a tall narrow card.
- The icon is the left cell of a horizontal row, so it lines up with the middle of the whole text block, not the top of the title.
- The title does not wrap (`AUTOWRAP_OFF`).
- `[E]` is the bottom-right line. Floor items use it. The card CRT-opens under the items_indicator.
- `tools/qa/world_item_card_check.gd` fails if the description width does not follow the title, or if the title is more than one line.

## Locked choices

- One shared width for every overworld card: 42% of the window width. The width does not change per item. On a 1920-wide window that is about 800 px, a wide landscape bar.
- Height still grows with the text. Do not clip the description.
- Icon stays top-left, fixed size, in its own box. The title is in the column to the right of the icon and may wrap to a second line inside that column only. The description wraps in that same column, under the title.
- `[E]` stays at the bottom-right for floor items. The item wheel hover hides `[E]`; that hide is part of the wheel, not a second card.
- Combat item rows are not this card. Do not change them.

## Steps

1. Replace `_title_px()` sizing. Set the text column width to `viewport_width * 0.42` minus the icon and the row gap.
2. Turn title autowrap on, and give the title the same max width as the description. Keep the icon’s vertical size flags at the top of the row (`SIZE_SHRINK_BEGIN`), not vertically centered.
3. Keep the card under the items_indicator by the same 10 px gap, and keep it inside the window on X.
4. Update `world_item_card_check.gd`: description max width is the shared column width, not the title string width. A short title and a long title produce the same panel width (within a few pixels). The icon’s top is within a few pixels of the title’s top.

## What you should see

Locker Tape and a long item name use the same wide card. The icon is at the top-left. A two-line title stays to the right of the icon. The description wraps under the title. `[E]` is still at the bottom-right on a floor item.

## How to test

1. Walk up to a short-name floor item and a long-name floor item. The cards are the same width.
2. Run `world_item_card_check.gd` headless and expect exit 0.

## Risks

- Godot 4.7 wrapping labels need a real max width. Do not use the old `custom_minimum_size.x = 1` trick.
- The wheel hover uses this same card. After this ships, that hover gets the new width without a second layout.

## When this ships

One changelog line. Update the floor-marker card sentence in `plans/core/AI_DOCS.md`.
