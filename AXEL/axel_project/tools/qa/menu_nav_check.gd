extends SceneTree

const TITLE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const SAVES := "res://scenes/Main_Menu/Saves.tscn"
const NEW_GAME_SCENE := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const OPTIONS := "res://scenes/Main_Menu/Options.tscn"
const CREDITS := "res://scenes/Main_Menu/Credits.tscn"
const WINDOW := Vector2i(1920, 1280)
const _QA_DIR := "user://saves_qa_menu_nav"

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_SKIP_INTRO", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	await process_frame
	_assert_ui_mirror()

	var saves := root.get_node_or_null("AxelSaves")
	if saves == null:
		push_error("menu_nav_check: AxelSaves missing")
		quit(1)
		return

	saves.dir_override = _QA_DIR
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_QA_DIR))
	for i in 3:
		saves._delete_slot_files(i)
	if not bool(saves.call("new_game", 0)):
		_fail("could not seed a living slot")
	saves.call("deactivate")

	if not await _open(TITLE):
		_fail("could not open title")
	else:
		await _settle()
		await _measure_title()
		await _check_wasd_title()
		await _check_interact_and_back()

	for i in 3:
		saves._delete_slot_files(i)
	saves.call("deactivate")
	saves.dir_override = ""

	if _failures.is_empty():
		print("Menu nav check OK.")
		quit(0)
	else:
		for f in _failures:
			push_error("menu_nav_check: %s" % f)
		quit(1)


func _assert_ui_mirror() -> void:
	_expect_mirrored("move_up", "ui_up")
	_expect_mirrored("move_down", "ui_down")
	_expect_mirrored("move_left", "ui_left")
	_expect_mirrored("move_right", "ui_right")
	_expect_mirrored("interact", "ui_accept")
	_expect_mirrored("back", "ui_cancel")


func _expect_mirrored(src: String, dst: String) -> void:
	if not InputMap.has_action(src) or not InputMap.has_action(dst):
		_fail("missing action %s or %s" % [src, dst])
		return
	var src_n := InputMap.action_get_events(src).size()
	var dst_n := InputMap.action_get_events(dst).size()
	if src_n != dst_n:
		_fail("%s has %d events but %s has %d" % [src, src_n, dst, dst_n])
	var src_keys := _physical_keys(src)
	var dst_keys := _physical_keys(dst)
	if src_keys != dst_keys:
		_fail("%s keys %s were not copied onto %s (%s)" % [src, str(src_keys), dst, str(dst_keys)])


func _physical_keys(action: String) -> Array[int]:
	var keys: Array[int] = []
	if not InputMap.has_action(action):
		return keys
	for ev in InputMap.action_get_events(action):
		var k := ev as InputEventKey
		if k != null:
			keys.append(int(k.physical_keycode))
	keys.sort()
	return keys


func _measure_title() -> void:
	var scene := current_scene
	if scene == null:
		_fail("title scene missing")
		return
	var vp := Rect2(Vector2.ZERO, Vector2(WINDOW))
	var title := scene.find_child("TitleLabel", true, false) as Label
	if title == null:
		_fail("title label missing")
	else:
		if not vp.encloses(title.get_global_rect()):
			_fail("title label sits outside the viewport")
		if title.get_visible_line_count() < 1:
			_fail("title label has no visible line")
		elif title.get_character_bounds(0).size == Vector2.ZERO:
			_fail("title label character bounds empty")
	for name in [
		"ContinueButton", "NewGameButton", "LoadGameButton",
		"OptionsButton", "CreditsButton", "QuitButton",
	]:
		var btn := scene.find_child(name, true, false) as Button
		if btn == null:
			_fail("%s missing" % name)
			continue
		if btn.text.is_empty():
			_fail("%s has empty text" % name)
		if not vp.encloses(btn.get_global_rect()):
			_fail("%s sits outside the viewport" % name)
		if btn.get_global_rect().size.x < 8.0 or btn.get_global_rect().size.y < 8.0:
			_fail("%s is too small to read" % name)
		_assert_hugs_text(btn, name)
	await _measure_pause_buttons()


func _measure_pause_buttons() -> void:
	var pause := root.get_node_or_null("AxelPause")
	if pause == null:
		_fail("AxelPause missing")
		return
	var menu := pause.get_node_or_null("AxelPauseMenu")
	if menu == null or not menu.has_method("show_menu"):
		_fail("pause menu missing")
		return
	menu.call("show_menu")
	await _settle()
	var found := false
	for child in menu.find_children("*", "Button", true, false):
		var btn := child as Button
		if btn == null or not btn.is_visible_in_tree() or btn.text.is_empty():
			continue
		if btn.text == "Resume" or btn.text == "Options" or btn.text.begins_with("Quit"):
			found = true
			_assert_hugs_text(btn, "pause %s" % btn.text)
	if not found:
		_fail("pause menu had no visible buttons to measure")
	if menu.has_method("hide_menu"):
		menu.call("hide_menu")
	if current_scene != null and current_scene.has_method("_focus_start"):
		current_scene.call("_focus_start")
	await process_frame


func _check_wasd_title() -> void:
	var cont := _button("ContinueButton")
	var new_game := _button("NewGameButton")
	if cont == null or new_game == null:
		return
	if not cont.has_focus():
		_fail("title did not start focused on Continue")
		cont.grab_focus(true)
		await process_frame
	if cont.has_focus(true):
		_fail("title showed the focus outline before any key")
	await _tap(KEY_S)
	if not new_game.has_focus():
		_fail("S did not move title focus from Continue to New Game (owner=%s)" % _focus_name())
		return
	if not new_game.has_focus(true):
		_fail("S did not reveal the focus outline on New Game")
	await _tap(KEY_W)
	if not cont.has_focus():
		_fail("W did not move title focus back to Continue (owner=%s)" % _focus_name())


func _check_interact_and_back() -> void:
	var new_game := _button("NewGameButton")
	if new_game == null:
		return
	new_game.grab_focus()
	await process_frame
	await _tap(KEY_E)
	if not await _open_wait(NEW_GAME_SCENE):
		_fail("E on New Game did not start 1.1 (scene=%s)" % _scene_path())
		return
	await _settle()
	if not await _open(TITLE):
		_fail("could not return to title after New Game")
		return
	await _settle()

	var load_btn := _button("LoadGameButton")
	if load_btn == null:
		return
	load_btn.grab_focus()
	await process_frame
	await _tap(KEY_E)
	if not await _open_wait(SAVES):
		_fail("E on Load Game did not open Saves (scene=%s)" % _scene_path())
		return
	await _settle()
	var slot := current_scene.find_child("Slot1", true, false) as Button
	var delete_btn := current_scene.find_child("DeleteSlot1", true, false) as Button
	if slot == null or delete_btn == null:
		_fail("Load Saves missing Slot1 or Delete")
	else:
		if not slot.has_focus():
			_fail("Load Saves did not focus Slot1 (owner=%s)" % _focus_name())
			slot.grab_focus()
			await process_frame
		await _tap(KEY_D)
		if not delete_btn.has_focus():
			_fail("D did not move Load Saves focus to Delete (owner=%s)" % _focus_name())
		await _tap(KEY_A)
		if not slot.has_focus():
			_fail("A did not move Load Saves focus back to Slot1 (owner=%s)" % _focus_name())
	await _tap(KEY_ESCAPE)
	if not await _open_wait(TITLE):
		_fail("Esc on Load Saves did not return to title (scene=%s)" % _scene_path())
		return
	await _settle()

	var credits_btn := _button("CreditsButton")
	if credits_btn == null:
		return
	credits_btn.grab_focus()
	await process_frame
	await _tap(KEY_SPACE)
	if not await _open_wait(CREDITS):
		_fail("Space on Credits did not open Credits (scene=%s)" % _scene_path())
		return
	await _settle()
	await _tap(KEY_BACKSPACE)
	if not await _open_wait(TITLE):
		_fail("Backspace on Credits did not return to title (scene=%s)" % _scene_path())
		return
	await _settle()

	var options_btn := _button("OptionsButton")
	if options_btn == null:
		return
	options_btn.grab_focus()
	await process_frame
	await _tap(KEY_ENTER)
	if not await _open_wait(OPTIONS):
		_fail("Enter on Options did not open Options (scene=%s)" % _scene_path())
		return
	await _settle()
	var focused := root.gui_get_focus_owner()
	if focused == null:
		_fail("Options opened with no focus owner")
	await _tap(KEY_ESCAPE)
	if not await _open_wait(TITLE):
		_fail("Esc on Options did not return to title (scene=%s)" % _scene_path())


func _assert_hugs_text(btn: Button, label: String) -> void:
	if btn == null or btn.text.is_empty():
		return
	var font := btn.get_theme_font("font")
	var font_size := btn.get_theme_font_size("font_size")
	if font == null or font_size < 1:
		_fail("%s has no font to measure" % label)
		return
	var text_w := font.get_string_size(btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var box := btn.get_global_rect()
	if box.size.x > text_w + 80.0:
		_fail("%s outline is %.0f px wide; text is only %.0f px" % [label, box.size.x, text_w])
	if box.size.x + 0.5 < text_w + 24.0:
		_fail("%s outline has no padding around the text (box %.0f, text %.0f)" % [
			label, box.size.x, text_w
		])
	var focus := btn.get_theme_stylebox("focus") as StyleBoxFlat
	if focus == null:
		_fail("%s is missing a flat focus style" % label)
		return
	if not focus.border_color.is_equal_approx(MenuLook.ACCENT):
		_fail("%s focus outline is %s, expected menu red" % [label, str(focus.border_color)])
	if focus.get_border_width_min() < 4:
		_fail("%s focus outline is only %d px thick" % [label, focus.get_border_width_min()])
	if focus.anti_aliasing:
		_fail("%s focus outline is smoothed, not pixelated" % label)


func _button(node_name: String) -> Button:
	if current_scene == null:
		_fail("no current scene while looking for %s" % node_name)
		return null
	var btn := current_scene.find_child(node_name, true, false) as Button
	if btn == null:
		_fail("%s missing" % node_name)
	return btn


func _focus_name() -> String:
	var owner := root.gui_get_focus_owner()
	if owner == null:
		return "<none>"
	return owner.name


func _scene_path() -> String:
	if current_scene == null:
		return "<none>"
	return current_scene.scene_file_path


func _open(path: String) -> bool:
	if change_scene_to_file(path) != OK:
		return false
	return await _open_wait(path)


func _open_wait(path: String) -> bool:
	for _i in 90:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == path:
			return true
	return false


func _settle() -> void:
	for _i in 6:
		await process_frame


func _tap(key: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = key
	press.physical_keycode = key
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var rel := InputEventKey.new()
	rel.keycode = key
	rel.physical_keycode = key
	rel.pressed = false
	Input.parse_input_event(rel)
	await process_frame
	await process_frame
