extends Node2D

const _DEFAULT_SHEET := "res://assets/sprites/item_hand-Sheet.png"
const _ANIM := &"point"

@export var sprite_sheet: Texture2D
@export var frame_width: int = 48
@export var frame_height: int = 48
@export var animation_fps: float = 8.0
@export var marker_px: float = 180.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite
@onready var _shadow: AnimatedSprite2D = $ShadowOutline
@onready var _halo: AnimatedSprite2D = $RedHalo

var _pickup: Node2D = null


func bind_pickup(pickup: Node2D) -> void:
	_pickup = pickup


func _ready() -> void:
	if sprite_sheet == null and ResourceLoader.exists(_DEFAULT_SHEET):
		sprite_sheet = load(_DEFAULT_SHEET) as Texture2D
	if sprite_sheet == null:
		push_warning("ItemMarker: missing sprite sheet at %s" % _DEFAULT_SHEET)
		return
	_build_frames()
	_sprite.play(_ANIM)
	_shadow.play(_ANIM)
	_halo.play(_ANIM)
	_sync_to_pickup()
	set_process(true)


func _process(_delta: float) -> void:
	_sync_to_pickup()


func _sync_to_pickup() -> void:
	if _pickup == null:
		return
	if not is_instance_valid(_pickup):
		queue_free()
		return
	global_position = _pickup.global_position
	var cell := maxf(float(frame_width), 0.001)
	scale = _pickup.global_scale * (marker_px / cell)
	visible = _pickup.visible
	if _sprite.sprite_frames != null:
		_shadow.frame = _sprite.frame
		_halo.frame = _sprite.frame


func _build_frames() -> void:
	var sf := SpriteFrames.new()
	sf.add_animation(_ANIM)
	sf.set_animation_loop(_ANIM, true)
	sf.set_animation_speed(_ANIM, 1.0)
	var frame_time := 1.0 / maxf(animation_fps, 0.001)
	var cell_w := maxi(frame_width, 1)
	var cell_h := maxi(frame_height, 1)
	var cols := int(floor(float(sprite_sheet.get_width()) / float(cell_w)))
	for i in cols:
		var region := Rect2(i * cell_w, 0, cell_w, cell_h)
		if _region_is_empty(region):
			continue
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = region
		sf.add_frame(_ANIM, atlas, frame_time)
	_sprite.sprite_frames = sf
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_shadow.sprite_frames = sf
	_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_halo.sprite_frames = sf
	_halo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _region_is_empty(region: Rect2) -> bool:
	var image := sprite_sheet.get_image()
	if image == null:
		return false
	if image.is_compressed():
		return false
	for y in range(int(region.position.y), int(region.end.y)):
		for x in range(int(region.position.x), int(region.end.x)):
			if image.get_pixel(x, y).a > 0.0:
				return false
	return true
