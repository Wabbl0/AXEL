extends Node2D
## Shared "a combat item is here" marker. Every floor pickup shows this same
## pulsing pentacle, so the player learns one shape instead of reading a
## different catalog picture in every room. The item's real name, description
## and icon come from the walk-near card, not from the floor.
##
## Lives under EnvironmentColliders (AxelWorld._spawn_pickups), so it inherits
## the room's cover-fit scale and the live AxelPostFxStack noir + scanline + CRT
## pass. Do NOT reparent to PlayerLayer — that skip is the MemoryIndicator
## exception, not the rule.

const _DEFAULT_SHEET := "res://assets/sprites/animated_pentacle_48x48.png"
const _ANIM := &"pulse"

## The itch sheet is 576x96: twelve frames laid out across, each 48 wide and
## 96 tall. The disc sits in the lower 48 px and pulses dark to pale; the last
## three frames add a glow above it, which is why the cell is two tiles tall
## and not square.
@export var sprite_sheet: Texture2D
@export var frame_width: int = 48
@export var frame_height: int = 96
@export var animation_fps: float = 10.0
## On-screen width of one frame in EnvironmentColliders (texture) pixels.
@export var marker_px: float = 180.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite


func _ready() -> void:
	if sprite_sheet == null and ResourceLoader.exists(_DEFAULT_SHEET):
		sprite_sheet = load(_DEFAULT_SHEET) as Texture2D
	if sprite_sheet == null:
		push_warning("PentacleMarker: missing sprite sheet at %s" % _DEFAULT_SHEET)
		return
	_build_frames()
	# The disc fills the lower half of the cell, so centring the cell would hang
	# the pentacle below the marker. Lift by a quarter cell to put the disc
	# itself on the spot AxelWorld picked.
	_sprite.offset = Vector2(0.0, -float(frame_height) * 0.25)
	scale = Vector2.ONE * (marker_px / maxf(float(frame_width), 0.001))
	_sprite.play(_ANIM)


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


## Guards against a re-exported sheet with padding cells: a fully transparent
## frame would read as the marker blinking out.
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
