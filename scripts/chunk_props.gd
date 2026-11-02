class_name ChunkProps
extends RefCounted

## Gives every item in a chunk that is not a cube a box body, so the player's
## ray can pick it. Solid items are on layer 1 and also block movement; plants
## and flat items are on PICK_LAYER, which only the ray checks.

const SX: int = 16
const SY: int = 32
const SZ: int = 16
const PICK_LAYER: int = 4


static func build(parent: Node3D, blocks: Array, facing: Dictionary = {}) -> void:
	for child in parent.get_children():
		child.free()
	for z in SZ:
		for y in SY:
			for x in SX:
				var i: int = x + y * SX + z * SX * SY
				var id: int = blocks[i]
				if id == 0 or BlockDefs.is_cube(id):
					continue
				var box: AABB = BlockDefs.get_box(id, facing.get(i, 0))
				var body: StaticBody3D = StaticBody3D.new()
				body.collision_layer = 1 if BlockDefs.is_solid(id) else PICK_LAYER
				body.collision_mask = 0
				body.position = Vector3(x + 0.5, y, z + 0.5) + box.get_center()
				body.set_meta("cell", Vector3i(x, y, z))
				var shape: CollisionShape3D = CollisionShape3D.new()
				var box_shape: BoxShape3D = BoxShape3D.new()
				box_shape.size = box.size
				shape.shape = box_shape
				body.add_child(shape)
				parent.add_child(body)
