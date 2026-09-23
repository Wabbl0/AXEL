# Plan: Load Game seed hover and copy

Plan only. Do not implement in the planning chat.

## What you asked

On Load Game, hovering the seed shows the full number, because the row usually cuts it off. Clicking the seed copies it to the clipboard.

## What the game does now

- `scenes/Main_Menu/Saves.gd` builds one long button label: slot, room, time, date, then `seed N` at the end (`_slot_label`).
- That button sets `clip_text` and ellipsis so the Delete button stays fully visible. The seed is the part that disappears.
- Pressing the slot button loads the game. There is no clipboard use anywhere in the project.
- Pause shows a separate `SEED N` label. It is not clipped and it is not clickable. Leave it alone.

## Locked choices

- The seed gets its own button on the row, between the slot summary and Delete. Clicking it copies. It does not load the slot.
- Hover shows the full number in a small label, even when the button itself is cut off.
- The slot summary button no longer includes the seed, so room and time are what get clipped first.

## Steps

1. In `_slot_label`, stop appending `seed %d`.
2. In `_make_slot_row`, when the slot has a non-zero seed, add a button named `SeedSlotN`. Text is `seed %d`. Use the same VT323 look as the other menu buttons (`MenuLook.apply_button`).
3. Let that button ellipsize if the row is narrow. On `mouse_entered`, show a hover label (child of the Saves screen, not a Godot tooltip) with the full `seed %d` string in the same font. Hide it on `mouse_exited`. Place it just above the seed button, and keep it inside the window.
4. On press, call `DisplayServer.clipboard_set` with the digits only (no “seed ” prefix). Set the status line to `Seed copied.` Do not call `load_slot`.
5. Empty slots get no seed button.
6. Keyboard: focusing the seed button and pressing interact (E / Space / Enter) copies, because it is a normal button press. Focusing the slot button still loads.
7. Add a check in `tools/qa/save_slots_check.gd` or `menu_nav_check.gd`: a living slot’s seed button text contains the header seed, and the slot button text does not.

## What you should see

Load Game shows the seed as its own word. If the window cuts it, hovering shows every digit. Clicking it copies the digits. The slot still loads only when you press the main slot row.

## How to test

1. Open Load Game with a used slot.
2. Hover the seed. The full number is readable.
3. Click it, paste into Notepad. The number matches. The game does not load.
4. Click the slot row. The game loads.
5. Run the save-slot or menu-nav check headless and expect exit 0.

## Risks

- A hover label must not cover the Delete button’s click.
- Do not copy on the slot-row click.

## When this ships

One changelog line. Pause `SEED N` stays unchanged. Seed-entry (typing a seed to load) is still later and is not this task.
