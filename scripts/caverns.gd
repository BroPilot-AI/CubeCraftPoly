class_name Caverns
extends RefCounted

## Crystal caverns: about one chunk in CHANCE, clear of spawn and the ruins,
## hides a round room under the ground (CENTER, RADIUS), its walls glittering
## with Crystal and a little Diamond and Big Crystals on its floor, with a 2 x 2
## shaft at SHAFT up to the surface and a Big Crystal beside the top of it.
## ChunkGenerator.generate_blocks carves it on worker threads, so all here is
## static and works on plain data.

## One chunk in CHANCE has a cavern, none within SPAWN_CLEAR chunks of spawn
const CHANCE: int = 20
const SPAWN_CLEAR: int = 2
## The room's middle in the chunk, and how far it reaches each way
const CENTER: Vector3i = Vector3i(8, 6, 8)
const RADIUS: Vector3 = Vector3(6.0, 3.5, 6.0)
## The block id of a Big Crystal (BlockDefs)
const BIG_CRYSTAL: int = 26
## The shaft's lower x, z corner in the chunk
const SHAFT: Vector2i = Vector2i(12, 8)
## The columns of the room's floor a Big Crystal stands in
const FLOOR_CRYSTALS: Array[Vector2i] = [Vector2i(8, 8), Vector2i(5, 9), Vector2i(11, 7)]
const NEXT: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]


## True when chunk (cx, cz) has a cavern
static func is_site(cx: int, cz: int) -> bool:
	if absi(cx) <= SPAWN_CLEAR and absi(cz) <= SPAWN_CLEAR:
		return false
	if Ruins.is_site(cx, cz):
		return false
	return posmod((cx * 83492791) ^ (cz * 2971215073), CHANCE) == 0


## Writes the cavern into a chunk's blocks (indexed as generate_blocks does);
## surface is each column's top y, by x + z * CHUNK_X. Leaves y 0 as it is.
static func carve(blocks: Array[int], surface: Array[int]) -> void:
	var low := Vector3i(CENTER.x - ceili(RADIUS.x), CENTER.y - ceili(RADIUS.y), CENTER.z - ceili(RADIUS.z))
	var high := Vector3i(CENTER.x + ceili(RADIUS.x), CENTER.y + ceili(RADIUS.y), CENTER.z + ceili(RADIUS.z))
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			for z in range(low.z, high.z + 1):
				if _in_room(Vector3i(x, y, z)):
					blocks[_index(x, y, z)] = Chunk.AIR
	for x in range(low.x - 1, high.x + 2):
		for y in range(maxi(low.y - 1, 1), high.y + 2):
			for z in range(low.z - 1, high.z + 2):
				_glitter(blocks, Vector3i(x, y, z))
	for column: Vector2i in FLOOR_CRYSTALS:
		for y in range(1, high.y + 1):
			if _in_room(Vector3i(column.x, y, column.y)):
				if blocks[_index(column.x, y - 1, column.y)] != Chunk.AIR:
					blocks[_index(column.x, y, column.y)] = BIG_CRYSTAL
				break
	for x in range(SHAFT.x, SHAFT.x + 2):
		for z in range(SHAFT.y, SHAFT.y + 2):
			var top: int = surface[x + z * Chunk.CHUNK_X]
			for y in range(CENTER.y, mini(top + 2, Chunk.CHUNK_Y)):
				blocks[_index(x, y, z)] = Chunk.AIR
	var mark: int = surface[SHAFT.x + 2 + SHAFT.y * Chunk.CHUNK_X] + 1
	if mark < Chunk.CHUNK_Y:
		blocks[_index(SHAFT.x + 2, mark, SHAFT.y)] = BIG_CRYSTAL


## True when cell (in the chunk) is inside the room
static func _in_room(cell: Vector3i) -> bool:
	var off := Vector3(cell - CENTER) / RADIUS
	return off.length_squared() <= 1.0


## A solid cell by the room turns to Crystal or Diamond where its pattern says
static func _glitter(blocks: Array[int], cell: Vector3i) -> void:
	if not _inside(cell) or _in_room(cell) or not BlockDefs.is_cube(blocks[_index(cell.x, cell.y, cell.z)]):
		return
	var by_room: bool = false
	for step: Vector3i in NEXT:
		by_room = by_room or _in_room(cell + step)
	if not by_room:
		return
	if (cell.x * 5 + cell.y * 3 + cell.z * 7) % 4 == 0:
		blocks[_index(cell.x, cell.y, cell.z)] = Chunk.CRYSTAL
	elif (cell.x * 11 + cell.y * 13 + cell.z * 17) % 37 == 0:
		blocks[_index(cell.x, cell.y, cell.z)] = Chunk.DIAMOND


static func _inside(cell: Vector3i) -> bool:
	return cell.x >= 0 and cell.x < Chunk.CHUNK_X and cell.y >= 1 and cell.y < Chunk.CHUNK_Y and cell.z >= 0 and cell.z < Chunk.CHUNK_Z


static func _index(x: int, y: int, z: int) -> int:
	return x + y * Chunk.CHUNK_X + z * Chunk.CHUNK_X * Chunk.CHUNK_Y
