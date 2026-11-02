class_name ChunkGenerator

const Chunk: GDScript = preload("res://scripts/chunk.gd")

const CHUNK_X: int = 16
const CHUNK_Y: int = 32
const CHUNK_Z: int = 16

const SEA_LEVEL: int = 10
const BASE_HEIGHT: int = 14
const HEIGHT_AMPLITUDE: int = 10
const BIOME_SNOW_THRESHOLD: float = 0.33
const BIOME_SAND_THRESHOLD: float = -0.28
## The three lands, from the biome noise; each has its own monsters
const BIOME_MEADOW: int = 0
const BIOME_DESERT: int = 1
const BIOME_SNOW: int = 2
## The spawn search walks out a spiral of this many columns, about this many
## blocks apart, for meadow land above the sand flats with meadow all about it
## for SPAWN_CLEAR blocks, read every SPAWN_CLEAR_STEP blocks
const SPAWN_SEARCH_TRIES: int = 512
const SPAWN_SEARCH_STEP: float = 8.0
const SPAWN_CLEAR: float = 40.0
const SPAWN_CLEAR_STEP: float = 8.0
## Radians the spawn search turns from one column to the next: the golden angle
const SPAWN_SEARCH_TURN: float = 2.39996

## Each land's ores: [block id, highest y it forms at, noise level it needs].
## The first match wins. The better ores lie under the harder lands: the
## meadow has coal and a little deep metal, the desert metal and crystal, the
## snow crystal and diamond.
const ORES: Dictionary = {
	BIOME_MEADOW: [
		[Chunk.METAL, 5, 0.92],
		[Chunk.COAL, CHUNK_Y, 0.76],
	],
	BIOME_DESERT: [
		[Chunk.CRYSTAL, 8, 0.86],
		[Chunk.METAL, 12, 0.82],
		[Chunk.COAL, CHUNK_Y, 0.8],
	],
	BIOME_SNOW: [
		[Chunk.DIAMOND, 6, 0.89],
		[Chunk.CRYSTAL, 10, 0.85],
		[Chunk.COAL, CHUNK_Y, 0.8],
	],
}
## Each ore reads the noise this far apart times its id, so their veins do
## not overlap
const ORE_OFFSET: float = 1000.0

## Caves open the stone where the cave noise is above CAVE_LEVEL, from
## CAVE_FLOOR up to the dirt, so the ground over them stays whole. The noise
## reads y CAVE_SQUASH times as far, so caves are wider than they are tall.
const CAVE_LEVEL: float = 0.4
const CAVE_FLOOR: int = 1
const CAVE_SQUASH: float = 2.0
## What grows in a cave on a stone floor: [item id, chance per cell]. A cell
## grows at most one.
const CAVE_DECOR: Array = [
	[25, 0.018],  # Crystal Shard
	[26, 0.006],  # Big Crystal
	[13, 0.005],  # Cheese
]
const CAVE_DECOR_SEED: int = 5

## Decor per surface block: [item id, chance per column]. A column grows at most one.
const DECOR: Dictionary = {
	Chunk.GRASS: [
		[32, 0.008],  # Oak Tree
		[33, 0.008],  # Small Tree
		[34, 0.004],  # Wide Tree
		[17, 0.05],   # Tall Grass
		[18, 0.07],   # Short Grass
		[19, 0.015],  # Daisies
		[20, 0.015],  # Bluebells
		[21, 0.012],  # Fern
		[22, 0.012],  # Leafy Plant
		[24, 0.01],   # Bush
		[23, 0.004],  # Mushroom
		[28, 0.004],  # Mossy Rock
	],
	Chunk.SAND: [
		[35, 0.004],  # Dead Tree
		[37, 0.004],  # Twisted Tree
		[27, 0.008],  # Rock
	],
	Chunk.SNOW: [
		[36, 0.006],  # Bare Tree
		[25, 0.01],   # Crystal Shard
		[26, 0.003],  # Big Crystal
		[27, 0.004],  # Rock
	],
}
## Decor on grass at most LOWLAND_HEIGHT above sea level, by the sand flats
const DECOR_LOWLAND: Array = [
	[29, 0.03],  # Bamboo
	[30, 0.02],  # Pale Bamboo
	[31, 0.02],  # Tall Bamboo
	[17, 0.05],  # Tall Grass
	[21, 0.02],  # Fern
	[23, 0.01],  # Mushroom
]
const LOWLAND_HEIGHT: int = 2
const DECOR_SEED: int = 3

## Offsets every noise and the decor roll. 0 is the first world, made before
## seeds were saved; Main sets it from the save.
static var world_seed: int = 0


static func generate(chunk: Node3D) -> void:
	if chunk == null:
		push_error("ChunkGenerator.generate: chunk is null")
		return
	chunk.blocks = generate_blocks(chunk.cx, chunk.cz)
	chunk.mark_dirty()


## The blocks of chunk (cx, cz), in Chunk.blocks order. It touches no nodes, so
## worker threads can run it.
static func generate_blocks(cx: int, cz: int) -> Array[int]:
	var blocks: Array[int] = []
	blocks.resize(CHUNK_X * CHUNK_Y * CHUNK_Z)
	blocks.fill(Chunk.AIR)
	var noise_height: FastNoiseLite = _make_height_noise()
	var noise_biome: FastNoiseLite = _make_biome_noise()
	var noise_ore: FastNoiseLite = _make_ore_noise()
	var noise_cave: FastNoiseLite = _make_cave_noise()
	var ruin_floor: int = -1
	# Each column's surface y, by x + z * CHUNK_X, for a crystal cavern
	var surfaces: Array[int] = []
	surfaces.resize(CHUNK_X * CHUNK_Z)

	for x in CHUNK_X:
		for z in CHUNK_Z:
			# Index of cell (x, 0, z); each step up adds CHUNK_X
			var column: int = x + z * CHUNK_X * CHUNK_Y
			var wx: float = float(cx * CHUNK_X + x)
			var wz: float = float(cz * CHUNK_Z + z)
			var h: int = _height_of(noise_height.get_noise_2d(wx, wz))
			var biome: int = _biome_of(noise_biome.get_noise_2d(wx, wz))
			var snowy: bool = biome == BIOME_SNOW
			# Low ground is sand, or ice in the snow biome
			var fill: int = Chunk.ICE if snowy else Chunk.SAND

			for y in h:
				var id: int = Chunk.DIRT
				if y < h - 2 and _is_cave(noise_cave, wx, y, wz):
					var below: int = blocks[column + (y - 1) * CHUNK_X]
					id = _cave_decor_at(below, Vector3i(cx * CHUNK_X + x, y, cz * CHUNK_Z + z))
				elif y < h - 2:
					id = _ore_at(noise_ore, wx, y, wz, biome)
				blocks[column + y * CHUNK_X] = id

			var top: int
			if h <= SEA_LEVEL:
				top = fill
			elif snowy:
				top = Chunk.SNOW
			elif biome == BIOME_DESERT:
				top = Chunk.SAND
			else:
				top = Chunk.GRASS
			blocks[column + h * CHUNK_X] = top

			for y in range(h + 1, SEA_LEVEL):
				blocks[column + y * CHUNK_X] = fill

			# Low columns are filled up to the sand flats, so their surface is there
			var surface: int = maxi(h, SEA_LEVEL - 1)
			surfaces[x + z * CHUNK_X] = surface
			if x == Ruins.CENTER and z == Ruins.CENTER:
				ruin_floor = surface
			var decor: int = _decor_at(top, surface, Vector2i(cx * CHUNK_X + x, cz * CHUNK_Z + z))
			if decor != Chunk.AIR and surface + 1 < CHUNK_Y:
				blocks[column + (surface + 1) * CHUNK_X] = decor

	# A crystal cavern lies deep enough to have ground over all of it
	if Caverns.is_site(cx, cz) and surfaces.min() >= Caverns.CENTER.y + Caverns.RADIUS.y + 3:
		Caverns.carve(blocks, surfaces)
	# A watchtower stands on dry ground, in place of any ruin
	var tower: bool = Towers.is_site(cx, cz)
	var base: int = surfaces[Towers.MIDDLE.x + Towers.MIDDLE.y * CHUNK_X]
	if tower and base > SEA_LEVEL:
		Towers.build(blocks, base)
	# A ruin stands on dry ground, with room above it for its walls
	if not tower and Ruins.is_site(cx, cz) and ruin_floor > SEA_LEVEL and ruin_floor + 5 < CHUNK_Y:
		Ruins.build(blocks, ruin_floor)
		Ruins.lay_track(blocks, surfaces)
	return blocks


## The land of world column (x, z): BIOME_MEADOW, BIOME_DESERT or BIOME_SNOW.
static func biome_at(x: int, z: int) -> int:
	return _biome_of(_make_biome_noise().get_noise_2d(float(x), float(z)))


## The nearest column to start, on a spiral out from it, that is meadow land
## above the sand flats with meadow all about it, so no desert or snow monster
## is near at the start. Failing that the nearest meadow column above the sand
## flats, and failing that start.
static func spawn_column(start: Vector2i) -> Vector2i:
	var noise_height: FastNoiseLite = _make_height_noise()
	var noise_biome: FastNoiseLite = _make_biome_noise()
	for clear: float in [SPAWN_CLEAR, 0.0]:
		for i in SPAWN_SEARCH_TRIES:
			var dist: float = sqrt(float(i)) * SPAWN_SEARCH_STEP
			var turn: float = i * SPAWN_SEARCH_TURN
			var c: Vector2i = start + Vector2i(roundi(cos(turn) * dist), roundi(sin(turn) * dist))
			var h: int = _height_of(noise_height.get_noise_2d(float(c.x), float(c.y)))
			if h > SEA_LEVEL and _all_meadow(noise_biome, c, clear):
				return c
	return start


## True when the land is meadow at c and all over the disc of radius clear
## about it, read every SPAWN_CLEAR_STEP blocks.
static func _all_meadow(noise: FastNoiseLite, c: Vector2i, clear: float) -> bool:
	var reach: int = floori(clear / SPAWN_CLEAR_STEP)
	for i in range(-reach, reach + 1):
		for j in range(-reach, reach + 1):
			var off: Vector2 = Vector2(i, j) * SPAWN_CLEAR_STEP
			if off.length() > clear:
				continue
			if _biome_of(noise.get_noise_2d(c.x + off.x, c.y + off.y)) != BIOME_MEADOW:
				return false
	return true


static func _biome_of(value: float) -> int:
	if value > BIOME_SNOW_THRESHOLD:
		return BIOME_SNOW
	if value < BIOME_SAND_THRESHOLD:
		return BIOME_DESERT
	return BIOME_MEADOW


## The height of the top block of a column from its height noise
static func _height_of(value: float) -> int:
	return clampi(BASE_HEIGHT + int(value * float(HEIGHT_AMPLITUDE)), 1, CHUNK_Y - 1)


## The decor growing on a column whose surface block is top, or AIR.
static func _decor_at(top: int, surface: int, column: Vector2i) -> int:
	var table: Array = DECOR.get(top, [])
	if top == Chunk.GRASS and surface <= SEA_LEVEL + LOWLAND_HEIGHT:
		table = DECOR_LOWLAND
	var key: Vector3i = Vector3i(column.x, column.y, DECOR_SEED + world_seed)
	var roll: float = float(hash(key) % 10000) / 10000.0
	for entry: Array in table:
		roll -= entry[1]
		if roll < 0.0:
			return entry[0]
	return Chunk.AIR


## True when the stone cell at (wx, y, wz) is opened by a cave.
static func _is_cave(noise: FastNoiseLite, wx: float, y: int, wz: float) -> bool:
	return y >= CAVE_FLOOR and noise.get_noise_3d(wx, y * CAVE_SQUASH, wz) > CAVE_LEVEL


## What grows in the open cave cell at cell, over the block below: one of
## CAVE_DECOR on stone, else AIR.
static func _cave_decor_at(below: int, cell: Vector3i) -> int:
	if below != Chunk.STONE:
		return Chunk.AIR
	var key: Vector4i = Vector4i(cell.x, cell.y, cell.z, CAVE_DECOR_SEED + world_seed)
	var roll: float = float(hash(key) % 10000) / 10000.0
	for entry: Array in CAVE_DECOR:
		roll -= entry[1]
		if roll < 0.0:
			return entry[0]
	return Chunk.AIR


## The ore in a stone cell of land, or STONE when there is none.
static func _ore_at(noise: FastNoiseLite, wx: float, y: int, wz: float, land: int) -> int:
	for ore: Array in ORES[land]:
		if y <= ore[1] and noise.get_noise_3d(wx + ORE_OFFSET * ore[0], float(y), wz) > ore[2]:
			return ore[0]
	return Chunk.STONE


static func _make_height_noise() -> FastNoiseLite:
	var n: FastNoiseLite = FastNoiseLite.new()
	n.seed = world_seed
	n.frequency = 0.02
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.fractal_octaves = 2
	return n


static func _make_biome_noise() -> FastNoiseLite:
	var n: FastNoiseLite = FastNoiseLite.new()
	n.seed = world_seed + 1
	n.frequency = 0.01
	n.noise_type = FastNoiseLite.TYPE_CELLULAR
	n.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	n.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	return n


static func _make_ore_noise() -> FastNoiseLite:
	var n: FastNoiseLite = FastNoiseLite.new()
	n.seed = world_seed + 2
	n.frequency = 0.15
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.fractal_type = FastNoiseLite.FRACTAL_NONE
	return n


static func _make_cave_noise() -> FastNoiseLite:
	var n: FastNoiseLite = FastNoiseLite.new()
	n.seed = world_seed + 3
	n.frequency = 0.03
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.fractal_octaves = 2
	return n
