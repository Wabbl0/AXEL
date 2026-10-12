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
	var combat := scene.get_node_or_null("%CombatRoot")
	if skull == null or combat == null:
		_fail("PremiumSkull or CombatRoot missing")
		_finish()
		return
	_check_layer(skull)
	await _check_fill_steps(skull)
	await _check_spit_ignores_reset(skull)
	await _check_signals(skull, combat)
	scene.queue_free()
	vp.queue_free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("Skull fluid check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("skull_fluid_check: %s" % msg)
	quit(1)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _level(skull: Control) -> float:
	return float(skull.call("fluid_level"))


func _check_layer(skull: Control) -> void:
	var layer := skull.call("fluid_layer") as CanvasLayer
	if layer == null:
		_fail("skull fluid layer was not built")
		return
	if layer.layer != 95:
		_fail("skull fluid should sit on layer 95 (above noir 90, below scanline 105), got %d" % layer.layer)
	var fluid := layer.find_child("SkullFluid", true, false) as ColorRect
	if fluid == null or not (fluid.material is ShaderMaterial):
		_fail("SkullFluid rect with shader material missing")


func _check_fill_steps(skull: Control) -> void:
	skull.call("set_fill", 0.0)
	await _wait(0.7)
	for step in [1.0 / 3.0, 2.0 / 3.0, 1.0]:
		skull.call("set_fill", step)
		await _wait(0.05)
		if _level(skull) >= step - 0.001 and step > 0.34:
			_fail("fluid should rise smoothly, not jump to %.2f" % step)
		await _wait(0.7)
		if absf(_level(skull) - step) > 0.01:
			_fail("fluid should settle at %.2f, got %.3f" % [step, _level(skull)])
	var layer := skull.call("fluid_layer") as CanvasLayer
	var fluid := layer.find_child("SkullFluid", true, false) as ColorRect
	if fluid != null and not fluid.visible:
		_fail("full fluid should be visible")
	if fluid != null:
		var mat := fluid.material as ShaderMaterial
		if absf(float(mat.get_shader_parameter("level")) - 1.0) > 0.01:
			_fail("shader level should follow the fluid, got %s" % str(mat.get_shader_parameter("level")))


func _check_spit_ignores_reset(skull: Control) -> void:
	skull.call("set_fill", 1.0)
	await _wait(0.7)
	skull.call("play_spit", true)
	if not bool(skull.call("is_spitting")):
		_fail("play_spit should start a spit")
	skull.call("set_fill", 0.0)
	await _wait(0.2)
	if int(skull.call("spit_amount")) != 90:
		_fail("big spit should throw 90 drops, got %d" % int(skull.call("spit_amount")))
	if not bool(skull.call("is_spitting")):
		_fail("meter reset mid-spit should not cut the spit short")
	await _wait(0.8)
	if bool(skull.call("is_spitting")):
		_fail("spit should finish within about 1 second")
	if _level(skull) > 0.001:
		_fail("spit should leave the skull empty, got %.3f" % _level(skull))


func _check_signals(skull: Control, combat: Node) -> void:
	skull.call("set_fill", 0.0)
	await _wait(0.1)
	combat.emit_signal("vice_round_cleared")
	if not bool(skull.call("is_spitting")):
		_fail("vice_round_cleared should make the skull spit")
	await _wait(1.0)
	combat.emit_signal("free_spins_bonus_granted", 2)
	if not bool(skull.call("is_spitting")):
		_fail("free_spins_bonus_granted should make the skull spit")
	await _wait(0.2)
	if int(skull.call("spit_amount")) != 36:
		_fail("Free Spins bonus spit should be small (36 drops), got %d" % int(skull.call("spit_amount")))
	await _wait(0.8)
