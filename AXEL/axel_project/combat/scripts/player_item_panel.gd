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

var _list: VBoxContainer
var _fitting: bool = false


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
	for child in _list.get_children():
		child.queue_free()
	if items.is_empty():
		return
	for item in items:
		if item == null:
			continue
		_list.add_child(_make_row(item))
	call_deferred("_fit_row_names")


func _on_resized() -> void:
	if _fitting:
		return
	call_deferred("_fit_row_names")


func _text_col_width() -> float:
	return maxf(size.x - float(ICON_PX) - float(ROW_SEP) - NAME_RIGHT_PAD, 1.0)


func _make_row(item: Resource) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", ROW_SEP)
	var icon := TextureRect.new()
	icon.set_meta("item_row_icon", true)
	icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = ItemDefScript.texture_at_res(item.get("icon") as Texture2D, ICON_RES_PX)
	row.add_child(icon)
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.propagate_maximum_size = true
	text_col.add_theme_constant_override("separation", 2)
	row.add_child(text_col)
	var leftover := _text_col_width()
	var name_lab := Label.new()
	name_lab.set_meta("item_row_name", true)
	name_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lab.mouse_filter = Control.MOUSE_FILTER_STOP
	name_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lab.clip_text = false
	name_lab.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	name_lab.max_lines_visible = NAME_MAX_LINES
	name_lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lab.custom_maximum_size = Vector2(leftover, -1.0)
	name_lab.custom_minimum_size = Vector2(leftover, float(ICON_PX))
	name_lab.text = str(item.get("display_name"))
	name_lab.add_theme_font_override("font", VT323_FONT)
	name_lab.add_theme_font_size_override("font_size", BODY_FONT)
	name_lab.add_theme_color_override("font_color", NAME_COLOR)
	text_col.add_child(name_lab)
	var desc_lab := Label.new()
	desc_lab.set_meta("item_row_desc", true)
	desc_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lab.clip_text = false
	desc_lab.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	desc_lab.custom_maximum_size = Vector2(leftover, -1.0)
	var desc_val = item.get("description")
	desc_lab.text = str(desc_val).strip_edges() if desc_val != null else ""
	desc_lab.add_theme_font_override("font", VT323_FONT)
	desc_lab.add_theme_font_size_override("font_size", DESC_FONT)
	desc_lab.add_theme_color_override("font_color", DESC_COLOR)
	desc_lab.visible = false
	text_col.add_child(desc_lab)
	name_lab.mouse_entered.connect(func() -> void: _show_row_desc(desc_lab))
	name_lab.mouse_exited.connect(func() -> void: _hide_row_desc(desc_lab))
	return row


func _show_row_desc(desc_lab: Label) -> void:
	if desc_lab == null or not is_instance_valid(desc_lab):
		return
	desc_lab.visible = true
	call_deferred("_fit_row_names")


func _hide_row_desc(desc_lab: Label) -> void:
	if desc_lab == null or not is_instance_valid(desc_lab):
		return
	desc_lab.visible = false
	call_deferred("_fit_row_names")


func _fit_row_names() -> void:
	if _fitting or _list == null:
		return
	_fitting = true
	var inner := maxf(size.x, 64.0)
	if not is_equal_approx(_list.custom_maximum_size.x, inner):
		_list.custom_maximum_size = Vector2(inner, -1.0)
	var max_w := maxf(inner - float(ICON_PX) - float(ROW_SEP) - NAME_RIGHT_PAD, 1.0)
	for row in _list.get_children():
		if not row is HBoxContainer:
			continue
		_fit_text_labels(row, max_w)
	_fitting = false


func _fit_text_labels(node: Node, max_w: float) -> void:
	if node is VBoxContainer:
		var box := node as VBoxContainer
		box.propagate_maximum_size = true
		if not is_equal_approx(box.custom_maximum_size.x, max_w):
			box.custom_maximum_size = Vector2(max_w, -1.0)
	var lab := node as Label
	if lab != null and (
		bool(lab.get_meta("item_row_name", false)) or bool(lab.get_meta("item_row_desc", false))
	):
		if not is_equal_approx(lab.custom_maximum_size.x, max_w):
			lab.custom_maximum_size = Vector2(max_w, -1.0)
		var line_h := lab.get_line_height()
		if line_h <= 0:
			line_h = BODY_FONT if bool(lab.get_meta("item_row_name", false)) else DESC_FONT
		var lines := maxi(lab.get_line_count(), 1)
		if bool(lab.get_meta("item_row_name", false)):
			lines = clampi(lines, 1, NAME_MAX_LINES)
		var want_h := float(line_h * lines)
		if bool(lab.get_meta("item_row_name", false)):
			want_h = maxf(want_h, float(ICON_PX))
		if not is_equal_approx(lab.custom_minimum_size.x, max_w) or not is_equal_approx(lab.custom_minimum_size.y, want_h):
			lab.custom_minimum_size = Vector2(max_w, want_h)
	for child in node.get_children():
		_fit_text_labels(child, max_w)
