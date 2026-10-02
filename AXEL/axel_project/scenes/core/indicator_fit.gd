extends RefCounted
class_name IndicatorFit

const MEMORY_REF_PLAYER := 0.298
const MEMORY_REF_SCALE := 2.25
const ITEM_REF_PLAYER := 0.198
const ITEM_REF_BASELINE := 0.352
const ITEM_REF_MARKER_PX := 180.0


static func memory_from_player(player_scale: float) -> float:
	if player_scale <= 0.0:
		return 0.0
	return snappedf(MEMORY_REF_SCALE * (player_scale / MEMORY_REF_PLAYER), 0.001)


static func item_marker_px(player_scale: float, baseline: float) -> float:
	if player_scale <= 0.0 or baseline <= 0.0:
		return 0.0
	var px := ITEM_REF_MARKER_PX * (ITEM_REF_BASELINE / ITEM_REF_PLAYER) * (player_scale / baseline)
	return snappedf(px, 0.1)
