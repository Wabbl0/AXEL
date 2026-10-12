extends PanelContainer

signal order_changed(item_ids: Array)

const VT323_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const ItemDefScript := preload("res://combat/scripts/item_def.gd")
const ICON_PX := 144
const ICON_RES_PX := 120
const BODY_FONT := 84
const DESC_FONT := 58
const ROW_SEP := 8
const LIST_SEP := 10
const NAME_RIGHT_PAD := 8.0
const NAME_MAX_LINES := 2
const NAME_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DESC_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DESC_BG := Color(0.1, 0.0, 0.0, 0.96)
const DESC_BORDER := Color(0.6, 0.05, 0.05, 1.0)
const DESC_BORDER_PX := 2
const DESC_Z := 60
const DESC_MARGIN_L := 8.0
const DESC_MARGIN_R := 8.0
const DESC_MARGIN_T := 4.0
const DESC_MARGIN_B := 4.0
const DESC_UNDER_TITLE_PX := 8.0
const PULSE_SCALE := 1.35
const PULSE_SEC := 0.45
const PULSE_ICON_COLOR := Color(1.8, 1.25, 1.25, 1.0)
const PULSE_BACK_COLOR := Color(0.85, 0.0, 0.0, 0.55)
const COUNT_FONT := 60
const COUNT_COLOR := Color(1.0, 1.0, 1.0, 0.6)
const COUNT_MIN_ITEMS := 3
const FIT_ROWS := 7
const MIN_ROW_PX := 72.0
const DESC_VIEW_PAD := 8.0
const DROP_LINE_PX := 4.0

var _list: VBoxContainer
var _fitting: bool = false
var _desc_text_w := 0.0
var _icons: Dictionary = {}
var _count_label: Label
var _slot_cap := 0
var _item_count := 0
var _pulse_counts: Dictionary = {}
var _pulse_tweens: Dictionary = {}
var _pending_pulses: Array[String] = []
var _scroll: ScrollContainer
var _row_h := float(ICON_PX)
var _order: PackedStringArray = PackedStringArray()
var _drop_line: ColorRect
var reorder_enabled := true


func _ready() -> void:
	name = "PlayerItemPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	var body := VBoxContainer.new()
	body.name = "Body"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 4)
	add_child(body)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll = scroll
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.propagate_maximum_size = true
	_list.add_theme_constant_override("separation", LIST_SEP)
	scroll.add_child(_list)
	_count_label = Label.new()
	_count_label.name = "SlotCount"
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_count_label.add_theme_font_override("font", VT323_FONT)
	_count_label.add_theme_font_size_override("font_size", COUNT_FONT)
	_count_label.add_theme_color_override("font_color", COUNT_COLOR)
	_count_label.visible = false
	body.add_child(_count_label)
	_drop_line = ColorRect.new()
	_drop_line.name = "DropLine"
	_drop_line.top_level = true
	_drop_line.z_as_relative = false
	_drop_line.z_index = DESC_Z
	_drop_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drop_line.color = DESC_BORDER
	_drop_line.visible = false
	add_child(_drop_line)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _drop_line != null:
		_drop_line.visible = false


func row_height() -> float:
	return _row_h


func set_order(item_ids: PackedStringArray) -> void:
	_order = item_ids.duplicate()


func current_order() -> Array:
	var out: Array = []
	if _list == null:
		return out
	for row in _list.get_children():
		var item_id := String(row.get_meta("item_id", ""))
		if not item_id.is_empty():
			out.append(item_id)
	return out


func _sorted_items(items: Array) -> Array:
	if _order.is_empty():
		return items
	var known: Array = []
	var rest: Array = []
	for item in items:
		if item == null:
			continue
		if _order.has(str(item.get("id"))):
			known.append(item)
		else:
			rest.append(item)
	known.sort_custom(func(a: Resource, b: Resource) -> bool: return _order.find(str(a.get("id"))) < _order.find(str(b.get("id"))))
	return known + rest


func set_slot_cap(cap: int) -> void:
	_slot_cap = maxi(cap, 0)
	if _scroll != null:
		_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if _slot_cap > FIT_ROWS else ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_refresh_count()


func _refresh_count() -> void:
	if _count_label == null:
		return
	_count_label.visible = _slot_cap > 0 and _item_count >= COUNT_MIN_ITEMS
	_count_label.text = "%d / %d" % [_item_count, _slot_cap]


func set_equipped_items(items: Array) -> void:
	if _list == null:
		return
	_icons.clear()
	for child in _list.get_children():
		child.queue_free()
	_item_count = 0
	for item in items:
		if item != null:
			_item_count += 1
	_refresh_count()
	if items.is_empty():
		return
	_row_h = _fit_row_height()
	for item in _sorted_items(items):
		if item == null:
			continue
		_list.add_child(_make_row(item))
	call_deferred("_fit_row_names")
	_play_pending_pulses()


func _play_pending_pulses() -> void:
	if _pending_pulses.is_empty():
		return
	var ids := _pending_pulses.duplicate()
	_pending_pulses.clear()
	for item_id in ids:
		if _icons.has(item_id):
			pulse_item(item_id)


func pulse_items(item_ids: Array) -> void:
	for item_id in item_ids:
		pulse_item(String(item_id))


func pulse_item(item_id: String) -> void:
	var icon: TextureRect = _icons.get(item_id) as TextureRect
	if icon == null or not is_instance_valid(icon):
		if not _pending_pulses.has(item_id):
			_pending_pulses.append(item_id)
		return
	_pulse_counts[item_id] = int(_pulse_counts.get(item_id, 0)) + 1
	var existing: Tween = _pulse_tweens.get(item_id) as Tween
	if existing != null and existing.is_valid():
		existing.kill()
	icon.scale = Vector2.ONE
	icon.modulate = Color.WHITE
	icon.pivot_offset = icon.size * 0.5
	var row := icon.get_parent()
	var back := row.get_node_or_null("PulseBack") as ColorRect
	if back != null:
		back.color = Color(PULSE_BACK_COLOR, 0.0)
	var tw := CombatPace.bind(create_tween())
	_pulse_tweens[item_id] = tw
	tw.tween_property(icon, "scale", Vector2(PULSE_SCALE, PULSE_SCALE), PULSE_SEC * 0.3)
	tw.parallel().tween_property(icon, "modulate", PULSE_ICON_COLOR, PULSE_SEC * 0.3)
	if back != null:
		tw.parallel().tween_property(back, "color", PULSE_BACK_COLOR, PULSE_SEC * 0.3)
	tw.tween_property(icon, "scale", Vector2.ONE, PULSE_SEC * 0.7)
	tw.parallel().tween_property(icon, "modulate", Color.WHITE, PULSE_SEC * 0.7)
	if back != null:
		tw.parallel().tween_property(back, "color", Color(PULSE_BACK_COLOR, 0.0), PULSE_SEC * 0.7)


func pulse_play_count(item_id: String) -> int:
	return int(_pulse_counts.get(item_id, 0))


func _on_resized() -> void:
	if _fitting:
		return
	call_deferred("_fit_row_names")


func _text_col_width() -> float:
	return maxf(size.x - _row_h - float(ROW_SEP) - NAME_RIGHT_PAD, 1.0)


func _fit_row_height() -> float:
	var avail := 0.0
	if _scroll != null:
		avail = _scroll.size.y
	if avail <= 1.0:
		avail = size.y
		if _count_label != null and _count_label.visible:
			avail -= _count_label.get_combined_minimum_size().y + 4.0
	if avail <= 1.0:
		return float(ICON_PX)
	var fit := floorf((avail - float(LIST_SEP) * float(FIT_ROWS - 1)) / float(FIT_ROWS))
	return clampf(fit, MIN_ROW_PX, float(ICON_PX))


func _name_font_size() -> int:
	return maxi(int(round(float(BODY_FONT) * _row_h / float(ICON_PX))), 24)


func _make_row(item: Resource) -> Control:
	var row := Control.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, _row_h)
	var back := ColorRect.new()
	back.name = "PulseBack"
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.color = Color(PULSE_BACK_COLOR, 0.0)
	back.position = Vector2.ZERO
	back.size = Vector2(_row_h, _row_h)
	row.add_child(back)
	var icon := TextureRect.new()
	icon.set_meta("item_row_icon", true)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2.ZERO
	icon.custom_minimum_size = Vector2(_row_h, _row_h)
	icon.size = Vector2(_row_h, _row_h)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = ItemDefScript.texture_at_res(item.get("icon") as Texture2D, ICON_RES_PX)
	row.add_child(icon)
	var item_id := str(item.get("id"))
	icon.set_meta("item_id", item_id)
	row.set_meta("item_id", item_id)
	_icons[item_id] = icon
	var leftover := _text_col_width()
	var name_lab := Label.new()
	name_lab.set_meta("item_row_name", true)
	name_lab.position = Vector2(_row_h + float(ROW_SEP), 0.0)
	name_lab.size = Vector2(leftover, _row_h)
	name_lab.mouse_filter = Control.MOUSE_FILTER_STOP
	name_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lab.clip_text = false
	name_lab.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	name_lab.max_lines_visible = NAME_MAX_LINES
	name_lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lab.custom_maximum_size = Vector2(leftover, _row_h)
	name_lab.custom_minimum_size = Vector2(leftover, _row_h)
	name_lab.text = str(item.get("display_name"))
	name_lab.add_theme_font_override("font", VT323_FONT)
	name_lab.add_theme_font_size_override("font_size", _name_font_size())
	name_lab.add_theme_color_override("font_color", NAME_COLOR)
	row.add_child(name_lab)
	var desc_panel := PanelContainer.new()
	desc_panel.set_meta("item_row_desc_panel", true)
	desc_panel.visible = false
	desc_panel.top_level = true
	desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_panel.z_as_relative = false
	desc_panel.z_index = DESC_Z
	var style := StyleBoxFlat.new()
	style.bg_color = DESC_BG
	style.border_color = DESC_BORDER
	style.set_border_width_all(DESC_BORDER_PX)
	style.content_margin_left = DESC_MARGIN_L
	style.content_margin_right = DESC_MARGIN_R
	style.content_margin_top = DESC_MARGIN_T
	style.content_margin_bottom = DESC_MARGIN_B
	desc_panel.add_theme_stylebox_override("panel", style)
	var desc_lab := Label.new()
	desc_lab.set_meta("item_row_desc", true)
	desc_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lab.custom_maximum_size = Vector2(leftover, -1.0)
	var desc_val = item.get("description")
	desc_lab.text = str(desc_val).strip_edges() if desc_val != null else ""
	desc_lab.add_theme_font_override("font", VT323_FONT)
	desc_lab.add_theme_font_size_override("font_size", DESC_FONT)
	desc_lab.add_theme_color_override("font_color", DESC_COLOR)
	desc_lab.visible = false
	desc_panel.add_child(desc_lab)
	row.add_child(desc_panel)
	name_lab.mouse_entered.connect(func() -> void: _show_row_desc(desc_panel, name_lab))
	name_lab.mouse_exited.connect(func() -> void: _hide_row_desc(desc_panel))
	row.set_drag_forwarding(_drag_row.bind(row), _can_drop_row.bind(row), _drop_row.bind(row))
	name_lab.set_drag_forwarding(_drag_row.bind(row), _can_drop_row.bind(row), _drop_row.bind(row))
	return row


func _drag_row(_at: Vector2, row: Control) -> Variant:
	if not reorder_enabled or _list == null or _list.get_child_count() < 2:
		return null
	var item_id := String(row.get_meta("item_id", ""))
	if item_id.is_empty():
		return null
	var icon := _icons.get(item_id) as TextureRect
	if icon != null and is_instance_valid(icon):
		var preview := TextureRect.new()
		preview.texture = icon.texture
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		preview.size = icon.size * icon.get_global_transform_with_canvas().get_scale()
		preview.modulate = Color(1.0, 1.0, 1.0, 0.75)
		set_drag_preview(preview)
	for other in _list.get_children():
		for child in other.get_children():
			var panel := child as PanelContainer
			if panel != null and bool(panel.get_meta("item_row_desc_panel", false)):
				_hide_row_desc(panel)
	return {"item_box_row": item_id}


func _can_drop_row(at: Vector2, data: Variant, row: Control) -> bool:
	if not reorder_enabled or not (data is Dictionary) or not (data as Dictionary).has("item_box_row"):
		return false
	_show_drop_line(row, at.y >= _row_h * 0.5)
	return true


func _drop_row(at: Vector2, data: Variant, row: Control) -> void:
	if _drop_line != null:
		_drop_line.visible = false
	if not reorder_enabled or not (data is Dictionary) or not (data as Dictionary).has("item_box_row"):
		return
	var moving_id := String((data as Dictionary)["item_box_row"])
	var moving: Control = null
	for child in _list.get_children():
		if String(child.get_meta("item_id", "")) == moving_id:
			moving = child as Control
	if moving == null or moving == row:
		return
	var target := row.get_index()
	if at.y >= _row_h * 0.5:
		target += 1
	if moving.get_index() < target:
		target -= 1
	_list.move_child(moving, target)
	_order = PackedStringArray(current_order())
	order_changed.emit(current_order())


func _show_drop_line(row: Control, after: bool) -> void:
	if _drop_line == null:
		return
	var xf := row.get_global_transform()
	var local_y := _row_h + float(LIST_SEP) * 0.5 if after else -float(LIST_SEP) * 0.5
	var s := xf.get_scale()
	_drop_line.scale = s
	_drop_line.size = Vector2(row.size.x, DROP_LINE_PX)
	_drop_line.global_position = xf * Vector2(0.0, local_y) - Vector2(0.0, DROP_LINE_PX * s.y * 0.5)
	_drop_line.visible = true


func _show_row_desc(desc_panel: PanelContainer, name_lab: Label) -> void:
	if desc_panel == null or not is_instance_valid(desc_panel):
		return
	if _desc_text_w > 1.0:
		_apply_desc_box(desc_panel, _desc_text_w)
	_place_desc_panel(desc_panel, name_lab)
	desc_panel.visible = true
	for child in desc_panel.get_children():
		child.visible = true


func _hide_row_desc(desc_panel: PanelContainer) -> void:
	if desc_panel == null or not is_instance_valid(desc_panel):
		return
	desc_panel.visible = false
	for child in desc_panel.get_children():
		child.visible = false


func _fit_row_names() -> void:
	if _fitting or _list == null:
		return
	_fitting = true
	var inner := maxf(size.x, 64.0)
	if not is_equal_approx(_list.custom_maximum_size.x, inner):
		_list.custom_maximum_size = Vector2(inner, -1.0)
	_row_h = _fit_row_height()
	var max_w := maxf(inner - _row_h - float(ROW_SEP) - NAME_RIGHT_PAD, 1.0)
	var room := max_w + NAME_RIGHT_PAD
	var text_cap := maxf(room - DESC_MARGIN_L - DESC_MARGIN_R, 1.0)
	_desc_text_w = _shared_desc_width(text_cap)
	for row in _list.get_children():
		if not row is Control:
			continue
		_fit_row(row as Control, max_w)
	_fitting = false


func _fit_row(row: Control, max_w: float) -> void:
	row.custom_minimum_size = Vector2(0, _row_h)
	var name_lab: Label = null
	var desc_panel: PanelContainer = null
	for child in row.get_children():
		var icon := child as TextureRect
		if icon != null and bool(icon.get_meta("item_row_icon", false)):
			icon.custom_minimum_size = Vector2(_row_h, _row_h)
			icon.size = Vector2(_row_h, _row_h)
		var back := child as ColorRect
		if back != null and back.name == "PulseBack":
			back.position = Vector2.ZERO
			back.size = Vector2(_row_h, _row_h)
		var lab := child as Label
		if lab != null and bool(lab.get_meta("item_row_name", false)):
			name_lab = lab
			lab.add_theme_font_size_override("font_size", _name_font_size())
			lab.position = Vector2(_row_h + float(ROW_SEP), 0.0)
			lab.custom_maximum_size = Vector2(max_w, _row_h)
			lab.custom_minimum_size = Vector2(max_w, _row_h)
			lab.size = Vector2(max_w, _row_h)
		var panel := child as PanelContainer
		if panel != null and bool(panel.get_meta("item_row_desc_panel", false)):
			desc_panel = panel
	if desc_panel != null and _desc_text_w > 1.0:
		_apply_desc_box(desc_panel, _desc_text_w)
		if name_lab != null:
			_place_desc_panel(desc_panel, name_lab)


func _shared_desc_width(text_cap: float) -> float:
	var widest := 0.0
	for row in _list.get_children():
		var desc := _row_desc_label(row)
		if desc == null:
			continue
		var text := desc.text.strip_edges()
		if text.is_empty():
			continue
		widest = maxf(widest, _widest_line(text, text_cap))
	if widest <= 1.0:
		return text_cap
	return minf(ceilf(widest + 1.0), text_cap)


func _widest_line(text: String, wrap_w: float) -> float:
	var para := _desc_paragraph(text, wrap_w)
	var widest := 0.0
	for i in para.get_line_count():
		widest = maxf(widest, para.get_line_size(i).x)
	return widest


func _desc_paragraph(text: String, wrap_w: float) -> TextParagraph:
	var para := TextParagraph.new()
	para.width = maxf(wrap_w, 1.0)
	para.add_string(text, VT323_FONT, DESC_FONT)
	return para


func _apply_desc_box(panel: PanelContainer, text_w: float) -> void:
	var desc := _row_desc_label(panel)
	if desc == null:
		return
	var inner_w := maxf(text_w, 1.0)
	desc.custom_minimum_size = Vector2(inner_w, 0.0)
	desc.custom_maximum_size = Vector2(inner_w, -1.0)
	var block_h := _desc_paragraph(desc.text, inner_w).get_size().y
	var outer := Vector2(
		inner_w + DESC_MARGIN_L + DESC_MARGIN_R,
		maxf(block_h, 1.0) + DESC_MARGIN_T + DESC_MARGIN_B
	)
	panel.custom_minimum_size = outer
	panel.size = outer


func _place_desc_panel(desc_panel: PanelContainer, name_lab: Label) -> void:
	if not name_lab.is_inside_tree():
		return
	var xf := name_lab.get_global_transform()
	var s := xf.get_scale()
	desc_panel.scale = s
	var pos := xf * Vector2(0.0, _title_text_bottom(name_lab) + DESC_UNDER_TITLE_PX)
	var panel_h := desc_panel.size.y * s.y
	var view := _view_rect_canvas()
	if pos.y + panel_h > view.end.y - DESC_VIEW_PAD:
		var row_top := (xf * Vector2.ZERO).y
		pos.y = maxf(row_top - DESC_UNDER_TITLE_PX * s.y - panel_h, view.position.y + DESC_VIEW_PAD)
	var panel_w := desc_panel.size.x * s.x
	pos.x = clampf(pos.x, view.position.x + DESC_VIEW_PAD, maxf(view.end.x - DESC_VIEW_PAD - panel_w, view.position.x + DESC_VIEW_PAD))
	desc_panel.global_position = pos


func _view_rect_canvas() -> Rect2:
	var vp := get_viewport_rect()
	var inv := get_canvas_transform().affine_inverse()
	var a := inv * vp.position
	var b := inv * vp.end
	return Rect2(a, b - a).abs()


func _title_text_bottom(name_lab: Label) -> float:
	var count := name_lab.get_total_character_count()
	var bottom := 0.0
	var found := false
	for i in count:
		var bounds := name_lab.get_character_bounds(i)
		if bounds.size.x <= 0.0 and bounds.size.y <= 0.0:
			continue
		bottom = maxf(bottom, bounds.end.y)
		found = true
	if found:
		return bottom
	var font := name_lab.get_theme_font("font")
	var font_size := name_lab.get_theme_font_size("font_size")
	if font == null or font_size <= 0:
		return name_lab.size.y
	var para := TextParagraph.new()
	para.width = maxf(name_lab.size.x, 1.0)
	para.add_string(name_lab.text, font, font_size)
	var block_h := para.get_size().y
	if name_lab.max_lines_visible > 0:
		var line_h := font.get_height(font_size)
		block_h = minf(block_h, line_h * float(name_lab.max_lines_visible))
	var top := maxf((name_lab.size.y - block_h) * 0.5, 0.0)
	return top + block_h


func _row_desc_label(node: Node) -> Label:
	if node == null:
		return null
	for child in node.get_children():
		var lab := child as Label
		if lab != null and bool(lab.get_meta("item_row_desc", false)):
			return lab
		var nested := _row_desc_label(child)
		if nested != null:
			return nested
	return null
