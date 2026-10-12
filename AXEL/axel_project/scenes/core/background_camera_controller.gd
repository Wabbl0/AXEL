extends Camera2D
class_name BackgroundCamera

const Layout := preload("res://scenes/core/background_layout.gd")

enum CameraMode {
	STATIC_LOCKED,
	MOVABLE_FOLLOW,
}

const DEFAULT_MARGIN_PX := 0.0
const DEFAULT_FOLLOW_SMOOTHING := 5.0
const DEFAULT_MAX_AUTO_ZOOM := 4.0

@export var background_path: NodePath
@export var fit_mode: Layout.FitMode = Layout.FitMode.COVER
@export var camera_mode: CameraMode = CameraMode.STATIC_LOCKED
@export var margin_px: float = DEFAULT_MARGIN_PX
@export var edge_reveal: float = -1.0
@export var target_path: NodePath
@export var background_y: float = Layout.DEFAULT_BACKGROUND_Y
@export var follow_smoothing: float = DEFAULT_FOLLOW_SMOOTHING
@export var max_auto_zoom: float = DEFAULT_MAX_AUTO_ZOOM
@export var static_center: Vector2 = Vector2.INF
var follow_enabled: bool = true

signal layout_applied(scale_factor: float, bg_position: Vector2, world_rect: Rect2)

var _target: Node2D
var _world_rect: Rect2 = Rect2()
var _inset_rect: Rect2 = Rect2()
var _viewport_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node2D
	_run_pipeline()
	call_deferred("_run_pipeline")
	get_viewport().size_changed.connect(_run_pipeline)
	make_current()


func _physics_process(delta: float) -> void:
	if camera_mode != CameraMode.MOVABLE_FOLLOW:
		return
	if not follow_enabled:
		return
	if not is_instance_valid(_target):
		return
	var desired := _target.global_position
	var next := desired
	if follow_smoothing > 0.0:
		next = global_position.lerp(desired, 1.0 - exp(-follow_smoothing * delta))
	global_position = clamp_center_to_rect(next, _inset_rect, _viewport_size, zoom)


func set_follow_enabled(follow_on: bool) -> void:
	follow_enabled = follow_on


func place_center_clamped(world_center: Vector2) -> void:
	global_position = clamp_center_to_rect(
		world_center, _inset_rect, _viewport_size, zoom
	)


func _run_pipeline() -> void:
	_viewport_size = Layout.get_viewport_size(self)
	var world_rect := _world_rect
	var effective_edge_reveal := _resolved_edge_reveal()
	var effective_fit := effective_fit_mode()
	if not background_path.is_empty():
		var background := get_node_or_null(background_path) as Sprite2D
		if background != null:
			var layout: Dictionary = Layout.apply(
				background, _viewport_size, effective_fit, background_y, effective_edge_reveal
			)
			if not layout.is_empty():
				Layout.apply_to_sprite(background, layout)


				world_rect = Layout.compute_global_world_rect(background)
				layout_applied.emit(
					layout["scale_factor"], layout["position"], world_rect
				)
	if world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
		return
	_world_rect = world_rect
	_inset_rect = _rect_with_margin(world_rect, margin_px)
	apply_limits(
		self,
		world_rect,
		camera_mode,
		_target,
		margin_px,
		_viewport_size,
		static_center,
		max_auto_zoom,
		effective_edge_reveal,
		effective_fit == Layout.FitMode.CONTAIN
	)
	_inset_rect = _rect_with_margin(world_rect, margin_px)


func effective_fit_mode() -> Layout.FitMode:
	if camera_mode == CameraMode.STATIC_LOCKED:
		return Layout.FitMode.CONTAIN
	return fit_mode


func _resolved_edge_reveal() -> float:
	if effective_fit_mode() != Layout.FitMode.COVER or camera_mode != CameraMode.STATIC_LOCKED:
		return 0.0
	if edge_reveal < 0.0:
		return Layout.MAX_EDGE_REVEAL
	return clampf(edge_reveal, 0.0, 0.5)


static func apply_limits(
	camera: Camera2D,
	world_rect: Rect2,
	mode: CameraMode,
	target: Node2D,
	margin_inset_px: float,
	viewport_size: Vector2,
	lock_center: Vector2 = Vector2.INF,
	max_zoom: float = DEFAULT_MAX_AUTO_ZOOM,
	edge_reveal_amount: float = 0.0,
	show_whole: bool = false,
) -> void:
	if world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
		return

	var inset := _rect_with_margin(world_rect, margin_inset_px)
	camera.limit_smoothed = false
	if show_whole and mode == CameraMode.STATIC_LOCKED:
		camera.zoom = Vector2.ONE
		camera.position_smoothing_enabled = false
		var whole_center := world_rect.get_center()
		camera.global_position = whole_center
		var whole_half := viewport_size * 0.5
		camera.limit_left = int(floor(whole_center.x - whole_half.x))
		camera.limit_right = int(ceil(whole_center.x + whole_half.x))
		camera.limit_top = int(floor(whole_center.y - whole_half.y))
		camera.limit_bottom = int(ceil(whole_center.y + whole_half.y))
		return
	if edge_reveal_amount > 0.0:
		camera.zoom = Vector2.ONE
	else:
		camera.zoom = compute_auto_zoom(viewport_size, inset, camera.zoom, max_zoom)

	match mode:
		CameraMode.STATIC_LOCKED:
			camera.position_smoothing_enabled = false
			var center := lock_center
			if not center.is_finite():
				center = inset.get_center()
			center = clamp_center_to_rect(center, inset, viewport_size, camera.zoom)
			camera.global_position = center
			var half := viewport_size / (2.0 * camera.zoom)
			camera.limit_left = int(round(center.x - half.x))
			camera.limit_right = int(round(center.x + half.x))
			camera.limit_top = int(round(center.y - half.y))
			camera.limit_bottom = int(round(center.y + half.y))
		CameraMode.MOVABLE_FOLLOW:
			camera.position_smoothing_enabled = true
			camera.limit_left = int(floor(inset.position.x))
			camera.limit_top = int(floor(inset.position.y))
			camera.limit_right = int(ceil(inset.position.x + inset.size.x))
			camera.limit_bottom = int(ceil(inset.position.y + inset.size.y))
			if is_instance_valid(target):
				camera.global_position = clamp_center_to_rect(
					target.global_position, inset, viewport_size, camera.zoom
				)


static func compute_auto_zoom(
	viewport_size: Vector2,
	inset: Rect2,
	current_zoom: Vector2,
	max_zoom: float,
) -> Vector2:
	if inset.size.x <= 0.0 or inset.size.y <= 0.0:
		return current_zoom
	var vis_w := viewport_size.x / current_zoom.x
	var vis_h := viewport_size.y / current_zoom.y
	var needed_x := current_zoom.x
	var needed_y := current_zoom.y
	if vis_w > inset.size.x:
		needed_x = viewport_size.x / inset.size.x
	if vis_h > inset.size.y:
		needed_y = viewport_size.y / inset.size.y
	var uniform := maxf(needed_x, needed_y)
	if uniform <= current_zoom.x and uniform <= current_zoom.y:
		return current_zoom
	uniform = minf(uniform, max_zoom)
	return Vector2.ONE * uniform


static func clamp_center_to_rect(
	center: Vector2,
	inset: Rect2,
	viewport_size: Vector2,
	cam_zoom: Vector2,
) -> Vector2:
	if inset.size.x <= 0.0 or inset.size.y <= 0.0:
		return center
	var half := viewport_size / (2.0 * cam_zoom)
	var min_x := inset.position.x + half.x
	var max_x := inset.position.x + inset.size.x - half.x
	var min_y := inset.position.y + half.y
	var max_y := inset.position.y + inset.size.y - half.y
	var out := center
	if min_x > max_x:
		out.x = inset.get_center().x
	else:
		out.x = clampf(center.x, min_x, max_x)
	if min_y > max_y:
		out.y = inset.get_center().y
	else:
		out.y = clampf(center.y, min_y, max_y)
	return out


static func limits_enclose_rect(
	camera: Camera2D,
	world_rect: Rect2,
	viewport_size: Vector2,
	margin_inset_px: float = DEFAULT_MARGIN_PX,
) -> PackedStringArray:
	var violations: PackedStringArray = PackedStringArray()
	if world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
		violations.append("world_rect is empty")
		return violations

	var inset := _rect_with_margin(world_rect, margin_inset_px)
	var half := viewport_size / (2.0 * camera.zoom)
	var view_rect := Rect2(
		camera.global_position - half,
		viewport_size / camera.zoom,
	)
	if view_rect.position.x < inset.position.x - 0.5:
		violations.append("camera view extends left of art rect")
	if view_rect.position.y < inset.position.y - 0.5:
		violations.append("camera view extends above art rect")
	var view_end := view_rect.position + view_rect.size
	var inset_end := inset.position + inset.size
	if view_end.x > inset_end.x + 0.5:
		violations.append("camera view extends right of art rect")
	if view_end.y > inset_end.y + 0.5:
		violations.append("camera view extends below art rect")
	return violations


static func _rect_with_margin(world_rect: Rect2, margin_inset_px: float) -> Rect2:
	if margin_inset_px <= 0.0:
		return world_rect
	var inset := world_rect.grow(-margin_inset_px)
	if inset.size.x <= 0.0 or inset.size.y <= 0.0:
		return world_rect
	return inset
