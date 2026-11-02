class_name Raids
extends Node

## Goblin raids on home: once the player has done FROM_QUEST quests, every
## RAID_EVERY-th dawn that finds the player within NEAR_HOME of home brings
## MIN_RAIDERS to MAX_RAIDERS Goblins RING blocks round it, after the player.
## They stay round home (Mob.stay_near), by day too, till the raid ends. When
## every raider died the player is given REWARD Cheese; when one goes any other
## way, or the player dies, the raid just ends.

signal raid_came
signal raid_beaten

## Quests done before raids come, and the dawns from one to the next
const FROM_QUEST: int = 4
const RAID_EVERY: int = 4
## Blocks across the ground from home the player must be within at dawn
const NEAR_HOME: float = 40.0
## Blocks from home the raiders come out, round it
const RING: float = 14.0
const MIN_RAIDERS: int = 4
const MAX_RAIDERS: int = 6
const KIND: String = "Goblin"
## Cheese given for beating a raid
const REWARD: int = 5
## The banners as a raid comes and once it is beaten
const COME_TEXT: String = "Goblins raid your home!"
const BEAT_TEXT: String = "You beat back the raid!"

## The raiders still living while a raid is on, else empty
var raiders: Array[Mob] = []
var _player: Player = null
var _mobs: MobSpawner = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(player: Player, mobs: MobSpawner, day_night: DayNight) -> void:
	_player = player
	_mobs = mobs
	day_night.day_began.connect(_on_day)
	player.died.connect(end)


## True when the dawn of day brings a raid, with quest quests done
static func is_raid_day(quest: int, day: int) -> bool:
	return quest >= FROM_QUEST and day > 0 and day % RAID_EVERY == 0


func _on_day() -> void:
	if not _player.survival or not _player.home.is_finite():
		return
	var off: Vector3 = _player.global_position - _player.home
	if Vector2(off.x, off.z).length() <= NEAR_HOME and is_raid_day(_player.quest, _player.blood_moon.day):
		start()


## Puts the raiders down round home, those with ground to stand on, unless a
## raid is on already.
func start() -> void:
	if not raiders.is_empty():
		return
	var count: int = _rng.randi_range(MIN_RAIDERS, MAX_RAIDERS)
	for i in count:
		var angle: float = TAU * i / count
		var column := Vector2i(floori(_player.home.x + sin(angle) * RING), floori(_player.home.z + cos(angle) * RING))
		var raider: Mob = _mobs.put_at(KIND, column)
		if raider == null:
			continue
		raider.stay_near = _player.home
		raider.died.connect(_on_died.bind(raider))
		raider.tree_exiting.connect(_on_left.bind(raider))
		raiders.append(raider)
	if not raiders.is_empty():
		raid_came.emit()


## Ends the raid with no reward: the raiders left go back to being Goblins.
func end() -> void:
	for raider: Mob in raiders:
		raider.stay_near = Vector3.INF
	raiders.clear()


## A raider killed: killing the last one beats the raid
func _on_died(raider: Mob) -> void:
	if not raiders.has(raider):
		return
	raiders.erase(raider)
	if raiders.is_empty():
		_player.take(Chunk.CHEESE, REWARD, _player.global_position)
		raid_beaten.emit()


## A raider gone without dying ends the raid
func _on_left(raider: Mob) -> void:
	if raiders.has(raider):
		raiders.erase(raider)
		end()
