@tool
class_name CombatHudPiece
extends Control

signal activated
signal hover_changed(on: bool)
signal press_changed(on: bool)

@export var clickable: bool = false
@export var use_alpha_hit: bool = false
@export var text_inset_px: float = 8.0
@export var hover_scale: float = 1.04
@export var press_scale: float = 0.96
@export var pop_on_change: bool = true
@export var alpha_hit_threshold: float = 0.08
@export var art_node_path: NodePath = NodePath("")

var _art: TextureRect
var _text_box: Control
var _hovering := false
var _pressing := false
var _base_scale := Vector2.ONE
var _pop_tween: Tween
var _feel_tween: Tween


func _ready() -> void:
	_cache_children()
	_base_scale = scale
	_sync_mouse_filter()
	_sync_pivot()
	if _text_box != null:
		_text_box.clip_contents = true
		_text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _art != null:
		_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_pivot()


func _sync_pivot() -> void:
	pivot_offset = size * 0.5


func _sync_mouse_filter() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE
	if clickable:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _cache_children() -> void:
	_art = null
	if not art_node_path.is_empty():
		_art = get_node_or_null(art_node_path) as TextureRect
	if _art == null:
		_art = get_node_or_null("Art") as TextureRect
	if _art == null:
		for child in get_children():
			if child is TextureRect:
				_art = child as TextureRect
				break
	if _art == null:
		_art = find_child("SkullStage1", true, false) as TextureRect
	_text_box = get_node_or_null("MOVE_TextBox") as Control
	if _text_box == null:
		_text_box = get_node_or_null("TextBox") as Control
	if _text_box == null:
		_text_box = Control.new()
		_text_box.name = "MOVE_TextBox"
		_text_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_text_box.clip_contents = true
		_text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_text_box)
		if Engine.is_editor_hint():
			_text_box.owner = owner if owner != null else self


func get_art() -> TextureRect:
	_cache_children()
	return _art


func get_text_box() -> Control:
	_cache_children()
	return _text_box


func attach(widget: Control, host: Control = null) -> void:
	if widget == null:
		return
	_cache_children()
	var target := host
	if target == null:
		target = _text_box
	if target == null:
		return
	if widget.get_parent() != target:
		widget.reparent(target)
	widget.visible = true
	widget.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var inset := 0.0 if clickable else text_inset_px
	widget.offset_left = inset
	widget.offset_top = inset
	widget.offset_right = -inset
	widget.offset_bottom = -inset
	_strip_widget_chrome(widget)
	if widget is Label:
		var lab := widget as Label
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.clip_text = true


func _strip_widget_chrome(widget: Control) -> void:
	var empty := StyleBoxEmpty.new()
	if widget is PanelContainer:
		(widget as PanelContainer).add_theme_stylebox_override("panel", empty)
	elif widget is Button:
		var btn := widget as Button
		btn.add_theme_stylebox_override("normal", empty)
		btn.add_theme_stylebox_override("pressed", empty)
		btn.add_theme_stylebox_override("hover", empty)
		btn.add_theme_stylebox_override("disabled", empty)
		btn.add_theme_stylebox_override("focus", empty)


func set_base_scale(value: Vector2) -> void:
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	if _feel_tween != null and _feel_tween.is_valid():
		_feel_tween.kill()
	_base_scale = value
	scale = value


func pop() -> void:
	if not pop_on_change:
		return
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	scale = _base_scale
	_pop_tween = create_tween()
	_pop_tween.tween_property(self, "scale", _base_scale * 1.06, 0.06)
	_pop_tween.tween_property(self, "scale", _base_scale, 0.06)


func play_press() -> void:
	if not clickable:
		return
	_pressing = true
	_apply_feel()
	press_changed.emit(true)
	var tree := get_tree()
	if tree == null:
		_pressing = false
		_apply_feel()
		press_changed.emit(false)
		return
	var timer := tree.create_timer(0.08)
	timer.timeout.connect(_release_press_feel, CONNECT_ONE_SHOT)


func _release_press_feel() -> void:
	_pressing = false
	_apply_feel()
	press_changed.emit(false)


func set_clickable(enabled: bool) -> void:
	clickable = enabled
	_sync_mouse_filter()


func _has_point(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, size).has_point(point):
		return false
	if not clickable:
		return true


	return _text_box_local_rect().has_point(point)


func _text_box_local_rect() -> Rect2:
	if _text_box == null or not is_instance_valid(_text_box):
		_cache_children()
	if _text_box == null or not is_instance_valid(_text_box):
		return Rect2(Vector2.ZERO, size)
	var top_left := _text_box.get_transform() * Vector2.ZERO
	return Rect2(top_left, _text_box.size)


func _gui_input(event: InputEvent) -> void:
	if not clickable:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_pressing = true
			_apply_feel()
			press_changed.emit(true)
			accept_event()
		else:
			if _pressing:
				_pressing = false
				_apply_feel()
				press_changed.emit(false)
				activated.emit()
				accept_event()


func _on_mouse_entered() -> void:
	if not clickable:
		return
	_hovering = true
	_apply_feel()
	hover_changed.emit(true)


func _on_mouse_exited() -> void:
	var was_pressing := _pressing
	_hovering = false
	_pressing = false
	_apply_feel()
	if was_pressing:
		press_changed.emit(false)
	hover_changed.emit(false)


func _apply_feel() -> void:
	if not clickable:
		return
	var target := _base_scale
	if _pressing:
		target *= press_scale
	elif _hovering:
		target *= hover_scale
	if _feel_tween != null and _feel_tween.is_valid():
		_feel_tween.kill()
	_feel_tween = create_tween()
	_feel_tween.tween_property(self, "scale", target, 0.08)
