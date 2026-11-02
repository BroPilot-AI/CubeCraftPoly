class_name Ruins
extends RefCounted

## The small brick ruins some chunks hold: broken walls round a room, a locked
## metal door with a lever beside it outside, and inside an Old Chest that gives
## loot of its land the first time it opens. On flat ground an old track runs
## past it, all along its chunk. Only static functions on plain data, so
## ChunkGenerator's worker threads can run them.

## About one chunk in CHANCE holds a ruin
const CHANCE: int = 10
## No ruin within this many chunks of chunk (0, 0)
const SPAWN_CLEAR: int = 2
## The room is the cells LO..HI on x and z; its floor is the ground of the
## column (CENTER, CENTER)
const LO: int = 4
const HI: int = 10
const CENTER: int = 7
## Wall rows above the floor, and the rows of air cleared above it
const WALL_HEIGHT: int = 3
const HEADROOM: int = 4
## How far down the floor is propped up over low ground
const PROP_DEPTH: int = 4
## The door in the near wall, the lever outside beside it and the chest at the
## back, as (x, z) cells one above the floor
const DOOR_CELL: Vector2i = Vector2i(7, 10)
const LEVER_CELL: Vector2i = Vector2i(8, 11)
const CHEST_CELL: Vector2i = Vector2i(7, 5)
## The row (z) of the chunk the old track runs along, outside the walls and
## away from the lever
const TRACK_ROW: int = 13


## True when chunk (cx, cz) holds a ruin: about one chunk in CHANCE, none
## near spawn.
static func is_site(cx: int, cz: int) -> bool:
	if absi(cx) <= SPAWN_CLEAR and absi(cz) <= SPAWN_CLEAR:
		return false
	return posmod((cx * 73856093) ^ (cz * 19349663), CHANCE) == 0


## Writes the ruin into a chunk's blocks (in ChunkGenerator.generate_blocks
## order) with its floor at floor_y.
static func build(blocks: Array[int], floor_y: int) -> void:
	for x in range(LO, HI + 1):
		for z in range(LO, HI + 1):
			_floor(blocks, x, z, floor_y)
			if x == LO or x == HI or z == LO or z == HI:
				_wall(blocks, x, z, floor_y)
	# A step outside the door, so it can be walked up to and the lever stands on it
	for x in range(DOOR_CELL.x - 1, DOOR_CELL.x + 2):
		_floor(blocks, x, DOOR_CELL.y + 1, floor_y)
	_put(blocks, DOOR_CELL.x, floor_y + 1, DOOR_CELL.y, BlockDefs.DOOR)
	_put(blocks, DOOR_CELL.x, floor_y + 2, DOOR_CELL.y, Chunk.AIR)
	_put(blocks, LEVER_CELL.x, floor_y + 1, LEVER_CELL.y, BlockDefs.LEVER)
	_put(blocks, CHEST_CELL.x, floor_y + 1, CHEST_CELL.y, BlockDefs.OLD_CHEST)


## Lays an old track along x (the way a rail with no turn runs) on the row
## TRACK_ROW, a rail one above the ground of each column, when all 16 columns
## there are at one height with only air or plants above. surface holds the
## ground y of each column, at x + z * CHUNK_X. Gives whether it laid one.
static func lay_track(blocks: Array[int], surface: Array[int]) -> bool:
	var y: int = surface[TRACK_ROW * Chunk.CHUNK_X]
	if y + 1 >= Chunk.CHUNK_Y:
		return false
	for x in Chunk.CHUNK_X:
		var above: int = blocks[_index(x, y + 1, TRACK_ROW)]
		if surface[x + TRACK_ROW * Chunk.CHUNK_X] != y or (above != Chunk.AIR and not BlockDefs.is_replaceable(above)):
			return false
	for x in Chunk.CHUNK_X:
		_put(blocks, x, y + 1, TRACK_ROW, BlockDefs.RAIL)
	return true


## What an Old Chest in land gives: [[item id, count], ...]
static func loot(land: int) -> Array:
	match land:
		ChunkGenerator.BIOME_DESERT:
			return [[Chunk.CRYSTAL, 3], [Chunk.METAL, 2], [Chunk.CHEESE, 4]]
		ChunkGenerator.BIOME_SNOW:
			return [[Chunk.DIAMOND, 2], [Chunk.ICE, 4], [Chunk.CHEESE, 4]]
	return [[Chunk.COAL, 6], [Chunk.CHEESE, 4], [BlockDefs.KEY, 1], [BlockDefs.MINECART, 1]]


## Grey brick at floor_y in column (x, z), propped down to the ground, with air
## above it.
static func _floor(blocks: Array[int], x: int, z: int, floor_y: int) -> void:
	_put(blocks, x, floor_y, z, Chunk.GREY_BRICK)
	for y in range(floor_y - 1, maxi(floor_y - 1 - PROP_DEPTH, -1), -1):
		if blocks[_index(x, y, z)] != Chunk.AIR:
			break
		_put(blocks, x, y, z, Chunk.GREY_BRICK)
	for y in range(floor_y + 1, floor_y + HEADROOM + 1):
		_put(blocks, x, y, z, Chunk.AIR)


## The wall in column (x, z) of the ring: brick WALL_HEIGHT rows up, with gaps
## broken in the top and middle rows away from the corners.
static func _wall(blocks: Array[int], x: int, z: int, floor_y: int) -> void:
	var corner: bool = (x == LO or x == HI) and (z == LO or z == HI)
	for row in range(1, WALL_HEIGHT + 1):
		var broken: bool = false
		if not corner and row == WALL_HEIGHT:
			broken = (x + z) % 3 == 0
		elif not corner and row == WALL_HEIGHT - 1:
			broken = (x * 7 + z * 3) % 11 == 0
		_put(blocks, x, floor_y + row, z, Chunk.AIR if broken else Chunk.BRICK)


static func _put(blocks: Array[int], x: int, y: int, z: int, id: int) -> void:
	blocks[_index(x, y, z)] = id


static func _index(x: int, y: int, z: int) -> int:
	return x + z * Chunk.CHUNK_X * Chunk.CHUNK_Y + y * Chunk.CHUNK_X
