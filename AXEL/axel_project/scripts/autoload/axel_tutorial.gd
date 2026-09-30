extends Node

const CrtPowerFx := preload("res://scenes/ui/crt_power_fx.gd")
const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const OPEN_STREAM: AudioStreamWAV = preload("res://assets/audio/axel_typewriter_open.wav")
const TYPE_STREAM: AudioStreamWAV = preload("res://assets/audio/axel_typewriter_v4.wav")

const CARD_W := 520.0
const CARD_H := 860.0
const CARD_MARGIN := 36.0
const REF_H := 1280.0
const FONT_PX := 32.0
const OUTLINE_PX := 4.0
const CHARS_PER_SEC := 35.0
const TITLE_MARK_GAP := 18.0
const AUTO_READING_BASE_SEC := 3.0
const AUTO_READING_SQRT := 0.5774
const AUTO_READING_MAX_SEC := 20.0
const AUTO_SKIP_GRACE_SEC := 2.0
const GLOW_PAD := 10.0
const GLOW_BORDER := 4.0
const GLOW_STEADY := 0.45
const GLOW_PULSE_SEC := 1.2

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
	"fight_stakes": ["MOVE_Balance", "MOVE_BetStrip", "NEW_Goal"],
	"fight_items": ["NEW_Items"],
}

enum Phase { IDLE, OPENING, TYPING, WAITING, CLOSING }

var _debug_enabled := false
var _phase := Phase.IDLE
var _open_id := ""
var _queue: Array[String] = []
var _marked: Dictionary = {}
var _hud_rects: Dictionary = {}
var _body_text := ""
var _typed := 0
var _type_acc := 0.0
var _run_token := 0
var _reversed_open: AudioStreamWAV

var _glow_layer: CanvasLayer
var _glow_root: Control
var _rims: Array[Control] = []
var _card_layer: CanvasLayer
var _card_host: Control
var _fade_root: Control
var _bar_panel: PanelContainer
var _inner_panel: PanelContainer
var _beam: ColorRect
var _bloom: ColorRect
var _title: Label
var _title_font: FontVariation
var _body: Label
var _mark: Label
var _mark_end: Label
var _header: HBoxContainer
var _column: VBoxContainer
var _exit: Button
var _wait_left := 0.0
var _open_player: AudioStreamPlayer
var _type_player: AudioStreamPlayer


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
	if _is_seen(id) or id == _open_id or _queue.has(id):
		return
	_queue.append(id)


func is_open() -> bool:
	return _phase != Phase.IDLE


func is_waiting() -> bool:
	return _phase == Phase.WAITING


func blocks_spin() -> bool:
	if _phase != Phase.IDLE:
		return true
	for id in _queue:
		if _is_fight(id):
			return true
	return false


func suppresses_skull_hint() -> bool:
	return (
		_phase == Phase.OPENING
		or _phase == Phase.TYPING
		or _phase == Phase.WAITING
	) and _is_fight(_open_id)


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
	if _open_id != "":
		_layout_card()
		_sync_glows()


func card_rect() -> Rect2:
	if _card_host == null:
		return Rect2()
	return _card_host.get_global_rect()


func debug_dismiss() -> void:
	_on_dismiss_pressed()


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
	if _phase == Phase.TYPING:
		_advance_type(delta)
	elif _phase == Phase.WAITING:
		_wait_left -= delta
		if _wait_left <= 0.0:
			_start_close()
	_sync_glows()
	if _phase == Phase.IDLE:
		_try_start()


func _try_start() -> void:
	if _queue.is_empty() or _story_busy():
		return
	var id := _queue[0]
	_queue.remove_at(0)
	_open_id = id
	_phase = Phase.OPENING
	_run_card(id)


func _run_card(id: String) -> void:
	var token := _bump_token()
	var lesson: Dictionary = LESSONS[id]
	_body_text = String(lesson["body"])
	_typed = 0
	_type_acc = 0.0
	_title.text = String(lesson["title"])
	_body.text = ""
	_card_host.visible = true
	if _exit != null:
		_exit.visible = true
	_layout_card()
	_sync_glows()
	_play_open()
	await CrtPowerFx.power_on(self, _fade_root, _bar_panel, _beam, _bloom)
	if token != _run_token or _open_id != id or _phase != Phase.OPENING:
		return
	_phase = Phase.TYPING
	_play_type_loop()


func _advance_type(delta: float) -> void:
	if _body_text.is_empty():
		_begin_wait(false)
		return
	_type_acc += delta * CHARS_PER_SEC
	var add := int(_type_acc)
	if add <= 0:
		return
	_type_acc -= float(add)
	_typed = mini(_typed + add, _body_text.length())
	_body.text = _body_text.substr(0, _typed)
	if _typed >= _body_text.length():
		_begin_wait(false)


func _begin_wait(from_skip: bool) -> void:
	_phase = Phase.WAITING
	_stop_type_loop()
	if from_skip:
		_wait_left = AUTO_SKIP_GRACE_SEC
	else:
		_wait_left = _reading_duration_sec(_body_text)


func _reading_duration_sec(text: String) -> float:
	var word_count := text.split(" ", false).size()
	var extra_words := maxf(float(word_count - 1), 0.0)
	return clampf(
		AUTO_READING_BASE_SEC + AUTO_READING_SQRT * sqrt(extra_words),
		AUTO_READING_BASE_SEC,
		AUTO_READING_MAX_SEC,
	)


func _on_dismiss_pressed() -> void:
	if _phase == Phase.TYPING:
		_body.text = _body_text
		_typed = _body_text.length()
		_begin_wait(true)
		return
	if _phase != Phase.WAITING:
		return
	_start_close()


func _on_exit_pressed() -> void:
	if _phase == Phase.IDLE or _phase == Phase.CLOSING:
		return
	if _phase == Phase.TYPING or _phase == Phase.OPENING:
		_body.text = _body_text
		_typed = _body_text.length()
		_stop_type_loop()
		_phase = Phase.WAITING
	_start_close()


func _start_close() -> void:
	if _phase != Phase.WAITING:
		return
	var id := _open_id
	_phase = Phase.CLOSING
	_mark_seen(id)
	_hide_glows()
	_stop_type_loop()
	_play_close()
	var token := _bump_token()
	await CrtPowerFx.power_off(self, _fade_root, _bar_panel, _beam, _bloom)
	if token != _run_token:
		return
	_phase = Phase.IDLE
	_open_id = ""
	_body_text = ""
	if _card_host != null:
		_card_host.visible = false
	if _exit != null:
		_exit.visible = false


func _input(event: InputEvent) -> void:
	if _phase == Phase.IDLE or event.is_echo():
		return
	if not _is_dismiss_event(event):
		return
	get_viewport().set_input_as_handled()
	_on_dismiss_pressed()


func _is_dismiss_event(event: InputEvent) -> bool:
	if event.is_action_pressed("interact"):
		return true
	if event.is_action_pressed("dialogue_advance"):
		return true
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
	if _open_id != "":
		_layout_card()


func _viewport_size() -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	if vp.x < 2.0 or vp.y < 2.0:
		return Vector2(1920.0, 1280.0)
	return vp


func _layout_card() -> void:
	if _card_host == null or _open_id.is_empty():
		return
	var vp := _viewport_size()
	var scale := vp.y / REF_H
	var margin := CARD_MARGIN * scale
	var width := CARD_W * scale
	# Top stays where the old tall card started. Height follows the words.
	var y := (vp.y - CARD_H * scale) * 0.5
	var rect := Rect2(vp.x - margin - width, y, width, _measured_height(scale, width))
	var targets := _glow_targets()
	if _overlaps_any(rect, targets):
		rect.position.x = margin
		var guard := 0
		var min_w := 220.0 * scale
		while _overlaps_any(rect, targets) and rect.size.x > min_w and guard < 40:
			rect.size.x = maxf(min_w, rect.size.x - 20.0 * scale)
			rect.size.y = _measured_height(scale, rect.size.x)
			guard += 1
	_card_host.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_card_host.position = rect.position
	_card_host.size = rect.size
	_card_host.custom_minimum_size = rect.size
	_apply_chrome(scale, rect.size.x)
	if _exit != null:
		UiViewportScale.apply_exit_button(_exit, scale)
	CrtPowerFx.reset_pivot(_bar_panel)


func _glow_targets() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for piece_name in glow_piece_names(_open_id):
		if not _hud_rects.has(piece_name):
			continue
		var rect: Rect2 = _hud_rects[piece_name]
		if rect.size.x <= 1.0 or rect.size.y <= 1.0:
			continue
		out.append(rect)
	return out


func _overlaps_any(rect: Rect2, targets: Array[Rect2]) -> bool:
	for target in targets:
		if rect.intersects(target):
			return true
	return false


func _apply_chrome(scale: float, host_w: float) -> void:
	_bar_panel.add_theme_stylebox_override("panel", _outer_style(scale))
	_inner_panel.add_theme_stylebox_override("panel", _inner_style(scale))
	var font_size := maxi(12, int(round(FONT_PX * scale)))
	var outline := maxi(1, int(round(OUTLINE_PX * scale)))
	var inner_w := maxf(40.0, host_w - 44.0 * scale)
	for lab in [_mark, _mark_end, _title, _body]:
		lab.add_theme_font_size_override("font_size", font_size)
		lab.add_theme_constant_override("outline_size", outline)
	var gap := TITLE_MARK_GAP * scale
	_header.add_theme_constant_override("separation", maxi(1, int(round(gap))))
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.clip_text = false
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_w := 0.0
	if _title_font != null and not _title.text.is_empty():
		title_w = _title_font.get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var side := float(outline) + 2.0 * scale
	_title.custom_minimum_size.x = title_w + side * 2.0
	_body.custom_maximum_size = Vector2(inner_w, -1.0)


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


func _sync_glows() -> void:
	if not suppresses_skull_hint():
		_hide_glows()
		return
	var names := glow_piece_names(_open_id)
	var used := 0
	for piece_name in names:
		if not _hud_rects.has(piece_name):
			continue
		var rect: Rect2 = _hud_rects[piece_name]
		if rect.size.x <= 1.0 or rect.size.y <= 1.0:
			continue
		var rim := _rim_at(used)
		used += 1
		rim.visible = true
		rim.position = rect.position - Vector2(GLOW_PAD, GLOW_PAD)
		rim.size = rect.size + Vector2(GLOW_PAD * 2.0, GLOW_PAD * 2.0)
		rim.modulate = Color(1, 1, 1, _glow_alpha())
		rim.queue_redraw()
	while used < _rims.size():
		_rims[used].visible = false
		used += 1


func _glow_alpha() -> float:
	var settings := get_node_or_null("/root/AxelSettings")
	var steady := false
	if settings != null and settings.has_method("get_value"):
		steady = bool(settings.call("get_value", "access", "reduce_flashing", false))
	if steady:
		return GLOW_STEADY
	var t := float(Time.get_ticks_msec()) * 0.001
	var wave := 0.5 + 0.5 * sin(t * TAU / GLOW_PULSE_SEC)
	return lerpf(0.25, 0.85, wave)


func _measured_height(scale: float, host_w: float) -> float:
	var font_size := maxi(12, int(round(FONT_PX * scale)))
	var inner_w := maxf(40.0, host_w - 44.0 * scale)
	var gap := 8.0 * scale
	var mark_w := FONT.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var title_w := maxf(40.0, inner_w - mark_w * 2.0 - gap * 2.0)
	var title_h := _block_height_font(_title_font, _title.text, title_w, font_size)
	var body_h := _block_height(_body_text, inner_w, font_size)
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
	for rim in _rims:
		rim.visible = false


func _rim_at(index: int) -> Control:
	while _rims.size() <= index:
		var rim := GlowRim.new()
		rim.visible = false
		rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_glow_root.add_child(rim)
		_rims.append(rim)
	return _rims[index]


func _build() -> void:
	_glow_layer = CanvasLayer.new()
	_glow_layer.name = "GlowLayer"
	_glow_layer.layer = 113
	add_child(_glow_layer)
	_glow_root = Control.new()
	_glow_root.name = "GlowRoot"
	_glow_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow_layer.add_child(_glow_root)

	_card_layer = CanvasLayer.new()
	_card_layer.name = "CardLayer"
	_card_layer.layer = 114
	add_child(_card_layer)

	_card_host = Control.new()
	_card_host.name = "CardHost"
	_card_host.visible = false
	_card_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_layer.add_child(_card_host)

	_fade_root = Control.new()
	_fade_root.name = "FadeRoot"
	_fade_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_root.modulate.a = 0.0
	_card_host.add_child(_fade_root)

	_bar_panel = PanelContainer.new()
	_bar_panel.name = "BarPanel"
	_bar_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_root.add_child(_bar_panel)

	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_beam = ColorRect.new()
	_beam.name = "PowerBeam"
	_beam.color = Color.WHITE
	_beam.modulate.a = 0.0
	_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beam.material = add_mat
	_beam.z_index = 2
	_bar_panel.add_child(_beam)

	_inner_panel = PanelContainer.new()
	_inner_panel.name = "InnerPanel"
	_inner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_panel.add_child(_inner_panel)

	_column = VBoxContainer.new()
	_column.name = "TextColumn"
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner_panel.add_child(_column)

	_header = HBoxContainer.new()
	_header.name = "HeaderRow"
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(_header)

	_title_font = FontVariation.new()
	_title_font.base_font = FONT
	_title_font.variation_embolden = 0.8

	_mark = _make_label("MarkLabel")
	_mark.text = "?"
	_mark.autowrap_mode = TextServer.AUTOWRAP_OFF
	_mark.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_header.add_child(_mark)

	_title = _make_label("TitleLabel")
	_title.add_theme_font_override("font", _title_font)
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header.add_child(_title)

	_mark_end = _make_label("MarkEndLabel")
	_mark_end.text = "?"
	_mark_end.autowrap_mode = TextServer.AUTOWRAP_OFF
	_mark_end.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_header.add_child(_mark_end)

	_body = _make_label("BodyLabel")
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_column.add_child(_body)

	_bloom = ColorRect.new()
	_bloom.name = "Bloom"
	_bloom.color = Color(1, 0, 0, 1)
	_bloom.modulate.a = 0.0
	_bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bloom.material = add_mat
	_bloom.z_index = 3
	_bar_panel.add_child(_bloom)

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

	_exit = Button.new()
	_exit.name = "ExitButton"
	_exit.text = "X"
	_exit.visible = false
	_exit.focus_mode = Control.FOCUS_NONE
	_exit.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_exit.add_theme_font_override("font", FONT)
	_exit.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	_exit.add_theme_color_override("font_pressed_color", Color(0.75, 0, 0, 1))
	_exit.add_theme_color_override("font_hover_color", Color(1, 0.25, 0.25, 1))
	_exit.pressed.connect(_on_exit_pressed)
	_card_layer.add_child(_exit)


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


func _play_type_loop() -> void:
	if _type_player == null:
		return
	if not _type_player.playing:
		_type_player.play()


func _stop_type_loop() -> void:
	if _type_player != null and _type_player.playing:
		_type_player.stop()


func _on_type_finished() -> void:
	if _phase == Phase.TYPING:
		_play_type_loop()


func _bump_token() -> int:
	_run_token += 1
	return _run_token


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


class GlowRim extends Control:
	func _draw() -> void:
		var border := 4.0
		var rect := Rect2(Vector2(border * 0.5, border * 0.5), size - Vector2(border, border))
		if rect.size.x < 1.0 or rect.size.y < 1.0:
			return
		draw_rect(rect, Color.WHITE, false, border)
