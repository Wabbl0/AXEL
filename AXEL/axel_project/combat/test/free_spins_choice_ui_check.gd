extends SceneTree

const SCENE_PATH := "res://combat/combat_test.tscn"
const WANT := Vector2(1920, 1280)
const SCRIM_A := 0.72
const HOVER_SCALE := 1.15
const SIZE_SLACK := 4.0

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_POST_FX", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	await process_frame
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("free_spins_choice_ui_check: could not load combat test")
		quit(1)
		return
	var ui := packed.instantiate()
	root.add_child(ui)
	var ready := false
	for _i in 40:
		await process_frame
		if ui.get_node_or_null("FreeSpinsChoiceLayer") != null:
			ready = true
			break
	if not ready:
		_fail("FreeSpinsChoiceLayer was not built")
		_finish()
		return
	var combat = ui.get("combat")
	if combat == null:
		_fail("CombatRoot missing")
		_finish()
		return
	combat._awaiting_free_spin_choice = true
	ui._refresh_super_fs_choice_overlay()
	for _j in 4:
		await process_frame
	_check_chrome(ui)
	_check_columns(ui)
	await _check_section_hover(ui)
	await _check_hover_keeps_words(ui)
	await _check_padding_click(ui, combat)
	await _check_spin_bars(ui, combat)
	_finish()


func _check_chrome(ui: Node) -> void:
	var overlay := ui.find_child("SuperFSChoiceOverlay", true, false) as Control
	if overlay == null or not overlay.visible:
		_fail("choice overlay should be visible")
		return
	var layer := overlay.get_parent() as CanvasLayer
	if layer == null or layer.layer != 116:
		_fail("choice overlay should sit on canvas layer 116")
	var title := ui.find_child("SuperFSChoiceTitle", true, false) as Label
	var vice_word := ui.find_child("ViceTitleWord", true, false) as Label
	if title == null or title.text != "Choose Your ":
		_fail("title should be Choose Your Vice")
	elif not _is_white(title.get_theme_color("font_color")):
		_fail("Choose Your should stay white")
	if vice_word == null or vice_word.text != "Vice" or not _is_red(vice_word.get_theme_color("font_color")):
		_fail("Vice in the title should be red")
	var hint := ui.find_child("SuperFSChoiceHint", true, false) as Label
	if hint == null or hint.text != "Fewer spins, higher potential":
		_fail("hint text changed")
	var panel := overlay.get_node_or_null("SuperFSChoicePanel") as Panel
	if panel == null:
		_fail("choices should share one panel")
	else:
		var panel_rect := panel.get_global_rect()
		if panel_rect.size.x > WANT.x * 0.92 or panel_rect.size.y > WANT.y * 0.92:
			_fail("choice panel spans the window (%s)" % panel_rect.size)
		if title != null and not panel_rect.grow(2.0).encloses(title.get_global_rect()):
			_fail("title should sit on the shared panel")
		if ui.find_child("ViceChoiceHeader", true, false) != null:
			_fail("title should not have its own black box")
		_check_fade(panel)
	var scrim := overlay.get_node_or_null("SuperFSChoiceDimmer") as ColorRect
	if scrim == null:
		_fail("scrim missing")
		return
	if absf(scrim.color.a - SCRIM_A) > 0.02:
		_fail("scrim alpha %.3f should be %.2f" % [scrim.color.a, SCRIM_A])
	var scrim_rect := scrim.get_global_rect()
	if scrim_rect.size.x < WANT.x - SIZE_SLACK or scrim_rect.size.y < WANT.y - SIZE_SLACK:
		_fail("scrim size %s is not the full window" % scrim_rect.size)


func _check_columns(ui: Node) -> void:
	var expect := {
		"ChooseBloodyHandButton": "bloody_hand.png",
		"ChooseAlcoholButton": "booze.png",
		"ChooseCigaretteButton": "cigarette.png",
	}
	for button_name in expect.keys():
		var button := ui.find_child(button_name, true, false) as Button
		if button == null:
			_fail("%s missing" % button_name)
			continue
		if not button.text.is_empty():
			_fail("%s should not draw its own button text" % button_name)
		var icon := button.find_child("ViceIcon", true, false) as TextureRect
		var text_block := button.find_child("ViceTextBlock", true, false) as PanelContainer
		if icon == null or icon.texture == null:
			_fail("%s icon missing" % button_name)
			continue
		var path := icon.texture.resource_path
		if not path.ends_with(str(expect[button_name])):
			_fail("%s icon is %s" % [button_name, path])
		if icon.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			_fail("%s icon should stay pixelated" % button_name)
		if icon.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_fail("%s icon should pass hover to the whole choice" % button_name)
		if text_block == null:
			_fail("%s text block missing" % button_name)
			continue
		if _is_black_panel(text_block):
			_fail("%s should use the shared panel, not its own black box" % button_name)
		var name_lab := button.find_child("ViceName", true, false) as Label
		if name_lab == null or not _is_red(name_lab.get_theme_color("font_color")):
			_fail("%s name should be red" % button_name)
		var spins_lab := button.find_child("ViceSpins", true, false) as Label
		if spins_lab == null or not _is_white(spins_lab.get_theme_color("font_color")):
			_fail("%s spin line should stay white" % button_name)
		var btn_rect := button.get_global_rect()
		var icon_rect := icon.get_global_rect()
		var text_rect := text_block.get_global_rect()
		var shared := ui.find_child("SuperFSChoicePanel", true, false) as Panel
		if shared == null or not shared.get_global_rect().grow(2.0).encloses(text_rect) or not shared.get_global_rect().grow(2.0).encloses(icon_rect):
			_fail("%s icon or words sit outside the shared panel" % button_name)
		if icon_rect.size.x < 8.0 or text_rect.size.x < 8.0:
			_fail("%s icon or text has no size" % button_name)
			continue
		if not btn_rect.has_point(icon_rect.get_center()) or not btn_rect.has_point(text_rect.get_center()):
			_fail("%s hit box does not cover the icon and the words" % button_name)
		if btn_rect.size.x < text_rect.size.x + 24.0 or btn_rect.size.y < text_rect.size.y + icon_rect.size.y + 24.0:
			_fail("%s hit box is not larger than the words" % button_name)
		if _padding_point(btn_rect, icon_rect, text_rect) == Vector2.INF:
			_fail("%s has no padding outside the icon and the words" % button_name)
		var glow := button.find_child("ViceHoverHighlight", true, false) as TextureRect
		if glow == null or not glow.get_global_rect().grow(4.0).encloses(icon_rect):
			_fail("%s highlight should sit behind the icon" % button_name)
		elif glow.get_global_rect().intersects(text_rect.grow(-6.0)):
			_fail("%s highlight should not cover the words" % button_name)
		elif not _is_faded_white_glow(glow):
			_fail("%s highlight should be a faded white gradient" % button_name)


func _check_fade(panel: Panel) -> void:
	var fade := panel.get_node_or_null("ViceChoiceFade") as TextureRect
	if fade == null or fade.texture == null:
		_fail("choice background should fade out")
		return
	if fade.get_global_rect().size.x < panel.get_global_rect().size.x + 40.0:
		_fail("fade should extend past the card")
	var img := fade.texture.get_image()
	if img == null or img.is_empty():
		_fail("fade image missing")
		return
	var center := img.get_pixel(img.get_width() / 2, img.get_height() / 2)
	var corner := img.get_pixel(0, 0)
	if center.a < 0.9 or center.r > 0.05:
		_fail("fade center should be solid black")
	if corner.a > 0.08:
		_fail("fade corner should be clear, alpha %.3f" % corner.a)
	var found_mid := false
	var x := img.get_width() / 2
	for y in img.get_height():
		var a := img.get_pixel(x, y).a
		if a > 0.25 and a < 0.75:
			found_mid = true
			break
		if a > 0.9:
			break
	if not found_mid:
		_fail("fade should pass through a mid alpha")


func _check_section_hover(ui: Node) -> void:
	var button := ui.find_child("ChooseCigaretteButton", true, false) as Button
	if button == null:
		return
	var icon := button.find_child("ViceIcon", true, false) as Control
	var text_block := button.find_child("ViceTextBlock", true, false) as Control
	if icon == null or text_block == null:
		_fail("section hover pieces missing")
		return
	for point in [icon.get_global_rect().get_center(), text_block.get_global_rect().get_center()]:
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		root.push_input(motion)
		await process_frame
		var hovered := root.gui_get_hovered_control()
		if hovered != button:
			var hovered_name := "none"
			if hovered != null:
				hovered_name = String(hovered.name)
			_fail("choice hover hit %s, expected the whole cigarette section" % hovered_name)


func _check_hover_keeps_words(ui: Node) -> void:
	var button := ui.find_child("ChooseCigaretteButton", true, false) as Button
	if button == null:
		return
	var icon := button.find_child("ViceIcon", true, false) as TextureRect
	var text_block := button.find_child("ViceTextBlock", true, false) as Control
	var highlight := button.find_child("ViceHoverHighlight", true, false) as TextureRect
	if icon == null or text_block == null or highlight == null:
		_fail("hover pieces missing")
		return
	if highlight.modulate.a > 0.05:
		_fail("highlight should start hidden")
	var before := text_block.get_global_rect().position
	button.mouse_entered.emit()
	if absf(icon.scale.x - 1.0) > 0.02:
		_fail("hover scale jumped immediately to %.3f" % icon.scale.x)
	var reached := false
	for _i in 45:
		await process_frame
		if absf(icon.scale.x - HOVER_SCALE) < 0.03 and highlight.modulate.a > 0.92:
			reached = true
			break
	if not reached:
		_fail("icon hover scale is %.3f, highlight %.3f" % [icon.scale.x, highlight.modulate.a])
	elif not _is_faded_white_glow(highlight):
		_fail("hover highlight should be a faded white gradient")
	var after := text_block.get_global_rect().position
	if before.distance_to(after) > 1.0:
		_fail("hovering the icon moved the words")
	button.mouse_exited.emit()
	var shrunk := false
	for _j in 45:
		await process_frame
		if absf(icon.scale.x - 1.0) < 0.03 and highlight.modulate.a < 0.08:
			shrunk = true
			break
	if not shrunk:
		_fail("icon did not shrink back after hover (scale %.3f)" % icon.scale.x)


func _check_padding_click(ui: Node, combat: Node) -> void:
	var button := ui.find_child("ChooseAlcoholButton", true, false) as Button
	if button == null:
		return
	var icon := button.find_child("ViceIcon", true, false) as Control
	var text_block := button.find_child("ViceTextBlock", true, false) as Control
	if icon == null or text_block == null:
		return
	var point := _padding_point(button.get_global_rect(), icon.get_global_rect(), text_block.get_global_rect())
	if point == Vector2.INF:
		return
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	await process_frame
	var hovered := root.gui_get_hovered_control()
	if hovered != button:
		var hovered_name := "none"
		if hovered != null:
			hovered_name = String(hovered.name)
		_fail("padding hover hit %s, expected ChooseAlcoholButton" % hovered_name)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = point
	click.global_position = point
	root.push_input(click)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = point
	release.global_position = point
	root.push_input(release)
	await process_frame
	var chosen := String(combat.free_spins.chosen_power)
	if chosen != "alcohol":
		_fail("padding click chose '%s', expected alcohol" % chosen)


func _check_spin_bars(ui: Node, combat: Node) -> void:
	combat._encounter_complete = true
	combat.free_spins.reset()
	for _i in 240:
		await process_frame
		if not bool(ui.get("_spin_busy")):
			break
	combat._encounter_complete = false
	combat._state = CombatRoot.State.IDLE
	combat.free_spins.reset()
	combat._awaiting_free_spin_choice = true
	combat.choose_free_spins_power(&"bloody_hand")
	await process_frame
	var skull := ui.find_child("PremiumSkull", true, false) as Control
	if skull == null:
		_fail("skull missing during free spins")
		return
	var full_face := 0.85 * 1.067
	if absf(skull.scale.x - full_face) > 0.04:
		_fail("skull scale %.3f should stay on the smaller full face" % skull.scale.x)
	var history := ui.find_child("NEW_History", true, false) as Control
	if history != null:
		var hist_rect := _visual_rect(history)
		var skull_rect := _visual_rect(skull)
		var drawn_top := skull_rect.position.y + skull_rect.size.y * (27.0 / 922.0)
		var drawn_hist_bottom := hist_rect.position.y + hist_rect.size.y * (866.0 / 881.0)
		var gap := drawn_top - drawn_hist_bottom
		if gap < 8.0:
			_fail("skull should keep a small gap under history, gap %.1f" % gap)
		elif gap > 48.0:
			_fail("skull moved too far from history, gap %.1f" % gap)
	var host := ui.find_child("FreeSpinBars", true, false) as Control
	if host == null or not host.visible:
		_fail("FreeSpinBars should be visible")
		return
	var blocks: Array[Panel] = []
	var count_root := host.find_child("FreeSpinCountRoot", true, false)
	if count_root != null:
		for child in count_root.get_children():
			if child is Panel:
				blocks.append(child as Panel)
	if blocks.size() != 4:
		_fail("expected 4 spin blocks, got %d" % blocks.size())
	for block in blocks:
		var style := block.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null or not _is_white(style.bg_color):
			_fail("spin block should be white")
		elif style.border_color.r > 0.05 or style.border_color.g > 0.05 or style.border_color.b > 0.05:
			_fail("spin block edge should be black")
		elif style.get_border_width(SIDE_LEFT) < 2:
			_fail("spin block edge should be at least 2px")
		elif style.shadow_color.a < 0.3 or style.shadow_offset.y < 1.0:
			_fail("spin block should have a small shadow")
	if not blocks.is_empty():
		var block_parent := blocks[0].get_parent()
		var count_layer := block_parent.get_parent() if block_parent != null else null
		if count_layer is CanvasLayer and (count_layer as CanvasLayer).layer <= 108:
			_fail("spin blocks should sit above the skull")
		elif not count_layer is CanvasLayer:
			_fail("spin blocks should sit above the skull")
		var drawn_skull := _visual_rect(skull)
		var drawn_bottom := drawn_skull.position.y + drawn_skull.size.y * (885.0 / 922.0)
		var overlap := drawn_bottom - blocks[0].get_global_rect().position.y
		if overlap > 10.0:
			_fail("spin bars overlap the skull by %.1f" % overlap)
	if not blocks.is_empty():
		var first_rect := blocks[0].get_global_rect()
		_check_inside_window("first spin block", first_rect)
		if first_rect.size.x < 20.0 or first_rect.size.y < 14.0:
			_fail("spin block is too small (%s)" % first_rect.size)
	var label := host.find_child("FreeSpinCount", true, false) as Label
	if label == null or label.text != "1/4 spins":
		var got := ""
		if label != null:
			got = label.text
		_fail("count should read 1/4 spins, got '%s'" % got)
		return
	_check_inside_window("spin count", label.get_global_rect())
	if not _is_white(label.get_theme_color("font_color")):
		_fail("spin count should be white")
	var count_layer := label.get_parent().get_parent() as CanvasLayer
	if count_layer == null or count_layer.layer <= 108:
		_fail("spin count should sit above the color filter")
	if label.get_theme_constant("shadow_offset_y") < 2:
		_fail("spin count should have a small shadow")
	combat.free_spins.reset()
	ui._refresh_spin_bars()
	if label.is_visible_in_tree():
		_fail("spin count should hide when free spins end")


func _visual_rect(node: Control) -> Rect2:
	var xform := node.get_global_transform_with_canvas()
	var corners: Array[Vector2] = [
		xform * Vector2.ZERO,
		xform * Vector2(node.size.x, 0.0),
		xform * node.size,
		xform * Vector2(0.0, node.size.y),
	]
	var lo := corners[0]
	var hi := corners[0]
	for point in corners:
		lo = lo.min(point)
		hi = hi.max(point)
	return Rect2(lo, hi - lo)


func _check_inside_window(what: String, rect: Rect2) -> void:
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		_fail("%s has no size" % what)
		return
	if rect.position.x < -1.0 or rect.position.y < -1.0 or rect.end.x > WANT.x + 1.0 or rect.end.y > WANT.y + 1.0:
		_fail("%s sits outside the window (%s)" % [what, rect])


func _padding_point(btn_rect: Rect2, icon_rect: Rect2, text_rect: Rect2) -> Vector2:
	var spots: Array[Vector2] = [
		btn_rect.position + Vector2(12, 12),
		Vector2(btn_rect.position.x + 12, btn_rect.end.y - 12),
		Vector2(btn_rect.end.x - 12, btn_rect.position.y + 12),
		Vector2(btn_rect.end.x - 12, btn_rect.end.y - 12),
	]
	var blocked_icon := icon_rect.grow(6.0)
	var blocked_text := text_rect.grow(6.0)
	for spot in spots:
		if not btn_rect.has_point(spot):
			continue
		if blocked_icon.has_point(spot) or blocked_text.has_point(spot):
			continue
		return spot
	return Vector2.INF


func _is_faded_white_glow(glow: TextureRect) -> bool:
	if glow.texture == null:
		return false
	var img := glow.texture.get_image()
	if img == null or img.is_empty():
		return false
	var center := img.get_pixel(img.get_width() / 2, img.get_height() / 2)
	var corner := img.get_pixel(0, 0)
	if center.r < 0.9 or center.g < 0.9 or center.b < 0.9:
		return false
	if center.a < 0.15 or center.a > 0.5:
		return false
	if corner.a > 0.06:
		return false
	var mid := img.get_pixel(img.get_width() / 2, int(img.get_height() * 0.2))
	return mid.a > corner.a + 0.05 and mid.a < center.a - 0.02


func _is_red(color: Color) -> bool:
	return color.r > 0.9 and color.g < 0.15 and color.b < 0.15 and color.a > 0.9


func _is_white(color: Color) -> bool:
	return color.r > 0.98 and color.g > 0.98 and color.b > 0.98 and color.a > 0.98


func _is_black_panel(panel: PanelContainer) -> bool:
	return _is_black_style(panel)


func _is_black_style(control: Control) -> bool:
	var style := control.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return false
	return style.bg_color.r < 0.02 and style.bg_color.g < 0.02 and style.bg_color.b < 0.02 and style.bg_color.a > 0.98


func _finish() -> void:
	if _failures.is_empty():
		print("Free spins choice UI check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("free_spins_choice_ui_check: %s" % msg)
	quit(1)
