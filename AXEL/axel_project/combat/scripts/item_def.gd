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

const FILE_PX := 1024
const COMBAT_RES_PX := 120


static func texture_at_res(src: Texture2D, px: int) -> Texture2D:
	if src == null or px <= 0:
		return src
	if src.get_width() == px and src.get_height() == px:
		return src
	var img := src.get_image()
	if img == null:
		var path := src.resource_path
		if path.is_empty():
			return src
		img = Image.new()
		if img.load(ProjectSettings.globalize_path(path)) != OK:
			return src
	if img.is_compressed() and img.decompress() != OK:
		return src
	img = img.duplicate()
	if img.get_width() != px or img.get_height() != px:
		img.resize(px, px, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)
