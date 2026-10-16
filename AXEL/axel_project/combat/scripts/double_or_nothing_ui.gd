extends Control

signal picked(pick: StringName)
signal collected()
signal ticked()

const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const BONUS_FX := preload("res://combat/scripts/bonus_intro_fx.gd")
const ICONS := {
	&"alcohol": preload("res://combat/art/grid_symbols/booze.png"),
	&"bloody_hand": preload("res://combat/art/grid_symbols/bloody_hand.png"),
	&"cigarette": preload("res://combat/art/grid_symbols/cigarette.png"),
}
const NAMES := {&"alcohol": "ALCOHOL", &"bloody_hand": "BLOODY HAND", &"cigarette": "CIGARETTE"}
const RED := Color(0.86, 0.08, 0.08, 1.0)
const DARK_RED := Color(0.45, 0.03, 0.03, 1.0)
const WHITE := Color(1.0, 1.0, 1.0, 1.0)
const GREY := Color(0.62, 0.58, 0.54, 1.0)
const TILE_FILL := Color(0.07, 0.06, 0.06, 1.0)
const TILE_EDGE := Color(0.26, 0.23, 0.21, 1.0)
const SCRIM_ALPHA := 0.45
const BAND_ALPHA := 0.6
const BAND_HALF := 200.0
const BAR_MARGIN := 24.0
const BULB_STEP_SEC := 0.08
const OPEN_SEC := 0.22
const CLOSE_SEC := 0.15
const CHOICE_ICON_PX := 132.0
const CHOICE_GAP := 130.0
const CHOICE_HIT_PAD := Vector2(70.0, 120.0)
const HOVER_SCALE := 1.15
const HOVER_SPEED := 10.0
const TILE_PX := 150.0
const TILE_GAP := 12.0
const BELT_START := 3.0
const BELT_SEC := 4.6
const BELT_FADE_FRAC := 0.24
const RESULT_IN_SEC := 0.25
const RESULT_HOLD_SEC := 1.1
const TITLE_SIZE := 64
const POT_SIZE := 48
const MULT_SIZE := 52
const NAME_SIZE := 28
const COLLECT_SIZE := 48
const RESULT_SIZE := 72
const OUTLINE_PX := 8
const LAYOUT_BASE_W := 1100.0

enum Mode { HIDDEN, CHOICE, BELT, RESULT }

var _mode := Mode.HIDDEN
var _t := 0.0
var _open_k := 0.0
var _pot := 0
var _calm := false
var _hover: StringName = &""
var _hover_k := {&"alcohol": 0.0, &"bloody_hand": 0.0, &"cigarette": 0.0}
var _collect_hover := false
var _belt: Array[StringName] = []
var _belt_pos := 0.0
var _last_tick := 0
var _land_index := 0
var _pick: StringName = &""
var _won := false
var _result_k := 0.0
var _open_tween: Tween
var _belt_tween: Tween
var _result_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func is_open() -> bool:
	return _mode != Mode.HIDDEN


func is_choosing() -> bool:
	return _mode == Mode.CHOICE


func open(pot: int, calm: bool) -> void:
	_pot = pot
	_calm = calm
	_mode = Mode.CHOICE
	_belt.clear()
	_pick = &""
	_hover = &""
	_collect_hover = false
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tween_open(1.0, OPEN_SEC)
	queue_redraw()


func close() -> void:
	_mode = Mode.HIDDEN
	_hover = &""
	_collect_hover = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tween_open(0.0, CLOSE_SEC)


func play_belt(round_data: Dictionary) -> void:
	_belt.clear()
	for id in round_data.get("belt", []):
		_belt.append(StringName(id))
	_land_index = int(round_data.get("land_index", 0))
	_pick = StringName(round_data.get("pick", &""))
	_won = bool(round_data.get("won", false))
	_result_k = 0.0
	_hover = &""
	_collect_hover = false
	_mode = Mode.BELT
	_belt_pos = BELT_START
	_last_tick = int(round(_belt_pos))
	var target := float(_land_index) + float(round_data.get("land_offset", 0.0))
	if _belt_tween != null and _belt_tween.is_valid():
		_belt_tween.kill()
	_belt_tween = create_tween()
	_belt_tween.tween_property(self, "_belt_pos", target, BELT_SEC).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	CombatPace.bind(_belt_tween)
	await _belt_tween.finished


func show_result(won: bool, pot: int) -> void:
	_won = won
	if won:
		_pot = pot
	_mode = Mode.RESULT
	_result_k = 0.0
	if _result_tween != null and _result_tween.is_valid():
		_result_tween.kill()
	_result_tween = create_tween()
	_result_tween.tween_property(self, "_result_k", 1.0, RESULT_IN_SEC)
	CombatPace.bind(_result_tween)
	await CombatPace.await_seconds(RESULT_HOLD_SEC)
	if won and _mode == Mode.RESULT:
		_mode = Mode.CHOICE


func _tween_open(to: float, sec: float) -> void:
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	_open_tween = create_tween()
	_open_tween.tween_property(self, "_open_k", to, sec)
	if to <= 0.0:
		_open_tween.tween_callback(_hide_if_closed)


func _hide_if_closed() -> void:
	if _mode == Mode.HIDDEN:
		visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	for id in _hover_k.keys():
		var goal := 1.0 if (_mode == Mode.CHOICE and id == _hover) else 0.0
		_hover_k[id] = move_toward(float(_hover_k[id]), goal, delta * HOVER_SPEED)
	if _mode == Mode.BELT:
		var idx := int(round(_belt_pos))
		if idx != _last_tick:
			_last_tick = idx
			ticked.emit()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if _mode != Mode.CHOICE:
		accept_event()
		return
	if event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position)
		accept_event()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
			accept_event()
			return
		_update_hover(mb.position)
		accept_event()
		if _hover != &"":
			picked.emit(_hover)
		elif _collect_hover:
			collected.emit()


func _update_hover(at: Vector2) -> void:
	_hover = &""
	for i in DoubleOrNothing.PICKS.size():
		if _choice_hit_rect(i).has_point(at):
			_hover = DoubleOrNothing.PICKS[i]
	_collect_hover = _hover == &"" and _collect_rect().has_point(at)


func _view() -> Vector2:
	if size.x >= 64.0 and size.y >= 64.0:
		return size
	var vp := get_viewport()
	if vp != null:
		return vp.get_visible_rect().size
	return Vector2(1920.0, 1280.0)


func _s() -> float:
	return clampf(_view().x / LAYOUT_BASE_W, 0.45, 1.0)


func _band_rect() -> Rect2:
	var v := _view()
	var half := BAND_HALF * _s()
	return Rect2(0.0, v.y * 0.5 - half, v.x, half * 2.0)


func _choice_center(i: int) -> Vector2:
	var s := _s()
	var band := _band_rect()
	var step := (CHOICE_ICON_PX + CHOICE_GAP) * s
	return Vector2(_view().x * 0.5 + float(i - 1) * step, band.get_center().y - 6.0 * s)


func _choice_hit_rect(i: int) -> Rect2:
	var s := _s()
	var c := _choice_center(i)
	var w := (CHOICE_ICON_PX + CHOICE_HIT_PAD.x) * s
	var h := (CHOICE_ICON_PX + CHOICE_HIT_PAD.y) * s
	return Rect2(c.x - w * 0.5, c.y - CHOICE_ICON_PX * s * 0.5 - 16.0 * s, w, h)


func _collect_text() -> String:
	return "[%s] COLLECT" % _interact_key_name()


func _collect_rect() -> Rect2:
	var s := _s()
	var fs := int(COLLECT_SIZE * s)
	var text_size := FONT.get_string_size(_collect_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var band := _band_rect()
	var center := Vector2(_view().x * 0.5, band.end.y + 62.0 * s)
	var pad := Vector2(24.0, 12.0) * s
	return Rect2(center - text_size * 0.5 - pad, text_size + pad * 2.0)


func _interact_key_name() -> String:
	for ev in InputMap.action_get_events("interact"):
		if ev is InputEventKey:
			var key := ev as InputEventKey
			var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
			var label := OS.get_keycode_string(code)
			if label != "":
				return label.to_upper()
	return "E"


func _ink(id: StringName) -> Texture2D:
	return BONUS_FX._ink_texture(ICONS.get(id) as Texture2D)


func _draw() -> void:
	if not visible:
		return
	var a := _open_k
	if a <= 0.001:
		return
	var v := _view()
	var s := _s()
	draw_rect(Rect2(Vector2.ZERO, v), Color(0.0, 0.0, 0.0, SCRIM_ALPHA * a))
	var band := _band_rect()
	draw_rect(band, Color(0.0, 0.0, 0.0, BAND_ALPHA * a))
	var grow := 1.0 - pow(1.0 - a, 3.0)
	MarqueeBars.draw_bar(self, band.position.y, BAR_MARGIN, v.x - BAR_MARGIN, grow, true, a, _t, BULB_STEP_SEC)
	MarqueeBars.draw_bar(self, band.end.y, BAR_MARGIN, v.x - BAR_MARGIN, grow, false, a, _t, BULB_STEP_SEC)
	_draw_title(band, s, a)
	_draw_pot(band, s, a)
	if _mode == Mode.CHOICE or (_mode == Mode.HIDDEN and _belt.is_empty()):
		_draw_choices(s, a)
		_draw_collect(s, a)
	elif _mode == Mode.BELT or _mode == Mode.RESULT or _mode == Mode.HIDDEN:
		_draw_belt(band, s, a)
		_draw_belt_caption(band, s, a)


func _draw_text(text: String, center: Vector2, font_size: int, color: Color, alpha: float) -> void:
	var w := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := Vector2(center.x - w * 0.5, center.y + float(font_size) * 0.3)
	var outline := Color(0.0, 0.0, 0.0, alpha)
	draw_string_outline(FONT, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, OUTLINE_PX, outline)
	draw_string(FONT, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color.r, color.g, color.b, color.a * alpha))


func _draw_two_tone(left: String, right: String, center: Vector2, font_size: int, alpha: float) -> void:
	var lw := FONT.get_string_size(left, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var rw := FONT.get_string_size(right, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x := center.x - (lw + rw) * 0.5
	_draw_text(left, Vector2(x + lw * 0.5, center.y), font_size, WHITE, alpha)
	_draw_text(right, Vector2(x + lw + rw * 0.5, center.y), font_size, RED, alpha)


func _draw_title(band: Rect2, s: float, a: float) -> void:
	_draw_two_tone("DOUBLE OR ", "NOTHING", Vector2(band.get_center().x, band.position.y - 52.0 * s), int(TITLE_SIZE * s), a)


func _draw_pot(band: Rect2, s: float, a: float) -> void:
	_draw_two_tone("POT  ", "%d" % _pot, Vector2(band.get_center().x, band.position.y + 40.0 * s), int(POT_SIZE * s), a)


func _draw_choices(s: float, a: float) -> void:
	for i in DoubleOrNothing.PICKS.size():
		var id: StringName = DoubleOrNothing.PICKS[i]
		var c := _choice_center(i)
		var hk := float(_hover_k[id])
		var px := CHOICE_ICON_PX * s * (1.0 + (HOVER_SCALE - 1.0) * hk)
		if hk > 0.01:
			draw_circle(c, px * 0.7, Color(1.0, 1.0, 1.0, 0.06 * hk * a))
			draw_circle(c, px * 0.5, Color(1.0, 1.0, 1.0, 0.1 * hk * a))
		var tex := _ink(id)
		if tex != null:
			draw_texture_rect(tex, Rect2(c - Vector2(px, px) * 0.5, Vector2(px, px)), false, Color(1.0, 1.0, 1.0, a))
		var mult := DoubleOrNothing.multiplier_for(id)
		var below := c.y + CHOICE_ICON_PX * s * 0.5
		_draw_text("x%d" % mult, Vector2(c.x, below + 40.0 * s), int(MULT_SIZE * s), RED if id == &"bloody_hand" else WHITE, a)
		_draw_text(String(NAMES[id]), Vector2(c.x, below + 82.0 * s), int(NAME_SIZE * s), GREY, a)


func _draw_collect(s: float, a: float) -> void:
	var r := _collect_rect()
	if _collect_hover:
		draw_rect(r, Color(DARK_RED.r, DARK_RED.g, DARK_RED.b, 0.85 * a))
	draw_rect(r, Color(RED.r, RED.g, RED.b, a), false, maxf(2.0 * s, 1.0))
	_draw_text(_collect_text(), r.get_center(), int(COLLECT_SIZE * s), WHITE, a)


func _draw_belt(band: Rect2, s: float, a: float) -> void:
	var v := _view()
	var tile := TILE_PX * s
	var step := (TILE_PX + TILE_GAP) * s
	var cx := v.x * 0.5
	var cy := band.get_center().y + 28.0 * s
	var reach := cx / step + 2.0
	var first := maxi(int(floor(_belt_pos - reach)), 0)
	var last := mini(int(ceil(_belt_pos + reach)), _belt.size() - 1)
	for i in range(first, last + 1):
		var x := cx + (float(i) - _belt_pos) * step
		var r := Rect2(x - tile * 0.5, cy - tile * 0.5, tile, tile)
		var id: StringName = _belt[i]
		var landed := _mode == Mode.RESULT and i == _land_index
		var dim := 1.0
		if _mode == Mode.RESULT and not landed:
			dim = 1.0 - 0.55 * _result_k
		draw_rect(r, Color(TILE_FILL.r, TILE_FILL.g, TILE_FILL.b, a))
		var edge := RED if id == &"bloody_hand" else GREY
		draw_rect(Rect2(r.position.x, r.end.y - 7.0 * s, tile, 7.0 * s), Color(edge.r, edge.g, edge.b, a * dim))
		draw_rect(r, Color(TILE_EDGE.r, TILE_EDGE.g, TILE_EDGE.b, a * dim), false, maxf(2.0 * s, 1.0))
		var tex := _ink(id)
		if tex != null:
			var inset := 20.0 * s
			draw_texture_rect(tex, Rect2(r.position + Vector2(inset, inset * 0.8), Vector2(tile - inset * 2.0, tile - inset * 2.0)), false, Color(dim, dim, dim, a))
		if landed:
			var ring := WHITE if _won else RED
			var pulse := 1.0 if _calm else 0.65 + 0.35 * sin(_t * 14.0)
			draw_rect(r.grow(6.0 * s), Color(ring.r, ring.g, ring.b, a * _result_k * pulse), false, maxf(5.0 * s, 2.0))
	_draw_belt_fades(cy, tile, s, a)
	var needle_top := cy - tile * 0.5 - 24.0 * s
	var needle_bottom := cy + tile * 0.5 + 24.0 * s
	draw_rect(Rect2(cx - 2.0 * s, needle_top, 4.0 * s, needle_bottom - needle_top), Color(1.0, 1.0, 1.0, a))
	var tri := 14.0 * s
	draw_colored_polygon(PackedVector2Array([Vector2(cx - tri, needle_top - tri), Vector2(cx + tri, needle_top - tri), Vector2(cx, needle_top + 2.0)]), Color(1.0, 1.0, 1.0, a))
	draw_colored_polygon(PackedVector2Array([Vector2(cx - tri, needle_bottom + tri), Vector2(cx + tri, needle_bottom + tri), Vector2(cx, needle_bottom - 2.0)]), Color(1.0, 1.0, 1.0, a))


func _draw_belt_fades(cy: float, tile: float, s: float, a: float) -> void:
	var v := _view()
	var w := v.x * BELT_FADE_FRAC
	var top := cy - tile * 0.5 - 4.0 * s
	var bottom := cy + tile * 0.5 + 4.0 * s
	var solid := Color(0.0, 0.0, 0.0, a)
	var clear := Color(0.0, 0.0, 0.0, 0.0)
	draw_polygon(
		PackedVector2Array([Vector2(0.0, top), Vector2(w, top), Vector2(w, bottom), Vector2(0.0, bottom)]),
		PackedColorArray([solid, clear, clear, solid])
	)
	draw_polygon(
		PackedVector2Array([Vector2(v.x - w, top), Vector2(v.x, top), Vector2(v.x, bottom), Vector2(v.x - w, bottom)]),
		PackedColorArray([clear, solid, solid, clear])
	)


func _draw_belt_caption(band: Rect2, s: float, a: float) -> void:
	var at := Vector2(band.get_center().x, band.end.y + 62.0 * s)
	if _mode == Mode.RESULT:
		var k := a * _result_k
		if _won:
			_draw_two_tone("YOU WIN  ", "x%d" % DoubleOrNothing.multiplier_for(_pick), at, int(RESULT_SIZE * s), k)
		else:
			_draw_text("NOTHING", at, int(RESULT_SIZE * s), RED, k)
		return
	if _pick == &"":
		return
	_draw_two_tone("%s  " % String(NAMES.get(_pick, "")), "x%d" % DoubleOrNothing.multiplier_for(_pick), at, int(COLLECT_SIZE * s), a)
