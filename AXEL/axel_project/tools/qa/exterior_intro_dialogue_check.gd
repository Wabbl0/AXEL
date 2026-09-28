extends SceneTree

const ROOM := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const FIRST_LINE := "You promised, you'd never come back."
const WINDOW := Vector2i(1920, 1280)

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_SKIP_INTRO", "0")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_POST_FX", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	var settings := root.get_node_or_null("AxelSettings")
	if settings != null and settings.has_method("set_value"):
		settings.call("set_value", "gameplay", "auto_advance", true)
	await process_frame
	change_scene_to_file(ROOM)
	if not await _wait_scene():
		_fail("1.1 failed to load")
		_finish()
		return
	var scene := current_scene
	var player := scene.get_node_or_null("PlayerLayer/Player") as CharacterBody2D
	var dialogue := scene.get_node_or_null("TopDialogueOverlay")
	if player == null or dialogue == null:
		_fail("player or dialogue missing")
		_finish()
		return
	if not await _wait_input_enabled(scene, player):
		_fail("intro did not unlock movement")
		_finish()
		return

	Input.action_press("move_right")
	var walked := await _walk_past_first_line_gate(scene, player, dialogue)
	Input.action_release("move_right")
	if not walked:
		_finish()
		return
	if str(dialogue.get("_active_line_text")) != FIRST_LINE:
		_fail("moving replaced the first line with '%s'" % str(dialogue.get("_active_line_text")))
	if bool(scene.get("_second_dialogue_fired")):
		_fail("walk-away lines started during the first line")
	if bool(scene.get("_watching_movement")):
		_fail("walk-away watch armed before the first line finished")
	if current_scene != scene:
		_fail("movement left 1.1 during the first line")
		_finish()
		return

	if not await _wait_second_line(scene, dialogue):
		_fail("walk-away lines did not start after the first line")
	elif str(dialogue.get("_active_line_text")).find("here we are") < 0 \
			and str(dialogue.get("_active_line_text")).find("Pathetic") < 0:
		_fail("second line text missing, got '%s'" % str(dialogue.get("_active_line_text")))
	_finish()


func _wait_scene() -> bool:
	for _i in 90:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ROOM:
			return true
	return false


func _wait_input_enabled(scene: Node, player: CharacterBody2D) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 40000:
		player.speed = 8000.0
		await process_frame
		if player.has_method("is_input_enabled") and player.is_input_enabled():
			if str(scene.get("_intro_state")) == "1" or int(scene.get("_intro_state")) == 1:
				return true
	return false


func _walk_past_first_line_gate(scene: Node, player: CharacterBody2D, dialogue: Node) -> bool:
	var start := Time.get_ticks_msec()
	var saw_first := false
	var nudged := false
	while Time.get_ticks_msec() - start < 8000:
		await process_frame
		var text := str(dialogue.get("_active_line_text"))
		if text.find("here we are") >= 0 or text.find("Pathetic") >= 0:
			_fail("first line was replaced while moving")
			return false
		if text == FIRST_LINE:
			saw_first = true
		if not nudged and Time.get_ticks_msec() - start > 500:
			var moved := player.global_position.distance_to(scene.get("_unlock_position"))
			if moved < 8.0:
				var gate := float(scene.call("_scaled_intro_distance", 50.0))
				player.global_position = scene.get("_unlock_position") + Vector2(gate + 40.0, 0.0)
				nudged = true
		if saw_first:
			var gate := float(scene.call("_scaled_intro_distance", 50.0))
			if player.global_position.distance_to(scene.get("_unlock_position")) >= gate:
				for _i in 30:
					await process_frame
				return true
	if not saw_first:
		_fail("first line never played")
	else:
		_fail("player never passed the walk-away distance")
	return false


func _wait_second_line(scene: Node, dialogue: Node) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 15000:
		_tap_advance()
		for _i in 8:
			await process_frame
		if bool(scene.get("_second_dialogue_fired")):
			var text_start := Time.get_ticks_msec()
			while Time.get_ticks_msec() - text_start < 4000:
				await process_frame
				var text := str(dialogue.get("_active_line_text"))
				if text.find("here we are") >= 0 or text.find("Pathetic") >= 0:
					return true
			return false
	return false


func _tap_advance() -> void:
	var press := InputEventAction.new()
	press.action = "dialogue_advance"
	press.pressed = true
	press.strength = 1.0
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = "dialogue_advance"
	release.pressed = false
	Input.parse_input_event(release)


func _finish() -> void:
	Input.action_release("move_right")
	if _failures.is_empty():
		print("Exterior intro dialogue check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("exterior_intro_dialogue_check: %s" % msg)
	quit(1)
