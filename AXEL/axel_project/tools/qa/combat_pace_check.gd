extends SceneTree


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	await process_frame
	var failures: Array[String] = []
	var settings := root.get_node_or_null("AxelSettings")
	var pace := root.get_node_or_null("CombatPaceHost")
	if settings == null or pace == null:
		push_error("combat_pace_check: AxelSettings or CombatPaceHost autoload missing")
		quit(1)
		return

	var had: bool = settings._config.has_section_key("gameplay", "combat_speed")
	var original := String(settings.get_value("gameplay", "combat_speed"))
	CombatPace.clear_rush()
	_expect_scale(settings, "normal", 1.0, failures)
	_expect_scale(settings, "slow", 0.5, failures)
	_expect_scale(settings, "fast", 2.0, failures)
	settings.set_value("gameplay", "combat_speed", "nope")
	if not is_equal_approx(CombatPace.multiplier(), 1.0):
		failures.append("unknown combat speed should play at normal, got %s" % CombatPace.multiplier())

	settings.set_value("gameplay", "combat_speed", "fast")
	CombatPace.set_rush(true)
	if not is_equal_approx(CombatPace.multiplier(), 16.0):
		failures.append("fast rush should be 16x, got %s" % CombatPace.multiplier())

	var host := Node2D.new()
	root.add_child(host)
	var tween := host.create_tween()
	tween.pause()
	tween.tween_property(host, "position:x", 100.0, 1.0)
	CombatPace.bind(tween)
	tween.custom_step(0.05)
	var rushed := tween.get_total_elapsed_time()
	if absf(rushed - 0.8) > 0.08:
		failures.append("rush should scale tween time to 0.8s, got %s" % rushed)
	CombatPace.clear_rush()
	var before := tween.get_total_elapsed_time()
	tween.custom_step(0.1)
	var added := tween.get_total_elapsed_time() - before
	if absf(added - 0.2) > 0.04:
		failures.append("clearing rush on fast should step at 2x, added %s" % added)
	if tween.is_valid():
		tween.kill()
	host.queue_free()
	CombatPace.clear_rush()

	if had:
		settings.set_value("gameplay", "combat_speed", original)
	elif settings._config.has_section_key("gameplay", "combat_speed"):
		settings._config.erase_section_key("gameplay", "combat_speed")
		settings._queue_save()
	await process_frame
	await process_frame

	if failures.is_empty():
		print("Combat pace check OK.")
		quit(0)
		return
	for failure in failures:
		push_error("combat_pace_check: %s" % failure)
	quit(1)


func _expect_scale(settings: Node, key: String, expected: float, failures: Array[String]) -> void:
	CombatPace.clear_rush()
	settings.set_value("gameplay", "combat_speed", key)
	var got := CombatPace.multiplier()
	if not is_equal_approx(got, expected):
		failures.append("%s should be %s, got %s" % [key, expected, got])
