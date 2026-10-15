extends Node

const RunStateScript := preload("res://combat/scripts/run_state.gd")
const ItemInventoryScript := preload("res://combat/scripts/item_inventory.gd")

const LOCKER_SCENE := "res://scenes/Arc_1/1.3_LockerHub.tscn"
const COMBAT_SCENE := "res://combat/combat_test.tscn"
const TITLE_SCENE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const ITEM_DIR := "res://combat/data/items/"
const LORE_FLAGS: PackedStringArray = ["hasFlashlight", "hasKey", "hasShovel", "hasName"]
const LORE_GOAL_BONUS := 0.15
const WORLD_GOAL_LADDER_CENTS: PackedInt32Array = [
	50, 60, 70, 80, 95, 115, 145, 190, 250, 330,
]
const WORLD_GOAL_LADDER_GROWTH := 1.5
const WORLD_GOAL_GROWTH_STEP := 0.02
const DREAD_BY_RANK := {"C": 0.08, "U": 0.10, "R": 0.12, "E": 0.16, "L": 0.20}
const DREAD_PER_MEMORY := 0.10
const TICKET_BASE_PRICE := 300
const TICKET_PRICE_GROWTH := 1.5
const TICKET_MIN_LEFT := 100
const TRAVEL_BALANCE_PCT := 0.10
const TRAVEL_MIN_PRICE := 50
const TRAVEL_MIN_LEFT := 100
const WORLD_GOAL_LADDER_ROUNDING := 5
const REASON_LOCKER_TUTORIAL := "locker_tutorial"
const GUIDE_LESSON := "guide_pause"
const STARTING_BANKROLL_CENTS := 3000
const MAX_PLAYABLE_ACT := 3
const NEW_GAME_SCENE := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
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
var _game_over_open: bool = false
var _retry_slot: int = -1


func _ready() -> void:
	var tree := get_tree()
	if tree != null and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	reset_run()


func reset_run(slot: int = -1) -> void:
	state = RunStateScript.new()
	state.seed = _make_run_seed(slot)
	state.bankroll_cents = STARTING_BANKROLL_CENTS
	_wired_root = null
	_wire_tries = 0
	_finish_busy = false
	_game_over_open = false
	_retry_slot = -1


func _make_run_seed(slot: int = -1) -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var mixed := int(Time.get_ticks_usec())
	mixed ^= int(rng.randi())
	mixed ^= int(Time.get_unix_time_from_system()) * 1009
	if slot >= 0:
		mixed ^= (slot + 1) * 1000003
	if mixed == 0:
		mixed = int(rng.randi())
	if mixed == 0:
		mixed = 1
	return mixed


func is_tutorial_last_spin_lock() -> bool:
	if is_tutorial_encounter():
		return true
	return state.world_encounter and int(state.world_fight_count) <= 1


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
	_game_over_open = false
	_retry_slot = -1


func is_in_encounter() -> bool:
	return state.in_encounter


func is_game_over_menu_open() -> bool:
	return _game_over_open


func mark_first_encounter_warned() -> void:
	state.first_encounter_warned = true
	_persist()


func grant_locker_stash_once() -> void:
	if state.locker_stash_granted:
		return
	state.locker_stash_granted = true
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


func dread_pct() -> float:
	return float(state.dread_pct)


static func dread_for_item(item_id: String) -> float:
	if item_id.is_empty():
		return 0.0
	return float(DREAD_BY_RANK.get(item_id.left(1), 0.0))


func add_item_dread(item_id: String) -> void:
	state.dread_pct = float(state.dread_pct) + dread_for_item(item_id)
	_persist()


func add_memory_dread() -> void:
	state.dread_pct = float(state.dread_pct) + DREAD_PER_MEMORY
	_persist()


func ticket_price() -> int:
	var value := float(TICKET_BASE_PRICE) * pow(TICKET_PRICE_GROWTH, float(state.tickets_bought))
	return maxi(int(round(value / 5.0)) * 5, 5)


func ticket_machine_open() -> bool:
	if int(state.tickets_bought) > 0 or int(state.tickets) > 0:
		return true
	var profile := get_node_or_null("/root/AxelProfile")
	return profile != null and bool(profile.call("is_ticket_machine_unlocked"))


func can_buy_ticket() -> bool:
	return int(state.bankroll_cents) - ticket_price() >= TICKET_MIN_LEFT


func buy_ticket() -> bool:
	if not can_buy_ticket():
		return false
	state.bankroll_cents = int(state.bankroll_cents) - ticket_price()
	state.tickets_bought = int(state.tickets_bought) + 1
	state.tickets = int(state.tickets) + 1
	_persist()
	return true


func travel_price() -> int:
	var raw := float(state.bankroll_cents) * TRAVEL_BALANCE_PCT
	return maxi(int(round(raw / 5.0)) * 5, TRAVEL_MIN_PRICE)


func can_pay_travel() -> bool:
	return int(state.bankroll_cents) - travel_price() >= TRAVEL_MIN_LEFT


func pay_travel() -> bool:
	if not can_pay_travel():
		return false
	state.bankroll_cents = int(state.bankroll_cents) - travel_price()
	state.travel_uses = int(state.travel_uses) + 1
	_persist()
	return true


func ticket_count() -> int:
	return int(state.tickets)


func spend_ticket() -> bool:
	if int(state.tickets) <= 0:
		return false
	state.tickets = int(state.tickets) - 1
	state.tickets_used = int(state.tickets_used) + 1
	_persist()
	return true


func goal_bonus_pct() -> float:
	return lore_goal_bonus() + dread_pct()


func current_encounter_path() -> String:
	if state.world_encounter:
		var world_i: int = posmod(int(state.world_encounter_index), WORLD_ENCOUNTER_PATHS.size())
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


func world_goal_base_cents() -> int:
	var rung := maxi(int(state.world_fight_count) - 1, 0)
	var last := WORLD_GOAL_LADDER_CENTS.size() - 1
	if rung <= last:
		return int(WORLD_GOAL_LADDER_CENTS[rung])
	var value := float(WORLD_GOAL_LADDER_CENTS[last])
	for i in rung - last:
		value *= WORLD_GOAL_LADDER_GROWTH + WORLD_GOAL_GROWTH_STEP * float(i)
	var step := float(WORLD_GOAL_LADDER_ROUNDING)
	return maxi(int(round(value / step)) * WORLD_GOAL_LADDER_ROUNDING, 1)


func depth_goal_mult() -> float:
	var world := get_node_or_null("/root/AxelWorld")
	if world == null or not world.has_method("depth_goal_mult_for_scene"):
		return 1.0
	return float(world.call("depth_goal_mult_for_scene", String(state.world_return_scene)))


func world_goal_cents_for_fight() -> int:
	var base := world_goal_base_cents()
	if is_tutorial_encounter():
		return base
	var raw := float(base) * depth_goal_mult()
	return maxi(int(ceil(raw / 5.0)) * 5, 1)


func is_tutorial_encounter() -> bool:
	return state.world_encounter and String(state.world_reason) == REASON_LOCKER_TUTORIAL


func encounter_seed() -> int:
	if state.world_encounter:
		return state.seed + 500009 + state.world_encounter_index * 10007
	return state.seed + state.act * 10007 + state.encounter_index * 97


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
	state.world_encounter_index = int(state.world_encounter_index) + 1
	state.world_fight_count = int(state.world_fight_count) + 1
	state.in_encounter = true
	_persist_now()
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("play_fight_intro_lines"):
		await world.play_fight_intro_lines()
	if get_tree() == null:
		return
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
		_delete_active_run()
		_permadeath_to_title()
		return
	capture_bankroll_from(_live_combat_root())
	_apply_win_progress()
	if state.world_encounter:
		_return_to_world_room()
		return
	_to_overworld_music()
	get_tree().change_scene_to_file(LOCKER_SCENE)
	_finish_busy = false


func abort_encounter_as_loss() -> void:
	if not state.in_encounter and not _finish_busy and not _game_over_open:
		return
	_finish_busy = false
	state.in_encounter = false
	_unlock_guide()
	_delete_active_run()
	_permadeath_to_title()


func _unlock_guide() -> void:
	var profile := get_node_or_null("/root/AxelProfile")
	if profile != null:
		profile.call("unlock_guide")


func write_tombstone_only() -> void:
	state.in_encounter = false
	_delete_active_run()


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


func equip_owned_if_free(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	if Array(state.equipped_item_ids).has(item_id):
		return true
	return toggle_equip(item_id)


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
	_unlock_guide()
	var encounter := current_encounter()
	if encounter != null:
		root.set("encounter_def", encounter)

	var tutorial := is_tutorial_encounter()
	if root.has_method("set_lore_goal_bonus"):
		root.call("set_lore_goal_bonus", 0.0 if tutorial else goal_bonus_pct())
	if root.has_method("set_equipped_items"):
		root.call("set_equipped_items", [] if tutorial else equipped_items())
	if state.world_encounter and root.has_method("set_goal_base_target_cents"):
		root.call("set_goal_base_target_cents", world_goal_cents_for_fight())
	if tutorial and root.has_method("set_tutorial_script_seeds"):
		root.call("set_tutorial_script_seeds", CombatRoot.TUTORIAL_SCRIPT_SEEDS)
	if is_tutorial_last_spin_lock() and root.has_method("set_tutorial_last_spin_lock"):
		root.call("set_tutorial_last_spin_lock", true)
	if encounter != null and root.has_method("set_spin_budget"):
		root.call("set_spin_budget", int(encounter.get("spin_budget")))
	root.call("setup_new_grid", encounter_seed())
	if root.has_method("restore_run_bankroll"):
		root.call("restore_run_bankroll", int(state.bankroll_cents))
	if scene.has_method("refresh_player_item_box"):
		scene.call("refresh_player_item_box")
	if root.has_signal("encounter_finished"):
		if not root.is_connected("encounter_finished", _on_root_finished):
			root.connect("encounter_finished", _on_root_finished)


func _on_root_finished(success: bool) -> void:
	if _finish_busy:
		return
	_unlock_guide()
	if success:
		_finish_busy = true
		capture_bankroll_from(_live_combat_root())
		await _show_round_complete_card()
		await _show_guide_lesson()
		var root := _live_combat_root()
		if root != null and root.has_method("await_victory_confirm"):
			await root.call("await_victory_confirm")
		await _fade_out_of_combat()
		if get_tree() == null:
			return
		capture_bankroll_from(_live_combat_root())
		_apply_win_progress()
		await _return_after_win()
		return
	_finish_busy = true
	state.in_encounter = false
	_open_permadeath_menu()


func max_equip_slots() -> int:
	var inv := ItemInventoryScript.new()
	inv.set_all(equipped_items())
	return inv.get_current_max_slots()


func _apply_win_progress() -> void:
	state.in_encounter = false
	if state.world_encounter:

		_persist_now()
		return
	state.encounter_index += 1
	var act_i: int = clampi(int(state.act) - 1, 0, ACT_PATHS.size() - 1)
	if int(state.encounter_index) >= (ACT_PATHS[act_i] as Array).size():
		if int(state.act) < MAX_PLAYABLE_ACT:
			state.act += 1
			state.encounter_index = 0


	_persist_now()


func _return_after_win() -> void:
	if get_tree() == null:
		return
	if state.world_encounter:
		await _return_to_world_room()
		return
	_to_overworld_music()
	get_tree().change_scene_to_file(LOCKER_SCENE)
	await _fade_in_after_combat()
	_finish_busy = false


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
	if dest.ends_with("1.4_BasementDoor.tscn"):
		var gm := get_node_or_null("/root/GameManager")
		if gm != null and gm.has_method("set_basement_hint_soon"):
			gm.call("set_basement_hint_soon", true)
	_to_overworld_music()
	get_tree().change_scene_to_file(dest)
	await _wait_return_placement(world)
	await _fade_in_after_combat()
	_finish_busy = false


func _wait_return_placement(world: Node) -> void:
	if world == null or not world.has_method("is_return_placement_pending"):
		return
	for _i in 60:
		if get_tree() == null:
			return
		await get_tree().process_frame
		if not bool(world.call("is_return_placement_pending")):
			return


func _clear_world_encounter() -> void:
	state.world_encounter = false
	state.world_reason = ""
	state.world_return_scene = ""
	state.world_return_tex_x = 0.0
	state.world_return_tex_y = 0.0
	state.world_return_tex_valid = false


func _open_permadeath_menu() -> void:
	_game_over_open = true
	var saves := get_node_or_null("/root/AxelSaves")
	_retry_slot = -1
	if saves != null and bool(saves.call("is_active")):
		_retry_slot = int(saves.get("active_slot"))
	_delete_active_run()
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("notify_fight_ended"):
		world.call("notify_fight_ended")
	var feel := _live_feel()
	if feel != null and feel.has_method("show_game_over_menu"):
		feel.call(
			"show_game_over_menu",
			_retry_new_run,
			_to_title_after_death,
			_quit_after_death
		)
		return
	_to_title_after_death()


func _retry_new_run() -> void:
	_game_over_open = false
	var saves := get_node_or_null("/root/AxelSaves")
	var slot := _retry_slot
	if slot < 0 and saves != null and saves.has_method("first_free_slot"):
		slot = int(saves.call("first_free_slot"))
	if saves != null and slot >= 0 and saves.has_method("begin_new_game_immediate"):
		if bool(saves.call("begin_new_game_immediate", slot)):
			_finish_busy = false
			return
	_to_overworld_music()
	if get_tree() != null:
		get_tree().change_scene_to_file(NEW_GAME_SCENE)
	_finish_busy = false


func _to_title_after_death() -> void:
	_game_over_open = false
	_permadeath_to_title()


func _quit_after_death() -> void:
	_game_over_open = false
	if OS.has_feature("web"):
		_permadeath_to_title()
		return
	if get_tree() != null:
		get_tree().quit()


func _permadeath_to_title() -> void:
	state.in_encounter = false
	_clear_world_encounter()
	var world := get_node_or_null("/root/AxelWorld")
	if world != null and world.has_method("notify_fight_ended"):
		world.call("notify_fight_ended")
	_to_overworld_music()
	if get_tree() != null:
		get_tree().change_scene_to_file(TITLE_SCENE)
	_finish_busy = false
	_game_over_open = false


func _delete_active_run() -> void:
	var saves := get_node_or_null("/root/AxelSaves")
	if saves == null or not bool(saves.call("is_active")):
		return
	saves.call("delete_slot", int(saves.get("active_slot")))


func _live_combat_root() -> Node:
	if get_tree() == null:
		return null
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("CombatRoot", true, false)


func _live_feel() -> Node:
	var root := _live_combat_root()
	if root != null and root.has_method("get_feel"):
		return root.call("get_feel")
	if root != null:
		return root.find_child("CombatFeel", true, false)
	return null


func _show_round_complete_card() -> void:
	var scene := get_tree().current_scene if get_tree() != null else null
	if scene != null and scene.has_method("await_victory_prelude"):
		await scene.call("await_victory_prelude")
	var root := _live_combat_root()
	if root != null and root.has_method("play_goal_win_burst"):
		await root.call("play_goal_win_burst")
	await _await_fight_cards_closed()
	var pace := get_node_or_null("/root/CombatPace")
	if pace != null and pace.has_method("clear_rush"):
		pace.call("clear_rush")
	var fx := get_node_or_null("/root/AxelEventFx")
	if fx != null and fx.has_method("show_round_complete_card"):
		var bets := 0
		var balance := 0
		root = _live_combat_root()
		if root != null and root.has_method("get_bets_used"):
			bets = int(root.call("get_bets_used"))
		if root != null and root.has_method("get_bankroll"):
			balance = int(root.call("get_bankroll"))
		var points: Array = []
		if root != null and root.has_method("goal_skull_points"):
			points = root.call("goal_skull_points")
		var gathered := bool(fx.call("show_round_complete_card", bets, balance, points))
		if gathered and root != null and root.has_method("hide_goal_skulls"):
			root.call("hide_goal_skulls")
		await _await_round_intro(fx)


func _await_fight_cards_closed() -> void:
	var tutorial := get_node_or_null("/root/AxelTutorial")
	if tutorial == null or not tutorial.has_method("has_blocking_fight_card"):
		return
	tutorial.call("drop_queued_fight_lessons")
	var tree := get_tree()
	while tree != null and bool(tutorial.call("has_blocking_fight_card")):
		tutorial.call("set_playing_along", true)
		await tree.process_frame


func _await_round_intro(fx: Node) -> void:
	if fx == null or not fx.has_method("is_round_intro_playing"):
		return
	var tree := get_tree()
	var was_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	while tree != null and bool(fx.call("is_round_intro_playing")):
		var down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		var pressed := (down and not was_down) or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("dialogue_advance")
		was_down = down
		if pressed and not tree.paused:
			fx.call("skip_round_intro")
			break
		await tree.process_frame


func _show_guide_lesson() -> void:
	var tutorial := get_node_or_null("/root/AxelTutorial")
	if tutorial == null or not bool(tutorial.call("wants", GUIDE_LESSON)):
		return
	tutorial.call("request", GUIDE_LESSON)
	var tree := get_tree()
	var can_close := false
	var was_down := true
	while tree != null:
		if not bool(tutorial.call("wants", GUIDE_LESSON)) and not bool(tutorial.call("is_showing", GUIDE_LESSON)):
			break
		var down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		var pressed := (down and not was_down) or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("dialogue_advance")
		was_down = down
		if can_close and pressed and not tree.paused:
			tutorial.call("complete", GUIDE_LESSON)
		can_close = bool(tutorial.call("is_waiting")) and bool(tutorial.call("is_showing", GUIDE_LESSON))
		await tree.process_frame
	if tree != null:
		await tree.create_timer(0.2).timeout


func _fade_out_of_combat() -> void:
	var fx := get_node_or_null("/root/AxelEventFx")
	if fx != null and fx.has_method("play_round_complete_fade"):
		await fx.call("play_round_complete_fade")


func _fade_in_after_combat() -> void:
	var fx := get_node_or_null("/root/AxelEventFx")
	if fx != null and fx.has_method("finish_round_complete_fade"):
		await fx.call("finish_round_complete_fade")


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
	for fname in ResourceLoader.list_directory(ITEM_DIR):
		if fname.ends_with(".tres"):
			var path := ITEM_DIR + fname
			var res := load(path)
			if res != null:
				var item_id := String(res.get("id"))
				if not item_id.is_empty():
					_catalog[item_id] = path
