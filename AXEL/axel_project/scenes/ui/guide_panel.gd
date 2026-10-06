class_name GuidePanel
extends Control

signal closed

const PAGE_WIDTH := 1180.0
const SIDE_GUTTER := 32.0
const SCROLL_MAX_HEIGHT := 760.0
const SCROLL_MIN_HEIGHT := 200.0
const CHROME_HEIGHT := 460.0
const BODY_PX := 32
const DETAIL_PX := 30
const ICON_PX := 64
const ICON_PAD := 4
const GRID_GAP := 8
const SYMBOL_PX := 64
const LOCKED_TINT := Color(0.22, 0.22, 0.22, 1.0)
const RARITY_NAMES: PackedStringArray = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const SYMBOL_DIR := "res://combat/data/symbols/"
const ITEM_DIR := "res://combat/data/items/"
const DETAIL_IDLE := "Hover an item to read it."

var _page := 0
var _page_title: Label
var _page_count: Label
var _scroll: ScrollContainer
var _body: VBoxContainer
var _detail: Label
var _prev: Button
var _next: Button
var _wrap_labels: Array[Label] = []
var _compendium_grids: Array[GridContainer] = []
var _symbols: Array = []
var _items: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	get_viewport().size_changed.connect(_apply_layout)
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		closed.emit()


func open() -> void:
	visible = true
	show_page(_page)
	_focus_nav()


func page_count() -> int:
	return GuidePages.PAGES.size()


func current_page() -> int:
	return _page


func next_page() -> void:
	if _page < page_count() - 1:
		show_page(_page + 1)
		_focus_nav()


func prev_page() -> void:
	if _page > 0:
		show_page(_page - 1)
		_focus_nav()


func show_page(index: int) -> void:
	_page = clampi(index, 0, page_count() - 1)
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_wrap_labels.clear()
	_compendium_grids.clear()
	var data: Dictionary = GuidePages.PAGES[_page]
	var kind := String(data.get("kind", GuidePages.KIND_TEXT))
	var title := String(data.get("title", ""))
	match kind:
		GuidePages.KIND_PAYTABLE:
			_add_text(String(data.get("body", "")))
			_add_paytable()
			_add_text(String(data.get("footer", "")), MenuLook.ACCENT)
		GuidePages.KIND_FREE_SPINS:
			if _free_spins_seen():
				_add_text(String(data.get("body", "")))
			else:
				title = GuidePages.FREE_SPINS_LOCKED_TITLE
				_add_text(GuidePages.FREE_SPINS_LOCKED_BODY)
		GuidePages.KIND_COMPENDIUM:
			_add_text(String(data.get("body", "")))
			_add_compendium()
		_:
			_add_text(String(data.get("body", "")))
	_page_title.text = "? %s ?" % title
	_page_count.text = "%d / %d" % [_page + 1, page_count()]
	MenuLook.set_button_disabled(_prev, _page == 0)
	MenuLook.set_button_disabled(_next, _page == page_count() - 1)
	_detail.visible = kind == GuidePages.KIND_COMPENDIUM
	_detail.text = DETAIL_IDLE
	_scroll.scroll_vertical = 0
	_apply_layout()


func page_title_text() -> String:
	return _page_title.text if _page_title != null else ""


func page_body_text() -> String:
	var parts: PackedStringArray = []
	for label in _wrap_labels:
		parts.append(label.text)
	return "\n".join(parts)


func compendium_entries() -> Array[Button]:
	var out: Array[Button] = []
	for grid in _compendium_grids:
		for child in grid.get_children():
			if child is Button:
				out.append(child as Button)
	return out


func _build() -> void:
	var center := CenterContainer.new()
	center.name = "GuideCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var col := VBoxContainer.new()
	col.name = "GuideColumn"
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)

	var title := Label.new()
	title.name = "GuideTitle"
	title.text = "GUIDE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(title, 64, MenuLook.ACCENT)
	col.add_child(title)

	_page_title = Label.new()
	_page_title.name = "GuidePageTitle"
	_page_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuLook.apply_label(_page_title, 44, MenuLook.ACCENT)
	col.add_child(_page_title)

	_scroll = ScrollContainer.new()
	_scroll.name = "GuideScroll"
	_scroll.focus_mode = Control.FOCUS_NONE
	_scroll.follow_focus = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	MenuLook.apply_scroll(_scroll)
	col.add_child(_scroll)

	_body = VBoxContainer.new()
	_body.name = "GuideBody"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 14)
	_scroll.add_child(_body)

	_detail = Label.new()
	_detail.name = "GuideDetail"
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuLook.apply_label(_detail, DETAIL_PX)
	_detail.custom_minimum_size.y = DETAIL_PX * 2 + 8
	_detail.visible = false
	col.add_child(_detail)

	var nav := HBoxContainer.new()
	nav.name = "GuideNav"
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	nav.add_theme_constant_override("separation", 24)
	col.add_child(nav)

	_prev = Button.new()
	_prev.name = "PrevButton"
	_prev.text = "< Prev"
	MenuLook.apply_button(_prev, 36)
	_prev.pressed.connect(prev_page)
	nav.add_child(_prev)

	_page_count = Label.new()
	_page_count.name = "GuidePageCount"
	_page_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_count.custom_minimum_size.x = 120
	MenuLook.apply_label(_page_count, 32, MenuLook.DIM)
	nav.add_child(_page_count)

	_next = Button.new()
	_next.name = "NextButton"
	_next.text = "Next >"
	MenuLook.apply_button(_next, 36)
	_next.pressed.connect(next_page)
	nav.add_child(_next)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back"
	MenuLook.apply_button(back, 43)
	back.pressed.connect(func() -> void: closed.emit())
	col.add_child(back)

	show_page(_page)


func _apply_layout() -> void:
	if _scroll == null:
		return
	var vp := get_viewport_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	var width := minf(PAGE_WIDTH, vp.x - SIDE_GUTTER * 2.0)
	var height := clampf(vp.y - CHROME_HEIGHT, SCROLL_MIN_HEIGHT, SCROLL_MAX_HEIGHT)
	_scroll.custom_minimum_size = Vector2(width, height)
	var text_w := width - 24.0
	for label in _wrap_labels:
		if is_instance_valid(label):
			label.custom_minimum_size.x = text_w
			label.custom_maximum_size.x = text_w
	_detail.custom_minimum_size.x = width
	_detail.custom_maximum_size.x = width
	var cell := float(ICON_PX + ICON_PAD * 2 + GRID_GAP)
	var cols := maxi(int(floor(text_w / cell)), 1)
	for grid in _compendium_grids:
		if is_instance_valid(grid):
			grid.columns = cols


func _focus_nav() -> void:
	call_deferred("_grab_nav_focus")


func _grab_nav_focus() -> void:
	if not is_visible_in_tree():
		return
	var target: Button = _next if not _next.disabled else _prev
	if target != null and not target.disabled:
		target.grab_focus(true)


func _format(text: String) -> String:
	return text.format({"rtp": GuidePages.RTP_PERCENT, "hit": GuidePages.HIT_RATE_IN_TEN})


func _add_text(text: String, color: Color = MenuLook.TEXT) -> Label:
	var label := Label.new()
	label.text = _format(text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuLook.apply_label(label, BODY_PX, color)
	_body.add_child(label)
	_wrap_labels.append(label)
	return label


func _add_paytable() -> void:
	var holder := CenterContainer.new()
	holder.name = "PaytableHolder"
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(holder)
	var grid := GridContainer.new()
	grid.name = "PaytableGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 36)
	grid.add_theme_constant_override("v_separation", 8)
	holder.add_child(grid)
	for caption in ["", "Symbol", "x3", "x4", "x5"]:
		grid.add_child(_cell_label(caption, MenuLook.ACCENT))
	for sym in _load_symbols():
		var icon := TextureRect.new()
		icon.texture = sym.get("texture") as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(SYMBOL_PX, SYMBOL_PX)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(icon)
		grid.add_child(_cell_label(String(sym.get("display_name")), MenuLook.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
		grid.add_child(_cell_label(str(int(sym.get("payout_x3")))))
		grid.add_child(_cell_label(str(int(sym.get("payout_x4")))))
		grid.add_child(_cell_label(str(int(sym.get("payout_x5")))))


func _cell_label(text: String, color: Color = MenuLook.TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuLook.apply_label(label, BODY_PX, color)
	return label


func _load_symbols() -> Array:
	if not _symbols.is_empty():
		return _symbols
	for fname in ResourceLoader.list_directory(SYMBOL_DIR):
		if not fname.ends_with(".tres"):
			continue
		var res := load(SYMBOL_DIR + fname)
		if res != null and float(res.get("payout_x3")) > 0.0:
			_symbols.append(res)
	_symbols.sort_custom(func(a: Resource, b: Resource) -> bool:
		var ax := float(a.get("payout_x5"))
		var bx := float(b.get("payout_x5"))
		if ax != bx:
			return ax > bx
		return String(a.get("display_name")) < String(b.get("display_name"))
	)
	return _symbols


func _load_items() -> Array:
	if not _items.is_empty():
		return _items
	for fname in ResourceLoader.list_directory(ITEM_DIR):
		if not fname.ends_with(".tres"):
			continue
		var res := load(ITEM_DIR + fname)
		if res != null and not String(res.get("id")).is_empty():
			_items.append(res)
	_items.sort_custom(func(a: Resource, b: Resource) -> bool:
		var ar := int(a.get("rarity"))
		var br := int(b.get("rarity"))
		if ar != br:
			return ar < br
		return String(a.get("id")).naturalnocasecmp_to(String(b.get("id"))) < 0
	)
	return _items


func _add_compendium() -> void:
	var items := _load_items()
	var found_count := 0
	for item in items:
		if _item_found(String(item.get("id"))):
			found_count += 1
	var counter := _cell_label("Found %d / %d" % [found_count, items.size()], MenuLook.ACCENT)
	counter.name = "CompendiumCount"
	_body.add_child(counter)
	for rarity in RARITY_NAMES.size():
		var group: Array = items.filter(func(it: Resource) -> bool: return int(it.get("rarity")) == rarity)
		if group.is_empty():
			continue
		var heading := _cell_label(
			"%s %s" % [ItemDef.rarity_glyph_index(rarity), RARITY_NAMES[rarity]],
			MenuLook.ACCENT,
			HORIZONTAL_ALIGNMENT_LEFT
		)
		_body.add_child(heading)
		var grid := GridContainer.new()
		grid.name = "CompendiumGrid%d" % rarity
		grid.add_theme_constant_override("h_separation", GRID_GAP)
		grid.add_theme_constant_override("v_separation", GRID_GAP)
		_body.add_child(grid)
		_compendium_grids.append(grid)
		for item in group:
			grid.add_child(_compendium_entry(item))


func _compendium_entry(item: Resource) -> Button:
	var item_id := String(item.get("id"))
	var found := _item_found(item_id)
	var entry := Button.new()
	entry.name = "Entry_%s" % item_id.replace("-", "_")
	entry.flat = true
	entry.icon = ItemDef.cached_wheel_texture(item)
	entry.expand_icon = true
	entry.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entry.custom_minimum_size = Vector2(ICON_PX + ICON_PAD * 2, ICON_PX + ICON_PAD * 2)
	entry.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	entry.set_meta("item_id", item_id)
	entry.set_meta("found", found)
	var tint := Color.WHITE if found else LOCKED_TINT
	for key in ["icon_normal_color", "icon_hover_color", "icon_focus_color", "icon_pressed_color", "icon_hover_pressed_color"]:
		entry.add_theme_color_override(key, tint)
	var pad := StyleBoxEmpty.new()
	pad.set_content_margin_all(ICON_PAD)
	var ring := _entry_ring()
	entry.add_theme_stylebox_override("normal", pad)
	entry.add_theme_stylebox_override("pressed", pad)
	entry.add_theme_stylebox_override("disabled", pad)
	entry.add_theme_stylebox_override("hover", ring)
	entry.add_theme_stylebox_override("hover_pressed", ring)
	entry.add_theme_stylebox_override("focus", ring)
	entry.focus_entered.connect(_show_item_detail.bind(item, found))
	entry.mouse_entered.connect(_show_item_detail.bind(item, found))
	return entry


func _entry_ring() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = MenuLook.ACCENT
	style.set_border_width_all(4)
	style.anti_aliasing = false
	style.corner_detail = 1
	style.set_corner_radius_all(0)
	style.set_content_margin_all(ICON_PAD)
	return style


func _show_item_detail(item: Resource, found: bool) -> void:
	if found:
		_detail.text = "%s\n%s" % [ItemDef.rarity_name(item), String(item.get("description"))]
	else:
		_detail.text = "%s ???\nNot found yet." % ItemDef.rarity_glyph(item)


func _profile() -> Node:
	return get_node_or_null("/root/AxelProfile")


func _free_spins_seen() -> bool:
	var profile := _profile()
	return profile != null and bool(profile.call("has_seen_free_spins"))


func _item_found(item_id: String) -> bool:
	var profile := _profile()
	return profile != null and bool(profile.call("has_found_item", item_id))
