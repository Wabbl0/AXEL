# Plan: Overworld item wheel

Shipped. Do not build this again. The behavior below is what the game does now. The other playtest notes in this folder are still plans.

## What you asked

Remove item rows from the pause menu. Open a half-circle wheel on Mike with a click, or with Tab, Q, R, or I. Four bands, inner to outer: Common, Uncommon, Rare, Epic. Legendary is not on the wheel. Each band shows 3 items and scrolls. Equipped items are full color. The others are grey. Hover shows the overworld card without `[E]`.

## What the game does now

- Pause has no item list, no equip checkbox, and no `0/7` line.
- `scenes/ui/item_wheel.gd` is created by `AxelWorld`. Click Mike, or press Tab, Q, R, or I (`item_wheel`). Tab still advances a line when the dialogue bar is up. Esc closes the wheel and does not pause on that press.
- Four ranks, inner to outer: Common, Uncommon, Rare, Epic. The fill is near-black. The Common arc is always drawn. Uncommon, Rare, and Epic arcs appear only after an item of that rank is owned, packed inward so a skipped rank leaves no empty hole. Legendary is not drawn. A pickup can still auto-equip a Legendary, and the cap count includes it.
- Each drawn arc shows up to 3 owned items. Downward arrows at the lower ends, and the mouse wheel, scroll. The list wraps. Left still scrolls back and right still scrolls forward. Equipped icons are full color. The others are grey. Click toggles equip through `AxelRun.toggle_equip`. Hover grows the icon from 40px to 46px.
- The `n/cap` label sits above the outermost drawn arc, and only after the player owns at least one item.
- Hover uses `world_item_info_card.gd` with its top-left just outside the icon’s bottom-right corner, without `[E]`. Floor cards still show `[E]` under the items_indicator.
- The wheel closes on pause or when a fight starts. It is not on the title menu or in combat.

## Locked choices

- Overworld only. Not combat. Not the title, Load, Options, or Credits screens.
- New InputMap action `item_wheel`: Tab, Q, R, and I. No raw key checks. Tab still advances a line when the dialogue bar is up, because the bar handles that key first.
- Esc (`pause` / `back`) closes the wheel and does not open pause on that press.
- Clicking Mike toggles the wheel. Walking still works. The wheel follows Mike’s head.
- Four ranks. Inner Common, then Uncommon, Rare, outer Epic. Fill is near-black. Outlines are red. The sketch colors were only to separate the bands.
- The Common arc is always drawn. A higher arc is drawn only after the player owns an item of that rank. Skipped ranks pack inward and do not leave an empty hole. Each drawn arc shows up to 3 owned items of that rank. More than 3 scroll, and the list wraps. Fewer than 3 just show those. Arrows on the lower-left and lower-right of each drawn arc point down and scroll opposite ways. The mouse wheel scrolls the arc under the pointer.
- Click an item to toggle equip. A full cap does not equip another item. Equipped icons stay full color. Owned but unequipped icons are grey.
- Legendary items are not drawn and cannot be toggled here. The cap count still includes one that is equipped. Pickup auto-equip is unchanged.
- The `n/7` label leaves the pause menu. It shows on the wheel only when the player owns at least one item (any rank, including Legendary).
- Pause loses the item list, the checkboxes, and the story-item rows. Story items are not on this wheel.
- Hover grows the icon a little and uses the existing walk-up card, without `[E]`, from the icon’s bottom-right corner. Do not change the card’s width in this note.
- The wheel closes when a fight starts or the game pauses.

## Steps

1. Add `item_wheel` to `project.godot`.
2. Add `scenes/ui/item_wheel.gd`. `AxelWorld` creates it so every overworld scene has it. Layer `109`, above the CRT and under dialogue. The walk-up card stays on top of the arcs.
3. Draw four upper half-rings over the head. Place up to three icons on each ring. Left arrow scrolls back. Right arrow scrolls forward.
4. Add `show_screen_item` on the info card for the hover. Floor `show_item` still shows `[E]` under the items_indicator.
5. Delete the pause loadout column, cap label, and equip handlers.
6. Update `tools/qa/pause_contract_check.gd` so it expects no loadout. Add `tools/qa/item_wheel_check.gd`: 4 bands, a Legendary id is owned but not listed, the cap label is hidden with an empty inventory and visible once an item is owned.
7. Update the pause and input sentences in `plans/core/AI_DOCS.md`.

## What you should see

Click Mike, or press Q, R, I, or Tab (when no line is playing). A near-black half-rainbow with red edges opens over his head. Only the Common arc shows until a higher rank is collected. Icons you have equipped are bright. The rest are grey. The end arrows point down. Hover grows the icon and shows the name and description from its bottom-right, with no `[E]`. Pause no longer lists items.

## How to test

1. With no items, open the wheel. One empty Common arc. No `0/7`. Owning an Uncommon adds the next arc. A Rare with no Uncommon adds that arc without a blank hole.
2. Own a Common and a Legendary. The Common can appear. The Legendary does not. If the Legendary is equipped, the count includes it.
3. Own four Commons. Only three show. The arrows and the mouse wheel change which three, and the list wraps.
4. Click an icon until the cap is full. Another click does not equip. Clicking an equipped icon turns it off.
5. Press Esc. The wheel closes and pause does not open. Press Esc again. Pause opens, with no item list.
6. Run `item_wheel_check.gd` and `pause_contract_check.gd` headless and expect exit 0.

## Risks

- A Legendary that auto-equipped cannot be turned off from this wheel. The locker shelf is unchanged, but this note does not add a Legendary band.
- Tab must not open the wheel while a line is typing.
- The wheel must not use mouse-stop on the whole window, or Mike cannot walk and doors cannot be clicked.

## When this ships

One changelog line. Card width, plain descriptions, the items_indicator outline, and the memory color stay separate notes.
