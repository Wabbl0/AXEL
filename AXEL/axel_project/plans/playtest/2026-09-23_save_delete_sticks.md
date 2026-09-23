# Plan: Deleted save stays deleted

Plan only. Do not implement in the planning chat.

## What you asked

After you delete a save, then immediately leave the debug session, the save is back the next time you look.

## What the game does now

- Load Game delete is two presses. The second press calls `AxelSaves.delete_slot` in `scripts/autoload/axel_saves.gd`.
- That removes `user://saves/slot_N.meta.json` and `slot_N.json`. It does not remove a half-written `*.json.tmp`. It does not check whether the delete actually worked.
- If that slot was the one you were playing, `active_slot` is cleared. The run is still in memory (`GameManager`, `AxelRun`, `AxelWorld`).
- A save that was already started can still finish and write the files again. `save_active_now` (Quit to Desktop, and `deactivate` on Quit to Title) writes the active slot from memory.
- Combat Dev Tools (`scripts/debug/axel_combat_dev_tools.gd`) never reads or writes saves. Closing that menu is not what puts the file back. The write comes from `AxelSaves` still holding the run.

## Locked choice

A deleted slot must not be written again until New Game uses that slot on purpose. Leaving the game, changing scenes, or closing Dev Tools must not recreate it.

## Steps

1. In `delete_slot` (`axel_saves.gd`), cancel any queued save (`_save_queued = false`) before touching disk.
2. Remember the slot as blocked. `save_active`, `save_active_now`, `_flush_save`, and `_on_scene_changed` must return without writing if the slot they would write is blocked.
3. In `_flush_save`, read `active_slot` once at the start. Check the block again immediately before each `_atomic_write`, so a delete that lands in the middle of a write cannot rename a `.tmp` back into a live file.
4. In `_delete_slot_files`, also delete `slot_N.meta.json.tmp` and `slot_N.json.tmp`. If a real file is still there after the remove, `delete_slot` returns false and Load Game keeps the row (do not show “Slot deleted.”).
5. `new_game` clears the block for that slot, then writes, as it already does today.
6. Do not change Dev Tools, volume settings, or the three-slot layout.
7. Extend `tools/qa/save_slots_check.gd`:
   - Delete the active slot, then call `save_active_now` and a deferred flush. Both files stay gone.
   - Start a flush, delete during it, and assert the files are not recreated.
   - `new_game` on that slot still creates a fresh save.

## What you should see

Delete a slot, confirm, leave Load Game, stop the debug play session, and start again. That slot is empty. Continue does not open it.

## How to test

1. New Game, play for a moment, Quit to Title.
2. Load Game, delete that slot (press Delete twice). It shows empty.
3. Back out, stop Play, press Play again, open Load Game. The slot is still empty.
4. Run `tools/cmd/godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/save_slots_check.gd` and expect exit 0.

## Risks

- If someone deletes the files in File Explorer while a run is still active, the next real save can still write them. This plan covers the in-game Delete button.
- OneDrive restoring `user://` is outside the game. `user://` is the Godot user folder, not the project folder.

## When this ships

Add a changelog entry. No combat or CRT docs change.
