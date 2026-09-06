extends Control

const LOCKER_HUB_SCENE := "res://scenes/Arc_1/1.3_LockerHub.tscn"

const DESTINATIONS: Array[Dictionary] = [
	{"label": "Go to the cafeteria", "path": "res://scenes/Arc_2/2.1_Cafeteria.tscn"},
	{"label": "Go to the kitchen", "path": "res://scenes/Arc_2/2.3_Kitchen.tscn"},
	{"label": "Go to the classroom", "path": "res://scenes/Arc_5/5.1_Classroom.tscn"},
	{"label": "Go to the classrooms corridor", "path": "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn"},
	{"label": "Go to the backyard", "path": "res://scenes/Arc_3/3.1_Backyard.tscn"},
	{"label": "Go to the teacher's lounge", "path": "res://scenes/Arc_4/4.1_TeachersLounge.tscn"},
]

const _UI_FONT := preload("res://combat/ui/fonts/VT323-Regular.ttf")
## Authored (1920x1280) chrome sizes; _apply_chrome_scale multiplies by the
## live UiViewportScale factor so 4K does not shrink the travel list.
const _BUTTON_MIN_SIZE := Vector2(320.0, 42.0)
const _BUTTON_FONT_BASE := 22
const _PANEL_OFFSETS_BASE := Vector4(24.0, -460.0, 400.0, -24.0)
const _PANEL_SEPARATION_BASE := 10.0

@onready var _choices_panel: VBoxContainer = $UiLayer/ChoicesPanel
@onready var _exit_button: Button = $UiLayer/ExitButton

var _is_transitioning := false


var _orbit: Node3D
var _yaw := 0.35
var _pitch := -0.45
var _drag := false
var _last_mouse := Vector2.ZERO
var _pick_camera: Camera3D
var _room_bodies: Dictionary = {}
var _diorama_host: SubViewportContainer
var _diorama_vp: SubViewport


func _ready() -> void:
	_exit_button.pressed.connect(_on_exit_pressed)
	set_process_input(true)
	_build_diorama()
	_build_destination_buttons()
	_apply_chrome_scale()
	get_viewport().size_changed.connect(_apply_chrome_scale)


func _process(_delta: float) -> void:
	if _orbit != null:
		_orbit.rotation = Vector3(_pitch, _yaw, 0.0)


func _build_destination_buttons() -> void:
	for child in _choices_panel.get_children():
		child.queue_free()
	for destination in DESTINATIONS:
		var button := Button.new()
		button.custom_minimum_size = _BUTTON_MIN_SIZE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_override("font", _UI_FONT)
		var scene_path: String = destination["path"]
		# The map only travels to rooms you have actually walked in.
		if ResourceLoader.exists(scene_path) and _is_unlocked(scene_path):
			button.text = destination["label"]
			button.pressed.connect(func() -> void:
				_go_to_scene(scene_path)
			)
		else:
			button.text = "?????"
			button.disabled = true
			button.modulate = Color(0.35, 0.35, 0.35, 1.0)
		_choices_panel.add_child(button)

	var basement := Button.new()
	var basement_open := GameManager.get_flag("hasKey")
	basement.text = "ENTER THE BASEMENT" if basement_open else "BASEMENT (LOCKED)"
	basement.custom_minimum_size = _BUTTON_MIN_SIZE
	basement.alignment = HORIZONTAL_ALIGNMENT_LEFT
	basement.add_theme_font_override("font", _UI_FONT)
	basement.disabled = not basement_open
	basement.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	basement.add_theme_color_override("font_disabled_color", Color(0.55, 0, 0, 1))
	if basement_open:
		basement.pressed.connect(func() -> void:
			_go_to_scene("res://scenes/Arc_6/6.1_BasementDoor.tscn")
		)
	_choices_panel.add_child(basement)


## A room card / travel button works only after the player walked there once.
func _is_unlocked(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.has_method("has_visited"):
		return true
	return bool(gm.call("has_visited", scene_path))


func _apply_chrome_scale() -> void:
	var f := UiViewportScale.factor(self)
	UiViewportScale.apply_exit_button(_exit_button, f)
	_choices_panel.offset_left = _PANEL_OFFSETS_BASE.x * f
	_choices_panel.offset_top = _PANEL_OFFSETS_BASE.y * f
	_choices_panel.offset_right = _PANEL_OFFSETS_BASE.z * f
	_choices_panel.offset_bottom = _PANEL_OFFSETS_BASE.w * f
	_choices_panel.add_theme_constant_override("separation", roundi(_PANEL_SEPARATION_BASE * f))
	for child in _choices_panel.get_children():
		var button := child as Button
		if button == null:
			continue
		button.custom_minimum_size = _BUTTON_MIN_SIZE * f
		button.add_theme_font_size_override("font_size", roundi(_BUTTON_FONT_BASE * f))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_drag = mouse.pressed
			_last_mouse = mouse.position
			if not mouse.pressed:
				_try_pick_room(mouse.position)
	elif event is InputEventMouseMotion and _drag:
		var motion := event as InputEventMouseMotion
		_yaw += motion.relative.x * 0.005
		_pitch = clampf(_pitch + motion.relative.y * 0.005, -1.1, -0.15)
	if not _is_exit_key(event):
		return
	get_viewport().set_input_as_handled()
	_on_exit_pressed()


func _build_diorama() -> void:
	var host := SubViewportContainer.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.stretch = true
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)
	move_child(host, 1)
	_diorama_host = host
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.handle_input_locally = false
	vp.size = _diorama_size()
	host.add_child(vp)
	_diorama_vp = vp
	var world := Node3D.new()
	vp.add_child(world)
	_orbit = Node3D.new()
	world.add_child(_orbit)
	_pick_camera = Camera3D.new()
	_pick_camera.position = Vector3(0, 7.5, 11)
	_orbit.add_child(_pick_camera)
	_pick_camera.look_at(Vector3(0, 0, 0))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	world.add_child(light)
	var rooms := [
		{"id": "exterior", "pos": Vector3(-6.4, 0, 3.4), "tex": "res://exports/Drawings/1.1_SchoolExterior.png", "path": "res://scenes/Arc_1/1.1_SchoolExterior.tscn", "size": Vector2(2.2, 1.5)},
		{"id": "corridor", "pos": Vector3(-3.2, 0, 3.4), "tex": "res://exports/Drawings/1.2_Corridor.png", "path": "res://scenes/Arc_1/1.2_Corridor.tscn", "size": Vector2(2.2, 1.5)},
		{"id": "door", "pos": Vector3(0.0, 0, 3.4), "tex": "res://exports/Drawings/1.4_BasementDoor.png", "path": "res://scenes/Arc_1/1.4_BasementDoor.tscn", "size": Vector2(2.2, 1.5)},
		{"id": "cafeteria", "pos": Vector3(-3.2, 0, 1.2), "tex": "res://exports/Drawings/2.1_Cafeteria.png", "path": "res://scenes/Arc_2/2.1_Cafeteria.tscn"},
		{"id": "kitchen", "pos": Vector3(-6.0, 0, 1.2), "tex": "res://exports/Drawings/2.3_Kitchen.png", "path": "res://scenes/Arc_2/2.3_Kitchen.tscn", "size": Vector2(2.0, 1.4)},
		{"id": "class_hall", "pos": Vector3(0.4, 0, 1.2), "tex": "res://exports/Drawings/2.4_ClassroomsCorridor.png", "path": "res://scenes/Arc_2/2.4_ClassroomsCorridor.tscn", "size": Vector2(2.0, 1.4)},
		{"id": "classroom", "pos": Vector3(3.2, 0, 1.2), "tex": "res://exports/Drawings/5.1_Classroom.png", "path": "res://scenes/Arc_5/5.1_Classroom.tscn"},
		{"id": "backyard", "pos": Vector3(-3.2, 0, -2.8), "tex": "res://exports/Drawings/3.1_Backyard.png", "path": "res://scenes/Arc_3/3.1_Backyard.tscn"},
		{"id": "lounge", "pos": Vector3(3.2, 0, -2.8), "tex": "res://exports/Drawings/4.1_TeachersLounge.png", "path": "res://scenes/Arc_4/4.1_TeachersLounge.tscn"},
		{"id": "basement", "pos": Vector3(0, -1.6, 0), "tex": "", "path": "res://scenes/Arc_6/6.1_BasementDoor.tscn", "locked": true},
	]
	_add_corridor(world, Vector3(-3.2, -0.7, 2.3), Vector3(6.4, 0.12, 0.35))
	_add_corridor(world, Vector3(-1.4, -0.7, 0.0), Vector3(8.8, 0.12, 0.35))
	_add_corridor(world, Vector3(0.0, -0.9, -0.8), Vector3(0.35, 0.12, 2.4))
	for room in rooms:
		world.add_child(_make_room_card(room))


func _diorama_size() -> Vector2i:
	var settings := get_node_or_null("/root/AxelSettings")
	if settings != null and settings.has_method("diorama_size"):
		return settings.call("diorama_size") as Vector2i
	return Vector2i(1920, 1280)


func _add_corridor(world: Node3D, pos: Vector3, box_size: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = box_size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.12, 0.12, 0.12, 1)
	mesh.material_override = mat
	mesh.position = pos
	world.add_child(mesh)


func _make_room_card(room: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = String(room.get("id", "room"))
	root.position = room.get("pos", Vector3.ZERO)
	var card_size: Vector2 = room.get("size", Vector2(2.8, 2.0))
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = card_size
	mesh.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var tex_path := String(room.get("tex", ""))
	var room_path := String(room.get("path", ""))
	var is_locked_basement := bool(room.get("locked", false))
	# Unvisited rooms stay blank on the map: you can see the shape, not the room.
	var thumb: Texture2D = null
	if not is_locked_basement and _is_unlocked(room_path):
		thumb = _thumb(String(room.get("id", "")), tex_path)
	if thumb != null:
		mat.albedo_texture = thumb
	else:
		mat.albedo_color = Color(0.09, 0.09, 0.09, 1)
	if is_locked_basement and not GameManager.get_flag("hasKey"):
		mat.albedo_color = Color(0.08, 0.08, 0.08, 1)
	mesh.material_override = mat
	root.add_child(mesh)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(card_size.x, card_size.y, 0.08)
	col.shape = box
	body.add_child(col)
	root.add_child(body)
	_room_bodies[body.get_instance_id()] = room
	return root


func _thumb(room_id: String, path: String) -> Texture2D:
	var baked := "res://assets/map_thumbs/%s.png" % room_id
	if ResourceLoader.exists(baked):
		return load(baked) as Texture2D
	if path.is_empty():
		return null
	var abs_path := ProjectSettings.globalize_path(path)
	var img := Image.new()
	if img.load(abs_path) != OK:
		if not ResourceLoader.exists(path):
			return null
		var tex := load(path) as Texture2D
		if tex == null:
			return null
		img = tex.get_image()
		if img == null:
			return tex
	img.resize(512, 360, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _try_pick_room(screen: Vector2) -> void:
	if _pick_camera == null:
		return
	var vp_pos := screen
	if _diorama_host != null and _diorama_vp != null:
		var host_rect := _diorama_host.get_global_rect()
		if host_rect.size.x > 1.0 and host_rect.size.y > 1.0:
			var local := screen - host_rect.position
			vp_pos = Vector2(
				local.x / host_rect.size.x * float(_diorama_vp.size.x),
				local.y / host_rect.size.y * float(_diorama_vp.size.y)
			)
	var from := _pick_camera.project_ray_origin(vp_pos)
	var dir := _pick_camera.project_ray_normal(vp_pos)
	var space := _pick_camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 80.0)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider == null:
		return
	var room: Dictionary = _room_bodies.get(collider.get_instance_id(), {})
	if room.is_empty():
		return
	if bool(room.get("locked", false)):
		if not GameManager.get_flag("hasKey"):
			return
		_go_to_scene(String(room.get("path", "")))
		return
	var room_path := String(room.get("path", ""))
	if not _is_unlocked(room_path):
		return
	_go_to_scene(room_path)


func _is_exit_key(event: InputEvent) -> bool:
	# Named InputMap action (Esc/Backspace/Delete + gamepad B). Excludes echo presses.
	return event.is_action_pressed("back")


func _on_exit_pressed() -> void:
	var dest := LOCKER_HUB_SCENE
	if not GameManager.pause_map_return_path.is_empty():
		dest = GameManager.pause_map_return_path
		GameManager.pause_map_return_path = ""
	_go_to_scene(dest)


func _go_to_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene to %s (error %d)." % [scene_path, err])
		_is_transitioning = false
		if is_instance_valid(AxelPostFxStack):
			AxelPostFxStack.apply_to_scene(get_tree().current_scene)
