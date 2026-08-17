extends Node
## 2.2-only: top-crop to 1.85:1, then fit as large as possible above the dialogue bar
## with a little side margin and some black at the top and above the bar.

const TARGET_ASPECT := 1.85
## A little black on the left/right (~48px at 1920).
const SIDE_MARGIN_FRACTION := 0.025
## Some black above the still (~58px at 1280).
const TOP_MARGIN_FRACTION := 0.045
## Small gap so the still sits just above the dialogue bar.
const GAP_ABOVE_BAR_FRACTION := 0.02
## Must match TopDialogueOverlay BAR_MIN_HEIGHT + bottom_gap_viewport_fraction.
const DIALOGUE_BAR_MIN_PX := 136.0
const DIALOGUE_BOTTOM_GAP_FRACTION := 0.03

@onready var _camera: Camera2D = $"../Camera2D"
@onready var _background: Sprite2D = $"../WalkableWorld/Background"


func _ready() -> void:
	var void_fill := $"../WalkableWorld/VoidFill" as CanvasItem
	if void_fill != null:
		void_fill.visible = true
	if is_instance_valid(_camera) and _camera.has_signal("layout_applied"):
		_camera.layout_applied.connect(_on_layout_applied)
	_apply_frame()


func _on_layout_applied(_scale_factor: float, _bg_position: Vector2, _world_rect: Rect2) -> void:
	_apply_frame()


func _apply_frame() -> void:
	if not is_instance_valid(_background) or _background.texture == null:
		return
	_apply_top_crop()
	var art_size := _art_size()
	if art_size.x <= 0.0 or art_size.y <= 0.0:
		return
	var view := _camera_view_rect()
	var box := _content_box(view.size)
	var fit_scale := minf(box.size.x / art_size.x, box.size.y / art_size.y)
	var scaled := art_size * fit_scale
	_background.scale = Vector2.ONE * fit_scale
	_background.position = view.position + box.position + (box.size - scaled) * 0.5


func _apply_top_crop() -> void:
	var src_size := _source_size()
	if src_size.x <= 0.0 or src_size.y <= 0.0:
		return
	var crop_h := src_size.x / TARGET_ASPECT
	if crop_h > src_size.y:
		crop_h = src_size.y
	var crop_y := src_size.y - crop_h
	_background.region_enabled = true
	_background.region_rect = Rect2(0.0, crop_y, src_size.x, crop_h)


func _content_box(view_size: Vector2) -> Rect2:
	var side := view_size.x * SIDE_MARGIN_FRACTION
	var top := view_size.y * TOP_MARGIN_FRACTION
	var gap_above_bar := view_size.y * GAP_ABOVE_BAR_FRACTION
	var dialogue_from_bottom := DIALOGUE_BAR_MIN_PX + view_size.y * DIALOGUE_BOTTOM_GAP_FRACTION
	var box_h := view_size.y - top - gap_above_bar - dialogue_from_bottom
	return Rect2(side, top, view_size.x - side * 2.0, maxf(1.0, box_h))


func _camera_view_rect() -> Rect2:
	var vp_size := _get_viewport_size()
	var view_size := vp_size
	var view_center := vp_size * 0.5
	if is_instance_valid(_camera):
		var zoom: Vector2 = _camera.zoom
		if zoom.x > 0.0 and zoom.y > 0.0:
			view_size = Vector2(vp_size.x / zoom.x, vp_size.y / zoom.y)
		view_center = _camera.global_position
	return Rect2(view_center - view_size * 0.5, view_size)


func _source_size() -> Vector2:
	var tex := _background.texture
	if tex is AtlasTexture:
		var atlas := tex as AtlasTexture
		if atlas.atlas != null:
			return atlas.atlas.get_size()
	return tex.get_size()


func _art_size() -> Vector2:
	if _background.region_enabled:
		return _background.region_rect.size
	return _source_size()


func _get_viewport_size() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2(1920.0, 1280.0)
	var size := vp.get_visible_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2(1920.0, 1280.0)
	return size
