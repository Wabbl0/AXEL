extends SceneTree

func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var failures: Array[String] = []
	var saves := root.get_node_or_null("AxelSaves")
	var gm := root.get_node_or_null("GameManager")
	if saves == null or gm == null:
		push_error("corrupt_save_check: autoloads missing")
		quit(1)
		return

	saves.dir_override = "user://saves_qa_corrupt_tmp"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(saves.dir_override))
	for i in 3:
		saves._delete_slot_files(i)

	if not bool(saves.call("new_game", 0)):
		failures.append("new_game failed")
	saves.call("save_active_now")
	saves.call("deactivate")

	var body_path: String = saves.call("_body_path", 0)
	var file := FileAccess.open(body_path, FileAccess.WRITE)
	if file == null:
		failures.append("could not overwrite body")
	else:
		file.store_string("{not-json")
		file.close()

	var parsed: Dictionary = saves.call("_read_body", 0)
	if not parsed.is_empty():
		failures.append("corrupt JSON should return empty body")
	if bool(saves.call("load_slot", 0)):
		failures.append("load_slot must refuse a corrupt body")

	file = FileAccess.open(body_path, FileAccess.WRITE)
	if file != null:
		file.store_string("{\"version\":1}")
		file.close()
	parsed = saves.call("_read_body", 0)
	if not parsed.is_empty():
		failures.append("body missing game_state should return empty")

	if not bool(saves.call("new_game", 0)):
		failures.append("new_game after corrupt slot failed")

	for i in 3:
		saves._delete_slot_files(i)
	saves.call("deactivate")
	saves.dir_override = ""

	if failures.is_empty():
		print("Corrupt save check OK.")
		quit(0)
	else:
		for f in failures:
			push_error("corrupt_save_check: %s" % f)
		quit(1)
