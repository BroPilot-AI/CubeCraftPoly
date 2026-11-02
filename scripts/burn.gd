class_name Burn
extends Node

## A monster on fire from a Flame Blade's hit (Gifts.FLAME): it glows orange
## with flames rising off it, and loses a point of health each BURN_EVERY
## seconds for BURN_TIME, but never its last, so the player's killing blow
## still gets its drop. Neither a boss nor an animal or villager burns.

const BURN_TIME: float = 3.0
const BURN_EVERY: float = 1.0
const GLOW: Color = Color(1.0, 0.45, 0.05, 0.35)
const FLAME: Color = Color(1.0, 0.55, 0.1)
## Flames rising off it at once, each FLAME_SIZE across for FLAME_TIME
const FLAMES: int = 12
const FLAME_SIZE: float = 0.12
const FLAME_TIME: float = 0.6
const FLAME_RISE: float = 1.5

## Seconds it burns on for
var left: float = BURN_TIME
var _mob: Mob = null
var _tick_left: float = BURN_EVERY


## The fire on mob, or null when it is not burning.
static func of(mob: Mob) -> Burn:
	for child: Node in mob.get_children():
		if child is Burn and not child.is_queued_for_deletion():
			return child
	return null


## Sets mob on fire for BURN_TIME, or keeps it burning that long again when it
## already is. Returns whether it burns: a boss, an animal, a villager or a
## dead monster does not.
static func light(mob: Mob) -> bool:
	if mob.boss != -1 or not MobDefs.is_hostile(mob.kind) or mob.health <= 0:
		return false
	var burn: Burn = of(mob)
	if burn == null:
		burn = Burn.new(mob)
		mob.add_child(burn)
	burn.left = BURN_TIME
	return true


func _init(mob: Mob) -> void:
	_mob = mob
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.albedo_color = GLOW
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mob.show_glow(glow)
	_mob.add_child(_flames())


func _physics_process(delta: float) -> void:
	tick(delta)


## Burns on for delta seconds, taking a point off each BURN_EVERY, and goes
## out at the end, or when the monster dies.
func tick(delta: float) -> void:
	left -= delta
	_tick_left -= delta
	while _tick_left <= 0.0:
		_tick_left += BURN_EVERY
		if _mob.health > 1:
			_mob.health -= 1
	if left <= 0.0 or _mob.health <= 0:
		_mob.show_glow(null)
		queue_free()


## Little orange boxes rising off the monster's body, gone with the fire.
func _flames() -> CPUParticles3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE * FLAME_SIZE
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = FLAME
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material = material
	var flames: CPUParticles3D = CPUParticles3D.new()
	flames.mesh = box
	flames.amount = FLAMES
	flames.lifetime = FLAME_TIME
	var body: Vector3 = MobDefs.body_size(_mob.kind) * _mob.size
	flames.position.y = body.y / 2.0
	flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	flames.emission_box_extents = body / 2.0
	flames.direction = Vector3.UP
	flames.spread = 15.0
	flames.gravity = Vector3.ZERO
	flames.initial_velocity_min = FLAME_RISE * 0.5
	flames.initial_velocity_max = FLAME_RISE
	flames.scale_amount_min = 0.5
	tree_exiting.connect(flames.queue_free)
	return flames
