class_name ThrownStone
extends Node3D

## A stone a skeleton throws, the kit's Rock made small, or the fire, ice or
## bones a boss throws (BossMoves), a glowing block. It flies straight at where
## the player's chest was when it was thrown, or turned from there, spinning,
## and hurts the player if it meets them, and ice chills them too; a block in
## the way stops it, and after LIFE seconds it is gone. It keeps to the world,
## not to the one that threw it.

## Blocks a second it flies at
const SPEED: float = 12.0
## Seconds it flies for at most
const LIFE: float = 1.5
## Blocks above the player's feet it is aimed at
const AIM_HEIGHT: float = 1.0
## Its size against the kit's Rock, and how fast it spins (radians/s)
const SIZE: float = 0.6
const SPIN: float = 12.0
## What stops it: the world's blocks (1) and the player (2)
const MASK: int = 3
## The fire, ice and bones a boss throws: special: [colour, size in blocks]
const LOOKS: Dictionary = {
	MobDefs.Special.FIRE: [Color(1.0, 0.45, 0.1), Vector3(0.4, 0.4, 0.4)],
	MobDefs.Special.ICE: [Color(0.6, 0.9, 1.0), Vector3(0.2, 0.2, 0.6)],
	MobDefs.Special.BONES: [Color(0.95, 0.92, 0.8), Vector3(0.12, 0.12, 0.6)],
}
## How brightly a boss's throw glows
const GLOW: float = 1.5

var target: Player = null
var damage: int = 0
## Where it was thrown from, which its hit knocks the player away from
var origin: Vector3 = Vector3.ZERO
## Which of LOOKS a boss threw, or -1 for a skeleton's stone
var special: int = -1
var _velocity: Vector3 = Vector3.ZERO
var _life_left: float = LIFE


## Thrown at at from from for hit, as look, one of LOOKS, or a stone for -1,
## and turned turn radians from straight at at.
func _init(at: Player, hit: int, from: Vector3, look: int = -1, turn: float = 0.0) -> void:
	target = at
	damage = hit
	origin = from
	special = look
	top_level = true
	position = from
	_velocity = (at.global_position + Vector3.UP * AIM_HEIGHT - from).normalized().rotated(Vector3.UP, turn) * SPEED
	if look == -1:
		var rock: Node3D = (load(MobDefs.KIT_DIR + "Rock.glb") as PackedScene).instantiate()
		rock.scale = Vector3.ONE * BlockDefs.KIT_SCALE * SIZE
		add_child(rock)
	else:
		add_child(_block(LOOKS[look][0], LOOKS[look][1]))


func _physics_process(delta: float) -> void:
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()
		return
	rotate_x(SPIN * delta)
	var step: Vector3 = _velocity * delta
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position, global_position + step, MASK)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position += step
		return
	if hit.collider == target:
		target.hurt(damage, origin)
		if special == MobDefs.Special.ICE:
			target.chill(Mob.CHILL_TIME)
	queue_free()


## A glowing block of color and size, its long side along the way it flies.
func _block(color: Color, size: Vector3) -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = GLOW
	box.material = material
	var block: MeshInstance3D = MeshInstance3D.new()
	block.mesh = box
	block.rotation.y = atan2(_velocity.x, _velocity.z)
	return block
