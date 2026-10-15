class_name TicketMachine
extends PanelContainer

const TITLE_PX := 40
const ROW_PX := 32
const MARGIN := 24.0
const FILL := Color(0.03, 0.02, 0.02, 0.92)

var _tickets_label: Label
var _price_label: Label
var _buy: Button
var _flash := 0.0


func _ready() -> void:
	name = "TicketMachine"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var frame := StyleBoxFlat.new()
	frame.bg_color = FILL
	frame.border_color = MenuLook.ACCENT
	frame.set_border_width_all(3)
	frame.set_content_margin_all(14)
	add_theme_stylebox_override("panel", frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	var title := Label.new()
	title.name = "Title"
	title.text = "TICKET MACHINE"
	MenuLook.apply_label(title, TITLE_PX, MenuLook.ACCENT)
	column.add_child(title)
	_tickets_label = Label.new()
	_tickets_label.name = "Tickets"
	MenuLook.apply_label(_tickets_label, ROW_PX)
	column.add_child(_tickets_label)
	_price_label = Label.new()
	_price_label.name = "Price"
	MenuLook.apply_label(_price_label, ROW_PX, MenuLook.DIM)
	column.add_child(_price_label)
	_buy = Button.new()
	_buy.name = "BuyButton"
	MenuLook.apply_button(_buy, ROW_PX, Control.SIZE_SHRINK_BEGIN)
	_buy.pressed.connect(_on_buy)
	column.add_child(_buy)
	refresh()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
		if _flash <= 0.0:
			refresh()


func place(view: Vector2, f: float) -> void:
	reset_size()
	position = Vector2(MARGIN * f, view.y - size.y - MARGIN * f)


func refresh() -> void:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or _buy == null:
		return
	_tickets_label.text = "TICKETS: %d" % int(run.call("ticket_count"))
	_price_label.text = "Reroll a floor item at the same rarity."
	_buy.text = "BUY  %d" % int(run.call("ticket_price"))
	_buy.disabled = not bool(run.call("can_buy_ticket"))


func _on_buy() -> void:
	var run := get_node_or_null("/root/AxelRun")
	if run == null:
		return
	if not bool(run.call("buy_ticket")):
		_buy.text = "Not enough"
		_flash = 0.8
		return
	refresh()
