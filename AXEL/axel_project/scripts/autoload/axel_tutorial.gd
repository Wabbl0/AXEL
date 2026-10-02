extends Node

const CrtPowerFx := preload("res://scenes/ui/crt_power_fx.gd")
const PieceHighlightGlow := preload("res://combat/scripts/piece_highlight_glow.gd")
const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const OPEN_STREAM: AudioStreamWAV = preload("res://assets/audio/axel_typewriter_open.wav")
const TYPE_STREAM: AudioStreamWAV = preload("res://assets/audio/axel_typewriter_v4.wav")

const CARD_W := 520.0
const CARD_H := 860.0
const CARD_MARGIN := 36.0
const STACK_GAP_PX := 16.0
const STACK_OPEN_GAP_SEC := 5.0
const REF_H := 1280.0
const FONT_PX := 32.0
const OUTLINE_PX := 4.0
const CHARS_PER_SEC := 35.0
const TITLE_MARK_GAP := 18.0
const AUTO_READING_BASE_SEC := 3.0
const AUTO_READING_SQRT := 0.5774
const AUTO_READING_MAX_SEC := 20.0
const AUTO_SKIP_GRACE_SEC := 2.0
const GLOW_STEADY := 0.45
const GLOW_PULSE_SEC := 1.6
const GLOW_FADE_OUT_SEC := 0.35
const GLOW_ALPHA_MIN := 0.0
const GLOW_ALPHA_MAX := 1.0

const LESSONS := {
	"move_walk": {
		"title": "Moving",
		"body": "WASD or the arrow keys walk.",
	},
	"fight_spin": {
		"title": "Fights",
		"body": "Click the skull, or press E, to spin. Match 3 or more of the same picture in a row or a column.",
	},
	"fight_stakes": {
		"title": "Fights",
		"body": "BALANCE is your chips. The bet is spent each spin. Fill GOAL to win. If you cannot pay another spin, you lose.",
	},
	"fight_items": {
		"title": "Fights",
		"body": "Equipped items sit on the left. They act on their own. Hover a name to read it.",
	},
	"items_hand": {
		"title": "Items",
		"body": "That is an item. Press E to take it. It equips by itself if you have a free slot.",
	},
	"items_wheel": {
		"title": "Items",
		"body": "Tab, Q, R, or I opens your items. Clicking MIKE does too. Click to switch.",
	},
}

const GLOW_PIECES := {
	"fight_spin": ["NEW_Execute", "NEW_Grid"],
	"fight_stakes": ["NEW_Bets", "NEW_Goal"],
	"fight_items": ["NEW_Items"],
}

enum Phase { IDLE, OPENING, TYPING, WAITING, CLOSING }

var _debug_enabled := false
var _queue: Array[String] = []
var _marked: Dictionary = {}
var _hud_rects: Dictionary = {}
var _reversed_open: AudioStreamWAV
var _stack_gap_left := 0.0
var _glow_pieces: Dictionary = {}
var _glow_on_ms: Dictionary = {}
var _glow_off: Dictionary = {}
var _glow_last_alpha: Dictionary = {}

var _card_layer: CanvasLayer
var _slots: Array = []
var _title_font: FontVariation
var _open_player: AudioStreamPlayer
var _type_player: AudioStreamPlayer


class CardSlot:
	var index: int = 0
	var phase: int = Phase.IDLE
	var open_id: String = ""
	var body_text: String = ""
	var typed: int = 0
	var type_acc: float = 0.0
	var wait_left: float = 0.0
	var run_token: int = 0
	var laid_out: bool = false
	var card_host: Control
	var fade_root: Control
	var bar_panel: PanelContainer
	var inner_panel: PanelContainer
	var beam: ColorRect
	var bloom: ColorRect
	var title: Label
	var body: Label
	var mark: Label
	var mark_end: Label
	var header: HBoxContainer
	var column: VBoxContainer
	var exit: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reversed_open = _make_reversed_wav(OPEN_STREAM)
	_build()
	get_tree().scene_changed.connect(_on_scene_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)


func debug_set_enabled(enabled: bool) -> void:
	_debug_enabled = enabled


func request(id: String) -> void:
	if not _allows():
		return
	if not LESSONS.has(id):
		return
	if _is_seen(id) or _queue.has(id) or _is_showing_id(id):
		return
	_queue.append(id)


func is_open() -> bool:
	for slot in _slots:
		if slot.phase != Phase.IDLE:
			return true
	return false


func is_waiting() -> bool:
	for slot in _slots:
		if slot.phase == Phase.WAITING:
			return true
	return false


func blocks_spin() -> bool:
	if is_open():
		return true
	for id in _queue:
		if _is_fight(id):
			return true
	return false


func suppresses_skull_hint() -> bool:
	for slot in _slots:
		if not _is_fight(slot.open_id):
			continue
		if (
			slot.phase == Phase.OPENING
			or slot.phase == Phase.TYPING
			or slot.phase == Phase.WAITING
		):
			return true
	return false


func wants_hud_rects() -> bool:
	if suppresses_skull_hint():
		return true
	for id in _queue:
		if _is_fight(id):
			return true
	return false


func glow_piece_names(id: String) -> PackedStringArray:
	if not GLOW_PIECES.has(id):
		return PackedStringArray()
	return PackedStringArray(GLOW_PIECES[id])


func set_hud_rects(rects: Dictionary) -> void:
	_hud_rects = rects.duplicate()
	_layout_cards()
	_sync_glows()


func card_rect() -> Rect2:
	if _slots.is_empty() or _slots[0].card_host == null:
		return Rect2()
	return _slots[0].card_host.get_global_rect()


func claims_point(pos: Vector2) -> bool:
	for slot in _slots:
		if slot.phase == Phase.IDLE:
			continue
		if slot.exit != null and slot.exit.visible and slot.exit.get_global_rect().has_point(pos):
			return true
		if slot.card_host != null and slot.card_host.visible and slot.card_host.get_global_rect().has_point(pos):
			return true
	return false


func debug_dismiss() -> void:
	_dismiss_one_card()


func _allows() -> bool:
	if _debug_enabled:
		return true
	return DisplayServer.get_name() != "headless"


func _is_fight(id: String) -> bool:
	return GLOW_PIECES.has(id)


func _is_seen(id: String) -> bool:
	if _marked.has(id):
		return true
	var run := get_node_or_null("/root/AxelRun")
	if run == null:
		return false
	return run.state.tutorial_seen.has(id)


func _is_showing_id(id: String) -> bool:
	for slot in _slots:
		if slot.open_id == id and slot.phase != Phase.IDLE:
			return true
	return false


func _mark_seen(id: String) -> void:
	if id.is_empty() or _marked.has(id):
		return
	_marked[id] = true
	var run := get_node_or_null("/root/AxelRun")
	if run != null:
		var seen: PackedStringArray = run.state.tutorial_seen
		if not seen.has(id):
			seen.append(id)
			run.state.tutorial_seen = seen
	var saves := get_node_or_null("/root/AxelSaves")
	if saves != null and saves.has_method("save_active"):
		saves.call("save_active")


func _process(delta: float) -> void:
	if _focus_frozen():
		return
	if _stack_gap_left > 0.0:
		_stack_gap_left = maxf(0.0, _stack_gap_left - delta)
	for slot in _slots:
		if slot.phase == Phase.TYPING:
			_advance_type(slot, delta)
		elif slot.phase == Phase.WAITING:
			slot.wait_left -= delta
			if slot.wait_left <= 0.0:
				_start_close(slot)
	_sync_glows()
	_try_start()


func _free_slot_index() -> int:
	for i in _slots.size():
		if _slots[i].phase == Phase.IDLE:
			return i
	return -1


func _try_start() -> void:
	if _queue.is_empty() or _story_busy():
		return
	var idx := _free_slot_index()
	if idx < 0:
		return
	if is_open() and _stack_gap_left > 0.0:
		return
	var id := _queue[0]
	_queue.remove_at(0)
	_open_slot(idx, id)
	_stack_gap_left = STACK_OPEN_GAP_SEC


func _open_slot(idx: int, id: String) -> void:
	var slot: CardSlot = _slots[idx]
	slot.open_id = id
	slot.phase = Phase.OPENING
	slot.laid_out = false
	_run_card(slot, id)


func _run_card(slot: CardSlot, id: String) -> void:
	var token := _bump_token(slot)
	var lesson: Dictionary = LESSONS[id]
	slot.body_text = String(lesson["body"])
	slot.typed = 0
	slot.type_acc = 0.0
	slot.title.text = String(lesson["title"])
	slot.body.text = ""
	slot.card_host.visible = true
	if slot.exit != null:
		slot.exit.visible = true
	_layout_cards()
	_sync_glows()
	_play_open()
	await CrtPowerFx.power_on(self, slot.fade_root, slot.bar_panel, slot.beam, slot.bloom)
	if token != slot.run_token or slot.open_id != id or slot.phase != Phase.OPENING:
		return
	slot.phase = Phase.TYPING
	_play_type_loop()


func _advance_type(slot: CardSlot, delta: float) -> void:
	if slot.body_text.is_empty():
		_begin_wait(slot, false)
		return
	slot.type_acc += delta * CHARS_PER_SEC
	var add := int(slot.type_acc)
	if add <= 0:
		return
	slot.type_acc -= float(add)
	slot.typed = mini(slot.typed + add, slot.body_text.length())
	slot.body.text = slot.body_text.substr(0, slot.typed)
	if slot.typed >= slot.body_text.length():
		_begin_wait(slot, false)


func _begin_wait(slot: CardSlot, from_skip: bool) -> void:
	slot.phase = Phase.WAITING
	_refresh_type_loop()
	if from_skip:
		slot.wait_left = AUTO_SKIP_GRACE_SEC
	else:
		slot.wait_left = _reading_duration_sec(slot.body_text)


func _reading_duration_sec(text: String) -> float:
	var word_count := text.split(" ", false).size()
	var extra_words := maxf(float(word_count - 1), 0.0)
	return clampf(
		AUTO_READING_BASE_SEC + AUTO_READING_SQRT * sqrt(extra_words),
		AUTO_READING_BASE_SEC,
		AUTO_READING_MAX_SEC,
	)


func _dismiss_one_card() -> void:
	for slot in _slots:
		if slot.phase == Phase.TYPING:
			slot.body.text = slot.body_text
			slot.typed = slot.body_text.length()
			_begin_wait(slot, true)
			return
	for slot in _slots:
		if slot.phase == Phase.WAITING:
			_start_close(slot)
			return


func _on_exit_pressed_slot(idx: int) -> void:
	if idx < 0 or idx >= _slots.size():
		return
	var slot: CardSlot = _slots[idx]
	if slot.phase == Phase.IDLE or slot.phase == Phase.CLOSING:
		return
	if slot.phase == Phase.TYPING or slot.phase == Phase.OPENING:
		slot.body.text = slot.body_text
		slot.typed = slot.body_text.length()
		slot.phase = Phase.WAITING
		_refresh_type_loop()
	_start_close(slot)


func _start_close(slot: CardSlot) -> void:
	if slot.phase != Phase.WAITING:
		return
	var id := slot.open_id
	slot.phase = Phase.CLOSING
	_mark_seen(id)
	_sync_glows()
	_refresh_type_loop()
	_play_close()
	var token := _bump_token(slot)
	await CrtPowerFx.power_off(self, slot.fade_root, slot.bar_panel, slot.beam, slot.bloom)
	if token != slot.run_token:
		return
	slot.phase = Phase.IDLE
	slot.open_id = ""
	slot.body_text = ""
	slot.laid_out = false
	if slot.card_host != null:
		slot.card_host.visible = false
	if slot.exit != null:
		slot.exit.visible = false
	_layout_cards()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or event.is_echo():
		return
	if not _is_dismiss_event(event):
		return
	get_viewport().set_input_as_handled()
	_dismiss_one_card()


func _is_dismiss_event(event: InputEvent) -> bool:

	if event.is_action_pressed("back"):
		return true
	if event.is_action_pressed("pause"):
		return true
	if event.is_action_pressed("item_wheel"):
		return true
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		return mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	return false


func _story_busy() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var overlay := scene.get_node_or_null("TopDialogueOverlay")
	if overlay == null:
		overlay = scene.find_child("TopDialogueOverlay", true, false)
	if overlay != null and overlay.has_method("is_sequence_busy"):
		return bool(overlay.call("is_sequence_busy"))
	return false


func _on_scene_changed() -> void:
	_hud_rects.clear()
	_hide_glows()


func _on_viewport_resized() -> void:
	if is_open():
		_layout_cards()


func _viewport_size() -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	if vp.x < 2.0 or vp.y < 2.0:
		return Vector2(1920.0, 1280.0)
	return vp


func _layout_cards() -> void:
	if _slots.is_empty():
		return
	var vp := _viewport_size()
	var scale := vp.y / REF_H
	var margin := CARD_MARGIN * scale
	var width := CARD_W * scale
	var gap := STACK_GAP_PX * scale
	var base_y := (vp.y - CARD_H * scale) * 0.5
	var x := vp.x - margin - width
	var s0: CardSlot = _slots[0]
	var s1: CardSlot = _slots[1]
	var show0 := s0.phase != Phase.IDLE and s0.card_host != null and s0.card_host.visible
	var show1 := s1.phase != Phase.IDLE and s1.card_host != null and s1.card_host.visible
	var h0 := 0.0
	var h1 := 0.0
	if show0:
		h0 = _measured_height(s0, scale, width)
	if show1:
		h1 = _measured_height(s1, scale, width)
	if show0 and show1:
		var y0 := base_y
		var y1 := y0 + h0 + gap
		var bottom := y1 + h1
		var limit := vp.y - margin
		if bottom > limit:
			var shift := bottom - limit
			y0 -= shift
			y1 -= shift
		_apply_slot_rect(s0, x, y0, width, h0, scale)
		_apply_slot_rect(s1, x, y1, width, h1, scale)
	elif show0:
		_apply_slot_rect(s0, x, base_y, width, h0, scale)
	elif show1:
		var y1 := s1.card_host.position.y
		if not s1.laid_out:
			y1 = base_y
		_apply_slot_rect(s1, x, y1, width, h1, scale)

	if show0 and s0.exit != null:
		UiViewportScale.apply_exit_button(s0.exit, scale * 0.5)
	if show1 and s1.exit != null:
		UiViewportScale.apply_exit_button(s1.exit, scale * 0.5)


func _apply_slot_rect(
	slot: CardSlot, x: float, y: float, width: float, height: float, scale: float
) -> void:
	slot.card_host.set_anchors_preset(Control.PRESET_TOP_LEFT)
	slot.card_host.position = Vector2(x, y)
	slot.card_host.size = Vector2(width, height)
	slot.card_host.custom_minimum_size = Vector2(width, height)
	slot.laid_out = true
	_apply_chrome(slot, scale, width)
	CrtPowerFx.reset_pivot(slot.bar_panel)


func _apply_chrome(slot: CardSlot, scale: float, host_w: float) -> void:
	slot.bar_panel.add_theme_stylebox_override("panel", _outer_style(scale))
	slot.inner_panel.add_theme_stylebox_override("panel", _inner_style(scale))
	var font_size := maxi(12, int(round(FONT_PX * scale)))
	var outline := maxi(1, int(round(OUTLINE_PX * scale)))
	var inner_w := maxf(40.0, host_w - 44.0 * scale)
	for lab in [slot.mark, slot.mark_end, slot.title, slot.body]:
		lab.add_theme_font_size_override("font_size", font_size)
		lab.add_theme_constant_override("outline_size", outline)
	var gap := TITLE_MARK_GAP * scale
	slot.header.add_theme_constant_override("separation", maxi(1, int(round(gap))))
	slot.title.autowrap_mode = TextServer.AUTOWRAP_OFF
	slot.title.clip_text = false
	slot.title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_w := 0.0
	if _title_font != null and not slot.title.text.is_empty():
		title_w = _title_font.get_string_size(
			slot.title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
		).x
	var side := float(outline) + 2.0 * scale
	slot.title.custom_minimum_size.x = title_w + side * 2.0
	slot.body.custom_maximum_size = Vector2(inner_w, -1.0)


func _outer_style(scale: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var pad := 14.0 * scale
	var pad_y := 10.0 * scale
	style.content_margin_left = pad
	style.content_margin_right = pad
	style.content_margin_top = pad_y
	style.content_margin_bottom = pad_y
	style.bg_color = Color8(48, 0, 0)
	style.border_color = Color.BLACK
	style.set_border_width_all(3)
	style.shadow_color = Color(0, 0, 0, 0.9)
	style.shadow_size = maxi(1, int(round(6.0 * scale)))
	style.shadow_offset = Vector2(8.0, 10.0) * scale
	return style


func _inner_style(scale: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var pad := 8.0 * scale
	var pad_y := 6.0 * scale
	style.content_margin_left = pad
	style.content_margin_right = pad
	style.content_margin_top = pad_y
	style.content_margin_bottom = pad_y
	style.bg_color = Color8(32, 0, 0)
	style.set_border_width_all(0)
	return style


func _open_fight_glow_names() -> Dictionary:
	var wanted: Dictionary = {}
	for slot in _slots:
		if not _is_fight(slot.open_id):
			continue
		if (
			slot.phase != Phase.OPENING
			and slot.phase != Phase.TYPING
			and slot.phase != Phase.WAITING
		):
			continue
		for piece_name in glow_piece_names(slot.open_id):
			wanted[String(piece_name)] = true
	return wanted


func _sync_glows() -> void:
	var wanted := _open_fight_glow_names()
	if wanted.is_empty() and _glow_on_ms.is_empty() and _glow_off.is_empty():
		_hide_glows()
		return
	var scene := get_tree().current_scene
	if scene == null:
		_hide_glows()
		return
	var now := Time.get_ticks_msec()
	var all_names: Dictionary = {}
	for lesson_id in GLOW_PIECES.keys():
		for piece_name in GLOW_PIECES[lesson_id]:
			all_names[String(piece_name)] = true
	for piece_name in all_names.keys():
		var piece: Control = null
		if _glow_pieces.has(piece_name) and is_instance_valid(_glow_pieces[piece_name]):
			piece = _glow_pieces[piece_name] as Control
		else:
			piece = scene.find_child(piece_name, true, false) as Control
			if piece != null:
				_glow_pieces[piece_name] = piece
		if piece == null:
			continue
		if wanted.has(piece_name):
			_glow_off.erase(piece_name)
			if not _glow_on_ms.has(piece_name):
				_glow_on_ms[piece_name] = now
			PieceHighlightGlow.set_highlight(piece, true)
			var alpha := _glow_alpha(float(now - int(_glow_on_ms[piece_name])) * 0.001)
			_glow_last_alpha[piece_name] = alpha
			PieceHighlightGlow.pulse_highlights(piece, alpha)
			continue
		if _glow_on_ms.has(piece_name):
			_glow_on_ms.erase(piece_name)
			_glow_off[piece_name] = now
		if _glow_off.has(piece_name):
			var t := float(now - int(_glow_off[piece_name])) * 0.001 / GLOW_FADE_OUT_SEC
			if t < 1.0:
				var from := float(_glow_last_alpha.get(piece_name, GLOW_ALPHA_MAX))
				PieceHighlightGlow.pulse_highlights(piece, from * (1.0 - t))
				continue
			_glow_off.erase(piece_name)
			_glow_last_alpha.erase(piece_name)
		PieceHighlightGlow.set_highlight(piece, false)


func _glow_alpha(elapsed_sec: float) -> float:
	var settings := get_node_or_null("/root/AxelSettings")
	var steady := false
	if settings != null and settings.has_method("get_value"):
		steady = bool(settings.call("get_value", "access", "reduce_flashing", false))
	if steady:
		return GLOW_STEADY
	var wave := 0.5 - 0.5 * cos(elapsed_sec * TAU / GLOW_PULSE_SEC)
	return lerpf(GLOW_ALPHA_MIN, GLOW_ALPHA_MAX, wave)


func _focus_frozen() -> bool:
	var pause := get_node_or_null("/root/AxelPause")
	return pause != null and pause.has_method("is_focus_frozen") and bool(pause.call("is_focus_frozen"))


func _measured_height(slot: CardSlot, scale: float, host_w: float) -> float:
	var font_size := maxi(12, int(round(FONT_PX * scale)))
	var inner_w := maxf(40.0, host_w - 44.0 * scale)
	var gap := 8.0 * scale
	var mark_w := FONT.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var title_w := maxf(40.0, inner_w - mark_w * 2.0 - gap * 2.0)
	var title_h := _block_height_font(_title_font, slot.title.text, title_w, font_size)
	var body_h := _block_height(slot.body_text, inner_w, font_size)
	var chrome_y := (10.0 + 6.0) * 2.0 * scale + 6.0
	return title_h + body_h + chrome_y


func _block_height(text: String, width: float, font_size: int) -> float:
	return _block_height_font(FONT, text, width, font_size)


func _block_height_font(font: Font, text: String, width: float, font_size: int) -> float:
	if font == null:
		return _block_height(text, width, font_size)
	var line_h := font.get_height(font_size)
	if text.is_empty():
		return line_h
	var size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size)
	return maxf(size.y, line_h)


func _hide_glows() -> void:
	for piece_name in _glow_pieces.keys():
		var piece: Control = _glow_pieces[piece_name] as Control
		if piece == null or not is_instance_valid(piece):
			continue
		PieceHighlightGlow.set_highlight(piece, false)
	_glow_pieces.clear()
	_glow_on_ms.clear()
	_glow_off.clear()
	_glow_last_alpha.clear()


func _build() -> void:
	_card_layer = CanvasLayer.new()
	_card_layer.name = "CardLayer"
	_card_layer.layer = 114
	add_child(_card_layer)

	_title_font = FontVariation.new()
	_title_font.base_font = FONT
	_title_font.variation_embolden = 0.8

	_slots.append(_make_slot(0, "CardHost"))
	_slots.append(_make_slot(1, "CardHost2"))

	_open_player = AudioStreamPlayer.new()
	_open_player.name = "OpenClosePlayer"
	_open_player.bus = &"TypewriterOpen"
	_open_player.volume_db = -6.0
	_open_player.stream = OPEN_STREAM
	add_child(_open_player)

	_type_player = AudioStreamPlayer.new()
	_type_player.name = "TypeLoopPlayer"
	_type_player.bus = &"Typewriter"
	_type_player.stream = TYPE_STREAM
	_type_player.finished.connect(_on_type_finished)
	add_child(_type_player)


func _make_slot(index: int, host_name: String) -> CardSlot:
	var slot := CardSlot.new()
	slot.index = index

	slot.card_host = Control.new()
	slot.card_host.name = host_name
	slot.card_host.visible = false
	slot.card_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_layer.add_child(slot.card_host)

	slot.fade_root = Control.new()
	slot.fade_root.name = "FadeRoot"
	slot.fade_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.fade_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.fade_root.modulate.a = 0.0
	slot.card_host.add_child(slot.fade_root)

	slot.bar_panel = PanelContainer.new()
	slot.bar_panel.name = "BarPanel"
	slot.bar_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.bar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.fade_root.add_child(slot.bar_panel)

	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	slot.beam = ColorRect.new()
	slot.beam.name = "PowerBeam"
	slot.beam.color = Color.WHITE
	slot.beam.modulate.a = 0.0
	slot.beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.beam.material = add_mat
	slot.beam.z_index = 2
	slot.bar_panel.add_child(slot.beam)

	slot.inner_panel = PanelContainer.new()
	slot.inner_panel.name = "InnerPanel"
	slot.inner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.bar_panel.add_child(slot.inner_panel)

	slot.column = VBoxContainer.new()
	slot.column.name = "TextColumn"
	slot.column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	slot.column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.inner_panel.add_child(slot.column)

	slot.header = HBoxContainer.new()
	slot.header.name = "HeaderRow"
	slot.header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.column.add_child(slot.header)

	slot.mark = _make_label("MarkLabel")
	slot.mark.text = "?"
	slot.mark.autowrap_mode = TextServer.AUTOWRAP_OFF
	slot.mark.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	slot.header.add_child(slot.mark)

	slot.title = _make_label("TitleLabel")
	slot.title.add_theme_font_override("font", _title_font)
	slot.title.autowrap_mode = TextServer.AUTOWRAP_OFF
	slot.title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	slot.title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot.header.add_child(slot.title)

	slot.mark_end = _make_label("MarkEndLabel")
	slot.mark_end.text = "?"
	slot.mark_end.autowrap_mode = TextServer.AUTOWRAP_OFF
	slot.mark_end.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	slot.header.add_child(slot.mark_end)

	slot.body = _make_label("BodyLabel")
	slot.body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	slot.column.add_child(slot.body)

	slot.bloom = ColorRect.new()
	slot.bloom.name = "Bloom"
	slot.bloom.color = Color(1, 0, 0, 1)
	slot.bloom.modulate.a = 0.0
	slot.bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.bloom.material = add_mat
	slot.bloom.z_index = 3
	slot.bar_panel.add_child(slot.bloom)

	slot.exit = Button.new()
	slot.exit.name = "ExitButton"
	slot.exit.text = "X"
	slot.exit.visible = false
	slot.exit.focus_mode = Control.FOCUS_NONE
	slot.exit.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.exit.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	slot.exit.add_theme_font_override("font", FONT)
	slot.exit.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	slot.exit.add_theme_color_override("font_pressed_color", Color(0.75, 0, 0, 1))
	slot.exit.add_theme_color_override("font_hover_color", Color(1, 0.25, 0.25, 1))
	slot.exit.pressed.connect(_on_exit_pressed_slot.bind(index))
	slot.exit.z_index = 8
	slot.card_host.add_child(slot.exit)

	return slot


func _make_label(node_name: String) -> Label:
	var lab := Label.new()
	lab.name = node_name
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.add_theme_font_override("font", FONT)
	lab.add_theme_color_override("font_color", Color.WHITE)
	lab.add_theme_color_override("font_outline_color", Color.BLACK)
	lab.add_theme_constant_override("outline_size", 4)
	return lab


func _play_open() -> void:
	if _open_player == null:
		return
	_open_player.stream = OPEN_STREAM
	_open_player.play()


func _play_close() -> void:
	if _open_player == null:
		return
	_open_player.stream = _reversed_open if _reversed_open != null else OPEN_STREAM
	_open_player.play()


func _any_typing() -> bool:
	for slot in _slots:
		if slot.phase == Phase.TYPING:
			return true
	return false


func _play_type_loop() -> void:
	if _type_player == null:
		return
	if not _type_player.playing:
		_type_player.play()


func _refresh_type_loop() -> void:
	if _any_typing():
		_play_type_loop()
	elif _type_player != null and _type_player.playing:
		_type_player.stop()


func _on_type_finished() -> void:
	if _any_typing():
		_play_type_loop()


func _bump_token(slot: CardSlot) -> int:
	slot.run_token += 1
	return slot.run_token


func _make_reversed_wav(src: AudioStreamWAV) -> AudioStreamWAV:
	var out := AudioStreamWAV.new()
	out.format = src.format
	out.mix_rate = src.mix_rate
	out.stereo = src.stereo
	var data := src.data
	var bytes_per_frame := 2
	match src.format:
		AudioStreamWAV.FORMAT_8_BITS:
			bytes_per_frame = 1
		AudioStreamWAV.FORMAT_16_BITS:
			bytes_per_frame = 2
		_:
			out.data = data
			return out
	if src.stereo:
		bytes_per_frame *= 2
	if bytes_per_frame <= 0 or data.size() < bytes_per_frame:
		out.data = data
		return out
	@warning_ignore("integer_division")
	var frame_count := data.size() / bytes_per_frame
	var reversed := PackedByteArray()
	reversed.resize(frame_count * bytes_per_frame)
	for i in range(frame_count):
		var src_i := (frame_count - 1 - i) * bytes_per_frame
		var dst_i := i * bytes_per_frame
		for b in range(bytes_per_frame):
			reversed[dst_i + b] = data[src_i + b]
	out.data = reversed
	return out
