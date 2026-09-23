# Plan: Esc skips a dialogue line

Plan only. Do not implement in the planning chat.

## What you asked

Esc should skip dialogue the same way the other skip keys do.

## What the game does now

- `scenes/ui/TopDialogueOverlay.gd` `_is_advance_event` accepts `dialogue_advance` (Tab, E, Space, Enter, pad A) and a left click. While the line is typing, that reveals the whole line. When the line is fully shown, it advances.
- Esc is the `pause` action and the `back` action. It is not `dialogue_advance`.
- `AxelPause` refuses to pause while `is_sequence_busy()`, and it does not mark the key handled when pause is refused. Esc during a line does nothing.
- The locker and the map leave the room on `back`. If Esc is not consumed by the dialogue bar, it can also try to leave.

## Locked choices

- Esc, Backspace, and Delete (the `back` action) do the same thing as Tab: reveal the current line, then advance.
- The dialogue bar marks that key handled, so the locker and the map do not exit on the same press.
- Lines with skip turned off still ignore Esc.
- Pause still waits until the line sequence is finished.
- If the item wheel is open and no line is playing, Esc closes the wheel and does not pause. That close belongs to the wheel, not this note.

## Steps

1. In `_is_advance_event`, also return true for `event.is_action_pressed("back")` when skip input is enabled. Do not add Esc to the `dialogue_advance` action. Esc stays pause and back everywhere else.
2. `_input` already marks the event handled after a successful reveal or advance. Keep that, so `_unhandled_input` on the room and on `AxelPause` does not also run.
3. Do not treat Esc as “skip every remaining line.” One press, one line, same as Tab.
4. Add a headless check: show a line, send Esc, the line is fully revealed or the sequence advances, and `request_pause` is still false while the sequence is busy.

## What you should see

During a line, Esc finishes the typing, then the next Esc goes to the next line or closes the bar. The pause menu does not open on top of the line. The locker does not kick you out on that same press.

## How to test

1. Walk into a room with an enter line. Press Esc while the letters are still typing. The whole line appears.
2. Press Esc again. The line advances or the bar closes.
3. After the bar is gone, Esc opens pause.
4. Run the dialogue check headless and expect exit 0.

## Risks

- First-visit lines that block leaving must advance on Esc, not exit the room.
- Do not let one Esc both advance the line and open pause.

## When this ships

One changelog line. Update the dialogue input sentence in `plans/core/AI_DOCS.md`.
