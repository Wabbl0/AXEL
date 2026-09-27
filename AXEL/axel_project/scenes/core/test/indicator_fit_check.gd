extends SceneTree

const Fit := preload("res://scenes/core/indicator_fit.gd")

const MEMORY_EPS := 0.0001
const ITEM_EPS := 0.001
const MEMORY_RATIO_EPS := 0.01
const ITEM_RATIO_EPS := 0.25

const ROOMS := [
	{"name": "1.1", "player": 0.079, "baseline": 0.33494318, "memory": 0.596, "item": 75.5},
	{"name": "1.2", "player": 0.198, "baseline": 0.546, "memory": 1.495, "item": 116.0},
	{"name": "1.4", "player": 0.198, "baseline": 0.352, "memory": 1.495, "item": 180.0},
	{"name": "2.1", "player": 0.298, "baseline": 1920.0 / 3508.0, "memory": 2.25, "item": 174.2},
	{"name": "2.3", "player": 0.331, "baseline": 1920.0 / 3508.0, "memory": 2.499, "item": 193.5},
	{"name": "2.4", "player": 0.198, "baseline": 1920.0 / 7016.0, "memory": 1.495, "item": 231.5},
	{"name": "3.1", "player": 0.277, "baseline": 1920.0 / 3508.0, "memory": 2.091, "item": 162.0},
	{"name": "4.1", "player": 0.257, "baseline": 1920.0 / 3508.0, "memory": 1.940, "item": 150.3},
	{"name": "5.1", "player": 0.298, "baseline": 1920.0 / 3508.0, "memory": 2.25, "item": 174.2},
]

const LIVE_ROOMS := [
	{
		"path": "res://scenes/Arc_2/2.1_Cafeteria.tscn",
		"memory": 2.25,
		"item": 174.2,
		"glow": true,
	},
	{
		"path": "res://scenes/Arc_1/1.4_BasementDoor.tscn",
		"memory": 0.0,
		"item": 180.0,
		"glow": false,
	},
	{
		"path": "res://scenes/Arc_3/3.1_Backyard.tscn",
		"memory": 2.091,
		"item": 162.0,
		"glow": true,
	},
	{
		"path": "res://scenes/Arc_4/4.1_TeachersLounge.tscn",
		"memory": 1.940,
		"item": 150.3,
		"glow": true,
	},
	{
		"path": "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn",
		"memory": 0.0,
		"item": 231.5,
		"glow": false,
	},
]


func _init() -> void:
	call_deferred("_main")


func _fail(msg: String) -> void:
	push_error("IndicatorFit FAIL: %s" % msg)
	quit(1)


func _main() -> void:
	var memory_21: float = Fit.memory_from_player(Fit.MEMORY_REF_PLAYER)
	if absf(memory_21 - Fit.MEMORY_REF_SCALE) > MEMORY_EPS:
		_fail("2.1 glow=%.4f expected %.4f" % [memory_21, Fit.MEMORY_REF_SCALE])
		return
	var item_14: float = Fit.item_marker_px(Fit.ITEM_REF_PLAYER, Fit.ITEM_REF_BASELINE)
	if absf(item_14 - Fit.ITEM_REF_MARKER_PX) > ITEM_EPS:
		_fail("1.4 hand=%.4f expected %.4f" % [item_14, Fit.ITEM_REF_MARKER_PX])
		return
	if absf(Fit.memory_from_player(0.0)) > MEMORY_EPS or absf(Fit.item_marker_px(0.0, 1.0)) > ITEM_EPS:
		_fail("zero scale should return 0")
		return
	if absf(Fit.item_marker_px(0.198, 0.0)) > ITEM_EPS:
		_fail("zero baseline should return 0")
		return

	var memory_ratio := Fit.MEMORY_REF_SCALE / Fit.MEMORY_REF_PLAYER
	var item_k := Fit.ITEM_REF_MARKER_PX * (Fit.ITEM_REF_BASELINE / Fit.ITEM_REF_PLAYER)
	for room in ROOMS:
		var player_scale: float = room["player"]
		var baseline: float = room["baseline"]
		var memory: float = Fit.memory_from_player(player_scale)
		var item: float = Fit.item_marker_px(player_scale, baseline)
		if absf(memory - float(room["memory"])) > MEMORY_EPS:
			_fail("%s glow=%.4f expected %.4f" % [room["name"], memory, float(room["memory"])])
			return
		if absf(item - float(room["item"])) > ITEM_EPS:
			_fail("%s hand=%.4f expected %.4f" % [room["name"], item, float(room["item"])])
			return
		if absf(memory / player_scale - memory_ratio) > MEMORY_RATIO_EPS:
			_fail("%s glow/Mike drifted" % room["name"])
			return
		if absf(item * baseline / player_scale - item_k) > ITEM_RATIO_EPS:
			_fail("%s hand/Mike drifted" % room["name"])
			return

	root.size = Vector2i(1920, 1280)
	if not await _check_live_rooms():
		return
	print("IndicatorFit check OK (2.1 glow=%.3f, 1.4 hand=%.1f, rooms=%d)." % [
		memory_21, item_14, ROOMS.size()
	])
	quit(0)


func _check_live_rooms() -> bool:
	for room in LIVE_ROOMS:
		var path: String = room["path"]
		var packed := load(path) as PackedScene
		if packed == null:
			_fail("could not load %s" % path)
			return false
		var node := packed.instantiate()
		root.add_child(node)
		if not node.is_node_ready():
			await node.ready
		await process_frame
		var hand := float(node.call("floor_item_marker_px"))
		if absf(hand - float(room["item"])) > ITEM_EPS:
			_fail("%s live hand=%.4f expected %.4f" % [path, hand, float(room["item"])])
			return false
		var glow := node.get_node_or_null("PlayerLayer/MemoryIndicator")
		if bool(room["glow"]):
			if glow == null:
				_fail("%s missing memory glow" % path)
				return false
			var scale := float(glow.get("indicator_scale"))
			if absf(scale - float(room["memory"])) > MEMORY_EPS:
				_fail("%s live glow=%.4f expected %.4f" % [path, scale, float(room["memory"])])
				return false
			var player := node.get_node_or_null("PlayerLayer/Player") as Node2D
			if player == null or not player.has_meta("axel_authored_scale"):
				_fail("%s missing authored Mike scale" % path)
				return false
			var authored: Vector2 = player.get_meta("axel_authored_scale")
			if absf(player.scale.x) < 0.0001 or absf(authored.x) < 0.0001:
				_fail("%s Mike scale is zero" % path)
				return false
			var rel := absf(glow.scale.x) / absf(player.scale.x)
			var want := float(room["memory"]) / authored.x
			if absf(rel - want) > MEMORY_RATIO_EPS:
				_fail("%s glow/Mike=%.4f expected %.4f" % [path, rel, want])
				return false
		elif glow != null:
			_fail("%s should not have a memory glow" % path)
			return false
		node.queue_free()
		await process_frame
	return true
