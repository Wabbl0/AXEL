extends RefCounted
class_name VisualStyleVariantMatrix
## Canonical variant list for Scene 1.1 style comparison sweeps.
## IDs and filenames are stable; do not rename without updating capture tooling.

const SCENE_PATH := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const OUTPUT_DIR := "user://style_sweep_1_1"

const VARIANTS: Array[Dictionary] = [
	{
		"id": "baseline",
		"label": "Baseline (noir + scanline)",
		"png": "01_baseline.png",
		"stack": "baseline",
		"shader": "",
	},
	{
		"id": "A_crt_plugin",
		"label": "Option A — CRT plugin (curvature + mask)",
		"png": "02_A_crt_plugin.png",
		"stack": "stack",
		"shader": "res://scenes/fx/crt_plugin_overlay.gdshader",
	},
	{
		"id": "B_vhs",
		"label": "Option B — GodotRetro VHS",
		"png": "03_B_vhs.png",
		"stack": "stack",
		"shader": "res://test/visual_style/shaders/option_b_vhs.gdshader",
	},
	{
		"id": "C1_poster_dither",
		"label": "Option C1 — Posterize + dither",
		"png": "04_C1_poster_dither.png",
		"stack": "replace_noir",
		"shader": "res://test/visual_style/shaders/option_c1_poster_dither.gdshader",
	},
	{
		"id": "C2_bayer_reduce",
		"label": "Option C2 — Bayer + palette reduce",
		"png": "05_C2_bayer_reduce.png",
		"stack": "replace_noir",
		"shader": "res://test/visual_style/shaders/option_c2_bayer_reduce.gdshader",
	},
	{
		"id": "C3_oklab_snap",
		"label": "Option C3 — Oklab palette snap",
		"png": "06_C3_oklab_snap.png",
		"stack": "replace_noir",
		"shader": "res://test/visual_style/shaders/option_c3_oklab_snap.gdshader",
	},
	{
		"id": "C4_vespera",
		"label": "Option C4 — VesperaFX-style modular",
		"png": "07_C4_vespera.png",
		"stack": "replace_noir",
		"shader": "res://test/visual_style/shaders/option_c4_vespera.gdshader",
	},
	{
		"id": "D_crt_display",
		"label": "Option D — CRT display (mask + glow)",
		"png": "08_D_crt_display.png",
		"stack": "stack",
		"shader": "res://test/visual_style/shaders/option_d_crt_display.gdshader",
	},
	{
		"id": "E_crt_luminance",
		"label": "Option E — CRT luminance-preserving",
		"png": "09_E_crt_luminance.png",
		"stack": "stack",
		"shader": "res://test/visual_style/shaders/option_e_crt_luminance.gdshader",
	},
]


static func variant_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for v in VARIANTS:
		ids.append(String(v["id"]))
	return ids


static func find_by_id(variant_id: String) -> Dictionary:
	for v in VARIANTS:
		if String(v["id"]) == variant_id:
			return v
	return {}


static func expected_png_count() -> int:
	return VARIANTS.size()
