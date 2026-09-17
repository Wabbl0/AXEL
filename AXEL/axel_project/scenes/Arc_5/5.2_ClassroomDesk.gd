extends Node2D

const CLASSROOM_SCENE := "res://scenes/Arc_5/5.1_Classroom.tscn"
const TEX_EMPTY := "res://exports/Drawings/desk_empty.png"
const TEX_HAND := "res://exports/Drawings/desk_hand.png"
const TEX_DESK := "res://exports/Drawings/desk.png"
const OPEN_LINE := "This was their desk."
const DARE_LINE := "You said it was a dare."
const SPIT_LINE := "I'd spit on you if I could."
const BEAT_SEC := 1.5
const HAND_HOLD_SEC := 1.0
const SHAKE_AMPLITUDE_PX := 10.0
const DIM_ALPHA := 0.35

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _exit_button: Button = $ExitLayer/ExitButton
@onready var _background: Sprite2D = $WalkableWorld/Background
@onready var _camera: Camera2D = $Camera2D
@onready var _dim_rect: ColorRect = $DimLayer/DimRect

var _is_transitioning := false
var _can_exit := false
var _shake_tween: Tween


func _ready() -> void:
	_set_plate(TEX_EMPTY)
	_dim_rect.color = Color(1, 1, 1, 0)
	_exit_button.pressed.connect(_on_exit_pressed)
	_apply_chrome_scale()
	get_viewport().size_changed.connect(_apply_chrome_scale)
	_exit_button.visible = false
	set_process_unhandled_input(true)
	call_deferred("_run_desk_sequence")


func _run_desk_sequence() -> void:
	_set_plate(TEX_EMPTY)
	if is_instance_valid(_top_dialogue):
		_top_dialogue.visible = true
		await _top_dialogue.type_line(OPEN_LINE)
	await get_tree().create_timer(BEAT_SEC).timeout
	_set_plate(TEX_HAND)
	_start_local_shake()
	_tween_dim(DIM_ALPHA)
	await get_tree().create_timer(HAND_HOLD_SEC).timeout
	_stop_local_shake()
	_set_plate(TEX_DESK)
	await _tween_dim(0.0, true)
	if is_instance_valid(_top_dialogue):
		await _top_dialogue.hide_line()
		await _top_dialogue.type_line(DARE_LINE)
		await _top_dialogue.await_line_advance()
		await _top_dialogue.type_line(SPIT_LINE)
		await _top_dialogue.await_line_advance()
		await _top_dialogue.hide_line()
	_can_exit = true
	_exit_button.visible = true


func _set_plate(path: String) -> void:
	var tex := load(path) as Texture2D
	if tex != null:
		_background.texture = tex


func _start_local_shake() -> void:
	_stop_local_shake()
	if not is_instance_valid(_camera):
		return
	_shake_tween = create_tween()
	_shake_tween.set_loops(8)
	_shake_tween.tween_property(
		_camera, "offset", Vector2(SHAKE_AMPLITUDE_PX, -SHAKE_AMPLITUDE_PX * 0.6), 0.04
	)
	_shake_tween.tween_property(
		_camera, "offset", Vector2(-SHAKE_AMPLITUDE_PX, SHAKE_AMPLITUDE_PX * 0.5), 0.04
	)
	_shake_tween.tween_property(_camera, "offset", Vector2.ZERO, 0.04)


func _stop_local_shake() -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = null
	if is_instance_valid(_camera):
		_camera.offset = Vector2.ZERO


func _tween_dim(target_alpha: float, wait_done: bool = false) -> void:
	if not is_instance_valid(_dim_rect):
		return
	var tw := create_tween()
	tw.tween_property(_dim_rect, "color:a", target_alpha, 0.12)
	if wait_done:
		await tw.finished


func _unhandled_input(event: InputEvent) -> void:
	if not _can_exit or _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	_begin_return_to_classroom()


func _apply_chrome_scale() -> void:
	UiViewportScale.apply_exit_button(_exit_button, UiViewportScale.factor(self))


func _on_exit_pressed() -> void:
	if not _can_exit:
		return
	_begin_return_to_classroom()


func _is_interaction_event(event: InputEvent) -> bool:

	if event.is_action_pressed("dialogue_advance"):
		return true
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		return touch_event.pressed
	return false


func _begin_return_to_classroom() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	GameManager.set_classroom_desk_seen(true)
	_stop_local_shake()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()

	var world := get_node_or_null("/root/AxelWorld")
	if world != null and bool(world.call("start_memory_fight", CLASSROOM_SCENE)):
		return
	var err := get_tree().change_scene_to_file(CLASSROOM_SCENE)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [CLASSROOM_SCENE, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)
