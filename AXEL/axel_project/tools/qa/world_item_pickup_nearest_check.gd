extends SceneTree

const PickupScript := preload("res://scenes/world/world_item_pickup.gd")


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	OS.set_environment("AXEL_WORLD_COMBAT", "0")
	root.size = Vector2i(1920, 1280)
	await process_frame
	var failures: Array[String] = []
	var world := root.get_node_or_null("AxelWorld")
	if world == null:
		push_error("world_item_pickup_nearest_check: AxelWorld autoload missing")
		quit(1)
		return

	var room := Node2D.new()
	room.name = "Room"
	var layer := Node2D.new()
	layer.name = "PlayerLayer"
	room.add_child(layer)
	var player := CharacterBody2D.new()
	player.name = "Player"
	layer.add_child(player)
	var items := Node2D.new()
	items.name = "Items"
	room.add_child(items)
	root.add_child(room)
	current_scene = room

	var pickups: Array[Area2D] = []
	for x in [150.0, 60.0, 100.0]:
		var pickup := PickupScript.new() as Area2D
		pickup.position = Vector2(x, 0.0)
		items.add_child(pickup)
		pickup.setup("C-TEST-%d" % int(x), "", -1)
		pickups.append(pickup)
	await process_frame
	for pickup in pickups:
		pickup.set("_player_inside", true)
	await process_frame

	_press_interact()
	await process_frame
	var taken := _taken_flags(pickups)
	if taken != [false, true, false]:
		failures.append("one press should take only the nearest item, got %s" % [taken])

	_press_interact()
	await process_frame
	taken = _taken_flags(pickups)
	if taken != [false, true, true]:
		failures.append("second press should take the next nearest item, got %s" % [taken])

	world.set("_starting_fight", true)
	_press_interact()
	await process_frame
	taken = _taken_flags(pickups)
	if taken != [false, true, true]:
		failures.append("no item should be taken while a fight is starting, got %s" % [taken])
	world.set("_starting_fight", false)

	room.queue_free()
	await process_frame

	if failures.is_empty():
		print("World item pickup nearest check OK.")
		quit(0)
		return
	for failure in failures:
		push_error("world_item_pickup_nearest_check: %s" % failure)
	quit(1)


func _press_interact() -> void:
	var ev := InputEventAction.new()
	ev.action = &"interact"
	ev.pressed = true
	root.push_input(ev)
	var up := InputEventAction.new()
	up.action = &"interact"
	up.pressed = false
	root.push_input(up)


func _taken_flags(pickups: Array[Area2D]) -> Array:
	var out: Array = []
	for pickup in pickups:
		out.append(bool(pickup.get("_taken")))
	return out
