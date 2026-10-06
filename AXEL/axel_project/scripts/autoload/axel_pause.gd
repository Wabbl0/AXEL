extends Node

signal pause_state_changed(paused: bool)

const _MENU_SCENE_PREFIX := "res://scenes/Main_Menu/"
const _PauseMenuScript := preload("res://scenes/ui/pause_menu.gd")

var _menu: CanvasLayer
var _focus_frozen := false
var _freeze_paused_tree := false
var _freeze_master_was_muted := false
var _freeze_start_ms := 0
var _frozen_total_ms := 0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focus_freeze()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focus_thaw()


func is_focus_frozen() -> bool:
	return _focus_frozen


func game_msec() -> int:
	var now := Time.get_ticks_msec()
	var frozen := _frozen_total_ms
	if _focus_frozen:
		frozen += now - _freeze_start_ms
	return now - frozen


func _focus_freeze() -> void:
	if _focus_frozen:
		return
	_focus_frozen = true
	_freeze_start_ms = Time.get_ticks_msec()
	var tree := get_tree()
	_freeze_paused_tree = tree != null and not tree.paused
	if _freeze_paused_tree:
		tree.paused = true
	var master := AudioServer.get_bus_index(&"Master")
	if master >= 0:
		_freeze_master_was_muted = AudioServer.is_bus_mute(master)
		AudioServer.set_bus_mute(master, true)
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("set_frozen"):
		music.call("set_frozen", true)
	var saves := get_node_or_null("/root/AxelSaves")
	if saves != null and saves.has_method("save_active"):
		saves.call("save_active")


func _focus_thaw() -> void:
	if not _focus_frozen:
		return
	_frozen_total_ms += Time.get_ticks_msec() - _freeze_start_ms
	_focus_frozen = false
	var tree := get_tree()
	if _freeze_paused_tree and tree != null:
		tree.paused = false
	_freeze_paused_tree = false
	var master := AudioServer.get_bus_index(&"Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, _freeze_master_was_muted)
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("set_frozen"):
		music.call("set_frozen", false)


func _ready() -> void:
	_promote_music_for_pause()
	_menu = _PauseMenuScript.new()
	_menu.name = "AxelPauseMenu"
	add_child(_menu)
	var saves := get_node_or_null("/root/AxelSaves")
	if saves != null and saves.has_method("maybe_begin_play_scene"):
		saves.call("maybe_begin_play_scene")


func is_paused() -> bool:
	return get_tree().paused


func request_pause() -> bool:
	if get_tree().paused or _focus_frozen:
		return false
	if not _can_pause_here():
		return false
	get_tree().paused = true
	if _menu != null and _menu.has_method("show_menu"):
		_menu.call("show_menu")
	var sfx := get_node_or_null("/root/AxelSfx")
	if sfx != null and sfx.has_method("play_pause_open"):
		sfx.call("play_pause_open")
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


func open_guide() -> bool:
	if _menu == null or not _menu.has_method("open_guide"):
		return false
	if not get_tree().paused and not request_pause():
		return false
	return bool(_menu.call("open_guide"))


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
	if _tutorial_open():
		return false
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("is_game_over_menu_open") and bool(run.call("is_game_over_menu_open")):
		return false
	return true


func _tutorial_open() -> bool:
	var tutorial := get_node_or_null("/root/AxelTutorial")
	return tutorial != null and tutorial.has_method("is_typing") and bool(tutorial.call("is_typing"))


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
