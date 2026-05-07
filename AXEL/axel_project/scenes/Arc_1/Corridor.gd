extends Node2D

@onready var background: ColorRect = $Background
@onready var highlighted_locker: Sprite2D = $LockerRow/HighlightedLocker
@onready var ceiling_light: PointLight2D = $CeilingLight

var _base_locker_modulate := Color(1.0, 1.0, 1.0, 1.0)
var _flicker_time := 0.0

func _ready() -> void:
	_base_locker_modulate = highlighted_locker.modulate
	_start_push_in_tween()

func _process(delta: float) -> void:
	_flicker_time += delta
	_update_highlighted_locker()
	_update_ceiling_flicker()

func _start_push_in_tween() -> void:
	background.scale = Vector2.ONE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(background, "scale", Vector2(1.04, 1.04), 3.2)

func _update_highlighted_locker() -> void:
	var pulse := 0.12 + (sin(_flicker_time * 2.2) * 0.08)
	var red_boost := 0.18 + (sin(_flicker_time * 4.0) * 0.05)
	var jitter := 0.0
	if int(_flicker_time * 9.0) % 11 == 0:
		jitter = 0.8
	highlighted_locker.position.x = 640.0 + jitter
	highlighted_locker.modulate = Color(
		clamp(_base_locker_modulate.r + red_boost, 0.0, 1.0),
		clamp(_base_locker_modulate.g - pulse * 0.45, 0.0, 1.0),
		clamp(_base_locker_modulate.b - pulse * 0.75, 0.0, 1.0),
		1.0
	)

func _update_ceiling_flicker() -> void:
	var base_energy := 0.72 + (sin(_flicker_time * 7.0) * 0.18)
	if int(_flicker_time * 14.0) % 13 == 0:
		base_energy = 0.2
	ceiling_light.energy = clamp(base_energy, 0.15, 1.1)
