extends PanelContainer

const VT323_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const ItemDefScript := preload("res://combat/scripts/item_def.gd")
const ICON_PX := 144
const ICON_RES_PX := 120
const BODY_FONT := 84
const DESC_FONT := 48
const ROW_SEP := 8
const LIST_SEP := 10
const NAME_RIGHT_PAD := 8.0
const NAME_MAX_LINES := 2
const NAME_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DESC_COLOR := Color(1.0, 1.0, 1.0, 0.75)
const DESC_BG := Color(0.25, 0.0, 0.0, 0.45)
const DESC_MARGIN_L := 8.0
const DESC_MARGIN_R := 8.0
const DESC_MARGIN_T := 4.0
const DESC_MARGIN_B := 4.0
const DESC_UNDER_TITLE_PX := 8.0
const PULSE_SCALE := 1.12
const PULSE_SEC := 0.22

var _list: VBoxContainer
var _fitting: bool = false
var _desc_text_w := 0.0
var _icons: Dictionary = {}
var _pulse_counts: Dictionary = {}
var _pulse_tweens: Dictionary = {}
var _pending_pulses: Array[String] = []


func _ready() -> void:
	name = "PlayerItemPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.propagate_maximum_size = true
	_list.add_theme_constant_override("separation", LIST_SEP)
	scroll.add_child(_list)


func set_equipped_items(items: Array) -> void:
	if _list == null:
		return
	_icons.clear()
	for child in _list.get_children():
		child.queue_free()
	if items.is_empty():
		return
	for item in items:
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
	icon.pivot_offset = Vector2(ICON_PX, ICON_PX) * 0.5
	var tw := CombatPace.bind(create_tween())
	_pulse_tweens[item_id] = tw
	tw.tween_property(icon, "scale", Vector2(PULSE_SCALE, PULSE_SCALE), PULSE_SEC * 0.45)
	tw.parallel().tween_property(icon, "modulate", Color(1.35, 0.9, 0.9, 1.0), PULSE_SEC * 0.45)
	tw.tween_property(icon, "scale", Vector2.ONE, PULSE_SEC * 0.55)
	tw.parallel().tween_property(icon, "modulate", Color.WHITE, PULSE_SEC * 0.55)


func pulse_play_count(item_id: String) -> int:
	return int(_pulse_counts.get(item_id, 0))


func _on_resized() -> void:
	if _fitting:
		return
	call_deferred("_fit_row_names")


func _text_col_width() -> float:
	return maxf(size.x - float(ICON_PX) - float(ROW_SEP) - NAME_RIGHT_PAD, 1.0)


func _make_row(item: Resource) -> Control:
	var row := Control.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, ICON_PX)
	var icon := TextureRect.new()
	icon.set_meta("item_row_icon", true)
	icon.position = Vector2.ZERO
	icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	icon.size = Vector2(ICON_PX, ICON_PX)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = ItemDefScript.texture_at_res(item.get("icon") as Texture2D, ICON_RES_PX)
	row.add_child(icon)
	var item_id := str(item.get("id"))
	icon.set_meta("item_id", item_id)
	_icons[item_id] = icon
	var leftover := _text_col_width()
	var name_lab := Label.new()
	name_lab.set_meta("item_row_name", true)
	name_lab.position = Vector2(float(ICON_PX) + float(ROW_SEP), 0.0)
	name_lab.size = Vector2(leftover, float(ICON_PX))
	name_lab.mouse_filter = Control.MOUSE_FILTER_STOP
	name_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lab.clip_text = false
	name_lab.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	name_lab.max_lines_visible = NAME_MAX_LINES
	name_lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lab.custom_maximum_size = Vector2(leftover, float(ICON_PX))
	name_lab.custom_minimum_size = Vector2(leftover, float(ICON_PX))
	name_lab.text = str(item.get("display_name"))
	name_lab.add_theme_font_override("font", VT323_FONT)
	name_lab.add_theme_font_size_override("font_size", BODY_FONT)
	name_lab.add_theme_color_override("font_color", NAME_COLOR)
	row.add_child(name_lab)
	var desc_panel := PanelContainer.new()
	desc_panel.set_meta("item_row_desc_panel", true)
	desc_panel.visible = false
	desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_panel.z_index = 4
	var style := StyleBoxFlat.new()
	style.bg_color = DESC_BG
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
	return row


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
	var max_w := maxf(inner - float(ICON_PX) - float(ROW_SEP) - NAME_RIGHT_PAD, 1.0)
	var room := max_w + NAME_RIGHT_PAD
	var text_cap := maxf(room - DESC_MARGIN_L - DESC_MARGIN_R, 1.0)
	_desc_text_w = _shared_desc_width(text_cap)
	for row in _list.get_children():
		if not row is Control:
			continue
		_fit_row(row as Control, max_w)
	_fitting = false


func _fit_row(row: Control, max_w: float) -> void:
	row.custom_minimum_size = Vector2(0, ICON_PX)
	var name_lab: Label = null
	var desc_panel: PanelContainer = null
	for child in row.get_children():
		var lab := child as Label
		if lab != null and bool(lab.get_meta("item_row_name", false)):
			name_lab = lab
			lab.position = Vector2(float(ICON_PX) + float(ROW_SEP), 0.0)
			lab.custom_maximum_size = Vector2(max_w, float(ICON_PX))
			lab.custom_minimum_size = Vector2(max_w, float(ICON_PX))
			lab.size = Vector2(max_w, float(ICON_PX))
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
	desc_panel.position = Vector2(
		name_lab.position.x,
		name_lab.position.y + _title_text_bottom(name_lab) + DESC_UNDER_TITLE_PX
	)


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
