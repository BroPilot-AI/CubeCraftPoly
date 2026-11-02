class_name ShockRing
extends Node3D

## The warning on the ground before a boss's slam lands (BossMoves): a ring as
## wide as the slam reaches, filling from the middle until it lands, then
## fading. It keeps to the world, not to the boss.

## Blocks wide the ring's edge is
const LINE: float = 0.15
## Blocks above the ground it is drawn, so it shows over the blocks
const LIFT: float = 0.05
## How solid the edge and the fill are, 0 to 1
const EDGE_ALPHA: float = 0.9
const FILL_ALPHA: float = 0.35
## Blocks thick the fill is
const FILL_HEIGHT: float = 0.02
## The fill's size at first, against its whole size
const FILL_START: float = 0.01
## Seconds it fades for once the slam lands
const FADE_TIME: float = 0.4

var _fill: MeshInstance3D = null
var _warn: float = 0.0


## A ring radius blocks wide in color, that fills over warn seconds.
func _init(radius: float, color: Color, warn: float) -> void:
	top_level = true
	_warn = warn
	var edge: TorusMesh = TorusMesh.new()
	edge.inner_radius = radius - LINE
	edge.outer_radius = radius
	add_child(_mesh(edge, color, EDGE_ALPHA))
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = FILL_HEIGHT
	_fill = _mesh(disc, color, FILL_ALPHA)
	_fill.scale = Vector3(FILL_START, 1.0, FILL_START)
	add_child(_fill)


func _ready() -> void:
	create_tween().tween_property(_fill, "scale", Vector3.ONE, _warn)


## The slam landed: it fades, then is gone.
func burst() -> void:
	var fade: Tween = create_tween().set_parallel()
	for mesh: Node in get_children():
		fade.tween_property((mesh as MeshInstance3D).material_override, "albedo_color:a", 0.0, FADE_TIME)
	fade.chain().tween_callback(queue_free)


## A flat see-through mesh of shape in color, alpha solid, that casts no shadow.
func _mesh(shape: PrimitiveMesh, color: Color, alpha: float) -> MeshInstance3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(color, alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = material
	mesh.position.y = LIFT
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh
