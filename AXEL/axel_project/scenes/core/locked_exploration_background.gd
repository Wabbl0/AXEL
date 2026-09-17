@tool
extends Sprite2D

const _EDIT_LOCK_META := "_edit_lock_"


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return
	BackgroundLayout.ensure_editor_locked(self)
