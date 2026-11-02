## The monsters the villagers put a bounty on, and the reward for each.
## A bounty is a list: kind, how many, what it pays, how much, and the quest
## that opens it.  A player works through them one at a time, and each one
## has to be claimed before the next opens up.
class_name Bounties
extends RefCounted

const LIST: Array = [
	["Zombie", 3, Chunk.CHEESE, 3, 1],
	["Wolf", 2, Chunk.WOOL, 2, 2],
	["Goblin", 4, Chunk.COAL, 4, 3],
	["Skeleton", 3, Chunk.METAL, 2, 6],
	["Demon", 2, Chunk.CRYSTAL, 2, 6],
	["Yeti", 2, Chunk.DIAMOND, 1, 8],
]

const NONE: String = "No bounty yet."

## How many have been claimed
var done: int = 0
## How many of the current bounty's monsters have been killed
var kills: int = 0


## The bounties a player on the quest at index can be doing: each list is a
## bounty's own
static func open(index: int) -> Array:
	var found: Array = []
	for bounty: Array in LIST:
		if bounty[4] <= index:
			found.append(bounty)
	return found


## The bounty a player is doing next, and none while the ones open have all
## been claimed
func current(index: int) -> Array:
	var opened: Array = open(index)
	if opened.is_empty():
		return []
	return opened[done % opened.size()]


## A kill only counts toward the current bounty, and once that many have
## been killed it does nothing
func count_kill(kind: String, index: int) -> bool:
	var bounty: Array = current(index)
	if bounty.is_empty() or kind != bounty[0] or kills >= bounty[1]:
		return false
	kills += 1
	return true


## The current bounty has been fully killed
func can_claim(index: int) -> bool:
	var bounty: Array = current(index)
	return not bounty.is_empty() and kills >= bounty[1]


## The next bounty, once that many have been killed, and it gives nothing
## back and changes nothing while that is not the case
func claim(index: int) -> Array:
	if not can_claim(index):
		return []
	var bounty: Array = current(index)
	done += 1
	kills = 0
	return bounty


## How a bounty says on the quest screen
static func describe(bounty: Array, kill_count: int) -> String:
	if bounty.is_empty():
		return NONE
	return "Defeat %d %s (%d done)" % [bounty[1], bounty[0], kill_count]


## The save keeps how many bounties have been claimed and how many kills
## have been counted
func to_dict() -> Dictionary:
	return {"done": done, "kills": kills}


## A save that is missing or not as it was written starts the bounties over
func from_dict(saved: Variant) -> void:
	done = 0
	kills = 0
	if typeof(saved) != TYPE_DICTIONARY:
		return
	var value: Variant = saved.get("done")
	if (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and value >= 0:
		done = int(value)
	value = saved.get("kills")
	if (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and value >= 0:
		kills = int(value)
