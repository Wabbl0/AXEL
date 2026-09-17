extends SceneTree

func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var failures: Array[String] = []
	var saves := root.get_node_or_null("AxelSaves")
	var settings := root.get_node_or_null("AxelSettings")
	var gm := root.get_node_or_null("GameManager")
	if saves == null or gm == null:
		push_error("save_slots_check: AxelSaves missing")
		quit(1)
		return

	var original_vol: float = 1.0
	if settings != null:
		original_vol = float(settings.get_value("audio", "master_volume"))
		settings.set_value("audio", "master_volume", 0.42)

	saves.dir_override = "user://saves_qa_tmp"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(saves.dir_override))
	for i in 3:
		saves._delete_slot_files(i)

	if not bool(saves.call("new_game", 0)):
		failures.append("new_game(0) failed")
	gm.call("set_flag", "hasFlashlight", true)
	gm.call("add_memory_once", "save_slots_check_mem")
	saves.call("save_active_now")
	saves.call("deactivate")

	if not bool(saves.call("new_game", 1)):
		failures.append("new_game(1) failed")
	gm.call("set_flag", "hasKey", true)
	saves.call("save_active_now")
	saves.call("deactivate")

	var h0: Dictionary = saves.call("read_header", 0)
	var h1: Dictionary = saves.call("read_header", 1)
	if int(h0.get("memories", -1)) < 1:
		failures.append("slot 0 header missing memory count")
	var items0: Array = h0.get("items", [])
	if not items0.has("Flashlight"):
		failures.append("slot 0 header missing Flashlight")
	var items1: Array = h1.get("items", [])
	if items1.has("Flashlight"):
		failures.append("slot 1 inherited slot 0 flashlight")
	if not items1.has("Key"):
		failures.append("slot 1 header missing Key")

	saves.call("write_tombstone", 0)
	if not bool(saves.call("is_dead", 0)):
		failures.append("tombstone did not mark slot 0 dead")
	if bool(saves.call("load_slot", 0)):
		failures.append("load_slot should refuse a tombstone")

	if settings != null:
		var live_vol := float(settings.get_value("audio", "master_volume"))
		if absf(live_vol - 0.42) > 0.001:
			failures.append("deleting/tombstoning a slot reset master volume")
		settings.set_value("audio", "master_volume", original_vol)

	for i in 3:
		saves._delete_slot_files(i)
	saves.call("deactivate")
	saves.dir_override = ""

	if failures.is_empty():
		print("Save slots check OK.")
		quit(0)
	else:
		for f in failures:
			push_error("save_slots_check: %s" % f)
		quit(1)
