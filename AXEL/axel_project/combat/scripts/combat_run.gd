extends Control
## Player combat host. Instances the protected scaffold and hides playtest chrome.

var _hide_tries: int = 0


func _ready() -> void:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not bool(run.call("is_in_encounter")):
		return
	call_deferred("_hide_playtest_chrome")
	call_deferred("_wire_empty_sfx")


func _wire_empty_sfx() -> void:
	var root := find_child("CombatRoot", true, false)
	if root == null or not root.has_signal("sfx_requested"):
		return
	if not root.is_connected("sfx_requested", _on_sfx_requested):
		root.connect("sfx_requested", _on_sfx_requested)


func _on_sfx_requested(_cue: StringName) -> void:
	# D15: named hook only. The author is making the sounds.
	pass


func _hide_playtest_chrome() -> void:
	for node_name in ["SeedSpinBox", "PlaytestTuning", "ItemPickerPanel", "NEW_Items"]:
		var node := find_child(node_name, true, false)
		if node != null:
			node.visible = false
	_hide_tries += 1
	if _hide_tries < 20:
		call_deferred("_hide_playtest_chrome")
