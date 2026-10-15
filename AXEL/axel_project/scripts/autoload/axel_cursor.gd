extends Node

const CURSOR_PATH := "res://exports/Drawings/axel_cursor.png"
const DISPLAY_HEIGHT := 33.0
const PIXEL_TEX_HEIGHT := 16
const INK_COVERAGE := 0.12
const PAPER_BYTE := 235
const SAMPLE_STEP := 2
const EDGE_PAD := 1
const FILL_COLOR := Color(1, 1, 1, 1)
const OUTLINE_COLOR := Color(1.0, 0.08, 0.08, 0.28)
const SHADOW_COLOR := Color(0, 0, 0, 0.6)
const SHADOW_OFFSET := Vector2i(1, 1)
const PRESS_SCALE := 0.91
const PRESS_SECONDS := 0.07

var _sprite: Sprite2D
var _body_pixels := PIXEL_TEX_HEIGHT
var _base_scale := 1.0
var _tip := Vector2.ZERO
var _center_local := Vector2.ZERO
var _pressed := false
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if PortraitUi.is_touch_device():
		return
	var image := _load_cursor()
	if image == null:
		return
	var tex := ImageTexture.create_from_image(image)
	var layer := CanvasLayer.new()
	layer.name = "AxelCursor"
	layer.layer = 400
	add_child(layer)
	_sprite = Sprite2D.new()
	_sprite.name = "CursorSprite"
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.offset = -_tip
	_center_local = Vector2(image.get_size()) * 0.5 - _tip
	_base_scale = DISPLAY_HEIGHT / float(_body_pixels)
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
	var tex := load(CURSOR_PATH) as Texture2D
	var image: Image = tex.get_image() if tex != null else null
	if image == null:
		push_error("AxelCursor: could not load %s" % CURSOR_PATH)
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return _pixelate(image)


func _pixelate(image: Image) -> Image:
	var src_w := image.get_width()
	var src_h := image.get_height()
	if src_h <= PIXEL_TEX_HEIGHT:
		return image
	var dst_h := PIXEL_TEX_HEIGHT
	var dst_w := maxi(1, int(round(float(src_w) * float(dst_h) / float(src_h))))
	var src := image.get_data()
	var keep := PackedByteArray()
	keep.resize(dst_w * dst_h)
	for oy in dst_h:
		@warning_ignore("integer_division")
		var y0 := oy * src_h / dst_h
		@warning_ignore("integer_division")
		var y1 := (oy + 1) * src_h / dst_h
		if y1 <= y0:
			y1 = mini(src_h, y0 + 1)
		for ox in dst_w:
			@warning_ignore("integer_division")
			var x0 := ox * src_w / dst_w
			@warning_ignore("integer_division")
			var x1 := (ox + 1) * src_w / dst_w
			if x1 <= x0:
				x1 = mini(src_w, x0 + 1)
			var n := 0
			var samples := 0
			for sy in range(y0, y1, SAMPLE_STEP):
				var row := sy * src_w * 4
				for sx in range(x0, x1, SAMPLE_STEP):
					samples += 1
					var i := row + sx * 4
					var pr := int(src[i])
					var pg := int(src[i + 1])
					var pb := int(src[i + 2])
					if pr >= PAPER_BYTE and pg >= PAPER_BYTE and pb >= PAPER_BYTE:
						continue
					n += 1
			if samples > 0 and n > 0 and float(n) / float(samples) >= INK_COVERAGE:
				keep[oy * dst_w + ox] = 1
	_body_pixels = dst_h
	return _paint_cursor(keep, dst_w, dst_h)


func _paint_cursor(keep: PackedByteArray, body_w: int, body_h: int) -> Image:
	var out_w := body_w + EDGE_PAD * 2 + SHADOW_OFFSET.x
	var out_h := body_h + EDGE_PAD * 2 + SHADOW_OFFSET.y
	var out := Image.create(out_w, out_h, false, Image.FORMAT_RGBA8)
	var outline := PackedByteArray()
	outline.resize(out_w * out_h)
	var body := PackedByteArray()
	body.resize(out_w * out_h)
	var best := Vector2i(EDGE_PAD, EDGE_PAD)
	var best_score := 999999
	var found := false
	for y in body_h:
		for x in body_w:
			if keep[y * body_w + x] == 0:
				continue
			var px := x + EDGE_PAD
			var py := y + EDGE_PAD
			body[py * out_w + px] = 1
			var score := px + py
			if score < best_score:
				best_score = score
				best = Vector2i(px, py)
				found = true
	if found:
		_tip = Vector2(best)
	var outside := PackedByteArray()
	outside.resize(out_w * out_h)
	var queue: Array[Vector2i] = []
	for x in out_w:
		_seed_outside(body, outside, queue, out_w, out_h, x, 0)
		_seed_outside(body, outside, queue, out_w, out_h, x, out_h - 1)
	for y in out_h:
		_seed_outside(body, outside, queue, out_w, out_h, 0, y)
		_seed_outside(body, outside, queue, out_w, out_h, out_w - 1, y)
	var head := 0
	while head < queue.size():
		var p: Vector2i = queue[head]
		head += 1
		_seed_outside(body, outside, queue, out_w, out_h, p.x + 1, p.y)
		_seed_outside(body, outside, queue, out_w, out_h, p.x - 1, p.y)
		_seed_outside(body, outside, queue, out_w, out_h, p.x, p.y + 1)
		_seed_outside(body, outside, queue, out_w, out_h, p.x, p.y - 1)
	for y in out_h:
		for x in out_w:
			var i := y * out_w + x
			if outside[i] == 0:
				continue
			var left := x > 0 and body[i - 1] == 1
			var right := x + 1 < out_w and body[i + 1] == 1
			var up := y > 0 and body[i - out_w] == 1
			var down := y + 1 < out_h and body[i + out_w] == 1
			if (left and right) or (up and down):
				continue
			var touches_body := false
			for ny in range(y - 1, y + 2):
				for nx in range(x - 1, x + 2):
					if nx < 0 or ny < 0 or nx >= out_w or ny >= out_h:
						continue
					if body[ny * out_w + nx] == 1:
						touches_body = true
			if touches_body:
				outline[i] = 1
	for y in out_h:
		for x in out_w:
			var i := y * out_w + x
			if body[i] == 0 and outline[i] == 0:
				continue
			var sx := x + SHADOW_OFFSET.x
			var sy := y + SHADOW_OFFSET.y
			if sx < 0 or sy < 0 or sx >= out_w or sy >= out_h:
				continue
			var si := sy * out_w + sx
			if body[si] == 1 or outside[si] == 0:
				continue
			out.set_pixel(sx, sy, SHADOW_COLOR)
	for y in out_h:
		for x in out_w:
			var i := y * out_w + x
			if outline[i] == 1 and body[i] == 0:
				out.set_pixel(x, y, OUTLINE_COLOR)
	for y in out_h:
		for x in out_w:
			if body[y * out_w + x] == 1:
				out.set_pixel(x, y, FILL_COLOR)
	return out


func _seed_outside(
	body: PackedByteArray,
	outside: PackedByteArray,
	queue: Array[Vector2i],
	width: int,
	height: int,
	x: int,
	y: int
) -> void:
	if x < 0 or y < 0 or x >= width or y >= height:
		return
	var i := y * width + x
	if outside[i] != 0 or body[i] == 1:
		return
	outside[i] = 1
	queue.append(Vector2i(x, y))
