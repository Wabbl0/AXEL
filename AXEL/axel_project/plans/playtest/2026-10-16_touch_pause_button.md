# 2026-10-16 Touch pause button and guide touch wording

Follow-up to `2026-10-15_web_phone_touch.md` ("Still open").

## Problem
- A phone player cannot open pause, Guide, Options or Save & Quit outside a fight. Pause is only on the `pause` action (Esc) in the overworld.
- `guide_pages.gd` still names keys (bets: "keys Q and R"; item wheel: "Tab, Q, R, I, or click Mike").

## Fix
- `AxelTouchStick` owns a small `II` button in the top-right of `PortraitUi.safe_rect` (VT323, `MenuLook.apply_button`, no focus).
  - Shown only when touch mode is on, the stick is active (overworld room with a Player, input on, no fight, no dialogue) and `AxelPause.can_pause_here()`.
  - Tap calls `AxelPause.request_pause()`. `AxelPause` stays the only writer of `get_tree().paused`.
  - A touch that starts on the button never starts the stick.
- `AxelPause.can_pause_here()`: public wrapper of the existing pause gate.
- Guide blocks: optional `touch_text`, shown by `GuidePanel` in touch mode (same idea as tutorial `touch_body`). Added for bets, the item wheel and "hover an item name" (now "tap"). `item_wording_check.gd` also scans `touch_text`.
- `touch_stick_check.gd`: the button shows in 1.4 in touch mode, a tap on it pauses, it hides while paused.

## Still open
- Real phone test (Android Chrome, iPhone Safari, first-tap audio, load time).
