extends CanvasLayer

class WheelPaint extends Control:
	var wheel: Node = null

	func _draw() -> void:
		if wheel != null and wheel.has_method("paint_on"):
			wheel.call("paint_on", self)

const BAND_COUNT := 4
const VISIBLE_COUNT := 3
const ICON_SLOTS := BAND_COUNT * VISIBLE_COUNT
const BAND_THICK := 52.0
const BAND_GAP := 8.0
const ICON_PX := 40.0
const ICON_HOVER_PX := 46.0
const HIT_PX := 28.0
const ARC_STEPS := 18
const FILL := Color(0.02, 0.02, 0.02, 0.98)
const OUTLINE := Color(0.9, 0.0, 0.0, 1.0)
const SHADOW := Color(0.04, 0.04, 0.04, 0.95)
const SHADOW_OFFSET := Vector2(5, 6)
const GREYED := Color(0.38, 0.38, 0.38, 1.0)
const ARC_START := PI
const ARC_END := TAU

var _root: Control
var _cap: Label
var _icons: Array[TextureButton] = []
var _arrows: Array[Button] = []
var _scroll: Array[int] = [0, 0, 0, 0]
var _open := false
var _center := Vector2.ZERO
var _inner := 64.0
var _hover_id := ""
var _cache_warmed := false


func _ready() -> void:
	layer = 109
	_build()
	var tree := get_tree()
	if tree != null and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	var pause := get_node_or_null("/root/AxelPause")
	if pause != null and pause.has_signal("pause_state_changed"):
		pause.pause_state_changed.connect(_on_pause_changed)


func band_count() -> int:
	return BAND_COUNT


func shown_band_count() -> int:
	return _shown_bands().size()


func is_wheel_open() -> bool:
	return _open


func listed_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for band in BAND_COUNT:
		for item in _items_for_band(band):
			ids.append(str(item.get("id")))
	return ids


func visible_ids(band: int) -> PackedStringArray:
	var ids := PackedStringArray()
	if band < 0 or band >= BAND_COUNT:
		return ids
	for item in _visible_slice(_items_for_band(band), _scroll[band]):
		ids.append(str(item.get("id")))
	return ids


func scroll_band(band: int, delta: int) -> void:
	_scroll_band(band, delta)


func cap_is_visible() -> bool:
	return _cap != null and _cap.visible


func cap_text() -> String:
	if _cap == null:
		return ""
	return _cap.text


func open_wheel() -> bool:
	if _open:
		return true
	if not _can_open():
		return false
	_open = true
	_root.visible = true
	_hide_floor_card()
	_layout()
	_play_sfx(&"item_wheel_open")
	var tutorial := get_node_or_null("/root/AxelTutorial")
	if tutorial != null and tutorial.has_method("complete"):
		tutorial.call("complete", "items_wheel")
	return true


func close_wheel() -> void:
	if not _open and (_root == null or not _root.visible):
		return
	_open = false
	_hover_id = ""
	if _root != null:
		_root.visible = false
	_hide_hover()


func _build() -> void:
	var paint := WheelPaint.new()
	paint.wheel = self
	_root = paint
	_root.name = "WheelRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	_cap = Label.new()
	_cap.name = "EquipCap"
	_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cap.visible = false
	MenuLook.apply_label(_cap, 28, MenuLook.TEXT)
	_root.add_child(_cap)

	for _i in ICON_SLOTS:
		var icon := TextureButton.new()
		icon.focus_mode = Control.FOCUS_NONE
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.ignore_texture_size = true
		icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
		icon.size = Vector2(ICON_PX, ICON_PX)
		icon.visible = false
		var empty := StyleBoxEmpty.new()
		icon.add_theme_stylebox_override("normal", empty)
		icon.add_theme_stylebox_override("hover", empty)
		icon.add_theme_stylebox_override("pressed", empty)
		icon.add_theme_stylebox_override("focus", empty)
		icon.pressed.connect(_on_icon_pressed.bind(icon))
		icon.mouse_entered.connect(_on_icon_hover.bind(icon))
		icon.mouse_exited.connect(_on_icon_exit.bind(icon))
		_icons.append(icon)
		_root.add_child(icon)

	for _i in BAND_COUNT * 2:
		var arrow := Button.new()
		arrow.focus_mode = Control.FOCUS_NONE
		arrow.flat = true
		arrow.mouse_filter = Control.MOUSE_FILTER_STOP
		arrow.custom_minimum_size = Vector2(HIT_PX, HIT_PX)
		arrow.size = Vector2(HIT_PX, HIT_PX)
		arrow.visible = false
		var empty := StyleBoxEmpty.new()
		for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
			arrow.add_theme_stylebox_override(state_name, empty)
		arrow.pressed.connect(_on_arrow_pressed.bind(arrow))
		_arrows.append(arrow)
		_root.add_child(arrow)


func _process(_delta: float) -> void:
	if not _cache_warmed:
		_cache_warmed = true
		call_deferred("_warm_wheel_textures")
	if not _open:
		return
	if not _can_open():
		close_wheel()
		return
	_layout()


func _input(event: InputEvent) -> void:
	if not _open or event.is_echo():
		return
	if _dialogue_busy():
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("back"):
		close_wheel()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var wheel := event as InputEventMouseButton
		if not wheel.pressed:
			return
		if wheel.button_index != MOUSE_BUTTON_WHEEL_UP and wheel.button_index != MOUSE_BUTTON_WHEEL_DOWN:
			return
		var band := _band_at(wheel.position)
		if band < 0:
			return
		var direction := 1 if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1
		_scroll_band(band, direction)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("item_wheel"):
		if _dialogue_busy():
			return
		if _open:
			close_wheel()
		else:
			open_wheel()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouseButton:
		return
	var click := event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _hit_player(click.position):
		return
	if _dialogue_busy() and not _open:
		return
	if _open:
		close_wheel()
	else:
		open_wheel()
	get_viewport().set_input_as_handled()


func _on_scene_changed() -> void:
	close_wheel()
	_cache_warmed = false


func _on_pause_changed(paused: bool) -> void:
	if paused:
		close_wheel()


func _layout() -> void:
	var metrics := _metrics()
	if metrics.is_empty():
		close_wheel()
		return
	_center = metrics["center"]
	_inner = float(metrics["inner"])
	_place_icons()
	_place_arrows()
	_place_cap()
	_follow_hover()
	_root.queue_redraw()


func paint_on(canvas: Control) -> void:
	if not _open:
		return
	var shown := _shown_bands()
	for visual in shown.size():
		var inner_edge := _inner + float(visual) * (BAND_THICK + BAND_GAP)
		var outer_edge := inner_edge + BAND_THICK
		for step in ARC_STEPS:
			var a0 := lerpf(ARC_START, ARC_END, float(step) / float(ARC_STEPS))
			var a1 := lerpf(ARC_START, ARC_END, float(step + 1) / float(ARC_STEPS))
			var pts := _quad(_center, inner_edge, outer_edge, a0, a1)
			var shadow_pts := PackedVector2Array()
			for p in pts:
				shadow_pts.append(p + SHADOW_OFFSET)
			canvas.draw_colored_polygon(shadow_pts, SHADOW)
			canvas.draw_colored_polygon(pts, FILL)
		canvas.draw_polyline(_arc_points(_center, outer_edge, ARC_START, ARC_END), OUTLINE, 2.0, false)
		canvas.draw_polyline(_arc_points(_center, inner_edge, ARC_START, ARC_END), OUTLINE, 2.0, false)
		canvas.draw_line(_point(_center, inner_edge, ARC_START), _point(_center, outer_edge, ARC_START), OUTLINE, 2.0, false)
		canvas.draw_line(_point(_center, inner_edge, ARC_END), _point(_center, outer_edge, ARC_END), OUTLINE, 2.0, false)
		var mid_r := (inner_edge + outer_edge) * 0.5
		_paint_chevron(canvas, _point(_center, mid_r, ARC_START))
		_paint_chevron(canvas, _point(_center, mid_r, ARC_END))


func _quad(center: Vector2, inner_edge: float, outer_edge: float, a0: float, a1: float) -> PackedVector2Array:
	return PackedVector2Array([
		_point(center, inner_edge, a0),
		_point(center, outer_edge, a0),
		_point(center, outer_edge, a1),
		_point(center, inner_edge, a1),
	])


func _arc_points(center: Vector2, radius: float, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for step in ARC_STEPS + 1:
		var angle := lerpf(a0, a1, float(step) / float(ARC_STEPS))
		pts.append(_point(center, radius, angle))
	return pts


func _paint_chevron(canvas: Control, at: Vector2) -> void:
	var tip := at + Vector2(0.0, 9.0)
	var left := at + Vector2(-8.0, -7.0)
	var right := at + Vector2(8.0, -7.0)
	canvas.draw_colored_polygon(PackedVector2Array([tip, left, right]), OUTLINE)


func _can_open() -> bool:
	var tree := get_tree()
	if tree == null or tree.paused:
		return false
	var scene := tree.current_scene
	if scene == null:
		return false
	var path := String(scene.scene_file_path)
	if path.begins_with("res://scenes/Main_Menu/") or path.begins_with("res://combat/"):
		return false
	if _dialogue_busy():
		return false
	if _find_player() == null:
		return false
	var run := _run()
	if run != null and run.has_method("is_in_encounter") and bool(run.call("is_in_encounter")):
		return false
	if run != null and run.has_method("is_game_over_menu_open") and bool(run.call("is_game_over_menu_open")):
		return false
	return true


func _dialogue_busy() -> bool:
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if scene == null:
		return false
	var overlay := scene.get_node_or_null("TopDialogueOverlay")
	if overlay != null and overlay.has_method("is_sequence_busy"):
		return bool(overlay.call("is_sequence_busy"))
	return false


func _sprite_local_rect(sprite: AnimatedSprite2D) -> Rect2:
	if sprite.sprite_frames == null:
		return Rect2()
	var anim := sprite.animation
	if anim == StringName() or not sprite.sprite_frames.has_animation(anim):
		return Rect2()
	var frame_count := sprite.sprite_frames.get_frame_count(anim)
	if frame_count <= 0:
		return Rect2()
	var frame := clampi(sprite.frame, 0, frame_count - 1)
	var tex := sprite.sprite_frames.get_frame_texture(anim, frame)
	if tex == null:
		return Rect2()
	var size := tex.get_size()
	var origin := sprite.offset
	if sprite.centered:
		origin -= size * 0.5
	return Rect2(origin, size)


func _find_player() -> Node2D:
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if scene == null:
		return null
	var direct := scene.get_node_or_null("PlayerLayer/Player") as Node2D
	if direct != null:
		return direct
	return scene.find_child("Player", true, false) as Node2D


func _metrics() -> Dictionary:
	var player := _find_player()
	if player == null:
		return {}
	var sprite := player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	var center := Vector2.ZERO
	var inner := 64.0
	if sprite != null:
		var xf := sprite.get_global_transform_with_canvas()
		var rect := _sprite_local_rect(sprite)
		if rect.size.y > 2.0:
			var head := Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.16)
			center = xf * head
			var top := xf * Vector2(rect.position.x, rect.position.y)
			var bottom := xf * Vector2(rect.position.x, rect.end.y)
			inner = clampf(absf(bottom.y - top.y) * 0.22, 48.0, 120.0)
		else:
			center = xf.origin
	else:
		center = player.get_global_transform_with_canvas().origin
	return {"center": center, "inner": inner}


func _shown_bands() -> Array[int]:
	var bands: Array[int] = []
	bands.append(0)
	for band in range(1, BAND_COUNT):
		if _items_for_band(band).is_empty():
			continue
		bands.append(band)
	return bands


func _visual_index(band: int) -> int:
	return _shown_bands().find(band)


func _items_for_band(band: int) -> Array:
	var out: Array = []
	var run := _run()
	if run == null or not run.has_method("owned_items"):
		return out
	for item in run.call("owned_items"):
		if item == null:
			continue
		if int(item.get("rarity")) != band:
			continue
		out.append(item)
	return out


func _visible_slice(items: Array, scroll: int) -> Array:
	if items.size() <= VISIBLE_COUNT:
		return items
	var out: Array = []
	for i in VISIBLE_COUNT:
		out.append(items[posmod(scroll + i, items.size())])
	return out


func _slot_angles(count: int) -> Array:
	var left := ARC_START + 0.48
	var right := ARC_END - 0.48
	var mid := (left + right) * 0.5
	if count <= 1:
		return [mid]
	if count == 2:
		return [left, right]
	return [left, mid, right]


func _place_icons() -> void:
	var slot := 0
	for band in BAND_COUNT:
		var shown := _visible_slice(_items_for_band(band), _scroll[band])
		var angles: Array = _slot_angles(shown.size())
		var mid_r := _mid_radius(band)
		for i in shown.size():
			var icon := _icons[slot]
			slot += 1
			var item: Resource = shown[i]
			var item_id := str(item.get("id"))
			var px := ICON_HOVER_PX if item_id == _hover_id else ICON_PX
			icon.visible = true
			icon.custom_minimum_size = Vector2(px, px)
			icon.size = Vector2(px, px)
			var cached := ItemDef.cached_wheel_texture(item)
			var prev_id := str(icon.get_meta("item_id", ""))
			if prev_id != item_id or icon.texture_normal != cached:
				icon.texture_normal = cached
			icon.modulate = Color.WHITE if _is_equipped(item_id) else GREYED
			icon.set_meta("item_id", item_id)
			var at := _point(_center, mid_r, float(angles[i]))
			icon.position = at - icon.size * 0.5
	while slot < _icons.size():
		_icons[slot].visible = false
		_icons[slot].set_meta("item_id", "")
		slot += 1


func _warm_wheel_textures() -> void:
	var run := _run()
	if run == null or not run.has_method("owned_items"):
		return
	for item in run.call("owned_items"):
		if item == null:
			continue
		ItemDef.cached_wheel_texture(item)


func _place_arrows() -> void:
	var index := 0
	var shown := _shown_bands()
	for band in BAND_COUNT:
		var band_on := shown.has(band)
		var mid_r := _mid_radius(band)
		for direction in [-1, 1]:
			var arrow := _arrows[index]
			index += 1
			arrow.visible = band_on
			if not band_on:
				continue
			arrow.size = Vector2(HIT_PX, HIT_PX)
			arrow.set_meta("band", band)
			arrow.set_meta("dir", direction)
			var angle := ARC_START if direction < 0 else ARC_END
			var at := _point(_center, mid_r, angle)
			arrow.position = at - arrow.size * 0.5


func _place_cap() -> void:
	var owned := _owned_count()
	_cap.visible = owned > 0
	if owned <= 0:
		return
	var run := _run()
	var equipped := 0
	var cap := 7
	if run != null:
		equipped = run.state.equipped_item_ids.size()
		if run.has_method("max_equip_slots"):
			cap = int(run.call("max_equip_slots"))
	_cap.text = "%d/%d" % [equipped, cap]
	_cap.reset_size()
	var label_size := _cap.get_combined_minimum_size()
	var rings := _shown_bands().size()
	var outer := _inner + float(rings) * (BAND_THICK + BAND_GAP) - BAND_GAP
	_cap.position = Vector2(
		_center.x - label_size.x * 0.5,
		_center.y - outer - label_size.y - 8.0
	)


func _mid_radius(band: int) -> float:
	var visual := _visual_index(band)
	if visual < 0:
		visual = 0
	var inner_edge := _inner + float(visual) * (BAND_THICK + BAND_GAP)
	return inner_edge + BAND_THICK * 0.5


func _point(center: Vector2, radius: float, angle: float) -> Vector2:
	return center + Vector2(cos(angle), sin(angle)) * radius


func _scroll_band(band: int, delta: int) -> void:
	if band < 0 or band >= BAND_COUNT or delta == 0:
		return
	var count := _items_for_band(band).size()
	if count <= VISIBLE_COUNT:
		return
	_scroll[band] = posmod(_scroll[band] + delta, count)
	_layout()


func _band_at(screen_pos: Vector2) -> int:
	if not _open:
		return -1
	var delta := screen_pos - _center
	var dist := delta.length()
	var angle := atan2(delta.y, delta.x)
	if angle > 0.08 and angle < PI - 0.08:
		return -1
	var shown := _shown_bands()
	for visual in shown.size():
		var inner_edge := _inner + float(visual) * (BAND_THICK + BAND_GAP)
		var outer_edge := inner_edge + BAND_THICK
		if dist >= inner_edge - 4.0 and dist <= outer_edge + 4.0:
			return int(shown[visual])
	return -1


func _hit_player(screen_pos: Vector2) -> bool:
	var player := _find_player()
	if player == null:
		return false
	var sprite := player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	if sprite == null or not sprite.visible:
		return false
	var xf := sprite.get_global_transform_with_canvas()
	var rect := _sprite_local_rect(sprite).grow(8.0)
	if rect.size.y <= 2.0:
		return xf.origin.distance_to(screen_pos) <= 48.0
	return rect.has_point(xf.affine_inverse() * screen_pos)


func _is_equipped(item_id: String) -> bool:
	var run := _run()
	if run == null:
		return false
	for existing in run.state.equipped_item_ids:
		if String(existing) == item_id:
			return true
	return false


func _owned_count() -> int:
	var run := _run()
	if run == null:
		return 0
	return run.state.owned_item_ids.size()


func _run() -> Node:
	return get_node_or_null("/root/AxelRun")


func _on_icon_pressed(icon: TextureButton) -> void:
	var item_id := str(icon.get_meta("item_id", ""))
	if item_id.is_empty():
		return
	_play_sfx(&"item_wheel_click")
	var run := _run()
	if run != null and run.has_method("toggle_equip"):
		run.call("toggle_equip", item_id)
	_layout()


func _play_sfx(cue: StringName) -> void:
	var sfx := get_node_or_null("/root/AxelSfx")
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", cue)


func _on_icon_hover(icon: TextureButton) -> void:
	var item_id := str(icon.get_meta("item_id", ""))
	if item_id.is_empty():
		return
	var item := _item_by_id(item_id)
	if item == null:
		return
	_hover_id = item_id
	var card := _card()
	if card == null or not card.has_method("show_screen_item"):
		return
	card.call(
		"show_screen_item",
		_grown_corner(icon),
		ItemDef.rarity_name(item),
		str(item.get("description")),
		item.get("icon")
	)


func _follow_hover() -> void:
	if _hover_id.is_empty():
		return
	var card := _card()
	if card == null or not card.has_method("nudge_screen_item"):
		return
	for icon in _icons:
		if not icon.visible:
			continue
		if str(icon.get_meta("item_id", "")) != _hover_id:
			continue
		card.call("nudge_screen_item", _grown_corner(icon))
		return


func _grown_corner(icon: Control) -> Vector2:
	var rect := icon.get_global_rect()
	return rect.get_center() + Vector2(ICON_HOVER_PX, ICON_HOVER_PX) * 0.5


func _on_icon_exit(icon: TextureButton) -> void:
	var item_id := str(icon.get_meta("item_id", ""))
	if _hover_id != item_id:
		return
	_hover_id = ""
	call_deferred("_hide_hover_if_clear")


func _hide_hover_if_clear() -> void:
	if not _hover_id.is_empty():
		return
	_hide_hover()


func _on_arrow_pressed(arrow: Button) -> void:
	_scroll_band(int(arrow.get_meta("band", -1)), int(arrow.get_meta("dir", 0)))


func _item_by_id(item_id: String) -> Resource:
	for band in BAND_COUNT:
		for item in _items_for_band(band):
			if str(item.get("id")) == item_id:
				return item
	return null


func _card() -> Node:
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if scene == null:
		return null
	var card := scene.get_node_or_null("WorldItemInfoCard")
	if card != null:
		return card
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("_ensure_info_card"):
		return world.call("_ensure_info_card", scene)
	return null


func _hide_floor_card() -> void:
	_hide_hover()


func _hide_hover() -> void:
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if scene == null:
		return
	var card := scene.get_node_or_null("WorldItemInfoCard")
	if card == null:
		return
	if card.has_method("hide_card_immediate"):
		card.call("hide_card_immediate")
	elif card.has_method("hide_card"):
		card.call("hide_card")
