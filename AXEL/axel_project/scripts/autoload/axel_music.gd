extends Node
## Global soundtrack controller for menu/overworld + combat casino layers.
## Matching stems start together and stay sample-locked; only their volumes change.

const MENU_SCENE_PATH := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const MENU_STEM: AudioStreamWAV = preload("res://assets/audio/music/B_Goes_Down_p2.wav")
const OVERWORLD_STEM: AudioStreamWAV = preload("res://assets/audio/music/B_Goes_Down_p1.wav")

const CASINO_DRUMS_P1: AudioStreamWAV = preload("res://assets/audio/music/casino_Drums_p1.wav")
const CASINO_DRUMS_P2: AudioStreamWAV = preload("res://assets/audio/music/casino_Drums_p2.wav")
const CASINO_P1: AudioStreamWAV = preload("res://assets/audio/music/casino_p1.wav")
const CASINO_P2: AudioStreamWAV = preload("res://assets/audio/music/casino_p2.wav")
const CASINO_LIKE_THAT: AudioStreamWAV = preload("res://assets/audio/music/casino_like_that.wav")

const MENU_INDEX := 0
const OVERWORLD_INDEX := 1

const COMBAT_DRUMS_P1_INDEX := 0
const COMBAT_DRUMS_P2_INDEX := 1
const COMBAT_P1_INDEX := 2
const COMBAT_P2_INDEX := 3
const COMBAT_LIKE_THAT_INDEX := 4
const COMBAT_LAYER_COUNT := 5

const MUSIC_BUS := &"Music"
const SILENT_DB := -80.0
const FULL_VOLUME_DB := 0.0
const MENU_FADE_IN_SEC := 10.0
const NEW_GAME_CROSSFADE_SEC := 10.0
const COMBAT_FADE_OUT_SEC := 2.0
const LOOP_WRAP_DETECT_SEC := 0.25
## Audible end of like_that (+ small air) before unmuting drums+p1 mid-loop.
const LIKE_THAT_AUDIBLE_SEC := 2.0

enum MusicState {
	UNSET,
	MENU,
	OVERWORLD,
	COMBAT,
}

enum CombatMix {
	UNSET,
	INTRO,
	WAIT_LOOP,
	LIKE_THAT,
	REGULAR,
	TRINITY,
}

var _player: AudioStreamPlayer
var _sync_stream: AudioStreamSynchronized
var _combat_player: AudioStreamPlayer
var _combat_sync: AudioStreamSynchronized
var _fade_tween: Tween
var _state: MusicState = MusicState.UNSET
var _combat_mix: CombatMix = CombatMix.UNSET
var _music_enabled := true
var _first_win_notified := false
var _combat_last_pos := 0.0
var _combat_ignore_drop := false
var _entering_combat := false


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

	_combat_player = AudioStreamPlayer.new()
	_combat_player.name = "CombatMusicPlayer"
	_combat_player.bus = MUSIC_BUS
	_combat_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_combat_player)

	_combat_sync = AudioStreamSynchronized.new()
	_combat_sync.stream_count = COMBAT_LAYER_COUNT
	_combat_sync.set_sync_stream(COMBAT_DRUMS_P1_INDEX, _make_looped_wav(CASINO_DRUMS_P1))
	_combat_sync.set_sync_stream(COMBAT_DRUMS_P2_INDEX, _make_looped_wav(CASINO_DRUMS_P2))
	_combat_sync.set_sync_stream(COMBAT_P1_INDEX, _make_looped_wav(CASINO_P1))
	_combat_sync.set_sync_stream(COMBAT_P2_INDEX, _make_looped_wav(CASINO_P2))
	_combat_sync.set_sync_stream(COMBAT_LIKE_THAT_INDEX, _make_looped_wav(CASINO_LIKE_THAT))
	_set_combat_volumes_all_silent()

	_combat_player.stream = _combat_sync
	if not _combat_player.finished.is_connected(_on_combat_player_finished):
		_combat_player.finished.connect(_on_combat_player_finished)

	var tree := get_tree()
	if tree == null:
		return
	if not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	call_deferred("_apply_scene_music")


func to_overworld() -> void:
	if not _music_enabled:
		return
	_stop_combat_music()
	_transition_to_overworld()


## Fade out room music, then start casino from the top. Safe to call before a future scene swap.
func to_combat() -> void:
	if not _music_enabled:
		return
	_begin_combat_entry()


func notify_first_win() -> void:
	if not _music_enabled or _state != MusicState.COMBAT:
		return
	if _first_win_notified:
		return
	if _combat_mix == CombatMix.TRINITY:
		return
	_first_win_notified = true
	if _combat_mix == CombatMix.INTRO:
		_combat_mix = CombatMix.WAIT_LOOP
		_combat_ignore_drop = true
		if _combat_player != null and _combat_player.playing:
			_combat_last_pos = _combat_player.get_playback_position()


func notify_trinity() -> void:
	if not _music_enabled or _state != MusicState.COMBAT:
		return
	_first_win_notified = true
	_apply_combat_mix(CombatMix.TRINITY)


## Restart casino from drums_p1 only (new playtest encounter in the same scene).
func reset_combat_encounter() -> void:
	if not _music_enabled:
		return
	if _state != MusicState.COMBAT:
		return
	_first_win_notified = false
	_restart_combat_from_intro()


func _process(_delta: float) -> void:
	if not _music_enabled or _state != MusicState.COMBAT:
		return
	if _combat_player == null or not _combat_player.playing:
		return
	if _combat_mix != CombatMix.WAIT_LOOP and _combat_mix != CombatMix.LIKE_THAT:
		return

	var pos := _combat_player.get_playback_position()
	if _combat_ignore_drop:
		_combat_last_pos = pos
		_combat_ignore_drop = false
		return

	if _combat_mix == CombatMix.LIKE_THAT and pos >= LIKE_THAT_AUDIBLE_SEC:
		## Stems stay sample-locked; unmute drums+p1 mid-loop to keep the beat without long silence.
		_apply_combat_mix(CombatMix.REGULAR)
		_combat_last_pos = pos
		return

	if pos + LOOP_WRAP_DETECT_SEC < _combat_last_pos:
		if _combat_mix == CombatMix.WAIT_LOOP:
			_apply_combat_mix(CombatMix.LIKE_THAT)
			_combat_ignore_drop = true
		elif _combat_mix == CombatMix.LIKE_THAT:
			_apply_combat_mix(CombatMix.REGULAR)
			_combat_ignore_drop = true
	_combat_last_pos = pos


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

	if path == MENU_SCENE_PATH:
		_stop_combat_music()
		## New Game starts the crossfade while the menu is still current.
		if _state == MusicState.OVERWORLD:
			return
		if resumed and _state == MusicState.MENU:
			_set_layer_volumes(FULL_VOLUME_DB, SILENT_DB)
		_transition_to_menu(true)
		return

	if _is_combat_path(path):
		_begin_combat_entry()
		return

	if _state == MusicState.COMBAT or _entering_combat:
		_stop_combat_music()

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
	if _state == MusicState.COMBAT and not _entering_combat:
		return
	if _entering_combat:
		return
	_entering_combat = true
	_first_win_notified = false
	_kill_fade_tween()

	var from_menu_lin := 0.0
	var from_overworld_lin := 0.0
	if _sync_stream != null:
		from_menu_lin = _db_to_linear(_sync_stream.get_sync_stream_volume(MENU_INDEX))
		from_overworld_lin = _db_to_linear(_sync_stream.get_sync_stream_volume(OVERWORLD_INDEX))

	if from_menu_lin <= 0.0002 and from_overworld_lin <= 0.0002:
		_finish_combat_entry()
		return

	_fade_tween = get_tree().create_tween().bind_node(self)
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_method(
		func(t: float) -> void:
			_apply_layer_linear(
				lerpf(from_menu_lin, 0.0, t),
				lerpf(from_overworld_lin, 0.0, t)
			),
		0.0,
		1.0,
		COMBAT_FADE_OUT_SEC
	)
	_fade_tween.finished.connect(_finish_combat_entry, CONNECT_ONE_SHOT)


func _finish_combat_entry() -> void:
	_entering_combat = false
	_kill_fade_tween()
	_set_layer_volumes(SILENT_DB, SILENT_DB)
	if _player != null and _player.playing:
		_player.stop()
	_state = MusicState.COMBAT
	_restart_combat_from_intro()


func _restart_combat_from_intro() -> void:
	if _combat_player == null or _combat_sync == null:
		return
	_set_combat_volumes_all_silent()
	_combat_player.stream = _combat_sync
	_combat_player.play(0.0)
	_combat_ignore_drop = true
	_combat_last_pos = 0.0
	_apply_combat_mix(CombatMix.INTRO)


func _stop_combat_music() -> void:
	_entering_combat = false
	_combat_mix = CombatMix.UNSET
	_first_win_notified = false
	_set_combat_volumes_all_silent()
	if _combat_player != null and _combat_player.playing:
		_combat_player.stop()


func _apply_combat_mix(mix: CombatMix) -> void:
	_combat_mix = mix
	match mix:
		CombatMix.INTRO, CombatMix.WAIT_LOOP:
			_set_combat_layer_volumes(
				FULL_VOLUME_DB, SILENT_DB, SILENT_DB, SILENT_DB, SILENT_DB
			)
		CombatMix.LIKE_THAT:
			_set_combat_layer_volumes(
				SILENT_DB, SILENT_DB, SILENT_DB, SILENT_DB, FULL_VOLUME_DB
			)
		CombatMix.REGULAR:
			_set_combat_layer_volumes(
				FULL_VOLUME_DB, SILENT_DB, FULL_VOLUME_DB, SILENT_DB, SILENT_DB
			)
		CombatMix.TRINITY:
			_set_combat_layer_volumes(
				SILENT_DB, FULL_VOLUME_DB, FULL_VOLUME_DB, FULL_VOLUME_DB, SILENT_DB
			)
		_:
			_set_combat_volumes_all_silent()


func _set_combat_volumes_all_silent() -> void:
	_set_combat_layer_volumes(SILENT_DB, SILENT_DB, SILENT_DB, SILENT_DB, SILENT_DB)


func _set_combat_layer_volumes(
	drums_p1_db: float,
	drums_p2_db: float,
	p1_db: float,
	p2_db: float,
	like_that_db: float
) -> void:
	if _combat_sync == null:
		return
	_combat_sync.set_sync_stream_volume(COMBAT_DRUMS_P1_INDEX, drums_p1_db)
	_combat_sync.set_sync_stream_volume(COMBAT_DRUMS_P2_INDEX, drums_p2_db)
	_combat_sync.set_sync_stream_volume(COMBAT_P1_INDEX, p1_db)
	_combat_sync.set_sync_stream_volume(COMBAT_P2_INDEX, p2_db)
	_combat_sync.set_sync_stream_volume(COMBAT_LIKE_THAT_INDEX, like_that_db)


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
	if _state == MusicState.COMBAT:
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
	if _is_fading():
		return
	match _state:
		MusicState.MENU:
			_set_layer_volumes(FULL_VOLUME_DB, SILENT_DB)
		MusicState.OVERWORLD:
			_set_layer_volumes(SILENT_DB, FULL_VOLUME_DB)
		_:
			_set_layer_volumes(SILENT_DB, SILENT_DB)


func _on_combat_player_finished() -> void:
	if not _music_enabled or _state != MusicState.COMBAT:
		return
	if _combat_player == null or _combat_sync == null:
		return
	_combat_ignore_drop = true
	_combat_player.play(0.0)
	_apply_combat_mix(_combat_mix)


static func _is_combat_path(path: String) -> bool:
	return not path.is_empty() and path.begins_with("res://combat/")


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
