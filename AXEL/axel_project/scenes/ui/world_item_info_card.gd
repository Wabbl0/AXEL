extends CanvasLayer

const CrtPowerFx = preload("res://scenes/ui/crt_power_fx.gd")

const CARD_LAYER := 109
const HOVER_LAYER := 110
const ICON_PX := 96.0
const NAME_FONT := 34
const DESC_FONT := 28
const DESC_MIN_W := 380.0
const KEY_TEXT := "[E]"
const ITEMS_INDICATOR_GAP_PX := 10.0
const WINDOW_PAD := 8.0
const SCREEN_CORNER_GAP := 6.0
const ROW_SEP := 12.0

var _root: Control
var _panel: PanelContainer
var _beam: ColorRect
var _bloom: ColorRect
var _icon: TextureRect
var _text_col: VBoxContainer
var _name_label: Label
var _desc_label: RichTextLabel
var _key_label: Label
var _world_anchor := Vector2.ZERO
var _anchor: Node
var _screen_lock := false
var _screen_pos := Vector2.ZERO
var _shown := false
var _crt_settled := false
var _anim_token := 0


func _ready() -> void:
	layer = CARD_LAYER
	follow_viewport_enabled = false
	_build()
	_apply_scale()
	get_viewport().size_changed.connect(_apply_scale)
	_root.visible = false
	_root.modulate.a = 0.0
	set_process(false)
	CrtPowerFx.reset_visual(_root, _panel, _beam, _bloom)
	tree_exiting.connect(_on_tree_exiting)


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

	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_beam = ColorRect.new()
	_beam.name = "PowerBeam"
	_beam.color = Color(1, 1, 1, 1)
	_beam.modulate = Color(1, 1, 1, 0)
	_beam.material = add
	_beam.z_index = 2
	_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_beam)

	var row := HBoxContainer.new()
	row.name = "CardRow"
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
	_text_col.name = "CardText"
	_text_col.add_theme_constant_override("separation", 2)
	_text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_text_col)

	_name_label = Label.new()
	_name_label.name = "ItemName"
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	MenuLook.apply_label(_name_label, NAME_FONT, MenuLook.ACCENT)
	_text_col.add_child(_name_label)

	_desc_label = ItemDescFormat.make_label("ItemDescription", DESC_FONT, DESC_MIN_W)
	_text_col.add_child(_desc_label)

	_key_label = Label.new()
	_key_label.name = "ItemKey"
	_key_label.text = KEY_TEXT
	_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuLook.apply_label(_key_label, DESC_FONT, MenuLook.TEXT)
	_text_col.add_child(_key_label)

	_bloom = ColorRect.new()
	_bloom.name = "Bloom"
	_bloom.color = Color(1, 0, 0, 1)
	_bloom.modulate = Color(1, 1, 1, 0)
	_bloom.material = add
	_bloom.z_index = 3
	_bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_bloom)
	_set_ignore_mouse_recursive(self)


func _title_px() -> float:
	if _name_label == null:
		return 32.0
	var font := _name_label.get_theme_font("font")
	if font == null:
		return 32.0
	var px := _name_label.get_theme_font_size("font_size")
	return maxf(font.get_string_size(_name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x, 32.0)


func _apply_wrap_sizes(f: float) -> void:
	var title_w := _title_px()
	var text_w := maxf(title_w, DESC_MIN_W * f)
	if _name_label != null:
		_name_label.custom_minimum_size = Vector2(title_w, 0.0)
	if _desc_label != null:
		ItemDescFormat.apply_size(_desc_label, _desc_label.get_theme_font_size("normal_font_size"), text_w)
	if _icon != null:
		var icon_px := ICON_PX * f
		_icon.custom_minimum_size = Vector2(icon_px, icon_px)


func _apply_scale() -> void:
	if _desc_label == null:
		return
	var f := UiViewportScale.factor(self)
	var name_px := maxi(roundi(NAME_FONT * f), 10)
	var desc_px := maxi(roundi(DESC_FONT * f), 10)
	_name_label.add_theme_font_size_override("font_size", name_px)
	_desc_label.add_theme_font_size_override("normal_font_size", desc_px)
	if _key_label != null:
		_key_label.add_theme_font_size_override("font_size", desc_px)
	_apply_wrap_sizes(f)
	if _shown:
		_refresh_panel_size()
		_update_screen_position()


func show_item(
	world_pos: Vector2,
	item_name: String,
	description: String,
	icon: Texture2D,
	anchor: Node = null,
) -> void:
	_screen_lock = false
	layer = CARD_LAYER
	_world_anchor = world_pos
	_anchor = anchor
	_apply_payload(item_name, description, icon, true)
	_reveal()


func nudge_screen_item(screen_pos: Vector2) -> void:
	if not _screen_lock or not _shown:
		return
	_screen_pos = screen_pos
	_update_screen_position()


func show_screen_item(
	screen_pos: Vector2,
	item_name: String,
	description: String,
	icon: Texture2D,
) -> void:
	_screen_lock = true
	_screen_pos = screen_pos
	_anchor = null
	layer = HOVER_LAYER
	_apply_payload(item_name, description, icon, false)
	_reveal()


func _apply_payload(item_name: String, description: String, icon: Texture2D, show_key: bool) -> void:
	_name_label.text = item_name
	ItemDescFormat.set_text(_desc_label, description)
	_icon.texture = icon
	_icon.visible = icon != null
	if _key_label != null:
		_key_label.visible = show_key
	_apply_scale()


func _reveal() -> void:
	if _shown and _crt_settled:
		_refresh_panel_size()
		_update_screen_position()
		return
	if _shown and not _crt_settled:
		_snap_shown()
		return
	_run_show_async()


func hide_card() -> void:
	if not _shown:
		return
	if not _crt_settled:
		hide_card_immediate()
		return
	_run_hide_async()


func hide_card_immediate() -> void:
	_anim_token += 1
	if is_instance_valid(_root) and is_instance_valid(_panel):
		CrtPowerFx.cancel(self, _root, _panel, _beam, _bloom)
	_shown = false
	_crt_settled = false
	_anchor = null
	_screen_lock = false
	layer = CARD_LAYER
	if _key_label != null:
		_key_label.visible = true
	if is_instance_valid(_root):
		_root.visible = false
		_root.modulate.a = 0.0
	set_process(false)


func is_card_visible() -> bool:
	return _shown and _root != null and _root.visible


func is_crt_settled() -> bool:
	return _crt_settled


func _process(_delta: float) -> void:
	if _shown:
		_update_screen_position()


func _on_tree_exiting() -> void:
	_anim_token += 1
	if is_instance_valid(_root) and is_instance_valid(_panel):
		CrtPowerFx.cancel(self, _root, _panel, _beam, _bloom)
	_shown = false
	_crt_settled = false
	set_process(false)


func _host_alive() -> bool:
	return is_instance_valid(self) and is_inside_tree() and get_tree() != null


func _snap_shown() -> void:
	_anim_token += 1
	CrtPowerFx.cancel(self, _root, _panel, _beam, _bloom)
	_shown = true
	_crt_settled = true
	_root.visible = true
	_root.modulate.a = 1.0
	CrtPowerFx.reset_visual(_root, _panel, _beam, _bloom)
	set_process(true)
	_refresh_panel_size()
	_update_screen_position()


func _run_show_async() -> void:
	if not _host_alive():
		return
	_anim_token += 1
	var token := _anim_token
	_shown = true
	_crt_settled = false
	_root.visible = true
	set_process(true)
	_refresh_panel_size()
	_update_screen_position()
	await CrtPowerFx.power_on(self, _root, _panel, _beam, _bloom)
	if not _host_alive() or token != _anim_token:
		return
	_crt_settled = true
	_refresh_panel_size()
	_update_screen_position()


func _run_hide_async() -> void:
	if not _host_alive():
		return
	_anim_token += 1
	var token := _anim_token
	_crt_settled = false
	await CrtPowerFx.power_off(self, _root, _panel, _beam, _bloom)
	if not _host_alive() or token != _anim_token:
		return
	_shown = false
	_anchor = null
	_root.visible = false
	set_process(false)
	CrtPowerFx.reset_visual(_root, _panel, _beam, _bloom)


func _items_indicator_rect() -> Rect2:
	if is_instance_valid(_anchor) and _anchor.has_method("ink_screen_rect"):
		var got: Variant = _anchor.call("ink_screen_rect")
		if got is Rect2 and (got as Rect2).size.y > 1.0:
			return got as Rect2
	var viewport := get_viewport()
	if viewport == null:
		return Rect2()
	var screen_pos := viewport.get_canvas_transform() * _world_anchor
	return Rect2(screen_pos, Vector2(1.0, 1.0))


func _refresh_panel_size() -> void:
	if _panel == null:
		return
	_panel.reset_size()
	if _root != null:
		_root.size = _panel.size


func _update_screen_position() -> void:
	var viewport := get_viewport()
	if viewport == null or _panel == null or _root == null:
		return
	if _screen_lock:
		_place_at_screen(viewport)
		return
	var items_indicator := _items_indicator_rect()
	_refresh_panel_size()
	var card_size := _panel.size
	if card_size.x <= 0.0 or card_size.y <= 0.0:
		card_size = _panel.get_combined_minimum_size()
	var card_w := card_size.x
	var gap := ITEMS_INDICATOR_GAP_PX
	var pos := Vector2(items_indicator.get_center().x - card_w * 0.5, items_indicator.end.y + gap)
	var view_size := Vector2(viewport.get_visible_rect().size)
	pos.x = clampf(pos.x, WINDOW_PAD, maxf(view_size.x - card_w - WINDOW_PAD, WINDOW_PAD))
	_root.position = pos
	_root.size = card_size


func _place_at_screen(viewport: Viewport) -> void:
	_refresh_panel_size()
	var card_size := _panel.size
	if card_size.x <= 0.0 or card_size.y <= 0.0:
		card_size = _panel.get_combined_minimum_size()
	var view_size := Vector2(viewport.get_visible_rect().size)
	var pos := _screen_pos + Vector2(SCREEN_CORNER_GAP, SCREEN_CORNER_GAP)
	if pos.x + card_size.x > view_size.x - WINDOW_PAD:
		pos.x = _screen_pos.x - card_size.x - SCREEN_CORNER_GAP
	pos.x = clampf(pos.x, WINDOW_PAD, maxf(view_size.x - card_size.x - WINDOW_PAD, WINDOW_PAD))
	pos.y = clampf(pos.y, WINDOW_PAD, maxf(view_size.y - card_size.y - WINDOW_PAD, WINDOW_PAD))
	_root.position = pos
	_root.size = card_size


func _set_ignore_mouse_recursive(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_set_ignore_mouse_recursive(c)
