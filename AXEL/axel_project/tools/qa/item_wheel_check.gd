extends SceneTree

const ROOM := "res://scenes/Arc_1/1.2_Corridor.tscn"

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var world := root.get_node_or_null("AxelWorld")
	var run := root.get_node_or_null("AxelRun")
	if world == null or run == null:
		push_error("item_wheel_check: autoloads missing")
		quit(1)
		return
	if change_scene_to_file(ROOM) != OK:
		_fail("could not load 1.2")
	else:
		for _i in 8:
			await process_frame
		var overlay := current_scene.get_node_or_null("TopDialogueOverlay")
		if overlay != null and overlay.has_method("interrupt_line"):
			overlay.call("interrupt_line")
		for _i in 4:
			await process_frame
		var wheel := world.get_node_or_null("ItemWheel")
		if wheel == null:
			_fail("ItemWheel missing")
		else:
			await _check_wheel(wheel, run)
	if _failures.is_empty():
		print("Item wheel check OK.")
		quit(0)
	else:
		for msg in _failures:
			push_error("item_wheel_check: %s" % msg)
		quit(1)


func _check_wheel(wheel: Node, run: Node) -> void:
	if int(wheel.call("band_count")) != 4:
		_fail("wheel should have 4 bands, got %s" % str(wheel.call("band_count")))
	run.call("reset_run")
	if not bool(wheel.call("open_wheel")):
		_fail("wheel did not open with no items")
		return
	await process_frame
	if bool(wheel.call("cap_is_visible")):
		_fail("cap should stay hidden until the player owns an item")
	var listed: PackedStringArray = wheel.call("listed_ids")
	if not listed.is_empty():
		_fail("empty inventory listed %s" % str(listed))
	_expect_arcs(wheel, 1, "empty inventory")
	run.state.owned_item_ids = PackedStringArray(["C1"])
	run.state.equipped_item_ids = PackedStringArray()
	await process_frame
	_expect_icon_texture_width(wheel, 64)
	_expect_arcs(wheel, 1, "commons only")
	run.state.owned_item_ids = PackedStringArray(["C1", "U1"])
	await process_frame
	_expect_arcs(wheel, 2, "uncommon owned")
	run.state.owned_item_ids = PackedStringArray(["C1", "U1", "R1"])
	await process_frame
	_expect_arcs(wheel, 3, "rare owned")
	run.state.owned_item_ids = PackedStringArray(["C1", "U1", "R1", "E1"])
	await process_frame
	_expect_arcs(wheel, 4, "epic owned")
	run.state.owned_item_ids = PackedStringArray(["C1", "R1"])
	run.state.equipped_item_ids = PackedStringArray()
	await process_frame
	_expect_arcs(wheel, 2, "rare without uncommon")
	listed = wheel.call("listed_ids")
	if not listed.has("R1"):
		_fail("rare without uncommon was not listed in %s" % str(listed))
	if listed.has("U1"):
		_fail("skipped uncommon was listed in %s" % str(listed))
	run.state.owned_item_ids = PackedStringArray(["C1", "C2", "U1", "E1", "L1"])
	run.state.equipped_item_ids = PackedStringArray(["C1", "L1"])
	await process_frame
	listed = wheel.call("listed_ids")
	for banned in ["L1"]:
		if listed.has(banned):
			_fail("legendary %s was listed" % banned)
	for needed in ["C1", "C2", "U1", "E1"]:
		if not listed.has(needed):
			_fail("missing owned item %s in %s" % [needed, str(listed)])
	if not bool(wheel.call("cap_is_visible")):
		_fail("cap should show after the first owned item")
	if str(wheel.call("cap_text")) != "2/7":
		_fail("cap text should be 2/7, got %s" % str(wheel.call("cap_text")))
	run.state.owned_item_ids = PackedStringArray(["C1", "C2", "C3", "C4"])
	run.state.equipped_item_ids = PackedStringArray(["C1"])
	await process_frame
	var before: PackedStringArray = wheel.call("visible_ids", 0)
	if before.size() != 3:
		_fail("common band should show 3 of 4, got %s" % str(before))
	wheel.call("scroll_band", 0, 1)
	var after: PackedStringArray = wheel.call("visible_ids", 0)
	if after == before:
		_fail("scrolling the common band did not change the 3 icons")
	if after.size() == 3 and not after.has(before[0]) and before.size() == 3:
		pass
	elif after.size() == 3 and after[0] == before[1]:
		pass
	else:
		_fail("scroll should move the window, before %s after %s" % [str(before), str(after)])
	wheel.call("scroll_band", 0, 3)
	var wrapped: PackedStringArray = wheel.call("visible_ids", 0)
	if wrapped != before:
		_fail("scroll should wrap, before %s wrapped %s" % [str(before), str(wrapped)])
	wheel.call("close_wheel")
	if bool(wheel.call("is_wheel_open")):
		_fail("wheel stayed open after close")


func _expect_icon_texture_width(wheel: Node, px: int) -> void:
	var root := wheel.get_node_or_null("WheelRoot")
	if root == null:
		_fail("WheelRoot missing for icon texture check")
		return
	for child in root.get_children():
		if not child is TextureButton:
			continue
		var icon := child as TextureButton
		if not icon.visible:
			continue
		var tex := icon.texture_normal
		if tex == null:
			_fail("visible icon has no texture_normal")
			return
		if tex.get_width() != px:
			_fail("visible icon texture_normal width should be %d, got %d" % [px, tex.get_width()])
		return
	_fail("no visible icon button after owning one item")


func _expect_arcs(wheel: Node, arcs: int, label: String) -> void:
	var got := int(wheel.call("shown_band_count"))
	if got != arcs:
		_fail("%s should draw %d arcs, got %d" % [label, arcs, got])
