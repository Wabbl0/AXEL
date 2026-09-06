extends Node
## Combat run owner + narrow overworld/combat bridge (Phase 2).
## Combat never reads story flags; lore goal bonus is a number passed in.

const RunStateScript := preload("res://combat/scripts/run_state.gd")
const ItemInventoryScript := preload("res://combat/scripts/item_inventory.gd")

const LOCKER_SCENE := "res://scenes/Arc_1/1.3_LockerHub.tscn"
const COMBAT_SCENE := "res://combat/combat_run.tscn"
const TITLE_SCENE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const ITEM_DIR := "res://combat/data/items/"
const LORE_FLAGS: PackedStringArray = ["hasFlashlight", "hasKey", "hasShovel", "hasName"]
const LORE_GOAL_BONUS := 0.15
const STARTER_ITEMS: PackedStringArray = ["C1", "C2", "C3"]
## Act I locker, Act II cafeteria/classrooms, Act III basement. No Act IV.
const MAX_PLAYABLE_ACT := 3
const WIN_RETURN_SEC := 1.6
## World fights (walk / pickup / memory). One encounter, then back to the room.
const WORLD_ENCOUNTER_PATHS: PackedStringArray = [
	"res://combat/data/encounters/encounter_payout.tres",
	"res://combat/data/encounters/encounter_wild_count.tres",
	"res://combat/data/encounters/encounter_grid_clear.tres",
]
const ACT_PATHS := [
	[
		"res://combat/data/encounters/encounter_payout.tres",
		"res://combat/data/encounters/encounter_wild_count.tres",
		"res://combat/data/encounters/encounter_grid_clear.tres",
	],
	[
		"res://combat/data/encounters/encounter_payout.tres",
		"res://combat/data/encounters/encounter_wild_count.tres",
		"res://combat/data/encounters/encounter_grid_clear.tres",
	],
	[
		"res://combat/data/encounters/encounter_payout.tres",
		"res://combat/data/encounters/encounter_wild_count.tres",
		"res://combat/data/encounters/encounter_grid_clear.tres",
	],
]

var state = RunStateScript.new()
var _catalog: Dictionary = {}
var _wired_root: Node = null
var _wire_tries: int = 0
var _finish_busy: bool = false


func _ready() -> void:
	var tree := get_tree()
	if tree != null and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	reset_run()


func reset_run() -> void:
	state = RunStateScript.new()
	state.seed = int(Time.get_unix_time_from_system())
	_wired_root = null
	_wire_tries = 0
	_finish_busy = false


func to_dict() -> Dictionary:
	return state.to_dict()


func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		reset_run()
		return
	state = RunStateScript.from_dict(data)
	_wired_root = null
	_wire_tries = 0
	_finish_busy = false


func is_in_encounter() -> bool:
	return state.in_encounter


func mark_first_encounter_warned() -> void:
	state.first_encounter_warned = true
	_persist()


func grant_locker_stash_once() -> void:
	if state.locker_stash_granted:
		return
	state.locker_stash_granted = true
	for item_id in STARTER_ITEMS:
		if not state.owned_item_ids.has(item_id):
			state.owned_item_ids.append(item_id)
	_persist()


func lore_goal_bonus() -> float:
	var n := 0
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.has_method("get_flag"):
		return 0.0
	for flag_name in LORE_FLAGS:
		if bool(gm.call("get_flag", flag_name)):
			n += 1
	return float(n) * LORE_GOAL_BONUS


func current_encounter_path() -> String:
	if state.world_encounter:
		var world_i: int = clampi(int(state.world_encounter_index), 0, WORLD_ENCOUNTER_PATHS.size() - 1)
		return String(WORLD_ENCOUNTER_PATHS[world_i])
	if state.act < 1 or state.act > MAX_PLAYABLE_ACT:
		return ""
	var act_i: int = int(state.act) - 1
	if act_i < 0 or act_i >= ACT_PATHS.size():
		return ""
	var list: Array = ACT_PATHS[act_i]
	if state.encounter_index < 0 or state.encounter_index >= list.size():
		return ""
	return String(list[state.encounter_index])


func current_encounter() -> Resource:
	var path := current_encounter_path()
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path)


func encounters_in_act() -> int:
	var act_i: int = clampi(int(state.act) - 1, 0, ACT_PATHS.size() - 1)
	return (ACT_PATHS[act_i] as Array).size()


func can_start_encounter() -> bool:
	return current_encounter() != null


func encounter_seed() -> int:
	if state.world_encounter:
		return state.seed + 500009 + state.world_encounter_index * 10007
	return state.seed + state.act * 10007 + state.encounter_index * 97


## Narrative-side door: one encounter, then back to `return_scene`.
## `return_tex` is an EnvironmentColliders-local (texture pixel) standing spot;
## pass `has_tex = false` to let the room place the player its own way.
func enter_world_encounter(
	reason: String,
	return_scene: String,
	return_tex: Vector2 = Vector2.ZERO,
	has_tex: bool = false,
) -> void:
	if state.in_encounter or _finish_busy:
		return
	state.world_encounter = true
	state.world_reason = reason
	state.world_return_scene = return_scene
	state.world_return_tex_x = return_tex.x
	state.world_return_tex_y = return_tex.y
	state.world_return_tex_valid = has_tex
	state.world_encounter_index = (int(state.world_encounter_index) + 1) % WORLD_ENCOUNTER_PATHS.size()
	state.in_encounter = true
	_persist_now()
	if is_instance_valid(AxelEventFx):
		await AxelEventFx.play_combat_wipe()
	if get_tree() == null:
		return
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("to_combat"):
		music.call("to_combat")
	get_tree().change_scene_to_file(COMBAT_SCENE)


func enter_combat() -> void:
	if not can_start_encounter():
		return
	state.in_encounter = true
	_persist_now()
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("to_combat"):
		music.call("to_combat")
	get_tree().change_scene_to_file(COMBAT_SCENE)


func on_encounter_finished(success: bool) -> void:
	if _finish_busy:
		return
	_finish_busy = true
	state.in_encounter = false
	if not success:
		_permadeath_to_title()
		return
	_apply_win_progress()
	if state.world_encounter:
		_return_to_world_room()
		return
	_to_overworld_music()
	get_tree().change_scene_to_file(LOCKER_SCENE)
	_finish_busy = false


func abort_encounter_as_loss() -> void:
	if not state.in_encounter and not _finish_busy:
		return
	_finish_busy = false
	state.in_encounter = false
	_permadeath_to_title()


func write_tombstone_only() -> void:
	state.in_encounter = false
	_write_tombstone()


func load_item(item_id: String) -> Resource:
	_ensure_catalog()
	var path := String(_catalog.get(item_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path)


func equipped_items() -> Array:
	var out: Array = []
	for item_id in state.equipped_item_ids:
		var item := load_item(item_id)
		if item != null:
			out.append(item)
	return out


func owned_items() -> Array:
	var out: Array = []
	for item_id in state.owned_item_ids:
		var item := load_item(item_id)
		if item != null:
			out.append(item)
	return out


func toggle_equip(item_id: String) -> bool:
	var ids: Array = []
	for existing in state.equipped_item_ids:
		ids.append(String(existing))
	if ids.has(item_id):
		ids.erase(item_id)
		state.equipped_item_ids = PackedStringArray(ids)
		_persist()
		return true
	if not Array(state.owned_item_ids).has(item_id):
		return false
	var inv := ItemInventoryScript.new()
	inv.set_all(equipped_items())
	var item := load_item(item_id)
	if item == null:
		return false
	if not inv.equip(item):
		return false
	ids.append(item_id)
	state.equipped_item_ids = PackedStringArray(ids)
	_persist()
	return true


func capture_bankroll_from(root: Node) -> void:
	if root != null and root.has_method("get_bankroll"):
		state.bankroll_cents = int(root.call("get_bankroll"))


func _on_scene_changed() -> void:
	_wired_root = null
	_wire_tries = 0
	var scene := get_tree().current_scene
	if scene == null or not scene.scene_file_path.begins_with("res://combat/"):
		return
	if not state.in_encounter:
		return
	call_deferred("_wire_combat_root")


func _wire_combat_root() -> void:
	if not state.in_encounter:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var root := scene.find_child("CombatRoot", true, false)
	if root == null or not root.has_method("setup_new_grid"):
		_wire_tries += 1
		if _wire_tries < 24:
			call_deferred("_wire_combat_root")
		return
	if _wired_root == root:
		return
	_wired_root = root
	var encounter := current_encounter()
	if encounter != null:
		root.set("encounter_def", encounter)
	if root.has_method("set_lore_goal_bonus"):
		root.call("set_lore_goal_bonus", lore_goal_bonus())
	if root.has_method("set_equipped_items"):
		root.call("set_equipped_items", equipped_items())
	if root.has_method("set_limit_spins"):
		root.call("set_limit_spins", true)
	if encounter != null and root.has_method("set_spin_budget"):
		root.call("set_spin_budget", int(encounter.get("spin_budget")))
	root.call("setup_new_grid", encounter_seed())
	if root.has_method("restore_run_bankroll"):
		root.call("restore_run_bankroll", state.bankroll_cents)
	elif root.has_method("set_bankroll_cents"):
		root.call("set_bankroll_cents", state.bankroll_cents)
	if root.has_signal("encounter_finished"):
		if not root.is_connected("encounter_finished", _on_root_finished):
			root.connect("encounter_finished", _on_root_finished)


func _on_root_finished(success: bool) -> void:
	if _finish_busy:
		return
	if success:
		_finish_busy = true
		capture_bankroll_from(_wired_root)
		_apply_win_progress()
		_return_after_win()
		return
	on_encounter_finished(false)


func max_equip_slots() -> int:
	var inv := ItemInventoryScript.new()
	inv.set_all(equipped_items())
	return inv.get_current_max_slots()


func _apply_win_progress() -> void:
	state.in_encounter = false
	if state.world_encounter:
		# World fights are one-offs: they never move the act pointer.
		_persist_now()
		return
	state.encounter_index += 1
	var act_i: int = clampi(int(state.act) - 1, 0, ACT_PATHS.size() - 1)
	if int(state.encounter_index) >= (ACT_PATHS[act_i] as Array).size():
		if int(state.act) < MAX_PLAYABLE_ACT:
			state.act += 1
			state.encounter_index = 0
		# Last act is finished: keep act at MAX and leave index past the list
		# so can_start_encounter() is false. Do not invent Act IV.
	_persist_now()


func _return_after_win() -> void:
	if WIN_RETURN_SEC > 0.0:
		await get_tree().create_timer(WIN_RETURN_SEC).timeout
	if get_tree() == null:
		return
	if state.world_encounter:
		_return_to_world_room()
		return
	_to_overworld_music()
	get_tree().change_scene_to_file(LOCKER_SCENE)
	_finish_busy = false


## Win after a walk / pickup / memory fight: back to the room, same spot.
func _return_to_world_room() -> void:
	var dest := String(state.world_return_scene)
	var tex := Vector2(float(state.world_return_tex_x), float(state.world_return_tex_y))
	var has_tex := bool(state.world_return_tex_valid)
	var reason := String(state.world_reason)
	_clear_world_encounter()
	_persist_now()
	if dest.is_empty() or not ResourceLoader.exists(dest):
		dest = LOCKER_SCENE
		has_tex = false
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("notify_fight_won"):
		world.call("notify_fight_won", reason, dest, tex, has_tex)
	_to_overworld_music()
	get_tree().change_scene_to_file(dest)
	_finish_busy = false


func _clear_world_encounter() -> void:
	state.world_encounter = false
	state.world_reason = ""
	state.world_return_scene = ""
	state.world_return_tex_x = 0.0
	state.world_return_tex_y = 0.0
	state.world_return_tex_valid = false


func _permadeath_to_title() -> void:
	_clear_world_encounter()
	_write_tombstone()
	_to_overworld_music()
	get_tree().change_scene_to_file(TITLE_SCENE)
	_finish_busy = false


func _write_tombstone() -> void:
	var saves := get_node_or_null("/root/AxelSaves")
	if saves == null or not bool(saves.call("is_active")):
		return
	saves.call("write_tombstone", int(saves.get("active_slot")))


func _to_overworld_music() -> void:
	var music := get_node_or_null("/root/AxelMusic")
	if music != null and music.has_method("to_overworld"):
		music.call("to_overworld")


func _persist() -> void:
	var saves := get_node_or_null("/root/AxelSaves")
	if saves != null and bool(saves.call("is_active")):
		saves.call("save_active")


func _persist_now() -> void:
	var saves := get_node_or_null("/root/AxelSaves")
	if saves != null and bool(saves.call("is_active")):
		saves.call("save_active_now")


func _ensure_catalog() -> void:
	if not _catalog.is_empty():
		return
	var dir := DirAccess.open(ITEM_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var path := ITEM_DIR + fname
			var res := load(path)
			if res != null:
				var item_id := String(res.get("id"))
				if not item_id.is_empty():
					_catalog[item_id] = path
		fname = dir.get_next()
	dir.list_dir_end()
