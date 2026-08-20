extends SceneTree
## Headless lock: PlayerCoverSync keeps player.scale / cover_scale constant across
## two cover sizes, including the first apply (not only later resizes).
## Run from repo root:
##   tools\cmd\godot.cmd --headless --path AXEL/axel_project -s res://scenes/core/test/player_cover_sync_check.gd

const PlayerCoverSyncScript := preload("res://scenes/core/player_cover_sync.gd")
const MockPlayerScript := preload("res://scenes/core/test/mock_cover_player.gd")

const AUTHORED_SCALE := 3.0
const AUTHORED_SPEED := 189.75
const BASELINE := 0.5
const COVER_A := 0.25
const COVER_B := 1.0
const EPS := 0.0001


func _init() -> void:
	call_deferred("_main")


func _make_player() -> CharacterBody2D:
	var player: CharacterBody2D = MockPlayerScript.new()
	player.speed = AUTHORED_SPEED
	player.locked_feet_y = -1.0
	player.scale = Vector2(AUTHORED_SCALE, AUTHORED_SCALE)
	return player


func _main() -> void:
	var sync: PlayerCoverSync = PlayerCoverSyncScript.new()
	var player := _make_player()
	root.add_child(player)

	sync.bind_from_player(player)
	sync.authored_bg_baseline = BASELINE
	sync.authored_bg_baseline_position = Vector2.ZERO

	# First apply must already scale (not wait until resize).
	sync.apply(player, COVER_A, Vector2(10.0, 20.0))
	var ratio_a := player.scale.x / COVER_A
	var expected_a := AUTHORED_SCALE / BASELINE
	if absf(ratio_a - expected_a) > EPS:
		push_error(
			"PlayerCoverSync FAIL: first apply scale/cover=%.6f expected %.6f (scale=%.4f cover=%.4f)"
			% [ratio_a, expected_a, player.scale.x, COVER_A]
		)
		quit(1)
		return
	var speed_a := float(player.speed)
	var expected_speed_a := AUTHORED_SPEED * (COVER_A / BASELINE)
	if absf(speed_a - expected_speed_a) > 0.01:
		push_error(
			"PlayerCoverSync FAIL: first apply speed=%.4f expected %.4f"
			% [speed_a, expected_speed_a]
		)
		quit(1)
		return

	# Second cover (different computer / Game tab) must keep the same scale/cover.
	sync.apply(player, COVER_B, Vector2(40.0, 60.0))
	var ratio_b := player.scale.x / COVER_B
	if absf(ratio_b - ratio_a) > EPS:
		push_error(
			"PlayerCoverSync FAIL: scale/cover drifted A=%.6f B=%.6f"
			% [ratio_a, ratio_b]
		)
		quit(1)
		return
	if absf(ratio_b - expected_a) > EPS:
		push_error(
			"PlayerCoverSync FAIL: second apply scale/cover=%.6f expected %.6f"
			% [ratio_b, expected_a]
		)
		quit(1)
		return

	# Authored meta must stay at design values for QA validators.
	const META_SCALE := "axel_authored_scale"
	if not player.has_meta(META_SCALE):
		push_error("PlayerCoverSync FAIL: missing authored scale meta")
		quit(1)
		return
	var meta_scale: Vector2 = player.get_meta(META_SCALE)
	if absf(meta_scale.x - AUTHORED_SCALE) > EPS:
		push_error(
			"PlayerCoverSync FAIL: authored scale meta mutated to %.4f"
			% meta_scale.x
		)
		quit(1)
		return

	# Extra PlayerLayer node (memory glow) tracks the same ratio.
	var glow := Node2D.new()
	glow.scale = Vector2(1.5, 1.5)
	root.add_child(glow)
	var sync2: PlayerCoverSync = PlayerCoverSyncScript.new()
	var player2 := _make_player()
	root.add_child(player2)
	sync2.bind_from_player(player2)
	sync2.authored_bg_baseline = BASELINE
	sync2.bind_extra_node(glow)
	sync2.apply(player2, COVER_A, Vector2.ZERO)
	var glow_expected := 1.5 * (COVER_A / BASELINE)
	if absf(glow.scale.x - glow_expected) > EPS:
		push_error(
			"PlayerCoverSync FAIL: extra node scale=%.4f expected %.4f"
			% [glow.scale.x, glow_expected]
		)
		quit(1)
		return

	# bind_design_from_background must no-op when baseline already set.
	sync2.authored_bg_baseline = BASELINE
	sync2.bind_design_from_background(null)
	if absf(sync2.authored_bg_baseline - BASELINE) > EPS:
		push_error("PlayerCoverSync FAIL: bind_design mutated existing baseline")
		quit(1)
		return

	print(
		"PlayerCoverSync check OK (first+second apply scale/cover=%.4f, extras OK)."
		% ratio_a
	)
	quit(0)
