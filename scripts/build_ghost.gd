class_name BuildGhost
extends Node3D

## See-through boxes by home where the blocks of the build the villagers asked
## for still go (Builds), shown in survival only. Sits at the world's origin,
## and reuses its boxes rather than making new ones each look.

## Seconds between looks at what is built
const TICK: float = 0.5
## A box's side, a little smaller than a block
const SIZE: float = 0.9
const COLOR: Color = Color(1, 1, 1, 0.25)

var _player: Player = null
var _cm: Node3D = null
var _mesh: BoxMesh = null
## The boxes made so far; those past the cells missing are hidden
var _boxes: Array[MeshInstance3D] = []
var _left: float = 0.0


func setup(player: Player, cm: Node3D) -> void:
	_player = player
	_cm = cm
	_mesh = BoxMesh.new()
	_mesh.size = Vector3.ONE * SIZE
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = COLOR
	_mesh.material = material


func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0 or _player == null:
		return
	_left = TICK
	refresh()


## Puts a box at each cell of the current build still missing its block,
## starting the build when it has not, and none when there is no build
func refresh() -> void:
	var missing: Array[Vector3i] = []
	var build: Array = _player.builds.current(_player.quest)
	if _player.survival and not build.is_empty() and _player.builds.start(_cm, _player.home):
		missing = _player.builds.missing(_cm, build)
	while _boxes.size() < missing.size():
		var box: MeshInstance3D = MeshInstance3D.new()
		box.mesh = _mesh
		box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(box)
		_boxes.append(box)
	for i in _boxes.size():
		_boxes[i].visible = i < missing.size()
		if i < missing.size():
			_boxes[i].position = Vector3(missing[i]) + Vector3(0.5, 0.5, 0.5)
