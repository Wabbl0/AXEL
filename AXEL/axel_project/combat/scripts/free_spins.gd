class_name FreeSpinsState
extends RefCounted

const BASE_SPINS := {
	&"bloody_hand": 4,
	&"alcohol": 5,
	&"cigarette": 8,
}

const BONUS_SPINS := {
	&"bloody_hand": 4,
	&"alcohol": 3,
	&"cigarette": 2,
}

var active: bool = false
var chosen_power: StringName = &""
var spins_remaining: int = 0
var spins_awarded_total: int = 0
var multiplier_cap: int = 100
var total_spin_cap: int = 100
var powers_used_once: Dictionary = {}

func reset() -> void:
	active = false
	chosen_power = &""
	spins_remaining = 0
	spins_awarded_total = 0
	powers_used_once = {}

func start_with_power(power_id: StringName, extra_spins: int = 0) -> void:
	var base := int(BASE_SPINS.get(power_id, 4)) + maxi(extra_spins, 0)
	active = true
	chosen_power = power_id
	spins_remaining = base
	spins_awarded_total = base
	powers_used_once = {
		&"bloody_hand": false,
		&"alcohol": false,
		&"cigarette": false,
	}

func consume_spin() -> void:
	if spins_remaining > 0:
		spins_remaining -= 1
	if spins_remaining <= 0:
		active = false

func award_from_meter() -> void:
	if not active:
		return
	var bonus := int(BONUS_SPINS.get(chosen_power, 0))
	if bonus <= 0:
		return
	var remaining_room := maxi(0, total_spin_cap - spins_awarded_total)
	var grant := mini(bonus, remaining_room)
	if grant <= 0:
		return
	spins_remaining += grant
	spins_awarded_total += grant

func mark_power_used_once(power_id: StringName) -> void:
	if not powers_used_once.has(power_id):
		return
	powers_used_once[power_id] = true

func has_used_power(power_id: StringName) -> bool:
	return bool(powers_used_once.get(power_id, false))

func all_powers_used_once() -> bool:
	return has_used_power(&"bloody_hand") and has_used_power(&"alcohol") and has_used_power(&"cigarette")

func ensure_end_guard_spin() -> void:
	if active and spins_remaining <= 0:
		spins_remaining = 1
