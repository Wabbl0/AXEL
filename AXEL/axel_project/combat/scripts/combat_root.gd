class_name CombatRoot
extends Node2D

enum State { IDLE, SPINNING }

@export var symbol_resources: Array[Resource] = []

@export_group("Visual pacing (async spin() only)")
## Pause at the start of a spin so the initial grid reads before anything resolves.
@export var pause_at_spin_start_sec: float = 0.85
## Pause after clusters are cleared and wilds are placed (before gravity).
@export var pause_after_cluster_resolve_sec: float = 1.6
## Pause after symbols fall and new symbols spawn.
@export var pause_after_gravity_refill_sec: float = 1.5

@onready var grid: GridManager = $GridManager
@onready var grid_ui: GridContainer = $GridUI
@onready var multiplier_label: Label = $MultiplierLabel

const SYMBOL_SLOT_SCENE := preload("res://combat/scenes/symbol.tscn")

var rng := CombatRNG.new()
var multiplier := CombatMultiplier.new()
var wild_symbol: SymbolDef
var low_symbol_pool: Array[SymbolDef] = []

var _state: State = State.IDLE
var _weights: Dictionary = {}


func _ready() -> void:
	_ensure_symbol_slots()
	_load_symbols_from_export()
	grid.grid_populated.connect(_on_grid_populated)
	grid.cells_cleared.connect(_on_cells_cleared)
	grid.symbols_fell.connect(_on_symbols_fell)
	grid.symbols_spawned.connect(_on_symbols_spawned)
	_refresh_multiplier_label()


func _load_symbols_from_export() -> void:
	low_symbol_pool.clear()
	wild_symbol = null
	for res in symbol_resources:
		var sd := res as SymbolDef
		if sd == null:
			continue
		if sd.tier == SymbolDef.Tier.WILD:
			wild_symbol = sd
		elif sd.tier == SymbolDef.Tier.LOW:
			low_symbol_pool.append(sd)
			_weights[sd.id] = sd.base_weight
	if wild_symbol == null:
		push_error("CombatRoot: assign wild SymbolDef in symbol_resources.")
	if low_symbol_pool.is_empty():
		push_error("CombatRoot: assign at least one LOW symbol in symbol_resources.")


func get_state() -> int:
	return _state as int


func get_multiplier_value() -> int:
	return multiplier.value


func setup_new_grid(seed_value: int) -> void:
	rng.seed(seed_value)
	multiplier.reset()
	_refresh_multiplier_label()
	grid.populate(rng, low_symbol_pool, _weights)
	_refresh_cells_visual()


func spin() -> void:
	if _state != State.IDLE:
		return
	_state = State.SPINNING
	multiplier.reset()
	_refresh_multiplier_label()
	await _pause_visual(pause_at_spin_start_sec)
	while true:
		var clusters: Array = ClusterDetector.find_clusters(grid.cells)
		if clusters.is_empty():
			break
		await _resolve_clusters(clusters)
		await _apply_gravity_and_refill()
	_state = State.IDLE
	_refresh_multiplier_label()


## Headless / determinism: same logic as spin() without awaiting the renderer.
func spin_sync() -> void:
	if _state != State.IDLE:
		return
	_state = State.SPINNING
	multiplier.reset()
	while true:
		var clusters: Array = ClusterDetector.find_clusters(grid.cells)
		if clusters.is_empty():
			break
		_resolve_clusters_sync(clusters)
		_apply_gravity_and_refill_sync()
	_state = State.IDLE


func serialize_spin_result() -> String:
	return "%s|%d" % [grid.snapshot_ids(), multiplier.value]


func _resolve_clusters(clusters: Array) -> void:
	_resolve_clusters_impl(clusters)
	await _pause_visual(pause_after_cluster_resolve_sec)


func _resolve_clusters_sync(clusters: Array) -> void:
	_resolve_clusters_impl(clusters)


func _resolve_clusters_impl(clusters: Array) -> void:
	var all_cleared: Array = []
	for cl in clusters:
		for p in cl["cells"]:
			all_cleared.append(p)
	grid.clear_cells_and_emit(all_cleared)
	var sorted_clusters: Array = clusters.duplicate()
	sorted_clusters.sort_custom(_compare_clusters_sort)
	for cl in sorted_clusters:
		var cells: Array = cl["cells"]
		var drop_cell := _wild_drop_cell_in_footprint(cells)
		grid.set_cell(drop_cell, wild_symbol)
		multiplier.add(1)
	_refresh_cells_visual()
	_refresh_multiplier_label()


func _compare_clusters_sort(a: Variant, b: Variant) -> bool:
	var ka: Vector2i = _cluster_sort_key((a as Dictionary)["cells"] as Array)
	var kb: Vector2i = _cluster_sort_key((b as Dictionary)["cells"] as Array)
	if ka.y != kb.y:
		return ka.y < kb.y
	return ka.x < kb.x


func _cluster_sort_key(cluster_cells: Array) -> Vector2i:
	var best := Vector2i(999, 999)
	for p in cluster_cells:
		var v := p as Vector2i
		if v.y < best.y or (v.y == best.y and v.x < best.x):
			best = v
	return best


func _wild_drop_cell_in_footprint(cluster_cells: Array) -> Vector2i:
	var ideal := ClusterDetector.centroid_cell(cluster_cells)
	for p in cluster_cells:
		var v := p as Vector2i
		if v == ideal:
			return ideal
	var best: Vector2i = cluster_cells[0] as Vector2i
	var best_dist := 999999
	for p in cluster_cells:
		var v := p as Vector2i
		var d: int = absi(v.x - ideal.x) + absi(v.y - ideal.y)
		if d < best_dist or (d == best_dist and (v.y < best.y or (v.y == best.y and v.x < best.x))):
			best_dist = d
			best = v
	return best


func _apply_gravity_and_refill() -> void:
	grid.apply_gravity()
	grid.refill(rng, low_symbol_pool, _weights)
	_refresh_cells_visual()
	await _pause_visual(pause_after_gravity_refill_sec)


func _apply_gravity_and_refill_sync() -> void:
	grid.apply_gravity()
	grid.refill(rng, low_symbol_pool, _weights)
	_refresh_cells_visual()


func _pause_visual(seconds: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	if seconds <= 0.0:
		await tree.process_frame
		return
	await tree.create_timer(seconds).timeout


func _on_grid_populated() -> void:
	_refresh_cells_visual()


func _on_cells_cleared(_coords: Array) -> void:
	pass


func _on_symbols_fell(_moves: Array) -> void:
	pass


func _on_symbols_spawned(_spawns: Array) -> void:
	pass


func _refresh_multiplier_label() -> void:
	if multiplier_label:
		multiplier_label.text = "Multiplier: %d×" % multiplier.value


func _ensure_symbol_slots() -> void:
	if grid_ui.get_child_count() >= 25:
		return
	for i in 25:
		grid_ui.add_child(SYMBOL_SLOT_SCENE.instantiate())


func _refresh_cells_visual() -> void:
	var idx := 0
	for child in grid_ui.get_children():
		var row: int = int(idx / float(GridManager.COLS))
		var col: int = idx % GridManager.COLS
		var sym: SymbolDef = grid.cells[row][col]
		if child.has_method("set_symbol"):
			child.call("set_symbol", sym)
		else:
			var tex_rect := child as TextureRect
			if tex_rect != null:
				tex_rect.texture = sym.texture if sym != null and sym.texture != null else null
		idx += 1
