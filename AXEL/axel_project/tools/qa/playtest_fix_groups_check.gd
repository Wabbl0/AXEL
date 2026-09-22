extends SceneTree

const WINDOW := Vector2i(1920, 1280)
const ROOMS := [
	"res://scenes/Arc_1/1.1_SchoolExterior.tscn",
	"res://scenes/Arc_1/1.2_Corridor.tscn",
	"res://scenes/Arc_1/1.4_BasementDoor.tscn",
	"res://scenes/Arc_2/2.1_Cafeteria.tscn",
	"res://scenes/Arc_2/2.3_Kitchen.tscn",
	"res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn",
	"res://scenes/Arc_3/3.1_Backyard.tscn",
	"res://scenes/Arc_4/4.1_TeachersLounge.tscn",
	"res://scenes/Arc_5/5.1_Classroom.tscn",
]
const GAP_ROOMS := [
	"res://scenes/Arc_1/1.2_Corridor.tscn",
	"res://scenes/Arc_2/2.1_Cafeteria.tscn",
]

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_WORLD_COMBAT", "0")
	OS.set_environment("AXEL_SKIP_INTRO", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	await process_frame
	await _check_rarity()
	_check_marker_z()
	await _check_outlines()
	await _check_prompt_gaps()
	_check_grime()
	_check_goal_round()
	_check_wild_halo()
	await _check_options_theme()
	await _check_item_rows()
	_check_hud_white()
	await _check_combat_music()
	if _failures.is_empty():
		print("Playtest fix groups check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("playtest_fix_groups_check: %s" % msg)
	quit(1)


func _check_rarity() -> void:
	var defs: Script = load("res://combat/scripts/item_def.gd")
	for i in 5:
		var glyph: String = defs.call("rarity_glyph_index", i)
		var want: String = ["◇", "◈", "◆", "★", "✦"][i]
		if glyph != want:
			_fail("rarity %d glyph %s should be %s" % [i, glyph, want])
	var item := load("res://combat/data/items/C1_ash_spin_token.tres") as Resource
	var card: Node = load("res://scenes/ui/world_item_info_card.gd").new()
	root.add_child(card)
	if not card.is_node_ready():
		await card.ready
	card.call("show_item", Vector2.ZERO, defs.call("rarity_name", item), "desc", null)
	var name_lab := card.find_child("ItemName", true, false) as Label
	if name_lab == null or not name_lab.text.begins_with("◇"):
		_fail("world card name should start with the common glyph")
	card.queue_free()


func _check_marker_z() -> void:
	var marker := load("res://scenes/world/ItemMarker.tscn").instantiate() as Node2D
	root.add_child(marker)
	var marker_z := marker.z_index
	if marker_z != -8:
		_fail("item marker z should be -8, got %d" % marker_z)
	for room_path in ROOMS:
		var player_z := _player_z_in_scene(room_path)
		if player_z <= marker_z:
			_fail("%s player z %d is not above the item marker" % [room_path, player_z])
	marker.queue_free()


func _player_z_in_scene(room_path: String) -> int:
	var text := FileAccess.get_file_as_string(room_path)
	var at := text.find("[node name=\"Player\"")
	if at < 0:
		return -1
	var next := text.find("\n[", at + 8)
	var block := text.substr(at, next - at if next > at else text.length() - at)
	var z_at := block.find("z_index")
	if z_at < 0:
		return -1
	var line := block.substr(z_at, 32)
	var eq := line.find("=")
	if eq < 0:
		return -1
	return int(line.substr(eq + 1).strip_edges().split("\n")[0])


func _check_outlines() -> void:
	var item: Node = load("res://scenes/world/ItemMarker.tscn").instantiate()
	var memory: Node = load("res://scenes/fx/MemoryIndicator.tscn").instantiate()
	root.add_child(item)
	root.add_child(memory)
	await process_frame
	var item_halo := item.get_node_or_null("RedHalo") as CanvasItem
	var mem_sprite := memory.get_node_or_null("AnimatedSprite") as CanvasItem
	var mem_halo := memory.get_node_or_null("Halo") as CanvasItem
	_assert_glow(item_halo, 12.0, Color(0.9, 0, 0, 1), "item")
	_assert_glow(mem_halo, 12.0, Color(1, 1, 1, 1), "memory halo")
	if mem_sprite == null or mem_sprite.modulate.r < 0.8 or mem_sprite.modulate.g > 0.05:
		_fail("memory sprite should be red")
	item.queue_free()
	memory.queue_free()


func _assert_glow(node: CanvasItem, spread: float, color: Color, where: String) -> void:
	if node == null or not node.material is ShaderMaterial:
		_fail("%s halo missing" % where)
		return
	var mat := node.material as ShaderMaterial
	var got_spread := float(mat.get_shader_parameter("spread"))
	if absf(got_spread - spread) > 0.01:
		_fail("%s spread %.2f should be %.2f" % [where, got_spread, spread])
	var got: Color = mat.get_shader_parameter("glow_color")
	if got.r < color.r - 0.05 or absf(got.g - color.g) > 0.05:
		_fail("%s glow color %s should be %s" % [where, got, color])


func _check_prompt_gaps() -> void:
	for room_path in GAP_ROOMS:
		if change_scene_to_file(room_path) != OK:
			_fail("could not load %s" % room_path)
			continue
		for _i in 24:
			await process_frame
		var scene := current_scene
		if scene == null:
			_fail("%s did not load" % room_path)
			continue
		var layer := scene.get_node_or_null("PlayerLayer")
		if layer == null:
			_fail("%s missing PlayerLayer" % room_path)
			continue
		var marker := load("res://scenes/world/ItemMarker.tscn").instantiate() as Node2D
		layer.add_child(marker)
		marker.position = Vector2(200, 200)
		for _j in 4:
			await process_frame
		var hand := marker.get_node_or_null("AnimatedSprite") as CanvasItem
		var prompt: Node = load("res://scenes/ui/InteractPromptOverlay.tscn").instantiate()
		scene.add_child(prompt)
		prompt.call("show_prompt_below_sprite_immediate", hand, 10.0)
		await process_frame
		var hand_rect: Rect2 = prompt.call("anchored_hand_screen_rect")
		var chip: Rect2 = prompt.call("chip_screen_rect")
		var gap := chip.position.y - hand_rect.end.y
		if absf(gap - 10.0) > 2.0:
			_fail("%s item chip gap %.2f should be 10" % [room_path, gap])
		var sprite := marker.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
		if sprite != null:
			var frame_h := 48.0 * absf(sprite.get_global_transform_with_canvas().get_scale().y)
			if hand_rect.size.y > frame_h * 0.7:
				_fail("%s item chip should sit under the visible hand, height %.1f frame %.1f" % [room_path, hand_rect.size.y, frame_h])
		if room_path == GAP_ROOMS[0]:
			_assert_glyph_on_ink(marker)
		scene.queue_free()
		await process_frame


func _assert_glyph_on_ink(marker: Node2D) -> void:
	if marker.has_method("set_rarity_glyph"):
		marker.call("set_rarity_glyph", "◇")
	var glyph := marker.get_node_or_null("RarityGlyph") as Label
	if glyph == null or not marker.has_method("ink_local_rect"):
		_fail("rarity glyph missing")
		return
	var ink: Rect2 = marker.call("ink_local_rect")
	var half := Vector2(float(marker.get("frame_width")), float(marker.get("frame_height"))) * 0.5
	var corner := Vector2(ink.end.x - half.x, ink.position.y - half.y)
	var s := maxf(absf(marker.scale.x), 0.001)
	var glyph_h := glyph.size.y / s
	if glyph_h < 0.1:
		glyph_h = glyph.get_combined_minimum_size().y / s
	var marker_script := load("res://scenes/world/item_marker.gd") as GDScript
	var overlap := float(marker_script.get_script_constant_map()["GLYPH_OVERLAP_PX"])
	var want := Vector2(corner.x - overlap / s, corner.y + overlap / s - glyph_h)
	if glyph.position.distance_to(want) > 1.0:
		_fail("rarity glyph %s should sit on the hand corner %s" % [glyph.position, want])


func _check_grime() -> void:
	var host := Node2D.new()
	var grid := Control.new()
	grid.size = Vector2(400, 300)
	root.add_child(host)
	host.add_child(grid)
	var feel: Node = load("res://combat/scripts/combat_feel.gd").new()
	host.add_child(feel)
	feel.call("setup", host, grid)
	feel.call("set_goal_progress", 1.0)
	var band := host.find_child("FeelGrimeBand", true, false) as ColorRect
	if band == null:
		_fail("FeelGrimeBand missing")
	elif band.color.a > 0.001 or band.size.y > 0.001:
		_fail("goal band should stay invisible, alpha %.3f height %.1f" % [band.color.a, band.size.y])
	host.queue_free()


func _check_goal_round() -> void:
	var combat: Node = load("res://combat/scripts/combat_root.gd").new()
	combat.set("_encounter_goal_base_target_cents", 800)
	combat.call("set_lore_goal_bonus", 0.0775)
	var got := int(combat.call("get_effective_goal_target_cents"))
	if got != 875:
		_fail("goal 862 should round up to 875, got %d" % got)
	combat.set("_encounter_goal_base_target_cents", 225)
	combat.call("set_lore_goal_bonus", 0.0)
	if int(combat.call("get_effective_goal_target_cents")) != 225:
		_fail("goal 225 should stay 225")
	combat.set("_encounter_goal_base_target_cents", 10000)
	if int(combat.call("get_effective_goal_target_cents")) != 10000:
		_fail("goal 10000 should stay 10000")
	combat.free()


func _check_wild_halo() -> void:
	var src := FileAccess.get_file_as_string("res://combat/art/generate_placeholders.py")
	var at := src.find("PREMIUM_FILES")
	var tail := src.substr(at, 80) if at >= 0 else ""
	if tail.contains("satanic_wild.png"):
		_fail("generator must not halo satanic_wild.png")
	var img := Image.new()
	if img.load(ProjectSettings.globalize_path("res://combat/art/grid_symbols/satanic_wild.png")) != OK:
		_fail("could not load satanic_wild.png")
		return
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			var r := int(round(px.r * 255.0))
			var g := int(round(px.g * 255.0))
			var b := int(round(px.b * 255.0))
			var a := int(round(px.a * 255.0))
			if r == 96 and g == 96 and b == 96 and a == 255:
				_fail("satanic_wild.png still has the white halo")
				return


func _check_options_theme() -> void:
	var panel: Node = load("res://scenes/ui/options_panel.gd").new()
	root.add_child(panel)
	if not panel.is_node_ready():
		await panel.ready
	await process_frame
	var slider := panel.find_child("*", true, false) as HSlider
	var sliders := panel.find_children("*", "HSlider", true, false)
	if sliders.is_empty():
		_fail("options panel has no slider")
	else:
		slider = sliders[0] as HSlider
		var grab := slider.get_theme_icon("grabber")
		if grab == null:
			_fail("slider grabber missing")
		else:
			var img := grab.get_image()
			var px := img.get_pixel(1, 1)
			if px.r < 0.7 or px.g > 0.2:
				_fail("slider grabber should be red")
		var font := slider.get_theme_font("font")
		if font == null or not str(font.resource_path).contains("VT323"):
			_fail("slider should use VT323")
	var scroll := panel.find_child("*", true, false) as ScrollContainer
	var scrolls := panel.find_children("*", "ScrollContainer", true, false)
	if scrolls.is_empty() or (scrolls[0] as ScrollContainer).theme == null:
		_fail("options scroll theme missing")
	else:
		var theme := (scrolls[0] as ScrollContainer).theme
		var grabber := theme.get_stylebox("grabber", "VScrollBar") as StyleBoxFlat
		if grabber == null or grabber.bg_color.r < 0.7:
			_fail("scrollbar grabber should be red")
		if theme.default_font == null or not str(theme.default_font.resource_path).contains("VT323"):
			_fail("scrollbar theme should use VT323")
	panel.queue_free()


func _check_item_rows() -> void:
	var defs: Script = load("res://combat/scripts/item_def.gd")
	var fx: RefCounted = load("res://combat/scripts/item_effect_dispatcher.gd").new()
	var refund: Resource = defs.new()
	refund.set("id", &"C10")
	refund.set("effect_id", &"first_paid_spin_refund")
	refund.set("effect_params", {"amount": 0.25})
	refund.set("display_name", "Tarnished Coin")
	var amount := float(fx.call("first_paid_spin_refund", [refund]))
	if amount <= 0.0:
		_fail("refund mock should pay")
	else:
		fx.call("note_effect", [refund], &"first_paid_spin_refund")
	var refund_ids: Array = fx.call("drain_procs")
	if refund_ids.size() != 1 or refund_ids[0] != &"C10":
		_fail("first paid refund should proc once, got %s" % str(refund_ids))
	var bonus: Resource = defs.new()
	bonus.set("id", &"C2")
	bonus.set("display_name", "Chalk Dust")
	bonus.set("description", "Normal bonus")
	bonus.set("effect_id", &"normal_payout_bonus")
	bonus.set("effect_params", {"amount": 0.1})
	fx.call("line_payout_bonus", [bonus], 0, &"", false, true)
	fx.call("line_payout_bonus", [bonus], 0, &"", false, true)
	var bonus_ids: Array = fx.call("drain_procs")
	if bonus_ids.size() != 2 or bonus_ids[0] != &"C2" or bonus_ids[1] != &"C2":
		_fail("line bonus should proc once per winning line, got %s" % str(bonus_ids))
	fx.call("line_payout_bonus", [bonus], 0, &"", false, false)
	var preview: Array = fx.call("drain_procs")
	if not preview.is_empty():
		_fail("preview payout must not proc an item")
	var goal_item: Resource = defs.new()
	goal_item.set("id", &"C-H")
	goal_item.set("effect_id", &"true_path_goal")
	goal_item.set("effect_params", {"goal_percent": 0.08})
	fx.call("note_paid_spin_passives", [goal_item])
	var goal_procs: Array = fx.call("drain_procs")
	if not goal_procs.is_empty():
		_fail("goal-percent items must not pulse on a spin")
	var panel: Node = load("res://combat/scripts/player_item_panel.gd").new()
	root.add_child(panel)
	if not panel.is_node_ready():
		await panel.ready
	(panel as Control).size = Vector2(640, 400)
	panel.call("set_equipped_items", [bonus])
	for _i in 3:
		await process_frame
	var icon := _icon_of(panel)
	if icon == null:
		_fail("item row icon missing")
		panel.queue_free()
		return
	var before := icon.global_position
	var name_lab := _named_label(panel)
	var desc_panel := _desc_panel(panel)
	if name_lab == null or desc_panel == null:
		_fail("item description panel missing")
	else:
		panel.call("_show_row_desc", desc_panel, name_lab)
		await process_frame
		if icon.global_position.distance_to(before) > 0.5:
			_fail("hovering the item name moved the icon")
		var style := desc_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null or style.bg_color.a < 0.2 or style.bg_color.r < 0.15:
			_fail("item description should have a faint dark red background")
		if desc_panel.size.x > name_lab.size.x - 40.0:
			_fail(
				"short description box should end after the text, width %.1f name %.1f"
				% [desc_panel.size.x, name_lab.size.x]
			)
		if desc_panel.position.y >= name_lab.size.y - 1.0:
			_fail("description should sit under the title letters, y %.1f" % desc_panel.position.y)
		var longer: Resource = defs.new()
		longer.set("id", &"C3")
		longer.set("display_name", "Locker Tape")
		longer.set("description", "Regular spins only: skip top refill; payout bonus +12%. Does not apply in Vice Round or Free Spins")
		longer.set("effect_id", &"normal_payout_bonus")
		longer.set("effect_params", {"amount": 0.12})
		panel.call("set_equipped_items", [bonus, longer])
		for _k in 3:
			await process_frame
		var boxes: Array[PanelContainer] = []
		for node in panel.find_children("*", "PanelContainer", true, false):
			if bool(node.get_meta("item_row_desc_panel", false)):
				boxes.append(node as PanelContainer)
		if boxes.size() < 2:
			_fail("expected two description boxes")
		elif absf(boxes[0].size.x - boxes[1].size.x) > 1.0:
			_fail(
				"description boxes should share one width, got %.1f and %.1f"
				% [boxes[0].size.x, boxes[1].size.x]
			)
	panel.call("pulse_item", "C2")
	panel.call("pulse_item", "C2")
	if int(panel.call("pulse_play_count", "C2")) != 2:
		_fail("item icon should pulse on every proc")
	panel.queue_free()


func _icon_of(panel: Node) -> TextureRect:
	for node in panel.find_children("*", "TextureRect", true, false):
		if bool(node.get_meta("item_row_icon", false)):
			return node as TextureRect
	return null


func _named_label(panel: Node) -> Label:
	for node in panel.find_children("*", "Label", true, false):
		if bool(node.get_meta("item_row_name", false)):
			return node as Label
	return null


func _desc_panel(panel: Node) -> PanelContainer:
	for node in panel.find_children("*", "PanelContainer", true, false):
		if bool(node.get_meta("item_row_desc_panel", false)):
			return node as PanelContainer
	return null


func _check_hud_white() -> void:
	var ui: Node = load("res://combat/scripts/combat_test.gd").new()
	var winnings := Label.new()
	ui.set("mult_label", winnings)
	ui.call("_configure_winnings_readout")
	if winnings.get_theme_color("font_color") != Color.WHITE:
		_fail("round winnings should be white")
	var mult := Label.new()
	ui.set("_cascade_mult_label", mult)
	ui.call("_configure_cascade_multiplier_readout")
	if mult.get_theme_color("font_color") != Color.WHITE:
		_fail("multiplier should be white")
	var row := HBoxContainer.new()
	var selected := Label.new()
	var other := Label.new()
	var labels: Array[Label] = []
	labels.append(selected)
	labels.append(other)
	ui.set("_bet_strip_row", row)
	ui.set("_bet_strip_labels", labels)
	ui.call("_refresh_bet_strip")
	var live: Array = ui.get("_bet_strip_labels")
	if live.size() < 2:
		_fail("bet strip did not keep its labels")
		ui.free()
		return
	var selected_lab := live[0] as Label
	var other_lab := live[1] as Label
	if selected_lab.get_theme_color("font_color") != Color.WHITE:
		_fail("selected bet should be white")
	if other_lab.get_theme_color("font_color") == Color.WHITE:
		_fail("unselected bet should stay grey")
	ui.free()


func _check_combat_music() -> void:
	var music := root.get_node_or_null("AxelMusic")
	if music == null:
		_fail("AxelMusic missing")
		return
	var room_player := music.get("_player") as AudioStreamPlayer
	if room_player == null or not room_player.playing:
		_fail("room music should be playing before combat")
		return
	music.call("to_combat")
	if not room_player.playing:
		_fail("room music should keep playing into combat")
	if _sync_volume_db(music, 3) > -40.0:
		_fail("drums 2 should start silent")
	music.call("notify_trinity")
	await create_timer(0.7).timeout
	if _sync_volume_db(music, 3) < -6.0:
		_fail("vice round should fade drums 2 in")
	music.call("notify_trinity_ended", true)
	await create_timer(0.7).timeout
	if _sync_volume_db(music, 3) < -6.0:
		_fail("drums 2 should stay up when vice leads into free spins")
	music.call("notify_free_spins_ended")
	await create_timer(0.7).timeout
	if _sync_volume_db(music, 3) > -40.0:
		_fail("drums 2 should fade out when free spins end")
	if not room_player.playing:
		_fail("room music stopped during the vice fades")
	music.call("to_overworld")
	await process_frame
	if not room_player.playing:
		_fail("leaving combat should keep the room song playing")


func _sync_volume_db(music: Node, index: int) -> float:
	var sync: AudioStreamSynchronized = music.get("_sync_stream")
	if sync == null:
		return -80.0
	return sync.get_sync_stream_volume(index)
