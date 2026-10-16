class_name FeedbackSpinLog
extends RefCounted

const MAX_SPINS := 300
const MAX_FIGHTS := 60

var spins: Array = []
var fights: Array = []
var _root_ref: WeakRef = null
var _fight: Dictionary = {}
var _pending: Dictionary = {}


func begin_fight(root: Node, info: Dictionary) -> void:
	_close_open_fight("left")
	_root_ref = weakref(root)
	_pending = {}
	_fight = info.duplicate(true)
	_fight["balance_start"] = int(_call(root, "get_bankroll", 0.0))
	_fight["result"] = ""
	_fight["spins"] = 0
	_fight["free_spins"] = 0
	_fight["vice_rounds"] = 0
	_fight["best_payout"] = 0
	_connect(root, "spin_started", _on_spin_started)
	_connect(root, "spin_finished", _on_spin_finished)
	_connect(root, "vice_round_cleared", _on_vice_cleared)
	_connect(root, "encounter_finished", _on_finished)


func clear() -> void:
	spins.clear()
	fights.clear()
	_fight = {}
	_pending = {}
	_root_ref = null


func snapshot() -> Dictionary:
	var fight_rows := fights.duplicate(true)
	if not _fight.is_empty():
		var open := _fight.duplicate(true)
		open["result"] = "in_progress"
		fight_rows.append(open)
	return {"fights": fight_rows, "spins": spins.duplicate(true)}


func _root() -> Node:
	if _root_ref == null:
		return null
	return _root_ref.get_ref() as Node


func _connect(root: Node, signal_name: String, cb: Callable) -> void:
	if root.has_signal(signal_name) and not root.is_connected(signal_name, cb):
		root.connect(signal_name, cb)


func _call(root: Node, method: String, fallback: Variant) -> Variant:
	if root != null and root.has_method(method):
		return root.call(method)
	return fallback


func _on_spin_started(seed_value: int) -> void:
	var root := _root()
	if root == null or _fight.is_empty():
		return
	var free: Vector2i = _call(root, "get_free_spin_counter", Vector2i.ZERO)
	var held := bool(_call(root, "is_bonus_skull_held", false))
	_pending = {
		"seed": seed_value,
		"bet": int(_call(root, "get_current_bet", 0.0)),
		"balance_before": int(_call(root, "get_bankroll", 0.0)),
		"free_spin": free.x > 0,
		"vice": held and free.x <= 0,
	}


func _on_spin_finished() -> void:
	var root := _root()
	if root == null or _pending.is_empty() or _fight.is_empty():
		return
	var summary: Dictionary = _call(root, "get_last_spin_summary", {})
	var row := _pending.duplicate()
	_pending = {}
	row["fight"] = int(_fight.get("fight", 0))
	row["fight_seed"] = int(_fight.get("seed", 0))
	row["spin"] = int(_call(root, "get_spins_used", 0))
	row["payout"] = int(summary.get("payout", 0))
	row["line_payout"] = int(summary.get("line_payout", 0))
	row["cascades"] = int(summary.get("cascade_drops", 0))
	row["wilds"] = int(summary.get("wilds_placed", 0))
	row["power"] = bool(summary.get("power_triggered", false))
	row["grid_cleared"] = bool(summary.get("grid_cleared", false))
	row["balance_after"] = int(_call(root, "get_bankroll", 0.0))
	spins.append(row)
	while spins.size() > MAX_SPINS:
		spins.pop_front()
	_fight["spins"] = int(_fight["spins"]) + 1
	if bool(row["free_spin"]):
		_fight["free_spins"] = int(_fight["free_spins"]) + 1
	_fight["best_payout"] = maxi(int(_fight["best_payout"]), int(row["payout"]))


func _on_vice_cleared() -> void:
	if not _fight.is_empty():
		_fight["vice_rounds"] = int(_fight["vice_rounds"]) + 1


func _on_finished(success: bool) -> void:
	_close_open_fight("win" if success else "loss")


func _close_open_fight(result: String) -> void:
	if _fight.is_empty():
		return
	var root := _root()
	_fight["result"] = result
	_fight["spins_used"] = int(_call(root, "get_spins_used", 0))
	_fight["bets_used"] = int(_call(root, "get_bets_used", 0))
	_fight["balance_end"] = int(_call(root, "get_bankroll", 0.0))
	fights.append(_fight)
	while fights.size() > MAX_FIGHTS:
		fights.pop_front()
	_fight = {}
	_pending = {}
