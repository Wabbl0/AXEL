extends SceneTree

func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	await process_frame
	var failures: Array[String] = []
	var settings := root.get_node_or_null("AxelSettings")
	if settings == null:
		push_error("graphics_preset_check: AxelSettings missing")
		quit(1)
		return
	var original := String(settings.call("get_value", "video", "graphics_quality", "high"))
	settings.call("set_value", "video", "graphics_quality", "low")
	var low: Vector2i = settings.call("diorama_size")
	if low != Vector2i(960, 640):
		failures.append("low diorama size %s" % low)
	settings.call("set_value", "video", "graphics_quality", "medium")
	var mid: Vector2i = settings.call("diorama_size")
	if mid.x >= 1920:
		failures.append("medium diorama should be cheaper than high")
	settings.call("set_value", "video", "graphics_quality", "high")
	var high: Vector2i = settings.call("diorama_size")
	if high != Vector2i(1920, 1280):
		failures.append("high diorama size %s" % high)
	settings.call("set_value", "video", "graphics_quality", original)
	if failures.is_empty():
		print("Graphics preset check OK.")
		quit(0)
	else:
		for f in failures:
			push_error("graphics_preset_check: %s" % f)
		quit(1)
