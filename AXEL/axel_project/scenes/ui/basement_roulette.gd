class_name BasementRoulette
extends CanvasLayer

signal closed

const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const SLICE_ICON_PX := 128
const REEL_SIZE := 8
const PENDING := "pending"
const SPIN_TURNS := 5
const SPIN_SEC := 3.0
const HEADER_TEXT := "One spin. Whatever it gives, you carry."
const INK_RED := Color(0.85, 0.06, 0.06, 1)
const DIM_GREY := Color(0.62, 0.6, 0.58, 1)

var _world: Node
var _run: Node
var _disc: RouletteDisc
var _pointer: RoulettePointer
var _header: Label
var _name_label: Label
var _family_label: Label
var _desc_label: RichTextLabel
var _dread_label: Label
var _buttons: HBoxContainer
var _spin_button: Button
var _leave_button: Button
var _take_button: Button
var _respin_button: Button
var _reel: Array = []
var _spinning := false
var _closing := false


func _ready() -> void:
	layer = 110
	_world = get_node_or_null("/root/AxelWorld")
	_run = get_node_or_null("/root/AxelRun")
	_build()
	_layout()
	get_viewport().size_changed.connect(_layout)
	if is_pending():
		_build_reel()
		_disc.rotation = _rest_rotation(_result_slot())
		_show_result()
	else:
		_build_reel()
		_show_offer()


func is_pending() -> bool:
	return _world != null and String(_world.call("roulette_state")) == PENDING


func is_spinning() -> bool:
	return _spinning


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_disc = RouletteDisc.new()
	_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_disc)
	_pointer = RoulettePointer.new()
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pointer)
	_header = _make_label(40, Color(1, 1, 1, 1))
	_header.text = HEADER_TEXT
	add_child(_header)
	_name_label = _make_label(44, Color(1, 1, 1, 1))
	add_child(_name_label)
	_family_label = _make_label(28, DIM_GREY)
	add_child(_family_label)
	_desc_label = ItemDescFormat.make_label("RouletteDesc", 30, 720.0)
	add_child(_desc_label)
	_dread_label = _make_label(30, INK_RED)
	add_child(_dread_label)
	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 48)
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_buttons)
	_spin_button = _make_button("Spin", _on_spin)
	_leave_button = _make_button("Leave it", _on_leave)
	_take_button = _make_button("Take", _on_take)
	_respin_button = _make_button("Respin", _on_respin)


func _make_label(font_px: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_px)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 40)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_hover_color", INK_RED)
	button.add_theme_color_override("font_focus_color", INK_RED)
	button.add_theme_color_override("font_disabled_color", DIM_GREY)
	button.custom_minimum_size = Vector2(220, 56)
	button.pressed.connect(handler)
	_buttons.add_child(button)
	return button


func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var radius := minf(size.y * 0.25, size.x * 0.3)
	var center := Vector2(size.x * 0.5, size.y * 0.08 + 56.0 + radius)
	_disc.radius = radius
	_disc.size = Vector2.ONE * radius * 2.0
	_disc.position = center - Vector2.ONE * radius
	_disc.pivot_offset = Vector2.ONE * radius
	_disc.queue_redraw()
	_pointer.size = Vector2(radius * 0.24, radius * 0.24)
	_pointer.position = Vector2(center.x - _pointer.size.x * 0.5, center.y - radius - _pointer.size.y * 0.55)
	_pointer.queue_redraw()
	_place_label(_header, size.x, size.y * 0.04)
	var y := center.y + radius + 24.0
	_place_label(_name_label, size.x, y)
	y += 52.0
	_place_label(_family_label, size.x, y)
	y += 36.0
	var desc_w := minf(720.0, size.x - 32.0)
	ItemDescFormat.apply_size(_desc_label, 30, desc_w)
	_desc_label.position = Vector2((size.x - desc_w) * 0.5, y)
	y += 80.0
	_place_label(_dread_label, size.x, y)
	y += 56.0
	_buttons.position = Vector2(0, minf(y, size.y - 64.0))
	_buttons.size = Vector2(size.x, 56.0)


func _place_label(label: Label, width: float, y: float) -> void:
	label.position = Vector2(16, y)
	label.size = Vector2(width - 32.0, 0)


func _build_reel() -> void:
	_reel = (_world.call("roulette_reel_ids") as Array).duplicate() if _world != null else []
	if is_pending():
		_place_result_in_reel(String(_world.call("roulette_item")))
	_disc.icons = _reel_icons()
	_disc.queue_redraw()


func _place_result_in_reel(item_id: String) -> void:
	if item_id.is_empty():
		return
	_reel.erase(item_id)
	while _reel.size() < REEL_SIZE:
		_reel.append(item_id)
	_reel[_result_slot()] = item_id
	_disc.icons = _reel_icons()
	_disc.queue_redraw()


func _result_slot() -> int:
	var spins := int(_world.call("roulette_spins")) if _world != null else 0
	return posmod(spins * 3, REEL_SIZE)


func _reel_icons() -> Array:
	var out: Array = []
	for item_id in _reel:
		var item: Resource = _item(String(item_id))
		var icon: Texture2D = item.get("icon") as Texture2D if item != null else null
		out.append(ItemDef.texture_at_res(icon, SLICE_ICON_PX))
	return out


func _item(item_id: String) -> Resource:
	if _run == null or item_id.is_empty() or not _run.has_method("load_item"):
		return null
	return _run.call("load_item", item_id)


func _rest_rotation(slot: int) -> float:
	var seg := TAU / float(REEL_SIZE)
	return -(float(slot) + 0.5) * seg


func _show_offer() -> void:
	_name_label.text = ""
	_family_label.text = ""
	ItemDescFormat.set_text(_desc_label, "")
	_dread_label.text = ""
	_set_buttons([_spin_button, _leave_button])
	_spin_button.grab_focus()


func _show_result() -> void:
	var item_id := String(_world.call("roulette_item"))
	var item := _item(item_id)
	_name_label.text = ItemDef.rarity_name(item) if item != null else item_id
	_family_label.text = ItemDef.family_name(item) if item != null else ""
	ItemDescFormat.set_text(_desc_label, String(item.get("description")) if item != null else "")
	_desc_label.text = "[center]%s[/center]" % _desc_label.text
	var pct := 0
	if _run != null and _run.has_method("dread_for_item"):
		pct = int(round(float(_run.call("dread_for_item", item_id)) * 100.0))
	_dread_label.text = "+%d%% Dread" % pct if pct > 0 else ""
	var shown: Array = [_take_button]
	var tickets := int(_run.call("ticket_count")) if _run != null and _run.has_method("ticket_count") else 0
	if tickets > 0:
		_respin_button.text = "%s Respin (%d)" % [_reroll_key_text(), tickets]
		shown.append(_respin_button)
	_set_buttons(shown)
	_take_button.grab_focus()


func _set_buttons(shown: Array) -> void:
	for button in [_spin_button, _leave_button, _take_button, _respin_button]:
		button.visible = shown.has(button)
		button.disabled = false


func _hide_buttons() -> void:
	for button in [_spin_button, _leave_button, _take_button, _respin_button]:
		button.visible = false


func _reroll_key_text() -> String:
	for ev in InputMap.action_get_events("reroll"):
		if ev is InputEventKey:
			var key := ev as InputEventKey
			var code := key.physical_keycode if int(key.physical_keycode) != 0 else key.keycode
			return "[%s]" % OS.get_keycode_string(code)
	return "[F]"


func _on_spin() -> void:
	if _spinning or _closing or _world == null:
		return
	var item_id := String(_world.call("roulette_spin"))
	if item_id.is_empty():
		return
	_spin_to(item_id)


func _on_respin() -> void:
	if _spinning or _closing or _world == null or not is_pending():
		return
	var item_id := String(_world.call("roulette_respin"))
	if item_id.is_empty():
		return
	_spin_to(item_id)


func _spin_to(item_id: String) -> void:
	_spinning = true
	_hide_buttons()
	_name_label.text = ""
	_family_label.text = ""
	ItemDescFormat.set_text(_desc_label, "")
	_dread_label.text = ""
	_place_result_in_reel(item_id)
	var sfx := get_node_or_null("/root/AxelSfx")
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", &"spin")
	var start := _disc.rotation
	var rest := _rest_rotation(_result_slot())
	var target := start + TAU * float(SPIN_TURNS) + fposmod(rest - start, TAU)
	var tween := create_tween()
	tween.tween_property(_disc, "rotation", target, SPIN_SEC).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tween.finished
	_disc.rotation = fposmod(target, TAU)
	_spinning = false
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", &"line_win")
	_show_result()


func _on_take() -> void:
	if _spinning or _closing or _world == null:
		return
	if not bool(_world.call("roulette_take")):
		return
	_close()


func _on_leave() -> void:
	if _spinning or _closing or _world == null:
		return
	if not bool(_world.call("roulette_decline")):
		return
	_close()


func _close() -> void:
	_closing = true
	_hide_buttons()
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed("reroll"):
		if _respin_button.visible:
			_on_respin()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("back"):
		if _leave_button.visible:
			_on_leave()
		get_viewport().set_input_as_handled()


class RouletteDisc:
	extends Control

	var radius := 200.0
	var icons: Array = []

	func _draw() -> void:
		var count := maxi(icons.size(), 1)
		var seg := TAU / float(count)
		var center := Vector2.ONE * radius
		for i in count:
			var a0 := -PI * 0.5 + float(i) * seg
			var a1 := a0 + seg
			var points := PackedVector2Array([center])
			for step in 17:
				var a := lerpf(a0, a1, float(step) / 16.0)
				points.append(center + Vector2(cos(a), sin(a)) * radius)
			var fill := Color(0.32, 0.02, 0.02, 1) if i % 2 == 0 else Color(0.07, 0.065, 0.06, 1)
			draw_colored_polygon(points, fill)
			draw_line(center, center + Vector2(cos(a0), sin(a0)) * radius, Color(0.75, 0.05, 0.05, 1), 3.0)
			if i < icons.size() and icons[i] is Texture2D:
				var mid := a0 + seg * 0.5
				var icon_px := radius * 0.34
				var at := center + Vector2(cos(mid), sin(mid)) * radius * 0.64
				draw_set_transform(at, mid + PI * 0.5, Vector2.ONE)
				draw_texture_rect(icons[i] as Texture2D, Rect2(-Vector2.ONE * icon_px * 0.5, Vector2.ONE * icon_px), false)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_arc(center, radius, 0.0, TAU, 96, Color(0.75, 0.05, 0.05, 1), 5.0, true)
		draw_circle(center, radius * 0.12, Color(0.05, 0.05, 0.05, 1))
		draw_arc(center, radius * 0.12, 0.0, TAU, 48, Color(0.75, 0.05, 0.05, 1), 3.0, true)


class RoulettePointer:
	extends Control

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var points := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w * 0.5, h)])
		draw_colored_polygon(points, Color(1, 1, 1, 1))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color(0.75, 0.05, 0.05, 1), 3.0, true)
