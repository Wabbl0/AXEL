extends Node

func _ready() -> void:
	#region agent log
	var file := FileAccess.open("C:/Users/valtt/OneDrive/Godot/debug-7980eb.log", FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open("C:/Users/valtt/OneDrive/Godot/debug-7980eb.log", FileAccess.WRITE_READ)
	if file != null:
		file.seek_end()
		file.store_line(JSON.stringify({
			"sessionId": "7980eb",
			"runId": "run1",
			"hypothesisId": "H5",
			"location": "ScriptReloadMarker.gd:_ready",
			"message": "Autoload script marker ready",
			"data": {"node_type": get_class()},
			"timestamp": Time.get_unix_time_from_system() * 1000
		}))
		file.close()
	#endregion
	print("[ScriptReloadMarker] Script loaded successfully.")
