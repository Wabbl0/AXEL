extends Node
## Per-scene exploration window size. Applied on scene enter; restores previous size on exit.
## Sets both root content_scale_size (game coords) and window size so cover-fit layout matches.
## Embedded editor play ignores window resize — use Run → "Make Floating" / disable embed.

const ENV_DEBUG_SCALE := "AXEL_DEBUG_VIEWPORT_SCALE"

@export var design_viewport: Vector2i = Vector2i(1920, 1200)
@export var debug_scale: float = 1.0

var _previous_window_size: Vector2i = Vector2i.ZERO
var _previous_content_scale: Vector2i = Vector2i.ZERO


func _ready() -> void:
	var root: Window = get_tree().root
	_previous_window_size = root.size
	_previous_content_scale = root.content_scale_size
	var target := _target_size()
	root.content_scale_size = target
	root.size = target


func _exit_tree() -> void:
	var root: Window = get_tree().root
	if _previous_content_scale.x > 0 and _previous_content_scale.y > 0:
		root.content_scale_size = _previous_content_scale
	if _previous_window_size.x > 0 and _previous_window_size.y > 0:
		root.size = _previous_window_size


func _target_size() -> Vector2i:
	var scale := _effective_scale()
	return Vector2i(
		roundi(float(design_viewport.x) * scale),
		roundi(float(design_viewport.y) * scale),
	)


func _effective_scale() -> float:
	var env := OS.get_environment(ENV_DEBUG_SCALE)
	if not env.is_empty():
		var parsed := env.to_float()
		if parsed > 0.0:
			return parsed
	if debug_scale > 0.0:
		return debug_scale
	return 1.0
