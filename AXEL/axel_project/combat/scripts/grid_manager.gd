class_name GridManager
extends Node

const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")
const CombatRNGScript := preload("res://combat/scripts/rng.gd")

const COLS := 5
const ROWS := 5

## cells[row][col] : SymbolDef or null
var cells: Array = []
## flags[row][col] : Dictionary (reserved for hazards / locks later)
var flags: Array = []

signal grid_populated
signal cells_cleared(coords: Array)
signal symbols_fell(moves: Array)
signal symbols_spawned(spawns: Array)


func _ready() -> void:
	_ensure_arrays()


func _ensure_arrays() -> void:
	cells.clear()
	flags.clear()
	for r in ROWS:
		var row: Array = []
		var frow: Array = []
		for c in COLS:
			row.append(null)
			frow.append({})
		cells.append(row)
		flags.append(frow)


func get_cell(p: Vector2i) -> SymbolDefScript:
	if not _in_bounds(p):
		return null
	return cells[p.y][p.x]


func set_cell(p: Vector2i, sym: SymbolDefScript) -> void:
	if not _in_bounds(p):
		return
	cells[p.y][p.x] = sym


func _in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < COLS and p.y >= 0 and p.y < ROWS


func populate(rng: CombatRNGScript, pool: Array, weights: Dictionary) -> void:
	_ensure_arrays()
	for r in ROWS:
		for c in COLS:
			cells[r][c] = _draw_symbol(rng, pool, weights)
	grid_populated.emit()


func _draw_symbol(rng: CombatRNGScript, pool: Array, weights: Dictionary) -> SymbolDefScript:
	if pool.is_empty():
		return null
	var total := 0.0
	for s in pool:
		var sym := s as SymbolDefScript
		if sym == null:
			continue
		total += _weight_for(sym, weights)
	if total <= 0.0:
		return pool[0] as SymbolDefScript
	var pick := rng.randf() * total
	var acc := 0.0
	for s in pool:
		var sym := s as SymbolDefScript
		if sym == null:
			continue
		acc += _weight_for(sym, weights)
		if pick <= acc:
			return sym
	return pool.back() as SymbolDefScript


func _weight_for(sym: SymbolDefScript, weights: Dictionary) -> float:
	if weights.has(sym.id):
		return float(weights[sym.id])
	return sym.base_weight


## Clears listed coords to null. Does not emit.
func clear_cells(coords: Array) -> void:
	for p in coords:
		var v := p as Vector2i
		set_cell(v, null)


func clear_cells_and_emit(coords: Array) -> void:
	clear_cells(coords)
	cells_cleared.emit(coords)


## Returns moves: Array of { "from": Vector2i, "to": Vector2i }
func apply_gravity() -> Array:
	var moves: Array = []
	for c in COLS:
		var write_row := ROWS - 1
		for read_row in range(ROWS - 1, -1, -1):
			var sym: SymbolDefScript = cells[read_row][c]
			if sym == null:
				continue
			if read_row != write_row:
				cells[read_row][c] = null
				cells[write_row][c] = sym
				moves.append({"from": Vector2i(c, read_row), "to": Vector2i(c, write_row)})
			write_row -= 1
	if not moves.is_empty():
		symbols_fell.emit(moves)
	return moves


## Fills null cells from top with weighted random from pool.
func refill(rng: CombatRNGScript, pool: Array, weights: Dictionary) -> void:
	var spawns: Array = []
	for c in COLS:
		for r in ROWS:
			if cells[r][c] != null:
				continue
			var sym := _draw_symbol(rng, pool, weights)
			cells[r][c] = sym
			spawns.append({"coord": Vector2i(c, r), "sym": sym})
	if not spawns.is_empty():
		symbols_spawned.emit(spawns)


## Nearest empty cell (Manhattan, then lower y, then lower x). Returns (-1,-1) if none.
func nearest_empty(from: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 999
	for r in ROWS:
		for c in COLS:
			if cells[r][c] != null:
				continue
			var p := Vector2i(c, r)
			var d: int = absi(p.x - from.x) + absi(p.y - from.y)
			if d < best_d:
				best_d = d
				best = p
				continue
			if d == best_d:
				if best.x < 0 or p.y < best.y or (p.y == best.y and p.x < best.x):
					best = p
	return best


func snapshot_ids() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for r in ROWS:
		for c in COLS:
			var s: SymbolDefScript = cells[r][c]
			if s == null:
				parts.append(".")
			else:
				parts.append(String(s.id))
	return "|".join(parts)
