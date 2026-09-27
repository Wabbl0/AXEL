extends SceneTree

const ShelvesScript := preload("res://scenes/ui/locker_shelves.gd")
const HUB := "res://scenes/Arc_1/1.3_LockerHub.tscn"
const WINDOW := Vector2i(1920, 1280)

var _fails: PackedStringArray = PackedStringArray()


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	_check_lore_filter()
	root.size = WINDOW
	await _check_scene()
	if _fails.is_empty():
		print("Locker shelf check OK.")
		quit(0)
		return
	for msg in _fails:
		push_error("locker_shelf_check: %s" % msg)
	quit(1)


func _fail(msg: String) -> void:
	_fails.append(msg)


func _check_lore_filter() -> void:
	var entries: Array = ShelvesScript.lore_entries_for_flags(PackedStringArray([
		"hasFlashlight", "hasKey", "hasName", "hasShovel", "C1",
	]))
	if entries.size() != 3:
		_fail("expected flashlight, key, and name only, got %d" % entries.size())
		return
	if String(entries[0].get("title", "")) != "Flashlight":
		_fail("first locker picture was %s" % str(entries[0].get("title", "")))
	if String(entries[1].get("title", "")) != "Key":
		_fail("second locker picture was %s" % str(entries[1].get("title", "")))
	if String(entries[2].get("title", "")) != "Name":
		_fail("third locker picture was %s" % str(entries[2].get("title", "")))


func _check_scene() -> void:
	var packed := load(HUB) as PackedScene
	if packed == null:
		_fail("could not load locker hub")
		return
	var hub := packed.instantiate()
	root.add_child(hub)
	if not hub.is_node_ready():
		await hub.ready
	for _i in 6:
		await process_frame
	var shelves := hub.get_node_or_null("LockerShelves")
	var anchor := hub.get_node_or_null("LockerShelves/ItemAnchor")
	if shelves == null or anchor == null:
		_fail("locker pictures are missing")
		hub.queue_free()
		return
	if anchor.get_node_or_null("Shovel") != null:
		_fail("shovel picture is still on the locker")
	for node_name in ["Flashlight", "Key", "Nametag"]:
		var sprite := anchor.get_node_or_null(node_name) as Sprite2D
		if sprite == null or sprite.texture == null:
			_fail("%s picture is missing" % node_name)
			continue
		if sprite.visible:
			_fail("%s is visible before it is picked up" % node_name)
		if sprite.position == Vector2.ZERO:
			_fail("%s is still at the origin" % node_name)
		var clip := sprite.get_node_or_null("ClipPolygon") as CollisionPolygon2D
		if clip == null or clip.polygon.size() < 3:
			_fail("%s is missing its clip polygon" % node_name)
		if int(sprite.get("FEATHER_PX")) != 1:
			_fail("%s clip feather is not 1px" % node_name)
	var shader_src := FileAccess.get_file_as_string("res://scenes/ui/shelf_clip.gdshader")
	if shader_src.is_empty() or shader_src.find("feather_px") < 0:
		_fail("shelf clip shader is missing")
	if shader_src.find("leaf_fade") >= 0:
		_fail("shelf clip uses the behind-filter fade")
	var gm := root.get_node_or_null("GameManager")
	if gm == null or not gm.has_method("set_flag"):
		_fail("GameManager is missing")
	else:
		gm.call("set_flag", "hasFlashlight", true)
		gm.call("set_flag", "hasKey", false)
		gm.call("set_flag", "hasName", false)
		shelves.call("_apply_visibility")
		var light := anchor.get_node("Flashlight") as CanvasItem
		var key := anchor.get_node("Key") as CanvasItem
		var tag := anchor.get_node("Nametag") as CanvasItem
		if not light.visible:
			_fail("flashlight stayed hidden after pickup")
		if key.visible or tag.visible:
			_fail("key or nametag showed without being picked up")
		gm.call("set_flag", "hasFlashlight", false)
	hub.queue_free()
	await process_frame
