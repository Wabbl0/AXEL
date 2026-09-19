extends CanvasLayer

const CARD_LAYER := 109
const ICON_PX := 64.0
const NAME_FONT := 26
const DESC_FONT := 20
const CARD_WIDTH := 280.0
const CHIP_GAP_PX := 20.0
const WINDOW_PAD := 8.0
const ROW_SEP := 12.0
const PANEL_PAD_X := 24.0

var _root: Control
var _panel: PanelContainer
var _icon: TextureRect
var _text_col: VBoxContainer
var _name_label: Label
var _desc_label: Label
var _world_anchor := Vector2.ZERO
var _shown := false
var _chip_host: Node


func _ready() -> void:
	layer = CARD_LAYER
	follow_viewport_enabled = false
	_build()
	_apply_scale()
	get_viewport().size_changed.connect(_apply_scale)
	_root.visible = false
	set_process(false)


func bind_chip_host(host: Node) -> void:
	_chip_host = host


func _build() -> void:
	_root = Control.new()
	_root.name = "CardRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_panel = PanelContainer.new()
	_panel.name = "CardPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.72)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.290196, 0, 0, 0.85)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(ROW_SEP))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)

	_icon = TextureRect.new()
	_icon.name = "ItemIcon"
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)

	_text_col = VBoxContainer.new()
	_text_col.add_theme_constant_override("separation", 2)
	_text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_col.propagate_maximum_size = true
	row.add_child(_text_col)

	_name_label = Label.new()
	_name_label.name = "ItemName"
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MenuLook.apply_label(_name_label, NAME_FONT, MenuLook.ACCENT)
	_text_col.add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.name = "ItemDescription"
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MenuLook.apply_label(_desc_label, DESC_FONT, MenuLook.TEXT)
	_text_col.add_child(_desc_label)
	_apply_wrap_sizes(1.0)


func _text_wrap_width(f: float) -> float:
	var icon_w := ICON_PX * f
	if _icon != null and not _icon.visible:
		icon_w = 0.0
	var sep := ROW_SEP if icon_w > 0.0 else 0.0
	return maxf(CARD_WIDTH * f - icon_w - sep - PANEL_PAD_X, 80.0)


func _apply_wrap_sizes(f: float) -> void:
	var wrap_w := _text_wrap_width(f)
	if _name_label != null:
		_name_label.custom_maximum_size = Vector2(wrap_w, -1.0)
	if _desc_label != null:
		_desc_label.custom_minimum_size = Vector2(wrap_w, 0.0)
		_desc_label.custom_maximum_size = Vector2(wrap_w, -1.0)
	if _text_col != null:
		_text_col.custom_maximum_size = Vector2(wrap_w, -1.0)
	if _icon != null:
		_icon.custom_minimum_size = Vector2(ICON_PX * f, ICON_PX * f)
	if _panel != null:
		_panel.custom_maximum_size = Vector2(CARD_WIDTH * f, -1.0)


func _apply_scale() -> void:
	if _desc_label == null:
		return
	var f := UiViewportScale.factor(self)
	_name_label.add_theme_font_size_override("font_size", maxi(roundi(NAME_FONT * f), 10))
	_desc_label.add_theme_font_size_override("font_size", maxi(roundi(DESC_FONT * f), 10))
	_apply_wrap_sizes(f)
	if _shown:
		_update_screen_position()


func show_item(world_pos: Vector2, item_name: String, description: String, icon: Texture2D) -> void:
	_world_anchor = world_pos
	_name_label.text = item_name
	_desc_label.text = description
	_icon.texture = icon
	_icon.visible = icon != null
	_shown = true
	_root.visible = true
	set_process(true)
	_apply_scale()
	if _panel != null:
		_panel.reset_size()
	_update_screen_position()


func hide_card() -> void:
	_shown = false
	_root.visible = false
	set_process(false)


func is_card_visible() -> bool:
	return _shown and _root != null and _root.visible


func _process(_delta: float) -> void:
	if _shown:
		_update_screen_position()


func _chip_rect() -> Rect2:
	if is_instance_valid(_chip_host) and _chip_host.has_method("chip_screen_rect"):
		var rect: Variant = _chip_host.call("chip_screen_rect")
		if rect is Rect2 and (rect as Rect2).size.x > 1.0:
			return rect as Rect2
	var viewport := get_viewport()
	if viewport == null:
		return Rect2()
	var screen_pos := viewport.get_canvas_transform() * _world_anchor
	return Rect2(screen_pos - Vector2(18.0, 18.0), Vector2(36.0, 36.0))


func _update_screen_position() -> void:
	var viewport := get_viewport()
	if viewport == null or _panel == null or _root == null:
		return
	var chip := _chip_rect()
	if _panel.size.x <= 0.0 or _panel.size.y <= 0.0:
		_panel.reset_size()
	var card_size := _panel.size
	if card_size.x <= 0.0 or card_size.y <= 0.0:
		card_size = _panel.get_combined_minimum_size()
	var card_w := card_size.x
	var card_h := card_size.y
	var gap := CHIP_GAP_PX * UiViewportScale.factor(self)
	var pos := Vector2(chip.get_center().x - card_w * 0.5, chip.end.y + gap)
	var view_size := Vector2(viewport.get_visible_rect().size)
	if pos.y + card_h > view_size.y:
		pos.y = chip.position.y - gap - card_h
	pos.x = clampf(pos.x, WINDOW_PAD, maxf(view_size.x - card_w - WINDOW_PAD, WINDOW_PAD))
	pos.y = clampf(pos.y, WINDOW_PAD, maxf(view_size.y - card_h - WINDOW_PAD, WINDOW_PAD))
	_root.position = pos
	_root.size = card_size
