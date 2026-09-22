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
const RARITY_GLYPHS: PackedStringArray = ["◇", "◈", "◆", "★", "✦"]


static func rarity_glyph(item: Resource) -> String:
	if item == null:
		return ""
	return rarity_glyph_index(int(item.get("rarity")))


static func rarity_glyph_index(rarity_index: int) -> String:
	if rarity_index < 0 or rarity_index >= RARITY_GLYPHS.size():
		return ""
	return RARITY_GLYPHS[rarity_index]


static func rarity_name(item: Resource) -> String:
	var base := ""
	if item != null:
		base = str(item.get("display_name")).strip_edges()
		if base.is_empty():
			base = str(item.get("id"))
	var glyph := rarity_glyph(item)
	if glyph.is_empty():
		return base
	if base.is_empty():
		return glyph
	return "%s %s" % [glyph, base]


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
