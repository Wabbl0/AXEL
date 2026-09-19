extends CanvasLayer

@onready var _filter_rect: ColorRect = $FilterRect

const LAYER := 113
const _DEFAULT_DURATION := 0.85


func _ready() -> void:
	layer = LAYER
	visible = false
	_filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func play_burst(duration_sec: float = _DEFAULT_DURATION) -> void:
	if _filter_rect.material is ShaderMaterial:
		(_filter_rect.material as ShaderMaterial).set_shader_parameter("intensity", 0.82)
	visible = true
	await get_tree().create_timer(maxf(duration_sec, 0.05)).timeout
	visible = false
