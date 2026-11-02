class_name BreakOverlay
extends Node3D

## Seconds a knock wobbles the crack for, and how much bigger it starts
const WOBBLE_TIME: float = 0.12
const WOBBLE_GROW: float = 0.08

@onready var mesh_instance: MeshInstance3D = $Box
@onready var mat: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D

var _wobble: Tween = null


func _ready() -> void:
	visible = false


func show_at(world_pos: Vector3, progress: float) -> void:
	if mat != null:
		mat.albedo_color = Color(0, 0, 0, clampf(progress * 0.8, 0.0, 0.8))
	global_position = world_pos
	visible = true


func update_progress(progress: float) -> void:
	if mat != null:
		mat.albedo_color = Color(0, 0, 0, clampf(progress * 0.8, 0.0, 0.8))


## Makes the crack jump a little bigger and ease back, for a knock.
func wobble() -> void:
	if _wobble != null:
		_wobble.kill()
	mesh_instance.scale = Vector3.ONE * (1.0 + WOBBLE_GROW)
	_wobble = create_tween()
	_wobble.tween_property(mesh_instance, "scale", Vector3.ONE, WOBBLE_TIME)


func hide_overlay() -> void:
	visible = false
