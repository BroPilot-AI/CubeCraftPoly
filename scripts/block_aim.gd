class_name BlockAim
extends RefCounted

## What the crosshair is on: a block in REACH, which the highlight outlines, a
## mob in HIT_REACH, or nothing. The player aims each physics frame, with a ray
## from the eyes.

## Blocks from the eyes a block can be reached at, and a mob hit at
const REACH: float = 6.0
const HIT_REACH: float = 3.5
## The cell while no block is aimed at
const NO_CELL: Vector3i = Vector3i(-1, -1, -1)

## &"block", &"mob" or &"none"
var state: StringName = &"none"
## The world cell of the block aimed at and its chunk, or NO_CELL and null
var cell: Vector3i = NO_CELL
var chunk = null
## Out of the face of the block aimed at
var normal: Vector3 = Vector3.ZERO
## The mob in the crosshair, or null
var mob: Mob = null
## The wireframe cube over the block aimed at
var _highlight: MeshInstance3D = null


func _init(highlight: MeshInstance3D) -> void:
	_highlight = highlight
	_build_highlight()


static func cell_from_hit(hit_pos: Vector3, hit_normal: Vector3) -> Vector3i:
	# Step half a block back into the hit block, then floor (works for negative coords).
	return Vector3i((hit_pos - hit_normal * 0.5).floor())


## Aims at what a ray from origin along forward hits first in space. Returns
## true when the state, the cell or the normal changed.
func update(space: PhysicsDirectSpaceState3D, origin: Vector3, forward: Vector3) -> bool:
	mob = null
	var target: Vector3 = origin + forward * REACH
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, target)
	# Layer 1 = cubes and solid items, layer 4 = plants and flat items, layer 8 = mobs
	query.collision_mask = 13
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result: Dictionary = space.intersect_ray(query)
	if result.is_empty():
		return _set_aim_state(&"none", null, Vector3i.ZERO, Vector3.ZERO)
	var hit_pos: Vector3 = result.position
	var hit_normal: Vector3 = result.normal
	var hit_collider: Object = result.collider
	if hit_collider is Mob:
		if origin.distance_to(hit_pos) > HIT_REACH:
			return _set_aim_state(&"none", null, Vector3i.ZERO, Vector3.ZERO)
		mob = hit_collider
		return _set_aim_state(&"mob", null, Vector3i.ZERO, Vector3.ZERO)
	var hit_chunk: Node3D = _resolve_chunk_from_collider(hit_collider)
	if hit_chunk == null:
		return _set_aim_state(&"none", null, Vector3i.ZERO, Vector3.ZERO)
	var world_cell: Vector3i = cell_from_hit(hit_pos, hit_normal)
	var local: Vector3i = Vector3i(
		posmod(world_cell.x, Chunk.CHUNK_X), world_cell.y, posmod(world_cell.z, Chunk.CHUNK_Z)
	)
	if hit_collider.has_meta("cell"):
		# Item bodies store their cell: the hit point can be outside it
		local = hit_collider.get_meta("cell")
	return _set_aim_state(&"block", hit_chunk, local, hit_normal)


func _resolve_chunk_from_collider(collider: Object) -> Node3D:
	if collider == null:
		return null
	# Hit collider is the chunk's ChunkBody, or an item body under the chunk's Props node.
	var parent: Node = collider.get_parent()
	if parent != null and parent.name == &"Props":
		parent = parent.get_parent()
	if parent != null and parent.get_script() != null and parent is Node3D:
		return parent
	return null


## Aims at new_state, at the cell local in new_chunk for a block. Returns true,
## and moves the highlight, when the state, the cell or the normal changed.
func _set_aim_state(new_state: StringName, new_chunk, local: Vector3i, new_normal: Vector3) -> bool:
	var new_cell: Vector3i = NO_CELL
	if new_chunk != null:
		new_cell = Vector3i(
			(new_chunk.cx * Chunk.CHUNK_X) + local.x, local.y, (new_chunk.cz * Chunk.CHUNK_Z) + local.z
		)
	if new_state == state and new_cell == cell and new_normal == normal:
		return false
	state = new_state
	normal = new_normal
	cell = new_cell
	chunk = new_chunk
	if state == &"block":
		_place_highlight_at(new_chunk, local, new_normal)
	else:
		_highlight.visible = false
	return true


func _place_highlight_at(at_chunk, local: Vector3i, face: Vector3) -> void:
	# The highlight is a unit cube: stretch it over the target's box
	var box: AABB = BlockDefs.get_box(at_chunk.get_block(local), at_chunk.get_facing(local))
	var world_pos: Vector3 = at_chunk.position + Vector3(local) + Vector3(0.5, 0.0, 0.5) + box.get_center()
	_highlight.global_position = world_pos + face * 0.01
	_highlight.scale = box.size
	_highlight.visible = true


func _build_highlight() -> void:
	# World-space wireframe cube: top_level stops it turning with the camera.
	_highlight.top_level = true
	var h: float = 0.502
	var corners: Array[Vector3] = []
	for i in 8:
		corners.append(Vector3(h if i & 1 else -h, h if i & 2 else -h, h if i & 4 else -h))
	var lines: PackedVector3Array = PackedVector3Array()
	for i in 8:
		for bit: int in [1, 2, 4]:
			if (i & bit) == 0:
				lines.append(corners[i])
				lines.append(corners[i | bit])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = lines
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	_highlight.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0, 0, 0, 1)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight.material_override = mat
	_highlight.visible = false
