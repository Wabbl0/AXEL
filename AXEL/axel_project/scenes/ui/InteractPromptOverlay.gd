extends CanvasLayer

const CrtPowerFx = preload("res://scenes/ui/crt_power_fx.gd")

## World-anchored interact key chip; CRT on/off uses compact opts (no white beam wash).

@export var key_label := "[E]"
@export var screen_offset := Vector2(0.0, -52.0)

@onready var _root: Control = $ViewportRoot/ChipRoot
@onready var _panel: PanelContainer = $ViewportRoot/ChipRoot/BarPanel
@onready var _beam: ColorRect = $ViewportRoot/ChipRoot/BarPanel/PowerBeam
@onready var _bloom: ColorRect = $ViewportRoot/ChipRoot/BarPanel/Bloom
@onready var _label: Label = $ViewportRoot/ChipRoot/BarPanel/InnerPanel/KeyLabel

var _world_anchor := Vector2.ZERO
var _is_active := false
var _crt_settled := false
var _anim_token := 0
var _crt_opts = CrtPowerFx.compact_chip_options()


func _ready() -> void:
	layer = 111
	_label.text = key_label
	_root.visible = false
	_root.modulate.a = 0.0
	_beam.visible = false
	_set_ignore_mouse_recursive(self)
	set_process(false)
	CrtPowerFx.reset_visual(_root, _panel, _beam, _bloom)
	tree_exiting.connect(_on_tree_exiting)


func _on_tree_exiting() -> void:
	_anim_token += 1


func _host_alive() -> bool:
	return is_instance_valid(self) and is_inside_tree() and get_tree() != null


func _process(_delta: float) -> void:
	if not _is_active:
		return
	_update_screen_position()


func set_world_anchor(world_pos: Vector2) -> void:
	_world_anchor = world_pos
	if _is_active:
		_update_screen_position()


func show_prompt(world_pos: Vector2) -> void:
	_world_anchor = world_pos
	if _is_active and _crt_settled:
		_update_screen_position()
		return
	if _is_active:
		return
	_run_show_async()


func hide_prompt() -> void:
	if not _is_active:
		return
	_run_hide_async()


## Instant hide for scene transitions; skips CRT tweens so unload cannot race power_off.
func hide_prompt_immediate() -> void:
	_anim_token += 1
	CrtPowerFx.cancel(self, _root, _panel, _beam, _bloom)
	_is_active = false
	_crt_settled = false
	_root.visible = false
	_root.modulate.a = 0.0
	set_process(false)


func is_prompt_visible() -> bool:
	return _is_active and _root.visible and _root.modulate.a > 0.01


func _run_show_async() -> void:
	if not _host_alive():
		return
	_anim_token += 1
	var token := _anim_token
	_is_active = true
	_crt_settled = false
	_root.visible = true
	set_process(true)
	_update_screen_position()
	await CrtPowerFx.power_on(self, _root, _panel, _beam, _bloom, _crt_opts)
	if not _host_alive() or token != _anim_token:
		return
	_crt_settled = true
	_update_screen_position()


func _run_hide_async() -> void:
	if not _host_alive():
		return
	_anim_token += 1
	var token := _anim_token
	_crt_settled = false
	await CrtPowerFx.power_off(self, _root, _panel, _beam, _bloom, _crt_opts)
	if not _host_alive() or token != _anim_token:
		return
	_is_active = false
	_root.visible = false
	set_process(false)
	CrtPowerFx.reset_visual(_root, _panel, _beam, _bloom)


func _update_screen_position() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var screen_pos := viewport.get_canvas_transform() * _world_anchor
	var panel_size := _panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		panel_size = _panel.get_combined_minimum_size()
	_chip_root_position(screen_pos + screen_offset - panel_size * 0.5)


func _chip_root_position(pos: Vector2) -> void:
	_root.position = pos


func _set_ignore_mouse_recursive(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_set_ignore_mouse_recursive(c)
