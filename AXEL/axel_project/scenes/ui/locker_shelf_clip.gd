@tool
class_name LockerShelfClip
extends Sprite2D


const FEATHER_PX := 1.0
const MAX_POINTS := 16
const SHADER := preload("res://scenes/ui/shelf_clip.gdshader")

var _sig := ""


func _ready() -> void:
	_push_clip()
	if Engine.is_editor_hint():
		set_process(true)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	var sig := _polygon_signature()
	if sig == _sig:
		return
	_sig = sig
	_push_clip()
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var poly := _polygon_node()
	if poly == null or poly.polygon.size() < 3:
		return
	var pts := _local_points(poly)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color(0.2, 0.95, 0.45, 0.95), 1.5, true)


func _polygon_node() -> CollisionPolygon2D:
	return get_node_or_null("ClipPolygon") as CollisionPolygon2D


func _polygon_signature() -> String:
	var poly := _polygon_node()
	if poly == null:
		return ""
	return "%s|%s|%s|%s" % [poly.polygon, poly.position, poly.rotation, poly.scale]


func _ensure_material() -> ShaderMaterial:
	var current := material as ShaderMaterial
	if current != null and current.shader == SHADER:
		return current
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	material = mat
	return mat


func _local_points(poly: CollisionPolygon2D) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := mini(poly.polygon.size(), MAX_POINTS)
	pts.resize(n)
	for i in n:
		pts[i] = to_local(poly.to_global(poly.polygon[i]))
	return pts


func _push_clip() -> void:
	var mat := _ensure_material()
	var packed := PackedVector2Array()
	packed.resize(MAX_POINTS)
	var count := 0
	var poly := _polygon_node()
	if poly != null:
		var pts := _local_points(poly)
		count = pts.size()
		for i in count:
			packed[i] = pts[i]
	mat.set_shader_parameter("clip_points", packed)
	mat.set_shader_parameter("clip_count", count)
	mat.set_shader_parameter("feather_px", FEATHER_PX)
