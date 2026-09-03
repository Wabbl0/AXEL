extends Node
## Legacy per-scene window sizer — now inert.
##
## Window size and aspect are handled project-wide in project.godot.
## Stretch is disabled, so this node no longer forces the OS window per scene and
## the game uses the real viewport pixels of the Game tab / OS window.
##
## Exports and the node are kept only so existing 1.1 / 1.2 scenes still load
## without edits. They have no runtime effect.

@export var design_viewport: Vector2i = Vector2i(1920, 1280)
@export var debug_scale: float = 1.0
