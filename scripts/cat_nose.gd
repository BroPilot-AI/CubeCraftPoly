class_name CatNose
extends RefCounted

## Where a tamed cat leads its owner: the nearest Old Chest still closed, the
## buried treasure of their map or the chest of a ruin. Only static functions.

## The kind that leads to chests
const KIND: String = "Cat"
## Blocks from the player across the ground a cat smells a ruin's chest in
const RANGE: int = 64
## Blocks ahead of the player a leading cat walks, at the least and the most
const AHEAD_MIN: float = 3.0
const AHEAD_MAX: float = 6.0
## Blocks from the chest the player comes before the cat sits by it
const SIT_NEAR: float = 4.0
## No cell: there is no chest
const NONE: Vector3i = Vector3i(-1, -1, -1)


## The cell of the Old Chest of the ruin in chunk (cx, cz), going down column
## Ruins.CHEST_CELL, or NONE when the chunk holds no ruin, is not loaded or its
## chest has been opened.
static func ruin_chest(cm: Node3D, cx: int, cz: int) -> Vector3i:
	if not Ruins.is_site(cx, cz) or cm.get_chunk(cx, cz) == null:
		return NONE
	var cell := Vector3i(cx * Chunk.CHUNK_X + Ruins.CHEST_CELL.x, Chunk.CHUNK_Y - 1, cz * Chunk.CHUNK_Z + Ruins.CHEST_CELL.y)
	while cell.y >= 0:
		if cm.get_block_at(cell) == BlockDefs.OLD_CHEST:
			return cell
		cell.y -= 1
	return NONE


## The closest to at of: the treasure's chest when it is buried, else its spot
## at at's height while the map is followed; and each ruin's chest RANGE blocks
## or less from at across the ground. INF when there is none.
static func nearest(cm: Node3D, at: Vector3, treasure: TreasureMap) -> Vector3:
	var goals: Array[Vector3] = []
	if treasure.active and treasure.buried:
		goals.append(Vector3(treasure.buried_at) + Vector3(0.5, 0.0, 0.5))
	elif treasure.active:
		goals.append(Vector3(treasure.spot.x + 0.5, at.y, treasure.spot.y + 0.5))
	var reach: int = ceili(float(RANGE) / Chunk.CHUNK_X)
	var cx: int = floori(at.x / Chunk.CHUNK_X)
	var cz: int = floori(at.z / Chunk.CHUNK_Z)
	for dx in range(-reach, reach + 1):
		for dz in range(-reach, reach + 1):
			var chest: Vector3i = ruin_chest(cm, cx + dx, cz + dz)
			if chest != NONE and _across(at, Vector3(chest)) <= RANGE:
				goals.append(Vector3(chest) + Vector3(0.5, 0.0, 0.5))
	var best: Vector3 = Vector3.INF
	for goal: Vector3 in goals:
		if is_inf(best.x) or _across(at, goal) < _across(at, best):
			best = goal
	return best


## The spot AHEAD_MAX blocks from at toward goal across the ground, or goal
## when that is nearer.
static func lead_spot(at: Vector3, goal: Vector3) -> Vector3:
	var level := Vector3(goal.x - at.x, 0.0, goal.z - at.z)
	if level.length() <= AHEAD_MAX:
		return goal
	return at + level.normalized() * AHEAD_MAX


## Blocks from a to b across the ground
static func _across(a: Vector3, b: Vector3) -> float:
	return Vector2(b.x - a.x, b.z - a.z).length()
