class_name FreeSpinsState
extends RefCounted

const BASE_SPINS := {
	&"love": 4,
	&"star": 5,
	&"storm": 8,
}

const BONUS_SPINS := {
	&"love": 4,
	&"star": 3,
	&"storm": 2,
}

var active: bool = false
var chosen_princess: StringName = &""
var spins_remaining: int = 0
var spins_awarded_total: int = 0
var multiplier_cap: int = 100
var total_spin_cap: int = 100
var powers_used_once: Dictionary = {}
const AGENT_DEBUG_LOG_PATH := "res://../../logs/debug/debug-c9d495.log"
const AGENT_DEBUG_SESSION_ID := "c9d495"


func reset() -> void:
	active = false
	chosen_princess = &""
	spins_remaining = 0
	spins_awarded_total = 0
	powers_used_once = {}


func start_with_princess(princess_id: StringName) -> void:
	var base := int(BASE_SPINS.get(princess_id, 4))
	# #region agent log
	_agent_debug_log(
		"pre-fix",
		"H6",
		"free_spins.gd:start_with_princess",
		"start_with_princess called",
		{
			"princess_id": String(princess_id),
			"base_spins": base,
			"active_before": active,
			"spins_remaining_before": spins_remaining,
		}
	)
	# #endregion
	active = true
	chosen_princess = princess_id
	spins_remaining = base
	spins_awarded_total = base
	powers_used_once = {
		&"love": false,
		&"star": false,
		&"storm": false,
	}


func consume_spin() -> void:
	# #region agent log
	_agent_debug_log(
		"pre-fix",
		"H8",
		"free_spins.gd:consume_spin",
		"consume_spin entry",
		{
			"active_before": active,
			"spins_remaining_before": spins_remaining,
			"all_powers_used_once_before": all_powers_used_once(),
		}
	)
	# #endregion
	if spins_remaining > 0:
		spins_remaining -= 1
	if spins_remaining <= 0:
		active = false
	# #region agent log
	_agent_debug_log(
		"pre-fix",
		"H8",
		"free_spins.gd:consume_spin",
		"consume_spin exit",
		{
			"active_after": active,
			"spins_remaining_after": spins_remaining,
			"all_powers_used_once_after": all_powers_used_once(),
		}
	)
	# #endregion


func award_from_meter() -> void:
	if not active:
		return
	var bonus := int(BONUS_SPINS.get(chosen_princess, 0))
	if bonus <= 0:
		return
	var remaining_room := maxi(0, total_spin_cap - spins_awarded_total)
	var grant := mini(bonus, remaining_room)
	if grant <= 0:
		return
	spins_remaining += grant
	spins_awarded_total += grant


func mark_power_used_once(princess_id: StringName) -> void:
	if not powers_used_once.has(princess_id):
		return
	powers_used_once[princess_id] = true


func has_used_power(princess_id: StringName) -> bool:
	return bool(powers_used_once.get(princess_id, false))


func all_powers_used_once() -> bool:
	return has_used_power(&"love") and has_used_power(&"star") and has_used_power(&"storm")


func ensure_end_guard_spin() -> void:
	if active and spins_remaining <= 0:
		spins_remaining = 1


func _agent_debug_log(run_id: String, hypothesis_id: String, location: String, message: String, data: Dictionary) -> void:
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(AGENT_DEBUG_LOG_PATH) else FileAccess.WRITE_READ
	var file := FileAccess.open(AGENT_DEBUG_LOG_PATH, mode)
	if file == null:
		return
	file.seek_end()
	var payload := {
		"sessionId": AGENT_DEBUG_SESSION_ID,
		"runId": run_id,
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_unix_time_from_system() * 1000,
	}
	file.store_line(JSON.stringify(payload))
	file.close()
