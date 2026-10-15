extends SceneTree

const ITEMS_DIR := "res://combat/data/items"
const TUTORIAL := preload("res://scripts/autoload/axel_tutorial.gd")
const BANNED := [
	["(?i)\\bpictures?\\b", "picture (say symbol)"],
	["(?i)\\bboards?\\b", "board (say grid)"],
	["SKULL step", "SKULL step (say Skull Meter step)"],
	["SKULL [Mm]eter", "SKULL meter (say Skull Meter)"],
	["(?i)skull meter", ""],
	["(?i)\\btiles?\\b", "tile (say symbol or cell)"],
	["(?i)\\bshapes?\\b", "shapes (say Normal symbols)"],
	["(?i)\\bbooze\\b", "booze (say alcohol)"],
	["(?i)\\btrinity\\b", "Trinity (say Vice)"],
	["(?i)super free spins", "SUPER Free Spins (say Free Spins)"],
	["(?i)vice round free spins", "Vice Round called Free Spins"],
]

var _failures: Array[String] = []
var _patterns: Array = []


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	for entry in BANNED:
		var re := RegEx.new()
		re.compile(String(entry[0]))
		_patterns.append([re, String(entry[1]), String(entry[0])])
	var items := 0
	for file in DirAccess.get_files_at(ITEMS_DIR):
		if not file.ends_with(".tres"):
			continue
		var item := load(ITEMS_DIR.path_join(file)) as Resource
		if item == null:
			continue
		items += 1
		_scan("item %s" % file.get_basename(), str(item.get("description")))
	if items < 75:
		_failures.append("expected 75 items, found %d" % items)
	for id in TUTORIAL.LESSONS.keys():
		_scan("tutorial %s" % id, String(TUTORIAL.LESSONS[id].get("body", "")))
		_scan("tutorial touch %s" % id, String(TUTORIAL.LESSONS[id].get("touch_body", "")))
	for page in GuidePages.PAGES:
		for block in page.get("blocks", []):
			if (block as Dictionary).has("text"):
				_scan("guide %s" % String(page.get("title", "")), String(block["text"]))
	if _failures.is_empty():
		print("Item wording check OK (%d items)." % items)
		quit(0)
		return
	for msg in _failures:
		push_error("item_wording_check: %s" % msg)
	quit(1)


func _scan(where: String, text: String) -> void:
	for p in _patterns:
		var re: RegEx = p[0]
		var label: String = p[1]
		if label.is_empty():
			if text.findn("skull meter") >= 0 and text.find("Skull Meter") < 0:
				_failures.append("%s: write Skull Meter with capitals" % where)
			continue
		var hit := re.search(text)
		if hit != null:
			_failures.append("%s: %s in \"%s\"" % [where, label, text.left(80)])
