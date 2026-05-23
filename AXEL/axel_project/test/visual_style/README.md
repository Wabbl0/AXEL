# Scene 1.1 Visual Style Sweep

Deterministic screenshot pass for `1.1_SchoolExterior` across baseline and all options in `plans/references/VISUAL_STYLE_OPTIONS.md`.

## Variants

| ID | Output PNG |
|----|------------|
| `baseline` | `01_baseline.png` |
| `A_crt_plugin` | `02_A_crt_plugin.png` |
| `B_vhs` | `03_B_vhs.png` |
| `C1_poster_dither` | `04_C1_poster_dither.png` |
| `C2_bayer_reduce` | `05_C2_bayer_reduce.png` |
| `C3_oklab_snap` | `06_C3_oklab_snap.png` |
| `C4_vespera` | `07_C4_vespera.png` |
| `D_crt_display` | `08_D_crt_display.png` |
| `E_crt_luminance` | `09_E_crt_luminance.png` |

Test-only shaders live under `test/visual_style/shaders/` and do not replace production `scenes/fx/` assets.

## Run (repo root)

```powershell
tools\cmd\godot.cmd --path AXEL/axel_project -s res://test/visual_style/capture_scene_1_1_style_sweep.gd
```

Or:

```powershell
AXEL\axel_project\tools\visual_style\run_scene_1_1_style_sweep.ps1
```

Single variant:

```powershell
$env:AXEL_STYLE_VARIANT="baseline"
tools\cmd\godot.cmd --path AXEL/axel_project -s res://test/visual_style/capture_scene_1_1_style_sweep.gd
```

Output default: `user://style_sweep_1_1` (Godot userdata for project **AXEL**).
