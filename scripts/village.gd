class_name Village
extends RefCounted

## Home grows into a village as quests are done: each of PARTS is put down
## once, on the ground round home, when the player has done its quests and the
## ground under it is loaded, and RESIDENTS come to live there (MobSpawner).
## Only static functions.

## BlockDefs.ITEMS ids of the decor the village is made of
const FLOWERS: int = 19
const BUSH: int = 24
const BIG_CRYSTAL: int = 26
const FENCE: int = BlockDefs.FENCE
const CRATE: int = Chunk.CRATE
## Each [quests done, Array of [block id, offset from home across (x, z)]], in
## order of quests done. The fence stands on every other cell of the ring 7
## out, with a gate in the side toward +z.
const PARTS: Array = [
	[1, [
		[FLOWERS, Vector2i(3, 3)], [FLOWERS, Vector2i(-3, 3)], [FLOWERS, Vector2i(3, -3)],
		[FLOWERS, Vector2i(-3, -3)], [FLOWERS, Vector2i(0, 4)], [FLOWERS, Vector2i(4, 0)],
	]],
	[3, [
		[FENCE, Vector2i(-7, -7)], [FENCE, Vector2i(-5, -7)], [FENCE, Vector2i(-3, -7)],
		[FENCE, Vector2i(-1, -7)], [FENCE, Vector2i(1, -7)], [FENCE, Vector2i(3, -7)],
		[FENCE, Vector2i(5, -7)], [FENCE, Vector2i(7, -7)],
		[FENCE, Vector2i(-7, -5)], [FENCE, Vector2i(7, -5)], [FENCE, Vector2i(-7, -3)],
		[FENCE, Vector2i(7, -3)], [FENCE, Vector2i(-7, -1)], [FENCE, Vector2i(7, -1)],
		[FENCE, Vector2i(-7, 1)], [FENCE, Vector2i(7, 1)], [FENCE, Vector2i(-7, 3)],
		[FENCE, Vector2i(7, 3)], [FENCE, Vector2i(-7, 5)], [FENCE, Vector2i(7, 5)],
		[FENCE, Vector2i(-7, 7)], [FENCE, Vector2i(-5, 7)], [FENCE, Vector2i(-3, 7)],
		[FENCE, Vector2i(3, 7)], [FENCE, Vector2i(5, 7)], [FENCE, Vector2i(7, 7)],
	]],
	[5, [
		[CRATE, Vector2i(5, -5)], [CRATE, Vector2i(5, -4)], [CRATE, Vector2i(4, -5)],
		[BUSH, Vector2i(-5, -5)], [BUSH, Vector2i(-5, 5)],
	]],
	[7, [
		[BIG_CRYSTAL, Vector2i(0, -5)], [FLOWERS, Vector2i(-2, -5)], [FLOWERS, Vector2i(2, -5)],
	]],
	[10, [
		[BIG_CRYSTAL, Vector2i(-5, 0)], [BIG_CRYSTAL, Vector2i(5, 0)],
		[FLOWERS, Vector2i(-4, 1)], [FLOWERS, Vector2i(4, 1)],
		[FLOWERS, Vector2i(-4, -1)], [FLOWERS, Vector2i(4, -1)],
	]],
]
## Each [quests done, villager kind] who lives at home from then on
const RESIDENTS: Array = [[5, "Steve"], [7, "Cube Woman Character"]]


## The y of the top block at (x, z) under any air and plants, or -1 when its
## chunk is not loaded or the column is empty.
static func ground(cm: Node3D, x: int, z: int) -> int:
	if cm.get_chunk(floori(x / float(Chunk.CHUNK_X)), floori(z / float(Chunk.CHUNK_Z))) == null:
		return -1
	for y in range(Chunk.CHUNK_Y - 1, -1, -1):
		var id: int = cm.get_block_at(Vector3i(x, y, z))
		if id != Chunk.AIR and not BlockDefs.is_replaceable(id):
			return y
	return -1


## Puts down, in order, each part past the built first ones whose quests done
## are done: each block on its cell's ground, where that cell is empty. Stops at
## a part whose ground is not all loaded. Returns how many parts are built now;
## with home INF, built.
static func build(cm: Node3D, home: Vector3, done: int, built: int) -> int:
	if is_inf(home.x):
		return built
	var at := Vector2i(floori(home.x), floori(home.z))
	while built < PARTS.size() and PARTS[built][0] <= done:
		var cells: Array = PARTS[built][1]
		var tops: Array[int] = []
		for cell: Array in cells:
			var spot: Vector2i = at + cell[1]
			tops.append(ground(cm, spot.x, spot.y))
		if tops.has(-1):
			return built
		for i in cells.size():
			var spot: Vector2i = at + cells[i][1]
			var place := Vector3i(spot.x, tops[i] + 1, spot.y)
			if place.y < Chunk.CHUNK_Y and cm.get_block_at(place) == Chunk.AIR:
				cm.set_block_at(place, cells[i][0])
		built += 1
	return built


## The kinds of RESIDENTS who live at home once done quests are done
static func residents(done: int) -> Array[String]:
	var kinds: Array[String] = []
	for resident: Array in RESIDENTS:
		if resident[0] <= done:
			kinds.append(resident[1])
	return kinds


## The parts built a save gives; 0 when it is missing or not a count
static func load_built(saved: Variant) -> int:
	if not (saved is int or saved is float):
		return 0
	return clampi(int(saved), 0, PARTS.size())
