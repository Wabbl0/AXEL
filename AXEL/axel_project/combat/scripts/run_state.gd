class_name RunState
extends Resource
## Saveable combat run (Phase 2.1). No renderer state.
## Serialises into the slot body, not a separate user://run.save.

@export var schema_version: int = 1
@export var seed: int = 0
@export var act: int = 1
@export var encounter_index: int = 0
@export var bankroll_cents: int = 1000
@export var stake_cents: int = 100
@export var smokes: int = 0
@export var memory_fragments: int = 0
@export var rot: int = 0
@export var lucid: int = 0
@export var owned_item_ids: PackedStringArray = PackedStringArray()
@export var equipped_item_ids: PackedStringArray = PackedStringArray()
@export var first_encounter_warned: bool = false
@export var locker_stash_granted: bool = false
@export var in_encounter: bool = false


func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"seed": seed,
		"act": act,
		"encounter_index": encounter_index,
		"bankroll_cents": bankroll_cents,
		"stake_cents": stake_cents,
		"smokes": smokes,
		"memory_fragments": memory_fragments,
		"rot": rot,
		"lucid": lucid,
		"owned_item_ids": Array(owned_item_ids),
		"equipped_item_ids": Array(equipped_item_ids),
		"first_encounter_warned": first_encounter_warned,
		"locker_stash_granted": locker_stash_granted,
		"in_encounter": in_encounter,
	}


static func from_dict(data: Dictionary) -> RunState:
	var state := RunState.new()
	if data.is_empty():
		return state
	state.schema_version = int(data.get("schema_version", 1))
	state.seed = int(data.get("seed", 0))
	state.act = maxi(int(data.get("act", 1)), 1)
	state.encounter_index = maxi(int(data.get("encounter_index", 0)), 0)
	state.bankroll_cents = int(data.get("bankroll_cents", 1000))
	state.stake_cents = int(data.get("stake_cents", 100))
	state.smokes = int(data.get("smokes", 0))
	state.memory_fragments = int(data.get("memory_fragments", 0))
	state.rot = int(data.get("rot", 0))
	state.lucid = int(data.get("lucid", 0))
	state.owned_item_ids = PackedStringArray(data.get("owned_item_ids", []))
	state.equipped_item_ids = PackedStringArray(data.get("equipped_item_ids", []))
	state.first_encounter_warned = bool(data.get("first_encounter_warned", false))
	state.locker_stash_granted = bool(data.get("locker_stash_granted", false))
	state.in_encounter = bool(data.get("in_encounter", false))
	return state
