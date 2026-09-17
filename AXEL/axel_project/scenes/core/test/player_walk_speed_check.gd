extends SceneTree

const WalkSpeed := preload("res://scenes/core/player_walk_speed.gd")
const CoverSync := preload("res://scenes/core/player_cover_sync.gd")
const MockPlayer := preload("res://scenes/core/test/mock_cover_player.gd")
const EPS := 0.1


func _init() -> void:
	call_deferred("_main")


func _fail(msg: String) -> void:
	push_error("PlayerWalkSpeed FAIL: %s" % msg)
	quit(1)


func _main() -> void:

	var at_threshold: float = WalkSpeed.from_scale(WalkSpeed.SMALL_SCALE)
	var expected_threshold: float = WalkSpeed.stride_k() * WalkSpeed.SMALL_SCALE
	if absf(at_threshold - expected_threshold) > EPS:
		_fail(
			"at scale 0.3 speed=%.4f expected %.4f (no extra)"
			% [at_threshold, expected_threshold]
		)
		return


	var mid := 0.2
	var low := 0.1
	var mid_speed: float = WalkSpeed.from_scale(mid)
	var low_speed: float = WalkSpeed.from_scale(low)
	var mid_base: float = WalkSpeed.stride_k() * mid
	var low_base: float = WalkSpeed.stride_k() * low
	var mid_extra: float = mid_speed - mid_base
	var low_extra: float = low_speed - low_base
	if mid_extra <= 0.0 or low_extra <= mid_extra:
		_fail(
			"extra should grow as scale drops; mid_extra=%.4f low_extra=%.4f"
			% [mid_extra, low_extra]
		)
		return


	var s11: float = WalkSpeed.SMALL_ANCHOR_SCALE
	var speed_11: float = WalkSpeed.from_scale(s11)
	var base_11: float = WalkSpeed.stride_k() * s11
	var extra_11: float = speed_11 - base_11
	if absf(extra_11 - WalkSpeed.SMALL_ANCHOR_ADD) > EPS:
		_fail("1.1 extra=%.4f expected %.4f" % [extra_11, WalkSpeed.SMALL_ANCHOR_ADD])
		return


	var kitchen := 0.331
	var kitchen_speed: float = WalkSpeed.from_scale(kitchen)
	var kitchen_expected: float = WalkSpeed.stride_k() * kitchen
	if absf(kitchen_speed - kitchen_expected) > EPS:
		_fail(
			"kitchen speed=%.4f expected %.4f (no extra)"
			% [kitchen_speed, kitchen_expected]
		)
		return


	var shared: float = WalkSpeed.REF_SCALE
	var shared_speed: float = WalkSpeed.from_scale(shared)
	var shared_base: float = WalkSpeed.REF_SPEED
	if shared_speed <= shared_base:
		_fail("shared speed=%.4f should exceed REF_SPEED %.4f" % [shared_speed, shared_base])
		return


	var player: CharacterBody2D = MockPlayer.new()
	player.scale = Vector2(shared, shared)
	player.speed = 1.0
	root.add_child(player)
	var sync = CoverSync.new()
	sync.bind_from_player(player)
	if absf(sync.authored_speed - shared_speed) > EPS:
		_fail(
			"bind_from_player authored_speed=%.4f expected %.4f"
			% [sync.authored_speed, shared_speed]
		)
		return
	if absf(float(player.speed) - shared_speed) > EPS:
		_fail("bind_from_player player.speed=%.4f expected %.4f" % [player.speed, shared_speed])
		return

	print(
		"PlayerWalkSpeed check OK (threshold=%.2f, 1.1 extra=%.2f, shared=%.2f, kitchen=%.2f)."
		% [at_threshold, extra_11, shared_speed, kitchen_speed]
	)
	quit(0)
