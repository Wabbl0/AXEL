extends SceneTree

const FLAME_BURST := preload("res://combat/scripts/flame_burst.gd")
const JACKPOT := preload("res://scenes/fx/round_jackpot_fx.gd")
const BONUS_INTRO := preload("res://combat/scripts/bonus_intro_fx.gd")
const SHEETS := [
	"res://assets/sprites/combat/flame_1_48x48.png",
]
const MAX_SAT := 0.15
const STEP := 1.0 / 60.0

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	_check_colors("flame_burst FLAME_COLORS", FLAME_BURST.FLAME_COLORS)
	_check_colors("flame_burst burn", [FLAME_BURST.BURN_RED, FLAME_BURST.BURN_EMBER])
	_check_colors("round_jackpot_fx SPARK_COLORS", JACKPOT.SPARK_COLORS)
	_check_colors("bonus_intro_fx SPARK_COLORS", BONUS_INTRO.SPARK_COLORS)
	for path in SHEETS:
		_check_sheet(path)
	_check_burn_fades()
	for h in [1280, 1080]:
		await _check_skull_floor(Vector2i(1920, h))
	if _failures.is_empty():
		print("FX palette check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("fx_palette_check: %s" % msg)
	quit(1)


func _palette_ok(c: Color) -> bool:
	if c.s <= MAX_SAT:
		return true
	return c.h <= 0.03 or c.h >= 0.95


func _check_colors(where: String, colors: Array) -> void:
	for c in colors:
		if not _palette_ok(c as Color):
			_fail("%s has an off-palette color %s" % [where, str(c)])


func _check_sheet(path: String) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		_fail("missing sheet %s" % path)
		return
	var image := tex.get_image()
	if image.is_compressed():
		image.decompress()
	var grey: Image = FLAME_BURST.palette_grey(image)
	for y in range(0, grey.get_height(), 2):
		for x in range(0, grey.get_width(), 2):
			var px := grey.get_pixel(x, y)
			if px.a > 0.1 and px.s > 0.01:
				_fail("%s still has color after palette_grey at %d,%d" % [path, x, y])
				return
	for tint in FLAME_BURST.FLAME_COLORS:
		var probe := Color(0.8, 0.8, 0.8, 1.0) * (tint as Color)
		if not _palette_ok(probe):
			_fail("%s tinted by %s leaves the palette" % [path, str(tint)])


func _check_burn_fades() -> void:
	var last := 2.0
	for i in 11:
		var look: Array = FLAME_BURST.spark_look(Color.WHITE, float(i) / 10.0, 1.0, 0.0)
		var c: Color = look[0]
		if c.a > last + 0.001:
			_fail("spark alpha should only fall while it burns out")
		last = c.a
		if not _palette_ok(Color(c.r, c.g, c.b, 1.0)):
			_fail("burning spark leaves the palette at t=%.1f" % (float(i) / 10.0))
	if last > 0.01:
		_fail("spark should be fully faded at the end of its life, got %.3f" % last)


func _check_skull_floor(window: Vector2i) -> void:
	root.size = window
	await process_frame
	var fx: Control = JACKPOT.new()
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(fx)
	await process_frame
	fx.size = Vector2(window)
	var skulls: Array = fx.get("_skulls")
	skulls.append({
		"pos": Vector2(960.0, float(window.y) - 300.0),
		"vel": Vector2(0.0, 200.0),
		"rot": 0.0,
		"spin": 0.0,
		"age": 0.0,
		"falling": false,
		"bounces": 0,
		"max_bounces": 2,
	})
	var lowest := -INF
	var jump := 0.0
	var before_fall := 0.0
	var was_falling := false
	for i in 1200:
		if skulls.is_empty():
			break
		var k: Dictionary = skulls[0]
		var vy_before := (k["vel"] as Vector2).y
		fx.call("_tick_skulls", STEP)
		if skulls.is_empty():
			break
		k = skulls[0]
		if not bool(k["falling"]):
			var bottom := (k["pos"] as Vector2).y + float(fx.call("_skull_low", float(k["rot"])))
			lowest = maxf(lowest, bottom)
		elif not was_falling:
			was_falling = true
			before_fall = vy_before
			jump = (k["vel"] as Vector2).y - vy_before
	if absf(lowest - float(window.y)) > 2.0:
		_fail("%dx%d: skulls bounce at %.1f, window bottom is %d" % [window.x, window.y, lowest, window.y])
	if not was_falling:
		_fail("%dx%d: skull never started falling off" % [window.x, window.y])
	elif jump > 40.0:
		_fail("%dx%d: falling off jumped speed by %.0f (from %.0f)" % [window.x, window.y, jump, before_fall])
	fx.queue_free()
	await process_frame
