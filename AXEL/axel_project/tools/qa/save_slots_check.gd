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

	if not bool(saves.call("delete_slot", 1)):
		failures.append("delete_slot(1) failed")
	if not bool(saves.call("is_empty", 1)):
		failures.append("delete_slot(1) did not empty the slot")
	if bool(saves.call("delete_slot", 1)):
		failures.append("delete_slot should refuse an empty slot")

	saves.call("write_tombstone", 0)
	if not bool(saves.call("is_dead", 0)):
		failures.append("tombstone did not mark slot 0 dead")
	if bool(saves.call("load_slot", 0)):
		failures.append("load_slot should refuse a tombstone")
	if not bool(saves.call("delete_slot", 0)):
		failures.append("delete_slot(0) tombstone failed")
	if not bool(saves.call("is_empty", 0)):
		failures.append("delete_slot did not clear tombstone")
	if bool(saves.call("is_dead", 0)):
		failures.append("deleted tombstone still reads as dead")

	if settings != null:
		var live_vol := float(settings.get_value("audio", "master_volume"))
		if absf(live_vol - 0.42) > 0.001:
			failures.append("deleting/tombstoning a slot reset master volume")
		settings.set_value("audio", "master_volume", original_vol)

	if not bool(saves.call("new_game", 0)):
		failures.append("new_game(0) for load-delete UI failed")
	saves.call("deactivate")
	var saves_script := load("res://scenes/Main_Menu/Saves.gd")
	if saves_script == null:
		failures.append("could not load Saves.gd")
	else:
		saves_script.open_mode = "load"
		var packed := load("res://scenes/Main_Menu/Saves.tscn") as PackedScene
		if packed == null:
			failures.append("could not load Saves.tscn")
		else:
			var screen := packed.instantiate() as Control
			root.add_child(screen)
			if not screen.is_node_ready():
				await screen.ready
			for _i in 4:
				await process_frame
			var bg_layer := screen.find_child("MenuBackdropLayer", true, false) as CanvasLayer
			if bg_layer == null or bg_layer.layer != 100:
				failures.append("title backdrop not on layer 100")
			var bg := screen.find_child("MenuBackdrop", true, false) as TextureRect
			if bg == null or bg.texture == null:
				failures.append("title backdrop missing texture")
			var host := screen.find_child("SavesHost", true, false) as Control
			var del := screen.find_child("DeleteSlot1", true, false) as Button
			if host == null or del == null:
				failures.append("load saves UI missing host or Delete")
			else:
				if not host.get_global_rect().encloses(del.get_global_rect()):
					failures.append("Delete button sits outside SavesHost")
				if del.disabled:
					failures.append("Delete on occupied slot was disabled")
				del.pressed.emit()
				await process_frame
				var status := screen.find_child("SavesStatus", true, false) as Label
				if status == null or status.text != "Press again to delete this slot.":
					failures.append("delete confirm status missing")
				elif status.get_visible_line_count() < 1:
					failures.append("delete confirm status has no visible line")
				elif status.get_character_bounds(0).size == Vector2.ZERO:
					failures.append("delete confirm status empty character bounds")
				del.pressed.emit()
				for _j in 4:
					await process_frame
				if not bool(saves.call("is_empty", 0)):
					failures.append("UI delete did not empty slot 0")
				status = screen.find_child("SavesStatus", true, false) as Label
				if status == null or status.text != "Slot deleted.":
					failures.append("slot deleted status missing")
				elif status.get_visible_line_count() < 1:
					failures.append("slot deleted status has no visible line")
			screen.queue_free()
			await process_frame
			saves_script.open_mode = "new"
			var new_screen := packed.instantiate() as Control
			root.add_child(new_screen)
			if not new_screen.is_node_ready():
				await new_screen.ready
			await process_frame
			if new_screen.find_child("DeleteSlot1", true, false) != null:
				failures.append("New Game showed a Delete button")
			new_screen.queue_free()
			await process_frame
			saves_script.open_mode = "load"

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
