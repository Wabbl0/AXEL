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
	if src.find("start_interface_distortion(true)") < 0:
		_fail("1.1 intro wave must cross once")
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
	_assert_rest_pulse(pulse, "after room load")
	_assert_overworld_crt(scene)
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
	_assert_rest_pulse(pulse, "after pulse")
	await _check_intro_roll_once(fx, pulse)
	if is_instance_valid(scene):
		scene.queue_free()
	await process_frame


func _assert_rest_pulse(pulse: CanvasLayer, where: String) -> void:
	if not pulse.visible:
		_fail("%s: pulse overlay should stay visible" % where)
	var rect := pulse.get_node_or_null("FilterRect") as ColorRect
	if rect == null:
		_fail("%s: pulse FilterRect missing" % where)
		return
	if absf(rect.modulate.a - 0.20) > 0.05:
		_fail("%s: pulse alpha %.3f should stay near 0.20" % [where, rect.modulate.a])
	var mat := rect.material as ShaderMaterial
	if mat == null:
		_fail("%s: pulse shader missing" % where)
		return
	var roll := float(mat.get_shader_parameter("roll_amount"))
	if roll > 0.001:
		_fail("%s: roll_amount %.3f should be 0 between waves" % [where, roll])
	var glitch := float(mat.get_shader_parameter("glitch_shift"))
	if glitch > 0.0001:
		_fail("%s: glitch_shift %.4f should be 0 between waves" % [where, glitch])


func _check_intro_roll_once(fx: Node, pulse: CanvasLayer) -> void:
	fx.call("start_interface_distortion", true)
	await create_timer(0.05).timeout
	var early := _roll_amount(pulse)
	if early < 0.1:
		_fail("one-shot wave should start with the roll on (got %.3f)" % early)
	var start_y := _shader_number(pulse, "roll_center")
	if start_y < 1.0:
		_fail("wave should start below the screen (center %.3f)" % start_y)
	await create_timer(1.9).timeout
	var mid_y := _shader_number(pulse, "roll_center")
	if mid_y < 0.0 or mid_y > 1.0:
		_fail("wave should cross the middle of the screen (center %.3f)" % mid_y)
	await create_timer(2.3).timeout
	var late := _roll_amount(pulse)
	if late > 0.001:
		_fail("one-shot wave should finish after one pass (roll %.3f)" % late)
	if pulse.has_method("is_wave_active") and not bool(pulse.call("is_wave_active")):
		_fail("pulse should stay up after the single roll")
	var mat := _pulse_material(pulse)
	if mat != null:
		var raw: Variant = mat.get_shader_parameter("roll_color")
		var red := 0.0
		var green := 1.0
		var blue := 1.0
		if raw is Vector3:
			red = raw.x
			green = raw.y
			blue = raw.z
		elif raw is Color:
			red = raw.r
			green = raw.g
			blue = raw.b
		if red > 0.05 or green > 0.05 or blue > 0.05:
			_fail("wave color should be black, got %s" % raw)
		var strength := float(mat.get_shader_parameter("roll_color_strength"))
		if absf(strength - 0.224) > 0.02:
			_fail("wave opacity %.3f should stay near 0.224" % strength)
		var warp := _shader_number(pulse, "roll_warp")
		if absf(warp - 0.0045) > 0.0005:
			_fail("wave warp %.4f should stay near 0.0045" % warp)
	if fx.has_method("stop_interface_distortion"):
		await fx.call("stop_interface_distortion")
	_assert_rest_pulse(pulse, "after one-shot wave")


func _roll_amount(pulse: CanvasLayer) -> float:
	return _shader_number(pulse, "roll_amount")


func _shader_number(pulse: CanvasLayer, param: String) -> float:
	var mat := _pulse_material(pulse)
	if mat == null:
		return -1.0
	var raw: Variant = mat.get_shader_parameter(param)
	var kind := typeof(raw)
	if kind != TYPE_FLOAT and kind != TYPE_INT:
		return -1.0
	return float(raw)


func _pulse_material(pulse: CanvasLayer) -> ShaderMaterial:
	var rect := pulse.get_node_or_null("FilterRect") as ColorRect
	if rect == null:
		return null
	return rect.material as ShaderMaterial


func _assert_overworld_crt(scene: Node) -> void:
	var crt := scene.get_node_or_null("CrtPluginOverlay") as CanvasLayer
	if crt == null:
		_fail("overworld CrtPluginOverlay missing")
		return
	var rect := crt.get_node_or_null("FilterRect") as ColorRect
	if rect == null or not rect.material is ShaderMaterial:
		_fail("overworld CRT FilterRect missing")
		return
	var curv := float((rect.material as ShaderMaterial).get_shader_parameter("curvature"))
	if absf(curv) > 0.001:
		_fail("overworld CRT curvature %.3f should stay at 0" % curv)
