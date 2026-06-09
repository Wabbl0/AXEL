extends Node2D

@onready var background: Sprite2D = $WalkableWorld/Background
@onready var _top_dialogue: Node = $TopDialogueOverlay

## Vertical offset for the corridor drawing (top-left anchor). Adjust when aligning floor/walls.
const BACKGROUND_Y := 0.0
## Border StaticBody2D nodes live under WalkableWorld/EnvironmentColliders in texture-pixel
## space; _sync_environment_colliders applies the same cover-fit scale/offset as Background.


func _ready() -> void:
	# Deferred so ExplorationViewport resize is visible to get_visible_rect().
	call_deferred("_apply_background_layout")
	_show_spawn_line()


func _show_spawn_line() -> void:
	await _top_dialogue.show_line("Even after all these years the smell is the same.", 3.5)


func _get_viewport_size() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2(1280.0, 720.0)
	var size := vp.get_visible_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2(1280.0, 720.0)
	return size


func _apply_background_layout() -> void:
	var tex := background.texture
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	var viewport_size := _get_viewport_size()
	var cover_scale := maxf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
	var fit_scale := Vector2.ONE * cover_scale
	background.scale = fit_scale
	background.position = Vector2(
		(viewport_size.x - tex_size.x * cover_scale) * 0.5,
		BACKGROUND_Y
	)
	_sync_environment_colliders(cover_scale, background.position)


func _sync_environment_colliders(cover_scale: float, bg_position: Vector2) -> void:
	var env := $WalkableWorld/EnvironmentColliders
	env.position = bg_position
	env.scale = Vector2.ONE * cover_scale
	call_deferred("_wake_static_colliders")


func _wake_static_colliders() -> void:
	for child in $WalkableWorld/EnvironmentColliders.get_children():
		if child is StaticBody2D:
			child.position = child.position
