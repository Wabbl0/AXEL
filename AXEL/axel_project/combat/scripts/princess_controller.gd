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
	match current_id():
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
				grid.set_cell(p, target)


func _star_add_wilds(ctx: Dictionary) -> void:
	var grid: GridManagerScript = ctx.get("grid")
	var rng: CombatRNGScript = ctx.get("rng")
	var wild: SymbolDefScript = ctx.get("wild")
	if grid == null or rng == null or wild == null:
		return
	var placements := rng.randi_range(1, 2)
	var blocked: Dictionary = {}
	for _i in placements:
		var best_score := -1
		var best_cell := Vector2i(-1, -1)
		for r in GridManagerScript.ROWS:
			for c in GridManagerScript.COLS:
				var p := Vector2i(c, r)
				if blocked.has(p):
					continue
				var score: int = LineDetectorScript.score_wild_at(grid.cells, p)
				if score > best_score:
					best_score = score
					best_cell = p
		if best_cell.x < 0:
			return
		grid.set_cell(best_cell, wild)
		blocked[best_cell] = true


func _storm_remove_lowpays(ctx: Dictionary) -> void:
	var grid: GridManagerScript = ctx.get("grid")
	if grid == null:
		return
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
	if ids.size() > 1:
		remove_ids[ids[1]] = true
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
