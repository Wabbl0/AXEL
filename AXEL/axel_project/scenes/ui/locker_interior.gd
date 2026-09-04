class_name LockerInterior
extends CanvasLayer
## Locker loadout (D7 / D11). Owned items on a shelf grid; click to equip.

signal closed
signal start_requested

const COLS := 6
const ICON_PX := 72


var _panel: Control
var _grid: GridContainer
var _hover: Label
var _equip_label: Label
var _act_label: Label
var _start_btn: Button
var _status: Label


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	_build()


func is_open() -> bool:
	return visible


func open_locker() -> void:
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("grant_locker_stash_once"):
		run.call("grant_locker_stash_once")
	visible = true
	_apply_scale()
	_refresh()


func _apply_scale() -> void:
	if _panel == null:
		return
	var f := UiViewportScale.factor(self)
	_panel.offset_left = -420.0 * f
	_panel.offset_right = 420.0 * f
	_panel.offset_top = -360.0 * f
	_panel.offset_bottom = 360.0 * f


func close_locker() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("back"):
		close_locker()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var scrim := ColorRect.new()
	scrim.color = Color(0.0, 0.0, 0.0, 0.78)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(scrim)

	_panel = VBoxContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -420
	_panel.offset_right = 420
	_panel.offset_top = -360
	_panel.offset_bottom = 360
	_panel.add_theme_constant_override("separation", 10)
	root.add_child(_panel)

	var title := Label.new()
	title.text = "YOUR LOCKER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(title, 40, MenuLook.ACCENT)
	_panel.add_child(title)

	_act_label = Label.new()
	_act_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(_act_label, 22, MenuLook.TEXT)
	_panel.add_child(_act_label)

	_equip_label = Label.new()
	_equip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(_equip_label, 22, MenuLook.DIM)
	_panel.add_child(_equip_label)

	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_panel.add_child(_grid)

	_hover = Label.new()
	_hover.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hover.custom_minimum_size = Vector2(800, 72)
	MenuLook.apply_label(_hover, 20, MenuLook.TEXT)
	_panel.add_child(_hover)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MenuLook.apply_label(_status, 20, MenuLook.DIM)
	_panel.add_child(_status)

	_start_btn = Button.new()
	_start_btn.text = "START RUN"
	MenuLook.apply_button(_start_btn, 32)
	_start_btn.pressed.connect(_on_start)
	_panel.add_child(_start_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	MenuLook.apply_button(close_btn, 28)
	close_btn.pressed.connect(close_locker)
	_panel.add_child(close_btn)


func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var run := get_node_or_null("/root/AxelRun")
	if run == null:
		return
	var owned: Array = run.call("owned_items")
	var equipped: PackedStringArray = run.state.equipped_item_ids
	for item in owned:
		_grid.add_child(_make_item_button(item, equipped))
	if owned.is_empty():
		var empty := Label.new()
		empty.text = "The locker is empty."
		MenuLook.apply_label(empty, 22, MenuLook.DIM)
		_grid.add_child(empty)
	var max_slots := 7
	if run.has_method("max_equip_slots"):
		max_slots = int(run.call("max_equip_slots"))
	_equip_label.text = "Equipped  %d / %d" % [equipped.size(), max_slots]
	_act_label.text = _act_line(run)
	_hover.text = "Hover an item to read it. Click to equip."
	var can_start := bool(run.call("can_start_encounter"))
	_start_btn.disabled = not can_start
	if can_start:
		_status.text = ""
	elif int(run.state.act) >= 3:
		_status.text = "The locker is quiet. This run is finished."
	else:
		_status.text = "The locker is quiet."


func _act_line(run: Node) -> String:
	var act: int = int(run.state.act)
	var names: PackedStringArray = ["", "THE LOCKER", "CAFETERIA + CLASSROOMS", "THE BASEMENT"]
	var act_name: String = names[act] if act < names.size() else "UNKNOWN"
	if not bool(run.call("can_start_encounter")):
		return "ACT %s — %s  ·  done" % [_roman(act), act_name]
	var idx: int = int(run.state.encounter_index) + 1
	var total: int = int(run.call("encounters_in_act"))
	return "ACT %s — %s  ·  encounter %d / %d" % [_roman(act), act_name, idx, total]


func _roman(act: int) -> String:
	match act:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		_:
			return str(act)


func _make_item_button(item: Resource, equipped: PackedStringArray) -> Button:
	var item_id := String(item.get("id"))
	var button := Button.new()
	button.custom_minimum_size = Vector2(ICON_PX + 16, ICON_PX + 28)
	button.toggle_mode = true
	button.button_pressed = equipped.has(item_id)
	button.tooltip_text = String(item.get("description"))
	var icon := item.get("icon") as Texture2D
	if icon != null:
		button.icon = icon
		button.expand_icon = true
	button.text = item_id
	MenuLook.apply_button(button, 16)
	if button.button_pressed:
		button.add_theme_color_override("font_color", MenuLook.ACCENT)
	button.pressed.connect(func() -> void: _on_item_clicked(item_id))
	button.mouse_entered.connect(func() -> void: _show_hover(item))
	return button


func _show_hover(item: Resource) -> void:
	_hover.text = "%s  —  %s" % [String(item.get("display_name")), String(item.get("description"))]


func _on_item_clicked(item_id: String) -> void:
	var run := get_node_or_null("/root/AxelRun")
	if run == null:
		return
	if not bool(run.call("toggle_equip", item_id)):
		_status.text = "Loadout is full."
	_refresh()


func _on_start() -> void:
	start_requested.emit()
