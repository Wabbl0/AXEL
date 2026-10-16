extends Area2D

const ItemMarkerScene := preload("res://scenes/world/ItemMarker.tscn")

const RADIUS := 220.0
const MARKER_PX := 180.0
const REASON_ITEM := "item_pickup"
const MARKER_NODE := "ItemMarker"
const TAP_GROUP := &"touch_tap_target"
const TAP_HIT_RADIUS := 70.0

var item_id: String = ""
var room_path: String = ""
var slot_index: int = -1

var _info_card: Node
var _player_inside := false
var _taken := false
var _marker: Node2D = null
var _wheel_was_open := false

static var _card_pickup_id := 0


func setup(
	new_item_id: String, new_room_path: String, index: int, info_card: Node = null
) -> void:
	item_id = new_item_id
	room_path = new_room_path
	slot_index = index
	_info_card = info_card


func floor_marker() -> Node2D:
	return _marker if is_instance_valid(_marker) else null


func _ready() -> void:
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	_build_visual()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_process_unhandled_input(true)


func _build_visual() -> void:
	var marker := ItemMarkerScene.instantiate() as Node2D
	if marker == null:
		push_warning("WorldItemPickup: could not instantiate the item marker")
		return
	marker.name = MARKER_NODE
	marker.set("marker_px", _room_marker_px())
	if marker.has_method("bind_pickup"):
		marker.call("bind_pickup", self)
	var layer := _player_layer()
	if layer != null:
		layer.add_child(marker)
		layer.move_child(marker, 0)
	else:
		add_child(marker)
	_marker = marker
	_reveal_rarity(false)


func _reveal_rarity(show: bool) -> void:
	if not is_instance_valid(_marker) or not _marker.has_method("set_rarity_glyph"):
		return
	_marker.call("set_rarity_glyph", ItemDef.rarity_glyph(_item_def()) if show else "")


func _room_marker_px() -> float:
	var scene := get_tree().current_scene if get_tree() != null else null
	if scene != null and scene.has_method("floor_item_marker_px"):
		var px := float(scene.call("floor_item_marker_px"))
		if px > 0.0:
			return px
	return MARKER_PX


func _player_layer() -> Node:
	var scene := get_tree().current_scene if get_tree() != null else null
	if scene == null:
		return null
	var layer := scene.get_node_or_null("PlayerLayer")
	if layer == null:
		layer = scene.find_child("PlayerLayer", true, false)
	return layer


func _exit_tree() -> void:
	if is_instance_valid(_marker):
		_marker.queue_free()
	_marker = null


func _item_def() -> Resource:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not run.has_method("load_item"):
		return null
	return run.call("load_item", item_id) as Resource


func _icon_texture() -> Texture2D:
	var item := _item_def()
	if item == null:
		return null
	return item.get("icon") as Texture2D


func display_name() -> String:
	var item := _item_def()
	if item == null:
		return item_id
	return ItemDef.rarity_name(item)


func description() -> String:
	var item := _item_def()
	if item == null:
		return ""
	return String(item.get("description"))


func is_player_inside() -> bool:
	return _player_inside and not _taken


func _process(_delta: float) -> void:
	var open := _wheel_is_open()
	var nearest := is_player_inside() and _nearest_candidate() == self and not _fight_starting()
	if nearest and not open and (_wheel_was_open or _card_pickup_id != get_instance_id()):
		_show_info_card()
	_wheel_was_open = open


func _nearest_candidate() -> Node:
	var parent := get_parent()
	if parent == null:
		return self
	var player := _find_player()
	if player == null:
		return self
	var from := player.get_global_transform_with_canvas().origin
	var best: Node = null
	var best_dist := INF
	for child in parent.get_children():
		if not child is Node2D or not child.has_method("is_player_inside"):
			continue
		if not bool(child.call("is_player_inside")):
			continue
		var dist := from.distance_squared_to((child as Node2D).get_global_transform_with_canvas().origin)
		if dist < best_dist:
			best_dist = dist
			best = child
	return best if best != null else self


func _find_player() -> Node2D:
	var scene := get_tree().current_scene if get_tree() != null else null
	if scene == null:
		return null
	var direct := scene.get_node_or_null("PlayerLayer/Player") as Node2D
	if direct != null:
		return direct
	return scene.find_child("Player", true, false) as Node2D


func _fight_starting() -> bool:
	var world := get_node_or_null("/root/AxelWorld")
	return world != null and world.has_method("is_fight_starting") and bool(world.call("is_fight_starting"))


func _wheel_is_open() -> bool:
	var wheel := get_node_or_null("/root/AxelWorld/ItemWheel")
	if wheel == null or not wheel.has_method("is_wheel_open"):
		return false
	return bool(wheel.call("is_wheel_open"))


func _on_body_entered(body: Node) -> void:
	if _taken or not _is_player(body):
		return
	_player_inside = true
	add_to_group(TAP_GROUP)
	_reveal_rarity(true)


func _on_body_exited(body: Node) -> void:
	if not _is_player(body):
		return
	_player_inside = false
	remove_from_group(TAP_GROUP)
	if _card_pickup_id == get_instance_id():
		_card_pickup_id = 0
		_hide_info_card()


static func _is_player(body: Node) -> bool:
	return body != null and body.name == "Player"


func _unhandled_input(event: InputEvent) -> void:
	if _taken or not _player_inside:
		return
	if event.is_action_pressed("reroll"):
		_try_reroll()
		return
	if not event.is_action_pressed("interact"):
		return
	if _fight_starting() or _nearest_candidate() != self:
		return
	var scene := get_tree().current_scene if get_tree() != null else null
	var dialogue := scene.get_node_or_null("TopDialogueOverlay") if scene != null else null
	if InteractZoneGate.blocks_interact(dialogue):
		return
	get_viewport().set_input_as_handled()
	_take()


func touch_tap_hit(screen_pos: Vector2) -> bool:
	if _taken or not _player_inside or not is_inside_tree():
		return false
	var anchor: CanvasItem = _marker if is_instance_valid(_marker) else self
	var center := anchor.get_global_transform_with_canvas().origin
	var radius := TAP_HIT_RADIUS * UiViewportScale.factor(self)
	if is_instance_valid(_marker):
		var px := float(_marker.get("marker_px"))
		radius = maxf(radius, px * 0.5 * get_global_transform_with_canvas().get_scale().x)
	return screen_pos.distance_to(center) <= radius


func _take() -> void:
	if _taken:
		return
	_taken = true
	remove_from_group(TAP_GROUP)
	if _card_pickup_id == get_instance_id():
		_card_pickup_id = 0
	_hide_info_card_immediate()
	visible = false
	monitoring = false
	if is_instance_valid(_marker):
		_marker.visible = false
	var world := get_node_or_null("/root/AxelWorld")
	if world == null:
		return
	var tutorial := get_node_or_null("/root/AxelTutorial")
	if tutorial != null and tutorial.has_method("complete"):
		tutorial.call("complete", "items_hand")
	world.call("take_item", room_path, slot_index)
	world.call("start_fight_here", REASON_ITEM)


func _show_info_card() -> void:
	if _wheel_is_open():
		return
	if _info_card == null or not is_instance_valid(_info_card):
		return
	if _info_card.has_method("show_item"):
		_card_pickup_id = get_instance_id()
		_info_card.call(
			"show_item",
			global_position,
			display_name(),
			_card_description(),
			_icon_texture(),
			_marker
		)
		var tutorial := get_node_or_null("/root/AxelTutorial")
		if tutorial != null and tutorial.has_method("request"):
			tutorial.call("request", "items_hand")
			if _dread_pct() > 0:
				tutorial.call("request", "items_dread")
			if not _hex_text().is_empty():
				tutorial.call("request", "items_hex")


func _dread_pct() -> int:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not run.has_method("dread_for_item"):
		return 0
	return int(round(float(run.call("dread_for_item", item_id)) * 100.0))


func _hide_info_card() -> void:
	if _info_card == null or not is_instance_valid(_info_card):
		return
	if _info_card.has_method("hide_card"):
		_info_card.call("hide_card")


func _hide_info_card_immediate() -> void:
	if _info_card == null or not is_instance_valid(_info_card):
		return
	if _info_card.has_method("hide_card_immediate"):
		_info_card.call("hide_card_immediate")
	elif _info_card.has_method("hide_card"):
		_info_card.call("hide_card")


func _hex_text() -> String:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not run.has_method("hex_text"):
		return ""
	return String(run.call("hex_text", item_id))


func _card_description() -> String:
	var text := description()
	var hex := _hex_text()
	if not hex.is_empty():
		text = "%s  %s." % [text, hex]
	var pct := _dread_pct()
	if pct <= 0:
		return text
	var run := get_node_or_null("/root/AxelRun")
	text = "%s  +%d%% Dread" % [text, pct]
	var tickets := int(run.call("ticket_count")) if run.has_method("ticket_count") else 0
	if tickets > 0:
		text = "%s  %s Reroll (%d)" % [text, _reroll_key_text(), tickets]
	return text


func _reroll_key_text() -> String:
	for ev in InputMap.action_get_events("reroll"):
		if ev is InputEventKey:
			var key := ev as InputEventKey
			var code := key.physical_keycode if int(key.physical_keycode) != 0 else key.keycode
			return "[%s]" % OS.get_keycode_string(code)
	return "[F]"


func _try_reroll() -> void:
	if _fight_starting() or _nearest_candidate() != self:
		return
	var world := get_node_or_null("/root/AxelWorld")
	if world == null or not world.has_method("reroll_item"):
		return
	get_viewport().set_input_as_handled()
	if not bool(world.call("reroll_item", room_path, slot_index)):
		return
	var entries: Array = world.call("room_item_entries", room_path) if world.has_method("room_item_entries") else []
	if slot_index >= 0 and slot_index < entries.size():
		item_id = String((entries[slot_index] as Dictionary).get("id", item_id))
	_reveal_rarity(true)
	_card_pickup_id = 0
	_show_info_card()
