class_name Recipes
extends RefCounted

## What the backpack screen makes. Each recipe is [item made, how many,
## [[item used, how many], ...]]. The LIST recipes are made anywhere, the
## AT_FURNACE ones only within FURNACE_REACH blocks of a furnace.

## Blocks off each way a furnace can be and still be used
const FURNACE_REACH: int = 4

const LIST: Array = [
	# Wood and stone pickaxe, axe, shovel and sword
	[101, 1, [[Chunk.WOOD_PLANKS, 3]]],
	[105, 1, [[Chunk.WOOD_PLANKS, 3]]],
	[109, 1, [[Chunk.WOOD_PLANKS, 1]]],
	[113, 1, [[Chunk.WOOD_PLANKS, 2]]],
	[102, 1, [[Chunk.STONE, 3], [Chunk.WOOD_PLANKS, 2]]],
	[106, 1, [[Chunk.STONE, 3], [Chunk.WOOD_PLANKS, 2]]],
	[110, 1, [[Chunk.STONE, 1], [Chunk.WOOD_PLANKS, 2]]],
	[114, 1, [[Chunk.STONE, 2], [Chunk.WOOD_PLANKS, 1]]],
	# Blocks and props
	[BlockDefs.FURNACE, 1, [[Chunk.STONE, 8], [Chunk.COAL, 2]]],
	[BlockDefs.CHEST, 1, [[Chunk.WOOD_PLANKS, 8]]],
	[Chunk.CRATE, 1, [[Chunk.WOOD_PLANKS, 4]]],
	[BlockDefs.FENCE, 3, [[Chunk.WOOD_PLANKS, 4]]],
	[Chunk.GREY_BRICK, 4, [[Chunk.STONE, 4]]],
	[BlockDefs.LEVER, 1, [[Chunk.STONE, 1], [Chunk.WOOD_PLANKS, 1]]],
	[BlockDefs.BUTTON, 1, [[Chunk.STONE, 1]]],
]

## What a furnace makes: the gold and diamond gear, and what is fired
const AT_FURNACE: Array = [
	# Gold and diamond pickaxe, axe, shovel and sword
	[103, 1, [[Chunk.METAL, 3], [Chunk.WOOD_PLANKS, 2]]],
	[107, 1, [[Chunk.METAL, 3], [Chunk.WOOD_PLANKS, 2]]],
	[111, 1, [[Chunk.METAL, 1], [Chunk.WOOD_PLANKS, 2]]],
	[115, 1, [[Chunk.METAL, 2], [Chunk.WOOD_PLANKS, 1]]],
	[104, 1, [[Chunk.DIAMOND, 3], [Chunk.WOOD_PLANKS, 2]]],
	[108, 1, [[Chunk.DIAMOND, 3], [Chunk.WOOD_PLANKS, 2]]],
	[112, 1, [[Chunk.DIAMOND, 1], [Chunk.WOOD_PLANKS, 2]]],
	[116, 1, [[Chunk.DIAMOND, 2], [Chunk.WOOD_PLANKS, 1]]],
	# Fired brick, and the metal door, key, rails and cart
	[Chunk.BRICK, 4, [[Chunk.SAND, 4], [Chunk.COAL, 1]]],
	[BlockDefs.DOOR, 1, [[Chunk.METAL, 6]]],
	[BlockDefs.KEY, 1, [[Chunk.METAL, 1], [Chunk.CRYSTAL, 1]]],
	[BlockDefs.RAIL, 8, [[Chunk.METAL, 3], [Chunk.WOOD_PLANKS, 1]]],
	[BlockDefs.MINECART, 1, [[Chunk.METAL, 5]]],
]


## Every recipe: LIST, then AT_FURNACE.
static func all() -> Array:
	return LIST + AT_FURNACE


## True when the chunk manager cm has a furnace within FURNACE_REACH blocks
## of cell each way.
static func furnace_near(cm: Node3D, cell: Vector3i) -> bool:
	for x in range(-FURNACE_REACH, FURNACE_REACH + 1):
		for y in range(-FURNACE_REACH, FURNACE_REACH + 1):
			for z in range(-FURNACE_REACH, FURNACE_REACH + 1):
				if cm.get_block_at(cell + Vector3i(x, y, z)) == BlockDefs.FURNACE:
					return true
	return false


## True when bp holds everything recipe uses and has room for what it makes.
static func can_make(bp: Backpack, recipe: Array) -> bool:
	for need: Array in recipe[2]:
		if bp.count_of(need[0]) < need[1]:
			return false
	return bp.room_for(recipe[0]) >= recipe[1]


## Uses up what recipe needs and adds what it makes. Changes nothing and
## returns false when it cannot be made.
static func make(bp: Backpack, recipe: Array) -> bool:
	if not can_make(bp, recipe):
		return false
	for need: Array in recipe[2]:
		bp.remove(need[0], need[1])
	bp.add(recipe[0], recipe[1])
	return true


## The recipe as a line of text, such as "Rail x8: 3 Metal, 1 Wood Planks".
static func describe(recipe: Array) -> String:
	var text: String = BlockDefs.display_name(recipe[0])
	if recipe[1] > 1:
		text += " x%d" % recipe[1]
	var parts: PackedStringArray = []
	for need: Array in recipe[2]:
		parts.append("%d %s" % [need[1], BlockDefs.display_name(need[0])])
	return text + ": " + ", ".join(parts)
