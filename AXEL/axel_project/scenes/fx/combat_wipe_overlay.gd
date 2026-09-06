extends CanvasLayer
## Overworld -> combat wipe. Red bars close over the screen, the scene changes
## underneath, then the bars open again on the combat board.
##
## Lives on AxelEventFx (autoload) so it survives change_scene_to_file.
## D15: no sound. Palette stays 8-band noir red / black.

const BAR_COUNT := 12
const CLOSE_SEC := 0.34
const OPEN_SEC := 0.28
const FLASH_SEC := 0.05
const FLASH_COUNT := 3
const BAR_RED := Color(0.62, 0.02, 0.02, 1.0)
const BAR_BLACK := Color(0.02, 0.02, 0.02, 1.0)

var _root: Control
var _flash: ColorRect
var _bars: Array[ColorRect] = []
var _covered := false
var _busy := false


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_set_hidden()
	get_viewport().size_changed.connect(_layout_bars)


func is_covered() -> bool:
	return _covered


func _build() -> void:
	_root = Control.new()
	_root.name = "WipeRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	for i in BAR_COUNT:
		var bar := ColorRect.new()
		bar.name = "Bar%d" % i
		bar.color = BAR_RED if i % 2 == 0 else BAR_BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(bar)
		_bars.append(bar)
	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)


func _viewport_size() -> Vector2:
	var vp := get_viewport()
	return Vector2(vp.get_visible_rect().size) if vp != null else Vector2(1920, 1280)


func _layout_bars(progress: float = -1.0) -> void:
	var size := _viewport_size()
	var bar_h := size.y / float(BAR_COUNT)
	var fill: float = progress if progress >= 0.0 else (1.0 if _covered else 0.0)
	for i in _bars.size():
		var bar := _bars[i]
		var width := size.x * clampf(fill, 0.0, 1.0)
		bar.size = Vector2(width, ceilf(bar_h) + 1.0)
		# Alternate the side each bar closes from.
		bar.position = Vector2(0.0 if i % 2 == 0 else size.x - width, float(i) * bar_h)


func _set_hidden() -> void:
	_covered = false
	_root.visible = false
	_layout_bars(0.0)
	if _flash != null:
		_flash.color.a = 0.0


## Cover the screen. Awaited by AxelRun before the scene change.
func close_wipe() -> void:
	if _busy:
		return
	_busy = true
	_root.visible = true
	if not _reduce_flashing():
		await _play_flashes()
	await _tween_bars(0.0, 1.0, CLOSE_SEC)
	_covered = true
	_busy = false


## Uncover once the combat board is up.
func open_wipe() -> void:
	if not _covered and not _root.visible:
		return
	_busy = true
	_root.visible = true
	await _tween_bars(1.0, 0.0, OPEN_SEC)
	_set_hidden()
	_busy = false


## Emergency clear (aborted scene change, headless, disabled FX).
func clear_now() -> void:
	_busy = false
	_set_hidden()


func _play_flashes() -> void:
	for i in FLASH_COUNT:
		_flash.color = Color(0.75, 0.0, 0.0, 0.55) if i % 2 == 0 else Color(0, 0, 0, 0.75)
		await _wait(FLASH_SEC)
		_flash.color.a = 0.0
		await _wait(FLASH_SEC * 0.6)


func _tween_bars(from_fill: float, to_fill: float, duration: float) -> void:
	var elapsed := 0.0
	_layout_bars(from_fill)
	while elapsed < duration:
		await _wait(0.016)
		elapsed += 0.016
		var t := clampf(elapsed / duration, 0.0, 1.0)
		_layout_bars(lerpf(from_fill, to_fill, t * t * (3.0 - 2.0 * t)))
	_layout_bars(to_fill)


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
