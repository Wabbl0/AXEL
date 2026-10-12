extends Control

signal cue(cue_id: StringName)
signal impact(strength: int)

const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const SKULL_ART := preload("res://combat/art/grid_symbols/satanic_wild.png")
const RED := Color(0.86, 0.08, 0.08, 1.0)
const DIM_RED := Color(0.45, 0.03, 0.03, 1.0)
const WHITE := Color(1.0, 1.0, 1.0, 1.0)
const GREY := Color(0.62, 0.58, 0.54, 1.0)
const SPARK_COLORS: Array[Color] = [RED, WHITE, WHITE, GREY]
const SPARK_SIZES: Array[float] = [4.0, 6.0, 8.0]
const TOTAL_SEC := 2.15
const EXIT_AT := 1.75
const SCRIM_SNAP := 0.55
const SCRIM_PEAK := 0.8
const SCRIM_RISE_SEC := 0.3
const FLASH_SEC := 0.14
const SLAM_AT: Array[float] = [0.05, 0.22]
const SLAM_SEC := 0.16
const LAND_SQUASH_SEC := 0.15
const REEL_AT := 0.05
const REEL_GAP := 0.06
const REEL_SPIN_SEC := 0.18
const REEL_TICK_SEC := 0.035
const REEL_GLYPHS := "ABCDEFGHJKLMNPRSTUVWXYZ0123456789#$%&?"
const LOCK_PUNCH_SEC := 0.12
const HOLD_DELAY_SEC := 0.1
const ICON_AT := 0.4
const ICON_GAP := 0.15
const ICON_POP_SEC := 0.22
const RAYS_AT := 0.05
const RAYS_IN_SEC := 0.35
const RAY_COUNT := 12
const RAY_TURN_DEG := 18.0
const BARS_AT := 0.3
const BARS_IN_SEC := 0.3
const BAR_HEIGHT := 5.0
const BAR_MARGIN := 24.0
const BAR_MARGIN_WIDE := 140.0
const BULB_GAP := 28.0
const BULB_SIZE := 9.0
const BULB_STEP_SEC := 0.08
const CHASE_STEP_SEC := 0.09
const VOLLEY_FROM := 0.4
const VOLLEY_GAP := 0.3
const VOLLEY_SPARKS := 18
const RAIN_FROM := 0.3
const RAIN_GAP := 0.05
const RAIN_SIZE := 84.0
const SPARK_GRAVITY := 520.0
const SPARK_DRAG := 0.9
const SPARK_CAP := 500
const RING_LIFE := 0.5
const SHOCK_RADIUS := 700.0
const POP_LIFE := 0.9
const POP_NAME_SIZE := 56
const POP_TAG_SIZE := 48
const FONT_MAX := 150
const FONT_MIN := 40
const OUTLINE_PX := 10

static var _ink_cache: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _calm := false
var _kind: StringName = &""
var _active := false
var _t := 0.0
var _hold_at := 0.0
var _rect := Rect2()
var _center := Vector2.ZERO
var _font_size := 96
var _chars: Array[Dictionary] = []
var _icons: Array[Texture2D] = []
var _events: Array[Dictionary] = []
var _next_volley := 0.0
var _next_rain := 0.0
var _sparks: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _rain: Array[Dictionary] = []
var _pops: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_rng.randomize()
	set_process(true)


func is_playing() -> bool:
	return _active


func is_idle() -> bool:
	return not _active and _sparks.is_empty() and _rings.is_empty() and _rain.is_empty() and _pops.is_empty()


func play(kind: StringName, rect: Rect2, text: String, icons: Array[Texture2D], calm: bool) -> void:
	_kind = kind
	_calm = calm
	_rect = rect
	_center = rect.get_center()
	_icons.clear()
	for tex in icons:
		if tex != null:
			_icons.append(_ink_texture(tex))
	_t = 0.0
	_active = true
	_next_volley = VOLLEY_FROM
	_next_rain = RAIN_FROM
	_rain.clear()
	_layout_text(text)
	_schedule_events()
	queue_redraw()
	await _wait_total()
	_active = false
	_rain.clear()
	_events.clear()
	queue_redraw()


func power_pop(center: Vector2, radius: float, title: String, tag: String, loud: bool, calm: bool) -> void:
	if not loud:
		if not calm:
			_rings.append({"pos": center, "age": 0.0, "life": RING_LIFE, "max_r": maxf(radius * 1.6, 60.0), "color": WHITE, "width": 6.0})
		queue_redraw()
		return
	_pops.append({"pos": center, "r": maxf(radius, 24.0), "title": title.to_upper(), "tag": tag, "age": 0.0, "calm": calm})
	if not calm:
		_shockwave(center, 0.6)
		_burst(center, 20, 180.0, 520.0)
	queue_redraw()


func _wait_total() -> void:
	await CombatPace.await_seconds(TOTAL_SEC)
	var tree := get_tree()
	while tree != null and is_inside_tree() and _t < TOTAL_SEC:
		await tree.process_frame


func _layout_text(text: String) -> void:
	_chars.clear()
	var max_w := maxf(_rect.size.x * 0.9, 64.0)
	var fs := FONT_MAX
	while fs > FONT_MIN and FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
		fs -= 4
	_font_size = fs
	var total := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x := _center.x - total * 0.5
	var group := 0
	var index := 0
	for i in text.length():
		var ch := text.substr(i, 1)
		var w := FONT.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		if ch == " ":
			group = 1
		else:
			_chars.append({
				"ch": ch,
				"x": x + w * 0.5,
				"w": w,
				"group": group,
				"i": index,
				"lock": REEL_AT + float(index) * REEL_GAP + REEL_SPIN_SEC,
			})
			index += 1
		x += w
	if _is_reel():
		_hold_at = REEL_AT + float(maxi(index - 1, 0)) * REEL_GAP + REEL_SPIN_SEC + HOLD_DELAY_SEC
	else:
		_hold_at = SLAM_AT[1] + SLAM_SEC + HOLD_DELAY_SEC


func _schedule_events() -> void:
	_events.clear()
	if _is_reel():
		var last := _chars.size() - 1
		for c in _chars:
			var idx := int(c["i"])
			_events.append({"at": float(c["lock"]), "type": &"lock_final" if idx == last else &"lock", "x": float(c["x"]), "i": idx})
	else:
		_events.append({"at": SLAM_AT[0] + SLAM_SEC, "type": &"slam", "big": false})
		_events.append({"at": SLAM_AT[1] + SLAM_SEC, "type": &"slam", "big": true})
		for i in _icons.size():
			_events.append({"at": ICON_AT + float(i) * ICON_GAP + ICON_POP_SEC * 0.5, "type": &"icon", "i": i})


func _is_reel() -> bool:
	return _kind == &"free_spins"


func _process(delta: float) -> void:
	var tree := get_tree()
	if tree != null and tree.paused:
		return
	if is_idle():
		return
	var d := delta * CombatPace.multiplier()
	if _active:
		_t += d
		_fire_due()
		if not _calm and _t < EXIT_AT:
			_tick_volleys()
			if _is_reel():
				_tick_rain_spawn()
	_tick_sparks(d)
	_tick_rings(d)
	_tick_rain(d)
	_tick_pops(d)
	queue_redraw()


func _fire_due() -> void:
	var i := 0
	while i < _events.size():
		var e: Dictionary = _events[i]
		if float(e["at"]) <= _t:
			_events.remove_at(i)
			_fire_event(e)
		else:
			i += 1


func _fire_event(e: Dictionary) -> void:
	match e["type"]:
		&"slam":
			var big := bool(e["big"])
			var p := Vector2(_group_center_x(1 if big else 0), _center.y)
			if not _calm:
				_shockwave(p, 1.0 if big else 0.7)
				_burst(p, 28 if big else 20, 220.0, 620.0)
				impact.emit(3 if big else 2)
			if big:
				cue.emit(&"bonus_slam")
		&"lock":
			if not _calm:
				var p := Vector2(float(e["x"]), _center.y)
				_burst(p, 6, 120.0, 320.0)
				_rings.append({"pos": p, "age": 0.0, "life": 0.3, "max_r": _font_size * 0.8, "color": WHITE, "width": 4.0})
			if int(e["i"]) % 3 == 0:
				cue.emit(&"skull")
		&"lock_final":
			if not _calm:
				_shockwave(_center, 1.0)
				_burst(_center, 32, 240.0, 680.0)
				impact.emit(3)
			cue.emit(&"bonus_slam")
		&"icon":
			if not _calm:
				var p := _icon_center(int(e["i"]))
				_rings.append({"pos": p, "age": 0.0, "life": 0.4, "max_r": _icon_size() * 1.4, "color": WHITE, "width": 6.0})
				_burst(p, 12, 140.0, 380.0)


func _group_center_x(group: int) -> float:
	var sum := 0.0
	var n := 0
	for c in _chars:
		if int(c["group"]) == group:
			sum += float(c["x"])
			n += 1
	return sum / float(n) if n > 0 else _center.x


func _tick_volleys() -> void:
	if _t < _next_volley:
		return
	_next_volley += VOLLEY_GAP
	var area := _rect.grow(80.0)
	var view := _view()
	var p := Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))
	p = p.clamp(Vector2.ZERO, view)
	_burst(p, VOLLEY_SPARKS, 140.0, 420.0)
	_rings.append({"pos": p, "age": 0.0, "life": 0.35, "max_r": 100.0, "color": WHITE, "width": 4.0})


func _tick_rain_spawn() -> void:
	while _t >= _next_rain:
		_next_rain += RAIN_GAP
		var view := _view()
		var sz := RAIN_SIZE * _rng.randf_range(0.6, 1.1)
		_rain.append({
			"pos": Vector2(_rng.randf_range(0.0, view.x), -sz),
			"vel": Vector2(_rng.randf_range(-60.0, 60.0), _rng.randf_range(420.0, 760.0)),
			"rot": _rng.randf_range(0.0, TAU),
			"spin": _rng.randf_range(-5.0, 5.0),
			"size": sz,
		})


func _shockwave(p: Vector2, strength: float) -> void:
	_rings.append({"pos": p, "age": 0.0, "life": RING_LIFE, "max_r": SHOCK_RADIUS * strength, "color": WHITE, "width": 12.0})
	_rings.append({"pos": p, "age": -0.06, "life": RING_LIFE, "max_r": SHOCK_RADIUS * strength * 0.8, "color": RED, "width": 8.0})


func _burst(p: Vector2, count: int, speed_min: float, speed_max: float) -> void:
	for i in count:
		if _sparks.size() >= SPARK_CAP:
			return
		var angle := TAU * float(i) / float(maxi(count, 1)) + _rng.randf_range(-0.12, 0.12)
		_sparks.append({
			"pos": p,
			"vel": Vector2.from_angle(angle) * _rng.randf_range(speed_min, speed_max),
			"age": 0.0,
			"life": _rng.randf_range(0.6, 1.1),
			"color": SPARK_COLORS[_rng.randi() % SPARK_COLORS.size()],
			"size": SPARK_SIZES[_rng.randi() % SPARK_SIZES.size()],
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


func _tick_rain(d: float) -> void:
	var h := _view().y
	var i := _rain.size() - 1
	while i >= 0:
		var k: Dictionary = _rain[i]
		k["pos"] = (k["pos"] as Vector2) + (k["vel"] as Vector2) * d
		k["rot"] = float(k["rot"]) + float(k["spin"]) * d
		if (k["pos"] as Vector2).y > h + float(k["size"]):
			_rain.remove_at(i)
		i -= 1


func _tick_pops(d: float) -> void:
	var i := _pops.size() - 1
	while i >= 0:
		var p: Dictionary = _pops[i]
		p["age"] = float(p["age"]) + d
		if float(p["age"]) >= POP_LIFE:
			_pops.remove_at(i)
		i -= 1


func _view() -> Vector2:
	if size.x >= 64.0 and size.y >= 64.0:
		return size
	var vp := get_viewport()
	if vp != null:
		var vis := vp.get_visible_rect().size
		if vis.x >= 64.0 and vis.y >= 64.0:
			return vis
	return Vector2(1920, 1280)


func _exit_k() -> float:
	return clampf((_t - EXIT_AT) / (TOTAL_SEC - EXIT_AT), 0.0, 1.0)


func _zoom() -> float:
	var e := _exit_k()
	return 1.0 + 0.5 * e * e


func _icon_size() -> float:
	return clampf(float(_font_size), 56.0, 140.0)


func _bar_offset() -> float:
	return float(_font_size) * 0.55 + 18.0


func _icon_center(i: int) -> Vector2:
	var n := _icons.size()
	var s := _icon_size()
	var x := _center.x + (float(i) - float(n - 1) * 0.5) * s * 1.35
	var y := _center.y + _bar_offset() + BULB_SIZE + 24.0 + s * 0.5
	return Vector2(x, y)


func _draw() -> void:
	if _active:
		_draw_scrim()
		if not _calm:
			_draw_flash()
			_draw_rays()
			_draw_bars()
		_draw_rain()
	_draw_rings()
	if _active:
		_draw_text()
		_draw_icons()
	_draw_sparks()
	_draw_pops()


func _draw_scrim() -> void:
	var rise := clampf(_t / SCRIM_RISE_SEC, 0.0, 1.0)
	var a := SCRIM_PEAK * rise if _calm else lerpf(SCRIM_SNAP, SCRIM_PEAK, rise)
	var e := _exit_k()
	a *= 1.0 - e * e * (3.0 - 2.0 * e)
	if a <= 0.001:
		return
	draw_rect(Rect2(Vector2.ZERO, _view()), Color(0.0, 0.0, 0.0, a))


func _draw_flash() -> void:
	var k := 1.0 - _t / FLASH_SEC
	if k <= 0.0:
		return
	var c := WHITE if _is_reel() else RED
	c.a = 0.35 * k
	draw_rect(Rect2(Vector2.ZERO, _view()), c)


func _draw_rays() -> void:
	var k := clampf((_t - RAYS_AT) / RAYS_IN_SEC, 0.0, 1.0)
	if k <= 0.0:
		return
	var e := _exit_k()
	var rs := _ease_back(k) * (1.0 - e * e)
	if rs <= 0.001:
		return
	var span := _view() if _is_reel() else _rect.size
	var reach := maxf(span.x, span.y) * 0.75 * rs
	var turn := deg_to_rad(RAY_TURN_DEG) * _t
	var half := TAU / float(RAY_COUNT * 2) * 0.5
	var pulse := 0.85 + 0.15 * sin(_t * 7.0)
	for i in RAY_COUNT:
		var a := turn + TAU * float(i) / float(RAY_COUNT)
		var pts := PackedVector2Array([
			_center,
			_center + Vector2.from_angle(a - half) * reach,
			_center + Vector2.from_angle(a + half) * reach,
		])
		var c := Color(RED.r, RED.g, RED.b, 0.28 * pulse) if i % 2 == 0 else Color(0.55, 0.02, 0.02, 0.2)
		draw_colored_polygon(pts, c)
	draw_circle(_center, reach * 0.3, Color(RED.r, RED.g, RED.b, 0.12 * pulse))


func _draw_bars() -> void:
	var k := clampf((_t - BARS_AT) / BARS_IN_SEC, 0.0, 1.0)
	if k <= 0.0:
		return
	var grow := 1.0 - pow(1.0 - k, 3.0)
	var alpha := 1.0 - _exit_k()
	if alpha <= 0.001:
		return
	var margin := BAR_MARGIN_WIDE if _is_reel() else BAR_MARGIN
	var x0 := maxf(_rect.position.x, 0.0) + margin
	var x1 := minf(_rect.end.x, _view().x) - margin
	var off := _bar_offset()
	_draw_bar(_center.y - off, x0, x1, grow, true, alpha)
	_draw_bar(_center.y + off, x0, x1, grow, false, alpha)


func _draw_bar(y: float, x0: float, x1: float, grow: float, from_left: bool, alpha: float) -> void:
	var full := x1 - x0
	if full <= 0.0:
		return
	var reach := full * grow
	var rect := Rect2(x0, y - BAR_HEIGHT * 0.5, reach, BAR_HEIGHT)
	if not from_left:
		rect.position.x = x1 - reach
	draw_rect(rect, Color(RED.r, RED.g, RED.b, alpha))
	var step_sec := BULB_STEP_SEC * (0.5 if _is_reel() else 1.0)
	var step := int(floor(_t / step_sec))
	var dir := 1 if from_left else -1
	var count := int(floor(full / BULB_GAP))
	for i in count + 1:
		var bx := x0 + float(i) * BULB_GAP
		if bx < rect.position.x - 0.5 or bx > rect.end.x + 0.5:
			continue
		var lit := posmod(i - step * dir, 3) == 0
		var c := WHITE if lit else DIM_RED
		c.a = alpha
		draw_rect(Rect2(bx - BULB_SIZE * 0.5, y - BAR_HEIGHT * 0.5 - BULB_SIZE - 4.0, BULB_SIZE, BULB_SIZE), c)
		draw_rect(Rect2(bx - BULB_SIZE * 0.5, y + BAR_HEIGHT * 0.5 + 4.0, BULB_SIZE, BULB_SIZE), c)


func _draw_rain() -> void:
	if _rain.is_empty():
		return
	var tex: Texture2D = SKULL_ART
	var alpha := 1.0 - _exit_k()
	for k in _rain:
		var sz := float(k["size"])
		draw_set_transform(k["pos"], float(k["rot"]), Vector2.ONE)
		draw_texture_rect(tex, Rect2(-Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, Color(1.0, 1.0, 1.0, 0.85 * alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_rings() -> void:
	for r in _rings:
		var age := float(r["age"])
		if age < 0.0:
			continue
		var k := clampf(age / float(r["life"]), 0.0, 1.0)
		var radius := float(r["max_r"]) * (1.0 - pow(1.0 - k, 3.0))
		var c: Color = r["color"]
		c.a = 1.0 - k
		draw_arc(r["pos"], maxf(radius, 1.0), 0.0, TAU, 96, c, float(r["width"]) * (1.0 - k * 0.6) + 1.0)


func _draw_text() -> void:
	var fade := 1.0 - _exit_k()
	if fade <= 0.001:
		return
	var zoom := _zoom()
	var baseline := (FONT.get_ascent(_font_size) - FONT.get_descent(_font_size)) * 0.5
	var held := not _calm and _t >= _hold_at
	var chase := int(floor(_t / CHASE_STEP_SEC))
	var jitter := 2.0 + float(posmod(int(_t * 24.0), 3))
	for c in _chars:
		var pose := _reel_pose(c) if _is_reel() else _slam_pose(c)
		var alpha := float(pose["alpha"]) * fade
		if alpha <= 0.001:
			continue
		var i := int(c["i"])
		var offset: Vector2 = pose["offset"]
		var color: Color = pose["color"]
		if held:
			offset.y += sin(_t * 8.0 + float(i) * 0.6) * float(_font_size) * 0.05
			color = WHITE if posmod(i + chase, 2) == 0 else RED
		elif _calm:
			color = WHITE if i % 2 == 0 else RED
		var pos := Vector2(float(c["x"]), _center.y) + offset
		pos = _center + (pos - _center) * zoom
		var s := float(pose["scale"]) * zoom
		var glyph := String(pose["glyph"])
		var origin := Vector2(-float(c["w"]) * 0.5, baseline)
		draw_set_transform(pos, 0.0, Vector2(s, s))
		draw_string_outline(FONT, origin, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, OUTLINE_PX, Color(0.0, 0.0, 0.0, alpha))
		if held:
			draw_string(FONT, origin + Vector2(-jitter, 0.0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, Color(DIM_RED.r, DIM_RED.g, DIM_RED.b, alpha * 0.8))
			draw_string(FONT, origin + Vector2(jitter, 0.0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, Color(GREY.r, GREY.g, GREY.b, alpha * 0.4))
		color.a = alpha
		draw_string(FONT, origin, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _slam_pose(c: Dictionary) -> Dictionary:
	var group := int(c["group"])
	var start := SLAM_AT[mini(group, SLAM_AT.size() - 1)]
	var k := (_t - start) / SLAM_SEC
	if k <= 0.0:
		return {"alpha": 0.0, "scale": 1.0, "offset": Vector2.ZERO, "color": WHITE, "glyph": c["ch"]}
	k = minf(k, 1.0)
	var inv := 1.0 - k
	var grow := 1.0 + 0.25 * inv * inv if _calm else 1.0 + 2.0 * inv * inv * inv
	var offset := Vector2.ZERO
	if group == 1 and not _calm:
		offset.x = inv * inv * inv * _rect.size.x * 0.35
	var land := (_t - start - SLAM_SEC) / LAND_SQUASH_SEC
	if land > 0.0 and land < 1.0 and not _calm:
		grow *= 1.0 - 0.1 * sin(land * PI)
	return {"alpha": clampf(k * 3.0, 0.0, 1.0), "scale": grow, "offset": offset, "color": WHITE, "glyph": c["ch"]}


func _reel_pose(c: Dictionary) -> Dictionary:
	if _t < REEL_AT:
		return {"alpha": 0.0, "scale": 1.0, "offset": Vector2.ZERO, "color": WHITE, "glyph": c["ch"]}
	if _calm:
		return {"alpha": clampf((_t - REEL_AT) / 0.2, 0.0, 1.0), "scale": 1.0, "offset": Vector2.ZERO, "color": WHITE, "glyph": c["ch"]}
	var lock := float(c["lock"])
	if _t < lock:
		var tick := int(floor(_t / REEL_TICK_SEC))
		var idx := posmod(hash(int(c["i"]) * 977 + tick), REEL_GLYPHS.length())
		var roll := fposmod(_t / REEL_TICK_SEC, 1.0) - 0.5
		return {
			"alpha": 0.85,
			"scale": 1.0,
			"offset": Vector2(0.0, roll * float(_font_size) * 0.35),
			"color": GREY,
			"glyph": REEL_GLYPHS.substr(idx, 1),
		}
	var p := clampf((_t - lock) / LOCK_PUNCH_SEC, 0.0, 1.0)
	return {"alpha": 1.0, "scale": 1.0 + 0.35 * (1.0 - p) * (1.0 - p), "offset": Vector2.ZERO, "color": WHITE, "glyph": c["ch"]}


func _draw_icons() -> void:
	if _icons.is_empty():
		return
	var fade := 1.0 - _exit_k()
	if fade <= 0.001:
		return
	var zoom := _zoom()
	var base := _icon_size()
	for i in _icons.size():
		var k := (_t - (ICON_AT + float(i) * ICON_GAP)) / ICON_POP_SEC
		if k <= 0.0:
			continue
		k = minf(k, 1.0)
		var s := (1.0 - (1.0 - k) * (1.0 - k)) if _calm else _ease_back(k)
		var p := _icon_center(i)
		if not _calm and k >= 1.0:
			p.y += sin(_t * 6.0 + float(i) * 1.3) * 4.0
		p = _center + (p - _center) * zoom
		var sz := base * s * zoom
		var alpha := minf(k * 2.0, 1.0) * fade
		draw_circle(p, sz * 0.6, Color(RED.r, RED.g, RED.b, 0.25 * alpha))
		draw_texture_rect(_icons[i], Rect2(p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, Color(1.0, 1.0, 1.0, alpha))


func _draw_sparks() -> void:
	for s in _sparks:
		var life := float(s["life"])
		var a := clampf((life - float(s["age"])) / (life * 0.4), 0.0, 1.0)
		var c: Color = s["color"]
		c.a = a
		var sz := float(s["size"])
		draw_rect(Rect2((s["pos"] as Vector2) - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), c)


func _draw_pops() -> void:
	for p in _pops:
		var age := float(p["age"])
		var k := age / POP_LIFE
		var alpha := clampf(age / 0.08, 0.0, 1.0) * clampf((1.0 - k) / 0.4, 0.0, 1.0)
		if alpha <= 0.001:
			continue
		var punch := 1.0 if bool(p["calm"]) else 1.0 + 0.3 * pow(1.0 - clampf(age / 0.15, 0.0, 1.0), 2.0)
		var center: Vector2 = p["pos"]
		var r := float(p["r"])
		var title := String(p["title"])
		var tag := String(p["tag"])
		_draw_centered(title, POP_NAME_SIZE, center + Vector2(0.0, r + 14.0 + FONT.get_ascent(POP_NAME_SIZE) * 0.5), punch, Color(RED.r, RED.g, RED.b, alpha), alpha)
		if not tag.is_empty():
			_draw_centered(tag, POP_TAG_SIZE, center - Vector2(0.0, r + 14.0 + FONT.get_ascent(POP_TAG_SIZE) * 0.5), punch, Color(1.0, 1.0, 1.0, alpha), alpha)


func _draw_centered(text: String, font_size: int, at: Vector2, mult: float, color: Color, alpha: float) -> void:
	var w := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := (FONT.get_ascent(font_size) - FONT.get_descent(font_size)) * 0.5
	var origin := Vector2(-w * 0.5, baseline)
	draw_set_transform(at, 0.0, Vector2(mult, mult))
	draw_string_outline(FONT, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, Color(0.0, 0.0, 0.0, alpha))
	draw_string(FONT, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _ease_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


static func _ink_texture(source: Texture2D) -> Texture2D:
	if source == null:
		return null
	if _ink_cache.has(source):
		return _ink_cache[source]
	var image := source.get_image()
	if image == null:
		_ink_cache[source] = source
		return source
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
	var tex := ImageTexture.create_from_image(image)
	_ink_cache[source] = tex
	return tex
