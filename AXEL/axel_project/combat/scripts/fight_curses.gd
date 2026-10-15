extends RefCounted

const CURSE_DIR := "res://combat/data/curses/"
const ALL_IDS: Array[StringName] = [
	&"blind", &"no_vice", &"sealed", &"double_goal", &"item_jam",
	&"heavy_meter", &"short_fuse", &"thin_wallet", &"ash",
]

var _order: Array[StringName] = []
var _params: Dictionary = {}
var _defs: Dictionary = {}


static func load_def(curse_id: StringName) -> Resource:
	var path := CURSE_DIR + String(curse_id) + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path)


func set_list(list: Array) -> void:
	_order.clear()
	_params.clear()
	_defs.clear()
	for entry in list:
		var curse_id: StringName = &""
		var overrides: Dictionary = {}
		if entry is Dictionary:
			curse_id = StringName(str(entry.get("id", "")))
			var p = entry.get("params", {})
			if p is Dictionary:
				overrides = p
		else:
			curse_id = StringName(str(entry))
		if curse_id == &"" or _params.has(curse_id):
			continue
		var def := load_def(curse_id)
		if def == null:
			push_warning("FightCurses: unknown curse %s." % String(curse_id))
			continue
		_order.append(curse_id)
		_defs[curse_id] = def
		_params[curse_id] = def.call("merged_params", overrides)


func get_list() -> Array:
	var out: Array = []
	for curse_id in _order:
		out.append({"id": curse_id, "params": (_params[curse_id] as Dictionary).duplicate(true)})
	return out


func ids() -> Array[StringName]:
	return _order.duplicate()


func is_empty() -> bool:
	return _order.is_empty()


func has(curse_id: StringName) -> bool:
	return _params.has(curse_id)


func param(curse_id: StringName, key: String, fallback: Variant) -> Variant:
	var p: Dictionary = _params.get(curse_id, {})
	return p.get(key, fallback)


func display_name(curse_id: StringName) -> String:
	var def: Resource = _defs.get(curse_id, null)
	return str(def.get("name")) if def != null else String(curse_id)


func describe(curse_id: StringName, live: Dictionary = {}) -> String:
	var def: Resource = _defs.get(curse_id, null)
	if def == null:
		return ""
	var p: Dictionary = (_params.get(curse_id, {}) as Dictionary).duplicate()
	for key in live.keys():
		p[key] = live[key]
	return str(def.call("describe", p))


func goal_multiplier() -> float:
	if not has(&"double_goal"):
		return 1.0
	return maxf(float(param(&"double_goal", "mult", 2.0)), 0.0)


func min_bet() -> float:
	if not has(&"thin_wallet"):
		return 0.0
	return float(param(&"thin_wallet", "min_bet", 200))


func extra_meter_sections() -> int:
	if not has(&"heavy_meter"):
		return 0
	return maxi(int(param(&"heavy_meter", "extra_sections", 1)), 0)


func low_pay_multiplier() -> float:
	if not has(&"ash"):
		return 1.0
	return clampf(float(param(&"ash", "low_pay_mult", 0.75)), 0.0, 1.0)


func spin_cap() -> int:
	if not has(&"short_fuse"):
		return 0
	return maxi(int(param(&"short_fuse", "spins", 8)), 1)


func blocks_vice() -> bool:
	return has(&"no_vice")


func is_blind() -> bool:
	return has(&"blind")


func jam_count() -> int:
	if not has(&"item_jam"):
		return 0
	return maxi(int(param(&"item_jam", "count", 1)), 0)


func sealed_range() -> Vector2i:
	if not has(&"sealed"):
		return Vector2i.ZERO
	var lo := maxi(int(param(&"sealed", "min", 1)), 0)
	var hi := maxi(int(param(&"sealed", "max", 2)), lo)
	return Vector2i(lo, hi)
