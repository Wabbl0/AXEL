extends Control

const VT323_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const FILL_COLOR := Color(0.55, 0.02, 0.02, 1.0)
const EDGE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const TEXT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const EDGE_PX := 1.5
const INSET_SHARE := 0.1
const INSET_MIN_PX := 8.0
const SIZE_SHARE := 0.24
const SIZE_MIN := 14.0
const SIZE_MAX := 48.0
const TEXT_PAD_SHARE := 0.22
const RARITY_GLYPHS := ["◇", "◈", "◆", "★", "✦"]

var text := "":
	set(value):
		text = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)


func _side() -> float:
	return clampf(minf(size.x, size.y) * SIZE_SHARE, SIZE_MIN, SIZE_MAX)


func _inset() -> float:
	return maxf(minf(size.x, size.y) * INSET_SHARE, INSET_MIN_PX) + EDGE_PX


func is_number() -> bool:
	return not text.is_empty() and not RARITY_GLYPHS.has(text)


func _font_size() -> int:
	return maxi(int(round(_side() * 1.05)), 10)


func mark_rect() -> Rect2:
	var side := _side()
	var pad := _inset()
	var w := side
	if is_number():
		var text_w := VT323_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size()).x
		w = maxf(side, text_w + side * TEXT_PAD_SHARE * 2.0)
	return Rect2(Vector2(pad, size.y - pad - side), Vector2(w, side))


func _draw() -> void:
	if text.is_empty():
		return
	var box := mark_rect()
	if is_number():
		_draw_number(box)
		return
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


func _draw_number(box: Rect2) -> void:
	draw_rect(box, FILL_COLOR, true)
	draw_rect(box, EDGE_COLOR, false, EDGE_PX)
	var fs := _font_size()
	var text_size := VT323_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var ascent := VT323_FONT.get_ascent(fs)
	var descent := VT323_FONT.get_descent(fs)
	var x := box.position.x + (box.size.x - text_size.x) * 0.5
	var baseline := box.get_center().y + (ascent - descent) * 0.5
	draw_string(VT323_FONT, Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, TEXT_COLOR)


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
