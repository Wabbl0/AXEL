class_name CombatFeel
extends Node
## Visual-only combat juice (Phase 3). Never touches CombatRNG.

const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")

var _root: Node2D
var _grid_ui: Control
var _shake_host: Node2D
var _banner: Label
var _banner_scrim: ColorRect
var _grime: ColorRect
var _grime_band: ColorRect
var _banner_tween: Tween
var _shake_tween: Tween
var _wobble_tween: Tween
var _host_rest: Vector2 = Vector2.ZERO


func setup(root: Node2D, grid_ui: Control) -> void:
	_root = root
	_grid_ui = grid_ui
	_shake_host = root
	_host_rest = root.position
	_build()


func _build() -> void:
	if _grid_ui == null:
		return
	var host := _grid_ui.get_parent()
	var overlay := Control.new()
	overlay.name = "FeelGridOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if host != null:
		host.add_child(overlay)
	else:
		_grid_ui.add_child(overlay)
	_grime = ColorRect.new()
	_grime.name = "FeelGrime"
	_grime.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grime.color = Color(0.08, 0.02, 0.02, 0.0)
	overlay.add_child(_grime)
	_grime_band = ColorRect.new()
	_grime_band.name = "FeelGrimeBand"
	_grime_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grime_band.color = Color(0.04, 0.0, 0.0, 0.0)
	overlay.add_child(_grime_band)
	var layer := CanvasLayer.new()
	layer.name = "FeelLayer"
	layer.layer = 95
	_root.add_child(layer)
	_banner_scrim = ColorRect.new()
	_banner_scrim.name = "FeelBannerScrim"
	_banner_scrim.color = Color(0.0, 0.0, 0.0, 0.0)
	_banner_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_banner_scrim)
	_banner = Label.new()
	_banner.name = "FeelBanner"
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_override("font", FONT)
	_banner.add_theme_font_size_override("font_size", 96)
	_banner.add_theme_color_override("font_color", Color(0.75, 0.04, 0.04, 1.0))
	_banner.modulate.a = 0.0
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_banner)


func set_goal_progress(ratio: float) -> void:
	if _grime == null:
		return
	if _grid_ui != null:
		var overlay := _grime.get_parent() as Control
		if overlay != null:
			overlay.position = _grid_ui.position
			overlay.size = _grid_ui.size
		_grime.size = _grid_ui.size
		_grime.position = Vector2.ZERO
	var t := clampf(ratio, 0.0, 1.0)
	_grime.color.a = t * 0.28
	if _grime_band != null:
		_grime_band.size = Vector2(_grime.size.x, maxf(8.0, _grime.size.y * t * 0.35))
		_grime_band.position = Vector2(0.0, _grime.size.y - _grime_band.size.y)
		_grime_band.color.a = t * 0.45


## No-op. The dim corner icon row is gone; the center PowerIntroIcon already shows
## which princess is acting. Kept so Trinity call sites stay valid.
func highlight_princess(_id_name: StringName) -> void:
	pass


func play_banner(text: String, hold_sec: float = 0.55, scrim_a: float = 0.62) -> void:
	if _banner == null:
		return
	_banner.text = text
	_kill(_banner_tween)
	_banner.modulate.a = 0.0
	_banner_scrim.color = Color(0.0, 0.0, 0.0, 0.0)
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.18)
	_banner_tween.parallel().tween_property(_banner_scrim, "color:a", scrim_a, 0.18)
	_banner_tween.tween_interval(hold_sec)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.35)
	_banner_tween.parallel().tween_property(_banner_scrim, "color:a", 0.0, 0.35)


func shake(multiplier_value: int, settings: Node) -> void:
	if _shake_host == null:
		return
	if settings != null:
		if bool(settings.call("get_value", "access", "reduce_flashing", false)):
			return
		var scale := clampf(float(settings.call("get_value", "access", "screen_shake", 1.0)), 0.0, 1.0)
		if scale <= 0.01:
			return
	var amp := 2.0 + float(maxi(multiplier_value, 1)) * 1.6
	if settings != null:
		amp *= clampf(float(settings.call("get_value", "access", "screen_shake", 1.0)), 0.0, 1.0)
	_kill(_shake_tween)
	_shake_host.position = _host_rest
	_shake_tween = create_tween()
	for i in 5:
		var kick := Vector2(amp if i % 2 == 0 else -amp, amp * 0.4 if i % 2 == 0 else -amp * 0.4)
		_shake_tween.tween_property(_shake_host, "position", _host_rest + kick, 0.03)
	_shake_tween.tween_property(_shake_host, "position", _host_rest, 0.05)


func crt_wobble(multiplier_value: int, settings: Node) -> void:
	if _shake_host == null:
		return
	if settings != null:
		if bool(settings.call("get_value", "access", "reduce_flashing", false)):
			return
		if clampf(float(settings.call("get_value", "access", "screen_shake", 1.0)), 0.0, 1.0) <= 0.01:
			return
	var amp := 1.2 + float(maxi(multiplier_value, 1)) * 0.35
	if settings != null:
		amp *= clampf(float(settings.call("get_value", "access", "screen_shake", 1.0)), 0.0, 1.0)
	_kill(_wobble_tween)
	_wobble_tween = create_tween()
	for i in 6:
		var kick := Vector2(amp if i % 2 == 0 else -amp, 0.0)
		_wobble_tween.tween_property(_shake_host, "position", _host_rest + kick, 0.05)
	_wobble_tween.tween_property(_shake_host, "position", _host_rest, 0.08)


func glitch_flash(settings: Node) -> void:
	if _banner_scrim == null:
		return
	if settings != null and bool(settings.call("get_value", "access", "reduce_flashing", false)):
		return
	var peak := 0.28
	if settings != null:
		peak *= clampf(float(settings.call("get_value", "access", "glitch_intensity", 1.0)), 0.0, 1.0)
	_banner_scrim.color = Color(0.9, 0.05, 0.05, peak)
	var tw := create_tween()
	tw.tween_property(_banner_scrim, "color:a", 0.0, 0.12)


func _kill(tw: Tween) -> void:
	if tw != null and is_instance_valid(tw):
		tw.kill()
