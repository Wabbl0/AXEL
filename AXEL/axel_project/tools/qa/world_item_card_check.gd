extends SceneTree

const InfoCardScript := preload("res://scenes/ui/world_item_info_card.gd")
const ROOM := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const ITEM_TRES := "res://combat/data/items/C1_ash_spin_token.tres"
const WINDOW := Vector2i(1920, 1280)
const CARD_MAX_W := 320.0
const EDGE := 8.0

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	await process_frame
	await _check_room_card()
	await _check_flip_above()
	if _failures.is_empty():
		print("World item card check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("world_item_card_check: %s" % msg)
	quit(1)


func _check_room_card() -> void:
	var world := root.get_node_or_null("AxelWorld")
	var run := root.get_node_or_null("AxelRun")
	if world == null or run == null:
		_fail("autoloads missing")
		return
	world.call("reset_world")
	run.call("reset_run")
	if world.has_method("plan_floor_items"):
		world.call("plan_floor_items", int(run.state.seed))
	if change_scene_to_file(ROOM) != OK:
		_fail("could not load 1.4")
		return
	await _frames(45)
	if current_scene == null or current_scene.scene_file_path != ROOM:
		_fail("1.4 did not become the current scene")
		return
	var env := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	var host := env.get_node_or_null("WorldItemScatter") if env != null else null
	if host == null or host.get_child_count() < 1:
		_fail("1.4 has no floor item")
		return
	var pickup := host.get_child(0)
	var card := current_scene.get_node_or_null("WorldItemInfoCard")
	var prompt := current_scene.get_node_or_null("WorldItemPromptOverlay")
	if card == null:
		_fail("WorldItemInfoCard missing")
		return
	if prompt != null and prompt.has_method("show_prompt_immediate"):
		prompt.call("show_prompt_immediate", pickup.global_position)
	if pickup.has_method("_show_info_card"):
		pickup.call("_show_info_card")
	elif card.has_method("show_item"):
		card.call(
			"show_item",
			pickup.global_position,
			str(pickup.call("display_name")),
			str(pickup.call("description")),
			pickup.call("_icon_texture")
		)
	await _frames(12)
	_assert_card(card, prompt, "1.4 room")


func _check_flip_above() -> void:
	var card := InfoCardScript.new()
	card.name = "FlipCard"
	root.add_child(card)
	if not card.is_node_ready():
		await card.ready
	var fake := FakeChipHost.new()
	fake.rect = Rect2(900.0, 1180.0, 48.0, 28.0)
	root.add_child(fake)
	card.call("bind_chip_host", fake)
	var item := load(ITEM_TRES) as Resource
	var item_name := "Ash Spin Token"
	var desc := "Each paid spin adds +0.06x encounter payout scalar (cap +0.36x)"
	var icon: Texture2D = null
	if item != null:
		item_name = str(item.get("display_name"))
		desc = str(item.get("description"))
		icon = item.get("icon") as Texture2D
	card.call("show_item", Vector2(924.0, 1194.0), item_name, desc, icon)
	await _frames(12)
	_assert_card(card, fake, "flip")
	card.queue_free()
	fake.queue_free()


func _assert_card(card: Node, chip_host: Node, where: String) -> void:
	if card == null:
		_fail("%s: card missing" % where)
		return
	if card.has_method("is_card_visible") and not bool(card.call("is_card_visible")):
		_fail("%s: card not visible" % where)
	var panel := card.find_child("CardPanel", true, false) as Control
	var root_ctrl := card.find_child("CardRoot", true, false) as Control
	var desc := card.find_child("ItemDescription", true, false) as Label
	if panel == null or root_ctrl == null:
		_fail("%s: card chrome missing" % where)
		return
	if root_ctrl.size.x <= 1.0:
		root_ctrl.size = panel.size
	if panel.size.x > CARD_MAX_W or root_ctrl.size.x > CARD_MAX_W:
		_fail("%s: card width %.1f wider than %.0f" % [where, maxf(panel.size.x, root_ctrl.size.x), CARD_MAX_W])
	if desc == null:
		_fail("%s: desc label missing" % where)
		return
	if not String(desc.text).contains(" "):
		_fail("%s: desc has no spaces" % where)
	if desc.get_visible_line_count() < 1:
		_fail("%s: desc has no visible line" % where)
	var bounds := desc.get_character_bounds(0)
	if bounds.size.x <= 0.0 and bounds.size.y <= 0.0:
		_fail("%s: desc character bounds empty" % where)
	var chip := _chip_rect(chip_host, card)
	var card_rect := root_ctrl.get_global_rect()
	if card_rect.size.x <= 1.0:
		card_rect = panel.get_global_rect()
	var under := card_rect.position.y + 1.0 >= chip.end.y
	var above := card_rect.end.y <= chip.position.y + 1.0
	if not under and not above:
		_fail(
			"%s: card neither under nor above chip (card y %.1f–%.1f, chip y %.1f–%.1f)"
			% [where, card_rect.position.y, card_rect.end.y, chip.position.y, chip.end.y]
		)
	if card_rect.position.x < EDGE - 1.0 or card_rect.position.y < EDGE - 1.0:
		_fail("%s: card left the 8px window pad" % where)
	var panel_rect := panel.get_global_rect()
	for child in [desc, card.find_child("ItemName", true, false), card.find_child("ItemIcon", true, false)]:
		var ctrl := child as Control
		if ctrl == null or not ctrl.visible:
			continue
		var r := ctrl.get_global_rect()
		if r.position.x < panel_rect.position.x - 1.0 or r.end.x > panel_rect.end.x + 1.0:
			_fail("%s: %s spills the card panel on X" % [where, ctrl.name])
		if r.position.y < panel_rect.position.y - 1.0 or r.end.y > panel_rect.end.y + 1.0:
			_fail("%s: %s spills the card panel on Y" % [where, ctrl.name])


func _chip_rect(chip_host: Node, card: Node) -> Rect2:
	if is_instance_valid(chip_host) and chip_host.has_method("chip_screen_rect"):
		var rect: Variant = chip_host.call("chip_screen_rect")
		if rect is Rect2 and (rect as Rect2).size.x > 1.0:
			return rect as Rect2
	if card != null and card.has_method("_chip_rect"):
		var fallback: Variant = card.call("_chip_rect")
		if fallback is Rect2:
			return fallback as Rect2
	return Rect2()


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


class FakeChipHost extends Node:
	var rect := Rect2()

	func chip_screen_rect() -> Rect2:
		return rect
