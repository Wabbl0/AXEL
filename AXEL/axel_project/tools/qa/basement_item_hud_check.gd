extends SceneTree

const ROOM := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const COMBAT_PREFIX := "res://combat/"
const HOST_PAD_PX := 1.0
const NAME_MIN_W := 40.0
const PLAYER_ICON_PX := 144.0
const PLAYER_ICON_RES_PX := 120
const PLAYER_NAME_FONT := 84
const PLAYER_DESC_FONT := 58
const MID_Y_SLACK := 8.0

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var world := root.get_node_or_null("AxelWorld")
	var run := root.get_node_or_null("AxelRun")
	if world == null or run == null:
		push_error("basement_item_hud_check: autoloads missing")
		quit(1)
		return
	world.call("reset_world")
	run.call("reset_run")
	if world.has_method("plan_floor_items"):
		world.call("plan_floor_items", int(run.state.seed))
	if change_scene_to_file(ROOM) != OK:
		push_error("basement_item_hud_check: could not load 1.4")
		quit(1)
		return
	await _frames(45)
	if current_scene == null or current_scene.scene_file_path != ROOM:
		_fail("1.4 did not become the current scene")
		_finish()
		return
	var env := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	var host := env.get_node_or_null("WorldItemScatter") if env != null else null
	if host == null or host.get_child_count() < 1:
		_fail("1.4 has no floor item to take")
		_finish()
		return
	var pickup := host.get_child(0)
	var item_id := String(pickup.get("item_id"))
	var want_name := item_id
	var item_res = run.call("load_item", item_id)
	if item_res != null:
		want_name = str(item_res.get("display_name"))
	if not pickup.has_method("_take"):
		_fail("floor item has no _take")
		_finish()
		return
	world.call("take_item", ROOM, 0)
	if not Array(run.state.equipped_item_ids).has(item_id):
		_fail("1.4 pickup did not auto-equip %s" % item_id)
	await _frames(20)
	if not bool(world.call("start_fight_here", "item_pickup")):
		_fail("1.4 pickup fight did not start")
		_finish()
		return
	if not await _wait_scene_prefix(COMBAT_PREFIX, 400):
		_fail("1.4 pickup did not start a fight")
		_finish()
		return
	await _frames(56)
	var ui := current_scene
	var layer := ui.find_child("FeelLayer", true, false) as CanvasLayer
	if layer == null:
		_fail("FeelLayer missing")
	elif layer.layer < 115:
		_fail("FeelLayer %d should sit above the grid/CRT" % layer.layer)
	var combat := ui.find_child("CombatRoot", true, false)
	if combat == null:
		_fail("CombatRoot missing")
		_finish()
		return
	var inv = combat.get("inventory")
	var inv_ids: Array = []
	if inv != null and inv.get("items") != null:
		for it in inv.items:
			if it != null:
				inv_ids.append(str(it.get("id")))
	if not inv_ids.has(item_id):
		_fail("CombatRoot inventory missing %s (got %s)" % [item_id, str(inv_ids)])
	var panel := ui.find_child("PlayerItemPanel", true, false)
	if panel == null:
		_fail("PlayerItemPanel missing after 1.4 wire")
	else:
		await _assert_named_item_rows(ui, want_name)
	_finish()


func _assert_named_item_rows(ui: Node, want_name: String) -> void:
	var host := ui.find_child("Host_items", true, false) as Control
	if host == null:
		var test := ui.find_child("CombatTest", true, false)
		if test != null and test.has_method("get_items_widget_host"):
			host = test.call("get_items_widget_host") as Control
	if host == null:
		_fail("missing items host")
		return
	var names: Array[Label] = []
	var icons: Array[TextureRect] = []
	var descs: Array[Label] = []
	_collect_row_nodes(ui, names, icons, descs)
	if names.is_empty():
		_fail("no item row names after 1.4 pickup")
		return
	var saw := false
	var host_rect := host.get_global_rect()
	for lab in names:
		if lab.text == want_name:
			saw = true
		_assert_visible_label(lab, "name")
		if lab.size.x < NAME_MIN_W:
			_fail("'%s' width %.1f" % [lab.text, lab.size.x])
		if lab.get_global_rect().end.x > host_rect.end.x + HOST_PAD_PX:
			_fail("name '%s' spills past ITEMS host" % lab.text)
	if not saw:
		_fail("ITEMS box missing name '%s'" % want_name)
	if icons.is_empty():
		_fail("no item row icons after 1.4 pickup")
	for icon in icons:
		if not is_equal_approx(icon.custom_minimum_size.x, PLAYER_ICON_PX) or not is_equal_approx(icon.custom_minimum_size.y, PLAYER_ICON_PX):
			_fail("icon slot %s not 144x144" % icon.custom_minimum_size)
		var tex := icon.texture
		if tex == null or tex.get_width() != PLAYER_ICON_RES_PX or tex.get_height() != PLAYER_ICON_RES_PX:
			_fail("combat icon resolution is not 120x120")
		if icon.get_global_rect().end.x > host_rect.end.x + HOST_PAD_PX:
			_fail("icon spills past ITEMS host")
	if descs.is_empty():
		_fail("no item row descriptions after 1.4 pickup")
	if not names.is_empty() and names[0].get_theme_font_size("font_size") != PLAYER_NAME_FONT:
		_fail("name font %d not %d" % [names[0].get_theme_font_size("font_size"), PLAYER_NAME_FONT])
	if not descs.is_empty() and descs[0].get_theme_font_size("font_size") != PLAYER_DESC_FONT:
		_fail("desc font %d not %d" % [descs[0].get_theme_font_size("font_size"), PLAYER_DESC_FONT])
	if not names.is_empty() and not icons.is_empty():
		var icon_rect := icons[0].get_global_rect()
		var name_rect := names[0].get_global_rect()
		var icon_mid := icon_rect.position.y + icon_rect.size.y * 0.5
		var name_mid := name_rect.position.y + name_rect.size.y * 0.5
		if absf(icon_mid - name_mid) > MID_Y_SLACK:
			_fail("icon mid y %.1f not beside title mid y %.1f" % [icon_mid, name_mid])
	for desc in descs:
		if desc.visible:
			_fail("desc should start hidden until title hover")
	for lab in names:
		lab.mouse_entered.emit()
	for _i in 8:
		await process_frame
	for desc in descs:
		if not desc.visible:
			_fail("desc stayed hidden after title hover")
			continue
		_assert_visible_label(desc, "desc")
		if not String(desc.text).contains(" "):
			_fail("desc '%s' has no spaces" % desc.text)
		if desc.get_global_rect().end.x > host_rect.end.x + HOST_PAD_PX:
			_fail("desc spills past ITEMS host")


func _assert_visible_label(lab: Label, kind: String) -> void:
	if lab.get_visible_line_count() < 1:
		_fail("%s '%s' has no visible lines" % [kind, lab.text])
	var bounds := lab.get_character_bounds(0)
	if bounds.size.x <= 0.0 and bounds.size.y <= 0.0:
		_fail("%s '%s' character bounds empty" % [kind, lab.text])


func _collect_row_nodes(
	node: Node, names: Array[Label], icons: Array[TextureRect], descs: Array[Label]
) -> void:
	var lab := node as Label
	if lab != null:
		if bool(lab.get_meta("item_row_name", false)) and lab.is_visible_in_tree():
			names.append(lab)
		elif bool(lab.get_meta("item_row_desc", false)):
			descs.append(lab)
	var icon := node as TextureRect
	if icon != null and bool(icon.get_meta("item_row_icon", false)) and icon.is_visible_in_tree():
		icons.append(icon)
	for child in node.get_children():
		_collect_row_nodes(child, names, icons, descs)


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _wait_scene_prefix(prefix: String, max_frames: int) -> bool:
	for _i in max_frames:
		await process_frame
		if current_scene != null and String(current_scene.scene_file_path).begins_with(prefix):
			return true
	return false


func _finish() -> void:
	if _failures.is_empty():
		print("Basement item HUD check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("basement_item_hud_check: %s" % msg)
	quit(1)
