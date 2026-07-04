extends SceneTree
## Dumps the combat play-area layout rects at portrait size to diagnose
## side-panel overflow. Run: godot --headless -s tools/probes/combat_layout_probe.gd

func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var packed := load("res://combat/combat_test.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	root.size = Vector2i(720, 1560)
	for i in range(120):
		await process_frame
	var ct := scene as Control
	print("scene size=", ct.size)
	var play := ct.get_node_or_null("PlayArea") as Control
	if play != null:
		print("play_area pos=", play.position, " size=", play.size)
		for child in play.get_children():
			var c := child as Control
			if c == null:
				continue
			print("  ", c.name, " pos=", c.position, " size=", c.size, " min=", c.custom_minimum_size, " combined_min=", c.get_combined_minimum_size())
			for sub in c.get_children():
				var s := sub as Control
				if s == null:
					continue
				print("    ", s.name, " pos=", s.position, " size=", s.size, " combined_min=", s.get_combined_minimum_size())
	var items := ct.get_node_or_null("PlayArea/PlayRow/ItemPickerPanel") as Control
	if items != null:
		_dump_min(items, "  ")
		var header := items.find_child("SectionHeader", true, false) as Label
		if header != null:
			print("tree header text=", header.text,
				" font=", header.get_theme_font_size("font_size"),
				" overrun=", header.text_overrun_behavior,
				" path=", header.get_path())
		var meta_header = items.get_meta("header") if items.has_meta("header") else null
		if meta_header is Label and is_instance_valid(meta_header):
			var chain := ""
			var n: Node = meta_header
			while n != null:
				chain = "/" + n.name + chain
				n = n.get_parent()
			print("meta header text=", (meta_header as Label).text,
				" font=", (meta_header as Label).get_theme_font_size("font_size"),
				" same=", meta_header == header,
				" inside_tree=", (meta_header as Label).is_inside_tree(),
				" chain=", chain)
		else:
			print("meta header invalid or missing: ", meta_header)
	quit(0)


func _dump_min(node: Control, indent: String) -> void:
	print(indent, node.name, " (", node.get_class(), ") combined_min=", node.get_combined_minimum_size())
	for child in node.get_children():
		var c := child as Control
		if c != null:
			_dump_min(c, indent + "  ")
