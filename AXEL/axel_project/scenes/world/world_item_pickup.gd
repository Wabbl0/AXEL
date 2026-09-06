extends Area2D
## A combat item lying on the floor. Press [E] to take it; taking it always
## starts a fight. Spawned by AxelWorld under EnvironmentColliders so it shares
## the room's cover-fit.

## Texture-pixel sizes: the node lives under EnvironmentColliders, so these
## scale with the room the same way the walls do.
const RADIUS := 220.0
const ICON_PX := 180.0
const REASON_ITEM := "item_pickup"

var item_id: String = ""
var room_path: String = ""
var slot_index: int = -1

var _prompt: Node
var _player_inside := false
var _taken := false


func setup(new_item_id: String, new_room_path: String, index: int, prompt: Node) -> void:
	item_id = new_item_id
	room_path = new_room_path
	slot_index = index
	_prompt = prompt


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
	var icon := _icon_texture()
	if icon != null:
		var sprite := Sprite2D.new()
		sprite.name = "Icon"
		sprite.texture = icon
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var widest := maxf(float(icon.get_width()), float(icon.get_height()))
		if widest > 0.0:
			sprite.scale = Vector2.ONE * (ICON_PX / widest)
		add_child(sprite)
		return
	# Post-FX authoring rule: placeholders are black so noir turns them red.
	var blob := Polygon2D.new()
	blob.name = "Blob"
	blob.color = Color(0, 0, 0, 1)
	var h := ICON_PX * 0.5
	var w := ICON_PX * 0.38
	blob.polygon = PackedVector2Array([
		Vector2(0, -h), Vector2(w, 0), Vector2(0, h), Vector2(-w, 0),
	])
	add_child(blob)


func _icon_texture() -> Texture2D:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not run.has_method("load_item"):
		return null
	var item := run.call("load_item", item_id) as Resource
	if item == null:
		return null
	return item.get("icon") as Texture2D


func display_name() -> String:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not run.has_method("load_item"):
		return item_id
	var item := run.call("load_item", item_id) as Resource
	if item == null:
		return item_id
	return String(item.get("display_name"))


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
	if _prompt == null or not is_instance_valid(_prompt):
		return
	if _prompt.has_method("show_prompt"):
		_prompt.call("show_prompt", global_position)


func _hide_prompt() -> void:
	if _prompt == null or not is_instance_valid(_prompt):
		return
	if _prompt.has_method("hide_prompt"):
		_prompt.call("hide_prompt")


func _hide_prompt_immediate() -> void:
	if _prompt == null or not is_instance_valid(_prompt):
		return
	if _prompt.has_method("hide_prompt_immediate"):
		_prompt.call("hide_prompt_immediate")
	elif _prompt.has_method("hide_prompt"):
		_prompt.call("hide_prompt")
