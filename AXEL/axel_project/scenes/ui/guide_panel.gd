class_name GuidePanel
extends Control

signal closed

const PAGE_WIDTH := 1180.0
const SIDE_GUTTER := 32.0
const SCROLL_MAX_HEIGHT := 740.0
const SCROLL_MIN_HEIGHT := 200.0
const CHROME_HEIGHT := 500.0
const FRAME_MARGIN := 18
const FRAME_BORDER := 3
const BODY_PX := 30
const HEADING_PX := 38
const CAPTION_PX := 26
const DETAIL_PX := 30
const INLINE_IMG_PX := 34
const LINE_GAP := 4
const ICON_PX := 64
const ICON_PAD := 4
const GRID_GAP := 8
const SYMBOL_PX := 64
const BOARD_CELL_PX := 52
const DOT_PX := 14
const LOCKED_TINT := Color(0.22, 0.22, 0.22, 1.0)
const INK := Color(0.07, 0.02, 0.02, 1.0)
const FRAME_FILL := Color(0.0, 0.0, 0.0, 0.62)
const RARITY_NAMES: PackedStringArray = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const SYMBOL_DIR := "res://combat/data/symbols/"
const ITEM_DIR := "res://combat/data/items/"
const DETAIL_IDLE := "Hover an item to read it."
const ART_DIR := "res://combat/art/grid_symbols/"
const HUD_DIR := "res://exports/Drawings/"
const ART_HAND := ART_DIR + "bloody_hand.png"
const ART_ALCOHOL := ART_DIR + "booze.png"
const ART_CIG := ART_DIR + "cigarette.png"
const ART_WILD := ART_DIR + "satanic_wild.png"
const ART_HEART := ART_DIR + "red_heart.png"
const ART_STAR := ART_DIR + "blue_star.png"
const ART_SQUARE := ART_DIR + "green_circle.png"
const HUD_GOAL := HUD_DIR + "axel_combat_goal.png"
const HUD_BETS := HUD_DIR + "axel_combat_bets.png"
const HUD_MULT := HUD_DIR + "axel_combat_multiplier.png"
const HUD_SKULLS: PackedStringArray = [
	HUD_DIR + "axel_skull_1.png",
	HUD_DIR + "axel_skull_2.png",
	HUD_DIR + "axel_skull_3.png",
]
const BET_STEPS: PackedStringArray = ["100", "200", "300", "400", "500", "1000"]

var _page := 0
var _page_title: Label
var _page_count: Label
var _dots: HBoxContainer
var _frame: PanelContainer
var _scroll: ScrollContainer
var _body: VBoxContainer
var _detail: Label
var _prev: Button
var _next: Button
var _rich_labels: Array[RichTextLabel] = []
var _figures: Array[Control] = []
var _compendium_grids: Array[GridContainer] = []
var _symbols: Array = []
var _items: Array = []
var _textures: Dictionary = {}
var _bold_font: FontVariation


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
	_rich_labels.clear()
	_figures.clear()
	_compendium_grids.clear()
	var data: Dictionary = GuidePages.PAGES[_page]
	var kind := String(data.get("kind", GuidePages.KIND_TEXT))
	var title := String(data.get("title", ""))
	var blocks: Array = data.get("blocks", [])
	if kind == GuidePages.KIND_FREE_SPINS and not _free_spins_seen():
		title = GuidePages.FREE_SPINS_LOCKED_TITLE
		blocks = GuidePages.FREE_SPINS_LOCKED_BLOCKS
	for block in blocks:
		_add_block(block)
	_page_title.text = "? %s ?" % title
	_page_count.text = "%d / %d" % [_page + 1, page_count()]
	_refresh_dots()
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
	for label in _rich_labels:
		parts.append(label.get_parsed_text())
	return "\n".join(parts)


func page_figure_count() -> int:
	return _figures.size()


func compendium_entries() -> Array[Button]:
	var out: Array[Button] = []
	for grid in _compendium_grids:
		for child in grid.get_children():
			if child is Button:
				out.append(child as Button)
	return out


func _build() -> void:
	_bold_font = FontVariation.new()
	_bold_font.base_font = MenuLook.FONT
	_bold_font.variation_embolden = 0.8

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
	_page_title.add_theme_font_override("font", _bold_font)
	col.add_child(_page_title)

	_dots = HBoxContainer.new()
	_dots.name = "GuideDots"
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_dots.add_theme_constant_override("separation", 10)
	for i in page_count():
		var dot := ColorRect.new()
		dot.name = "Dot%d" % i
		dot.custom_minimum_size = Vector2(DOT_PX, DOT_PX)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dots.add_child(dot)
	col.add_child(_dots)

	_frame = PanelContainer.new()
	_frame.name = "GuideFrame"
	_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_theme_stylebox_override("panel", _frame_style())
	col.add_child(_frame)

	_scroll = ScrollContainer.new()
	_scroll.name = "GuideScroll"
	_scroll.focus_mode = Control.FOCUS_NONE
	_scroll.follow_focus = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	MenuLook.apply_scroll(_scroll)
	_frame.add_child(_scroll)

	_body = VBoxContainer.new()
	_body.name = "GuideBody"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 16)
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
	var inset := float(FRAME_MARGIN + FRAME_BORDER) * 2.0
	var scroll_w := width - inset
	_scroll.custom_minimum_size = Vector2(scroll_w, height)
	var text_w := scroll_w - 24.0
	for label in _rich_labels:
		if is_instance_valid(label):
			label.custom_minimum_size.x = text_w
			label.custom_maximum_size.x = text_w
	_detail.custom_minimum_size.x = width
	_detail.custom_maximum_size.x = width
	var cell := float(ICON_PX + ICON_PAD * 2 + GRID_GAP)
	var cols := maxi(int(floor(text_w / cell)), 1)
	for grid in _compendium_grids:
		if is_instance_valid(grid):
			grid.columns = mini(cols, grid.get_child_count())


func _refresh_dots() -> void:
	for i in _dots.get_child_count():
		var dot := _dots.get_child(i) as ColorRect
		dot.color = MenuLook.ACCENT if i == _page else MenuLook.DIM


func _focus_nav() -> void:
	call_deferred("_grab_nav_focus")


func _grab_nav_focus() -> void:
	if not is_visible_in_tree():
		return
	var target: Button = _next if not _next.disabled else _prev
	if target != null and not target.disabled:
		target.grab_focus(true)


func _format(text: String) -> String:
	var accent := MenuLook.ACCENT.to_html(false)
	var out := text.format({
		"rtp": GuidePages.RTP_PERCENT,
		"hit": GuidePages.HIT_RATE_IN_TEN,
		"hand": _inline_img(ART_HAND),
		"alcohol": _inline_img(ART_ALCOHOL),
		"cig": _inline_img(ART_CIG),
		"wild": _inline_img(ART_WILD),
	})
	out = out.replace("[b]", "[b][color=#%s]" % accent).replace("[/b]", "[/color][/b]")
	return out


func _inline_img(path: String) -> String:
	return "[img=%dx%d]%s[/img]" % [INLINE_IMG_PX, INLINE_IMG_PX, path]


func _add_block(block: Dictionary) -> void:
	if block.has("text"):
		_add_text(String(block["text"]))
	elif block.has("heading"):
		_add_heading(String(block["heading"]))
	elif block.has("divider"):
		_add_divider()
	elif block.has("figure"):
		_add_figure(String(block["figure"]))


func _add_text(text: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.focus_mode = Control.FOCUS_NONE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_override("normal_font", MenuLook.FONT)
	label.add_theme_font_override("bold_font", _bold_font)
	label.add_theme_font_size_override("normal_font_size", BODY_PX)
	label.add_theme_font_size_override("bold_font_size", BODY_PX)
	label.add_theme_color_override("default_color", MenuLook.TEXT)
	label.add_theme_constant_override("line_separation", LINE_GAP)
	label.text = "[center]%s[/center]" % _format(text)
	_body.add_child(label)
	_rich_labels.append(label)
	return label


func _add_heading(text: String) -> Label:
	var label := _caption(text, HEADING_PX, MenuLook.ACCENT, true)
	label.name = "Heading"
	_body.add_child(label)
	return label


func _add_divider() -> void:
	var holder := CenterContainer.new()
	holder.name = "Divider"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := ColorRect.new()
	bar.color = MenuLook.DIM
	bar.custom_minimum_size = Vector2(260, 2)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bar)
	_body.add_child(holder)


func _add_figure(id: String) -> void:
	var fig: Control = null
	match id:
		GuidePages.FIG_FIGHT_HUD:
			fig = _fig_fight_hud()
		GuidePages.FIG_GOAL_LADDER:
			fig = _fig_goal_ladder()
		GuidePages.FIG_MATCH_LINE:
			fig = _fig_match_line()
		GuidePages.FIG_CASCADE:
			fig = _fig_cascade()
		GuidePages.FIG_PAYTABLE:
			fig = _fig_paytable()
		GuidePages.FIG_BET_STEPS:
			fig = _fig_bet_steps()
		GuidePages.FIG_MULTIPLIER:
			fig = _fig_multiplier()
		GuidePages.FIG_SKULLS:
			fig = _fig_skulls()
		GuidePages.FIG_POWERS:
			fig = _fig_icons([ART_HAND, ART_ALCOHOL, ART_CIG], ["Bloody Hand", "Alcohol", "Cigarette"], false)
		GuidePages.FIG_VICE_ORDER:
			fig = _fig_icons([ART_HAND, ART_ALCOHOL, ART_CIG], ["1. Bloody Hand", "2. Alcohol", "3. Cigarette"], true)
		GuidePages.FIG_FREE_SPINS:
			fig = _fig_icons([ART_HAND, ART_ALCOHOL, ART_CIG], ["4 spins", "5 spins", "8 spins"], false)
		GuidePages.FIG_LOCKED:
			fig = _fig_locked()
		GuidePages.FIG_ODDS:
			fig = _fig_odds()
		GuidePages.FIG_RARITY:
			fig = _fig_rarity()
		GuidePages.FIG_COMPENDIUM:
			fig = _fig_compendium()
	if fig == null:
		return
	fig.name = "Figure_%s" % id
	fig.set_meta("guide_figure", id)
	_body.add_child(fig)
	_figures.append(fig)


func _tex(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path]


func _fig_row(separation: int = 28) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", separation)
	return row


func _pic(path: String, height: float, tint: Color = Color.WHITE) -> TextureRect:
	var tex := _tex(path)
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate = tint
	var aspect := 1.0
	if tex != null and tex.get_height() > 0:
		aspect = float(tex.get_width()) / float(tex.get_height())
	rect.custom_minimum_size = Vector2(roundf(height * aspect), height)
	return rect


func _caption(text: String, px: int = CAPTION_PX, color: Color = MenuLook.TEXT, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuLook.apply_label(label, px, color)
	if bold:
		label.add_theme_font_override("font", _bold_font)
	return label


func _captioned(ctrl: Control, caption: String, color: Color = MenuLook.TEXT) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	ctrl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ctrl)
	box.add_child(_caption(caption, CAPTION_PX, color))
	return box


func _arrow() -> Label:
	var label := _caption(">", 44, MenuLook.ACCENT, true)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _framed(path: String, height: float, lines: Array) -> TextureRect:
	var rect := _pic(path, height)
	for line in lines:
		var box: Rect2 = line[1]
		var label := _caption(String(line[0]), int(line[2]), INK, true)
		label.anchor_left = box.position.x
		label.anchor_top = box.position.y
		label.anchor_right = box.end.x
		label.anchor_bottom = box.end.y
		label.offset_left = 0
		label.offset_top = 0
		label.offset_right = 0
		label.offset_bottom = 0
		rect.add_child(label)
	return rect


func _board_cell(path: String, ringed: bool) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.custom_minimum_size = Vector2(BOARD_CELL_PX, BOARD_CELL_PX)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.02, 0.02, 0.85) if ringed else Color(0.0, 0.0, 0.0, 0.5)
	style.border_color = MenuLook.ACCENT if ringed else Color(MenuLook.DIM, 0.6)
	style.set_border_width_all(3 if ringed else 1)
	style.anti_aliasing = false
	style.set_content_margin_all(4)
	cell.add_theme_stylebox_override("panel", style)
	if not path.is_empty():
		var pic := _pic(path, BOARD_CELL_PX - 10)
		cell.add_child(pic)
	return cell


func _mini_board(rows: Array) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = (rows[0] as Array).size()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	for row in rows:
		for cell in row:
			var spec: Array = cell
			grid.add_child(_board_cell(String(spec[0]), bool(spec[1])))
	return grid


func _fig_fight_hud() -> Control:
	var row := _fig_row(48)
	var goal := _framed(HUD_GOAL, 140, [["GOAL\n100", Rect2(0.08, 0.12, 0.84, 0.76), 34]])
	row.add_child(_captioned(goal, "how much to win"))
	var bets := _framed(HUD_BETS, 120, [
		["BET 100", Rect2(0.27, 0.06, 0.5, 0.4), 30],
		["BALANCE 1000", Rect2(0.08, 0.57, 0.84, 0.36), 30],
	])
	row.add_child(_captioned(bets, "what you pay, what you have"))
	return row


func _fig_goal_ladder() -> Control:
	var row := _fig_row(14)
	var steps: PackedStringArray = ["50", "60", "70", "x1.5"]
	for i in steps.size():
		if i > 0:
			row.add_child(_arrow())
		row.add_child(_framed(HUD_GOAL, 64, [[steps[i], Rect2(0.08, 0.12, 0.84, 0.76), 28]]))
	return row


func _fig_match_line() -> Control:
	var row := _fig_row(24)
	var before := _mini_board([[
		[ART_HEART, false], [ART_STAR, true], [ART_STAR, true], [ART_STAR, true], [ART_SQUARE, false],
	]])
	var after := _mini_board([[
		[ART_HEART, false], ["", false], [ART_WILD, true], ["", false], [ART_SQUARE, false],
	]])
	row.add_child(_captioned(before, "a line of 3 wins"))
	row.add_child(_arrow())
	row.add_child(_captioned(after, "a Wild stays", MenuLook.ACCENT))
	return row


func _fig_cascade() -> Control:
	var row := _fig_row(24)
	var before := _mini_board([
		[[ART_HEART, false], [ART_SQUARE, false], [ART_HEART, false]],
		[[ART_STAR, true], [ART_STAR, true], [ART_STAR, true]],
		[[ART_SQUARE, false], [ART_HEART, false], [ART_SQUARE, false]],
	])
	var after := _mini_board([
		[["", false], [ART_SQUARE, false], ["", false]],
		[[ART_HEART, true], [ART_WILD, false], [ART_HEART, true]],
		[[ART_SQUARE, false], [ART_HEART, false], [ART_SQUARE, false]],
	])
	row.add_child(_captioned(before, "the line wins"))
	row.add_child(_arrow())
	row.add_child(_captioned(after, "the rest falls", MenuLook.ACCENT))
	return row


func _fig_paytable() -> Control:
	var holder := CenterContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grid := GridContainer.new()
	grid.name = "PaytableGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 36)
	grid.add_theme_constant_override("v_separation", 8)
	holder.add_child(grid)
	for caption in ["", "Symbol", "x3", "x4", "x5"]:
		grid.add_child(_caption(caption, BODY_PX, MenuLook.ACCENT, true))
	for sym in _load_symbols():
		var icon := TextureRect.new()
		icon.texture = sym.get("texture") as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(SYMBOL_PX, SYMBOL_PX)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(icon)
		var name_label := _caption(String(sym.get("display_name")), BODY_PX)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(name_label)
		grid.add_child(_caption("%d%%" % int(sym.get("payout_x3")), BODY_PX))
		grid.add_child(_caption("%d%%" % int(sym.get("payout_x4")), BODY_PX))
		grid.add_child(_caption("%d%%" % int(sym.get("payout_x5")), BODY_PX))
	return holder


func _fig_bet_steps() -> Control:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 14)
	var top := _fig_row()
	top.add_child(_framed(HUD_BETS, 120, [
		["BET 100", Rect2(0.27, 0.06, 0.5, 0.4), 30],
		["BALANCE 1000", Rect2(0.08, 0.57, 0.84, 0.36), 30],
	]))
	box.add_child(top)
	var steps := _fig_row(10)
	for i in BET_STEPS.size():
		steps.add_child(_chip(BET_STEPS[i], i == 0))
	box.add_child(steps)
	return box


func _chip(text: String, lit: bool) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = MenuLook.ACCENT if lit else Color(0, 0, 0, 0.5)
	style.border_color = MenuLook.ACCENT
	style.set_border_width_all(2)
	style.anti_aliasing = false
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)
	chip.add_child(_caption(text, CAPTION_PX, Color.BLACK if lit else MenuLook.TEXT, true))
	return chip


func _fig_multiplier() -> Control:
	var row := _fig_row(14)
	var marks: PackedStringArray = ["x1", "x2", "x3"]
	var notes: PackedStringArray = ["spin starts", "after 1 win", "after 2 wins"]
	for i in marks.size():
		if i > 0:
			row.add_child(_arrow())
		var pic := _framed(HUD_MULT, 92, [[marks[i], Rect2(0.3, 0.2, 0.4, 0.6), 36]])
		row.add_child(_captioned(pic, notes[i]))
	return row


func _fig_skulls() -> Control:
	var row := _fig_row(40)
	var notes: PackedStringArray = ["1 part", "2 parts", "FULL"]
	for i in HUD_SKULLS.size():
		var color := MenuLook.ACCENT if i == HUD_SKULLS.size() - 1 else MenuLook.TEXT
		row.add_child(_captioned(_pic(HUD_SKULLS[i], 120), notes[i], color))
	return row


func _fig_icons(paths: Array, notes: Array, arrows: bool) -> Control:
	var row := _fig_row(18 if arrows else 48)
	for i in paths.size():
		if arrows and i > 0:
			row.add_child(_arrow())
		row.add_child(_captioned(_pic(String(paths[i]), 76), String(notes[i])))
	return row


func _fig_locked() -> Control:
	var row := _fig_row()
	row.add_child(_pic(HUD_SKULLS[2], 170, LOCKED_TINT))
	return row


func _fig_odds() -> Control:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	var row := _fig_row(8)
	for i in 10:
		var square := Panel.new()
		square.mouse_filter = Control.MOUSE_FILTER_IGNORE
		square.custom_minimum_size = Vector2(40, 40)
		var style := StyleBoxFlat.new()
		var lit := i < GuidePages.HIT_RATE_IN_TEN
		style.bg_color = MenuLook.ACCENT if lit else Color(0, 0, 0, 0.5)
		style.border_color = MenuLook.ACCENT if lit else MenuLook.DIM
		style.set_border_width_all(2)
		style.anti_aliasing = false
		square.add_theme_stylebox_override("panel", style)
		row.add_child(square)
	box.add_child(row)
	box.add_child(_caption("%d of 10 spins win something" % GuidePages.HIT_RATE_IN_TEN))
	return box


func _fig_rarity() -> Control:
	var row := _fig_row(36)
	for i in RARITY_NAMES.size():
		var glyph := _caption(ItemDef.rarity_glyph_index(i), 52, MenuLook.ACCENT)
		row.add_child(_captioned(glyph, RARITY_NAMES[i]))
	return row


func _fig_compendium() -> Control:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 12)
	var items := _load_items()
	var found_count := 0
	for item in items:
		if _item_found(String(item.get("id"))):
			found_count += 1
	var counter := _caption("Found %d / %d" % [found_count, items.size()], BODY_PX, MenuLook.ACCENT, true)
	counter.name = "CompendiumCount"
	box.add_child(counter)
	for rarity in RARITY_NAMES.size():
		var group: Array = items.filter(func(it: Resource) -> bool: return int(it.get("rarity")) == rarity)
		if group.is_empty():
			continue
		box.add_child(_caption(
			"%s %s" % [ItemDef.rarity_glyph_index(rarity), RARITY_NAMES[rarity]],
			BODY_PX,
			MenuLook.ACCENT,
			true
		))
		var grid := GridContainer.new()
		grid.name = "CompendiumGrid%d" % rarity
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid.add_theme_constant_override("h_separation", GRID_GAP)
		grid.add_theme_constant_override("v_separation", GRID_GAP)
		box.add_child(grid)
		_compendium_grids.append(grid)
		for item in group:
			grid.add_child(_compendium_entry(item))
	return box


func _frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = FRAME_FILL
	style.border_color = MenuLook.ACCENT
	style.set_border_width_all(FRAME_BORDER)
	style.anti_aliasing = false
	style.corner_detail = 1
	style.set_corner_radius_all(0)
	style.set_content_margin_all(FRAME_MARGIN)
	return style


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
