# Reroll survives area rank-up (2026-10-15)

## Problem

HANDOFF item 4. `AxelWorld.reroll_item` only swapped the slot's `id`. When another area was first cleared, `_retier_open_areas` → `_roll_open_area_ids` re-rolled every untaken slot in every untouched area from the room seed, so a paid ticket reroll was thrown away. A save/load did the same (`from_dict` re-tiers once any area is frozen).

## Fix

- `reroll_item` marks the slot `"rerolled": true`.
- `_roll_open_area_ids` keeps a rerolled slot as it is (like a taken one). Rerolled ids and their lanes go into `blocked` / `used_lanes` first, so other slots never duplicate them.
- `from_dict` keeps the `rerolled` key.
- A rerolled item keeps the rarity it had when rerolled. It does not gain the rank-up shift.

## Check

`tools/qa/ticket_machine_check.gd`: reroll a cafeteria slot, take an item in another area (rank-up), and save/load. The rerolled id must stay.
