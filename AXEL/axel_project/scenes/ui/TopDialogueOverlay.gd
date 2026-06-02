extends CanvasLayer

const CrtPowerFx = preload("res://scenes/ui/crt_power_fx.gd")

## Non-blocking bottom-centered dialogue bar; does not pause physics or capture input.
## Typewriter reveal: press Tab to skip to full line (does not block movement).

const FADE_IN_SEC := 0.22
const FADE_OUT_SEC := 0.22
const DEFAULT_CHARS_PER_SEC := 28.0
const SLIDE_OFFSET := 12.0
const SIDE_INSET_PX := 28.0
const CURSOR_GLYPH := "\u2588"
const GLITCH_SEC := 0.12
const SCRAMBLE_CHARS := "!@#$%^&*?/\\|{}[]<>~`"
const BASE_BORDER := Color(0.290196, 0, 0, 1)
const DIM_BORDER := Color(0.290196, 0, 0, 0.35)
const BAR_MIN_HEIGHT := 136.0

@export var bottom_gap_px := 12.0
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

var _skip_typewriter := false
var _panel_style: StyleBoxFlat
var _inner_style: StyleBoxFlat
var _inner_style_empty: StyleBoxEmpty
var _pulse_tween: Tween
var _cursor_active := false
var _cursor_text := ""
var _rest_offset_bottom := 0.0
var _rest_offset_top := 0.0


func _ready() -> void:
	layer = 110
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
	_begin_layout()


func _begin_layout() -> void:
	await get_tree().process_frame
	_lock_bottom_layout()


func _lock_bottom_layout() -> void:
	if not is_instance_valid(_fade_root) or not is_instance_valid(_panel):
		return
	var bar_h := maxf(_panel.get_combined_minimum_size().y, BAR_MIN_HEIGHT)
	_fade_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_fade_root.offset_left = SIDE_INSET_PX
	_fade_root.offset_right = -SIDE_INSET_PX
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
	if not _fade_root.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_skip_typewriter = true


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
		var scrambled := ""
		for _i in range(max(length, 1)):
			scrambled += SCRAMBLE_CHARS[randi() % SCRAMBLE_CHARS.length()]
		_label.text = scrambled
		await get_tree().process_frame


## Fade in, typewriter reveal, hold, fade out. Safe to await; does not disable player movement.
func show_line(
	text: String,
	hold_duration: float = 2.5,
	chars_per_sec: float = DEFAULT_CHARS_PER_SEC,
	allow_skip: bool = true,
) -> void:
	_skip_typewriter = false
	_label.text = ""
	_apply_chrome()
	await _fade_in()
	await _run_typewriter(text, chars_per_sec, allow_skip)
	await get_tree().create_timer(maxf(hold_duration, 0.05)).timeout
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


## Fade in (if needed) + typewriter, then return with the line still visible.
func type_line(
	text: String,
	chars_per_sec: float = DEFAULT_CHARS_PER_SEC,
	allow_skip: bool = true,
) -> void:
	_skip_typewriter = false
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
	await _run_typewriter(text, chars_per_sec, allow_skip)


func _run_typewriter(full_text: String, chars_per_sec: float, allow_skip: bool) -> void:
	var n := full_text.length()
	if n == 0:
		return

	_start_border_pulse()
	var cps := maxf(chars_per_sec, 4.0)
	var delay := 1.0 / cps

	for i in range(1, n + 1):
		if allow_skip and _skip_typewriter:
			_cursor_active = false
			_label.text = full_text
			_stop_border_pulse()
			return
		var revealed := full_text.substr(0, i)
		_cursor_text = revealed
		if fx_cursor:
			_cursor_active = true
			_label.text = _compose(revealed)
		else:
			_cursor_active = false
			_label.text = revealed
		await get_tree().create_timer(delay).timeout

	_cursor_active = false
	_label.text = full_text
	_stop_border_pulse()


func hide_line() -> void:
	if not _fade_root.visible:
		return
	_cursor_active = false
	_stop_border_pulse()
	if fx_crt_power:
		await _crt_power_off()
		_fade_root.visible = false
		_lock_bottom_layout()
		_label.text = ""
		return
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(_fade_root, "modulate:a", 0.0, FADE_OUT_SEC)
	if fx_slide_up:
		tw_out.tween_property(_fade_root, "offset_bottom", _rest_offset_bottom + SLIDE_OFFSET, FADE_OUT_SEC)
		tw_out.tween_property(_fade_root, "offset_top", _rest_offset_top + SLIDE_OFFSET, FADE_OUT_SEC)
	await tw_out.finished
	_fade_root.visible = false
	_lock_bottom_layout()
	_label.text = ""
