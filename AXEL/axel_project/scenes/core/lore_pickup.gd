extends RefCounted
class_name LorePickup


static func is_owned(flag: String) -> bool:
	if flag.is_empty():
		return false
	return bool(GameManager.get_flag(flag))


static func hide_owned(area: Area2D, visual: Node2D = null) -> void:
	if is_instance_valid(area):
		area.visible = false
		area.monitoring = false
		area.monitorable = false
		var shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape != null:
			shape.disabled = true
	if is_instance_valid(visual):
		visual.visible = false


static func take(
	host: Node,
	flag: String,
	inventory_name: String,
	dialogue: Node,
	lines,
	fight_return_scene: String,
	after_take: Callable = Callable(),
) -> void:
	if flag.is_empty() or is_owned(flag):
		return
	GameManager.set_flag(flag, true)
	GameManager.add_inventory_item(flag, inventory_name)
	if after_take.is_valid():
		after_take.call()
	if is_instance_valid(dialogue):
		if lines is String and not String(lines).is_empty():
			await dialogue.show_line(String(lines), 3.0)
		elif lines is PackedStringArray and (lines as PackedStringArray).size() > 0:
			await dialogue.show_lines(lines)
		elif lines is Array and (lines as Array).size() > 0:
			await dialogue.show_lines(lines)
	if fight_return_scene.is_empty() or host == null:
		return
	var world := host.get_node_or_null("/root/AxelWorld")
	if world != null:
		world.call("start_lore_fight", flag, fight_return_scene, true)
