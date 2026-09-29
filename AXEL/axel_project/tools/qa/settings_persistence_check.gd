extends SceneTree

const PROBE_SECTION := "audio"
const PROBE_KEY := "master_volume"


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	await process_frame
	var failures: Array[String] = []
	var settings := root.get_node_or_null("AxelSettings")
	if settings == null:
		push_error("settings_persistence_check: AxelSettings autoload not found")
		quit(1)
		return


	_assert_locked(settings, failures)
	_assert_combat_speed(settings, failures)
	if Engine.max_fps != 0:
		failures.append("FPS cap should stay off, got %s" % Engine.max_fps)
	_assert_rebinds_ignored(settings, failures)

	var default_volume: float = settings.get_value(PROBE_SECTION, PROBE_KEY)
	if default_volume < 0.0:
		failures.append("default for %s/%s should be at least 0, got %s" % [PROBE_SECTION, PROBE_KEY, default_volume])

	var signal_hits: Array = []
	settings.setting_changed.connect(func(section: String, key: String) -> void:
		signal_hits.append("%s/%s" % [section, key])
	)

	var original: float = settings.get_value(PROBE_SECTION, PROBE_KEY)
	var probe_value := original + 0.25
	settings.set_value(PROBE_SECTION, PROBE_KEY, probe_value)
	if not signal_hits.has("%s/%s" % [PROBE_SECTION, PROBE_KEY]):
		failures.append("setting_changed did not fire for %s/%s" % [PROBE_SECTION, PROBE_KEY])

	await process_frame
	await process_frame
	var cold := ConfigFile.new()
	var err := cold.load(settings.SETTINGS_PATH)
	if err != OK:
		failures.append("could not load %s after save (err %d)" % [settings.SETTINGS_PATH, err])
	elif not is_equal_approx(float(cold.get_value(PROBE_SECTION, PROBE_KEY, -1.0)), probe_value):
		failures.append("cold read expected %s, got %s" % [probe_value, cold.get_value(PROBE_SECTION, PROBE_KEY, -1.0)])

	settings.set_value(PROBE_SECTION, PROBE_KEY, original)
	await process_frame
	await process_frame

	if failures.is_empty():
		print("Settings persistence check OK.")
		quit(0)
	else:
		for f in failures:
			push_error("settings_persistence_check: %s" % f)
		quit(1)


func _assert_locked(settings: Node, failures: Array[String]) -> void:
	if not is_equal_approx(float(settings.get_value("gameplay", "text_speed_cps")), 35.0):
		failures.append("dialogue speed should stay at 35")
	settings.set_value("gameplay", "text_speed_cps", 12.0)
	if not is_equal_approx(float(settings.get_value("gameplay", "text_speed_cps")), 35.0):
		failures.append("dialogue speed should ignore writes")
	settings.set_value("video", "crt_enabled", false)
	if not bool(settings.get_value("video", "crt_enabled")):
		failures.append("CRT should stay on")
	settings.set_value("video", "fps_cap", 30)
	if int(settings.get_value("video", "fps_cap")) != 0:
		failures.append("FPS cap should stay off")
	settings.set_value("video", "ui_scale", 1.5)
	if not is_equal_approx(float(settings.get_value("video", "ui_scale")), 1.0):
		failures.append("UI scale should stay at 1")
	settings.set_value("gameplay", "auto_advance", false)
	if not bool(settings.get_value("gameplay", "auto_advance")):
		failures.append("auto-advance should stay on")
	settings.set_value("access", "reduce_flashing", true)
	if bool(settings.get_value("access", "reduce_flashing")):
		failures.append("reduce flashing should stay off")
	settings.set_value("access", "screen_shake", 0.0)
	if not is_equal_approx(float(settings.get_value("access", "screen_shake")), 1.0):
		failures.append("screen shake should stay full")
	settings.set_value("access", "glitch_intensity", 0.0)
	if not is_equal_approx(float(settings.get_value("access", "glitch_intensity")), 1.0):
		failures.append("glitch intensity should stay full")


func _assert_combat_speed(settings: Node, failures: Array[String]) -> void:
	var had: bool = settings._config.has_section_key("gameplay", "combat_speed")
	var original := String(settings.get_value("gameplay", "combat_speed"))
	if original != "slow" and original != "normal" and original != "fast":
		failures.append("combat speed should be slow, normal, or fast, got %s" % original)
	settings.set_value("gameplay", "combat_speed", "fast")
	if String(settings.get_value("gameplay", "combat_speed")) != "fast":
		failures.append("combat speed should save fast")
	settings.set_value("gameplay", "combat_speed", "slow")
	if String(settings.get_value("gameplay", "combat_speed")) != "slow":
		failures.append("combat speed should save slow")
	if had:
		settings.set_value("gameplay", "combat_speed", original)
	elif settings._config.has_section_key("gameplay", "combat_speed"):
		settings._config.erase_section_key("gameplay", "combat_speed")
		settings._queue_save()


func _assert_rebinds_ignored(settings: Node, failures: Array[String]) -> void:
	var before := _events_text("move_up")
	var had: bool = settings._config.has_section_key("controls", "move_up")
	var old: Variant = settings._config.get_value("controls", "move_up") if had else null
	var poke := InputEventKey.new()
	poke.keycode = KEY_F13
	settings._config.set_value("controls", "move_up", [poke])
	settings._apply_input_overrides()
	if _events_text("move_up") != before:
		failures.append("saved rebind was applied")
	if had:
		settings._config.set_value("controls", "move_up", old)
	elif settings._config.has_section_key("controls", "move_up"):
		settings._config.erase_section_key("controls", "move_up")


func _events_text(action: String) -> String:
	var parts: PackedStringArray = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEvent:
			parts.append((ev as InputEvent).as_text())
	return "|".join(parts)
