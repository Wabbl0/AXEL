extends TextureRect

const SymbolDefScript := preload("res://combat/scripts/symbol_def.gd")


func set_symbol(sym: SymbolDefScript) -> void:
	if sym != null and sym.texture != null:
		texture = sym.texture
	else:
		texture = null
