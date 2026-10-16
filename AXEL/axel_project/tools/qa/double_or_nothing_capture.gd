extends SceneTree

const SCENE_PATH := "res://combat/combat_test.tscn"
const WINDOW := Vector2i(1920, 1280)
const MAX_SPINS := 60

var _out_dir := "user://double_or_nothing"
var _pick: StringName = &"bloody_hand"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):
			_out_dir = arg.substr(10)
		elif arg.begins_with("--pick="):
			_pick = StringName(arg.substr(7))
	DisplayServer.window_set_size(WINDOW)
	root.size = WINDOW
	root.get_node("AxelProfile").call("debug_use_memory_only")
	var tutorial := root.get_node("AxelTutorial")
	var marked: Dictionary = tutorial.get("_marked")
	for id in tutorial.LESSONS.keys():
		marked[String(id)] = true
	if change_scene_to_file(SCENE_PATH) != OK:
		quit(1)
		return
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	for i in 60:
		await process_frame
	var ui: Node = current_scene
	var combat: CombatRoot = ui.combat
	combat.set_goal_base_target_cents(1000000)
	var spins := 0
	while not combat.has_gamble_offer() and spins < MAX_SPINS:
		await process_frame
		if combat.get_state() != CombatRoot.State.IDLE or bool(ui.get("_spin_busy")):
			continue
		spins += 1
		await ui.call("_request_spin")
	if not combat.has_gamble_offer():
		print("NO OFFER after ", spins, " spins")
		quit(1)
		return
	await _wait(1.5)
	await _shot("01_offer_chip")
	ui.call("_on_gamble_chip_pressed")
	var dn: Control = ui.get("_gamble_ui")
	await _wait(0.5)
	dn.call("_update_hover", dn.call("_choice_center", 1))
	await _wait(0.5)
	await _shot("02_choice")
	dn.picked.emit(_pick)
	await _wait(1.2)
	await _shot("03_belt_moving")
	for i in 400:
		await _wait(0.02)
		if int(dn.get("_mode")) == 3:
			break
	await _wait(0.4)
	await _shot("04_result")
	await _wait(2.0)
	await _shot("05_after")
	print("DONE pot=", combat.get_gamble_pot(), " offer=", combat.has_gamble_offer())
	quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := "%s/%s.png" % [_out_dir, name]
	img.save_png(path)
	print("SHOT ", ProjectSettings.globalize_path(path))


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
