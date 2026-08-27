@tool
class_name CombatHudPiece
extends Control
## One movable HUD piece: art + clipped TextBox. Widgets attach into TextBox at runtime.

signal activated

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
var _hit_image: Image
var _hit_tex_size: Vector2 = Vector2.ZERO
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
	if use_alpha_hit:
		_cache_hit_image()


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
	widget.offset_left = text_inset_px
	widget.offset_top = text_inset_px
	widget.offset_right = -text_inset_px
	widget.offset_bottom = -text_inset_px
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


func pop() -> void:
	if not pop_on_change:
		return
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	scale = _base_scale
	_pop_tween = create_tween()
	_pop_tween.tween_property(self, "scale", _base_scale * 1.06, 0.06)
	_pop_tween.tween_property(self, "scale", _base_scale, 0.06)


func set_clickable(enabled: bool) -> void:
	clickable = enabled
	_sync_mouse_filter()


func _has_point(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, size).has_point(point):
		return false
	## Clickable pieces use MOVE_TextBox as the hit rect (not the whole art frame).
	if clickable and _text_box != null and is_instance_valid(_text_box):
		var box_rect := Rect2(_text_box.position, _text_box.size)
		if not box_rect.has_point(point):
			return false
	if not use_alpha_hit or _art == null or _art.texture == null:
		return true
	if _hit_image == null:
		_cache_hit_image()
	if _hit_image == null or _hit_tex_size.x <= 0.0 or _hit_tex_size.y <= 0.0:
		return true
	# Art may be nested (e.g. skull stage under PremiumSkull); map into art local space.
	var art_global := _art.get_global_rect()
	var self_global_pos := global_position
	var art_local_rect := Rect2(art_global.position - self_global_pos, art_global.size)
	if not art_local_rect.has_point(point):
		return false
	var local := point - art_local_rect.position
	var uv := Vector2(
		local.x / maxf(art_local_rect.size.x, 1.0),
		local.y / maxf(art_local_rect.size.y, 1.0)
	)
	var px := int(clampf(uv.x, 0.0, 1.0) * (_hit_tex_size.x - 1.0))
	var py := int(clampf(uv.y, 0.0, 1.0) * (_hit_tex_size.y - 1.0))
	return _hit_image.get_pixel(px, py).a >= alpha_hit_threshold


func _cache_hit_image() -> void:
	_hit_image = null
	_hit_tex_size = Vector2.ZERO
	if _art == null or _art.texture == null:
		return
	var img := _art.texture.get_image()
	if img == null:
		return
	_hit_image = img
	_hit_tex_size = Vector2(img.get_width(), img.get_height())


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
			accept_event()
		else:
			if _pressing:
				_pressing = false
				_apply_feel()
				activated.emit()
				accept_event()


func _on_mouse_entered() -> void:
	if not clickable:
		return
	_hovering = true
	_apply_feel()


func _on_mouse_exited() -> void:
	_hovering = false
	_pressing = false
	_apply_feel()


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
