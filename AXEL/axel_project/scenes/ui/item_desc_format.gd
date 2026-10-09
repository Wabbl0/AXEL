class_name ItemDescFormat

const NUMBER_COLOR := Color(1.0, 0.16, 0.16)
const NUMBER_PATTERN := "(?<![A-Za-z0-9])[+-]?[x×]?\\d+(?:\\.\\d+)?%?(?:[x×](?![A-Za-z]))?"

static var _regex: RegEx


static func colorize_numbers(text: String, color: Color = NUMBER_COLOR) -> String:
	if _regex == null:
		_regex = RegEx.new()
		_regex.compile(NUMBER_PATTERN)
	var hex := color.to_html(false)
	var out := ""
	var at := 0
	for m in _regex.search_all(text):
		out += _escape(text.substr(at, m.get_start() - at))
		out += "[color=#%s]%s[/color]" % [hex, _escape(m.get_string())]
		at = m.get_end()
	out += _escape(text.substr(at))
	return out


static func make_label(node_name: String, font_px: int, width: float) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.name = node_name
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("normal_font", MenuLook.FONT)
	label.add_theme_color_override("default_color", MenuLook.TEXT)
	apply_size(label, font_px, width)
	return label


static func apply_size(label: RichTextLabel, font_px: int, width: float) -> void:
	label.add_theme_font_size_override("normal_font_size", font_px)
	label.custom_minimum_size = Vector2(width, 0.0)
	label.custom_maximum_size = Vector2(width, -1.0)


static func set_text(label: RichTextLabel, plain: String) -> void:
	label.text = colorize_numbers(plain)


static func _escape(part: String) -> String:
	return part.replace("[", "[lb]")
