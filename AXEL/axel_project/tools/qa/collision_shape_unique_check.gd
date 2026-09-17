extends SceneTree

const SCAN_ROOT := "res://scenes"
const ALLOWED_SHARED_SHAPE := "res://scenes/player/hitbox_front.tres"


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	var fail_count := 0
	for scene_path in _list_tscn(SCAN_ROOT):
		var pairs := _shared_shape_pairs(scene_path)
		for pair in pairs:
			fail_count += 1
			push_error(
				"COLLISION_SHAPE_UNIQUE FAIL %s: %s and %s share %s"
				% [scene_path, pair["a"], pair["b"], pair["shape"]]
			)
	if fail_count > 0:
		push_error("COLLISION_SHAPE_UNIQUE FAIL count=%d" % fail_count)
		quit(1)
		return
	print("COLLISION_SHAPE_UNIQUE OK")
	quit(0)


func _list_tscn(dir_path: String) -> PackedStringArray:
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
			out.append_array(_list_tscn(full))
		elif name.ends_with(".tscn"):
			out.append(full)
		name = d.get_next()
	d.list_dir_end()
	out.sort()
	return out


func _shared_shape_pairs(scene_path: String) -> Array:
	var src := FileAccess.get_file_as_string(scene_path)
	if src.is_empty():
		return []
	var ext_paths: Dictionary = {}
	var uses: Dictionary = {}
	var node_label := ""
	var is_collision_shape := false
	for line in src.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("[ext_resource") and trimmed.contains("type=\"Shape2D\""):
			var res_id := _header_field(trimmed, "id")
			var res_path := _header_field(trimmed, "path")
			if not res_id.is_empty() and not res_path.is_empty():
				ext_paths[res_id] = res_path
			continue
		if trimmed.begins_with("[node "):
			var node_name := _header_field(trimmed, "name")
			var node_type := _header_field(trimmed, "type")
			var parent := _header_field(trimmed, "parent")
			is_collision_shape = node_type == "CollisionShape2D"
			if parent.is_empty():
				node_label = node_name
			else:
				node_label = "%s/%s" % [parent, node_name]
			continue
		if not is_collision_shape or not trimmed.begins_with("shape = "):
			continue
		var key := _shape_share_key(trimmed, ext_paths)
		if key.is_empty():
			continue
		if not uses.has(key):
			uses[key] = PackedStringArray()
		var labels: PackedStringArray = uses[key]
		labels.append(node_label)
		uses[key] = labels

	var pairs: Array = []
	for key in uses.keys():
		var labels: PackedStringArray = uses[key]
		if labels.size() < 2:
			continue
		pairs.append({
			"shape": key,
			"a": labels[0],
			"b": labels[1],
		})
	return pairs


func _shape_share_key(shape_line: String, ext_paths: Dictionary) -> String:
	var sub_id := _wrapped_id(shape_line, "SubResource")
	if not sub_id.is_empty():
		return "SubResource(%s)" % sub_id
	var ext_id := _wrapped_id(shape_line, "ExtResource")
	if ext_id.is_empty():
		return ""
	var res_path := str(ext_paths.get(ext_id, ""))
	if res_path == ALLOWED_SHARED_SHAPE:
		return ""
	if res_path.is_empty():
		return "ExtResource(%s)" % ext_id
	return res_path


func _wrapped_id(line: String, wrapper: String) -> String:
	var token := wrapper + "(\""
	var i := line.find(token)
	if i < 0:
		return ""
	var start := i + token.length()
	var end := line.find("\"", start)
	if end < 0:
		return ""
	return line.substr(start, end - start)


func _header_field(header: String, key: String) -> String:
	var token := key + "=\""
	var i := header.find(token)
	if i < 0:
		return ""
	var start := i + token.length()
	var end := header.find("\"", start)
	if end < 0:
		return ""
	return header.substr(start, end - start)
