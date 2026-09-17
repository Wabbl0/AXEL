extends MemoryStill

const CAFETERIA_SCENE := "res://scenes/Arc_2/2.1_Cafeteria.tscn"
const MEMORY_KEY := "cafeteria_memory"
const MEMORY_LINES := [
	"|other|Do you think I'm a bad person?",
	"No.",
	"I just |beat:1.5| don't have the energy. To be around you.",
	"Sorry.",
	"|other|Oh.",
	"|other|No. I understand.",
]


func _init() -> void:
	dest_scene = CAFETERIA_SCENE
	memory_key = MEMORY_KEY
	seen_property = "cafeteria_memory_line_seen"
	lines = PackedStringArray(MEMORY_LINES)
