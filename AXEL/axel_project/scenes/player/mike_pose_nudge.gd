@tool
class_name MikePoseNudge
extends Resource

## Pixel shift for the front drawing (S / idle / walk_down). Shared by every room.
@export var front: Vector2 = Vector2.ZERO
## Pixel shift for the back drawing (W / idle_back / walk_up). Shared by every room.
@export var back: Vector2 = Vector2.ZERO
## Pixel shift for the side drawing (A/D / idle_side / walk_right). Flips with left-facing.
@export var side: Vector2 = Vector2.ZERO
