extends Node2D

@onready var background: ColorRect = $Background
@onready var ceiling_light: PointLight2D = $CeilingLight
@onready var _top_dialogue: Node = $TopDialogueOverlay
@onready var _highlighted_locker_bypass: Sprite2D = $LockerBypassLayer/HighlightedLockerBypass
@onready var _highlighted_locker_aura: Sprite2D = $LockerBypassLayer/HighlightedLockerAura

const _USE_LOCAL_NOIR_TUNING := false
const _USE_HIGHLIGHT_PULSE := true
const _LOCKER_BASE_SCALE := Vector2(2.06, 2.06)
const _LOCKER_AURA_BASE_SCALE := Vector2(2.16, 2.16)

var _flicker_time := 0.0

func _ready() -> void:
	if _USE_LOCAL_NOIR_TUNING:
		_apply_local_noir_tuning()
	_start_push_in_tween()
	_show_spawn_line()


func _show_spawn_line() -> void:
	await _top_dialogue.show_line("Even after all these years the smell is the same.", 3.5)

func _process(delta: float) -> void:
	_flicker_time += delta
	_update_ceiling_flicker()
	_update_highlight_pulse()

func _start_push_in_tween() -> void:
	background.scale = Vector2.ONE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(background, "scale", Vector2(1.04, 1.04), 3.2)

func _update_ceiling_flicker() -> void:
	var base_energy := 0.72 + (sin(_flicker_time * 7.0) * 0.18)
	if int(_flicker_time * 14.0) % 13 == 0:
		base_energy = 0.2
	ceiling_light.energy = clamp(base_energy, 0.15, 1.1)


func _apply_local_noir_tuning() -> void:
	var filter_rect: ColorRect = null
	var stack := get_node_or_null("/root/AxelPostFxStack")
	if stack != null and stack.has_method("get_noir_filter_rect"):
		filter_rect = stack.get_noir_filter_rect()
	if filter_rect == null:
		filter_rect = get_node_or_null("NoirPaletteOverlay/FilterRect") as ColorRect
	var shader_material := filter_rect.material as ShaderMaterial if filter_rect != null else null
	if shader_material == null:
		return

	# Local Scene 1.2 guardrail: reduce how many corridor texels collapse to pure white.
	shader_material.set_shader_parameter("t2", 0.72)
	shader_material.set_shader_parameter("white_color", Color(0.93, 0.93, 0.93, 1.0))


func _update_highlight_pulse() -> void:
	if not _USE_HIGHLIGHT_PULSE:
		return
	if not is_instance_valid(_highlighted_locker_bypass):
		return

	var pulse := 0.5 + (0.5 * sin(_flicker_time * 3.2))
	var glow_mix := 0.14 + (pulse * 0.24)
	_highlighted_locker_bypass.modulate = Color(
		1.0,
		1.0,
		1.0,
		1.0
	).lerp(Color(1.2, 1.0, 1.0, 1.0), glow_mix)
	var scale_boost := 1.0 + (pulse * 0.016)
	_highlighted_locker_bypass.scale = _LOCKER_BASE_SCALE * scale_boost

	if is_instance_valid(_highlighted_locker_aura):
		var aura_alpha := 0.20 + (pulse * 0.25)
		_highlighted_locker_aura.modulate = Color(1.2, 1.16, 1.16, aura_alpha)
		var aura_scale_boost := 1.0 + (pulse * 0.05)
		_highlighted_locker_aura.scale = _LOCKER_AURA_BASE_SCALE * aura_scale_boost
