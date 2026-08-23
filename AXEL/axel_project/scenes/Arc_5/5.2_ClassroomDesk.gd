extends Node2D

const CLASSROOM_SCENE := "res://scenes/Arc_5/5.1_Classroom.tscn"
const TEX_EMPTY := "res://exports/Drawings/desk_empty.png"
const TEX_HAND := "res://exports/Drawings/desk_hand.png"
const TEX_DESK := "res://exports/Drawings/desk.png"
const DESK_LINES := [
	"It's THEIR desk.",
	"You said it was a dare.|beat:1.5|",
	"I'd spit on you if I could.",
]
const T_HAND_MS := 650
const T_DESK_MS := 1000
const T_LINES_MS := 1300
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
	var empty_tex := load(TEX_EMPTY) as Texture2D
	if empty_tex != null:
		_background.texture = empty_tex
	_dim_rect.color = Color(0, 0, 0, 0)
	_exit_button.pressed.connect(_on_exit_pressed)
	_exit_button.visible = false
	set_process_unhandled_input(true)
	call_deferred("_run_desk_sequence")


func _run_desk_sequence() -> void:
	var start_ms := Time.get_ticks_msec()
	await _wait_until(start_ms, T_HAND_MS)
	var hand_tex := load(TEX_HAND) as Texture2D
	if hand_tex != null:
		_background.texture = hand_tex
	_start_local_shake()
	_tween_dim(DIM_ALPHA)
	await _wait_until(start_ms, T_DESK_MS)
	_stop_local_shake()
	_tween_dim(0.0)
	var desk_tex := load(TEX_DESK) as Texture2D
	if desk_tex != null:
		_background.texture = desk_tex
	await _wait_until(start_ms, T_LINES_MS)
	if is_instance_valid(_top_dialogue):
		await _top_dialogue.show_lines(DESK_LINES)
	_can_exit = true
	_exit_button.visible = true


func _wait_until(start_ms: int, target_offset_ms: int) -> void:
	var remain_ms := target_offset_ms - (Time.get_ticks_msec() - start_ms)
	if remain_ms > 0:
		await get_tree().create_timer(remain_ms / 1000.0).timeout


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


func _tween_dim(target_alpha: float) -> void:
	if not is_instance_valid(_dim_rect):
		return
	var tw := create_tween()
	tw.tween_property(_dim_rect, "color:a", target_alpha, 0.12)


func _unhandled_input(event: InputEvent) -> void:
	if not _can_exit or _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	_begin_return_to_classroom()


func _on_exit_pressed() -> void:
	if not _can_exit:
		return
	_begin_return_to_classroom()


func _is_interaction_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]


func _begin_return_to_classroom() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	GameManager.set_classroom_desk_seen(true)
	_stop_local_shake()
	if is_instance_valid(_top_dialogue) and _top_dialogue.has_method("interrupt_line"):
		_top_dialogue.interrupt_line()
	var err := get_tree().change_scene_to_file(CLASSROOM_SCENE)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [CLASSROOM_SCENE, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)
