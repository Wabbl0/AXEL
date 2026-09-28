extends SceneTree

const TITLE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const OPTIONS := "res://scenes/Main_Menu/Options.tscn"
const QUIET_MIN := 10.0
const QUIET_MAX := 30.0

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	if change_scene_to_file(TITLE) != OK:
		_fail("could not open title")
		_finish()
		return
	for _i in 6:
		await process_frame

	var bg := current_scene.find_child("MenuBackdrop", true, false) as TextureRect
	if bg == null or bg.get_script() == null:
		_fail("title backdrop is missing its glitch script")
		_finish()
		return
	var layer := bg.get_parent() as CanvasLayer
	if layer == null or layer.layer != 100:
		_fail("backdrop layer should stay at 100")
	var chrome := current_scene.find_child("MenuChrome", true, false) as CanvasLayer
	if chrome == null or chrome.layer != 110:
		_fail("menu buttons should stay on layer 110")
	var title := current_scene.find_child("TitleLabel", true, false) as Label
	if title != null and title.material != null:
		_fail("title text should not use the backdrop shader")

	var mat := bg.material as ShaderMaterial
	if mat == null or mat.shader == null:
		_fail("backdrop shader missing")
		_finish()
		return
	if not str(mat.shader.resource_path).ends_with("menu_backdrop_glitch.gdshader"):
		_fail("backdrop shader path %s" % str(mat.shader.resource_path))
	elif float(mat.get_shader_parameter("amount")) > 0.001:
		_fail("glitch should be quiet when the menu opens")

	var lo := QUIET_MAX
	var hi := QUIET_MIN
	for _n in 40:
		bg.call("_schedule")
		var wait := float(bg.get("_wait_left"))
		if wait < QUIET_MIN or wait > QUIET_MAX:
			_fail("quiet gap %.3f is outside 10-30" % wait)
			break
		lo = minf(lo, wait)
		hi = maxf(hi, wait)
	if lo > 16.0 or hi < 22.0:
		_fail("quiet gap spread too narrow (%.2f-%.2f)" % [lo, hi])

	var blocked := bool(bg.call("_fx_blocked"))
	if blocked:
		bg.set("_wait_left", 0.0)
		bg.set("_burst_left", 0.0)
		bg.call("_process", 0.2)
		if float(bg.get("_burst_left")) > 0.0:
			_fail("glitch fired while flashing is reduced or event fx is off")
	else:
		_check_gap(bg, mat)

	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	bg.set("_wait_left", 0.0)
	bg.set("_burst_left", 0.0)
	bg.call("_set_quiet")
	bg.call("_process", 0.2)
	if float(bg.get("_burst_left")) > 0.0 or float(mat.get_shader_parameter("amount")) > 0.001:
		_fail("AXEL_DISABLE_EVENT_FX should skip the title glitch")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "0")

	if change_scene_to_file(OPTIONS) != OK:
		_fail("could not open options")
	else:
		for _i in 6:
			await process_frame
		var options_bg := current_scene.find_child("MenuBackdrop", true, false) as TextureRect
		if options_bg == null:
			_fail("options backdrop missing")
		elif options_bg.get_script() != null:
			_fail("options backdrop should not glitch")

	_finish()


func _check_gap(bg: TextureRect, mat: ShaderMaterial) -> void:
	bg.call("_schedule")
	var wait := float(bg.get("_wait_left"))
	bg.call("_process", wait - 0.05)
	if float(bg.get("_burst_left")) > 0.0:
		_fail("glitch started before the quiet gap ended")
		return
	bg.call("_process", 0.1)
	if float(bg.get("_burst_left")) <= 0.0:
		_fail("glitch did not start after the quiet gap")
		return
	var strength := float(bg.call("_intensity"))
	if float(mat.get_shader_parameter("amount")) < 0.4 * strength:
		_fail("glitch amount stayed at %.3f" % float(mat.get_shader_parameter("amount")))
	bg.call("_process", 2.0)
	if float(bg.get("_burst_left")) > 0.0:
		_fail("glitch did not end")
	if float(mat.get_shader_parameter("amount")) > 0.001:
		_fail("glitch amount stayed up after the burst")
	var next_wait := float(bg.get("_wait_left"))
	if next_wait < QUIET_MIN or next_wait > QUIET_MAX:
		_fail("cooldown after burst is %.3f" % next_wait)
		return
	bg.call("_process", next_wait - 0.05)
	if float(bg.get("_burst_left")) > 0.0:
		_fail("next glitch started inside the 10s cooldown")


func _finish() -> void:
	if _failures.is_empty():
		print("Menu backdrop glitch check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("menu_backdrop_glitch_check: %s" % msg)
	quit(1)
