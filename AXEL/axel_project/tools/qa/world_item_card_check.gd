extends SceneTree

const InfoCardScript := preload("res://scenes/ui/world_item_info_card.gd")
const ROOM := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const ITEM_TRES := "res://combat/data/items/C1_ash_spin_token.tres"
const WINDOW := Vector2i(1920, 1280)
const EDGE := 8.0
const ITEMS_INDICATOR_GAP := 10.0

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
	await _check_flips_above()
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
	if current_scene.get_node_or_null("WorldItemPromptOverlay") != null:
		_fail("1.4 room: item [E] chip should not spawn")
	var env := current_scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
	var host := env.get_node_or_null("WorldItemScatter") if env != null else null
	if host == null or host.get_child_count() < 1:
		_fail("1.4 has no floor item")
		return
	var pickup := host.get_child(0)
	var card := current_scene.get_node_or_null("WorldItemInfoCard")
	if card == null:
		_fail("WorldItemInfoCard missing")
		return
	if pickup.has_method("_show_info_card"):
		pickup.call("_show_info_card")
	await _wait_settled(card, "1.4 room")
	var marker: Node = pickup.call("floor_marker") if pickup.has_method("floor_marker") else null
	var items_indicator := Rect2()
	if marker != null and marker.has_method("ink_screen_rect"):
		var got: Variant = marker.call("ink_screen_rect")
		if got is Rect2:
			items_indicator = got
	var room_panel := card.find_child("CardPanel", true, false) as Control
	var room_above := room_panel != null and items_indicator.end.y + ITEMS_INDICATOR_GAP + room_panel.size.y > float(WINDOW.y) - EDGE
	_assert_card(card, items_indicator, "1.4 room", room_above)


func _check_flips_above() -> void:
	var card := InfoCardScript.new()
	card.name = "BelowCard"
	root.add_child(card)
	if not card.is_node_ready():
		await card.ready
	var fake := FakeItemsIndicator.new()
	fake.rect = Rect2(900.0, 1180.0, 48.0, 28.0)
	root.add_child(fake)
	var item := load(ITEM_TRES) as Resource
	var item_name := "Ash Spin Token"
	var desc := "Each paid spin adds +0.06x encounter payout scalar (cap +0.36x)"
	var icon: Texture2D = null
	if item != null:
		item_name = ItemDef.rarity_name(item)
		desc = str(item.get("description"))
		icon = item.get("icon") as Texture2D
	card.call("show_item", Vector2(924.0, 1194.0), item_name, desc, icon, fake)
	await _wait_settled(card, "above")
	_assert_card(card, fake.rect, "above", true)
	card.queue_free()
	fake.queue_free()


func _assert_card(card: Node, items_indicator: Rect2, where: String, above: bool = false) -> void:
	if card == null:
		_fail("%s: card missing" % where)
		return
	if card.has_method("is_card_visible") and not bool(card.call("is_card_visible")):
		_fail("%s: card not visible" % where)
	if card.has_method("is_crt_settled") and not bool(card.call("is_crt_settled")):
		_fail("%s: card CRT did not settle" % where)
	var panel := card.find_child("CardPanel", true, false) as Control
	var root_ctrl := card.find_child("CardRoot", true, false) as Control
	var desc := card.find_child("ItemDescription", true, false) as RichTextLabel
	var title := card.find_child("ItemName", true, false) as Label
	var key := card.find_child("ItemKey", true, false) as Label
	var icon := card.find_child("ItemIcon", true, false) as Control
	if panel == null or root_ctrl == null:
		_fail("%s: card chrome missing" % where)
		return
	if card.find_child("PowerBeam", true, false) == null or card.find_child("Bloom", true, false) == null:
		_fail("%s: CRT beam or bloom missing" % where)
	if root_ctrl.size.x <= 1.0:
		root_ctrl.size = panel.size
	if title == null or desc == null or key == null:
		_fail("%s: title, description, or [E] missing" % where)
		return
	if title.autowrap_mode != TextServer.AUTOWRAP_OFF:
		_fail("%s: title should stay on one row" % where)
	if title.get_visible_line_count() != 1:
		_fail("%s: title lines %d should be 1" % [where, title.get_visible_line_count()])
	var title_bounds := title.get_character_bounds(0)
	if title_bounds.size.x <= 0.0 and title_bounds.size.y <= 0.0:
		_fail("%s: title character bounds empty" % where)
	if key.text != "[E]":
		_fail("%s: key text %s" % [where, key.text])
	if key.get_theme_font_size("font_size") != desc.get_theme_font_size("normal_font_size"):
		_fail(
			"%s: [E] font %d should match description %d"
			% [where, key.get_theme_font_size("font_size"), desc.get_theme_font_size("normal_font_size")]
		)
	if not desc.get_parsed_text().contains(" "):
		_fail("%s: desc has no spaces" % where)
	if desc.get_line_count() < 1 or desc.size.y < 4.0:
		_fail("%s: desc has no visible line" % where)
	var title_w := title.get_combined_minimum_size().x
	var wrap_w := desc.custom_maximum_size.x
	if wrap_w + 4.0 < title_w:
		_fail("%s: description width %.1f should be at least the title %.1f" % [where, wrap_w, title_w])
	var text_w := maxf(title_w, wrap_w)
	var icon_w := 0.0
	var sep := 0.0
	if icon != null and icon.visible:
		icon_w = icon.get_combined_minimum_size().x
		sep = 12.0
	var chrome := 0.0
	var style := panel.get_theme_stylebox("panel")
	if style != null:
		chrome = style.get_minimum_size().x
	var expected := text_w + icon_w + sep + chrome
	if absf(panel.size.x - expected) > 8.0:
		_fail("%s: panel width %.1f should match the title row %.1f" % [where, panel.size.x, expected])
	if items_indicator.size.y > 1.0:
		var card_rect := root_ctrl.get_global_rect()
		if card_rect.size.x <= 1.0:
			card_rect = panel.get_global_rect()
		if above:
			var gap_up := items_indicator.position.y - card_rect.end.y
			if absf(gap_up - ITEMS_INDICATOR_GAP) > 3.0:
				_fail("%s: card gap %.1f should be %.0f above the items_indicator" % [where, gap_up, ITEMS_INDICATOR_GAP])
			if card_rect.end.y > float(WINDOW.y) - EDGE + 1.0:
				_fail("%s: card runs off the bottom of the window" % where)
		else:
			var gap := card_rect.position.y - items_indicator.end.y
			if absf(gap - ITEMS_INDICATOR_GAP) > 3.0:
				_fail("%s: card gap %.1f should be %.0f under the items_indicator" % [where, gap, ITEMS_INDICATOR_GAP])
			if card_rect.position.y + 1.0 < items_indicator.end.y:
				_fail("%s: card must stay under the items_indicator" % where)
	if root_ctrl.position.x < EDGE - 1.0:
		_fail("%s: card left the 8px window pad" % where)
	var panel_rect := panel.get_global_rect()
	for child in [desc, title, icon, key]:
		var ctrl := child as Control
		if ctrl == null or not ctrl.visible:
			continue
		var r := ctrl.get_global_rect()
		if r.position.x < panel_rect.position.x - 1.0 or r.end.x > panel_rect.end.x + 1.0:
			_fail("%s: %s spills the card panel on X" % [where, ctrl.name])
		if r.position.y < panel_rect.position.y - 1.0 or r.end.y > panel_rect.end.y + 1.0:
			_fail("%s: %s spills the card panel on Y" % [where, ctrl.name])
	var key_rect := key.get_global_rect()
	var desc_rect := desc.get_global_rect()
	if key_rect.position.y < desc_rect.end.y - 2.0:
		_fail("%s: [E] should sit under the description" % where)
	if key_rect.end.x < panel_rect.end.x - 28.0:
		_fail("%s: [E] should sit at the bottom right" % where)


func _string_width(label: Label) -> float:
	var font := label.get_theme_font("font")
	if font == null:
		return 0.0
	return font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x


func _wait_settled(card: Node, where: String) -> void:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 2500:
		if card != null and card.has_method("is_crt_settled") and bool(card.call("is_crt_settled")):
			await process_frame
			await process_frame
			return
		await process_frame
	_fail("%s: card CRT did not settle" % where)


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


class FakeItemsIndicator extends Node:
	var rect := Rect2()

	func ink_screen_rect() -> Rect2:
		return rect
