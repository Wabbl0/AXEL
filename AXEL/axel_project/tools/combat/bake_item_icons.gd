extends SceneTree

const OUT_DIR := "res://combat/art/item_icons"
const MAP_PATH := "res://tools/combat/item_icon_sources.json"
const SIZE := 48

const REDS: Array[Color] = [
	Color(0.90, 0.0, 0.0),
	Color(0.70, 0.0, 0.0),
	Color(0.50, 0.0, 0.0),
	Color(0.30, 0.0, 0.0),
]
const GREYS: Array[Color] = [
	Color(0.18, 0.02, 0.02),
	Color(0.08, 0.01, 0.01),
]
const BLACKS: Array[Color] = [
	Color(0.02, 0.0, 0.0),
	Color(0.0, 0.0, 0.0),
]
const WHITE := Color(1, 1, 1, 1)

var _interiors_root: String = ""
var _exteriors_root: String = ""
var _map: Dictionary = {}


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_interiors_root = args[0].strip_edges().trim_suffix("/").trim_suffix("\\")
	if args.size() >= 2:
		_exteriors_root = args[1].strip_edges().trim_suffix("/").trim_suffix("\\")
	_map = _load_map()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var ids := _item_ids()
	var baked := 0
	var from_source := 0
	for item_id in ids:
		var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		_fill_placeholder(img, item_id)
		var src_path := _source_for(item_id)
		if src_path != "" and FileAccess.file_exists(src_path):
			var loaded := Image.new()
			if loaded.load(src_path) == OK:
				img = _crop_pad_remap(loaded)
				from_source += 1
		var out_path := "%s/%s.png" % [OUT_DIR, item_id]
		img.save_png(out_path)
		baked += 1
	print(
		"BAKE_ITEM_ICONS wrote=%d from_source=%d interiors=%s exteriors=%s"
		% [baked, from_source, _interiors_root, _exteriors_root]
	)
	quit(0)


func _load_map() -> Dictionary:
	if not FileAccess.file_exists(MAP_PATH):
		return {}
	var f := FileAccess.open(MAP_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func _source_for(item_id: String) -> String:
	if not _map.has(item_id):
		return ""
	var rel := str(_map[item_id]).strip_edges().replace("\\", "/")
	if rel.begins_with("interiors/"):
		if _interiors_root == "":
			return ""
		return _interiors_root.path_join(rel.substr("interiors/".length()))
	if rel.begins_with("exteriors/"):
		if _exteriors_root == "":
			return ""
		return _exteriors_root.path_join(rel.substr("exteriors/".length()))

	if _interiors_root != "":
		var cand := _interiors_root.path_join(rel)
		if FileAccess.file_exists(cand):
			return cand
	if _exteriors_root != "":
		return _exteriors_root.path_join(rel)
	return ""


func _fill_placeholder(img: Image, item_id: String) -> void:
	var h := absi(item_id.hash())
	var stroke := REDS[h % REDS.size()]
	var fill := GREYS[h % GREYS.size()]
	for y in SIZE:
		for x in SIZE:
			var c := BLACKS[1]
			if x < 2 or y < 2 or x >= SIZE - 2 or y >= SIZE - 2:
				c = stroke
			elif x >= 10 and x < 38 and y >= 10 and y < 38:
				if ((x * 7 + y * 13 + h) % 11) < 4:
					c = stroke
				else:
					c = fill
			if x == 5 and (y == 5 or y == 6):
				c = WHITE
			img.set_pixel(x, y, c)


func _crop_pad_remap(src: Image) -> Image:
	src.convert(Image.FORMAT_RGBA8)
	var min_x := src.get_width()
	var min_y := src.get_height()
	var max_x := -1
	var max_y := -1
	for y in src.get_height():
		for x in src.get_width():
			if src.get_pixel(x, y).a < 0.15:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x:
		return src
	var cw := max_x - min_x + 1
	var ch := max_y - min_y + 1
	var cropped := src.get_region(Rect2i(min_x, min_y, cw, ch))
	var scale: float = float(SIZE) / float(maxi(cw, ch))
	var nw := maxi(1, int(round(float(cw) * scale)))
	var nh := maxi(1, int(round(float(ch) * scale)))
	cropped.resize(nw, nh, Image.INTERPOLATE_NEAREST)
	var out := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	@warning_ignore("integer_division")
	var ox := int((SIZE - nw) / 2)
	@warning_ignore("integer_division")
	var oy := int((SIZE - nh) / 2)
	out.blit_rect(cropped, Rect2i(0, 0, nw, nh), Vector2i(ox, oy))
	for y in SIZE:
		for x in SIZE:
			var px := out.get_pixel(x, y)
			if px.a < 0.15:
				out.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			out.set_pixel(x, y, _remap_noir(px))
	return out


func _remap_noir(px: Color) -> Color:
	if px.r > 0.92 and px.g > 0.92 and px.b > 0.92:
		return WHITE
	var lum := px.r * 0.299 + px.g * 0.587 + px.b * 0.114
	if lum < 0.125:
		return REDS[0]
	if lum < 0.25:
		return REDS[1]
	if lum < 0.375:
		return REDS[2]
	if lum < 0.5:
		return REDS[3]
	if lum < 0.625:
		return GREYS[0]
	if lum < 0.75:
		return GREYS[1]
	if lum < 0.875:
		return BLACKS[0]
	return BLACKS[1]


func _item_ids() -> PackedStringArray:
	return PackedStringArray([
		"C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9", "C10",
		"U1", "U2", "U3", "U4", "U5", "U6", "U7", "U8",
		"R1", "R2", "R3", "R4", "R5", "R6",
		"E1", "E2", "E3", "E4",
		"L1", "L2", "L3",
		"C-A", "U-A", "R-A", "E-A",
		"C-B", "U-B", "R-B", "E-B", "L-B",
		"C-C", "U-C", "R-C", "E-C", "L-C",
		"C-D", "U-D", "R-D", "E-D", "L-D",
		"C-E", "U-E", "R-E", "E-E", "L-E",
		"C-F", "U-F", "R-F", "E-F", "L-F",
		"C-M", "U-M", "R-M", "E-M", "L-M",
		"C-G", "U-G", "R-G", "E-G", "L-G",
		"C-H", "U-H", "R-H", "E-H", "L-H",
	])
