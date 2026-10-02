extends Node


const COMBAT_BUS := &"CombatSfx"
const UI_BUS := &"UiSfx"
const POOL_SIZE := 8

const PATH_POWER := "res://assets/audio/sfx/power_activate.wav"
const PATH_PAUSE := "res://assets/audio/sfx/pause_open.wav"
const PATH_SKULL := "res://assets/audio/sfx/skull_spin.wav"
const PATH_MATCH := "res://assets/audio/sfx/symbol_match.wav"
const PATH_ROUND := "res://assets/audio/sfx/round_winnings.wav"
const PATH_WHEEL_OPEN := "res://assets/audio/sfx/item_wheel_open.wav"
const PATH_WHEEL_CLICK := "res://assets/audio/sfx/item_wheel_click.wav"
const PATH_COMBAT_TRANSITION := "res://assets/audio/sfx/combat_transition.wav"

var _pool: Array[AudioStreamPlayer] = []
var _pool_i := 0
var _enabled := true
var _stream_power: AudioStream
var _stream_pause: AudioStream
var _stream_skull: AudioStream
var _stream_match: AudioStream
var _stream_round: AudioStream
var _stream_wheel_open: AudioStream
var _stream_wheel_click: AudioStream
var _stream_combat_transition: AudioStream


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enabled = not _sfx_disabled()
	if not _enabled:
		return
	_stream_power = load(PATH_POWER) as AudioStream
	_stream_pause = load(PATH_PAUSE) as AudioStream
	_stream_skull = load(PATH_SKULL) as AudioStream
	_stream_match = load(PATH_MATCH) as AudioStream
	_stream_round = load(PATH_ROUND) as AudioStream
	_stream_wheel_open = load(PATH_WHEEL_OPEN) as AudioStream
	_stream_wheel_click = load(PATH_WHEEL_CLICK) as AudioStream
	_stream_combat_transition = load(PATH_COMBAT_TRANSITION) as AudioStream
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer_%d" % i
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_pool.append(player)


func play(cue: StringName) -> void:
	if not _enabled:
		return
	if DisplayServer.get_name() == "headless":
		return
	var stream: AudioStream = null
	var bus := COMBAT_BUS
	match cue:
		&"power":
			stream = _stream_power
		&"pause":
			stream = _stream_pause
			bus = UI_BUS
		&"spin", &"skull":
			stream = _stream_skull
		&"line_win":
			stream = _stream_match
		&"round_winnings":
			stream = _stream_round
		&"item_wheel_open":
			stream = _stream_wheel_open
			bus = UI_BUS
		&"item_wheel_click":
			stream = _stream_wheel_click
			bus = UI_BUS
		&"combat_transition":
			stream = _stream_combat_transition
			bus = UI_BUS
		_:
			return
	_play_stream(stream, bus)


func play_pause_open() -> void:
	play(&"pause")


func play_skull() -> void:
	play(&"skull")


func _play_stream(stream: AudioStream, bus: StringName) -> void:
	if stream == null or _pool.is_empty():
		return
	var player := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	player.stop()
	player.stream = stream
	player.bus = bus
	player.volume_db = 0.0
	player.play()


func _sfx_disabled() -> bool:
	var env := String(OS.get_environment("AXEL_DISABLE_SFX")).strip_edges().to_lower()
	return env in ["1", "true", "yes", "on"]
