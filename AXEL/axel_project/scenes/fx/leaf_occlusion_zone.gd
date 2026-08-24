@tool
class_name LeafOcclusionZone
extends Area2D

const MAX_SHADER_POINTS := 64
const MAX_SHADER_PARTS := 4

@export_range(0.0, 64.0, 0.5) var feather_px: float = 2.0:
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
	for local_points in _get_all_local_polygon_points():
		if local_points.size() < 3:
			continue
		draw_colored_polygon(local_points, editor_fill_color)
		var closed := local_points.duplicate()
		closed.append(local_points[0])
		draw_polyline(closed, editor_line_color, false, 2.0)


func get_collision_polygon_nodes() -> Array[CollisionPolygon2D]:
	var nodes: Array[CollisionPolygon2D] = []
	for child in get_children():
		var polygon_node := child as CollisionPolygon2D
		if polygon_node == null or polygon_node.polygon.is_empty():
			continue
		nodes.append(polygon_node)
	if nodes.is_empty():
		var fallback := get_node_or_null(polygon_node_path) as CollisionPolygon2D
		if fallback != null and not fallback.polygon.is_empty():
			nodes.append(fallback)
	return nodes


func get_world_polygon() -> PackedVector2Array:
	var polys := get_shader_polygons()
	if polys.is_empty():
		return PackedVector2Array()
	return polys[0]


func get_shader_polygons() -> Array[PackedVector2Array]:
	var polys: Array[PackedVector2Array] = []
	for polygon_node in get_collision_polygon_nodes():
		polys.append(_world_points_of(polygon_node))
	return polys


func get_shader_polygon() -> PackedVector2Array:
	var polys := get_shader_polygons()
	if polys.is_empty():
		return PackedVector2Array()
	return polys[0]


func get_packed_shader_points() -> PackedVector2Array:
	var packed := PackedVector2Array()
	var part_i := 0
	for poly in get_shader_polygons():
		if part_i >= MAX_SHADER_PARTS:
			push_warning(
				"%s has more than %d CollisionPolygon2D children; extra polygons are ignored."
				% [name, MAX_SHADER_PARTS]
			)
			break
		if packed.size() + poly.size() > MAX_SHADER_POINTS:
			push_warning(
				"%s behind polygons exceed %d shader points; extra verts are ignored."
				% [name, MAX_SHADER_POINTS]
			)
			break
		if poly.size() < 3:
			continue
		packed.append_array(poly)
		part_i += 1
	return packed


func get_packed_part_counts() -> Vector4i:
	var counts := Vector4i.ZERO
	var used := 0
	var part_i := 0
	for poly in get_shader_polygons():
		if part_i >= MAX_SHADER_PARTS:
			push_warning(
				"%s has more than %d CollisionPolygon2D children; extra polygons are ignored."
				% [name, MAX_SHADER_PARTS]
			)
			break
		if used + poly.size() > MAX_SHADER_POINTS:
			break
		if poly.size() < 3:
			continue
		match part_i:
			0:
				counts.x = poly.size()
			1:
				counts.y = poly.size()
			2:
				counts.z = poly.size()
			3:
				counts.w = poly.size()
		used += poly.size()
		part_i += 1
	return counts


func _world_points_of(polygon_node: CollisionPolygon2D) -> PackedVector2Array:
	var world_points := PackedVector2Array()
	world_points.resize(polygon_node.polygon.size())
	for i in polygon_node.polygon.size():
		world_points[i] = polygon_node.to_global(polygon_node.polygon[i])
	return world_points


func _get_all_local_polygon_points() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for polygon_node in get_collision_polygon_nodes():
		var local_points := PackedVector2Array()
		local_points.resize(polygon_node.polygon.size())
		for i in polygon_node.polygon.size():
			local_points[i] = to_local(polygon_node.to_global(polygon_node.polygon[i]))
		result.append(local_points)
	return result
