extends Node2D

const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const MEMORY_KEY := "cafeteria_memory"
const MEMORY_LINES := [
	"|other|Do you think I'm a bad person?",
	"No.",
	"I just |beat:1.5| don't have the energy. To be around you.",
	"Sorry.",
	"|other|Oh.",
	"|other|No. I understand.",
]

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _exit_button: Button = $ExitLayer/ExitButton

var _is_transitioning := false
var _can_exit := false


func _ready() -> void:
	_exit_button.pressed.connect(_on_exit_pressed)
	_apply_chrome_scale()
	get_viewport().size_changed.connect(_apply_chrome_scale)
	set_process_unhandled_input(true)
	call_deferred("_play_memory_dialogue")


func _play_memory_dialogue() -> void:
	if GameManager.cafeteria_memory_line_seen:
		_can_exit = true
		return
	if not is_instance_valid(_top_dialogue):
		_can_exit = true
		return
	GameManager.set_cafeteria_memory_line_seen(true)
	await _top_dialogue.show_lines(MEMORY_LINES)
	_can_exit = true


func _unhandled_input(event: InputEvent) -> void:
	if not _can_exit or _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	_begin_return_to_cafeteria()


func _apply_chrome_scale() -> void:
	UiViewportScale.apply_exit_button(_exit_button, UiViewportScale.factor(self))


func _on_exit_pressed() -> void:
	if not _can_exit:
		return
	_begin_return_to_cafeteria()


func _is_interaction_event(event: InputEvent) -> bool:
	# Named InputMap action (Tab/E/Space/Enter + gamepad A). Excludes echo presses.
	if event.is_action_pressed("dialogue_advance"):
		return true
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		return touch_event.pressed
	return false


func _begin_return_to_cafeteria() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	GameManager.add_memory_once(MEMORY_KEY)
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var err := get_tree().change_scene_to_file(CAFETERIA_SCENE)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [CAFETERIA_SCENE, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)
