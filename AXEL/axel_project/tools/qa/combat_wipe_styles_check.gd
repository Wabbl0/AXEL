extends SceneTree

const WipeScript := preload("res://scenes/fx/combat_wipe_overlay.gd")
const GRID_X := 48
const GRID_Y := 32
const STYLE_NAMES := ["BARS", "BLINDS", "SLASH", "CENTER_SPLIT"]

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame

	var wipe: CanvasLayer = WipeScript.new()
	wipe.name = "WipeUnderTest"
	root.add_child(wipe)
	await process_frame

	var count: int = WipeScript.Style.size()
	if count != STYLE_NAMES.size():
		_fail("expected %d styles, got %d" % [STYLE_NAMES.size(), count])

	var pieces: Array[ColorRect] = wipe.call("get_pieces")
	var rows: int = WipeScript.BAR_COUNT
	for i in rows:
		if pieces[i * 2].color != pieces[(rows - 1 - i) * 2].color:
			_fail("row colors not mirrored top to bottom at row %d" % i)

	for style in count:
		var label: String = STYLE_NAMES[style]
		wipe.call("set_style", style)
		_check_coverage(wipe, label, 0.0, 0.0)
		_check_coverage(wipe, label, 1.0, 1.0)
		_check_coverage(wipe, label, 2.0, 0.0)
		_check_coverage(wipe, label, 0.5, -1.0)
		_check_coverage(wipe, label, 1.5, -1.0)
		wipe.call("_layout", 1.0)
		var min_h := INF
		var max_h := -INF
		for i in rows:
			var h: float = pieces[i * 2].size.y
			min_h = minf(min_h, h)
			max_h = maxf(max_h, h)
		if max_h - min_h > 1.0:
			_fail("%s: row heights differ by %.1f px" % [label, max_h - min_h])

	for style in [WipeScript.Style.BARS, WipeScript.Style.SLASH]:
		wipe.call("set_style", style)
		for p in [0.3, 1.0, 1.6]:
			wipe.call("_layout", p)
			var w: float = (wipe.get_node("WipeRoot/BarsRoot") as Control).size.x
			for i in range(0, rows - 1, 2):
				var red := pieces[i * 2]
				var black := pieces[(i + 1) * 2]
				var mirrored := w - black.position.x - black.size.x
				if absf(red.position.x - mirrored) > 0.5 or absf(red.size.x - black.size.x) > 0.5:
					_fail("%s p=%.1f: red row %d is not the mirror of black row %d" % [STYLE_NAMES[style], p, i, i + 1])

	wipe.call("set_style", WipeScript.Style.BARS)
	wipe.call("_layout", 1.5)
	var half := 1920.0 * 0.5
	for i in rows:
		var piece := pieces[i * 2]
		if i % 2 == 0 and piece.position.x < half - 0.5:
			_fail("BARS p=1.5: red row %d did not pass through to the right" % i)
		if i % 2 == 1 and piece.position.x + piece.size.x > half + 0.5:
			_fail("BARS p=1.5: black row %d did not pass through to the left" % i)

	var fx := root.get_node_or_null("AxelEventFx")
	if fx == null or not fx.has_method("pick_combat_wipe_style"):
		_fail("AxelEventFx.pick_combat_wipe_style missing")
	else:
		var seen := {}
		var last := -1
		for n in 50:
			var s := int(fx.call("pick_combat_wipe_style"))
			if s < 0 or s >= count:
				_fail("picked style out of range: %d" % s)
			if s == last:
				_fail("style %d picked twice in a row" % s)
			seen[s] = true
			last = s
		if seen.size() != count:
			_fail("only %d of %d styles picked in 50 tries" % [seen.size(), count])
		fx.call("set_next_wipe_style", WipeScript.Style.BLINDS)
		if int(fx.call("pick_combat_wipe_style")) != WipeScript.Style.BLINDS:
			_fail("set_next_wipe_style override ignored")

	wipe.queue_free()
	await process_frame

	if _failures.is_empty():
		print("combat_wipe_styles_check: OK")
		quit(0)
	else:
		for f in _failures:
			push_error("combat_wipe_styles_check: " + f)
		quit(1)


func _check_coverage(wipe: CanvasLayer, label: String, p: float, expected: float) -> void:
	wipe.call("_layout", p)
	var pieces: Array[ColorRect] = wipe.call("get_pieces")
	var inverses: Array[Transform2D] = []
	var rects: Array[Rect2] = []
	for piece in pieces:
		if not piece.visible:
			continue
		inverses.append(piece.get_global_transform().affine_inverse())
		rects.append(Rect2(Vector2.ZERO, piece.size))
	var covered := 0
	for gy in GRID_Y:
		for gx in GRID_X:
			var pt := Vector2((float(gx) + 0.5) * 1920.0 / GRID_X, (float(gy) + 0.5) * 1280.0 / GRID_Y)
			for k in rects.size():
				if rects[k].has_point(inverses[k] * pt):
					covered += 1
					break
	var ratio := float(covered) / float(GRID_X * GRID_Y)
	if expected < 0.0:
		if ratio <= 0.05 or ratio >= 0.95:
			_fail("%s p=%.1f: expected partial coverage, got %.2f" % [label, p, ratio])
	elif absf(ratio - expected) > 0.0001:
		_fail("%s p=%.1f: expected coverage %.0f%%, got %.1f%%" % [label, p, expected * 100.0, ratio * 100.0])
