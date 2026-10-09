extends SceneTree

const SCENE_PATH := "res://combat/combat_test.tscn"
const WINDOW := Vector2i(1920, 1280)

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_SFX", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("could not load %s" % SCENE_PATH)
		_finish()
		return
	var vp := SubViewport.new()
	vp.size = WINDOW
	root.add_child(vp)
	var scene := packed.instantiate() as Control
	vp.add_child(scene)
	if not scene.is_node_ready():
		await scene.ready
	for i in 16:
		await process_frame
	scene.set_process(false)
	var skull := scene.find_child("PremiumSkull", true, false) as Control
	var piece := scene.find_child("NEW_Execute", true, false) as Control
	if skull == null or piece == null:
		_fail("PremiumSkull or NEW_Execute missing")
		_finish()
		return
	if skull.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("PremiumSkull must ignore the mouse so NEW_Execute owns the click")
	var settings := root.get_node_or_null("AxelSettings")
	var calm_before := false
	if settings != null:
		calm_before = bool(settings.call("get_value", "access", "reduce_flashing", false))
		settings.call("set_value", "access", "reduce_flashing", false)
	await _check_ready_busy(skull)
	await _check_hover_forward(skull, piece)
	await _check_gulp(skull)
	await _check_fire(skull, settings)
	await _check_nudge(skull)
	if settings != null:
		settings.call("set_value", "access", "reduce_flashing", calm_before)
	scene.queue_free()
	vp.queue_free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("Skull feel check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("skull_feel_check: %s" % msg)
	quit(1)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _stage_alpha(skull: Control) -> float:
	var stage := skull.get_node_or_null("SkullStage1") as CanvasItem
	return stage.modulate.a if stage != null else -1.0


func _check_ready_busy(skull: Control) -> void:
	skull.call("set_ready", false, false)
	await _wait(0.4)
	var busy := _stage_alpha(skull)
	if absf(busy - 0.5) > 0.06:
		_fail("busy skull should fade to about 0.5 alpha, got %.2f" % busy)
	skull.call("set_ready", true, false)
	await _wait(0.4)
	var ready_alpha := _stage_alpha(skull)
	if ready_alpha < 0.95:
		_fail("ready skull should be fully opaque, got %.2f" % ready_alpha)


func _check_hover_forward(skull: Control, piece: Control) -> void:
	piece.call("_on_mouse_entered")
	await _wait(0.35)
	if not bool(skull.get("_hovering")):
		_fail("hovering NEW_Execute did not reach the skull")
	var hover_scale := float(skull.get("_hover_scale"))
	if hover_scale < 1.05:
		_fail("ready hover should grow the skull, got %.3f" % hover_scale)
	if not bool(skull.call("is_chip_showing")):
		_fail("hover should show the spin chip")
	var glow := skull.get_node_or_null("Glow") as CanvasItem
	if glow == null or not glow.visible:
		_fail("hover should light the rim glow")
	piece.call("_on_mouse_exited")
	await _wait(0.35)
	if bool(skull.get("_hovering")):
		_fail("leaving NEW_Execute did not clear skull hover")


func _check_gulp(skull: Control) -> void:
	skull.call("set_fill", 0.0)
	skull.call("set_fill", 1.0 / 3.0)
	if int(skull.call("burst_amount")) != 24:
		_fail("first meter section should burst 24 embers, got %d" % int(skull.call("burst_amount")))
	await _wait(0.05)
	var punch: Vector2 = skull.get("_punch")
	if punch.x <= 1.01:
		_fail("meter fill should punch the skull up, got %s" % punch)
	skull.call("set_fill", 2.0 / 3.0)
	if int(skull.call("burst_amount")) != 40:
		_fail("second meter section should burst 40 embers, got %d" % int(skull.call("burst_amount")))
	skull.call("set_fill", 0.0)
	await _wait(0.8)


func _check_fire(skull: Control, settings: Node) -> void:
	skull.call("play_fire")
	if float(skull.get("_flash")) <= 0.5:
		_fail("fire should flash the skull")
	await _wait(0.6)
	if settings == null:
		return
	settings.call("set_value", "access", "reduce_flashing", true)
	if not bool(settings.call("get_value", "access", "reduce_flashing", false)):
		return
	skull.call("play_fire")
	if float(skull.get("_flash")) > 0.01:
		_fail("reduce flashing should block the fire flash")
	settings.call("set_value", "access", "reduce_flashing", false)
	await _wait(0.6)


func _check_nudge(skull: Control) -> void:
	skull.call("set_ready", true, true)
	skull.set("_idle_time", 5.95)
	await _wait(0.2)
	if not bool(skull.call("is_chip_showing")):
		_fail("idle nudge should show the spin chip")
	skull.call("set_ready", false, true)
	await _wait(0.3)
	if bool(skull.call("is_chip_showing")):
		_fail("busy skull should hide the spin chip")
