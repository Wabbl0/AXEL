extends Node2D
## Looping white/gray memory-marker sprite. Place under PlayerLayer (above Noir)
## so the global CRT pass keeps it bright white like the player.
## Halo child draws a soft white outer glow behind the sharp pixel blob.

const _DEFAULT_SHEET := "res://assets/sprites/memory_glow-Sheet.png"
const _FRAME_COUNT := 5
const _ANIM := &"glow"

@export var sprite_sheet: Texture2D
@export var frame_size: int = 48
@export var animation_fps: float = 8.0
@export var indicator_scale: float = 2.25
## Opt-in only: keep ZERO unless asked. Fine-tune the glow in on-screen
## pixels without moving the node's editor/anchor position.
@export var visual_offset: Vector2 = Vector2.ZERO

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite
@onready var _halo: AnimatedSprite2D = $Halo


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
