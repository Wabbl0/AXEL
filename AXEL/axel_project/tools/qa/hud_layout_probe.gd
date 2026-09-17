extends SceneTree

const SCENE_PATH := "res://combat/combat_test.tscn"
const PLATE := Vector2(3508.0, 2480.0)
const WINDOW := Vector2i(1920, 1280)

var _canvas_inv := Transform2D()


func _initialize() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load %s" % SCENE_PATH)
		quit(1)
		return

	var vp := SubViewport.new()
	vp.size = WINDOW
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var scene := packed.instantiate()
	vp.add_child(scene)
	_run(scene)


func _run(scene: Node) -> void:
	for i in 12:
		await process_frame
	var canvas := scene.get_node_or_null("HudCanvas") as Control
	if canvas == null:
		push_error("HudCanvas missing")
		quit(1)
		return
	_canvas_inv = canvas.get_global_transform().affine_inverse()

	print("=== VIEWPORT / CANVAS ===")
	print("viewport            : %s" % str(WINDOW))
	print("scene.size          : %s" % str((scene as Control).size))
	print("HudCanvas.position  : %s" % str(canvas.position))
	print("HudCanvas.size      : %s" % str(canvas.size))
	print("HudCanvas.scale     : %s" % str(canvas.scale))
	print("plate               : %s" % str(PLATE))

	print("\n=== PIECES (drawing-pixel space, plate is 0,0 - 3508,2480) ===")
	_dump_pieces(canvas)

	print("\n=== WIDGET HOSTS vs THEIR MOVE_TextBox (screen space) ===")
	_dump_hosts(scene)

	print("\n=== GRID CHAIN ===")
	_dump_grid(scene)

	quit(0)


func _dump_pieces(canvas: Control) -> void:
	var stack: Array[Node] = [canvas]
	var rows: Array[Dictionary] = []
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.push_back(child)
		var ctrl := node as Control
		if ctrl == null or ctrl == canvas:
			continue
		var n := ctrl.name
		if not (n.begins_with("NEW_") or n.begins_with("MOVE_") or n.begins_with("Art") or n == "SkullStage1"):
			continue
		rows.append({"ctrl": ctrl, "rect": _plate_rect(ctrl)})
	rows.sort_custom(func(a, b): return (a["rect"] as Rect2).position.y < (b["rect"] as Rect2).position.y)
	for row in rows:
		var ctrl: Control = row["ctrl"]
		var r: Rect2 = row["rect"]
		print("%-46s %s  %s" % [
			_short_path(ctrl),
			_fmt_rect(r),
			_flag(r, ctrl),
		])


func _plate_rect(ctrl: Control) -> Rect2:
	var xf := _canvas_inv * ctrl.get_global_transform()
	return Rect2(xf.origin, ctrl.size * xf.get_scale())


func _flag(r: Rect2, ctrl: Control) -> String:
	var notes: Array[String] = []
	if r.size.x <= 1.0 or r.size.y <= 1.0:
		notes.append("ZERO-SIZE")
	if r.position.x < -0.5 or r.position.y < -0.5:
		notes.append("OFF-PLATE(top/left)")
	if r.position.x + r.size.x > PLATE.x + 0.5 or r.position.y + r.size.y > PLATE.y + 0.5:
		notes.append("OFF-PLATE(bottom/right)")
	if not ctrl.visible:
		notes.append("hidden")
	return "  <-- " + ", ".join(notes) if not notes.is_empty() else ""


func _dump_hosts(scene: Node) -> void:
	var layer := scene.get_node_or_null("WidgetLayer")
	if layer == null:
		layer = scene.find_child("WidgetLayer", true, false)
	if layer == null:
		print("(no WidgetLayer)")
		return
	var widget_root := layer.get_node_or_null("WidgetRoot") as Control
	if widget_root == null:
		print("(no WidgetRoot)")
		return
	for host in widget_root.get_children():
		var h := host as Control
		if h == null:
			continue
		var kids: Array[String] = []
		for k in h.get_children():
			kids.append("%s(%s)" % [k.name, k.get_class()])
		print("%-24s gpos=%s size=%s scale=%s  children=[%s]" % [
			h.name,
			_fmt_v(h.global_position),
			_fmt_v(h.size),
			_fmt_v(h.scale),
			", ".join(kids),
		])


func _dump_grid(scene: Node) -> void:
	var grid_host := scene.find_child("GridHost", true, false) as Control
	if grid_host != null:
		print("GridHost      gpos=%s size=%s scale=%s" % [
			_fmt_v(grid_host.global_position), _fmt_v(grid_host.size), _fmt_v(grid_host.scale)])

	var combat := scene.find_child("CombatRoot", true, false) as Node2D
	if combat == null:
		print("(no CombatRoot)")
		return
	print("CombatRoot    pos=%s" % _fmt_v(combat.position))
	var grid_ui := combat.get_node_or_null("GridUI") as Control
	if grid_ui != null:
		print("GridUI        pos=%s size=%s children=%d" % [
			_fmt_v(grid_ui.position), _fmt_v(grid_ui.size), grid_ui.get_child_count()])
		var first := grid_ui.get_child(0) as Control
		if first != null:
			print("GridUI cell0  %-14s pos=%s size=%s" % [
				first.name, _fmt_v(first.position), _fmt_v(first.size)])


func _short_path(ctrl: Control) -> String:
	var parts := str(ctrl.get_path()).split("/")
	var tail: Array[String] = []
	for i in range(maxi(0, parts.size() - 3), parts.size()):
		tail.append(parts[i])
	return "/".join(tail)


func _fmt_rect(r: Rect2) -> String:
	return "x %7.1f  y %7.1f   w %7.1f  h %7.1f" % [r.position.x, r.position.y, r.size.x, r.size.y]


func _fmt_v(v: Vector2) -> String:
	return "(%.1f, %.1f)" % [v.x, v.y]
