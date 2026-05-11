class_name ItemInventory
extends RefCounted

const BASE_MAX_SLOTS := 7
const SLOT_BONUS_EFFECT_ID := &"extra_inventory_slots"
const LEGENDARY_RARITY_INT := 4

## Direct access for iteration; use equip()/unequip() to enforce constraints.
var items: Array = []


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
	var projected_max := BASE_MAX_SLOTS + _compute_bonus_slots(items) + _item_slot_bonus(item)
	if items.size() + 1 > projected_max:
		return false
	items.append(item)
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
	for item in items:
		if item.get("id") == item_id:
			return true
	return false


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
