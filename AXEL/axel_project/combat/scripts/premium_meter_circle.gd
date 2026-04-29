extends Control

@export_range(0, 3, 1) var filled_sections: int = 0:
	set(value):
		filled_sections = clampi(value, 0, 3)
		queue_redraw()

@export var ring_radius: float = 42.0
@export var ring_width: float = 10.0
@export var show_charge_pulse: bool = true

var _pulse_phase: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(120, 120)
	set_process(true)


func set_sections(value: int) -> void:
	filled_sections = value


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
