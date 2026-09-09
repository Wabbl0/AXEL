extends Area2D
## A combat item lying on the floor. Every one of these shows the same pentacle
## marker; walking near it reads out the item's real name, description and icon
## on the info card. Press [E] to take it; taking it always starts a fight.
## Spawned by AxelWorld under EnvironmentColliders so it shares the room's
## cover-fit.

const PentacleMarkerScene := preload("res://scenes/world/PentacleMarker.tscn")

## Texture-pixel sizes: the node lives under EnvironmentColliders, so these
## scale with the room the same way the walls do.
const RADIUS := 220.0
const MARKER_PX := 180.0
const REASON_ITEM := "item_pickup"

var item_id: String = ""
var room_path: String = ""
var slot_index: int = -1

var _prompt: Node
var _info_card: Node
var _player_inside := false
var _taken := false


func setup(
	new_item_id: String, new_room_path: String, index: int, prompt: Node, info_card: Node = null
) -> void:
	item_id = new_item_id
	room_path = new_room_path
	slot_index = index
	_prompt = prompt
	_info_card = info_card


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


## One shared marker for every item. What is lying here is deliberately not
## readable from across the room — you have to walk over and read the card.
func _build_visual() -> void:
	var marker := PentacleMarkerScene.instantiate() as Node2D
	if marker == null:
		push_warning("WorldItemPickup: could not instantiate the pentacle marker")
		return
	marker.name = "Pentacle"
	marker.set("marker_px", MARKER_PX)
	add_child(marker)


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
	var name_text := String(item.get("display_name"))
	return name_text if not name_text.is_empty() else item_id


func description() -> String:
	var item := _item_def()
	if item == null:
		return ""
	return String(item.get("description"))


func _on_body_entered(body: Node) -> void:
	if _taken or not _is_player(body):
		return
	_player_inside = true
	_show_prompt()


func _on_body_exited(body: Node) -> void:
	if not _is_player(body):
		return
	_player_inside = false
	_hide_prompt()


static func _is_player(body: Node) -> bool:
	return body != null and body.name == "Player"


func _unhandled_input(event: InputEvent) -> void:
	if _taken or not _player_inside:
		return
	if not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	_take()


func _take() -> void:
	if _taken:
		return
	_taken = true
	_hide_prompt_immediate()
	visible = false
	monitoring = false
	var world := get_node_or_null("/root/AxelWorld")
	if world == null:
		return
	world.call("take_item", room_path, slot_index)
	world.call("start_fight_here", REASON_ITEM)


func _show_prompt() -> void:
	_show_info_card()
	if _prompt == null or not is_instance_valid(_prompt):
		return
	if _prompt.has_method("show_prompt"):
		_prompt.call("show_prompt", global_position)


func _hide_prompt() -> void:
	_hide_info_card()
	if _prompt == null or not is_instance_valid(_prompt):
		return
	if _prompt.has_method("hide_prompt"):
		_prompt.call("hide_prompt")


func _hide_prompt_immediate() -> void:
	_hide_info_card()
	if _prompt == null or not is_instance_valid(_prompt):
		return
	if _prompt.has_method("hide_prompt_immediate"):
		_prompt.call("hide_prompt_immediate")
	elif _prompt.has_method("hide_prompt"):
		_prompt.call("hide_prompt")


func _show_info_card() -> void:
	if _info_card == null or not is_instance_valid(_info_card):
		return
	if _info_card.has_method("show_item"):
		_info_card.call("show_item", global_position, display_name(), description(), _icon_texture())


func _hide_info_card() -> void:
	if _info_card == null or not is_instance_valid(_info_card):
		return
	if _info_card.has_method("hide_card"):
		_info_card.call("hide_card")
