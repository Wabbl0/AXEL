class_name ItemInventory
extends RefCounted

const BASE_MAX_SLOTS := 7
const SLOT_BONUS_EFFECT_ID := &"extra_inventory_slots"
const LEGENDARY_RARITY_INT := 4

var items: Array = []
var ignore_slot_cap: bool = false


func get_base_max_slots() -> int:
	return BASE_MAX_SLOTS


func get_current_max_slots() -> int:
	return BASE_MAX_SLOTS + _compute_bonus_slots(items)


func equip(item: Resource) -> bool:
	if item == null:
		return false
	var new_id = item.get("id")
	if new_id != null:
		for existing in items:
			if existing.get("id") == new_id:
				return false
	if not ignore_slot_cap:
		var projected_max := BASE_MAX_SLOTS + _compute_bonus_slots(items) + _item_slot_bonus(item)
		if items.size() + 1 > projected_max:
			return false
	items.append(item)
	return true


func replace_at(index: int, new_item: Resource) -> bool:
	if new_item == null:
		return false
	if index < 0 or index >= items.size():
		return false
	var new_id = new_item.get("id")
	if new_id != null:
		for i in items.size():
			if i == index:
				continue
			if items[i].get("id") == new_id:
				return false
	if not ignore_slot_cap:
		var without: Array = []
		for i in items.size():
			if i != index:
				without.append(items[i])
		var projected_max := BASE_MAX_SLOTS + _compute_bonus_slots(without) + _item_slot_bonus(new_item)
		if without.size() + 1 > projected_max:
			return false
	items[index] = new_item
	return true


func unequip(item: Resource) -> void:
	if item == null:
		return
	var target_id = item.get("id")
	for i in items.size():
		if items[i].get("id") == target_id:
			items.remove_at(i)
			return


func clear() -> void:
	items.clear()


func set_all(new_items: Array) -> void:
	items.clear()
	for item in new_items:
		if item != null:
			equip(item)


func size() -> int:
	return items.size()


func has_item(item_id: StringName) -> bool:
	return index_of(item_id) >= 0


func index_of(item_id: StringName) -> int:
	for i in items.size():
		if items[i].get("id") == item_id:
			return i
	return -1


func _compute_bonus_slots(item_list: Array) -> int:
	var bonus := 0
	for item in item_list:
		bonus += _item_slot_bonus(item)
	return bonus


func _item_slot_bonus(item: Resource) -> int:
	if item == null:
		return 0
	var eff_id = item.get("effect_id")
	var rarity = item.get("rarity")
	if eff_id != SLOT_BONUS_EFFECT_ID or rarity != LEGENDARY_RARITY_INT:
		return 0
	var params = item.get("effect_params")
	if params == null:
		return 0
	return int(params.get("bonus_slots", 0))
