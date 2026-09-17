extends SceneTree

const Layout := preload("res://scenes/core/background_layout.gd")
const PlayerCoverSyncScript := preload("res://scenes/core/player_cover_sync.gd")
const MockPlayerScript := preload("res://scenes/core/test/mock_cover_player.gd")

const TEX_SIZE := Vector2i(3508, 2480)
const VIEW_3_2 := Vector2(1920.0, 1280.0)
const VIEW_16_9 := Vector2(1920.0, 1080.0)
const AUTHORED_SCALE := 0.277
const EPS := 0.001


func _init() -> void:
	call_deferred("_main")


func _fail(msg: String) -> void:
	push_error("BackgroundFit FAIL: %s" % msg)
	quit(1)


func _make_sprite() -> Sprite2D:
	var image := Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = texture
	root.add_child(sprite)
	return sprite


func _main() -> void:
	var sprite := _make_sprite()
	var cover_169 := Layout.apply(sprite, VIEW_16_9, Layout.FitMode.COVER, 0.0, 0.0)
	var reveal_169 := Layout.apply(
		sprite, VIEW_16_9, Layout.FitMode.COVER, 0.0, Layout.MAX_EDGE_REVEAL
	)
	var contain_169 := Layout.apply(sprite, VIEW_16_9, Layout.FitMode.CONTAIN, 0.0, 0.0)
	if cover_169.is_empty() or reveal_169.is_empty() or contain_169.is_empty():
		_fail("layout helper returned empty data")
		return

	if absf(float(cover_169["scale_factor"]) - 0.5473204) > 0.001:
		_fail("plain cover scale changed unexpectedly")
		return
	if absf(float(Layout.apply(sprite, VIEW_16_9, Layout.FitMode.COVER, 0.0, 0.0)["scale_factor"]) - float(cover_169["scale_factor"])) > EPS:
		_fail("edge_reveal=0 should be bit-identical to plain cover")
		return

	var expected_reveal := maxf(
		float(contain_169["scale_factor"]),
		float(cover_169["scale_factor"]) * (1.0 - 2.0 * Layout.MAX_EDGE_REVEAL)
	)
	if absf(float(reveal_169["scale_factor"]) - expected_reveal) > EPS:
		_fail(
			"revealed cover scale=%.6f expected %.6f"
			% [float(reveal_169["scale_factor"]), expected_reveal]
		)
		return
	if float(reveal_169["scale_factor"]) + EPS < float(contain_169["scale_factor"]):
		_fail("revealed cover fell below contain")
		return
	if float(reveal_169["scale_factor"]) - EPS > float(cover_169["scale_factor"]):
		_fail("revealed cover exceeded plain cover")
		return

	var reveal_size := TEX_SIZE * float(reveal_169["scale_factor"])
	var gap_x := maxf(VIEW_16_9.x - reveal_size.x, 0.0)
	var gap_y := maxf(VIEW_16_9.y - reveal_size.y, 0.0)
	if gap_x / VIEW_16_9.x > Layout.MAX_EDGE_REVEAL * 2.0 + EPS:
		_fail("horizontal strip exceeded budget")
		return
	if gap_y / VIEW_16_9.y > Layout.MAX_EDGE_REVEAL * 2.0 + EPS:
		_fail("vertical strip exceeded budget")
		return

	var sync := PlayerCoverSyncScript.new()
	var player := MockPlayerScript.new()
	player.scale = Vector2(AUTHORED_SCALE, AUTHORED_SCALE)
	player.speed = 1.0
	player.locked_feet_y = -1.0
	root.add_child(player)
	sync.bind_from_player(player)
	sync.bind_design_from_background(sprite, Layout.FitMode.COVER, 0.0)

	sync.apply(player, float(Layout.apply(sprite, VIEW_3_2, Layout.FitMode.COVER, 0.0, Layout.MAX_EDGE_REVEAL)["scale_factor"]), Vector2.ZERO)
	var ratio_32 := player.scale.x / float(Layout.apply(sprite, VIEW_3_2, Layout.FitMode.COVER, 0.0, Layout.MAX_EDGE_REVEAL)["scale_factor"])
	sync.apply(player, float(reveal_169["scale_factor"]), Vector2.ZERO)
	var ratio_169 := player.scale.x / float(reveal_169["scale_factor"])
	if absf(ratio_32 - ratio_169) > EPS:
		_fail("player/art ratio drifted across aspect ratios (3:2=%.6f 16:9=%.6f)" % [ratio_32, ratio_169])
		return

	print(
		"BackgroundFit check OK (cover=%.4f reveal=%.4f contain=%.4f gap_x=%.1f gap_y=%.1f)."
		% [
			float(cover_169["scale_factor"]),
			float(reveal_169["scale_factor"]),
			float(contain_169["scale_factor"]),
			gap_x,
			gap_y,
		]
	)
	quit(0)
