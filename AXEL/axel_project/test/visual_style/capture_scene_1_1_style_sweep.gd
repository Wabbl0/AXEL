extends SceneTree
## Scene 1.1 visual style sweep: baseline + 3 scanline/glitch comparison options.
##
## Run from repo root:
##   tools\cmd\godot.cmd --path AXEL/axel_project -s res://test/visual_style/capture_scene_1_1_style_sweep.gd
##
## Optional env:
##   AXEL_STYLE_VARIANT=baseline   (single variant; default = all)
##   AXEL_STYLE_THEME=axel|green|white  (override theme_mode for option shaders)
##   AXEL_STYLE_OUTPUT=user://style_sweep_1_1  (override output dir)
##
## Exit 0 when all requested PNGs are written; 1 on failure.

const _INTRO_WAIT_SEC := 0.15
const _WALK_FRAMES := 120
const _SETTLE_FRAMES := 6
const _RENDER_WARMUP_FRAMES := 4

var _scene_path: String = VisualStyleVariantMatrix.SCENE_PATH
var _output_dir := ""


func _init() -> void:
	OS.set_environment("AXEL_SKIP_INTRO", "1")
	OS.set_environment("AXEL_DISABLE_POST_FX", "1")
	_output_dir = _resolve_output_dir()
	_ensure_output_dir()
	call_deferred("_main")


func _resolve_output_dir() -> String:
	if OS.has_environment("AXEL_STYLE_OUTPUT") and not OS.get_environment("AXEL_STYLE_OUTPUT").is_empty():
		return OS.get_environment("AXEL_STYLE_OUTPUT")
	return VisualStyleVariantMatrix.OUTPUT_DIR


func _ensure_output_dir() -> void:
	var abs_path := ProjectSettings.globalize_path(_output_dir)
	DirAccess.make_dir_recursive_absolute(abs_path)


func _main() -> void:
	var only_id := ""
	if OS.has_environment("AXEL_STYLE_VARIANT"):
		only_id = OS.get_environment("AXEL_STYLE_VARIANT").strip_edges()

	var specs: Array[Dictionary] = []
	for v in VisualStyleVariantMatrix.VARIANTS:
		if only_id.is_empty() or String(v["id"]) == only_id:
			specs.append(v)

	if specs.is_empty():
		push_error("No variants matched filter '%s'." % only_id)
		quit(1)
		return

	var failures: Array[String] = []
	for spec in specs:
		var ok: bool = await _capture_one(spec)
		if not ok:
			failures.append(String(spec["id"]))

	if failures.is_empty():
		print("Style sweep OK: %d captures -> %s" % [specs.size(), ProjectSettings.globalize_path(_output_dir)])
		_print_manifest()
		quit(0)
	else:
		push_error("Style sweep FAILED variants: %s" % ", ".join(failures))
		quit(1)


func _capture_one(spec: Dictionary) -> bool:
	var variant_id := String(spec["id"])
	print("--- Capturing variant: %s (%s) ---" % [variant_id, spec["label"]])

	var err := change_scene_to_file(_scene_path)
	if err != OK:
		push_error("change_scene_to_file failed (%d) for %s" % [err, _scene_path])
		return false

	for _i in 4:
		await process_frame

	if current_scene == null:
		push_error("current_scene null after load.")
		return false

	_hide_dialogue_for_capture()
	var applier := StyleOverlayApplier.new(current_scene)
	applier.apply_variant(spec)

	await create_timer(_INTRO_WAIT_SEC).timeout

	var driver := InputEventDriver.new(self, false)
	var runner := BotScenarioRunner.new(self, driver, false)
	var commands: Array = [
		{"op": "hold", "key": KEY_D, "frames": _WALK_FRAMES},
		{"op": "wait_frames", "frames": _SETTLE_FRAMES},
	]
	var movement_ok: bool = await runner.run(commands)
	driver.release_all()
	if not movement_ok:
		push_error("Movement failed for %s: %s" % [variant_id, runner.failure_summary()])
		return false

	for _i in _RENDER_WARMUP_FRAMES:
		await process_frame

	var png_name := String(spec["png"])
	var out_path := "%s/%s" % [_output_dir, png_name]
	if not _save_viewport_png(out_path):
		push_error("PNG save failed: %s" % out_path)
		return false

	print("Wrote %s" % ProjectSettings.globalize_path(out_path))
	return true


func _hide_dialogue_for_capture() -> void:
	var dlg := current_scene.get_node_or_null("TopDialogueOverlay")
	if dlg == null:
		return
	if dlg.has_method("hide_line"):
		dlg.hide_line()
	dlg.visible = false


func _save_viewport_png(user_path: String) -> bool:
	var vp := root.get_viewport()
	if vp == null:
		return false
	var tex := vp.get_texture()
	if tex == null:
		return false
	var img := tex.get_image()
	if img == null or img.is_empty():
		return false
	var err := img.save_png(user_path)
	return err == OK


func _print_manifest() -> void:
	var theme_override := ""
	if OS.has_environment("AXEL_STYLE_THEME"):
		theme_override = OS.get_environment("AXEL_STYLE_THEME")
	var payload := {
		"scene": _scene_path,
		"output_dir": ProjectSettings.globalize_path(_output_dir),
		"viewport": Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")
		),
		"walk_frames": _WALK_FRAMES,
		"variants": VisualStyleVariantMatrix.variant_ids(),
		"theme_override": theme_override,
	}
	print("STYLE_SWEEP_MANIFEST %s" % JSON.stringify(payload))
