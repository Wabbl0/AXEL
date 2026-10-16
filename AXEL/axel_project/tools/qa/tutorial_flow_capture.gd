extends SceneTree

const SCENE_PATH := "res://combat/combat_test.tscn"
const WINDOW := Vector2i(1920, 1280)
const SHOT_DELAY_FRAMES := 150
const MAX_FRAMES := 9000

var _out_dir := "user://tutorial_flow"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):
			_out_dir = arg.substr(10)
	DisplayServer.window_set_size(WINDOW)
	root.size = WINDOW
	root.get_node("AxelProfile").call("debug_use_memory_only")
	if change_scene_to_file(SCENE_PATH) != OK:
		quit(1)
		return
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	for i in 60:
		await process_frame
	var tutorial := root.get_node("AxelTutorial")
	tutorial.call("debug_set_enabled", true)
	var seen: Array[String] = []
	var current := ""
	var shown_frames := 0
	var spins := 0
	for frame in MAX_FRAMES:
		await process_frame
		var open_id := _open_lesson(tutorial)
		if open_id != current:
			current = open_id
			shown_frames = 0
			if not open_id.is_empty():
				print("CARD ", open_id, " frozen=", tutorial.call("is_freezing"), " mult=", current_scene.combat.get_multiplier_value())
		if not open_id.is_empty():
			shown_frames += 1
			if shown_frames == SHOT_DELAY_FRAMES:
				await RenderingServer.frame_post_draw
				var img := root.get_texture().get_image()
				var path := "%s/%02d_%s.png" % [_out_dir, seen.size(), open_id]
				img.save_png(path)
				seen.append(open_id)
				print("SHOT ", path)
				tutorial.call("dismiss_open_card")
			elif shown_frames > SHOT_DELAY_FRAMES and shown_frames % 30 == 0:
				tutorial.call("dismiss_open_card")
			continue
		if seen.has("slot_history"):
			break
		var combat: Node = current_scene.combat
		if combat == null or int(combat.call("get_state")) != 0 or bool(tutorial.call("is_freezing")):
			continue
		if not seen.has("fight_spin"):
			continue
		if frame % 60 != 0:
			continue
		if spins >= 25:
			break
		spins += 1
		current_scene.call("_on_spin_pressed")
	print("SEEN ", seen)
	quit(0)


func _open_lesson(tutorial: Node) -> String:
	for slot in tutorial.get("_slots"):
		if slot.phase != 0 and slot.phase != 4:
			return String(slot.open_id)
	return ""
