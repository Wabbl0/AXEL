extends Node2D
class_name MemoryStill

@export var dest_scene: String = ""
@export var memory_key: String = ""
@export var seen_property: String = ""
@export var lines: PackedStringArray = PackedStringArray()
@export var add_memory_on_leave: bool = true
@export var set_desk_seen_on_leave: bool = false
@export var hide_exit_until_ready: bool = false

@onready var _top_dialogue: Node = get_node_or_null("TopDialogueOverlay")
@onready var _exit_button: Button = get_node_or_null("ExitLayer/ExitButton")

var _is_transitioning := false
var _can_exit := false


func _ready() -> void:
	if is_instance_valid(_exit_button):
		_exit_button.pressed.connect(_on_exit_pressed)
		if hide_exit_until_ready:
			_exit_button.visible = false
	_apply_chrome_scale()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_apply_chrome_scale):
		vp.size_changed.connect(_apply_chrome_scale)
	set_process_unhandled_input(true)
	call_deferred("_play_opening")


func _play_opening() -> void:
	await play_default_lines()
	mark_can_exit()


func play_default_lines() -> void:
	if not seen_property.is_empty() and bool(GameManager.get(seen_property)):
		return
	if not is_instance_valid(_top_dialogue):
		return
	if not seen_property.is_empty():
		var setter := "set_%s" % seen_property
		if GameManager.has_method(setter):
			GameManager.call(setter, true)
	if lines.size() > 0:
		await _top_dialogue.show_lines(lines)


func mark_can_exit() -> void:
	_can_exit = true
	if is_instance_valid(_exit_button):
		_exit_button.visible = true


func _apply_chrome_scale() -> void:
	if not is_instance_valid(_exit_button):
		return
	UiViewportScale.apply_exit_button(_exit_button, UiViewportScale.factor(self))


func _on_exit_pressed() -> void:
	if not _can_exit:
		return
	begin_leave()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_exit or _is_transitioning:
		return
	if not is_leave_event(event):
		return
	begin_leave()


func is_leave_event(event: InputEvent) -> bool:
	if event.is_action_pressed("dialogue_advance"):
		return true
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		return touch_event.pressed
	return false


func begin_leave() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if add_memory_on_leave and not memory_key.is_empty():
		GameManager.add_memory_once(memory_key)
	if set_desk_seen_on_leave:
		GameManager.set_classroom_desk_seen(true)
	on_before_leave()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and bool(world.call("start_memory_fight", dest_scene)):
		return
	if not ExplorationTransition.go(self, dest_scene, null, null, false):
		_is_transitioning = false


func on_before_leave() -> void:
	pass
