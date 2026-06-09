extends Node
## Per-scene exploration window size. Applied on scene enter; restores previous size on exit.
## Future user-scale settings can multiply design_viewport via a separate autoload.

const ENV_DEBUG_SCALE := "AXEL_DEBUG_VIEWPORT_SCALE"

@export var design_viewport: Vector2i = Vector2i(1920, 1200)
@export var debug_scale: float = 1.0

var _previous_size: Vector2i = Vector2i.ZERO


func _ready() -> void:
	_previous_size = DisplayServer.window_get_size()
	var scale := _effective_scale()
	var target := Vector2i(
		roundi(float(design_viewport.x) * scale),
		roundi(float(design_viewport.y) * scale),
	)
	DisplayServer.window_set_size(target)


func _exit_tree() -> void:
	if _previous_size.x > 0 and _previous_size.y > 0:
		DisplayServer.window_set_size(_previous_size)


func _effective_scale() -> float:
	var env := OS.get_environment(ENV_DEBUG_SCALE)
	if not env.is_empty():
		var parsed := env.to_float()
		if parsed > 0.0:
			return parsed
	if debug_scale > 0.0:
		return debug_scale
	return 1.0
