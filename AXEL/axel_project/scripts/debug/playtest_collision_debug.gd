extends CanvasLayer
## Debug-only overlay: cyan (teal) outlines for 2D collision helpers so they read
## separately from AXEL palette (black / red / white). Visible only when
## `OS.is_debug_build()` is true.

const TOGGLE_KEY := KEY_F7

## Neon cyan/teal — intentionally outside shipped palette for readability.
@export var outline_color := Color(0.0, 0.92, 0.95, 0.95)
@export var line_width := 2.0
## Above gameplay UI (e.g. PlayerLayer 100) and typical bypass layers; below editor.
@export var debug_canvas_layer := 2000

var collision_debug_visible: bool = true

var _shape_nodes: Array[Node] = []
var _dirty: bool = true
var _draw_host: Node2D


func is_active() -> bool:
	return OS.is_debug_build() and collision_debug_visible


func get_shape_nodes() -> Array[Node]:
	return _shape_nodes


func _ready() -> void:
	if not OS.is_debug_build():
		process_mode = Node.PROCESS_MODE_DISABLED
		set_process_input(false)
		visible = false
		return

	layer = debug_canvas_layer
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_unhandled_input(true)

	_draw_host = Node2D.new()
	_draw_host.name = "PlaytestCollisionDebugDraw"
	var draw_script := load("res://scripts/debug/playtest_collision_debug_draw.gd") as Script
	_draw_host.set_script(draw_script)
	add_child(_draw_host)

	var tree := get_tree()
	tree.node_added.connect(_on_tree_topology_changed)
	tree.node_removed.connect(_on_tree_topology_changed)
	tree.scene_changed.connect(_on_scene_changed)

	_mark_dirty_deferred()


func _exit_tree() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if tree.node_added.is_connected(_on_tree_topology_changed):
		tree.node_added.disconnect(_on_tree_topology_changed)
	if tree.node_removed.is_connected(_on_tree_topology_changed):
		tree.node_removed.disconnect(_on_tree_topology_changed)
	if tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.disconnect(_on_scene_changed)


func _on_scene_changed() -> void:
	_mark_dirty_deferred()


func _on_tree_topology_changed(_what: Node) -> void:
	_mark_dirty_deferred()


func _mark_dirty_deferred() -> void:
	_dirty = true
	call_deferred("_rebuild_tracking_if_dirty")


func _process(_delta: float) -> void:
	if not OS.is_debug_build():
		return
	if _dirty:
		_rebuild_shape_cache()


func _rebuild_tracking_if_dirty() -> void:
	if _dirty:
		_rebuild_shape_cache()


func _rebuild_shape_cache() -> void:
	_dirty = false
	_shape_nodes.clear()
	var root := get_tree().root
	if root:
		_collect_collision_nodes(root)


func _collect_collision_nodes(n: Node) -> void:
	if n is CollisionShape2D or n is CollisionPolygon2D:
		_shape_nodes.append(n)
	for c in n.get_children():
		_collect_collision_nodes(c)


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode != TOGGLE_KEY:
		return
	collision_debug_visible = not collision_debug_visible
	get_viewport().set_input_as_handled()
