extends MemoryStill

const LOUNGE_SCENE := "res://scenes/Arc_4/4.1_TeachersLounge.tscn"
const MEMORY_KEY := "teachers_memory"
const MEMORY_LINES := [
	"|grey|So, when did you see him last?",
	"That day during lunch. I mean I guess he was in the same classes as me.",
	"|grey|You guess?",
	"He's so - silent. I barely notice him anymore.",
]


func _init() -> void:
	dest_scene = LOUNGE_SCENE
	memory_key = MEMORY_KEY
	seen_property = "teachers_memory_line_seen"
	lines = PackedStringArray(MEMORY_LINES)
