extends CanvasLayer

const TAB_ITEMS := 0
const TAB_STATS := 1
const TAB_PAY := 2
const TAB_AREAS := 3
const TAB_NAMES: PackedStringArray = ["ITEMS", "STATS", "PAY", "AREAS"]
const SORT_RARITY := 0
const SORT_NEWEST := 1
const SORT_NAME := 2
const SORT_FAMILY := 3
const SORT_NAMES: PackedStringArray = ["RARITY", "NEWEST", "NAME", "TYPE"]
const SYMBOL_PATHS: PackedStringArray = [
	"res://combat/data/symbols/sym_green_circle.tres",
	"res://combat/data/symbols/sym_yellow_triangle.tres",
	"res://combat/data/symbols/sym_blue_star.tres",
	"res://combat/data/symbols/sym_red_heart.tres",
	"res://combat/data/symbols/sym_cigarette.tres",
	"res://combat/data/symbols/sym_booze.tres",
	"res://combat/data/symbols/sym_bloody_hand.tres",
	"res://combat/data/symbols/sym_satanic.tres",
]
const BOX_W := 680.0
const BOX_H := 560.0
const TAB_PX := 36
const ROW_PX := 30
const SMALL_PX := 24
const ICON_PX := 40.0
const OPEN_SEC := 0.12
const CLOSE_SEC := 0.08
const FILL := Color(0.02, 0.02, 0.02, 0.96)
const OUTLINE := Color(0.9, 0.0, 0.0, 1.0)
const ROW_ON := Color(0.22, 0.02, 0.02, 0.92)
const ROW_HOVER := Color(0.12, 0.05, 0.05, 0.92)
const WARM_GREY := Color(0.36, 0.32, 0.31, 1.0)
const WARM_GREY_LIGHT := Color(0.66, 0.6, 0.58, 1.0)
const GREYED := Color(0.45, 0.45, 0.45, 1.0)

var _root: Control
var _box: PanelContainer
var _tab_buttons: Array[Button] = []
var _tools: HBoxContainer
var _sort_button: Button
var _rank_button: Button
var _family_button: Button
var _scroll: ScrollContainer
var _list: VBoxContainer
var _balance: Label
var _dread: Label
var _tickets: Label
var _cap: Label
var _open := false
var _tab := TAB_ITEMS
var _sort := SORT_RARITY
var _rank_filter := -1
var _family_filter := ""
var _anim_t := 0.0
var _close_t := -1.0
var _hover_id := ""
var _cache_warmed := false
var _state_key := ""
var _symbols: Array = []
var _fx := ItemEffectDispatcher.new()


func _ready() -> void:
	layer = 109
	_build()
	var tree := get_tree()
	if tree != null and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	var pause := get_node_or_null("/root/AxelPause")
	if pause != null and pause.has_signal("pause_state_changed"):
		pause.pause_state_changed.connect(_on_pause_changed)


func is_wheel_open() -> bool:
	return _open


func tab_names() -> PackedStringArray:
	return TAB_NAMES


func current_tab() -> int:
	return _tab


func set_tab(tab: int) -> void:
	_tab = clampi(tab, 0, TAB_NAMES.size() - 1)
	_hide_hover()
	_rebuild()


func set_sort(mode: int) -> void:
	_sort = clampi(mode, 0, SORT_NAMES.size() - 1)
	_rebuild()


func set_rank_filter(rank: int) -> void:
	_rank_filter = clampi(rank, -1, ItemDef.RARITY_GLYPHS.size() - 1)
	_rebuild()


func set_family_filter(family: String) -> void:
	_family_filter = family
	_rebuild()


func family_options() -> PackedStringArray:
	var out := PackedStringArray()
	for item in _owned_items():
		var fam := ItemDef.family_name(item)
		if not out.has(fam):
			out.append(fam)
	out.sort()
	return out


func listed_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for item in _listed_items():
		ids.append(str(item.get("id")))
	return ids


func cap_is_visible() -> bool:
	return _cap != null and _cap.visible


func cap_text() -> String:
	if _cap == null:
		return ""
	return _cap.text


func balance_text() -> String:
	if _balance == null:
		return ""
	return _balance.text


func pay_values(symbol_id: String) -> Array[float]:
	var out: Array[float] = []
	var symbol := _symbol_by_id(symbol_id)
	if symbol == null:
		return out
	var items := _equipped_items()
	for length in [3, 4, 5]:
		out.append(_fx.pay_preview(items, symbol, length))
	return out


func area_rows() -> Array:
	var world := get_node_or_null("/root/AxelWorld")
	if world == null or not world.has_method("area_item_rows"):
		return []
	return world.call("area_item_rows")


func open_progress() -> float:
	if not _open:
		return 0.0
	return clampf(_anim_t / OPEN_SEC, 0.0, 1.0)


func open_wheel() -> bool:
	if _open:
		return true
	if not _can_open():
		return false
	_open = true
	_anim_t = 0.0
	_close_t = -1.0
	_root.visible = true
	_hide_hover()
	_layout_box()
	_rebuild()
	_apply_anim(0.0)
	_play_sfx(&"item_wheel_open")
	var tutorial := get_node_or_null("/root/AxelTutorial")
	if tutorial != null and tutorial.has_method("complete"):
		tutorial.call("complete", "items_wheel")
	return true


func close_wheel(instant: bool = false) -> void:
	if not _open:
		if instant and _root != null and _root.visible:
			_close_t = -1.0
			_root.visible = false
		return
	_open = false
	_hover_id = ""
	if _root != null:
		if instant:
			_close_t = -1.0
			_root.visible = false
		else:
			_close_t = CLOSE_SEC
	_hide_hover()


func _build() -> void:
	_root = Control.new()
	_root.name = "WheelRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	_box = PanelContainer.new()
	_box.name = "ItemBox"
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_box.add_theme_stylebox_override("panel", _frame_style())
	_root.add_child(_box)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_box.add_child(column)

	var tabs := HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.add_theme_constant_override("separation", 4)
	column.add_child(tabs)
	for i in TAB_NAMES.size():
		var tab := _make_button(TAB_NAMES[i], TAB_PX)
		tab.pressed.connect(_on_tab_pressed.bind(i))
		tabs.add_child(tab)
		_tab_buttons.append(tab)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tabs.add_child(spacer)
	var close := _make_button("X", TAB_PX)
	close.name = "Close"
	close.pressed.connect(_on_close_pressed)
	tabs.add_child(close)

	column.add_child(_rule())

	_tools = HBoxContainer.new()
	_tools.name = "Tools"
	_tools.add_theme_constant_override("separation", 4)
	column.add_child(_tools)
	_sort_button = _make_button("", SMALL_PX)
	_sort_button.pressed.connect(_on_sort_pressed)
	_tools.add_child(_sort_button)
	_rank_button = _make_button("", SMALL_PX)
	_rank_button.pressed.connect(_on_rank_pressed)
	_tools.add_child(_rank_button)
	_family_button = _make_button("", SMALL_PX)
	_family_button.pressed.connect(_on_family_pressed)
	_tools.add_child(_family_button)

	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	MenuLook.apply_scroll(_scroll)
	_scroll.get_v_scroll_bar().value_changed.connect(_on_scrolled)
	column.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)

	column.add_child(_rule())

	var footer := HBoxContainer.new()
	footer.name = "Footer"
	column.add_child(footer)
	_balance = Label.new()
	_balance.name = "Balance"
	_balance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuLook.apply_label(_balance, ROW_PX, MenuLook.TEXT)
	footer.add_child(_balance)
	_dread = Label.new()
	_dread.name = "Dread"
	_dread.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuLook.apply_label(_dread, ROW_PX, OUTLINE)
	footer.add_child(_dread)
	_tickets = Label.new()
	_tickets.name = "Tickets"
	_tickets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuLook.apply_label(_tickets, ROW_PX, MenuLook.TEXT)
	footer.add_child(_tickets)
	_cap = Label.new()
	_cap.name = "EquipCap"
	_cap.visible = false
	MenuLook.apply_label(_cap, ROW_PX, MenuLook.TEXT)
	footer.add_child(_cap)


func _process(delta: float) -> void:
	if not _cache_warmed:
		_cache_warmed = true
		call_deferred("_warm_wheel_textures")
	if _close_t >= 0.0:
		_close_t -= delta
		if _close_t < 0.0:
			_close_t = -1.0
			_root.visible = false
		else:
			_apply_anim(clampf(_close_t / CLOSE_SEC, 0.0, 1.0))
	if not _open:
		return
	if not _can_open():
		close_wheel(true)
		return
	if _anim_t < OPEN_SEC:
		_anim_t += delta
		_apply_anim(open_progress())
	var key := _current_state_key()
	if key != _state_key:
		_rebuild()


func _input(event: InputEvent) -> void:
	if not _open or event.is_echo():
		return
	if _dialogue_busy():
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("back"):
		close_wheel()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("item_wheel"):
		if _dialogue_busy():
			return
		if _open:
			close_wheel()
		else:
			open_wheel()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouseButton:
		return
	var click := event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _hit_player(click.position):
		return
	if _dialogue_busy() and not _open:
		return
	if _open:
		close_wheel()
	else:
		open_wheel()
	get_viewport().set_input_as_handled()


func _on_scene_changed() -> void:
	close_wheel(true)
	_cache_warmed = false


func _on_pause_changed(paused: bool) -> void:
	if paused:
		close_wheel(true)


func _scale() -> float:
	return UiViewportScale.factor(_root)


func _px(authored: int) -> int:
	return maxi(roundi(float(authored) * _scale()), 8)


func _layout_box() -> void:
	var s := _scale()
	var view := _root.get_viewport_rect().size
	var box_size := Vector2(minf(BOX_W * s, view.x - 32.0), minf(BOX_H * s, view.y - 32.0))
	_box.custom_minimum_size = box_size
	_box.size = box_size
	_box.position = ((view - box_size) * 0.5).floor()
	_box.pivot_offset = box_size * 0.5
	for i in _tab_buttons.size():
		_tab_buttons[i].add_theme_font_size_override("font_size", _px(TAB_PX))
	var close := _box.find_child("Close", true, false) as Button
	if close != null:
		close.add_theme_font_size_override("font_size", _px(TAB_PX))
	for button in [_sort_button, _rank_button, _family_button]:
		button.add_theme_font_size_override("font_size", _px(SMALL_PX))
	_balance.add_theme_font_size_override("font_size", _px(ROW_PX))
	_dread.add_theme_font_size_override("font_size", _px(ROW_PX))
	_tickets.add_theme_font_size_override("font_size", _px(ROW_PX))
	_cap.add_theme_font_size_override("font_size", _px(ROW_PX))


func _apply_anim(t: float) -> void:
	if _box == null:
		return
	var eased := 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)
	_box.scale = Vector2(1.0, maxf(eased, 0.02))
	_box.modulate.a = clampf(t * 1.5, 0.0, 1.0)


func _rebuild() -> void:
	_state_key = _current_state_key()
	if _list == null:
		return
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for i in _tab_buttons.size():
		var on := i == _tab
		var color := MenuLook.ACCENT if on else MenuLook.TEXT
		_tab_buttons[i].add_theme_color_override("font_color", color)
		_tab_buttons[i].add_theme_color_override("font_hover_color", MenuLook.ACCENT if not on else Color.WHITE)
	_tools.visible = _tab == TAB_ITEMS
	_refresh_tools()
	match _tab:
		TAB_ITEMS:
			_build_items()
		TAB_STATS:
			_build_stats()
		TAB_PAY:
			_build_pay()
		TAB_AREAS:
			_build_areas()
	_refresh_footer()


func _refresh_tools() -> void:
	_sort_button.text = "SORT: %s" % SORT_NAMES[_sort]
	var rank := "ALL" if _rank_filter < 0 else ItemDef.rarity_glyph_index(_rank_filter)
	_rank_button.text = "RANK: %s" % rank
	var fam := "ALL" if _family_filter.is_empty() else _family_filter.to_upper()
	_family_button.text = "TYPE: %s" % fam


func _refresh_footer() -> void:
	var run := _run()
	var bankroll := 0
	var equipped := 0
	var cap := 7
	if run != null:
		bankroll = int(run.state.bankroll_cents)
		equipped = run.state.equipped_item_ids.size()
		if run.has_method("max_equip_slots"):
			cap = int(run.call("max_equip_slots"))
	_balance.text = "BALANCE: %d" % bankroll
	var dread := 0.0
	if run != null and run.has_method("dread_pct"):
		dread = float(run.call("dread_pct"))
	_dread.visible = dread > 0.0
	_dread.text = "DREAD %d%%" % int(round(dread * 100.0))
	var tickets := int(run.call("ticket_count")) if run != null and run.has_method("ticket_count") else 0
	_tickets.visible = tickets > 0
	_tickets.text = "TICKETS %d" % tickets
	_cap.visible = _owned_count() > 0
	_cap.text = "%d/%d" % [equipped, cap]
	_cap.add_theme_color_override("font_color", OUTLINE if equipped >= cap else MenuLook.TEXT)


func _build_items() -> void:
	var items := _listed_items()
	if items.is_empty():
		_list.add_child(_note("No items yet." if _owned_count() == 0 else "Nothing matches."))
		return
	for item in items:
		_list.add_child(_item_row(item))


func _item_row(item: Resource) -> Button:
	var item_id := str(item.get("id"))
	var equipped := _is_equipped(item_id)
	var row := Button.new()
	row.name = "Row_%s" % item_id
	row.focus_mode = Control.FOCUS_NONE
	row.flat = true
	row.custom_minimum_size = Vector2(0.0, (ICON_PX + 8.0) * _scale())
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.set_meta("item_id", item_id)
	var base := StyleBoxFlat.new()
	base.bg_color = ROW_ON if equipped else Color(0, 0, 0, 0)
	base.anti_aliasing = false
	var hover := base.duplicate() as StyleBoxFlat
	hover.bg_color = ROW_ON.lightened(0.08) if equipped else ROW_HOVER
	for state_name in ["normal", "focus", "disabled"]:
		row.add_theme_stylebox_override(state_name, base)
	for state_name in ["hover", "pressed", "hover_pressed"]:
		row.add_theme_stylebox_override(state_name, hover)
	row.pressed.connect(_on_row_pressed.bind(item_id))
	row.mouse_entered.connect(_on_row_hover.bind(row))
	row.mouse_exited.connect(_on_row_exit.bind(item_id))

	var line := HBoxContainer.new()
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 6.0
	line.offset_right = -6.0
	line.add_theme_constant_override("separation", 12)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	var tint := Color.WHITE if equipped else GREYED
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = ItemDef.cached_wheel_texture(item)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX) * _scale()
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.modulate = tint
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon)
	var title := _label(ItemDef.rarity_name(item), ROW_PX, MenuLook.TEXT if equipped else WARM_GREY_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.add_child(title)
	line.add_child(_label(ItemDef.family_name(item).to_upper(), SMALL_PX, MenuLook.DIM if not equipped else WARM_GREY_LIGHT))
	line.add_child(_label("ON" if equipped else "--", ROW_PX, OUTLINE if equipped else WARM_GREY))
	return row


func _build_stats() -> void:
	var groups: Dictionary = {}
	var order: Array = []
	for item in _equipped_items():
		var fam := ItemDef.family_name(item)
		if not groups.has(fam):
			groups[fam] = []
			order.append(fam)
		(groups[fam] as Array).append(item)
	if order.is_empty():
		_list.add_child(_note("No active effects. Equip an item on ITEMS."))
		return
	order.sort()
	var width := _text_width()
	for fam in order:
		_list.add_child(_label(String(fam).to_upper(), SMALL_PX, MenuLook.ACCENT))
		for item in groups[fam]:
			var text := "%s: %s" % [ItemDef.rarity_name(item), _described(item)]
			var desc := ItemDescFormat.make_label("Stat_%s" % str(item.get("id")), _px(SMALL_PX), width)
			ItemDescFormat.set_text(desc, text)
			_list.add_child(desc)


func _described(item: Resource) -> String:
	var text := str(item.get("description"))
	var run := _run()
	if run == null or not run.has_method("hex_text"):
		return text
	var hex := String(run.call("hex_text", str(item.get("id"))))
	return text if hex.is_empty() else "%s  %s." % [text, hex]


func _build_pay() -> void:
	var grid := GridContainer.new()
	grid.name = "PayGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 0)
	_list.add_child(grid)
	grid.add_child(_label("", SMALL_PX))
	grid.add_child(_label("SYMBOL", SMALL_PX, MenuLook.ACCENT))
	for length in [3, 4, 5]:
		grid.add_child(_label("x%d" % length, SMALL_PX, MenuLook.ACCENT))
	var items := _equipped_items()
	for symbol in _load_symbols():
		var icon := TextureRect.new()
		icon.texture = symbol.get("texture")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX) * _scale()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(icon)
		var name_label := _label(str(symbol.get("display_name")), ROW_PX)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(name_label)
		for length in [3, 4, 5]:
			var base := float(symbol.call("payout_multiplier_for_length", length))
			var now := _fx.pay_preview(items, symbol, length)
			var changed := not is_equal_approx(base, now)
			grid.add_child(_label(_pay_text(now), ROW_PX, OUTLINE if changed else MenuLook.TEXT))
	_list.add_child(_note("Win = bet x pay % x multiplier. Red = raised by your items."))
	if _has_effect(items, &"trinity_run"):
		_list.add_child(_note("+ more during the Vice Round."))
	if _has_effect(items, &"paid_spin_payout_scalar"):
		_list.add_child(_note("+ grows with each paid spin in a fight."))


func _build_areas() -> void:
	var rows := area_rows()
	var cleared := 0
	for row in rows:
		if bool(row["cleared"]):
			cleared += 1
	_list.add_child(_label("AREAS CLEARED %d/%d" % [cleared, rows.size()], ROW_PX, MenuLook.ACCENT))
	var grid := GridContainer.new()
	grid.name = "AreaGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 4)
	_list.add_child(grid)
	for row in rows:
		var done := bool(row["cleared"])
		var placed := int(row["placed"])
		var name_label := _label(String(row["label"]), ROW_PX, MenuLook.TEXT if placed > 0 else WARM_GREY)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(name_label)
		var count := "%d/%d" % [int(row["taken"]), placed] if placed > 0 else "-"
		grid.add_child(_label(count, ROW_PX, MenuLook.TEXT if placed > 0 else WARM_GREY))
		grid.add_child(_label("CLEARED" if done else "", ROW_PX, OUTLINE))


func _pay_text(value: float) -> String:
	return "%d%%" % roundi(value)


func _has_effect(items: Array, effect_id: StringName) -> bool:
	for item in items:
		if item != null and StringName(str(item.get("effect_id"))) == effect_id:
			return true
	return false


func _load_symbols() -> Array:
	if not _symbols.is_empty():
		return _symbols
	for path in SYMBOL_PATHS:
		var symbol := load(path)
		if symbol != null:
			_symbols.append(symbol)
	return _symbols


func _symbol_by_id(symbol_id: String) -> Resource:
	for symbol in _load_symbols():
		if str(symbol.get("id")) == symbol_id:
			return symbol
	return null


func _listed_items() -> Array:
	var owned := _owned_items()
	var order: Dictionary = {}
	for i in owned.size():
		order[str(owned[i].get("id"))] = i
	var out: Array = []
	for item in owned:
		if _rank_filter >= 0 and int(item.get("rarity")) != _rank_filter:
			continue
		if not _family_filter.is_empty() and ItemDef.family_name(item) != _family_filter:
			continue
		out.append(item)
	match _sort:
		SORT_RARITY:
			out.sort_custom(func(a, b): return _by_rarity(a, b, order))
		SORT_NEWEST:
			out.sort_custom(func(a, b): return int(order[str(a.get("id"))]) > int(order[str(b.get("id"))]))
		SORT_NAME:
			out.sort_custom(func(a, b): return _display_name(a).naturalnocasecmp_to(_display_name(b)) < 0)
		SORT_FAMILY:
			out.sort_custom(func(a, b): return _by_family(a, b, order))
	return out


func _by_rarity(a: Resource, b: Resource, order: Dictionary) -> bool:
	var ra := int(a.get("rarity"))
	var rb := int(b.get("rarity"))
	if ra != rb:
		return ra < rb
	return int(order[str(a.get("id"))]) < int(order[str(b.get("id"))])


func _by_family(a: Resource, b: Resource, order: Dictionary) -> bool:
	var fa := ItemDef.family_name(a)
	var fb := ItemDef.family_name(b)
	if fa != fb:
		return fa.naturalnocasecmp_to(fb) < 0
	return _by_rarity(a, b, order)


func _display_name(item: Resource) -> String:
	var text := str(item.get("display_name")).strip_edges()
	return text if not text.is_empty() else str(item.get("id"))


func _owned_items() -> Array:
	var run := _run()
	if run == null or not run.has_method("owned_items"):
		return []
	var out: Array = []
	for item in run.call("owned_items"):
		if item != null:
			out.append(item)
	return out


func _equipped_items() -> Array:
	var run := _run()
	if run == null or not run.has_method("equipped_items"):
		return []
	var out: Array = []
	for item in run.call("equipped_items"):
		if item != null:
			out.append(item)
	return out


func _current_state_key() -> String:
	var run := _run()
	if run == null:
		return ""
	return "%s|%s|%d" % [
		",".join(run.state.owned_item_ids),
		",".join(run.state.equipped_item_ids),
		int(run.state.bankroll_cents),
	]


func _make_button(text: String, size_px: int) -> Button:
	var button := Button.new()
	button.text = text
	MenuLook.apply_button(button, _px(size_px), Control.SIZE_SHRINK_BEGIN)
	button.focus_mode = Control.FOCUS_NONE
	var pad := StyleBoxEmpty.new()
	pad.content_margin_left = 8
	pad.content_margin_right = 8
	pad.content_margin_top = 2
	pad.content_margin_bottom = 2
	for state_name in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, pad)
	return button


func _label(text: String, size_px: int, color: Color = MenuLook.TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	MenuLook.apply_label(label, _px(size_px), color)
	return label


func _note(text: String) -> Control:
	var note := ItemDescFormat.make_label("Note", _px(SMALL_PX), _text_width())
	note.text = text
	note.add_theme_color_override("default_color", WARM_GREY_LIGHT)
	return note


func _text_width() -> float:
	return maxf(_box.custom_minimum_size.x - 64.0 * _scale(), 120.0)


func _rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.color = MenuLook.ACCENT
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


func _frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = FILL
	style.border_color = OUTLINE
	style.set_border_width_all(3)
	style.anti_aliasing = false
	style.corner_detail = 1
	style.set_corner_radius_all(0)
	style.shadow_color = Color(0.04, 0.04, 0.04, 0.95)
	style.shadow_offset = Vector2(5, 6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _on_tab_pressed(tab: int) -> void:
	_play_sfx(&"item_wheel_click")
	_scroll.scroll_vertical = 0
	set_tab(tab)


func _on_close_pressed() -> void:
	close_wheel()


func _on_sort_pressed() -> void:
	_play_sfx(&"item_wheel_click")
	set_sort((_sort + 1) % SORT_NAMES.size())


func _on_rank_pressed() -> void:
	_play_sfx(&"item_wheel_click")
	var next := _rank_filter + 1
	if next >= ItemDef.RARITY_GLYPHS.size():
		next = -1
	set_rank_filter(next)


func _on_family_pressed() -> void:
	_play_sfx(&"item_wheel_click")
	var options := family_options()
	if options.is_empty():
		set_family_filter("")
		return
	var at := options.find(_family_filter)
	if _family_filter.is_empty():
		set_family_filter(options[0])
	elif at < 0 or at + 1 >= options.size():
		set_family_filter("")
	else:
		set_family_filter(options[at + 1])


func _on_row_pressed(item_id: String) -> void:
	_play_sfx(&"item_wheel_click")
	toggle_item(item_id)


func toggle_item(item_id: String) -> void:
	var run := _run()
	if run != null and run.has_method("toggle_equip"):
		run.call("toggle_equip", item_id)
	_rebuild()
	if not _hover_id.is_empty():
		var row := _list.find_child("Row_%s" % _hover_id, false, false) as Control
		if row != null:
			_show_hover(row)


func _on_row_hover(row: Control) -> void:
	_show_hover(row)


func _show_hover(row: Control) -> void:
	var item_id := str(row.get_meta("item_id", ""))
	var item := _item_by_id(item_id)
	if item == null:
		return
	_hover_id = item_id
	var card := _card()
	if card == null or not card.has_method("show_screen_item"):
		return
	var box_rect := _box.get_global_rect()
	var row_rect := row.get_global_rect()
	card.call(
		"show_screen_item",
		Vector2(box_rect.end.x + 12.0, row_rect.position.y),
		ItemDef.rarity_name(item),
		_described(item),
		item.get("icon")
	)


func _on_row_exit(item_id: String) -> void:
	if _hover_id != item_id:
		return
	_hover_id = ""
	call_deferred("_hide_hover_if_clear")


func _on_scrolled(_value: float) -> void:
	_hover_id = ""
	_hide_hover()


func _hide_hover_if_clear() -> void:
	if not _hover_id.is_empty():
		return
	_hide_hover()


func _item_by_id(item_id: String) -> Resource:
	for item in _owned_items():
		if str(item.get("id")) == item_id:
			return item
	return null


func _warm_wheel_textures() -> void:
	for item in _owned_items():
		ItemDef.cached_wheel_texture(item)


func _can_open() -> bool:
	var tree := get_tree()
	if tree == null or tree.paused:
		return false
	var scene := tree.current_scene
	if scene == null:
		return false
	var path := String(scene.scene_file_path)
	if path.begins_with("res://scenes/Main_Menu/") or path.begins_with("res://combat/"):
		return false
	if _dialogue_busy():
		return false
	if _find_player() == null:
		return false
	var run := _run()
	if run != null and run.has_method("is_in_encounter") and bool(run.call("is_in_encounter")):
		return false
	if run != null and run.has_method("is_game_over_menu_open") and bool(run.call("is_game_over_menu_open")):
		return false
	return true


func _dialogue_busy() -> bool:
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if scene == null:
		return false
	var overlay := scene.get_node_or_null("TopDialogueOverlay")
	if overlay != null and overlay.has_method("is_sequence_busy"):
		return bool(overlay.call("is_sequence_busy"))
	return false


func _sprite_local_rect(sprite: AnimatedSprite2D) -> Rect2:
	if sprite.sprite_frames == null:
		return Rect2()
	var anim := sprite.animation
	if anim == StringName() or not sprite.sprite_frames.has_animation(anim):
		return Rect2()
	var frame_count := sprite.sprite_frames.get_frame_count(anim)
	if frame_count <= 0:
		return Rect2()
	var frame := clampi(sprite.frame, 0, frame_count - 1)
	var tex := sprite.sprite_frames.get_frame_texture(anim, frame)
	if tex == null:
		return Rect2()
	var size := tex.get_size()
	var origin := sprite.offset
	if sprite.centered:
		origin -= size * 0.5
	return Rect2(origin, size)


func _find_player() -> Node2D:
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if scene == null:
		return null
	var direct := scene.get_node_or_null("PlayerLayer/Player") as Node2D
	if direct != null:
		return direct
	return scene.find_child("Player", true, false) as Node2D


func _hit_player(screen_pos: Vector2) -> bool:
	var player := _find_player()
	if player == null:
		return false
	var sprite := player.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	if sprite == null or not sprite.visible:
		return false
	var xf := sprite.get_global_transform_with_canvas()
	var rect := _sprite_local_rect(sprite).grow(8.0)
	if rect.size.y <= 2.0:
		return xf.origin.distance_to(screen_pos) <= 48.0
	return rect.has_point(xf.affine_inverse() * screen_pos)


func _is_equipped(item_id: String) -> bool:
	var run := _run()
	if run == null:
		return false
	for existing in run.state.equipped_item_ids:
		if String(existing) == item_id:
			return true
	return false


func _owned_count() -> int:
	var run := _run()
	if run == null:
		return 0
	return run.state.owned_item_ids.size()


func _run() -> Node:
	return get_node_or_null("/root/AxelRun")


func _play_sfx(cue: StringName) -> void:
	var sfx := get_node_or_null("/root/AxelSfx")
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", cue)


func _card() -> Node:
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if scene == null:
		return null
	var card := scene.get_node_or_null("WorldItemInfoCard")
	if card != null:
		return card
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("_ensure_info_card"):
		return world.call("_ensure_info_card", scene)
	return null


func _hide_hover() -> void:
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if scene == null:
		return
	var card := scene.get_node_or_null("WorldItemInfoCard")
	if card == null:
		return
	if card.has_method("hide_card_immediate"):
		card.call("hide_card_immediate")
	elif card.has_method("hide_card"):
		card.call("hide_card")
