class_name CombatFeel
extends Node

const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const FLAME_BURST_SCRIPT := preload("res://combat/scripts/flame_burst.gd")
const BANNER_LAYER := 115
const ENCOUNTER_BANNER_HOLD_SEC := 1.6
const ENCOUNTER_BANNER_SCRIM := 0.85
const BANNER_FADE_IN_SEC := 0.36
const BANNER_FADE_OUT_SEC := 0.70

var _root: Node2D
var _grid_ui: Control
var _shake_host: Node2D
var _layer: CanvasLayer
var _banner: Label
var _banner_scrim: ColorRect
var _grime: ColorRect
var _grime_band: ColorRect
var _menu_box: VBoxContainer
var _banner_tween: Tween
var _shake_tween: Tween
var _wobble_tween: Tween
var _host_rest: Vector2 = Vector2.ZERO
var _game_over_open := false
var _banner_anchor: Control
var _loss_presentation := false
var _loss_rush_frame := -1


func setup(root: Node2D, grid_ui: Control) -> void:
	_root = root
	_grid_ui = grid_ui
	_shake_host = root
	_host_rest = root.position
	_build()


func _build() -> void:
	if _grid_ui == null:
		return
	var host := _grid_ui.get_parent()
	var overlay := Control.new()
	overlay.name = "FeelGridOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if host != null:
		host.add_child(overlay)
	else:
		_grid_ui.add_child(overlay)
	_grime = ColorRect.new()
	_grime.name = "FeelGrime"
	_grime.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grime.color = Color(0.08, 0.02, 0.02, 0.0)
	overlay.add_child(_grime)
	_grime_band = ColorRect.new()
	_grime_band.name = "FeelGrimeBand"
	_grime_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grime_band.color = Color(0.04, 0.0, 0.0, 0.0)
	overlay.add_child(_grime_band)
	_layer = CanvasLayer.new()
	_layer.name = "FeelLayer"
	_layer.layer = BANNER_LAYER
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.add_child(_layer)
	_banner_scrim = ColorRect.new()
	_banner_scrim.name = "FeelBannerScrim"
	_banner_scrim.color = Color(0.0, 0.0, 0.0, 0.0)
	_banner_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_banner_scrim)
	_banner = Label.new()
	_banner.name = "FeelBanner"
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_override("font", FONT)
	_banner.add_theme_font_size_override("font_size", 96)
	_banner.add_theme_color_override("font_color", Color(0.75, 0.04, 0.04, 1.0))
	_banner.modulate.a = 0.0
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.offset_bottom = -180.0
	_layer.add_child(_banner)
	_menu_box = VBoxContainer.new()
	_menu_box.name = "GameOverMenu"
	_menu_box.visible = false
	_menu_box.set_anchors_preset(Control.PRESET_CENTER)
	_menu_box.offset_left = -260
	_menu_box.offset_right = 260
	_menu_box.offset_top = 40
	_menu_box.offset_bottom = 280
	_menu_box.add_theme_constant_override("separation", 10)
	_layer.add_child(_menu_box)
	var vp := _root.get_viewport() if _root != null else null
	if vp != null and not vp.size_changed.is_connected(_on_banner_viewport_resized):
		vp.size_changed.connect(_on_banner_viewport_resized)


func set_goal_progress(ratio: float) -> void:
	if _grime == null:
		return
	if _grid_ui != null:
		var overlay := _grime.get_parent() as Control
		if overlay != null:
			overlay.position = _grid_ui.position
			overlay.size = _grid_ui.size
		_grime.size = _grid_ui.size
		_grime.position = Vector2.ZERO
	var t := clampf(ratio, 0.0, 1.0)
	_grime.color.a = t * 0.28
	if _grime_band != null:
		_grime_band.size = Vector2.ZERO
		_grime_band.position = Vector2.ZERO
		_grime_band.color.a = 0.0


func highlight_power(_id_name: StringName) -> void:
	pass


func play_banner(text: String, hold_sec: float = 0.55, scrim_a: float = 0.62, persist: bool = false, anchor: Control = null) -> void:
	if _banner == null:
		return
	_banner.text = text
	_banner_anchor = anchor
	_place_banner()
	_kill(_banner_tween)
	_banner.modulate.a = 0.0
	_banner_scrim.color = Color(0.0, 0.0, 0.0, 0.0)
	_banner_tween = CombatPace.bind(create_tween())
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, BANNER_FADE_IN_SEC)
	_banner_tween.parallel().tween_property(_banner_scrim, "color:a", scrim_a, BANNER_FADE_IN_SEC)
	_banner_tween.tween_interval(hold_sec)
	if not persist:
		_banner_tween.tween_property(_banner, "modulate:a", 0.0, BANNER_FADE_OUT_SEC)
		_banner_tween.parallel().tween_property(_banner_scrim, "color:a", 0.0, BANNER_FADE_OUT_SEC)
	await _banner_tween.finished
	if not persist:
		_banner_anchor = null
		_place_banner()


func _on_banner_viewport_resized() -> void:
	if _banner != null and _banner.modulate.a > 0.01:
		_place_banner()


func _place_banner() -> void:
	if _banner == null:
		return
	if _banner_anchor == null or not is_instance_valid(_banner_anchor):
		_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
		_banner.offset_left = 0.0
		_banner.offset_top = 0.0
		_banner.offset_right = 0.0
		_banner.offset_bottom = -180.0
		_banner.add_theme_font_size_override("font_size", 96)
		return
	var rect := _banner_anchor.get_global_rect()
	_banner.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_banner.position = rect.position
	_banner.size = rect.size
	_banner.offset_left = rect.position.x
	_banner.offset_top = rect.position.y
	_banner.offset_right = rect.position.x + rect.size.x
	_banner.offset_bottom = rect.position.y + rect.size.y
	var font := _banner.get_theme_font("font")
	var size := 96
	if font != null and rect.size.x > 8.0:
		while size > 32 and font.get_string_size(_banner.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x - 8.0:
			size -= 4
	_banner.add_theme_font_size_override("font_size", size)


func is_game_over_open() -> bool:
	return _game_over_open


func is_loss_presentation() -> bool:
	return _loss_presentation


func note_rush_press() -> void:
	_loss_rush_frame = Engine.get_process_frames()


func show_game_over_menu(retry: Callable, to_menu: Callable, quit_app: Callable) -> void:
	_game_over_open = true
	_loss_presentation = true
	set_process_unhandled_input(true)
	_kill(_banner_tween)
	_banner_anchor = null
	_place_banner()
	if _menu_box != null:
		_menu_box.visible = false
	if _banner != null:
		_banner.text = ""
		_banner.modulate.a = 0.0
	if _banner_scrim != null:
		_banner_scrim.color = Color(0.0, 0.0, 0.0, ENCOUNTER_BANNER_SCRIM)
		_banner_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	await _play_loss_collapse()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var line := "IT TAKES YOU" if rng.randi() % 2 == 1 else "GONE"
	if _banner != null:
		_banner.text = line
		_banner.modulate.a = 0.0
		var fade := CombatPace.bind(create_tween())
		fade.tween_property(_banner, "modulate:a", 1.0, 0.5)
		await fade.finished
	_loss_presentation = false
	set_process_unhandled_input(false)
	CombatPace.clear_rush()
	await _wait_for_loss_buttons()
	_reveal_loss_buttons(retry, to_menu, quit_app)


func _unhandled_input(event: InputEvent) -> void:
	if not _loss_presentation or not event.is_action_pressed("interact"):
		return
	if _combat_paused():
		return
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()
	CombatPace.set_rush(true)
	note_rush_press()


func _play_loss_collapse() -> void:
	var pieces := _loss_pieces()
	if pieces.is_empty():
		return
	var view := _loss_view_size()
	var layer := CanvasLayer.new()
	layer.name = "LossFallLayer"
	layer.layer = 114
	if _root != null:
		_root.add_child(layer)
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.position = Vector2.ZERO
	host.size = view
	layer.add_child(host)
	var burst = null
	if not _reduce_flashing():
		burst = FLAME_BURST_SCRIPT.new()
		burst.name = "LossFlameBurst"
		if _root != null:
			_root.add_child(burst)
		burst.bind(host)
	var spin := RandomNumberGenerator.new()
	spin.randomize()
	for i in pieces.size():
		var piece := pieces[i] as Control
		if piece == null or not is_instance_valid(piece):
			continue
		if burst != null:
			var rect := piece.get_global_rect()
			burst.play_waves(rect.position + rect.size * 0.5, [4])
		var global_pos: Vector2 = piece.global_position
		var parent := piece.get_parent()
		if parent != null:
			parent.remove_child(piece)
		host.add_child(piece)
		piece.global_position = global_pos
		var drop := CombatPace.bind(create_tween())
		var delay := float(i) * 0.04
		if delay > 0.0:
			drop.tween_interval(delay)
		drop.tween_property(piece, "global_position:y", view.y + 80.0, 0.8)
		drop.parallel().tween_property(piece, "rotation", spin.randf_range(-0.6, 0.6), 0.8)
		drop.finished.connect(_hide_loss_piece.bind(piece))
	var tree := get_tree()
	if tree != null:
		await CombatPace.await_seconds(minf(float(pieces.size()) * 0.04, 0.4) + 0.15)


func _hide_loss_piece(piece: CanvasItem) -> void:
	if is_instance_valid(piece):
		piece.visible = false


func _loss_pieces() -> Array[CanvasItem]:
	var out: Array[CanvasItem] = []
	var scene := get_tree().current_scene if get_tree() != null else null
	if scene != null:
		for piece_name in [
			"NEW_Grid", "NEW_History", "NEW_Items", "NEW_Bets",
			"NEW_Goal", "NEW_Multiplier", "NEW_Settings", "NEW_Execute",
		]:
			var node := scene.find_child(piece_name, true, false) as CanvasItem
			if node != null and node.visible:
				out.append(node)
		var dvd := scene.find_child("EmptyItemDvd", true, false) as CanvasItem
		if dvd != null and dvd.visible:
			out.append(dvd)
	if _grid_ui != null:
		for child in _grid_ui.get_children():
			if child is CanvasItem:
				out.append(child as CanvasItem)
	if _root != null:
		var frame := _root.get_node_or_null("GridFrame") as CanvasItem
		if frame != null and frame.visible:
			out.append(frame)
	return out


func _loss_view_size() -> Vector2:
	var vp := get_viewport()
	if vp != null:
		var vis := vp.get_visible_rect().size
		if vis.x >= 64.0 and vis.y >= 64.0:
			return vis
	return Vector2(1920, 1280)


func _combat_paused() -> bool:
	var pause := get_node_or_null("/root/AxelPause")
	return pause != null and pause.has_method("is_paused") and bool(pause.call("is_paused"))


func _reduce_flashing() -> bool:
	var settings := get_node_or_null("/root/AxelSettings")
	if settings != null and settings.has_method("get_value"):
		return bool(settings.call("get_value", "access", "reduce_flashing", false))
	return false


func _wait_for_loss_buttons() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var elapsed := 0.0
	var reveal := false
	while elapsed < 3.0:
		var rush_press := Engine.get_process_frames() == _loss_rush_frame
		if not rush_press and (Input.is_action_just_pressed("interact") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			reveal = true
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()
			break
		await tree.process_frame
		var delta := get_process_delta_time()
		elapsed += delta if delta > 0.0 else (1.0 / 60.0)
	if reveal:
		while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			await tree.process_frame
		await tree.process_frame


func _reveal_loss_buttons(retry: Callable, to_menu: Callable, quit_app: Callable) -> void:
	if _menu_box == null:
		return
	for child in _menu_box.get_children():
		_menu_box.remove_child(child)
		child.free()
	_add_game_over_button("Retry", retry)
	_add_game_over_button("Return To Main Menu", to_menu)
	_add_game_over_button("Exit", quit_app)
	_menu_box.visible = true
	MenuLook.grab_first_focus(_menu_box)


func _add_game_over_button(caption: String, cb: Callable) -> void:
	var button := Button.new()
	button.text = caption
	MenuLook.apply_button(button, 36)
	button.pressed.connect(cb)
	_menu_box.add_child(button)


func shake(multiplier_value: int, settings: Node) -> void:
	if _shake_host == null:
		return
	if settings != null:
		if bool(settings.call("get_value", "access", "reduce_flashing", false)):
			return
		var scale := clampf(float(settings.call("get_value", "access", "screen_shake", 1.0)), 0.0, 1.0)
		if scale <= 0.01:
			return
	var amp := 2.0 + float(maxi(multiplier_value, 1)) * 1.6
	if settings != null:
		amp *= clampf(float(settings.call("get_value", "access", "screen_shake", 1.0)), 0.0, 1.0)
	_kill(_shake_tween)
	_shake_host.position = _host_rest
	_shake_tween = CombatPace.bind(create_tween())
	for i in 5:
		var kick := Vector2(amp if i % 2 == 0 else -amp, amp * 0.4 if i % 2 == 0 else -amp * 0.4)
		_shake_tween.tween_property(_shake_host, "position", _host_rest + kick, 0.03)
	_shake_tween.tween_property(_shake_host, "position", _host_rest, 0.05)


func crt_wobble(multiplier_value: int, settings: Node) -> void:
	if _shake_host == null:
		return
	if settings != null:
		if bool(settings.call("get_value", "access", "reduce_flashing", false)):
			return
		if clampf(float(settings.call("get_value", "access", "screen_shake", 1.0)), 0.0, 1.0) <= 0.01:
			return
	var amp := 1.2 + float(maxi(multiplier_value, 1)) * 0.35
	if settings != null:
		amp *= clampf(float(settings.call("get_value", "access", "screen_shake", 1.0)), 0.0, 1.0)
	_kill(_wobble_tween)
	_wobble_tween = CombatPace.bind(create_tween())
	for i in 6:
		var kick := Vector2(amp if i % 2 == 0 else -amp, 0.0)
		_wobble_tween.tween_property(_shake_host, "position", _host_rest + kick, 0.05)
	_wobble_tween.tween_property(_shake_host, "position", _host_rest, 0.08)


func glitch_flash(settings: Node) -> void:
	if _banner_scrim == null:
		return
	if settings != null and bool(settings.call("get_value", "access", "reduce_flashing", false)):
		return
	var peak := 0.28
	if settings != null:
		peak *= clampf(float(settings.call("get_value", "access", "glitch_intensity", 1.0)), 0.0, 1.0)
	_banner_scrim.color = Color(0.9, 0.05, 0.05, peak)
	var tw := CombatPace.bind(create_tween())
	tw.tween_property(_banner_scrim, "color:a", 0.0, 0.12)


func _kill(tw: Tween) -> void:
	if tw != null and is_instance_valid(tw):
		tw.kill()
