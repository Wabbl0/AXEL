class_name LockerShelfRow
extends Control

const ICON_PX := 120.0

@export var uv_rect := Rect2(0.18, 0.22, 0.62, 0.14)
@export var icon_px := ICON_PX
@export var icon_gap := 8.0
@export var scroll_bar_thickness := 10.0

signal item_hovered(item: Resource)
signal item_clicked(item_id: String)

var _scroll: ScrollContainer
var _row: HBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	_scroll = ScrollContainer.new()
	_scroll.name = "ShelfScroll"
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.clip_contents = true
	add_child(_scroll)
	_row = HBoxContainer.new()
	_row.name = "ShelfItems"
	_row.add_theme_constant_override("separation", int(icon_gap))
	_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_scroll.add_child(_row)


func set_items(items: Array, equipped: PackedStringArray) -> void:
	if _row == null:
		_build()
	for child in _row.get_children():
		child.queue_free()
	for item in items:
		if item == null:
			continue
		_row.add_child(_make_item_button(item, equipped))


func _make_item_button(item: Resource, equipped: PackedStringArray) -> Button:
	var item_id := String(item.get("id"))
	var button := Button.new()
	button.custom_minimum_size = Vector2(icon_px, icon_px)
	button.toggle_mode = true
	button.button_pressed = equipped.has(item_id)
	button.expand_icon = false
	button.flat = true
	var icon := item.get("icon") as Texture2D
	if icon != null:
		button.icon = icon
		button.add_theme_constant_override("icon_max_width", int(icon_px))
	button.text = ""
	if button.button_pressed:
		button.modulate = Color(1.15, 0.75, 0.75, 1.0)
	button.pressed.connect(func() -> void: item_clicked.emit(item_id))
	button.mouse_entered.connect(func() -> void: item_hovered.emit(item))
	return button
