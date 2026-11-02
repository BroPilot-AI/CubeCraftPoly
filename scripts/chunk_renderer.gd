class_name ChunkRenderer
extends RefCounted

## Draws a chunk with the Cube World Kit meshes: one MultiMeshInstance3D per
## block id, one instance per block with at least one side open to a non-cube cell.

const SX: int = 16
const SY: int = 32
const SZ: int = 16
const LAYER: int = SX * SY


## neighbours: block arrays of the chunks at +X, -X, +Z, -Z ([] when not loaded).
## facing: cell index -> quarter turns for props.
static func build(parent: Node3D, blocks: Array, neighbours: Array, facing: Dictionary = {}) -> void:
	apply(parent, transforms_for(blocks, neighbours, facing))


## Block id -> the Transform3Ds of its instances. It touches no nodes, so worker
## threads can run it.
static func transforms_for(blocks: Array, neighbours: Array, facing: Dictionary = {}) -> Dictionary:
	var nb: Array = [[], [], [], []]
	for k in mini(neighbours.size(), 4):
		nb[k] = neighbours[k]
	var transforms: Dictionary = {}
	for z in SZ:
		for y in SY:
			for x in SX:
				var i: int = x + y * SX + z * LAYER
				var id: int = blocks[i]
				if id == 0:
					continue
				if _is_cube(id) and not _is_exposed(blocks, nb, x, y, z, i):
					continue
				if id == BlockDefs.FENCE or id == BlockDefs.RAIL:
					for piece: Array in _joined(blocks, nb, x, y, z, id, facing.get(i, 0)):
						if not transforms.has(piece[0]):
							transforms[piece[0]] = []
						var turned: Basis = Basis(Vector3.UP, piece[1] * PI / 2.0)
						transforms[piece[0]].append(Transform3D(turned, Vector3(x + 0.5, y, z + 0.5)))
					continue
				if not transforms.has(id):
					transforms[id] = []
				var basis: Basis = Basis.IDENTITY
				if BlockDefs.has_random_yaw(id):
					# A fixed angle per cell, so copies of a plant do not all face one way
					basis = Basis(Vector3.UP, deg_to_rad(float(hash(i) % 360)))
				elif facing.has(i):
					basis = Basis(Vector3.UP, facing[i] * PI / 2.0)
				transforms[id].append(Transform3D(basis, Vector3(x + 0.5, y, z + 0.5)))
	return transforms


## Shows transforms (from transforms_for) under parent. Main thread only.
static func apply(parent: Node3D, transforms: Dictionary) -> void:
	for child in parent.get_children():
		if not transforms.has(int(String(child.name))):
			(child as MultiMeshInstance3D).multimesh.instance_count = 0
	for id in transforms:
		var mmi: MultiMeshInstance3D = parent.get_node_or_null(str(id)) as MultiMeshInstance3D
		if mmi == null:
			mmi = MultiMeshInstance3D.new()
			mmi.name = str(id)
			mmi.multimesh = MultiMesh.new()
			mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			mmi.multimesh.mesh = BlockDefs.get_mesh(id)
			parent.add_child(mmi)
		var list: Array = transforms[id]
		mmi.multimesh.instance_count = list.size()
		for k in list.size():
			mmi.multimesh.set_instance_transform(k, list[k])


## The [piece id, quarter turns] that draw the fence or rail at (x, y, z) joined
## to its neighbours. turns is the cell's facing, which a lone piece keeps.
static func _joined(blocks: Array, nb: Array, x: int, y: int, z: int, id: int, turns: int) -> Array:
	var mask: int = 0
	var up: int = 0
	for k in 4:
		var side: Vector2i = Connections.SIDES[k]
		var next: int = _block_at(blocks, nb, x + side.x, y, z + side.y)
		if id == BlockDefs.FENCE:
			# A fence joins other fences and walls
			if next == BlockDefs.FENCE or _is_cube(next):
				mask |= 1 << k
		elif next == BlockDefs.RAIL or _block_at(blocks, nb, x + side.x, y - 1, z + side.y) == BlockDefs.RAIL:
			mask |= 1 << k
		elif _block_at(blocks, nb, x + side.x, y + 1, z + side.y) == BlockDefs.RAIL:
			# The rail there is a step up, so this one slopes up to it
			mask |= 1 << k
			if up == 0:
				up = 1 << k
	if id == BlockDefs.FENCE:
		return Connections.fence(mask, turns)
	# A lone rail runs the way its placer looked
	return [Connections.rail(mask, up, turns + 1)]


## Block id at (x, y, z), which may be one step into a side chunk; 0 when that
## chunk is not loaded or y is out of range.
static func _block_at(blocks: Array, nb: Array, x: int, y: int, z: int) -> int:
	if y < 0 or y >= SY:
		return 0
	var src: Array = blocks
	if x >= SX:
		src = nb[0]
		x -= SX
	elif x < 0:
		src = nb[1]
		x += SX
	elif z >= SZ:
		src = nb[2]
		z -= SZ
	elif z < 0:
		src = nb[3]
		z += SZ
	if src.is_empty():
		return 0
	return src[x + y * SX + z * LAYER]


static func _is_cube(id: int) -> bool:
	return id >= 1 and id <= BlockDefs.LAST_CUBE


static func _is_exposed(blocks: Array, nb: Array, x: int, y: int, z: int, i: int) -> bool:
	if y == SY - 1 or not _is_cube(blocks[i + SX]):
		return true
	if y > 0 and not _is_cube(blocks[i - SX]):
		return true
	if x < SX - 1:
		if not _is_cube(blocks[i + 1]):
			return true
	elif nb[0].is_empty() or not _is_cube(nb[0][i - (SX - 1)]):
		return true
	if x > 0:
		if not _is_cube(blocks[i - 1]):
			return true
	elif nb[1].is_empty() or not _is_cube(nb[1][i + (SX - 1)]):
		return true
	if z < SZ - 1:
		if not _is_cube(blocks[i + LAYER]):
			return true
	elif nb[2].is_empty() or not _is_cube(nb[2][i - (SZ - 1) * LAYER]):
		return true
	if z > 0:
		if not _is_cube(blocks[i - LAYER]):
			return true
	elif nb[3].is_empty() or not _is_cube(nb[3][i + (SZ - 1) * LAYER]):
		return true
	return false
