extends Control

var _backdrop: TextureRect
var _time := 0.0


func _ready() -> void:
	_backdrop = MenuLook.make_backdrop(self)
	var chrome := MenuLook.make_chrome_layer(self)
	var panel := OptionsPanel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.closed.connect(func() -> void: MenuLook.go(get_tree(), MenuLook.TITLE_SCENE))
	chrome.add_child(panel)


func _process(delta: float) -> void:
	_time += delta
	MenuLook.drift_backdrop(_backdrop, _time)
