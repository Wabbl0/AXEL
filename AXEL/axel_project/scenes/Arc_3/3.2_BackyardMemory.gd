extends MemoryStill

const BACKYARD_SCENE := "res://scenes/Arc_3/3.1_Backyard.tscn"
const MEMORY_KEY := "backyard_memory"
const MEMORY_LINES := [
	"|other|Oh. Sorry. I'll go.",
	"No. I don't mind.",
	"Haven't seen you in school for awhile.",
	"|other|Didn't think you'd notice.",
	"What does that mean?",
	"|other|Nothing.",
	"|other|Are we still friends?",
]


func _init() -> void:
	dest_scene = BACKYARD_SCENE
	memory_key = MEMORY_KEY
	seen_property = "backyard_memory_line_seen"
	lines = PackedStringArray(MEMORY_LINES)
