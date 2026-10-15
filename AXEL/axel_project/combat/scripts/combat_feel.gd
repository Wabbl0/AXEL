class_name CombatFeel
extends Node

signal sfx_cue(cue_id: StringName)

const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const FLAME_BURST_SCRIPT := preload("res://combat/scripts/flame_burst.gd")
const BONUS_INTRO_SCRIPT := preload("res://combat/scripts/bonus_intro_fx.gd")
const BONUS_WIDE_LIFT := 90.0
const BANNER_LAYER := 115
const ENCOUNTER_BANNER_HOLD_SEC := 1.6
const ENCOUNTER_BANNER_SCRIM := 0.85
const BANNER_FADE_IN_SEC := 0.36
const BANNER_FADE_OUT_SEC := 0.70
const LOSS_SHATTER_SCRIPT := preload("res://combat/scripts/loss_shatter.gd")
const LOSS_PAIRS := [["NEW_Goal", "NEW_Multiplier"], ["NEW_Items", "NEW_History"], ["NEW_Bets", "NEW_Execute"]]
const LOSS_LAST := ["NEW_Settings"]
const LOSS_COMPANIONS := {"NEW_Grid": ["MOVE_SpinMoney"], "NEW_Execute": ["MOVE_PremiumBar"]}
const LOSS_HIT_SEC := 0.10
const LOSS_COLUMN_GAP_SEC := 0.07
const LOSS_ROW_STAGGER_SEC := 0.02
const LOSS_AFTER_SYMBOLS_SEC := 0.20
const LOSS_AFTER_GRID_SEC := 0.40
const LOSS_PAIR_GAP_SEC := 0.22
const LOSS_SCRIM_FADE_SEC := 0.60
const LOSS_SETTLE_CAP_SEC := 0.90
const LOSS_LINE_GAP := 40.0
const LOSS_REVEAL_SEC := 0.25

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
var _loss_banner_shift := 0.0
var _loss_hud_canvas: Control
var _loss_jolt_rest := Vector2.ZERO
var _loss_jolt_tween: Tween
var _loss_flames = null
var _bonus_fx: Control


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
	_bonus_fx = BONUS_INTRO_SCRIPT.new()
	_bonus_fx.name = "BonusIntroFx"
	_bonus_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_bonus_fx)
	_bonus_fx.cue.connect(_on_bonus_cue)
	_bonus_fx.impact.connect(_on_bonus_impact)
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


func play_bonus_intro(kind: StringName, text: String, anchor: Control = null, icons: Array[Texture2D] = []) -> void:
	if _bonus_fx == null:
		return
	var calm := _reduce_flashing()
	if not calm:
		shake(2, get_node_or_null("/root/AxelSettings"))
	await _bonus_fx.play(kind, _bonus_rect(anchor), text, icons, calm)


func power_pop(center: Vector2, radius: float, title: String, tag: String, loud: bool) -> void:
	if _bonus_fx == null:
		return
	var calm := _reduce_flashing()
	_bonus_fx.power_pop(center, radius, title, tag, loud, calm)
	if loud and not calm:
		shake(1, get_node_or_null("/root/AxelSettings"))


func is_bonus_intro_playing() -> bool:
	return _bonus_fx != null and _bonus_fx.is_playing()


func _bonus_rect(anchor: Control) -> Rect2:
	if anchor != null and is_instance_valid(anchor):
		var xf := anchor.get_global_transform_with_canvas()
		return Rect2(xf.origin, anchor.size * xf.get_scale())
	var view := _loss_view_size()
	return Rect2(Vector2(0.0, -BONUS_WIDE_LIFT), view)


func _on_bonus_cue(cue_id: StringName) -> void:
	sfx_cue.emit(cue_id)


func _on_bonus_impact(strength: int) -> void:
	shake(strength, get_node_or_null("/root/AxelSettings"))


func _on_banner_viewport_resized() -> void:
	if _game_over_open and _menu_box != null and _menu_box.visible:
		_loss_banner_shift = _layout_loss_block()
	if _banner != null and _banner.modulate.a > 0.01:
		_place_banner()


func _place_banner() -> void:
	if _banner == null:
		return
	if _game_over_open and (_banner_anchor == null or not is_instance_valid(_banner_anchor)):
		_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
		_banner.offset_left = 0.0
		_banner.offset_top = _loss_banner_shift
		_banner.offset_right = 0.0
		_banner.offset_bottom = _loss_banner_shift
		_banner.add_theme_font_size_override("font_size", 96)
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
	_loss_banner_shift = 0.0
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
		_banner_scrim.color = Color(0.0, 0.0, 0.0, 0.0)
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
	var beats := _loss_beats()
	if beats.is_empty():
		await _fade_loss_scrim()
		return
	var view := _loss_view_size()
	var shatter = LOSS_SHATTER_SCRIPT.new()
	shatter.name = "LossShatter"
	add_child(shatter)
	shatter.set_view(view)
	_loss_hud_canvas = _loss_find("HudCanvas", false)
	if _loss_hud_canvas != null:
		_loss_jolt_rest = _loss_hud_canvas.position
	_loss_flames = _make_loss_flames(view)
	_loss_hit()
	await CombatPace.await_seconds(LOSS_HIT_SEC)
	var scrim_started := false
	for beat in beats:
		var kind: StringName = beat["kind"]
		if kind == &"symbols":
			await _drop_loss_symbols(shatter, beat["columns"])
			await CombatPace.await_seconds(LOSS_AFTER_SYMBOLS_SEC)
		elif kind == &"break":
			var big := bool(beat["big"])
			for node in beat["nodes"]:
				_break_loss_piece(shatter, node, int(beat["spokes"]), float(beat["crack"]), big)
			await CombatPace.await_seconds(LOSS_AFTER_GRID_SEC if big else LOSS_PAIR_GAP_SEC)
		elif kind == &"drop":
			_fade_loss_scrim()
			scrim_started = true
			for node in beat["nodes"]:
				shatter.drop(node, 0.0, _loss_seed(node))
				_drop_loss_text(shatter, node)
	if not scrim_started:
		_fade_loss_scrim()
	var waited := 0.0
	while waited < LOSS_SETTLE_CAP_SEC and (waited < LOSS_SCRIM_FADE_SEC or not shatter.is_done()):
		await CombatPace.await_seconds(0.05)
		waited += 0.05


func _loss_beats() -> Array[Dictionary]:
	var beats: Array[Dictionary] = []
	var columns := _loss_symbol_columns()
	if not columns.is_empty():
		beats.append({"kind": &"symbols", "columns": columns})
	var grid := _loss_find("NEW_Grid")
	if grid != null:
		beats.append({"kind": &"break", "nodes": [grid], "spokes": 8, "crack": 0.18, "big": true})
	for pair in LOSS_PAIRS:
		var nodes: Array = []
		for piece_name in pair:
			var node := _loss_find(piece_name)
			if node != null:
				nodes.append(node)
		if not nodes.is_empty():
			beats.append({"kind": &"break", "nodes": nodes, "spokes": 5, "crack": 0.12, "big": false})
	var last: Array = []
	for piece_name in LOSS_LAST:
		var node := _loss_find(piece_name)
		if node != null:
			last.append(node)
	if _root != null:
		var frame := _root.get_node_or_null("GridFrame") as Control
		if frame != null and frame.visible:
			last.append(frame)
	if not last.is_empty():
		beats.append({"kind": &"drop", "nodes": last})
	return beats


func _loss_find(piece_name: String, need_visible: bool = true) -> Control:
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if scene == null:
		return null
	var node := scene.find_child(piece_name, true, false) as Control
	if node == null or (need_visible and not node.is_visible_in_tree()):
		return null
	return node


func _loss_symbol_columns() -> Array:
	var out: Array = []
	if _grid_ui == null:
		return out
	var cols := 5
	if _grid_ui is GridContainer:
		cols = maxi((_grid_ui as GridContainer).columns, 1)
	var index := 0
	for child in _grid_ui.get_children():
		if not (child is Control) or not (child as Control).visible:
			continue
		var col := index % cols
		while out.size() <= col:
			out.append([])
		out[col].push_front(child)
		index += 1
	return out


func _drop_loss_symbols(shatter, columns: Array) -> void:
	if _grid_ui == null:
		return
	var parent: CanvasItem = _grid_ui
	while parent.get_parent() is CanvasItem:
		parent = parent.get_parent() as CanvasItem
	if parent == _grid_ui:
		return
	var holder := Control.new()
	holder.name = "LossSymbols"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	var local := parent.get_global_transform().affine_inverse() * _grid_ui.get_global_transform()
	holder.position = local.origin
	holder.rotation = local.get_rotation()
	holder.scale = local.get_scale()
	for c in columns.size():
		var column: Array = columns[c]
		for k in column.size():
			var node := column[k] as Control
			if node == null or not is_instance_valid(node):
				continue
			var at := node.position
			node.get_parent().remove_child(node)
			holder.add_child(node)
			node.position = at
			shatter.drop(node, float(k) * LOSS_ROW_STAGGER_SEC, _loss_seed(node) + c)
		if c + 1 < columns.size():
			await CombatPace.await_seconds(LOSS_COLUMN_GAP_SEC)


func _break_loss_piece(shatter, piece: Control, spokes: int, crack_sec: float, big: bool) -> void:
	var host := _loss_shard_host(piece)
	await shatter.break_piece(piece, host, _loss_seed(piece), spokes, crack_sec, _loss_shake_scale())
	if piece == null or not is_instance_valid(piece):
		return
	_drop_loss_text(shatter, piece)
	for companion_name in LOSS_COMPANIONS.get(str(piece.name), []):
		var companion := _loss_find(companion_name)
		if companion != null:
			shatter.drop(companion, 0.0, _loss_seed(companion))
			_drop_loss_text(shatter, companion)
	_loss_flame_at(piece, [4, 4] if big else [4])
	if big:
		shake(4, get_node_or_null("/root/AxelSettings"))
		_loss_jolt(10.0)
	else:
		_loss_jolt(4.0)


func _drop_loss_text(shatter, piece: Node) -> void:
	var layer := _loss_widget_layer()
	if layer == null:
		return
	var hosts: Array = layer.call("release_for", piece)
	for i in hosts.size():
		var host := hosts[i] as Control
		if host == null or not is_instance_valid(host) or not host.visible:
			continue
		if _root != null and host.is_ancestor_of(_root):
			continue
		shatter.drop(host, 0.03, _loss_seed(piece) + i)


func _loss_widget_layer() -> Node:
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if scene == null:
		return null
	var layer := scene.find_child("WidgetLayer", true, false)
	if layer != null and layer.has_method("release_for"):
		return layer
	return null


func _loss_shard_host(piece: Control) -> Control:
	var base: Node = piece.get_parent()
	var walk: Node = piece
	while walk != null:
		if str(walk.name) == "HudCanvas" and walk is Control:
			base = walk
			break
		walk = walk.get_parent()
	if not (base is Control):
		return null
	var host := base.get_node_or_null("LossShards") as Control
	if host == null:
		host = Control.new()
		host.name = "LossShards"
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		base.add_child(host)
	return host


func _loss_seed(node: Node) -> int:
	return hash(str(node.name)) if node != null else 0


func _loss_hit() -> void:
	var settings := get_node_or_null("/root/AxelSettings")
	glitch_flash(settings)
	shake(3, settings)
	_loss_jolt(6.0)


func _loss_jolt(amp_px: float) -> void:
	var node := _loss_hud_canvas
	var amp := amp_px * _loss_shake_scale()
	if node == null or not is_instance_valid(node) or amp <= 0.01:
		return
	_kill(_loss_jolt_tween)
	node.position = _loss_jolt_rest
	_loss_jolt_tween = CombatPace.bind(create_tween())
	for i in 4:
		var kick := Vector2(amp if i % 2 == 0 else -amp, amp * 0.5 if i % 2 == 0 else -amp * 0.5)
		_loss_jolt_tween.tween_property(node, "position", _loss_jolt_rest + kick, 0.03)
	_loss_jolt_tween.tween_property(node, "position", _loss_jolt_rest, 0.05)


func _loss_shake_scale() -> float:
	if _reduce_flashing():
		return 0.0
	var settings := get_node_or_null("/root/AxelSettings")
	if settings != null and settings.has_method("get_value"):
		return clampf(float(settings.call("get_value", "access", "screen_shake", 1.0)), 0.0, 1.0)
	return 1.0


func _make_loss_flames(view: Vector2):
	if _reduce_flashing() or _root == null:
		return null
	var layer := CanvasLayer.new()
	layer.name = "LossFlameLayer"
	layer.layer = 114
	_root.add_child(layer)
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.size = view
	layer.add_child(host)
	var burst = FLAME_BURST_SCRIPT.new()
	burst.name = "LossFlameBurst"
	_root.add_child(burst)
	burst.bind(host)
	return burst


func play_win_flames(piece: Control, counts: Array) -> void:
	if _reduce_flashing() or _root == null or piece == null:
		return
	var layer := CanvasLayer.new()
	layer.name = "WinFlameLayer"
	layer.layer = 114
	_root.add_child(layer)
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.size = _loss_view_size()
	layer.add_child(host)
	var burst = FLAME_BURST_SCRIPT.new()
	burst.name = "WinFlameBurst"
	layer.add_child(burst)
	burst.bind(host)
	var center := piece.get_global_transform_with_canvas() * (piece.size * 0.5)
	await burst.play_waves(center, counts)
	await burst.await_done()
	if is_instance_valid(layer):
		layer.queue_free()


func _loss_flame_at(piece: Control, counts: Array) -> void:
	if _loss_flames == null or not is_instance_valid(_loss_flames):
		return
	var center := piece.get_global_transform_with_canvas() * (piece.size * 0.5)
	_loss_flames.play_waves(center, counts)


func _fade_loss_scrim() -> void:
	if _banner_scrim == null:
		return
	_banner_scrim.color = Color(0.0, 0.0, 0.0, 0.0)
	var fade := CombatPace.bind(create_tween())
	fade.tween_property(_banner_scrim, "color:a", ENCOUNTER_BANNER_SCRIM, LOSS_SCRIM_FADE_SEC)
	await fade.finished


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
	if not OS.has_feature("web"):
		_add_game_over_button("Exit", quit_app)
	var shift := _layout_loss_block()
	_menu_box.modulate.a = 0.0
	_menu_box.visible = true
	MenuLook.grab_first_focus(_menu_box)
	_loss_banner_shift = shift
	if _banner == null:
		_menu_box.modulate.a = 1.0
		return
	var glide := CombatPace.bind(create_tween())
	glide.tween_property(_banner, "offset_top", shift, LOSS_REVEAL_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	glide.parallel().tween_property(_banner, "offset_bottom", shift, LOSS_REVEAL_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	glide.parallel().tween_property(_menu_box, "modulate:a", 1.0, LOSS_REVEAL_SEC)


func _layout_loss_block() -> float:
	if _menu_box == null:
		return 0.0
	var view := _loss_view_size()
	var banner_h := _banner.get_combined_minimum_size().y if _banner != null else 0.0
	var menu_h := _menu_box.get_combined_minimum_size().y
	var top := (view.y - (banner_h + LOSS_LINE_GAP + menu_h)) * 0.5
	_menu_box.offset_top = top + banner_h + LOSS_LINE_GAP - view.y * 0.5
	_menu_box.offset_bottom = _menu_box.offset_top + menu_h
	return top + banner_h * 0.5 - view.y * 0.5


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
