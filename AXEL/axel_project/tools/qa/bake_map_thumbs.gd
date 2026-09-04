extends SceneTree
## Downscale room drawings to 512×360 map thumbs (Phase 5 texture budget).

const OUT_DIR := "res://assets/map_thumbs/"
const THUMBS := {
	"exterior": "res://exports/Drawings/1.1_SchoolExterior.png",
	"corridor": "res://exports/Drawings/1.2_Corridor.png",
	"door": "res://exports/Drawings/1.4_BasementDoor.png",
	"cafeteria": "res://exports/Drawings/2.1_Cafeteria.png",
	"kitchen": "res://exports/Drawings/2.3_Kitchen.png",
	"class_hall": "res://exports/Drawings/2.4_ClassroomsCorridor.png",
	"classroom": "res://exports/Drawings/5.1_Classroom.png",
	"backyard": "res://exports/Drawings/3.1_Backyard.png",
	"lounge": "res://exports/Drawings/4.1_TeachersLounge.png",
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var written := 0
	for room_id in THUMBS.keys():
		var src := String(THUMBS[room_id])
		var abs_src := ProjectSettings.globalize_path(src)
		var img := Image.new()
		if img.load(abs_src) != OK:
			push_warning("bake_map_thumbs: skip missing %s" % src)
			continue
		img.resize(512, 360, Image.INTERPOLATE_LANCZOS)
		var dest := ProjectSettings.globalize_path("%s%s.png" % [OUT_DIR, room_id])
		img.save_png(dest)
		written += 1
	print("bake_map_thumbs wrote %d thumbs" % written)
	quit(0 if written > 0 else 1)
