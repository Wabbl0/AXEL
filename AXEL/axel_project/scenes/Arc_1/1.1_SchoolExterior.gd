extends Node2D

@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _player: CharacterBody2D = $PlayerLayer/Player
@onready var _door_interact_area: Area2D = get_node("1.1_EnvironmentPlaceholders/1.1_School_Building_Doors_01_InteractArea")

var _noir_filter_rect: ColorRect

const _NEXT_SCENE_PATH := "res://scenes/Arc_1/1.2_Corridor.tscn"
const _NOIR_OVERLAY_ENABLED := false
const _USE_LOCAL_NOIR_TUNING := true

var _is_transitioning := false


func _ready() -> void:
	var noir_overlay := get_node_or_null("NoirPaletteOverlay") as CanvasLayer
	if noir_overlay != null:
		noir_overlay.visible = _NOIR_OVERLAY_ENABLED
	if _NOIR_OVERLAY_ENABLED:
		_noir_filter_rect = get_node_or_null("NoirPaletteOverlay/FilterRect") as ColorRect
		if _USE_LOCAL_NOIR_TUNING:
			_apply_local_noir_tuning()
	set_process_unhandled_input(true)
	_run_intro_dialogue()


func _apply_local_noir_tuning() -> void:
	if _noir_filter_rect == null:
		push_warning("1.1_SchoolExterior: NoirPaletteOverlay/FilterRect missing; skipping local noir tuning.")
		return
	var shader_material := _noir_filter_rect.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("t0", 0.10)
	shader_material.set_shader_parameter("t1", 0.28)
	shader_material.set_shader_parameter("t2", 0.58)
	shader_material.set_shader_parameter("line_contrast", 1.5)
	shader_material.set_shader_parameter("dark_blood_color", Color(0.26, 0.0, 0.0, 1.0))
	shader_material.set_shader_parameter("blood_red_color", Color(0.88, 0.0, 0.0, 1.0))
	shader_material.set_shader_parameter("white_color", Color(0.0, 0.0, 0.0, 1.0))


func _run_intro_dialogue() -> void:
	await _top_dialogue.show_line("You promised, you'd never come back.", 2.0)
	await get_tree().create_timer(0.8).timeout
	await _top_dialogue.show_line("Yet, here we are...", 2.5)
	await get_tree().create_timer(0.55).timeout
	await _top_dialogue.show_line("Pathetic.", 1.6)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if not _is_interaction_event(event):
		return
	if not _is_player_near_door():
		return
	_is_transitioning = true
	var err := get_tree().change_scene_to_file(_NEXT_SCENE_PATH)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [_NEXT_SCENE_PATH, err])
		_is_transitioning = false


func _is_interaction_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]


func _is_player_near_door() -> bool:
	if not is_instance_valid(_door_interact_area) or not is_instance_valid(_player):
		return false
	for body in _door_interact_area.get_overlapping_bodies():
		if body == _player:
			return true
	return false
