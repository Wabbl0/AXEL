extends Control

const CORRIDOR_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const MAP_SCENE := "res://scenes/Arc_1/1.3_SchoolMap.tscn"
const MEMORY_KEY := "scene_3"

@onready var _map_hotspot = $MapHotspot
@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _exit_button: Button = $ExitLayer/ExitButton
@onready var _shelves: Node = get_node_or_null("LockerShelves")

var _is_transitioning := false
var _first_visit_dialogue_running := false


func _ready() -> void:
	_exit_button.pressed.connect(_on_exit_pressed)
	_apply_chrome_scale()
	get_viewport().size_changed.connect(_apply_chrome_scale)
	_map_hotspot.activated.connect(_on_map_hotspot_activated)
	set_process_input(true)
	_grant_stash_flag()
	call_deferred("_play_first_visit_dialogue")


func _grant_stash_flag() -> void:
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("grant_locker_stash_once"):
		run.call("grant_locker_stash_once")


func _play_first_visit_dialogue() -> void:
	if GameManager.has_memory_scene(MEMORY_KEY):
		return
	_first_visit_dialogue_running = true
	await _top_dialogue.show_lines([
		"Oh look, a map of the school.",
		"Was your memory so bad you needed a map of the school?",
	])
	GameManager.add_memory_once(MEMORY_KEY)
	_first_visit_dialogue_running = false


func _on_map_hotspot_activated() -> void:
	if _first_visit_dialogue_running:
		return
	_go_to_scene(MAP_SCENE)


func _input(event: InputEvent) -> void:
	if not _is_exit_key(event):
		return
	if _first_visit_dialogue_running:
		get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()
	_on_exit_pressed()


func _is_exit_key(event: InputEvent) -> bool:
	return event.is_action_pressed("back")


func _apply_chrome_scale() -> void:
	var f := UiViewportScale.factor(self)
	UiViewportScale.apply_exit_button(_exit_button, f)
	if _shelves != null and _shelves.has_method("_remap_rows"):
		_shelves.call("_remap_rows")


func _on_exit_pressed() -> void:
	if _first_visit_dialogue_running or _is_transitioning:
		return
	GameManager.set_corridor_from_locker(true)
	_queue_locker_tutorial_fight()
	_go_to_scene(CORRIDOR_SCENE)


func _queue_locker_tutorial_fight() -> void:
	var world := get_node_or_null("/root/AxelWorld")
	var run := get_node_or_null("/root/AxelRun")
	if world == null or not world.has_method("queue_locker_tutorial_fight"):
		return
	if run != null and (
		bool(run.state.tutorial_fight_done) or bool(run.state.tutorial_fight_pending)
	):
		return
	if not bool(world.call("queue_locker_tutorial_fight")):
		push_warning("1.3_LockerHub: tutorial fight did not queue on locker exit")


func _go_to_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if scene_path == CORRIDOR_SCENE and is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [scene_path, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)
