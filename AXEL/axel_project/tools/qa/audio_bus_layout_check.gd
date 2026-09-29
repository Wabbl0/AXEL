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
			var expected_db := linear_to_db(0.5)
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
