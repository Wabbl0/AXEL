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
const CADENCE_TIMER_MAX := 30.0
const CADENCE_STEPS_MIN := 40
const CADENCE_STEPS_MAX := 90
const CADENCE_COOLDOWN_SEC := 0.0

var _glitch: CanvasLayer
var _pulse: CanvasLayer
var _combat_wipe: CanvasLayer
var _wipe_guard_left := 0.0

var _active_scene: Node = null
var _cadence_enabled := true
var _cadence_active := false
var _timer_elapsed := 0.0
var _timer_target := 30.0
var _steps_accumulated := 0
var _steps_target := 65
var _cooldown_remaining := 0.0
var _pulse_in_progress := false
var _enter_glitch_pending := false
var _skip_next_enter_glitch := false
const ROUND_COMPLETE_SCRIM_A := 0.72
const ROUND_COMPLETE_TEXT := "Round Complete!"
const FLAME_BURST_SCRIPT := preload("res://combat/scripts/flame_burst.gd")

var _round_fade: CanvasLayer
var _round_root: Control
var _round_scrim: ColorRect
var _round_flames: Control
var _round_label: RichTextLabel
var _round_bets_label: Label
var _round_balance_label: Label
var _round_hop: Tween

const LOAD_COVER_LAYER := 120
const LOAD_FADE_SEC := 0.35
var _load_cover: CanvasLayer
var _load_scrim: ColorRect
var _load_cover_holding := false
var _intro_pose_ready := false


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
	_build_round_complete_overlay()
	_ensure_load_cover()

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
	if _timer_elapsed >= _timer_target:
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
	# Rest pulse stays on. The rolling wave is only the 30s burst.
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
	if _skip_next_enter_glitch:
		_skip_next_enter_glitch = false
		return true
	if scene.scene_file_path == SCENE_1_1:
		if not _intro_skipped():
			return true
	return false


func skip_next_enter_glitch() -> void:
	_skip_next_enter_glitch = true


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
	# Walk steps no longer advance cadence. Kept so Player.gd still compiles.
	return


func show_round_complete_card(bets_used: int = 0, balance: int = 0) -> void:
	skip_next_enter_glitch()
	_ensure_round_complete_overlay()
	_layout_round_complete()
	if _round_fade == null or _round_scrim == null or _round_label == null:
		return
	_round_fade.visible = true
	if _round_root != null:
		_round_root.visible = true
	_round_scrim.color = Color(0, 0, 0, ROUND_COMPLETE_SCRIM_A)
	_round_scrim.visible = true
	_round_label.text = _round_complete_bbcode()
	_round_label.modulate.a = 1.0
	_round_label.visible = true
	if _round_bets_label != null:
		_round_bets_label.text = "Bets used: %d" % bets_used
		_round_bets_label.visible = true
	if _round_balance_label != null:
		_round_balance_label.text = "Current balance: %d" % balance
		_round_balance_label.visible = true
	_start_round_hop()
	_start_round_flames()


func play_round_complete_fade() -> void:
	_stop_round_hop()
	skip_next_enter_glitch()
	if _event_fx_disabled():
		return
	_ensure_round_complete_overlay()
	_layout_round_complete()
	if _round_scrim == null or _round_label == null:
		return
	_round_fade.visible = true
	if _round_root != null:
		_round_root.visible = true
	_round_label.visible = true
	_round_label.modulate.a = 1.0
	if _round_bets_label != null:
		_round_bets_label.visible = true
	if _round_balance_label != null:
		_round_balance_label.visible = true
	var fade_in := CombatPace.bind(create_tween())
	fade_in.tween_property(_round_scrim, "color:a", 1.0, 0.35)
	await fade_in.finished


func finish_round_complete_fade() -> void:
	if _event_fx_disabled():
		_hide_round_complete()
		return
	_ensure_round_complete_overlay()
	if _round_scrim == null:
		_hide_round_complete()
		return
	_round_fade.visible = true
	_round_scrim.color = Color(0, 0, 0, 1)
	if _round_label != null:
		_round_label.visible = false
	if _round_bets_label != null:
		_round_bets_label.visible = false
	if _round_balance_label != null:
		_round_balance_label.visible = false
	var fade_out := CombatPace.bind(create_tween())
	fade_out.tween_property(_round_scrim, "color:a", 0.0, 0.35)
	await fade_out.finished
	_hide_round_complete()


func get_round_complete_scrim() -> ColorRect:
	_ensure_round_complete_overlay()
	return _round_scrim


func is_load_cover_up() -> bool:
	return _load_cover_holding


func notify_intro_pose_ready() -> void:
	_intro_pose_ready = true


func fade_to_black() -> void:
	_ensure_load_cover()
	_intro_pose_ready = false
	_load_cover_holding = true
	_load_cover.visible = true
	_layout_load_cover()
	if _load_fade_instant():
		_load_scrim.color = Color(0, 0, 0, 1)
		if get_tree() != null:
			await get_tree().process_frame
		return
	_load_scrim.color = Color(0, 0, 0, 0)
	var fade_in := create_tween()
	fade_in.tween_property(_load_scrim, "color:a", 1.0, LOAD_FADE_SEC)
	await fade_in.finished
	if get_tree() != null:
		await get_tree().process_frame


func fade_from_black() -> void:
	if _load_scrim == null:
		_load_cover_holding = false
		return
	if _load_fade_instant():
		_load_scrim.color = Color(0, 0, 0, 0)
		if _load_cover != null:
			_load_cover.visible = false
		_load_cover_holding = false
		if get_tree() != null:
			await get_tree().process_frame
		return
	var fade_out := create_tween()
	fade_out.tween_property(_load_scrim, "color:a", 0.0, LOAD_FADE_SEC)
	await fade_out.finished
	if _load_cover != null:
		_load_cover.visible = false
	_load_cover_holding = false


func reveal_after_intro_pose() -> void:
	var guard := 0
	while not _intro_pose_ready and guard < 180:
		guard += 1
		if get_tree() == null:
			return
		await get_tree().process_frame
	await fade_from_black()


func wait_load_cover_clear() -> void:
	var guard := 0
	while _load_cover_holding and guard < 600:
		guard += 1
		if get_tree() == null:
			return
		await get_tree().process_frame


func _load_fade_instant() -> bool:
	return DisplayServer.get_name() == "headless"


func _ensure_load_cover() -> void:
	if _load_cover != null:
		return
	_load_cover = CanvasLayer.new()
	_load_cover.name = "LoadCover"
	_load_cover.layer = LOAD_COVER_LAYER
	_load_cover.process_mode = Node.PROCESS_MODE_ALWAYS
	_load_cover.visible = false
	add_child(_load_cover)
	_load_scrim = ColorRect.new()
	_load_scrim.name = "LoadScrim"
	_load_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_load_scrim.color = Color(0, 0, 0, 0)
	_load_cover.add_child(_load_scrim)
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_layout_load_cover):
		vp.size_changed.connect(_layout_load_cover)
	_layout_load_cover()


func _layout_load_cover() -> void:
	if _load_scrim == null:
		return
	var size := _viewport_size()
	_load_scrim.position = Vector2.ZERO
	_load_scrim.size = size


func get_round_complete_label() -> RichTextLabel:
	_ensure_round_complete_overlay()
	return _round_label


func _hide_round_complete() -> void:
	if _round_fade != null:
		_round_fade.visible = false
	if _round_root != null:
		_round_root.visible = false
	if _round_scrim != null:
		_round_scrim.color = Color(0, 0, 0, 0)
	_stop_round_hop()
	_clear_round_flames()
	if _round_label != null:
		_round_label.visible = false
		_round_label.modulate.a = 0.0
		_round_label.position = Vector2.ZERO
	if _round_bets_label != null:
		_round_bets_label.visible = false
	if _round_balance_label != null:
		_round_balance_label.visible = false


func _viewport_size() -> Vector2:
	var vp := get_viewport()
	if vp != null:
		var vis := vp.get_visible_rect().size
		if vis.x >= 64.0 and vis.y >= 64.0:
			return vis
	var tree := get_tree()
	if tree != null and tree.root != null:
		return Vector2(tree.root.size)
	return Vector2(1920, 1280)


func _layout_round_complete() -> void:
	var size := _viewport_size()
	if _round_root != null:
		_round_root.position = Vector2.ZERO
		_round_root.size = size
	if _round_scrim != null:
		_round_scrim.position = Vector2.ZERO
		_round_scrim.size = size
	if _round_flames != null:
		_round_flames.position = Vector2.ZERO
		_round_flames.size = size
	if _round_label != null:
		_round_label.position = Vector2.ZERO
		_round_label.size = size
	var stats_y := size.y * 0.5 + 40.0
	if _round_bets_label != null:
		_round_bets_label.position = Vector2(0.0, stats_y)
		_round_bets_label.size = Vector2(size.x, 36.0)
	if _round_balance_label != null:
		_round_balance_label.position = Vector2(0.0, stats_y + 36.0 + 4.0)
		_round_balance_label.size = Vector2(size.x, 36.0)


func _build_round_complete_overlay() -> void:
	_round_fade = CanvasLayer.new()
	_round_fade.name = "RoundCompleteOverlay"
	_round_fade.layer = 220
	_round_fade.process_mode = Node.PROCESS_MODE_ALWAYS
	_round_fade.visible = false
	add_child(_round_fade)
	_round_root = Control.new()
	_round_root.name = "RoundRoot"
	_round_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round_fade.add_child(_round_root)
	_round_scrim = ColorRect.new()
	_round_scrim.name = "RoundScrim"
	_round_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round_scrim.color = Color(0, 0, 0, 0)
	_round_root.add_child(_round_scrim)
	_round_flames = Control.new()
	_round_flames.name = "RoundFlames"
	_round_flames.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round_root.add_child(_round_flames)
	_round_label = RichTextLabel.new()
	_round_label.name = "RoundCompleteLabel"
	_round_label.bbcode_enabled = true
	_round_label.scroll_active = false
	_round_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_round_label.text = _round_complete_bbcode()
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_round_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var round_font := load("res://combat/ui/fonts/VT323-Regular.ttf")
	_round_label.add_theme_font_override("normal_font", round_font)
	_round_label.add_theme_font_size_override("normal_font_size", 64)
	_round_label.add_theme_color_override("default_color", Color.WHITE)
	_round_label.modulate.a = 0.0
	_round_label.visible = false
	_round_root.add_child(_round_label)
	_round_bets_label = Label.new()
	_round_bets_label.name = "RoundBetsLabel"
	_round_bets_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_bets_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round_bets_label.add_theme_font_override("font", round_font)
	_round_bets_label.add_theme_font_size_override("font_size", 32)
	_round_bets_label.add_theme_color_override("font_color", Color.WHITE)
	_round_bets_label.visible = false
	_round_root.add_child(_round_bets_label)
	_round_balance_label = Label.new()
	_round_balance_label.name = "RoundBalanceLabel"
	_round_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_balance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round_balance_label.add_theme_font_override("font", round_font)
	_round_balance_label.add_theme_font_size_override("font_size", 32)
	_round_balance_label.add_theme_color_override("font_color", Color.WHITE)
	_round_balance_label.visible = false
	_round_root.add_child(_round_balance_label)
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_layout_round_complete):
		vp.size_changed.connect(_layout_round_complete)
	_layout_round_complete()


func _round_complete_bbcode() -> String:
	var out := ""
	for i in ROUND_COMPLETE_TEXT.length():
		var ch := ROUND_COMPLETE_TEXT.substr(i, 1)
		var color := "white" if i % 2 == 0 else "red"
		out += "[color=%s]%s[/color]" % [color, ch]
	return out


func _start_round_hop() -> void:
	_stop_round_hop()
	if _round_label == null:
		return
	var rest_y := _round_label.position.y
	_round_hop = CombatPace.bind(create_tween())
	_round_hop.set_loops()
	_round_hop.tween_property(_round_label, "position:y", rest_y - 24.0, 0.225)
	_round_hop.tween_property(_round_label, "position:y", rest_y, 0.225)


func _stop_round_hop() -> void:
	if _round_hop != null and is_instance_valid(_round_hop):
		_round_hop.kill()
	_round_hop = null


func _start_round_flames() -> void:
	if _round_root == null or _round_flames == null:
		return
	_clear_round_flames()
	var burst = FLAME_BURST_SCRIPT.new()
	burst.name = "RoundFlameBurst"
	_round_root.add_child(burst)
	burst.bind(_round_flames)
	burst.play_waves_linger(_round_root.size * 0.5, [8, 16])


func _clear_round_flames() -> void:
	if _round_root == null:
		return
	var old := _round_root.get_node_or_null("RoundFlameBurst")
	if old != null:
		old.queue_free()


func _ensure_round_complete_overlay() -> void:
	if _round_fade == null or not is_instance_valid(_round_fade):
		_build_round_complete_overlay()


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


func get_interface_pulse() -> CanvasLayer:
	if _pulse != null and is_instance_valid(_pulse):
		return _pulse
	return null


func get_intro_glitch() -> CanvasLayer:
	if _glitch != null and is_instance_valid(_glitch):
		return _glitch
	return null


func start_interface_distortion(once: bool = false) -> void:
	if _pulse != null and is_instance_valid(_pulse) and _pulse.has_method("start_distortion"):
		_pulse.start_distortion(once)


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
	# Rest pulse stays on. The rolling wave is only the 30s burst.
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
