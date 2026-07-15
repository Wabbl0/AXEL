extends Node
## Legacy per-scene window sizer — now inert.
##
## Window size and aspect are handled project-wide (Keep aspect, 1920x1280 = 3:2)
## in project.godot. This node no longer forces the OS window per scene, so the
## window is free to be any resolution while gameplay stays 3:2 (auto-letterboxed).
##
## Exports and the node are kept only so existing 1.1 / 1.2 scenes still load
## without edits. They have no runtime effect.

@export var design_viewport: Vector2i = Vector2i(1920, 1280)
@export var debug_scale: float = 1.0
