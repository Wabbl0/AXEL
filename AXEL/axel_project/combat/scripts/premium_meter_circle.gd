extends Control

@export_range(0, 3, 1) var filled_sections: int = 0:
	set(value):
		filled_sections = clampi(value, 0, 3)
		queue_redraw()

@export var ring_radius: float = 42.0
@export var ring_width: float = 10.0
@export var show_charge_pulse: bool = true
@export var full_flash_scale_peak: float = 1.18
@export var full_flash_duration_sec: float = 0.55

var _pulse_phase: float = 0.0
var _full_flash_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(120, 120)
	set_process(true)
	pivot_offset = custom_minimum_size * 0.5


func set_sections(value: int) -> void:
	filled_sections = value


func play_full_flash() -> void:
	_kill_full_flash_tween()
	pivot_offset = size * 0.5
	scale = Vector2.ONE
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	var half: float = max(full_flash_duration_sec * 0.5, 0.08)
	_full_flash_tween = create_tween()
	_full_flash_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_full_flash_tween.tween_property(self, "scale", Vector2(full_flash_scale_peak, full_flash_scale_peak), half)
	_full_flash_tween.parallel().tween_property(self, "modulate", Color(1.6, 1.4, 1.4, 1.0), half)
	_full_flash_tween.set_ease(Tween.EASE_IN)
	_full_flash_tween.tween_property(self, "scale", Vector2.ONE, half)
	_full_flash_tween.parallel().tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), half)


func _kill_full_flash_tween() -> void:
	if _full_flash_tween != null and is_instance_valid(_full_flash_tween):
		_full_flash_tween.kill()
	_full_flash_tween = null


func _process(delta: float) -> void:
	if show_charge_pulse and filled_sections >= 3:
		_pulse_phase += delta * 4.0
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var base_color := Color(0.2, 0.03, 0.03, 1.0)
	var fill_color := Color(1.0, 0.05, 0.05, 1.0)

	draw_arc(center, ring_radius, 0.0, TAU, 96, base_color, ring_width, true)

	var fill_amount := float(filled_sections) / 3.0
	if fill_amount > 0.0:
		draw_arc(center, ring_radius, -PI * 0.5, -PI * 0.5 + TAU * fill_amount, 96, fill_color, ring_width, true)

	var pulse_boost := 1.0
	if show_charge_pulse and filled_sections >= 3:
		pulse_boost = 1.15 + 0.12 * sin(_pulse_phase)
	draw_arc(center, ring_radius + 6.0, -PI * 0.5, -PI * 0.5 + TAU * fill_amount, 96, Color(1.0, 0.08, 0.08, 0.35 * pulse_boost), 3.0, true)
