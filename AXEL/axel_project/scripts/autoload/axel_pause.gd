extends Node

signal pause_state_changed(paused: bool)

const _MENU_SCENE_PREFIX := "res://scenes/Main_Menu/"
const _PauseMenuScript := preload("res://scenes/ui/pause_menu.gd")

var _menu: CanvasLayer


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_promote_music_for_pause()
	_menu = _PauseMenuScript.new()
	_menu.name = "AxelPauseMenu"
	add_child(_menu)


func is_paused() -> bool:
	return get_tree().paused


func request_pause() -> bool:
	if get_tree().paused:
		return false
	if not _can_pause_here():
		return false
	get_tree().paused = true
	if _menu != null and _menu.has_method("show_menu"):
		_menu.call("show_menu")
	pause_state_changed.emit(true)
	return true


func request_unpause() -> bool:
	if not get_tree().paused:
		return false
	get_tree().paused = false
	if _menu != null and _menu.has_method("hide_menu"):
		_menu.call("hide_menu")
	pause_state_changed.emit(false)
	return true


func toggle_pause() -> bool:
	return request_unpause() if get_tree().paused else request_pause()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back") and get_tree().paused:
		if _menu != null and _menu.has_method("close_submenu") and bool(_menu.call("close_submenu")):
			get_viewport().set_input_as_handled()
			return
	if not event.is_action_pressed("pause"):
		return
	if get_tree().paused and _menu != null and _menu.has_method("close_submenu"):
		if bool(_menu.call("close_submenu")):
			get_viewport().set_input_as_handled()
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
