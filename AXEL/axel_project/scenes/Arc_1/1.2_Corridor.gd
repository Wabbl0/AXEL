extends Node2D

@onready var background: Sprite2D = $Background
@onready var _top_dialogue: Node = $TopDialogueOverlay

## Vertical offset for the corridor drawing (top-left anchor). Adjust when aligning floor/walls.
const BACKGROUND_Y := 0.0

const _VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const _PUSH_IN_SCALE_MULTIPLIER := 1.04
const _PUSH_IN_DURATION := 3.2

var _background_base_scale := Vector2.ONE


func _ready() -> void:
	_apply_background_layout()
	_start_push_in_tween()
	_show_spawn_line()


func _show_spawn_line() -> void:
	await _top_dialogue.show_line("Even after all these years the smell is the same.", 3.5)


func _apply_background_layout() -> void:
	var tex := background.texture
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	var cover_scale := maxf(_VIEWPORT_SIZE.x / tex_size.x, _VIEWPORT_SIZE.y / tex_size.y)
	_background_base_scale = Vector2.ONE * cover_scale
	background.scale = _background_base_scale
	background.position = Vector2(
		(_VIEWPORT_SIZE.x - tex_size.x * cover_scale) * 0.5,
		BACKGROUND_Y
	)


func _start_push_in_tween() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		background,
		"scale",
		_background_base_scale * _PUSH_IN_SCALE_MULTIPLIER,
		_PUSH_IN_DURATION
	)
