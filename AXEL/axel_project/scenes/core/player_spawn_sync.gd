extends RefCounted
class_name PlayerSpawnSync
## Default spawn is the Player node's live editor position.
## Capture in EnvironmentColliders local space *before* cover-fit, then apply
## after. Never hardcode a spawn Vector2. Peek / return from another room may
## place elsewhere; a fresh Play with no transition flag must use this node.


static func capture_tex(env: Node2D, player: Node2D) -> Vector2:
	if not is_instance_valid(env) or not is_instance_valid(player):
		return Vector2.ZERO
	return env.to_local(player.global_position)


static func apply_tex(env: Node2D, player: Node2D, tex: Vector2) -> void:
	if not is_instance_valid(env) or not is_instance_valid(player):
		return
	player.global_position = env.to_global(tex)
