class_name CloudRig
extends Node3D

const CLOUD_COUNT: int = 60
const AREA_SIZE: float = 200.0
const CLOUD_HEIGHT: float = 40.0
const DRIFT_SPEED: float = 0.3

@onready var multi_mesh_instance: MultiMeshInstance3D = $Clouds

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _offsets: Array[Vector3] = []


func _ready() -> void:
	_rng.seed = 12345
	_build()


func _build() -> void:
	var mm: MultiMesh = multi_mesh_instance.multimesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false
	mm.mesh = _make_box_mesh()
	mm.instance_count = CLOUD_COUNT
	_offsets.clear()
	for i in CLOUD_COUNT:
		var x: float = _rng.randf_range(-AREA_SIZE * 0.5, AREA_SIZE * 0.5)
		var z: float = _rng.randf_range(-AREA_SIZE * 0.5, AREA_SIZE * 0.5)
		var y: float = CLOUD_HEIGHT + _rng.randf_range(-2.0, 4.0)
		var s: float = _rng.randf_range(0.6, 1.6)
		_offsets.append(Vector3(x, y, z))
		var t: Transform3D = Transform3D(Basis().scaled(Vector3.ONE * s), Vector3(x, y, z))
		mm.set_instance_transform(i, t)


func _process(delta: float) -> void:
	var mm: MultiMesh = multi_mesh_instance.multimesh
	var centre: Vector3 = Vector3.ZERO
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null:
		centre = cam.global_position
	var half: float = AREA_SIZE * 0.5
	for i in CLOUD_COUNT:
		var off: Vector3 = _offsets[i]
		off.x = wrapf(off.x + DRIFT_SPEED * delta, -half, half)
		_offsets[i] = off
		# Tile the cloud field around the camera so the player never walks out of it
		var pos: Vector3 = Vector3(
			centre.x + wrapf(off.x - centre.x, -half, half),
			off.y,
			centre.z + wrapf(off.z - centre.z, -half, half)
		)
		var s: float = mm.get_instance_transform(i).basis.get_scale().x
		var t: Transform3D = Transform3D(Basis().scaled(Vector3.ONE * s), pos)
		mm.set_instance_transform(i, t)


func _make_box_mesh() -> BoxMesh:
	var b: BoxMesh = BoxMesh.new()
	b.size = Vector3(4, 1, 4)
	return b
