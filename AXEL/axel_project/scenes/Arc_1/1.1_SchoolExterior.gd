extends Node2D

@onready var _top_dialogue: Node = $TopDialogueOverlay


func _ready() -> void:
	_run_intro_dialogue()


func _run_intro_dialogue() -> void:
	await _top_dialogue.show_line("You promised, you'd never come back.", 2.0)
	await get_tree().create_timer(0.8).timeout
	await _top_dialogue.show_line("Yet, here we are...", 2.5)
