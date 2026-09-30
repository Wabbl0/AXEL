# 2026-09-30 — Tutorial highlight: white, and skull stays visible

## Problem
- The "Fights" tutorial glow on the grid / winnings bar / skull showed black, not white.
- The skull vanished while `fight_spin` was open.

## Cause
- `piece_highlight_glow.gd` added a white copy of each art as a child on the HUD canvas. The HUD is under the noir filter (layer 90), which turns white into black.
- The glow shader filled the whole shape, and sat on top of the art. The skull got covered by a solid silhouette that the filter turned black.

## Fix
- The glow now lives on its own `HudHighlightLayer` CanvasLayer (layer 93): above noir (90) and the drop shadows (92), below scanline (105) and CRT (108). It follows each art's screen rect every frame, like `hud_drop_shadow.gd`.
- The shader repaints the art's own ink (the dark source pixels that noir turns red) in white, exactly on top of the art. The pulse fades it between red and white. It is not an outline or a halo, so it never lands on the drop shadows.
- Only the frame art glows for a `TextureRect` piece (`NEW_Grid`, whose art includes the winnings bar). For other pieces, every child `TextureRect` glows, except `Glow`, `DropShadow*` and `HighlightGlow*`. A glow hides while its art is hidden (for example the inactive `SkullStage`s).
- The `axel_tutorial.gd` API is unchanged.

## Files
- `combat/scripts/piece_highlight_glow.gd`
- `combat/shaders/piece_highlight_glow.gdshader`
- `tools/qa/tutorial_popup_check.gd` (new `_check_highlight_above_noir`)

## Verification
- All headless checks exited 0: tutorial popup, scaffold, determinism, powers, scene smoke, audio bus, settings, pause, and menu nav.
- A rendered 1920×1280 combat frame with `fight_spin` open shows the grid frame, cell lines, winnings bar and skull turned white, with the skull still visible.
