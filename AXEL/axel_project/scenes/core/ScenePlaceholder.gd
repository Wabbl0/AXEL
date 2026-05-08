extends Control

@export var scene_id: String = ""
@export var location_label: String = ""
@export var dialogue: PackedStringArray = PackedStringArray()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.modulate = Color(0, 0, 0, 1)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var id_label := Label.new()
	id_label.text = scene_id
	id_label.modulate = Color(1, 1, 1, 1)
	id_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(id_label)

	var location_text := location_label if location_label != "" else "(NO LOCATION LABEL)"
	var location_node := Label.new()
	location_node.text = location_text
	location_node.modulate = Color(1, 1, 1, 1)
	location_node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(location_node)

	var body := RichTextLabel.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.fit_content = false
	body.scroll_active = true
	body.bbcode_enabled = false
	body.selection_enabled = false
	body.modulate = Color(1, 1, 1, 1)
	body.text = "\n".join(dialogue) if dialogue.size() > 0 else ""
	vbox.add_child(body)
