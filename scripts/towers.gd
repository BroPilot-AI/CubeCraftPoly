class_name Towers
extends RefCounted

## Old watchtowers: one in each CELL x CELL square of chunks, clear of spawn. A
## tall hollow grey brick tower, 5 x 5 at LOW in its chunk, with a doorway on
## its +z side, a stair winding up the inside one block a step, and a roof with
## a way out onto it and an Old Chest on top. ChunkGenerator.generate_blocks
## builds it on worker threads, so all here is static and works on plain data.

## Chunks a side of each square, and none within SPAWN_CLEAR chunks of spawn
const CELL: int = 8
const SPAWN_CLEAR: int = 2
## Blocks from the floor up to the roof, at most
const HEIGHT: int = 16
## The tower's lower x, z corner in its chunk
const LOW: Vector2i = Vector2i(5, 5)
## The column in the middle of the tower (LOW + (2, 2)), whose ground it stands on
const MIDDLE: Vector2i = Vector2i(7, 7)
## The cells round the middle of the inside, going round, from LOW + (1, 1)
const RING: Array[Vector2i] = [
	Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(3, 2),
	Vector2i(3, 3), Vector2i(2, 3), Vector2i(1, 3), Vector2i(1, 2),
]
## The ring cell of the first step: the one in the far corner from the doorway
const START: int = 0


## The chunk of square (sx, sz) that holds its tower
static func site_of(sx: int, sz: int) -> Vector2i:
	var h: int = (sx * 1640531513) ^ (sz * 2654435761)
	return Vector2i(sx * CELL + posmod(h, CELL), sz * CELL + posmod(h / CELL, CELL))


## True when chunk (cx, cz) has a tower
static func is_site(cx: int, cz: int) -> bool:
	if absi(cx) <= SPAWN_CLEAR and absi(cz) <= SPAWN_CLEAR:
		return false
	return site_of(floori(cx / float(CELL)), floori(cz / float(CELL))) == Vector2i(cx, cz)


## The roof's height for a tower whose floor is at base
static func top_of(base: int) -> int:
	return mini(base + HEIGHT, Chunk.CHUNK_Y - 3)


## Writes the tower into a chunk's blocks (indexed as generate_blocks does),
## its floor at height base.
static func build(blocks: Array[int], base: int) -> void:
	var top: int = top_of(base)
	for x in 5:
		for z in 5:
			var wall: bool = x == 0 or x == 4 or z == 0 or z == 4
			# Down to the ground where it falls away under the tower
			var y: int = base - 1
			while y > 0 and not BlockDefs.is_cube(blocks[_index(LOW.x + x, y, LOW.y + z)]):
				_put(blocks, x, y, z, Chunk.GREY_BRICK)
				y -= 1
			_put(blocks, x, base, z, Chunk.GREY_BRICK)
			for up in range(base + 1, top):
				_put(blocks, x, up, z, Chunk.GREY_BRICK if wall else Chunk.AIR)
			_put(blocks, x, top, z, Chunk.GREY_BRICK)
	for up in [base + 1, base + 2]:
		_put(blocks, 2, up, 4, Chunk.AIR)
		_put(blocks, 2, up, 5, Chunk.AIR)
	var steps: int = top - base - 1
	for k in steps:
		var cell: Vector2i = RING[(k + START) % RING.size()]
		_put(blocks, cell.x, base + 1 + k, cell.y, Chunk.GREY_BRICK)
	# The way out onto the roof, over the last two steps so neither is a low ceiling
	for k in [steps - 1, steps - 2]:
		var cell: Vector2i = RING[(k + START) % RING.size()]
		_put(blocks, cell.x, top, cell.y, Chunk.AIR)
	_put(blocks, 2, top + 1, 2, BlockDefs.OLD_CHEST)


## Sets the cell (x, y, z) from LOW in the chunk to id
static func _put(blocks: Array[int], x: int, y: int, z: int, id: int) -> void:
	blocks[_index(LOW.x + x, y, LOW.y + z)] = id


static func _index(x: int, y: int, z: int) -> int:
	return x + y * Chunk.CHUNK_X + z * Chunk.CHUNK_X * Chunk.CHUNK_Y
