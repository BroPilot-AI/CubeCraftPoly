class_name Riding
extends RefCounted

## The tamed horse the player rides, and where it waits when nobody does. The
## player gets on it by using it, steers it the way they look, jumps it and
## gets off with sneak; a hit throws them off, and they cannot get back on for
## KNOCK_OFF_TIME. The spawner puts the horse back where it waits after a load
## (MobSpawner.keep_pets).

## The kind that can be ridden
const KIND: String = "Horse"
## Height of the player's feet above the horse's
const SEAT: float = 1.0
## Seconds after a throw before the player can get on again
const KNOCK_OFF_TIME: float = 1.0

## The horse ridden, or null
var horse: Mob = null
## Where the tamed horse waits while nobody rides it, or INF before it has
## stood anywhere; saved
var left_at: Vector3 = Vector3.INF
## Seconds until the player can get on again
var _no_mount: float = 0.0


## True for a tamed horse while nobody rides one and no throw is fresh.
func can_mount(mob: Mob) -> bool:
	return mob != null and mob.tamed and mob.kind == KIND and horse == null and _no_mount <= 0.0


## Gets the player on mob when can_mount allows it. Returns whether they got on.
func try_mount(player: Player, mob: Mob) -> bool:
	if not can_mount(mob):
		return false
	mount(player, mob)
	return true


## Puts the player on mob; the two pass through each other.
func mount(player: Player, mob: Mob) -> void:
	horse = mob
	mob.rider = player
	player.add_collision_exception_with(mob)
	mob.add_collision_exception_with(player)


## Moves the horse ridden along way, jumping it when jump, and the player with
## it, SEAT above it and still.
func carry(player: Player, way: Vector3, jump: bool, delta: float) -> void:
	_no_mount -= delta
	if horse == null:
		return
	horse.ride(way, jump, delta)
	player.global_position = horse.global_position + Vector3.UP * SEAT
	player.velocity = Vector3.ZERO


## Puts the player down where the horse stands, and the horse waits there.
func get_off(player: Player) -> void:
	if horse == null:
		return
	player.global_position = horse.global_position
	player.velocity = Vector3.ZERO
	left_at = horse.global_position
	player.remove_collision_exception_with(horse)
	horse.remove_collision_exception_with(player)
	horse.rider = null
	horse = null


## A hit throws a rider off, and they cannot get back on for KNOCK_OFF_TIME.
func throw_off(player: Player) -> void:
	if horse == null:
		return
	get_off(player)
	_no_mount = KNOCK_OFF_TIME


## Counts down to when the player can get on again, while not riding.
func tick(delta: float) -> void:
	if horse == null:
		_no_mount -= delta


func to_dict() -> Dictionary:
	if is_inf(left_at.x):
		return {}
	return {"left_at": [left_at.x, left_at.y, left_at.z]}


## A save that is missing or not as it was written has the horse wait nowhere
func from_dict(saved: Variant) -> void:
	left_at = Vector3.INF
	if not saved is Dictionary:
		return
	var at: Variant = saved.get("left_at")
	if at is Array and at.size() == 3 and at.all(func(n: Variant) -> bool: return n is int or n is float):
		left_at = Vector3(at[0], at[1], at[2])
