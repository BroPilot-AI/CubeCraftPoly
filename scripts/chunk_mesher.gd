class_name ChunkMesher
extends RefCounted

const CHUNK_X: int = 16
const CHUNK_Y: int = 32
const CHUNK_Z: int = 16
const AIR: int = 0
const STRIDES: Array[int] = [1, CHUNK_X, CHUNK_X * CHUNK_Y]

const FACES: Array = [
	{"normal": Vector3(1, 0, 0), "u": 2, "v": 1, "slice": 0, "sign": 1},
	{"normal": Vector3(-1, 0, 0), "u": 2, "v": 1, "slice": 0, "sign": -1},
	{"normal": Vector3(0, 1, 0), "u": 0, "v": 2, "slice": 1, "sign": 1},
	{"normal": Vector3(0, -1, 0), "u": 0, "v": 2, "slice": 1, "sign": -1},
	{"normal": Vector3(0, 0, 1), "u": 0, "v": 1, "slice": 2, "sign": 1},
	{"normal": Vector3(0, 0, -1), "u": 0, "v": 1, "slice": 2, "sign": -1},
]


static func build_mesh(blocks: Array, block_materials: Dictionary) -> ArrayMesh:
	return build(blocks, block_materials)["mesh"]


## {"mesh": ArrayMesh, "faces": PackedVector3Array}. faces are the mesh's
## triangles, for a ConcavePolygonShape3D: create_trimesh_shape would read them
## back from the GPU, which stalls the frame.
static func build(blocks: Array, block_materials: Dictionary) -> Dictionary:
	var mesh: ArrayMesh = ArrayMesh.new()
	var faces: PackedVector3Array = PackedVector3Array()
	var per_block: Dictionary = {}

	for f in 6:
		_mesh_face(f, blocks, per_block)

	for block_id in per_block:
		var data: Dictionary = per_block[block_id]
		if data.indices.is_empty():
			continue
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = data.verts
		arrays[Mesh.ARRAY_TEX_UV] = data.uvs
		arrays[Mesh.ARRAY_NORMAL] = data.normals
		arrays[Mesh.ARRAY_INDEX] = data.indices
		var mat: Material = block_materials.get(block_id, null)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, 0)
		if mat != null:
			mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
		var verts: PackedVector3Array = data.verts
		for i: int in data.indices:
			faces.append(verts[i])

	return {"mesh": mesh, "faces": faces}


static func _mesh_face(face_idx: int, blocks: Array, per_block: Dictionary) -> void:
	var face: Dictionary = FACES[face_idx]
	var sign: int = face.sign
	var u_axis: int = face.u
	var v_axis: int = face.v
	var slice_axis: int = face.slice

	var size_u: int = _axis_size(u_axis)
	var size_v: int = _axis_size(v_axis)
	var num_slices: int = _axis_size(slice_axis)
	var stride_u: int = STRIDES[u_axis]
	var stride_v: int = STRIDES[v_axis]
	var stride_n: int = STRIDES[slice_axis] * sign
	# mask[u * size_v + v] = id of the block whose face is exposed there, or AIR
	var mask: PackedInt32Array = PackedInt32Array()
	mask.resize(size_u * size_v)

	for slice_idx in num_slices:
		var at_edge: bool = slice_idx + sign < 0 or slice_idx + sign >= num_slices
		var slice_base: int = slice_idx * STRIDES[slice_axis]
		for u in size_u:
			for v in size_v:
				var i: int = slice_base + u * stride_u + v * stride_v
				var cell_id: int = blocks[i]
				var exposed: bool = cell_id >= 1 and cell_id <= BlockDefs.LAST_CUBE
				if exposed and not at_edge:
					var n_id: int = blocks[i + stride_n]
					exposed = n_id < 1 or n_id > BlockDefs.LAST_CUBE
				mask[u * size_v + v] = cell_id if exposed else AIR

		for u in size_u:
			for v in size_v:
				var block_id: int = mask[u * size_v + v]
				if block_id == AIR:
					continue
				var w: int = 1
				while u + w < size_u and mask[(u + w) * size_v + v] == block_id:
					w += 1
				var h: int = 1
				var done: bool = false
				while v + h < size_v and not done:
					for du in w:
						if mask[(u + du) * size_v + v + h] != block_id:
							done = true
							break
					if not done:
						h += 1
				_emit_quad(
					face_idx,
					slice_axis,
					slice_idx,
					u_axis,
					u,
					v_axis,
					v,
					w,
					h,
					sign,
					block_id,
					per_block
				)
				for du in w:
					for dv in h:
						mask[(u + du) * size_v + v + dv] = AIR


static func _emit_quad(
	face_idx: int,
	slice_axis: int,
	slice_idx: int,
	u_axis: int,
	u: int,
	v_axis: int,
	v: int,
	w: int,
	h: int,
	sign: int,
	block_id: int,
	per_block: Dictionary
) -> void:
	if not per_block.has(block_id):
		per_block[block_id] = {
			"verts": PackedVector3Array(),
			"uvs": PackedVector2Array(),
			"normals": PackedVector3Array(),
			"indices": PackedInt32Array(),
		}
	var data: Dictionary = per_block[block_id]
	var normal: Vector3 = FACES[face_idx].normal

	var base: Vector3 = Vector3.ZERO
	base[slice_axis] = float(slice_idx) + (1.0 if sign > 0 else 0.0)
	base[u_axis] = float(u)
	base[v_axis] = float(v)
	var p00: Vector3 = base
	var p10: Vector3 = base
	p10[u_axis] += float(w)
	var p11: Vector3 = base
	p11[u_axis] += float(w)
	p11[v_axis] += float(h)
	var p01: Vector3 = base
	p01[v_axis] += float(h)

	var base_idx: int = data.verts.size()
	data.verts.append_array([p00, p10, p11, p01])
	data.uvs.append_array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
	for i in 4:
		data.normals.append(normal)
	var eu: Vector3 = Vector3.ZERO
	eu[u_axis] = 1.0
	var ev: Vector3 = Vector3.ZERO
	ev[v_axis] = 1.0
	if eu.cross(ev).dot(normal) > 0.0:
		data.indices.append_array(
			[base_idx, base_idx + 2, base_idx + 1, base_idx, base_idx + 3, base_idx + 2]
		)
	else:
		data.indices.append_array(
			[base_idx, base_idx + 1, base_idx + 2, base_idx, base_idx + 2, base_idx + 3]
		)


static func _axis_size(axis: int) -> int:
	match axis:
		0:
			return CHUNK_X
		1:
			return CHUNK_Y
		2:
			return CHUNK_Z
	return 0
