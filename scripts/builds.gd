class_name Builds
extends RefCounted

## What the villagers ask to have built by home, one after another once each
## one's quest is reached: first a well, then a watchtower. A build starts on
## the ground at its own spot by home the first time it is looked for there
## (BuildGhost), and pays its reward once every block of it is in place.

## How a layer of a build covers the 3 x 3 cells round its middle
enum Shape { RING, CORNERS, ALL }

## Each [name, the quest that opens it, reward item, count, Array of layers],
## a layer being [block id, Shape, from y, to y] up from the build's ground
const LIST: Array = [
	["A well", 2, Chunk.CRYSTAL, 3, [
		[Chunk.STONE, Shape.RING, 0, 1],
		[Chunk.WOOD_PLANKS, Shape.CORNERS, 2, 3],
		[Chunk.WOOD_PLANKS, Shape.ALL, 4, 4],
	]],
	["A watchtower", 5, Chunk.DIAMOND, 2, [
		[Chunk.WOOD_PLANKS, Shape.RING, 0, 6],
	]],
]
## From home across (x, z) to the first build's middle, outside the village
## fence 7 out, and from each build's middle to the next, so none stands on
## another
const OFFSET: Vector2i = Vector2i(10, 2)
const STEP: Vector2i = Vector2i(0, 5)
const NONE: String = "No build yet."
const UNSET: Vector3i = Vector3i(0, -1, 0)

## How many have been claimed
var done: int = 0
## Where the current build's middle stands, on its ground; UNSET till it starts
var anchor: Vector3i = UNSET


## The build a player on the quest at index is doing, and none before its
## quest or once all are claimed
func current(quest: int) -> Array:
	if done >= LIST.size() or LIST[done][1] > quest:
		return []
	return LIST[done]


## Sets where the current build stands, once: on the ground at its spot by
## home. False while there is no home or that ground is not loaded.
func start(cm: Node3D, home: Vector3) -> bool:
	if anchor != UNSET:
		return true
	if not home.is_finite():
		return false
	var spot: Vector2i = Vector2i(floori(home.x), floori(home.z)) + OFFSET + STEP * done
	var ground: int = Village.ground(cm, spot.x, spot.y)
	if ground == -1:
		return false
	anchor = Vector3i(spot.x, ground + 1, spot.y)
	return true


## Each [Vector3i offset from the anchor, block id] of build; none for none
static func cells(build: Array) -> Array:
	var found: Array = []
	if build.is_empty():
		return found
	for layer: Array in build[4]:
		for y in range(layer[2], layer[3] + 1):
			for x in range(-1, 2):
				for z in range(-1, 2):
					if _covers(layer[1], x, z):
						found.append([Vector3i(x, y, z), layer[0]])
	return found


static func _covers(shape: Shape, x: int, z: int) -> bool:
	match shape:
		Shape.RING:
			return x != 0 or z != 0
		Shape.CORNERS:
			return x != 0 and z != 0
	return true


## The world cells of build's blocks not yet in place; every one of them while
## it has not started
func missing(cm: Node3D, build: Array) -> Array[Vector3i]:
	var found: Array[Vector3i] = []
	for cell: Array in cells(build):
		var at: Vector3i = anchor + cell[0]
		if anchor == UNSET or cm.get_block_at(at) != cell[1]:
			found.append(at)
	return found


## How many of build's cells hold their own block
func placed(cm: Node3D, build: Array) -> int:
	return cells(build).size() - missing(cm, build).size()


## The current build has started and has every block in place
func can_claim(cm: Node3D, quest: int) -> bool:
	var build: Array = current(quest)
	return not build.is_empty() and anchor != UNSET and missing(cm, build).is_empty()


## The build claimed, once can_claim; the next starts at its own spot
func claim() -> Array:
	var build: Array = LIST[done]
	done += 1
	anchor = UNSET
	return build


## How a build says on the villager screen, with have of its blocks in place
static func describe(build: Array, have: int) -> String:
	if build.is_empty():
		return NONE
	return "Build %s by home (%d of %d blocks)" % [build[0], have, cells(build).size()]


## The save keeps how many have been claimed and where the current one stands
func to_dict() -> Dictionary:
	return {"done": done, "anchor": [anchor.x, anchor.y, anchor.z]}


## A save that is missing or not as it was written starts the builds over
func from_dict(saved: Variant) -> void:
	done = 0
	anchor = UNSET
	if typeof(saved) != TYPE_DICTIONARY:
		return
	var value: Variant = saved.get("done")
	if (value is int or value is float) and value >= 0:
		done = mini(int(value), LIST.size())
	var at: Variant = saved.get("anchor")
	if at is Array and at.size() == 3 and at.all(func(n: Variant) -> bool: return n is int or n is float):
		anchor = Vector3i(int(at[0]), int(at[1]), int(at[2]))
