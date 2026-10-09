extends Node

const GRAVITY_PX := 2200.0
const MAX_AGE := 4.0
const OFF_MARGIN_PX := 40.0
const CRACK_COLOR := Color(0.30, 0.0, 0.0, 1.0)
const CRACK_WIDTH_PX := 3.0
const JITTER_PX := 4.0

var _items: Array[Dictionary] = []
var _view := Vector2(1920, 1280)
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_process(true)


func set_view(view: Vector2) -> void:
	_view = view


func is_done() -> bool:
	return _items.is_empty()


func live_count() -> int:
	return _items.size()


static func art_of(piece: Node) -> TextureRect:
	if piece == null:
		return null
	if piece is TextureRect and (piece as TextureRect).texture != null:
		return piece as TextureRect
	for child in piece.find_children("SkullStage*", "TextureRect", true, false):
		var stage := child as TextureRect
		if stage.is_visible_in_tree() and stage.texture != null:
			return stage
	if piece.has_method("get_art"):
		var art := piece.call("get_art") as TextureRect
		if art != null and art.texture != null and art.is_visible_in_tree():
			return art
	return null


static func draw_rect_of(art: TextureRect) -> Rect2:
	var full := Rect2(Vector2.ZERO, art.size)
	if art.texture == null:
		return full
	var tex := art.texture.get_size()
	if tex.x <= 0.0 or tex.y <= 0.0 or art.size.x <= 0.0 or art.size.y <= 0.0:
		return full
	match art.stretch_mode:
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED, TextureRect.STRETCH_KEEP_ASPECT:
			var s := minf(art.size.x / tex.x, art.size.y / tex.y)
			var drawn := tex * s
			var pos := Vector2.ZERO
			if art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
				pos = (art.size - drawn) * 0.5
			return Rect2(pos, drawn)
		TextureRect.STRETCH_KEEP_CENTERED:
			return Rect2((art.size - tex) * 0.5, tex)
		TextureRect.STRETCH_KEEP:
			return Rect2(Vector2.ZERO, tex)
	return full


static func shard_polygons(rect: Rect2, impact: Vector2, spokes: int, seed_value: int) -> Array[PackedVector2Array]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var p := impact.clamp(rect.position + rect.size * 0.1, rect.end - rect.size * 0.1)
	var border: Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]
	var extra := maxi(spokes - 4, 0)
	for i in extra:
		var t := (float(i) + rng.randf_range(0.25, 0.75)) / float(extra)
		border.append(_perimeter_point(rect, t))
	border.sort_custom(func(a: Vector2, b: Vector2) -> bool: return (a - p).angle() < (b - p).angle())
	var inner: Array[Vector2] = []
	for b in border:
		inner.append(p.lerp(b, rng.randf_range(0.35, 0.6)))
	var out: Array[PackedVector2Array] = []
	var n := border.size()
	for i in n:
		var j := (i + 1) % n
		out.append(PackedVector2Array([p, inner[i], inner[j]]))
		out.append(PackedVector2Array([inner[i], border[i], border[j], inner[j]]))
	return out


static func polygon_area(poly: PackedVector2Array) -> float:
	var sum := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		sum += a.x * b.y - b.x * a.y
	return absf(sum) * 0.5


static func _perimeter_point(rect: Rect2, t: float) -> Vector2:
	var w := rect.size.x
	var h := rect.size.y
	var d := fposmod(t, 1.0) * 2.0 * (w + h)
	if d < w:
		return rect.position + Vector2(d, 0.0)
	d -= w
	if d < h:
		return Vector2(rect.end.x, rect.position.y + d)
	d -= h
	if d < w:
		return Vector2(rect.end.x - d, rect.end.y)
	d -= w
	return Vector2(rect.position.x, rect.end.y - d)


static func _screen_scale(item: CanvasItem) -> float:
	if item == null or not item.is_inside_tree():
		return 1.0
	var s := item.get_global_transform_with_canvas().get_scale()
	return maxf(absf(s.x), 0.01)


func break_piece(piece: Control, host: Control, seed_value: int, spokes: int, crack_sec: float, shake_scale: float) -> void:
	if piece == null or not is_instance_valid(piece):
		return
	var art := art_of(piece)
	if art == null or host == null or art.texture is AtlasTexture:
		drop(piece, 0.0, seed_value)
		return
	var rect := draw_rect_of(art)
	if rect.size.x < 4.0 or rect.size.y < 4.0:
		drop(piece, 0.0, seed_value)
		return
	_rng.seed = seed_value
	var impact := rect.get_center() + Vector2(
		_rng.randf_range(-0.12, 0.12) * rect.size.x,
		_rng.randf_range(-0.12, 0.12) * rect.size.y
	)
	var polys := shard_polygons(rect, impact, spokes, seed_value)
	var unit := _screen_scale(host)
	if crack_sec > 0.0:
		var to_host_crack := host.get_global_transform().affine_inverse() * art.get_global_transform()
		await _crack(piece, host, to_host_crack, polys, unit, crack_sec, shake_scale)
		if not is_instance_valid(piece) or not is_instance_valid(art) or not is_instance_valid(host):
			return
	var to_host := host.get_global_transform().affine_inverse() * art.get_global_transform()
	_spawn_shards(art, host, to_host, rect, polys, to_host * polys[0][0], unit, seed_value)
	piece.visible = false


func drop(node: CanvasItem, delay: float, seed_value: int) -> void:
	if node == null or not is_instance_valid(node):
		return
	_rng.seed = seed_value
	var unit := _screen_scale(node.get_parent() as CanvasItem)
	var radius := 0.0
	if node is Control:
		var c := node as Control
		c.pivot_offset = c.size * 0.5
		radius = c.size.length() * _screen_scale(c)
	var vel := Vector2(_rng.randf_range(-60.0, 60.0), -_rng.randf_range(60.0, 180.0)) / unit
	_items.append({
		"node": node,
		"vel": vel,
		"spin": _rng.randf_range(-2.5, 2.5),
		"delay": maxf(delay, 0.0),
		"age": 0.0,
		"gravity": GRAVITY_PX / unit,
		"radius": radius,
		"owned": false,
	})


func _crack(piece: Control, host: Control, to_host: Transform2D, polys: Array[PackedVector2Array], unit: float, crack_sec: float, shake_scale: float) -> void:
	var center: Vector2 = to_host * polys[0][0]
	var spokes: Array[Line2D] = []
	var rings: Array[Line2D] = []
	var ends: Array[Vector2] = []
	var ring_pts: Array[PackedVector2Array] = []
	for i in range(1, polys.size(), 2):
		var quad: PackedVector2Array = polys[i]
		ends.append(to_host * quad[1])
		ring_pts.append(PackedVector2Array([to_host * quad[0], to_host * quad[3]]))
		spokes.append(_crack_line(host, unit, center))
		rings.append(_crack_line(host, unit, to_host * quad[0]))
	var grow := CombatPace.bind(create_tween())
	grow.tween_method(
		func(t: float) -> void: _grow_cracks(spokes, rings, center, ends, ring_pts, t),
		0.0, 1.0, crack_sec
	)
	var base := piece.position
	var amp := JITTER_PX * clampf(shake_scale, 0.0, 1.0) / _screen_scale(piece.get_parent() as CanvasItem)
	if amp > 0.01:
		var jitter := CombatPace.bind(create_tween())
		var step := crack_sec / 5.0
		for k in 4:
			var kick := Vector2(amp if k % 2 == 0 else -amp, amp * 0.5 if k % 2 == 0 else -amp * 0.5)
			jitter.tween_property(piece, "position", base + kick, step)
		jitter.tween_property(piece, "position", base, step)
	await grow.finished
	if is_instance_valid(piece):
		piece.position = base
	for line in spokes + rings:
		if is_instance_valid(line):
			line.queue_free()


func _crack_line(host: Control, unit: float, start: Vector2) -> Line2D:
	var line := Line2D.new()
	line.width = CRACK_WIDTH_PX / unit
	line.default_color = CRACK_COLOR
	line.antialiased = false
	line.points = PackedVector2Array([start, start])
	host.add_child(line)
	return line


func _grow_cracks(spokes: Array[Line2D], rings: Array[Line2D], center: Vector2, ends: Array[Vector2], ring_pts: Array[PackedVector2Array], t: float) -> void:
	var spoke_t := clampf(t * 1.6, 0.0, 1.0)
	var ring_t := clampf((t - 0.5) * 2.0, 0.0, 1.0)
	for i in spokes.size():
		if is_instance_valid(spokes[i]):
			spokes[i].points = PackedVector2Array([center, center.lerp(ends[i], spoke_t)])
		if is_instance_valid(rings[i]):
			var a := ring_pts[i][0]
			rings[i].points = PackedVector2Array([a, a.lerp(ring_pts[i][1], ring_t)])


func _spawn_shards(art: TextureRect, host: Control, to_host: Transform2D, rect: Rect2, polys: Array[PackedVector2Array], impact_host: Vector2, unit: float, seed_value: int) -> void:
	var tex_size := art.texture.get_size()
	var tint := _tint_of(art, host)
	var reach := maxf(to_host.basis_xform(rect.size).length(), 1.0)
	_rng.seed = seed_value + 7
	for poly in polys:
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		var c := Vector2.ZERO
		for v in poly:
			var hv := to_host * v
			pts.append(hv)
			c += hv
			uvs.append((v - rect.position) / rect.size * tex_size)
		c /= float(poly.size())
		var radius := 0.0
		for k in pts.size():
			pts[k] -= c
			radius = maxf(radius, pts[k].length())
		var shard := Polygon2D.new()
		shard.texture = art.texture
		shard.polygon = pts
		shard.uv = uvs
		shard.antialiased = false
		shard.color = tint
		if art.texture_filter != CanvasItem.TEXTURE_FILTER_PARENT_NODE:
			shard.texture_filter = art.texture_filter
		shard.position = c
		host.add_child(shard)
		var away := c - impact_host
		var dir := away.normalized() if away.length() > 0.001 else Vector2.UP
		var vel := dir * _rng.randf_range(60.0, 200.0) + Vector2(_rng.randf_range(-30.0, 30.0), -_rng.randf_range(120.0, 300.0))
		_items.append({
			"node": shard,
			"vel": vel / unit,
			"spin": _rng.randf_range(-3.5, 3.5),
			"delay": away.length() / reach * 0.06,
			"age": 0.0,
			"gravity": GRAVITY_PX / unit,
			"radius": radius * unit,
			"owned": true,
		})


func _tint_of(art: TextureRect, host: Control) -> Color:
	var tint := art.self_modulate
	var stop := host.get_parent()
	var node: Node = art
	while node != null and node != stop:
		if node is CanvasItem:
			tint *= (node as CanvasItem).modulate
		node = node.get_parent()
	return tint


func _process(delta: float) -> void:
	delta *= CombatPace.multiplier()
	if delta <= 0.0:
		return
	var i := _items.size() - 1
	while i >= 0:
		var item: Dictionary = _items[i]
		var node := item["node"] as CanvasItem
		if node == null or not is_instance_valid(node):
			_items.remove_at(i)
			i -= 1
			continue
		var age := float(item["age"]) + delta
		item["age"] = age
		if age < float(item["delay"]):
			i -= 1
			continue
		var vel: Vector2 = item["vel"]
		vel.y += float(item["gravity"]) * delta
		item["vel"] = vel
		var turn := float(item["spin"]) * delta
		if node is Node2D:
			(node as Node2D).position += vel * delta
			(node as Node2D).rotation += turn
		elif node is Control:
			(node as Control).position += vel * delta
			(node as Control).rotation += turn
		var y := node.get_global_transform_with_canvas().origin.y
		if y - float(item["radius"]) > _view.y + OFF_MARGIN_PX or age > MAX_AGE:
			_finish(item)
			_items.remove_at(i)
		i -= 1


func _finish(item: Dictionary) -> void:
	var node := item["node"] as CanvasItem
	if node == null or not is_instance_valid(node):
		return
	if bool(item.get("owned", false)):
		node.queue_free()
	else:
		node.visible = false


func _exit_tree() -> void:
	for item in _items:
		if bool(item.get("owned", false)):
			var node := item.get("node") as Node
			if node != null and is_instance_valid(node):
				node.queue_free()
	_items.clear()
