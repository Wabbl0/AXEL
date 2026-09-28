extends Node

const CURSOR_PATH := "res://exports/Drawings/axel_cursor.png"
const DISPLAY_HEIGHT := 33.0
const PREP_SIZE := 220
const PRESS_SCALE := 0.91
const PRESS_SECONDS := 0.07

var _sprite: Sprite2D
var _base_scale := 1.0
var _tip := Vector2.ZERO
var _center_local := Vector2.ZERO
var _pressed := false
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var image := _load_cursor()
	if image == null:
		return
	var tex := ImageTexture.create_from_image(image)
	var layer := CanvasLayer.new()
	layer.name = "AxelCursor"
	layer.layer = 400
	add_child(layer)
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.offset = -_tip
	_center_local = Vector2(image.get_size()) * 0.5 - _tip
	_base_scale = DISPLAY_HEIGHT / float(image.get_height())
	_sprite.scale = Vector2(_base_scale, _base_scale)
	layer.add_child(_sprite)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	set_process_input(true)


func _process(_delta: float) -> void:
	if _sprite == null:
		return
	var mouse := get_viewport().get_mouse_position()
	var shrink := _base_scale - _sprite.scale.x
	_sprite.global_position = mouse + _center_local * shrink


func _input(event: InputEvent) -> void:
	if _sprite == null or not (event is InputEventMouseButton):
		return
	var button := event as InputEventMouseButton
	if button.button_index != MOUSE_BUTTON_LEFT:
		return
	_set_pressed(button.pressed)


func _set_pressed(down: bool) -> void:
	if _pressed == down:
		return
	_pressed = down
	var amount := _base_scale * (PRESS_SCALE if down else 1.0)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_sprite, "scale", Vector2(amount, amount), PRESS_SECONDS)


func _load_cursor() -> Image:
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(CURSOR_PATH))
	if err != OK:
		push_error("AxelCursor: could not load %s" % CURSOR_PATH)
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var longest := maxi(image.get_width(), image.get_height())
	if longest > PREP_SIZE:
		var fit := float(PREP_SIZE) / float(longest)
		image.resize(
			maxi(1, int(round(image.get_width() * fit))),
			maxi(1, int(round(image.get_height() * fit))),
			Image.INTERPOLATE_LANCZOS
		)
	_clear_outside(image)
	return image


func _clear_outside(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
	var queue: Array[Vector2i] = []
	_try_seed(image, seen, queue, 0, 0)
	_try_seed(image, seen, queue, width - 1, 0)
	_try_seed(image, seen, queue, 0, height - 1)
	_try_seed(image, seen, queue, width - 1, height - 1)
	var head := 0
	while head < queue.size():
		var p: Vector2i = queue[head]
		head += 1
		_try_seed(image, seen, queue, p.x + 1, p.y)
		_try_seed(image, seen, queue, p.x - 1, p.y)
		_try_seed(image, seen, queue, p.x, p.y + 1)
		_try_seed(image, seen, queue, p.x, p.y - 1)
	var clear := Color(0, 0, 0, 0)
	var best := Vector2i(0, 0)
	var best_score := 999999
	for y in height:
		for x in width:
			var i := y * width + x
			if seen[i] == 1:
				image.set_pixel(x, y, clear)
				continue
			var score := x + y
			if score < best_score:
				best_score = score
				best = Vector2i(x, y)
	_tip = Vector2(best)


func _try_seed(image: Image, seen: PackedByteArray, queue: Array[Vector2i], x: int, y: int) -> void:
	var width := image.get_width()
	var height := image.get_height()
	if x < 0 or y < 0 or x >= width or y >= height:
		return
	var i := y * width + x
	if seen[i] != 0:
		return
	var color := image.get_pixel(x, y)
	if color.r < 0.92 or color.g < 0.92 or color.b < 0.92:
		return
	seen[i] = 1
	queue.append(Vector2i(x, y))
