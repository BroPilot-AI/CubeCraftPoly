class_name WizardLook
extends RefCounted

## Dresses Steve's model as the Wizard, as the kit has no model of him: a tall
## pointed blue hat with a gold tip, a white beard and a blue robe, made of
## boxes. Each piece hangs on a bone, so it moves as he does.

const HAT: Color = Color(0.16, 0.3, 0.75)
const BRIM: Color = Color(0.1, 0.18, 0.5)
const TIP: Color = Color(1.0, 0.8, 0.2)
const BEARD: Color = Color(0.95, 0.95, 0.92)
const ROBE: Color = Color(0.2, 0.36, 0.8)
## Bone -> its pieces, each [size, middle, colour] in the model's own units,
## where Steve stands 2.66 high facing +Z
const PIECES: Dictionary = {
	"Head": [
		[Vector3(1.15, 0.12, 1.25), Vector3(0.0, 2.72, 0.0), BRIM],
		[Vector3(0.8, 0.4, 0.8), Vector3(0.0, 2.98, -0.02), HAT],
		[Vector3(0.55, 0.4, 0.55), Vector3(0.0, 3.38, -0.08), HAT],
		[Vector3(0.32, 0.4, 0.32), Vector3(0.0, 3.78, -0.16), HAT],
		[Vector3(0.16, 0.16, 0.16), Vector3(0.0, 4.04, -0.22), TIP],
		[Vector3(0.8, 0.45, 0.14), Vector3(0.0, 1.75, 0.64), BEARD],
	],
	"Torso": [
		[Vector3(0.5, 0.35, 0.14), Vector3(0.0, 1.38, 0.42), BEARD],
		[Vector3(0.95, 0.65, 0.8), Vector3(0.0, 1.2, -0.1), ROBE],
	],
	"Hips": [
		[Vector3(1.0, 0.6, 0.85), Vector3(0.0, 0.62, -0.1), ROBE],
	],
}


## Hangs the pieces on model's bones. Each bone's pieces sit in a holder that
## undoes the bone's rest place, so they are put in the model's own units.
static func dress(model: Node3D) -> void:
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	# From the skeleton's units to the model's
	var down: Transform3D = Transform3D.IDENTITY
	var node: Node = skeleton
	while node != model:
		down = (node as Node3D).transform * down
		node = node.get_parent()
	for bone: String in PIECES:
		var on_bone: BoneAttachment3D = BoneAttachment3D.new()
		on_bone.bone_name = bone
		skeleton.add_child(on_bone)
		var holder: Node3D = Node3D.new()
		holder.transform = (down * skeleton.get_bone_global_rest(skeleton.find_bone(bone))).affine_inverse()
		on_bone.add_child(holder)
		for piece: Array in PIECES[bone]:
			holder.add_child(_box(piece))


static func _box(piece: Array) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = piece[0]
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = piece[2]
	material.roughness = 1.0
	mesh.material = material
	var box: MeshInstance3D = MeshInstance3D.new()
	box.mesh = mesh
	box.position = piece[1]
	return box
