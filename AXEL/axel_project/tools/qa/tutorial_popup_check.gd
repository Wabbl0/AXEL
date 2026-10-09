extends SceneTree

const RunStateScript := preload("res://combat/scripts/run_state.gd")
const PieceHighlightGlow := preload("res://combat/scripts/piece_highlight_glow.gd")


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
	await _check_card_stack(tutorial, failures)
	await _check_slot_freeze(tutorial, failures)
	await _check_click_and_close_keys(tutorial, failures)
	await _check_highlight_above_noir(failures)
	await _check_guide_link(tutorial, failures)
	_finish(failures)


func _check_guide_link(tutorial: Node, failures: Array[String]) -> void:
	var pause := root.get_node_or_null("AxelPause")
	var profile := root.get_node_or_null("AxelProfile")
	if pause == null or profile == null:
		failures.append("guide link check needs AxelPause and AxelProfile")
		return
	profile.call("debug_use_memory_only")
	profile.call("unlock_guide")
	var scene := Node2D.new()
	scene.name = "GuideLinkProbeScene"
	root.add_child(scene)
	current_scene = scene
	await process_frame

	var menu: Node = pause.get("_menu")
	await _open_guide_card(tutorial)
	if _open_lesson(tutorial) != "guide_pause":
		failures.append("guide card did not open")
		return
	var rich := tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel/InnerPanel/TextColumn/BodyRich") as RichTextLabel
	if rich == null or not rich.visible:
		failures.append("guide card has no rich body")
		return
	if not rich.text.contains("[url=guide]") or not rich.text.contains("[u]Guide[/u]"):
		failures.append("guide word is not an underlined link: %s" % rich.text)
	if rich.get_parsed_text() != String(tutorial.get("LESSONS")["guide_pause"]["body"]):
		failures.append("guide card text changed: %s" % rich.get_parsed_text())
	rich.emit_signal("meta_clicked", "guide")
	await process_frame
	if not get_tree_paused():
		failures.append("guide link did not pause the game")
	if menu == null or not bool(menu.call("is_guide_open")):
		failures.append("guide link did not open the Guide")
	for _i in 120:
		await process_frame
		if not bool(tutorial.call("is_open")):
			break
	if bool(tutorial.call("is_open")):
		failures.append("guide card stayed after the link opened the Guide")
	pause.call("request_unpause")
	await process_frame

	await _open_guide_card(tutorial)
	if _open_lesson(tutorial) != "guide_pause":
		failures.append("guide card did not reopen for the pause route")
	else:
		pause.call("request_pause")
		menu.call("_open_guide")
		for _i in 120:
			await process_frame
			if not bool(tutorial.call("is_open")):
				break
		if bool(tutorial.call("is_open")):
			failures.append("guide card stayed after opening the Guide from pause")
		pause.call("request_unpause")
	current_scene = null
	scene.queue_free()
	await process_frame


func _open_guide_card(tutorial: Node) -> void:
	var marked: Dictionary = tutorial.get("_marked")
	marked.erase("guide_pause")
	var run := root.get_node_or_null("AxelRun")
	if run != null:
		var seen: PackedStringArray = run.state.tutorial_seen
		var at := seen.find("guide_pause")
		if at >= 0:
			seen.remove_at(at)
			run.state.tutorial_seen = seen
	root.get_node("AxelProfile").call("debug_use_memory_only")
	root.get_node("AxelProfile").call("unlock_guide")
	tutorial.call("request", "guide_pause")
	await _wait_lesson(tutorial, "guide_pause")
	for _i in 600:
		await process_frame
		if bool(tutorial.call("is_waiting")):
			return


func get_tree_paused() -> bool:
	return paused


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
	_expect_pieces(tutorial, failures, "fight_stakes", ["NEW_Bets", "NEW_Goal"])
	_expect_pieces(tutorial, failures, "fight_items", ["NEW_Items"])
	_expect_pieces(tutorial, failures, "slot_match", ["NEW_History", "NEW_Grid"])
	_expect_pieces(tutorial, failures, "slot_power", ["NEW_Execute"])
	_expect_pieces(tutorial, failures, "slot_vice", ["NEW_Execute", "NEW_Grid"])
	_expect_pieces(tutorial, failures, "slot_multiplier", ["NEW_Multiplier"])
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
	var exit_button := tutorial.get_node_or_null("CardLayer/CardHost/ExitButton") as Button
	if exit_button == null or exit_button.text != "X" or not exit_button.visible:
		failures.append("tutorial X marker is missing")
	else:
		var exit_rect := exit_button.get_global_rect()
		var card_rect := card
		if not card_rect.grow(4.0).intersects(exit_rect):
			failures.append("tutorial X is not on the move card at %s" % exit_rect)
		var want_font := roundi(float(UiViewportScale.EXIT_BUTTON_FONT) * scale * 0.5)
		var got_font := exit_button.get_theme_font_size("font_size")
		if absi(got_font - want_font) > 2:
			failures.append("tutorial X font is %s, want about %s" % [got_font, want_font])
		if exit_rect.size.x > 52.0 * scale:
			failures.append("tutorial X is too large (%s)" % exit_rect.size)
		if exit_rect.size.x < 40.0 * scale:
			failures.append("tutorial X is too small (%s)" % exit_rect.size)
	if card.position.x < vp.x * 0.5:
		failures.append("move card is not on the right half")
	if bool(tutorial.call("blocks_spin")):
		failures.append("an open card must not block a spin")
	for _i in 240:
		await process_frame
		if bool(tutorial.call("is_waiting")):
			break
	card = tutorial.call("card_rect")
	var body_rect := body.get_global_rect()
	if body_rect.end.y > card.end.y + 1.0:
		failures.append("tutorial body hangs out of the card")
	if card.end.y - body_rect.end.y > 84.0 * scale:
		failures.append("tutorial card has empty space under the text (%s)" % (card.end.y - body_rect.end.y))
	tutorial.call("debug_dismiss")
	await create_timer(4.0).timeout
	if not bool(tutorial.call("is_open")):
		failures.append("move card closed without the walk action or X")
		return
	tutorial.call("complete", "move_walk")
	var closed := false
	for _i in 180:
		await process_frame
		if not bool(tutorial.call("is_open")):
			closed = true
			break
	if not closed:
		failures.append("move card did not close on its action")
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
	await create_timer(0.7).timeout
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
	if card.position.x <= vp.x * 0.5:
		failures.append("spin card left the right half at %s" % card)
	_expect_flanked_title(tutorial, failures, "Fights")
	await _close_card(tutorial)
	await create_timer(0.7).timeout
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


func _check_card_stack(tutorial: Node, failures: Array[String]) -> void:
	tutorial.call("request", "fight_stakes")
	tutorial.call("request", "fight_items")
	var host := tutorial.get_node_or_null("CardLayer/CardHost") as Control
	var host2 := tutorial.get_node_or_null("CardLayer/CardHost2") as Control
	if host == null or host2 == null:
		failures.append("card hosts missing for stack check")
		return
	if not await _wait_lesson(tutorial, "fight_stakes"):
		failures.append("stakes card did not open")
		return
	var exit0 := tutorial.get_node_or_null("CardLayer/CardHost/ExitButton") as Button
	if exit0 == null or not exit0.visible:
		failures.append("stakes card should have an X")
	await create_timer(2.0).timeout
	if host2.visible:
		failures.append("a second card opened while the first was still up")

	var open_before := bool(tutorial.call("is_open"))
	Input.action_press("interact")
	await process_frame
	Input.action_release("interact")
	await process_frame
	if open_before and not bool(tutorial.call("is_open")):
		failures.append("interact closed a tutorial card")

	tutorial.call("request", "slot_power")
	if not await _wait_lesson(tutorial, "slot_power"):
		failures.append("freeze card did not cut in front of the stakes card")
	if bool(tutorial.call("_is_seen", "fight_stakes")):
		failures.append("cut-in marked the stakes card as seen")
	if host2.visible:
		failures.append("cut-in opened a second card host")
	tutorial.call("close_freeze_card")
	if not await _wait_lesson(tutorial, "fight_stakes"):
		failures.append("stakes card did not come back after the cut-in")
	tutorial.call("complete", "fight_stakes")
	if not await _wait_lesson(tutorial, "fight_items"):
		failures.append("items card did not follow the stakes card")
	if not bool(tutorial.call("_is_seen", "fight_stakes")):
		failures.append("stakes card not marked seen after the bet change")
	await _close_both_cards(tutorial)


func _check_click_and_close_keys(tutorial: Node, failures: Array[String]) -> void:
	var pause := root.get_node_or_null("AxelPause")
	tutorial.call("request", "items_wheel")
	if not await _wait_lesson(tutorial, "items_wheel"):
		failures.append("items_wheel card did not open for the click check")
		return
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	tutorial.call("_on_card_gui_input", click, 0)
	for _i in 180:
		await process_frame
		if not bool(tutorial.call("is_open")):
			break
	if bool(tutorial.call("is_open")):
		failures.append("a click on the card did not close it")
	if not bool(tutorial.call("_is_seen", "items_wheel")):
		failures.append("a click close did not mark the card seen")
	await create_timer(0.7).timeout
	tutorial.call("request", "slot_multiplier")
	if not await _wait_lesson(tutorial, "slot_multiplier"):
		failures.append("multiplier card did not open")
		return
	if pause != null and bool(pause.call("_can_pause_here")):
		failures.append("pause is allowed while a card is up")
	var esc := InputEventAction.new()
	esc.action = &"pause"
	esc.pressed = true
	tutorial.call("_unhandled_input", esc)
	for _i in 180:
		await process_frame
		if not bool(tutorial.call("is_open")):
			break
	if bool(tutorial.call("is_open")):
		failures.append("Esc did not close the card")
	if get_tree_paused():
		failures.append("Esc paused the game while a card was up")
	if not bool(tutorial.call("_is_seen", "slot_multiplier")):
		failures.append("Esc close did not mark the card seen")
	if CombatPace.is_frozen():
		failures.append("time stayed frozen after Esc closed the card")


func _open_lesson(tutorial: Node) -> String:
	var slot = tutorial.get("_slots")[0]
	if slot.phase == 0 or slot.phase == 4:
		return ""
	return String(slot.open_id)


func _wait_lesson(tutorial: Node, id: String) -> bool:
	var left := 4.0
	while left > 0.0:
		await process_frame
		left -= 1.0 / 60.0
		if _open_lesson(tutorial) == id:
			return true
	return false


func _check_slot_freeze(tutorial: Node, failures: Array[String]) -> void:
	tutorial.call("request", "slot_match")
	if not bool(tutorial.call("is_freezing")) or not CombatPace.is_frozen():
		failures.append("slot_match did not freeze combat time")
	if not is_zero_approx(CombatPace.multiplier()):
		failures.append("combat pace is not zero while frozen")
	var slot_ready := false
	var waited := 0.0
	while waited < 40.0:
		await process_frame
		waited += 1.0 / 60.0
		if bool(tutorial.call("is_waiting")):
			slot_ready = true
			break
	if not slot_ready:
		failures.append("slot_match card never finished typing")
		return
	await create_timer(1.0).timeout
	if not bool(tutorial.call("is_waiting")):
		failures.append("slot card closed by itself without X")
	if not bool(tutorial.call("blocks_spin")):
		failures.append("slot card should block spinning while frozen")
	if not CombatPace.is_frozen():
		failures.append("time unfroze before the card closed")
	await _close_card(tutorial)
	if CombatPace.is_frozen() or bool(tutorial.call("is_freezing")):
		failures.append("time stayed frozen after the card closed")
	if CombatPace.multiplier() <= 0.0:
		failures.append("combat pace stayed at zero after unfreeze")


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
	var exit_button := tutorial.get_node_or_null("CardLayer/CardHost/ExitButton") as Button
	if exit_button != null:
		exit_button.emit_signal("pressed")
	for _i in 180:
		await process_frame
		if not bool(tutorial.call("is_open")):
			return


func _close_both_cards(tutorial: Node) -> void:
	var exit0 := tutorial.get_node_or_null("CardLayer/CardHost/ExitButton") as Button
	var exit1 := tutorial.get_node_or_null("CardLayer/CardHost2/ExitButton") as Button
	if exit0 != null and exit0.visible:
		exit0.emit_signal("pressed")
	if exit1 != null and exit1.visible:
		exit1.emit_signal("pressed")
	for _i in 240:
		await process_frame
		if not bool(tutorial.call("is_open")):
			return

	for _i in 4:
		tutorial.call("debug_dismiss")
		await process_frame
	for _i in 180:
		await process_frame
		if not bool(tutorial.call("is_open")):
			return


func _body_label(tutorial: Node) -> Label:
	return tutorial.get_node_or_null("CardLayer/CardHost/FadeRoot/BarPanel/InnerPanel/TextColumn/BodyLabel") as Label


func _color_close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.02 and absf(a.g - b.g) < 0.02 and absf(a.b - b.b) < 0.02 and absf(a.a - b.a) < 0.02


func _check_highlight_above_noir(failures: Array[String]) -> void:
	var scene := Control.new()
	scene.name = "GlowProbeScene"
	root.add_child(scene)
	var piece := Control.new()
	piece.name = "NEW_Execute"
	piece.position = Vector2(200, 200)
	piece.size = Vector2(120, 160)
	scene.add_child(piece)
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	image.fill_rect(Rect2i(8, 8, 16, 16), Color.BLACK)
	var art := TextureRect.new()
	art.name = "SkullStage1"
	art.texture = ImageTexture.create_from_image(image)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.size = Vector2(120, 160)
	piece.add_child(art)
	await process_frame
	PieceHighlightGlow.set_highlight(piece, true)
	PieceHighlightGlow.pulse_highlights(piece, 0.8)
	await process_frame
	await process_frame
	var glow: TextureRect = PieceHighlightGlow.glow_for(art)
	if glow == null:
		failures.append("highlight glow was not made")
	else:
		var layer := glow.get_parent().get_parent() as CanvasLayer
		if layer == null or layer.layer <= 90:
			failures.append("highlight glow is not above the noir layer")
		if art.is_ancestor_of(glow):
			failures.append("highlight glow sits inside the art")
		if not glow.visible:
			failures.append("highlight glow is hidden while the art shows")
		if not glow.get_global_rect().is_equal_approx(art.get_global_rect()):
			failures.append("highlight glow does not sit on the art: %s vs %s" % [glow.get_global_rect(), art.get_global_rect()])
		if absf(glow.modulate.a - 0.8) > 0.01:
			failures.append("highlight glow pulse alpha is %.2f" % glow.modulate.a)
	if not art.is_visible_in_tree():
		failures.append("highlighted art went hidden")
	PieceHighlightGlow.set_highlight(piece, false)
	await process_frame
	await process_frame
	if PieceHighlightGlow.glow_for(art) != null:
		failures.append("highlight glow stayed after turning off")
	scene.queue_free()
	await process_frame


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("tutorial popup check OK")
		quit(0)
		return
	for line in failures:
		push_error(line)
	quit(1)
