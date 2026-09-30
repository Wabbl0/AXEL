extends Node

const MENU_SCENE_PATH := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const MENU_STEM: AudioStream = preload("res://assets/audio/music/B_Goes_Down_p2.ogg")
const OVERWORLD_STEM: AudioStream = preload("res://assets/audio/music/B_Goes_Down_p1.ogg")
const DRUMS1_STEM: AudioStream = preload("res://assets/audio/music/B_Goes_Down_Drums_p1.wav")
const DRUMS2_STEM: AudioStream = preload("res://assets/audio/music/B_Goes_Down_Drums_p2_fixed.wav")

const MENU_INDEX := 0
const OVERWORLD_INDEX := 1
const DRUMS1_INDEX := 2
const DRUMS2_INDEX := 3

const MUSIC_BUS := &"Music"
const SILENT_DB := -80.0
const FULL_VOLUME_DB := 0.0
const MENU_FADE_IN_SEC := 10.0
const NEW_GAME_CROSSFADE_SEC := 10.0
const DRUM_FADE_IN_SEC := 0.35
const VICE_DRUM_FADE_IN_SEC := 1.0
const VICE_DRUM_FADE_SEC := 0.5

enum MusicState {
	UNSET,
	MENU,
	OVERWORLD,
	COMBAT,
}

var _player: AudioStreamPlayer
var _sync_stream: AudioStreamSynchronized
var _fade_tween: Tween
var _drums1_tween: Tween
var _drums2_tween: Tween
var _state: MusicState = MusicState.UNSET
var _music_enabled := true
var _drums2_up := false


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
	_sync_stream.stream_count = 4
	_sync_stream.set_sync_stream(MENU_INDEX, _make_looped(MENU_STEM))
	_sync_stream.set_sync_stream(OVERWORLD_INDEX, _make_looped(OVERWORLD_STEM))
	_sync_stream.set_sync_stream(DRUMS1_INDEX, _make_looped(DRUMS1_STEM))
	_sync_stream.set_sync_stream(DRUMS2_INDEX, _make_looped(DRUMS2_STEM))
	_set_stream_db(MENU_INDEX, SILENT_DB)
	_set_stream_db(OVERWORLD_INDEX, SILENT_DB)
	_set_stream_db(DRUMS1_INDEX, SILENT_DB)
	_set_stream_db(DRUMS2_INDEX, SILENT_DB)

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
	_silence_combat_drums()
	_transition_to_overworld()


func to_combat() -> void:
	if not _music_enabled:
		return
	_begin_combat_entry()


func set_frozen(frozen: bool) -> void:
	if _player == null:
		return
	_player.stream_paused = frozen


func notify_trinity() -> void:
	if not _music_enabled or _state != MusicState.COMBAT:
		return
	_drums2_up = true
	_fade_drums2(FULL_VOLUME_DB, VICE_DRUM_FADE_IN_SEC)


func notify_trinity_ended(keep_for_free_spins: bool) -> void:
	if not _music_enabled or _state != MusicState.COMBAT:
		return
	if keep_for_free_spins:
		return
	_drums2_up = false
	_fade_drums2(SILENT_DB, VICE_DRUM_FADE_SEC)


func notify_free_spins_ended() -> void:
	if not _music_enabled or _state != MusicState.COMBAT:
		return
	_drums2_up = false
	_fade_drums2(SILENT_DB, VICE_DRUM_FADE_SEC)


func reset_combat_encounter() -> void:
	if not _music_enabled or _state != MusicState.COMBAT:
		return
	if not _drums2_up:
		return
	_drums2_up = false
	_fade_drums2(SILENT_DB, VICE_DRUM_FADE_SEC)


func _on_scene_changed() -> void:
	call_deferred("_apply_scene_music")


func _apply_scene_music() -> void:
	if not _music_enabled or _sync_stream == null:
		return

	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var path := tree.current_scene.scene_file_path
	var resumed := _ensure_player_active()

	if path == MENU_SCENE_PATH or path.begins_with("res://scenes/Main_Menu/"):
		if _state == MusicState.COMBAT:
			_silence_combat_drums()
		if _state == MusicState.OVERWORLD:
			return
		if resumed and _state == MusicState.MENU:
			_set_layer_volumes(FULL_VOLUME_DB, SILENT_DB)
		_transition_to_menu(true)
		return

	if _is_combat_path(path):
		_begin_combat_entry()
		return

	if _state == MusicState.COMBAT:
		_silence_combat_drums()
		_state = MusicState.OVERWORLD
		if _is_fading():
			return
		_fade_layers(SILENT_DB, FULL_VOLUME_DB, NEW_GAME_CROSSFADE_SEC)
		return

	if _is_fading():
		return

	if _state == MusicState.OVERWORLD:
		if resumed:
			_set_layer_volumes(SILENT_DB, FULL_VOLUME_DB)
		return

	_transition_to_overworld()


func _begin_combat_entry() -> void:
	if not _music_enabled:
		return
	if _state == MusicState.COMBAT:
		return
	_state = MusicState.COMBAT
	_drums2_up = false
	_ensure_player_active()
	_fade_layers(SILENT_DB, FULL_VOLUME_DB, NEW_GAME_CROSSFADE_SEC)
	_fade_drums1(FULL_VOLUME_DB, DRUM_FADE_IN_SEC)
	_fade_drums2(SILENT_DB, 0.0)


func _silence_combat_drums() -> void:
	_drums2_up = false
	_fade_drums1(SILENT_DB, NEW_GAME_CROSSFADE_SEC)
	_fade_drums2(SILENT_DB, NEW_GAME_CROSSFADE_SEC)


func _fade_drums1(target_db: float, duration: float) -> void:
	_drums1_tween = _start_layer_fade(DRUMS1_INDEX, target_db, duration, _drums1_tween)


func _fade_drums2(target_db: float, duration: float) -> void:
	_drums2_tween = _start_layer_fade(DRUMS2_INDEX, target_db, duration, _drums2_tween)


func _start_layer_fade(index: int, target_db: float, duration: float, active: Tween) -> Tween:
	if _sync_stream == null:
		return null
	if active != null and active.is_valid():
		active.kill()
	var from_lin := _db_to_linear(_sync_stream.get_sync_stream_volume(index))
	var to_lin := _db_to_linear(target_db)
	if is_equal_approx(from_lin, to_lin) or duration <= 0.0:
		_set_stream_linear(index, to_lin)
		return null
	var tree := get_tree()
	if tree == null:
		_set_stream_linear(index, to_lin)
		return null
	var layer := index
	var tw := tree.create_tween().bind_node(self)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(
		func(t: float) -> void:
			_set_stream_linear(layer, lerpf(from_lin, to_lin, t)),
		0.0,
		1.0,
		duration
	)
	return tw


func _transition_to_menu(use_fade: bool) -> void:
	if _state == MusicState.MENU:
		return
	_state = MusicState.MENU
	_ensure_player_active()
	if use_fade:
		_fade_layers(FULL_VOLUME_DB, SILENT_DB, MENU_FADE_IN_SEC)
	else:
		_set_layer_volumes(FULL_VOLUME_DB, SILENT_DB)


func _transition_to_overworld() -> void:
	if _state == MusicState.OVERWORLD:
		return
	_state = MusicState.OVERWORLD
	_ensure_player_active()
	_fade_layers(SILENT_DB, FULL_VOLUME_DB, NEW_GAME_CROSSFADE_SEC)


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


func _set_stream_db(index: int, db: float) -> void:
	_set_stream_linear(index, _db_to_linear(db))


func _set_stream_linear(index: int, linear: float) -> void:
	if _sync_stream == null:
		return
	_sync_stream.set_sync_stream_volume(index, _linear_to_db(linear))


func _kill_fade_tween() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _is_fading() -> bool:
	return _fade_tween != null and _fade_tween.is_valid() and _fade_tween.is_running()


func _is_tween_running(tw: Tween) -> bool:
	return tw != null and tw.is_valid() and tw.is_running()


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
	_player.play()
	return true


func _on_player_finished() -> void:
	if not _music_enabled:
		return
	if _state == MusicState.COMBAT:
		return
	_ensure_player_active()
	if not _is_fading():
		match _state:
			MusicState.MENU:
				_set_layer_volumes(FULL_VOLUME_DB, SILENT_DB)
			MusicState.OVERWORLD:
				_set_layer_volumes(SILENT_DB, FULL_VOLUME_DB)
			_:
				_set_layer_volumes(SILENT_DB, SILENT_DB)
	if not _is_tween_running(_drums1_tween):
		_set_stream_db(DRUMS1_INDEX, SILENT_DB)
	if not _is_tween_running(_drums2_tween):
		_set_stream_db(DRUMS2_INDEX, SILENT_DB)


static func _is_combat_path(path: String) -> bool:
	return not path.is_empty() and path.begins_with("res://combat/")


static func _music_disabled() -> bool:
	return OS.has_environment("AXEL_DISABLE_MUSIC") and OS.get_environment("AXEL_DISABLE_MUSIC") == "1"


static func _make_looped(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamWAV:
		return _make_looped_wav(stream as AudioStreamWAV)
	if stream is AudioStreamOggVorbis:
		var ogg := (stream as AudioStreamOggVorbis).duplicate(true) as AudioStreamOggVorbis
		if ogg == null:
			return stream
		ogg.loop = true
		return ogg
	return stream


static func _make_looped_wav(stream: AudioStreamWAV) -> AudioStreamWAV:
	var looped := stream.duplicate(true) as AudioStreamWAV
	if looped == null:
		return stream

	looped.loop_mode = AudioStreamWAV.LOOP_FORWARD
	looped.loop_begin = 0
	looped.loop_end = _wav_frame_count(looped)
	return looped


static func _wav_frame_count(stream: AudioStreamWAV) -> int:
	return int(round(stream.get_length() * float(stream.mix_rate)))
