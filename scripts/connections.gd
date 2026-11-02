class_name Connections
extends RefCounted

## Picks the kit pieces and quarter turns that join a fence or a rail to its
## neighbours. A mask holds one bit per side in the order W (-X), S (+Z),
## E (+X), N (-Z); one quarter turn moves each arm one place along that order.

const W: int = 1
const S: int = 2
const E: int = 4
const N: int = 8
## Cell step (x, z) to the side of each mask bit, in bit order
const SIDES: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1)]

## Piece id -> the sides its arms reach with no turn: Fence, End, Corner, T
const FENCE_ARMS: Dictionary = {40: W | E, 47: W, 48: W | S, 49: W | E | S}
## Piece id -> the sides its arms reach with no turn: Rail, Corner
const RAIL_ARMS: Dictionary = {41: W | E, 50: E | S}
## The rail incline rises toward E with no turn
const INCLINE: int = 51


## The mask with every arm moved k quarter turns.
static func turn(mask: int, k: int) -> int:
	var t: int = posmod(k, 4)
	return ((mask << t) | (mask >> (4 - t))) & 15


## [[piece id, turns], ...] that draw a fence with arms on the mask's sides.
## A lone fence keeps lone_turns.
static func fence(mask: int, lone_turns: int) -> Array:
	if mask == 0:
		return [[BlockDefs.FENCE, lone_turns]]
	if mask == 15:
		# The kit has no cross: lay two straight fences over each other
		return [[BlockDefs.FENCE, 0], [BlockDefs.FENCE, 1]]
	return [_fit(FENCE_ARMS, mask)]


## [piece id, turns] that draws a rail with arms on the mask's sides. up is the
## side whose rail is a step higher (0 for none). A lone rail keeps lone_turns.
static func rail(mask: int, up: int, lone_turns: int) -> Array:
	if up != 0:
		return _fit({INCLINE: E}, up)
	if mask == 0:
		return [BlockDefs.RAIL, lone_turns]
	var count: int = 0
	for k in 4:
		count += (mask >> k) & 1
	if count == 1:
		# One neighbour: run straight on toward it
		mask |= turn(mask, 2)
	elif count > 2:
		# A rail joins two sides; three or four neighbours always hold a straight pair
		mask = W | E if (mask & (W | E)) == W | E else S | N
	return _fit(RAIL_ARMS, mask)


## The [piece id, turns] whose arms land on just the mask's sides.
static func _fit(arms: Dictionary, mask: int) -> Array:
	for id: int in arms:
		for k in 4:
			if turn(arms[id], k) == mask:
				return [id, k]
	return []
