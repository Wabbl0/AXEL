extends CanvasLayer

enum Style { BARS, BLINDS, SLASH, CENTER_SPLIT }

const BAR_COUNT := 13
const CLOSE_SEC := 0.34
const OPEN_SEC := 0.28
const MAX_STEP_SEC := 1.0 / 30.0
const FLASH_SEC := 0.05
const FLASH_COUNT := 3
const SLASH_DEG := -20.0
const BAR_RED := Color(0.62, 0.02, 0.02, 1.0)
const BAR_BLACK := Color(0.02, 0.02, 0.02, 1.0)

var _root: Control
var _bars_root: Control
var _flash: ColorRect
var _pieces: Array[ColorRect] = []
var _style: int = Style.BARS
var _progress := 0.0
var _covered := false
var _busy := false


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_set_hidden()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func is_covered() -> bool:
	return _covered


func get_style() -> int:
	return _style


func set_style(style: int) -> void:
	_style = clampi(style, 0, Style.size() - 1)


func get_pieces() -> Array[ColorRect]:
	return _pieces


func _build() -> void:
	_root = Control.new()
	_root.name = "WipeRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_bars_root = Control.new()
	_bars_root.name = "BarsRoot"
	_bars_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bars_root)
	for i in BAR_COUNT:
		for k in 2:
			var piece := ColorRect.new()
			piece.name = "Bar%d_%d" % [i, k]
			piece.color = BAR_RED if i % 2 == 0 else BAR_BLACK
			piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_bars_root.add_child(piece)
			_pieces.append(piece)
	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)


func _viewport_size() -> Vector2:
	var vp := get_viewport()
	return Vector2(vp.get_visible_rect().size) if vp != null else Vector2(1920, 1280)


func _on_viewport_size_changed() -> void:
	_layout(_progress)


func _layout_frame() -> Vector2:
	var size := _viewport_size()
	if _style == Style.SLASH:
		var d := ceilf(sqrt(size.x * size.x + size.y * size.y))
		_bars_root.rotation = 0.0
		_bars_root.size = Vector2(d, d)
		_bars_root.position = (size - Vector2(d, d)) * 0.5
		_bars_root.pivot_offset = Vector2(d, d) * 0.5
		_bars_root.rotation = deg_to_rad(SLASH_DEG)
	else:
		_bars_root.rotation = 0.0
		_bars_root.pivot_offset = Vector2.ZERO
		_bars_root.position = Vector2.ZERO
		_bars_root.size = size
	return _bars_root.size


func _layout(progress: float) -> void:
	_progress = clampf(progress, 0.0, 2.0)
	var area := _layout_frame()
	var w := area.x
	var row_h := area.y / float(BAR_COUNT)
	var c := clampf(_progress, 0.0, 1.0)
	var q := clampf(_progress - 1.0, 0.0, 1.0)
	var opening := _progress > 1.0
	for i in BAR_COUNT:
		var a := _pieces[i * 2]
		var b := _pieces[i * 2 + 1]
		var y0 := roundf(float(i) * row_h)
		var y1 := roundf(float(i + 1) * row_h)
		var red := i % 2 == 0
		match _style:
			Style.BLINDS:
				var s := (1.0 - q) if opening else c
				var mid := (y0 + y1) * 0.5
				var h := (y1 - y0) * s
				_place(a, 0.0, mid - h * 0.5, w, mid + h * 0.5)
				_place(b, 0.0, 0.0, 0.0, 0.0)
			Style.CENTER_SPLIT:
				var half := w * 0.5
				if opening:
					_place(a, 0.0, y0, half * (1.0 - q), y1)
					_place(b, half + half * q, y0, w, y1)
				else:
					_place(a, half - half * c, y0, half, y1)
					_place(b, half, y0, half + half * c, y1)
			_:
				if red:
					if opening:
						_place(a, w * q, y0, w, y1)
					else:
						_place(a, 0.0, y0, w * c, y1)
				else:
					if opening:
						_place(a, 0.0, y0, w - w * q, y1)
					else:
						_place(a, w - w * c, y0, w, y1)
				_place(b, 0.0, 0.0, 0.0, 0.0)


func _place(piece: ColorRect, x0: float, y0: float, x1: float, y1: float) -> void:
	var size := Vector2(maxf(x1 - x0, 0.0), maxf(y1 - y0, 0.0))
	piece.visible = size.x > 0.0 and size.y > 0.0
	piece.position = Vector2(x0, y0)
	piece.size = size


func _set_hidden() -> void:
	_covered = false
	_root.visible = false
	_layout(0.0)
	if _flash != null:
		_flash.color.a = 0.0


func close_wipe(style: int = Style.BARS) -> void:
	if _busy:
		return
	_busy = true
	set_style(style)
	_layout(0.0)
	_root.visible = true
	if not _reduce_flashing():
		await _play_flashes()
	await _tween_progress(0.0, 1.0, CLOSE_SEC)
	_covered = true
	_busy = false


func open_wipe() -> void:
	if not _covered and not _root.visible:
		return
	_busy = true
	_root.visible = true
	await _tween_progress(1.0, 2.0, OPEN_SEC)
	_set_hidden()
	_busy = false


func clear_now() -> void:
	_busy = false
	_set_hidden()


func _play_flashes() -> void:
	for i in FLASH_COUNT:
		_flash.color = Color(0.75, 0.0, 0.0, 0.55) if i % 2 == 0 else Color(0, 0, 0, 0.75)
		await _wait(FLASH_SEC)
		_flash.color.a = 0.0
		await _wait(FLASH_SEC * 0.6)


func _tween_progress(from_p: float, to_p: float, duration: float) -> void:
	_layout(from_p)
	var elapsed := 0.0
	var last := Time.get_ticks_usec()
	while elapsed < duration:
		var tree := get_tree()
		if tree == null:
			break
		await tree.process_frame
		var now := Time.get_ticks_usec()
		elapsed += minf(float(now - last) / 1000000.0, MAX_STEP_SEC)
		last = now
		var t := clampf(elapsed / duration, 0.0, 1.0)
		_layout(lerpf(from_p, to_p, t * t * (3.0 - 2.0 * t)))
	_layout(to_p)


func _wait(seconds: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(seconds, true, false, true).timeout


func _reduce_flashing() -> bool:
	var settings := get_node_or_null("/root/AxelSettings")
	if settings == null:
		return false
	return bool(settings.call("get_value", "access", "reduce_flashing", false))
