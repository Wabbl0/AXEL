extends Node

const FLAME_SHEET := "res://assets/sprites/combat/flame_1_48x48.png"
const DRAW := 48.0
const LIFE := 1.2
const GAP := 0.18
const FPS := 10.0
const CAP := 96
const PUNCH_BLACK := 0.08
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
		_spawn_wave(origin, int(counts[i]))
		if i + 1 < counts.size():
			var tree := get_tree()
			if tree == null:
				return
			await tree.create_timer(GAP).timeout


func _spawn_wave(origin: Vector2, count: int) -> void:
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
		node.modulate = FLAME_COLORS[_rng.randi() % FLAME_COLORS.size()]
		_parent.add_child(node)
		var vel := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(90.0, 240.0)
		_items.append({"node": node, "vel": vel, "age": 0.0})
		_live += 1


func _process(delta: float) -> void:
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
		var vel: Vector2 = item["vel"]
		vel.y += 30.0 * delta
		item["vel"] = vel
		node.position += vel * delta
		var idx := int(floor(age * FPS)) % _frames.size()
		node.texture = _frames[idx]
		if age >= LIFE:
			node.queue_free()
			_items.remove_at(i)
			_live = maxi(_live - 1, 0)
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
	image = _punch_black(image)
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
