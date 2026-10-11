class_name ItemEffectDispatcher
extends RefCounted

const ALL_POWERS: Array[StringName] = [&"bloody_hand", &"alcohol", &"cigarette"]
const PAID_SPIN_SCALAR_TOTAL_CAP := 2.0
const EXTRA_WILDS_PER_CREATE_CAP := 1
const HEAD_START_CAP := 0.5

var dead_power_streak: int = 0
var pending_power_chance: float = 0.0
var pending_power_spawn: float = 0.0
var first_dead_used: bool = false
var wilds_created_encounter: int = 0
var first_wild_this_spin: bool = true
var first_premium_this_spin: bool = true
var overclock_used_this_spin: bool = false
var trinity_win_scalar_accum: float = 0.0
var fs_first_win_this_spin: bool = true
var glyphs: Dictionary = {}
var meter_frac_accum: float = 0.0
var chaining: bool = false
var girl_power_this_spin: bool = false
var _procs: Array[StringName] = []


func reset_encounter() -> void:
	dead_power_streak = 0
	pending_power_chance = 0.0
	pending_power_spawn = 0.0
	first_dead_used = false
	wilds_created_encounter = 0
	trinity_win_scalar_accum = 0.0
	glyphs.clear()
	meter_frac_accum = 0.0
	chaining = false
	reset_spin()


func reset_spin() -> void:
	first_wild_this_spin = true
	first_premium_this_spin = true
	overclock_used_this_spin = false
	fs_first_win_this_spin = true
	chaining = false
	girl_power_this_spin = false
	glyphs.clear()


func note_proc(item: Resource) -> void:
	if item == null:
		return
	var item_id := StringName(str(item.get("id")))
	if item_id == &"":
		return
	_procs.append(item_id)


func note_effect(items: Array, effect_id: StringName) -> void:
	for item in items:
		if _eff(item) == effect_id:
			note_proc(item)


func note_same_params(items: Array, params: Dictionary) -> void:
	for item in items:
		if _params(item) == params:
			note_proc(item)
			return


func note_param(items: Array, effect_id: StringName, key: String) -> void:
	for item in items:
		if _eff(item) != effect_id:
			continue
		var v = _params(item).get(key, null)
		if v == null:
			continue
		if v is bool and not v:
			continue
		if (v is int or v is float) and float(v) == 0.0:
			continue
		note_proc(item)


func note_charm(items: Array, power_id: StringName) -> void:
	for item in items:
		if _eff(item) == &"power_charm" and StringName(str(_params(item).get("power", ""))) == power_id:
			note_proc(item)


func note_paid_spin_passives(items: Array) -> void:
	for item in items:
		var eid := _eff(item)
		var p := _params(item)
		var hit := false
		match eid:
			&"paid_spin_payout_scalar":
				hit = float(p.get("per_paid_spin", 0.0)) > 0.0
			&"spawn_weight_normals", &"power_symbol_weight", &"girl_power_chance":
				hit = true
			&"sealed_grid":
				hit = float(p.get("payout_bonus", 0.0)) > 0.0
		if hit:
			note_proc(item)


func drain_procs() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_procs)
	_procs.clear()
	return out


func _eff(item: Resource) -> StringName:
	if item == null:
		return &""
	return StringName(str(item.get("effect_id")))


func _params(item: Resource) -> Dictionary:
	if item == null:
		return {}
	var p = item.get("effect_params")
	if p is Dictionary:
		return p
	return {}


func head_start_percent(items: Array) -> float:
	var total := 0.0
	for item in items:
		if _eff(item) != &"goal_head_start":
			continue
		total += float(_params(item).get("paid_percent", 0.0))
	return minf(total, HEAD_START_CAP)


func paid_spin_payout_scalar(items: Array, spins_used: int) -> float:
	var total := 0.0
	for item in items:
		if _eff(item) != &"paid_spin_payout_scalar":
			continue
		var p := _params(item)
		var per := float(p.get("per_paid_spin", 0.0))
		var cap := float(p.get("cap", 99.0))
		total += minf(float(spins_used) * per, cap)
	return minf(total, PAID_SPIN_SCALAR_TOTAL_CAP)


func sealed_payout(items: Array, regular_mode: bool) -> float:
	if not regular_mode:
		return 0.0
	var total := 0.0
	for item in items:
		if _eff(item) != &"sealed_grid":
			continue
		total += float(_params(item).get("payout_bonus", 0.0))
	return total


func has_sealed_grid(items: Array) -> bool:
	for item in items:
		if _eff(item) == &"sealed_grid":
			return true
	return false


func should_skip_refill(items: Array, in_trinity: bool, in_free_spins: bool) -> bool:
	if in_trinity or in_free_spins:
		return false
	return has_sealed_grid(items)


func first_paid_spin_free(items: Array) -> bool:
	for item in items:
		if _eff(item) == &"paid_spin_payout_scalar" and bool(_params(item).get("first_free", false)):
			return true
	return false


func first_paid_spin_refund(items: Array) -> float:
	var total := 0.0
	for item in items:
		if _eff(item) == &"first_paid_spin_refund":
			total += float(_params(item).get("amount", 0.0))
	return total


func girl_power_chance(items: Array, base: float) -> float:
	var chance := base
	for item in items:
		var eid := _eff(item)
		var p := _params(item)
		if eid == &"girl_power_chance":
			if str(p.get("mode", "")) == "double":
				chance *= 2.0
			chance += float(p.get("amount", 0.0))
	chance += pending_power_chance
	return clampf(chance, 0.0, 1.0)


func apply_weights(items: Array, base_weights: Dictionary, symbols_by_id: Dictionary) -> Dictionary:
	var weights: Dictionary = base_weights.duplicate()
	var normal_add := 0.0
	var power_add := 0.0
	var power_chance_add := 0.0
	var per_power: Dictionary = {}
	for item in items:
		var eid := _eff(item)
		var p := _params(item)
		match eid:
			&"spawn_weight_normals":
				normal_add += float(p.get("amount", 0.0))
			&"normal_payout_bonus":
				normal_add += float(p.get("weight", 0.0))
			&"power_symbol_weight":
				power_add += float(p.get("amount", 0.0))
			&"paid_spin_payout_scalar":
				power_chance_add += float(p.get("power_symbol_chance", 0.0))
			&"power_charm":
				var pid := StringName(str(p.get("power", "")))
				per_power[pid] = float(per_power.get(pid, 0.0)) + float(p.get("spawn_chance", 0.0))
			&"first_dead_power_spawn":
				pass
	power_add += pending_power_spawn
	for sid in weights.keys():
		var sd = symbols_by_id.get(sid, null)
		if sd == null:
			continue
		var w := float(weights[sid])
		var tier = sd.get("tier")
		var power_id: StringName = sd.get("power_id") if sd.get("power_id") != null else &""
		if int(tier) == 0:
			w *= 1.0 + normal_add
		if power_id != &"":
			w *= 1.0 + power_add + power_chance_add
			w *= 1.0 + float(per_power.get(power_id, 0.0))
		weights[sid] = w
	return weights


func line_payout_bonus(
	items: Array,
	symbol_tier: int,
	power_id: StringName,
	in_trinity: bool,
	record_procs: bool = false
) -> float:
	var bonus := 0.0
	for item in items:
		var eid := _eff(item)
		var p := _params(item)
		var add := 0.0
		match eid:
			&"normal_payout_bonus":
				if symbol_tier == 0:
					add = float(p.get("amount", 0.0))
			&"power_payout_bonus":
				if power_id != &"" and StringName(str(p.get("power", ""))) == power_id:
					add = float(p.get("amount", 0.0))
			&"power_symbol_weight":
				if power_id != &"":
					add = float(p.get("payout", 0.0))
			&"trinity_run":
				if in_trinity and symbol_tier == 0:
					add = float(p.get("normal_payout", 0.0))
		if add == 0.0:
			continue
		bonus += add
		if record_procs:
			note_proc(item)
	if in_trinity:
		bonus += trinity_win_scalar_accum
	return bonus


func power_potency_bonus(items: Array) -> float:
	var total := 0.0
	for item in items:
		if _eff(item) == &"power_symbol_weight":
			total += float(_params(item).get("potency", 0.0))
	return total


func diagonal_opts(items: Array) -> Dictionary:
	var opts := {
		"mode": "none",
		"wilds": false,
		"meter_frac": 0.0,
		"full_lines": false,
	}
	for item in items:
		if _eff(item) != &"diagonal":
			continue
		var p := _params(item)
		opts["mode"] = str(p.get("mode", "none"))
		if p.has("wilds"):
			opts["wilds"] = bool(p.get("wilds", false))
		if p.has("meter_frac"):
			opts["meter_frac"] = float(p.get("meter_frac", 0.0))
		if p.has("full_lines"):
			opts["full_lines"] = bool(p.get("full_lines", false))
			if bool(opts["full_lines"]):
				opts["wilds"] = true
	return opts


func board_count_rule(items: Array) -> Dictionary:
	var rule := {
		"threshold": 0,
		"bonus_stake": 0.0,
		"once_per_step": false,
		"meter": false,
		"full_resolver": false,
	}
	var bonus_sum := 0.0
	for item in items:
		if _eff(item) != &"board_count":
			continue
		var p := _params(item)
		if p.has("threshold"):
			rule["threshold"] = int(p.get("threshold", 0))
		bonus_sum += float(p.get("bonus_stake", 0.0))
		if p.has("once_per_step"):
			rule["once_per_step"] = bool(p.get("once_per_step", false))
		if p.has("meter"):
			rule["meter"] = bool(p.get("meter", false))
		if p.has("full_resolver"):
			rule["full_resolver"] = bool(p.get("full_resolver", false))
	rule["bonus_stake"] = bonus_sum
	return rule


func meter_mods(items: Array) -> Dictionary:
	var mods := {
		"first_line_bonus": 0,
		"gain_mult": 1.0,
		"length_boost": 0,
		"any_line_fills": false,
		"wild_extra": 0,
		"overflow": false,
		"first_fills_section": false,
		"diag_meter_frac": 0.0,
		"board_count_meter": false,
	}
	for item in items:
		var eid := _eff(item)
		var p := _params(item)
		if eid == &"premium_meter":
			mods["first_line_bonus"] = int(mods["first_line_bonus"]) + int(p.get("first_line_bonus", 0))
			if p.has("gain_mult"):
				mods["gain_mult"] = float(p.get("gain_mult", 1.0))
			if p.has("length_boost"):
				mods["length_boost"] = int(p.get("length_boost", 0))
			if p.has("any_line_fills"):
				mods["any_line_fills"] = bool(p.get("any_line_fills", false))
			mods["wild_extra"] = int(mods["wild_extra"]) + int(p.get("wild_extra", 0))
			if p.has("overflow"):
				mods["overflow"] = bool(p.get("overflow", false))
			if p.has("first_fills_section"):
				mods["first_fills_section"] = bool(p.get("first_fills_section", false))
		elif eid == &"diagonal":
			if p.has("meter_frac"):
				mods["diag_meter_frac"] = float(p.get("meter_frac", 0.0))
		elif eid == &"board_count":
			if bool(p.get("meter", false)):
				mods["board_count_meter"] = true
	return mods


func trinity_mods(items: Array) -> Dictionary:
	var mods := {
		"first_miss_extra_spins": 0,
		"win_scalar": 0.0,
		"vice_potency": 1.0,
		"chosen_plus_random": 0.0,
	}
	for item in items:
		if _eff(item) != &"trinity_run":
			continue
		var p := _params(item)
		mods["first_miss_extra_spins"] = int(mods["first_miss_extra_spins"]) + int(p.get("first_miss_extra_spins", 0))
		mods["win_scalar"] = float(mods["win_scalar"]) + float(p.get("win_scalar", 0.0))
		if p.has("vice_potency"):
			mods["vice_potency"] = maxf(float(mods["vice_potency"]), float(p.get("vice_potency", 1.0)))
		if p.has("chosen_plus_random"):
			mods["chosen_plus_random"] = float(p.get("chosen_plus_random", 0.0))
	return mods


func free_spins_mods(items: Array) -> Dictionary:
	var mods := {
		"enter_burst": 0.0,
		"extra_spins": 0,
		"cascade_payout_step": 0,
		"first_win_wild": false,
		"chain_random_potency": 0.0,
	}
	for item in items:
		if _eff(item) != &"free_spins":
			continue
		var p := _params(item)
		mods["enter_burst"] = float(mods["enter_burst"]) + float(p.get("enter_burst", 0.0))
		mods["extra_spins"] = int(mods["extra_spins"]) + int(p.get("extra_spins", 0))
		mods["cascade_payout_step"] = int(mods["cascade_payout_step"]) + int(p.get("cascade_payout_step", 0))
		if p.has("first_win_wild"):
			mods["first_win_wild"] = bool(p.get("first_win_wild", false))
		if p.has("chain_random_potency"):
			mods["chain_random_potency"] = float(p.get("chain_random_potency", 0.0))
	return mods


func glyph_params(items: Array) -> Dictionary:
	var params := {
		"cells": 0,
		"mult_min": 2.0,
		"mult_max": 2.5,
		"dest": "winnings",
		"win_frac": 1.0,
	}
	for item in items:
		if _eff(item) != &"corner_glyphs":
			continue
		var p := _params(item)
		params["cells"] = int(params["cells"]) + int(p.get("cells", 0))
		if p.has("mult_min"):
			params["mult_min"] = float(p.get("mult_min", 2.0))
		if p.has("mult_max"):
			params["mult_max"] = float(p.get("mult_max", 2.5))
		if p.has("dest"):
			params["dest"] = str(p.get("dest", "winnings"))
		if p.has("win_frac"):
			params["win_frac"] = float(p.get("win_frac", 1.0))
	return params


func roll_glyphs(items: Array, rng: CombatRNG) -> void:
	glyphs.clear()
	var gp := glyph_params(items)
	var n: int = mini(int(gp["cells"]), 25)
	if n <= 0 or rng == null:
		return
	note_effect(items, &"corner_glyphs")
	var used: Dictionary = {}
	for _i in n:
		var tries := 0
		var key := ""
		while tries < 40:
			var x := rng.randi_range(0, 4)
			var y := rng.randi_range(0, 4)
			key = "%d:%d" % [x, y]
			if not used.has(key):
				used[key] = true
				break
			tries += 1
		if key == "" or glyphs.has(key):
			continue
		var lo := float(gp["mult_min"])
		var hi := float(gp["mult_max"])
		var mult := lo
		if hi > lo:
			mult = lo + rng.randf() * (hi - lo)
		glyphs[key] = {
			"mult": mult,
			"dest": str(gp["dest"]),
			"win_frac": float(gp["win_frac"]),
		}


func charm_mods(items: Array, power_id: StringName) -> Dictionary:
	var out := {
		"extra_set_chance": 0.0,
		"extra_wild_chance": 0.0,
		"extra_transform_chance": 0.0,
	}
	for item in items:
		if _eff(item) != &"power_charm":
			continue
		var p := _params(item)
		if StringName(str(p.get("power", ""))) != power_id:
			continue
		out["extra_set_chance"] = float(out["extra_set_chance"]) + float(p.get("extra_set_chance", 0.0))
		out["extra_wild_chance"] = float(out["extra_wild_chance"]) + float(p.get("extra_wild_chance", 0.0))
		out["extra_transform_chance"] = float(out["extra_transform_chance"]) + float(p.get("extra_transform_chance", 0.0))
	return out


func null_gravity_chance(items: Array) -> float:
	var total := 0.0
	for item in items:
		if _eff(item) == &"null_gravity":
			total += float(_params(item).get("chance", 0.0))
	return total


func trinity_echo(items: Array) -> Dictionary:
	var out := {"chance": 0.0, "potency": 0.5}
	for item in items:
		if _eff(item) != &"trinity_echo":
			continue
		var p := _params(item)
		out["chance"] = float(out["chance"]) + float(p.get("chance", 0.0))
		out["potency"] = float(p.get("potency", 0.5))
	return out


func collect_power_chains(items: Array) -> Array:
	var out: Array = []
	for item in items:
		if _eff(item) != &"power_chain":
			continue
		out.append(_params(item))
	return out


func extra_wilds_for_create(items: Array, rng: CombatRNG) -> int:
	var extra := 0
	wilds_created_encounter += 1
	for item in items:
		if _eff(item) != &"extra_wild_on_create":
			continue
		var p := _params(item)
		if bool(p.get("always", false)):
			extra += 1
			note_proc(item)
			continue
		if bool(p.get("first_each_spin", false)):
			if first_wild_this_spin:
				extra += 1
				note_proc(item)
			continue
		var every_nth := int(p.get("every_nth", 0))
		if every_nth > 0 and wilds_created_encounter % every_nth == 0:
			extra += 1
			note_proc(item)
			continue
		var chance := float(p.get("chance", 0.0))
		if chance > 0.0 and rng != null and rng.randf() <= chance:
			extra += 1
			note_proc(item)
	first_wild_this_spin = false
	return mini(extra, EXTRA_WILDS_PER_CREATE_CAP)


func apply_c5_c9_from_items(items: Array, produced_win: bool, power_triggered: bool) -> void:
	if power_triggered:
		dead_power_streak = 0
	else:
		dead_power_streak += 1
	pending_power_chance = 0.0
	if not power_triggered:
		for item in items:
			if _eff(item) != &"dead_spin_power_catchup":
				continue
			var need := int(_params(item).get("spins", 2))
			if dead_power_streak >= need:
				pending_power_chance += float(_params(item).get("amount", 0.0))
				dead_power_streak = 0
				note_proc(item)
	pending_power_spawn = 0.0
	if not produced_win and not first_dead_used:
		first_dead_used = true
		for item in items:
			if _eff(item) == &"first_dead_power_spawn":
				pending_power_spawn += float(_params(item).get("amount", 0.0))
				note_proc(item)


func other_powers(except_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for pid in ALL_POWERS:
		if pid != except_id:
			out.append(pid)
	return out


func paid_spin_hint(items: Array, spins_used: int) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for item in items:
		if _eff(item) != &"paid_spin_payout_scalar":
			continue
		var p := _params(item)
		var per := float(p.get("per_paid_spin", 0.0))
		var cap := float(p.get("cap", 99.0))
		var cur := minf(float(spins_used) * per, cap)
		parts.append("%s +%.2fx at %d used, cap %.2f" % [String(item.get("id")), cur, spins_used, cap])
	for item in items:
		if _eff(item) == &"first_paid_spin_refund":
			if spins_used <= 0:
				parts.append("C10 refund pending")
			else:
				parts.append("C10 refund consumed")
	if parts.is_empty():
		return ""
	return ", ".join(parts)
