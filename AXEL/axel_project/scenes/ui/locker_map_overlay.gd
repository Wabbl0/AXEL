extends CanvasLayer

signal travel_requested(scene_path: String)
signal closed

# Room boxes are pixels on axel_map_v2.png.
const MAP_TEXTURE := preload("res://exports/Drawings/axel_map_v2.png")
const HAND_SHEET := preload("res://assets/sprites/item_hand-Sheet.png")
const UI_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const FADE_COLOR := Color(0, 0, 0, 0.75)
const HIGHLIGHT_COLOR := Color(0.85, 0.0, 0.0, 0.62)
const LABEL_COLOR := Color(1, 1, 1, 1)
const LABEL_FONT_BASE := 36
const CARD_NAME_FONT := 26
const CARD_DESC_FONT := 20
const CARD_ICON_PX := 64.0
const CARD_GAP := 12.0
const PIN_PX := 28.0
const HOVER_GROW := 1.08
const ROCK_DEGREES := 1.0
const ROCK_PERIOD := 28.0

const ENTRANCE_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const SCHOOL_MAP_SCENE := "res://scenes/Arc_1/1.3_SchoolMap.tscn"
const BASEMENT_SCENE := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const ENTRANCE_PIN_RECT := Rect2(487, 533, 475, 95)
const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const KITCHEN_SCENE := "res://scenes/Arc_2/2.3_Kitchen.tscn"
const HALLWAY_SCENE := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const BACKYARD_SCENE := "res://scenes/Arc_3/3.1_Backyard.tscn"
const LOUNGE_SCENE := "res://scenes/Arc_4/4.1_TeachersLounge.tscn"
const CLASSROOM_SCENE := "res://scenes/Arc_5/5.1_Classroom.tscn"

# fit: the hover fill stays inside this box, on the inside of the red line.
const AREAS: Array[Dictionary] = [
	{
		"name": "Kitchen",
		"rect": Rect2(1253, 13, 323, 244),
		"fit": true,
		"scene": KITCHEN_SCENE,
		"plate": "res://exports/Drawings/2.3_Kitchen.png",
	},
	{
		"name": "Cafeteria",
		"rect": Rect2(976, 270, 723, 598),
		"fit": true,
		"scene": CAFETERIA_SCENE,
		"plate": "res://exports/Drawings/2.1_Cafeteria.png",
	},
	{
		"name": "Backyard",
		"fade": true,
		"fit": true,
		"scene": BACKYARD_SCENE,
		"plate": "res://exports/Drawings/3.1_Backyard.png",
	},
	{
		"name": "Hallway",
		"fit": true,
		"scene": HALLWAY_SCENE,
		"plate": "res://exports/Drawings/2.4_ClassroomsCorridor.png",
		# Right stem, then the bottom bar. It stops on the white bar.
		"rects": [
			Rect2(1424, 881, 140, 461),
			Rect2(856, 1342, 708, 105),
		],
	},
	{
		"name": "Entrance",
		"rect": Rect2(13, 533, 949, 95),
		"fit": true,
		"scene": ENTRANCE_SCENE,
		# Basement hand only. The click still travels the whole strip to 1.2.
		"pin_scene": BASEMENT_SCENE,
		"pin_plate": "res://exports/Drawings/1.4_BasementDoor_v2.png",
		"pin_rect": ENTRANCE_PIN_RECT,
	},
	{
		"name": "Classroom",
		"rect": Rect2(1232, 1063, 181, 266.5),
		"scene": CLASSROOM_SCENE,
		"plate": "res://exports/Drawings/5.1_Classroom.png",
	},
	{
		"name": "Teachers' Lounge",
		"rect": Rect2(1578, 1256, 300, 184),
		"scene": LOUNGE_SCENE,
		"plate": "res://exports/Drawings/4.1_TeachersLounge.png",
	},
]

var _root: Control
var _rock: Control
var _map: TextureRect
var _rock_time := 0.0
var _outline: Control
var _label: Label
var _exit_button: Button
var _pin_host: Control
var _card_host: Control
var _hand_tex: AtlasTexture
var _plate_size: Dictionary = {}
var _parts: Array[Control] = []
var _part_area: Array[int] = []
var _part_slot: Array[int] = []
var _hover_depth: Array[int] = []
var _hover_index := -1
var _hover_part := -1
var _hover_mouse := Vector2.INF
var _map_origin := Vector2.ZERO
var _map_scale := Vector2.ONE


func _ready() -> void:
	layer = 110
	visible = false
	_hover_depth.resize(AREAS.size())
	_reset_hover()
	_build()
	_layout()
	get_viewport().size_changed.connect(_layout)
	var world := _world()
	if world != null and world.has_signal("map_spots_updated"):
		var spots_ready := Callable(self, "_on_map_spots_updated")
		if not world.is_connected("map_spots_updated", spots_ready):
			world.connect("map_spots_updated", spots_ready)


func is_open() -> bool:
	return visible


func open() -> void:
	_reset_hover()
	_rock_time = 0.0
	if _rock != null:
		_rock.rotation = 0.0
	_refresh_hover()
	visible = true
	_layout()


func close() -> void:
	_reset_hover()
	_refresh_hover()
	visible = false
	closed.emit()


func _reset_hover() -> void:
	_hover_index = -1
	_hover_part = -1
	for i in _hover_depth.size():
		_hover_depth[i] = 0


func _build() -> void:
	_root = Control.new()
	_root.name = "MapOverlay"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var fade := ColorRect.new()
	fade.name = "Fade"
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = FADE_COLOR
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(fade)

	_rock = Control.new()
	_rock.name = "Rock"
	_rock.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rock.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_rock)

	_map = TextureRect.new()
	_map.name = "Map"
	_map.texture = MAP_TEXTURE
	_map.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_SCALE
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rock.add_child(_map)

	for i in AREAS.size():
		var rects := _rects_for(i)
		for slot in rects.size():
			var area := Control.new()
			area.name = String(AREAS[i]["name"])
			area.mouse_filter = Control.MOUSE_FILTER_STOP
			area.mouse_entered.connect(_on_part_enter.bind(i, slot))
			area.mouse_exited.connect(_on_part_exit.bind(i))
			area.gui_input.connect(_on_part_gui.bind(i))
			_rock.add_child(area)
			_parts.append(area)
			_part_area.append(i)
			_part_slot.append(slot)

	var highlight := Highlight.new()
	highlight.name = "Highlight"
	highlight.host = self
	highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rock.add_child(highlight)
	_outline = highlight

	_label = Label.new()
	_label.name = "SectionName"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_override("font", UI_FONT)
	_label.add_theme_color_override("font_color", LABEL_COLOR)
	_label.visible = false
	_rock.add_child(_label)

	_pin_host = Control.new()
	_pin_host.name = "ItemPins"
	_pin_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pin_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rock.add_child(_pin_host)

	_card_host = Control.new()
	_card_host.name = "ItemCards"
	_card_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_host.visible = false
	_card_host.mouse_exited.connect(_on_cards_exited)
	_rock.add_child(_card_host)

	_exit_button = Button.new()
	_exit_button.name = "ExitButton"
	_exit_button.text = "X"
	_exit_button.focus_mode = Control.FOCUS_NONE
	_exit_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_exit_button.add_theme_font_override("font", UI_FONT)
	_exit_button.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	_exit_button.add_theme_color_override("font_pressed_color", Color(0.75, 0, 0, 1))
	_exit_button.add_theme_color_override("font_hover_color", Color(1, 0.25, 0.25, 1))
	_exit_button.pressed.connect(close)
	_root.add_child(_exit_button)


func _layout() -> void:
	if _map == null or _map.texture == null:
		return
	var view := _view_size()
	var fit := clampf(view.y / UiViewportScale.DESIGN_VIEWPORT_H, 0.5, 2.5)
	var margin := 72.0 * fit
	var avail := Vector2(maxf(view.x - margin * 2.0, 32.0), maxf(view.y - margin * 2.0, 32.0))
	var tex_size := _map.texture.get_size()
	var scale := minf(avail.x / tex_size.x, avail.y / tex_size.y)
	var drawn := tex_size * scale
	_map_origin = (view - drawn) * 0.5
	_map_scale = Vector2(scale, scale)
	_map.position = _map_origin
	_map.size = drawn
	_apply_area_rects()
	var chrome := UiViewportScale.factor(self)
	UiViewportScale.apply_exit_button(_exit_button, chrome)
	_label.add_theme_font_size_override("font_size", roundi(LABEL_FONT_BASE * chrome))
	_refresh_hover()
	_refresh_pins()


func _view_size() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2(1920, 1280)
	var size := viewport.get_visible_rect().size
	if size.x < 2.0 or size.y < 2.0:
		return Vector2(1920, 1280)
	return size


func _screen_rect(tex_rect: Rect2) -> Rect2:
	return Rect2(_map_origin + tex_rect.position * _map_scale, tex_rect.size * _map_scale)


func _process(delta: float) -> void:
	if not visible or _rock == null or _map == null:
		return
	_rock_time += delta
	_rock.pivot_offset = _map.position + _map.size * 0.5
	var turns := _rock_time / ROCK_PERIOD
	_rock.rotation = sin(turns * TAU) * deg_to_rad(ROCK_DEGREES)
	if _hover_index >= 0:
		var viewport := get_viewport()
		if viewport != null:
			var mouse := viewport.get_mouse_position()
			if mouse.distance_to(_hover_mouse) > 1.0:
				_hover_mouse = mouse
				_drop_hover_if_outside(_hover_index)


func _rects_for(index: int) -> Array:
	var area: Dictionary = AREAS[index]
	if bool(area.get("fade", false)):
		return [_backyard_rect()]
	if area.has("rects"):
		return area["rects"]
	return [area["rect"]]


func _keeps_inside(index: int) -> bool:
	return bool(AREAS[index].get("fit", false))


func _backyard_rect() -> Rect2:
	var lounge: Rect2 = _named_rect("Teachers' Lounge")
	var cafe: Rect2 = _named_rect("Cafeteria")
	var size := lounge.size * HOVER_GROW
	var x := cafe.position.x + cafe.size.x + 12.0
	var y := cafe.get_center().y - size.y * 0.5
	return Rect2(x, y, size.x, size.y)


func _named_rect(area_name: String) -> Rect2:
	for area in AREAS:
		if String(area["name"]) == area_name and area.has("rect"):
			return area["rect"]
	return Rect2()


func _on_part_enter(index: int, slot: int) -> void:
	_hover_depth[index] += 1
	_hover_index = index
	_hover_part = slot
	var viewport := get_viewport()
	if viewport != null:
		_hover_mouse = viewport.get_mouse_position()
	_refresh_hover()


func _on_part_exit(index: int) -> void:
	_hover_depth[index] = maxi(_hover_depth[index] - 1, 0)
	if _hover_depth[index] > 0:
		return
	if _hover_index != index:
		return
	call_deferred("_drop_hover_if_outside", index)


func _on_cards_exited() -> void:
	if _hover_index < 0:
		return
	call_deferred("_drop_hover_if_outside", _hover_index)


func _drop_hover_if_outside(index: int) -> void:
	if _hover_index != index:
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var mouse := viewport.get_mouse_position()
	if _pointer_on_cards(mouse):
		return
	if _pointer_on_area(index, mouse):
		return
	_hover_index = -1
	_hover_part = -1
	_refresh_hover()


func _pointer_on_cards(mouse: Vector2) -> bool:
	if _card_host == null or not _card_host.visible or _card_host.size.x < 1.0:
		return false
	var chrome := 1.0
	if is_inside_tree():
		chrome = UiViewportScale.factor(self)
	return _card_host.get_global_rect().grow(CARD_GAP * chrome + 8.0).has_point(mouse)


func _pointer_on_area(index: int, mouse: Vector2) -> bool:
	for i in _parts.size():
		if _part_area[i] != index:
			continue
		if _parts[i].get_global_rect().has_point(mouse):
			return true
	return false


func _on_part_gui(event: InputEvent, index: int) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if index < 0 or index >= AREAS.size():
		return
	var scene_path := String(AREAS[index].get("scene", ""))
	if not _can_travel(scene_path):
		return
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
	if scene_path == _opened_from_room():
		return
	travel_requested.emit(scene_path)


func _can_travel(scene_path: String) -> bool:
	var world := get_node_or_null("/root/AxelWorld")
	if world == null or not world.has_method("map_can_travel"):
		return false
	return bool(world.call("map_can_travel", scene_path))


func _opened_from_room() -> String:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return ""
	var here := String(tree.current_scene.scene_file_path)
	if here == SCHOOL_MAP_SCENE:
		var gm := get_node_or_null("/root/GameManager")
		if gm == null:
			return ""
		return String(gm.get("pause_map_return_path"))
	return here


func _apply_area_rects() -> void:
	for i in _parts.size():
		var tex_rect: Rect2 = _rects_for(_part_area[i])[_part_slot[i]]
		var rect := _screen_rect(tex_rect)
		if _part_area[i] == _hover_index and not _keeps_inside(_part_area[i]):
			rect = _grown(rect)
		_parts[i].position = rect.position
		_parts[i].size = rect.size
	if _hover_index < 0 or _outline == null:
		return
	for i in _parts.size():
		if _part_area[i] == _hover_index:
			_rock.move_child(_parts[i], _outline.get_index())


func _grown(rect: Rect2) -> Rect2:
	var size := rect.size * HOVER_GROW
	return Rect2(rect.get_center() - size * 0.5, size)


func _refresh_hover() -> void:
	_apply_area_rects()
	if _outline != null:
		_outline.queue_redraw()
	if _label == null:
		return
	if _hover_index < 0 or _hover_index >= AREAS.size():
		_label.visible = false
		_clear_cards()
		_refresh_pins()
		return
	var chrome := 1.0
	if is_inside_tree():
		chrome = UiViewportScale.factor(self)
	_label.text = String(AREAS[_hover_index]["name"])
	var font_size := roundi(LABEL_FONT_BASE * chrome)
	_label.add_theme_font_size_override("font_size", font_size)
	_label.size = UI_FONT.get_string_size(_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var rects := _rects_for(_hover_index)
	var slot := _label_slot(rects)
	var tex_rect: Rect2 = rects[slot]
	var area_rect := _screen_rect(tex_rect)
	if not _keeps_inside(_hover_index):
		area_rect = _grown(area_rect)
	_label.position = area_rect.position + (area_rect.size - _label.size) * 0.5
	_label.visible = true
	_refresh_cards()
	_refresh_pins()


func paint_highlight(canvas: Control) -> void:
	if canvas == null or _hover_index < 0 or _hover_index >= AREAS.size():
		return
	var area: Dictionary = AREAS[_hover_index]
	if bool(area.get("fade", false)):
		_draw_edge_fade(canvas, _screen_rect(_rects_for(_hover_index)[0]), HIGHLIGHT_COLOR)
		return
	if area.has("rects"):
		var points := _corridor_polygon(_rects_for(_hover_index))
		if not _keeps_inside(_hover_index):
			points = _grown_polygon(points)
		var screen := PackedVector2Array()
		for point in points:
			screen.append(_screen_point(point))
		if screen.size() >= 3:
			canvas.draw_colored_polygon(screen, HIGHLIGHT_COLOR)
		return
	var area_rect := _screen_rect(_rects_for(_hover_index)[0])
	if not _keeps_inside(_hover_index):
		area_rect = _grown(area_rect)
	if area_rect.size.x < 4.0 or area_rect.size.y < 4.0:
		return
	canvas.draw_rect(area_rect, HIGHLIGHT_COLOR, true)


func _label_slot(rects: Array) -> int:
	if rects.size() > 1:
		var slot := 0
		var widest := -1.0
		for i in rects.size():
			var piece: Rect2 = rects[i]
			if piece.size.x > widest:
				widest = piece.size.x
				slot = i
		return slot
	if _hover_part >= 0 and _hover_part < rects.size():
		return _hover_part
	return 0


func _draw_edge_fade(canvas: Control, outer: Rect2, color: Color) -> void:
	var fade := minf(outer.size.x, outer.size.y) * 0.42
	var inner := outer.grow(-fade)
	if inner.size.x < 4.0 or inner.size.y < 4.0:
		canvas.draw_rect(outer, color, true)
		return
	var clear := Color(color.r, color.g, color.b, 0.0)
	canvas.draw_rect(inner, color, true)
	var o0 := outer.position
	var o1 := outer.end
	var i0 := inner.position
	var i1 := inner.end
	_fade_quad(canvas, Vector2(i0.x, o0.y), Vector2(i1.x, o0.y), Vector2(i1.x, i0.y), Vector2(i0.x, i0.y), clear, clear, color, color)
	_fade_quad(canvas, Vector2(i0.x, i1.y), Vector2(i1.x, i1.y), Vector2(i1.x, o1.y), Vector2(i0.x, o1.y), color, color, clear, clear)
	_fade_quad(canvas, Vector2(o0.x, i0.y), Vector2(i0.x, i0.y), Vector2(i0.x, i1.y), Vector2(o0.x, i1.y), clear, color, color, clear)
	_fade_quad(canvas, Vector2(i1.x, i0.y), Vector2(o1.x, i0.y), Vector2(o1.x, i1.y), Vector2(i1.x, i1.y), color, clear, clear, color)
	_fade_quad(canvas, Vector2(o0.x, o0.y), Vector2(i0.x, o0.y), Vector2(i0.x, i0.y), Vector2(o0.x, i0.y), clear, clear, color, clear)
	_fade_quad(canvas, Vector2(i1.x, o0.y), Vector2(o1.x, o0.y), Vector2(o1.x, i0.y), Vector2(i1.x, i0.y), clear, clear, clear, color)
	_fade_quad(canvas, Vector2(o0.x, i1.y), Vector2(i0.x, i1.y), Vector2(i0.x, o1.y), Vector2(o0.x, o1.y), clear, color, clear, clear)
	_fade_quad(canvas, Vector2(i1.x, i1.y), Vector2(o1.x, i1.y), Vector2(o1.x, o1.y), Vector2(i1.x, o1.y), color, clear, clear, clear)


func _fade_quad(canvas: Control, a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	canvas.draw_polygon(
		PackedVector2Array([a, b, c, d]),
		PackedColorArray([ca, cb, cc, cd])
	)


func _corridor_polygon(rects: Array) -> PackedVector2Array:
	var right: Rect2 = rects[0]
	var bottom: Rect2 = rects[1]
	var right_end := right.position + right.size
	var bottom_end := bottom.position + bottom.size
	return PackedVector2Array([
		bottom.position,
		Vector2(right.position.x, bottom.position.y),
		right.position,
		Vector2(right_end.x, right.position.y),
		bottom_end,
		Vector2(bottom.position.x, bottom_end.y),
	])


func _grown_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var center := bounds.get_center()
	var grown := PackedVector2Array()
	for point in points:
		grown.append(center + (point - center) * HOVER_GROW)
	return grown


func _screen_point(tex_point: Vector2) -> Vector2:
	return _map_origin + tex_point * _map_scale


static func pin_tex_point(item_px: Vector2, plate: Vector2, measure: Rect2) -> Vector2:
	if plate.x < 1.0 or plate.y < 1.0 or measure.size.x < 1.0 or measure.size.y < 1.0:
		return measure.get_center()
	var uv := Vector2(item_px.x / plate.x, item_px.y / plate.y)
	return measure.position + Vector2(uv.x * measure.size.x, uv.y * measure.size.y)


func _measure_rect(index: int) -> Rect2:
	var rects := _rects_for(index)
	var bounds: Rect2 = rects[0]
	for i in range(1, rects.size()):
		var piece: Rect2 = rects[i]
		var pos := Vector2(
			minf(bounds.position.x, piece.position.x),
			minf(bounds.position.y, piece.position.y)
		)
		var end := Vector2(maxf(bounds.end.x, piece.end.x), maxf(bounds.end.y, piece.end.y))
		bounds = Rect2(pos, end - pos)
	return bounds


func _pin_measure_rect(index: int) -> Rect2:
	var pin_rect: Variant = AREAS[index].get("pin_rect", null)
	if pin_rect is Rect2:
		return pin_rect
	return _measure_rect(index)


func _pin_plate_size(index: int) -> Vector2:
	var path := String(AREAS[index].get("pin_plate", ""))
	if path.is_empty():
		path = String(AREAS[index].get("plate", ""))
	return _texture_size(path)


func _texture_size(path: String) -> Vector2:
	if path.is_empty():
		return Vector2.ZERO
	if _plate_size.has(path):
		return _plate_size[path]
	var tex := load(path) as Texture2D
	var size := tex.get_size() if tex != null else Vector2.ZERO
	_plate_size[path] = size
	return size


func _hand_frame() -> Texture2D:
	if _hand_tex == null:
		_hand_tex = AtlasTexture.new()
		_hand_tex.atlas = HAND_SHEET
		_hand_tex.region = Rect2(0, 0, 48, 48)
	return _hand_tex


func _world() -> Node:
	return get_node_or_null("/root/AxelWorld")


func _items_for(index: int) -> Array:
	var world := _world()
	if world == null or not world.has_method("placed_floor_items"):
		return []
	var area: Dictionary = AREAS[index]
	var scene_path := String(area.get("pin_scene", ""))
	if scene_path.is_empty():
		scene_path = String(area.get("scene", ""))
	if scene_path.is_empty():
		return []
	return world.call("placed_floor_items", scene_path)


func _on_map_spots_updated() -> void:
	_refresh_pins()
	if _hover_index >= 0:
		_refresh_cards()


func _pin_glyph(item_id: String) -> String:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not run.has_method("load_item"):
		return ""
	var item := run.call("load_item", item_id) as Resource
	if item == null:
		return ""
	return ItemDef.rarity_glyph(item)


func _refresh_pins() -> void:
	if _pin_host == null:
		return
	var old_pins: Array = _pin_host.get_children()
	for child in old_pins:
		_pin_host.remove_child(child)
		child.free()
	var chrome := 1.0
	if is_inside_tree():
		chrome = UiViewportScale.factor(self)
	var pin := PIN_PX * chrome
	var pin_index := 0
	for index in AREAS.size():
		var measure := _pin_measure_rect(index)
		var plate := _pin_plate_size(index)
		if plate.x < 1.0 or plate.y < 1.0:
			continue
		for entry in _items_for(index):
			var placed: Dictionary = entry
			var tex_point := pin_tex_point(
				Vector2(float(placed.get("x", 0.0)), float(placed.get("y", 0.0))),
				plate,
				measure
			)
			var screen := _screen_point(tex_point)
			var mark := TextureRect.new()
			mark.name = "ItemPin%d" % pin_index
			mark.set_meta("pin_area", String(AREAS[index].get("name", "")))
			mark.set_meta("tex_point", tex_point)
			pin_index += 1
			mark.texture = _hand_frame()
			mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.custom_minimum_size = Vector2(pin, pin)
			mark.size = Vector2(pin, pin)
			mark.position = screen - mark.size * 0.5
			_pin_host.add_child(mark)
			var glyph_text := _pin_glyph(String(placed.get("id", "")))
			if not glyph_text.is_empty():
				var glyph := Label.new()
				glyph.name = "PinGlyph"
				glyph.text = glyph_text
				glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
				glyph.add_theme_font_override("font", UI_FONT)
				glyph.add_theme_font_size_override("font_size", maxi(roundi(16.0 * chrome), 10))
				glyph.add_theme_color_override("font_color", Color(0.92, 0.88, 0.88, 1.0))
				glyph.position = Vector2(pin * 0.42, -pin * 0.2)
				mark.add_child(glyph)


func _clear_cards() -> void:
	if _card_host == null:
		return
	for child in _card_host.get_children():
		child.queue_free()
	_card_host.visible = false
	_card_host.size = Vector2.ZERO


func _refresh_cards() -> void:
	if _card_host == null or _hover_index < 0:
		_clear_cards()
		return
	_clear_cards()
	var items := _items_for(_hover_index)
	if items.is_empty():
		return
	var chrome := 1.0
	if is_inside_tree():
		chrome = UiViewportScale.factor(self)
	var cursor := 0.0
	var widest := 0.0
	var gap := CARD_GAP * chrome
	for entry in items:
		var card := _make_item_card(entry as Dictionary, chrome)
		card.position = Vector2(0.0, cursor)
		_card_host.add_child(card)
		cursor += card.size.y + gap
		widest = maxf(widest, card.size.x)
	if cursor > 0.0:
		cursor -= gap
	_card_host.size = Vector2(widest, cursor)
	_place_card_host()
	_card_host.visible = true


func _place_card_host() -> void:
	var visual := _screen_rect(_measure_rect(_hover_index))
	if not _keeps_inside(_hover_index):
		visual = _grown(visual)
	var chrome := UiViewportScale.factor(self) if is_inside_tree() else 1.0
	var gap := CARD_GAP * chrome
	var view := _view_size()
	var pos := Vector2(visual.end.x + gap, visual.position.y)
	if pos.x + _card_host.size.x > view.x - gap:
		pos.x = visual.position.x - gap - _card_host.size.x
	pos.x = clampf(pos.x, gap, maxf(view.x - _card_host.size.x - gap, gap))
	pos.y = clampf(pos.y, gap, maxf(view.y - _card_host.size.y - gap, gap))
	_card_host.position = pos


func _make_item_card(entry: Dictionary, chrome: float) -> Control:
	var view := _item_view(String(entry.get("id", "")))
	var name_px := maxi(roundi(CARD_NAME_FONT * chrome), 10)
	var desc_px := maxi(roundi(CARD_DESC_FONT * chrome), 10)
	var icon_px := CARD_ICON_PX * chrome
	var title := String(view.get("name", ""))
	var body := String(view.get("description", ""))
	var title_w := maxf(UI_FONT.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, name_px).x, 32.0)
	var desc_size := UI_FONT.get_multiline_string_size(
		body, HORIZONTAL_ALIGNMENT_LEFT, title_w, desc_px
	)
	var text_h := UI_FONT.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, name_px).y + 2.0 + desc_size.y
	var row_h := maxf(icon_px, text_h)
	var pad_x := 12.0 * chrome
	var pad_y := 8.0 * chrome
	var card_size := Vector2(pad_x * 2.0 + icon_px + CARD_GAP * chrome + title_w, pad_y * 2.0 + row_h)

	var panel := PanelContainer.new()
	panel.name = "ItemCard"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = card_size
	panel.size = card_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.72)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.290196, 0, 0, 0.85)
	style.content_margin_left = pad_x
	style.content_margin_top = pad_y
	style.content_margin_right = pad_x
	style.content_margin_bottom = pad_y
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.name = "CardRow"
	row.add_theme_constant_override("separation", int(CARD_GAP * chrome))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)

	var icon := TextureRect.new()
	icon.name = "ItemIcon"
	icon.texture = view.get("icon") as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(icon_px, icon_px)
	icon.size = Vector2(icon_px, icon_px)
	row.add_child(icon)

	var text_col := VBoxContainer.new()
	text_col.name = "CardText"
	text_col.add_theme_constant_override("separation", 2)
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_col)

	var name_label := Label.new()
	name_label.name = "ItemName"
	name_label.text = title
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.custom_minimum_size = Vector2(title_w, 0.0)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuLook.apply_label(name_label, name_px, MenuLook.ACCENT)
	text_col.add_child(name_label)

	var desc_label := Label.new()
	desc_label.name = "ItemDescription"
	desc_label.text = body
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(title_w, desc_size.y)
	desc_label.custom_maximum_size = Vector2(title_w, -1.0)
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuLook.apply_label(desc_label, desc_px, MenuLook.TEXT)
	text_col.add_child(desc_label)
	return panel


func _item_view(item_id: String) -> Dictionary:
	var run := get_node_or_null("/root/AxelRun")
	var item: Resource = null
	if run != null and run.has_method("load_item"):
		item = run.call("load_item", item_id) as Resource
	if item == null:
		return {"name": item_id, "description": "", "icon": null}
	return {
		"name": ItemDef.rarity_name(item),
		"description": String(item.get("description")),
		"icon": item.get("icon"),
	}


class Highlight extends Control:
	var host: CanvasLayer

	func _draw() -> void:
		if host != null and host.has_method("paint_highlight"):
			host.call("paint_highlight", self)
