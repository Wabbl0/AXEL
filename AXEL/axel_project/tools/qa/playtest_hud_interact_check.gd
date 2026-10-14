extends SceneTree

const ROOM := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const BASEMENT := "res://scenes/Arc_6/6.1_BasementDoor.tscn"
const COMBAT := "res://combat/combat_test.tscn"
const WINDOW := Vector2i(1920, 1280)

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_WORLD_COMBAT", "0")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	await process_frame
	await _check_door_chip()
	await _check_combat_hud()
	if _failures.is_empty():
		print("Playtest HUD / interact check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("playtest_hud_interact_check: %s" % msg)
	quit(1)


func _check_door_chip() -> void:
	var gm := root.get_node_or_null("GameManager")
	if gm != null:
		gm.basement_door_line_seen = true
	change_scene_to_file(ROOM)
	for _i in 24:
		await process_frame
	var scene := current_scene
	if scene == null:
		_fail("1.4 failed to load")
		return
	var prompt := scene.get_node_or_null("InteractPromptOverlay")
	var dialogue := scene.get_node_or_null("TopDialogueOverlay")
	var player := scene.get_node_or_null("PlayerLayer/Player") as Node2D
	var door := scene.get_node_or_null("WalkableWorld/EnvironmentColliders/DoorInteractArea") as Area2D
	if prompt == null or dialogue == null or player == null or door == null:
		_fail("1.4 missing prompt, dialogue, player, or door")
		return
	if prompt.get("screen_offset") != Vector2(0, -52) and prompt.get("screen_offset") != Vector2.ZERO:
		_fail("door overlay offset should stay 0 or leftover -52, got %s" % prompt.get("screen_offset"))
	player.global_position = door.global_position
	for _i in 8:
		await process_frame
	if scene.has_method("_refresh_active_zones"):
		scene.call("_refresh_active_zones")
	if dialogue.has_method("is_sequence_busy") and not bool(dialogue.call("is_sequence_busy")):
		if dialogue.has_method("show_line"):
			dialogue.call("show_line", "Testing.", 3.0)
	for _i in 8:
		await process_frame
	if prompt.has_method("is_prompt_visible") and not bool(prompt.call("is_prompt_visible")):
		_fail("door [E] should stay visible while a line is playing")
	if dialogue.has_method("interrupt_line"):
		dialogue.call("interrupt_line")
	for _i in 4:
		await process_frame
	if scene.has_method("on_zone_interact"):
		scene.call("on_zone_interact", "door")
	for _i in 120:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == BASEMENT:
			break
	if current_scene == null or current_scene.scene_file_path != BASEMENT:
		_fail("1.4 door [E] did not open 6.1")
	await process_frame


func _check_combat_hud() -> void:
	var packed := load(COMBAT) as PackedScene
	if packed == null:
		_fail("could not load combat_test")
		return
	var vp := SubViewport.new()
	vp.size = WINDOW
	root.add_child(vp)
	var scene := packed.instantiate() as Control
	vp.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	for _i in 16:
		await process_frame
	var skull := scene.find_child("PremiumSkull", true, false) as Control
	if skull == null:
		_fail("PremiumSkull missing")
	elif absf(skull.scale.x - 0.85) > 0.02 or absf(skull.scale.y - 0.85) > 0.02:
		_fail("PremiumSkull scale should be 0.85, got %s" % skull.scale)
	var execute := scene.find_child("NEW_Execute", true, false) as Control
	if execute == null:
		_fail("NEW_Execute missing")
	elif absf(execute.size.x - 692.0) > 2.0 or absf(execute.size.y - 922.0) > 2.0:
		_fail("NEW_Execute box changed size: %s" % execute.size)
	var slot_script := load("res://combat/scripts/symbol_slot.gd") as GDScript
	if slot_script != null:
		var consts: Dictionary = slot_script.get_script_constant_map()
		if int(consts.get("WIN_POPUP_FONT_SIZE", 0)) != 70:
			_fail("WIN_POPUP_FONT_SIZE should be 70, got %s" % consts.get("WIN_POPUP_FONT_SIZE"))
	var mult := scene.find_child("CascadeMultiplierReadout", true, false) as Label
	if mult == null:
		_fail("cascade multiplier label missing")
	else:
		if mult.get_visible_line_count() < 1 and not str(mult.text).is_empty():
			_fail("cascade multiplier text is not visible")
	scene.queue_free()
	vp.queue_free()
	await process_frame
