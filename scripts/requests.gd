class_name Requests
extends RefCounted

## Besides the quests, a villager asks each day for some of one thing for some
## of another, like a trade. The requests come in turn from those the quest
## being done has opened; once one is handed in, the next waits for the
## morning after.

const MUSHROOM: int = 23
## Each is [item wanted, how many, item given, how many, the quest that opens
## it]: what is wanted is about by then, and what is given comes in handy.
const LIST: Array = [
	[MUSHROOM, 4, Chunk.CHEESE, 2, 0],
	[Chunk.DIRT, 24, Chunk.CHEESE, 3, 1],
	[Chunk.STONE, 24, Chunk.COAL, 2, 3],
	[Chunk.WOOL, 2, Chunk.CHEESE, 4, 5],
	[Chunk.COAL, 6, Chunk.METAL, 2, 5],
	[Chunk.SAND, 16, Chunk.CRYSTAL, 1, 6],
	[Chunk.SNOW, 16, Chunk.ICE, 2, 7],
	[Chunk.ICE, 4, Chunk.DIAMOND, 1, 8],
]
const WAITING: String = "Come back tomorrow for another request."

## Requests handed in
var done: int = 0
## True from a hand-in to the next morning, when there is no request
var waiting: bool = false


## The requests the quest at index has opened
static func open(index: int) -> Array:
	return LIST.filter(func(request: Array) -> bool: return request[4] <= index)


static func can_hand_in(bp: Backpack, request: Array) -> bool:
	return bp.count_of(request[0]) >= request[1]


## The request as a line of text, such as "Bring 4 Mushroom (have 1)"
static func describe(bp: Backpack, request: Array) -> String:
	var have: int = mini(bp.count_of(request[0]), request[1])
	return "Bring %d %s (have %d)" % [request[1], BlockDefs.display_name(request[0]), have]


## The request asked for on the quest at index
func today(index: int) -> Array:
	var opened: Array = open(index)
	return opened[done % opened.size()]


## Counts a request handed in; the next waits for the morning.
func hand_in() -> void:
	done += 1
	waiting = true


func to_dict() -> Dictionary:
	return {"done": done, "waiting": waiting}


## Fills from what to_dict gave; anything else starts the requests over.
func from_dict(saved: Variant) -> void:
	done = 0
	waiting = false
	if not saved is Dictionary:
		return
	var saved_done: Variant = saved.get("done")
	if saved_done is int or saved_done is float:
		done = maxi(int(saved_done), 0)
	waiting = saved.get("waiting") is bool and saved.get("waiting")
