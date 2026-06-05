@tool
class_name LeafOcclusionZone
extends Area2D

const MAX_SHADER_POINTS := 32

@export_range(0.0, 64.0, 0.5) var feather_px: float = 8.0:
	set(value):
		feather_px = maxf(value, 0.0)
		queue_redraw()

@export var polygon_node_path: NodePath = ^"CollisionPolygon2D"

@export_group("Editor Preview")
@export var show_editor_preview: bool = true
@export var editor_fill_color: Color = Color(0.2, 0.9, 0.35, 0.12)
@export var editor_line_color: Color = Color(0.2, 0.9, 0.35, 0.9)


func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint() or not show_editor_preview:
		return
	var local_points := _get_local_polygon_points()
	if local_points.size() < 3:
		return
	draw_colored_polygon(local_points, editor_fill_color)
	var closed := local_points.duplicate()
	closed.append(local_points[0])
	draw_polyline(closed, editor_line_color, false, 2.0)


func get_world_polygon() -> PackedVector2Array:
	var polygon_node := get_node_or_null(polygon_node_path) as CollisionPolygon2D
	if polygon_node == null or polygon_node.polygon.is_empty():
		return PackedVector2Array()
	var world_points := PackedVector2Array()
	world_points.resize(polygon_node.polygon.size())
	for i in polygon_node.polygon.size():
		world_points[i] = polygon_node.to_global(polygon_node.polygon[i])
	return world_points


func get_shader_polygon() -> PackedVector2Array:
	var world_points := get_world_polygon()
	if world_points.size() > MAX_SHADER_POINTS:
		push_warning(
			"%s polygon has %d points; only the first %d are sent to the leaf fade shader."
			% [name, world_points.size(), MAX_SHADER_POINTS]
		)
		return world_points.slice(0, MAX_SHADER_POINTS)
	return world_points


func _get_local_polygon_points() -> PackedVector2Array:
	var polygon_node := get_node_or_null(polygon_node_path) as CollisionPolygon2D
	if polygon_node == null or polygon_node.polygon.is_empty():
		return PackedVector2Array()
	var local_points := PackedVector2Array()
	local_points.resize(polygon_node.polygon.size())
	for i in polygon_node.polygon.size():
		local_points[i] = to_local(polygon_node.to_global(polygon_node.polygon[i]))
	return local_points
