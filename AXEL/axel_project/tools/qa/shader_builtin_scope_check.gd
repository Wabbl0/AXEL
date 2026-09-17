extends SceneTree

const SCAN_ROOTS := ["res://scenes", "res://tools", "res://combat", "res://scripts"]

const FORBIDDEN := [
	"SCREEN_UV",
	"SCREEN_PIXEL_SIZE",
	"FRAGCOORD",
	"UV",
	"COLOR",
	"TEXTURE",
	"TEXTURE_PIXEL_SIZE",
	"VERTEX",
	"POINT_COORD",
	"MODULATE",
	"NORMAL",
	"NORMAL_MAP",
	"NORMAL_MAP_DEPTH",
	"SPECULAR_SHININESS",
	"LIGHT",
	"LIGHT_COLOR",
	"LIGHT_ENERGY",
	"LIGHT_POSITION",
	"LIGHT_DIRECTION",
	"LIGHT_IS_DIRECTIONAL",
	"ATTENUATION",
	"SHADOW_MODULATE",
]

const PROCESSORS := ["fragment", "vertex", "light", "start", "process"]


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var fail_count := 0
	for root in SCAN_ROOTS:
		for shader_path in _list_gdshader(root):
			for hit in _scan_shader(shader_path):
				fail_count += 1
				push_error(
					"SHADER_BUILTIN_SCOPE FAIL %s: helper '%s' uses %s (pass it in from fragment/vertex)"
					% [shader_path, hit["fn"], hit["builtin"]]
				)
	if fail_count > 0:
		push_error("SHADER_BUILTIN_SCOPE FAIL count=%d" % fail_count)
		quit(1)
		return
	print("SHADER_BUILTIN_SCOPE OK")
	quit(0)


func _list_gdshader(dir_path: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var d := DirAccess.open(dir_path)
	if d == null:
		return out
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if name.begins_with("."):
			name = d.get_next()
			continue
		var full := dir_path.path_join(name)
		if d.current_is_dir():
			out.append_array(_list_gdshader(full))
		elif name.ends_with(".gdshader") or name.ends_with(".gdshaderinc"):
			out.append(full)
		name = d.get_next()
	d.list_dir_end()
	out.sort()
	return out


func _scan_shader(shader_path: String) -> Array:
	var src := FileAccess.get_file_as_string(shader_path)
	if src.is_empty():
		return []
	var hits: Array = []
	var depth := 0
	var current_fn := ""
	var in_processor := false

	var cleaned := _strip_line_comments(src)
	for line in cleaned.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.is_empty():
			continue

		var fn_name := _function_name(trimmed)
		if not fn_name.is_empty() and depth == 0:
			current_fn = fn_name
			in_processor = fn_name in PROCESSORS
		var open_count := trimmed.count("{")
		var close_count := trimmed.count("}")

		if not in_processor and not current_fn.is_empty():
			if depth > 0 or open_count > 0:
				for builtin in FORBIDDEN:
					if _token_present(trimmed, builtin):
						hits.append({"fn": current_fn, "builtin": builtin})
		depth += open_count - close_count
		if depth < 0:
			depth = 0
		if depth == 0:
			current_fn = ""
			in_processor = false
	return hits


func _strip_line_comments(src: String) -> String:
	var out := ""
	for line in src.split("\n"):
		var cut := line.find("//")
		if cut >= 0:
			out += line.substr(0, cut) + "\n"
		else:
			out += line + "\n"
	return out


func _function_name(line: String) -> String:

	if line.begins_with("#") or line.begins_with("shader_type") or line.begins_with("render_mode"):
		return ""
	if line.begins_with("uniform") or line.begins_with("varying") or line.begins_with("const"):
		return ""
	if line.begins_with("struct"):
		return ""
	var paren := line.find("(")
	if paren < 0:
		return ""

	var before := line.substr(0, paren).strip_edges()
	if before.is_empty():
		return ""
	var parts := before.split(" ", false)
	if parts.is_empty():
		return ""
	var name: String = parts[parts.size() - 1]

	if name.contains("=") or name.contains(".") or name.contains("["):
		return ""

	if not _is_identifier(name):
		return ""
	return name


func _is_identifier(s: String) -> bool:
	if s.is_empty():
		return false
	var c0 := s.unicode_at(0)
	if not ((c0 >= 65 and c0 <= 90) or (c0 >= 97 and c0 <= 122) or c0 == 95):
		return false
	for i in range(1, s.length()):
		var c := s.unicode_at(i)
		if not (
			(c >= 65 and c <= 90)
			or (c >= 97 and c <= 122)
			or (c >= 48 and c <= 57)
			or c == 95
		):
			return false
	return true


func _token_present(line: String, token: String) -> bool:
	var i := 0
	while true:
		var at := line.find(token, i)
		if at < 0:
			return false
		var before_ok := at == 0 or not _is_ident_char(line.unicode_at(at - 1))
		var after_idx := at + token.length()
		var after_ok := after_idx >= line.length() or not _is_ident_char(line.unicode_at(after_idx))
		if before_ok and after_ok:
			return true
		i = at + 1
	return false


func _is_ident_char(c: int) -> bool:
	return (
		(c >= 65 and c <= 90)
		or (c >= 97 and c <= 122)
		or (c >= 48 and c <= 57)
		or c == 95
	)
