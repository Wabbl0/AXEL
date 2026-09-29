extends Node

signal setting_changed(section: String, key: String)

const SETTINGS_PATH := "user://axel_settings.cfg"
const REBINDABLE_ACTIONS: PackedStringArray = [
	"move_up", "move_down", "move_left", "move_right",
	"interact", "dialogue_advance", "back", "pause",
]
const _UI_MIRROR := {
	"move_up": "ui_up",
	"move_down": "ui_down",
	"move_left": "ui_left",
	"move_right": "ui_right",
	"interact": "ui_accept",
	"back": "ui_cancel",
}

const DEFAULTS := {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 1.0,
		"effects_volume": 1.0,
	},
	"video": {
		"window_mode": "windowed",
		"window_size": "1920x1280",
		"vsync": true,
		"fps_cap": 0,
		"crt_enabled": true,
		"graphics_quality": "high",
		"ui_scale": 1.0,
	},
	"gameplay": {
		"text_speed_cps": 35.0,
		"auto_advance": true,
		"combat_speed": "normal",
	},
	"access": {
		"reduce_flashing": false,
		"screen_shake": 1.0,
		"glitch_intensity": 1.0,
	},
}

var _config := ConfigFile.new()
var _save_queued := false
var _bus_volumes_applied := false


func _enter_tree() -> void:
	var err := _config.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("AxelSettings: could not read %s (err %d); using defaults." % [SETTINGS_PATH, err])
		_config = ConfigFile.new()
	_apply_all()


func get_value(section: String, key: String, default: Variant = null) -> Variant:
	if _is_locked(section, key):
		return (DEFAULTS[section] as Dictionary)[key]
	if default == null and DEFAULTS.has(section) and (DEFAULTS[section] as Dictionary).has(key):
		default = DEFAULTS[section][key]
	return _config.get_value(section, key, default)


func set_value(section: String, key: String, value: Variant) -> void:
	if _is_locked(section, key):
		return
	if _config.has_section_key(section, key) and _config.get_value(section, key) == value:
		return
	_config.set_value(section, key, value)
	_queue_save()
	_apply_one(section, key)
	setting_changed.emit(section, key)


func master_volume() -> float:
	return clampf(float(get_value("audio", "master_volume")), 0.0, 1.0)


func music_volume() -> float:
	return clampf(float(get_value("audio", "music_volume")), 0.0, 1.0)


func effects_volume() -> float:
	return clampf(float(get_value("audio", "effects_volume")), 0.0, 1.0)


func ui_scale() -> float:
	return clampf(float(get_value("video", "ui_scale")), 0.5, 2.0)


func graphics_quality() -> String:
	return String(get_value("video", "graphics_quality", "high")).to_lower()


func diorama_size() -> Vector2i:
	match graphics_quality():
		"low":
			return Vector2i(960, 640)
		"medium":
			return Vector2i(1280, 854)
		_:
			return Vector2i(1920, 1280)


func store_action_binding(action: String, events: Array) -> void:
	if not REBINDABLE_ACTIONS.has(action):
		push_warning("AxelSettings: '%s' is not rebindable." % action)
		return
	_config.set_value("controls", action, events)
	_queue_save()
	_apply_action_binding(action, events)
	_mirror_ui_actions_from_gameplay()
	setting_changed.emit("controls", action)


func clear_action_binding(action: String) -> void:
	if _config.has_section_key("controls", action):
		_config.erase_section_key("controls", action)
		_queue_save()

	InputMap.load_from_project_settings()
	_apply_input_overrides()
	setting_changed.emit("controls", action)


func _apply_all() -> void:
	_apply_window_mode()
	_apply_window_size()
	_apply_vsync()
	_apply_fps_cap()
	_apply_bus_volumes()
	_apply_input_overrides()


func _apply_one(section: String, key: String) -> void:
	match [section, key]:
		["video", "window_mode"]:
			_apply_window_mode()
		["video", "window_size"]:
			_apply_window_size()
		["video", "vsync"]:
			_apply_vsync()
		["video", "fps_cap"]:
			_apply_fps_cap()
		["audio", "master_volume"], ["audio", "music_volume"], ["audio", "effects_volume"]:
			_apply_bus_volumes()
		["video", "graphics_quality"], ["video", "crt_enabled"]:
			pass
		_:
			pass


func _apply_window_mode() -> void:
	if DisplayServer.get_name() == "headless":
		return

	if not _config.has_section_key("video", "window_mode"):
		return
	match String(get_value("video", "window_mode")):
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		_:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			_apply_window_size()


func _apply_window_size() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if String(get_value("video", "window_mode")) != "windowed":
		return
	if not _config.has_section_key("video", "window_size"):
		return
	var parsed := parse_size_string(String(get_value("video", "window_size")))
	if parsed == Vector2i.ZERO:
		return
	DisplayServer.window_set_size(parsed)
	var tree := get_tree()
	if tree != null:
		tree.root.size = parsed


static func parse_size_string(raw: String) -> Vector2i:
	var parts := raw.to_lower().split("x")
	if parts.size() != 2:
		return Vector2i.ZERO
	var w := parts[0].to_int()
	var h := parts[1].to_int()
	if w < 64 or h < 64:
		return Vector2i.ZERO
	return Vector2i(w, h)


func _apply_vsync() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var on := bool(get_value("video", "vsync"))
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED
	)


func _apply_fps_cap() -> void:
	Engine.max_fps = maxi(int(get_value("video", "fps_cap")), 0)


func _apply_bus_volumes() -> void:
	var respect_existing_mute := not _bus_volumes_applied
	_set_bus_linear("Master", master_volume(), respect_existing_mute)
	_set_bus_linear("Music", music_volume(), respect_existing_mute)
	_set_bus_linear("Effects", effects_volume(), respect_existing_mute)
	_bus_volumes_applied = true


func _set_bus_linear(bus_name: String, linear: float, respect_existing_mute: bool = false) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	if linear <= 0.001:
		AudioServer.set_bus_mute(idx, true)
		return
	if respect_existing_mute and AudioServer.is_bus_mute(idx):
		return
	AudioServer.set_bus_mute(idx, false)


func _apply_input_overrides() -> void:
	# Menu rebinds are gone. A saved [controls] block must not replace the project keys.
	_mirror_ui_actions_from_gameplay()


func _is_locked(section: String, key: String) -> bool:
	match section:
		"video":
			return key == "fps_cap" or key == "crt_enabled" or key == "ui_scale"
		"gameplay":
			return key == "text_speed_cps" or key == "auto_advance"
		"access":
			return key == "reduce_flashing" or key == "screen_shake" or key == "glitch_intensity"
		_:
			return false


func _mirror_ui_actions_from_gameplay() -> void:
	# Godot Control focus still reads ui_*; keep those in sync with live gameplay binds.
	for src_var in _UI_MIRROR.keys():
		var src := String(src_var)
		var dst := String(_UI_MIRROR[src])
		if not InputMap.has_action(src) or not InputMap.has_action(dst):
			continue
		InputMap.action_erase_events(dst)
		for ev in InputMap.action_get_events(src):
			if ev is InputEvent:
				var copy := (ev as InputEvent).duplicate() as InputEvent
				if copy != null:
					InputMap.action_add_event(dst, copy)


func _apply_action_binding(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		push_warning("AxelSettings: unknown action '%s' in controls overrides." % action)
		return
	InputMap.action_erase_events(action)
	for ev in events:
		if ev is InputEvent:
			InputMap.action_add_event(action, ev)


func _queue_save() -> void:
	if _save_queued:
		return
	_save_queued = true
	_flush_save.call_deferred()


func _flush_save() -> void:
	_save_queued = false
	var err := _config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("AxelSettings: save failed (err %d)." % err)
