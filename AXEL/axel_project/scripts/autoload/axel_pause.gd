extends Node
## AxelPause — global pause owner (Phase 0.6, D6).
##
## Contract:
## - This autoload is the ONLY writer of `get_tree().paused`.
## - It runs in PROCESS_MODE_ALWAYS so it can unpause.
## - AxelMusic is promoted to ALWAYS so BGM keeps playing under the pause menu.
## - AxelEventFx stays PAUSABLE on purpose: glitch bursts, jumpscares and the
##   interface pulse must not fire while paused.
## - Pause is refused while TopDialogueOverlay is mid-sequence (D6: pausing may
##   not desync the typewriter) and on non-gameplay scenes (main menu).
## - Esc / gamepad Start arrive via _unhandled_input, so any scene that consumes
##   the key first (locker hub, school map, combat settings panel) wins — those
##   screens keep their existing back/close behavior.
##
## Phase 1.5 replaces the placeholder scrim with the real pause menu; it must
## keep using request_pause()/request_unpause() and pause_state_changed.

signal pause_state_changed(paused: bool)

const _MENU_SCENE_PREFIX := "res://scenes/Main_Menu/"

var _scrim_layer: CanvasLayer


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_promote_music_for_pause()
	_build_placeholder_scrim()


func is_paused() -> bool:
	return get_tree().paused


## Returns true when the pause state actually changed.
func request_pause() -> bool:
	if get_tree().paused:
		return false
	if not _can_pause_here():
		return false
	get_tree().paused = true
	_set_scrim_visible(true)
	pause_state_changed.emit(true)
	return true


func request_unpause() -> bool:
	if not get_tree().paused:
		return false
	get_tree().paused = false
	_set_scrim_visible(false)
	pause_state_changed.emit(false)
	return true


func toggle_pause() -> bool:
	return request_unpause() if get_tree().paused else request_pause()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if toggle_pause():
		get_viewport().set_input_as_handled()


func _can_pause_here() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	if scene.scene_file_path.begins_with(_MENU_SCENE_PREFIX):
		return false
	if _dialogue_busy(scene):
		return false
	return true


func _dialogue_busy(scene: Node) -> bool:
	var overlay := scene.get_node_or_null("TopDialogueOverlay")
	if overlay == null:
		return false
	if overlay.has_method("is_sequence_busy"):
		return bool(overlay.call("is_sequence_busy"))
	return false


func _promote_music_for_pause() -> void:
	var music := get_node_or_null("/root/AxelMusic")
	if music != null:
		music.process_mode = Node.PROCESS_MODE_ALWAYS


## Minimal "PAUSED" scrim so the 0.6 contract is visible and testable before
## the Phase 1.5 pause menu replaces it. CanvasLayer 120: above dialogue (111)
## and hub chrome (110).
func _build_placeholder_scrim() -> void:
	_scrim_layer = CanvasLayer.new()
	_scrim_layer.name = "AxelPauseScrim"
	_scrim_layer.layer = 120
	_scrim_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_scrim_layer.visible = false

	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.62)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim_layer.add_child(scrim)

	var label := Label.new()
	label.name = "PausedLabel"
	label.text = "PAUSED"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	var font := load("res://combat/ui/fonts/VT323-Regular.ttf") as FontFile
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color(0.86, 0.08, 0.08))
	_scrim_layer.add_child(label)

	add_child(_scrim_layer)


func _set_scrim_visible(visible_now: bool) -> void:
	if not is_instance_valid(_scrim_layer):
		return
	if visible_now:
		var label := _scrim_layer.get_node_or_null("PausedLabel") as Label
		if label != null:
			label.add_theme_font_size_override(
				"font_size", roundi(64.0 * UiViewportScale.factor(self))
			)
	_scrim_layer.visible = visible_now
