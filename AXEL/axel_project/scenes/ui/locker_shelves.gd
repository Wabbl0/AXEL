@tool
class_name LockerShelves
extends Control

# Drag Flashlight, Key, and Nametag. ItemAnchor follows the locker picture.
# Each picture stays hidden until that item is picked up. The shovel is not here.
# After a correct board answer, the name tag picture becomes that item's icon.

const LORE_PROPS: Array[Dictionary] = [
	{
		"node": "Flashlight",
		"flag": "hasFlashlight",
		"title": "Flashlight",
		"texture": "res://exports/Drawings/Flashlight.png",
	},
	{
		"node": "Key",
		"flag": "hasKey",
		"title": "Key",
		"texture": "res://exports/Drawings/Key.png",
	},
	{
		"node": "Nametag",
		"flag": "hasName",
		"title": "Name",
		"texture": "res://exports/Drawings/Nametag.png",
	},
]

@export var background_path: NodePath = ^"../Background"
@export var anchor_path: NodePath = ^"ItemAnchor"

var _layout_sig := ""


static func lore_entries_for_flags(owned_flags: PackedStringArray) -> Array:
	var out: Array = []
	for spec in LORE_PROPS:
		if owned_flags.has(String(spec.get("flag", ""))):
			out.append((spec as Dictionary).duplicate())
	return out


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Engine.is_editor_hint():
		set_process(true)
		_sync_anchor()
		return
	_apply_visibility()
	_bind_inventory()
	_grant_stash_flag()
	if not resized.is_connected(_sync_anchor):
		resized.connect(_sync_anchor)
	get_viewport().size_changed.connect(_sync_anchor)
	call_deferred("_sync_anchor")


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	var sig := _layout_signature()
	if sig == _layout_sig and not sig.is_empty():
		return
	if _sync_anchor():
		_layout_sig = sig


func _layout_signature() -> String:
	var bg := get_node_or_null(background_path) as TextureRect
	if bg == null:
		return ""
	return "%d,%d" % [int(round(bg.size.x)), int(round(bg.size.y))]


func _anchor() -> Node2D:
	return get_node_or_null(anchor_path) as Node2D


func _sync_anchor() -> bool:
	var anchor := _anchor()
	var bg := get_node_or_null(background_path) as TextureRect
	if anchor == null or bg == null or bg.texture == null:
		return false
	var tex_size := bg.texture.get_size()
	if tex_size.x <= 1.0 or tex_size.y <= 1.0:
		return false
	var control_size := bg.size
	if control_size.x <= 1.0 or control_size.y <= 1.0:
		return false
	var cover_scale := maxf(control_size.x / tex_size.x, control_size.y / tex_size.y)
	var drawn := tex_size * cover_scale
	var offset := (control_size - drawn) * 0.5
	var sc := drawn / tex_size
	if not anchor.position.is_equal_approx(offset):
		anchor.position = offset
	if not anchor.scale.is_equal_approx(sc):
		anchor.scale = sc
	return true


func _apply_visibility() -> void:
	if Engine.is_editor_hint():
		return
	var gm := get_node_or_null("/root/GameManager")
	var anchor := _anchor()
	if anchor == null:
		return
	for spec in LORE_PROPS:
		var sprite := anchor.get_node_or_null(String(spec.get("node", ""))) as CanvasItem
		if sprite == null:
			continue
		var owned := false
		if gm != null and gm.has_method("get_flag"):
			owned = bool(gm.call("get_flag", String(spec.get("flag", ""))))
		sprite.visible = owned
		if String(spec.get("node", "")) == "Nametag":
			_apply_nametag_icon(sprite as Sprite2D)


func _apply_nametag_icon(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	if not sprite.has_meta(&"authored_texture"):
		sprite.set_meta(&"authored_texture", sprite.texture)
	var icon := _answered_item_icon()
	if icon != null:
		sprite.texture = icon
		return
	var authored: Texture2D = sprite.get_meta(&"authored_texture")
	if authored != null:
		sprite.texture = authored


func _answered_item_icon() -> Texture2D:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.has_method("get_flag"):
		return null
	if not bool(gm.call("get_flag", "hasName")):
		return null
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not run.has_method("load_item"):
		return null
	var item_id := String(run.state.board_item_id)
	if item_id.is_empty():
		return null
	var item = run.call("load_item", item_id)
	if item == null:
		return null
	return item.get("icon") as Texture2D


func _bind_inventory() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.has_signal("inventory_changed"):
		return
	if not gm.inventory_changed.is_connected(_on_inventory_changed):
		gm.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed(_items: Array) -> void:
	_apply_visibility()


func _grant_stash_flag() -> void:
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("grant_locker_stash_once"):
		run.call("grant_locker_stash_once")
