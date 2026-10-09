extends CanvasLayer

const LAYER_INDEX := 106
const TERMINAL_THEME := preload("res://combat/ui/terminal_theme.tres")

var _root: Control
var _pairs: Array[Dictionary] = []


func _ready() -> void:
	layer = LAYER_INDEX
	_ensure_root()
	if _root != null and not _root.resized.is_connected(_sync_all):
		_root.resized.connect(_sync_all)
	set_process(true)


func _ensure_root() -> void:
	_root = get_node_or_null("WidgetRoot") as Control
	if _root == null:
		_root = Control.new()
		_root.name = "WidgetRoot"
		add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_root.theme = TERMINAL_THEME


func get_widget_root() -> Control:
	_ensure_root()
	return _root


func register(box: Control, id: String, existing_host: Control = null) -> Control:
	if box == null:
		return null
	_ensure_root()
	for pair in _pairs:
		if str(pair.get("id", "")) == id and is_instance_valid(pair.get("host")):
			pair["box"] = box
			_sync_one(pair)
			return pair["host"] as Control
	var host := existing_host
	if host == null:
		host = Control.new()
		host.name = "Host_%s" % id
		_root.add_child(host)
	elif host.get_parent() != _root:
		host.reparent(_root)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.clip_contents = true
	var pair := {
		"id": id,
		"box": box,
		"host": host,
		"gp": Vector2.INF,
		"sc": Vector2.INF,
		"sz": Vector2.INF,
	}
	_pairs.append(pair)
	_sync_one(pair)
	return host


func sync_now() -> void:
	_sync_all()


func _process(_delta: float) -> void:
	_sync_all()


func _sync_all() -> void:
	for pair in _pairs:
		_sync_one(pair)


func _sync_one(pair: Dictionary) -> void:
	var box := pair.get("box") as Control
	var host := pair.get("host") as Control
	if box == null or host == null:
		return
	if not is_instance_valid(box) or not is_instance_valid(host):
		return
	if not box.is_inside_tree() or not host.is_inside_tree():
		return
	var gp := box.global_position
	var sc := box.get_global_transform().get_scale()
	var sz := box.size
	if pair.get("gp") == gp and pair.get("sc") == sc and pair.get("sz") == sz:
		return
	pair["gp"] = gp
	pair["sc"] = sc
	pair["sz"] = sz
	host.global_position = gp
	host.scale = sc
	host.size = sz


func release_for(piece: Node) -> Array[Control]:
	var out: Array[Control] = []
	if piece == null:
		return out
	var i := _pairs.size() - 1
	while i >= 0:
		var box := _pairs[i].get("box") as Control
		var host := _pairs[i].get("host") as Control
		if is_instance_valid(box) and is_instance_valid(host) and (box == piece or piece.is_ancestor_of(box)):
			out.append(host)
			_pairs.remove_at(i)
		i -= 1
	return out
