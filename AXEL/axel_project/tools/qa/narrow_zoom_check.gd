extends SceneTree

const Layout := preload("res://scenes/core/background_layout.gd")
const ROOM := "res://scenes/Arc_3/3.1_Backyard.tscn"
const CORRIDOR := "res://scenes/Arc_1/1.2_Corridor.tscn"
const MEMORY := "res://scenes/Arc_2/2.2_CafeteriaMemory.tscn"
const WIDE := Vector2i(1920, 1280)
const NARROW := Vector2i(1000, 1280)
const EPS := 0.002

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_WORLD_COMBAT", "0")
	OS.set_environment("AXEL_SKIP_INTRO", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _load(path: String, size: Vector2i) -> Node:
	root.size = size
	await process_frame
	var scene := (load(path) as PackedScene).instantiate()
	root.add_child(scene)
	for _i in 6:
		await physics_frame
	return scene


func _bg_scale(scene: Node) -> float:
	var bg := scene.find_child("Background", true, false) as Sprite2D
	return bg.scale.x if bg != null else -1.0


func _contain(scene: Node, size: Vector2i) -> float:
	var bg := scene.find_child("Background", true, false) as Sprite2D
	var tex := bg.texture.get_size()
	return minf(size.x / tex.x, size.y / tex.y)


func _mike_share(scene: Node, size: Vector2i) -> float:
	var player := scene.find_child("Player", true, false) as Node2D
	var cam := scene.find_child("Camera2D", true, false) as Camera2D
	return player.scale.y * cam.zoom.y / float(size.y)


func _main() -> void:
	var wide := await _load(ROOM, WIDE)
	if absf(_bg_scale(wide) - _contain(wide, WIDE)) > EPS:
		_fail("3.1 at 1920x1280 changed scale: %f vs contain %f" % [_bg_scale(wide), _contain(wide, WIDE)])
	var wide_share := _mike_share(wide, WIDE)
	wide.queue_free()
	await process_frame

	var narrow := await _load(ROOM, NARROW)
	var narrow_share := _mike_share(narrow, NARROW)
	if absf(narrow_share - wide_share) > wide_share * 0.01:
		_fail("3.1 Mike screen share differs: wide %f narrow %f" % [wide_share, narrow_share])
	var cam := narrow.find_child("Camera2D", true, false) as Camera2D
	var player := narrow.find_child("Player", true, false) as Node2D
	if not bool(cam.get("_pan_x")):
		_fail("3.1 at 1000x1280 does not pan")
	var bg := narrow.find_child("Background", true, false) as Sprite2D
	var rect := Layout.compute_global_world_rect(bg)
	player.global_position.x = rect.position.x + rect.size.x - 10.0
	for _i in 120:
		await physics_frame
	var right_edge := cam.global_position.x + NARROW.x * 0.5
	if absf(right_edge - (rect.position.x + rect.size.x)) > 2.0:
		_fail("3.1 camera did not follow Mike to the right edge: %f vs %f" % [right_edge, rect.position.x + rect.size.x])
	narrow.queue_free()
	await process_frame

	var corridor := await _load(CORRIDOR, NARROW)
	var ccam := corridor.find_child("Camera2D", true, false)
	if not bool(ccam.call("keeps_height")):
		_fail("1.2 camera has no follow target")
	corridor.queue_free()
	await process_frame

	var memory := await _load(MEMORY, NARROW)
	if _bg_scale(memory) > _contain(memory, NARROW) + EPS:
		_fail("2.2 memory is not whole at 1000x1280: %f vs %f" % [_bg_scale(memory), _contain(memory, NARROW)])
	memory.queue_free()
	await process_frame

	if _failures.is_empty():
		print("NARROW_ZOOM_CHECK pass")
		quit(0)
	else:
		for f in _failures:
			push_error("NARROW_ZOOM_CHECK " + f)
		quit(1)
