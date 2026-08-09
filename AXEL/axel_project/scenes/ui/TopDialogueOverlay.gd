extends CanvasLayer

const CrtPowerFx = preload("res://scenes/ui/crt_power_fx.gd")

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
const DEFAULT_CHARS_PER_SEC := 28.0
const AUTO_ADVANCE_READING_BASE_SEC := 3.0
const AUTO_ADVANCE_READING_SQRT_COEFFICIENT := 0.5774
const AUTO_ADVANCE_SKIP_GRACE_SEC := 2.0
const AUTO_ADVANCE_READING_MAX_SEC := 20.0
const SLIDE_OFFSET := 12.0
## Baseline side padding for the full-width bar (fraction 1.0).
const SIDE_INSET_PX := 28.0
## Pre-test full-width look: set `bar_width_fraction` back to this.
const BAR_WIDTH_FRACTION_FULL := 1.0
const CURSOR_GLYPH := "\u2588"
const GLITCH_SEC := 0.12
const SCRAMBLE_CHARS := "!@#$%^&*?/\\|{}[]<>~`"
const BASE_BORDER := Color(0.290196, 0, 0, 1)
const DIM_BORDER := Color(0.290196, 0, 0, 0.35)
const BAR_MIN_HEIGHT := 136.0

@export var bottom_gap_px := 12.0
## Playtest: bar width as a fraction of the old nearly-full bar. 1.0 = rollback to full width.
@export_range(0.2, 1.0, 0.01) var bar_width_fraction := 2.0 / 3.0
@export var fx_cursor := false
@export var fx_slide_up := false
@export var fx_chrome := true
@export var fx_line_swap_glitch := true
@export var fx_border_pulse := false
@export var fx_crt_power := true

@onready var _fade_root: Control = $ViewportRoot/RootMargin
@onready var _panel: PanelContainer = $ViewportRoot/RootMargin/BarPanel
@onready var _beam: ColorRect = $ViewportRoot/RootMargin/BarPanel/PowerBeam
@onready var _bloom: ColorRect = $ViewportRoot/RootMargin/BarPanel/Bloom
@onready var _inner_panel: PanelContainer = $ViewportRoot/RootMargin/BarPanel/InnerPanel
@onready var _label: Label = $ViewportRoot/RootMargin/BarPanel/InnerPanel/LineLabel

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


func _ready() -> void:
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
	var viewport_w := get_viewport().get_visible_rect().size.x
	var full_bar_w := maxf(0.0, viewport_w - (SIDE_INSET_PX * 2.0))
	var fraction := clampf(bar_width_fraction, 0.2, BAR_WIDTH_FRACTION_FULL)
	var target_w := full_bar_w * fraction
	var side_inset := maxf(SIDE_INSET_PX, (viewport_w - target_w) * 0.5)
	_fade_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_fade_root.offset_left = side_inset
	_fade_root.offset_right = -side_inset
	_rest_offset_bottom = -bottom_gap_px
	_rest_offset_top = -(bottom_gap_px + bar_h)
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


func _fade_in() -> void:
	_lock_bottom_layout()
	_fade_root.visible = true
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


## Instantly cuts the current line so a higher-priority line can take over.
func interrupt_line() -> void:
	_line_token += 1
	_line_phase = LinePhase.NONE
	_sequence_active = false
	_advance_requested = false
	_skip_requested = false
	_cursor_active = false
	_stop_border_pulse()
	_cancel_crt_power()
	if is_instance_valid(_fade_root):
		_fade_root.visible = false
		_fade_root.modulate.a = 0.0
	if is_instance_valid(_label):
		_label.text = ""
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
func show_line(
	text: String,
	_hold_duration: float = 2.5,
	chars_per_sec: float = DEFAULT_CHARS_PER_SEC,
	allow_skip: bool = true,
) -> void:
	await show_lines([text], chars_per_sec, allow_skip)


## Multi-line sequence: advance on press scrambles to the next line; last line CRT powers off.
func show_lines(
	texts: Array,
	chars_per_sec: float = DEFAULT_CHARS_PER_SEC,
	allow_skip: bool = true,
) -> void:
	if texts.is_empty():
		return

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
		if i > 0:
			if fx_line_swap_glitch:
				await _scramble_glitch(text.length())
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
	_advance_requested = false
	_skip_requested = false
	_skip_input_enabled = allow_skip
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
		await _scramble_glitch(text.length())
	await _run_typewriter(text, chars_per_sec, allow_skip, _line_token)


func _run_typewriter(
	full_text: String,
	chars_per_sec: float,
	allow_skip: bool,
	token: int = -1,
) -> void:
	var n := full_text.length()
	_active_line_text = full_text
	_active_line_start_ms = Time.get_ticks_msec()
	_skip_requested = false
	if n == 0:
		_line_phase = LinePhase.READY
		return

	_line_phase = LinePhase.TYPING
	_start_border_pulse()
	var cps := maxf(chars_per_sec, 4.0)
	var delay := 1.0 / cps

	for i in range(1, n + 1):
		if token >= 0 and not _line_alive(token):
			_stop_border_pulse()
			_line_phase = LinePhase.NONE
			return
		if allow_skip and _skip_requested:
			break
		var revealed := full_text.substr(0, i)
		_cursor_text = revealed
		if fx_cursor:
			_cursor_active = true
			_label.text = _compose(revealed)
		else:
			_cursor_active = false
			_label.text = revealed
		if await _await_or_skip(delay, allow_skip):
			break

	_cursor_active = false
	_label.text = full_text
	_stop_border_pulse()
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
	_line_phase = LinePhase.NONE
	_sequence_active = true
	if fx_crt_power:
		await _crt_power_off()
		if not _line_alive(token):
			return
		_fade_root.visible = false
		_lock_bottom_layout()
		_label.text = ""
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
	_sequence_active = false
