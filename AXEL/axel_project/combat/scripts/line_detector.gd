class_name LineDetector
extends RefCounted

const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")
const ROWS := 5
const COLS := 5

static func find_lines(cells: Array) -> Array:
	var lines: Array = []
	for row in ROWS:
		_scan_run(cells, lines, Vector2i(0, row), Vector2i(1, 0), COLS)
	for col in COLS:
		_scan_run(cells, lines, Vector2i(col, 0), Vector2i(0, 1), ROWS)
	return lines

static func score_wild_at(cells: Array, at: Vector2i) -> int:
	if at.x < 0 or at.x >= COLS or at.y < 0 or at.y >= ROWS:
		return -1
	var best := 0
	for row in ROWS:
		best = maxi(best, _score_axis_with_wild(cells, at, Vector2i(0, row), Vector2i(1, 0), COLS))
	for col in COLS:
		best = maxi(best, _score_axis_with_wild(cells, at, Vector2i(col, 0), Vector2i(0, 1), ROWS))
	return best

static func _scan_run(cells: Array, out_lines: Array, start: Vector2i, delta: Vector2i, length: int) -> void:
	var axis_positions: Array[Vector2i] = []
	var axis_symbols: Array = []
	var symbol_ids: Dictionary = {}
	for i in length:
		var p := start + (delta * i)
		var sym: SymbolDefScript = cells[p.y][p.x]
		axis_positions.append(p)
		axis_symbols.append(sym)
		if sym != null and sym.tier != SymbolDefScript.Tier.HAZARD and sym.tier != SymbolDefScript.Tier.WILD:
			symbol_ids[sym.id] = true

	var emitted_keys: Dictionary = {}
	for sid in symbol_ids.keys():
		var run_cells: Array[Vector2i] = []
		for i in length:
			var sym: SymbolDefScript = axis_symbols[i]
			var can_match := false
			if sym != null and sym.tier != SymbolDefScript.Tier.HAZARD:
				can_match = sym.tier == SymbolDefScript.Tier.WILD or sym.id == sid
			if can_match:
				run_cells.append(axis_positions[i])
				continue
			_emit_run_for_symbol(run_cells, sid, out_lines, delta, emitted_keys, cells)
			run_cells.clear()
		_emit_run_for_symbol(run_cells, sid, out_lines, delta, emitted_keys, cells)

static func _emit_run(run_cells: Array[Vector2i], run_symbol_id: StringName, out_lines: Array, delta: Vector2i) -> void:
	if run_cells.size() < 3:
		return
	var final_symbol := run_symbol_id
	if final_symbol == &"__wild__":
		final_symbol = &"wild"
	out_lines.append({
		"symbol_id": final_symbol,
		"cells": run_cells.duplicate(),
		"length": run_cells.size(),
		"axis": "h" if delta.x != 0 else "v",
	})

static func _emit_run_for_symbol(run_cells: Array[Vector2i], sid: StringName, out_lines: Array, delta: Vector2i, emitted_keys: Dictionary, cells: Array) -> void:
	if run_cells.size() < 3:
		return
	var has_base_symbol := false
	for p in run_cells:
		var sym: SymbolDefScript = cells[p.y][p.x]
		if sym != null and sym.tier != SymbolDefScript.Tier.WILD and sym.id == sid:
			has_base_symbol = true
			break
	if not has_base_symbol:
		return
	var axis := "h" if delta.x != 0 else "v"
	var coords_key := ""
	for idx in run_cells.size():
		var c: Vector2i = run_cells[idx]
		if idx > 0:
			coords_key += ","
		coords_key += "%d:%d" % [c.x, c.y]
	var key := "%s|%s|%s" % [axis, String(sid), coords_key]
	if emitted_keys.has(key):
		return
	emitted_keys[key] = true
	_emit_run(run_cells, sid, out_lines, delta)

static func _score_axis_with_wild(cells: Array, at: Vector2i, start: Vector2i, delta: Vector2i, length: int) -> int:
	var best := 0
	for i in length:
		var pos := start + (delta * i)
		var target_sym: SymbolDefScript = cells[pos.y][pos.x]
		if target_sym == null or target_sym.tier == SymbolDefScript.Tier.HAZARD:
			continue
		if target_sym.tier == SymbolDefScript.Tier.WILD:
			continue
		var sid: StringName = target_sym.id
		var left := i
		while left > 0 and _matches_id(cells, at, start + (delta * (left - 1)), sid):
			left -= 1
		var right := i
		while right < length - 1 and _matches_id(cells, at, start + (delta * (right + 1)), sid):
			right += 1
		var run_len := right - left + 1
		best = maxi(best, run_len)
	return best

static func _matches_id(cells: Array, forced_wild: Vector2i, pos: Vector2i, sid: StringName) -> bool:
	if pos == forced_wild:
		return true
	var sym: SymbolDefScript = cells[pos.y][pos.x]
	if sym == null or sym.tier == SymbolDefScript.Tier.HAZARD:
		return false
	return sym.tier == SymbolDefScript.Tier.WILD or sym.id == sid

static func _coords_to_strings(coords: Array[Vector2i]) -> Array:
	var out: Array = []
	for p in coords:
		out.append("%d:%d" % [p.x, p.y])
	return out

