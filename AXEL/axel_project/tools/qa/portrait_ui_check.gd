extends SceneTree

const PHONE := Vector2i(1179, 2556)
const DESK := Vector2i(1920, 1280)
const MAIN := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const SAVES := "res://scenes/Main_Menu/Saves.tscn"
const CREDITS := "res://scenes/Main_Menu/Credits.tscn"
const OPTIONS := "res://scenes/Main_Menu/Options.tscn"
const COMBAT := "res://combat/combat_test.tscn"

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_WORLD_COMBAT", "0")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _load(path: String, size: Vector2i) -> Node:
	root.size = size
	await process_frame
	var scene := (load(path) as PackedScene).instantiate()
	root.add_child(scene)
	for _i in 8:
		await process_frame
	return scene


func _drop(scene: Node) -> void:
	scene.queue_free()
	await process_frame
	await process_frame


func _safe() -> Rect2:
	var top := PHONE.y * PortraitUi.TOP_BAND
	var bottom := PHONE.y * PortraitUi.BOTTOM_BAND
	return Rect2(0.0, top, PHONE.x, PHONE.y - top - bottom)


func _inside(rect: Rect2, area: Rect2, pad: float = 2.0) -> bool:
	return area.grow(pad).encloses(rect)


func _text_w(label: Control, text: String) -> float:
	var font := label.get_theme_font("font")
	var fs := label.get_theme_font_size("font_size")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


func _check_texts_inside(scene_name: String, scene: Node, check_y: bool) -> void:
	var area := _safe() if check_y else Rect2(0.0, -100000.0, PHONE.x, 200000.0)
	for node in scene.find_children("*", "Control", true, false):
		var c := node as Control
		if c == null or not c.is_visible_in_tree():
			continue
		if not (c is Button or c is Label):
			continue
		if c.size.x < 1.0:
			continue
		if not _inside(c.get_global_rect(), area):
			_fail("%s: %s sits outside the safe area %s" % [scene_name, c.name, str(c.get_global_rect())])


func _main() -> void:
	var menu := await _load(MAIN, PHONE)
	var title := menu.find_child("TitleLabel", true, false) as Label
	if title == null:
		_fail("main menu: TitleLabel missing")
	elif _text_w(title, title.text) < PHONE.x * 0.4:
		_fail("main menu: title only %d px wide" % roundi(_text_w(title, title.text)))
	var first := menu.find_child("ContinueButton", true, false) as Control
	var last := menu.find_child("QuitButton", true, false) as Control
	if first != null and last != null:
		var spread := last.get_global_rect().end.y - first.get_global_rect().position.y
		if spread < PHONE.y * 0.5:
			_fail("main menu: buttons only spread %d px" % roundi(spread))
	_check_texts_inside("main menu", menu, true)
	await _drop(menu)

	var saves := await _load(SAVES, PHONE)
	_check_texts_inside("saves", saves, true)
	await _drop(saves)

	var credits := await _load(CREDITS, PHONE)
	_check_texts_inside("credits", credits, true)
	await _drop(credits)

	var options := await _load(OPTIONS, PHONE)
	_check_texts_inside("options", options, false)
	await _drop(options)

	var combat := await _load(COMBAT, PHONE)
	await _check_combat_portrait(combat)
	root.size = DESK
	for _i in 8:
		await process_frame
	_check_combat_landscape(combat)
	await _drop(combat)

	if _failures.is_empty():
		print("PORTRAIT_UI_CHECK pass")
		quit(0)
	else:
		for f in _failures:
			push_error("PORTRAIT_UI_CHECK " + f)
		quit(1)


func _check_combat_portrait(combat: Node) -> void:
	if not bool(combat.call("is_hud_portrait")):
		_fail("combat: portrait layout not active at 1179x2556")
		return
	var layout: Dictionary = combat.get("PORTRAIT_LAYOUT")
	var rects := {}
	for piece_name in layout.keys():
		var piece := combat.find_child(piece_name, true, false) as Control
		if piece == null:
			_fail("combat: %s missing" % piece_name)
			continue
		var rect := piece.get_global_rect()
		rects[piece_name] = rect
		if piece_name != "NEW_Settings" and not _inside(rect, _safe()):
			_fail("combat: %s outside the safe area %s" % [piece_name, str(rect)])
	var names: Array = rects.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: Rect2 = rects[names[i]]
			var b: Rect2 = rects[names[j]]
			if a.grow(-2.0).intersects(b.grow(-2.0)):
				_fail("combat: %s overlaps %s" % [names[i], names[j]])
	if rects.has("NEW_Grid"):
		var grid_w: float = (rects["NEW_Grid"] as Rect2).size.x
		if grid_w < PHONE.x * 0.85:
			_fail("combat: grid only %d px wide" % roundi(grid_w))
	var spin := combat.find_child("SpinButton", true, false) as Control
	if spin != null and rects.has("NEW_Execute"):
		if not _inside(spin.get_global_rect(), rects["NEW_Execute"], 4.0):
			_fail("combat: SpinButton %s is not on the skull %s" % [str(spin.get_global_rect()), str(rects["NEW_Execute"])])


func _check_combat_landscape(combat: Node) -> void:
	if bool(combat.call("is_hud_portrait")):
		_fail("combat: still portrait at 1920x1280")
		return
	var spots: Dictionary = combat.get("_hud_landscape_spots")
	for piece_name in spots.keys():
		var piece := combat.find_child(piece_name, true, false) as Control
		var spot: Array = spots[piece_name]
		if piece.position.distance_to(spot[0]) > 0.5 or absf(piece.scale.x - float(spot[1])) > 0.001:
			_fail("combat: %s did not return to its landscape spot" % piece_name)
