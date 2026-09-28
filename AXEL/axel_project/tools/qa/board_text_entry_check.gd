extends SceneTree

const OVERLAY := "res://scenes/ui/TopDialogueOverlay.tscn"
const CLASSROOM := "res://scenes/Arc_5/5.1_Classroom.gd"
const WORLD := "res://scripts/autoload/axel_world.gd"
const WINDOW := Vector2i(1920, 1280)

var _failures: Array[String] = []
var _entry_result: Dictionary = {}
var _entry_finished := false


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_POST_FX", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	await process_frame
	_check_classroom_source()
	await _check_entry_field()
	if _failures.is_empty():
		print("Board text entry check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("board_text_entry_check: %s" % msg)
	quit(1)


func _check_classroom_source() -> void:
	var src := FileAccess.get_file_as_string(CLASSROOM)
	if src.is_empty():
		_fail("could not read classroom script")
		return
	if src.contains("5.3_ClassroomBoard"):
		_fail("classroom still opens the board scene")
	if src.find("await_text_entry") < 0:
		_fail("classroom does not use the dialogue-bar answer")
	if src.find("Nah.") < 0:
		_fail("missing fail line")
	if src.find("ensure_board_question") < 0:
		_fail("classroom does not ask the saved board question")
	if src.find("spend_board_guess") < 0:
		_fail("missing one-guess lock")
	var world_src := FileAccess.get_file_as_string(WORLD)
	if world_src.find("In which room") < 0:
		_fail("missing room question")


func _check_entry_field() -> void:
	var packed: PackedScene = load(OVERLAY)
	var overlay: Node = packed.instantiate()
	overlay.set("fx_crt_power", false)
	overlay.set("fx_char_scramble", false)
	overlay.set("fx_line_swap_glitch", false)
	root.add_child(overlay)
	_entry_result = {}
	_entry_finished = false
	_run_entry(overlay)
	var panel := overlay.get_node("ViewportRoot/RootMargin/BarPanel") as Control
	var caret := overlay.get_node("ViewportRoot/AnswerCaret") as ColorRect
	var ready := false
	for _i in 180:
		await process_frame
		if (
			overlay.is_text_entry_active()
			and panel.get_global_rect().size.x > 400.0
			and caret.size.y > 1.0
		):
			ready = true
			break
	if not ready:
		_fail("answer bar did not open")
		overlay.queue_free()
		return
	var label := overlay.get_node("ViewportRoot/RootMargin/BarPanel/InnerPanel/LineLabel") as Label
	if not panel.get_global_rect().encloses(caret.get_global_rect()):
		_fail("caret is outside the dialogue bar")
	if not _is_white(caret.color):
		_fail("caret should start white")
	overlay._input(_key(KEY_A, 65))
	await process_frame
	if label.text != "":
		_fail("typing worked before the bar was pressed")
	if overlay.is_text_entry_armed():
		_fail("letter key armed the bar")
	overlay._input(_click(Vector2(4, 4)))
	await process_frame
	if overlay.is_text_entry_armed():
		_fail("a click outside the bar armed it")
	overlay._input(_click(panel.get_global_rect().get_center()))
	await process_frame
	if not overlay.is_text_entry_armed():
		_fail("pressing the bar did not arm typing")
	if not _is_red(caret.color):
		_fail("caret should turn red after the bar is pressed")
	if not panel.get_global_rect().encloses(caret.get_global_rect()):
		_fail("red caret left the dialogue bar")
	for pair in [[KEY_A, 65], [KEY_X, 88], [KEY_E, 69], [KEY_L, 76], [KEY_X, 88]]:
		overlay._input(_key(int(pair[0]), int(pair[1])))
	await process_frame
	if label.text != "AXELX":
		_fail("typed text was '%s'" % label.text)
	overlay._input(_key(KEY_BACKSPACE, 0))
	await process_frame
	if label.text != "AXEL":
		_fail("backspace left '%s'" % label.text)
	overlay._input(_key(KEY_ENTER, 0))
	for _i in 180:
		await process_frame
		if _entry_finished:
			break
	if not _entry_finished:
		_fail("enter did not submit")
	elif bool(_entry_result.get("cancelled", true)) or String(_entry_result.get("text", "")) != "AXEL":
		_fail("submit returned %s" % str(_entry_result))
	overlay.queue_free()
	await process_frame


func _run_entry(overlay: Node) -> void:
	_entry_result = await overlay.await_text_entry()
	_entry_finished = true


func _key(code: Key, unicode: int) -> InputEventKey:
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = code
	key.physical_keycode = code
	key.unicode = unicode
	return key


func _click(at: Vector2) -> InputEventMouseButton:
	var mouse := InputEventMouseButton.new()
	mouse.pressed = true
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = at
	return mouse


func _is_white(color: Color) -> bool:
	return color.r > 0.9 and color.g > 0.9 and color.b > 0.9


func _is_red(color: Color) -> bool:
	return color.r > 0.9 and color.g < 0.1 and color.b < 0.1
