class_name PortraitUi
extends RefCounted

const PHONE_W := 1080.0
const TOP_BAND := 0.07
const BOTTOM_BAND := 0.04


static func view_size(node: Node) -> Vector2:
	var vp := node.get_viewport() if node != null else null
	if vp == null:
		return Vector2(1920.0, 1280.0)
	var size := vp.get_visible_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2(1920.0, 1280.0)
	return size


static func is_portrait(node: Node) -> bool:
	var size := view_size(node)
	return size.x < size.y


static func safe_rect(node: Node) -> Rect2:
	var size := view_size(node)
	if size.x >= size.y:
		return Rect2(Vector2.ZERO, size)
	var top := size.y * TOP_BAND
	var bottom := size.y * BOTTOM_BAND
	if OS.has_feature("mobile"):
		var area := DisplayServer.get_display_safe_area()
		var win := Vector2(DisplayServer.window_get_size())
		if area.size.x > 0 and area.size.y > 0 and win.y > 0.0:
			var k := size.y / win.y
			top = maxf(float(area.position.y) * k, 0.0)
			bottom = maxf((win.y - float(area.end.y)) * k, 0.0)
	return Rect2(Vector2(0.0, top), Vector2(size.x, size.y - top - bottom))


static func width_factor(node: Node) -> float:
	return clampf(view_size(node).x / PHONE_W, 0.5, 2.5) * UiViewportScale.settings_ui_scale(node)


static func boost(node: Node, amount: float) -> float:
	if not is_portrait(node):
		return 1.0
	return width_factor(node) * amount


static func font(node: Node, authored: int, amount: float) -> int:
	if not is_portrait(node):
		return MenuLook.scaled_font(node, authored)
	return maxi(roundi(float(authored) * width_factor(node) * amount), 8)
