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
			var room_dev := pause_menu.find_child("DevToolsButton", true, false) as Button
			if OS.is_debug_build() and (room_dev == null or not room_dev.visible):
				_fail("room pause menu missing visible Dev Tools")
			_assert_encounters_can_be_blocked()
			await _assert_menu_centered(pause_menu, "1.2")

		await _tap_escape()
		if paused:
			_fail("Esc did not unpause")


		var overlay := current_scene.get_node_or_null("TopDialogueOverlay")
		if overlay == null or not overlay.has_method("show_line"):
			_fail("TopDialogueOverlay missing in 1.2")
		else:
			var probe := "Pause guard probe line."
			overlay.call("show_line", probe)
			await process_frame
			if not bool(overlay.call("is_sequence_busy")):
				_fail("overlay not busy right after show_line (probe invalid)")
			elif bool(pause.call("request_pause")):
				_fail("pause should be refused while dialogue is busy")
				pause.call("request_unpause")
			await _assert_escape_skips_line(overlay, probe, "1.2")
			if overlay.has_method("interrupt_line"):
				overlay.call("interrupt_line")

	if change_scene_to_file("res://scenes/Arc_1/1.3_LockerHub.tscn") == OK:
		for _i in 8:
			await process_frame
		var hub_overlay := current_scene.get_node_or_null("TopDialogueOverlay")
		if hub_overlay != null and bool(hub_overlay.call("is_sequence_busy")):
			await _assert_escape_skips_line(hub_overlay, "Oh look, a map of the school.", "locker hub")
			var hub_path := "" if current_scene == null else str(current_scene.scene_file_path)
			if not hub_path.ends_with("1.3_LockerHub.tscn"):
				_fail("Esc left the locker hub during first-visit dialogue")
			if paused:
				_fail("Esc paused in the locker hub during dialogue")
				pause.call("request_unpause")
		if hub_overlay != null and hub_overlay.has_method("interrupt_line"):
			hub_overlay.call("interrupt_line")
	else:
		_fail("could not load locker hub")

	if change_scene_to_file("res://combat/combat_test.tscn") == OK:
		for _i in 12:
			await process_frame
		if bool(pause.call("request_pause")):
			var menu := pause.get_node_or_null("AxelPauseMenu") as CanvasLayer
			var dev := menu.find_child("DevToolsButton", true, false) as Button if menu != null else null
			if OS.is_debug_build() and (dev == null or not dev.visible):
				_fail("combat pause menu missing visible Dev Tools")
			if menu == null or not menu.visible:
				_fail("pause menu not visible in combat")
			elif menu.layer <= 220:
				_fail("pause layer %d is not above combat overlays" % menu.layer)
			await _assert_menu_centered(menu, "combat")
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


func _assert_encounters_can_be_blocked() -> void:
	if not OS.is_debug_build():
		return
	var world := root.get_node_or_null("AxelWorld")
	if world == null or not world.has_method("set_encounters_suppressed"):
		_fail("AxelWorld encounter switch missing")
		return
	world.call("set_encounters_suppressed", true)
	var walk_started := bool(world.call("start_fight_here", "walk"))
	var item_started := bool(world.call("start_fight_here", "item_pickup"))
	var memory_started := bool(world.call("start_fight_to_scene", "memory", _ROOM))
	world.call("set_encounters_suppressed", false)
	if walk_started or item_started or memory_started:
		_fail("disabled encounters still started a fight")
	if bool(world.call("encounters_suppressed")):
		_fail("encounter switch stayed on after the check")


func _assert_menu_centered(menu: Node, where: String) -> void:
	if menu == null:
		_fail("%s pause menu missing" % where)
		return
	for _i in 3:
		await process_frame
	var column := menu.find_child("PauseColumn", true, false) as Control
	if column == null:
		_fail("%s pause column missing" % where)
		return
	var rect := column.get_global_rect()
	if rect.size.x < 8.0 or rect.size.y < 8.0:
		_fail("%s pause column has no size" % where)
		return
	var vp := Vector2(root.size)
	var mid := vp * 0.5
	var col_mid := rect.get_center()
	if col_mid.distance_to(mid) > 48.0:
		_fail(
			"%s pause column center %s is %.1f px from window center %s"
			% [where, col_mid, col_mid.distance_to(mid), mid]
		)
	var title := menu.find_child("PausedTitle", true, false) as Label
	if title == null or title.text != "PAUSED":
		_fail("%s PAUSED title missing" % where)
		return
	var title_mid := title.get_global_rect().get_center()
	if title_mid.y < vp.y * 0.2:
		_fail("%s PAUSED title is still near the top (y=%.1f)" % [where, title_mid.y])
	if absf(title_mid.x - mid.x) > 80.0:
		_fail("%s PAUSED title is %.1f px off horizontal center" % [where, absf(title_mid.x - mid.x)])


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


func _assert_escape_skips_line(overlay: Node, full_text: String, where: String) -> void:
	var label := overlay.find_child("LineLabel", true, false) as Label
	if label == null:
		_fail("%s dialogue label missing" % where)
		return
	var started := false
	for _i in 300:
		await process_frame
		if bool(overlay.call("is_line_ready")) or not label.text.is_empty():
			started = true
			break
	if not started:
		_fail("%s dialogue never started" % where)
		return
	var before_ready := bool(overlay.call("is_line_ready"))
	await _tap_escape()
	var skipped := false
	for _j in 30:
		await process_frame
		if paused:
			_fail("Esc paused during %s dialogue" % where)
			return
		if before_ready:
			if not bool(overlay.call("is_line_ready")):
				skipped = true
				break
		elif label.text == full_text or bool(overlay.call("is_line_ready")):
			skipped = true
			break
	if not skipped:
		_fail("Esc did not skip the %s dialogue line" % where)


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
