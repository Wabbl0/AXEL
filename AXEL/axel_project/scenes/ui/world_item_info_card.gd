extends CanvasLayer

const CARD_LAYER := 109
const ICON_PX := 64.0
const NAME_FONT := 26
const DESC_FONT := 20
const CARD_WIDTH := 520.0
const LIFT_PX := 150.0

var _root: Control
var _panel: PanelContainer
var _icon: TextureRect
var _name_label: Label
var _desc_label: Label
var _world_anchor := Vector2.ZERO
var _shown := false


func _ready() -> void:
	layer = CARD_LAYER
	follow_viewport_enabled = false
	_build()
	_apply_scale()
	get_viewport().size_changed.connect(_apply_scale)
	_root.visible = false
	set_process(false)


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
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)

	_icon = TextureRect.new()
	_icon.name = "ItemIcon"
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)

	var text_col := VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 2)
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_col)

	_name_label = Label.new()
	_name_label.name = "ItemName"
	MenuLook.apply_label(_name_label, NAME_FONT, MenuLook.ACCENT)
	text_col.add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.name = "ItemDescription"
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MenuLook.apply_label(_desc_label, DESC_FONT, MenuLook.TEXT)
	text_col.add_child(_desc_label)


func _apply_scale() -> void:
	if _desc_label == null:
		return
	var f := UiViewportScale.factor(self)
	_name_label.add_theme_font_size_override("font_size", maxi(roundi(NAME_FONT * f), 10))
	_desc_label.add_theme_font_size_override("font_size", maxi(roundi(DESC_FONT * f), 10))
	_desc_label.custom_minimum_size = Vector2(CARD_WIDTH * f, 0.0)
	_icon.custom_minimum_size = Vector2(ICON_PX * f, ICON_PX * f)
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


func _update_screen_position() -> void:
	var viewport := get_viewport()
	if viewport == null or _panel == null:
		return
	var screen_pos := viewport.get_canvas_transform() * _world_anchor
	var card_size := _panel.size
	if card_size.x <= 0.0 or card_size.y <= 0.0:
		card_size = _panel.get_combined_minimum_size()
	var lift := LIFT_PX * UiViewportScale.factor(self)
	var pos := screen_pos - Vector2(card_size.x * 0.5, card_size.y + lift)

	var view_size := Vector2(viewport.get_visible_rect().size)
	pos.x = clampf(pos.x, 8.0, maxf(view_size.x - card_size.x - 8.0, 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(view_size.y - card_size.y - 8.0, 8.0))
	_root.position = pos
