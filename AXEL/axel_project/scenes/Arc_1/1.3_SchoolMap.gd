extends Control

const LOCKER_HUB_SCENE := "res://scenes/Arc_1/1.3_LockerHub.tscn"
const _MapOverlayScript := preload("res://scenes/ui/locker_map_overlay.gd")

var _is_transitioning := false
var _map_overlay: CanvasLayer


func _ready() -> void:
	set_process_input(true)
	_map_overlay = _MapOverlayScript.new()
	_map_overlay.name = "LockerMapOverlay"
	_map_overlay.connect("travel_requested", _on_travel)
	_map_overlay.connect("closed", _on_exit_pressed)
	add_child(_map_overlay)
	if _map_overlay.has_method("open"):
		_map_overlay.call("open")


func _input(event: InputEvent) -> void:
	if not _is_exit_key(event):
		return
	get_viewport().set_input_as_handled()
	_on_exit_pressed()


func _is_exit_key(event: InputEvent) -> bool:
	return event.is_action_pressed("back")


func _on_travel(scene_path: String) -> void:
	_go_to_scene(scene_path)


func _on_exit_pressed() -> void:
	var dest := LOCKER_HUB_SCENE
	var keep_pause_return := false
	if not GameManager.pause_map_return_path.is_empty():
		dest = GameManager.pause_map_return_path
		keep_pause_return = true
	_go_to_scene(dest, keep_pause_return)


func _go_to_scene(scene_path: String, keep_pause_return: bool = false) -> void:
	if _is_transitioning:
		return
	if not keep_pause_return:
		GameManager.clear_pause_map_return()
	_is_transitioning = true
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [scene_path, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)
