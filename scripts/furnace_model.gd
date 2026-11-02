class_name FurnaceModel
extends RefCounted

## The furnace's look, put together from kit pieces: a squat grey brick oven
## under a metal plate, with a metal fire door at the front, the fire glowing
## in its mouth and a button above it for the dial. A minecart is sunk in the
## top for the crucible, full of molten ore, and a lever beside it tips it. The
## front is +Z, toward the player who put it down.

## Kit item, scale, turn (Euler angles) and where its origin, the bottom centre
## of its cell, goes in the furnace's cell
const PARTS: Array = [
	[Chunk.GREY_BRICK, Vector3(0.9, 0.7, 0.9), Vector3.ZERO, Vector3(0.0, 0.005, 0.0)],
	[Chunk.METAL, Vector3(0.94, 0.08, 0.94), Vector3.ZERO, Vector3(0.0, 0.69, 0.0)],
	[Chunk.METAL, Vector3(0.56, 0.36, 0.04), Vector3.ZERO, Vector3(0.0, 0.08, 0.452)],
	[BlockDefs.MINECART, Vector3(0.6, 0.6, 0.6), Vector3.ZERO, Vector3(-0.1, 0.532, -0.05)],
	[BlockDefs.BUTTON, Vector3(0.22, 0.22, 0.22), Vector3(PI / 2.0, 0.0, 0.0), Vector3(0.0, 0.57, 0.44)],
	[BlockDefs.LEVER, Vector3(0.35, 0.35, 0.35), Vector3(0.0, PI / 2.0, 0.0), Vector3(0.32, 0.772, 0.2)],
]
const FIRE: Color = Color(1.0, 0.35, 0.05)
const EMBERS: Color = Color(1.0, 0.65, 0.15)
## Boxes of plain colour, and how bright each glows: the mouth, the fire in it
## and the embers at its foot, and the molten ore in the crucible
const BOXES: Array = [
	[AABB(Vector3(-0.21, 0.12, 0.473), Vector3(0.42, 0.26, 0.004)), Color(0.08, 0.05, 0.04), 0.0],
	[AABB(Vector3(-0.18, 0.14, 0.477), Vector3(0.36, 0.2, 0.004)), FIRE, 1.0],
	[AABB(Vector3(-0.16, 0.14, 0.481), Vector3(0.32, 0.06, 0.004)), EMBERS, 1.0],
	[AABB(Vector3(-0.35, 0.77, -0.27), Vector3(0.5, 0.06, 0.44)), FIRE, 1.0],
]


static func build() -> ArrayMesh:
	var out: ArrayMesh = ArrayMesh.new()
	for part: Array in PARTS:
		var xf: Transform3D = Transform3D(Basis.from_euler(part[2]) * Basis.from_scale(part[1]), part[3])
		var mesh: Mesh = BlockDefs.get_mesh(part[0])
		for s in mesh.get_surface_count():
			_add(out, mesh.surface_get_arrays(s), xf, mesh.surface_get_material(s))
	var box: BoxMesh = BoxMesh.new()
	for b: Array in BOXES:
		var at: AABB = b[0]
		var paint: StandardMaterial3D = StandardMaterial3D.new()
		paint.albedo_color = b[1]
		if b[2] > 0.0:
			paint.emission_enabled = true
			paint.emission = b[1]
			paint.emission_energy_multiplier = b[2]
		box.size = at.size
		_add(out, box.get_mesh_arrays(), Transform3D(Basis.IDENTITY, at.get_center()), paint)
	return out


## Adds the surface arrays to out, moved by xf, drawn with material.
static func _add(out: ArrayMesh, arrays: Array, xf: Transform3D, material: Material) -> void:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for k in verts.size():
		verts[k] = xf * verts[k]
	for k in normals.size():
		normals[k] = (xf.basis.inverse().transposed() * normals[k]).normalized()
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = null
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	out.surface_set_material(out.get_surface_count() - 1, material)
