extends SceneTree


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	await process_frame
	var failures: Array[String] = []
	var cursor := root.get_node_or_null("AxelCursor")
	if cursor == null:
		failures.append("AxelCursor autoload missing")
		_finish(failures)
		return
	var sprite := cursor.get_node_or_null("AxelCursor/CursorSprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		failures.append("cursor sprite missing")
		_finish(failures)
		return
	if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		failures.append("cursor filter is not nearest")
	var image := sprite.texture.get_image()
	if image.get_height() != 19 or image.get_width() != 19:
		failures.append("cursor texture is %dx%d, expected 19x19" % [image.get_width(), image.get_height()])
	var shown := sprite.scale.y * 16.0
	if absf(shown - 33.0) > 0.05:
		failures.append("cursor body height is %.2f, expected 33" % shown)
	var white := 0
	var outline := 0
	var shadow := 0
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.05:
				continue
			if color.r > 0.9 and color.g > 0.9 and color.b > 0.9 and color.a > 0.9:
				white += 1
			elif color.r > color.g + 0.4 and color.r > color.b + 0.4 and color.a < 0.7:
				outline += 1
			elif color.r < 0.15 and color.g < 0.15 and color.b < 0.15 and color.a > 0.2:
				shadow += 1
	if white < 12:
		failures.append("cursor body is too thin (%d white pixels)" % white)
	if outline < 8:
		failures.append("cursor outline is missing (%d red pixels)" % outline)
	if shadow < 4:
		failures.append("cursor shadow is missing (%d pixels)" % shadow)
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("axel_cursor_check OK")
		quit(0)
	else:
		for failure in failures:
			push_error("axel_cursor_check: %s" % failure)
		quit(1)
