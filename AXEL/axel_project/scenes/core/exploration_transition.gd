extends RefCounted
class_name ExplorationTransition


static func go(
	host: Node,
	scene_path: String,
	prompt: Node = null,
	dialogue: Node = null,
	interrupt_dialogue: bool = true,
) -> bool:
	if scene_path.is_empty() or host == null:
		return false
	var tree := host.get_tree()
	if tree == null:
		return false
	if is_instance_valid(prompt) and prompt.has_method("hide_prompt_immediate"):
		prompt.call("hide_prompt_immediate")
	if (
		interrupt_dialogue
		and is_instance_valid(dialogue)
		and dialogue.has_method("interrupt_line")
	):
		dialogue.call("interrupt_line")
	var err := tree.change_scene_to_file(scene_path)
	if err == OK:
		return true
	push_error("Failed to change scene to %s (error %d)." % [scene_path, err])
	if is_instance_valid(AxelPostFxStack):
		AxelPostFxStack.apply_to_scene(tree.current_scene)
	return false
