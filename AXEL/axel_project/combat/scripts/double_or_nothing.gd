class_name DoubleOrNothing
extends RefCounted

const PICKS: Array[StringName] = [&"alcohol", &"bloody_hand", &"cigarette"]
const ROLL_ORDER: Array[StringName] = [&"alcohol", &"cigarette", &"bloody_hand"]
const WEIGHTS := {&"alcohol": 47, &"cigarette": 47, &"bloody_hand": 6}
const MULTIPLIERS := {&"alcohol": 2, &"cigarette": 2, &"bloody_hand": 15}
const BELT_LENGTH := 64
const LAND_INDEX := 52
const LAND_OFFSET_MAX := 0.38
const NEAR_MISS_CHANCE := 0.55


static func multiplier_for(pick: StringName) -> int:
	return int(MULTIPLIERS.get(pick, 0))


static func make_rng(seed_value: int, step: int) -> CombatRNG:
	var r := CombatRNG.new()
	r.seed(hash([seed_value, step, "double_or_nothing"]))
	return r


static func roll_with(r: CombatRNG) -> StringName:
	var total := 0
	for id in ROLL_ORDER:
		total += int(WEIGHTS[id])
	var n := r.randi_range(0, total - 1)
	for id in ROLL_ORDER:
		n -= int(WEIGHTS[id])
		if n < 0:
			return id
	return ROLL_ORDER[0]


static func play_round(seed_value: int, step: int) -> Dictionary:
	var r := make_rng(seed_value, step)
	var result := roll_with(r)
	var belt: Array[StringName] = []
	for i in BELT_LENGTH:
		belt.append(roll_with(r))
	belt[LAND_INDEX] = result
	if result != &"bloody_hand" and r.randf() < NEAR_MISS_CHANCE:
		var side := 1 if r.randf() < 0.5 else -1
		belt[LAND_INDEX + side] = &"bloody_hand"
	var offset := r.randf_range(-LAND_OFFSET_MAX, LAND_OFFSET_MAX)
	return {
		"result": result,
		"belt": belt,
		"land_index": LAND_INDEX,
		"land_offset": offset,
		"step": step,
	}
