extends RefCounted
class_name PlayerSpawnSync


static func capture_tex(env: Node2D, player: Node2D) -> Vector2:
	if not is_instance_valid(env) or not is_instance_valid(player):
		return Vector2.ZERO
	return env.to_local(player.global_position)


static func apply_tex(env: Node2D, player: Node2D, tex: Vector2) -> void:
	if not is_instance_valid(env) or not is_instance_valid(player):
		return
	player.global_position = env.to_global(tex)
