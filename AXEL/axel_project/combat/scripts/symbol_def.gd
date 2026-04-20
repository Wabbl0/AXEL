class_name SymbolDef
extends Resource

enum Tier { LOW, PREMIUM, WILD, HAZARD }

@export var id: StringName
@export var display_name: String = ""
@export var tier: Tier = Tier.LOW
@export var texture: Texture2D
@export var base_weight: float = 1.0
