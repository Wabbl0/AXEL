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

static var _crt_tokens: Dictionary = {}
## Per-host CRT tweens we create (avoids Tween.get_bound_node, not in all Godot 4.x bindings).
static var _crt_tweens: Dictionary = {}


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


static func _host_key(host: Node) -> int:
	return host.get_instance_id()


static func _bump_token(host: Node) -> int:
	var key := _host_key(host)
	var next := int(_crt_tokens.get(key, 0)) + 1
	_crt_tokens[key] = next
	return next


static func _token_valid(host: Node, session: int) -> bool:
	return _host_valid(host) and int(_crt_tokens.get(_host_key(host), 0)) == session


## Awaits one process frame if host is still in a tree. Returns false if host/tree is gone.
static func _await_process_frame(host: Node) -> bool:
	if not _host_valid(host):
		return false
	var tree := host.get_tree()
	if tree == null:
		return false
	await tree.process_frame
	return _host_valid(host)


static func _make_tween(host: Node, parallel: bool = false) -> Tween:
	var tween := host.create_tween()
	if parallel:
		tween.set_parallel(true)
	var key := _host_key(host)
	var list: Array = _crt_tweens.get(key, [])
	list.append(tween)
	_crt_tweens[key] = list
	return tween


static func _kill_crt_tweens(host: Node, _targets: Array = []) -> void:
	if host == null:
		return
	var key := _host_key(host)
	var list: Array = _crt_tweens.get(key, [])
	for tween in list:
		if tween is Tween and (tween as Tween).is_valid():
			(tween as Tween).kill()
	_crt_tweens[key] = []


static func _await_tween(host: Node, session: int, tween: Tween) -> void:
	while tween.is_valid() and tween.is_running():
		if not _token_valid(host, session):
			tween.kill()
			return
		if not await _await_process_frame(host):
			if tween.is_valid():
				tween.kill()
			return


## Kills in-flight CRT tweens, invalidates awaiting power_on/power_off, and resets visuals off.
static func cancel(
	host: Node,
	fade_root: Control,
	panel: Control,
	beam: CanvasItem,
	bloom: CanvasItem,
) -> void:
	if host == null:
		return
	_bump_token(host)
	if not _host_valid(host):
		return
	_kill_crt_tweens(host, [fade_root, panel, beam, bloom])
	reset_visual(fade_root, panel, beam, bloom)
	if is_instance_valid(fade_root):
		fade_root.modulate.a = 0.0
	if is_instance_valid(panel):
		panel.scale = Vector2.ZERO


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
	var session := _bump_token(host)
	var o := opts if opts != null else default_options()
	if not await _await_process_frame(host):
		return
	if not _token_valid(host, session):
		return
	reset_pivot(panel)
	panel.scale = Vector2.ZERO
	fade_root.modulate.a = 0.0
	beam.modulate.a = 0.0
	bloom.modulate.a = 0.0

	var tw_bright := _make_tween(host, true)
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
	await _await_tween(host, session, tw_bright)
	if not _token_valid(host, session):
		return

	var tw_grow := _make_tween(host, true)
	tw_grow.tween_property(
		panel,
		"scale",
		Vector2(1.0, CRT_LINE_SCALE_Y),
		CRT_OFF_SHRINK_SEC,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if o.enable_beam:
		tw_grow.tween_property(beam, "modulate:a", CRT_BEAM_ALPHA, CRT_OFF_SHRINK_SEC * 0.3)
	await _await_tween(host, session, tw_grow)
	if not _token_valid(host, session):
		return

	var tw_flash := _make_tween(host)
	tw_flash.tween_property(bloom, "modulate:a", o.bloom_flash_peak, CRT_OFF_FLASH_SEC * 0.4)
	tw_flash.tween_property(bloom, "modulate:a", 0.0, CRT_OFF_FLASH_SEC * 0.6)
	await _await_tween(host, session, tw_flash)
	if not _token_valid(host, session):
		return

	var tw_expand := _make_tween(host, true)
	tw_expand.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		CRT_OFF_COLLAPSE_SEC,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if o.enable_beam:
		tw_expand.tween_property(beam, "modulate:a", 0.0, CRT_OFF_COLLAPSE_SEC * 0.25)
	await _await_tween(host, session, tw_expand)
	if not _token_valid(host, session):
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
	var session := _bump_token(host)
	var o := opts if opts != null else default_options()
	if not await _await_process_frame(host):
		return
	if not _token_valid(host, session):
		return
	reset_pivot(panel)

	var tw_collapse := _make_tween(host, true)
	tw_collapse.tween_property(
		panel,
		"scale",
		Vector2(1.0, CRT_LINE_SCALE_Y),
		CRT_OFF_COLLAPSE_SEC,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if o.enable_beam:
		tw_collapse.tween_property(beam, "modulate:a", CRT_BEAM_ALPHA, CRT_OFF_COLLAPSE_SEC * 0.25)
	await _await_tween(host, session, tw_collapse)
	if not _token_valid(host, session):
		return

	var tw_flash := _make_tween(host)
	tw_flash.tween_property(bloom, "modulate:a", o.bloom_flash_peak, CRT_OFF_FLASH_SEC * 0.4)
	tw_flash.tween_property(bloom, "modulate:a", 0.0, CRT_OFF_FLASH_SEC * 0.6)
	await _await_tween(host, session, tw_flash)
	if not _token_valid(host, session):
		return

	var tw_shrink := _make_tween(host, true)
	tw_shrink.tween_property(
		panel,
		"scale",
		Vector2(CRT_DOT_SCALE, CRT_LINE_SCALE_Y),
		CRT_OFF_SHRINK_SEC,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if o.enable_beam:
		tw_shrink.tween_property(beam, "modulate:a", CRT_BEAM_ALPHA, CRT_OFF_SHRINK_SEC * 0.3)
	await _await_tween(host, session, tw_shrink)
	if not _token_valid(host, session):
		return

	var tw_dark := _make_tween(host, true)
	tw_dark.tween_property(panel, "scale", Vector2.ZERO, CRT_OFF_AFTERGLOW_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_dark.tween_property(fade_root, "modulate:a", 0.0, CRT_OFF_AFTERGLOW_SEC)
	if o.enable_beam:
		tw_dark.tween_property(beam, "modulate:a", 0.0, CRT_OFF_AFTERGLOW_SEC)
	tw_dark.tween_property(bloom, "modulate:a", 0.0, CRT_OFF_AFTERGLOW_SEC)
	await _await_tween(host, session, tw_dark)
	if not _token_valid(host, session):
		return
	reset_visual(fade_root, panel, beam, bloom)
