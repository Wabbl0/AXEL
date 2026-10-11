# AXEL: build touch move stick + tap to interact (handoff plan, built 2026-10-11)

Design note: `plans/playtest/2026-10-09_touch_move_stick.md`. All paths below are relative to `AXEL/axel_project/` (`res://`).

## What and why
AXEL will be ported to phones (iOS later). Phones have no keyboard or mouse, so the overworld needs:
1. **Move stick.** The player presses anywhere and slides a finger toward where Mike should walk.
   - A faint stick shows on finger down: a small knob inside a bigger ring, at the finger-down spot.
   - The knob follows the finger, staying inside the ring.
   - A short slide walks slowly; a slide to the ring's edge walks at full speed.
   - Finger up: the stick fades out and Mike stops.
2. **Tap to interact.** The player taps the object.
   - On mobile the `[E]` chip is not shown. A soft pulsing red highlight replaces it.
   - It shows only when Mike is in range, the same moment the chip shows today.
   - Tapping something out of range does nothing.

Out of scope: on-screen pause button, item wheel (`scenes/ui/item_wheel.gd`), walk-to-tapped-object, the iOS export preset.

## Facts about the existing code
- **Movement:** `scripts/Player.gd` reads `Input.get_vector("move_left", "move_right", "move_up", "move_down")`. `Input.action_press(action, strength)` drives Mike with no Player change. InputMap `move_*` deadzone is 0.2.
- **Player lookup:** `get_tree().current_scene.get_node_or_null("PlayerLayer/Player")`.
- **Pause:** `scripts/autoload/axel_pause.gd`: `is_paused()`, `is_focus_frozen()`, `signal pause_state_changed(paused)`. Only `AxelPause` writes `get_tree().paused`.
- **Combat:** `AxelRun.is_in_encounter()`.
- **Dialogue busy:** `InteractZoneGate.dialogue_busy(scene.get_node_or_null("TopDialogueOverlay"))`.
- **CanvasLayers:** 90–108 post-FX, 109 item wheel / info card / touch stick, 110 `InteractPromptOverlay`, 111 `TopDialogueOverlay`, 250 pause menu, 400 `AxelCursor`.
- **`[E]` chip:** `scenes/ui/InteractPromptOverlay.gd`. Tree `ViewportRoot/ChipRoot/BarPanel/...`. Every room names it `InteractPromptOverlay` at the scene root.
- **Interact handlers** all use `_unhandled_input` + `event.is_action_pressed("interact")`, so a synthetic `InputEventAction` "interact" through `Input.parse_input_event` triggers them all unchanged.
- **Dialogue:** `TopDialogueOverlay.gd` used to advance on both `InputEventScreenTouch` and the emulated mouse press from the same tap.

## Steps (done)
1. New autoload `scripts/autoload/axel_touch_stick.gd` registered as `AxelTouchStick`.
   - `is_touch_mode()`: `OS.has_feature("mobile")` or env `AXEL_TOUCH_STICK == "1"`; `set_touch_mode_override(on)` for tests.
   - Left mouse acts as one finger; emulated mouse events are ignored.
   - CanvasLayer 109: grey ring ~25% alpha, r 90 px × UI scale; red knob `Color(0.9, 0, 0)` ~35% alpha; 0.1 s fade.
   - `_process` maps offset / radius to `move_*` strengths; below 0.2 nothing is pressed.
   - Tap: lift within 0.25 s, never left the dead zone. Targets: the prompt's `tap_hit(pos)`, then group `touch_tap_target` `touch_tap_hit(pos)`. A hit sends an `interact` press + release.
   - Gate: touch mode, Player with `is_input_enabled()`, not paused / focus frozen, not in an encounter, not the main menu, not dialogue busy. Also releases on `pause_state_changed` and `scene_changed`.
2. `InteractPromptOverlay.gd`: touch mode hides `BarPanel`, adds `TapPulse` (1.2 s loop, alpha 0.25 → 0.6, scale 1.0 → 1.15), `tap_center()`, `tap_hit(screen_pos)`.
3. `world_item_pickup.gd`: joins `touch_tap_target` while the player is inside; `touch_tap_hit(screen_pos)` around the floor marker.
4. `axel_cursor.gd`: no cursor sprite on `mobile`.
5. `TopDialogueOverlay.gd`: skip the `InputEventScreenTouch` branches while `emulate_mouse_from_touch` is on.
6. Check `tools/qa/touch_stick_check.gd` (room 1.4): drag strength and release, dead zone, pause mid-drag, input disabled, prompt tap fires once / far tap fires nothing, one emulated tap advances dialogue once.

## Verification
1. `tools\cmd\godot.cmd --headless --path AXEL/axel_project --import` once.
2. `tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/touch_stick_check.gd` plus the standard checks in `CLAUDE.md`. Exit code 0 means pass.
3. Manual: set env `AXEL_TOUCH_STICK=1` and Play from the editor.
   - Mouse drag: the stick shows and Mike walks.
   - Near an object: the pulse shows instead of `[E]`, and a click on it interacts.
   - Dialogue: one click advances one line.
   - Keyboard still works as before.
