extends CharacterBody2D

enum SheetLayoutMode {
	AUTO,
	HORIZONTAL_13,
	GRID,
}

const _MIKE_FRAME_INDICES := {
	&"idle": [0],
	&"walk_right": [1, 2, 3],
	&"walk_left": [4, 5, 6],
	&"walk_up_right": [7, 8, 9],
	&"walk_up_left": [10, 11, 12],
}

const _MIKE_FRAME_COUNT := 13

@export var speed: float = 220.0
@export var overworld_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
## When empty, tries common paths under res://assets/sprites/ (including mike walking exports).
@export var sprite_sheet: Texture2D
## AUTO: wide strip if width divisible by 13; else if width and height divisible by sheet_columns / sheet_rows, use GRID.
@export var sheet_layout_mode: SheetLayoutMode = SheetLayoutMode.AUTO
## For GRID / AUTO grid: your Aseprite “Sheet” export is often 4×4 cells (13 frames used).
@export var sheet_columns: int = 4
@export var sheet_rows: int = 4
## Forced cell size; if 0, derived from texture and layout (recommended).
@export var frame_width: int = 0
@export var frame_height: int = 0
@export var animation_fps: float = 10.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var shadow_outline: AnimatedSprite2D = $ShadowOutline
@onready var fallback_body: Polygon2D = $FallbackBody

## Right-side walks (walk_right / walk_up_right) vs left-side; W-only and S-only use this. Idle does not clear it.
var _last_side_is_right: bool = true

var _layout: SheetLayoutMode = SheetLayoutMode.HORIZONTAL_13
var _cell: Vector2i = Vector2i(32, 32)

func _ready() -> void:
	if sprite_sheet == null:
		sprite_sheet = _try_load_default_sprite_sheet()
	if sprite_sheet:
		_resolve_layout_and_cell()
		_build_sprite_frames()
		_setup_shadow_outline()
		fallback_body.visible = false
		animated_sprite.visible = true
		_apply_overworld_tint()
	else:
		fallback_body.visible = true
		animated_sprite.visible = false
		shadow_outline.visible = false

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


func _apply_overworld_tint() -> void:
	if overworld_tint == Color(1.0, 1.0, 1.0, 1.0):
		var shader := load("res://scenes/fx/white_sprite.gdshader") as Shader
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			animated_sprite.material = mat
	else:
		animated_sprite.modulate = overworld_tint
	shadow_outline.modulate = Color(0.0, 0.0, 0.0, 0.55)

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1.0

	velocity = direction.normalized() * speed
	move_and_slide()
	_update_animation(direction)

func _update_animation(direction: Vector2) -> void:
	if animated_sprite.sprite_frames == null:
		return

	if direction == Vector2.ZERO:
		_sync_shadow_animation()
		if animated_sprite.animation != &"idle":
			animated_sprite.play(&"idle")
			shadow_outline.play(&"idle")
		return

	var up := direction.y < 0.0
	var down := direction.y > 0.0
	var left := direction.x < 0.0
	var right := direction.x > 0.0

	var anim: StringName
	if up and right:
		anim = &"walk_up_right"
		_last_side_is_right = true
	elif up and left:
		anim = &"walk_up_left"
		_last_side_is_right = false
	elif up:
		anim = &"walk_up_right" if _last_side_is_right else &"walk_up_left"
	elif down and right:
		anim = &"walk_right"
		_last_side_is_right = true
	elif down and left:
		anim = &"walk_left"
		_last_side_is_right = false
	elif down:
		anim = &"walk_right" if _last_side_is_right else &"walk_left"
	elif right:
		anim = &"walk_right"
		_last_side_is_right = true
	elif left:
		anim = &"walk_left"
		_last_side_is_right = false
	else:
		anim = &"idle"

	if animated_sprite.animation != anim:
		animated_sprite.play(anim)
		shadow_outline.play(anim)
	elif not animated_sprite.is_playing():
		animated_sprite.play()
		shadow_outline.play()

	_sync_shadow_animation()

func _sync_shadow_animation() -> void:
	if shadow_outline.animation != animated_sprite.animation:
		shadow_outline.play(animated_sprite.animation)
	shadow_outline.frame = animated_sprite.frame
	shadow_outline.frame_progress = animated_sprite.frame_progress
