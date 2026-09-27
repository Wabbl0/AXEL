extends SceneTree

const CORRIDOR := "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"
const OTHER_ROOM := "res://scenes/Arc_1/1.4_BasementDoor.tscn"
const EXTERIOR := "res://scenes/Arc_1/1.1_SchoolExterior.tscn"
const WINDOW := Vector2i(1920, 1280)

var _failures: Array[String] = []


func _init() -> void:
	OS.set_environment("AXEL_DISABLE_MUSIC", "1")
	call_deferred("_main")


func _fail(msg: String) -> void:
	_failures.append(msg)


func _main() -> void:
	root.size = WINDOW
	await process_frame
	await _expect_texture_edge(CORRIDOR)
	await _expect_texture_edge(OTHER_ROOM)
	await _expect_texture_edge(EXTERIOR)
	if _failures.is_empty():
		print("Corridor CRT rim check OK.")
		quit(0)
		return
	for msg in _failures:
		push_error("corridor_crt_rim_check: %s" % msg)
	quit(1)


func _expect_texture_edge(scene_path: String) -> void:
	var mat: ShaderMaterial = await _crt_material(scene_path)
	if mat == null:
		return
	var bounds: Variant = mat.get_shader_parameter("texture_bounds_px")
	if bounds is Vector4:
		var box := bounds as Vector4
		if box.z - box.x < 100.0 or box.w - box.y < 100.0:
			_fail("%s texture bounds are too small: %s" % [scene_path, box])
	else:
		_fail("%s texture_bounds_px missing" % scene_path)
	_near(scene_path, "edge_start_px", _param(mat, "edge_start_px"), 3.0)
	_near(scene_path, "edge_opacity", _param(mat, "edge_opacity"), 0.8)
	_near(scene_path, "vignette", _param(mat, "vignette"), 0.0)
	_near(scene_path, "edge_fade_px", _param(mat, "edge_fade_px"), 0.0)
	_near(scene_path, "curvature", _param(mat, "curvature"), 0.0)
	_near(scene_path, "mirror_edges", _param(mat, "mirror_edges"), 0.0)


func _crt_material(scene_path: String) -> ShaderMaterial:
	if change_scene_to_file(scene_path) != OK:
		_fail("could not load %s" % scene_path)
		return
	for _i in 16:
		await process_frame
	var scene := current_scene
	if scene == null or scene.scene_file_path != scene_path:
		_fail("scene did not become %s" % scene_path)
		return
	var crt := scene.get_node_or_null("CrtPluginOverlay") as CanvasLayer
	if crt == null:
		_fail("%s is missing CrtPluginOverlay" % scene_path)
		return
	var rect := crt.get_node_or_null("FilterRect") as ColorRect
	if rect == null or not (rect.material is ShaderMaterial):
		_fail("%s CRT material missing" % scene_path)
		return
	return rect.material as ShaderMaterial


func _param(mat: ShaderMaterial, key: String) -> float:
	var value: Variant = mat.get_shader_parameter(key)
	if value == null:
		return 0.0
	return float(value)


func _near(scene_path: String, key: String, got: float, want: float) -> void:
	if not is_equal_approx(got, want):
		_fail("%s %s is %s, expected %s" % [scene_path, key, got, want])
