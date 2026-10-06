extends SceneTree

const _ROOM := "res://scenes/Arc_1/1.2_Corridor.tscn"
const _ITEM_DIR := "res://combat/data/items/"
const _TMP_PROFILE := "user://axel_profile_qa_tmp.cfg"

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

	var pause := root.get_node_or_null("AxelPause")
	var profile := root.get_node_or_null("AxelProfile")
	if pause == null or profile == null:
		push_error("guide_panel_check: AxelPause or AxelProfile autoload missing")
		quit(1)
		return
	profile.call("debug_use_memory_only")

	_check_profile_file(profile)
	profile.call("debug_use_memory_only")
	_check_merge(profile)
	profile.call("debug_use_memory_only")
	_check_tutorial_cross_save(profile)
	profile.call("debug_use_memory_only")

	if change_scene_to_file(_ROOM) != OK:
		_fail("could not load 1.2 corridor")
	else:
		for _i in 10:
			await process_frame
		var overlay := current_scene.get_node_or_null("TopDialogueOverlay")
		if overlay != null and overlay.has_method("interrupt_line"):
			overlay.call("interrupt_line")
		for _i in 4:
			await process_frame
		await _check_menu(pause, profile)

	if _failures.is_empty():
		print("Guide panel check OK.")
		quit(0)
	else:
		for f in _failures:
			push_error("guide_panel_check: %s" % f)
		quit(1)


func _check_menu(pause: Node, profile: Node) -> void:
	if not bool(pause.call("request_pause")):
		_fail("pause refused in 1.2")
		return
	await process_frame
	var menu := root.get_node_or_null("AxelPause/AxelPauseMenu")
	var button := menu.find_child("GuideButton", true, false) as Button if menu != null else null
	var guide := menu.find_child("GuidePanel", true, false) as GuidePanel if menu != null else null
	var column := menu.find_child("PauseColumn", true, false) as Control if menu != null else null
	if button == null or guide == null or column == null:
		_fail("GuideButton, GuidePanel or PauseColumn missing")
		pause.call("request_unpause")
		return
	if button.visible:
		_fail("GuideButton should be hidden before the first fight")
	pause.call("request_unpause")
	await process_frame

	profile.call("unlock_guide")
	pause.call("request_pause")
	await process_frame
	if not button.visible:
		_fail("GuideButton should show once the guide is unlocked")

	button.emit_signal("pressed")
	for _i in 3:
		await process_frame
	if not guide.visible or column.visible:
		_fail("Guide did not replace the pause column")
	var focus := root.gui_get_focus_owner()
	if focus == null or not guide.is_ancestor_of(focus):
		_fail("Guide did not grab focus on a live control")

	guide.show_page(0)
	guide.next_page()
	if guide.current_page() != 1:
		_fail("Next did not flip to page 2")
	guide.prev_page()
	if guide.current_page() != 0:
		_fail("Prev did not flip back to page 1")
	for page_i in guide.page_count():
		guide.show_page(page_i)
		if guide.page_body_text().strip_edges().is_empty():
			_fail("page %d has no body text" % page_i)
		if guide.page_body_text().contains("{"):
			_fail("page %d has an unfilled placeholder" % page_i)

	var fs_index := _page_index(GuidePages.KIND_FREE_SPINS)
	guide.show_page(fs_index)
	if not guide.page_title_text().contains("???"):
		_fail("Free Spins page should be ??? before Free Spins were reached")
	profile.call("mark_free_spins_seen")
	guide.show_page(fs_index)
	if not guide.page_title_text().contains("Free Spins"):
		_fail("Free Spins page should open after Free Spins were reached")

	var comp_index := _page_index(GuidePages.KIND_COMPENDIUM)
	guide.show_page(comp_index)
	var entries := guide.compendium_entries()
	var expected := _item_count()
	if entries.size() != expected:
		_fail("compendium shows %d entries, expected %d" % [entries.size(), expected])
	for entry in entries:
		if bool(entry.get_meta("found", false)):
			_fail("compendium entry %s should start greyed" % entry.name)
			break
	if not entries.is_empty():
		var first_id := String(entries[0].get_meta("item_id", ""))
		profile.call("mark_item_found", first_id)
		guide.show_page(comp_index)
		var found := 0
		for entry in guide.compendium_entries():
			if bool(entry.get_meta("found", false)):
				found += 1
				if entry.get_theme_color("icon_normal_color") != Color.WHITE:
					_fail("found entry is not full color")
		if found != 1:
			_fail("expected 1 found compendium entry, got %d" % found)
		await process_frame
		for entry in guide.compendium_entries():
			if entry.size.x > 120.0:
				_fail("compendium entry too wide: %s" % entry.size)
				break

	var scroll := guide.find_child("GuideScroll", true, false) as Control
	if scroll != null and scroll.get_global_rect().end.x > float(root.size.x):
		_fail("guide scroll runs off the window")

	if not bool(menu.call("close_submenu")):
		_fail("close_submenu did not close the guide")
	if guide.visible or not column.visible:
		_fail("Back did not return to the pause column")
	pause.call("request_unpause")
	await process_frame


func _check_profile_file(profile: Node) -> void:
	var abs_path := ProjectSettings.globalize_path(_TMP_PROFILE)
	if FileAccess.file_exists(_TMP_PROFILE):
		DirAccess.remove_absolute(abs_path)
	profile.set("_path", _TMP_PROFILE)
	profile.call("reset_profile")
	profile.call("unlock_guide")
	profile.call("mark_item_found", "C1")
	profile.call("mark_tutorial_seen", "move_walk")
	var cfg := ConfigFile.new()
	if cfg.load(_TMP_PROFILE) != OK:
		_fail("profile file was not written")
	else:
		if not bool(cfg.get_value("profile", "guide_unlocked", false)):
			_fail("guide_unlocked not saved")
		if not PackedStringArray(cfg.get_value("profile", "items_found", [])).has("C1"):
			_fail("items_found not saved")
		if not PackedStringArray(cfg.get_value("profile", "tutorials_seen", [])).has("move_walk"):
			_fail("tutorials_seen not saved")
	profile.call("_load")
	if not bool(profile.call("has_found_item", "C1")):
		_fail("profile did not reload items_found")
	DirAccess.remove_absolute(abs_path)


func _check_merge(profile: Node) -> void:
	var state := RunState.new()
	state.owned_item_ids = PackedStringArray(["C2"])
	state.tutorial_seen = PackedStringArray(["items_wheel"])
	state.tutorial_fight_done = true
	profile.call("merge_from_run", state)
	if not bool(profile.call("is_guide_unlocked")):
		_fail("merge_from_run did not unlock the guide")
	if not bool(profile.call("has_found_item", "C2")):
		_fail("merge_from_run did not copy owned items")
	if not bool(profile.call("has_seen_tutorial", "items_wheel")):
		_fail("merge_from_run did not copy tutorials")


func _check_tutorial_cross_save(profile: Node) -> void:
	var tutorial := root.get_node_or_null("AxelTutorial")
	var run := root.get_node_or_null("AxelRun")
	if tutorial == null or run == null:
		_fail("AxelTutorial or AxelRun missing")
		return
	profile.call("mark_tutorial_seen", "slot_vice")
	run.set("state", RunState.new())
	if not bool(tutorial.call("_is_seen", "slot_vice")):
		_fail("a tutorial seen on the profile should stay seen in a new save")
	if bool(tutorial.call("_is_seen", "slot_power")):
		_fail("an unseen tutorial should still show in a new save")


func _page_index(kind: String) -> int:
	for i in GuidePages.PAGES.size():
		if String(GuidePages.PAGES[i].get("kind", "")) == kind:
			return i
	return -1


func _item_count() -> int:
	var n := 0
	for fname in ResourceLoader.list_directory(_ITEM_DIR):
		if fname.ends_with(".tres"):
			var res := load(_ITEM_DIR + fname)
			if res != null and not String(res.get("id")).is_empty():
				n += 1
	return n
