extends CanvasLayer

const VT323_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const LAYER := 2100
const MENU_MIN_WIDTH := 300.0
const BANKROLL_STEP := 100
const GOAL_STEP := 1000
const PANEL_BG := Color(0.06, 0.0, 0.0, 0.92)
const PANEL_BORDER := Color(0.78, 0.03, 0.03, 0.95)
const ACCENT := Color(0.98, 0.35, 0.35, 1.0)
const TEXT_COLOR := Color(0.92, 0.88, 0.88, 1.0)

var _root: Control
var _menu: PanelContainer
var _menu_open: bool = false
var _combat: Node = null
var _row_labels: Dictionary = {}
var _outside_blocker: Control


func _ready() -> void:
	if not OS.is_debug_build():
		process_mode = Node.PROCESS_MODE_DISABLED
		set_process(false)
		set_process_input(false)
		visible = false
		return

	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	set_process(true)
	set_process_unhandled_input(true)

	_build_ui()
	var tree := get_tree()
	if tree != null:
		tree.scene_changed.connect(_on_scene_changed)
	call_deferred("_refresh_combat_binding")


func _exit_tree() -> void:
	var tree := get_tree()
	if tree != null and tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.disconnect(_on_scene_changed)
	_unbind_combat()


func _process(_delta: float) -> void:
	if not OS.is_debug_build():
		return
	_update_visibility_for_scene()


func _on_scene_changed() -> void:
	_close_menu()
	call_deferred("_refresh_combat_binding")


func _is_combat_scene() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var scene := tree.current_scene
	if scene == null:
		return false
	var path := String(scene.scene_file_path)
	return path.begins_with("res://combat/")


func _update_visibility_for_scene() -> void:
	if _root != null:
		_root.visible = true
	if not _is_combat_scene() and _combat != null:
		_unbind_combat()


func _refresh_combat_binding() -> void:
	if not OS.is_debug_build() or not _is_combat_scene():
		_unbind_combat()
		_update_visibility_for_scene()
		return
	var tree := get_tree()
	if tree == null:
		return
	var found: Node = null
	var nodes := tree.get_nodes_in_group("combat_root")
	if not nodes.is_empty():
		found = nodes[0]
	if found == null and tree.current_scene != null:
		found = tree.current_scene.find_child("CombatRoot", true, false)
	if found == _combat:
		_refresh_economy_labels()
		_refresh_toggle_labels()
		return
	_unbind_combat()
	_combat = found
	if _combat != null and _combat.has_signal("readouts_progressed"):
		_combat.readouts_progressed.connect(_on_combat_readouts)
	_refresh_economy_labels()
	_refresh_toggle_labels()
	_update_visibility_for_scene()


func _unbind_combat() -> void:
	if _combat != null and is_instance_valid(_combat):
		if _combat.has_signal("readouts_progressed") and _combat.readouts_progressed.is_connected(_on_combat_readouts):
			_combat.readouts_progressed.disconnect(_on_combat_readouts)
	_combat = null


func _on_combat_readouts() -> void:
	_refresh_economy_labels()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "CombatDevToolsRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_outside_blocker = Control.new()
	_outside_blocker.name = "OutsideBlocker"
	_outside_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_outside_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_outside_blocker.visible = false
	_outside_blocker.gui_input.connect(_on_outside_gui_input)
	_root.add_child(_outside_blocker)

	_menu = PanelContainer.new()
	_menu.name = "DevMenu"
	_menu.visible = false
	_menu.position = Vector2(8, 8)
	_menu.custom_minimum_size = Vector2(MENU_MIN_WIDTH, 0)
	_menu.add_theme_stylebox_override("panel", _panel_style())
	_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_menu)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_menu.add_child(vbox)

	_add_section_label(vbox, "WORLD")
	_add_toggle_row(vbox, "encounters", "Disable combat encounters")
	vbox.add_child(HSeparator.new())

	_add_section_label(vbox, "GUARANTEES")
	_add_toggle_row(vbox, "trinity", "Guarantee Vice Round")
	_add_toggle_row(vbox, "fs_clear", "Guarantee Free Spins")
	_add_toggle_row(vbox, "payout_1000x", "Guarantee 1000x Payout")
	vbox.add_child(HSeparator.new())

	_add_section_label(vbox, "ECONOMY")
	_add_economy_row(vbox, "bankroll", "Bankroll", BANKROLL_STEP)
	_add_economy_row(vbox, "goal_base", "Goal Base", GOAL_STEP)
	_add_economy_row(vbox, "goal_progress", "Goal Progress", GOAL_STEP)
	vbox.add_child(HSeparator.new())

	var skip_btn := Button.new()
	skip_btn.text = "Skip current spin"
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.add_theme_font_override("font", VT323_FONT)
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.add_theme_color_override("font_color", TEXT_COLOR)
	skip_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	skip_btn.pressed.connect(_on_skip_pressed)
	vbox.add_child(skip_btn)


func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var lab := Label.new()
	lab.text = text
	lab.add_theme_font_override("font", VT323_FONT)
	lab.add_theme_font_size_override("font_size", 14)
	lab.add_theme_color_override("font_color", ACCENT)
	parent.add_child(lab)


func _add_toggle_row(parent: VBoxContainer, key: String, title: String) -> void:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_override("font", VT323_FONT)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", TEXT_COLOR)
	btn.pressed.connect(_on_toggle_pressed.bind(key))
	parent.add_child(btn)
	_row_labels[key] = btn
	_set_toggle_text(key, title, false)


func _add_economy_row(parent: VBoxContainer, key: String, title: String, _step: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var lab := Label.new()
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.add_theme_font_override("font", VT323_FONT)
	lab.add_theme_font_size_override("font_size", 16)
	lab.add_theme_color_override("font_color", TEXT_COLOR)
	row.add_child(lab)
	_row_labels[key] = lab

	var minus := Button.new()
	minus.text = "-"
	minus.focus_mode = Control.FOCUS_NONE
	minus.custom_minimum_size = Vector2(28, 24)
	minus.add_theme_font_override("font", VT323_FONT)
	minus.pressed.connect(_on_economy_step.bind(key, -1))
	row.add_child(minus)

	var plus := Button.new()
	plus.text = "+"
	plus.focus_mode = Control.FOCUS_NONE
	plus.custom_minimum_size = Vector2(28, 24)
	plus.add_theme_font_override("font", VT323_FONT)
	plus.pressed.connect(_on_economy_step.bind(key, 1))
	row.add_child(plus)

	parent.add_child(row)
	_set_economy_text(key, title, 0)


func _set_toggle_text(key: String, title: String, on: bool) -> void:
	var btn := _row_labels.get(key) as Button
	if btn == null:
		return
	if on:
		btn.text = "✓  %s" % title
	else:
		btn.text = "   %s" % title


func _set_economy_text(key: String, title: String, value: int) -> void:
	var lab := _row_labels.get(key) as Label
	if lab == null:
		return
	lab.text = "%s: %d" % [title, value]


func open_dev_menu() -> void:

	if not OS.is_debug_build():
		return
	_open_menu()


func toggle_dev_menu() -> void:
	if not OS.is_debug_build():
		return
	_toggle_menu()


func _toggle_menu() -> void:
	if _menu_open:
		_close_menu()
	else:
		_open_menu()


func _open_menu() -> void:
	_refresh_combat_binding()
	_menu_open = true
	_menu.visible = true
	_outside_blocker.visible = true
	_outside_blocker.move_to_front()
	_menu.move_to_front()
	_refresh_toggle_labels()
	_refresh_economy_labels()


func is_menu_open() -> bool:
	return _menu_open


func _close_menu() -> void:
	_menu_open = false
	if _menu != null:
		_menu.visible = false
	if _outside_blocker != null:
		_outside_blocker.visible = false


func _on_outside_gui_input(event: InputEvent) -> void:
	if not _menu_open:
		return
	if event is InputEventMouseButton and event.pressed:
		_close_menu()
		_outside_blocker.accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not _menu_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_close_menu()
			get_viewport().set_input_as_handled()


func _on_toggle_pressed(key: String) -> void:
	if key == "encounters":
		_toggle_encounters()
		return
	if _combat == null or not is_instance_valid(_combat):
		_refresh_combat_binding()
	if _combat == null:
		return
	match key:
		"trinity":
			var on := not bool(_combat.call("debug_get_guarantee_trinity"))
			_combat.call("debug_set_guarantee_trinity", on)
		"fs_clear":
			var on_fs := not bool(_combat.call("debug_get_guarantee_fs_clear"))
			_combat.call("debug_set_guarantee_fs_clear", on_fs)
		"payout_1000x":
			var on_p := not bool(_combat.call("debug_get_guarantee_payout_1000x"))
			_combat.call("debug_set_guarantee_payout_1000x", on_p)
	_refresh_toggle_labels()


func _toggle_encounters() -> void:
	var world := get_node_or_null("/root/AxelWorld")
	if world == null or not world.has_method("set_encounters_suppressed"):
		return
	var on := not bool(world.call("encounters_suppressed"))
	world.call("set_encounters_suppressed", on)
	_refresh_toggle_labels()


func _refresh_toggle_labels() -> void:
	var blocked := false
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("encounters_suppressed"):
		blocked = bool(world.call("encounters_suppressed"))
	_set_toggle_text("encounters", "Disable combat encounters", blocked)
	var trinity := false
	var fs_clear := false
	var payout := false
	if _combat != null and is_instance_valid(_combat):
		if _combat.has_method("debug_get_guarantee_trinity"):
			trinity = bool(_combat.call("debug_get_guarantee_trinity"))
		if _combat.has_method("debug_get_guarantee_fs_clear"):
			fs_clear = bool(_combat.call("debug_get_guarantee_fs_clear"))
		if _combat.has_method("debug_get_guarantee_payout_1000x"):
			payout = bool(_combat.call("debug_get_guarantee_payout_1000x"))
	_set_toggle_text("trinity", "Guarantee Vice Round", trinity)
	_set_toggle_text("fs_clear", "Guarantee Free Spins", fs_clear)
	_set_toggle_text("payout_1000x", "Guarantee 1000x Payout", payout)


func _refresh_economy_labels() -> void:
	var bankroll := 0
	var goal_base := 0
	var goal_prog := 0
	if _combat != null and is_instance_valid(_combat):
		if _combat.has_method("get_bankroll"):
			bankroll = int(_combat.call("get_bankroll"))
		if _combat.has_method("get_goal_base_target_cents"):
			goal_base = int(_combat.call("get_goal_base_target_cents"))
		if _combat.has_method("get_chip_bar_goal_progress_cents"):
			goal_prog = int(_combat.call("get_chip_bar_goal_progress_cents"))
	_set_economy_text("bankroll", "Bankroll", bankroll)
	_set_economy_text("goal_base", "Goal Base", goal_base)
	_set_economy_text("goal_progress", "Goal Progress", goal_prog)


func _on_economy_step(key: String, direction: int) -> void:
	if _combat == null or not is_instance_valid(_combat):
		_refresh_combat_binding()
	if _combat == null:
		return
	match key:
		"bankroll":
			var cur := int(_combat.call("get_bankroll"))
			_combat.call("set_bankroll_cents", cur + direction * BANKROLL_STEP)
		"goal_base":
			var base := int(_combat.call("get_goal_base_target_cents"))
			_combat.call("set_goal_base_target_cents", maxi(base + direction * GOAL_STEP, 1))
		"goal_progress":
			var prog := int(_combat.call("get_chip_bar_goal_progress_cents"))
			_combat.call("set_goal_progress_cents", maxi(prog + direction * GOAL_STEP, 0))
	_refresh_economy_labels()


func _on_skip_pressed() -> void:
	if _combat == null or not is_instance_valid(_combat):
		_refresh_combat_binding()
	if _combat == null:
		return
	if _combat.has_method("debug_skip_current_loop"):
		_combat.call("debug_skip_current_loop")
