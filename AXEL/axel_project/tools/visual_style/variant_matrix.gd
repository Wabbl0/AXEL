extends RefCounted
class_name VisualStyleVariantMatrix
## Canonical variant list for Scene 1.1 scanline/glitch comparison sweeps.
## IDs and filenames are stable; do not rename without updating capture tooling.

const SCENE_PATH := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const OUTPUT_DIR := "user://style_sweep_1_1"
const SHADER_ROOT := "res://tools/visual_style/shaders/"

## theme_mode shader uniform: 0=axel pass-through, 1=green phosphor, 2=mono white
const THEME_AXEL := 0
const THEME_GREEN := 1
const THEME_MONO_WHITE := 2

const VARIANTS: Array[Dictionary] = [
	{
		"id": "baseline",
		"label": "Baseline (noir + scanline + CRT stack)",
		"png": "01_baseline.png",
		"stack": "baseline",
		"shader": "",
		"theme_mode": THEME_AXEL,
		"theme_strength": 1.0,
	},
	{
		"id": "option_1_crt_tv",
		"label": "Option 1 — CRT TV (Asset Library / nofacer style)",
		"png": "02_option_1_crt_tv.png",
		"stack": "stack",
		"shader": SHADER_ROOT + "option_1_crt_tv.gdshader",
		"theme_mode": THEME_AXEL,
		"theme_strength": 1.0,
	},
	{
		"id": "option_2_vhs_glitch",
		"label": "Option 2 — VHS Glitch Burst (godotshaders MIT)",
		"png": "03_option_2_vhs_glitch.png",
		"stack": "stack",
		"shader": SHADER_ROOT + "option_2_vhs_glitch.gdshader",
		"theme_mode": THEME_AXEL,
		"theme_strength": 1.0,
	},
	{
		"id": "option_3_terminal_crt",
		"label": "Option 3 — Terminal CRT (luminance-preserving)",
		"png": "04_option_3_terminal_crt.png",
		"stack": "stack",
		"shader": SHADER_ROOT + "option_3_terminal_crt.gdshader",
		"theme_mode": THEME_AXEL,
		"theme_strength": 1.0,
	},
]


static func theme_mode_from_env(default_mode: int) -> int:
	if not OS.has_environment("AXEL_STYLE_THEME"):
		return default_mode
	var raw := OS.get_environment("AXEL_STYLE_THEME").strip_edges().to_lower()
	match raw:
		"green", "green_phosphor", "pip_boy", "pip-boy":
			return THEME_GREEN
		"white", "mono_white", "mono":
			return THEME_MONO_WHITE
		"axel", "red_black", "red-black":
			return THEME_AXEL
		_:
			if raw.is_valid_int():
				return int(raw)
			return default_mode


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
