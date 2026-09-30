extends SceneTree

const RunStateScript := preload("res://combat/scripts/run_state.gd")


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var failures: Array[String] = []
	var tutorial := root.get_node_or_null("AxelTutorial")
	if tutorial == null:
		_finish(["AxelTutorial autoload missing"])
		return
	tutorial.call("debug_set_enabled", true)
	await process_frame

	_check_roundtrip(failures)
	_check_glow_map(tutorial, failures)
	await _check_move_card(tutorial, failures)
	await _check_spin_card_moves_off_glow(tutorial, failures)
	_finish(failures)


func _check_roundtrip(failures: Array[String]) -> void:
	var state = RunStateScript.new()
	state.tutorial_seen = PackedStringArray(["move_walk", "fight_spin"])
	var restored = RunStateScript.from_dict(state.to_dict())
	if not restored.tutorial_seen.has("move_walk") or not restored.tutorial_seen.has("fight_spin"):
		failures.append("tutorial_seen did not survive to_dict / from_dict")
	if restored.tutorial_seen.size() != 2:
		failures.append("tutorial_seen size changed on round trip")


func _check_glow_map(tutorial: Node, failures: Array[String]) -> void:
	_expect_pieces(tutorial, failures, "fight_spin", ["NEW_Execute", "NEW_Grid"])
	_expect_pieces(tutorial, failures, "fight_stakes", ["MOVE_Balance", "MOVE_BetStrip", "NEW_Goal"])
	_expect_pieces(tutorial, failures, "fight_items", ["NEW_Items"])
	var none: PackedStringArray = tutorial.call("glow_piece_names", "move_walk")
	if not none.is_empty():
		failures.append("move_walk should not glow a fight frame")


func _expect_pieces(tutorial: Node, failures: Array[String], id: String, want: Array) -> void:
	var got: PackedStringArray = tutorial.call("glow_piece_names", id)
	if got.size() != want.size():
		failures.append("%s glow count is %d" % [id, got.size()])
		return
	for piece_name in want:
		if not got.has(piece_name):
			failures.append("%s glow map missing %s" % [id, piece_name])


func _check_move_card(tutorial: Node, failures: Array[String]) -> void:
	tutorial.call("request", "move_walk")
	var body := _body_label(tutorial)
	if body == null:
		failures.append("tutorial body label missing")
		return
	var shown := false
	for _i in 240:
		await process_frame
		if body.text.length() > 0 and body.get_visible_line_count() >= 1:
			var bounds := body.get_character_bounds(0)
			if bounds.size.x > 0.0 and bounds.size.y > 0.0:
				shown = true
				break
	if not shown:
		failures.append("tutorial text did not become readable")
		return
	if not bool(tutorial.call("is_open")):
		failures.append("move card was not open")
	var panel := tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel") as PanelContainer
	if panel == null:
		failures.append("tutorial panel missing")
		return
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		failures.append("tutorial panel has no flat style")
		return
	var fill := Color8(48, 0, 0)
	if not _color_close(style.bg_color, fill):
		failures.append("tutorial fill is %s" % style.bg_color)
	if style.border_width_left < 3 or not _color_close(style.border_color, Color.BLACK):
		failures.append("tutorial border is not a black outline")
	if style.shadow_offset.x <= 0.0 or style.shadow_offset.y <= 0.0:
		failures.append("tutorial shadow does not sit down-right")
	var font_color: Color = body.get_theme_color("font_color")
	if font_color.r < 0.9 or font_color.g < 0.9 or font_color.b < 0.9:
		failures.append("tutorial text is not white")
	var vp := root.get_visible_rect().size
	var card: Rect2 = tutorial.call("card_rect")
	var scale := vp.y / 1280.0
	var anchor_y := (vp.y - 860.0 * scale) * 0.5
	if absf(card.position.y - anchor_y) > 2.0:
		failures.append("move card top moved to %s" % card.position.y)
	if card.size.y < 70.0 * scale or card.size.y > 200.0 * scale:
		failures.append("move card height is %s" % card.size.y)
	if absf(card.size.x - 520.0 * scale) > 2.0:
		failures.append("move card width is %s" % card.size.x)
	var mark := tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel/InnerPanel/TextColumn/HeaderRow/MarkLabel") as Label
	var title := tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel/InnerPanel/TextColumn/HeaderRow/TitleLabel") as Label
	var mark_end := tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel/InnerPanel/TextColumn/HeaderRow/MarkEndLabel") as Label
	if mark == null or mark.text != "?" or mark_end == null or mark_end.text != "?":
		failures.append("tutorial title should read ? Moving ?")
	elif title == null or title.text != "Moving":
		failures.append("tutorial title is missing")
	else:
		if mark.get_global_rect().position.x > card.position.x + 80.0 * scale:
			failures.append("opening ? is not in the top-left")
		var title_rect := title.get_global_rect()
		var open_gap := title_rect.position.x - mark.get_global_rect().end.x
		var close_gap := mark_end.get_global_rect().position.x - title_rect.end.x
		if open_gap < 10.0 * scale:
			failures.append("opening ? is too close to Moving (%s)" % open_gap)
		if close_gap < 10.0 * scale:
			failures.append("closing ? is too close to Moving (%s)" % close_gap)
		if title_rect.size.x < 70.0 * scale:
			failures.append("Moving is squeezed to %s" % title_rect.size.x)
		var title_font := title.get_theme_font("font")
		if not title_font is FontVariation or (title_font as FontVariation).variation_embolden < 0.5:
			failures.append("tutorial title is not bold")
	var dismiss := tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel/InnerPanel/TextColumn/DismissLabel")
	if dismiss != null:
		failures.append("tutorial card still has an E button")
	var exit_button := tutorial.get_node_or_null("CardLayer/ExitButton") as Button
	if exit_button == null or exit_button.text != "X" or not exit_button.visible:
		failures.append("tutorial X marker is missing")
	else:
		var exit_rect := exit_button.get_global_rect()
		if exit_rect.position.x < vp.x * 0.75 or exit_rect.end.y < vp.y * 0.9:
			failures.append("tutorial X is not in the bottom-right corner at %s" % exit_rect)
	if card.position.x < vp.x * 0.5:
		failures.append("move card is not on the right half")
	if not bool(tutorial.call("blocks_spin")):
		failures.append("an open card should block a spin")
	for _i in 240:
		await process_frame
		if bool(tutorial.call("is_waiting")):
			break
	card = tutorial.call("card_rect")
	var body_rect := body.get_global_rect()
	if body_rect.end.y > card.end.y + 1.0:
		failures.append("tutorial body hangs out of the card")
	if card.end.y - body_rect.end.y > 36.0 * scale:
		failures.append("tutorial card has empty space under the text (%s)" % (card.end.y - body_rect.end.y))
	tutorial.call("debug_dismiss")
	var closed := false
	for _i in 180:
		await process_frame
		if not bool(tutorial.call("is_open")):
			closed = true
			break
	if not closed:
		failures.append("move card did not close")
		return
	var run := root.get_node_or_null("AxelRun")
	if run == null or not run.state.tutorial_seen.has("move_walk"):
		failures.append("move_walk was not stored on the run")
	else:
		var restored = RunStateScript.from_dict(run.state.to_dict())
		if not restored.tutorial_seen.has("move_walk"):
			failures.append("live tutorial_seen did not round-trip")
	tutorial.call("request", "move_walk")
	for _i in 8:
		await process_frame
	if bool(tutorial.call("is_open")):
		failures.append("move_walk showed a second time")


func _check_spin_card_moves_off_glow(tutorial: Node, failures: Array[String]) -> void:
	var vp := root.get_visible_rect().size
	var scale := vp.y / 1280.0
	var margin := 36.0 * scale
	var width := 520.0 * scale
	var height := 860.0 * scale
	var right := Rect2(vp.x - margin - width, (vp.y - height) * 0.5, width, height)
	var skull := right.grow(2.0)
	tutorial.call("set_hud_rects", {"NEW_Execute": skull})
	tutorial.call("request", "fight_spin")
	var placed := false
	var card := Rect2()
	for _i in 60:
		await process_frame
		if not bool(tutorial.call("is_open")):
			continue
		card = tutorial.call("card_rect")
		if card.size.y > 40.0 and card.size.x > 40.0:
			placed = true
			break
	if not placed:
		failures.append("spin card did not open")
		return
	if card.intersects(skull):
		failures.append("spin card still covers the skull at %s" % card)
	if card.position.x > vp.x * 0.5:
		failures.append("spin card stayed on the right while the skull was there")
	_expect_flanked_title(tutorial, failures, "Fights")
	await _close_card(tutorial)
	tutorial.call("request", "items_hand")
	var items_title := ""
	var title_label := tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel/InnerPanel/TextColumn/HeaderRow/TitleLabel") as Label
	for _i in 90:
		await process_frame
		if title_label != null and title_label.text == "Items" and bool(tutorial.call("is_open")):
			items_title = title_label.text
			break
	if items_title != "Items":
		failures.append("items card title is '%s'" % items_title)
	else:
		_expect_flanked_title(tutorial, failures, "Items")
	await _close_card(tutorial)


func _expect_flanked_title(tutorial: Node, failures: Array[String], want: String) -> void:
	var title := tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel/InnerPanel/TextColumn/HeaderRow/TitleLabel") as Label
	var mark := tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel/InnerPanel/TextColumn/HeaderRow/MarkLabel") as Label
	var mark_end := tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel/InnerPanel/TextColumn/HeaderRow/MarkEndLabel") as Label
	if title == null or title.text != want:
		failures.append("tutorial title is '%s', expected %s" % [title.text if title != null else "", want])
		return
	if mark == null or mark.text != "?" or mark_end == null or mark_end.text != "?":
		failures.append("%s is missing its question marks" % want)
		return
	var title_rect := title.get_global_rect()
	var open_gap := title_rect.position.x - mark.get_global_rect().end.x
	var close_gap := mark_end.get_global_rect().position.x - title_rect.end.x
	if open_gap < 10.0:
		failures.append("opening ? is too close to %s (%s)" % [want, open_gap])
	if close_gap < 10.0:
		failures.append("closing ? is too close to %s (%s)" % [want, close_gap])
	if title_rect.size.x < 40.0:
		failures.append("%s is squeezed to %s" % [want, title_rect.size.x])
	var title_font := title.get_theme_font("font")
	if not title_font is FontVariation or (title_font as FontVariation).variation_embolden < 0.5:
		failures.append("%s is not bold" % want)


func _close_card(tutorial: Node) -> void:
	var exit_button := tutorial.get_node_or_null("CardLayer/ExitButton") as Button
	if exit_button != null:
		exit_button.emit_signal("pressed")
	for _i in 180:
		await process_frame
		if not bool(tutorial.call("is_open")):
			return


func _body_label(tutorial: Node) -> Label:
	return tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel/InnerPanel/TextColumn/BodyLabel") as Label


func _color_close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.02 and absf(a.g - b.g) < 0.02 and absf(a.b - b.b) < 0.02 and absf(a.a - b.a) < 0.02


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("tutorial popup check OK")
		quit(0)
		return
	for line in failures:
		push_error(line)
	quit(1)
