# Floor items: one E takes one item

**Note:** Three items close together were all taken.

**Cause:** Every pickup checked E on its own, using a 220 px circle. After the first take, the fight takes a moment to start, and each further E press took another item that was still in range.

**Fix (shipped):** `world_item_pickup.gd` lets only the nearest in-range pickup (among its siblings, measured from Mike) answer `interact`. No pickup answers while `AxelWorld.is_fight_starting()` is true. The walk-near card always shows the nearest item, which is the one E will take.

**Check:** `tools/qa/world_item_pickup_nearest_check.gd`.
