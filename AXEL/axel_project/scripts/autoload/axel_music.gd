extends Node
## Global soundtrack controller for menu/overworld music layers.
## Matching stems start together and stay sample-locked; only their volumes change.

const MENU_SCENE_PATH := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const MENU_STEM: AudioStreamWAV = preload("res://assets/audio/music/B_Goes_Down_p1.wav")
const OVERWORLD_STEM: AudioStreamWAV = preload("res://assets/audio/music/B_Goes_Down_p2.wav")

const MENU_INDEX := 0
const OVERWORLD_INDEX := 1
const MUSIC_BUS := &"Music"
const SILENT_DB := -80.0
const FULL_VOLUME_DB := 0.0
const MENU_FADE_IN_SEC := 10.0

enum MusicState {
	UNSET,
	MENU,
	HOLD_P1,
	OVERWORLD,
}

var _player: AudioStreamPlayer
var _sync_stream: AudioStreamSynchronized
var _fade_tween: Tween
var _state: MusicState = MusicState.UNSET
var _music_enabled := true
var _p1_hold_last_pos := 0.0
var _p1_hold_ignore_drop := false


func _ready() -> void:
	_music_enabled = not _music_disabled()
	if not _music_enabled:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS

	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = MUSIC_BUS
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)

	_sync_stream = AudioStreamSynchronized.new()
	_sync_stream.stream_count = 2
	_sync_stream.set_sync_stream(MENU_INDEX, _make_looped_wav(MENU_STEM))
	_sync_stream.set_sync_stream(OVERWORLD_INDEX, _make_looped_wav(OVERWORLD_STEM))
	_set_layer_volumes(SILENT_DB, SILENT_DB)

	_player.stream = _sync_stream
	if not _player.finished.is_connected(_on_player_finished):
		_player.finished.connect(_on_player_finished)
	_player.play()

	var tree := get_tree()
	if tree == null:
		return
	if not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	call_deferred("_apply_scene_music")


func to_overworld() -> void:
	if not _music_enabled:
		return
	var tree := get_tree()
	if tree != null and tree.current_scene != null and tree.current_scene.scene_file_path != MENU_SCENE_PATH:
		_begin_p1_hold()


func _process(_delta: float) -> void:
	if not _music_enabled or _state != MusicState.HOLD_P1 or _player == null:
		return
	if not _player.playing:
		return

	var pos := _player.get_playback_position()
	if _p1_hold_ignore_drop:
		_p1_hold_last_pos = pos
		_p1_hold_ignore_drop = false
		return

	if pos + 0.25 < _p1_hold_last_pos:
		_transition_to_overworld()
		return
	_p1_hold_last_pos = pos


func _on_scene_changed() -> void:
	call_deferred("_apply_scene_music")


func _apply_scene_music() -> void:
	if not _music_enabled or _sync_stream == null:
		return

	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var resumed := _ensure_player_active()
	if _is_fading():
		return

	if tree.current_scene.scene_file_path == MENU_SCENE_PATH:
		if resumed and _state == MusicState.MENU:
			_set_layer_volumes(FULL_VOLUME_DB, SILENT_DB)
		_transition_to_menu(true)
		return

	if _state == MusicState.OVERWORLD:
		if resumed:
			_set_layer_volumes(SILENT_DB, FULL_VOLUME_DB)
		return

	if resumed and _state == MusicState.HOLD_P1:
		_p1_hold_ignore_drop = true
		_set_layer_volumes(FULL_VOLUME_DB, SILENT_DB)
		return

	_begin_p1_hold()


func _transition_to_menu(use_fade: bool) -> void:
	if _state == MusicState.MENU:
		return
	_state = MusicState.MENU
	if use_fade:
		_fade_layers(FULL_VOLUME_DB, SILENT_DB, MENU_FADE_IN_SEC)
	else:
		_set_layer_volumes(FULL_VOLUME_DB, SILENT_DB)


func _begin_p1_hold() -> void:
	if _state == MusicState.HOLD_P1 or _state == MusicState.OVERWORLD:
		return
	_state = MusicState.HOLD_P1
	_set_layer_volumes(FULL_VOLUME_DB, SILENT_DB)
	_p1_hold_ignore_drop = true
	_p1_hold_last_pos = 0.0
	if _player != null and _player.playing:
		_p1_hold_last_pos = _player.get_playback_position()


func _transition_to_overworld() -> void:
	if _state == MusicState.OVERWORLD:
		return
	_state = MusicState.OVERWORLD
	_set_layer_volumes(SILENT_DB, FULL_VOLUME_DB)


func _fade_layers(menu_db: float, overworld_db: float, duration: float) -> void:
	if _sync_stream == null:
		return
	_kill_fade_tween()

	var from_menu_lin := _db_to_linear(_sync_stream.get_sync_stream_volume(MENU_INDEX))
	var from_overworld_lin := _db_to_linear(_sync_stream.get_sync_stream_volume(OVERWORLD_INDEX))
	var to_menu_lin := _db_to_linear(menu_db)
	var to_overworld_lin := _db_to_linear(overworld_db)
	if is_equal_approx(from_menu_lin, to_menu_lin) and is_equal_approx(from_overworld_lin, to_overworld_lin):
		return

	## One clock, both stems: linear amplitude so they overlap instead of dipping to silence.
	_fade_tween = get_tree().create_tween().bind_node(self)
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_method(
		func(t: float) -> void:
			_apply_layer_linear(
				lerpf(from_menu_lin, to_menu_lin, t),
				lerpf(from_overworld_lin, to_overworld_lin, t)
			),
		0.0,
		1.0,
		duration
	)


func _set_layer_volumes(menu_db: float, overworld_db: float) -> void:
	if _sync_stream == null:
		return
	_kill_fade_tween()
	_apply_layer_linear(_db_to_linear(menu_db), _db_to_linear(overworld_db))


func _apply_layer_linear(menu_linear: float, overworld_linear: float) -> void:
	if _sync_stream == null:
		return
	_sync_stream.set_sync_stream_volume(MENU_INDEX, _linear_to_db(menu_linear))
	_sync_stream.set_sync_stream_volume(OVERWORLD_INDEX, _linear_to_db(overworld_linear))


func _kill_fade_tween() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _is_fading() -> bool:
	return _fade_tween != null and _fade_tween.is_valid() and _fade_tween.is_running()


static func _db_to_linear(db: float) -> float:
	return db_to_linear(db)


static func _linear_to_db(linear: float) -> float:
	return linear_to_db(maxf(linear, 0.0001))


func _ensure_player_active() -> bool:
	if _player == null or _sync_stream == null:
		return false
	if _player.stream != _sync_stream:
		_player.stream = _sync_stream
	if _player.playing:
		return false
	_p1_hold_ignore_drop = true
	_player.play()
	return true


func _on_player_finished() -> void:
	if not _music_enabled:
		return
	_ensure_player_active()
	if _is_fading():
		return
	match _state:
		MusicState.MENU, MusicState.HOLD_P1:
			_set_layer_volumes(FULL_VOLUME_DB, SILENT_DB)
		MusicState.OVERWORLD:
			_set_layer_volumes(SILENT_DB, FULL_VOLUME_DB)
		_:
			_set_layer_volumes(SILENT_DB, SILENT_DB)


static func _music_disabled() -> bool:
	return OS.has_environment("AXEL_DISABLE_MUSIC") and OS.get_environment("AXEL_DISABLE_MUSIC") == "1"


static func _make_looped_wav(stream: AudioStreamWAV) -> AudioStreamWAV:
	var looped := stream.duplicate(true) as AudioStreamWAV
	if looped == null:
		return stream

	looped.loop_mode = AudioStreamWAV.LOOP_FORWARD
	looped.loop_begin = 0
	looped.loop_end = _wav_frame_count(looped)
	return looped


static func _wav_frame_count(stream: AudioStreamWAV) -> int:
	var channels: int = 2 if stream.stereo else 1
	var bytes_per_sample: int = 2
	match stream.format:
		AudioStreamWAV.FORMAT_8_BITS:
			bytes_per_sample = 1
		AudioStreamWAV.FORMAT_16_BITS:
			bytes_per_sample = 2
		_:
			bytes_per_sample = 2

	var bytes_per_frame: int = max(1, channels * bytes_per_sample)
	return int(floor(float(stream.data.size()) / float(bytes_per_frame)))
