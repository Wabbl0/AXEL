# Scene 1.1 Visual Style Sweep

Deterministic screenshot pass for `1.1_SchoolExterior` — baseline production stack vs scanline/glitch comparison options.

## Variants

| ID | Output PNG | Source |
|----|------------|--------|
| `baseline` | `01_baseline.png` | Production 8-band inverted noir + scanline + CRT |
| `option_1_crt_tv` | `02_option_1_crt_tv.png` | [Godot Asset Library CRT / nofacer](https://godotengine.org/asset-library/asset/4219) inspired |
| `option_2_vhs_glitch` | `03_option_2_vhs_glitch.png` | [Retro VHS Glitch for Godot 4 (MIT)](https://godotshaders.com/shader/retro-vhs-glitch-for-godot-4/) inspired |

`option_3_terminal_crt` was archived 2026-09-17 (look-dev only).

Most shaders here are look-dev only and do not replace production `scenes/fx/` assets. Exception: `noir_palette_8band_test.gdshader` is **production canon** overworld noir (wired by `AxelPostFxStack`). The old 3-band `scenes/fx/noir_palette_filter.gdshader` is retired.

## Theme modes (option shaders)

Set via variant metadata or env `AXEL_STYLE_THEME`:

| Value | Effect |
|-------|--------|
| `axel` | Pass-through (AXEL red/black noir stack) |
| `green` | Green phosphor / Pip-Boy tint |
| `white` | Mono white terminal tint |

## Run (repo root)

```powershell
tools\cmd\godot.cmd --path AXEL/axel_project -s res://tools/visual_style/capture_scene_1_1_style_sweep.gd
```

Or:

```powershell
AXEL\axel_project\tools\visual_style\run_scene_1_1_style_sweep.ps1
```

Single variant:

```powershell
$env:AXEL_STYLE_VARIANT="option_2_vhs_glitch"
tools\cmd\godot.cmd --path AXEL/axel_project -s res://tools/visual_style/capture_scene_1_1_style_sweep.gd
```

Green phosphor preview:

```powershell
$env:AXEL_STYLE_THEME="green"
tools\cmd\godot.cmd --path AXEL/axel_project -s res://tools/visual_style/capture_scene_1_1_style_sweep.gd
```

Output default: `user://style_sweep_1_1` (Godot userdata for project **AXEL**).
