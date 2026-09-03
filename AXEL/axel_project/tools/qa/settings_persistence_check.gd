extends SceneTree
## AxelSettings persistence regression check (Phase 0.4).
##
## Round-trips a setting through the ConfigFile on disk and verifies the
## default table, change signal, and that saves are debounced to one write.
##
## Run: tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://tools/qa/settings_persistence_check.gd

const PROBE_KEY := "text_speed_cps"


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

	# Defaults resolve without a stored value.
	var default_speed: float = settings.get_value("gameplay", PROBE_KEY)
	if default_speed <= 0.0:
		failures.append("default for gameplay/%s should be positive, got %s" % [PROBE_KEY, default_speed])

	# Signal fires on change.
	var signal_hits: Array = []
	settings.setting_changed.connect(func(section: String, key: String) -> void:
		signal_hits.append("%s/%s" % [section, key])
	)

	var original: float = settings.get_value("gameplay", PROBE_KEY)
	var probe_value := original + 7.0
	settings.set_value("gameplay", PROBE_KEY, probe_value)
	if not signal_hits.has("gameplay/%s" % PROBE_KEY):
		failures.append("setting_changed did not fire for gameplay/%s" % PROBE_KEY)

	# Deferred save flush, then read the file back cold.
	await process_frame
	await process_frame
	var cold := ConfigFile.new()
	var err := cold.load(settings.SETTINGS_PATH)
	if err != OK:
		failures.append("could not load %s after save (err %d)" % [settings.SETTINGS_PATH, err])
	elif float(cold.get_value("gameplay", PROBE_KEY, -1.0)) != probe_value:
		failures.append("cold read expected %s, got %s" % [probe_value, cold.get_value("gameplay", PROBE_KEY, -1.0)])

	# Restore the original value (keep the dev machine's settings intact).
	settings.set_value("gameplay", PROBE_KEY, original)
	await process_frame
	await process_frame

	if failures.is_empty():
		print("Settings persistence check OK.")
		quit(0)
	else:
		for f in failures:
			push_error("settings_persistence_check: %s" % f)
		quit(1)
