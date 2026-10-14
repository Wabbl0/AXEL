class_name SavesScreen
extends Control

const _COL_HALF_W := 500.0

static var open_mode := "load"

var _backdrop: TextureRect
var _chrome: CanvasLayer
var _time := 0.0
var _status: Label
var _seed_hover: Label
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
	_hide_seed_hover()
	for child in _chrome.get_children():
		child.queue_free()
	var host := Control.new()
	host.name = "SavesHost"
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chrome.add_child(host)
	var half_w := _col_half_w()
	var half_h := 360.0
	var portrait := PortraitUi.is_portrait(self)
	if portrait:
		half_h = PortraitUi.safe_rect(self).size.y * 0.42
	var col := VBoxContainer.new()
	col.name = "SavesColumn"
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.offset_left = -half_w
	col.offset_right = half_w
	col.offset_top = -half_h
	col.offset_bottom = half_h
	if portrait:
		col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", roundi(16.0 * PortraitUi.boost(self, 1.6)))
	col.propagate_maximum_size = true
	col.custom_maximum_size = Vector2(half_w * 2.0, -1.0)
	host.add_child(col)

	var title := Label.new()
	title.text = "NEW GAME" if open_mode == "new" else "LOAD GAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(title, PortraitUi.font(self, 48, 2.6), MenuLook.ACCENT)
	col.add_child(title)

	for i in AxelSaves.SLOT_COUNT:
		col.add_child(_make_slot_row(i))

	_status = Label.new()
	_status.name = "SavesStatus"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_maximum_size = Vector2(half_w * 2.0, -1.0)
	MenuLook.apply_label(_status, PortraitUi.font(self, 22, 1.8), MenuLook.DIM)
	col.add_child(_status)
	if not _status_hold.is_empty():
		_status.text = _status_hold
		_status_hold = ""

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back"
	MenuLook.apply_button(back, PortraitUi.font(self, 32, 2.2))
	back.pressed.connect(func() -> void: MenuLook.go(get_tree(), MenuLook.TITLE_SCENE))
	col.add_child(back)
	MenuLook.grab_first_focus(host)


func _col_half_w() -> float:
	if PortraitUi.is_portrait(self):
		return PortraitUi.view_size(self).x * 0.45
	return _COL_HALF_W


func _make_slot_row(slot: int) -> Control:
	if open_mode != "load":
		return _make_slot_button(slot)
	var portrait := PortraitUi.is_portrait(self)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.propagate_maximum_size = true
	var button := _make_slot_button(slot)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var outer: VBoxContainer = null
	if portrait:
		outer = VBoxContainer.new()
		outer.propagate_maximum_size = true
		outer.add_child(button)
		row.alignment = BoxContainer.ALIGNMENT_END
		outer.add_child(row)
	else:
		row.add_child(button)
	var seed_n := _slot_seed(slot)
	if seed_n != 0:
		var seed_btn := Button.new()
		seed_btn.name = "SeedSlot%d" % (slot + 1)
		seed_btn.text = "seed %d" % seed_n
		MenuLook.apply_button(seed_btn, PortraitUi.font(self, 28, 1.8), Control.SIZE_SHRINK_END)
		seed_btn.clip_text = true
		seed_btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		seed_btn.custom_maximum_size = Vector2(220.0 * PortraitUi.boost(self, 1.8), -1.0)
		seed_btn.mouse_entered.connect(func() -> void: _show_seed_hover(seed_btn, seed_n))
		seed_btn.mouse_exited.connect(_hide_seed_hover)
		seed_btn.pressed.connect(func() -> void: _on_seed_pressed(seed_n))
		row.add_child(seed_btn)
	var delete_btn := Button.new()
	delete_btn.name = "DeleteSlot%d" % (slot + 1)
	delete_btn.text = "Delete"
	MenuLook.apply_button(delete_btn, PortraitUi.font(self, 28, 1.8), Control.SIZE_SHRINK_END)
	var font := delete_btn.get_theme_font("font")
	var fs := delete_btn.get_theme_font_size("font_size")
	var word_w := 80.0
	if font != null:
		word_w = font.get_string_size("Delete", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	delete_btn.custom_minimum_size.x = word_w + 32.0
	MenuLook.set_button_disabled(delete_btn, AxelSaves.is_empty(slot))
	delete_btn.pressed.connect(func() -> void: _on_delete_pressed(slot))
	row.add_child(delete_btn)
	if outer != null:
		return outer
	return row


func _make_slot_button(slot: int) -> Button:
	var button := Button.new()
	button.name = "Slot%d" % (slot + 1)
	button.text = _slot_label(slot)
	MenuLook.apply_button(button, PortraitUi.font(self, 28, 1.8), Control.SIZE_SHRINK_BEGIN)
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
	@warning_ignore("integer_division")
	var mins := play / 60
	var secs := play % 60
	var stamp := int(header.get("timestamp_unix", 0))
	var when := ""
	if stamp > 0:
		when = Time.get_datetime_string_from_unix_time(stamp, true)
	var dead := "  DIED" if bool(header.get("dead", false)) else ""
	var fmt := "Slot %d%s  —  %s
%dm %ds  |  %s" if PortraitUi.is_portrait(self) else "Slot %d%s  —  %s  |  %dm %ds  |  %s"
	return fmt % [
		slot + 1,
		dead,
		String(header.get("last_room", "?")),
		mins,
		secs,
		when,
	]


func _slot_seed(slot: int) -> int:
	var header := AxelSaves.read_header(slot)
	if header.is_empty():
		return 0
	return int(header.get("seed", 0))


func _on_seed_pressed(seed_n: int) -> void:
	DisplayServer.clipboard_set(str(seed_n))
	_confirm_delete_slot = -1
	if _status != null:
		_status.text = "Seed copied."


func _show_seed_hover(button: Button, seed_n: int) -> void:
	_ensure_seed_hover()
	_seed_hover.text = "seed %d" % seed_n
	_seed_hover.visible = true
	var hover_size := _seed_hover.get_combined_minimum_size()
	if hover_size.x < 1.0 or hover_size.y < 1.0:
		hover_size = Vector2(220.0, 36.0)
	var btn_rect := button.get_global_rect()
	var view := get_viewport_rect().size
	var x := btn_rect.position.x
	var y := btn_rect.position.y - hover_size.y - 4.0
	if y < 0.0:
		y = btn_rect.end.y + 4.0
	x = clampf(x, 0.0, maxf(view.x - hover_size.x, 0.0))
	y = clampf(y, 0.0, maxf(view.y - hover_size.y, 0.0))
	_seed_hover.global_position = Vector2(x, y)
	_seed_hover.size = hover_size


func _hide_seed_hover() -> void:
	if _seed_hover != null and is_instance_valid(_seed_hover):
		_seed_hover.visible = false


func _ensure_seed_hover() -> void:
	if _seed_hover != null and is_instance_valid(_seed_hover):
		return
	_seed_hover = Label.new()
	_seed_hover.name = "SeedHover"
	_seed_hover.visible = false
	_seed_hover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seed_hover.z_index = 20
	MenuLook.apply_label(_seed_hover, PortraitUi.font(self, 28, 1.8), MenuLook.TEXT)
	add_child(_seed_hover)


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
	if not await AxelSaves.begin_new_game_and_enter(slot):
		if is_inside_tree():
			_status.text = "Could not start a new game."
