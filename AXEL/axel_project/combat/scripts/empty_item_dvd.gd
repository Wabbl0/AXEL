extends Control

const VT323_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const MILL_SHEET := "res://assets/sprites/combat/wind_mill_blades_48x48.png"
const FLAME_SHEET := "res://assets/sprites/combat/flame_1_48x48.png"
const TICKER_TEXT := "Nothing but us chickens."
const TICKER_H := 63.0
const MILL_DRAW := 96.0
const FLAME_DRAW := 48.0
const SPEED := 118.0
const TICKER_SPEED := 72.0
const MILL_FPS := 8.0
const FLAME_FPS := 10.0
const FLAME_FILL_COUNT := 16
const PUNCH_BLACK := 0.08
const DVD_COLORS: Array[Color] = [
	Color(1.0, 0.0, 0.0, 1.0),
	Color(1.0, 1.0, 1.0, 1.0),
	Color(0.62, 0.58, 0.54, 1.0),
]

var _rng := RandomNumberGenerator.new()
var _mill_frames: Array[Texture2D] = []
var _flame_frames: Array[Texture2D] = []
var _bouncers: Array[Dictionary] = []
var _bounce_clip: Control
var _ticker_clip: Control
var _ticker: Label
var _ticker_x := 0.0
var _exploded := false
var _anim_t := 0.0


func _ready() -> void:
	name = "EmptyItemDvd"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	_rng.seed = int(Time.get_ticks_usec())
	_mill_frames = _slice_strip(MILL_SHEET, false)
	_flame_frames = _slice_strip(FLAME_SHEET, true)
	_build_chrome()
	_spawn_mill()
	set_process(true)


func _build_chrome() -> void:
	_bounce_clip = Control.new()
	_bounce_clip.name = "BounceClip"
	_bounce_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bounce_clip.clip_contents = true
	_bounce_clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bounce_clip.offset_bottom = -TICKER_H
	add_child(_bounce_clip)

	_ticker_clip = Control.new()
	_ticker_clip.name = "TickerClip"
	_ticker_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticker_clip.clip_contents = true
	_ticker_clip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_ticker_clip.anchor_top = 1.0
	_ticker_clip.offset_top = -TICKER_H
	_ticker_clip.offset_bottom = 0.0
	_ticker_clip.offset_left = 0.0
	_ticker_clip.offset_right = 0.0
	add_child(_ticker_clip)

	_ticker = Label.new()
	_ticker.name = "ChickensTicker"
	_ticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ticker.add_theme_font_override("font", VT323_FONT)
	_ticker.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0, 1.0))
	_ticker.add_theme_font_size_override("font_size", 46)
	_ticker.text = "%s    %s    %s    %s" % [TICKER_TEXT, TICKER_TEXT, TICKER_TEXT, TICKER_TEXT]
	_ticker_clip.add_child(_ticker)


func _spawn_mill() -> void:
	if _mill_frames.is_empty():
		return
	var node := _make_sprite(_mill_frames[0], Vector2(MILL_DRAW, MILL_DRAW))
	_bounce_clip.add_child(node)
	var bounds := _bounce_size()
	var start := Vector2(
		_rng.randf_range(8.0, maxf(bounds.x - MILL_DRAW - 8.0, 8.0)),
		_rng.randf_range(8.0, maxf(bounds.y - MILL_DRAW - 8.0, 8.0))
	)
	node.position = start
	var heading := Vector2(1.0, 0.73).normalized()
	if _rng.randf() < 0.5:
		heading.x *= -1.0
	if _rng.randf() < 0.5:
		heading.y *= -1.0
	_bouncers.append({
		"node": node,
		"vel": heading * SPEED,
		"size": Vector2(MILL_DRAW, MILL_DRAW),
		"frames": _mill_frames,
		"color_i": 0,
		"kind": &"mill",
	})
	_apply_color(_bouncers[0])


func _process(delta: float) -> void:
	_anim_t += delta
	_tick_ticker(delta)
	var bounds := _bounce_size()
	if bounds.x <= 4.0 or bounds.y <= 4.0:
		return
	for bouncer in _bouncers:
		_step_bouncer(bouncer, delta, bounds)
		_advance_frame(bouncer)


func _tick_ticker(delta: float) -> void:
	if _ticker == null or _ticker_clip == null:
		return
	if _ticker.size.x <= 1.0:
		_ticker.reset_size()
	_ticker_x -= TICKER_SPEED * delta
	var loop_w := maxf(_ticker.size.x * 0.25, 80.0)
	if _ticker_x <= -loop_w:
		_ticker_x += loop_w
	_ticker.position = Vector2(_ticker_x, 0.0)
	_ticker.size = Vector2(_ticker.get_minimum_size().x, TICKER_H)


func _step_bouncer(bouncer: Dictionary, delta: float, bounds: Vector2) -> void:
	var node := bouncer.get("node") as Control
	if node == null or not is_instance_valid(node):
		return
	var sprite_size: Vector2 = bouncer["size"]
	var vel: Vector2 = bouncer["vel"]
	var pos := node.position + vel * delta
	var max_x := maxf(bounds.x - sprite_size.x, 0.0)
	var max_y := maxf(bounds.y - sprite_size.y, 0.0)
	var hit_x := false
	var hit_y := false
	if pos.x <= 0.0:
		pos.x = 0.0
		vel.x = absf(vel.x)
		hit_x = true
	elif pos.x >= max_x:
		pos.x = max_x
		vel.x = -absf(vel.x)
		hit_x = true
	if pos.y <= 0.0:
		pos.y = 0.0
		vel.y = absf(vel.y)
		hit_y = true
	elif pos.y >= max_y:
		pos.y = max_y
		vel.y = -absf(vel.y)
		hit_y = true
	node.position = pos
	bouncer["vel"] = vel
	if hit_x or hit_y:
		if StringName(bouncer.get("kind", &"")) == &"mill":
			bouncer["color_i"] = int(bouncer.get("color_i", 0) + 1) % DVD_COLORS.size()
			_apply_color(bouncer)
		if hit_x and hit_y:
			_on_corner(pos)


func _on_corner(at: Vector2) -> void:
	if _exploded or _flame_frames.is_empty():
		return
	_exploded = true
	var bounds := _bounce_size()
	for i in FLAME_FILL_COUNT:
		var node := _make_sprite(_flame_frames[i % _flame_frames.size()], Vector2(FLAME_DRAW, FLAME_DRAW))
		_bounce_clip.add_child(node)
		var jitter := Vector2(_rng.randf_range(-12.0, 12.0), _rng.randf_range(-12.0, 12.0))
		node.position = Vector2(
			clampf(at.x + jitter.x, 0.0, maxf(bounds.x - FLAME_DRAW, 0.0)),
			clampf(at.y + jitter.y, 0.0, maxf(bounds.y - FLAME_DRAW, 0.0))
		)
		var heading := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
		if heading.length_squared() < 0.04:
			heading = Vector2(1.0, 0.73)
		heading = heading.normalized()
		var speed := SPEED * _rng.randf_range(0.75, 1.35)
		_bouncers.append({
			"node": node,
			"vel": heading * speed,
			"size": Vector2(FLAME_DRAW, FLAME_DRAW),
			"frames": _flame_frames,
			"color_i": 0,
			"kind": &"flame",
		})


func _advance_frame(bouncer: Dictionary) -> void:
	var frames: Array = bouncer.get("frames", [])
	if frames.is_empty():
		return
	var node := bouncer.get("node") as TextureRect
	if node == null:
		return
	var fps := MILL_FPS if StringName(bouncer.get("kind", &"")) == &"mill" else FLAME_FPS
	var idx := int(floor(_anim_t * fps)) % frames.size()
	node.texture = frames[idx]


func _apply_color(bouncer: Dictionary) -> void:
	var node := bouncer.get("node") as CanvasItem
	if node == null:
		return
	var i := int(bouncer.get("color_i", 0)) % DVD_COLORS.size()
	node.modulate = DVD_COLORS[i]


func _bounce_size() -> Vector2:
	if _bounce_clip == null:
		return size
	var sz := _bounce_clip.size
	if sz.x <= 1.0 or sz.y <= 1.0:
		sz = Vector2(size.x, maxf(size.y - TICKER_H, 1.0))
	return sz


func _make_sprite(tex: Texture2D, draw_size: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = tex
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.custom_minimum_size = draw_size
	node.size = draw_size
	return node


func _slice_strip(path: String, punch_black: bool) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if not ResourceLoader.exists(path):
		push_warning("EmptyItemDvd: missing sheet %s" % path)
		return out
	var src := load(path) as Texture2D
	if src == null:
		return out
	var image := src.get_image()
	if image == null:
		return out
	if image.is_compressed():
		image.decompress()
	if punch_black:
		image = _punch_black(image)
	var cell := image.get_height()
	if cell <= 0:
		return out
	var img_tex := ImageTexture.create_from_image(image)
	var cols := int(floor(float(image.get_width()) / float(cell)))
	for i in maxi(cols, 1):
		var atlas := AtlasTexture.new()
		atlas.atlas = img_tex
		atlas.region = Rect2(i * cell, 0, cell, cell)
		atlas.filter_clip = true
		out.append(atlas)
	return out


func _punch_black(image: Image) -> Image:
	var copy := image.duplicate() as Image
	if copy.get_format() != Image.FORMAT_RGBA8:
		copy.convert(Image.FORMAT_RGBA8)
	for y in copy.get_height():
		for x in copy.get_width():
			var pixel := copy.get_pixel(x, y)
			if pixel.r <= PUNCH_BLACK and pixel.g <= PUNCH_BLACK and pixel.b <= PUNCH_BLACK:
				copy.set_pixel(x, y, Color(0, 0, 0, 0))
	return copy
