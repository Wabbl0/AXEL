extends SceneTree

const OVERLAY := "res://scenes/ui/TopDialogueOverlay.tscn"
const WINDOW := Vector2i(1920, 1280)
const SHADOW := Color(0.04, 0.04, 0.04, 1.0)
const BACKDROP := Color(0.75, 0.75, 0.75, 1.0)


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_POST_FX", "1")
	call_deferred("_main")


func _main() -> void:
	var failures: Array[String] = []
	root.size = WINDOW
	var backdrop := ColorRect.new()
	backdrop.name = "ShadowCheckBackdrop"
	backdrop.color = BACKDROP
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	await process_frame

	var overlay := (load(OVERLAY) as PackedScene).instantiate() as CanvasLayer
	overlay.set("fx_crt_power", false)
	overlay.set("fx_char_scramble", false)
	overlay.set("fx_line_swap_glitch", false)
	root.add_child(overlay)
	var shown := false
	_open_line(overlay)
	var panel := overlay.get_node("ViewportRoot/RootMargin/BarPanel") as PanelContainer
	var fade := overlay.get_node("ViewportRoot/RootMargin") as Control
	for _i in 180:
		await process_frame
		var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
		if (
			style != null
			and style.shadow_size >= 1
			and style.shadow_size <= 4
			and style.shadow_offset.x < 0.0
			and fade.visible
			and fade.modulate.a > 0.99
			and str(overlay.get("_active_line_text")) == "Shadow."
		):
			shown = true
			break
	if not shown:
		failures.append("dialogue bar did not open with its shadow")
		_finish(failures)
		return

	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		failures.append("dialogue panel style missing")
		_finish(failures)
		return
	if panel.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		failures.append("dialogue bar takes the mouse")
	if absf(style.shadow_color.r - SHADOW.r) > 0.04 \
			or absf(style.shadow_color.g - SHADOW.g) > 0.04 \
			or absf(style.shadow_color.b - SHADOW.b) > 0.04 \
			or style.shadow_color.a < 0.9:
		failures.append("shadow color is %s" % style.shadow_color)
	if style.shadow_size < 1 or style.shadow_size > 4:
		failures.append("shadow size is %d" % style.shadow_size)
	if style.shadow_offset.x > -1.0 or style.shadow_offset.x < -6.0 or style.shadow_offset.y < 1.0 or style.shadow_offset.y > 6.0:
		failures.append("shadow offset is %s" % style.shadow_offset)
	if style.anti_aliasing:
		failures.append("shadow edge is smoothed")

	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		_check_pixels(failures, panel, style)
	else:
		print("dialogue_bar_shadow_check: skipped pixels (headless).")

	if overlay.has_method("interrupt_line"):
		overlay.interrupt_line()
	_finish(failures)


func _open_line(overlay: Node) -> void:
	await overlay.type_line("Shadow.", 400.0, false)


func _check_pixels(failures: Array[String], panel: Control, style: StyleBoxFlat) -> void:
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("no frame to measure")
		return
	var rect := panel.get_global_rect()
	var center := _pixel(image, rect.get_center())
	if center.r > 0.08 or center.g > 0.08 or center.b > 0.08:
		failures.append("bar center is %s, expected black" % center)
	var below := rect.get_center() + Vector2(0.0, rect.size.y * 0.5 + 2.0)
	var shadow_px := _pixel(image, below)
	if not _near_shadow(shadow_px):
		failures.append("pixel under the bar is %s at %s, expected the dark shadow" % [shadow_px, below])
	var left := Vector2(rect.position.x - 2.0, rect.get_center().y)
	var left_px := _pixel(image, left)
	if not _near_shadow(left_px):
		failures.append("pixel left of the bar is %s at %s, expected the dark shadow" % [left_px, left])
	var right := rect.get_center() + Vector2(rect.size.x * 0.5 + 8.0, 0.0)
	var right_px := _pixel(image, right)
	if not _near_backdrop(right_px):
		failures.append("pixel right of the bar is %s, expected no shadow spill" % right_px)
	var clear := rect.position + Vector2(-16.0, rect.size.y * 0.5)
	var clear_px := _pixel(image, clear)
	if not _near_backdrop(clear_px):
		failures.append("shadow spills too far left: %s" % clear_px)
	var frame_path := ProjectSettings.globalize_path("user://dialogue_bar_shadow_check.png")
	image.save_png(frame_path)
	print(
		"dialogue shadow pixels center=%s below=%s left=%s right=%s clear=%s offset=%s size=%d frame=%s"
		% [center, shadow_px, left_px, right_px, clear_px, style.shadow_offset, style.shadow_size, frame_path]
	)


func _pixel(image: Image, point: Vector2) -> Color:
	var x := clampi(int(point.x), 0, image.get_width() - 1)
	var y := clampi(int(point.y), 0, image.get_height() - 1)
	return image.get_pixel(x, y)


func _near_shadow(color: Color) -> bool:
	return absf(color.r - SHADOW.r) < 0.02 \
		and absf(color.g - SHADOW.g) < 0.02 \
		and absf(color.b - SHADOW.b) < 0.02 \
		and color.a > 0.9


func _near_backdrop(color: Color) -> bool:
	return absf(color.r - BACKDROP.r) < 0.08 \
		and absf(color.g - BACKDROP.g) < 0.08 \
		and absf(color.b - BACKDROP.b) < 0.08


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Dialogue bar shadow check OK.")
		quit(0)
		return
	for msg in failures:
		push_error("dialogue_bar_shadow_check: %s" % msg)
	quit(1)
