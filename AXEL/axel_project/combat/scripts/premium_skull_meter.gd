extends Control
## Premium meter skull: stage art + hover/press feel. Fill is driven by combat meter sections.

signal pressed

@export_range(0.0, 1.0, 0.01) var preview_fill: float = 0.0

const STAGE_THRESHOLDS := [0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0]
const HOVER_SCALE := 1.06
const PRESS_SCALE := 0.94
const FILL_SCALE_1_3 := 1.08
const FILL_SCALE_2_3 := 1.1
const FILL_SCALE_FULL := 1.16
const GLOW_HOVER_ALPHA := 0.45
const GLOW_FILL_ALPHA := 0.55
const OUTLINE_SCALE := 1.03

@onready var _glow: TextureRect = $Glow
@onready var _stage1: TextureRect = $SkullStage1
@onready var _stage2: TextureRect = $SkullStage2
@onready var _stage3: TextureRect = $SkullStage3

var _fill: float = 0.0
var _hovering := false
var _pressing := false
var _base_scale := Vector2.ONE
var _shake_tween: Tween
var _press_tween: Tween


func _ready() -> void:
	## Clicks live on Execute MOVE_TextBox + SkullClickPolygon — skull art is display-only.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base_scale = scale
	pivot_offset = size * 0.5
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	if _glow != null:
		_glow.visible = false
		_glow.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for stage in [_stage1, _stage2, _stage3]:
		if stage != null:
			stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stage.pivot_offset = stage.size * 0.5
	set_fill(preview_fill)


func set_fill(f: float) -> void:
	_fill = clampf(f, 0.0, 1.0)
	_apply_stage_visibility()
	_apply_fill_feel()


func _apply_stage_visibility() -> void:
	var stage_idx := _stage_index_for_fill(_fill)
	if _stage1 != null:
		_stage1.visible = stage_idx == 0
	if _stage2 != null:
		_stage2.visible = stage_idx == 1
	if _stage3 != null:
		_stage3.visible = stage_idx == 2


func _stage_index_for_fill(f: float) -> int:
	if f >= STAGE_THRESHOLDS[3] - 0.0001:
		return 2
	if f >= STAGE_THRESHOLDS[2]:
		return 1
	return 0


func _apply_fill_feel() -> void:
	var target_scale := _base_scale
	var glow_on := false
	var glow_alpha := 0.0
	var shake_amp := 0.0
	var shake_count := 0

	if _fill >= STAGE_THRESHOLDS[3] - 0.0001:
		target_scale = _base_scale * FILL_SCALE_FULL
		glow_on = true
		glow_alpha = GLOW_FILL_ALPHA
		shake_amp = 6.0
		shake_count = 8
	elif _fill >= STAGE_THRESHOLDS[2]:
		target_scale = _base_scale * FILL_SCALE_2_3
		glow_on = true
		glow_alpha = GLOW_FILL_ALPHA
		shake_amp = 4.0
		shake_count = 5
	elif _fill >= STAGE_THRESHOLDS[1]:
		target_scale = _base_scale * FILL_SCALE_1_3
		glow_on = true
		glow_alpha = GLOW_FILL_ALPHA * 0.85

	if _hovering and not _pressing:
		target_scale *= HOVER_SCALE
		glow_on = true
		glow_alpha = maxf(glow_alpha, GLOW_HOVER_ALPHA)
	elif _pressing:
		target_scale *= PRESS_SCALE

	scale = target_scale
	_set_glow(glow_on, glow_alpha)

	if shake_amp > 0.0 and not _pressing:
		_play_shake(shake_amp, shake_count)


func _set_glow(on: bool, alpha: float) -> void:
	if _glow == null:
		return
	_glow.visible = on
	if on:
		_glow.modulate = Color(1.0, 1.0, 1.0, alpha)
		_glow.scale = Vector2(OUTLINE_SCALE, OUTLINE_SCALE)
		_glow.pivot_offset = _glow.size * 0.5
		_glow.position = (_glow.size * (1.0 - OUTLINE_SCALE)) * 0.5
	else:
		_glow.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_glow.scale = Vector2.ONE
		_glow.position = Vector2.ZERO


func _play_shake(amplitude: float, pulses: int) -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	var origin := position
	_shake_tween = create_tween()
	for i in range(pulses):
		var dir := 1.0 if (i % 2) == 0 else -1.0
		_shake_tween.tween_property(self, "position", origin + Vector2(dir * amplitude, 0.0), 0.03)
	_shake_tween.tween_property(self, "position", origin, 0.04)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_pressing = true
			_apply_fill_feel()
			_play_press_jitter()
			accept_event()
		else:
			if _pressing:
				_pressing = false
				_apply_fill_feel()
				pressed.emit()
				accept_event()


func _play_press_jitter() -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	var origin := position
	_press_tween = create_tween()
	_press_tween.tween_property(self, "position", origin + Vector2(3.0, 2.0), 0.03)
	_press_tween.tween_property(self, "position", origin + Vector2(-2.0, -1.0), 0.03)
	_press_tween.tween_property(self, "position", origin, 0.04)


func _on_mouse_entered() -> void:
	_hovering = true
	_apply_fill_feel()


func _on_mouse_exited() -> void:
	_hovering = false
	_pressing = false
	_apply_fill_feel()
