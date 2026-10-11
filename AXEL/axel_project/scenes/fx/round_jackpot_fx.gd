extends Control

const SKULL_ART := preload("res://combat/art/grid_symbols/satanic_wild.png")
const FLAME_BURST_SCRIPT := preload("res://combat/scripts/flame_burst.gd")
const RED := Color(0.86, 0.08, 0.08, 1.0)
const DIM_RED := Color(0.45, 0.03, 0.03, 1.0)
const WHITE := Color(1.0, 1.0, 1.0, 1.0)
const GREY := Color(0.62, 0.58, 0.54, 1.0)
const SPARK_COLORS: Array[Color] = [RED, WHITE, WHITE, GREY]
const SPARK_SIZES: Array[float] = [4.0, 6.0, 8.0]
const RAY_COUNT := 16
const RAY_TURN_DEG := 12.0
const RAY_RADIUS := 1300.0
const RAY_IN_SEC := 0.45
const BAR_DELAY_SEC := 0.1
const BAR_IN_SEC := 0.35
const BAR_TOP := -110.0
const BAR_BOTTOM := 200.0
const BAR_MARGIN := 140.0
const BAR_HEIGHT := 6.0
const BULB_GAP := 30.0
const BULB_SIZE := 10.0
const BULB_STEP_SEC := 0.09
const SPARK_GRAVITY := 520.0
const SPARK_DRAG := 0.9
const SPARK_CAP := 700
const VOLLEY_SPARKS := 28
const INTRO_VOLLEYS := 4
const INTRO_VOLLEYS_CALM := 2
const VOLLEY_GAP := 0.26
const IDLE_VOLLEY_SEC := 0.9
const SKULL_COUNT := 26
const SKULL_COUNT_CALM := 10
const SKULL_SPAWN_SEC := 1.3
const SKULL_DRAW := 96.0
const SKULL_GRAVITY := 1500.0
const SKULL_BOUNCE := 0.42
const SKULL_MAX_BOUNCES := 2
const SKULL_FADE_SEC := 0.5
const SKULL_MAX_AGE := 5.0
const RING_LIFE := 0.55
const RING_RADIUS := 900.0

static var _skull_tex: Texture2D

var _front: Control
var _flames
var _rng := RandomNumberGenerator.new()
var _calm := false
var _center := Vector2.ZERO
var _t := 0.0
var _rays_in := 0.0
var _bars_in := 0.0
var _playing := false
var _spawning := false
var _volleys_left := 0
var _volley_clock := 0.0
var _skulls_total := 0
var _skulls_left := 0
var _skull_clock := 0.0
var _sparks: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _skulls: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_rng.randomize()
	set_process(true)


func setup(front: Control, calm: bool) -> void:
	_calm = calm
	_front = front
	if _front != null:
		_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_front.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if not _front.draw.is_connected(_draw_front):
			_front.draw.connect(_draw_front)
		_flames = FLAME_BURST_SCRIPT.new()
		_flames.name = "JackpotFlames"
		add_child(_flames)
		_flames.bind(_front)


func play_intro(center: Vector2) -> void:
	_center = center
	_t = 0.0
	_rays_in = 0.0
	_bars_in = 0.0
	_playing = true
	_spawning = true
	_volleys_left = INTRO_VOLLEYS_CALM if _calm else INTRO_VOLLEYS
	_volley_clock = 0.12
	_skulls_total = SKULL_COUNT_CALM if _calm else SKULL_COUNT
	_skulls_left = _skulls_total
	_skull_clock = 0.0
	shockwave(center)
	queue_redraw()


func snap_final(center: Vector2) -> void:
	_center = center
	_playing = true
	_spawning = true
	_rays_in = 1.0
	_bars_in = 1.0
	_t = maxf(_t, BAR_DELAY_SEC + BAR_IN_SEC)
	_volleys_left = 0
	_volley_clock = IDLE_VOLLEY_SEC
	_skulls_left = 0
	_rings.clear()
	queue_redraw()


func stop_spawning() -> void:
	_spawning = false
	_volleys_left = 0
	_skulls_left = 0


func is_spawning() -> bool:
	return _spawning


func shockwave(point: Vector2) -> void:
	_rings.append({"pos": point, "age": 0.0, "life": RING_LIFE, "max_r": RING_RADIUS, "color": WHITE, "width": 12.0})
	_rings.append({"pos": point, "age": -0.08, "life": RING_LIFE, "max_r": RING_RADIUS * 0.8, "color": RED, "width": 8.0})


func burst_at(point: Vector2, count: int, speed_min: float = 160.0, speed_max: float = 440.0) -> void:
	for i in count:
		if _sparks.size() >= SPARK_CAP:
			return
		var angle := TAU * float(i) / float(maxi(count, 1)) + _rng.randf_range(-0.12, 0.12)
		_sparks.append({
			"pos": point,
			"vel": Vector2.from_angle(angle) * _rng.randf_range(speed_min, speed_max),
			"age": 0.0,
			"life": _rng.randf_range(0.8, 1.3),
			"color": SPARK_COLORS[_rng.randi() % SPARK_COLORS.size()],
			"size": SPARK_SIZES[_rng.randi() % SPARK_SIZES.size()],
		})


func fire_volley() -> void:
	var point := _center + Vector2(_rng.randf_range(-720.0, 720.0), _rng.randf_range(-360.0, 280.0))
	burst_at(point, VOLLEY_SPARKS)
	_rings.append({"pos": point, "age": 0.0, "life": 0.35, "max_r": 110.0, "color": WHITE, "width": 5.0})
	if _flames != null and not _calm:
		_flames.play_waves(point, [6])


func _process(delta: float) -> void:
	var tree := get_tree()
	if tree != null and tree.paused:
		return
	if not _playing and _sparks.is_empty() and _rings.is_empty() and _skulls.is_empty():
		return
	var d := delta * CombatPace.multiplier()
	_t += d
	if _playing:
		_rays_in = minf(_rays_in + d / RAY_IN_SEC, 1.0)
		if _t >= BAR_DELAY_SEC:
			_bars_in = minf(_bars_in + d / BAR_IN_SEC, 1.0)
	if _spawning:
		_tick_volleys(d)
		_tick_skull_spawn(d)
	_tick_sparks(d)
	_tick_rings(d)
	_tick_skulls(d)
	queue_redraw()
	if _front != null:
		_front.queue_redraw()


func _tick_volleys(d: float) -> void:
	_volley_clock -= d
	if _volley_clock > 0.0:
		return
	if _volleys_left > 0:
		fire_volley()
		_volleys_left -= 1
		_volley_clock = VOLLEY_GAP if _volleys_left > 0 else IDLE_VOLLEY_SEC
	elif not _calm:
		fire_volley()
		_volley_clock = IDLE_VOLLEY_SEC


func _tick_skull_spawn(d: float) -> void:
	if _skulls_left <= 0:
		return
	_skull_clock -= d
	var gap := SKULL_SPAWN_SEC / float(maxi(_skulls_total, 1))
	while _skull_clock <= 0.0 and _skulls_left > 0:
		_spawn_skull()
		_skulls_left -= 1
		_skull_clock += gap


func _spawn_skull() -> void:
	var w := size.x if size.x > 0.0 else 1920.0
	_skulls.append({
		"pos": Vector2(_rng.randf_range(80.0, w - 80.0), -SKULL_DRAW),
		"vel": Vector2(_rng.randf_range(-120.0, 120.0), _rng.randf_range(150.0, 450.0)),
		"rot": _rng.randf_range(0.0, TAU),
		"spin": _rng.randf_range(-6.0, 6.0),
		"age": 0.0,
		"bounces": 0,
		"fade_t": -1.0,
	})


func _tick_sparks(d: float) -> void:
	var i := _sparks.size() - 1
	while i >= 0:
		var s: Dictionary = _sparks[i]
		var vel: Vector2 = s["vel"]
		vel.y += SPARK_GRAVITY * d
		vel *= maxf(1.0 - SPARK_DRAG * d, 0.0)
		s["vel"] = vel
		s["pos"] = (s["pos"] as Vector2) + vel * d
		s["age"] = float(s["age"]) + d
		if float(s["age"]) >= float(s["life"]):
			_sparks.remove_at(i)
		i -= 1


func _tick_rings(d: float) -> void:
	var i := _rings.size() - 1
	while i >= 0:
		var r: Dictionary = _rings[i]
		r["age"] = float(r["age"]) + d
		if float(r["age"]) >= float(r["life"]):
			_rings.remove_at(i)
		i -= 1


func _tick_skulls(d: float) -> void:
	var h := size.y if size.y > 0.0 else 1280.0
	var w := size.x if size.x > 0.0 else 1920.0
	var floor_y := h - 8.0 - SKULL_DRAW * 0.5
	var i := _skulls.size() - 1
	while i >= 0:
		var k: Dictionary = _skulls[i]
		var age := float(k["age"]) + d
		k["age"] = age
		var fade_t := float(k["fade_t"])
		if fade_t >= 0.0:
			fade_t += d
			k["fade_t"] = fade_t
			if fade_t >= SKULL_FADE_SEC:
				_skulls.remove_at(i)
			i -= 1
			continue
		var vel: Vector2 = k["vel"]
		vel.y += SKULL_GRAVITY * d
		var pos: Vector2 = (k["pos"] as Vector2) + vel * d
		k["rot"] = float(k["rot"]) + float(k["spin"]) * d
		if pos.y >= floor_y and vel.y > 0.0:
			pos.y = floor_y
			vel.y = -vel.y * SKULL_BOUNCE
			vel.x *= 0.7
			k["spin"] = float(k["spin"]) * 0.6
			var bounces := int(k["bounces"]) + 1
			k["bounces"] = bounces
			if bounces >= SKULL_MAX_BOUNCES:
				k["fade_t"] = 0.0
		k["vel"] = vel
		k["pos"] = pos
		if age >= SKULL_MAX_AGE or pos.x < -SKULL_DRAW or pos.x > w + SKULL_DRAW:
			_skulls.remove_at(i)
		i -= 1


func _draw() -> void:
	if _playing:
		_draw_rays()
		if _bars_in > 0.0:
			_draw_bar(_center.y + BAR_TOP, true)
			_draw_bar(_center.y + BAR_BOTTOM, false)
	for r in _rings:
		var age := float(r["age"])
		if age < 0.0:
			continue
		var k := clampf(age / float(r["life"]), 0.0, 1.0)
		var radius := float(r["max_r"]) * (1.0 - pow(1.0 - k, 3.0))
		var c: Color = r["color"]
		c.a = 1.0 - k
		draw_arc(r["pos"], maxf(radius, 1.0), 0.0, TAU, 96, c, float(r["width"]) * (1.0 - k * 0.6) + 1.0)


func _draw_rays() -> void:
	var rs := _ease_back(_rays_in)
	if rs <= 0.001:
		return
	var calm_k := 0.55 if _calm else 1.0
	var pulse := 1.0 if _calm else 0.85 + 0.15 * sin(_t * 6.0)
	var turn := 0.0 if _calm else deg_to_rad(RAY_TURN_DEG) * _t
	var half := TAU / float(RAY_COUNT * 2) * 0.5
	var reach := RAY_RADIUS * rs
	for i in RAY_COUNT:
		var a := turn + TAU * float(i) / float(RAY_COUNT)
		var pts := PackedVector2Array([
			_center,
			_center + Vector2.from_angle(a - half) * reach,
			_center + Vector2.from_angle(a + half) * reach,
		])
		var c := Color(RED.r, RED.g, RED.b, 0.30 * pulse * calm_k) if i % 2 == 0 else Color(0.55, 0.02, 0.02, 0.22 * calm_k)
		draw_colored_polygon(pts, c)
	draw_circle(_center, 320.0 * rs, Color(RED.r, RED.g, RED.b, 0.14 * calm_k))
	draw_circle(_center, 180.0 * rs, Color(RED.r, RED.g, RED.b, 0.16 * pulse * calm_k))


func _draw_bar(y: float, from_left: bool) -> void:
	var x0 := BAR_MARGIN
	var x1 := size.x - BAR_MARGIN
	var full := x1 - x0
	if full <= 0.0:
		return
	var reach := full * (1.0 - pow(1.0 - _bars_in, 3.0))
	var rect := Rect2(x0, y - BAR_HEIGHT * 0.5, reach, BAR_HEIGHT)
	if not from_left:
		rect.position.x = x1 - reach
	draw_rect(rect, RED)
	var step := 0 if _calm else int(floor(_t / BULB_STEP_SEC))
	var dir := 1 if from_left else -1
	var count := int(floor(full / BULB_GAP))
	for i in count + 1:
		var bx := x0 + float(i) * BULB_GAP
		if bx < rect.position.x - 0.5 or bx > rect.end.x + 0.5:
			continue
		var lit := posmod(i - step * dir, 3) == 0
		var c := WHITE if lit else DIM_RED
		var top := Rect2(bx - BULB_SIZE * 0.5, y - BAR_HEIGHT * 0.5 - BULB_SIZE - 4.0, BULB_SIZE, BULB_SIZE)
		var bottom := Rect2(bx - BULB_SIZE * 0.5, y + BAR_HEIGHT * 0.5 + 4.0, BULB_SIZE, BULB_SIZE)
		draw_rect(top, c)
		draw_rect(bottom, c)


func _draw_front() -> void:
	if _front == null:
		return
	for s in _sparks:
		var life := float(s["life"])
		var a := clampf((life - float(s["age"])) / (life * 0.4), 0.0, 1.0)
		var c: Color = s["color"]
		c.a = a
		var sz := float(s["size"])
		_front.draw_rect(Rect2((s["pos"] as Vector2) - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), c)
	if _skulls.is_empty():
		return
	var tex := _skull_texture()
	var box := Rect2(-Vector2(SKULL_DRAW, SKULL_DRAW) * 0.5, Vector2(SKULL_DRAW, SKULL_DRAW))
	for k in _skulls:
		var fade_t := float(k["fade_t"])
		var a := 1.0 if fade_t < 0.0 else clampf(1.0 - fade_t / SKULL_FADE_SEC, 0.0, 1.0)
		_front.draw_set_transform(k["pos"], float(k["rot"]), Vector2.ONE)
		_front.draw_texture_rect(tex, box, false, Color(1.0, 1.0, 1.0, a))
	_front.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _ease_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


static func _skull_texture() -> Texture2D:
	if _skull_tex != null:
		return _skull_tex
	var image := SKULL_ART.get_image()
	if image == null:
		_skull_tex = SKULL_ART
		return _skull_tex
	image = image.duplicate() as Image
	if image.is_compressed():
		image.decompress()
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var px := image.get_pixel(x, y)
			if px.a < 0.05:
				continue
			if px.r > 0.9 and px.g > 0.9 and px.b > 0.9:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			elif px.r < 0.35 and px.g < 0.35 and px.b < 0.35:
				image.set_pixel(x, y, Color(1, 1, 1, px.a))
	_skull_tex = ImageTexture.create_from_image(image)
	return _skull_tex
