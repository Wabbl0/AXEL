extends SceneTree

const POWER_ACTIVATION_SEC := 1.75


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var failures: Array[String] = []
	var host := Node2D.new()
	root.add_child(host)
	var grid := Control.new()
	grid.name = "GridUI"
	grid.position = Vector2(560, 200)
	grid.size = Vector2(800, 800)
	host.add_child(grid)
	var feel = load("res://combat/scripts/combat_feel.gd").new()
	feel.name = "CombatFeel"
	host.add_child(feel)
	feel.setup(host, grid)
	await process_frame
	var fx := host.find_child("BonusIntroFx", true, false) as Control
	if fx == null:
		failures.append("BonusIntroFx missing under FeelLayer")
		_finish(failures)
		return
	var cues: Array[StringName] = []
	feel.sfx_cue.connect(func(c: StringName) -> void: cues.append(c))
	var icon := load("res://combat/art/grid_symbols/bloody_hand.png") as Texture2D
	var icons: Array[Texture2D] = [icon, icon, icon]

	var secs := await _timed(feel.play_bonus_intro.bind(&"vice", "VICE ROUND", grid, icons))
	if secs < 1.9 or secs > 2.6:
		failures.append("vice intro took %.2fs, expected about 2.15s" % secs)
	if cues.count(&"bonus_slam") != 1:
		failures.append("vice intro sent %d bonus_slam cues, expected 1" % cues.count(&"bonus_slam"))
	if fx.is_playing():
		failures.append("vice intro still playing after its await")

	cues.clear()
	secs = await _timed(feel.play_bonus_intro.bind(&"free_spins", "FREE SPINS"))
	if secs < 1.9 or secs > 2.6:
		failures.append("free spins intro took %.2fs, expected about 2.15s" % secs)
	if cues.count(&"bonus_slam") != 1:
		failures.append("free spins intro sent %d bonus_slam cues, expected 1" % cues.count(&"bonus_slam"))
	if cues.count(&"skull") < 2:
		failures.append("free spins reel sent %d skull ticks, expected at least 2" % cues.count(&"skull"))

	CombatPace.set_rush(true)
	secs = await _timed(feel.play_bonus_intro.bind(&"vice", "VICE ROUND", grid, icons))
	CombatPace.set_rush(false)
	if secs > 0.9:
		failures.append("rushed vice intro took %.2fs, expected under 0.9s" % secs)

	var empty: Array[Texture2D] = []
	secs = await _timed(fx.play.bind(&"free_spins", Rect2(Vector2.ZERO, Vector2(1920, 1280)), "FREE SPINS", empty, true))
	if secs < 1.9 or secs > 2.6:
		failures.append("calm free spins intro took %.2fs" % secs)

	feel.power_pop(Vector2(960, 600), 80.0, "Bloody Hand", "1/3", true)
	await create_timer(2.0).timeout
	if not fx.is_idle():
		failures.append("sparks, rings or pops were left after the effects ended")

	var root_script := load("res://combat/scripts/combat_root.gd") as Script
	var total := float(root_script.get_property_default_value("power_intro_scale_in_sec"))
	total += float(root_script.get_property_default_value("power_intro_hold_sec"))
	total += float(root_script.get_property_default_value("power_intro_scale_out_sec"))
	total += float(root_script.get_script_constant_map().get("POWER_ACT_SEC", 0.0))
	if absf(total - POWER_ACTIVATION_SEC) > 0.001:
		failures.append("power activation is %.2fs, must stay %.2fs" % [total, POWER_ACTIVATION_SEC])
	_finish(failures)


func _timed(call: Callable) -> float:
	var start := Time.get_ticks_msec()
	await call.call()
	return float(Time.get_ticks_msec() - start) / 1000.0


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("Bonus intro fx check OK.")
		quit(0)
	else:
		for f in failures:
			push_error("bonus_intro_fx_check: %s" % f)
		quit(1)
