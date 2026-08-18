class_name ItemDef
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var id: StringName = &""
@export var display_name: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var family: String = ""
@export var description: String = ""
@export var effect_id: StringName = &""
@export var effect_params: Dictionary = {}
@export var icon: Texture2D
