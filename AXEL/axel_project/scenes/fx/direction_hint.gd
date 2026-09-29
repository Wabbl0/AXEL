extends Node2D

@export var visual_offset: Vector2 = Vector2.ZERO
@export var indicator_scale: float = 2.25
@export var point_down: bool = false

@onready var _sprite: Sprite2D = $Sprite
@onready var _halo: Sprite2D = $Halo

const NUDGE_SCREEN_PX := 20.0
const NUDGE_HZ := 1.15

var _glow_off := false


func _ready() -> void:
	scale = Vector2(indicator_scale, indicator_scale)
	if point_down:
		rotation = PI * 0.5
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


func overlaps_player(player: Node2D) -> bool:
	if not is_instance_valid(player):
		return false
	var arrow := get_node_or_null("Sprite") as Sprite2D
	var mike := player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	if arrow == null or mike == null or not mike.visible:
		return false
	var arrow_rect := _centered_sprite_global_rect(arrow, _sprite2d_size(arrow), arrow.offset, arrow.centered)
	var mike_rect := _centered_sprite_global_rect(mike, _anim_frame_size(mike), mike.offset, mike.centered)
	if arrow_rect.size.x <= 0.0 or arrow_rect.size.y <= 0.0:
		return false
	if mike_rect.size.x <= 0.0 or mike_rect.size.y <= 0.0:
		return false
	return arrow_rect.intersects(mike_rect, true)


func _sprite2d_size(sprite: Sprite2D) -> Vector2:
	if sprite.texture == null:
		return Vector2.ZERO
	if sprite.region_enabled:
		return sprite.region_rect.size
	return sprite.texture.get_size()


func _anim_frame_size(sprite: AnimatedSprite2D) -> Vector2:
	if sprite.sprite_frames == null:
		return Vector2.ZERO
	var anim := sprite.animation
	if anim == StringName() or not sprite.sprite_frames.has_animation(anim):
		return Vector2.ZERO
	var tex := sprite.sprite_frames.get_frame_texture(anim, sprite.frame)
	if tex == null:
		return Vector2.ZERO
	return tex.get_size()


func _centered_sprite_global_rect(item: Node2D, tex_size: Vector2, sprite_offset: Vector2, centered: bool) -> Rect2:
	if tex_size == Vector2.ZERO:
		return Rect2()
	var origin := sprite_offset
	if centered:
		origin -= tex_size * 0.5
	var local := Rect2(origin, tex_size)
	var xf := item.get_global_transform()
	var rect := Rect2(xf * local.position, Vector2.ZERO)
	rect = rect.expand(xf * (local.position + Vector2(local.size.x, 0.0)))
	rect = rect.expand(xf * (local.position + local.size))
	rect = rect.expand(xf * (local.position + Vector2(0.0, local.size.y)))
	return rect
