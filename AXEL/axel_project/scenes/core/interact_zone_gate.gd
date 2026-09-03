extends RefCounted
class_name InteractZoneGate
## Shared door/[E] gate helpers for walkable rooms.
## body_in_area: live overlap poll (not body_entered latch).
## dialogue_busy: talk bar still doing something — hide chip, ignore door [E].
## movement_pressed: first WASD / arrow press clears the arrival latch.


static func body_in_area(area: Area2D, body: Node2D) -> bool:
	if not is_instance_valid(area) or not is_instance_valid(body):
		return false
	if not area.monitoring:
		return false
	if area.get_overlapping_bodies().has(body):
		return true
	# Physics overlap can stay empty after a parent scale/move until the area
	# is poked. Sample the Front circle against the live box (same point
	# InteractArrival uses — not CollisionShape2D.global_position).
	return _front_overlaps_rect_area(area, body)


static func _front_overlaps_rect_area(area: Area2D, body: Node2D) -> bool:
	var shape_node := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.disabled:
		return false
	var rect_shape := shape_node.shape as RectangleShape2D
	if rect_shape == null:
		return false
	var sample := body.global_position
	var radius := 0.0
	if body is CharacterBody2D:
		var front := body.get_node_or_null("CollisionFront") as CollisionShape2D
		if front != null:
			sample = body.to_global(front.position)
			var circle := front.shape as CircleShape2D
			if circle != null:
				var shape_scale := shape_node.global_transform.get_scale().x
				if shape_scale > 0.001:
					radius = circle.radius * body.global_transform.get_scale().x / shape_scale
	var local := shape_node.global_transform.affine_inverse() * sample
	var half := rect_shape.size * 0.5
	return absf(local.x) <= half.x + radius and absf(local.y) <= half.y + radius


static func dialogue_busy(overlay: Node) -> bool:
	if not is_instance_valid(overlay):
		return false
	if overlay.has_method("is_sequence_busy") and bool(overlay.call("is_sequence_busy")):
		return true
	if overlay.has_method("is_bar_visible") and bool(overlay.call("is_bar_visible")):
		return true
	return false


static func movement_pressed() -> bool:
	return (
		Input.is_action_pressed("move_left")
		or Input.is_action_pressed("move_right")
		or Input.is_action_pressed("move_up")
		or Input.is_action_pressed("move_down")
	)
