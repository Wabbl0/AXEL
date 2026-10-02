extends Node2D

const _DEFAULT_SHEET := "res://assets/sprites/items_indicator-Sheet.png"
const _ANIM := &"point"
const OutlineStyle := preload("res://scenes/fx/marker_outline_style.gd")
const GLYPH_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const DRAW_BELOW_PLAYER_Z := -8
const GLYPH_FONT_PX := 28
const GLYPH_OVERLAP_PX := 14.0

@export var sprite_sheet: Texture2D
@export var frame_width: int = 48
@export var frame_height: int = 48
@export var animation_fps: float = 8.0
@export var marker_px: float = 180.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite
@onready var _shadow: AnimatedSprite2D = $ShadowOutline
@onready var _halo: AnimatedSprite2D = $RedHalo

var _pickup: Node2D = null
var _glyph: Label = null
var _ink_frame := Rect2(0, 0, 48, 48)


func bind_pickup(pickup: Node2D) -> void:
	_pickup = pickup


func ink_local_rect() -> Rect2:
	return _ink_frame


func ink_screen_rect() -> Rect2:
	var ink := _ink_centered()
	if ink.size.x <= 1.0 or ink.size.y <= 1.0:
		return Rect2()
	var xf := get_global_transform_with_canvas()
	var rect := Rect2(xf * ink.position, Vector2.ZERO)
	rect = rect.expand(xf * (ink.position + Vector2(ink.size.x, 0.0)))
	rect = rect.expand(xf * (ink.position + ink.size))
	rect = rect.expand(xf * (ink.position + Vector2(0.0, ink.size.y)))
	return rect


func set_rarity_glyph(glyph: String) -> void:
	_ensure_glyph()
	if _glyph == null:
		return
	_glyph.text = glyph
	_glyph.visible = not glyph.is_empty()
	_fit_glyph_scale()


func _ready() -> void:
	z_index = DRAW_BELOW_PLAYER_Z
	OutlineStyle.apply_item_halo(_halo)
	_ensure_glyph()
	if sprite_sheet == null and ResourceLoader.exists(_DEFAULT_SHEET):
		sprite_sheet = load(_DEFAULT_SHEET) as Texture2D
	if sprite_sheet == null:
		push_warning("ItemMarker: missing sprite sheet at %s" % _DEFAULT_SHEET)
		return
	_build_frames()
	_sprite.play(_ANIM)
	_shadow.play(_ANIM)
	_halo.play(_ANIM)
	_halo.frame = _sprite.frame
	OutlineStyle.sync_frame(_halo)
	_sync_to_pickup()
	_fit_glyph_scale()
	set_process(true)


func _process(_delta: float) -> void:
	_sync_to_pickup()
	if _sprite.sprite_frames != null:
		_halo.frame = _sprite.frame
		OutlineStyle.sync_frame(_halo)


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
	_fit_glyph_scale()


func _ensure_glyph() -> void:
	if _glyph != null and is_instance_valid(_glyph):
		return
	_glyph = Label.new()
	_glyph.name = "RarityGlyph"
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glyph.add_theme_font_override("font", GLYPH_FONT)
	_glyph.add_theme_font_size_override("font_size", GLYPH_FONT_PX)
	_glyph.add_theme_color_override("font_color", Color(0.92, 0.88, 0.88, 1.0))
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_glyph.visible = false
	add_child(_glyph)
	_fit_glyph_scale()


func _fit_glyph_scale() -> void:
	if _glyph == null:
		return
	var s := maxf(absf(scale.x), 0.001)
	_glyph.scale = Vector2(1.0 / s, 1.0 / s)
	var glyph_px := _glyph.get_combined_minimum_size()
	if glyph_px.y < 1.0:
		glyph_px = Vector2(float(GLYPH_FONT_PX), float(GLYPH_FONT_PX))
	_glyph.size = glyph_px
	var tuck := GLYPH_OVERLAP_PX / s
	var glyph_h := glyph_px.y / s
	var ink := _ink_centered()
	_glyph.position = Vector2(ink.end.x - tuck, ink.position.y + tuck - glyph_h)


func _ink_centered() -> Rect2:
	var half := Vector2(float(frame_width), float(frame_height)) * 0.5
	var sprite_offset := Vector2.ZERO
	if _sprite != null:
		sprite_offset = _sprite.offset
	return Rect2(_ink_frame.position - half + sprite_offset, _ink_frame.size)


func _build_frames() -> void:
	_measure_ink()
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
	_halo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _measure_ink() -> void:
	var cell_w := maxi(frame_width, 1)
	var cell_h := maxi(frame_height, 1)
	_ink_frame = Rect2(0, 0, cell_w, cell_h)
	if sprite_sheet == null:
		return
	var image := sprite_sheet.get_image()
	if image == null or image.is_compressed():
		return
	var cols := int(floor(float(image.get_width()) / float(cell_w)))
	var min_x := cell_w
	var min_y := cell_h
	var max_x := 0
	var max_y := 0
	for i in cols:
		for y in cell_h:
			if y >= image.get_height():
				continue
			for x in cell_w:
				var px := i * cell_w + x
				if px >= image.get_width():
					continue
				if image.get_pixel(px, y).a <= 0.0:
					continue
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x + 1)
				max_y = maxi(max_y, y + 1)
	if max_x <= min_x or max_y <= min_y:
		return
	_ink_frame = Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


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
