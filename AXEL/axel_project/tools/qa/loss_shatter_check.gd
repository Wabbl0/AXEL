extends SceneTree

const SHATTER := preload("res://combat/scripts/loss_shatter.gd")
const FEEL := preload("res://combat/scripts/combat_feel.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	_check_pattern()
	await _check_break()
	_check_order()
	if _failures.is_empty():
		print("Loss shatter check OK.")
		quit(0)
	else:
		for f in _failures:
			push_error("loss_shatter_check: %s" % f)
		quit(1)


func _check_pattern() -> void:
	var rect := Rect2(0, 0, 200, 120)
	var polys := SHATTER.shard_polygons(rect, Vector2(110, 55), 8, 4242)
	if polys.size() < 8 or polys.size() > 20:
		_failures.append("shard count was %d" % polys.size())
	var area := 0.0
	for poly in polys:
		area += SHATTER.polygon_area(poly)
	if absf(area - rect.get_area()) > rect.get_area() * 0.01:
		_failures.append("shard area %.1f did not match %.1f" % [area, rect.get_area()])
	var again := SHATTER.shard_polygons(rect, Vector2(110, 55), 8, 4242)
	if again != polys:
		_failures.append("same seed gave different shards")


func _check_break() -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var host := Control.new()
	host.name = "LossShards"
	layer.add_child(host)
	var image := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.1, 0.1, 1.0))
	var art := TextureRect.new()
	art.texture = ImageTexture.create_from_image(image)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.position = Vector2(800, 500)
	art.size = Vector2(200, 120)
	layer.add_child(art)
	var shatter = SHATTER.new()
	root.add_child(shatter)
	shatter.set_view(Vector2(1920, 1280))
	await shatter.break_piece(art, host, 99, 6, 0.1, 1.0)
	if art.visible:
		_failures.append("art stayed visible after the break")
	var shards := 0
	for child in host.get_children():
		if child is Polygon2D:
			shards += 1
	if shards != 12:
		_failures.append("expected 12 shards, saw %d" % shards)
	await create_timer(3.0).timeout
	await process_frame
	if shatter.live_count() != 0:
		_failures.append("%d shards still alive after 3s" % shatter.live_count())
	var left := 0
	for child in host.get_children():
		if child is Polygon2D or child is Line2D:
			left += 1
	if left != 0:
		_failures.append("%d shard or crack nodes left in the host" % left)
	shatter.queue_free()
	layer.queue_free()


func _check_order() -> void:
	var scene := Control.new()
	scene.name = "FakeCombat"
	root.add_child(scene)
	current_scene = scene
	for piece_name in [
		"NEW_Settings", "NEW_Execute", "NEW_Bets", "NEW_History",
		"NEW_Items", "NEW_Multiplier", "NEW_Goal", "NEW_Grid",
	]:
		var piece := Control.new()
		piece.name = piece_name
		piece.size = Vector2(100, 100)
		scene.add_child(piece)
	var combat := Node2D.new()
	scene.add_child(combat)
	var grid := GridContainer.new()
	grid.name = "GridUI"
	grid.columns = 5
	combat.add_child(grid)
	for i in 25:
		var slot := Control.new()
		slot.name = "Slot%d" % i
		grid.add_child(slot)
	var feel = FEEL.new()
	combat.add_child(feel)
	feel.setup(combat, grid)
	var beats: Array = feel._loss_beats()
	var got: Array[String] = []
	for beat in beats:
		if beat["kind"] == &"symbols":
			got.append("symbols")
			var columns: Array = beat["columns"]
			if columns.size() != 5 or str((columns[0][0] as Node).name) != "Slot20" or str((columns[4][4] as Node).name) != "Slot4":
				_failures.append("symbol columns were not left to right, bottom row first")
		else:
			var names: Array[String] = []
			for node in beat["nodes"]:
				names.append(str((node as Node).name))
			got.append("+".join(names))
	var want: Array[String] = [
		"symbols", "NEW_Grid", "NEW_Goal+NEW_Multiplier",
		"NEW_Items+NEW_History", "NEW_Bets+NEW_Execute", "NEW_Settings",
	]
	if got != want:
		_failures.append("break order was %s" % [got])
	scene.queue_free()
