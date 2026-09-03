@tool
extends CharacterBody2D

enum SheetLayoutMode {
	AUTO,
	HORIZONTAL_13,
	GRID,
}

## Last facing for idle: front / back / side. Side also tracks flip via _last_side_is_right.
enum Facing { FRONT, BACK, SIDE }

const _MIKE_FRAME_INDICES := {
	&"idle": [0],
	&"idle_back": [5],
	&"idle_side": [8],
	&"walk_down": [0, 1, 2, 3],
	&"walk_up": [4, 5, 6],
	&"walk_right": [7, 8, 9, 10, 11],
}

const _MIKE_FRAME_COUNT := 12
const _HITBOX_FRONT := preload("res://scenes/player/hitbox_front.tres")
## Shared ShadowOutline fit authored in 1.2; applied on every room so the silhouette stays aligned.
const SHADOW_OUTLINE_POS := Vector2(-5.0416956, -5.041732)
const SHADOW_OUTLINE_SCALE := Vector2(1.0335996, 0.9969109)
## Shared Front circle placement authored in 1.1; applied on every room. Back/Side retired.
const HITBOX_FRONT_POS := Vector2(-37.812428, 126.04143)
const _POSE_NUDGE_PATH := "res://scenes/player/pose_nudge.tres"

@export var speed: float = 220.0
@export_group("Pose Nudge")
## Editor only: which idle pose is solid. The other two stay faded on top. Does not change Play.
@export_enum("Front", "Back", "Side") var editor_pose_preview: int = 0:
	get:
		return _editor_pose_preview
	set(value):
		_editor_pose_preview = value
		_on_pose_nudge_edited()
## Moves the front drawing (S / idle). Sprite pixels — try 80 to 200 if you see no move.
@export var pose_nudge_front: Vector2 = Vector2.ZERO:
	get:
		return _pose_nudge_front
	set(value):
		_pose_nudge_front = value
		_on_pose_nudge_edited()
## Moves the back drawing (W / idle_back). Sprite pixels — try 80 to 200 if you see no move.
@export var pose_nudge_back: Vector2 = Vector2.ZERO:
	get:
		return _pose_nudge_back
	set(value):
		_pose_nudge_back = value
		_on_pose_nudge_edited()
## Moves the side drawing (A/D / idle_side). Sprite pixels — try 80 to 200 if you see no move.
@export var pose_nudge_side: Vector2 = Vector2.ZERO:
	get:
		return _pose_nudge_side
	set(value):
		_pose_nudge_side = value
		_on_pose_nudge_edited()
@export_group("")
@export var overworld_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
## When empty, tries common paths under res://assets/sprites/ (including mike walking exports).
@export var sprite_sheet: Texture2D
## AUTO: wide strip if width divisible by frame count; else if width and height divisible by sheet_columns / sheet_rows, use GRID.
@export var sheet_layout_mode: SheetLayoutMode = SheetLayoutMode.AUTO
## For GRID / AUTO grid: optional multi-row sheet layout.
@export var sheet_columns: int = 4
@export var sheet_rows: int = 4
## Forced cell size; if 0, derived from texture and layout (recommended).
@export var frame_width: int = 0
@export var frame_height: int = 0
@export var animation_fps: float = 5.0
## If true, traces collision from sprite alpha. Default is the shared Front hitbox
## (`res://scenes/player/hitbox_front.tres`). CollisionBack / CollisionSide are retired.
@export var use_alpha_collision: bool = false
## Frame index on the Mike sheet when `collision_use_all_frames_union` is false.
@export_range(0, 11) var collision_frame_index: int = 0
## Union all walk frames so walk cycles do not poke past the collider.
@export var collision_use_all_frames_union: bool = true
@export_range(0.0, 1.0) var collision_alpha_threshold: float = 0.1
## Higher values simplify the traced outline (fewer sharp corners).
@export var collision_polygon_epsilon: float = 3.0
## Shrinks the alpha mask before tracing; removes thin protrusions that snag on walls.
@export_range(0, 8) var collision_alpha_shrink_pixels: int = 2
## Chaikin smoothing passes on the traced polygon (0 = off).
@export_range(0, 4) var collision_smooth_iterations: int = 2
## Pulls the final polygon slightly inward from its center so edges slide instead of catch.
@export var collision_inward_margin: float = 1.5
## Fraction of frame height kept for collision, measured from the feet up (0.5 = lower half / waist cut).
@export_range(0.2, 1.0) var collision_lower_body_ratio: float = 0.5
## When >= 0, snaps this player's feet to a fixed world Y every physics frame (walk left/right
## along a road at a constant height). Horizontal movement is unaffected. -1 = disabled.
@export var locked_feet_y: float = -1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var shadow_outline: AnimatedSprite2D = $ShadowOutline
@onready var fallback_body: Polygon2D = $FallbackBody

var _last_facing: Facing = Facing.FRONT
## Right-facing side walks vs left (flip_h); used for side idle and A/D.
var _last_side_is_right: bool = true
var _pose_nudge_res: Resource
var _editor_pose_preview: int = 0
var _pose_nudge_front: Vector2 = Vector2.ZERO
var _pose_nudge_back: Vector2 = Vector2.ZERO
var _pose_nudge_side: Vector2 = Vector2.ZERO

var _input_enabled: bool = true
var _scripted_velocity: Vector2 = Vector2.ZERO
var _step_distance_accumulator: float = 0.0
var _last_step_position: Vector2 = Vector2.ZERO

const _STEP_DISTANCE_PX := 8.0
const _EDITOR_HITBOX_FILL := Color(0.0, 0.92, 0.95, 0.22)
const _EDITOR_HITBOX_LINE := Color(0.0, 0.92, 0.95, 0.95)

var _layout: SheetLayoutMode = SheetLayoutMode.HORIZONTAL_13
var _cell: Vector2i = Vector2i(32, 32)
var _editor_hitbox_polys: Array[PackedVector2Array] = []
var _editor_hitbox_sig: String = ""


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		_scripted_velocity = Vector2.ZERO
		velocity = Vector2.ZERO


func is_input_enabled() -> bool:
	return _input_enabled


func set_scripted_velocity(v: Vector2) -> void:
	_scripted_velocity = v


func clear_scripted_velocity() -> void:
	_scripted_velocity = Vector2.ZERO

func _enter_tree() -> void:
	_load_pose_nudge_from_disk()
	if Engine.is_editor_hint():
		set_process(true)
		set_physics_process(false)
		set_notify_transform(true)


func _ready() -> void:
	_load_pose_nudge_from_disk()
	if Engine.is_editor_hint():
		_ensure_facing_hitboxes()
		_refresh_editor_hitbox_preview()
		_apply_editor_pose_preview()
		_apply_pose_nudge()
		_sync_editor_sprite_visibility()
		var editor_shadow := _pose_shadow()
		if editor_shadow != null:
			editor_shadow.visible = true
		queue_redraw()
		return
	motion_mode = MOTION_MODE_FLOATING
	safe_margin = 0.1
	_last_step_position = global_position
	if sprite_sheet == null:
		sprite_sheet = _try_load_default_sprite_sheet()
	if sprite_sheet:
		_resolve_layout_and_cell()
		_build_sprite_frames()
		_setup_shadow_outline()
		_ensure_facing_hitboxes()
		_setup_alpha_collision()
		fallback_body.visible = false
		animated_sprite.visible = true
		_apply_overworld_tint()
	else:
		_ensure_facing_hitboxes()
		fallback_body.visible = true
		animated_sprite.visible = false
		shadow_outline.visible = false
	_sync_manual_facing_collision()
	_apply_pose_nudge()

func _try_load_default_sprite_sheet() -> Texture2D:
	var candidates: Array[String] = [
		"res://assets/sprites/mike_walking-Sheet.png",
		"res://assets/sprites/mike_walking.png",
		"res://assets/sprites/player_sheet.png",
		"res://assets/sprites/player.png",
		"res://assets/sprites/character.png",
		"res://assets/sprites/sprite.png",
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

func _resolve_layout_and_cell() -> void:
	var w := sprite_sheet.get_width()
	var h := sprite_sheet.get_height()
	_layout = sheet_layout_mode
	if _layout == SheetLayoutMode.AUTO:
		if w % _MIKE_FRAME_COUNT == 0 and h > 0:
			_layout = SheetLayoutMode.HORIZONTAL_13
		elif w % sheet_columns == 0 and h % sheet_rows == 0:
			_layout = SheetLayoutMode.GRID
			if sheet_columns * sheet_rows < _MIKE_FRAME_COUNT:
				push_warning(
					"Player: sheet_columns * sheet_rows should be >= %d for Mike sheet (got %d)."
					% [_MIKE_FRAME_COUNT, sheet_columns * sheet_rows]
				)
		else:
			_layout = SheetLayoutMode.HORIZONTAL_13
			push_warning(
				"Player: could not AUTO-detect layout (texture %dx%d). Using HORIZONTAL_13 math; set Sheet Layout Mode to GRID or fix export."
				% [w, h]
			)

	var fw := frame_width
	var fh := frame_height
	if fw <= 0 or fh <= 0:
		match _layout:
			SheetLayoutMode.HORIZONTAL_13:
				fw = int(float(w) / float(_MIKE_FRAME_COUNT))
				fh = h
			SheetLayoutMode.GRID:
				fw = int(float(w) / float(sheet_columns))
				fh = int(float(h) / float(sheet_rows))
		_cell = Vector2i(fw, fh)
	else:
		_cell = Vector2i(fw, fh)

func _region_for_mike_frame(index: int) -> Rect2:
	var fw := float(_cell.x)
	var fh := float(_cell.y)
	match _layout:
		SheetLayoutMode.HORIZONTAL_13:
			return Rect2(float(index) * fw, 0.0, fw, fh)
		SheetLayoutMode.GRID:
			var col := index % sheet_columns
			var row := int(float(index) / float(sheet_columns))
			return Rect2(float(col) * fw, float(row) * fh, fw, fh)
		_:
			return Rect2(float(index) * fw, 0.0, fw, fh)

func _build_sprite_frames() -> void:
	var sf := SpriteFrames.new()
	var frame_time := 1.0 / maxf(animation_fps, 0.001)
	for anim_name in _MIKE_FRAME_INDICES:
		var indices: Array = _MIKE_FRAME_INDICES[anim_name]
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, true)
		sf.set_animation_speed(anim_name, 1.0)
		for i in indices:
			var atlas := AtlasTexture.new()
			atlas.atlas = sprite_sheet
			atlas.region = _region_for_mike_frame(i)
			sf.add_frame(anim_name, atlas, frame_time)
	animated_sprite.sprite_frames = sf
	animated_sprite.play(&"idle")

func _setup_shadow_outline() -> void:
	shadow_outline.sprite_frames = animated_sprite.sprite_frames
	shadow_outline.animation = animated_sprite.animation
	shadow_outline.frame = animated_sprite.frame
	shadow_outline.frame_progress = animated_sprite.frame_progress
	shadow_outline.play(animated_sprite.animation)
	shadow_outline.visible = true
	shadow_outline.modulate = Color(0.0, 0.0, 0.0, 0.55)
	_apply_shadow_outline_fit(_pose_nudge_value(_last_facing))


func _setup_alpha_collision() -> void:
	if Engine.is_editor_hint():
		return
	if not use_alpha_collision:
		return
	var pending_shapes := _collect_alpha_collision_polygons()
	if pending_shapes.is_empty():
		push_warning("Player: could not build alpha collision; keeping scene collision shape.")
		return
	call_deferred("_apply_alpha_collision_polygons", pending_shapes)


func _collect_alpha_collision_polygons() -> Array[PackedVector2Array]:
	var empty: Array[PackedVector2Array] = []
	if not use_alpha_collision:
		return empty
	if sprite_sheet == null:
		if Engine.is_editor_hint():
			return empty
		sprite_sheet = _try_load_default_sprite_sheet()
	var sheet_image := _get_sheet_image()
	if sheet_image == null or sprite_sheet == null:
		return empty
	_resolve_layout_and_cell()
	var fw := _cell.x
	var fh := _cell.y
	if fw <= 0 or fh <= 0:
		return empty

	var bitmap := BitMap.new()
	if collision_use_all_frames_union:
		bitmap = _build_union_alpha_bitmap(sheet_image)
	else:
		var frame_image := _crop_sheet_frame_image(sheet_image, collision_frame_index)
		bitmap.create_from_image_alpha(frame_image, collision_alpha_threshold)

	_bitmap_clip_to_lower_body(bitmap, fw, fh, collision_lower_body_ratio)
	var raw_bitmap := _copy_bitmap(bitmap)
	bitmap = _erode_bitmap(bitmap, collision_alpha_shrink_pixels)
	if not _bitmap_has_opaque_pixels(bitmap):
		bitmap = raw_bitmap
	return _polygons_from_alpha_bitmap(bitmap, fw, fh)


func _polygons_from_alpha_bitmap(bitmap: BitMap, fw: int, fh: int) -> Array[PackedVector2Array]:
	var polygons: Array = bitmap.opaque_to_polygons(Rect2i(0, 0, fw, fh), collision_polygon_epsilon)
	var frame_center := Vector2(float(fw) * 0.5, float(fh) * 0.5)
	var pending_shapes: Array[PackedVector2Array] = []

	for poly in polygons:
		var points: PackedVector2Array = poly
		if points.size() < 3:
			continue
		points = _smooth_collision_polygon(points, collision_smooth_iterations)
		if collision_inward_margin > 0.0:
			points = _inset_polygon_toward_center(points, collision_inward_margin)
		points = _sanitize_collision_polygon(points)
		if points.size() < 3:
			continue
		var centered := PackedVector2Array()
		centered.resize(points.size())
		for i in points.size():
			centered[i] = points[i] - frame_center
		pending_shapes.append(centered)

	if pending_shapes.is_empty():
		var fallback := _circle_points_from_bitmap(bitmap, fw, fh, frame_center)
		if fallback.size() >= 3:
			pending_shapes.append(fallback)
	return pending_shapes


func _apply_alpha_collision_polygons(pending_shapes: Array[PackedVector2Array]) -> void:
	if Engine.is_editor_hint() or not is_inside_tree():
		return
	if pending_shapes.is_empty():
		push_warning("Player: alpha collision produced no valid shapes; keeping scene collision shape.")
		return
	if animated_sprite == null:
		return

	var anchor_pos := animated_sprite.position
	_clear_collision_shapes()
	var insert_index := animated_sprite.get_index() + 1
	for centered in pending_shapes:
		var shape := ConvexPolygonShape2D.new()
		shape.points = centered
		var collision := CollisionShape2D.new()
		collision.position = anchor_pos
		collision.shape = shape
		add_child(collision)
		move_child(collision, insert_index)
		insert_index += 1


func _get_sheet_image() -> Image:
	if sprite_sheet != null:
		var image := sprite_sheet.get_image()
		if image != null and not image.is_empty():
			return image
		if not sprite_sheet.resource_path.is_empty() and ResourceLoader.exists(sprite_sheet.resource_path):
			var loaded := load(sprite_sheet.resource_path) as Texture2D
			if loaded != null:
				var reloaded := loaded.get_image()
				if reloaded != null and not reloaded.is_empty():
					return reloaded
	return null


func _crop_sheet_frame_image(sheet_image: Image, frame_index: int) -> Image:
	var region := _region_for_mike_frame(frame_index)
	return sheet_image.get_region(
		Rect2i(int(region.position.x), int(region.position.y), int(region.size.x), int(region.size.y))
	)


func _build_union_alpha_bitmap(sheet_image: Image) -> BitMap:
	var fw := _cell.x
	var fh := _cell.y
	var union := BitMap.new()
	union.create(Vector2i(fw, fh))
	for frame_index in _MIKE_FRAME_COUNT:
		var frame_image := _crop_sheet_frame_image(sheet_image, frame_index)
		var frame_bitmap := BitMap.new()
		frame_bitmap.create_from_image_alpha(frame_image, collision_alpha_threshold)
		for y in fh:
			for x in fw:
				if frame_bitmap.get_bit(x, y):
					union.set_bit(x, y, true)
	return union


func _clear_collision_shapes() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			remove_child(child)
			child.queue_free()


func _bitmap_has_opaque_pixels(bitmap: BitMap) -> bool:
	var size := bitmap.get_size()
	for y in size.y:
		for x in size.x:
			if bitmap.get_bit(x, y):
				return true
	return false


func _copy_bitmap(source: BitMap) -> BitMap:
	var copy := BitMap.new()
	var size := source.get_size()
	copy.create(size)
	for y in size.y:
		for x in size.x:
			if source.get_bit(x, y):
				copy.set_bit(x, y, true)
	return copy


func _bitmap_clip_to_lower_body(bitmap: BitMap, fw: int, fh: int, lower_ratio: float) -> void:
	if lower_ratio >= 1.0:
		return
	var keep_from_y := int(float(fh) * (1.0 - clampf(lower_ratio, 0.0, 1.0)))
	for y in keep_from_y:
		for x in fw:
			bitmap.set_bit(x, y, false)


func _erode_bitmap(source: BitMap, passes: int) -> BitMap:
	if passes <= 0:
		return source
	var size := source.get_size()
	var fw := size.x
	var fh := size.y
	var current := source
	for _pass in passes:
		var eroded := BitMap.new()
		eroded.create(size)
		for y in fh:
			for x in fw:
				if current.get_bit(x, y) and not _bitmap_has_empty_neighbor(current, x, y, fw, fh):
					eroded.set_bit(x, y, true)
		current = eroded
	return current


func _bitmap_has_empty_neighbor(bitmap: BitMap, x: int, y: int, fw: int, fh: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if nx < 0 or ny < 0 or nx >= fw or ny >= fh:
				return true
			if not bitmap.get_bit(nx, ny):
				return true
	return false


func _smooth_collision_polygon(points: PackedVector2Array, iterations: int) -> PackedVector2Array:
	var result := points.duplicate()
	for _iter in iterations:
		if result.size() < 3:
			break
		var smoothed := PackedVector2Array()
		var count := result.size()
		for i in count:
			var p0 := result[i]
			var p1 := result[(i + 1) % count]
			smoothed.append(p0.lerp(p1, 0.25))
			smoothed.append(p0.lerp(p1, 0.75))
		result = smoothed
		if result.size() > 64:
			result = _decimate_polygon(result, 32)
	return Geometry2D.convex_hull(result)


func _decimate_polygon(points: PackedVector2Array, target_count: int) -> PackedVector2Array:
	if points.size() <= target_count:
		return points
	var reduced := PackedVector2Array()
	var step := float(points.size()) / float(target_count)
	var idx := 0.0
	for _i in target_count:
		reduced.append(points[mini(int(idx), points.size() - 1)])
		idx += step
	return reduced


func _sanitize_collision_polygon(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 3:
		return PackedVector2Array()
	var hull := Geometry2D.convex_hull(points)
	if hull.size() < 3:
		return PackedVector2Array()
	if absf(_polygon_signed_area(hull)) < 8.0:
		return PackedVector2Array()
	return hull


func _polygon_signed_area(points: PackedVector2Array) -> float:
	var area := 0.0
	var count := points.size()
	for i in count:
		var p0 := points[i]
		var p1 := points[(i + 1) % count]
		area += p0.x * p1.y - p1.x * p0.y
	return area * 0.5


func _circle_points_from_bitmap(bitmap: BitMap, fw: int, fh: int, frame_center: Vector2) -> PackedVector2Array:
	var min_p := Vector2i(fw, fh)
	var max_p := Vector2i(-1, -1)
	for y in fh:
		for x in fw:
			if bitmap.get_bit(x, y):
				min_p.x = mini(min_p.x, x)
				min_p.y = mini(min_p.y, y)
				max_p.x = maxi(max_p.x, x)
				max_p.y = maxi(max_p.y, y)
	if max_p.x < 0:
		return PackedVector2Array()
	var center := Vector2(float(min_p.x + max_p.x) * 0.5, float(min_p.y + max_p.y) * 0.5) - frame_center
	var radius := Vector2(float(max_p.x - min_p.x), float(max_p.y - min_p.y)).length() * 0.22
	radius = maxf(radius, 6.0)
	var segments := 16
	var circle := PackedVector2Array()
	circle.resize(segments)
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		circle[i] = center + Vector2(cos(angle), sin(angle)) * radius
	return circle


func _inset_polygon_toward_center(points: PackedVector2Array, margin: float) -> PackedVector2Array:
	if points.is_empty() or margin <= 0.0:
		return points
	var center := Vector2.ZERO
	for p in points:
		center += p
	center /= float(points.size())
	var inset := PackedVector2Array()
	inset.resize(points.size())
	for i in points.size():
		var p := points[i]
		var offset := p - center
		var length := offset.length()
		if length <= margin:
			inset[i] = center
		else:
			inset[i] = center + offset * ((length - margin) / length)
	return Geometry2D.convex_hull(inset)


func _apply_overworld_tint() -> void:
	if overworld_tint == Color(1.0, 1.0, 1.0, 1.0):
		var shader := load("res://scenes/fx/white_sprite.gdshader") as Shader
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			animated_sprite.material = mat
			shadow_outline.material = mat
	else:
		animated_sprite.modulate = overworld_tint
	shadow_outline.modulate = Color(0.0, 0.0, 0.0, 0.55)


func configure_leaf_occlusion_masks(
	_mask0: Vector4,
	_mask1: Vector4,
	fade_alpha: float,
	edge_softness: float,
	y_cutoff_0: float = 1e9,
	y_cutoff_1: float = 1e9,
	gate_softness: float = -1.0,
) -> void:
	configure_leaf_occlusion_polygons(
		PackedVector2Array(),
		PackedVector2Array(),
		edge_softness,
		edge_softness,
		fade_alpha,
		y_cutoff_0,
		y_cutoff_1,
		gate_softness,
	)


const _LEAF_POLY_SHADER_MAX := 64


func _pad_leaf_polygon(poly: PackedVector2Array) -> PackedVector2Array:
	var padded := poly.duplicate()
	padded.resize(_LEAF_POLY_SHADER_MAX)
	return padded


func configure_leaf_occlusion_polygons(
	poly0: PackedVector2Array,
	poly1: PackedVector2Array,
	feather0: float,
	feather1: float,
	fade_alpha: float,
	y_cutoff_0: float = 1e9,
	y_cutoff_1: float = 1e9,
	gate_softness: float = -1.0,
	poly2: PackedVector2Array = PackedVector2Array(),
	feather2: float = 0.0,
	y_cutoff_2: float = 1e9,
	use_anchor_y: bool = false,
	poly3: PackedVector2Array = PackedVector2Array(),
	feather3: float = 0.0,
	y_cutoff_3: float = 1e9,
	poly4: PackedVector2Array = PackedVector2Array(),
	feather4: float = 0.0,
	y_cutoff_4: float = 1e9,
	poly5: PackedVector2Array = PackedVector2Array(),
	feather5: float = 0.0,
	y_cutoff_5: float = 1e9,
	slot_parts: Array = [],
	slot_part_cutoffs: Array = [],
) -> void:
	var mat := animated_sprite.material as ShaderMaterial
	if mat == null:
		return
	var gate := 12.0 if gate_softness < 0.0 else gate_softness
	_set_leaf_poly_slot(mat, 0, poly0, feather0, y_cutoff_0, slot_parts, slot_part_cutoffs)
	_set_leaf_poly_slot(mat, 1, poly1, feather1, y_cutoff_1, slot_parts, slot_part_cutoffs)
	_set_leaf_poly_slot(mat, 2, poly2, feather2, y_cutoff_2, slot_parts, slot_part_cutoffs)
	_set_leaf_poly_slot(mat, 3, poly3, feather3, y_cutoff_3, slot_parts, slot_part_cutoffs)
	_set_leaf_poly_slot(mat, 4, poly4, feather4, y_cutoff_4, slot_parts, slot_part_cutoffs)
	_set_leaf_poly_slot(mat, 5, poly5, feather5, y_cutoff_5, slot_parts, slot_part_cutoffs)
	mat.set_shader_parameter("leaf_fade_alpha", clampf(fade_alpha, 0.0, 1.0))
	mat.set_shader_parameter("leaf_gate_softness", maxf(gate, 0.001))
	mat.set_shader_parameter("leaf_mask_use_anchor_y", 1 if use_anchor_y else 0)
	if shadow_outline.material != mat:
		shadow_outline.material = mat


func _set_leaf_poly_slot(
	mat: ShaderMaterial,
	slot: int,
	poly: PackedVector2Array,
	feather: float,
	y_cutoff: float,
	slot_parts: Array = [],
	slot_part_cutoffs: Array = [],
) -> void:
	mat.set_shader_parameter("leaf_poly_%d" % slot, _pad_leaf_polygon(poly))
	mat.set_shader_parameter("leaf_poly_%d_count" % slot, mini(poly.size(), _LEAF_POLY_SHADER_MAX))
	mat.set_shader_parameter("leaf_poly_%d_feather" % slot, maxf(feather, 0.0))
	mat.set_shader_parameter("leaf_y_cutoff_%d" % slot, y_cutoff)
	var parts := Vector4i.ZERO
	if slot < slot_parts.size() and slot_parts[slot] is Vector4i:
		parts = slot_parts[slot]
	mat.set_shader_parameter("leaf_poly_%d_parts" % slot, parts)
	var part_cutoffs := Vector4.ZERO
	if slot < slot_part_cutoffs.size() and slot_part_cutoffs[slot] is Vector4:
		part_cutoffs = slot_part_cutoffs[slot]
	mat.set_shader_parameter("leaf_poly_%d_part_cutoffs" % slot, part_cutoffs)


func set_leaf_occlusion_active(_active: bool) -> void:
	# Kept for scene compatibility; occlusion is now spatial-only and always evaluated.
	# Parameter intentionally unused.
	pass


func _ensure_facing_hitboxes() -> void:
	_remove_retired_facing_hitbox("CollisionBack")
	_remove_retired_facing_hitbox("CollisionSide")
	if use_alpha_collision:
		return
	_bind_facing_hitbox("CollisionFront", _HITBOX_FRONT, HITBOX_FRONT_POS)
	var legacy := _manual_collision("CollisionShape2D")
	if legacy != null:
		legacy.disabled = true


func _remove_retired_facing_hitbox(node_name: String) -> void:
	var node := get_node_or_null(node_name)
	if node == null:
		return
	if Engine.is_editor_hint():
		node.owner = null
	remove_child(node)
	node.free()


func _bind_facing_hitbox(node_name: String, shape: Shape2D, authored_pos: Vector2) -> CollisionShape2D:
	var node := _manual_collision(node_name)
	if node == null:
		node = CollisionShape2D.new()
		node.name = node_name
		add_child(node)
		if Engine.is_editor_hint():
			node.owner = null
	node.shape = shape
	node.position = authored_pos
	node.scale = Vector2.ONE
	node.set_meta("authored_pos", authored_pos)
	return node


func _manual_collision(node_name: String) -> CollisionShape2D:
	return get_node_or_null(node_name) as CollisionShape2D


func _sync_manual_facing_collision() -> void:
	if Engine.is_editor_hint() or use_alpha_collision:
		return
	var front := _manual_collision("CollisionFront")
	if front == null:
		front = _manual_collision("CollisionShape2D")
	if front == null:
		return
	front.disabled = false
	var face_right := _last_facing != Facing.SIDE or _last_side_is_right
	_apply_collision_horizontal_flip(front, face_right)


func _apply_collision_horizontal_flip(collision: CollisionShape2D, face_right: bool) -> void:
	if not collision.has_meta("authored_pos"):
		collision.set_meta("authored_pos", collision.position)
	var authored: Vector2 = collision.get_meta("authored_pos")
	var sign_x := 1.0 if face_right else -1.0
	collision.scale.x = sign_x
	collision.position = Vector2(authored.x * sign_x, authored.y)


func _get_collision_feet_anchor_y() -> float:
	var anchor_y := -1.0e9
	for child in get_children():
		if child is CollisionShape2D:
			var collision := child as CollisionShape2D
			if collision.disabled:
				continue
			var shape := collision.shape
			if shape is ConvexPolygonShape2D:
				var poly := shape as ConvexPolygonShape2D
				for point in poly.points:
					anchor_y = maxf(anchor_y, collision.to_global(point).y)
			elif shape is CircleShape2D:
				var circle := shape as CircleShape2D
				anchor_y = maxf(anchor_y, collision.to_global(Vector2(0.0, circle.radius)).y)
	return anchor_y


func _update_leaf_occlusion_anchor() -> void:
	var mat := animated_sprite.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("player_anchor_y", _get_collision_feet_anchor_y())


func _pose_nudge_resource() -> Resource:
	if _pose_nudge_res != null:
		return _pose_nudge_res
	if ResourceLoader.exists(_POSE_NUDGE_PATH):
		_pose_nudge_res = load(_POSE_NUDGE_PATH)
	return _pose_nudge_res


func _load_pose_nudge_from_disk() -> void:
	var res := _pose_nudge_resource()
	if res == null:
		return
	_pose_nudge_front = res.get("front")
	_pose_nudge_back = res.get("back")
	_pose_nudge_side = res.get("side")


func _save_pose_nudge_to_disk() -> void:
	var res := _pose_nudge_resource()
	if res == null:
		return
	if (
		res.get("front") == _pose_nudge_front
		and res.get("back") == _pose_nudge_back
		and res.get("side") == _pose_nudge_side
	):
		return
	res.set("front", _pose_nudge_front)
	res.set("back", _pose_nudge_back)
	res.set("side", _pose_nudge_side)
	res.emit_changed()
	if Engine.is_editor_hint():
		ResourceSaver.save(res, _POSE_NUDGE_PATH)


func _on_pose_nudge_edited() -> void:
	if not is_inside_tree():
		return
	_apply_editor_pose_preview()
	_apply_pose_nudge()
	_sync_editor_sprite_visibility()
	queue_redraw()
	if Engine.is_editor_hint():
		_save_pose_nudge_to_disk()


func _sync_editor_sprite_visibility() -> void:
	if not Engine.is_editor_hint():
		return
	var sprite := _pose_sprite()
	var has_frames := sprite != null and sprite.sprite_frames != null
	if sprite != null:
		# Pose stack draws the white figure; hide the node so it does not double.
		sprite.visible = not has_frames
	# Do not overwrite ShadowOutline.visible every frame — that locked the Inspector eye off.


func _shadow_offset_for_nudge(nudge: Vector2) -> Vector2:
	# Scale is applied to offset. Divide so the silhouette stays around the figure
	# the same way for Front / Back / Side (pose nudges must not shift the outline).
	return Vector2(
		nudge.x / SHADOW_OUTLINE_SCALE.x,
		nudge.y / SHADOW_OUTLINE_SCALE.y
	)


func _apply_shadow_outline_fit(nudge: Vector2) -> void:
	var shadow := _pose_shadow()
	if shadow == null:
		return
	shadow.position = SHADOW_OUTLINE_POS
	shadow.scale = SHADOW_OUTLINE_SCALE
	shadow.offset = _shadow_offset_for_nudge(nudge)


func _draw_one_editor_pose(
	frames: SpriteFrames,
	anim: StringName,
	nudge: Vector2,
	tint: Color,
	include_shadow: bool
) -> void:
	if not frames.has_animation(anim) or frames.get_frame_count(anim) < 1:
		return
	var tex := frames.get_frame_texture(anim, 0)
	if tex == null:
		return
	var origin := nudge - tex.get_size() * 0.5
	if include_shadow:
		var shadow_tl := (
			SHADOW_OUTLINE_POS
			+ (_shadow_offset_for_nudge(nudge) - tex.get_size() * 0.5) * SHADOW_OUTLINE_SCALE
		)
		draw_set_transform(shadow_tl, 0.0, SHADOW_OUTLINE_SCALE)
		draw_texture(tex, Vector2.ZERO, Color(0.0, 0.0, 0.0, 0.55))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_texture(tex, origin, tint)


func _draw_editor_pose_stack() -> void:
	var sprite := _pose_sprite()
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames := sprite.sprite_frames
	var front_tint := Color(1.0, 1.0, 1.0, 0.42)
	var back_tint := Color(1.0, 0.4, 0.4, 0.42)
	var side_tint := Color(0.4, 0.75, 1.0, 0.42)
	# Faded poses draw their own silhouette. The solid pose uses the ShadowOutline node.
	if editor_pose_preview != 0:
		_draw_one_editor_pose(frames, &"idle", pose_nudge_front, front_tint, true)
	if editor_pose_preview != 1:
		_draw_one_editor_pose(frames, &"idle_back", pose_nudge_back, back_tint, true)
	if editor_pose_preview != 2:
		_draw_one_editor_pose(frames, &"idle_side", pose_nudge_side, side_tint, true)
	match editor_pose_preview:
		1:
			_draw_one_editor_pose(frames, &"idle_back", pose_nudge_back, Color.WHITE, false)
		2:
			_draw_one_editor_pose(frames, &"idle_side", pose_nudge_side, Color.WHITE, false)
		_:
			_draw_one_editor_pose(frames, &"idle", pose_nudge_front, Color.WHITE, false)
	draw_line(Vector2(-18, 0), Vector2(18, 0), Color(1.0, 1.0, 0.0, 0.9), 4.0)
	draw_line(Vector2(0, -18), Vector2(0, 18), Color(1.0, 1.0, 0.0, 0.9), 4.0)


func _pose_nudge_value(facing: Facing) -> Vector2:
	match facing:
		Facing.BACK:
			return pose_nudge_back
		Facing.SIDE:
			return pose_nudge_side
		_:
			return pose_nudge_front


func _editor_preview_anim() -> StringName:
	match editor_pose_preview:
		1:
			return &"idle_back"
		2:
			return &"idle_side"
		_:
			return &"idle"


func _apply_editor_pose_preview() -> void:
	if not Engine.is_editor_hint():
		return
	var sprite := _pose_sprite()
	if sprite == null or sprite.sprite_frames == null:
		return
	var anim := _editor_preview_anim()
	if not sprite.sprite_frames.has_animation(anim):
		return
	if sprite.animation != anim:
		sprite.animation = anim
		sprite.frame = 0
	var shadow := _pose_shadow()
	if shadow != null:
		if shadow.sprite_frames != sprite.sprite_frames:
			shadow.sprite_frames = sprite.sprite_frames
		if shadow.animation != anim:
			shadow.animation = anim
			shadow.frame = 0
		shadow.flip_h = sprite.flip_h
		shadow.modulate = Color(0.0, 0.0, 0.0, 0.55)
	match editor_pose_preview:
		1:
			_last_facing = Facing.BACK
		2:
			_last_facing = Facing.SIDE
			_last_side_is_right = true
		_:
			_last_facing = Facing.FRONT


func _pose_sprite() -> AnimatedSprite2D:
	if animated_sprite != null:
		return animated_sprite
	return get_node_or_null("AnimatedSprite") as AnimatedSprite2D


func _pose_shadow() -> AnimatedSprite2D:
	if shadow_outline != null:
		return shadow_outline
	return get_node_or_null("ShadowOutline") as AnimatedSprite2D


func _apply_pose_nudge() -> void:
	var sprite := _pose_sprite()
	if sprite == null:
		return
	var facing := _last_facing
	if Engine.is_editor_hint():
		match editor_pose_preview:
			1:
				facing = Facing.BACK
			2:
				facing = Facing.SIDE
			_:
				facing = Facing.FRONT
	var nudge := _pose_nudge_value(facing)
	if facing == Facing.SIDE and not _last_side_is_right:
		nudge.x = -nudge.x
	sprite.offset = nudge
	_apply_shadow_outline_fit(nudge)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	var sig := _editor_hitbox_signature()
	if sig != _editor_hitbox_sig:
		_refresh_editor_hitbox_preview()
	_apply_editor_pose_preview()
	_apply_pose_nudge()
	_sync_editor_sprite_visibility()
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	_draw_editor_pose_stack()
	if not use_alpha_collision:
		return
	var anchor := Vector2.ZERO
	if animated_sprite != null:
		anchor = animated_sprite.position
	for poly in _editor_hitbox_polys:
		if poly.size() < 3:
			continue
		var drawn := PackedVector2Array()
		drawn.resize(poly.size())
		for i in poly.size():
			drawn[i] = poly[i] + anchor
		draw_colored_polygon(drawn, _EDITOR_HITBOX_FILL)
		for i in drawn.size():
			draw_line(drawn[i], drawn[(i + 1) % drawn.size()], _EDITOR_HITBOX_LINE, 8.0)


func _editor_hitbox_signature() -> String:
	var sheet_path := ""
	if sprite_sheet != null:
		sheet_path = sprite_sheet.resource_path
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		use_alpha_collision,
		collision_frame_index,
		collision_use_all_frames_union,
		collision_alpha_threshold,
		collision_polygon_epsilon,
		collision_alpha_shrink_pixels,
		collision_smooth_iterations,
		collision_inward_margin,
		collision_lower_body_ratio,
		sheet_path,
		sheet_layout_mode,
		sheet_columns,
		sheet_rows,
		frame_width,
		frame_height,
	]


func _refresh_editor_hitbox_preview() -> void:
	_editor_hitbox_sig = _editor_hitbox_signature()
	_editor_hitbox_polys = _collect_alpha_collision_polygons()
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_leaf_occlusion_anchor()
	if not _input_enabled:
		if _scripted_velocity != Vector2.ZERO:
			velocity = _scripted_velocity
			move_and_slide()
			_apply_locked_feet_y()
			_update_animation(_scripted_velocity)
		else:
			velocity = Vector2.ZERO
			_update_animation(Vector2.ZERO)
		return

	# Named actions (project.godot [input]): WASD + arrows + gamepad stick/d-pad.
	# get_vector is normalized like the old manual sum, and analog tilt scales speed.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = direction * speed
	move_and_slide()
	_apply_locked_feet_y()
	_report_walk_steps_for_cadence()
	_update_animation(direction)


func _apply_locked_feet_y() -> void:
	if locked_feet_y < 0.0:
		return
	var feet_y := _get_collision_feet_anchor_y()
	if feet_y <= -1.0e9:
		return
	var offset := feet_y - global_position.y
	global_position.y = locked_feet_y - offset


func _report_walk_steps_for_cadence() -> void:
	if not _input_enabled:
		return
	var moved := global_position.distance_to(_last_step_position)
	if moved <= 0.001:
		return
	_last_step_position = global_position
	_step_distance_accumulator += moved
	while _step_distance_accumulator >= _STEP_DISTANCE_PX:
		_step_distance_accumulator -= _STEP_DISTANCE_PX
		AxelEventFx.register_walk_step()

func _update_animation(direction: Vector2) -> void:
	if animated_sprite.sprite_frames == null:
		return

	if direction == Vector2.ZERO:
		_play_idle_for_facing()
		return

	var up := direction.y < 0.0
	var down := direction.y > 0.0
	var left := direction.x < 0.0
	var right := direction.x > 0.0

	var anim: StringName
	var flip := false

	if up and (left or right):
		# Up + side diagonal keeps the up (back) cycle.
		anim = &"walk_up"
		_last_facing = Facing.BACK
		if right:
			_last_side_is_right = true
		elif left:
			_last_side_is_right = false
		flip = false
	elif up:
		anim = &"walk_up"
		_last_facing = Facing.BACK
		flip = false
	elif down and (left or right):
		# Down + side diagonal uses the side cycle.
		anim = &"walk_right"
		_last_facing = Facing.SIDE
		if right:
			_last_side_is_right = true
			flip = false
		else:
			_last_side_is_right = false
			flip = true
	elif down:
		anim = &"walk_down"
		_last_facing = Facing.FRONT
		flip = false
	elif right:
		anim = &"walk_right"
		_last_facing = Facing.SIDE
		_last_side_is_right = true
		flip = false
	elif left:
		anim = &"walk_right"
		_last_facing = Facing.SIDE
		_last_side_is_right = false
		flip = true
	else:
		_play_idle_for_facing()
		return

	animated_sprite.flip_h = flip
	shadow_outline.flip_h = flip

	if animated_sprite.animation != anim:
		animated_sprite.play(anim)
		shadow_outline.play(anim)
	elif not animated_sprite.is_playing():
		animated_sprite.play()
		shadow_outline.play()

	_sync_shadow_animation()
	_sync_manual_facing_collision()
	_apply_pose_nudge()


func _play_idle_for_facing() -> void:
	var anim: StringName
	var flip := false
	match _last_facing:
		Facing.BACK:
			anim = &"idle_back"
		Facing.SIDE:
			anim = &"idle_side"
			flip = not _last_side_is_right
		_:
			anim = &"idle"
	animated_sprite.flip_h = flip
	shadow_outline.flip_h = flip
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)
		shadow_outline.play(anim)
	_sync_shadow_animation()
	_sync_manual_facing_collision()
	_apply_pose_nudge()


func _sync_shadow_animation() -> void:
	if shadow_outline.animation != animated_sprite.animation:
		shadow_outline.play(animated_sprite.animation)
	shadow_outline.frame = animated_sprite.frame
	shadow_outline.frame_progress = animated_sprite.frame_progress
	shadow_outline.flip_h = animated_sprite.flip_h
