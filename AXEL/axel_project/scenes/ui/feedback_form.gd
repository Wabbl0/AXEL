class_name FeedbackForm
extends CanvasLayer

signal closed()

const SCALE_5 := ["1", "2", "3", "4", "5"]
const QUESTIONS := [
	{"id": "overall", "kind": "choice", "q": "Overall, how much did you enjoy AXEL?", "hint": "1 = not at all, 5 = loved it. Required.", "opts": SCALE_5},
	{"id": "one_word", "kind": "short", "q": "Describe AXEL in one word.", "max": 20, "placeholder": "one word"},
	{"id": "combat_fun", "kind": "choice", "q": "How fun is the slot-machine combat?", "hint": "1 = boring, 5 = very fun", "opts": SCALE_5},
	{"id": "difficulty", "kind": "choice", "q": "How hard is the game?", "opts": ["Too easy", "A bit easy", "Just right", "A bit hard", "Too hard"]},
	{"id": "atmosphere", "kind": "choice", "q": "How strong are the mood and atmosphere?", "hint": "1 = flat, 5 = gripping", "opts": SCALE_5},
	{"id": "story", "kind": "choice", "q": "Did you understand the story and what to do?", "opts": ["Yes", "Partly", "No"]},
	{"id": "progress", "kind": "choice", "q": "How far did you get?", "opts": ["Outside", "Corridor & locker", "Cafeteria", "Classrooms", "Basement", "An ending"]},
	{"id": "bugs", "kind": "choice", "q": "Did you find bugs?", "opts": ["None", "Minor", "Game-breaking"]},
	{"id": "bug_text", "kind": "long", "q": "Describe the bug: what happened and where?", "max": 1000, "placeholder": "optional"},
	{"id": "performance", "kind": "choice", "q": "How smooth did the game run?", "opts": ["Smooth", "Some stutter", "Laggy"]},
	{"id": "play_again", "kind": "choice", "q": "Would you play again?", "opts": ["Yes", "Maybe", "No"]},
	{"id": "comments", "kind": "long", "q": "Anything else? Write freely.", "max": 2000, "placeholder": "optional"},
	{"kind": "heading", "q": "ABOUT YOU (optional)"},
	{"id": "age", "kind": "age", "q": "Age", "placeholder": "10-110"},
	{"id": "gender", "kind": "choice", "q": "Gender", "opts": ["Male", "Female", "Non-binary"]},
	{"id": "occupation", "kind": "short", "q": "Occupation", "max": 40, "placeholder": "optional"},
]
const FIELD_BG := Color(0.09, 0.02, 0.02, 1.0)
const PANEL_BG := Color(0.035, 0.02, 0.02, 0.98)
const INK := Color(0.05, 0.0, 0.0, 1.0)

var _k := 1.0
var _root: Control
var _frame: MarginContainer
var _panel: PanelContainer
var _scroll: ScrollContainer
var _list: VBoxContainer
var _status: Label
var _send_button: Button
var _cancel_button: Button
var _data_box: CheckBox
var _groups: Dictionary = {}
var _fields: Dictionary = {}
var _wrap_labels: Array[Label] = []
var _prev_focus: Control = null
var _busy := false
var _closing := false
var _pending_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var vp := get_viewport()
	_prev_focus = vp.gui_get_focus_owner() if vp != null else null
	_k = _ui_k()
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()
	MenuLook.grab_first_focus(_list)


func _input(event: InputEvent) -> void:
	if _closing:
		return
	var close_press := event.is_action_pressed("pause")
	if not close_press and event.is_action_pressed("back") and not _typing():
		close_press = true
	if close_press:
		get_viewport().set_input_as_handled()
		close()


func _typing() -> bool:
	var owner := get_viewport().gui_get_focus_owner()
	return owner is LineEdit or owner is TextEdit


func _feedback() -> Node:
	return get_node_or_null("/root/AxelFeedback")


func _ui_k() -> float:
	var fb := _feedback()
	if fb != null and fb.has_method("ui_k"):
		return float(fb.call("ui_k", self))
	return 1.0


func _px(authored: float) -> int:
	return maxi(roundi(authored * _k), 8)


func _version() -> String:
	var fb := _feedback()
	return str(fb.call("version")) if fb != null else "dev"


func _build() -> void:
	_root = Control.new()
	_root.name = "FeedbackRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)
	_frame = MarginContainer.new()
	_frame.name = "Frame"
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_frame)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.add_theme_stylebox_override("panel", _box_style(PANEL_BG, MenuLook.ACCENT, 3, 24.0))
	_frame.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", _px(12))
	_panel.add_child(column)
	var title := Label.new()
	title.text = "FEEDBACK  -  AXEL v%s" % _version()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(title, _px(52), MenuLook.ACCENT)
	column.add_child(title)
	var sub := _wrap_label("Thank you for playing. Only the first question is required. Your answers are anonymous.", 26, MenuLook.TEXT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(sub)
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	MenuLook.apply_scroll(_scroll)
	column.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", _px(26))
	_scroll.add_child(_list)
	var number := 0
	for def in QUESTIONS:
		var kind := str(def["kind"])
		if kind == "heading":
			var head := _wrap_label(str(def["q"]), 34, MenuLook.ACCENT)
			_list.add_child(head)
			continue
		var prefix := ""
		if not (str(def["id"]) in ["age", "gender", "occupation"]):
			number += 1
			prefix = "%d. " % number
		_list.add_child(_build_question(def, prefix))
	_data_box = CheckBox.new()
	_data_box.name = "SendGameData"
	_data_box.text = "Send my game data too (seed, spins, fights, items). No personal info."
	_data_box.button_pressed = true
	MenuLook.apply_check(_data_box)
	_data_box.add_theme_font_size_override("font_size", _px(28))
	_data_box.add_theme_constant_override("icon_max_width", _px(32))
	_data_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_data_box.size_flags_horizontal = Control.SIZE_FILL
	_list.add_child(_data_box)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", _px(20))
	column.add_child(footer)
	_status = _wrap_label("", 26, MenuLook.TEXT)
	_status.name = "Status"
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_status)
	_cancel_button = Button.new()
	_cancel_button.name = "Cancel"
	_cancel_button.text = "Cancel"
	MenuLook.apply_button(_cancel_button, _px(34))
	_cancel_button.pressed.connect(close)
	footer.add_child(_cancel_button)
	_send_button = Button.new()
	_send_button.name = "Send"
	_send_button.text = "Send"
	MenuLook.apply_button(_send_button, _px(34))
	_send_button.add_theme_color_override("font_color", MenuLook.ACCENT)
	_send_button.pressed.connect(press_send)
	footer.add_child(_send_button)


func _build_question(def: Dictionary, prefix: String) -> Control:
	var id := str(def["id"])
	var box := VBoxContainer.new()
	box.name = "Q_" + id
	box.add_theme_constant_override("separation", _px(8))
	box.add_child(_wrap_label(prefix + str(def["q"]), 30, MenuLook.TEXT))
	if def.has("hint"):
		box.add_child(_wrap_label(str(def["hint"]), 24, MenuLook.DIM))
	match str(def["kind"]):
		"choice":
			var flow := HFlowContainer.new()
			flow.add_theme_constant_override("h_separation", _px(12))
			flow.add_theme_constant_override("v_separation", _px(10))
			var group := ButtonGroup.new()
			group.allow_unpress = true
			for opt in def["opts"]:
				var b := Button.new()
				b.text = str(opt)
				b.toggle_mode = true
				b.button_group = group
				b.set_meta(&"value", str(opt))
				_style_choice(b)
				flow.add_child(b)
			_groups[id] = group
			box.add_child(flow)
		"long":
			var edit := TextEdit.new()
			edit.name = "Field_" + id
			edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			edit.placeholder_text = str(def.get("placeholder", ""))
			edit.custom_minimum_size.y = _px(150)
			_style_field(edit)
			var limit := int(def.get("max", 1000))
			edit.text_changed.connect(func() -> void: _clip_text_edit(edit, limit))
			_fields[id] = edit
			box.add_child(edit)
		_:
			var line := LineEdit.new()
			line.name = "Field_" + id
			line.placeholder_text = str(def.get("placeholder", ""))
			_style_field(line)
			if str(def["kind"]) == "age":
				line.max_length = 3
				line.custom_minimum_size.x = _px(160)
				line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				line.text_changed.connect(func(_t: String) -> void: _digits_only(line))
			else:
				line.max_length = int(def.get("max", 40))
			_fields[id] = line
			box.add_child(line)
	return box


func _wrap_label(text: String, size_px: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_FILL
	MenuLook.apply_label(label, _px(size_px), color)
	_wrap_labels.append(label)
	return label


func _box_style(bg: Color, border: Color, border_px: int, pad: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(maxi(roundi(border_px * _k), 1))
	style.set_corner_radius_all(0)
	style.anti_aliasing = false
	style.content_margin_left = pad * _k
	style.content_margin_right = pad * _k
	style.content_margin_top = pad * 0.5 * _k
	style.content_margin_bottom = pad * 0.5 * _k
	return style


func _style_choice(b: Button) -> void:
	MenuLook.apply_button(b, _px(30))
	b.flat = false
	b.custom_minimum_size.x = _px(64)
	var off := _box_style(Color(0, 0, 0, 0), MenuLook.DIM, 2, 18.0)
	var hover := _box_style(Color(0.15, 0.02, 0.02, 1.0), MenuLook.ACCENT, 2, 18.0)
	var on := _box_style(MenuLook.ACCENT, MenuLook.ACCENT, 2, 18.0)
	b.add_theme_stylebox_override("normal", off)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_hover_pressed_color", INK)
	b.add_theme_color_override("font_hover_color", MenuLook.TEXT)
	b.add_theme_color_override("font_focus_color", MenuLook.TEXT)


func _style_field(field: Control) -> void:
	field.add_theme_font_override("font", MenuLook.FONT)
	field.add_theme_font_size_override("font_size", _px(30))
	field.add_theme_color_override("font_color", MenuLook.TEXT)
	field.add_theme_color_override("font_placeholder_color", MenuLook.DIM)
	field.add_theme_color_override("caret_color", MenuLook.ACCENT)
	field.add_theme_stylebox_override("normal", _box_style(FIELD_BG, MenuLook.DIM, 2, 14.0))
	field.add_theme_stylebox_override("focus", _box_style(FIELD_BG, MenuLook.ACCENT, 3, 14.0))
	field.add_theme_stylebox_override("read_only", _box_style(FIELD_BG, MenuLook.DIM, 2, 14.0))


func _clip_text_edit(edit: TextEdit, limit: int) -> void:
	if edit.text.length() <= limit:
		return
	edit.text = edit.text.substr(0, limit)
	edit.set_caret_line(edit.get_line_count() - 1)
	edit.set_caret_column(edit.get_line(edit.get_line_count() - 1).length())


func _digits_only(line: LineEdit) -> void:
	var clean := ""
	for ch in line.text:
		if ch >= "0" and ch <= "9":
			clean += ch
	if clean != line.text:
		line.text = clean
		line.caret_column = clean.length()


func _layout() -> void:
	if _panel == null:
		return
	var view := PortraitUi.view_size(self)
	var rect := Rect2(Vector2.ZERO, view)
	var margin := 40.0 * _k
	if PortraitUi.is_portrait(self):
		rect = PortraitUi.safe_rect(self)
		margin = 16.0 * _k
	var w := minf(1180.0 * _k, rect.size.x - margin * 2.0)
	var side := roundi(rect.position.x + (rect.size.x - w) * 0.5)
	_frame.add_theme_constant_override("margin_left", side)
	_frame.add_theme_constant_override("margin_right", roundi(view.x - rect.end.x) + side)
	_frame.add_theme_constant_override("margin_top", roundi(rect.position.y + margin))
	_frame.add_theme_constant_override("margin_bottom", roundi(view.y - rect.end.y + margin))
	var inner := w - 48.0 * _k - 24.0 * _k
	for label in _wrap_labels:
		if is_instance_valid(label):
			label.custom_maximum_size.x = inner
	_data_box.custom_maximum_size.x = inner


func collect_answers() -> Dictionary:
	var answers := {}
	for id in _groups.keys():
		var group: ButtonGroup = _groups[id]
		var picked := group.get_pressed_button()
		answers[id] = str(picked.get_meta(&"value")) if picked != null else ""
	for id in _fields.keys():
		var field = _fields[id]
		answers[id] = str(field.text).strip_edges()
	return answers


func set_choice(id: String, value: String) -> bool:
	var group: ButtonGroup = _groups.get(id)
	if group == null:
		return false
	for b in group.get_buttons():
		if str(b.get_meta(&"value")) == value:
			b.button_pressed = true
			return true
	return false


func set_text(id: String, value: String) -> bool:
	var field = _fields.get(id)
	if field == null:
		return false
	field.text = value
	return true


func set_send_game_data(on: bool) -> void:
	_data_box.button_pressed = on


func status_text() -> String:
	return _status.text


func press_send() -> void:
	if _busy or _closing:
		return
	var fb := _feedback()
	if fb == null:
		_set_status("Feedback is not available.", MenuLook.ACCENT)
		return
	var res: Dictionary = fb.call("submit", collect_answers(), _data_box.button_pressed)
	if not bool(res.get("ok", false)):
		_set_status(str(res.get("error", "Something went wrong.")), MenuLook.ACCENT)
		return
	if bool(res.get("queued", false)):
		_set_status("Saved. It will be sent when the game can reach the internet.", MenuLook.TEXT)
		_close_soon(2.2)
		return
	_busy = true
	MenuLook.set_button_disabled(_send_button, true)
	_pending_id = str(res.get("id", ""))
	_set_status("Sending...", MenuLook.TEXT)
	if not fb.is_connected("send_finished", _on_send_finished):
		fb.connect("send_finished", _on_send_finished)


func _on_send_finished(id: String, ok: bool) -> void:
	if not _busy:
		return
	if ok and id != _pending_id:
		return
	_busy = false
	var fb := _feedback()
	if fb != null and fb.is_connected("send_finished", _on_send_finished):
		fb.disconnect("send_finished", _on_send_finished)
	if ok:
		_set_status("Thank you! Your feedback was sent.", MenuLook.TEXT)
		_close_soon(1.6)
	else:
		_set_status("No connection right now. Saved, it will be sent automatically later.", MenuLook.TEXT)
		_close_soon(2.6)


func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)


func _close_soon(sec: float) -> void:
	MenuLook.set_button_disabled(_send_button, true)
	get_tree().create_timer(sec, true).timeout.connect(close)


func close() -> void:
	if _closing:
		return
	_closing = true
	var fb := _feedback()
	if fb != null and fb.is_connected("send_finished", _on_send_finished):
		fb.disconnect("send_finished", _on_send_finished)
	if is_instance_valid(_prev_focus) and _prev_focus.is_visible_in_tree():
		_prev_focus.grab_focus(true)
	closed.emit()
	queue_free()
