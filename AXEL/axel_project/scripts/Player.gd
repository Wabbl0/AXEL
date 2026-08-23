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
const _HITBOX_BACK := preload("res://scenes/player/hitbox_back.tres")
const _HITBOX_SIDE := preload("res://scenes/player/hitbox_side.tres")

@export var speed: float = 220.0
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
@export var animation_fps: float = 10.0
## If true, traces collision from sprite alpha. Default is the shared facing hitboxes
## (`res://scenes/player/hitbox_front.tres` / `hitbox_back.tres` / `hitbox_side.tres`).
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
	if Engine.is_editor_hint():
		set_process(true)
		set_physics_process(false)


func _ready() -> void:
	if Engine.is_editor_hint():
		_ensure_facing_hitboxes()
		_refresh_editor_hitbox_preview()
		return
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
) -> void:
	var mat := animated_sprite.material as ShaderMaterial
	if mat == null:
		return
	var gate := 12.0 if gate_softness < 0.0 else gate_softness
	mat.set_shader_parameter("leaf_poly_0", _pad_leaf_polygon(poly0))
	mat.set_shader_parameter("leaf_poly_0_count", mini(poly0.size(), _LEAF_POLY_SHADER_MAX))
	mat.set_shader_parameter("leaf_poly_0_feather", maxf(feather0, 0.0))
	mat.set_shader_parameter("leaf_poly_1", _pad_leaf_polygon(poly1))
	mat.set_shader_parameter("leaf_poly_1_count", mini(poly1.size(), _LEAF_POLY_SHADER_MAX))
	mat.set_shader_parameter("leaf_poly_1_feather", maxf(feather1, 0.0))
	mat.set_shader_parameter("leaf_poly_2", _pad_leaf_polygon(poly2))
	mat.set_shader_parameter("leaf_poly_2_count", mini(poly2.size(), _LEAF_POLY_SHADER_MAX))
	mat.set_shader_parameter("leaf_poly_2_feather", maxf(feather2, 0.0))
	mat.set_shader_parameter("leaf_fade_alpha", clampf(fade_alpha, 0.0, 1.0))
	mat.set_shader_parameter("leaf_gate_softness", maxf(gate, 0.001))
	mat.set_shader_parameter("leaf_y_cutoff_0", y_cutoff_0)
	mat.set_shader_parameter("leaf_y_cutoff_1", y_cutoff_1)
	mat.set_shader_parameter("leaf_y_cutoff_2", y_cutoff_2)
	mat.set_shader_parameter("leaf_mask_use_anchor_y", 1 if use_anchor_y else 0)
	if shadow_outline.material != mat:
		shadow_outline.material = mat


func set_leaf_occlusion_active(_active: bool) -> void:
	# Kept for scene compatibility; occlusion is now spatial-only and always evaluated.
	# Parameter intentionally unused.
	pass


func _ensure_facing_hitboxes() -> void:
	if use_alpha_collision:
		return
	_bind_facing_hitbox("CollisionFront", _HITBOX_FRONT)
	_bind_facing_hitbox("CollisionBack", _HITBOX_BACK)
	_bind_facing_hitbox("CollisionSide", _HITBOX_SIDE)
	var legacy := _manual_collision("CollisionShape2D")
	if legacy != null:
		legacy.disabled = true


func _bind_facing_hitbox(node_name: String, shape: Shape2D) -> CollisionShape2D:
	var node := _manual_collision(node_name)
	if node == null:
		node = CollisionShape2D.new()
		node.name = node_name
		add_child(node)
		if Engine.is_editor_hint():
			node.owner = null
	node.shape = shape
	node.position = Vector2.ZERO
	node.scale = Vector2.ONE
	node.set_meta("authored_pos", Vector2.ZERO)
	return node


func _manual_collision(node_name: String) -> CollisionShape2D:
	return get_node_or_null(node_name) as CollisionShape2D


func _sync_manual_facing_collision() -> void:
	if Engine.is_editor_hint() or use_alpha_collision:
		return
	var front := _manual_collision("CollisionFront")
	if front == null:
		front = _manual_collision("CollisionShape2D")
	var back := _manual_collision("CollisionBack")
	var side := _manual_collision("CollisionSide")
	if back == null and side == null:
		if front != null:
			_apply_collision_horizontal_flip(front, not (_last_facing == Facing.SIDE and not _last_side_is_right))
		return
	if front != null:
		front.disabled = _last_facing != Facing.FRONT
		_apply_collision_horizontal_flip(front, true)
	if back != null:
		back.disabled = _last_facing != Facing.BACK
		_apply_collision_horizontal_flip(back, true)
	if side != null:
		side.disabled = _last_facing != Facing.SIDE
		_apply_collision_horizontal_flip(side, _last_side_is_right)


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


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	var sig := _editor_hitbox_signature()
	if sig != _editor_hitbox_sig:
		_refresh_editor_hitbox_preview()


func _draw() -> void:
	if not Engine.is_editor_hint() or not use_alpha_collision:
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

	var direction := Vector2.ZERO

	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1.0

	velocity = direction.normalized() * speed if direction != Vector2.ZERO else Vector2.ZERO
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


func _sync_shadow_animation() -> void:
	if shadow_outline.animation != animated_sprite.animation:
		shadow_outline.play(animated_sprite.animation)
	shadow_outline.frame = animated_sprite.frame
	shadow_outline.frame_progress = animated_sprite.frame_progress
	shadow_outline.flip_h = animated_sprite.flip_h
