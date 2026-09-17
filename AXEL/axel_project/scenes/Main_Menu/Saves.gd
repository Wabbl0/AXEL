class_name SavesScreen
extends Control

static var open_mode := "load"

var _backdrop: TextureRect
var _chrome: CanvasLayer
var _time := 0.0
var _status: Label
var _confirm_slot := -1


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
		MenuLook.go(get_tree(), MenuLook.TITLE_SCENE)
		get_viewport().set_input_as_handled()


func _build() -> void:
	for child in _chrome.get_children():
		child.queue_free()
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chrome.add_child(host)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.offset_left = -420
	col.offset_right = 420
	col.offset_top = -360
	col.offset_bottom = 360
	col.add_theme_constant_override("separation", 16)
	host.add_child(col)

	var title := Label.new()
	title.text = "NEW GAME" if open_mode == "new" else "LOAD GAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(title, MenuLook.scaled_font(self, 48), MenuLook.ACCENT)
	col.add_child(title)

	for i in AxelSaves.SLOT_COUNT:
		col.add_child(_make_slot_button(i))

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MenuLook.apply_label(_status, MenuLook.scaled_font(self, 22), MenuLook.DIM)
	col.add_child(_status)

	var back := Button.new()
	back.text = "Back"
	MenuLook.apply_button(back, MenuLook.scaled_font(self, 32))
	back.pressed.connect(func() -> void: MenuLook.go(get_tree(), MenuLook.TITLE_SCENE))
	col.add_child(back)


func _make_slot_button(slot: int) -> Button:
	var button := Button.new()
	button.text = _slot_label(slot)
	MenuLook.apply_button(button, MenuLook.scaled_font(self, 28))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if open_mode == "load":
		button.disabled = AxelSaves.is_empty(slot) or AxelSaves.is_dead(slot)
	button.pressed.connect(func() -> void: _on_slot_pressed(slot))
	return button


func _slot_label(slot: int) -> String:
	var header := AxelSaves.read_header(slot)
	if header.is_empty():
		return "Slot %d  —  empty" % (slot + 1)
	var items: Array = header.get("items", [])
	var item_text := "none"
	if not items.is_empty():
		item_text = ", ".join(items)
	var play := int(float(header.get("playtime_sec", 0.0)))
	var mins := play / 60
	var secs := play % 60
	var stamp := int(header.get("timestamp_unix", 0))
	var when := ""
	if stamp > 0:
		when = Time.get_datetime_string_from_unix_time(stamp, true)
	var dead := "  DIED" if bool(header.get("dead", false)) else ""
	return "Slot %d%s  —  %s  |  mem %d/5  |  %s  |  %dm %ds  |  %s" % [
		slot + 1,
		dead,
		String(header.get("last_room", "?")),
		int(header.get("memories", 0)),
		item_text,
		mins,
		secs,
		when,
	]


func _on_slot_pressed(slot: int) -> void:
	if open_mode == "load":
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


func _start_new(slot: int) -> void:
	if not AxelSaves.new_game(slot):
		_status.text = "Could not start a new game."
		return
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("to_overworld"):
		music.call("to_overworld")
	get_tree().change_scene_to_file(AxelSaves.NEW_GAME_SCENE)
