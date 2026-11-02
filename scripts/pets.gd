class_name Pets
extends RefCounted

## The animals the player has tamed by feeding them Cheese, one of each kind at
## the most. A tamed dog follows the player and guards them (Mob.tame), a
## tamed cat leads them to chests (CatNose) and a tamed horse is ridden
## (Riding); the spawner puts them back after a load (MobSpawner.keep_pets).

## A mob of kind was tamed
signal tamed(kind: String)

## Cheese it takes to tame each kind
const TAME: Dictionary = {"Dog": 2, "Horse": 3, "Cat": 1}
## The kinds a tamed one follows and guards its owner; a horse waits where it
## was left
const FOLLOWERS: Array[String] = ["Dog"]
const TEXT: String = "The %s is yours!"

## The kinds tamed
var owned: Array[String] = []
## Cheese each untamed mob has had, by its instance id; not saved
var _fed: Dictionary = {}


## Feeds mob one Cheese from the held slot of a player in survival, and tames it
## once it has had as much as its kind takes. Returns false, and takes nothing,
## when the player holds no Cheese, or the mob is not a live untamed one of a
## kind that tames and is not owned yet.
func feed(player: Player, mob: Mob) -> bool:
	if mob == null or not player.survival or player.held() != Chunk.CHEESE:
		return false
	if not TAME.has(mob.kind) or mob.tamed or mob.health <= 0 or owned.has(mob.kind):
		return false
	player.backpack.take_one(player.current_slot)
	var id: int = mob.get_instance_id()
	_fed[id] = _fed.get(id, 0) + 1
	if _fed[id] >= TAME[mob.kind]:
		_fed.erase(id)
		mob.tame(player)
		owned.append(mob.kind)
		tamed.emit(mob.kind)
	return true


func to_dict() -> Dictionary:
	return {"owned": owned.duplicate()}


## A save that is missing or not as it was written owns none
func from_dict(saved: Variant) -> void:
	owned = []
	if not saved is Dictionary or not saved.get("owned") is Array:
		return
	for kind: Variant in saved.get("owned"):
		if kind is String and TAME.has(kind) and not owned.has(kind):
			owned.append(kind)
