class_name HeldHand
extends Node3D

## The item in the selected hotbar slot, held at the bottom right of the
## first-person view. It bobs as the player walks and swings on each use.

const HAND_SIZE: float = 0.3
const HAND_YAW: float = PI / 4.0
## Tools and the key are held by their base, face on, leaning toward the screen centre
const ITEM_HAND_SIZE: float = 0.35
const ITEM_HAND_ROLL: float = 0.5
const ITEM_HAND_DROP: float = 0.12

@onready var model: MeshInstance3D = $HandMesh


func _ready() -> void:
	position = Vector3(0.5, -0.4, -0.7)
	model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Shows the kit model of item_id, scaled to fit a HAND_SIZE box.
func hold(item_id: int) -> void:
	var mesh: Mesh = BlockDefs.get_mesh(item_id)
	model.mesh = mesh
	if mesh == null:
		return
	var aabb: AABB = mesh.get_aabb()
	if BlockDefs.kind(item_id) == BlockDefs.KIND_ITEM:
		var k: float = ITEM_HAND_SIZE / maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		model.basis = Basis(Vector3.BACK, ITEM_HAND_ROLL).scaled(Vector3.ONE * k)
		model.position = Vector3(0.0, -ITEM_HAND_DROP, 0.0)
		return
	var s: float = HAND_SIZE / maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	model.basis = Basis(Vector3.UP, HAND_YAW).scaled(Vector3.ONE * s)
	model.position = -(model.basis * aabb.get_center())


## Bobs while walking at speed, and slowly all the time while flying.
func bob(flying: bool, speed: float) -> void:
	if flying:
		position.y = -0.4 + sin(Time.get_ticks_msec() * 0.005) * 0.02
	else:
		var bob_amount: float = 0.04 if speed > 0.1 else 0.0
		position.y = -0.4 + sin(Time.get_ticks_msec() * 0.01) * bob_amount


func swing() -> void:
	var t: Tween = create_tween()
	t.tween_property(self, "rotation:x", -0.7, 0.06)
	t.tween_property(self, "rotation:x", 0.0, 0.14)
