# Item box redesign (2026-10-12)

## Problem
The half-circle rank wheel over Mike only showed 3 items per rank, hid Legendary items, and had no room for anything else. The player could not sort items, see their balance, see active effects, see how much symbols pay, or see which areas still hold items.

## Decision
Replace the wheel with one small rectangular box fixed at the screen center, with tabs:

- **ITEMS**: every owned item (Legendary included). Sort: rarity / newest pickup / name / type. Filter: rank, type (family). Click toggles equip. Hover shows the walk-up card beside the box.
- **STATS**: equipped items' effect text, grouped by family.
- **PAY**: 3/4/5 picture values per symbol after equipped items. Red = raised by items.
- **AREAS**: taken/placed floor items per area, `CLEARED` when all are picked up.
- Footer on every tab: `BALANCE` and `n/cap`.

The node path (`AxelWorld/ItemWheel`), input (`item_wheel` action, click Mike), Esc behaviour, SFX cues and the `items_wheel` tutorial id stay the same.

## Files
- `scenes/ui/item_wheel.gd`: rewritten as the tabbed box.
- `combat/scripts/item_def.gd`: `FAMILY_NAMES`, `family_name()`.
- `combat/scripts/item_effect_dispatcher.gd`: read-only `pay_preview()` (combat code does not call it).
- `scripts/autoload/axel_world.gd`: `area_item_counts()`, `area_item_rows()`.
- `scripts/autoload/axel_tutorial.gd`: `items_wheel` text.
- `tools/qa/item_wheel_check.gd`: new asserts (tabs, sort, filters, cap, toggle, balance, pay values, areas, open animation).

## Known limits
- PAY shows values at 0 paid spins and outside the Vice Round; notes appear when equipped items add more in those cases.
- `sym_green_circle.tres` has display name "Red square" (existing data, unchanged).
