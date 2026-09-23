extends SceneTree


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	root.size = Vector2i(1920, 1280)
	await process_frame
	var failures: Array[String] = []
	var host := Node2D.new()
	root.add_child(host)
	var grid := Control.new()
	grid.name = "GridUI"
	host.add_child(grid)
	var feel_script = load("res://combat/scripts/combat_feel.gd")
	var feel = feel_script.new()
	feel.name = "CombatFeel"
	host.add_child(feel)
	feel.setup(host, grid)
	var presses := {"retry": 0}
	feel.show_game_over_menu(
		func() -> void: presses["retry"] = int(presses["retry"]) + 1,
		func() -> void: pass,
		func() -> void: pass,
	)
	await process_frame
	var menu := host.find_child("GameOverMenu", true, false) as VBoxContainer
	if menu == null:
		failures.append("GameOverMenu missing")
	elif menu.visible:
		failures.append("loss buttons were visible before the wait")
	await create_timer(4.2).timeout
	if menu != null and not menu.visible:
		failures.append("loss buttons did not appear after 3 seconds")
	var captions: Array[String] = []
	if menu != null:
		for child in menu.get_children():
			if child is Button:
				captions.append((child as Button).text)
	if captions.size() != 3 or captions[0] != "Retry" or captions[1] != "Return To Main Menu" or captions[2] != "Exit":
		failures.append("loss buttons were %s" % [captions])
	if int(presses["retry"]) != 0:
		failures.append("Retry was pressed by the reveal itself")
	var banner := host.find_child("FeelBanner", true, false) as Label
	if banner == null or (banner.text != "GONE" and banner.text != "IT TAKES YOU"):
		var shown := "" if banner == null else banner.text
		failures.append("loss line was '%s'" % shown)
	if failures.is_empty():
		print("Loss menu check OK.")
		quit(0)
	else:
		for f in failures:
			push_error("loss_menu_check: %s" % f)
		quit(1)
