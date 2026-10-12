extends Node

const FLAME_SHEET := "res://assets/sprites/combat/flame_1_48x48.png"
const DRAW := 48.0
const LIFE := 1.2
const GAP := 0.18
const FPS := 10.0
const CAP := 96
const PUNCH_BLACK := 0.08
const LINGER_GRAVITY := 1400.0
const LINGER_BOUNCE_Y := 0.45
const LINGER_BOUNCE_X := 0.8
const LINGER_MAX_BOUNCES := 3
const LINGER_FADE_SEC := 0.6
const LINGER_MAX_AGE := 4.0
const BURN_START := 0.5
const BURN_RED := Color(0.86, 0.08, 0.08, 1.0)
const BURN_EMBER := Color(0.45, 0.03, 0.03, 1.0)
const BURN_SHRINK := 0.3
const BURN_FLICKER := 0.18
const OUT_SEC := 0.35
const OUT_SHRINK := 0.4
const FLAME_COLORS: Array[Color] = [
	Color(1.0, 0.0, 0.0, 1.0),
	Color(1.0, 1.0, 1.0, 1.0),
	Color(0.62, 0.58, 0.54, 1.0),
]

static var _live := 0
static var _frames: Array[Texture2D] = []

var _parent: Control
var _rng := RandomNumberGenerator.new()
var _items: Array[Dictionary] = []


func _ready() -> void:
	_rng.randomize()
	set_process(true)


func bind(parent: Control) -> void:
	_parent = parent


func play_waves(origin: Vector2, counts: Array) -> void:
	for i in counts.size():
		_spawn_wave(origin, int(counts[i]), false)
		if i + 1 < counts.size():
			var tree := get_tree()
			if tree == null:
				return
			await CombatPace.await_seconds(GAP)


func play_waves_linger(origin: Vector2, counts: Array) -> void:
	for i in counts.size():
		_spawn_wave(origin, int(counts[i]), true)
		if i + 1 < counts.size():
			var tree := get_tree()
			if tree == null:
				return
			await CombatPace.await_seconds(GAP)


func await_done() -> void:
	var guard := 0
	while not _items.is_empty() and guard < 120:
		guard += 1
		if get_tree() == null:
			return
		await CombatPace.await_seconds(0.05)


func _spawn_wave(origin: Vector2, count: int, linger: bool) -> void:
	_ensure_frames()
	if _parent == null or _frames.is_empty():
		return
	for _i in count:
		if _live >= CAP:
			return
		var node := TextureRect.new()
		node.texture = _frames[0]
		node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.size = Vector2(DRAW, DRAW)
		node.position = origin - Vector2(DRAW, DRAW) * 0.5
		var base: Color = FLAME_COLORS[_rng.randi() % FLAME_COLORS.size()]
		node.modulate = base
		node.pivot_offset = Vector2(DRAW, DRAW) * 0.5
		_parent.add_child(node)
		var vel := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(90.0, 240.0)
		_items.append({
			"node": node,
			"vel": vel,
			"age": 0.0,
			"linger": linger,
			"bounces": 0,
			"fading": false,
			"fade_t": 0.0,
			"color": base,
		})
		_live += 1


func _floor_y() -> float:
	return view_bottom(_parent) - DRAW


static func view_bottom(host: Control) -> float:
	if host == null or not host.is_inside_tree():
		return 1280.0
	var vp := host.get_viewport()
	if vp == null:
		return host.size.y
	var screen_h := vp.get_visible_rect().size.y
	var inv := host.get_global_transform_with_canvas().affine_inverse()
	return (inv * Vector2(0.0, screen_h)).y


static func burn(base: Color, k: float, phase: float, age: float) -> Color:
	var t := clampf(k, 0.0, 1.0)
	var c := base.lerp(BURN_RED, clampf(t * 2.0, 0.0, 1.0)).lerp(BURN_EMBER, clampf(t * 2.0 - 1.0, 0.0, 1.0))
	var flicker := 1.0 - BURN_FLICKER * t * (0.5 + 0.5 * sin(age * 38.0 + phase))
	c.a = base.a * (1.0 - t) * (1.0 - t) * flicker
	return c


static func spark_look(base: Color, age: float, life: float, phase: float) -> Array:
	var t := clampf(age / maxf(life, 0.001), 0.0, 1.0)
	var k := clampf((t - BURN_START) / (1.0 - BURN_START), 0.0, 1.0)
	return [burn(base, k, phase, age), lerpf(1.0, BURN_SHRINK, k)]


static func palette_grey(image: Image) -> Image:
	var copy := image.duplicate() as Image
	if copy.get_format() != Image.FORMAT_RGBA8:
		copy.convert(Image.FORMAT_RGBA8)
	for y in copy.get_height():
		for x in copy.get_width():
			var pixel := copy.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			var v := maxf(pixel.r, maxf(pixel.g, pixel.b))
			copy.set_pixel(x, y, Color(v, v, v, pixel.a))
	return copy


func _free_item(i: int, node: TextureRect) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()
	_items.remove_at(i)
	_live = maxi(_live - 1, 0)


func _process(delta: float) -> void:
	delta *= CombatPace.multiplier()
	var i := _items.size() - 1
	while i >= 0:
		var item: Dictionary = _items[i]
		var node := item.get("node") as TextureRect
		if node == null or not is_instance_valid(node):
			_items.remove_at(i)
			_live = maxi(_live - 1, 0)
			i -= 1
			continue
		var age := float(item["age"]) + delta
		item["age"] = age
		var linger := bool(item.get("linger", false))
		if linger:
			if bool(item.get("fading", false)):
				var fade_t := float(item.get("fade_t", 0.0)) + delta
				item["fade_t"] = fade_t
				var fk := clampf(fade_t / LINGER_FADE_SEC, 0.0, 1.0)
				node.modulate = burn(item.get("color", Color.WHITE), fk, float(i), age)
				node.scale = Vector2.ONE * lerpf(1.0, OUT_SHRINK, fk)
				var idx_f := int(floor(age * FPS)) % _frames.size()
				node.texture = _frames[idx_f]
				if fade_t >= LINGER_FADE_SEC or age >= LINGER_MAX_AGE:
					_free_item(i, node)
				i -= 1
				continue
			var vel: Vector2 = item["vel"]
			vel.y += LINGER_GRAVITY * delta
			item["vel"] = vel
			node.position += vel * delta
			var floor_y := _floor_y()
			if node.position.y >= floor_y and vel.y > 0.0:
				node.position.y = floor_y
				vel.y = -vel.y * LINGER_BOUNCE_Y
				vel.x *= LINGER_BOUNCE_X
				item["vel"] = vel
				var bounces := int(item.get("bounces", 0)) + 1
				item["bounces"] = bounces
				if bounces >= LINGER_MAX_BOUNCES:
					item["vel"] = Vector2.ZERO
					item["fading"] = true
					item["fade_t"] = 0.0
			var idx := int(floor(age * FPS)) % _frames.size()
			node.texture = _frames[idx]
			if age >= LINGER_MAX_AGE:
				_free_item(i, node)
			i -= 1
			continue
		var vel_n: Vector2 = item["vel"]
		vel_n.y += 30.0 * delta
		item["vel"] = vel_n
		node.position += vel_n * delta
		var idx_n := int(floor(age * FPS)) % _frames.size()
		node.texture = _frames[idx_n]
		var out_k := clampf((age - (LIFE - OUT_SEC)) / OUT_SEC, 0.0, 1.0)
		if out_k > 0.0:
			node.modulate = burn(item.get("color", Color.WHITE), out_k, float(i), age)
			node.scale = Vector2.ONE * lerpf(1.0, OUT_SHRINK, out_k)
		if age >= LIFE:
			_free_item(i, node)
		i -= 1


func _exit_tree() -> void:
	for item in _items:
		var node := item.get("node") as Node
		if node != null and is_instance_valid(node):
			node.queue_free()
	_live = maxi(_live - _items.size(), 0)
	_items.clear()


func _ensure_frames() -> void:
	if not _frames.is_empty():
		return
	if not ResourceLoader.exists(FLAME_SHEET):
		return
	var src := load(FLAME_SHEET) as Texture2D
	if src == null:
		return
	var image := src.get_image()
	if image == null:
		return
	if image.is_compressed():
		image.decompress()
	image = palette_grey(_punch_black(image))
	var cell := image.get_height()
	if cell <= 0:
		return
	var img_tex := ImageTexture.create_from_image(image)
	var cols := int(floor(float(image.get_width()) / float(cell)))
	for i in maxi(cols, 1):
		var atlas := AtlasTexture.new()
		atlas.atlas = img_tex
		atlas.region = Rect2(i * cell, 0, cell, cell)
		atlas.filter_clip = true
		_frames.append(atlas)


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
