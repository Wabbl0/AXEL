extends RefCounted

const LINE_DEFS := {
	"reroll": {"name": "Reroll payout", "rungs": ["C1", "U1", "R1", "E4", ""]},
	"normpay": {"name": "Normal payout", "rungs": ["C2", "U2", "R2", "", ""]},
	"pwrwgt": {"name": "Power-symbol weight", "rungs": ["", "U3", "R3", "E1", ""]},
	"pwrch": {"name": "Power chance", "rungs": ["C4", "U4", "R4", "", ""]},
	"storm": {"name": "Storm", "rungs": ["C6", "U6", "", "", ""]},
	"star": {"name": "Star", "rungs": ["C7", "U7", "", "", ""]},
	"love": {"name": "Love", "rungs": ["C8", "U8", "", "", ""]},
	"wilds": {"name": "Extra wild", "rungs": ["", "U5", "R5", "E3", "L1"]},
}

const COMMON_UNIQUE_IDS: PackedStringArray = ["C3", "C5", "C9", "C10"]


static func picker_line_keys() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for key in LINE_DEFS.keys():
		out.append(String(key))
	return out


static func scatter_lane_keys() -> PackedStringArray:
	var out := picker_line_keys()
	for item_id in COMMON_UNIQUE_IDS:
		out.append(item_id)
	return out


static func display_name(lane: String) -> String:
	if LINE_DEFS.has(lane):
		return String(LINE_DEFS[lane]["name"])
	return lane


static func is_picker_line(lane: String) -> bool:
	return LINE_DEFS.has(lane)


static func is_baseline_lane(lane: String) -> bool:
	return LINE_DEFS.has(lane) or COMMON_UNIQUE_IDS.has(lane)


static func rungs_of(lane: String) -> PackedStringArray:
	if LINE_DEFS.has(lane):
		var raw: Array = LINE_DEFS[lane]["rungs"]
		var out: PackedStringArray = PackedStringArray()
		for item_id in raw:
			out.append(String(item_id))
		return out
	if COMMON_UNIQUE_IDS.has(lane):
		return PackedStringArray([lane, "", "", "", ""])
	return PackedStringArray(["", "", "", "", ""])


static func rung_id(lane: String, rank: int) -> String:
	var rungs := rungs_of(lane)
	var i := clampi(rank, 0, rungs.size() - 1)
	return String(rungs[i])


static func item_id_at_rank(lane: String, rank: int) -> String:
	var rungs := rungs_of(lane)
	var start := clampi(rank, 0, rungs.size() - 1)
	for tier in range(start, -1, -1):
		var item_id := String(rungs[tier])
		if not item_id.is_empty():
			return item_id
	return ""


static func picker_ranks(lane: String) -> Array[int]:
	var out: Array[int] = []
	var rungs := rungs_of(lane)
	for i in mini(4, rungs.size()):
		if not String(rungs[i]).is_empty():
			out.append(i)
	return out


static func first_picker_rank(lane: String) -> int:
	var ranks := picker_ranks(lane)
	return ranks[0] if not ranks.is_empty() else 0


static func next_picker_rank(lane: String, current: int) -> int:
	var ranks := picker_ranks(lane)
	if ranks.is_empty():
		return (current + 1) % 4
	var idx := ranks.find(current)
	if idx < 0:
		return ranks[0]
	return ranks[(idx + 1) % ranks.size()]


static func lane_of_id(item_id: String) -> String:
	if COMMON_UNIQUE_IDS.has(item_id):
		return item_id
	for key in LINE_DEFS.keys():
		var raw: Array = LINE_DEFS[key]["rungs"]
		if raw.has(item_id):
			return String(key)
	return ""


static func is_c1_to_c10(item_id: String) -> bool:
	if item_id == "C10":
		return true
	if item_id.length() != 2 or item_id[0] != "C":
		return false
	var digit := item_id.substr(1)
	return digit.is_valid_int() and digit.to_int() >= 1 and digit.to_int() <= 9
