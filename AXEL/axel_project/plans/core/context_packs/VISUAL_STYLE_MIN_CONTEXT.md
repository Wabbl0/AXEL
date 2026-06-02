# Visual Style Min Context

**Prefix:** `vfx:` | **Unlock for:** combat, scenes, narrative

## Pointers (on demand)

`AI_DOCS.md` §6 · `AXEL_OVERWORLD_EVENT_FX.md` · `VISUAL_STYLE_OPTIONS.md` · `scripts/autoload/axel_post_fx_stack.gd` · `scripts/autoload/axel_event_fx.gd` · `scenes/fx/*` production shaders/overlays

## Invariants

- Palette: black + `#ff0000` + `#4a0000`; CRT/scanline/glitch = core identity
- `AxelPostFxStack`: noir + scanline + CRT on scene change; **exclude** `res://combat/*`
- Do not instance those three baseline overlays in overworld `.tscn`
- `AxelEventFx`: scene-transition glitch + event API + interface cadence; overlays owned by autoload (do not embed in `.tscn`)
- Glitch = discrete burst (`play_glitch_burst`); interface pulse = CRT cadence (`play_interface_pulse` / distortion API)
- Tests: `AXEL_DISABLE_POST_FX=1`, `AXEL_DISABLE_EVENT_FX=1`; `tools/visual_style/shaders/*` = candidates only

## Hard gates

- **Lock:** no combat RTP, `game.html` story, scene layout unless unlocked
