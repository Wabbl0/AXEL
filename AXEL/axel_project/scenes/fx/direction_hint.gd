extends Node2D

@export var visual_offset: Vector2 = Vector2.ZERO
@export var indicator_scale: float = 2.25

@onready var _sprite: Sprite2D = $Sprite
@onready var _halo: Sprite2D = $Halo

const NUDGE_SCREEN_PX := 20.0
const NUDGE_HZ := 1.15

var _glow_off := false


func _ready() -> void:
	scale = Vector2(indicator_scale, indicator_scale)
	_glow_off = OS.get_environment("AXEL_DISABLE_POST_FX") == "1"
	if is_instance_valid(_halo):
		_halo.visible = not _glow_off
	visible = false
	set_process(true)


func _process(_delta: float) -> void:
	if not visible:
		return
	var t := float(Time.get_ticks_msec()) * 0.001
	var bob := Vector2(_nudge_local_x(t), 0.0)
	if is_instance_valid(_sprite):
		_sprite.position = visual_offset + bob
	if is_instance_valid(_halo):
		_halo.position = visual_offset + bob
	modulate.a = 0.85 + 0.15 * (0.5 + 0.5 * sin(t * 2.2))


func _nudge_local_x(t: float) -> float:
	var cycle := fposmod(t * NUDGE_HZ, 1.0)
	var n := 0.0
	if cycle < 0.62:
		n = cycle / 0.62
	else:
		n = 1.0 - (cycle - 0.62) / 0.38
	n = n * n * (3.0 - 2.0 * n)
	var screen_per_global := 1.0
	var canvas := get_canvas_transform()
	screen_per_global = absf(canvas.get_scale().x)
	if screen_per_global < 0.001:
		screen_per_global = 1.0
	var global_dx := NUDGE_SCREEN_PX / screen_per_global
	return n * global_dx / maxf(absf(scale.x), 0.001)
