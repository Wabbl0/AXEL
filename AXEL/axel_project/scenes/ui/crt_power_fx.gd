extends RefCounted

## Shared CRT TV power-on/off tweens for dialogue bar and interact prompt overlays.

const CRT_DOT_SCALE := 0.02
const CRT_LINE_SCALE_Y := 0.03
const CRT_OFF_COLLAPSE_SEC := 0.16
const CRT_OFF_FLASH_SEC := 0.06
const CRT_OFF_SHRINK_SEC := 0.12
const CRT_OFF_AFTERGLOW_SEC := 0.12
const CRT_BEAM_ALPHA := 0.95
const CRT_BLOOM_ALPHA := 0.85


class Options:
	var enable_beam := true
	var bloom_surge_peak := CRT_BLOOM_ALPHA
	var bloom_flash_peak := 1.0


static func default_options() -> Options:
	return Options.new()


static func compact_chip_options() -> Options:
	var opts := Options.new()
	opts.enable_beam = false
	opts.bloom_surge_peak = 0.38
	opts.bloom_flash_peak = 0.52
	return opts


static func _host_valid(host: Node) -> bool:
	return host != null and is_instance_valid(host) and host.get_tree() != null


static func reset_pivot(panel: Control) -> void:
	if not is_instance_valid(panel):
		return
	var sz := panel.size
	if sz.x > 0.0 and sz.y > 0.0:
		panel.pivot_offset = sz * 0.5


static func reset_visual(
	fade_root: Control,
	panel: Control,
	beam: CanvasItem,
	bloom: CanvasItem,
) -> void:
	if is_instance_valid(panel):
		panel.scale = Vector2.ONE
		reset_pivot(panel)
	if is_instance_valid(beam):
		beam.modulate.a = 0.0
	if is_instance_valid(bloom):
		bloom.modulate.a = 0.0
	if is_instance_valid(fade_root):
		fade_root.modulate.a = 1.0


static func power_on(
	host: Node,
	fade_root: Control,
	panel: Control,
	beam: CanvasItem,
	bloom: CanvasItem,
	opts: Options = null,
) -> void:
	if not _host_valid(host):
		return
	var o := opts if opts != null else default_options()
	await host.get_tree().process_frame
	if not _host_valid(host):
		return
	reset_pivot(panel)
	panel.scale = Vector2.ZERO
	fade_root.modulate.a = 0.0
	beam.modulate.a = 0.0
	bloom.modulate.a = 0.0

	var tw_bright := host.create_tween().set_parallel(true)
	tw_bright.tween_property(
		panel,
		"scale",
		Vector2(CRT_DOT_SCALE, CRT_LINE_SCALE_Y),
		CRT_OFF_AFTERGLOW_SEC,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_bright.tween_property(fade_root, "modulate:a", 1.0, CRT_OFF_AFTERGLOW_SEC)
	if o.enable_beam:
		tw_bright.tween_property(beam, "modulate:a", CRT_BEAM_ALPHA, CRT_OFF_AFTERGLOW_SEC)
	tw_bright.tween_property(bloom, "modulate:a", o.bloom_surge_peak, CRT_OFF_AFTERGLOW_SEC)
	await tw_bright.finished
	if not _host_valid(host):
		return

	var tw_grow := host.create_tween().set_parallel(true)
	tw_grow.tween_property(
		panel,
		"scale",
		Vector2(1.0, CRT_LINE_SCALE_Y),
		CRT_OFF_SHRINK_SEC,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if o.enable_beam:
		tw_grow.tween_property(beam, "modulate:a", CRT_BEAM_ALPHA, CRT_OFF_SHRINK_SEC * 0.3)
	await tw_grow.finished
	if not _host_valid(host):
		return

	var tw_flash := host.create_tween()
	tw_flash.tween_property(bloom, "modulate:a", o.bloom_flash_peak, CRT_OFF_FLASH_SEC * 0.4)
	tw_flash.tween_property(bloom, "modulate:a", 0.0, CRT_OFF_FLASH_SEC * 0.6)
	await tw_flash.finished
	if not _host_valid(host):
		return

	var tw_expand := host.create_tween().set_parallel(true)
	tw_expand.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		CRT_OFF_COLLAPSE_SEC,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if o.enable_beam:
		tw_expand.tween_property(beam, "modulate:a", 0.0, CRT_OFF_COLLAPSE_SEC * 0.25)
	await tw_expand.finished
	if not _host_valid(host):
		return
	reset_visual(fade_root, panel, beam, bloom)


## Exact reverse of power_on from the settled post-on state (no upfront beam/bloom spike).
static func power_off(
	host: Node,
	fade_root: Control,
	panel: Control,
	beam: CanvasItem,
	bloom: CanvasItem,
	opts: Options = null,
) -> void:
	if not _host_valid(host):
		return
	var o := opts if opts != null else default_options()
	await host.get_tree().process_frame
	if not _host_valid(host):
		return
	reset_pivot(panel)

	var tw_collapse := host.create_tween().set_parallel(true)
	tw_collapse.tween_property(
		panel,
		"scale",
		Vector2(1.0, CRT_LINE_SCALE_Y),
		CRT_OFF_COLLAPSE_SEC,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if o.enable_beam:
		tw_collapse.tween_property(beam, "modulate:a", CRT_BEAM_ALPHA, CRT_OFF_COLLAPSE_SEC * 0.25)
	await tw_collapse.finished
	if not _host_valid(host):
		return

	var tw_flash := host.create_tween()
	tw_flash.tween_property(bloom, "modulate:a", o.bloom_flash_peak, CRT_OFF_FLASH_SEC * 0.4)
	tw_flash.tween_property(bloom, "modulate:a", 0.0, CRT_OFF_FLASH_SEC * 0.6)
	await tw_flash.finished
	if not _host_valid(host):
		return

	var tw_shrink := host.create_tween().set_parallel(true)
	tw_shrink.tween_property(
		panel,
		"scale",
		Vector2(CRT_DOT_SCALE, CRT_LINE_SCALE_Y),
		CRT_OFF_SHRINK_SEC,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if o.enable_beam:
		tw_shrink.tween_property(beam, "modulate:a", CRT_BEAM_ALPHA, CRT_OFF_SHRINK_SEC * 0.3)
	await tw_shrink.finished
	if not _host_valid(host):
		return

	var tw_dark := host.create_tween().set_parallel(true)
	tw_dark.tween_property(panel, "scale", Vector2.ZERO, CRT_OFF_AFTERGLOW_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_dark.tween_property(fade_root, "modulate:a", 0.0, CRT_OFF_AFTERGLOW_SEC)
	if o.enable_beam:
		tw_dark.tween_property(beam, "modulate:a", 0.0, CRT_OFF_AFTERGLOW_SEC)
	tw_dark.tween_property(bloom, "modulate:a", 0.0, CRT_OFF_AFTERGLOW_SEC)
	await tw_dark.finished
	if not _host_valid(host):
		return
	reset_visual(fade_root, panel, beam, bloom)
