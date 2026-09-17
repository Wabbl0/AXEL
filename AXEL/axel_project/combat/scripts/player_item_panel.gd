extends PanelContainer

const VT323_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const ICON_PX := 48
const BODY_FONT := 32
const HINT_FONT := 29
const ROW_SEP := 8
const LIST_SEP := 10
const NAME_RIGHT_PAD := 8.0
const NAME_MAX_LINES := 2
const RARITY_COLORS := {
	0: Color(0.65, 0.65, 0.65),
	1: Color(0.4, 0.78, 0.4),
	2: Color(0.4, 0.6, 0.9),
	3: Color(0.72, 0.4, 0.88),
	4: Color(0.95, 0.75, 0.2),
}

var _list: VBoxContainer
var _hover: PanelContainer
var _hover_label: Label


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
	_ensure_hover()


func set_equipped_items(items: Array) -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	if items.is_empty():
		var empty := Label.new()
		empty.text = ""
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_list.add_child(empty)
		return
	for item in items:
		if item == null:
			continue
		_list.add_child(_make_row(item))
	call_deferred("_fit_row_names")


func _on_resized() -> void:
	call_deferred("_fit_row_names")


func _make_row(item: Resource) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", ROW_SEP)
	var rarity_idx: int = clampi(int(item.get("rarity")), 0, RARITY_COLORS.size() - 1)
	var icon := TextureRect.new()
	icon.set_meta("item_row_icon", true)
	icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = item.get("icon") as Texture2D
	row.add_child(icon)
	var name_lab := Label.new()
	name_lab.set_meta("item_row_name", true)
	name_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lab.clip_text = false
	name_lab.max_lines_visible = NAME_MAX_LINES
	name_lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lab.text = str(item.get("display_name"))
	name_lab.add_theme_font_override("font", VT323_FONT)
	name_lab.add_theme_font_size_override("font_size", BODY_FONT)
	name_lab.add_theme_color_override("font_color", RARITY_COLORS.get(rarity_idx, Color.WHITE))
	name_lab.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(name_lab)
	var desc_val = item.get("description")
	var desc := str(desc_val).strip_edges() if desc_val != null else ""
	row.set_meta("item_desc", desc)
	row.mouse_entered.connect(_on_row_entered.bind(row))
	row.mouse_exited.connect(_on_row_exited)
	icon.mouse_entered.connect(_on_row_entered.bind(row))
	icon.mouse_exited.connect(_on_row_exited)
	name_lab.mouse_entered.connect(_on_row_entered.bind(row))
	name_lab.mouse_exited.connect(_on_row_exited)
	return row


func _fit_row_names() -> void:
	if _list == null:
		return
	var inner := maxf(size.x, 64.0)
	_list.custom_maximum_size = Vector2(inner, -1.0)
	var max_w := maxf(inner - float(ICON_PX) - float(ROW_SEP) - NAME_RIGHT_PAD, 48.0)
	for row in _list.get_children():
		if not row is HBoxContainer:
			continue
		for child in row.get_children():
			var lab := child as Label
			if lab == null or not bool(lab.get_meta("item_row_name", false)):
				continue
			lab.custom_maximum_size = Vector2(max_w, -1.0)
			lab.size.x = max_w
			var line_h := lab.get_line_height()
			if line_h <= 0:
				line_h = BODY_FONT
			var lines := clampi(lab.get_line_count(), 1, NAME_MAX_LINES)
			lab.custom_minimum_size = Vector2(0.0, float(line_h * lines))


func _ensure_hover() -> void:
	_hover = PanelContainer.new()
	_hover.name = "ItemHover"
	_hover.visible = false
	_hover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover.z_index = 2
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.9)
	style.border_color = Color(0.45, 0.03, 0.03, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_hover.add_theme_stylebox_override("panel", style)
	_hover_label = Label.new()
	_hover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hover_label.clip_text = false
	_hover_label.add_theme_font_override("font", VT323_FONT)
	_hover_label.add_theme_font_size_override("font_size", HINT_FONT)
	_hover_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.82, 1.0))
	_hover_label.custom_maximum_size = Vector2(220, -1.0)
	_hover_label.custom_minimum_size = Vector2(220, 0)
	_hover.add_child(_hover_label)
	add_child(_hover)


func _on_row_entered(row: Control) -> void:
	var desc := str(row.get_meta("item_desc", "")).strip_edges()
	if desc.is_empty() or _hover == null:
		return
	_hover_label.text = desc
	_hover.visible = true
	_hover.reset_size()
	var local := get_local_mouse_position() + Vector2(12, 18)
	var max_x := maxf(size.x - _hover.size.x - 4.0, 0.0)
	var max_y := maxf(size.y - _hover.size.y - 4.0, 0.0)
	_hover.position = Vector2(clampf(local.x, 0.0, max_x), clampf(local.y, 0.0, max_y))


func _on_row_exited() -> void:
	if _hover != null:
		_hover.visible = false
