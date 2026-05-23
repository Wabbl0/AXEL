extends RefCounted
class_name StyleOverlayApplier
## Applies test-only post overlays to a loaded 1.1 scene without mutating baseline assets.

const _NOIR_SCENE := "res://scenes/fx/NoirPaletteOverlay.tscn"
const _SCANLINE_SCENE := "res://scenes/fx/ScanlineOverlay.tscn"
const _CRT_SCENE := "res://scenes/fx/CrtPluginOverlay.tscn"
const _NOIR_SHADER := "res://scenes/fx/noir_palette_filter.gdshader"
const _TAG_ROOT := "StyleSweepOverlays"

var _root: Node
var _overlay_root: Node2D


func _init(scene_root: Node) -> void:
	_root = scene_root
	_overlay_root = Node2D.new()
	_overlay_root.name = _TAG_ROOT
	_root.add_child(_overlay_root)


func clear_all() -> void:
	for child in _overlay_root.get_children():
		child.queue_free()
	var owned_noir := _root.get_node_or_null("NoirPaletteOverlay") as CanvasLayer
	if owned_noir != null:
		owned_noir.visible = false
	var owned_scanline := _root.get_node_or_null("ScanlineOverlay") as CanvasLayer
	if owned_scanline != null:
		owned_scanline.visible = false
	var owned_crt := _root.get_node_or_null("CrtPluginOverlay") as CanvasLayer
	if owned_crt != null:
		owned_crt.visible = false


func apply_variant(spec: Dictionary) -> void:
	clear_all()
	var stack := String(spec.get("stack", ""))
	var shader_path := String(spec.get("shader", ""))
	var theme_mode := VisualStyleVariantMatrix.theme_mode_from_env(int(spec.get("theme_mode", 0)))
	var theme_strength := float(spec.get("theme_strength", 1.0))

	match stack:
		"baseline":
			_enable_scene_noir(true)
			_add_packed_overlay(_SCANLINE_SCENE, 105)
			_add_packed_overlay(_CRT_SCENE, 108)
		"stack":
			_enable_scene_noir(true)
			_add_packed_overlay(_SCANLINE_SCENE, 105)
			if not shader_path.is_empty():
				_add_shader_overlay(shader_path, 110, "OptionOverlay", theme_mode, theme_strength)
		"replace_noir":
			_enable_scene_noir(false)
			if not shader_path.is_empty():
				_add_shader_overlay(shader_path, 90, "ReplaceNoirOverlay", theme_mode, theme_strength)
		_:
			push_warning("StyleOverlayApplier: unknown stack mode '%s'" % stack)


func _enable_scene_noir(enabled: bool) -> void:
	var noir := _root.get_node_or_null("NoirPaletteOverlay") as CanvasLayer
	if noir == null:
		_add_packed_overlay(_NOIR_SCENE, 90)
		noir = _overlay_root.get_node_or_null("NoirPaletteOverlay") as CanvasLayer
	if noir == null:
		return
	noir.visible = enabled
	if not enabled:
		return
	var rect := noir.get_node_or_null("FilterRect") as ColorRect
	if rect == null:
		rect = noir.get_node_or_null("ScanlineRect") as ColorRect
	if rect == null:
		return
	var mat := rect.material as ShaderMaterial
	if mat == null:
		var sh := load(_NOIR_SHADER) as Shader
		if sh != null:
			mat = ShaderMaterial.new()
			mat.shader = sh
			rect.material = mat


func _add_packed_overlay(packed_path: String, layer: int) -> void:
	if not ResourceLoader.exists(packed_path):
		push_warning("StyleOverlayApplier: missing overlay scene %s" % packed_path)
		return
	var inst := (load(packed_path) as PackedScene).instantiate()
	if inst is CanvasLayer:
		(inst as CanvasLayer).layer = layer
	_overlay_root.add_child(inst)


func _add_shader_overlay(
	shader_path: String,
	layer: int,
	node_name: String,
	theme_mode: int,
	theme_strength: float
) -> void:
	if not ResourceLoader.exists(shader_path):
		push_warning("StyleOverlayApplier: missing shader %s" % shader_path)
		return
	var sh := load(shader_path) as Shader
	if sh == null:
		return
	var canvas := CanvasLayer.new()
	canvas.name = node_name
	canvas.layer = layer
	var rect := ColorRect.new()
	rect.name = "FilterRect"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("theme_mode", theme_mode)
	mat.set_shader_parameter("theme_strength", theme_strength)
	rect.material = mat
	canvas.add_child(rect)
	_overlay_root.add_child(canvas)
