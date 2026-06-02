extends CanvasLayer
## Event-driven Option 1 CRT TV distortion (distinct from glitch + baseline AxelPostFxStack).

@onready var _filter_rect: ColorRect = $FilterRect

const _DEFAULT_DURATION := 1.1
const _FADE_IN := 0.12
const _FADE_OUT := 0.16

var _distortion_active := false
var _fade_tween: Tween


func _ready() -> void:
	layer = 109
	visible = false
	_filter_rect.modulate.a = 0.0
	_filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func start_distortion() -> void:
	_kill_fade_tween()
	_distortion_active = true
	visible = true
	_fade_tween = create_tween()
	_fade_tween.tween_property(_filter_rect, "modulate:a", 1.0, _FADE_IN)


func stop_distortion() -> void:
	_kill_fade_tween()
	_distortion_active = false
	_fade_tween = create_tween()
	_fade_tween.tween_property(_filter_rect, "modulate:a", 0.0, _FADE_OUT)
	await _fade_tween.finished
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
