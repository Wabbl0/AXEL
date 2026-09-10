extends SceneTree
## Headless: F6 playtest keeps the catalog picker; combat_run shows the player item box.
## Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://combat/test/combat_player_item_box_check.gd

const PLAYTEST := "res://combat/combat_test.tscn"
const PLAYER := "res://combat/combat_run.tscn"
const STARTER := "res://combat/data/items/C1_ash_reroll_token.tres"
const HOST_PAD_PX := 1.0
const ICON_INSET_MIN_PX := 8.0
const NAME_MIN_W := 40.0
const PLAYER_HOVER_FONT := 29
const RARITY_PREFIXES := ["◇", "◈", "◆", "★", "✦"]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	await _check_playtest_picker()
	await _check_player_preview_egg()
	await _check_tutorial_egg()
	await _check_equipped_list()
	_reset_run()
	if not _failures.is_empty():
		push_error("combat_player_item_box_check FAIL: %s" % ", ".join(_failures))
		quit(1)
		return
	print("combat_player_item_box_check OK.")
	quit(0)


func _check_playtest_picker() -> void:
	var ui := await _boot(PLAYTEST)
	if ui == null:
		return
	var picker := ui.find_child("ItemPickerPanel", true, false) as CanvasItem
	if picker == null:
		_fail("F6 combat_test missing ItemPickerPanel")
	elif not picker.visible:
		_fail("F6 combat_test hid ItemPickerPanel")
	if ui.find_child("EmptyItemDvd", true, false) != null:
		_fail("F6 combat_test should not spawn EmptyItemDvd")
	if ui.find_child("PlayerItemPanel", true, false) != null:
		_fail("F6 combat_test should not spawn PlayerItemPanel")
	await _wait_layout()
	_assert_named_item_rows(ui, "F6 picker")
	ui.queue_free()
	await process_frame


func _check_player_preview_egg() -> void:
	_reset_run()
	var ui := await _boot(PLAYER)
	if ui == null:
		return
	_assert_player_chrome(ui, true)
	ui.queue_free()
	await process_frame


func _check_tutorial_egg() -> void:
	var run := root.get_node_or_null("AxelRun")
	if run == null:
		_fail("AxelRun autoload missing")
		return
	run.reset_run()
	run.state.in_encounter = true
	run.state.world_encounter = true
	run.state.world_reason = "locker_tutorial"
	var ui := await _boot(PLAYER)
	if ui == null:
		return
	_assert_player_chrome(ui, true)
	ui.queue_free()
	await process_frame
	_reset_run()


func _check_equipped_list() -> void:
	var run := root.get_node_or_null("AxelRun")
	if run == null:
		_fail("AxelRun autoload missing")
		return
	run.reset_run()
	run.state.in_encounter = true
	run.state.world_encounter = true
	run.state.world_reason = "walk"
	var ui := await _boot(PLAYER)
	if ui == null:
		return
	var root_combat := ui.find_child("CombatRoot", true, false)
	var item := load(STARTER) as Resource
	if root_combat != null and item != null and root_combat.has_method("set_equipped_items"):
		root_combat.call("set_equipped_items", [item])
	for _i in 30:
		await process_frame
	_assert_player_chrome(ui, false)
	var panel := ui.find_child("PlayerItemPanel", true, false)
	if panel == null:
		_fail("later fight missing PlayerItemPanel")
	elif panel.has_method("set_equipped_items") and item != null:
		panel.call("set_equipped_items", [item])
		await _wait_layout()
		var list := panel.find_child("List", true, false)
		if list == null or list.get_child_count() < 1:
			_fail("PlayerItemPanel did not show equipped rows")
		else:
			_assert_named_item_rows(ui, "equipped list")
			_assert_player_hover_font(panel)
	ui.queue_free()
	await process_frame
	_reset_run()


func _assert_player_chrome(ui: Node, want_egg: bool) -> void:
	var items := ui.find_child("NEW_Items", true, false) as CanvasItem
	if items == null:
		_fail("NEW_Items missing")
	elif not items.visible:
		_fail("player combat hid NEW_Items")
	var picker := ui.find_child("ItemPickerPanel", true, false) as CanvasItem
	if picker != null and picker.visible:
		_fail("player combat left ItemPickerPanel visible")
	var seed_box := ui.find_child("SeedSpinBox", true, false) as CanvasItem
	if seed_box != null and seed_box.visible:
		_fail("player combat left SeedSpinBox visible")
	var egg := ui.find_child("EmptyItemDvd", true, false)
	var ticker := ui.find_child("ChickensTicker", true, false) as Label
	var list := ui.find_child("PlayerItemPanel", true, false)
	if want_egg:
		if egg == null:
			_fail("empty-egg mode missing EmptyItemDvd")
		if ticker == null or not String(ticker.text).contains("Nothing but us chickens."):
			_fail("empty-egg mode missing chickens ticker")
		if list != null:
			_fail("empty-egg mode spawned PlayerItemPanel")
	else:
		if egg != null:
			_fail("equipped mode still has EmptyItemDvd")
		if list == null:
			_fail("equipped mode missing PlayerItemPanel")


func _items_host(ui: Node) -> Control:
	var test: Node = ui
	if not ui.has_method("get_items_widget_host"):
		test = ui.find_child("CombatTest", true, false)
	if test != null and test.has_method("get_items_widget_host"):
		return test.call("get_items_widget_host") as Control
	return ui.find_child("Host_items", true, false) as Control


func _assert_named_item_rows(ui: Node, where: String) -> void:
	var host := _items_host(ui)
	if host == null:
		_fail("%s: missing items host" % where)
		return
	var names: Array[Label] = []
	var icons: Array[TextureRect] = []
	_collect_item_row_nodes(ui, names, icons)
	if names.is_empty():
		_fail("%s: no item row names" % where)
		return
	var host_rect := host.get_global_rect()
	for lab in names:
		if lab.get_visible_line_count() < 1:
			_fail("%s: '%s' has no visible lines" % [where, lab.text])
		if lab.size.x < NAME_MIN_W:
			_fail("%s: '%s' width %.1f < %.1f" % [where, lab.text, lab.size.x, NAME_MIN_W])
		var bounds := lab.get_character_bounds(0)
		if bounds.size.x <= 0.0 and bounds.size.y <= 0.0:
			_fail("%s: '%s' character bounds empty" % [where, lab.text])
		if not _rect_inside_x(lab.get_global_rect(), host_rect):
			_fail("%s: name '%s' spills past ITEMS host" % [where, lab.text])
		if _has_rarity_glyph_prefix(lab.text):
			_fail("%s: name '%s' still has a rarity glyph" % [where, lab.text])
	if icons.is_empty():
		_fail("%s: no item row icons" % where)
		return
	for icon in icons:
		var icon_rect := icon.get_global_rect()
		var local_pos: Vector2 = host.get_global_transform().affine_inverse() * icon_rect.position
		var local_left: float = local_pos.x
		if local_left < ICON_INSET_MIN_PX:
			_fail(
				"%s: icon too close to ITEMS left (gap %.1f < %.1f)"
				% [where, local_left, ICON_INSET_MIN_PX]
			)
		if not _rect_inside_x(icon_rect, host_rect):
			_fail("%s: icon spills past ITEMS host" % where)


func _collect_item_row_nodes(node: Node, names: Array[Label], icons: Array[TextureRect]) -> void:
	var lab := node as Label
	if lab != null and bool(lab.get_meta("item_row_name", false)) and lab.is_visible_in_tree():
		names.append(lab)
	var icon := node as TextureRect
	if icon != null and bool(icon.get_meta("item_row_icon", false)) and icon.is_visible_in_tree():
		icons.append(icon)
	for child in node.get_children():
		_collect_item_row_nodes(child, names, icons)


func _has_rarity_glyph_prefix(text: String) -> bool:
	var t := text.strip_edges()
	for glyph in RARITY_PREFIXES:
		if t.begins_with(glyph):
			return true
	return false


func _assert_player_hover_font(panel: Node) -> void:
	var hover := panel.find_child("ItemHover", true, false)
	if hover == null:
		_fail("equipped list missing ItemHover")
		return
	var hover_lab: Label = null
	for child in hover.get_children():
		hover_lab = child as Label
		if hover_lab != null:
			break
	if hover_lab == null:
		_fail("equipped list ItemHover missing label")
		return
	var size := hover_lab.get_theme_font_size("font_size")
	if size != PLAYER_HOVER_FONT:
		_fail("equipped hover font %d != %d" % [size, PLAYER_HOVER_FONT])


func _rect_inside_x(child: Rect2, host: Rect2) -> bool:
	return child.position.x + HOST_PAD_PX >= host.position.x and child.end.x <= host.end.x + HOST_PAD_PX


func _wait_layout() -> void:
	for _i in 8:
		await process_frame


func _boot(path: String) -> Node:
	if not ResourceLoader.exists(path):
		_fail("missing %s" % path)
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		_fail("not a PackedScene: %s" % path)
		return null
	var node := packed.instantiate()
	if node == null:
		_fail("instantiate failed: %s" % path)
		return null
	root.add_child(node)
	if not node.is_node_ready():
		await node.ready
	for _i in 28:
		await process_frame
	return node


func _reset_run() -> void:
	var run := root.get_node_or_null("AxelRun")
	if run != null and run.has_method("reset_run"):
		run.call("reset_run")
