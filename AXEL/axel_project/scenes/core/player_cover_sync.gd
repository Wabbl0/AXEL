extends RefCounted
class_name PlayerCoverSync

const Layout := preload("res://scenes/core/background_layout.gd")
const PlayerWalkSpeedScript := preload("res://scenes/core/player_walk_speed.gd")
const AUTHORED_SCALE_META := "axel_authored_scale"
const AUTHORED_SPEED_META := "axel_authored_speed"

var authored_scale: Vector2 = Vector2.ONE
var authored_speed: float = 0.0
var authored_locked_feet_y: float = -1.0
var authored_bg_baseline: float = 0.0
var authored_bg_baseline_position: Vector2 = Vector2.ZERO
var reference_cover: float = -1.0
var _ref_bg_position: Vector2 = Vector2.ZERO
var _extra_authored: Dictionary = {}


func bind_from_player(player: CharacterBody2D) -> void:
	if not is_instance_valid(player):
		return
	authored_scale = player.scale


	authored_speed = PlayerWalkSpeedScript.from_scale(authored_scale.x)
	if player.get("speed") != null:
		player.speed = authored_speed
	authored_locked_feet_y = float(player.get("locked_feet_y"))
	player.set_meta(AUTHORED_SCALE_META, authored_scale)
	player.set_meta(AUTHORED_SPEED_META, authored_speed)


func bind_design_from_background(
	sprite: Sprite2D,
	fit_mode: Layout.FitMode = Layout.FitMode.COVER,
	background_y: float = Layout.DEFAULT_BACKGROUND_Y,
) -> void:
	if authored_bg_baseline > 0.0:
		return
	if sprite == null:
		return
	var layout: Dictionary = Layout.apply(
		sprite, Layout.DESIGN_VIEWPORT, fit_mode, background_y
	)
	if layout.is_empty():
		return
	authored_bg_baseline = float(layout["scale_factor"])
	authored_bg_baseline_position = layout["position"] as Vector2


func bind_extra_node(node: Node2D) -> void:
	if not is_instance_valid(node):
		return
	_extra_authored[node] = node.scale


func has_reference() -> bool:
	return reference_cover > 0.0


func cover_ratio(cover_scale: float) -> float:
	if authored_bg_baseline <= 0.0 or cover_scale <= 0.0:
		return 1.0
	return cover_scale / authored_bg_baseline


func apply(player: CharacterBody2D, cover_scale: float, bg_position: Vector2) -> void:
	if not is_instance_valid(player) or cover_scale <= 0.0:
		return


	if authored_bg_baseline <= 0.0:
		if reference_cover <= 0.0:
			reference_cover = cover_scale
			_ref_bg_position = bg_position
			player.scale = authored_scale
			player.speed = authored_speed
			if authored_locked_feet_y >= 0.0:
				player.locked_feet_y = authored_locked_feet_y
			_apply_extras(1.0)
			return
		var legacy_ratio := cover_scale / reference_cover
		player.scale = authored_scale * legacy_ratio
		player.speed = authored_speed * legacy_ratio
		if authored_locked_feet_y >= 0.0:
			var legacy_tex_y := (
				(authored_locked_feet_y - _ref_bg_position.y) / reference_cover
			)
			player.locked_feet_y = bg_position.y + legacy_tex_y * cover_scale
		_apply_extras(legacy_ratio)
		return

	var ratio := cover_ratio(cover_scale)
	if reference_cover <= 0.0:
		reference_cover = cover_scale
		_ref_bg_position = bg_position

	player.scale = authored_scale * ratio
	player.speed = authored_speed * ratio
	if authored_locked_feet_y >= 0.0:
		var tex_y := (
			(authored_locked_feet_y - authored_bg_baseline_position.y)
			/ authored_bg_baseline
		)
		player.locked_feet_y = bg_position.y + tex_y * cover_scale
	_apply_extras(ratio)


func _apply_extras(ratio: float) -> void:
	for node in _extra_authored.keys():
		if not is_instance_valid(node):
			continue
		var authored: Vector2 = _extra_authored[node]
		(node as Node2D).scale = authored * ratio
