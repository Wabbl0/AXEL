extends CanvasLayer

const MAP_SCENE := "res://scenes/Arc_1/1.3_SchoolMap.tscn"
const TITLE_SCENE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const MENU_LAYER := 250

var _root: Control
var _menu: VBoxContainer
var _options: OptionsPanel
var _guide: GuidePanel
var _guide_button: Button
var _map_button: Button
var _dev_button: Button
var _seed_label: Label


func _ready() -> void:
	layer = MENU_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func show_menu() -> void:
	_show_main()
	visible = true
	_refresh_map()
	_refresh_seed()
	_refresh_dev_tools()
	_refresh_guide()
	MenuLook.grab_first_focus(_menu)


func hide_menu() -> void:
	visible = false


func is_submenu_open() -> bool:
	if _dev_tools_open():
		return true
	if _guide != null and _guide.visible:
		return true
	return _options != null and _options.visible


func close_submenu() -> bool:
	if _close_dev_tools():
		return true
	if is_submenu_open():
		_show_main()
		return true
	return false


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var scrim := ColorRect.new()
	scrim.color = Color(0.0, 0.0, 0.0, 0.72)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(scrim)

	var host := CenterContainer.new()
	host.name = "PauseCenter"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_menu = VBoxContainer.new()
	_menu.name = "PauseColumn"
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_menu.add_theme_constant_override("separation", 8)
	host.add_child(_menu)

	var title := Label.new()
	title.name = "PausedTitle"
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(title, 64, MenuLook.ACCENT)
	_menu.add_child(title)

	_add_menu_button("Resume", func() -> void: AxelPause.request_unpause())
	_add_menu_button("Options", _open_options)
	_guide_button = _add_menu_button("Guide", _open_guide)
	_guide_button.name = "GuideButton"
	_dev_button = _add_menu_button("Dev Tools", _open_dev_tools)
	_dev_button.name = "DevToolsButton"
	_map_button = _add_menu_button("Map", _open_map)
	_add_menu_button("Quit to Title", _quit_title)
	_add_menu_button("Quit to Desktop", _quit_desktop)

	_seed_label = Label.new()
	_seed_label.name = "SeedLabel"
	_seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_seed_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_seed_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_seed_label.offset_left = -360
	_seed_label.offset_top = -48
	_seed_label.offset_right = -16
	_seed_label.offset_bottom = -16
	_seed_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuLook.apply_label(_seed_label, 22, MenuLook.DIM)
	_seed_label.visible = false
	_root.add_child(_seed_label)

	_options = OptionsPanel.new()
	_options.visible = false
	_options.closed.connect(_show_main)
	_root.add_child(_options)

	_guide = GuidePanel.new()
	_guide.name = "GuidePanel"
	_guide.visible = false
	_guide.closed.connect(_show_main)
	_root.add_child(_guide)


func _add_menu_button(caption: String, cb: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	MenuLook.apply_button(button, 32)
	button.pressed.connect(cb)
	_menu.add_child(button)
	return button


func _show_main() -> void:
	_menu.visible = true
	if _options != null:
		_options.visible = false
	if _guide != null:
		_guide.visible = false
	_refresh_map()
	_refresh_dev_tools()
	_refresh_guide()
	if visible:
		MenuLook.grab_first_focus(_menu)


func _open_options() -> void:
	_menu.visible = false
	_options.visible = true
	MenuLook.grab_first_focus(_options)


func open_guide() -> bool:
	if not _guide_unlocked():
		return false
	_open_guide()
	return true


func is_guide_open() -> bool:
	return _guide != null and _guide.visible


func _open_guide() -> void:
	if not _guide_unlocked():
		return
	_menu.visible = false
	_guide.open()
	var tutorial := get_node_or_null("/root/AxelTutorial")
	if tutorial != null and tutorial.has_method("complete"):
		tutorial.call("complete", "guide_pause")


func _guide_unlocked() -> bool:
	var profile := get_node_or_null("/root/AxelProfile")
	return profile != null and bool(profile.call("is_guide_unlocked"))


func _refresh_guide() -> void:
	if _guide_button != null:
		_guide_button.visible = _guide_unlocked()


func _open_map() -> void:
	if not AxelSaves.has_map() or _is_mid_encounter():
		return
	var scene := get_tree().current_scene
	if scene != null:
		var env: Node2D = null
		if scene.has_method("env_colliders"):
			env = scene.call("env_colliders") as Node2D
		if env == null:
			env = scene.get_node_or_null("WalkableWorld/EnvironmentColliders") as Node2D
		var player := scene.find_child("Player", true, false) as Node2D
		if env != null and player != null:
			GameManager.set_pause_map_return(
				scene.scene_file_path, env.to_local(player.global_position)
			)
		else:
			GameManager.pause_map_return_path = scene.scene_file_path
			GameManager.pause_map_return_tex = GameManager.INVALID_RETURN_POS
	AxelPause.request_unpause()
	get_tree().change_scene_to_file(MAP_SCENE)


func _quit_title() -> void:
	if _is_mid_encounter():
		AxelPause.request_unpause()
		var run := get_node_or_null("/root/AxelRun")
		if run != null:
			run.call("abort_encounter_as_loss")
		return
	AxelSaves.deactivate()
	AxelPause.request_unpause()
	get_tree().change_scene_to_file(TITLE_SCENE)


func _quit_desktop() -> void:
	if _is_mid_encounter():
		var run := get_node_or_null("/root/AxelRun")
		if run != null:
			run.call("write_tombstone_only")
		AxelPause.request_unpause()
		get_tree().quit()
		return
	AxelSaves.save_active_now()
	get_tree().quit()


func _is_mid_encounter() -> bool:
	var run := get_node_or_null("/root/AxelRun")
	return run != null and bool(run.call("is_in_encounter"))


func _refresh_map() -> void:
	if _map_button != null:
		_map_button.disabled = not AxelSaves.has_map() or _is_mid_encounter()


func _refresh_dev_tools() -> void:
	if _dev_button == null:
		return
	_dev_button.visible = OS.is_debug_build()


func _open_dev_tools() -> void:
	if not OS.is_debug_build():
		return
	var tools := get_node_or_null("/root/AxelCombatDevTools")
	if tools != null and tools.has_method("open_dev_menu"):
		tools.call("open_dev_menu")


func _dev_tools_open() -> bool:
	var tools := get_node_or_null("/root/AxelCombatDevTools")
	if tools != null and tools.has_method("is_menu_open"):
		return bool(tools.call("is_menu_open"))
	return false


func _close_dev_tools() -> bool:
	if not _dev_tools_open():
		return false
	var tools := get_node_or_null("/root/AxelCombatDevTools")
	if tools != null and tools.has_method("toggle_dev_menu"):
		tools.call("toggle_dev_menu")
		return true
	return false


func _refresh_seed() -> void:
	if _seed_label == null:
		return
	var run := get_node_or_null("/root/AxelRun")
	var seed_n := 0
	if run != null:
		seed_n = int(run.state.seed)
	_seed_label.visible = seed_n != 0
	if seed_n != 0:
		_seed_label.text = "SEED %d" % seed_n
