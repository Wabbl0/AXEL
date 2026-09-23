# Plan: Pause menu in the middle of every scene

Plan only. Do not implement in the planning chat.

## What you asked

The pause menu should sit in the middle of the screen, in every scene you can pause.

## What the game does now

- `scenes/ui/pause_menu.gd` builds one column (`_menu`) anchored to the full window with `offset_top = 36`. The word PAUSED and the buttons start at the top. That is why the menu sits high in the screenshot.
- `scripts/autoload/axel_pause.gd` already opens that same menu in any scene that is not the title screens, as long as a dialogue line is not playing and the loss menu is not open.
- The menu layer is `120`. Combat draws above that (`combat_root.gd` layer `180`, the combat wipe and settings panel at `200`, the round fade at `220`). A fight can cover the pause menu.

## Locked choices

- Center the button column on the window, horizontally and vertically. The seed label stays at the bottom-right.
- Same menu in rooms, the map, the locker, memory stills, and combat.
- Title, Load Game, Options, and Credits still have no pause menu.
- Raise the pause layer above the combat overlays so the menu is visible in a fight.

## Steps

1. In `_build`, stop anchoring `_menu` to the full window from the top. Put the column in a centered container (anchors at the center, or a `CenterContainer` filling the window). Keep the button text centered.
2. Set the pause `CanvasLayer` above `220` (use `250`).
3. Do not add a pause menu to `scenes/Main_Menu/`.
4. Extend `tools/qa/pause_contract_check.gd`: after pause opens in `1.2`, the PAUSED label’s center is near the window center (within about 80 px). After pause opens in `combat_test.tscn`, the menu node is visible and its layer is above `220`.

## What you should see

Esc in a room or a fight shows PAUSED in the middle of the window, not at the top, and not hidden under the combat art.

## How to test

1. Pause in room 2.1. The menu is in the middle.
2. Pause in a fight. The menu is in the middle and readable.
3. Open the title menu and press Esc. No pause menu.
4. Run the pause contract check headless and expect exit 0.

## Risks

- A taller column (if options are later added back) must still stay on screen. Centering the current button list is enough.
- Do not pause the tree from any script other than `AxelPause`.

## When this ships

One changelog line. Options still opens from this menu; the blank Options page is a separate note.
