extends Polygon2D

const ABOVE_NOIR_LAYER := 100
const HOVER_TINT := Color(1, 0, 0, 0.22)

var _lift: CanvasLayer
var _view: Polygon2D
var _tint: Polygon2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	visible = false
	call_deferred("_lift_above_noir")


func set_paper_hovered(hovered: bool) -> void:
	if _tint != null:
		_tint.visible = hovered


func _lift_above_noir() -> void:
	_lift = CanvasLayer.new()
	_lift.name = "LockerMapAboveNoir"
	_lift.layer = ABOVE_NOIR_LAYER
	_host().add_child(_lift)
	_view = Polygon2D.new()
	_view.texture = texture
	_view.texture_filter = texture_filter
	_view.polygon = polygon
	_view.uv = uv
	_view.color = color
	_lift.add_child(_view)
	_tint = Polygon2D.new()
	_tint.color = HOVER_TINT
	_tint.polygon = polygon
	_tint.visible = false
	_lift.add_child(_tint)
	var shelves := get_parent().get_parent()
	if shelves != null and shelves.has_signal("resized"):
		shelves.resized.connect(_sync_view, CONNECT_DEFERRED)
	get_viewport().size_changed.connect(_sync_view, CONNECT_DEFERRED)
	_sync_view()
	await get_tree().process_frame
	_sync_view()


func _host() -> Node:
	var node: Node = self
	while node.get_parent() != null and node.get_parent() != get_tree().root:
		node = node.get_parent()
	return node


func _process(_delta: float) -> void:
	_sync_view()


func _sync_view() -> void:
	if _view == null:
		return
	_view.global_transform = global_transform
	_tint.polygon = polygon
	_tint.global_transform = global_transform
