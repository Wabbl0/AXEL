extends Control

const CORRIDOR_SCENE := "res://scenes/Arc_1/1.2_Corridor.tscn"
const MEMORY_KEY := "scene_3"
const ESC_HINT_FONT := 48
const ESC_HINT_MARGIN := 24.0
const _MapOverlayScript := preload("res://scenes/ui/locker_map_overlay.gd")

@onready var _map_hotspot = $MapHotspot
@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _exit_button: Button = $ExitLayer/ExitButton
@onready var _shelves: Node = get_node_or_null("LockerShelves")
@onready var _esc_hint: Label = get_node_or_null("ExitLayer/EscHint")

var _map_overlay: CanvasLayer

var _is_transitioning := false
var _first_visit_dialogue_running := false


func _ready() -> void:
	_exit_button.pressed.connect(_on_exit_pressed)
	_apply_chrome_scale()
	get_viewport().size_changed.connect(_apply_chrome_scale)
	_map_hotspot.activated.connect(_on_map_hotspot_activated)
	_map_hotspot.mouse_entered.connect(_on_map_paper_hover.bind(true))
	_map_hotspot.mouse_exited.connect(_on_map_paper_hover.bind(false))
	_map_overlay = _MapOverlayScript.new()
	_map_overlay.name = "LockerMapOverlay"
	_map_overlay.connect("travel_requested", _on_map_travel)
	add_child(_map_overlay)
	set_process_input(true)
	_grant_stash_flag()
	call_deferred("_play_first_visit_dialogue")


func _process(_delta: float) -> void:
	if _esc_hint == null:
		return
	_esc_hint.visible = not _first_visit_dialogue_running and not _is_transitioning and not _map_is_open()


func _map_is_open() -> bool:
	return _map_overlay != null and _map_overlay.has_method("is_open") and bool(_map_overlay.call("is_open"))


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


func _on_map_paper_hover(hovered: bool) -> void:
	var paper := get_node_or_null("LockerShelves/ItemAnchor/Map")
	if paper != null and paper.has_method("set_paper_hovered"):
		paper.call("set_paper_hovered", hovered)


func _on_map_hotspot_activated() -> void:
	if _first_visit_dialogue_running:
		return
	if _map_overlay != null and _map_overlay.has_method("open"):
		_map_overlay.call("open")


func _on_map_travel(scene_path: String) -> void:
	if _first_visit_dialogue_running or _is_transitioning:
		return
	if scene_path.is_empty():
		return
	_go_to_scene(scene_path)


func _input(event: InputEvent) -> void:
	if not _is_exit_key(event):
		return
	if _overlay_wants_advance(event):
		return
	if _first_visit_dialogue_running:
		get_viewport().set_input_as_handled()
		return
	if _map_overlay != null and _map_overlay.has_method("is_open") and bool(_map_overlay.call("is_open")):
		get_viewport().set_input_as_handled()
		_map_overlay.call("close")
		return
	get_viewport().set_input_as_handled()
	_on_exit_pressed()


func _overlay_wants_advance(event: InputEvent) -> bool:
	if not is_instance_valid(_top_dialogue):
		return false
	if not _top_dialogue.has_method("wants_advance_event"):
		return false
	return bool(_top_dialogue.call("wants_advance_event", event))


func _is_exit_key(event: InputEvent) -> bool:
	return event.is_action_pressed("back")


func _apply_chrome_scale() -> void:
	var f := UiViewportScale.factor(self)
	UiViewportScale.apply_exit_button(_exit_button, f)
	if _esc_hint != null:
		_esc_hint.add_theme_font_size_override("font_size", roundi(ESC_HINT_FONT * f))
		_esc_hint.position = Vector2(ESC_HINT_MARGIN, ESC_HINT_MARGIN) * f
		_esc_hint.reset_size()
	if _shelves != null and _shelves.has_method("_remap_rows"):
		_shelves.call("_remap_rows")


func _on_exit_pressed() -> void:
	if _map_overlay != null and _map_overlay.has_method("is_open") and bool(_map_overlay.call("is_open")):
		_map_overlay.call("close")
		return
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
