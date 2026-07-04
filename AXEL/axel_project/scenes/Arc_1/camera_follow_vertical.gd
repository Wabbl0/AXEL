extends Camera2D
## Legacy 1.1 camera: vertical-only follow with a fixed X (landscape design).
## In portrait viewports (mobile) it switches to a zoomed player-follow mode whose
## bounds come from the placed background sprite, so the view never slides past
## the top/bottom (or side) edges of the art.

const BackgroundCameraStatics := preload("res://scenes/core/background_camera_controller.gd")

@export var target_path: NodePath
@export var fixed_x: float = 640.0
@export var vertical_smoothing: float = 5.0

@export_group("Portrait (mobile)")
## Background sprite whose placed transform defines the camera bounds in portrait.
@export var background_path: NodePath
@export var portrait_player_zoom: float = 2.0
@export var portrait_follow_smoothing: float = 5.0

var _target: Node2D
var _portrait_rect: Rect2 = Rect2()
var _authored_limits: Array[int] = []


func _ready() -> void:
	if not target_path.is_empty():
		_target = get_node_or_null(target_path)
	_authored_limits = [limit_left, limit_top, limit_right, limit_bottom]
	get_viewport().size_changed.connect(_refresh_portrait_setup)
	_refresh_portrait_setup()
	make_current()


func _restore_authored_limits() -> void:
	if _authored_limits.size() != 4:
		return
	limit_left = _authored_limits[0]
	limit_top = _authored_limits[1]
	limit_right = _authored_limits[2]
	limit_bottom = _authored_limits[3]


func _viewport_size() -> Vector2:
	return BackgroundLayout.get_viewport_size(self)


func _is_portrait() -> bool:
	var size := _viewport_size()
	return size.y > size.x


func _refresh_portrait_setup() -> void:
	if not _is_portrait():
		_portrait_rect = Rect2()
		zoom = Vector2.ONE
		_restore_authored_limits()
		return
	var background := get_node_or_null(background_path) as Sprite2D
	if background == null or background.texture == null:
		_portrait_rect = Rect2()
		zoom = Vector2.ONE
		_restore_authored_limits()
		return
	_portrait_rect = BackgroundLayout.compute_world_rect(
		background, background.position, background.scale
	)
	if _portrait_rect.size.x <= 0.0 or _portrait_rect.size.y <= 0.0:
		return
	var view := _viewport_size()
	var min_zoom := maxf(view.x / _portrait_rect.size.x, view.y / _portrait_rect.size.y)
	zoom = Vector2.ONE * maxf(portrait_player_zoom, min_zoom)
	# Engine limits must match the art rect; the authored landscape limits are
	# tighter than the art and would fight the portrait clamp.
	limit_left = int(floor(_portrait_rect.position.x))
	limit_top = int(floor(_portrait_rect.position.y))
	limit_right = int(ceil(_portrait_rect.position.x + _portrait_rect.size.x))
	limit_bottom = int(ceil(_portrait_rect.position.y + _portrait_rect.size.y))
	global_position = BackgroundCameraStatics.clamp_center_to_rect(
		_portrait_target_position(), _portrait_rect, view, zoom
	)


func _portrait_target_position() -> Vector2:
	if is_instance_valid(_target):
		return _target.global_position
	return _portrait_rect.get_center()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	if _portrait_rect.size.x > 0.0 and _portrait_rect.size.y > 0.0 and _is_portrait():
		var desired := _target.global_position
		var next := desired
		if portrait_follow_smoothing > 0.0:
			next = global_position.lerp(desired, 1.0 - exp(-portrait_follow_smoothing * delta))
		global_position = BackgroundCameraStatics.clamp_center_to_rect(
			next, _portrait_rect, _viewport_size(), zoom
		)
		return
	var target_y := _target.global_position.y
	var next_y := lerpf(global_position.y, target_y, 1.0 - exp(-vertical_smoothing * delta))
	global_position.x = fixed_x
	global_position.y = clampf(next_y, limit_top, limit_bottom)
