class_name RunState
extends Resource

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
@export var world_encounter: bool = false
@export var world_reason: String = ""
@export var world_return_scene: String = ""
@export var world_return_tex_x: float = 0.0
@export var world_return_tex_y: float = 0.0
@export var world_return_tex_valid: bool = false
@export var world_encounter_index: int = 0
@export var world_fight_count: int = 0
@export var tutorial_fight_pending: bool = false
@export var tutorial_fight_done: bool = false
@export var fought_rooms: PackedStringArray = PackedStringArray()


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
		"world_encounter": world_encounter,
		"world_reason": world_reason,
		"world_return_scene": world_return_scene,
		"world_return_tex_x": world_return_tex_x,
		"world_return_tex_y": world_return_tex_y,
		"world_return_tex_valid": world_return_tex_valid,
		"world_encounter_index": world_encounter_index,
		"world_fight_count": world_fight_count,
		"tutorial_fight_pending": tutorial_fight_pending,
		"tutorial_fight_done": tutorial_fight_done,
		"fought_rooms": Array(fought_rooms),
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
	state.world_encounter = bool(data.get("world_encounter", false))
	state.world_reason = String(data.get("world_reason", ""))
	state.world_return_scene = String(data.get("world_return_scene", ""))
	state.world_return_tex_x = float(data.get("world_return_tex_x", 0.0))
	state.world_return_tex_y = float(data.get("world_return_tex_y", 0.0))
	state.world_return_tex_valid = bool(data.get("world_return_tex_valid", false))
	state.world_encounter_index = maxi(int(data.get("world_encounter_index", 0)), 0)
	state.world_fight_count = maxi(int(data.get("world_fight_count", 0)), 0)
	state.tutorial_fight_pending = bool(data.get("tutorial_fight_pending", false))
	state.tutorial_fight_done = bool(data.get("tutorial_fight_done", false))
	state.fought_rooms = PackedStringArray(data.get("fought_rooms", []))
	return state
