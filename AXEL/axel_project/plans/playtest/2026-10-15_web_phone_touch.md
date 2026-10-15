# 2026-10-15 Touch controls on phone browsers (built)

Follow-up to `2026-10-09_touch_move_stick.md` and `2026-10-11_touch_controls_build.md`.

## What the phone test found (live 1.0.0 web build, emulated iPhone 13)
- Touch mode never turned on in a phone browser. Godot reports a phone browser as `web_android` / `web_ios`, not `mobile`.
  - Dragging did nothing: no stick, Mike did not walk.
  - The desktop cursor arrow was drawn on the phone.
  - The `[E]` chip showed instead of the tap pulse.
  - The portrait safe area ignored the device safe area.
- The tutorial cards spoke about keys ("WASD or the arrow keys walk", "Press E", "Esc", "Tab").
- Menus and New Game work with taps. Load time ~50 s on a desktop-emulated phone.

## Fix
- `PortraitUi.is_touch_device()`: `mobile`, `web_android` or `web_ios`. Used by `AxelTouchStick.is_touch_mode()`, `AxelCursor` and `PortraitUi.safe_rect`.
- `AxelTutorial.LESSONS`: optional `touch_body`, shown when `AxelTouchStick.is_touch_mode()` is true. Added for walk, spin, bets, items, item pickup, item wheel and guide.
- `item_wording_check.gd` also scans `touch_body`.

## Still open
- No on-screen pause button in the overworld. A phone player cannot open pause, Guide, Options or Save & Quit outside a fight.
- `guide_pages.gd` text still names keys.
- Test on a real phone (Android Chrome, iPhone Safari), including first-tap audio.
