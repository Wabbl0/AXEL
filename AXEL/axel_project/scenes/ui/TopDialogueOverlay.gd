extends CanvasLayer

## Non-blocking bottom-centered dialogue bar; does not pause physics or capture input.
## Typewriter reveal: press Tab to skip to full line (does not block movement).

const FADE_IN_SEC := 0.22
const FADE_OUT_SEC := 0.22
const DEFAULT_CHARS_PER_SEC := 28.0

@onready var _fade_root: Control = $RootMargin
@onready var _label: Label = $RootMargin/BarPanel/LineLabel

var _skip_typewriter := false


func _ready() -> void:
	layer = 110
	_fade_root.visible = false
	_fade_root.modulate.a = 0.0
	_set_ignore_mouse_recursive(self)
	set_process_input(true)


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


## Fade in, typewriter reveal, hold, fade out. Safe to await; does not disable player movement.
func show_line(
	text: String,
	hold_duration: float = 2.5,
	chars_per_sec: float = DEFAULT_CHARS_PER_SEC,
	allow_skip: bool = true,
) -> void:
	_skip_typewriter = false
	_label.text = ""
	_fade_root.visible = true
	var tw_in := create_tween()
	tw_in.tween_property(_fade_root, "modulate:a", 1.0, FADE_IN_SEC)
	await tw_in.finished

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


func _run_typewriter(full_text: String, chars_per_sec: float, allow_skip: bool) -> void:
	var n := full_text.length()
	if n == 0:
		return

	var cps := maxf(chars_per_sec, 4.0)
	var delay := 1.0 / cps

	for i in range(1, n + 1):
		if allow_skip and _skip_typewriter:
			_label.text = full_text
			return
		_label.text = full_text.substr(0, i)
		await get_tree().create_timer(delay).timeout

	_label.text = full_text


func hide_line() -> void:
	if not _fade_root.visible:
		return
	var tw_out := create_tween()
	tw_out.tween_property(_fade_root, "modulate:a", 0.0, FADE_OUT_SEC)
	await tw_out.finished
	_fade_root.visible = false
	_label.text = ""
