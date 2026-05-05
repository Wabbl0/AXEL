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
@export var section_fill_duration_sec: float = 0.22

var _pulse_phase: float = 0.0
var _full_flash_tween: Tween
var _section_fill_tween: Tween
var _visual_sections: float = 0.0:
	set(value):
		_visual_sections = clampf(value, 0.0, 3.0)
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(120, 120)
	set_process(true)
	pivot_offset = custom_minimum_size * 0.5
	_visual_sections = float(filled_sections)


func set_sections(value: int) -> void:
	var clamped := clampi(value, 0, 3)
	filled_sections = clamped
	_kill_section_fill_tween()
	_visual_sections = float(clamped)


func animate_to_sections(previous_sections: int, next_sections: int) -> void:
	var prev := clampi(previous_sections, 0, 3)
	var next := clampi(next_sections, 0, 3)
	filled_sections = next
	_kill_section_fill_tween()
	_visual_sections = float(prev)
	if next <= prev:
		_visual_sections = float(next)
		return
	var duration: float = maxf(section_fill_duration_sec * float(next - prev), 0.01)
	_section_fill_tween = create_tween()
	_section_fill_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_section_fill_tween.tween_property(self, "_visual_sections", float(next), duration)


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


func _kill_section_fill_tween() -> void:
	if _section_fill_tween != null and is_instance_valid(_section_fill_tween):
		_section_fill_tween.kill()
	_section_fill_tween = null


func _process(delta: float) -> void:
	if show_charge_pulse and filled_sections >= 3:
		_pulse_phase += delta * 4.0
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var base_color := Color(0.2, 0.03, 0.03, 1.0)
	var fill_color := Color(1.0, 0.05, 0.05, 1.0)

	draw_arc(center, ring_radius, 0.0, TAU, 96, base_color, ring_width, true)

	var fill_amount := _visual_sections / 3.0
	if fill_amount > 0.0:
		draw_arc(center, ring_radius, -PI * 0.5, -PI * 0.5 + TAU * fill_amount, 96, fill_color, ring_width, true)

	var pulse_boost := 1.0
	if show_charge_pulse and filled_sections >= 3:
		pulse_boost = 1.15 + 0.12 * sin(_pulse_phase)
	draw_arc(center, ring_radius + 6.0, -PI * 0.5, -PI * 0.5 + TAU * fill_amount, 96, Color(1.0, 0.08, 0.08, 0.35 * pulse_boost), 3.0, true)
