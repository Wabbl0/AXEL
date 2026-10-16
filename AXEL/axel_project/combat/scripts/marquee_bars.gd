class_name MarqueeBars
extends RefCounted

const RED := Color(0.86, 0.08, 0.08, 1.0)
const DIM_RED := Color(0.45, 0.03, 0.03, 1.0)
const WHITE := Color(1.0, 1.0, 1.0, 1.0)
const BAR_HEIGHT := 5.0
const BULB_GAP := 28.0
const BULB_SIZE := 9.0


static func draw_bar(ci: CanvasItem, y: float, x0: float, x1: float, grow: float, from_left: bool, alpha: float, t: float, step_sec: float) -> void:
	var full := x1 - x0
	if full <= 0.0:
		return
	var reach := full * grow
	var rect := Rect2(x0, y - BAR_HEIGHT * 0.5, reach, BAR_HEIGHT)
	if not from_left:
		rect.position.x = x1 - reach
	ci.draw_rect(rect, Color(RED.r, RED.g, RED.b, alpha))
	var step := int(floor(t / maxf(step_sec, 0.001)))
	var dir := 1 if from_left else -1
	var count := int(floor(full / BULB_GAP))
	for i in count + 1:
		var bx := x0 + float(i) * BULB_GAP
		if bx < rect.position.x - 0.5 or bx > rect.end.x + 0.5:
			continue
		var lit := posmod(i - step * dir, 3) == 0
		var c := WHITE if lit else DIM_RED
		c.a = alpha
		ci.draw_rect(Rect2(bx - BULB_SIZE * 0.5, y - BAR_HEIGHT * 0.5 - BULB_SIZE - 4.0, BULB_SIZE, BULB_SIZE), c)
		ci.draw_rect(Rect2(bx - BULB_SIZE * 0.5, y + BAR_HEIGHT * 0.5 + 4.0, BULB_SIZE, BULB_SIZE), c)
