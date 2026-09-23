# Plan: Combat loss collapse

Plan only. Do not implement in the planning chat.

## What you asked

When you lose:

- Every art piece in the combat screen explodes and is thrown down off the screen.
- Then either “GONE” or “IT TAKES YOU” fades in. The line is chosen at random.
- After 3 seconds, or a click, or interact (Space, E, Enter, and the other interact keys), the buttons appear: Retry, Return To Main Menu, and Exit.

## What the game does now

- A loss calls `AxelRun._open_permadeath_menu`, which deletes that slot’s save, then `CombatFeel.show_game_over_menu`.
- The menu sets the banner to “GONE” at full strength immediately and shows all three buttons at once. There is no “IT TAKES YOU” string in the live game.
- Nothing falls off the screen on a loss. (Symbols can fall during a normal spin. That is a different animation.)
- Feel layer is 115, above the combat CRT.

## Locked choices

- Delete the save at the start of the loss, before the animation, as today. Quitting during the fall must not keep the run.
- The coin flip uses its own `RandomNumberGenerator`, not the spin randomizer. Two losses may show different lines. Replaying the spins still matches.
- “Explode” here is a small flame pop (4 of the same corner flames), then the piece falls off the bottom. It is not the big doubling firework from the win plan.
- The 3 seconds start when the line has finished fading in. A click or interact before the line is fully visible does nothing. The input that reveals the buttons must not also press Retry.
- Buttons stay Retry, Return To Main Menu, and Exit, in that order.

## What counts as a piece

Throw these, staggered by about 0.04s, each fall about 0.8s with a small rotation:

- The 5×5 slots and the grid frame on `CombatRoot`
- HUD pieces: `NEW_Grid`, `NEW_History`, `NEW_Items`, `NEW_Bets`, `NEW_Goal`, `NEW_Multiplier`, `NEW_Settings`, and `NEW_Execute`
- The empty-item disc, if it is on screen

Do not throw the CRT overlay, the Feel layer (it holds the new line), or the pause menu.

## Steps

1. In `combat_feel.gd`, split `show_game_over_menu` into three beats: collapse, line, then buttons.
2. Collapse: gather the nodes above, spawn 4 flame sprites at each one’s center (same sheet as `empty_item_dvd.gd`), tween the node down past the bottom of the window, then hide it. Do not free HUD nodes; Retry already leaves the scene.
3. Pick “GONE” or “IT TAKES YOU” with a fresh RNG (`rng.randomize()`). Fade that banner from alpha 0 to 1 over about 0.5s. Keep the dark scrim.
4. When the fade finishes, start a 3s timer and listen for interact plus left click. Whichever comes first shows the three buttons and focuses Retry (`MenuLook.grab_first_focus`). Mark that input handled, and show the buttons on the next frame so the click does not land on Retry.
5. `axel_run.gd` still deletes the slot before calling the menu. Button callbacks stay `_retry_new_run`, `_to_title_after_death`, and `_quit_after_death`.
6. Add a headless check under `tools/qa/` that opens the loss menu, asserts the buttons are hidden, advances 3 seconds (or sends interact), then asserts the three captions exist. It does not need to screenshot the fall.

## What you should see

The combat pictures drop off the bottom in a short burst. One of the two lines fades in. The buttons are absent until you wait 3 seconds or press interact or click. Then you can retry, go to the title, or exit. The deleted slot stays deleted.

## How to test

1. Lose a fight (run out of chips).
2. Watch the pieces fall. Confirm the line fades in with no buttons yet.
3. Click once, or press E / Space / Enter. The three buttons appear and Retry is not activated by that same press.
4. Repeat a loss and wait 3 seconds without pressing anything. The buttons appear on their own.
5. Run the new loss-menu check and `save_slots_check.gd`. Both exit 0. The lost slot is empty on Load Game.

## Risks

- Throwing `NEW_Grid` and the live slots both move grid art. That is intended: the frame and the symbols both go.
- If reduce-flashing is on in settings, still play the fall and the line. You may skip the 4-flame pops only. Do not skip the buttons.

## When this ships

Update the loss sentence in `AI_DOCS.md` (GONE only, buttons immediate) to the two lines and the delayed buttons. Add a changelog entry.
