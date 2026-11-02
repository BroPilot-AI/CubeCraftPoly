class_name MobSpawner
extends Node3D

## Keeps animals wandering on the grass about the player, and monsters about.
## Each INTERVAL it lets go of mobs that are far off, and puts down an animal on a
## grass block SPAWN_MIN to SPAWN_MAX blocks away while there are fewer than
## MAX_PASSIVE, and a monster while there are fewer than hostile_cap: twice
## MAX_HOSTILE while a Blood Moon is up (BloodMoon), else MAX_HOSTILE. A monster
## comes up on its land's home ground, HOME_DEPTH blocks inside it, and is one
## of that land's kinds; the meadow's come only at night. While no villager is
## about, the animal put down is a villager. By day, while no hunter is about,
## a pack of PACK hunters may come up on the grass; each hunter is given the
## nearest prey to hunt. Daylight puts an end to the meadow's monsters, but for
## a raid's (Raids), which stay round home and are put down by put_at. A player
## in survival with a sword that hurts a land's boss wakes it, and at night a
## woken boss comes up on its home ground for a player who is BOSS_DEPTH blocks
## inside that land and has not beaten it; one boss at a time, and daylight does
## not end it. A tamed pet is never let go of, and keep_pets puts the player's
## pets back when they are not about: a dog beside them, a horse where it was
## left. The villagers who live at home (residents_of), and the Wizard once he
## has come, are kept there by keep_residents, and never let go of either.

## A Blood Moon came up, and the light turned red
signal blood_moon_rose
## The boss of land woke, for the player has a sword that hurts it
signal boss_woke(land: int)
## A boss came up
signal boss_came(boss: Mob)
## The boss of land was killed
signal boss_beaten(land: int)
## A boss is enraged, at half its health (BossMoves)
signal boss_raged(boss: Mob)

const MAX_PASSIVE: int = 8
const MAX_HOSTILE: int = 6
## Blocks from the player, across the ground
const SPAWN_MIN: float = 12.0
const SPAWN_MAX: float = 32.0
const DESPAWN_DISTANCE: float = 48.0
## Seconds between steps
const INTERVAL: float = 1.0
## Spots tried for each spawn
const TRIES: int = 4
## Blocks a monster comes up inside its land at the least, so none come up on a
## speck of it
const HOME_DEPTH: int = 4
## Blocks inside a land the player must be for its boss to come up
const BOSS_DEPTH: int = 16
## The most blocks a mob climbs from one block to the next
const CLIMB: int = 1
## Hunters in a pack, and the chance each step by day that one comes while no
## hunter is about
const PACK: int = 2
const PACK_CHANCE: float = 0.02
## Blocks from home a resident is put down in
const RESIDENT_NEAR: int = 4

## Plays the pets' barks; with none they are quiet
var sound: SoundBank = null
## The most monsters about: twice MAX_HOSTILE while a Blood Moon is up
var hostile_cap: int = MAX_HOSTILE
var _player: Node3D = null
var _cm: Node3D = null
## Tells night from day; with none it is always day
var _day_night: DayNight = null
var _timer: float = 0.0
## Whether the Blood Moon was up at the last step
var _blood: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(player: Node3D, cm: Node3D, day_night: DayNight = null) -> void:
	_player = player
	_cm = cm
	_day_night = day_night
	_rng.randomize()


func _process(delta: float) -> void:
	if _player == null:
		return
	_timer += delta
	if _timer >= INTERVAL:
		_timer = 0.0
		step()


## Lets go of far mobs, ends the meadow's monsters by day, gives the hunters
## their prey, puts down an animal or a monster when there are too few and by
## day maybe a pack when no hunter is about, wakes the bosses the player has
## the swords for, at night puts down a woken boss when none is about, and puts
## back the player's pets.
func step() -> void:
	var night: bool = _day_night != null and _day_night.is_night()
	_watch_blood_moon(night)
	var passive: int = 0
	var hostile: int = 0
	var villagers: int = 0
	var boss_up: bool = false
	var hunters: Array[Mob] = []
	var prey: Array[Mob] = []
	for mob: Mob in get_children():
		var off: Vector3 = mob.global_position - _player.global_position
		var far: bool = Vector2(off.x, off.z).length() > DESPAWN_DISTANCE and not mob.tamed and is_inf(mob.stay_near.x)
		if far or mob.global_position.y < 0.0:
			mob.queue_free()
		elif mob.tamed:
			# A pet is none of the mobs counted, and no hunter's prey
			continue
		elif mob.boss != -1:
			boss_up = true
		elif MobDefs.hunts(mob.kind):
			hunters.append(mob)
		elif not MobDefs.is_hostile(mob.kind):
			passive += 1
			if Quests.is_villager(mob.kind):
				villagers += 1
			if MobDefs.is_prey(mob.kind):
				prey.append(mob)
		elif night or MobDefs.home_of(mob.kind) != ChunkGenerator.BIOME_MEADOW or not is_inf(mob.stay_near.x):
			hostile += 1
		else:
			mob.hurt(mob.health, mob.global_position)
	_set_prey(hunters, prey)
	if passive < MAX_PASSIVE:
		# Someone to give the quests comes first
		_spawn(Quests.VILLAGERS if villagers == 0 else MobDefs.kinds(false))
	if hostile < hostile_cap:
		_spawn_monster(night)
	if not night and hunters.is_empty() and _rng.randf() < PACK_CHANCE:
		_spawn_pack()
	_wake_bosses()
	if night and not boss_up:
		_spawn_boss()
	var player: Player = _player as Player
	if player != null:
		keep_pets(player.pets, player.riding)
		keep_residents(player.home, residents_of(player))


## The Blood Moon is up while it is night and the player's BloodMoon says it
## is tonight: as it comes up the light turns red and blood_moon_rose is sent,
## and as it goes down the light turns back. Sets hostile_cap.
func _watch_blood_moon(night: bool) -> void:
	var player: Player = _player as Player
	var blood: bool = night and player != null and player.blood_moon.tonight()
	hostile_cap = MAX_HOSTILE * 2 if blood else MAX_HOSTILE
	if blood == _blood:
		return
	_blood = blood
	_day_night.tint = BloodMoon.TINT if blood else Color.WHITE
	if blood:
		blood_moon_rose.emit()


## The kinds who live at the player's home: the villagers their quests brought
## (Village.residents), and the Wizard once the boss that brings him is beaten.
static func residents_of(player: Player) -> Array[String]:
	var kinds: Array[String] = Village.residents(player.quest)
	if player.bosses.beaten.has(Legends.BRINGS_WIZARD):
		kinds.append(MobDefs.WIZARD)
	return kinds


## While the player is within DESPAWN_DISTANCE of home, puts a villager of each
## of kinds that has none living there on the ground within RESIDENT_NEAR of
## home, to stay near it (Mob.stay_near).
func keep_residents(home: Vector3, kinds: Array[String]) -> void:
	var off: Vector3 = _player.global_position - home
	if is_inf(home.x) or Vector2(off.x, off.z).length() > DESPAWN_DISTANCE:
		return
	var living: Array[String] = []
	for mob: Mob in get_children():
		if not is_inf(mob.stay_near.x) and mob.health > 0:
			living.append(mob.kind)
	for kind: String in kinds:
		if living.has(kind):
			continue
		var spot: Vector3i = _near_home(home)
		if spot.y >= 0:
			var one: Array[String] = [kind]
			_put(one, spot).stay_near = home


## A ground cell within RESIDENT_NEAR of home across, tried TRIES times; its y
## is -1 when none was found.
func _near_home(home: Vector3) -> Vector3i:
	for i in TRIES:
		var x: int = floori(home.x) + _rng.randi_range(-RESIDENT_NEAR, RESIDENT_NEAR)
		var z: int = floori(home.z) + _rng.randi_range(-RESIDENT_NEAR, RESIDENT_NEAR)
		var y: int = _ground(x, z)
		if y >= 0:
			return Vector3i(x, y, z)
	return Vector3i(0, -1, 0)


## Puts each kind of pets owned that has no tamed mob about back, tamed by the
## player: a horse where it was left (riding.left_at) once the chunk there is
## loaded, else beside the player. Gives each pet the sound and the time of
## day, and keeps where a horse nobody rides stands.
func keep_pets(pets: Pets, riding: Riding) -> void:
	var about: Dictionary = {}
	for mob: Mob in get_children():
		if mob.tamed and not mob.is_queued_for_deletion():
			about[mob.kind] = mob
	for kind: String in pets.owned:
		var pet: Mob = about.get(kind)
		var at: Vector3 = riding.left_at
		var waits: bool = kind == Riding.KIND and not is_inf(at.x)
		if pet == null and waits and _cm.get_chunk(floori(at.x / Chunk.CHUNK_X), floori(at.z / Chunk.CHUNK_Z)) == null:
			# With no ground there yet it would fall through
			continue
		if pet == null:
			var kinds: Array[String] = [kind]
			pet = _put(kinds, Vector3i(_player.global_position.floor()) + Vector3i.DOWN)
			pet.tame(_player as Player)
			if waits:
				pet.global_position = at
		elif kind == Riding.KIND and pet.rider == null and pet.is_on_floor():
			riding.left_at = pet.global_position
		pet.sound = sound
		pet.chunks = _cm
		pet.day_night = _day_night


## Tries TRIES spots in the ring about the player for a grass block with room
## above it, and puts down a mob of one of kinds there.
func _spawn(kinds: Array[String]) -> void:
	for i in TRIES:
		var spot: Vector3i = _ring_spot()
		if spot.y >= 0 and _cm.get_block_at(spot) == Chunk.GRASS:
			_put(kinds, spot)
			return


## Tries TRIES spots in the ring about the player for its land's home ground with
## room above it, and puts down one of that land's monsters there. By day the
## meadow has none.
func _spawn_monster(night: bool) -> void:
	for i in TRIES:
		var spot: Vector3i = _ring_spot()
		var biome: int = home_land(spot.x, spot.z)
		if biome == -1 or (not night and biome == ChunkGenerator.BIOME_MEADOW):
			continue
		if spot.y >= 0 and _cm.get_block_at(spot) == MobDefs.home_ground(biome):
			_put(MobDefs.monsters_of(biome), spot)
			return


## Tries TRIES spots in the ring about the player for a grass block with room
## above it, and puts down a pack of PACK hunters there, side by side.
func _spawn_pack() -> void:
	for i in TRIES:
		var spot: Vector3i = _ring_spot()
		if spot.y >= 0 and _cm.get_block_at(spot) == Chunk.GRASS:
			for n in PACK:
				var hunter: Mob = _put(MobDefs.HUNTERS, spot)
				hunter.global_position.x = spot.x + (n + 0.5) / PACK
			return


## Gives each hunter whose prey is gone or dead the nearest live one of prey in
## Mob.HUNT_DISTANCE, or none.
static func _set_prey(hunters: Array[Mob], prey: Array[Mob]) -> void:
	for hunter: Mob in hunters:
		if is_instance_valid(hunter.prey) and hunter.prey.health > 0:
			continue
		hunter.prey = null
		var best: float = Mob.HUNT_DISTANCE
		for animal: Mob in prey:
			var far: float = hunter.global_position.distance_to(animal.global_position)
			if animal.health > 0 and far < best:
				best = far
				hunter.prey = animal


## Wakes the bosses a player in survival now has a sword that hurts.
func _wake_bosses() -> void:
	var player: Player = _player as Player
	if player == null or not player.survival:
		return
	for land: int in player.bosses.wake(player.backpack):
		boss_woke.emit(land)


## Puts down the boss of the land a player in survival is BOSS_DEPTH blocks
## inside, when they have woken it and not beaten it, on its home ground in the
## ring about them where its whole width can walk to them, to fight them.
func _spawn_boss() -> void:
	var player: Player = _player as Player
	if player == null or not player.survival:
		return
	var at: Vector3 = player.global_position
	var land: int = home_land(floori(at.x), floori(at.z), BOSS_DEPTH)
	if land == -1 or not player.bosses.woken.has(land) or player.bosses.beaten.has(land):
		return
	for i in TRIES:
		var spot: Vector3i = _ring_spot()
		if spot.y < 0 or home_land(spot.x, spot.z) != land or _cm.get_block_at(spot) != MobDefs.home_ground(land):
			continue
		if not _clear_walk(spot, MobDefs.boss_half_width(land)):
			continue
		fight(land, Vector3(spot.x + 0.5, spot.y + 1, spot.z + 0.5))
		return


## Brings out the boss of land at at, with its fight (BossMoves). It goes after
## the player, comes up again elsewhere when it is stuck (unstick), and is
## beaten when it dies.
func fight(land: int, at: Vector3) -> Mob:
	var boss: Mob = Mob.new(MobDefs.boss_kind(land), land)
	boss.target = _player as Player
	boss.sound = sound
	boss.died.connect(boss_beaten.emit.bind(land))
	boss.stuck.connect(unstick.bind(boss))
	var moves: BossMoves = BossMoves.new(boss, self)
	moves.raged.connect(boss_raged.emit.bind(boss))
	boss.add_child(moves)
	add_child(boss)
	boss.global_position = at
	boss_came.emit(boss)
	return boss


## A spot SPAWN_MIN to SPAWN_MAX blocks from the player across the ground, at the
## height _ground gives it, so y is -1 where there is no ground to stand on.
func _ring_spot() -> Vector3i:
	var angle: float = _rng.randf() * TAU
	var dist: float = _rng.randf_range(SPAWN_MIN, SPAWN_MAX)
	var x: int = floori(_player.global_position.x + sin(angle) * dist)
	var z: int = floori(_player.global_position.z + cos(angle) * dist)
	return Vector3i(x, _ground(x, z), z)


## Moves a boss that is stuck to a spot in the ring about the player where its
## whole width can walk to them, as if it came up again there. It stays where
## it is when none of TRIES spots is clear, as with the player walled in.
func unstick(boss: Mob) -> void:
	for i in TRIES:
		var spot: Vector3i = _ring_spot()
		if spot.y >= 0 and _clear_walk(spot, MobDefs.boss_half_width(boss.boss)):
			boss.global_position = Vector3(spot.x + 0.5, spot.y + 1, spot.z + 0.5)
			boss.velocity = Vector3.ZERO
			return


## Whether a mob half wide standing on spot can walk the ground in a straight
## line to the player: its middle and both its sides, never climbing more than
## CLIMB blocks from one block to the next.
func _clear_walk(spot: Vector3i, half: float = 0.0) -> bool:
	var from: Vector2 = Vector2(spot.x + 0.5, spot.z + 0.5)
	var to: Vector2 = Vector2(_player.global_position.x, _player.global_position.z)
	var side: Vector2 = (to - from).normalized().orthogonal() * half
	for offset: Vector2 in [Vector2.ZERO, side, -side]:
		if not _clear_line(spot.y, from + offset, to + offset):
			return false
	return true


## Whether the ground from from to to, starting at height y, never climbs more
## than CLIMB blocks from one block to the next.
func _clear_line(y: int, from: Vector2, to: Vector2) -> bool:
	var steps: int = ceili(from.distance_to(to))
	var last: int = y
	for i in range(1, steps + 1):
		var at: Vector2 = from.lerp(to, float(i) / steps)
		var top: int = _ground(floori(at.x), floori(at.y))
		if top == -1 or top - last > CLIMB:
			return false
		last = top
	return true


## Puts down a mob of one of kinds standing on the block at spot, and gives it.
func _put(kinds: Array[String], spot: Vector3i) -> Mob:
	var mob: Mob = Mob.new(kinds[_rng.randi() % kinds.size()])
	mob.target = _player as Player
	add_child(mob)
	mob.global_position = Vector3(spot.x + 0.5, spot.y + 1, spot.z + 0.5)
	return mob


## Puts down a mob of kind on the ground of column and gives it, or gives null
## when there is no ground there to stand on.
func put_at(kind: String, column: Vector2i) -> Mob:
	var top: int = _ground(column.x, column.y)
	if top == -1:
		return null
	var one: Array[String] = [kind]
	return _put(one, Vector3i(column.x, top, column.y))


## The land of column (x, z) when it is the same depth blocks off each way
## across the ground, else -1: monsters come up only where this is not -1.
static func home_land(x: int, z: int, depth: int = HOME_DEPTH) -> int:
	var land: int = ChunkGenerator.biome_at(x, z)
	for off: Vector2i in [Vector2i(depth, 0), Vector2i(-depth, 0), Vector2i(0, depth), Vector2i(0, -depth)]:
		if ChunkGenerator.biome_at(x + off.x, z + off.y) != land:
			return -1
	return land


## Height of the top block at (x, z) under any air and plants, when it is a cube
## with two cells of room above it; else -1.
func _ground(x: int, z: int) -> int:
	for y in range(Chunk.CHUNK_Y - 1, -1, -1):
		var id: int = _cm.get_block_at(Vector3i(x, y, z))
		if id == Chunk.AIR or BlockDefs.is_replaceable(id):
			continue
		if BlockDefs.is_cube(id) and y + 2 < Chunk.CHUNK_Y:
			return y
		return -1
	return -1
