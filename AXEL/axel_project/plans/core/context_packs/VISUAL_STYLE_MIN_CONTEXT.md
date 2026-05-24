# Visual Style Min Context

**Prefix:** `vfx:` | **Unlock for:** combat, scenes, narrative

## Pointers (on demand)

`AI_DOCS.md` §6 · `VISUAL_STYLE_OPTIONS.md` · `scripts/autoload/axel_post_fx_stack.gd` · `scenes/fx/*` production shaders/overlays

## Invariants

- Palette: black + `#ff0000` + `#4a0000`; CRT/scanline/glitch = core identity
- `AxelPostFxStack`: noir + scanline + CRT on scene change; **exclude** `res://combat/*`
- Do not instance those three overlays in overworld `.tscn`
- Tests: `AXEL_DISABLE_POST_FX=1`; `tools/visual_style/shaders/*` = candidates only

## Hard gates

- **Lock:** no combat RTP, `game.html` story, scene layout unless unlocked
