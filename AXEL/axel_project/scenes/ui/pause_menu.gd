extends CanvasLayer

const MAP_SCENE := "res://scenes/Arc_1/1.3_SchoolMap.tscn"
const TITLE_SCENE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"

var _root: Control
var _menu: VBoxContainer
var _options: OptionsPanel
var _inventory: VBoxContainer
var _map_button: Button
var _dev_button: Button
var _seed_label: Label


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func show_menu() -> void:
	_show_main()
	visible = true
	_refresh_map()
	_refresh_seed()
	_refresh_dev_tools()
	MenuLook.grab_first_focus(_menu)


func hide_menu() -> void:
	visible = false
	_listening_clear()


func is_submenu_open() -> bool:
	if _dev_tools_open():
		return true
	return (_options != null and _options.visible) or (_inventory != null and _inventory.visible)


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

	_menu = VBoxContainer.new()
	_menu.set_anchors_preset(Control.PRESET_CENTER)
	_menu.offset_left = -220
	_menu.offset_right = 220
	_menu.offset_top = -220
	_menu.offset_bottom = 220
	_menu.add_theme_constant_override("separation", 8)
	_root.add_child(_menu)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(title, 64, MenuLook.ACCENT)
	_menu.add_child(title)

	_add_menu_button("Resume", func() -> void: AxelPause.request_unpause())
	_add_menu_button("Options", _open_options)
	_dev_button = _add_menu_button("Dev Tools", _open_dev_tools)
	_dev_button.name = "DevToolsButton"
	_add_menu_button("Inventory", _open_inventory)
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

	_inventory = VBoxContainer.new()
	_inventory.visible = false
	_inventory.set_anchors_preset(Control.PRESET_CENTER)
	_inventory.offset_left = -260
	_inventory.offset_right = 260
	_inventory.offset_top = -180
	_inventory.offset_bottom = 180
	_inventory.add_theme_constant_override("separation", 10)
	_root.add_child(_inventory)


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
	if _inventory != null:
		_inventory.visible = false
	_refresh_map()
	_refresh_dev_tools()
	if visible:
		MenuLook.grab_first_focus(_menu)


func _open_options() -> void:
	_menu.visible = false
	_inventory.visible = false
	_options.visible = true
	MenuLook.grab_first_focus(_options)


func _open_inventory() -> void:
	_menu.visible = false
	_options.visible = false
	_fill_inventory()
	_inventory.visible = true
	MenuLook.grab_first_focus(_inventory)


func _fill_inventory() -> void:
	for child in _inventory.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(title, 40, MenuLook.ACCENT)
	_inventory.add_child(title)
	var seen: Dictionary = {}
	var run := get_node_or_null("/root/AxelRun")
	if run != null and run.has_method("owned_items"):
		for item in run.call("owned_items"):
			if item == null:
				continue
			var item_name := str(item.get("display_name")).strip_edges()
			if item_name.is_empty() or seen.has(item_name):
				continue
			seen[item_name] = true
			_inventory.add_child(_make_owned_row(item_name, item.get("icon") as Texture2D))
	var lore = GameManager.game_state.get("inventory", [])
	if lore is Array:
		for lore_name in lore:
			var shown := str(lore_name).strip_edges()
			if shown.is_empty() or seen.has(shown):
				continue
			seen[shown] = true
			_inventory.add_child(_make_owned_row(shown, null))
	var back := Button.new()
	back.text = "Back"
	MenuLook.apply_button(back, 28)
	back.pressed.connect(_show_main)
	_inventory.add_child(back)


func _make_owned_row(item_name: String, icon_tex: Texture2D) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(LockerShelfRow.ICON_PX, LockerShelfRow.ICON_PX)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = icon_tex
		row.add_child(icon)
	var line := Label.new()
	line.text = item_name
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuLook.apply_label(line, 28, MenuLook.TEXT)
	row.add_child(line)
	return row


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
	_dev_button.visible = OS.is_debug_build() and _is_combat_scene()


func _is_combat_scene() -> bool:
	var scene := get_tree().current_scene if get_tree() != null else null
	if scene == null:
		return false
	var path := String(scene.scene_file_path)
	return path.begins_with("res://combat/")


func _open_dev_tools() -> void:
	if not OS.is_debug_build() or not _is_combat_scene():
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


func _listening_clear() -> void:
	if _options != null:
		_options._listening_action = ""
