extends SceneTree

const _ROOM := "res://scenes/Arc_1/1.2_Corridor.tscn"
const _MENU := "res://scenes/Main_Menu/0.1_MainMenu.tscn"

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

	var pause := root.get_node_or_null("AxelPause")
	var music := root.get_node_or_null("AxelMusic")
	if pause == null:
		push_error("pause_contract_check: AxelPause autoload missing")
		quit(1)
		return


	if music != null and music.process_mode != Node.PROCESS_MODE_ALWAYS:
		_fail("AxelMusic.process_mode should be ALWAYS, got %d" % music.process_mode)


	if change_scene_to_file(_MENU) != OK:
		_fail("could not load main menu")
	else:
		for _i in 6:
			await process_frame
		if bool(pause.call("request_pause")):
			_fail("pause should be refused on the main menu")
			pause.call("request_unpause")


	if change_scene_to_file(_ROOM) != OK:
		_fail("could not load 1.2 corridor")
	else:
		for _i in 10:
			await process_frame


		var enter_overlay := current_scene.get_node_or_null("TopDialogueOverlay")
		if enter_overlay != null and enter_overlay.has_method("interrupt_line"):
			enter_overlay.call("interrupt_line")
		for _i in 4:
			await process_frame


		await _tap_escape()
		if not paused:
			_fail("Esc did not pause in 1.2 corridor")


		var player := current_scene.get_node_or_null("PlayerLayer/Player") as CharacterBody2D
		if player == null:
			_fail("player node missing in 1.2")
		else:
			var press := InputEventKey.new()
			press.keycode = KEY_D
			press.physical_keycode = KEY_D
			press.pressed = true
			Input.parse_input_event(press)
			var before := player.global_position
			for _i in 30:
				await physics_frame
			var rel := InputEventKey.new()
			rel.keycode = KEY_D
			rel.physical_keycode = KEY_D
			rel.pressed = false
			Input.parse_input_event(rel)
			if player.global_position.distance_to(before) > 0.01:
				_fail("player moved %.2f px while paused" % player.global_position.distance_to(before))


		var pause_menu := pause.get_node_or_null("AxelPauseMenu")
		if pause_menu == null or not pause_menu.has_method("_fill_loadout"):
			_fail("pause menu missing loadout")
		else:
			_assert_no_inventory_button(pause_menu)
			pause_menu.call("_fill_loadout")
			await process_frame
			_assert_inventory_clean(pause_menu, "")
			var run := root.get_node_or_null("AxelRun")
			if run != null:
				run.state.owned_item_ids = PackedStringArray(["C1", "C2"])
				run.state.equipped_item_ids = PackedStringArray(["C1"])
				pause_menu.call("_fill_loadout")
				await process_frame
				_assert_inventory_clean(pause_menu, "Ash Spin Token")
				_assert_loadout_details(pause_menu)
				run.state.owned_item_ids = PackedStringArray()
				run.state.equipped_item_ids = PackedStringArray()
			if pause_menu.has_method("_show_main"):
				pause_menu.call("_show_main")

		await _tap_escape()
		if paused:
			_fail("Esc did not unpause")


		var overlay := current_scene.get_node_or_null("TopDialogueOverlay")
		if overlay == null or not overlay.has_method("show_line"):
			_fail("TopDialogueOverlay missing in 1.2")
		else:
			overlay.call("show_line", "Pause guard probe line.")
			await process_frame
			if not bool(overlay.call("is_sequence_busy")):
				_fail("overlay not busy right after show_line (probe invalid)")
			elif bool(pause.call("request_pause")):
				_fail("pause should be refused while dialogue is busy")
				pause.call("request_unpause")
			if overlay.has_method("interrupt_line"):
				overlay.call("interrupt_line")

	if change_scene_to_file("res://combat/combat_test.tscn") == OK:
		for _i in 12:
			await process_frame
		if bool(pause.call("request_pause")):
			var menu := pause.get_node_or_null("AxelPauseMenu")
			var dev := menu.find_child("DevToolsButton", true, false) as Button if menu != null else null
			if OS.is_debug_build() and (dev == null or not dev.visible):
				_fail("combat pause menu missing visible Dev Tools")
			pause.call("request_unpause")
		else:
			_fail("pause should be allowed in combat")
	else:
		_fail("could not load combat_test")

	if _failures.is_empty():
		print("Pause contract check OK.")
		quit(0)
	else:
		for f in _failures:
			push_error("pause_contract_check: %s" % f)
		quit(1)


func _assert_inventory_clean(menu: Node, must_contain: String) -> void:
	var box := menu.find_child("LoadoutList", true, false) as Node
	if box == null:
		_fail("pause inventory box missing")
		return
	var texts: PackedStringArray = PackedStringArray()
	_collect_labels(box, texts)
	var blob := " ".join(texts)
	for leak in ["missing", "Memories", "Flashlight", "Key", "Shovel", "Name"]:
		if blob.contains(leak):
			_fail("pause inventory leaked '%s'" % leak)
	if not must_contain.is_empty() and not blob.contains(must_contain):
		_fail("pause inventory missing owned item '%s'" % must_contain)
	if not must_contain.is_empty():
		var saw_full := false
		for node in box.find_children("*", "TextureRect", true, false):
			var icon := node as TextureRect
			if icon == null or icon.texture == null:
				continue
			if icon.texture.get_width() == 1024 and icon.texture.get_height() == 1024:
				saw_full = true
				break
		if not saw_full:
			_fail("pause inventory icon resolution is not 1024x1024")


func _assert_no_inventory_button(menu: Node) -> void:
	for node in menu.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text == "Inventory":
			_fail("pause menu still has an Inventory button")


func _assert_loadout_details(menu: Node) -> void:
	var cap := menu.find_child("EquipCap", true, false) as Label
	if cap == null or cap.text != "1/7":
		_fail("equip cap should read 1/7, got %s" % (cap.text if cap != null else "missing"))
	var box := menu.find_child("LoadoutList", true, false) as Node
	if box == null:
		return
	var texts: PackedStringArray = PackedStringArray()
	_collect_labels(box, texts)
	var blob := " ".join(texts)
	if not blob.contains("Chalk Dust"):
		_fail("pause loadout missing second owned item")
	if not blob.contains("paid spin"):
		_fail("pause loadout missing item description")
	var equipped_on := false
	var boxes := 0
	for node in box.find_children("*", "CheckBox", true, false):
		var check := node as CheckBox
		boxes += 1
		if check.button_pressed:
			equipped_on = true
	if boxes < 2:
		_fail("pause loadout should have an equip box per combat item")
	if not equipped_on:
		_fail("equipped item checkbox should be on")


func _collect_labels(node: Node, texts: PackedStringArray) -> void:
	if node is Label:
		texts.append((node as Label).text)
	for child in node.get_children():
		_collect_labels(child, texts)


func _tap_escape() -> void:
	var press := InputEventKey.new()
	press.keycode = KEY_ESCAPE
	press.physical_keycode = KEY_ESCAPE
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventKey.new()
	release.keycode = KEY_ESCAPE
	release.physical_keycode = KEY_ESCAPE
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
