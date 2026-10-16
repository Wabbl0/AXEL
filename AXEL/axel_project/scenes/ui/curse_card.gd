class_name CurseCard
extends CanvasLayer

signal closed

const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const CURSE_DIR := "res://combat/data/curses/"
const TITLE_TEXT := "CURSED"
const HINT_TEXT := "Face it"
const INK_RED := Color(0.85, 0.06, 0.06, 1)
const TEXT_WHITE := Color(0.92, 0.88, 0.88, 1)
const SCRIM := Color(0, 0, 0, 0.72)
const CARD_FILL := Color(0.02, 0.01, 0.01, 0.96)
const TITLE_PX := 72
const NAME_PX := 44
const DESC_PX := 32
const HINT_PX := 32
const CARD_W := 900.0
const OPEN_SEC := 0.18
const MIN_SHOW_SEC := 0.4

var curse_ids: Array = []
var _card: PanelContainer
var _shown_at := 0
var _closing := false


static func curse_text(curse_id: String) -> Dictionary:
	var path := "%s%s.tres" % [CURSE_DIR, curse_id]
	if not ResourceLoader.exists(path):
		return {"name": curse_id, "description": ""}
	var def := load(path) as CurseDef
	if def == null:
		return {"name": curse_id, "description": ""}
	var text := def.describe()
	var p := def.merged_params({})
	if p.has("spins"):
		text = text.replace("{left}", str(p["spins"]))
	return {"name": def.name, "description": text}


func _ready() -> void:
	layer = 112
	var f := UiViewportScale.factor(self)
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = SCRIM
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.gui_input.connect(_on_scrim_input)
	add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_card = PanelContainer.new()
	_card.name = "Card"
	var frame := StyleBoxFlat.new()
	frame.bg_color = CARD_FILL
	frame.border_color = INK_RED
	frame.set_border_width_all(maxi(roundi(3.0 * f), 2))
	frame.set_content_margin_all(28.0 * f)
	_card.add_theme_stylebox_override("panel", frame)
	_card.custom_minimum_size = Vector2(CARD_W * f, 0.0)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", roundi(14.0 * f))
	_card.add_child(column)
	column.add_child(_label("Title", TITLE_TEXT, TITLE_PX, INK_RED, f, true))
	for i in curse_ids.size():
		var info := curse_text(String(curse_ids[i]))
		column.add_child(_label("CurseName%d" % (i + 1), String(info["name"]), NAME_PX, INK_RED, f, false))
		var desc := _label("CurseDescription%d" % (i + 1), String(info["description"]), DESC_PX, TEXT_WHITE, f, false)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2((CARD_W - 56.0) * f, 0.0)
		column.add_child(desc)
	column.add_child(_label("Hint", "%s  %s" % [_interact_key_text(), HINT_TEXT], HINT_PX, TEXT_WHITE, f, true))
	_card.pivot_offset = Vector2(CARD_W * f * 0.5, 0.0)
	_card.scale = Vector2(1.0, 0.02)
	var tween := create_tween()
	tween.tween_property(_card, "scale", Vector2.ONE, OPEN_SEC)
	_shown_at = Time.get_ticks_msec()
	var tutorial := get_node_or_null("/root/AxelTutorial")
	if tutorial != null and tutorial.has_method("request"):
		tutorial.call("request", "fight_curse")


func _label(node_name: String, text: String, px: int, color: Color, f: float, centered: bool) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", maxi(roundi(float(px) * f), 12))
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _interact_key_text() -> String:
	for ev in InputMap.action_get_events("interact"):
		if ev is InputEventKey:
			var key := ev as InputEventKey
			var code := key.physical_keycode if int(key.physical_keycode) != 0 else key.keycode
			return "[%s]" % OS.get_keycode_string(code)
	return "[E]"


func _tutorial_open() -> bool:
	var tutorial := get_node_or_null("/root/AxelTutorial")
	return tutorial != null and tutorial.has_method("has_active_card") and bool(tutorial.call("has_active_card"))


func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		close()


func _on_scrim_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		close()


func close() -> void:
	if _closing or _tutorial_open():
		return
	if Time.get_ticks_msec() - _shown_at < int(MIN_SHOW_SEC * 1000.0):
		return
	_closing = true
	var tween := create_tween()
	tween.tween_property(_card, "scale", Vector2(1.0, 0.02), OPEN_SEC * 0.6)
	await tween.finished
	closed.emit()
	queue_free()
