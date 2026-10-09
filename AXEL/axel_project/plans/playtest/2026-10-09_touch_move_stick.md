# 2026-10-09 Touch move stick and tap to interact (plan, not built yet)

## Goal
On a phone, the player presses anywhere on the screen and slides a finger toward where Mike should walk. A faint stick (a small circle inside a bigger circle) shows where the finger went down and which way Mike is heading.

## How it works
- A new autoload, `AxelTouchStick` (`scripts/autoload/axel_touch_stick.gd`), draws on its own CanvasLayer. It sits above the world and below the dialogue bar, pause menu and cursor.
- **Finger down:** the spot becomes the stick's center. The outer ring appears there, faint.
- **Finger drags:** the inner knob follows the finger but stays inside the ring. Direction = finger minus center.
  - Dead zone: about 12 px at 1920×1280. Inside it, Mike stands still.
  - Full speed at the ring edge (about 90 px radius). In between, he walks slower (analog strength).
- **Finger up:** the stick fades out and Mike stops.
- The stick does not move Mike itself. It presses the existing `move_left/right/up/down` actions with `Input.action_press(action, strength)` and lets go of them with `Input.action_release`.
  - So `Player.gd` stays unchanged. Its `Input.get_vector(...)` line (`scripts/Player.gd:1041`) already reads analog strength.
  - This follows the "input goes through InputMap actions" rule.
- Only one finger at a time: the stick remembers the first touch index and ignores other fingers.

## Look
- Outer ring: thin line, warm grey from the noir palette, about 25% opacity.
- Inner knob: filled, dim red, about 35% opacity.
- Sizes scale with the live viewport height (1280 is the baseline), like the dialogue bar does.
- Fade in and out over about 0.1 s. No glow and no CRT effect on the stick for now.

## When the stick is off
- Not on a touch device. On by default when `OS.has_feature("mobile")` is true. For testing on Windows, there is a dev switch (env `AXEL_TOUCH_STICK=1`) that also lets a mouse drag drive the stick.
- No Player in the current scene, or `Player.is_input_enabled()` is false (dialogue, memories, cutscenes).
- Game paused (`AxelPause`), main menu, combat.
- A touch that lands on a UI control (buttons, `[E]` chip, hotspots). The stick listens in `_unhandled_input`, so UI gets the touch first.
- If any of these turn on mid-drag, the stick releases all move actions right away, so Mike never keeps walking on his own.

## Risks to check
- Godot turns touches into fake mouse clicks by default (`emulate_mouse_from_touch`). The dialogue bar and memory stills already handle touch, but a drag may also count as a click there. Check that a walk-drag never advances a line by accident.
- `AxelCursor` should hide on mobile (there is no mouse).
- Walk-step fight rolls (`_report_walk_steps_for_cadence`) should keep working, because Mike still moves through the normal path.

## Tap to interact (decided 2026-10-09)
The player interacts by tapping the object itself. On mobile there is no `[E]` chip. Instead, a soft pulsing highlight shows that something can be tapped.

- **When it shows:** only when the `[E]` chip would show today, meaning Mike is inside an armed interact zone. Walk up to an object and it starts pulsing.
- **Where it shows:** the same spot `InteractPromptOverlay` already uses for the chip. On mobile the overlay draws a pulsing ring there instead of the `[E]` box. Every room gets this for free, and no per-room work is needed.
- **Tap vs. walk:**
  - A touch that lifts within about 0.25 s and moves less than the dead zone is a **tap**.
  - Anything else is a **walk**.
  - A tap never moves Mike.
- **What a tap hits:** the tap counts if it lands on the pulse or on the active zone's `InteractArea` (with a small margin). Taps elsewhere do nothing.
- **How it fires:** the tap sends a fake `interact` action press (`Input.parse_input_event` with an `InputEventAction`). So `exploration_room.gd`, `world_item_pickup.gd`, `1.1`, `1.2` and the dialogue all work as they do today, with no per-room changes.
- **Out of range:** tapping an object Mike is not near does nothing for now. Walking there on tap could come later.

## Not in this plan (later)
- A **pause** button on screen.
- **Item wheel** on touch. Another agent is revamping it, so leave it alone.

## Checks after building
- Run the normal checks in CLAUDE.md, especially `tools/scene_smoke_check.gd`, `pause_contract_check.gd` and `menu_nav_check.gd`.
- New check `tools/qa/touch_stick_check.gd`: sends fake touch events and checks:
  - the move actions get pressed, with the right strength;
  - they get released on finger up;
  - they get released on pause;
  - nothing happens while input is disabled.
