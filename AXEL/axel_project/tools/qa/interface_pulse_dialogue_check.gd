extends SceneTree

const ROOM := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const INTRO_SCRIPT := "res://scenes/Arc_1/1.1_SchoolExterior.gd"
const WINDOW := Vector2i(1920, 1280)
const DIALOGUE_LAYER := 111
const PULSE_LAYER := 112
const GLITCH_LAYER := 113

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_SKIP_INTRO", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	await process_frame
	_check_intro_source_order()
	await _check_live_layers()
	if _failures.is_empty():
		print("Interface pulse dialogue check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("interface_pulse_dialogue_check: %s" % msg)
	quit(1)


func _check_intro_source_order() -> void:
	var src := FileAccess.get_file_as_string(INTRO_SCRIPT)
	if src.is_empty():
		_fail("could not read 1.1_SchoolExterior.gd")
		return
	var play_at := src.find("await _play_first_dialogue_line()")
	var stop_at := src.find("await AxelEventFx.stop_interface_distortion()")
	if play_at < 0 or stop_at < 0:
		_fail("1.1 intro must await first line and then stop the wave")
		return
	if stop_at < play_at:
		_fail("1.1 must keep the wave up through the first line")


func _check_live_layers() -> void:
	change_scene_to_file(ROOM)
	for _i in 24:
		await process_frame
	var scene := current_scene
	if scene == null:
		_fail("1.4 failed to load")
		return
	var dialogue := scene.get_node_or_null("TopDialogueOverlay") as CanvasLayer
	var fx := root.get_node_or_null("AxelEventFx")
	if dialogue == null or fx == null:
		_fail("missing TopDialogueOverlay or AxelEventFx")
		return
	var pulse: CanvasLayer = fx.call("get_interface_pulse")
	var glitch: CanvasLayer = fx.call("get_intro_glitch")
	if pulse == null:
		_fail("interface pulse overlay missing")
		return
	if pulse.layer != PULSE_LAYER:
		_fail("pulse layer %d should be %d" % [pulse.layer, PULSE_LAYER])
	if pulse.layer <= DIALOGUE_LAYER:
		_fail("pulse layer %d must sit above dialogue %d" % [pulse.layer, DIALOGUE_LAYER])
	if dialogue.layer != DIALOGUE_LAYER:
		_fail("dialogue layer %d should be %d" % [dialogue.layer, DIALOGUE_LAYER])
	if glitch == null:
		_fail("intro glitch overlay missing")
	elif glitch.layer != GLITCH_LAYER:
		_fail("glitch layer %d should be %d" % [glitch.layer, GLITCH_LAYER])
	elif glitch.layer <= pulse.layer:
		_fail("glitch layer %d must sit above pulse %d" % [glitch.layer, pulse.layer])
	var copy := pulse.get_node_or_null("BackBufferCopy") as BackBufferCopy
	if copy == null:
		_fail("pulse needs BackBufferCopy so the wave samples the dialogue bar")
	else:
		if copy.copy_mode != BackBufferCopy.COPY_MODE_VIEWPORT:
			_fail("pulse BackBufferCopy must copy the whole viewport")
		if copy.get_index() != 0:
			_fail("BackBufferCopy must draw before FilterRect")
	if not fx.has_method("start_interface_distortion"):
		_fail("AxelEventFx.start_interface_distortion missing")
		return
	fx.call("start_interface_distortion")
	if dialogue.has_method("show_line_nonblocking"):
		dialogue.call("show_line_nonblocking", "Wave persist probe.")
	elif dialogue.has_method("show_line"):
		dialogue.call("show_line", "Wave persist probe.", 3.0)
	await create_timer(0.5).timeout
	for _i in 8:
		await process_frame
	if pulse.has_method("is_wave_active") and not bool(pulse.call("is_wave_active")):
		_fail("wave should stay on while a dialogue line is showing")
	if dialogue.has_method("is_bar_visible") and not bool(dialogue.call("is_bar_visible")):
		_fail("dialogue bar should be up for the persist probe")
	if pulse.layer <= dialogue.layer:
		_fail("pulse must stay above the live dialogue layer")
	if fx.has_method("stop_interface_distortion"):
		await fx.call("stop_interface_distortion")
	if is_instance_valid(scene):
		scene.queue_free()
	await process_frame
