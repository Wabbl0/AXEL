class_name CurseDef
extends Resource

@export var id: StringName
@export var name: String = ""
@export_multiline var description: String = ""
@export var effect_id: StringName
@export var params: Dictionary = {}


func merged_params(overrides: Dictionary) -> Dictionary:
	var out := params.duplicate(true)
	for key in overrides.keys():
		out[key] = overrides[key]
	return out


func describe(overrides: Dictionary = {}) -> String:
	var p := merged_params(overrides)
	var text := description
	for key in p.keys():
		text = text.replace("{%s}" % str(key), str(p[key]))
	return text
