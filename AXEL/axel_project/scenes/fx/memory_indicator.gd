extends Node2D

const _DEFAULT_SHEET := "res://assets/sprites/memory_glow-Sheet.png"
const _FRAME_COUNT := 5
const _ANIM := &"glow"

@export var sprite_sheet: Texture2D
@export var frame_size: int = 48
@export var animation_fps: float = 8.0
@export var indicator_scale: float = 2.25
@export var visual_offset: Vector2 = Vector2.ZERO
@export var memory_key: String = ""
@export var collected_bool_property: String = ""
@export var interact_area_path: NodePath

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite
@onready var _halo: AnimatedSprite2D = $Halo

var _tex_pos := Vector2.ZERO
var _tex_captured := false


func _ready() -> void:
	scale = Vector2(indicator_scale, indicator_scale)
	var local_offset := visual_offset / maxf(indicator_scale, 0.0001)
	_sprite.position = local_offset
	_halo.position = local_offset
	if sprite_sheet == null:
		if ResourceLoader.exists(_DEFAULT_SHEET):
			sprite_sheet = load(_DEFAULT_SHEET) as Texture2D
	if sprite_sheet == null:
		push_warning("MemoryIndicator: missing sprite sheet at %s" % _DEFAULT_SHEET)
		return
	_build_frames()
	_sprite.play(_ANIM)
	_halo.play(_ANIM)
	capture_editor_tex()
	apply_collected()


func _build_frames() -> void:
	var sf := SpriteFrames.new()
	sf.add_animation(_ANIM)
	sf.set_animation_loop(_ANIM, true)
	sf.set_animation_speed(_ANIM, 1.0)
	var frame_time := 1.0 / maxf(animation_fps, 0.001)
	var cell := frame_size
	for i in _FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = Rect2(i * cell, 0, cell, cell)
		sf.add_frame(_ANIM, atlas, frame_time)
	_sprite.sprite_frames = sf
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_halo.sprite_frames = sf
	_halo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func capture_editor_tex() -> void:
	if _tex_captured:
		return
	_tex_pos = position
	_tex_captured = true


func remap_to_env(env: Node2D) -> void:
	if not visible or not is_instance_valid(env):
		return
	if not _tex_captured:
		capture_editor_tex()
	global_position = env.to_global(_tex_pos)


func is_collected() -> bool:
	if not memory_key.is_empty() and GameManager.has_memory_scene(memory_key):
		return true
	if not collected_bool_property.is_empty() and bool(GameManager.get(collected_bool_property)):
		return true
	return false


func apply_collected(area: Area2D = null) -> void:
	if not is_collected():
		return
	visible = false
	var target := area
	if target == null and not interact_area_path.is_empty():
		target = get_node_or_null(interact_area_path) as Area2D
	if not is_instance_valid(target):
		return
	target.monitoring = false
	target.monitorable = false
	var shape := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = true
