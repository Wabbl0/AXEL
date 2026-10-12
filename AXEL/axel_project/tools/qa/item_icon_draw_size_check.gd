extends SceneTree

const LockerShelvesScript := preload("res://scenes/ui/locker_shelves.gd")
const PlayerItemPanelScript := preload("res://combat/scripts/player_item_panel.gd")
const COMBAT_SCENE := "res://combat/combat_test.tscn"
const ITEM_TRES := "res://combat/data/items/C1_ash_spin_token.tres"
const WINDOW := Vector2i(1920, 1280)
const COMBAT_SLOT := 144.0
const COMBAT_RES := 120
const FILE_RES := 1024


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = WINDOW
	var fails: PackedStringArray = PackedStringArray()
	await _check_combat(fails)
	_check_locker(fails)
	if COMBAT_RES >= FILE_RES:
		fails.append("combat icon res %d must be below file res %d" % [COMBAT_RES, FILE_RES])
	if fails.is_empty():
		print("Item icon draw size check OK (combat slot 144 res 120, shelves lore-only).")
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
	ui.queue_free()
	var host := Control.new()
	host.custom_minimum_size = Vector2(700, 500)
	host.size = Vector2(700, 500)
	root.add_child(host)
	var panel := PlayerItemPanelScript.new()
	host.add_child(panel)
	if not panel.is_node_ready():
		await panel.ready
	var item := load(ITEM_TRES) as Resource
	if item == null:
		fails.append("could not load %s" % ITEM_TRES)
		host.queue_free()
		return
	panel.call("set_equipped_items", [item])
	for _i in 12:
		await process_frame
	var icons := panel.find_children("*", "TextureRect", true, false)
	var measured := 0
	for node in icons:
		var icon := node as TextureRect
		if icon == null or not bool(icon.get_meta("item_row_icon", false)):
			continue
		measured += 1
		var row_px := float(panel.call("row_height"))
		if row_px > COMBAT_SLOT + 0.5 or row_px < 72.0:
			fails.append("combat row height %.1f should be 72..144" % row_px)
		if not is_equal_approx(icon.custom_minimum_size.x, row_px) or not is_equal_approx(icon.custom_minimum_size.y, row_px):
			fails.append("combat icon slot %s not the %.0f row height" % [icon.custom_minimum_size, row_px])
		var tex := icon.texture
		if tex == null or tex.get_width() != COMBAT_RES or tex.get_height() != COMBAT_RES:
			fails.append("combat icon resolution is not 120x120")
		var name_lab := _find_meta_label(icon.get_parent(), "item_row_name")
		if name_lab != null:
			if name_lab.get_visible_line_count() < 1:
				fails.append("item name has no visible line")
			var bounds := name_lab.get_character_bounds(0)
			if bounds.size.x <= 0.0 and not String(name_lab.text).is_empty():
				fails.append("item name character bounds empty for '%s'" % name_lab.text)
	if measured < 1:
		fails.append("no combat ITEMS icons found to measure")
	host.queue_free()


func _find_meta_label(node: Node, meta: String) -> Label:
	if node == null:
		return null
	var lab := node as Label
	if lab != null and bool(lab.get_meta(meta, false)):
		return lab
	for child in node.get_children():
		var found := _find_meta_label(child, meta)
		if found != null:
			return found
	return null


func _check_locker(fails: PackedStringArray) -> void:
	var entries: Array = LockerShelvesScript.lore_entries_for_flags(PackedStringArray([
		"hasFlashlight", "hasKey", "hasName", "hasShovel", "C1",
	]))
	var titles: PackedStringArray = PackedStringArray()
	for entry in entries:
		var title := String((entry as Dictionary).get("title", ""))
		titles.append(title)
		var tex_path := String((entry as Dictionary).get("texture", ""))
		if tex_path.contains("combat/data/items") or tex_path.contains("item_icons"):
			fails.append("shelf entry %s points at a combat icon" % title)
		if title == "Shovel":
			fails.append("shovel must not sit on the locker shelves")
	if titles.size() != 3 or titles[0] != "Flashlight" or titles[1] != "Key" or titles[2] != "Name":
		fails.append("shelf lore entries were %s" % str(titles))
