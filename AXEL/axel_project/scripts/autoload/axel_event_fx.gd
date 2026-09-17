extends Node

const GLITCH_SCENE := "res://scenes/fx/IntroGlitchOverlay.tscn"
const PULSE_SCENE := "res://scenes/fx/InterfacePulseOverlay.tscn"
const SCENE_1_1 := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const CombatWipeScript := preload("res://scenes/fx/combat_wipe_overlay.gd")
const COMBAT_WIPE_MAX_SEC := 4.0

const ENTER_GLITCH_DURATION := 0.65
const DEFAULT_GLITCH_DURATION := 0.85
const DEFAULT_PULSE_DURATION := 1.1

const CADENCE_TIMER_MIN := 30.0
const CADENCE_TIMER_MAX := 60.0
const CADENCE_STEPS_MIN := 40
const CADENCE_STEPS_MAX := 90
const CADENCE_COOLDOWN_SEC := 30.0

var _glitch: CanvasLayer
var _pulse: CanvasLayer
var _combat_wipe: CanvasLayer
var _wipe_guard_left := 0.0

var _active_scene: Node = null
var _cadence_enabled := true
var _cadence_active := false
var _timer_elapsed := 0.0
var _timer_target := 45.0
var _steps_accumulated := 0
var _steps_target := 65
var _cooldown_remaining := 0.0
var _pulse_in_progress := false
var _enter_glitch_pending := false


func _ready() -> void:
	_glitch = _instantiate_overlay(GLITCH_SCENE) as CanvasLayer
	_pulse = _instantiate_overlay(PULSE_SCENE) as CanvasLayer
	if _glitch != null:
		add_child(_glitch)
	if _pulse != null:
		add_child(_pulse)
	_combat_wipe = CombatWipeScript.new()
	_combat_wipe.name = "CombatWipeOverlay"
	add_child(_combat_wipe)

	var tree := get_tree()
	if tree == null:
		return
	if not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	call_deferred("_on_scene_changed")


func _process(delta: float) -> void:
	if _wipe_guard_left > 0.0:
		_wipe_guard_left -= delta
		if _wipe_guard_left <= 0.0:
			clear_combat_wipe()
	if not _cadence_active or not _cadence_enabled or _pulse_in_progress:
		return
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
		return

	_timer_elapsed += delta
	if _timer_elapsed >= _timer_target or _steps_accumulated >= _steps_target:
		_fire_cadence_pulse()


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	_active_scene = scene
	_reset_cadence_state()

	if scene == null:
		_cadence_active = false
		_set_ambient(false)
		return

	if _should_skip_event_fx(scene):
		_cadence_active = false
		_set_ambient(false)
		return

	_cadence_active = true
	_set_ambient(true)
	_arm_cadence_targets()

	if not _should_skip_enter_glitch(scene):
		call_deferred("_play_enter_glitch_deferred")


func _should_skip_event_fx(scene: Node) -> bool:

	if _is_combat_scene(scene) and not AxelPostFxStack.COMBAT_ROOM_FX_TEST:
		return true
	if OS.has_environment("AXEL_DISABLE_POST_FX") and OS.get_environment("AXEL_DISABLE_POST_FX") == "1":
		return true
	if OS.has_environment("AXEL_DISABLE_EVENT_FX") and OS.get_environment("AXEL_DISABLE_EVENT_FX") == "1":
		return true
	if scene.get_node_or_null("StyleSweepOverlays") != null:
		return true
	return false


static func _is_combat_scene(scene: Node) -> bool:
	if scene == null:
		return false
	var path := scene.scene_file_path
	return not path.is_empty() and path.begins_with("res://combat/")


func _should_skip_enter_glitch(scene: Node) -> bool:
	if scene.scene_file_path == SCENE_1_1:
		if not _intro_skipped():
			return true
	return false


static func _intro_skipped() -> bool:
	return OS.has_environment("AXEL_SKIP_INTRO") and OS.get_environment("AXEL_SKIP_INTRO") == "1"


func _play_enter_glitch_deferred() -> void:
	if _enter_glitch_pending:
		return
	if _active_scene == null or _should_skip_event_fx(_active_scene):
		return
	_enter_glitch_pending = true
	await play_glitch_burst(ENTER_GLITCH_DURATION)
	_enter_glitch_pending = false


func _reset_cadence_state() -> void:
	_timer_elapsed = 0.0
	_steps_accumulated = 0
	_cooldown_remaining = 0.0
	_pulse_in_progress = false


func _arm_cadence_targets() -> void:
	_timer_elapsed = 0.0
	_timer_target = randf_range(CADENCE_TIMER_MIN, CADENCE_TIMER_MAX)
	_steps_accumulated = 0
	_steps_target = randi_range(CADENCE_STEPS_MIN, CADENCE_STEPS_MAX)


func _fire_cadence_pulse() -> void:
	if _reduce_flashing() or _glitch_scale() <= 0.05:
		_reset_cadence_state()
		return
	if _pulse_in_progress or _cooldown_remaining > 0.0:
		return
	_pulse_in_progress = true
	_cooldown_remaining = CADENCE_COOLDOWN_SEC
	_arm_cadence_targets()
	_run_cadence_pulse_async()


func _run_cadence_pulse_async() -> void:
	await play_interface_pulse(DEFAULT_PULSE_DURATION)
	_pulse_in_progress = false


func set_cadence_enabled(enabled: bool) -> void:
	_cadence_enabled = enabled
	if enabled and _cadence_active:
		_arm_cadence_targets()


func is_cadence_enabled() -> bool:
	return _cadence_enabled and _cadence_active


func register_walk_step() -> void:
	if not _cadence_active or not _cadence_enabled or _pulse_in_progress:
		return
	if _cooldown_remaining > 0.0:
		return
	_steps_accumulated += 1
	if _steps_accumulated >= _steps_target:
		_fire_cadence_pulse()


func play_combat_wipe() -> void:
	if _combat_wipe == null or not is_instance_valid(_combat_wipe):
		return
	if _event_fx_disabled():
		return
	_wipe_guard_left = COMBAT_WIPE_MAX_SEC
	await _combat_wipe.call("close_wipe")


func clear_combat_wipe() -> void:
	_wipe_guard_left = 0.0
	if _combat_wipe == null or not is_instance_valid(_combat_wipe):
		return
	if not bool(_combat_wipe.call("is_covered")):
		_combat_wipe.call("clear_now")
		return
	await _combat_wipe.call("open_wipe")


func is_combat_wipe_covered() -> bool:
	if _combat_wipe == null or not is_instance_valid(_combat_wipe):
		return false
	return bool(_combat_wipe.call("is_covered"))


static func _event_fx_disabled() -> bool:
	if OS.has_environment("AXEL_DISABLE_POST_FX") and OS.get_environment("AXEL_DISABLE_POST_FX") == "1":
		return true
	return OS.has_environment("AXEL_DISABLE_EVENT_FX") and OS.get_environment("AXEL_DISABLE_EVENT_FX") == "1"


func play_glitch_burst(duration_sec: float = DEFAULT_GLITCH_DURATION) -> void:
	if _reduce_flashing():
		return
	if _glitch == null or not is_instance_valid(_glitch):
		return
	if not _glitch.has_method("play_burst"):
		return
	await _glitch.play_burst(duration_sec * _glitch_scale())


func play_interface_pulse(duration_sec: float = DEFAULT_PULSE_DURATION) -> void:
	if _reduce_flashing():
		return
	if _pulse == null or not is_instance_valid(_pulse):
		return
	if not _pulse.has_method("play_pulse"):
		return
	await _pulse.play_pulse(duration_sec * _glitch_scale())


func start_interface_distortion() -> void:
	if _pulse != null and is_instance_valid(_pulse) and _pulse.has_method("start_distortion"):
		_pulse.start_distortion()


func stop_interface_distortion() -> void:
	if _pulse != null and is_instance_valid(_pulse) and _pulse.has_method("stop_distortion"):
		await _pulse.stop_distortion()


func play_jumpscare(
	glitch_duration_sec: float = DEFAULT_GLITCH_DURATION,
	pulse_duration_sec: float = DEFAULT_PULSE_DURATION,
) -> void:
	await play_glitch_burst(glitch_duration_sec)
	await play_interface_pulse(pulse_duration_sec)


func apply_to_scene(scene: Node) -> void:
	_active_scene = scene
	_reset_cadence_state()
	if scene == null:
		_cadence_active = false
		_set_ambient(false)
		return
	if _should_skip_event_fx(scene):
		_cadence_active = false
		_set_ambient(false)
		return
	_cadence_active = true
	_set_ambient(true)
	_arm_cadence_targets()


func _set_ambient(enabled: bool) -> void:
	if _pulse == null or not is_instance_valid(_pulse):
		return
	if enabled:
		if _pulse.has_method("start_ambient"):
			_pulse.start_ambient()
	else:
		if _pulse.has_method("stop_ambient"):
			_pulse.stop_ambient()


func _reduce_flashing() -> bool:
	var settings := get_node_or_null("/root/AxelSettings")
	if settings == null:
		return false
	return bool(settings.call("get_value", "access", "reduce_flashing", false))


func _glitch_scale() -> float:
	var settings := get_node_or_null("/root/AxelSettings")
	if settings == null:
		return 1.0
	return clampf(float(settings.call("get_value", "access", "glitch_intensity", 1.0)), 0.0, 1.0)


func _instantiate_overlay(packed_path: String) -> Node:
	if not ResourceLoader.exists(packed_path):
		push_warning("AxelEventFx: missing overlay scene %s" % packed_path)
		return null
	var packed := load(packed_path) as PackedScene
	if packed == null:
		return null
	return packed.instantiate()
