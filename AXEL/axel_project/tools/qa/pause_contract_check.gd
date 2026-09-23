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
		if pause_menu == null:
			_fail("pause menu missing")
		else:
			_assert_no_inventory_button(pause_menu)
			_assert_no_loadout(pause_menu)
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


func _assert_no_loadout(menu: Node) -> void:
	if menu.find_child("LoadoutList", true, false) != null:
		_fail("pause menu still lists items")
	if menu.find_child("EquipCap", true, false) != null:
		_fail("pause menu still shows the equip cap")
	if menu.has_method("_fill_loadout"):
		_fail("pause menu still builds a loadout")
	for node in menu.find_children("*", "CheckBox", true, false):
		if node != null and str(node.name) == "EquipBox":
			_fail("pause menu still has an equip box")


func _assert_no_inventory_button(menu: Node) -> void:
	for node in menu.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text == "Inventory":
			_fail("pause menu still has an Inventory button")


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
