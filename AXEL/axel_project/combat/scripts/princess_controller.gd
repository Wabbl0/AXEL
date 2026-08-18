class_name PrincessController
extends RefCounted

const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")
const GridManagerScript := preload("res://combat/scripts/grid_manager.gd")
const CombatRNGScript := preload("res://combat/scripts/rng.gd")
const LineDetectorScript := preload("res://combat/scripts/line_detector.gd")

enum Id { LOVE, STAR, STORM }

const ID_TO_NAME := {
	Id.LOVE: &"love",
	Id.STAR: &"star",
	Id.STORM: &"storm",
}
const NAME_TO_ID := {
	&"love": Id.LOVE,
	&"star": Id.STAR,
	&"storm": Id.STORM,
}

var _order: Array[int] = [Id.LOVE, Id.STAR, Id.STORM]
var _index: int = 0


func current_id() -> StringName:
	return ID_TO_NAME.get(_order[_index], &"love")


func next_id() -> StringName:
	var next_index := (_index + 1) % _order.size()
	return ID_TO_NAME.get(_order[next_index], &"star")


func set_current_id(id_name: StringName) -> void:
	var target: int = NAME_TO_ID.get(id_name, _order[_index])
	for i in _order.size():
		if _order[i] == target:
			_index = i
			return


func advance_rotation() -> void:
	_index = (_index + 1) % _order.size()


func randomize_start(rng: CombatRNGScript) -> void:
	if rng == null:
		_index = 0
		return
	_index = rng.randi_range(0, _order.size() - 1)


func trigger_current_power(ctx: Dictionary) -> void:
	trigger_power_by_id(current_id(), ctx)


func trigger_power_by_id(princess_id: StringName, ctx: Dictionary) -> void:
	match princess_id:
		&"love":
			_love_transform(ctx)
		&"star":
			_star_add_wilds(ctx)
		&"storm":
			_storm_remove_lowpays(ctx)


func snapshot_state() -> Dictionary:
	return {
		"index": _index,
		"current": current_id(),
		"next": next_id(),
	}


func restore_state(state: Dictionary) -> void:
	if state.has("index"):
		var idx: int = int(state["index"])
		if idx >= 0 and idx < _order.size():
			_index = idx
			return
	if state.has("current"):
		set_current_id(state["current"] as StringName)


func _love_transform(ctx: Dictionary) -> void:
	var grid: GridManagerScript = ctx.get("grid")
	var rng: CombatRNGScript = ctx.get("rng")
	var low_pool: Array = ctx.get("low_pool", [])
	var premium_pool: Array = ctx.get("premium_pool", [])
	var potency: float = float(ctx.get("potency", 1.0))
	if grid == null or rng == null:
		return
	var present_counts: Dictionary = {}
	for r in GridManagerScript.ROWS:
		for c in GridManagerScript.COLS:
			var sym: SymbolDefScript = grid.get_cell(Vector2i(c, r))
			if sym == null:
				continue
			if sym.tier == SymbolDefScript.Tier.WILD or sym.tier == SymbolDefScript.Tier.HAZARD:
				continue
			var sid: StringName = sym.id
			present_counts[sid] = int(present_counts.get(sid, 0)) + 1
	if present_counts.is_empty():
		return
	var source_ids: Array = present_counts.keys()
	var source_id: StringName = source_ids[rng.randi_range(0, source_ids.size() - 1)]
	var replacement_pool: Array[SymbolDefScript] = []
	for s in low_pool:
		var sym := s as SymbolDefScript
		if sym != null and sym.id != source_id:
			replacement_pool.append(sym)
	for s in premium_pool:
		var sym := s as SymbolDefScript
		if sym != null and sym.id != source_id:
			replacement_pool.append(sym)
	if replacement_pool.is_empty():
		return
	var repl_index := rng.randi_range(0, replacement_pool.size() - 1)
	var target: SymbolDefScript = replacement_pool[repl_index]
	for y in GridManagerScript.ROWS:
		for x in GridManagerScript.COLS:
			var p := Vector2i(x, y)
			var sym: SymbolDefScript = grid.get_cell(p)
			if sym != null and sym.id == source_id:
				if potency >= 1.0 or rng.randf() <= potency:
					grid.set_cell(p, target)
	var extra_transform: float = float(ctx.get("extra_transform_chance", 0.0))
	if extra_transform > 0.0 and rng.randf() <= extra_transform:
		var candidates: Array[Vector2i] = []
		for y2 in GridManagerScript.ROWS:
			for x2 in GridManagerScript.COLS:
				var p2 := Vector2i(x2, y2)
				var s2: SymbolDefScript = grid.get_cell(p2)
				if s2 != null and s2.id != target.id and s2.tier != SymbolDefScript.Tier.WILD:
					candidates.append(p2)
		if not candidates.is_empty():
			grid.set_cell(candidates[rng.randi_range(0, candidates.size() - 1)], target)


func _star_add_wilds(ctx: Dictionary) -> void:
	var grid: GridManagerScript = ctx.get("grid")
	var rng: CombatRNGScript = ctx.get("rng")
	var wild: SymbolDefScript = ctx.get("wild")
	var potency: float = float(ctx.get("potency", 1.0))
	var diag_opts: Dictionary = ctx.get("diag_opts", {})
	if grid == null or rng == null or wild == null:
		return
	var placements := rng.randi_range(1, 2)
	if potency < 1.0:
		placements = maxi(1, int(round(float(placements) * potency)))
	if float(ctx.get("extra_wild_chance", 0.0)) > 0.0 and rng.randf() <= float(ctx.get("extra_wild_chance", 0.0)):
		placements += 1
	var blocked: Dictionary = {}
	for _i in placements:
		var best_score := -1
		var best_cell := Vector2i(-1, -1)
		for r in GridManagerScript.ROWS:
			for c in GridManagerScript.COLS:
				var p := Vector2i(c, r)
				if blocked.has(p):
					continue
				var score: int = LineDetectorScript.score_wild_at(grid.cells, p, diag_opts)
				if score > best_score:
					best_score = score
					best_cell = p
		if best_cell.x < 0:
			return
		grid.set_cell(best_cell, wild)
		blocked[best_cell] = true


func _storm_remove_lowpays(ctx: Dictionary) -> void:
	var grid: GridManagerScript = ctx.get("grid")
	var rng: CombatRNGScript = ctx.get("rng")
	if grid == null:
		return
	var potency: float = float(ctx.get("potency", 1.0))
	var counts := {}
	var weights := {}
	for r in GridManagerScript.ROWS:
		for c in GridManagerScript.COLS:
			var sym: SymbolDefScript = grid.cells[r][c]
			if sym == null or sym.tier != SymbolDefScript.Tier.LOW:
				continue
			var id: StringName = sym.id
			counts[id] = int(counts.get(id, 0)) + 1
			weights[id] = sym.base_weight
	var ids: Array = counts.keys()
	if ids.is_empty():
		return
	ids.sort_custom(_sort_lowpay_ids.bind(counts, weights))
	var remove_ids: Dictionary = {}
	remove_ids[ids[0]] = true
	var sets_to_remove := 2
	if potency < 0.5:
		sets_to_remove = 1
	if ids.size() > 1 and sets_to_remove >= 2:
		remove_ids[ids[1]] = true
	if rng != null and float(ctx.get("extra_set_chance", 0.0)) > 0.0 and rng.randf() <= float(ctx.get("extra_set_chance", 0.0)):
		if ids.size() > remove_ids.size():
			for cand in ids:
				if not remove_ids.has(cand):
					remove_ids[cand] = true
					break
	for r in GridManagerScript.ROWS:
		for c in GridManagerScript.COLS:
			var p := Vector2i(c, r)
			var sym: SymbolDefScript = grid.get_cell(p)
			if sym == null:
				continue
			if remove_ids.has(sym.id):
				grid.set_cell(p, null)


func _sort_lowpay_ids(a: Variant, b: Variant, counts: Dictionary, weights: Dictionary) -> bool:
	var id_a: StringName = a
	var id_b: StringName = b
	var count_a: int = int(counts.get(id_a, 0))
	var count_b: int = int(counts.get(id_b, 0))
	if count_a != count_b:
		return count_a < count_b
	var weight_a: float = float(weights.get(id_a, 1.0))
	var weight_b: float = float(weights.get(id_b, 1.0))
	if not is_equal_approx(weight_a, weight_b):
		return weight_a < weight_b
	return String(id_a) < String(id_b)
