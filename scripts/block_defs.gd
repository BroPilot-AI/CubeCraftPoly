class_name BlockDefs
extends RefCounted

## Registry of the Cube World Kit models used as blocks.
## Meshes are baked to world scale (1 unit = 1 block) with the origin at the
## bottom centre of the cell, so an instance goes at Vector3(x + 0.5, y, z + 0.5).

const KIT_DIR: String = "res://assets/cubeworld/"
const KIT_SCALE: float = 0.5
const LAST_CUBE: int = 16
const SAND: int = 15
const SAND_COLOR: Color = Color(0.92, 0.85, 0.55)
## The kit's blank cube, drawn white: what a sheep leaves
const WOOL: int = 14
const WOOL_COLOR: Color = Color(0.95, 0.95, 0.92)
## Cubes drawn in one plain colour in place of their kit model's
const TINTS: Dictionary = {SAND: SAND_COLOR, WOOL: WOOL_COLOR}
const MIN_BOX: float = 0.1

## How an item behaves once placed in the world
const KIND_CUBE: int = 0    # full block, meshed into the chunk collision
const KIND_PLANT: int = 1   # walk-through, replaced by placing into it, random yaw
const KIND_NATURE: int = 2  # solid, random yaw
const KIND_PROP: int = 3    # solid, fixed yaw
const KIND_FLAT: int = 4    # walk-through, fixed yaw
const KIND_ITEM: int = 5    # held only (tools, the key, the minecart), never placed

## The key that opens the metal door
const KEY: int = 117
## Held while right-clicking a rail, it puts down a cart to ride
const MINECART: int = 118
## Props a right-click uses
const CHEST: int = 38
const DOOR: int = 39
const LEVER: int = 42
const BUTTON: int = 43
## Props drawn with the kit piece that joins their neighbours (see Connections)
const FENCE: int = 40
const RAIL: int = 41
## Made of stone and coal; by one the backpack makes the gold and diamond
## gear too. Its model is put together from kit pieces (see FurnaceModel).
const FURNACE: int = 52
## The chest a ruin holds: the first time it opens it gives loot of its land and
## becomes an Open Chest. Breaking one gives a plain Chest, so its loot is had once.
const OLD_CHEST: int = 53
## The door a player places: it opens by hand. A ruin's Metal Door opens only
## by a Key, a lever or a button.
const HAND_DOOR: int = 54
## Seconds to break a block by hand; a wood tool halves it
const HAND_BREAK_TIME: float = 0.8

const TOOL_PICKAXE: int = 0
const TOOL_AXE: int = 1
const TOOL_SHOVEL: int = 2
const TOOL_SWORD: int = 3

## id -> [display name, model path under KIT_DIR without ".glb", kind]
const ITEMS: Dictionary = {
	1: ["Dirt", "blocks/01_dirt", KIND_CUBE],
	2: ["Grass", "blocks/02_grass", KIND_CUBE],
	3: ["Stone", "blocks/03_stone", KIND_CUBE],
	4: ["Wood Planks", "blocks/04_wood_planks", KIND_CUBE],
	5: ["Brick", "blocks/05_brick", KIND_CUBE],
	6: ["Grey Bricks", "blocks/06_grey_bricks", KIND_CUBE],
	7: ["Coal Ore", "blocks/07_coal", KIND_CUBE],
	8: ["Diamond Ore", "blocks/08_diamond", KIND_CUBE],
	9: ["Crystal Ore", "blocks/09_crystal", KIND_CUBE],
	10: ["Metal", "blocks/10_metal", KIND_CUBE],
	11: ["Ice", "blocks/11_ice", KIND_CUBE],
	12: ["Snow", "blocks/12_snow", KIND_CUBE],
	13: ["Cheese", "blocks/13_cheese", KIND_CUBE],
	14: ["Wool", "blocks/14_blank", KIND_CUBE],
	15: ["Sand", "blocks/03_stone", KIND_CUBE],
	16: ["Crate", "decor/Crate", KIND_CUBE],
	17: ["Tall Grass", "decor/Grass", KIND_PLANT],
	18: ["Short Grass", "decor/Grass Small", KIND_PLANT],
	19: ["Daisies", "decor/Flowers", KIND_PLANT],
	20: ["Bluebells", "decor/Flowers-0mxlGKYE9P", KIND_PLANT],
	21: ["Fern", "decor/Plant", KIND_PLANT],
	22: ["Leafy Plant", "decor/Plant-n31PjUy6Ra", KIND_PLANT],
	23: ["Mushroom", "decor/Mushroom", KIND_PLANT],
	24: ["Bush", "decor/Bush", KIND_PLANT],
	25: ["Crystal Shard", "decor/Crystal", KIND_PLANT],
	26: ["Big Crystal", "decor/Big Crystal", KIND_NATURE],
	27: ["Rock", "decor/Rock-Xx1Jkg77vJ", KIND_NATURE],
	28: ["Mossy Rock", "decor/Rock", KIND_NATURE],
	29: ["Bamboo", "decor/Bamboo", KIND_NATURE],
	30: ["Pale Bamboo", "decor/Bamboo Mid", KIND_NATURE],
	31: ["Tall Bamboo", "decor/Bamboo-xBPj13w3JQ", KIND_NATURE],
	32: ["Oak Tree", "decor/Tree-s8XdT4FOZz", KIND_NATURE],
	33: ["Small Tree", "decor/Tree-ahBEW2RRgq", KIND_NATURE],
	34: ["Wide Tree", "decor/Tree", KIND_NATURE],
	35: ["Dead Tree", "decor/Dead Tree", KIND_NATURE],
	36: ["Bare Tree", "decor/Dead Tree-4E3IOActVF", KIND_NATURE],
	37: ["Twisted Tree", "decor/Dead Tree-9dGXS7GrWc", KIND_NATURE],
	38: ["Chest", "decor/Wood Chest", KIND_PROP],
	39: ["Metal Door", "decor/Metal Door", KIND_PROP],
	40: ["Fence", "decor/Fence Center", KIND_PROP],
	41: ["Rail", "decor/Rail Straight", KIND_FLAT],
	42: ["Lever", "decor/Lever", KIND_FLAT],
	43: ["Button", "decor/Button", KIND_FLAT],
	44: ["Open Chest", "decor/Chest Open", KIND_PROP],
	45: ["Open Metal Door", "decor/Metal Door", KIND_FLAT],
	46: ["Pulled Lever", "decor/Lever", KIND_FLAT],
	47: ["Fence End", "decor/Fence End", KIND_PROP],
	48: ["Fence Corner", "decor/Fence Corner", KIND_PROP],
	49: ["Fence T", "decor/Fence T", KIND_PROP],
	50: ["Rail Corner", "decor/Rail Corner", KIND_FLAT],
	51: ["Rail Incline", "decor/Rail Incline", KIND_FLAT],
	52: ["Furnace", "blocks/06_grey_bricks", KIND_PROP],
	53: ["Old Chest", "decor/Wood Chest", KIND_PROP],
	54: ["Door", "decor/Metal Door", KIND_PROP],
	55: ["Open Door", "decor/Metal Door", KIND_FLAT],
	101: ["Wood Pickaxe", "decor/Pickaxe Wood", KIND_ITEM],
	102: ["Stone Pickaxe", "decor/Stone Pickaxe", KIND_ITEM],
	103: ["Gold Pickaxe", "decor/Pickaxe Gold", KIND_ITEM],
	104: ["Diamond Pickaxe", "decor/Diamond Pickaxe", KIND_ITEM],
	105: ["Wood Axe", "decor/Wood Axe", KIND_ITEM],
	106: ["Stone Axe", "decor/Axe Stone", KIND_ITEM],
	107: ["Gold Axe", "decor/Gold Axe", KIND_ITEM],
	108: ["Diamond Axe", "decor/Diamond Axe", KIND_ITEM],
	109: ["Wood Shovel", "decor/Wood Shovel", KIND_ITEM],
	110: ["Stone Shovel", "decor/Stone Shovel", KIND_ITEM],
	111: ["Gold Shovel", "decor/Shovel Gold", KIND_ITEM],
	112: ["Diamond Shovel", "decor/Diamond Shovel", KIND_ITEM],
	113: ["Wood Sword", "decor/Wooden Sword", KIND_ITEM],
	114: ["Stone Sword", "decor/Sword Stone", KIND_ITEM],
	115: ["Gold Sword", "decor/Gold Sword", KIND_ITEM],
	116: ["Diamond Sword", "decor/Sword Diamond", KIND_ITEM],
	117: ["Key", "decor/Key", KIND_ITEM],
	118: ["Minecart", "decor/minecart", KIND_ITEM],
}

## Shut id -> open id for the props a right-click opens and shuts
const OPENS: Dictionary = {CHEST: 44, DOOR: 45, LEVER: 46, HAND_DOOR: 55}
## Ids that are another item's look, not items of their own: id -> base item id
const VARIANTS: Dictionary = {
	44: CHEST, 45: DOOR, 46: LEVER,
	47: FENCE, 48: FENCE, 49: FENCE, 50: RAIL, 51: RAIL,
	54: DOOR, 55: DOOR,
}
## Item id -> the block placing it puts down, when that is not the item itself
const PLACES: Dictionary = {DOOR: HAND_DOOR}
## Quarter turns baked into a variant's model: the open door swings to the -X
## side, the pulled lever points the other way
const BAKE_TURNS: Dictionary = {45: -1, 46: 2, 55: -1}

## Tool id -> [tool type, tier]. Tiers: 1 wood, 2 stone, 3 gold, 4 diamond.
const TOOLS: Dictionary = {
	101: [TOOL_PICKAXE, 1], 102: [TOOL_PICKAXE, 2], 103: [TOOL_PICKAXE, 3], 104: [TOOL_PICKAXE, 4],
	105: [TOOL_AXE, 1], 106: [TOOL_AXE, 2], 107: [TOOL_AXE, 3], 108: [TOOL_AXE, 4],
	109: [TOOL_SHOVEL, 1], 110: [TOOL_SHOVEL, 2], 111: [TOOL_SHOVEL, 3], 112: [TOOL_SHOVEL, 4],
	113: [TOOL_SWORD, 1], 114: [TOOL_SWORD, 2], 115: [TOOL_SWORD, 3], 116: [TOOL_SWORD, 4],
}
## A sword's damage by tier, wood to diamond; each tier is about what the next
## land's monsters take
const SWORD_DAMAGE: Array[int] = [3, 5, 8, 12]

## Tool type -> the items it breaks faster than a hand
const TOOL_BLOCKS: Dictionary = {
	TOOL_PICKAXE: [3, 5, 6, 7, 8, 9, 10, 11, 14, 26, 27, 28, 39, 52],
	TOOL_AXE: [4, 16, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 40, 53],
	TOOL_SHOVEL: [1, 2, 12, 13, 15],
}

## Item id -> [item id, count] that breaking it gives in survival, when that is
## not one of itself. Id 0 gives nothing.
const DROPS: Dictionary = {
	2: [1, 1],
	17: [0, 0], 18: [0, 0],
	27: [3, 2], 28: [3, 2],
	32: [4, 4], 33: [4, 4], 34: [4, 4], 35: [4, 2], 36: [4, 2], 37: [4, 2],
	OLD_CHEST: [CHEST, 1],
}
## Item id -> [[item id, chance], ...], chances adding up to 1: breaking it
## gives one of these at random. A crystal gives an ore: a shard coal or
## crystal, a Big Crystal metal, crystal or now and then diamond.
const RANDOM_DROPS: Dictionary = {
	25: [[7, 0.7], [9, 0.3]],
	26: [[10, 0.6], [9, 0.3], [8, 0.1]],
}
## Item id -> the pickaxe tier it needs to give anything when broken
const NEEDS_TIER: Dictionary = {
	3: 1, 5: 1, 6: 1, 7: 1, 27: 1, 28: 1, 39: 1, 52: 1,
	9: 2, 10: 2, 26: 2,
	8: 3,
}
## Item id -> health eating it gives back in survival: a Cheese a lot, a
## Mushroom a little
const FOOD: Dictionary = {13: 6, 23: 2}

static var _meshes: Dictionary = {}


static func is_cube(id: int) -> bool:
	return id >= 1 and id <= LAST_CUBE


static func kind(id: int) -> int:
	if not ITEMS.has(id):
		return -1
	return ITEMS[id][2]


## The block placing item id puts down: a Metal Door goes down as a hand door.
static func placed_as(id: int) -> int:
	return PLACES.get(id, id)


## The shut model of an open prop, or id itself.
static func shut_of(id: int) -> int:
	var shut: Variant = OPENS.find_key(id)
	return id if shut == null else shut


## True for a ruin's door, shut or open, which a hand opens only with the Key.
static func is_locked(id: int) -> bool:
	return id == DOOR or id == OPENS[DOOR]


## True for items that block movement.
static func is_solid(id: int) -> bool:
	var k: int = kind(id)
	return k == KIND_CUBE or k == KIND_NATURE or k == KIND_PROP


## True for items that can be put in the world.
static func is_placeable(id: int) -> bool:
	return ITEMS.has(id) and kind(id) != KIND_ITEM


## Seconds to break block_id while holding held_id. Plants and flat items break
## at once; the suited tool is (1 + tier) times faster than a hand.
static func break_time(block_id: int, held_id: int) -> float:
	var base: int = VARIANTS.get(block_id, block_id)
	var k: int = kind(base)
	if k == KIND_PLANT or k == KIND_FLAT:
		return 0.0
	if TOOLS.has(held_id):
		var tool: Array = TOOLS[held_id]
		if TOOL_BLOCKS.get(tool[0], []).has(base):
			return HAND_BREAK_TIME / (1.0 + tool[1])
	return HAND_BREAK_TIME


## Damage of a hit with held_id in hand: a sword's SWORD_DAMAGE for its tier,
## another tool 2, anything else 1.
static func attack_damage(held_id: int) -> int:
	if not TOOLS.has(held_id):
		return 1
	var tool: Array = TOOLS[held_id]
	return SWORD_DAMAGE[tool[1] - 1] if tool[0] == TOOL_SWORD else 2


## Health eating id gives back; 0 for what is not food
static func food_value(id: int) -> int:
	return FOOD.get(id, 0)


## What breaking block_id with held_id in hand gives: [item id, count], with id
## 0 when the block needs a better pickaxe than the one held. roll, from 0 to
## 1, picks what a RANDOM_DROPS item gives.
static func drop(block_id: int, held_id: int, roll: float = 0.0) -> Array:
	var base: int = VARIANTS.get(block_id, block_id)
	var need: int = NEEDS_TIER.get(base, 0)
	if need > 0:
		var tool: Array = TOOLS.get(held_id, [-1, 0])
		if tool[0] != TOOL_PICKAXE or tool[1] < need:
			return [0, 0]
	if RANDOM_DROPS.has(base):
		return [_pick(RANDOM_DROPS[base], roll), 1]
	return DROPS.get(base, [base, 1])


## The item of table, [[item id, chance], ...], that roll from 0 to 1 lands on.
static func _pick(table: Array, roll: float) -> int:
	for entry: Array in table:
		roll -= entry[1]
		if roll < 0.0:
			return entry[0]
	return table[-1][0]


## True for items that a placed block replaces.
static func is_replaceable(id: int) -> bool:
	return kind(id) == KIND_PLANT


static func has_random_yaw(id: int) -> bool:
	var k: int = kind(id)
	return k == KIND_PLANT or k == KIND_NATURE


## True for items placed facing the player (the cell stores quarter turns).
static func has_facing(id: int) -> bool:
	var k: int = kind(id)
	return k == KIND_PROP or k == KIND_FLAT


## The item's pick and collision box with the origin at the cell's bottom centre:
## the model's bounds cut to the cell sides and at least MIN_BOX thick, then
## turned by the cell's quarter turns.
static func get_box(id: int, turns: int = 0) -> AABB:
	var cell: AABB = AABB(Vector3(-0.5, 0.0, -0.5), Vector3.ONE)
	if id == FENCE:
		# A fence reaches out to its neighbours on any side, so it fills its cell
		return cell
	if id == RAIL:
		# A rail reaches out to its neighbours on any side, so it covers the floor
		return AABB(cell.position, Vector3(1.0, MIN_BOX, 1.0))
	var mesh: Mesh = get_mesh(id)
	if is_cube(id) or mesh == null:
		return cell
	var m: AABB = mesh.get_aabb()
	if has_random_yaw(id):
		# The model can face any way: use a square around the cell centre
		var r: float = minf(0.5, maxf(m.size.x, m.size.z) * 0.5)
		m = AABB(Vector3(-r, m.position.y, -r), Vector3(r * 2.0, m.size.y, r * 2.0))
	var lo: Vector3 = m.position.max(cell.position)
	var hi: Vector3 = m.end.min(Vector3(0.5, m.end.y, 0.5))
	var size: Vector3 = (hi - lo).max(Vector3.ONE * MIN_BOX)
	var box: AABB = AABB((lo + hi - size) * 0.5, size)
	return Transform3D(Basis(Vector3.UP, turns * PI / 2.0), Vector3.ZERO) * box


static func has_item(id: int) -> bool:
	return ITEMS.has(id)


static func display_name(id: int) -> String:
	if not ITEMS.has(id):
		return ""
	return ITEMS[id][0]


static func get_mesh(id: int) -> Mesh:
	if not ITEMS.has(id):
		return null
	if not _meshes.has(id):
		_meshes[id] = FurnaceModel.build() if id == FURNACE else _bake(id)
	return _meshes[id]


static func _bake(id: int) -> ArrayMesh:
	var path: String = KIT_DIR + ITEMS[id][1] + ".glb"
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		push_error("BlockDefs: cannot load %s" % path)
		return null
	var root: Node = scene.instantiate()
	var found: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if found.is_empty():
		push_error("BlockDefs: no MeshInstance3D in %s" % path)
		root.free()
		return null
	var mi: MeshInstance3D = found[0]
	var xf: Transform3D = Transform3D.IDENTITY
	var n: Node = mi
	while n is Node3D:
		xf = (n as Node3D).transform * xf
		n = n.get_parent()
	xf = Transform3D(Basis.from_scale(Vector3.ONE * KIT_SCALE), Vector3.ZERO) * xf
	if BAKE_TURNS.has(id):
		xf = Transform3D(Basis(Vector3.UP, BAKE_TURNS[id] * PI / 2.0), Vector3.ZERO) * xf
	var src: Mesh = mi.mesh
	root.free()

	var lift: Vector3 = Vector3(0.0, 0.5, 0.0)
	if not is_cube(id):
		# Stand the model on the cell floor, centred on the cell
		var bounds: AABB = xf * src.get_aabb()
		lift = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z)
		if has_facing(id):
			# Props are drawn on the kit's grid: a door keeps to its cell side
			lift = Vector3(0.0, -bounds.position.y, 0.0)
	var out: ArrayMesh = ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays: Array = src.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for k in verts.size():
			verts[k] = xf * verts[k] + lift
		for k in normals.size():
			normals[k] = (xf.basis * normals[k]).normalized()
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TANGENT] = null
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(s, src.surface_get_material(s))
	if TINTS.has(id):
		var tint: StandardMaterial3D = StandardMaterial3D.new()
		tint.albedo_color = TINTS[id]
		tint.roughness = 1.0
		out.surface_set_material(0, tint)
	return out
