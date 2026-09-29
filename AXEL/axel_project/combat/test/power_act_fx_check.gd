extends SceneTree

const CombatRootScene := preload("res://combat/scenes/combat_root.tscn")
const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")
const GridManagerScript := preload("res://combat/scripts/grid_manager.gd")
const PowerFxShader := preload("res://combat/shaders/power_symbol_fx.gdshader")

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	OS.set_environment("AXEL_DISABLE_EVENT_FX", "1")
	OS.set_environment("AXEL_DISABLE_POST_FX", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)
	push_error(msg)


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	await process_frame
	await _assert_timing_budget()
	await _assert_logs_match_board(&"bloody_hand", &"morph")
	await _assert_logs_match_board(&"alcohol", &"eat")
	await _assert_logs_match_board(&"cigarette", &"burn")
	await _assert_missing_log_is_safe()
	await _assert_same_seed_same_board()
	await _assert_collapse_keeps_last_kind()
	await _assert_slot_motions()
	await _assert_play_clears_and_times()
	if DisplayServer.get_name() != "headless":
		await _assert_shader_compiles()
	if not _failures.is_empty():
		push_error("Power act FX check FAILED (%d)." % _failures.size())
		quit(1)
		return
	print("Power act FX check OK.")
	quit(0)


func _spawn() -> CombatRoot:
	var cr: CombatRoot = CombatRootScene.instantiate()
	root.add_child(cr)
	if not cr.is_node_ready():
		await cr.ready
	return cr


func _symbol(cr: CombatRoot, id_name: StringName) -> SymbolDefScript:
	for r in cr.symbol_resources:
		var sym := r as SymbolDefScript
		if sym != null and sym.id == id_name:
			return sym
	return null


func _checkerboard(cr: CombatRoot) -> void:
	var a := _symbol(cr, &"sym_green_circle")
	var b := _symbol(cr, &"sym_yellow_triangle")
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			cr.grid.set_cell(Vector2i(x, y), a if (x + y) % 2 == 0 else b)


func _board(cr: CombatRoot) -> PackedStringArray:
	var out := PackedStringArray()
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			var sym: SymbolDefScript = cr.grid.get_cell(Vector2i(x, y))
			out.append("." if sym == null else String(sym.id))
	return out


func _assert_timing_budget() -> void:
	var cr := await _spawn()
	var intro := cr.power_intro_scale_in_sec + cr.power_intro_hold_sec + cr.power_intro_scale_out_sec
	var total := intro + CombatRoot.POWER_ACT_SEC
	if absf(cr.power_intro_hold_sec - 0.31) > 0.001:
		_fail("power icon hold should be 0.31s, got %s" % cr.power_intro_hold_sec)
	if absf(CombatRoot.POWER_ACT_SEC - 0.48) > 0.001:
		_fail("symbol motion should be 0.48s")
	if absf(total - 1.75) > 0.001:
		_fail("power activation should stay 1.75s, got %s" % total)
	if absf(cr.pause_after_power_sec - 0.25) > 0.001:
		_fail("empty-power pause should stay 0.25s")
	cr.queue_free()
	await process_frame


func _assert_logs_match_board(power_id: StringName, kind: StringName) -> void:
	var cr := await _spawn()
	cr.setup_new_grid(4201)
	_checkerboard(cr)
	var before := _board(cr)
	cr.powers.set_current_id(power_id)
	cr.debug_trigger_power()
	var after := _board(cr)
	var changed: Dictionary = {}
	for i in before.size():
		if before[i] != after[i]:
			var x := i % GridManagerScript.COLS
			var y := int(i / GridManagerScript.COLS)
			changed["%d,%d" % [x, y]] = true
	if changed.is_empty():
		_fail("%s changed no cells" % power_id)
	var logged: Dictionary = {}
	for raw in cr._power_fx_log:
		var event: Dictionary = raw
		if event.get("kind", &"") != kind:
			_fail("%s log kind %s, expected %s" % [power_id, event.get("kind", &""), kind])
		var cell: Vector2i = event.get("cell", Vector2i(-1, -1))
		logged["%d,%d" % [cell.x, cell.y]] = true
		if event.get("from_tex", null) == null:
			_fail("%s log is missing the old picture" % power_id)
	if logged.size() != changed.size():
		_fail("%s log has %d cells, board changed %d" % [power_id, logged.size(), changed.size()])
	for key in changed.keys():
		if not logged.has(key):
			_fail("%s did not log changed cell %s" % [power_id, key])
	if cr._power_fx_depth != 0:
		_fail("%s left the power log depth at %d" % [power_id, cr._power_fx_depth])
	cr.queue_free()
	await process_frame


func _assert_missing_log_is_safe() -> void:
	var cr := await _spawn()
	cr.setup_new_grid(4202)
	_checkerboard(cr)
	cr.powers.trigger_power_by_id(&"alcohol", {
		"grid": cr.grid,
		"rng": cr.rng,
		"wild": cr.wild_symbol,
		"potency": 1.0,
		"diag_opts": {},
	})
	var wilds := 0
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			var sym: SymbolDefScript = cr.grid.get_cell(Vector2i(x, y))
			if sym != null and sym.tier == SymbolDefScript.Tier.WILD:
				wilds += 1
	if wilds < 1:
		_fail("alcohol without a visual log should still place a wild")
	cr.queue_free()
	await process_frame


func _assert_same_seed_same_board() -> void:
	var left := await _fire(&"bloody_hand", 4301)
	var right := await _fire(&"bloody_hand", 4301)
	if left != right:
		_fail("same seed bloody hand boards diverged")
	left = await _fire(&"alcohol", 4302)
	right = await _fire(&"alcohol", 4302)
	if left != right:
		_fail("same seed alcohol boards diverged")
	left = await _fire(&"cigarette", 4303)
	right = await _fire(&"cigarette", 4303)
	if left != right:
		_fail("same seed cigarette boards diverged")


func _fire(power_id: StringName, seed_value: int) -> String:
	var cr := await _spawn()
	cr.setup_new_grid(seed_value)
	_checkerboard(cr)
	cr.powers.set_current_id(power_id)
	cr.debug_trigger_power()
	var snap := cr.grid.snapshot_ids()
	cr.queue_free()
	await process_frame
	return snap


func _assert_collapse_keeps_last_kind() -> void:
	var cr := await _spawn()
	var tex_a := _symbol(cr, &"sym_green_circle").texture
	var tex_b := _symbol(cr, &"sym_yellow_triangle").texture
	var skull := cr.wild_symbol.texture
	var log: Array = [
		{"kind": &"morph", "cell": Vector2i(1, 1), "from_tex": tex_a, "to_tex": tex_b},
		{"kind": &"eat", "cell": Vector2i(1, 1), "from_tex": tex_b, "to_tex": skull},
		{"kind": &"burn", "cell": Vector2i(0, 0), "from_tex": tex_a, "to_tex": null},
	]
	var collapsed: Array = cr._collapse_power_fx(log)
	if collapsed.size() != 2:
		_fail("two cells should stay two motions, got %d" % collapsed.size())
	var eaten: Dictionary = {}
	for raw in collapsed:
		var event: Dictionary = raw
		var cell: Vector2i = event.get("cell", Vector2i(-1, -1))
		if cell == Vector2i(1, 1):
			eaten = event
	if eaten.is_empty() or eaten.get("kind", &"") != &"eat":
		_fail("a cell hit twice should keep the last motion")
	if eaten.get("from_tex", null) != tex_a:
		_fail("a cell hit twice should start from the picture already on screen")
	cr.queue_free()
	await process_frame


func _assert_slot_motions() -> void:
	var cr := await _spawn()
	var slot := cr._get_slot(Vector2i(0, 0))
	if slot == null:
		_fail("missing symbol slot")
		cr.queue_free()
		await process_frame
		return
	slot.size = Vector2(64, 64)
	var tex_a := _symbol(cr, &"sym_green_circle").texture
	var tex_b := _symbol(cr, &"sym_yellow_triangle").texture
	var skull := cr.wild_symbol.texture
	slot.play_power_act(&"morph", tex_a, tex_b, 0.48, false)
	if slot.get_node_or_null("PowerGlow") == null:
		_fail("bloody hand should glow behind the symbol")
	var icon := slot.get_node("Icon") as TextureRect
	var mat := icon.material as ShaderMaterial
	if mat == null or not is_equal_approx(float(mat.get_shader_parameter("fx_mode")), 0.0):
		_fail("morph shader did not start")
	elif float(mat.get_shader_parameter("skip_white_hit")) > 0.5:
		_fail("white hit should play when flashing is allowed")
	slot.cancel_active_fx()
	if slot.get_node_or_null("PowerGlow") != null or icon.material != null:
		_fail("morph motion did not clean up")

	slot.play_power_act(&"eat", tex_a, skull, 0.48, false)
	var skull_node := slot.get_node_or_null("PowerSkull") as TextureRect
	if skull_node == null or skull_node.texture != skull:
		_fail("alcohol should show the wild skull behind the symbol")
	elif skull_node.get_index() > icon.get_index():
		_fail("wild skull should sit behind the symbol")
	slot.cancel_active_fx()
	if slot.get_node_or_null("PowerSkull") != null:
		_fail("eat motion did not clean up")

	slot.play_power_act(&"burn", tex_a, null, 0.48, false)
	var ash := slot.get_node_or_null("PowerAsh")
	if ash == null or ash.get_child_count() != 8:
		_fail("cigarette should crumble into 8 ash flecks")
	elif not slot.clip_contents:
		_fail("ash should stay clipped to the cell")
	slot.cancel_active_fx()
	if slot.get_node_or_null("PowerAsh") != null:
		_fail("burn motion did not clean up")

	slot.play_power_act(&"burn", tex_a, null, 0.48, true)
	if slot.get_node_or_null("PowerAsh") != null:
		_fail("reduce flashing should skip ash flecks")
	icon = slot.get_node("Icon") as TextureRect
	mat = icon.material as ShaderMaterial
	if mat == null or float(mat.get_shader_parameter("skip_white_hit")) < 0.5:
		_fail("reduce flashing should skip the white hit")
	slot.set_symbol(null)
	if icon.material != null or slot.get_node_or_null("PowerAsh") != null:
		_fail("setting the symbol should clear the motion")
	cr.queue_free()
	await process_frame


func _assert_play_clears_and_times() -> void:
	var cr := await _spawn()
	cr.enable_symbol_fx = true
	cr._dev_skip_visuals = false
	cr._slot_positions_ready = true
	var slot := cr._get_slot(Vector2i(2, 2))
	var tex_a := _symbol(cr, &"sym_green_circle").texture
	var tex_b := _symbol(cr, &"sym_yellow_triangle").texture
	var log: Array = [{
		"kind": &"morph",
		"cell": Vector2i(2, 2),
		"from_tex": tex_a,
		"to_tex": tex_b,
	}]
	var started := Time.get_ticks_msec()
	cr._play_power_act_fx(log)
	var icon := slot.get_node("Icon") as TextureRect
	if icon.material == null:
		_fail("power motion did not start on the cell")
	while icon.material != null and Time.get_ticks_msec() - started < 2000:
		await process_frame
	var elapsed := float(Time.get_ticks_msec() - started) / 1000.0
	if icon.material != null or slot.get_node_or_null("PowerGlow") != null:
		_fail("power motion was still running after the wait")
	if elapsed < 0.40 or elapsed > 0.68:
		_fail("symbol motion took %.3fs; it should be about 0.48s and not also wait the old 0.25s pause" % elapsed)

	started = Time.get_ticks_msec()
	await cr._play_power_act_fx([])
	elapsed = float(Time.get_ticks_msec() - started) / 1000.0
	if elapsed < 0.18 or elapsed > 0.40:
		_fail("a power that changes nothing took %.3fs; it should stay the 0.25s pause" % elapsed)
	cr.queue_free()
	await process_frame


func _assert_shader_compiles() -> void:
	var host := TextureRect.new()
	host.name = "PowerFxShaderHost"
	host.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	host.size = Vector2(64, 64)
	var mat := ShaderMaterial.new()
	mat.shader = PowerFxShader
	mat.set_shader_parameter("fx_mode", 0.0)
	mat.set_shader_parameter("progress", 0.35)
	mat.set_shader_parameter("skip_white_hit", 0.0)
	host.material = mat
	root.add_child(host)
	for _i in 4:
		await process_frame
	host.queue_free()
	await process_frame
