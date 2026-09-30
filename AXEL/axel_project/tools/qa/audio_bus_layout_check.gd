extends SceneTree

const EXPECTED_SENDS := {
	"Music": "Master",
	"Effects": "Master",
	"Typewriter": "Effects",
	"TypewriterOpen": "Effects",
	"CombatSfx": "Effects",
	"UiSfx": "Effects",
}


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	await process_frame
	var failures: Array[String] = []

	for bus_name: String in EXPECTED_SENDS:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx < 0:
			failures.append("missing bus '%s'" % bus_name)
			continue
		var send := String(AudioServer.get_bus_send(idx))
		if send != EXPECTED_SENDS[bus_name]:
			failures.append("bus '%s' sends to '%s', expected '%s'" % [bus_name, send, EXPECTED_SENDS[bus_name]])

	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx < 0:
		failures.append("missing Master bus")
	elif AudioServer.is_bus_mute(master_idx):
		failures.append("Master ships MUTED — un-mute it in the Audio panel before committing default_bus_layout.tres")
	else:
		_check_master_loudness(master_idx, failures)


	var settings := root.get_node_or_null("AxelSettings")
	if settings == null:
		failures.append("AxelSettings autoload not found")
	else:
		if master_idx >= 0:
			_assert_master_fader_kept(settings, master_idx, failures)
			var original_mute := AudioServer.is_bus_mute(master_idx)
			AudioServer.set_bus_mute(master_idx, true)
			settings._bus_volumes_applied = false
			settings._apply_bus_volumes()
			if not AudioServer.is_bus_mute(master_idx):
				failures.append("AxelSettings volume apply unmuted Master (Audio panel work-mute must stick on boot)")


			var original_master: float = settings.master_volume()
			if original_master > 0.001:
				AudioServer.set_bus_mute(master_idx, false)
				settings._bus_volumes_applied = true
				settings.set_value("audio", "master_volume", 0.0)
				if not AudioServer.is_bus_mute(master_idx):
					failures.append("master_volume=0 should mute Master")
				settings.set_value("audio", "master_volume", original_master)
				if AudioServer.is_bus_mute(master_idx):
					failures.append("master_volume>0 should unmute Master after an Options change")
			AudioServer.set_bus_mute(master_idx, original_mute)
		var effects_idx := AudioServer.get_bus_index("Effects")
		if effects_idx >= 0:
			var original: float = settings.get_value("audio", "effects_volume")
			settings.set_value("audio", "effects_volume", 0.5)
			var effects_base := float(settings._layout_volume_db.get("Effects", 0.0))
			var expected_db := effects_base + linear_to_db(0.5)
			var live_db := AudioServer.get_bus_volume_db(effects_idx)
			if absf(live_db - expected_db) > 0.01:
				failures.append("AxelSettings effects_volume=0.5 -> Effects at %.3f dB, expected %.3f dB" % [live_db, expected_db])
			settings.set_value("audio", "effects_volume", original)

	if failures.is_empty():
		print("Audio bus layout check OK (%d buses)." % AudioServer.bus_count)
		quit(0)
	else:
		for f in failures:
			push_error("audio_bus_layout_check: %s" % f)
		quit(1)


func _check_master_loudness(master_idx: int, failures: Array[String]) -> void:
	if AudioServer.get_bus_effect_count(master_idx) < 2:
		failures.append("Master needs a compressor, then a limiter")
		return
	var compressor := AudioServer.get_bus_effect(master_idx, 0)
	if not compressor is AudioEffectCompressor or not AudioServer.is_bus_effect_enabled(master_idx, 0):
		failures.append("Master effect 0 must be an enabled compressor")
	elif absf((compressor as AudioEffectCompressor).gain - 12.0) > 0.05:
		failures.append("Master compressor gain is %.2f dB, expected +12 dB" % (compressor as AudioEffectCompressor).gain)
	var limiter := AudioServer.get_bus_effect(master_idx, 1)
	if not limiter is AudioEffectHardLimiter or not AudioServer.is_bus_effect_enabled(master_idx, 1):
		failures.append("Master effect 1 must be an enabled hard limiter after the compressor")
	elif absf((limiter as AudioEffectHardLimiter).pre_gain_db) > 0.05:
		failures.append("Master limiter pre-gain is %.2f dB, expected 0" % (limiter as AudioEffectHardLimiter).pre_gain_db)


func _assert_master_fader_kept(settings: Node, master_idx: int, failures: Array[String]) -> void:
	var text := FileAccess.get_file_as_string("res://default_bus_layout.tres")
	var file_db := _tres_bus_volume_db(text, 0)
	if is_nan(file_db):
		failures.append("default_bus_layout.tres has no Master volume_db")
		return
	var saved_volume: float = settings.master_volume()
	var saved_mute := AudioServer.is_bus_mute(master_idx)
	settings._bus_volumes_applied = true
	settings.set_value("audio", "master_volume", 1.0)
	settings._apply_bus_volumes()
	var live_db := AudioServer.get_bus_volume_db(master_idx)
	if absf(live_db - file_db) > 0.05:
		failures.append("Master fader %.3f dB was replaced; live is %.3f dB" % [file_db, live_db])
	var captured := float(settings._layout_volume_db.get("Master", 999.0))
	if absf(captured - file_db) > 0.05:
		failures.append("captured Master fader %.3f dB, file is %.3f dB" % [captured, file_db])
	if not settings._reload_authored_bus_layout():
		failures.append("could not reload default_bus_layout.tres")
	else:
		live_db = AudioServer.get_bus_volume_db(master_idx)
		if absf(live_db - file_db) > 0.05:
			failures.append("reload Master is %.3f dB, file is %.3f dB" % [live_db, file_db])
		var file_mute := _tres_bus_muted(text, 0)
		if AudioServer.is_bus_mute(master_idx) != file_mute:
			failures.append("reload Master mute does not match the layout")
	settings.set_value("audio", "master_volume", saved_volume)
	settings._bus_volumes_applied = true
	settings._apply_bus_volumes()
	AudioServer.set_bus_mute(master_idx, saved_mute)


func _tres_bus_volume_db(text: String, bus_index: int) -> float:
	var key := "bus/%d/volume_db =" % bus_index
	var at := text.find(key)
	if at < 0:
		return NAN
	var rest := text.substr(at + key.length()).strip_edges()
	var line := rest.split("\n", true, 1)[0].strip_edges()
	return float(line)


func _tres_bus_muted(text: String, bus_index: int) -> bool:
	var start := text.find("bus/%d/" % bus_index)
	if start < 0:
		return false
	var next := text.find("bus/%d/" % (bus_index + 1))
	var chunk := text.substr(start, (next - start) if next > start else -1)
	return chunk.contains("mute = true")
