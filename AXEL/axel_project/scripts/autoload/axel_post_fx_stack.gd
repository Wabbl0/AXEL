extends Node
## Global noir + scanline + CRT stack for all non-combat scenes.
## Combat scenes under res://combat/ are excluded (combat uses its own FX).

const NOIR_SCENE := "res://scenes/fx/NoirPaletteOverlay.tscn"
const SCANLINE_SCENE := "res://scenes/fx/ScanlineOverlay.tscn"
const CRT_SCENE := "res://scenes/fx/CrtPluginOverlay.tscn"
const MANAGED_GROUP := "axel_post_fx_managed"

const _OVERLAY_NAME_NOIR := "NoirPaletteOverlay"
const _OVERLAY_NAME_SCANLINE := "ScanlineOverlay"
const _OVERLAY_NAME_CRT := "CrtPluginOverlay"

var _attached_scene: Node = null
var _noir: CanvasLayer = null
var _scanline: CanvasLayer = null
var _crt: CanvasLayer = null


func _ready() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	call_deferred("_on_scene_changed")


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	_detach()
	if scene == null:
		return
	if _should_skip_post_fx(scene):
		return
	_attach_to_scene(scene)


func _should_skip_post_fx(scene: Node) -> bool:
	if is_combat_scene(scene):
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


func _detach() -> void:
	for layer: CanvasLayer in [_noir, _scanline, _crt]:
		if layer != null and is_instance_valid(layer) and not layer.is_queued_for_deletion():
			var parent := layer.get_parent()
			if parent != null:
				parent.remove_child(layer)
			layer.queue_free()
	_noir = null
	_scanline = null
	_crt = null
	_attached_scene = null


func _attach_to_scene(scene: Node) -> void:
	_remove_legacy_scene_overlays(scene)
	_noir = _instantiate_overlay(NOIR_SCENE) as CanvasLayer
	_scanline = _instantiate_overlay(SCANLINE_SCENE) as CanvasLayer
	_crt = _instantiate_overlay(CRT_SCENE) as CanvasLayer
	if _noir == null or _scanline == null or _crt == null:
		push_warning("AxelPostFxStack: failed to instantiate one or more overlay scenes.")
		_detach()
		return
	for layer: CanvasLayer in [_noir, _scanline, _crt]:
		layer.add_to_group(MANAGED_GROUP)
		scene.add_child(layer)
	_attached_scene = scene


func _remove_legacy_scene_overlays(scene: Node) -> void:
	for overlay_name in [_OVERLAY_NAME_NOIR, _OVERLAY_NAME_SCANLINE, _OVERLAY_NAME_CRT]:
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
