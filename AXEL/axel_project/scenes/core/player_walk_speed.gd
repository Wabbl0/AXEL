extends RefCounted
class_name PlayerWalkSpeed
## Authored walk speed from authored Player scale (1920×1280 look).
## Stride constant K from shared rooms; below SMALL_SCALE add extra world
## speed linear in how far under that threshold (tiny Mike must not crawl).
## Apply only to authored values — never re-run on live cover-sync / 2.4 depth.

const REF_SCALE := 0.198
const REF_SPEED := 169.8
const SMALL_SCALE := 0.3
## 1.1 (0.079) gets +33.5 (old +50 × 0.67); same slope for every room below SMALL_SCALE.
const SMALL_ANCHOR_SCALE := 0.079
const SMALL_ANCHOR_ADD := 33.5


static func stride_k() -> float:
	return REF_SPEED / REF_SCALE


static func small_speed_per_scale() -> float:
	return SMALL_ANCHOR_ADD / (SMALL_SCALE - SMALL_ANCHOR_SCALE)


static func from_scale(scale_x: float) -> float:
	if scale_x <= 0.0:
		return 0.0
	var speed := stride_k() * scale_x
	if scale_x < SMALL_SCALE:
		speed += small_speed_per_scale() * (SMALL_SCALE - scale_x)
	return snappedf(speed, 0.1)
