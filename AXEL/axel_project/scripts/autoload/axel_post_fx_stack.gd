extends Node

const NOIR_SCENE := "res://scenes/fx/NoirPaletteOverlay.tscn"
const SCANLINE_SCENE := "res://scenes/fx/ScanlineOverlay.tscn"
const CRT_SCENE := "res://scenes/fx/CrtPluginOverlay.tscn"
const CRT_COMBAT_SCENE := "res://scenes/fx/CrtCombatOverlay.tscn"
const MANAGED_GROUP := "axel_post_fx_managed"
const NOIR_8BAND_SHADER := "res://tools/visual_style/shaders/noir_palette_8band_test.gdshader"

const DEBUG_USE_NOIR_8BAND_TEST := true

const COMBAT_ROOM_FX_TEST := true

const _OVERLAY_NAME_NOIR := "NoirPaletteOverlay"
const _OVERLAY_NAME_SCANLINE := "ScanlineOverlay"
const _OVERLAY_NAME_CRT := "CrtPluginOverlay"
const _OVERLAY_NAME_CRT_COMBAT := "CrtCombatOverlay"

const EDGE_START_PX := 3.0
const EDGE_SPAN_PX := 40.0
const EDGE_OPACITY := 0.8

var _attached_scene: Node = null
var _noir: CanvasLayer = null
var _scanline: CanvasLayer = null
var _crt: CanvasLayer = null
var _logged_8band := false


func _ready() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	var settings := get_node_or_null("/root/AxelSettings")
	if settings != null and settings.has_signal("setting_changed"):
		settings.setting_changed.connect(_on_setting_changed)
	process_priority = -128
	set_process(true)
	call_deferred("_on_scene_changed")


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	var old_noir := _noir
	var old_scanline := _scanline
	var old_crt := _crt
	_noir = null
	_scanline = null
	_crt = null
	_attached_scene = null

	if scene == null:
		_free_overlay(old_noir)
		_free_overlay(old_scanline)
		_free_overlay(old_crt)
		call_deferred("ensure_attached_to_current_scene")
		return

	if _should_skip_post_fx(scene):
		_free_overlay(old_noir)
		_free_overlay(old_scanline)
		_free_overlay(old_crt)
		call_deferred("ensure_attached_to_current_scene")
		return

	_attach_to_scene(scene)
	_free_overlay(old_noir)
	_free_overlay(old_scanline)
	_free_overlay(old_crt)
	call_deferred("ensure_attached_to_current_scene")


func _should_skip_post_fx(scene: Node) -> bool:
	if is_combat_scene(scene) and not _combat_room_fx_test():
		return true
	if OS.has_environment("AXEL_DISABLE_POST_FX") and OS.get_environment("AXEL_DISABLE_POST_FX") == "1":
		return true
	if scene.get_node_or_null("StyleSweepOverlays") != null:
		return true
	return false


static func is_combat_scene(scene: Node) -> bool:
	if scene == null:
		return false
	var path := scene.scene_file_path
	return not path.is_empty() and path.begins_with("res://combat/")


func _overlays_attached_to(scene: Node) -> bool:
	if not is_instance_valid(scene):
		return false
	for layer in [_noir, _scanline]:
		if layer == null or not is_instance_valid(layer):
			return false
		if layer.get_parent() != scene:
			return false
	var crt_on := true
	var settings := get_node_or_null("/root/AxelSettings")
	if settings != null:
		crt_on = bool(settings.call("get_value", "video", "crt_enabled", true))
	if crt_on:
		if _crt == null or not is_instance_valid(_crt) or _crt.get_parent() != scene:
			return false
	return true


func _on_setting_changed(section: String, key: String) -> void:
	if section == "video" and key in ["crt_enabled", "graphics_quality"]:
		_on_scene_changed()


func ensure_attached_to_current_scene() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var scene := tree.current_scene
	if scene == null:
		return
	if _should_skip_post_fx(scene):
		return
	if _overlays_attached_to(scene):
		return
	apply_to_scene(scene)


func _detach() -> void:
	_free_overlay(_noir)
	_free_overlay(_scanline)
	_free_overlay(_crt)
	_noir = null
	_scanline = null
	_crt = null
	_attached_scene = null


func _free_overlay(layer) -> void:
	if layer == null or not is_instance_valid(layer) or layer.is_queued_for_deletion():
		return
	var canvas_layer := layer as CanvasLayer
	if canvas_layer == null:
		return
	var parent := canvas_layer.get_parent()
	if parent != null and is_instance_valid(parent):
		parent.remove_child(canvas_layer)
	canvas_layer.queue_free()


func _attach_to_scene(scene: Node) -> void:
	_remove_legacy_scene_overlays(scene)
	_noir = _instantiate_overlay(NOIR_SCENE) as CanvasLayer
	_scanline = _instantiate_overlay(SCANLINE_SCENE) as CanvasLayer
	var crt_on := true
	var settings := get_node_or_null("/root/AxelSettings")
	if settings != null:
		crt_on = bool(settings.call("get_value", "video", "crt_enabled", true))
	if crt_on:
		var crt_path := CRT_COMBAT_SCENE if is_combat_scene(scene) else CRT_SCENE
		_crt = _instantiate_overlay(crt_path) as CanvasLayer
	if _noir == null or _scanline == null or (crt_on and _crt == null):
		push_warning("AxelPostFxStack: failed to instantiate one or more overlay scenes.")
		_noir = null
		_scanline = null
		_crt = null
		_attached_scene = null
		return
	for layer in [_noir, _scanline, _crt]:
		if not is_instance_valid(layer):
			continue
		var canvas_layer := layer as CanvasLayer
		if canvas_layer == null:
			continue
		canvas_layer.add_to_group(MANAGED_GROUP)
		scene.add_child(canvas_layer)
	_attached_scene = scene
	if _use_noir_8band_test():
		_apply_noir_8band_shader()
	_apply_graphics_quality()


func _combat_room_fx_test() -> bool:
	if OS.get_environment("COMBAT_ROOM_FX_TEST").strip_edges() == "1":
		return true
	return COMBAT_ROOM_FX_TEST


func _use_noir_8band_test() -> bool:
	if OS.has_environment("AXEL_NOIR_8BAND") and OS.get_environment("AXEL_NOIR_8BAND").strip_edges() == "1":
		return true
	return DEBUG_USE_NOIR_8BAND_TEST


func _apply_noir_8band_shader() -> void:
	var rect := get_noir_filter_rect()
	if rect == null:
		return
	if not ResourceLoader.exists(NOIR_8BAND_SHADER):
		push_warning("AxelPostFxStack: missing 8-band shader %s" % NOIR_8BAND_SHADER)
		return
	var sh := load(NOIR_8BAND_SHADER) as Shader
	if sh == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = sh
	rect.material = mat
	if not _logged_8band:
		_logged_8band = true
		print("AxelPostFxStack: noir 8-band TEST on (DEBUG_USE_NOIR_8BAND_TEST or AXEL_NOIR_8BAND=1)")


func _remove_legacy_scene_overlays(scene: Node) -> void:
	for overlay_name in [_OVERLAY_NAME_NOIR, _OVERLAY_NAME_SCANLINE, _OVERLAY_NAME_CRT, _OVERLAY_NAME_CRT_COMBAT]:
		var existing := scene.get_node_or_null(overlay_name)
		if existing != null and not existing.is_in_group(MANAGED_GROUP):
			existing.queue_free()


func _instantiate_overlay(packed_path: String) -> Node:
	if not ResourceLoader.exists(packed_path):
		push_warning("AxelPostFxStack: missing overlay scene %s" % packed_path)
		return null
	var packed := load(packed_path) as PackedScene
	if packed == null:
		return null
	return packed.instantiate()


func apply_to_scene(scene: Node) -> void:
	if scene == null:
		return
	_detach()
	if _should_skip_post_fx(scene):
		return
	_attach_to_scene(scene)


func _process(_delta: float) -> void:
	_apply_texture_edge()


func _apply_texture_edge() -> void:
	if _attached_scene == null or not is_instance_valid(_attached_scene):
		return
	if is_combat_scene(_attached_scene):
		return
	var bounds := _background_screen_bounds()
	_set_texture_edge_shader(bounds)


func _find_background() -> CanvasItem:
	var camera := _attached_scene.get_node_or_null("Camera2D")
	if camera != null and camera.get("background_path") != null:
		var path := camera.get("background_path") as NodePath
		if path != null and not path.is_empty():
			var from_camera := camera.get_node_or_null(path) as CanvasItem
			if from_camera != null:
				return from_camera
	for candidate in ["WalkableWorld/Background", "Background", "Background_1_1"]:
		var node := _attached_scene.get_node_or_null(candidate) as CanvasItem
		if node != null:
			return node
	return null


func _background_screen_bounds() -> Rect2:
	var item := _find_background()
	if item == null:
		return Rect2()
	if item is Sprite2D:
		var sprite := item as Sprite2D
		if sprite.texture == null:
			return Rect2()
		var local := sprite.get_rect()
		if local.size.x <= 1.0 or local.size.y <= 1.0:
			return Rect2()
		var xf := sprite.get_global_transform_with_canvas()
		var p0 := xf * local.position
		var p1 := xf * Vector2(local.position.x + local.size.x, local.position.y)
		var p2 := xf * (local.position + local.size)
		var p3 := xf * Vector2(local.position.x, local.position.y + local.size.y)
		var min_x := minf(minf(p0.x, p1.x), minf(p2.x, p3.x))
		var min_y := minf(minf(p0.y, p1.y), minf(p2.y, p3.y))
		var max_x := maxf(maxf(p0.x, p1.x), maxf(p2.x, p3.x))
		var max_y := maxf(maxf(p0.y, p1.y), maxf(p2.y, p3.y))
		return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
	if item is Control:
		var rect := (item as Control).get_global_rect()
		if rect.size.x <= 1.0 or rect.size.y <= 1.0:
			return Rect2()
		return rect
	return Rect2()


func _set_texture_edge_shader(bounds: Rect2) -> void:
	if _crt == null or not is_instance_valid(_crt):
		return
	var crt_rect := _crt.get_node_or_null("FilterRect") as ColorRect
	if crt_rect == null or not (crt_rect.material is ShaderMaterial):
		return
	var crt_mat := crt_rect.material as ShaderMaterial
	_apply_overworld_edge_rim(crt_mat, false)
	if bounds.size.x <= 1.0 or bounds.size.y <= 1.0:
		crt_mat.set_shader_parameter("texture_bounds_px", Vector4.ZERO)
		return
	crt_mat.set_shader_parameter(
		"texture_bounds_px",
		Vector4(bounds.position.x, bounds.position.y, bounds.end.x, bounds.end.y)
	)


func _apply_overworld_edge_rim(crt_mat: ShaderMaterial, combat: bool) -> void:
	if combat:
		return

	crt_mat.set_shader_parameter("curvature", 0.0)
	crt_mat.set_shader_parameter("mirror_edges", 0.0)
	crt_mat.set_shader_parameter("vignette", 0.0)
	crt_mat.set_shader_parameter("edge_fade_px", 0.0)
	crt_mat.set_shader_parameter("corner_darkness", 0.0)
	crt_mat.set_shader_parameter("edge_start_px", EDGE_START_PX)
	crt_mat.set_shader_parameter("edge_span_px", EDGE_SPAN_PX)
	crt_mat.set_shader_parameter("edge_opacity", EDGE_OPACITY)


func get_noir_filter_rect() -> ColorRect:
	if _noir != null and is_instance_valid(_noir):
		return _noir.get_node_or_null("FilterRect") as ColorRect
	return null


func _apply_graphics_quality() -> void:
	var settings := get_node_or_null("/root/AxelSettings")
	var quality := "high"
	if settings != null:
		quality = String(settings.call("get_value", "video", "graphics_quality", "high")).to_lower()
	var scan := _scanline.get_node_or_null("ScanlineRect") as ColorRect if _scanline != null else null
	if scan != null and scan.material is ShaderMaterial:
		var mat := scan.material as ShaderMaterial
		match quality:
			"low":
				mat.set_shader_parameter("blend_opacity", 0.08)
				mat.set_shader_parameter("noise_intensity", 0.008)
				mat.set_shader_parameter("flicker_strength", 0.0)
				mat.set_shader_parameter("scan_density", 160.0)
			"medium":
				mat.set_shader_parameter("blend_opacity", 0.16)
				mat.set_shader_parameter("noise_intensity", 0.02)
				mat.set_shader_parameter("flicker_strength", 0.004)
				mat.set_shader_parameter("scan_density", 240.0)
			_:
				mat.set_shader_parameter("blend_opacity", 0.22)
				mat.set_shader_parameter("noise_intensity", 0.04)
				mat.set_shader_parameter("flicker_strength", 0.008)
				mat.set_shader_parameter("scan_density", 300.0)
	var crt_rect: ColorRect = null
	if _crt != null:
		crt_rect = _crt.get_node_or_null("FilterRect") as ColorRect
	if crt_rect != null and crt_rect.material is ShaderMaterial:

		crt_rect.material = (crt_rect.material as ShaderMaterial).duplicate()
		var crt_mat := crt_rect.material as ShaderMaterial
		var combat := is_combat_scene(_attached_scene)
		match quality:
			"low":
				crt_mat.set_shader_parameter("curvature", 0.0 if combat else 0.04)
				crt_mat.set_shader_parameter("chroma", 0.0)
				crt_mat.set_shader_parameter("scanline_strength", 0.04)
				crt_mat.set_shader_parameter("mask_strength", 0.12)
				crt_mat.set_shader_parameter("vignette", 0.0 if combat else 0.2)
			"medium":
				crt_mat.set_shader_parameter("curvature", 0.0 if combat else 0.1)
				crt_mat.set_shader_parameter("chroma", 0.0006)
				crt_mat.set_shader_parameter("scanline_strength", 0.08)
				crt_mat.set_shader_parameter("mask_strength", 0.22)
				crt_mat.set_shader_parameter("vignette", 0.0 if combat else 0.32)
			_:
				crt_mat.set_shader_parameter("curvature", 0.0 if combat else 0.16)
				crt_mat.set_shader_parameter("chroma", 0.001)
				crt_mat.set_shader_parameter("scanline_strength", 0.12)
				crt_mat.set_shader_parameter("mask_strength", 0.35)
				crt_mat.set_shader_parameter("vignette", 0.0 if combat else 0.45)
		_apply_overworld_edge_rim(crt_mat, combat)
