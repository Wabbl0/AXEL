extends CanvasLayer

@onready var _filter_rect: ColorRect = $FilterRect

const BASELINE_ALPHA := 0.20
const SURGE_ALPHA := 0.536
const _DEFAULT_DURATION := 1.1
const _FADE_IN := 0.12
const _FADE_OUT := 0.16

var _ambient_active := false
var _distortion_active := false
var _fade_tween: Tween


func _ready() -> void:
	layer = 109
	visible = false
	_filter_rect.modulate.a = 0.0
	_filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _rest_alpha() -> float:
	# Pulse-only: never leave a visible roll between pulses.
	return 0.0


func start_ambient() -> void:
	# Kept for AxelEventFx callers. Do not show the roll or fade to 0.20.
	_kill_fade_tween()
	_ambient_active = true
	if _distortion_active:
		return
	_filter_rect.modulate.a = 0.0
	visible = false


func stop_ambient() -> void:
	# Instant hide so a scene change never leaves a visible roll.
	_kill_fade_tween()
	_ambient_active = false
	_distortion_active = false
	_filter_rect.modulate.a = 0.0
	visible = false


func start_distortion() -> void:
	_kill_fade_tween()
	_distortion_active = true
	visible = true
	_fade_tween = create_tween()
	_fade_tween.tween_property(_filter_rect, "modulate:a", SURGE_ALPHA, _FADE_IN)


func stop_distortion() -> void:
	_kill_fade_tween()
	_distortion_active = false
	var rest := _rest_alpha()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_filter_rect, "modulate:a", rest, _FADE_OUT)
	await _fade_tween.finished
	if rest <= 0.0:
		visible = false


func play_pulse(duration_sec: float = _DEFAULT_DURATION) -> void:
	start_distortion()
	var hold := maxf(duration_sec - _FADE_IN - _FADE_OUT, 0.2)
	await get_tree().create_timer(hold).timeout
	await stop_distortion()


func _kill_fade_tween() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
