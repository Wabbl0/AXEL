# 2026-10-14 — Basement and endings wiring

## Goal
Connect 1.4 to the basement chain (6.1–6.8) and then to the endings. The corpse now asks for the board symbol.

## Rules (new canon)
- Once the classroom board is cleared, it shows one of ten symbols. The run seed picks which one.
  - Line: `Something's scratched under it: %s`.
  - When the player looks at the board again later, the line repeats.
- 6.8 Corpse:
  - Shows "The body is waiting for a name." and then ten symbol buttons.
  - The buttons appear in a seeded order.
  - The right symbol, with the board cleared, opens the True Ending.
  - Anything else opens Ending 4.
  - The old "board item equipped" rule is gone.
- The 1.4 door always goes to 6.1, and the key check happens there.
  - Returning to 1.4 (6.1 "Go back", 6.3 "I'm not ready") puts the player at the door.
- 6.3: both stair buttons say "Go down", as in ARC6.
- "Start again" on Ending 2, 3 and 4 and on the Epilogue starts a fresh run at 1.1 in the same slot.
  - Ending 1 still goes to the main menu.
- The Ending 2 line "Your dumb." is misspelled on purpose.

## Files
- `combat/scripts/run_state.gd`: `board_symbol`
- `scripts/autoload/axel_world.gd`:
  - `BOARD_SYMBOLS`
  - `ensure_board_symbol`
  - `corpse_symbol_order`
  - `corpse_symbol_correct`
- `scenes/Arc_5/5.1_Classroom.gd`: symbol line
- `scenes/Arc_1/1.4_BasementDoor.gd`: door goes to 6.1, `basement_door` arrival
- `scenes/core/greybox_choice.gd`: spawn key, 6.8 symbol grid
- `scenes/Endings/ending_still.gd`: fresh run on restart
- Checks:
  - `board_room_question_check`
  - `greybox_flow_check`
  - new `basement_route_check`

## Status
Implemented 2026-10-14. Checks pass. Not committed yet.
