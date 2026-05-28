extends Camera2D

@export var target_path: NodePath
@export var fixed_x: float = 640.0
@export var vertical_smoothing: float = 5.0

var _target: Node2D


func _ready() -> void:
	if not target_path.is_empty():
		_target = get_node_or_null(target_path)
	make_current()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var target_y := _target.global_position.y
	var next_y := lerpf(global_position.y, target_y, 1.0 - exp(-vertical_smoothing * delta))
	global_position.x = fixed_x
	global_position.y = clampf(next_y, limit_top, limit_bottom)
