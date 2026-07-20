extends RefCounted
class_name PlayerCoverSync
## Keeps PlayerLayer/Player matched to background cover-fit on window resize.
## Authored scale/speed/locked_feet_y stay correct at the first layout cover scale,
## then track cover_scale / reference_cover on later resizes.

var authored_scale: Vector2 = Vector2.ONE
var authored_speed: float = 0.0
var authored_locked_feet_y: float = -1.0
var reference_cover: float = -1.0
var _ref_bg_position: Vector2 = Vector2.ZERO


func bind_from_player(player: CharacterBody2D) -> void:
	if not is_instance_valid(player):
		return
	authored_scale = player.scale
	authored_speed = player.speed
	authored_locked_feet_y = player.locked_feet_y


func has_reference() -> bool:
	return reference_cover > 0.0


func apply(player: CharacterBody2D, cover_scale: float, bg_position: Vector2) -> void:
	if not is_instance_valid(player) or cover_scale <= 0.0:
		return
	if reference_cover <= 0.0:
		reference_cover = cover_scale
		_ref_bg_position = bg_position
		player.scale = authored_scale
		player.speed = authored_speed
		return
	var ratio := cover_scale / reference_cover
	player.scale = authored_scale * ratio
	player.speed = authored_speed * ratio
	if authored_locked_feet_y >= 0.0:
		var tex_y := (authored_locked_feet_y - _ref_bg_position.y) / reference_cover
		player.locked_feet_y = bg_position.y + tex_y * cover_scale
