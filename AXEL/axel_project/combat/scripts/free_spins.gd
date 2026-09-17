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

func reset() -> void:
	active = false
	chosen_princess = &""
	spins_remaining = 0
	spins_awarded_total = 0
	powers_used_once = {}

func start_with_princess(princess_id: StringName, extra_spins: int = 0) -> void:
	var base := int(BASE_SPINS.get(princess_id, 4)) + maxi(extra_spins, 0)
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
	if spins_remaining > 0:
		spins_remaining -= 1
	if spins_remaining <= 0:
		active = false

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
