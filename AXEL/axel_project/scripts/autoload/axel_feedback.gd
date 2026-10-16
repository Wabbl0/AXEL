extends Node

signal form_closed()
signal send_finished(id: String, ok: bool)

const FormScript := preload("res://scenes/ui/feedback_form.gd")
const ENDPOINT_URL := "https://script.google.com/macros/s/AKfycby93Qvga4IkN_WYedTIjAU8r5XhRe4VUcInvpdnHvCqIqs2M91S97rI1qGAdjKJrXF_/exec"
const TOKEN := "axel-feedback-7q2k"
const OUTBOX_DIR := "user://feedback_outbox"
const TITLE_SCENE := "res://scenes/Main_Menu/0.1_MainMenu.tscn"
const PAUSE_MENU_PATH := "/root/AxelPause/AxelPauseMenu"
const BAR_LAYER := 255
const FORM_LAYER := 260
const BAR_HEIGHT := 46.0
const BAR_FONT := 30
const BAR_GAP := 160.0
const SCROLL_SPEED := 90.0
const SEND_TIMEOUT_SEC := 20.0
const FLUSH_DELAY_SEC := 4.0
const AGE_MIN := 10
const AGE_MAX := 110

var outbox_dir := OUTBOX_DIR
var endpoint_override := ""
var network_enabled := true

var _bar_layer: CanvasLayer
var _bar: Control
var _bar_bg: ColorRect
var _bar_line: ColorRect
var _bar_labels: Array[Label] = []
var _scroll_x := 0.0
var _hover := false
var _form: CanvasLayer = null
var _http: HTTPRequest
var _queue: Array[String] = []
var _sending_path := ""
var _sending_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var env := OS.get_environment("AXEL_FEEDBACK_URL")
	if env != "":
		endpoint_override = env
	if DisplayServer.get_name() == "headless":
		network_enabled = false
	_build_bar()
	_http = HTTPRequest.new()
	_http.name = "FeedbackHttp"
	_http.timeout = SEND_TIMEOUT_SEC
	if not OS.has_feature("web"):
		_http.max_redirects = 0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	get_viewport().size_changed.connect(_layout_bar)
	_layout_bar()
	if can_send():
		get_tree().create_timer(FLUSH_DELAY_SEC, true).timeout.connect(flush_outbox)


func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "dev"))


func endpoint() -> String:
	return endpoint_override if endpoint_override != "" else ENDPOINT_URL


func can_send() -> bool:
	return network_enabled and endpoint() != ""


func ui_k(node: Node) -> float:
	if PortraitUi.is_portrait(node):
		return PortraitUi.width_factor(node) * 1.6
	return UiViewportScale.factor(node)


func bar_text() -> String:
	return ">> PLAYTESTERS: TELL ME WHAT YOU THINK OF AXEL v%s  -  CLICK HERE TO GIVE FEEDBACK <<" % version()


func bar_height() -> float:
	if _bar_layer == null or not _bar_layer.visible:
		return 0.0
	return _bar.size.y


func bar_reserve(node: Node) -> float:
	return roundf(BAR_HEIGHT * ui_k(node))


func is_bar_visible() -> bool:
	return _bar_layer != null and _bar_layer.visible


func is_form_open() -> bool:
	return _form != null and is_instance_valid(_form)


func should_show_bar() -> bool:
	if is_form_open():
		return false
	var tree := get_tree()
	if tree == null:
		return false
	var scene := tree.current_scene
	if scene != null and scene.scene_file_path == TITLE_SCENE:
		return true
	var menu := get_node_or_null(PAUSE_MENU_PATH)
	if menu != null and menu.visible:
		return not (menu.has_method("is_submenu_open") and bool(menu.call("is_submenu_open")))
	return _loss_buttons_up()


func _loss_buttons_up() -> bool:
	var run := get_node_or_null("/root/AxelRun")
	if run == null or not run.has_method("is_game_over_menu_open"):
		return false
	if not bool(run.call("is_game_over_menu_open")):
		return false
	var feel: Node = run.call("_live_feel") if run.has_method("_live_feel") else null
	if feel == null or not feel.has_method("is_loss_presentation"):
		return false
	return not bool(feel.call("is_loss_presentation"))


func _process(delta: float) -> void:
	var want := should_show_bar()
	if _bar_layer.visible != want:
		_bar_layer.visible = want
		if want:
			_layout_bar()
	if want:
		_scroll_bar(delta)


func _build_bar() -> void:
	_bar_layer = CanvasLayer.new()
	_bar_layer.name = "FeedbackBarLayer"
	_bar_layer.layer = BAR_LAYER
	_bar_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_bar_layer.visible = false
	add_child(_bar_layer)
	_bar = Control.new()
	_bar.name = "FeedbackBar"
	_bar.clip_contents = true
	_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_bar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_bar.tooltip_text = ""
	_bar_layer.add_child(_bar)
	_bar_bg = ColorRect.new()
	_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bar.add_child(_bar_bg)
	_bar_line = ColorRect.new()
	_bar_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_line.color = MenuLook.DIM
	_bar.add_child(_bar_line)
	_bar.gui_input.connect(_on_bar_input)
	_bar.mouse_entered.connect(func() -> void: _set_hover(true))
	_bar.mouse_exited.connect(func() -> void: _set_hover(false))
	_set_hover(false)


func _set_hover(on: bool) -> void:
	_hover = on
	_bar_bg.color = Color(0.12, 0.0, 0.0, 0.7) if on else Color(0.0, 0.0, 0.0, 0.55)
	for label in _bar_labels:
		label.add_theme_color_override("font_color", MenuLook.ACCENT if on else MenuLook.TEXT)


func _layout_bar() -> void:
	if _bar == null:
		return
	var k := ui_k(_bar)
	var view := PortraitUi.view_size(_bar)
	var bottom := view.y
	if PortraitUi.is_portrait(_bar):
		bottom = PortraitUi.safe_rect(_bar).end.y
	var h := roundf(BAR_HEIGHT * k)
	_bar.position = Vector2(0.0, bottom - h)
	_bar.size = Vector2(view.x, h)
	_bar_line.position = Vector2.ZERO
	_bar_line.size = Vector2(view.x, maxf(2.0, roundf(2.0 * k)))
	var text := bar_text()
	var font_px := maxi(roundi(BAR_FONT * k), 12)
	var probe_w := MenuLook.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x
	var span := probe_w + BAR_GAP * k
	var need := int(ceil(view.x / maxf(span, 1.0))) + 1
	while _bar_labels.size() < need:
		var extra := Label.new()
		extra.mouse_filter = Control.MOUSE_FILTER_IGNORE
		extra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_bar.add_child(extra)
		_bar_labels.append(extra)
	_set_hover(_hover)
	for label in _bar_labels:
		label.text = text
		label.add_theme_font_override("font", MenuLook.FONT)
		label.add_theme_font_size_override("font_size", font_px)
		label.size = Vector2(label.get_minimum_size().x, h)
		label.position.y = 0.0
	_place_labels()


func _scroll_bar(delta: float) -> void:
	if _bar_labels.is_empty():
		return
	var k := ui_k(_bar)
	var span := _bar_labels[0].size.x + BAR_GAP * k
	if span <= 0.0:
		return
	_scroll_x = fposmod(_scroll_x + delta * SCROLL_SPEED * k, span)
	_place_labels()


func _place_labels() -> void:
	if _bar_labels.is_empty():
		return
	var k := ui_k(_bar)
	var span := _bar_labels[0].size.x + BAR_GAP * k
	for i in _bar_labels.size():
		_bar_labels[i].position.x = roundf(span * float(i) - _scroll_x)


func _on_bar_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if pressed:
		_bar.accept_event()
		open_form()


func open_form() -> Node:
	if is_form_open():
		return _form
	_form = FormScript.new()
	_form.name = "FeedbackForm"
	_form.layer = FORM_LAYER
	add_child(_form)
	_form.closed.connect(_on_form_closed)
	var sfx := get_node_or_null("/root/AxelSfx")
	if sfx != null and sfx.has_method("play_pause_open"):
		sfx.call("play_pause_open")
	return _form


func close_form() -> void:
	if is_form_open():
		_form.call("close")


func _on_form_closed() -> void:
	_form = null
	form_closed.emit()


func validate(answers: Dictionary) -> String:
	if str(answers.get("overall", "")) == "":
		return "Please pick an overall score (question 1)."
	var word := str(answers.get("one_word", "")).strip_edges()
	if word.contains(" "):
		return "Please use only one word to describe AXEL."
	var age := str(answers.get("age", "")).strip_edges()
	if age != "":
		if not age.is_valid_int() or int(age) < AGE_MIN or int(age) > AGE_MAX:
			return "Age must be a number from %d to %d, or left empty." % [AGE_MIN, AGE_MAX]
	return ""


func build_payload(answers: Dictionary, include_game_data: bool) -> Dictionary:
	var clean := {}
	for key in answers.keys():
		clean[str(key)] = str(answers[key]).strip_edges()
	return {
		"token": TOKEN,
		"id": _new_id(),
		"sent_unix": int(Time.get_unix_time_from_system()),
		"version": version(),
		"platform": _platform_name(),
		"debug": OS.is_debug_build(),
		"locale": OS.get_locale(),
		"answers": clean,
		"game_data": game_snapshot() if include_game_data else {},
	}


func game_snapshot() -> Dictionary:
	var data := {}
	var run := get_node_or_null("/root/AxelRun")
	if run != null:
		var st = run.get("state")
		if st != null:
			data["run_seed"] = int(st.seed)
			data["balance"] = int(st.bankroll_cents)
			data["fights_won"] = int(st.world_fight_count)
			data["owned_items"] = Array(st.owned_item_ids).duplicate()
			data["equipped_items"] = Array(st.equipped_item_ids).duplicate()
			data["tickets"] = int(st.tickets)
			data["tickets_bought"] = int(st.tickets_bought)
			data["travel_uses"] = int(st.travel_uses)
			data["in_fight"] = bool(st.in_encounter)
		if run.has_method("dread_pct"):
			data["dread_pct"] = float(run.call("dread_pct"))
		var spin_log = run.get("feedback_log")
		if spin_log != null:
			var snap: Dictionary = spin_log.call("snapshot")
			data["fights"] = snap.get("fights", [])
			data["spins"] = snap.get("spins", [])
	var gm := get_node_or_null("/root/GameManager")
	if gm != null:
		var gs = gm.get("game_state")
		if gs is Dictionary:
			data["memories"] = int((gs as Dictionary).get("memories", 0))
			data["flags"] = (gs as Dictionary).get("flags", {}).duplicate(true)
		var visited = gm.get("visited_rooms")
		if visited is Dictionary:
			data["visited_rooms"] = (visited as Dictionary).keys()
	var saves := get_node_or_null("/root/AxelSaves")
	if saves != null and saves.has_method("get_playtime_sec"):
		data["playtime_min"] = snappedf(float(saves.call("get_playtime_sec")) / 60.0, 0.1)
	var scene := get_tree().current_scene if get_tree() != null else null
	data["scene"] = scene.scene_file_path if scene != null else ""
	return data


func submit(answers: Dictionary, include_game_data: bool) -> Dictionary:
	var err := validate(answers)
	if err != "":
		return {"ok": false, "error": err}
	var payload := build_payload(answers, include_game_data)
	var path := _write_outbox(payload)
	if path == "":
		return {"ok": false, "error": "Could not save your feedback."}
	if not can_send():
		return {"ok": true, "id": payload["id"], "queued": true}
	flush_outbox()
	return {"ok": true, "id": payload["id"], "queued": false}


func outbox_files() -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(outbox_dir)
	if dir == null:
		return out
	for file in dir.get_files():
		if file.ends_with(".json"):
			out.append(outbox_dir.path_join(file))
	out.sort()
	return out


func flush_outbox() -> void:
	if not can_send():
		return
	for path in outbox_files():
		_enqueue(path)


func _write_outbox(payload: Dictionary) -> String:
	DirAccess.make_dir_recursive_absolute(outbox_dir)
	var path := outbox_dir.path_join("%d_%s.json" % [int(payload["sent_unix"]), str(payload["id"])])
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(payload))
	f.close()
	return path


func _enqueue(path: String) -> void:
	if path == _sending_path or _queue.has(path):
		return
	_queue.append(path)
	_send_next()


func _send_next() -> void:
	if _sending_path != "" or _queue.is_empty():
		return
	var path: String = _queue.pop_front()
	if not FileAccess.file_exists(path):
		_send_next()
		return
	var body := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(body)
	if not (parsed is Dictionary):
		DirAccess.remove_absolute(path)
		_send_next()
		return
	_sending_path = path
	_sending_id = str((parsed as Dictionary).get("id", ""))
	var headers := PackedStringArray(["Content-Type: text/plain;charset=utf-8"])
	var err := _http.request(endpoint(), headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_finish_send(false)


func _on_request_completed(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var ok := result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 400
	_finish_send(ok)


func _finish_send(ok: bool) -> void:
	var id := _sending_id
	if ok and _sending_path != "":
		DirAccess.remove_absolute(_sending_path)
	_sending_path = ""
	_sending_id = ""
	send_finished.emit(id, ok)
	if ok:
		_send_next()
	else:
		_queue.clear()


func _new_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return "%08x%08x" % [rng.randi(), rng.randi()]


func _platform_name() -> String:
	var os_name := OS.get_name()
	if OS.has_feature("web"):
		if OS.has_feature("web_android"):
			return "Web (Android)"
		if OS.has_feature("web_ios"):
			return "Web (iOS)"
		return "Web"
	return os_name
