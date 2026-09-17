extends SceneTree

const LockerInteriorScript := preload("res://scenes/ui/locker_interior.gd")
const COMBAT_SCENE := "res://combat/combat_test.tscn"
const ITEM_TRES := "res://combat/data/items/C1_ash_spin_token.tres"
const WINDOW := Vector2i(1920, 1280)
const COMBAT_ICON := 48.0
const LOCKER_ICON := 1024.0


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = WINDOW
	var fails: PackedStringArray = PackedStringArray()
	await _check_combat(fails)
	_check_locker(fails)
	if fails.is_empty():
		print("Item icon draw size check OK (combat 48, locker 1024).")
		quit(0)
		return
	for msg in fails:
		push_error("item_icon_draw_size_check: %s" % msg)
	quit(1)


func _check_combat(fails: PackedStringArray) -> void:
	var packed := load(COMBAT_SCENE) as PackedScene
	if packed == null:
		fails.append("could not load combat_test.tscn")
		return
	var ui := packed.instantiate() as Control
	if ui == null:
		fails.append("combat_test instantiate failed")
		return
	root.add_child(ui)
	if not ui.is_node_ready():
		await ui.ready
	await process_frame
	await process_frame
	if ui.get_node_or_null("RightMeterStack") != null:
		fails.append("RightMeterStack leftover still in combat_test.tscn")
	if ui.find_child("PremiumMeterCircle", true, false) != null:
		fails.append("PremiumMeterCircle leftover still in tree")
	if ui.find_child("PremiumProgressBar", true, false) != null:
		fails.append("PremiumProgressBar leftover still in tree")
	var icons := ui.find_children("*", "TextureRect", true, false)
	var measured := 0
	for node in icons:
		var icon := node as TextureRect
		if icon == null or not bool(icon.get_meta("item_row_icon", false)):
			continue
		measured += 1
		if not is_equal_approx(icon.custom_minimum_size.x, COMBAT_ICON) or not is_equal_approx(icon.custom_minimum_size.y, COMBAT_ICON):
			fails.append("combat icon min size %s not 48x48" % icon.custom_minimum_size)
		var name_lab := _row_name_label(icon.get_parent())
		if name_lab != null:
			if name_lab.get_visible_line_count() < 1:
				fails.append("item name has no visible line")
			var bounds := name_lab.get_character_bounds(0)
			if bounds.size.x <= 0.0 and not String(name_lab.text).is_empty():
				fails.append("item name character bounds empty for '%s'" % name_lab.text)
	if measured < 1:
		fails.append("no combat ITEMS icons found to measure")
	ui.queue_free()


func _row_name_label(row: Node) -> Label:
	if row == null:
		return null
	for child in row.get_children():
		var lab := child as Label
		if lab != null and bool(lab.get_meta("item_row_name", false)):
			return lab
	return null


func _check_locker(fails: PackedStringArray) -> void:
	var locker := LockerInteriorScript.new()
	root.add_child(locker)
	if int(locker.ICON_PX) != int(LOCKER_ICON):
		fails.append("locker ICON_PX is %d not 1024" % int(locker.ICON_PX))
	if int(locker.COLS) != 1:
		fails.append("locker COLS is %d not 1" % int(locker.COLS))
	var item := load(ITEM_TRES) as Resource
	if item == null:
		fails.append("could not load %s" % ITEM_TRES)
		locker.queue_free()
		return
	var btn := locker.call("_make_item_button", item, PackedStringArray()) as Button
	if btn == null:
		fails.append("locker _make_item_button returned null")
		locker.queue_free()
		return
	if btn.custom_minimum_size.x < LOCKER_ICON or btn.custom_minimum_size.y < LOCKER_ICON:
		fails.append("locker button min size %s smaller than 1024" % btn.custom_minimum_size)
	if btn.expand_icon:
		fails.append("locker button expand_icon must be false so the 1024 file is not squashed")
	var max_w := btn.get_theme_constant("icon_max_width")
	if max_w != int(LOCKER_ICON):
		fails.append("locker icon_max_width is %d not 1024" % max_w)
	locker.queue_free()
