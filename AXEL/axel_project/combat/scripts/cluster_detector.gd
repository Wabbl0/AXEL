class_name ClusterDetector
extends RefCounted

## DESIGN: Wild (tier WILD) matches the anchor symbol_id during flood fill.
## Clusters are 4-connected components of cells where every non-wild symbol has
## the same id as the anchor, and WILD cells may connect matching symbols.
## We never start a flood from a wild-only cell (no anchor id).
##
## Disjoint components: each cell appears in at most one winning cluster per pass.
## Only valid expansion targets are enqueued (wild or matching id) to avoid
## infinite stacks from wilds pushing rejected neighbors.
##
## Centroid: integer division on sum of coords (non-negative grid → trunc toward 0
## equals floor); deterministic for Phase 1.

const ROWS := 5 ## Must match GridManager.ROWS
const COLS := 5 ## Must match GridManager.COLS
const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")

static var _DIRS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]


static func find_clusters(cells: Array) -> Array:
	var clusters: Array = []
	var visited: Dictionary = {}
	for r in ROWS:
		for c in COLS:
			var p := Vector2i(c, r)
			if visited.has(p):
				continue
			var sym: SymbolDefScript = cells[r][c]
			if sym == null:
				visited[p] = true
				continue
			if sym.tier == SymbolDefScript.Tier.HAZARD:
				visited[p] = true
				continue
			if sym.tier == SymbolDefScript.Tier.WILD:
				continue
			var anchor_id: StringName = sym.id
			var component: Array = _flood_fill(cells, visited, p, anchor_id)
			if component.size() >= 3:
				clusters.append({"symbol_id": anchor_id, "cells": component})
	for r in ROWS:
		for c in COLS:
			var p2 := Vector2i(c, r)
			if visited.has(p2):
				continue
			var wsym: SymbolDefScript = cells[r][c]
			if wsym != null and wsym.tier == SymbolDefScript.Tier.WILD:
				visited[p2] = true
	return clusters


static func _flood_fill(cells: Array, visited: Dictionary, start: Vector2i, anchor_id: StringName) -> Array:
	var stack: Array[Vector2i] = [start]
	var queued: Dictionary = {start: true}
	var out: Array = []
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if visited.has(p):
			continue
		if p.x < 0 or p.x >= COLS or p.y < 0 or p.y >= ROWS:
			continue
		var sym: SymbolDefScript = cells[p.y][p.x]
		if sym == null or sym.tier == SymbolDefScript.Tier.HAZARD:
			continue
		if sym.tier == SymbolDefScript.Tier.WILD:
			visited[p] = true
			out.append(p)
			_try_push_neighbors(cells, visited, queued, stack, p, anchor_id)
			continue
		if sym.id != anchor_id:
			continue
		visited[p] = true
		out.append(p)
		_try_push_neighbors(cells, visited, queued, stack, p, anchor_id)
	return out


static func _try_push_neighbors(
	cells: Array,
	visited: Dictionary,
	queued: Dictionary,
	stack: Array[Vector2i],
	p: Vector2i,
	anchor_id: StringName
) -> void:
	for dir in _DIRS:
		var np := p + dir
		if visited.has(np) or queued.has(np):
			continue
		if np.x < 0 or np.x >= COLS or np.y < 0 or np.y >= ROWS:
			continue
		var ns: SymbolDefScript = cells[np.y][np.x]
		if ns == null or ns.tier == SymbolDefScript.Tier.HAZARD:
			continue
		if ns.tier == SymbolDefScript.Tier.WILD or ns.id == anchor_id:
			queued[np] = true
			stack.append(np)


static func centroid_cell(cluster_cells: Array) -> Vector2i:
	var sx := 0
	var sy := 0
	for p in cluster_cells:
		var v := p as Vector2i
		sx += v.x
		sy += v.y
	var n: int = cluster_cells.size()
	if n == 0:
		return Vector2i.ZERO
	return Vector2i(int(floor(float(sx) / n)), int(floor(float(sy) / n)))
