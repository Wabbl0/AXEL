extends Control

## Dev-only preview for TopDialogueOverlay FX toggles.
## Play this scene directly: keys 1-6 toggle effects, Space replays the sample sequence.

@onready var _overlay: CanvasLayer = $TopDialogueOverlay
@onready var _status: Label = $StatusLabel

var _playing := false


func _ready() -> void:
	set_process_unhandled_input(true)
	_refresh_status()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_overlay.fx_cursor = not _overlay.fx_cursor
		KEY_2:
			_overlay.fx_slide_up = not _overlay.fx_slide_up
		KEY_3:
			_overlay.fx_chrome = not _overlay.fx_chrome
		KEY_4:
			_overlay.fx_line_swap_glitch = not _overlay.fx_line_swap_glitch
		KEY_5:
			_overlay.fx_border_pulse = not _overlay.fx_border_pulse
		KEY_6:
			_overlay.fx_crt_power = not _overlay.fx_crt_power
		KEY_SPACE:
			_play_sample()
		_:
			return
	_refresh_status()


func _refresh_status() -> void:
	_status.text = (
		"TopDialogueOverlay FX Preview (defaults: chrome + glitch + CRT ON)\n"
		+ "1 cursor: %s  |  2 slide: %s  |  3 chrome: %s  |  4 glitch: %s  |  5 pulse: %s  |  6 CRT: %s\n"
		+ "[Space] replay sample (CRT on -> line2 -> 2s beat -> Pathetic. -> CRT off)"
	) % [
		_on_off(_overlay.fx_cursor),
		_on_off(_overlay.fx_slide_up),
		_on_off(_overlay.fx_chrome),
		_on_off(_overlay.fx_line_swap_glitch),
		_on_off(_overlay.fx_border_pulse),
		_on_off(_overlay.fx_crt_power),
	]


func _on_off(enabled: bool) -> String:
	return "ON" if enabled else "OFF"


func _play_sample() -> void:
	if _playing:
		return
	_playing = true
	await _overlay.type_line("Yet, here we are...")
	await get_tree().create_timer(2.0).timeout
	await _overlay.type_line("Pathetic.")
	await get_tree().create_timer(1.0).timeout
	await _overlay.hide_line()
	_playing = false
