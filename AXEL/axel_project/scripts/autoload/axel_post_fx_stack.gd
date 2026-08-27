extends Node
## Global noir + scanline + CRT stack for all non-combat scenes.
## Combat scenes under res://combat/ are excluded unless COMBAT_ROOM_FX_TEST is on.

const NOIR_SCENE := "res://scenes/fx/NoirPaletteOverlay.tscn"
const SCANLINE_SCENE := "res://scenes/fx/ScanlineOverlay.tscn"
const CRT_SCENE := "res://scenes/fx/CrtPluginOverlay.tscn"
## Flat CRT for combat (same shader, zero curve/vignette/rim) — edge-fringe fix without TV glass.
const CRT_COMBAT_SCENE := "res://scenes/fx/CrtCombatOverlay.tscn"
const MANAGED_GROUP := "axel_post_fx_managed"
## Test-only 8-band palette. Production overlay scene stays on the 3-band shader.
const NOIR_8BAND_SHADER := "res://tools/visual_style/shaders/noir_palette_8band_test.gdshader"

## Flip to true, save, then F5/F6 any non-combat scene to preview 8-band noir.
## Or launch with env AXEL_NOIR_8BAND=1 (same effect; no file edit). Keep false for production 3-band.
const DEBUG_USE_NOIR_8BAND_TEST := true

## Temporary test: attach room noir/scanline/CRT on res://combat/* (not AI_DOCS canon).
## Flip false to restore combat's own ScanlineOverlay-only look.
const COMBAT_ROOM_FX_TEST := true

const _OVERLAY_NAME_NOIR := "NoirPaletteOverlay"
const _OVERLAY_NAME_SCANLINE := "ScanlineOverlay"
const _OVERLAY_NAME_CRT := "CrtPluginOverlay"
const _OVERLAY_NAME_CRT_COMBAT := "CrtCombatOverlay"

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
	if is_combat_scene(scene) and not COMBAT_ROOM_FX_TEST:
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
	for layer in [_noir, _scanline, _crt]:
		if layer == null or not is_instance_valid(layer):
			return false
		if layer.get_parent() != scene:
			return false
	return true


## Re-attach when scene_changed aborted or overlays were detached without a successful attach.
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
	var crt_path := CRT_COMBAT_SCENE if is_combat_scene(scene) else CRT_SCENE
	_crt = _instantiate_overlay(crt_path) as CanvasLayer
	if _noir == null or _scanline == null or _crt == null:
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


## For headless tests that instantiate scenes without scene_changed.
func apply_to_scene(scene: Node) -> void:
	if scene == null:
		return
	_detach()
	if _should_skip_post_fx(scene):
		return
	_attach_to_scene(scene)


func get_noir_filter_rect() -> ColorRect:
	if _noir != null and is_instance_valid(_noir):
		return _noir.get_node_or_null("FilterRect") as ColorRect
	return null
