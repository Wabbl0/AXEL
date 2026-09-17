extends CanvasLayer

const MAP_SCENE := "res://scenes/Arc_1/1.3_SchoolMap.tscn"
const TITLE_SCENE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"

var _root: Control
var _menu: VBoxContainer
var _options: OptionsPanel
var _inventory: VBoxContainer
var _map_button: Button


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func show_menu() -> void:
	_show_main()
	visible = true
	_refresh_map()


func hide_menu() -> void:
	visible = false
	_listening_clear()


func is_submenu_open() -> bool:
	return (_options != null and _options.visible) or (_inventory != null and _inventory.visible)


func close_submenu() -> bool:
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
	_add_menu_button("Inventory", _open_inventory)
	_map_button = _add_menu_button("Map", _open_map)
	_add_menu_button("Quit to Title", _quit_title)
	_add_menu_button("Quit to Desktop", _quit_desktop)

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


func _open_options() -> void:
	_menu.visible = false
	_inventory.visible = false
	_options.visible = true


func _open_inventory() -> void:
	_menu.visible = false
	_options.visible = false
	_fill_inventory()
	_inventory.visible = true


func _fill_inventory() -> void:
	for child in _inventory.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(title, 40, MenuLook.ACCENT)
	_inventory.add_child(title)
	for pair in [
		["Flashlight", GameManager.get_flag("hasFlashlight")],
		["Key", GameManager.get_flag("hasKey")],
		["Shovel", GameManager.get_flag("hasShovel")],
		["Name", GameManager.get_flag("hasName")],
	]:
		var line := Label.new()
		var owned := bool(pair[1])
		line.text = "%s  —  %s" % [pair[0], "held" if owned else "missing"]
		MenuLook.apply_label(line, 28, MenuLook.TEXT if owned else MenuLook.DIM)
		_inventory.add_child(line)
	var mem := Label.new()
	mem.text = "Memories  %d / 5" % int(GameManager.game_state.get("memories", 0))
	MenuLook.apply_label(mem, 28, MenuLook.TEXT)
	_inventory.add_child(mem)
	var back := Button.new()
	back.text = "Back"
	MenuLook.apply_button(back, 28)
	back.pressed.connect(_show_main)
	_inventory.add_child(back)


func _open_map() -> void:
	if not AxelSaves.has_map() or _is_mid_encounter():
		return
	var scene := get_tree().current_scene
	if scene != null:
		GameManager.pause_map_return_path = scene.scene_file_path
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


func _listening_clear() -> void:
	if _options != null:
		_options._listening_action = ""
