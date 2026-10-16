extends SceneTree

const _MENU := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const _ROOM := "res://scenes/Arc_1/1.2_Corridor.tscn"
const _OUTBOX := "user://feedback_qa_tmp_outbox"
const SpinLogScript := preload("res://scripts/core/feedback_spin_log.gd")

var _failures: Array[String] = []


class FakeRoot extends Node:
	signal spin_started(seed_value: int)
	signal spin_finished()
	signal vice_round_cleared()
	signal encounter_finished(success: bool)
	var bank := 3000.0
	var used := 0

	func get_bankroll() -> float:
		return bank

	func get_current_bet() -> float:
		return 50.0

	func get_free_spin_counter() -> Vector2i:
		return Vector2i.ZERO

	func is_bonus_skull_held() -> bool:
		return false

	func get_spins_used() -> int:
		return used

	func get_bets_used() -> int:
		return used * 50

	func get_last_spin_summary() -> Dictionary:
		return {"payout": 120, "line_payout": 120, "cascade_drops": 1, "wilds_placed": 0, "power_triggered": true, "grid_cleared": false}


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var fb := root.get_node_or_null("AxelFeedback")
	var pause := root.get_node_or_null("AxelPause")
	if fb == null or pause == null:
		push_error("feedback_check: AxelFeedback or AxelPause autoload missing")
		quit(1)
		return
	_clear_outbox()
	fb.set("outbox_dir", _OUTBOX)
	if bool(fb.call("can_send")):
		_fail("headless run must never send over the network")
	if str(fb.call("version")) != str(ProjectSettings.get_setting("application/config/version", "")):
		_fail("version should come from application/config/version")

	_check_spin_log()
	_check_validation(fb)

	if change_scene_to_file(_MENU) != OK:
		_fail("could not load main menu")
	else:
		for _i in 8:
			await process_frame
		if not bool(fb.call("is_bar_visible")):
			_fail("feedback bar should show on the title screen")
		var bar := fb.get_node_or_null("FeedbackBarLayer/FeedbackBar") as Control
		if bar == null:
			_fail("FeedbackBar node missing")
		else:
			var view := Vector2(root.size)
			if absf(bar.position.y + bar.size.y - view.y) > 1.0:
				_fail("bar should sit on the bottom edge, got %s size %s" % [bar.position, bar.size])
			if absf(bar.size.x - view.x) > 1.0:
				_fail("bar should span the full width, got %s" % bar.size)
			await _click(bar.get_global_rect().get_center())
			if not bool(fb.call("is_form_open")):
				_fail("clicking the bar should open the form")
			await process_frame
			if bool(fb.call("is_bar_visible")):
				_fail("bar should hide while the form is open")
			await _tap_escape()
			if bool(fb.call("is_form_open")):
				_fail("Esc should close the form")
			if current_scene == null or current_scene.scene_file_path != _MENU:
				_fail("closing the form must stay on the title")
		await _check_form_submit(fb)

	if change_scene_to_file(_ROOM) != OK:
		_fail("could not load 1.2 corridor")
	else:
		for _i in 10:
			await process_frame
		var overlay := current_scene.get_node_or_null("TopDialogueOverlay")
		if overlay != null and overlay.has_method("interrupt_line"):
			overlay.call("interrupt_line")
		for _i in 4:
			await process_frame
		if bool(fb.call("is_bar_visible")):
			_fail("bar must stay hidden during gameplay")
		if not bool(pause.call("request_pause")):
			_fail("could not pause in 1.2")
		await process_frame
		await process_frame
		if not bool(fb.call("is_bar_visible")):
			_fail("bar should show on the pause menu")
		fb.call("open_form")
		await process_frame
		await _tap_escape()
		if bool(fb.call("is_form_open")):
			_fail("Esc should close the form during pause")
		if not paused:
			_fail("closing the form must not unpause")
		pause.call("request_unpause")
		await process_frame
		await process_frame
		if bool(fb.call("is_bar_visible")):
			_fail("bar should hide again after unpause")

	_clear_outbox()
	if _failures.is_empty():
		print("feedback_check: OK")
		quit(0)
	else:
		for f in _failures:
			push_error("feedback_check: " + f)
		quit(1)


func _check_spin_log() -> void:
	var log_obj = SpinLogScript.new()
	var fake := FakeRoot.new()
	root.add_child(fake)
	log_obj.begin_fight(fake, {"fight": 3, "seed": 777, "goal": 80})
	fake.spin_started.emit(11)
	fake.used = 1
	fake.bank = 3070.0
	fake.spin_finished.emit()
	fake.spin_finished.emit()
	fake.encounter_finished.emit(true)
	var snap: Dictionary = log_obj.snapshot()
	var spins: Array = snap.get("spins", [])
	var fights: Array = snap.get("fights", [])
	if spins.size() != 1:
		_fail("spin log should record one spin, got %d" % spins.size())
	elif int(spins[0].get("payout", 0)) != 120 or int(spins[0].get("seed", 0)) != 11 or int(spins[0].get("fight_seed", 0)) != 777:
		_fail("spin row wrong: %s" % spins[0])
	if fights.size() != 1 or str(fights[0].get("result", "")) != "win":
		_fail("fight row should be a win, got %s" % [fights])
	fake.queue_free()


func _check_validation(fb: Node) -> void:
	if str(fb.call("validate", {})) == "":
		_fail("overall score must be required")
	if str(fb.call("validate", {"overall": "3", "age": "5"})) == "":
		_fail("age 5 must be rejected")
	if str(fb.call("validate", {"overall": "3", "age": "111"})) == "":
		_fail("age 111 must be rejected")
	if str(fb.call("validate", {"overall": "3", "age": "42"})) != "":
		_fail("age 42 must pass")
	if str(fb.call("validate", {"overall": "3", "one_word": "two words"})) == "":
		_fail("one-word answer with a space must be rejected")
	var without: Dictionary = fb.call("build_payload", {"overall": "3"}, false)
	if not (without.get("game_data", {}) as Dictionary).is_empty():
		_fail("game data must be empty when the box is unticked")


func _check_form_submit(fb: Node) -> void:
	var form = fb.call("open_form")
	await process_frame
	if form == null:
		_fail("open_form returned null")
		return
	form.call("press_send")
	if not str(form.call("status_text")).to_lower().contains("overall"):
		_fail("sending without an overall score should explain why, got '%s'" % form.call("status_text"))
	if (fb.call("outbox_files") as PackedStringArray).size() != 0:
		_fail("a blocked send must not write the outbox")
	for pair in [["overall", "4"], ["difficulty", "Just right"], ["gender", "Non-binary"], ["progress", "Cafeteria"]]:
		if not bool(form.call("set_choice", pair[0], pair[1])):
			_fail("could not pick %s = %s" % pair)
	form.call("set_text", "one_word", "creepy")
	form.call("set_text", "comments", "Loved the CRT look.")
	form.call("set_text", "age", "29")
	form.call("set_send_game_data", true)
	form.call("press_send")
	var files: PackedStringArray = fb.call("outbox_files")
	if files.size() != 1:
		_fail("a valid send should write one outbox file, got %d" % files.size())
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(files[0]))
	if not (data is Dictionary):
		_fail("outbox file is not JSON")
		return
	var answers: Dictionary = data.get("answers", {})
	if str(answers.get("overall", "")) != "4" or str(answers.get("gender", "")) != "Non-binary" or str(answers.get("age", "")) != "29":
		_fail("answers not saved right: %s" % answers)
	if str(data.get("token", "")) == "" or str(data.get("version", "")) == "":
		_fail("payload needs token and version")
	var game: Dictionary = data.get("game_data", {})
	for key in ["run_seed", "balance", "fights", "spins", "playtime_min"]:
		if not game.has(key):
			_fail("game data missing %s" % key)
	for _i in 4:
		await process_frame
	if bool(fb.call("is_form_open")):
		fb.call("close_form")
		await process_frame


func _click(pos: Vector2) -> void:
	for down in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = down
		ev.position = pos
		ev.global_position = pos
		root.push_input(ev)
		await process_frame


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


func _clear_outbox() -> void:
	var dir := DirAccess.open(_OUTBOX)
	if dir == null:
		return
	for f in dir.get_files():
		dir.remove(f)
	DirAccess.remove_absolute(_OUTBOX)
