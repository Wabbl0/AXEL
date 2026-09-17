extends Node2D

@export var visual_offset: Vector2 = Vector2.ZERO
@export var indicator_scale: float = 2.25

@onready var _sprite: Sprite2D = $Sprite
@onready var _halo: Sprite2D = $Halo

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
	var bob := Vector2(sin(t * 2.2) * 3.0, 0.0)
	if is_instance_valid(_sprite):
		_sprite.position = visual_offset + bob
	if is_instance_valid(_halo):
		_halo.position = visual_offset + bob
	modulate.a = 0.72 + 0.28 * (0.5 + 0.5 * sin(t * 1.6))
