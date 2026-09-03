extends SceneTree
## AxelPause contract regression check (Phase 0.6, D6).
##
## Asserts:
## 1. Esc (pause action) toggles tree pause in a gameplay room.
## 2. The player freezes while paused (held D does not move Mike).
## 3. Pause is refused while TopDialogueOverlay is mid-sequence.
## 4. Pause is refused on the main menu.
## 5. AxelMusic runs in PROCESS_MODE_ALWAYS (BGM survives pause).
##
## Run: tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/pause_contract_check.gd

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

	# 5. Music process mode.
	if music != null and music.process_mode != Node.PROCESS_MODE_ALWAYS:
		_fail("AxelMusic.process_mode should be ALWAYS, got %d" % music.process_mode)

	# 4. Refused on the main menu (menu is the boot scene).
	if change_scene_to_file(_MENU) != OK:
		_fail("could not load main menu")
	else:
		for _i in 6:
			await process_frame
		if bool(pause.call("request_pause")):
			_fail("pause should be refused on the main menu")
			pause.call("request_unpause")

	# Load a gameplay room.
	if change_scene_to_file(_ROOM) != OK:
		_fail("could not load 1.2 corridor")
	else:
		for _i in 10:
			await process_frame

		# 1.2 auto-plays its enter line; end it so the dialogue guard is idle.
		var enter_overlay := current_scene.get_node_or_null("TopDialogueOverlay")
		if enter_overlay != null and enter_overlay.has_method("interrupt_line"):
			enter_overlay.call("interrupt_line")
		for _i in 4:
			await process_frame

		# 1. Esc toggles pause through the real input pipeline.
		await _tap_escape()
		if not paused:
			_fail("Esc did not pause in 1.2 corridor")

		# 2. Player frozen while paused.
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

		# Esc again unpauses.
		await _tap_escape()
		if paused:
			_fail("Esc did not unpause")

		# 3. Refused while dialogue busy.
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

	if _failures.is_empty():
		print("Pause contract check OK.")
		quit(0)
	else:
		for f in _failures:
			push_error("pause_contract_check: %s" % f)
		quit(1)


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
