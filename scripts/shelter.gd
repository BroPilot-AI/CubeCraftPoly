class_name Shelter
extends RefCounted

## Whether a cell is shut in: walled, floored and roofed by solid blocks, with
## a shut door counting as wall and an open one as a gap.

## Most cells a room can have; a bigger space is open land, not a shelter
const MAX_ROOM: int = 64
const SIDES: Array[Vector3i] = [
	Vector3i.LEFT,
	Vector3i.RIGHT,
	Vector3i.UP,
	Vector3i.DOWN,
	Vector3i.FORWARD,
	Vector3i.BACK,
]


## The cells of open room joined to cell, counting it, or 0 when cell is in a
## solid block or its room is open: bigger than MAX_ROOM or up to the sky.
static func room_size(cm: Node3D, cell: Vector3i) -> int:
	if BlockDefs.is_solid(cm.get_block_at(cell)):
		return 0
	var room: Dictionary = {cell: true}
	var todo: Array[Vector3i] = [cell]
	while not todo.is_empty():
		var at: Vector3i = todo.pop_back()
		if at.y >= Chunk.CHUNK_Y - 1:
			return 0
		for side: Vector3i in SIDES:
			var next: Vector3i = at + side
			if room.has(next) or next.y < 0 or BlockDefs.is_solid(cm.get_block_at(next)):
				continue
			if room.size() == MAX_ROOM:
				return 0
			room[next] = true
			todo.append(next)
	return room.size()
