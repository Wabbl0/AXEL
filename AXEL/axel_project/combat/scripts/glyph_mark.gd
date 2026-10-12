extends Control

const FILL_COLOR := Color(0.55, 0.02, 0.02, 1.0)
const EDGE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const EDGE_PX := 1.5
const INSET_PX := 4.0
const SIZE_SHARE := 0.13
const SIZE_MIN := 12.0
const SIZE_MAX := 30.0

var text := "":
	set(value):
		text = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func mark_rect() -> Rect2:
	var side := clampf(minf(size.x, size.y) * SIZE_SHARE, SIZE_MIN, SIZE_MAX)
	var pad := INSET_PX + EDGE_PX
	return Rect2(Vector2(pad, size.y - pad - side), Vector2(side, side))


func _draw() -> void:
	if text.is_empty():
		return
	var box := mark_rect()
	match text:
		"◇":
			_ring(_diamond(box, 1.0), box.size.x * 0.16)
		"◈":
			_ring(_diamond(box, 1.0), box.size.x * 0.13)
			_solid(_diamond(box, 0.38))
		"◆":
			_solid(_diamond(box, 1.0))
		"★":
			_solid(_star(box, 5, 0.42, -PI * 0.5))
		"✦":
			_solid(_star(box, 4, 0.3, -PI * 0.5))
		_:
			_solid(_diamond(box, 1.0))


func _diamond(box: Rect2, share: float) -> PackedVector2Array:
	var c := box.get_center()
	var r := box.size * 0.5 * share
	return PackedVector2Array([
		c + Vector2(0.0, -r.y), c + Vector2(r.x, 0.0), c + Vector2(0.0, r.y), c + Vector2(-r.x, 0.0)
	])


func _star(box: Rect2, points: int, inner: float, start: float) -> PackedVector2Array:
	var c := box.get_center()
	var r := box.size.x * 0.5
	var out := PackedVector2Array()
	for i in points * 2:
		var ang := start + float(i) * PI / float(points)
		var reach := r if i % 2 == 0 else r * inner
		out.append(c + Vector2(cos(ang), sin(ang)) * reach)
	return out


func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var loop := pts.duplicate()
	loop.append(pts[0])
	return loop


func _solid(pts: PackedVector2Array) -> void:
	draw_polyline(_closed(pts), EDGE_COLOR, EDGE_PX * 2.0, true)
	draw_colored_polygon(pts, FILL_COLOR)


func _ring(pts: PackedVector2Array, width: float) -> void:
	var loop := _closed(pts)
	draw_polyline(loop, EDGE_COLOR, width + EDGE_PX * 2.0, true)
	draw_polyline(loop, FILL_COLOR, width, true)
