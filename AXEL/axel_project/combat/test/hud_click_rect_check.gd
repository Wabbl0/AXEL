extends SceneTree

const SCENE_PATH := "res://combat/combat_test.tscn"
const WINDOW := Vector2i(1920, 1280)
const CLICKABLE := ["NEW_Settings", "NEW_Execute", "MOVE_BetMinus", "MOVE_BetPlus"]
const INSET := 4.0

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	_check_scaled_parent_synthetic()
	await _check_combat_test_scene()
	if _failures.is_empty():
		print("HUD click rect check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("HUD click rect FAIL: %s" % msg)
	quit(1)


func _check_scaled_parent_synthetic() -> void:
	var canvas := Control.new()
	canvas.name = "ScaledCanvas"
	canvas.size = Vector2(800, 600)
	canvas.scale = Vector2(0.5, 0.5)
	var piece := Control.new()
	piece.set_script(load("res://combat/scripts/hud_piece.gd"))
	piece.name = "Piece"
	piece.position = Vector2(40, 40)
	piece.size = Vector2(200, 200)
	piece.set("clickable", true)
	piece.set("use_alpha_hit", true)
	var art := TextureRect.new()
	art.name = "Art"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	piece.add_child(art)
	var box := Control.new()
	box.name = "MOVE_TextBox"
	box.position = Vector2(20, 24)
	box.size = Vector2(160, 150)
	piece.add_child(box)
	root.add_child(canvas)
	canvas.add_child(piece)
	if not piece.is_node_ready():
		await piece.ready
	var hud := piece as CombatHudPiece
	if hud == null:
		_fail("synthetic: piece is not CombatHudPiece")
		piece.queue_free()
		canvas.queue_free()
		return
	var inside_br := Vector2(20.0 + 160.0 - INSET, 24.0 + 150.0 - INSET)
	var outside_left := Vector2(8.0, 100.0)
	if not hud._has_point(inside_br):
		_fail("synthetic: TextBox bottom-right should click (got miss at %s)" % inside_br)
	if hud._has_point(outside_left):
		_fail("synthetic: left of TextBox should miss (got hit at %s)" % outside_left)
	piece.queue_free()
	canvas.queue_free()


func _check_combat_test_scene() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load %s" % SCENE_PATH)
		return
	var vp := SubViewport.new()
	vp.size = WINDOW
	root.add_child(vp)
	var scene := packed.instantiate() as Control
	vp.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	for i in 16:
		await process_frame
	for piece_name in CLICKABLE:
		_check_piece(scene, piece_name)
	_check_settings_square(scene)
	var poly := scene.find_child("SkullClickPolygon", true, false) as Control
	if poly == null:
		_fail("SkullClickPolygon missing")
	elif poly.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("SkullClickPolygon must ignore mouse so Execute TextBox owns the click")
	scene.queue_free()
	vp.queue_free()


func _check_piece(scene: Node, piece_name: String) -> void:
	var piece := scene.find_child(piece_name, true, false) as Control
	if piece == null:
		_fail("%s missing" % piece_name)
		return
	var hud := piece as CombatHudPiece
	if hud == null:
		_fail("%s is not CombatHudPiece" % piece_name)
		return
	if not hud.clickable:
		_fail("%s is not clickable" % piece_name)
		return
	var box := hud.get_text_box()
	if box == null:
		_fail("%s has no MOVE_TextBox" % piece_name)
		return
	if box.size.x < 8.0 or box.size.y < 8.0:
		_fail("%s TextBox has no size (%s)" % [piece_name, box.size])
		return
	var samples: Array[Vector2] = [
		Vector2(INSET, INSET),
		Vector2(box.size.x - INSET, INSET),
		Vector2(INSET, box.size.y - INSET),
		Vector2(box.size.x - INSET, box.size.y - INSET),
		box.size * 0.5,
	]
	for local in samples:
		var piece_local: Vector2 = box.get_transform() * local
		if not hud._has_point(piece_local):
			_fail("%s miss inside TextBox at local %s (piece %s)" % [piece_name, local, piece_local])
	var just_outside := box.get_transform() * Vector2(-INSET, box.size.y * 0.5)
	if Rect2(Vector2.ZERO, piece.size).has_point(just_outside):
		if hud._has_point(just_outside):
			_fail("%s hit outside TextBox at %s" % [piece_name, just_outside])


func _check_settings_square(scene: Node) -> void:
	var piece := scene.find_child("NEW_Settings", true, false) as CombatHudPiece
	if piece == null:
		_fail("NEW_Settings missing for square check")
		return
	var art := piece.get_art()
	var box := piece.get_text_box()
	if art == null or art.texture == null or box == null:
		_fail("NEW_Settings art or TextBox missing")
		return
	var image := art.texture.get_image()
	if image == null or image.is_empty():
		_fail("NEW_Settings art has no image")
		return
	if image.is_compressed():
		image.decompress()
	var ink := _opaque_bounds(image)
	if ink.size.x < 8.0 or ink.size.y < 8.0:
		_fail("NEW_Settings ink bounds are empty (%s)" % ink)
		return
	var art_to_piece := piece.get_global_transform().affine_inverse() * art.get_global_transform()
	var ink_in_piece := Rect2(art_to_piece * ink.position, ink.size * art_to_piece.get_scale())
	var box_in_piece := Rect2(box.position, box.size)
	if not _rects_close(box_in_piece, ink_in_piece, 2.0):
		_fail("Settings click box %s is not on the square %s" % [box_in_piece, ink_in_piece])
	var center: Vector2 = ink_in_piece.position + ink_in_piece.size * 0.5
	if not piece._has_point(center):
		_fail("Settings square center should click (got miss at %s)" % center)
	var beside := Vector2(ink_in_piece.position.x + ink_in_piece.size.x + 24.0, center.y)
	if piece._has_point(beside):
		_fail("Settings hit empty space beside the square at %s" % beside)


func _opaque_bounds(image: Image) -> Rect2:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= 10.0 / 255.0:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2()
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x + 1, max_y - min_y + 1))


func _rects_close(a: Rect2, b: Rect2, tol: float) -> bool:
	return absf(a.position.x - b.position.x) <= tol \
		and absf(a.position.y - b.position.y) <= tol \
		and absf(a.size.x - b.size.x) <= tol \
		and absf(a.size.y - b.size.y) <= tol


func _fail(msg: String) -> void:
	_failures.append(msg)
