extends CanvasLayer

const CrtPowerFx = preload("res://scenes/ui/crt_power_fx.gd")
const OPEN_STREAM: AudioStreamWAV = preload("res://assets/audio/axel_typewriter_open.wav")
const TYPE_STREAM: AudioStreamWAV = preload("res://assets/audio/axel_typewriter_v4.wav")

## Non-blocking bottom-centered dialogue bar; does not pause physics or capture input.
## While typing: Tab / E / Space / Enter / click → instantly reveal the full line.
## When fully shown: same inputs advance immediately; otherwise auto-advance after a
## word-count reading timer, or ~2s after an instant skip reveal.

enum LinePhase {
	NONE,
	TYPING,
	READY,
}

const FADE_IN_SEC := 0.22
const FADE_OUT_SEC := 0.22
## ~25% faster than the old 28 CPS baseline (char-scramble flashes add perceived delay).
const DEFAULT_CHARS_PER_SEC := 35.0
const AUTO_ADVANCE_READING_BASE_SEC := 3.0
const AUTO_ADVANCE_READING_SQRT_COEFFICIENT := 0.5774
const AUTO_ADVANCE_SKIP_GRACE_SEC := 2.0
const AUTO_ADVANCE_READING_MAX_SEC := 20.0
const SLIDE_OFFSET := 12.0
## Baseline side padding for the full-width bar (fraction 1.0).
const SIDE_INSET_PX := 28.0
## Pre-test full-width look: set `bar_width_fraction` back to this.
const BAR_WIDTH_FRACTION_FULL := 1.0
## Midpoint between full (1.0) and the first 2/3 playtest, then +5% width.
const BAR_WIDTH_FRACTION_PLAYTEST := (BAR_WIDTH_FRACTION_FULL + 2.0 / 3.0) * 0.5 + 0.05
## Pre-test bottom gap in pixels (used when `bottom_gap_viewport_fraction` is 0).
const BOTTOM_GAP_PX_FULL := 12.0
const CURSOR_GLYPH := "\u2588"
const GLITCH_SEC := 0.12
const SCRAMBLE_CHARS := "!@#$%^&*?/\\|{}[]<>~`"
const CHAR_SCRAMBLE_CHANCE := 0.4
const CHAR_SCRAMBLE_MIN_SEC := 0.03
const CHAR_SCRAMBLE_MAX_SEC := 0.05
const BASE_BORDER := Color(0.290196, 0, 0, 1)
const DIM_BORDER := Color(0.290196, 0, 0, 0.35)
const BAR_MIN_HEIGHT := 136.0
## Player / narration. Other speakers (`AXEL: ...`) use bright red.
## Opt-in `|grey|` (never shown) types light grey — wins over red when both apply.
const PLAYER_LINE_COLOR := Color(1, 1, 1, 1)
const OTHER_SPEAKER_COLOR := Color(1, 0, 0, 1)
const GREY_SPEAKER_COLOR := Color(0.72, 0.72, 0.72, 1)

## Shared typewriter tape position across rooms (seconds into v4).
static var _type_loop_pos_sec := 0.0
static var _reversed_open_stream: AudioStreamWAV = null

## Legacy fixed gap; ignored when `bottom_gap_viewport_fraction` > 0.
@export var bottom_gap_px := BOTTOM_GAP_PX_FULL
## Playtest: lift bar by this fraction of window height above the bottom edge. 0 = use `bottom_gap_px`.
@export_range(0.0, 0.4, 0.01) var bottom_gap_viewport_fraction := 0.03
## Playtest: bar width as a fraction of the old nearly-full bar. 1.0 = rollback to full width.
@export_range(0.2, 1.0, 0.01) var bar_width_fraction := BAR_WIDTH_FRACTION_PLAYTEST
@export var fx_cursor := false
@export var fx_slide_up := false
@export var fx_chrome := true
@export var fx_line_swap_glitch := true
@export var fx_border_pulse := false
@export var fx_crt_power := true
## Per-letter cryptic flash while typing (letters/digits only).
@export var fx_char_scramble := true

@onready var _fade_root: Control = $ViewportRoot/RootMargin
@onready var _panel: PanelContainer = $ViewportRoot/RootMargin/BarPanel
@onready var _beam: ColorRect = $ViewportRoot/RootMargin/BarPanel/PowerBeam
@onready var _bloom: ColorRect = $ViewportRoot/RootMargin/BarPanel/Bloom
@onready var _inner_panel: PanelContainer = $ViewportRoot/RootMargin/BarPanel/InnerPanel
@onready var _label: Label = $ViewportRoot/RootMargin/BarPanel/InnerPanel/LineLabel
@onready var _open_close_player: AudioStreamPlayer = $OpenClosePlayer
@onready var _type_loop_player: AudioStreamPlayer = $TypeLoopPlayer

var _line_phase := LinePhase.NONE
var _advance_requested := false
var _skip_requested := false
var _skip_input_enabled := true
var _active_line_text := ""
var _active_line_start_ms := 0
var _line_token := 0
## True for the whole show_lines / hide_line await (covers CRT gaps where bar alpha is ~0).
var _sequence_active := false
var _panel_style: StyleBoxFlat
var _inner_style: StyleBoxFlat
var _inner_style_empty: StyleBoxEmpty
var _pulse_tween: Tween
var _cursor_active := false
var _cursor_text := ""
var _rest_offset_bottom := 0.0
var _rest_offset_top := 0.0
## True while type loop should keep wrapping (letters appearing).
var _type_loop_wanted := false


func _ready() -> void:
	# Scene instances sometimes hide this CanvasLayer with the editor eye.
	# Only the inner bar (_fade_root) should start hidden.
	visible = true
	layer = 111
	_fade_root.visible = false
	_fade_root.modulate.a = 0.0
	_panel_style = _panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	_panel.add_theme_stylebox_override("panel", _panel_style)
	_inner_style = _inner_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	_inner_style_empty = StyleBoxEmpty.new()
	_apply_chrome()
	_set_ignore_mouse_recursive(self)
	set_process_input(true)
	set_process(fx_cursor)
	get_viewport().size_changed.connect(_lock_bottom_layout)
	tree_exiting.connect(_on_tree_exiting)
	_setup_audio_players()
	_begin_layout()


func _on_tree_exiting() -> void:
	interrupt_line()


func _tree_alive() -> bool:
	return is_instance_valid(self) and is_inside_tree() and get_tree() != null


func _await_process_frame() -> bool:
	if not _tree_alive():
		return false
	var tree := get_tree()
	if tree == null:
		return false
	await tree.process_frame
	return _tree_alive()


func _begin_layout() -> void:
	if not await _await_process_frame():
		return
	_lock_bottom_layout()


func _lock_bottom_layout() -> void:
	if not is_instance_valid(_fade_root) or not is_instance_valid(_panel):
		return
	var bar_h := maxf(_panel.get_combined_minimum_size().y, BAR_MIN_HEIGHT)
	var viewport_size := get_viewport().get_visible_rect().size
	var viewport_w := viewport_size.x
	var full_bar_w := maxf(0.0, viewport_w - (SIDE_INSET_PX * 2.0))
	var fraction := clampf(bar_width_fraction, 0.2, BAR_WIDTH_FRACTION_FULL)
	var target_w := full_bar_w * fraction
	var side_inset := maxf(SIDE_INSET_PX, (viewport_w - target_w) * 0.5)
	var gap_px := bottom_gap_px
	if bottom_gap_viewport_fraction > 0.0:
		gap_px = viewport_size.y * bottom_gap_viewport_fraction
	_fade_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_fade_root.offset_left = side_inset
	_fade_root.offset_right = -side_inset
	_rest_offset_bottom = -gap_px
	_rest_offset_top = -(gap_px + bar_h)
	_fade_root.offset_bottom = _rest_offset_bottom
	_fade_root.offset_top = _rest_offset_top
	_reset_crt_visual()


func _reset_crt_visual() -> void:
	CrtPowerFx.reset_visual(_fade_root, _panel, _beam, _bloom)


func _apply_slide_start_offsets() -> void:
	_fade_root.offset_bottom = _rest_offset_bottom + SLIDE_OFFSET
	_fade_root.offset_top = _rest_offset_top + SLIDE_OFFSET


func _process(_delta: float) -> void:
	if _cursor_active and fx_cursor:
		_label.text = _compose(_cursor_text)


func _input(event: InputEvent) -> void:
	if not _fade_root.visible or not _skip_input_enabled:
		return
	if not _is_advance_event(event):
		return
	if not _handle_line_input():
		return
	get_viewport().set_input_as_handled()


func _is_advance_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return false
		return key_event.keycode in [KEY_TAB, KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		return touch_event.pressed
	return false


## Returns false when input should not be consumed (e.g. bar visible but idle).
func _handle_line_input() -> bool:
	match _line_phase:
		LinePhase.TYPING:
			_skip_requested = true
			return true
		LinePhase.READY:
			_advance_requested = true
			return true
	return false


func is_line_ready() -> bool:
	return _line_phase == LinePhase.READY


## Waits until the player presses advance or the auto-advance deadline is reached.
func await_line_advance() -> void:
	var token := _line_token
	await _wait_for_advance(token, _compute_advance_deadline_ms())


func _reading_duration_sec(text: String) -> float:
	var word_count := text.split(" ", false).size()
	var extra_words := maxf(word_count - 1, 0)
	return clampf(
		AUTO_ADVANCE_READING_BASE_SEC + AUTO_ADVANCE_READING_SQRT_COEFFICIENT * sqrt(extra_words),
		AUTO_ADVANCE_READING_BASE_SEC,
		AUTO_ADVANCE_READING_MAX_SEC,
	)


func _compute_advance_deadline_ms() -> int:
	if _skip_requested:
		return Time.get_ticks_msec() + int(AUTO_ADVANCE_SKIP_GRACE_SEC * 1000.0)
	return _active_line_start_ms + int(_reading_duration_sec(_active_line_text) * 1000.0)


func _wait_for_advance(token: int, deadline_ms: int) -> void:
	if not _line_alive(token):
		return
	if _line_phase != LinePhase.READY:
		return
	_advance_requested = false
	while _line_alive(token) and not _advance_requested:
		if Time.get_ticks_msec() >= deadline_ms:
			break
		if not await _await_process_frame():
			break
	_advance_requested = false


func _await_or_skip(duration_sec: float, allow_skip: bool) -> bool:
	var end_ms := Time.get_ticks_msec() + int(duration_sec * 1000.0)
	while Time.get_ticks_msec() < end_ms:
		if allow_skip and _skip_requested:
			return true
		if not await _await_process_frame():
			return false
	return false


func _set_ignore_mouse_recursive(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_set_ignore_mouse_recursive(c)


func _apply_chrome() -> void:
	if fx_chrome:
		_inner_panel.add_theme_stylebox_override("panel", _inner_style)
	else:
		_inner_panel.add_theme_stylebox_override("panel", _inner_style_empty)


func _compose(visible_text: String) -> String:
	if not fx_cursor:
		return visible_text
	var on := int(Time.get_ticks_msec() / 500.0) % 2 == 0
	return visible_text + (CURSOR_GLYPH if on else " ")


func _setup_audio_players() -> void:
	if is_instance_valid(_open_close_player):
		_open_close_player.stream = OPEN_STREAM
	if is_instance_valid(_type_loop_player):
		_type_loop_player.stream = TYPE_STREAM
		if not _type_loop_player.finished.is_connected(_on_type_loop_finished):
			_type_loop_player.finished.connect(_on_type_loop_finished)
	_ensure_reversed_open_stream()


func _ensure_reversed_open_stream() -> void:
	if _reversed_open_stream != null:
		return
	_reversed_open_stream = _make_reversed_wav(OPEN_STREAM)


static func _make_reversed_wav(src: AudioStreamWAV) -> AudioStreamWAV:
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
			# Compressed formats cannot be frame-reversed safely; fall back to original.
			out.data = data
			return out
	if src.stereo:
		bytes_per_frame *= 2
	if bytes_per_frame <= 0 or data.size() < bytes_per_frame:
		out.data = data
		return out
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


func _type_stream_length_sec() -> float:
	var bytes_per_frame := 2
	match TYPE_STREAM.format:
		AudioStreamWAV.FORMAT_8_BITS:
			bytes_per_frame = 1
		AudioStreamWAV.FORMAT_16_BITS:
			bytes_per_frame = 2
		_:
			return 0.0
	if TYPE_STREAM.stereo:
		bytes_per_frame *= 2
	if bytes_per_frame <= 0 or TYPE_STREAM.mix_rate <= 0:
		return 0.0
	return float(TYPE_STREAM.data.size() / bytes_per_frame) / float(TYPE_STREAM.mix_rate)


func _play_open_sound() -> void:
	if not is_instance_valid(_open_close_player):
		return
	_open_close_player.stream = OPEN_STREAM
	_open_close_player.play(0.0)


func _play_close_sound() -> void:
	if not is_instance_valid(_open_close_player):
		return
	_ensure_reversed_open_stream()
	if _reversed_open_stream != null:
		_open_close_player.stream = _reversed_open_stream
	else:
		_open_close_player.stream = OPEN_STREAM
	_open_close_player.play(0.0)


func _stop_open_close_sound() -> void:
	if is_instance_valid(_open_close_player) and _open_close_player.playing:
		_open_close_player.stop()


func _save_type_loop_pos() -> void:
	if is_instance_valid(_type_loop_player) and _type_loop_player.playing:
		_type_loop_pos_sec = _type_loop_player.get_playback_position()


func _start_type_loop() -> void:
	if not is_instance_valid(_type_loop_player):
		return
	_type_loop_wanted = true
	if _type_loop_player.playing:
		_type_loop_player.stream_paused = false
		return
	var length := _type_stream_length_sec()
	var from_pos := _type_loop_pos_sec
	if length > 0.0:
		from_pos = fposmod(from_pos, length)
	_type_loop_player.stream_paused = false
	_type_loop_player.play(from_pos)


func _pause_type_loop() -> void:
	_type_loop_wanted = false
	if not is_instance_valid(_type_loop_player):
		return
	if _type_loop_player.playing:
		_type_loop_pos_sec = _type_loop_player.get_playback_position()
		_type_loop_player.stream_paused = true
	elif not _type_loop_player.stream_paused:
		_save_type_loop_pos()


func _stop_type_loop() -> void:
	_type_loop_wanted = false
	if not is_instance_valid(_type_loop_player):
		return
	if _type_loop_player.playing or _type_loop_player.stream_paused:
		_type_loop_pos_sec = _type_loop_player.get_playback_position()
	_type_loop_player.stream_paused = false
	_type_loop_player.stop()


func _jump_type_loop_forward(delta_sec: float) -> void:
	_save_type_loop_pos()
	var length := _type_stream_length_sec()
	if length <= 0.0:
		_pause_type_loop()
		return
	_type_loop_pos_sec = fposmod(_type_loop_pos_sec + maxf(delta_sec, 0.0), length)
	if is_instance_valid(_type_loop_player):
		if _type_loop_player.playing:
			_type_loop_player.seek(_type_loop_pos_sec)
		_type_loop_wanted = false
		_type_loop_player.stream_paused = true


func _on_type_loop_finished() -> void:
	_type_loop_pos_sec = 0.0
	if _type_loop_wanted and is_instance_valid(_type_loop_player):
		_type_loop_player.play(0.0)


func _fade_in() -> void:
	_lock_bottom_layout()
	_fade_root.visible = true
	_play_open_sound()
	if fx_crt_power:
		await _crt_power_on()
		if not is_instance_valid(self):
			return
		return
	_fade_root.modulate.a = 0.0
	if fx_slide_up:
		_apply_slide_start_offsets()
	var tw_in := create_tween().set_parallel(true)
	tw_in.tween_property(_fade_root, "modulate:a", 1.0, FADE_IN_SEC)
	if fx_slide_up:
		tw_in.tween_property(_fade_root, "offset_bottom", _rest_offset_bottom, FADE_IN_SEC)
		tw_in.tween_property(_fade_root, "offset_top", _rest_offset_top, FADE_IN_SEC)
	await tw_in.finished


func _crt_power_on() -> void:
	await CrtPowerFx.power_on(self, _fade_root, _panel, _beam, _bloom)


func _crt_power_off() -> void:
	await CrtPowerFx.power_off(self, _fade_root, _panel, _beam, _bloom)


func _start_border_pulse() -> void:
	_stop_border_pulse()
	if not fx_border_pulse:
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_panel_style, "border_color", DIM_BORDER, 0.45)
	_pulse_tween.tween_property(_panel_style, "border_color", BASE_BORDER, 0.45)


func _stop_border_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	if _panel_style != null:
		_panel_style.border_color = BASE_BORDER


func _scramble_glitch(length: int) -> void:
	var end_ms := Time.get_ticks_msec() + int(GLITCH_SEC * 1000.0)
	while Time.get_ticks_msec() < end_ms:
		if not is_instance_valid(_label):
			return
		var scrambled := ""
		for _i in range(max(length, 1)):
			scrambled += SCRAMBLE_CHARS[randi() % SCRAMBLE_CHARS.length()]
		_label.text = scrambled
		if not await _await_process_frame():
			return


## Splits `|beat:<seconds>|`, `|other|`, and `|grey|` markers from display text.
## Malformed tokens stay literal.
## Returns { "display": String, "segments": Array of {kind:text|beat, ...} }.
func _parse_dialogue_segments(raw: String) -> Dictionary:
	var segments: Array = []
	var display := ""
	var text_buf := ""
	var i := 0
	var n := raw.length()
	while i < n:
		if raw[i] == "|":
			var close := raw.find("|", i + 1)
			if close > i:
				var token := raw.substr(i + 1, close - i - 1)
				if token == "other" or token == "grey":
					i = close + 1
					continue
				if token.begins_with("beat:"):
					var sec_str := token.substr(5)
					if sec_str.is_valid_float():
						var sec := sec_str.to_float()
						if sec >= 0.0:
							if not text_buf.is_empty():
								segments.append({"kind": "text", "text": text_buf})
								display += text_buf
								text_buf = ""
							segments.append({"kind": "beat", "sec": sec})
							i = close + 1
							continue
			text_buf += raw[i]
			i += 1
		else:
			text_buf += raw[i]
			i += 1
	if not text_buf.is_empty():
		segments.append({"kind": "text", "text": text_buf})
		display += text_buf
	return {"display": display, "segments": segments}


func _dialogue_display_text(raw: String) -> String:
	return str(_parse_dialogue_segments(raw)["display"])


## True when the line is tagged `|other|` or starts with an ALL-CAPS speaker tag (`AXEL: ...`).
func _is_other_speaker_line(text: String) -> bool:
	if text.contains("|other|"):
		return true
	var display := _dialogue_display_text(text).strip_edges()
	var colon := display.find(":")
	if colon <= 0:
		return false
	var speaker := display.substr(0, colon)
	for i in range(speaker.length()):
		var code := speaker.unicode_at(i)
		if code == 32:
			continue
		if code < 65 or code > 90:
			return false
	return true


func _is_grey_speaker_line(text: String) -> bool:
	return text.contains("|grey|")


func _apply_line_color(text: String) -> void:
	if not is_instance_valid(_label):
		return
	var color := PLAYER_LINE_COLOR
	if _is_grey_speaker_line(text):
		color = GREY_SPEAKER_COLOR
	elif _is_other_speaker_line(text):
		color = OTHER_SPEAKER_COLOR
	_label.add_theme_color_override("font_color", color)


func _reset_line_color() -> void:
	if not is_instance_valid(_label):
		return
	_label.add_theme_color_override("font_color", PLAYER_LINE_COLOR)


func _is_scrambleable_char(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code := ch.unicode_at(0)
	var is_digit := code >= 48 and code <= 57
	var is_upper := code >= 65 and code <= 90
	var is_lower := code >= 97 and code <= 122
	return is_digit or is_upper or is_lower


func _set_typing_label(visible_text: String) -> void:
	_cursor_text = visible_text
	if fx_cursor:
		_cursor_active = true
		_label.text = _compose(visible_text)
	else:
		_cursor_active = false
		_label.text = visible_text


## Instantly cuts the current line so a higher-priority line can take over.
func interrupt_line() -> void:
	_line_token += 1
	_line_phase = LinePhase.NONE
	_sequence_active = false
	_advance_requested = false
	_skip_requested = false
	_cursor_active = false
	_stop_border_pulse()
	_stop_type_loop()
	_stop_open_close_sound()
	_cancel_crt_power()
	if is_instance_valid(_fade_root):
		_fade_root.visible = false
		_fade_root.modulate.a = 0.0
	if is_instance_valid(_label):
		_label.text = ""
	_reset_line_color()
	_reset_crt_visual()


## Stops the current show_line sequence without hiding the bar (for in-bar line swaps).
func cancel_pending_line() -> void:
	_line_token += 1
	_line_phase = LinePhase.NONE
	_sequence_active = false
	_advance_requested = false
	_skip_requested = false
	_cursor_active = false
	_stop_border_pulse()
	_pause_type_loop()


func is_bar_visible() -> bool:
	return is_instance_valid(_fade_root) and _fade_root.visible and _fade_root.modulate.a > 0.01


## True while a line sequence or CRT show/hide is in flight (including alpha~0 CRT gaps).
func is_sequence_busy() -> bool:
	return _sequence_active or _line_phase != LinePhase.NONE or is_bar_visible()


func _line_alive(token: int) -> bool:
	return is_instance_valid(self) and token == _line_token


## Snapshot for callers running their own fire-and-forget line (e.g. a scripted
## intro line that must not stomp on a newer, movement-triggered sequence).
func current_line_token() -> int:
	return _line_token


func is_line_token_current(token: int) -> bool:
	return _line_alive(token)


func _cancel_crt_power() -> void:
	CrtPowerFx.cancel(self, _fade_root, _panel, _beam, _bloom)


## Type, wait for player advance, CRT off. `hold_duration` is kept for call-site compat (unused).
func _skip_dialogue_requested() -> bool:
	return OS.has_environment("AXEL_SKIP_DIALOGUE") and OS.get_environment("AXEL_SKIP_DIALOGUE") == "1"


func show_line(
	text: String,
	_hold_duration: float = 2.5,
	chars_per_sec: float = DEFAULT_CHARS_PER_SEC,
	allow_skip: bool = true,
) -> void:
	if _skip_dialogue_requested():
		return
	await show_lines([text], chars_per_sec, allow_skip)


## Multi-line sequence: advance on press scrambles to the next line; last line CRT powers off.
func show_lines(
	texts: Array,
	chars_per_sec: float = DEFAULT_CHARS_PER_SEC,
	allow_skip: bool = true,
) -> void:
	if _skip_dialogue_requested() or texts.is_empty():
		return

	visible = true
	_line_token += 1
	var token := _line_token
	_sequence_active = true
	_advance_requested = false
	_skip_requested = false
	_skip_input_enabled = allow_skip
	_apply_chrome()

	if not _fade_root.visible or _fade_root.modulate.a < 1.0:
		_label.text = ""
		await _fade_in()
		if not _line_alive(token):
			return

	for i in range(texts.size()):
		var text: String = str(texts[i])
		_apply_line_color(text)
		if i > 0:
			if fx_line_swap_glitch:
				await _scramble_glitch(_dialogue_display_text(text).length())
			else:
				_label.text = ""
			if not _line_alive(token):
				return

		await _run_typewriter(text, chars_per_sec, allow_skip, token)
		if not _line_alive(token):
			return
		await _wait_for_advance(token, _compute_advance_deadline_ms())
		if not _line_alive(token):
			return

	await hide_line()


## Shows a line without blocking the caller; player movement continues during reveal/hold.
func show_line_nonblocking(
	text: String,
	hold_duration: float = 2.5,
	chars_per_sec: float = DEFAULT_CHARS_PER_SEC,
	allow_skip: bool = true,
) -> void:
	if _skip_dialogue_requested():
		return
	_run_line_async(text, hold_duration, chars_per_sec, allow_skip)


func _run_line_async(
	text: String,
	hold_duration: float,
	chars_per_sec: float,
	allow_skip: bool,
) -> void:
	await show_line(text, hold_duration, chars_per_sec, allow_skip)


## Fade in (if needed) + typewriter, then return with the line still visible and awaiting advance.
func type_line(
	text: String,
	chars_per_sec: float = DEFAULT_CHARS_PER_SEC,
	allow_skip: bool = true,
) -> void:
	if _skip_dialogue_requested():
		return
	_advance_requested = false
	_skip_requested = false
	_skip_input_enabled = allow_skip
	_apply_line_color(text)
	var is_swap := (
		fx_line_swap_glitch
		and _fade_root.visible
		and _fade_root.modulate.a >= 0.99
		and not _label.text.is_empty()
	)
	_label.text = ""
	_apply_chrome()
	if not _fade_root.visible or _fade_root.modulate.a < 1.0:
		await _fade_in()
	if is_swap:
		await _scramble_glitch(_dialogue_display_text(text).length())
	await _run_typewriter(text, chars_per_sec, allow_skip, _line_token)


func _run_typewriter(
	full_text: String,
	chars_per_sec: float,
	allow_skip: bool,
	token: int = -1,
) -> void:
	var parsed := _parse_dialogue_segments(full_text)
	var display_text: String = str(parsed["display"])
	var segments: Array = parsed["segments"]
	_apply_line_color(full_text)
	_active_line_text = display_text
	_skip_requested = false
	if display_text.is_empty() and segments.is_empty():
		# Reading timer starts when the line is fully shown, not when typing begins.
		_active_line_start_ms = Time.get_ticks_msec()
		_line_phase = LinePhase.READY
		_pause_type_loop()
		return

	_line_phase = LinePhase.TYPING
	_start_border_pulse()
	_start_type_loop()
	var cps := maxf(chars_per_sec, 4.0)
	var delay := 1.0 / cps
	var revealed := ""
	var abort_to_full := false

	for segment in segments:
		if token >= 0 and not _line_alive(token):
			_stop_border_pulse()
			_pause_type_loop()
			_line_phase = LinePhase.NONE
			return
		if allow_skip and _skip_requested:
			abort_to_full = true
			break

		if str(segment.get("kind", "")) == "beat":
			_pause_type_loop()
			var beat_sec: float = float(segment.get("sec", 0.0))
			var end_ms := Time.get_ticks_msec() + int(beat_sec * 1000.0)
			while Time.get_ticks_msec() < end_ms:
				if token >= 0 and not _line_alive(token):
					_stop_border_pulse()
					_pause_type_loop()
					_line_phase = LinePhase.NONE
					return
				if allow_skip and _skip_requested:
					# Advance during beat ends pause only; typing continues.
					_skip_requested = false
					break
				if not await _await_process_frame():
					_stop_border_pulse()
					_pause_type_loop()
					_line_phase = LinePhase.NONE
					return
			if _line_phase == LinePhase.TYPING:
				_start_type_loop()
			continue

		var chunk: String = str(segment.get("text", ""))
		for ci in range(chunk.length()):
			if token >= 0 and not _line_alive(token):
				_stop_border_pulse()
				_pause_type_loop()
				_line_phase = LinePhase.NONE
				return
			if allow_skip and _skip_requested:
				abort_to_full = true
				break

			var ch := chunk[ci]
			if (
				fx_char_scramble
				and _is_scrambleable_char(ch)
				and randf() < CHAR_SCRAMBLE_CHANCE
			):
				var scramble_ch := SCRAMBLE_CHARS[randi() % SCRAMBLE_CHARS.length()]
				_set_typing_label(revealed + scramble_ch)
				var flash_sec := randf_range(CHAR_SCRAMBLE_MIN_SEC, CHAR_SCRAMBLE_MAX_SEC)
				if await _await_or_skip(flash_sec, allow_skip):
					abort_to_full = true
					break

			revealed += ch
			_set_typing_label(revealed)
			if await _await_or_skip(delay, allow_skip):
				abort_to_full = true
				break

		if abort_to_full:
			break

	if abort_to_full:
		var remaining := display_text.length() - revealed.length()
		_jump_type_loop_forward(float(remaining) / cps)
	else:
		_pause_type_loop()

	_cursor_active = false
	_label.text = display_text
	_stop_border_pulse()
	# Start auto-advance clock after the last letter (beats/scramble no longer eat the hold).
	_active_line_start_ms = Time.get_ticks_msec()
	_line_phase = LinePhase.READY


func hide_line() -> void:
	var token := _line_token
	if not _fade_root.visible:
		_line_phase = LinePhase.NONE
		if _line_alive(token):
			_sequence_active = false
		return
	_cursor_active = false
	_stop_border_pulse()
	_pause_type_loop()
	_line_phase = LinePhase.NONE
	_sequence_active = true
	_play_close_sound()
	if fx_crt_power:
		await _crt_power_off()
		if not _line_alive(token):
			return
		_fade_root.visible = false
		_lock_bottom_layout()
		_label.text = ""
		_reset_line_color()
		_sequence_active = false
		return
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(_fade_root, "modulate:a", 0.0, FADE_OUT_SEC)
	if fx_slide_up:
		tw_out.tween_property(_fade_root, "offset_bottom", _rest_offset_bottom + SLIDE_OFFSET, FADE_OUT_SEC)
		tw_out.tween_property(_fade_root, "offset_top", _rest_offset_top + SLIDE_OFFSET, FADE_OUT_SEC)
	await tw_out.finished
	if not _line_alive(token):
		return
	_fade_root.visible = false
	_lock_bottom_layout()
	_label.text = ""
	_reset_line_color()
	_sequence_active = false
