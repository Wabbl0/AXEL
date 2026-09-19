class_name LockerShelves
extends Control

@export var background_path: NodePath = ^"../Background"

var _hover: Label
var _status: Label
var _rows: Array[Control] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_collect_rows()
	_ensure_labels()
	_grant_stash_flag()
	_refresh()
	get_viewport().size_changed.connect(_remap_rows)
	call_deferred("_remap_rows")


func _collect_rows() -> void:
	_rows.clear()
	for child in get_children():
		if child.has_method("set_items") and child.has_signal("item_clicked"):
			var row := child as Control
			_rows.append(row)
			if not row.is_connected("item_clicked", _on_item_clicked):
				row.connect("item_clicked", _on_item_clicked)
			if not row.is_connected("item_hovered", _on_item_hovered):
				row.connect("item_hovered", _on_item_hovered)


func _ensure_labels() -> void:
	if _hover == null:
		_hover = Label.new()
		_hover.name = "ShelfHover"
		_hover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hover.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_hover.custom_maximum_size = Vector2(720, -1.0)
		MenuLook.apply_label(_hover, 20, MenuLook.TEXT)
		add_child(_hover)
	if _status == null:
		_status = Label.new()
		_status.name = "ShelfStatus"
		_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		MenuLook.apply_label(_status, 18, MenuLook.DIM)
		add_child(_status)


func _grant_stash_flag() -> void:
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("grant_locker_stash_once"):
		run.call("grant_locker_stash_once")


func _remap_rows() -> void:
	var bg := get_node_or_null(background_path) as TextureRect
	var bg_rect := _background_draw_rect(bg)
	for row in _rows:
		if row == null or not is_instance_valid(row):
			continue
		var uv: Rect2 = row.get("uv_rect")
		var pos := bg_rect.position + Vector2(bg_rect.size.x * uv.position.x, bg_rect.size.y * uv.position.y)
		var sz := Vector2(bg_rect.size.x * uv.size.x, bg_rect.size.y * uv.size.y)
		row.position = pos
		row.size = sz
		row.pivot_offset = sz * 0.5
	_place_labels(bg_rect)


func _place_labels(bg_rect: Rect2) -> void:
	if _hover != null:
		_hover.position = Vector2(bg_rect.position.x + bg_rect.size.x * 0.18, bg_rect.position.y + bg_rect.size.y * 0.82)
		_hover.size = Vector2(bg_rect.size.x * 0.64, 48.0)
	if _status != null:
		_status.position = Vector2(bg_rect.position.x + bg_rect.size.x * 0.18, bg_rect.position.y + bg_rect.size.y * 0.88)
		_status.size = Vector2(bg_rect.size.x * 0.64, 28.0)


func _background_draw_rect(bg: TextureRect) -> Rect2:
	if bg == null:
		return Rect2(Vector2.ZERO, size)
	var tex := bg.texture
	if tex == null:
		return Rect2(Vector2.ZERO, bg.size)
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Rect2(Vector2.ZERO, bg.size)
	var control_size := bg.size
	var cover_scale := maxf(control_size.x / tex_size.x, control_size.y / tex_size.y)
	var drawn_size := tex_size * cover_scale
	var offset := (control_size - drawn_size) * 0.5
	return Rect2(offset, drawn_size)


func _refresh() -> void:
	_collect_rows()
	var run := get_node_or_null("/root/AxelRun")
	if run == null:
		return
	var owned: Array = run.call("owned_items")
	var equipped: PackedStringArray = run.state.equipped_item_ids
	var buckets: Array = []
	for _i in _rows.size():
		buckets.append([])
	for i in owned.size():
		if buckets.is_empty():
			break
		(buckets[i % buckets.size()] as Array).append(owned[i])
	for i in _rows.size():
		var list: Array = buckets[i] if i < buckets.size() else []
		_rows[i].call("set_items", list, equipped)
	if _hover != null:
		_hover.text = ""
	if _status != null:
		var max_slots := 7
		if run.has_method("max_equip_slots"):
			max_slots = int(run.call("max_equip_slots"))
		_status.text = "Equipped  %d / %d" % [equipped.size(), max_slots]


func _on_item_hovered(item: Resource) -> void:
	if _hover == null or item == null:
		return
	_hover.text = "%s  —  %s" % [String(item.get("display_name")), String(item.get("description"))]


func _on_item_clicked(item_id: String) -> void:
	var run := get_node_or_null("/root/AxelRun")
	if run == null:
		return
	if not bool(run.call("toggle_equip", item_id)):
		if _status != null:
			_status.text = "Loadout is full."
		return
	_refresh()
