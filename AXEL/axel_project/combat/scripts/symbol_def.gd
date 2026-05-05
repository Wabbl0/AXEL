class_name SymbolDef
extends Resource

enum Tier { LOW, PREMIUM, WILD, HAZARD }

@export var id: StringName
@export var display_name: String = ""
@export var tier: Tier = Tier.LOW
@export var texture: Texture2D
@export var power_intro_texture: Texture2D
@export var base_weight: float = 1.0
@export var princess_id: StringName = &""
@export var payout_x3: float = 0.0
@export var payout_x4: float = 0.0
@export var payout_x5: float = 0.0


func payout_multiplier_for_length(length: int) -> float:
	match length:
		3:
			return payout_x3
		4:
			return payout_x4
		5:
			return payout_x5
		_:
			return 0.0


func texture_for_power_intro() -> Texture2D:
	if power_intro_texture != null:
		return power_intro_texture
	return texture
