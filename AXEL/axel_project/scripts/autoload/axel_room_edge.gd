extends Node

const LINE_NAME := "RoomEdgeLine"
const LINE_COLOR := Color(0.45, 0.03, 0.03, 1.0)
const LINE_PX := 4.0
const FEATHER_PX := 2.0
const MASK_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const HINT_GAP_PX := 8.0

var _scene: Node


func _process(_delta: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var scene := tree.current_scene
	if scene == _scene:
		return
	_scene = scene
	if scene != null:
		attach(scene)


static func attach(scene: Node) -> Node2D:
	var layer := scene.get_node_or_null("PlayerLayer") as CanvasLayer
	if layer == null or layer.get_node_or_null("Player") == null:
		return null
	var existing := layer.get_node_or_null(LINE_NAME) as Node2D
	if existing != null:
		return existing
	var background := find_background(scene)
	if background == null:
		return null
	var line := EdgeLine.new()
	line.name = LINE_NAME
	line.background = background
	layer.add_child(line)
	var player := layer.get_node("Player")
	layer.move_child(line, player.get_index() + 1)
	return line


func inner_screen_rect(scene: Node) -> Rect2:
	if scene == null:
		return Rect2()
	var line := scene.get_node_or_null("PlayerLayer/" + LINE_NAME) as Node2D
	if line == null or not line.has_method("screen_rect"):
		return Rect2()
	var rect: Rect2 = line.call("screen_rect")
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Rect2()
	return rect.grow(-LINE_PX)


func keep_inside(node: Node2D, half_screen: Vector2) -> void:
	if node == null or not node.is_inside_tree():
		return
	var inner := inner_screen_rect(node.get_tree().current_scene)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return
	var canvas := node.get_canvas_transform()
	var screen := canvas * node.global_position
	var lo := inner.position + half_screen + Vector2(HINT_GAP_PX, HINT_GAP_PX)
	var hi := inner.end - half_screen - Vector2(HINT_GAP_PX, HINT_GAP_PX)
	if hi.x < lo.x or hi.y < lo.y:
		return
	var clamped := Vector2(clampf(screen.x, lo.x, hi.x), clampf(screen.y, lo.y, hi.y))
	if clamped != screen:
		node.global_position = canvas.affine_inverse() * clamped


static func find_background(scene: Node) -> Sprite2D:
	var best: Sprite2D = null
	for node in scene.find_children("Background*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite.texture == null:
			continue
		if best == null or _area(sprite) > _area(best):
			best = sprite
	return best


static func _area(sprite: Sprite2D) -> float:
	var r := sprite.get_global_transform() * sprite.get_rect()
	return absf(r.size.x * r.size.y)


class EdgeLine:
	extends Node2D

	var background: Sprite2D

	func _process(_delta: float) -> void:
		queue_redraw()

	func world_rect() -> Rect2:
		if background == null or not is_instance_valid(background):
			return Rect2()
		return background.get_global_transform() * background.get_rect()

	func screen_rect() -> Rect2:
		return get_canvas_transform() * world_rect()

	func _draw() -> void:
		var rect := world_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			return
		var zoom := maxf(get_canvas_transform().get_scale().x, 0.001)
		var width := LINE_PX / zoom
		_draw_mask(rect)
		_draw_feather(rect.grow(-width), FEATHER_PX / zoom)
		draw_rect(rect.grow(-width * 0.5), LINE_COLOR, false, width)

	func _draw_mask(rect: Rect2) -> void:
		var view := get_canvas_transform().affine_inverse() * get_viewport_rect()
		var outer := view.merge(rect).grow(64.0)
		draw_rect(Rect2(outer.position, Vector2(outer.size.x, rect.position.y - outer.position.y)), MASK_COLOR)
		draw_rect(Rect2(Vector2(outer.position.x, rect.end.y), Vector2(outer.size.x, outer.end.y - rect.end.y)), MASK_COLOR)
		draw_rect(Rect2(Vector2(outer.position.x, rect.position.y), Vector2(rect.position.x - outer.position.x, rect.size.y)), MASK_COLOR)
		draw_rect(Rect2(Vector2(rect.end.x, rect.position.y), Vector2(outer.end.x - rect.end.x, rect.size.y)), MASK_COLOR)

	func _draw_feather(edge: Rect2, feather: float) -> void:
		var inner := edge.grow(-feather)
		var solid := MASK_COLOR
		var clear := Color(MASK_COLOR.r, MASK_COLOR.g, MASK_COLOR.b, 0.0)
		var o := [edge.position, Vector2(edge.end.x, edge.position.y), edge.end, Vector2(edge.position.x, edge.end.y)]
		var i := [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]
		for k in 4:
			var n := (k + 1) % 4
			draw_polygon(
				PackedVector2Array([o[k], o[n], i[n], i[k]]),
				PackedColorArray([solid, solid, clear, clear])
			)
