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
var _wipe_rng := RandomNumberGenerator.new()
var _last_wipe_style := -1
var _next_wipe_style := -1

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
const JACKPOT_FX_SCRIPT := preload("res://scenes/fx/round_jackpot_fx.gd")
const JACKPOT_TEXT_SCRIPT := preload("res://scenes/fx/jackpot_text_effect.gd")

var _round_fade: CanvasLayer
var _round_root: Control
var _round_scrim: ColorRect
var _round_stage: Control
var _round_flames: Control
var _round_label: RichTextLabel
var _round_bets_label: RichTextLabel
var _round_balance_label: RichTextLabel
var _jackpot: Control
var _jackpot_front: Control
var _round_intro: Tween
var _round_land: Tween
var _round_shake: Tween
var _round_stats_tween: Tween
var _round_stats_punch: Tween
var _round_bets_value := 0
var _round_balance_value := 0
var _round_stats_rest: Array[float] = [0.0, 0.0]
const ROUND_NUMBER_COLOR := "#dc1414"
const ROUND_TITLE_SIZE := 104
const ROUND_STAT_SIZE := 36
const ROUND_STAT_HEIGHT := 44.0
const ROUND_STATS_OFFSET := 80.0
const ROUND_SLAM_SCALE := 3.2
const ROUND_SHAKE_PX := 14.0

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
	_wipe_rng.randomize()
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

	return


func show_round_complete_card(bets_used: int = 0, balance: int = 0) -> void:
	skip_next_enter_glitch()
	_ensure_round_complete_overlay()
	_layout_round_complete()
	if _round_fade == null or _round_scrim == null or _round_label == null:
		return
	_stop_round_intro()
	_clear_round_flames()
	_clear_jackpot()
	_round_fade.visible = true
	if _round_root != null:
		_round_root.visible = true
	if _round_stage != null:
		_round_stage.position = Vector2.ZERO
	if _round_flames != null:
		_round_flames.modulate = Color.WHITE
	_round_scrim.color = Color(0, 0, 0, ROUND_COMPLETE_SCRIM_A)
	_round_scrim.visible = true
	_round_label.text = _round_complete_bbcode()
	_round_label.modulate = Color.WHITE
	_round_label.scale = Vector2.ONE
	_round_label.visible = true
	_round_bets_value = bets_used
	_round_balance_value = balance
	_spawn_jackpot()
	if _load_fade_instant():
		_snap_round_intro(false)
		return
	_play_round_intro()


func is_round_intro_playing() -> bool:
	return _round_intro_running()


func skip_round_intro() -> void:
	if _round_intro_running():
		_snap_round_intro(true)


func play_round_complete_fade() -> void:
	if _round_intro_running():
		_snap_round_intro(true)
	_stop_round_intro()
	if _jackpot != null and is_instance_valid(_jackpot):
		_jackpot.call("stop_spawning")
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
	for node in [_jackpot, _jackpot_front, _round_flames]:
		if node != null and is_instance_valid(node):
			fade_in.parallel().tween_property(node, "modulate:a", 0.0, 0.35)
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
	_stop_round_intro()
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
	_stop_round_intro()
	_clear_round_flames()
	_clear_jackpot()
	if _round_stage != null:
		_round_stage.position = Vector2.ZERO
	if _round_flames != null:
		_round_flames.modulate = Color.WHITE
	if _round_label != null:
		_round_label.visible = false
		_round_label.modulate.a = 0.0
		_round_label.position = Vector2.ZERO
		_round_label.scale = Vector2.ONE
		_round_label.visible_characters = -1
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
	for node in [_round_root, _round_scrim, _round_stage, _round_flames, _round_label, _jackpot, _jackpot_front]:
		if node != null and is_instance_valid(node):
			(node as Control).position = Vector2.ZERO
			(node as Control).size = size
	if _round_label != null:
		_round_label.pivot_offset = size * 0.5
	var stats_y := size.y * 0.5 + ROUND_STATS_OFFSET
	_round_stats_rest = [stats_y, stats_y + ROUND_STAT_HEIGHT + 6.0]
	var labs := [_round_bets_label, _round_balance_label]
	for i in labs.size():
		var lab := labs[i] as RichTextLabel
		if lab == null:
			continue
		lab.position = Vector2(0.0, _round_stats_rest[i])
		lab.size = Vector2(size.x, ROUND_STAT_HEIGHT)
		lab.pivot_offset = lab.size * 0.5


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
	_round_stage = Control.new()
	_round_stage.name = "RoundStage"
	_round_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round_root.add_child(_round_stage)
	_round_flames = Control.new()
	_round_flames.name = "RoundFlames"
	_round_flames.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_round_stage.add_child(_round_flames)
	_round_label = RichTextLabel.new()
	_round_label.name = "RoundCompleteLabel"
	_round_label.bbcode_enabled = true
	_round_label.scroll_active = false
	_round_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_round_label.install_effect(JACKPOT_TEXT_SCRIPT.new())
	_round_label.text = _round_complete_bbcode()
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_round_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var round_font := load("res://combat/ui/fonts/VT323-Regular.ttf")
	_round_label.add_theme_font_override("normal_font", round_font)
	_round_label.add_theme_font_size_override("normal_font_size", ROUND_TITLE_SIZE)
	_round_label.add_theme_color_override("default_color", Color.WHITE)
	_round_label.add_theme_constant_override("outline_size", 10)
	_round_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_round_label.add_theme_color_override("font_shadow_color", Color(0.35, 0.0, 0.0, 1.0))
	_round_label.add_theme_constant_override("shadow_offset_x", 6)
	_round_label.add_theme_constant_override("shadow_offset_y", 6)
	_round_label.add_theme_constant_override("shadow_outline_size", 10)
	_round_label.modulate.a = 0.0
	_round_label.visible = false
	_round_stage.add_child(_round_label)
	_round_bets_label = _make_round_stat_label("RoundBetsLabel", round_font)
	_round_stage.add_child(_round_bets_label)
	_round_balance_label = _make_round_stat_label("RoundBalanceLabel", round_font)
	_round_stage.add_child(_round_balance_label)
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_layout_round_complete):
		vp.size_changed.connect(_layout_round_complete)
	_layout_round_complete()


func _round_complete_bbcode() -> String:
	var amp := 0.0 if _reduce_flashing() else 6.0
	var chase := 0 if _reduce_flashing() else 1
	return "[jackpot amp=%.1f chase=%d]%s[/jackpot]" % [amp, chase, ROUND_COMPLETE_TEXT]


func _make_round_stat_label(node_name: String, font: Font) -> RichTextLabel:
	var lab := RichTextLabel.new()
	lab.name = node_name
	lab.bbcode_enabled = true
	lab.scroll_active = false
	lab.autowrap_mode = TextServer.AUTOWRAP_OFF
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_theme_font_override("normal_font", font)
	lab.add_theme_font_size_override("normal_font_size", ROUND_STAT_SIZE)
	lab.add_theme_color_override("default_color", Color.WHITE)
	lab.add_theme_constant_override("outline_size", 6)
	lab.add_theme_color_override("font_outline_color", Color.BLACK)
	lab.visible = false
	return lab


func _set_round_stat(lab: RichTextLabel, caption: String, value: int) -> void:
	if lab == null:
		return
	lab.text = "%s: [color=%s]%d[/color]" % [caption, ROUND_NUMBER_COLOR, value]


func _set_round_bets(value: float) -> void:
	_set_round_stat(_round_bets_label, "Bets used", int(round(value)))


func _set_round_balance(value: float) -> void:
	_set_round_stat(_round_balance_label, "Current balance", int(round(value)))


func _round_intro_running() -> bool:
	for tw in [_round_intro, _round_stats_tween]:
		if tw != null and is_instance_valid(tw) and tw.is_running():
			return true
	return false


func _stop_round_intro() -> void:
	for tw in [_round_intro, _round_land, _round_shake, _round_stats_tween, _round_stats_punch]:
		if tw != null and is_instance_valid(tw):
			tw.kill()
	_round_intro = null
	_round_land = null
	_round_shake = null
	_round_stats_tween = null
	_round_stats_punch = null


func _snap_round_intro(keep_spawning: bool) -> void:
	_stop_round_intro()
	_layout_round_complete()
	if _round_scrim != null:
		_round_scrim.color = Color(0, 0, 0, ROUND_COMPLETE_SCRIM_A)
	if _round_stage != null:
		_round_stage.position = Vector2.ZERO
	if _round_label != null:
		_round_label.visible_characters = -1
		_round_label.scale = Vector2.ONE
		_round_label.modulate = Color.WHITE
	for lab in [_round_bets_label, _round_balance_label]:
		if lab != null:
			lab.modulate = Color.WHITE
			lab.scale = Vector2.ONE
			lab.visible = true
	_set_round_bets(_round_bets_value)
	_set_round_balance(_round_balance_value)
	if _jackpot != null and is_instance_valid(_jackpot):
		_jackpot.call("snap_final", _round_center())
		if not keep_spawning:
			_jackpot.call("stop_spawning")


func _round_center() -> Vector2:
	if _round_stage != null and _round_stage.size.x > 0.0:
		return _round_stage.size * 0.5
	return _viewport_size() * 0.5


func _play_round_intro() -> void:
	_stop_round_intro()
	for lab in [_round_bets_label, _round_balance_label]:
		if lab != null:
			lab.visible = false
			lab.modulate = Color(1, 1, 1, 0)
	_set_round_bets(0)
	_set_round_balance(0)
	_round_label.visible_characters = -1
	_round_label.pivot_offset = _round_label.size * 0.5
	_round_label.scale = Vector2(ROUND_SLAM_SCALE, ROUND_SLAM_SCALE)
	_round_label.modulate = Color(1, 1, 1, 0)
	if not _reduce_flashing() and _round_scrim != null:
		_round_scrim.color = Color(0.45, 0.0, 0.0, 0.85)
	var tw := CombatPace.bind(create_tween())
	_round_intro = tw
	tw.tween_property(_round_label, "scale", Vector2(0.92, 0.92), 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_round_label, "modulate:a", 1.0, 0.1)
	tw.tween_callback(_round_title_landed)
	tw.tween_property(_round_label, "scale", Vector2(1.12, 0.9), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_round_label, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.2)
	tw.tween_callback(_reveal_round_stats)


func _round_title_landed() -> void:
	if _round_label == null:
		return
	_round_label.modulate = Color.WHITE
	_round_land = CombatPace.bind(create_tween())
	if _round_scrim != null:
		_round_land.tween_property(_round_scrim, "color", Color(0, 0, 0, ROUND_COMPLETE_SCRIM_A), 0.35)
	if _jackpot != null and is_instance_valid(_jackpot):
		_jackpot.call("play_intro", _round_center())
	_start_round_flames()
	_play_round_sfx(&"power")
	if not _reduce_flashing():
		_shake_round_stage(ROUND_SHAKE_PX * _glitch_scale())


func _shake_round_stage(amp: float) -> void:
	if _round_stage == null or amp <= 0.5:
		return
	if _round_shake != null and is_instance_valid(_round_shake):
		_round_shake.kill()
	_round_stage.position = Vector2.ZERO
	_round_shake = CombatPace.bind(create_tween())
	var kicks := [Vector2(1.0, 0.5), Vector2(-0.9, -0.4), Vector2(0.7, -0.6), Vector2(-0.5, 0.5), Vector2(0.25, -0.2)]
	for kick in kicks:
		_round_shake.tween_property(_round_stage, "position", (kick as Vector2) * amp, 0.035)
	_round_shake.tween_property(_round_stage, "position", Vector2.ZERO, 0.05)


func _reveal_round_stats() -> void:
	_round_stats_tween = CombatPace.bind(create_tween())
	var labs := [_round_bets_label, _round_balance_label]
	var targets := [_round_bets_value, _round_balance_value]
	var setters := [_set_round_bets, _set_round_balance]
	var count_secs := [0.6, 0.9]
	for i in labs.size():
		var lab := labs[i] as RichTextLabel
		if lab == null:
			continue
		var rest := _round_stats_rest[i]
		lab.visible = true
		lab.modulate.a = 0.0
		lab.position.y = rest + 40.0
		_round_stats_tween.tween_property(lab, "position:y", rest, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_round_stats_tween.parallel().tween_property(lab, "modulate:a", 1.0, 0.15)
		_round_stats_tween.tween_method(setters[i], 0.0, float(targets[i]), count_secs[i]).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_round_stats_tween.tween_callback(_punch_round_balance)
	_round_stats_tween.tween_interval(0.35)


func _punch_round_balance() -> void:
	var lab := _round_balance_label
	if lab == null:
		return
	lab.pivot_offset = lab.size * 0.5
	lab.scale = Vector2(1.3, 1.3)
	lab.modulate = Color(1.6, 0.5, 0.5, 1.0) if not _reduce_flashing() else Color.WHITE
	_round_stats_punch = CombatPace.bind(create_tween())
	_round_stats_punch.tween_property(lab, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_round_stats_punch.parallel().tween_property(lab, "modulate", Color.WHITE, 0.25)
	_play_round_sfx(&"round_winnings")
	if _jackpot != null and is_instance_valid(_jackpot):
		var sparks := 16 if _reduce_flashing() else 36
		_jackpot.call("burst_at", _round_balance_number_point(), sparks, 120.0, 360.0)


func _round_balance_number_point() -> Vector2:
	var lab := _round_balance_label
	var font := lab.get_theme_font("normal_font")
	var font_size := lab.get_theme_font_size("normal_font_size")
	var x := lab.size.x * 0.5
	if font != null:
		var full_w := font.get_string_size(lab.get_parsed_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var num_w := font.get_string_size(str(_round_balance_value), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		x += full_w * 0.5 - num_w * 0.5
	return lab.position + Vector2(x, lab.size.y * 0.5)


func _play_round_sfx(cue: StringName) -> void:
	var sfx := get_node_or_null("/root/AxelSfx")
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", cue)


func _start_round_flames() -> void:
	if _round_stage == null or _round_flames == null:
		return
	_clear_round_flames()
	var burst = FLAME_BURST_SCRIPT.new()
	burst.name = "RoundFlameBurst"
	_round_stage.add_child(burst)
	burst.bind(_round_flames)
	burst.play_waves_linger(_round_center(), [16, 32, 16])


func _clear_round_flames() -> void:
	if _round_stage == null:
		return
	var old := _round_stage.get_node_or_null("RoundFlameBurst")
	if old != null:
		old.queue_free()


func _spawn_jackpot() -> void:
	_clear_jackpot()
	if _round_stage == null:
		return
	_jackpot = JACKPOT_FX_SCRIPT.new()
	_jackpot.name = "RoundJackpotFx"
	_round_stage.add_child(_jackpot)
	_round_stage.move_child(_jackpot, _round_flames.get_index() + 1)
	_jackpot_front = Control.new()
	_jackpot_front.name = "RoundJackpotFront"
	_round_stage.add_child(_jackpot_front)
	_layout_round_complete()
	_jackpot.call("setup", _jackpot_front, _reduce_flashing())


func _clear_jackpot() -> void:
	for node in [_jackpot, _jackpot_front]:
		if node != null and is_instance_valid(node):
			var parent: Node = node.get_parent()
			if parent != null:
				parent.remove_child(node)
			node.queue_free()
	_jackpot = null
	_jackpot_front = null


func _ensure_round_complete_overlay() -> void:
	if _round_fade == null or not is_instance_valid(_round_fade):
		_build_round_complete_overlay()


func play_combat_wipe() -> void:
	if _combat_wipe == null or not is_instance_valid(_combat_wipe):
		return
	if _event_fx_disabled():
		return
	_wipe_guard_left = COMBAT_WIPE_MAX_SEC
	var sfx := get_node_or_null("/root/AxelSfx")
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", &"combat_transition")
	await _combat_wipe.call("close_wipe", pick_combat_wipe_style())


func set_next_wipe_style(style: int) -> void:
	_next_wipe_style = style


func pick_combat_wipe_style() -> int:
	var count: int = CombatWipeScript.Style.size()
	var style := 0
	if _next_wipe_style >= 0:
		style = clampi(_next_wipe_style, 0, count - 1)
		_next_wipe_style = -1
	else:
		style = _wipe_rng.randi_range(0, count - 1)
		if count > 1 and style == _last_wipe_style:
			style = (style + 1 + _wipe_rng.randi_range(0, count - 2)) % count
	_last_wipe_style = style
	return style


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
