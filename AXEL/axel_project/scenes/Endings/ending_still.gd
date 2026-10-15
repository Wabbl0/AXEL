extends Control

@export var ending_id: String = ""

const FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
const TITLE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const EPILOGUE := "res://scenes/Endings/7.6_Epilogue.tscn"

var _busy := false


func _ready() -> void:
	var fill := ColorRect.new()
	fill.color = Color(1, 1, 1, 1)
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fill)
	var stamp := Label.new()
	stamp.text = "GREY-BOX  ·  %s" % ending_id
	stamp.add_theme_font_override("font", FONT)
	stamp.add_theme_font_size_override("font_size", 28)
	stamp.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	stamp.position = Vector2(32, 28)
	add_child(stamp)
	var overlay := load("res://scenes/ui/TopDialogueOverlay.tscn") as PackedScene
	var dialogue: Node = overlay.instantiate() if overlay != null else null
	if dialogue != null:
		add_child(dialogue)
	call_deferred("_play", dialogue)


func _play(dialogue: Node) -> void:
	var lines := _lines()
	if dialogue != null and dialogue.has_method("show_lines"):
		await dialogue.show_lines(lines)
	_leave()


func _leave() -> void:
	if _busy:
		return
	_busy = true
	if ending_id == "7.5":
		get_tree().change_scene_to_file(EPILOGUE)
		return
	var saves := get_node_or_null("/root/AxelSaves")
	if _can_start_again(saves):
		saves.call("begin_new_game_and_enter", int(saves.get("active_slot")))
		return
	if saves != null and saves.has_method("deactivate"):
		saves.call("deactivate")
	get_tree().change_scene_to_file(TITLE)


func _can_start_again(saves: Node) -> bool:
	if saves == null or not saves.has_method("begin_new_game_and_enter"):
		return false
	if not bool(saves.call("is_active")):
		return false
	return not bool(saves.call("is_play_scene_session"))


func _lines() -> Array:
	match ending_id:
		"7.2":
			return [
				"The shadows consume you.",
				"You lose your footing.",
				"Is this how it ends?",
				"Really?",
				"I mean...",
				"Your fault for thinking you could see where you're stepping in pitch-black.",
				"If only you had a FLASHLIGHT.",
				"You know the tool that lights up dark places.",
				"Maybe it's in the kitchen. I don't know.",
				"Your dumb.",
			]
		"7.3":
			return ["His eyes won't return yours.", "It's not complete."]
		"7.4":
			return [
				"You hear sirens.",
				"Then see the red and blue lights.",
				"What comes around, goes around.",
			]
		"7.5":
			return [
				"Maybe it wasn't ALL your fault.",
				"Maybe I was too harsh.",
				"Okay.",
				"I'll say it.",
				"Ugh.",
				"I'm sorry.",
			]
		"7.6":
			return [
				"I should quit.",
				"|other|Yeah, don't want to end like me before your time",
				"It was a really bad joke, but you still laugh.",
				"Just like old times.",
			]
		_:
			return ["It's over."]
