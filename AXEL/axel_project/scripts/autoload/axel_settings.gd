extends Node
## AxelSettings — player settings persistence + boot-time apply (Phase 0.4).
##
## - Stored in `user://axel_settings.cfg` (ConfigFile), fully separate from save
##   slots: deleting a save (D8 permadeath) never touches player settings.
## - Loaded in _enter_tree so values apply before the first frame paints.
## - Consumers read via get_value/typed helpers and listen to `setting_changed`.
## - Custom input bindings are stored under [controls] as serialized InputEvents
##   and applied over the project InputMap at boot (rebinding UI lands with the
##   Options screen; the storage contract lives here).
##
## Sections/keys in use (D4). Only add keys that a real feature reads:
##   audio/master_volume, audio/music_volume, audio/effects_volume  (linear 0..1)
##   video/window_mode ("windowed"|"borderless"|"fullscreen")
##   video/vsync (bool), video/fps_cap (int, 0 = uncapped)
##   video/crt_enabled (bool), video/graphics_quality ("low"|"medium"|"high")
##   video/ui_scale (float 0.75..1.5)
##   gameplay/text_speed_cps (float), gameplay/auto_advance (bool)
##   access/reduce_flashing (bool), access/screen_shake (float 0..1),
##   access/glitch_intensity (float 0..1)
##   controls/<action> (Array[InputEvent])

signal setting_changed(section: String, key: String)

const SETTINGS_PATH := "user://axel_settings.cfg"
## Actions the player may rebind. ui_* engine actions stay engine-owned.
const REBINDABLE_ACTIONS: PackedStringArray = [
	"move_up", "move_down", "move_left", "move_right",
	"interact", "dialogue_advance", "back", "pause",
]

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
	},
	"access": {
		"reduce_flashing": false,
		"screen_shake": 1.0,
		"glitch_intensity": 1.0,
	},
}

var _config := ConfigFile.new()
var _save_queued := false


func _enter_tree() -> void:
	var err := _config.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("AxelSettings: could not read %s (err %d); using defaults." % [SETTINGS_PATH, err])
		_config = ConfigFile.new()
	_apply_all()


func get_value(section: String, key: String, default: Variant = null) -> Variant:
	if default == null and DEFAULTS.has(section) and (DEFAULTS[section] as Dictionary).has(key):
		default = DEFAULTS[section][key]
	return _config.get_value(section, key, default)


func set_value(section: String, key: String, value: Variant) -> void:
	if _config.has_section_key(section, key) and _config.get_value(section, key) == value:
		return
	_config.set_value(section, key, value)
	_queue_save()
	_apply_one(section, key)
	setting_changed.emit(section, key)


## --- Typed conveniences (only for values with live consumers) ---


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


## --- Input rebinding storage ---


func store_action_binding(action: String, events: Array) -> void:
	if not REBINDABLE_ACTIONS.has(action):
		push_warning("AxelSettings: '%s' is not rebindable." % action)
		return
	_config.set_value("controls", action, events)
	_queue_save()
	_apply_action_binding(action, events)
	setting_changed.emit("controls", action)


func clear_action_binding(action: String) -> void:
	if _config.has_section_key("controls", action):
		_config.erase_section_key("controls", action)
		_queue_save()
	# Restore project defaults for this action.
	InputMap.load_from_project_settings()
	_apply_input_overrides()
	setting_changed.emit("controls", action)


## --- Apply ---


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
			pass  # Read-side consumers (dialogue speed, CRT, shake…) poll or listen.


func _apply_window_mode() -> void:
	if DisplayServer.get_name() == "headless":
		return
	# Only override the project default when the player chose something.
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
	_set_bus_linear("Master", master_volume())
	_set_bus_linear("Music", music_volume())
	_set_bus_linear("Effects", effects_volume())


func _set_bus_linear(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return  # Bus tree may not have this bus yet (Effects lands in Phase 0.5).
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)


func _apply_input_overrides() -> void:
	if not _config.has_section("controls"):
		return
	for action in _config.get_section_keys("controls"):
		var events: Variant = _config.get_value("controls", action, [])
		if events is Array:
			_apply_action_binding(String(action), events)


func _apply_action_binding(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		push_warning("AxelSettings: unknown action '%s' in controls overrides." % action)
		return
	InputMap.action_erase_events(action)
	for ev in events:
		if ev is InputEvent:
			InputMap.action_add_event(action, ev)


## --- Save (debounced so slider drags do not hammer the disk) ---


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
