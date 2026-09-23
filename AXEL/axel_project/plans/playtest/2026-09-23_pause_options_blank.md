# Plan: Options page is blank from pause

Plan only. Do not implement in the planning chat.

## What you asked

In room 2.1, Options on the pause menu showed nothing.

## What the game does now

- `scenes/ui/pause_menu.gd` `_open_options` hides the button column and sets `_options.visible = true`.
- `scenes/ui/options_panel.gd` builds itself in `_ready`, while the pause layer is still hidden (`visible = false` is set before the panel is added). A control built at size 0 can stay at size 0 until something forces a layout.
- Opening Options then hides the only visible text. The dark scrim remains. That looks like nothing happened.
- Room 2.1 does not cover the pause layer (`PlayerLayer` is `100`, pause is `120`). The blank page is the same in every scene. 2.1 is where it was tried.

## Locked choices

- Options is the same panel as the title Options screen: audio, video, gameplay, accessibility, controls, Back.
- On open, give the panel the current window rectangle, re-apply slider widths, and scroll to the top.
- Back or Esc returns to the pause button list. It does not unpause.

## Steps

1. In `OptionsPanel`, add a `present()` method. It sets anchors to the full rect, sets size from `get_viewport().get_visible_rect().size`, calls `_apply_scale()`, and sets the scroll vertical value to `0`.
2. Call `present()` from `_open_options` after making the panel visible, then `MenuLook.grab_first_focus`.
3. If the panel’s size is still under 2 px, build the rows again after the size is known.
4. Add a headless check (pause contract or a small new script): pause in `1.2`, call `_open_options`, find a label whose text is `OPTIONS`, and fail if its rectangle width is under 40 px or it sits outside the window.

## What you should see

Options replaces the pause buttons with the OPTIONS page. Sliders and the Back button are readable. Back returns to Resume / Options / Map.

## How to test

1. Pause in room 2.1. Press Options. The settings page is on screen.
2. Press Back. The pause buttons return. The game stays paused.
3. Run the new check headless and expect exit 0.

## Risks

- Do not leave the button column hidden if the options panel fails to build.
- Slider width stays one third of the window (`_BAR_SCREEN_FRACTION`). Do not change that rule here.

## When this ships

One changelog line. Centering the pause menu is a separate note.
