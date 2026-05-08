extends Node2D

@onready var background: ColorRect = $Background
@onready var ceiling_light: PointLight2D = $CeilingLight
@onready var _top_dialogue: Node = $TopDialogueOverlay

var _flicker_time := 0.0

func _ready() -> void:
	_start_push_in_tween()
	_show_spawn_line()


func _show_spawn_line() -> void:
	await _top_dialogue.show_line("Even after all these years the smell is the same.", 3.5)

func _process(delta: float) -> void:
	_flicker_time += delta
	_update_ceiling_flicker()

func _start_push_in_tween() -> void:
	background.scale = Vector2.ONE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(background, "scale", Vector2(1.04, 1.04), 3.2)

func _update_ceiling_flicker() -> void:
	var base_energy := 0.72 + (sin(_flicker_time * 7.0) * 0.18)
	if int(_flicker_time * 14.0) % 13 == 0:
		base_energy = 0.2
	ceiling_light.energy = clamp(base_energy, 0.15, 1.1)
