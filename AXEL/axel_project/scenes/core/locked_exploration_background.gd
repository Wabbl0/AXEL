@tool
extends Sprite2D
## Keeps exploration background sprites locked in the 2D editor so accidental drags
## do not nudge cover-fit art. Attach to WalkableWorld/Background (or legacy BG nodes).

const _EDIT_LOCK_META := "_edit_lock_"


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return
	BackgroundLayout.ensure_editor_locked(self)
