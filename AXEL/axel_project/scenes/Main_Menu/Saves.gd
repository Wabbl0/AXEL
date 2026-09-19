class_name SavesScreen
extends Control

const _COL_HALF_W := 500.0

static var open_mode := "load"

var _backdrop: TextureRect
var _chrome: CanvasLayer
var _time := 0.0
var _status: Label
var _confirm_slot := -1
var _confirm_delete_slot := -1
var _status_hold := ""


func _ready() -> void:
	_backdrop = MenuLook.make_backdrop(self)
	_chrome = MenuLook.make_chrome_layer(self)
	_build()
	get_viewport().size_changed.connect(_build)


func _process(delta: float) -> void:
	_time += delta
	MenuLook.drift_backdrop(_backdrop, _time)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		MenuLook.go(get_tree(), MenuLook.TITLE_SCENE)


func _build() -> void:
	for child in _chrome.get_children():
		child.queue_free()
	var host := Control.new()
	host.name = "SavesHost"
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chrome.add_child(host)
	var col := VBoxContainer.new()
	col.name = "SavesColumn"
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.offset_left = -_COL_HALF_W
	col.offset_right = _COL_HALF_W
	col.offset_top = -360
	col.offset_bottom = 360
	col.add_theme_constant_override("separation", 16)
	col.propagate_maximum_size = true
	col.custom_maximum_size = Vector2(_COL_HALF_W * 2.0, -1.0)
	host.add_child(col)

	var title := Label.new()
	title.text = "NEW GAME" if open_mode == "new" else "LOAD GAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(title, MenuLook.scaled_font(self, 48), MenuLook.ACCENT)
	col.add_child(title)

	for i in AxelSaves.SLOT_COUNT:
		col.add_child(_make_slot_row(i))

	_status = Label.new()
	_status.name = "SavesStatus"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_maximum_size = Vector2(_COL_HALF_W * 2.0, -1.0)
	MenuLook.apply_label(_status, MenuLook.scaled_font(self, 22), MenuLook.DIM)
	col.add_child(_status)
	if not _status_hold.is_empty():
		_status.text = _status_hold
		_status_hold = ""

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back"
	MenuLook.apply_button(back, MenuLook.scaled_font(self, 32))
	back.pressed.connect(func() -> void: MenuLook.go(get_tree(), MenuLook.TITLE_SCENE))
	col.add_child(back)
	MenuLook.grab_first_focus(host)


func _make_slot_row(slot: int) -> Control:
	if open_mode != "load":
		return _make_slot_button(slot)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.propagate_maximum_size = true
	var button := _make_slot_button(slot)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(button)
	var delete_btn := Button.new()
	delete_btn.name = "DeleteSlot%d" % (slot + 1)
	delete_btn.text = "Delete"
	MenuLook.apply_button(delete_btn, MenuLook.scaled_font(self, 28), Control.SIZE_SHRINK_END)
	var font := delete_btn.get_theme_font("font")
	var fs := delete_btn.get_theme_font_size("font_size")
	var word_w := 80.0
	if font != null:
		word_w = font.get_string_size("Delete", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	delete_btn.custom_minimum_size.x = word_w + 32.0
	MenuLook.set_button_disabled(delete_btn, AxelSaves.is_empty(slot))
	delete_btn.pressed.connect(func() -> void: _on_delete_pressed(slot))
	row.add_child(delete_btn)
	return row


func _make_slot_button(slot: int) -> Button:
	var button := Button.new()
	button.name = "Slot%d" % (slot + 1)
	button.text = _slot_label(slot)
	MenuLook.apply_button(button, MenuLook.scaled_font(self, 28), Control.SIZE_SHRINK_BEGIN)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if open_mode == "load":
		MenuLook.set_button_disabled(
			button, AxelSaves.is_empty(slot) or AxelSaves.is_dead(slot)
		)
	button.pressed.connect(func() -> void: _on_slot_pressed(slot))
	return button


func _slot_label(slot: int) -> String:
	var header := AxelSaves.read_header(slot)
	if header.is_empty():
		return "Slot %d  —  empty" % (slot + 1)
	var play := int(float(header.get("playtime_sec", 0.0)))
	var mins := play / 60
	var secs := play % 60
	var stamp := int(header.get("timestamp_unix", 0))
	var when := ""
	if stamp > 0:
		when = Time.get_datetime_string_from_unix_time(stamp, true)
	var dead := "  DIED" if bool(header.get("dead", false)) else ""
	var seed_n := int(header.get("seed", 0))
	var seed_txt := ("  |  seed %d" % seed_n) if seed_n != 0 else ""
	return "Slot %d%s  —  %s  |  %dm %ds  |  %s%s" % [
		slot + 1,
		dead,
		String(header.get("last_room", "?")),
		mins,
		secs,
		when,
		seed_txt,
	]


func _on_slot_pressed(slot: int) -> void:
	if open_mode == "load":
		_confirm_delete_slot = -1
		if not AxelSaves.load_slot(slot):
			_status.text = "Could not load that slot."
		return
	if AxelSaves.is_empty(slot):
		_start_new(slot)
		return
	if _confirm_slot == slot:
		_start_new(slot)
		return
	_confirm_slot = slot
	if AxelSaves.is_dead(slot):
		_status.text = "That slot died. Press again to overwrite."
	else:
		_status.text = "Slot has a run. Press again to overwrite."


func _on_delete_pressed(slot: int) -> void:
	if AxelSaves.is_empty(slot):
		_status.text = "That slot is already empty."
		return
	if _confirm_delete_slot == slot:
		if not AxelSaves.delete_slot(slot):
			_status.text = "Could not delete that slot."
			_confirm_delete_slot = -1
			return
		_confirm_delete_slot = -1
		_status_hold = "Slot deleted."
		_build()
		return
	_confirm_delete_slot = slot
	_status.text = "Press again to delete this slot."


func _start_new(slot: int) -> void:
	if not AxelSaves.new_game(slot):
		_status.text = "Could not start a new game."
		return
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("to_overworld"):
		music.call("to_overworld")
	get_tree().change_scene_to_file(AxelSaves.NEW_GAME_SCENE)
