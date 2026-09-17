extends Area2D
class_name InteractSpot

enum Action {
	GO_TO_SCENE,
	PICKUP_LORE,
	PLAY_LINES,
	OPEN_MEMORY,
	CUSTOM,
}

@export var zone_id: String = ""
@export var action: Action = Action.GO_TO_SCENE
@export var dest_scene: String = ""
@export var spawn_side_key: String = ""
@export var spawn_side_value: String = ""
@export var arrival_axis: int = Vector2.AXIS_Y
@export var save_arrival_t: bool = true
@export var lore_flag: String = ""
@export var lore_inventory_name: String = ""
@export var lore_fight_return_scene: String = ""
@export var hide_when_flag: String = ""
@export var memory_key: String = ""
@export var return_pos_setter: String = ""
@export var lines: PackedStringArray = PackedStringArray()
@export var prompt_visual_offset: Vector2 = Vector2.ZERO


func is_available() -> bool:
	if not hide_when_flag.is_empty() and LorePickup.is_owned(hide_when_flag):
		return false
	if action == Action.PICKUP_LORE and LorePickup.is_owned(lore_flag):
		return false
	if action == Action.OPEN_MEMORY and not memory_key.is_empty():
		if GameManager.has_memory_scene(memory_key):
			return false
	return monitoring


func prompt_anchor() -> Vector2:
	return anchor_from_area(self) + prompt_visual_offset


func apply_spawn_side() -> void:
	if spawn_side_key.is_empty() or spawn_side_value.is_empty():
		return
	var setter := "set_%s" % spawn_side_key
	if GameManager.has_method(setter):
		GameManager.call(setter, spawn_side_value)


func save_leave_t(player: Node2D) -> void:
	if not save_arrival_t or not is_instance_valid(player):
		return
	GameManager.set_interact_arrival_t(
		InteractArrival.fraction_along(player, self, arrival_axis)
	)


func save_return_pos(player: Node2D, env: Node2D) -> void:
	if return_pos_setter.is_empty():
		return
	if not is_instance_valid(player) or not is_instance_valid(env):
		return
	if GameManager.has_method(return_pos_setter):
		GameManager.call(return_pos_setter, env.to_local(player.global_position))


static func anchor_from_area(area: Area2D) -> Vector2:
	if not is_instance_valid(area):
		return Vector2.ZERO
	var shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape is RectangleShape2D:
		return shape.global_position
	var poly := area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if poly != null:
		return polygon_global_centroid(poly)
	return area.global_position


static func polygon_global_centroid(poly: CollisionPolygon2D) -> Vector2:
	if not is_instance_valid(poly) or poly.polygon.is_empty():
		return poly.global_position if is_instance_valid(poly) else Vector2.ZERO
	var sum := Vector2.ZERO
	for local_point in poly.polygon:
		sum += poly.to_global(local_point)
	return sum / float(poly.polygon.size())
