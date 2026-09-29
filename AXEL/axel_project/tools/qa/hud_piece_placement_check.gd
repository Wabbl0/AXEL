extends SceneTree

const SCENE_PATH := "res://combat/combat_test.tscn"
const PLATE := Vector2(3508.0, 2480.0)
const WINDOW := Vector2i(1920, 1280)
const POS_TOLERANCE := 2.0
const SIZE_TOLERANCE := 1.5

const EXPECTED := {
	"NEW_Settings": [-96.624756, 8.0, 145.0, 151.0],
	"NEW_Goal": [76.0, 190.0, 775.0, 571.0],
	"NEW_Items": [76.0, 791.0, 782.0, 1222.0],
	"NEW_Bets": [64.0, 2041.0, 793.0, 381.0],
	"NEW_Grid": [915.0, 87.0, 1670.0, 2346.0],
	"NEW_Multiplier": [2654.0, 84.0, 752.0, 497.0],
	"NEW_History": [2650.0, 621.0, 763.0, 881.0],
	"NEW_Execute": [2688.0, 1528.0, 692.0, 922.0],
}

var _failures: Array[String] = []
var _canvas_inv := Transform2D()


func _initialize() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load %s" % SCENE_PATH)
		quit(1)
		return
	var vp := SubViewport.new()
	vp.size = WINDOW
	root.add_child(vp)
	var scene := packed.instantiate()
	vp.add_child(scene)
	_run(scene)


func _run(scene: Node) -> void:
	for i in 12:
		await process_frame

	var canvas := scene.get_node_or_null("HudCanvas") as Control
	if canvas == null:
		_fail("HudCanvas is missing")
		_finish()
		return
	_canvas_inv = canvas.get_global_transform().affine_inverse()

	_check_plate_rect(scene, "HudCanvas/HudArtGuide", "HudArtGuide")
	_check_plate_rect(scene, "HudCanvas/HudPieces", "HudPieces")

	for name in EXPECTED:
		var piece := scene.find_child(name, true, false) as Control
		if piece == null:
			_fail("%s is missing from the scene" % name)
			continue
		var want: Array = EXPECTED[name]
		var got := _plate_rect(piece)
		_expect(name, "position", got.position, Vector2(want[0], want[1]), POS_TOLERANCE)
		_expect(name, "size", got.size, Vector2(want[2], want[3]), SIZE_TOLERANCE)
		_check_native_art_size(piece, name)
		_check_piece_shadow(piece, name)

	_check_pause_gear(scene)
	_check_on_plate(canvas)
	_check_grid_fills_box(scene)
	_finish()


func _check_plate_rect(scene: Node, path: String, label: String) -> void:
	var node := scene.get_node_or_null(path) as Control
	if node == null:
		_fail("%s is missing" % label)
		return
	var r := _plate_rect(node)
	_expect(label, "position", r.position, Vector2.ZERO, POS_TOLERANCE)
	_expect(label, "size", r.size, PLATE, SIZE_TOLERANCE)


func _check_native_art_size(piece: Control, name: String) -> void:
	var art := piece as TextureRect
	if art == null:
		for child in piece.get_children():
			if child.name == "DropShadow":
				continue
			if child is TextureRect and (child as TextureRect).texture != null:
				art = child as TextureRect
				break
	if art == null or art.texture == null:
		return
	var native := Vector2(art.texture.get_width(), art.texture.get_height())
	_expect(name, "native art size", _plate_rect(art).size, native, SIZE_TOLERANCE)


func _check_piece_shadow(piece: Control, name: String) -> void:
	var top: Node = piece
	var tree := piece.get_tree()
	if tree == null:
		_fail("%s has no drop shadow" % name)
		return
	while top.get_parent() != null and top.get_parent() != tree.root:
		top = top.get_parent()
	var layer := top.get_node_or_null("HudShadowLayer") as CanvasLayer
	if layer == null or layer.layer != 92:
		_fail("%s drop shadow is not above the noir filter" % name)
		return
	var shadow := layer.get_node_or_null("ShadowRoot/DropShadow_" + name) as Control
	if shadow == null:
		_fail("%s has no drop shadow" % name)
		return
	if shadow.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("%s drop shadow takes the click" % name)
	var mat := shadow.material as ShaderMaterial
	if mat == null:
		_fail("%s drop shadow has no material" % name)
		return
	var col: Variant = mat.get_shader_parameter("shadow_color")
	if not col is Color:
		_fail("%s drop shadow color is missing" % name)
		return
	var shadow_color := col as Color
	if (
		absf(shadow_color.r - 0.15) > 0.04
		or absf(shadow_color.g - 0.15) > 0.04
		or absf(shadow_color.b - 0.15) > 0.04
		or shadow_color.a < 0.9
	):
		_fail("%s drop shadow color is %s" % [name, shadow_color])
	if shadow.size.x < 8.0 or shadow.size.y < 8.0:
		_fail("%s drop shadow has no size (%s)" % [name, shadow.size])
		return
	var picture := _picture_node(piece)
	if picture == null:
		_fail("%s drop shadow is not on a picture" % name)
		return
	var art_rect := _plate_rect(picture)
	var shadow_rect := _plate_rect(shadow)
	if name == "NEW_Execute":
		if shadow_rect.position.x > art_rect.position.x - 0.5 or shadow_rect.end.y < art_rect.end.y + 0.5:
			_fail("%s skull shadow is not lower-left (%s vs %s)" % [name, shadow_rect, art_rect])
	elif shadow_rect.end.x < art_rect.end.x + 0.5 or shadow_rect.end.y < art_rect.end.y + 0.5:
		_fail("%s drop shadow does not sit down-right (%s vs %s)" % [name, shadow_rect, art_rect])


func _picture_node(piece: Control) -> Control:
	if piece is TextureRect and (piece as TextureRect).texture != null:
		return piece
	for child in piece.get_children():
		if str(child.name).begins_with("DropShadow"):
			continue
		if child is TextureRect and (child as TextureRect).texture != null:
			return child
	return piece.find_child("SkullStage1", true, false) as Control


func _check_pause_gear(scene: Node) -> void:
	var piece := scene.find_child("NEW_Settings", true, false) as Control
	if piece == null:
		_fail("NEW_Settings is missing")
		return
	var gear := piece.get_node_or_null("PauseGear") as Control
	if gear == null or str(gear.get_meta("gear_char", "")) != "⚙":
		_fail("pause square has no gear")
		return
	if gear.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("pause gear takes the click")
	var gap_l := gear.position.x
	var gap_t := gear.position.y
	var gap_r := piece.size.x - (gear.position.x + gear.size.x)
	var gap_b := piece.size.y - (gear.position.y + gear.size.y)
	if gap_l < -1.0 or gap_t < -1.0 or gap_r < -1.0 or gap_b < -1.0:
		_fail("pause gear sits outside the square (gaps %s %s %s %s, gear %s, piece %s)" % [gap_l, gap_t, gap_r, gap_b, gear.size, piece.size])
	if gap_l < 12.0 or gap_t < 12.0 or gap_r < 12.0 or gap_b < 12.0:
		_fail("pause gear is too close to the square edges (gaps %s %s %s %s)" % [gap_l, gap_t, gap_r, gap_b])
	if gap_l > 40.0 or gap_t > 40.0 or gap_r > 40.0 or gap_b > 40.0:
		_fail("pause gear is too small for the square (gaps %s %s %s %s)" % [gap_l, gap_t, gap_r, gap_b])


func _check_on_plate(canvas: Control) -> void:
	var stack: Array[Node] = [canvas]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.push_back(child)
		var ctrl := node as Control
		if ctrl == null or ctrl == canvas:
			continue
		if not (ctrl.name.begins_with("NEW_") or ctrl.name.begins_with("MOVE_")):
			continue
		var r := _plate_rect(ctrl)
		if r.size.x <= 1.0 or r.size.y <= 1.0:
			_fail("%s has no size (%s)" % [ctrl.name, r.size])
			continue
		var min_x := -POS_TOLERANCE
		var parent := ctrl.get_parent()
		if ctrl.name == "NEW_Settings" or (parent != null and parent.name == "NEW_Settings"):
			# The settings square sits in the left window margin, just off the plate.
			min_x = -100.0
		if r.position.x < min_x or r.position.y < -POS_TOLERANCE \
				or r.position.x + r.size.x > PLATE.x + POS_TOLERANCE \
				or r.position.y + r.size.y > PLATE.y + POS_TOLERANCE:
			_fail("%s leaves the plate: %s" % [ctrl.name, r])


func _check_grid_fills_box(scene: Node) -> void:
	var host := scene.find_child("GridHost", true, false) as Control
	var combat := scene.find_child("CombatRoot", true, false) as Node2D
	if host == null or combat == null:
		_fail("GridHost / CombatRoot missing")
		return
	var grid_ui := combat.get_node_or_null("GridUI") as Control
	if grid_ui == null:
		_fail("GridUI missing")
		return
	if host.size.x <= 1.0 or host.size.y <= 1.0:
		_fail("GridHost has no size")
		return
	var cover := Vector2(grid_ui.size.x / host.size.x, grid_ui.size.y / host.size.y)
	if cover.x < 0.98 or cover.y < 0.98:
		_fail("grid fills only %.0f%% x %.0f%% of its box (grid %s in host %s)" % [
			cover.x * 100.0, cover.y * 100.0, grid_ui.size, host.size])


func _plate_rect(ctrl: Control) -> Rect2:
	var xf := _canvas_inv * ctrl.get_global_transform()
	return Rect2(xf.origin, ctrl.size * xf.get_scale())


func _expect(name: String, what: String, got: Vector2, want: Vector2, tol: float) -> void:
	if absf(got.x - want.x) > tol or absf(got.y - want.y) > tol:
		_fail("%s %s is %s, expected %s" % [name, what, got, want])


func _fail(msg: String) -> void:
	_failures.append(msg)


func _finish() -> void:
	if _failures.is_empty():
		print("HUD piece placement check OK (%d pieces on plate)." % EXPECTED.size())
		quit(0)
		return
	for msg in _failures:
		printerr("HUD placement FAIL: %s" % msg)
	printerr("HUD piece placement check FAILED (%d problems)." % _failures.size())
	quit(1)
