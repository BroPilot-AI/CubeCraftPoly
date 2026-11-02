class_name Mob
extends CharacterBody3D

## An animal or monster from the Cube World Kit. It wanders: walks a random way
## for a few seconds or stands, hops up a block in its way and falls under
## gravity. Only the model turns to face the way it walks; the body box stays
## square to the world. A hit knocks it back and flashes it red; an animal runs
## off, a monster flinches, and at no health it falls over and goes in a puff of
## smoke; big monsters take less of the knockback. A monster with a target in
## CHASE_DISTANCE goes after it its own way (MobDefs.Attack): it walks up and
## hits it, stands off and throws stones at it, leaps at it, chills it as it
## hits, or stomps the ground by it. A villager talked to stands and faces the
## player for TALK_TIME. A boss is one of a land's monsters made big
## (MobDefs.BOSSES): it reaches and sees further for its size, takes no
## knockback, and its armor takes each hit's worth down, so only a good enough
## sword hurts it. A boss winds up each attack for WINDUP_TIME, standing still
## and not flinching, and misses a target that has got out of its reach by then. A hunter (the wolf) goes after only a target it sees in
## SIGHT_DISTANCE, and else hunts the prey the spawner gives it: it runs at it,
## bites it until it is dead and stands eating it for EAT_TIME. A tamed mob
## (Pets) follows the player who tamed it and hunts the monsters near them, and
## a tamed dog barks at night at one about. A tamed cat leads its owner to the
## nearest Old Chest still closed (CatNose). A tamed horse stands where it was
## left, and its rider moves it (ride). A villager who lives at home (Village)
## wanders near it (stay_near). The player's Frost slows it (chill_for).

## Fell at no health
signal died
## A boss going after its target has been held in place, by a wall, a tree or a
## climb of more than a block, for STUCK_TIME
signal stuck

const GRAVITY: float = 20.0
## Enough to clear one block
const JUMP_VELOCITY: float = 6.5
## Seconds each wander pick lasts
const WANDER_MIN: float = 2.0
const WANDER_MAX: float = 6.0
## Chance that a wander pick is to stand still
const IDLE_CHANCE: float = 0.4
## Blocks from stay_near a resident wanders in before it walks back
const STAY_RANGE: float = 12.0
## The group every mob is in, so a power can find those near the player
const GROUP: StringName = &"mobs"
## How fast the model turns to face its heading
const TURN_RATE: float = 8.0
## Seconds to blend from one clip to the next
const BLEND: float = 0.2
## Speed (blocks/s) a hit knocks the mob away at, and up at
const KNOCKBACK: float = 4.0
const KNOCKBACK_UP: float = 4.0
## Seconds the knockback carries the mob before it walks again
const KNOCKBACK_TIME: float = 0.3
## Seconds a hit mob freezes for, so the hit lands with weight
const HIT_STOP: float = 0.06
## Seconds a hit mob shows red
const FLASH_TIME: float = 0.25
const HURT_COLOR: Color = Color(1.0, 0.0, 0.0, 0.45)
## Seconds a hit animal runs off, and how much faster than it walks it runs, as
## a hunter does after its target or prey
const FLEE_TIME: float = 4.0
const FLEE_SPEED: float = 2.0
## Seconds a dead mob lies before it goes up in a puff, seconds the puff lasts,
## and seconds the mob takes to shrink away into it
const DEATH_TIME: float = 1.0
const PUFF_TIME: float = 0.5
const SHRINK_TIME: float = 0.25
## Bits of smoke in the puff, their size (blocks) and their color
const PUFF_AMOUNT: int = 20
const PUFF_SIZE: float = 0.2
const PUFF_COLOR: Color = Color(0.95, 0.95, 0.95, 1.0)
## Blocks from its target that a monster goes after it from, and hits it from
const CHASE_DISTANCE: float = 16.0
const ATTACK_REACH: float = 1.4
## Seconds between a monster's hits
const ATTACK_TIME: float = 1.0
## Blocks from its target a skeleton stands and throws from, seconds between
## its throws, and how far up its body (a share of it) the stone leaves from
const THROW_REACH: float = 8.0
const THROW_TIME: float = 2.0
const THROW_HEIGHT: float = 0.8
## Blocks from its target a demon leaps at it from, seconds between its leaps,
## its speed up as it leaps, and blocks short of the target it comes down
const LEAP_REACH: float = 6.0
const LEAP_TIME: float = 3.0
const LEAP_UP: float = 6.0
const LEAP_SHORT: float = 1.0
## Seconds a yeti's hit slows the player for
const CHILL_TIME: float = 3.0
## Blocks from its target a giant stomps from, seconds between its stomps, and
## how many times as hard as a hit a stomp throws the player
const STOMP_REACH: float = 2.2
const STOMP_TIME: float = 2.5
const STOMP_PUSH: float = 2.0
## Most blocks from its target a big giant stomps from, so the Frost Giant
## stomps from within a sword's reach
const STOMP_MOST: float = 3.3
## Seconds a boss winds up an attack before it lands
const WINDUP_TIME: float = 0.6
## Seconds a boss walks at under STUCK_SPEED of its speed before it is stuck
const STUCK_TIME: float = 3.0
const STUCK_SPEED: float = 0.25
## Seconds a villager talked to stands facing the player
const TALK_TIME: float = 10.0
## Blocks from its target a hunter sees it from, with nothing solid in the
## way, and from its prey it hunts it from
const SIGHT_DISTANCE: float = 10.0
const HUNT_DISTANCE: float = 16.0
## Seconds a hunter stands eating what it killed
const EAT_TIME: float = 5.0
## Blocks from its owner a tamed mob walks back from, and is put beside them from
const FOLLOW_NEAR: float = 3.0
const FOLLOW_FAR: float = 24.0
## Blocks from its owner a tamed mob hunts monsters in, and health its bite takes
const GUARD_RANGE: float = 10.0
const PET_BITE: int = 3
## Blocks off a monster a tamed dog barks at, at night, and seconds between barks
const BARK_RANGE: float = 16.0
const BARK_TIME: float = 20.0
## Speed (blocks/s) a ridden horse runs at, and its speed up as it jumps
const RIDE_SPEED: float = 9.5
const RIDE_JUMP: float = 9.5
## Seconds between a tamed cat's sniffs for a chest, and between its meows as
## it leads
const SNIFF_TIME: float = 2.0
const MEOW_TIME: float = 10.0

## Kit model name, a key of MobDefs.MOBS
var kind: String = ""
var health: int = 0
## The level unit direction the mob walks, or zero to stand
var heading: Vector3 = Vector3.ZERO
## The player a monster goes after, or null
var target: Player = null
## The land whose boss this is, or -1
var boss: int = -1
## What the move speed is multiplied by, more than 1 for a boss once it is
## enraged (BossMoves)
var speed_scale: float = 1.0
## Times as big as its kind, which its reach, sight and leaps grow with
var size: float = 1.0
## Health its attack takes off
var strength: int = 0
## How much of each hit does nothing; a hit no stronger does not hurt
var armor: int = 0
## The animal a hunter hunts, or null
var prey: Mob = null
## Fed enough Cheese to follow and guard its owner (Pets.feed)
var tamed: bool = false
## The player a tamed mob follows
var owner_player: Player = null
## Plays a tamed dog's barks and tells it night from day; the spawner gives them
var sound: SoundBank = null
var day_night: DayNight = null
## The world a tamed cat sniffs for chests in; the spawner gives it
var chunks: Node3D = null
## The chest a tamed cat leads its owner to, or INF
var goal: Vector3 = Vector3.INF
## The player riding this horse (Riding), or null
var rider: Player = null
## Home, for a villager who lives there (Village): it wanders within
## STAY_RANGE of it. INF for any other mob.
var stay_near: Vector3 = Vector3.INF
## What the move speed is multiplied by: less than 1 while chilled (chill_for)
var chill: float = 1.0
## Seconds left a boss stands still for one of its special moves (BossMoves)
var hold: float = 0.0
## What a boss glows with over its model (BossMoves), or null
var glow: Material = null
## Seconds left of the chill
var _chill_left: float = 0.0
var _wander_left: float = 0.0
var _fleeing: bool = false
var _knock_left: float = 0.0
var _flash_left: float = 0.0
## Seconds left of the freeze after a hit
var _stop_left: float = 0.0
var _attack_left: float = 0.0
## Seconds until a demon can leap again
var _leap_left: float = 0.0
## Seconds left of a boss's wind-up
var _windup_left: float = 0.0
## Seconds a boss has been held in place while it walks
var _stuck_for: float = 0.0
## Seconds left of a clip that plays through once (a flinch, the fall)
var _once_left: float = 0.0
## Seconds left of a hunter's eating
var _eat_left: float = 0.0
## True while a hunter runs after its target or prey
var _running: bool = false
## Seconds until a tamed dog can bark again
var _bark_left: float = 0.0
## Seconds until a tamed cat sniffs, and meows, again
var _sniff_left: float = 0.0
var _meow_left: float = 0.0
var _model: Node3D = null
var _anims: AnimationPlayer = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## A mob of mob_kind, made the boss of boss_land when that is not -1.
func _init(mob_kind: String = "Pig", boss_land: int = -1) -> void:
	kind = mob_kind
	boss = boss_land
	health = MobDefs.health(kind)
	strength = MobDefs.damage(kind)
	if boss != -1:
		size = MobDefs.boss_size(boss)
		health = MobDefs.boss_health(boss)
		strength = MobDefs.boss_damage(boss)
		armor = MobDefs.boss_armor(boss)
	collision_layer = MobDefs.LAYER
	collision_mask = 1
	var body: Vector3 = MobDefs.body_size(kind) * size
	var box: BoxShape3D = BoxShape3D.new()
	box.size = body
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = box
	shape.position.y = body.y / 2.0
	add_child(shape)
	_model = MobDefs.model(kind).instantiate()
	_model.scale = Vector3.ONE * BlockDefs.KIT_SCALE * size
	if kind == MobDefs.WIZARD:
		WizardLook.dress(_model)
	add_child(_model)
	_anims = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip: String in ["Idle", "Walk", "Run", "Idle_Eating"]:
		var clip_name: String = _clip(clip)
		if clip_name != "":
			_anims.get_animation(clip_name).loop_mode = Animation.LOOP_LINEAR
	_rng.randomize()


func _ready() -> void:
	add_to_group(GROUP)
	_play("Idle")


func _physics_process(delta: float) -> void:
	if rider != null:
		# Its rider moves it (ride)
		return
	if _stop_left > 0.0:
		# Frozen by a hit: no moving, no clocks, no animation
		_stop_left -= delta
		if _stop_left <= 0.0:
			_anims.speed_scale = 1.0
		return
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_tint(false)
	_knock_left -= delta
	_once_left -= delta
	_chill_left -= delta
	if _chill_left <= 0.0:
		chill = 1.0
	if health > 0:
		_wander_left -= delta
		_attack_left -= delta
		_leap_left -= delta
		_eat_left -= delta
		hold -= delta
		if _windup_left > 0.0:
			_windup_left -= delta
			if _windup_left <= 0.0:
				_land()
		_running = false
		if tamed and kind == CatNose.KIND:
			if not _lead(delta):
				_follow()
		elif tamed and Pets.FOLLOWERS.has(kind):
			_guard()
			_bark(delta)
		elif tamed:
			# A horse waits where it was left
			heading = Vector3.ZERO
		elif _target_near():
			_chase()
			_running = MobDefs.hunts(kind)
		elif _eat_left > 0.0:
			heading = Vector3.ZERO
		elif _prey_near():
			_hunt()
			_running = true
		elif _wander_left <= 0.0:
			_wander()
	if _knock_left <= 0.0:
		var speed: float = MobDefs.speed(kind) * (FLEE_SPEED if _fleeing or _running else 1.0) * chill * speed_scale
		velocity.x = heading.x * speed
		velocity.z = heading.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif heading != Vector3.ZERO and is_on_wall():
		velocity.y = JUMP_VELOCITY
	move_and_slide()
	if boss != -1:
		_watch_stuck(delta)
	if health <= 0 or _once_left > 0.0:
		return
	if heading != Vector3.ZERO:
		# The kit models face +Z
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(heading.x, heading.z), minf(1.0, TURN_RATE * delta))
		_play(_walk_clip())
	elif _eat_left > 0.0:
		_play("Idle_Eating")
	else:
		_play("Idle")


## Times how long a walking boss has gone at under STUCK_SPEED of its speed,
## and says it is stuck at STUCK_TIME.
func _watch_stuck(delta: float) -> void:
	var real: Vector3 = get_real_velocity()
	var slow: float = MobDefs.speed(kind) * chill * speed_scale * STUCK_SPEED
	if health <= 0 or heading == Vector3.ZERO or Vector2(real.x, real.z).length() > slow:
		_stuck_for = 0.0
		return
	_stuck_for += delta
	if _stuck_for >= STUCK_TIME:
		_stuck_for = 0.0
		stuck.emit()


## Takes damage from a hit by something at from, less its armor.
func hurt(damage: int, from: Vector3) -> void:
	if health <= 0 or damage <= armor:
		return
	health -= damage - armor
	var away: Vector3 = Vector3(global_position.x - from.x, 0.0, global_position.z - from.z).normalized()
	# Big monsters take a share of the knockback, or none, and a boss none
	var push: float = 0.0 if boss != -1 else MobDefs.knockback(kind)
	velocity = (away * KNOCKBACK + Vector3.UP * KNOCKBACK_UP) * push
	_knock_left = KNOCKBACK_TIME * push
	_flash_left = FLASH_TIME
	_tint(true)
	_stop_left = HIT_STOP
	_anims.speed_scale = 0.0
	if health <= 0:
		_die()
	elif MobDefs.is_hostile(kind):
		# A boss winding up or at a special move does not flinch, so the move
		# stays plain to see
		if not is_busy():
			_play_once("HitRecieve")
	elif away != Vector3.ZERO:
		heading = away
		_fleeing = true
		_wander_left = FLEE_TIME


## Stands still for TALK_TIME, turned to face at.
func face(at: Vector3) -> void:
	heading = Vector3.ZERO
	_fleeing = false
	_wander_left = TALK_TIME
	# The kit models face +Z
	_model.rotation.y = atan2(at.x - global_position.x, at.z - global_position.z)


## True while a boss winds up an attack or stands for a special move.
func is_busy() -> bool:
	return _windup_left > 0.0 or hold > 0.0


## Stands still for seconds facing its target, playing clip through once, for
## a special move.
func hold_for(seconds: float, clip: String) -> void:
	hold = seconds
	heading = Vector3.ZERO
	var to: Vector3 = target.global_position - global_position
	# The kit models face +Z
	_model.rotation.y = atan2(to.x, to.z)
	_play_once(clip)


## Glows with material over its model from now on, under the red of a hit.
func show_glow(material: Material) -> void:
	glow = material
	_tint(_flash_left > 0.0)


## Tamed by a player: one of Pets.FOLLOWERS follows and guards them from now
## on, biting for PET_BITE, a cat leads them to chests and a horse waits to be
## ridden.
func tame(by: Player) -> void:
	tamed = true
	owner_player = by
	strength = PET_BITE
	heading = Vector3.ZERO
	_fleeing = false


## Runs the horse the way its rider steers, along way at RIDE_SPEED, jumping
## it when jump and it is on the floor, and hopping up a block in its way.
func ride(way: Vector3, jump: bool, delta: float) -> void:
	var level: Vector3 = Vector3(way.x, 0.0, way.z).limit_length(1.0)
	velocity.x = level.x * RIDE_SPEED
	velocity.z = level.z * RIDE_SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif jump:
		velocity.y = RIDE_JUMP
	elif level != Vector3.ZERO and is_on_wall():
		velocity.y = JUMP_VELOCITY
	move_and_slide()
	if level == Vector3.ZERO:
		_play("Idle")
		return
	# The kit models face +Z
	_model.rotation.y = lerp_angle(_model.rotation.y, atan2(level.x, level.z), minf(1.0, TURN_RATE * delta))
	_running = true
	_play(_walk_clip())


## Falls over where it stands, out of reach of the aim, and after DEATH_TIME
## goes in a puff.
func _die() -> void:
	heading = Vector3.ZERO
	collision_layer = 0
	_play_once("Death")
	get_tree().create_timer(DEATH_TIME).timeout.connect(_poof)
	died.emit()


## A puff of smoke from the middle of the mob, which shrinks away into it and
## is gone when the puff is over.
func _poof() -> void:
	var puff: CPUParticles3D = _make_puff()
	puff.position.y = MobDefs.body_size(kind).y * size / 2.0
	add_child(puff)
	create_tween().tween_property(_model, "scale", Vector3.ZERO, SHRINK_TIME)
	get_tree().create_timer(PUFF_TIME).timeout.connect(queue_free)


## PUFF_AMOUNT bits of smoke thrown out every way at once, drifting up and
## shrinking to nothing over PUFF_TIME.
func _make_puff() -> CPUParticles3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = PUFF_COLOR
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE * PUFF_SIZE
	box.material = mat
	var shrink: Curve = Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.0))
	var puff: CPUParticles3D = CPUParticles3D.new()
	puff.mesh = box
	puff.amount = PUFF_AMOUNT
	puff.lifetime = PUFF_TIME
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.spread = 180.0
	puff.initial_velocity_min = 1.0
	puff.initial_velocity_max = 2.0
	puff.damping_min = 2.0
	puff.damping_max = 3.0
	puff.gravity = Vector3(0.0, 1.0, 0.0)
	puff.scale_amount_curve = shrink
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	puff.emitting = true
	return puff


## True for a monster with a target in CHASE_DISTANCE, times its size, or for
## a hunter with one in SIGHT_DISTANCE that it sees. A boss, which comes up for
## its target, goes after it from any way off.
func _target_near() -> bool:
	if target == null or not MobDefs.is_hostile(kind):
		return false
	if boss != -1:
		return true
	var far: float = global_position.distance_to(target.global_position)
	if MobDefs.hunts(kind):
		return far < SIGHT_DISTANCE and _sees(target)
	return far < CHASE_DISTANCE * size


## True when nothing solid stands between the top of the mob and the player's
## eyes.
func _sees(player: Player) -> bool:
	var from: Vector3 = global_position + Vector3.UP * MobDefs.body_size(kind).y * size
	# Layer 1 is the blocks and solid props; the player is on another
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, player.global_position + Player.EYE, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## True for a hunter with live prey in HUNT_DISTANCE.
func _prey_near() -> bool:
	return is_instance_valid(prey) and prey.health > 0 and global_position.distance_to(prey.global_position) < HUNT_DISTANCE


## Runs at the prey until it is in ATTACK_REACH, then stands facing it and
## bites it each time it is ready; once the prey is dead it stands eating it
## for EAT_TIME.
func _hunt() -> void:
	var level: Vector3 = Vector3(prey.global_position.x - global_position.x, 0.0, prey.global_position.z - global_position.z)
	if level.length() > ATTACK_REACH:
		heading = level.normalized()
		return
	heading = Vector3.ZERO
	# The kit models face +Z
	_model.rotation.y = atan2(level.x, level.z)
	if _attack_left > 0.0:
		return
	_attack_left = ATTACK_TIME
	_play_once(_attack_clip())
	prey.hurt(strength, global_position)
	if prey.health <= 0:
		prey = null
		_eat_left = EAT_TIME


## A tamed mob hunts the nearest live monster in GUARD_RANGE of its owner,
## running, as a hunter does its prey. Else it walks back to them from further
## than FOLLOW_NEAR, is put beside them from further than FOLLOW_FAR, and stands
## by them.
func _guard() -> void:
	var home: Vector3 = owner_player.global_position
	prey = _monster_near(home, GUARD_RANGE)
	if prey != null:
		_hunt()
		_running = true
		return
	_follow()


## Walks back to the owner from further than FOLLOW_NEAR, is put beside them
## from further than FOLLOW_FAR, and else stands by them.
func _follow() -> void:
	var home: Vector3 = owner_player.global_position
	var level: Vector3 = Vector3(home.x - global_position.x, 0.0, home.z - global_position.z)
	if level.length() > FOLLOW_FAR:
		global_position = home
		heading = Vector3.ZERO
	elif level.length() > FOLLOW_NEAR:
		heading = level.normalized()
	else:
		heading = Vector3.ZERO


## The nearest live monster beside this mob (under the same parent) in reach of
## at, or null.
func _monster_near(at: Vector3, reach: float) -> Mob:
	var best: Mob = null
	var near: float = reach
	for node: Node in get_parent().get_children():
		var mob: Mob = node as Mob
		if mob == null or mob.health <= 0 or not MobDefs.is_hostile(mob.kind):
			continue
		var far: float = mob.global_position.distance_to(at)
		if far < near:
			near = far
			best = mob
	return best


## A tamed cat sniffs for the nearest Old Chest still closed (CatNose) each
## SNIFF_TIME and leads its owner to it: it walks to CatNose.lead_spot, running
## when it is fewer than AHEAD_MIN blocks ahead, and meows each MEOW_TIME. Once
## the owner is within SIT_NEAR of the chest it stands facing it. Returns false
## when it knows of no chest.
func _lead(delta: float) -> bool:
	_sniff_left -= delta
	_meow_left -= delta
	if _sniff_left <= 0.0 and chunks != null:
		_sniff_left = SNIFF_TIME
		goal = CatNose.nearest(chunks, owner_player.global_position, owner_player.treasure)
	if is_inf(goal.x):
		return false
	var home: Vector3 = owner_player.global_position
	if Vector2(goal.x - home.x, goal.z - home.z).length() <= CatNose.SIT_NEAR:
		heading = Vector3.ZERO
		# The kit models face +Z
		_model.rotation.y = atan2(goal.x - global_position.x, goal.z - global_position.z)
		return true
	if Vector2(home.x - global_position.x, home.z - global_position.z).length() > FOLLOW_FAR:
		global_position = home
	var spot: Vector3 = CatNose.lead_spot(home, goal)
	var level := Vector3(spot.x - global_position.x, 0.0, spot.z - global_position.z)
	heading = level.normalized() if level.length() > 1.0 else Vector3.ZERO
	_running = level.length() > CatNose.AHEAD_MAX - CatNose.AHEAD_MIN
	if _meow_left <= 0.0 and sound != null:
		_meow_left = MEOW_TIME
		sound.play("meow", global_position)
	return true


## A tamed dog barks once each BARK_TIME at night while a live monster is in
## BARK_RANGE.
func _bark(delta: float) -> void:
	_bark_left -= delta
	if kind != "Dog" or _bark_left > 0.0 or sound == null or day_night == null:
		return
	if day_night.is_night() and _monster_near(global_position, BARK_RANGE) != null:
		_bark_left = BARK_TIME
		sound.play("bark", global_position)


## Walks at the target until it is in the monster's reach, then stands facing
## it and attacks each time it is ready, a boss winding up first; a demon on
## the ground leaps at a target in LEAP_REACH. Only a thrown stone reaches a
## target high above.
func _chase() -> void:
	if is_busy():
		heading = Vector3.ZERO
		return
	# Measured in the mob's size, so a big one reaches further
	var to: Vector3 = (target.global_position - global_position) / size
	var level: Vector3 = Vector3(to.x, 0.0, to.z)
	var attack: int = MobDefs.attack(kind)
	var far: float = level.length()
	if attack == MobDefs.Attack.LEAP and _leap_left <= 0.0 and is_on_floor() and far > ATTACK_REACH and far < LEAP_REACH:
		_leap(level)
		return
	if far > _reach(attack):
		heading = level.normalized()
		return
	heading = Vector3.ZERO
	# The kit models face +Z
	_model.rotation.y = atan2(level.x, level.z)
	var high: bool = absf(to.y) >= ATTACK_REACH and attack != MobDefs.Attack.THROW
	if _attack_left <= 0.0 and not high:
		_play_once(_attack_clip())
		if boss == -1:
			_attack(attack)
		else:
			_windup_left = WINDUP_TIME


## Blocks from its target the monster attacks from, by its attack. A boss that
## throws walks right up first, so the Skeleton King does not throw from afar,
## and a boss giant stomps from no further than STOMP_MOST.
func _reach(attack: int) -> float:
	match attack:
		MobDefs.Attack.THROW:
			return THROW_REACH if boss == -1 else ATTACK_REACH
		MobDefs.Attack.STOMP:
			return STOMP_REACH if boss == -1 else minf(STOMP_REACH, STOMP_MOST / size)
	return ATTACK_REACH


## Lands a boss's wound-up attack on its target when it is still in reach,
## and else misses and waits to attack again.
func _land() -> void:
	var attack: int = MobDefs.attack(kind)
	var to: Vector3 = (target.global_position - global_position) / size
	if Vector2(to.x, to.z).length() <= _reach(attack) and absf(to.y) < ATTACK_REACH:
		_attack(attack)
	else:
		_attack_left = ATTACK_TIME


## Hits the target, throws a stone at it, chills it as it hits, or stomps,
## throwing it far and raising dust, by attack, then waits to attack again.
func _attack(attack: int) -> void:
	match attack:
		MobDefs.Attack.THROW:
			_attack_left = THROW_TIME
			_throw()
		MobDefs.Attack.STOMP:
			_attack_left = STOMP_TIME
			target.hurt(strength, global_position, STOMP_PUSH)
			var dust: CPUParticles3D = _make_puff()
			dust.finished.connect(dust.queue_free)
			add_child(dust)
		MobDefs.Attack.CHILL:
			_attack_left = ATTACK_TIME
			target.hurt(strength, global_position)
			target.chill(CHILL_TIME)
		_:
			_attack_left = ATTACK_TIME
			target.hurt(strength, global_position)


## Jumps at the target along level, measured in the mob's size, to come down
## LEAP_SHORT of those short of it.
func _leap(level: Vector3) -> void:
	_leap_left = LEAP_TIME
	heading = level.normalized()
	# Seconds in the air, through which the leap carries the demon as a
	# knockback does
	var air: float = 2.0 * LEAP_UP / GRAVITY
	velocity = heading * (level.length() - LEAP_SHORT) * size / air + Vector3.UP * LEAP_UP
	_knock_left = air
	_play_once("Jump")


## Throws a stone at the target from THROW_HEIGHT up the skeleton.
func _throw() -> void:
	var from: Vector3 = global_position + Vector3.UP * MobDefs.body_size(kind).y * size * THROW_HEIGHT
	add_child(ThrownStone.new(target, strength, from))


## Multiplies the move speed by scale for the next seconds
func chill_for(scale: float, seconds: float) -> void:
	chill = scale
	_chill_left = seconds


## Picks what to do for the next few seconds: stand, or walk a random way. A
## resident further than STAY_RANGE from home walks back toward it.
func _wander() -> void:
	_fleeing = false
	_wander_left = _rng.randf_range(WANDER_MIN, WANDER_MAX)
	var back := Vector3(stay_near.x - global_position.x, 0.0, stay_near.z - global_position.z)
	if not is_inf(stay_near.x) and back.length() > STAY_RANGE:
		heading = back.normalized()
	elif _rng.randf() < IDLE_CHANCE:
		heading = Vector3.ZERO
	else:
		var angle: float = _rng.randf() * TAU
		heading = Vector3(sin(angle), 0.0, cos(angle))


## The clip to attack with: Attack, else Headbutt (the wolf).
func _attack_clip() -> String:
	return "Attack" if _clip("Attack") != "" else "Headbutt"


## The clip to walk with: Walk, else Run (the chickens), else Idle (the
## hedgehog). A fleeing mob, or a hunter running after something, runs when it
## can.
func _walk_clip() -> String:
	var order: Array = ["Run", "Walk"] if _fleeing or _running else ["Walk", "Run"]
	for clip: String in order:
		if _clip(clip) != "":
			return clip
	return "Idle"


## Blends to the model's clip ending in |clip, unless it already plays.
func _play(clip: String) -> void:
	var clip_name: String = _clip(clip)
	if clip_name != "" and _anims.current_animation != clip_name:
		_anims.play(clip_name, BLEND)


## Plays the model's clip ending in |clip through once from the start, before
## walking or standing take over again.
func _play_once(clip: String) -> void:
	var clip_name: String = _clip(clip)
	if clip_name == "":
		return
	_anims.play(clip_name, BLEND)
	_anims.seek(0.0, true)
	_once_left = _anims.get_animation(clip_name).length


## Shows the model red after a hit, or clears the red, back to its glow.
func _tint(on: bool) -> void:
	var overlay: Material = glow
	if on:
		overlay = StandardMaterial3D.new()
		overlay.albedo_color = HURT_COLOR
		overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for mesh: Node in _model.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_overlay = overlay


## The full name of the model's clip that ends in |clip, or "" when it has none.
func _clip(clip: String) -> String:
	for clip_name: String in _anims.get_animation_list():
		if clip_name.ends_with("|" + clip):
			return clip_name
	return ""
