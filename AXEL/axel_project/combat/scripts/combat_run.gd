extends Control

const EmptyItemDvdScript := preload("res://combat/scripts/empty_item_dvd.gd")
const PlayerItemPanelScript := preload("res://combat/scripts/player_item_panel.gd")
const ITEM_BOX_LEFT_INSET_PX := 12.0

var _hide_tries: int = 0
var _attach_tries: int = 0
var _player_box: Control


func _ready() -> void:
	call_deferred("_hide_playtest_chrome")
	call_deferred("_attach_player_item_box")
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not bool(run.call("is_in_encounter")):
		return
	call_deferred("_wire_empty_sfx")
	call_deferred("_open_combat_wipe")


func _open_combat_wipe() -> void:
	if not is_instance_valid(AxelEventFx):
		return
	var tree := get_tree()
	if tree == null:
		return
	await tree.process_frame
	if not is_instance_valid(AxelEventFx):
		return
	AxelEventFx.clear_combat_wipe()


func _wire_empty_sfx() -> void:
	var root := find_child("CombatRoot", true, false)
	if root == null or not root.has_signal("sfx_requested"):
		return
	if not root.is_connected("sfx_requested", _on_sfx_requested):
		root.connect("sfx_requested", _on_sfx_requested)


func _on_sfx_requested(_cue: StringName) -> void:

	pass


func _hide_playtest_chrome() -> void:
	for node_name in ["SeedSpinBox", "PlaytestTuning", "ItemPickerPanel"]:
		var node := find_child(node_name, true, false)
		if node != null:
			node.visible = false
	var items := find_child("NEW_Items", true, false) as CanvasItem
	if items != null:
		items.visible = true
	var focus := get_viewport().gui_get_focus_owner() as Control
	if focus != null and not focus.is_visible_in_tree():
		focus.release_focus()
	_hide_tries += 1
	if _hide_tries < 20:
		call_deferred("_hide_playtest_chrome")


func _is_empty_egg_mode() -> bool:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not bool(run.call("is_in_encounter")):
		return true
	return run.has_method("is_tutorial_encounter") and bool(run.call("is_tutorial_encounter"))


func _items_host() -> Control:
	var test := get_node_or_null("CombatTest")
	if test != null and test.has_method("get_items_widget_host"):
		var host := test.call("get_items_widget_host") as Control
		if host != null:
			return host
	return find_child("Host_items", true, false) as Control


func _attach_player_item_box() -> void:
	var host := _items_host()
	var piece := find_child("NEW_Items", true, false)
	if host == null or piece == null:
		_attach_tries += 1
		if _attach_tries < 24:
			call_deferred("_attach_player_item_box")
		return
	var want_egg := _is_empty_egg_mode()
	if _player_box != null and is_instance_valid(_player_box):
		var is_egg: bool = _player_box.get_script() == EmptyItemDvdScript
		if is_egg == want_egg:
			if not want_egg:
				_refresh_equipped_list()
			_attach_tries += 1
			if _attach_tries < 24:
				call_deferred("_attach_player_item_box")
			return
		_player_box.queue_free()
		_player_box = null
	if want_egg:
		_player_box = EmptyItemDvdScript.new() as Control
	else:
		_player_box = PlayerItemPanelScript.new() as Control
	host.add_child(_player_box)
	if piece.has_method("attach"):
		piece.call("attach", _player_box, host)
	if _player_box is Control:
		(_player_box as Control).offset_left = ITEM_BOX_LEFT_INSET_PX
	if not want_egg:
		_refresh_equipped_list()
	_attach_tries += 1
	if _attach_tries < 24:
		call_deferred("_attach_player_item_box")


func _refresh_equipped_list() -> void:
	if _player_box == null or not _player_box.has_method("set_equipped_items"):
		return
	var root := find_child("CombatRoot", true, false)
	if root == null:
		return
	var inv = root.get("inventory")
	if inv == null:
		return
	var items: Array = []
	if inv.get("items") != null:
		items = inv.items
	_player_box.call("set_equipped_items", items)
