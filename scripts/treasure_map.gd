class_name TreasureMap
extends RefCounted

## A treasure map a villager gives with a request from the FROM_QUEST quest on:
## a spot some way off where an Old Chest is buried once the player comes near.
## Opening or breaking that chest ends the map.

## The quest from which a request handed in gives a map
const FROM_QUEST: int = 2
## How far from the player, in blocks, the treasure is put
const NEAR: float = 60.0
const FAR: float = 110.0
## How near, in blocks, the player comes before the chest goes in
const BURY_AT: float = 24.0
const TEXT: String = "Treasure: %d blocks %s"
const FOUND: String = "You found the treasure!"
## The eight ways, turning from north (-z) toward east (+x)
const WAYS: Array[String] = ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]

## Where the treasure is, as (x, z)
var spot: Vector2i = Vector2i.ZERO
## True while there is a map to follow
var active: bool = false
## True once the Old Chest is in the ground, at buried_at
var buried: bool = false
var buried_at: Vector3i = Vector3i.ZERO


## A new map to a spot NEAR to FAR blocks from from, in a random direction.
func make(from: Vector3, rng: RandomNumberGenerator) -> void:
	var angle: float = rng.randf() * TAU
	var far: float = rng.randf_range(NEAR, FAR)
	spot = Vector2i(floori(from.x + cos(angle) * far), floori(from.z + sin(angle) * far))
	active = true
	buried = false


## Buries the Old Chest in place of the top block at the spot once the player
## at is within BURY_AT blocks and its chunk is loaded. Returns true once, when
## the buried chest has been opened or broken: the map is then done.
func update(cm: Node3D, at: Vector3) -> bool:
	if not active:
		return false
	if buried:
		if not _loaded(cm, buried_at) or cm.get_block_at(buried_at) == BlockDefs.OLD_CHEST:
			return false
		active = false
		return true
	var top := Vector3i(spot.x, Chunk.CHUNK_Y - 1, spot.y)
	if Vector2(at.x, at.z).distance_to(_center()) > BURY_AT or not _loaded(cm, top):
		return false
	while top.y >= 0 and cm.get_block_at(top) == Chunk.AIR:
		top.y -= 1
	if top.y >= 0:
		cm.set_block_at(top, BlockDefs.OLD_CHEST)
		buried = true
		buried_at = top
	return false


## Which way to is from from, as one of WAYS.
static func direction(from: Vector3, to: Vector2i) -> String:
	var off: Vector2 = Vector2(to.x + 0.5 - from.x, to.y + 0.5 - from.z)
	var turned: float = atan2(off.x, -off.y)
	return WAYS[posmod(roundi(turned / (TAU / WAYS.size())), WAYS.size())]


## How far and which way the treasure is from at, or "" with no map.
func describe(at: Vector3) -> String:
	if not active:
		return ""
	return TEXT % [roundi(Vector2(at.x, at.z).distance_to(_center())), direction(at, spot)]


func to_dict() -> Dictionary:
	return {"spot": [spot.x, spot.y], "active": active, "buried": buried, "at": [buried_at.x, buried_at.y, buried_at.z]}


## A save that is missing or not as it was written has no map
func from_dict(saved: Variant) -> void:
	active = false
	buried = false
	if not saved is Dictionary or not saved.get("active") is bool or not saved.get("active"):
		return
	var at: Variant = saved.get("spot")
	if not _numbers(at, 2):
		return
	spot = Vector2i(int(at[0]), int(at[1]))
	active = true
	at = saved.get("at")
	if saved.get("buried") is bool and saved.get("buried") and _numbers(at, 3):
		buried = true
		buried_at = Vector3i(int(at[0]), int(at[1]), int(at[2]))


func _center() -> Vector2:
	return Vector2(spot) + Vector2(0.5, 0.5)


static func _loaded(cm: Node3D, cell: Vector3i) -> bool:
	return cm.active_chunks.has(cm.world_cell_to_chunk_key(cell))


static func _numbers(list: Variant, size: int) -> bool:
	return list is Array and list.size() == size and list.all(func(n: Variant) -> bool: return n is int or n is float)
