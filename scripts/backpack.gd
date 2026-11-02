class_name Backpack
extends RefCounted

## What the player carries: SIZE slots, each an item id and how many of it. The
## first HOTBAR slots are the hotbar. An empty slot holds id 0 and count 0.

signal changed

const SIZE: int = 36
const HOTBAR: int = 9
## Most of one item a slot holds; an item that is only held (a tool, the key,
## the minecart) is one to a slot
const STACK: int = 64

var ids: Array[int] = []
var counts: Array[int] = []


func _init() -> void:
	ids.resize(SIZE)
	ids.fill(0)
	counts.resize(SIZE)
	counts.fill(0)


static func stack_size(id: int) -> int:
	return 1 if BlockDefs.kind(id) == BlockDefs.KIND_ITEM else STACK


## Puts count of id in slot, or empties the slot when count is 0.
func put(slot: int, id: int, count: int) -> void:
	if count <= 0 or id == 0:
		id = 0
		count = 0
	ids[slot] = id
	counts[slot] = count
	changed.emit()


## Adds count of id: onto slots of it first, then into empty slots, the hotbar
## first. Returns how many did not fit.
func add(id: int, count: int) -> int:
	var left: int = count
	var limit: int = stack_size(id)
	for i in SIZE:
		if left > 0 and ids[i] == id and counts[i] < limit:
			var n: int = mini(left, limit - counts[i])
			counts[i] += n
			left -= n
	for i in SIZE:
		if left > 0 and ids[i] == 0:
			var n: int = mini(left, limit)
			ids[i] = id
			counts[i] = n
			left -= n
	if left < count:
		changed.emit()
	return left


## How many of id would fit.
func room_for(id: int) -> int:
	var limit: int = stack_size(id)
	var room: int = 0
	for i in SIZE:
		if ids[i] == id:
			room += limit - counts[i]
		elif ids[i] == 0:
			room += limit
	return room


## How many of id the slots hold in all.
func count_of(id: int) -> int:
	var total: int = 0
	for i in SIZE:
		if ids[i] == id:
			total += counts[i]
	return total


## Takes count of id out of the slots, the last slot first. Takes nothing and
## returns false when there are fewer.
func remove(id: int, count: int) -> bool:
	if count_of(id) < count:
		return false
	var left: int = count
	for i in range(SIZE - 1, -1, -1):
		if left > 0 and ids[i] == id:
			var n: int = mini(left, counts[i])
			left -= n
			counts[i] -= n
			if counts[i] == 0:
				ids[i] = 0
	changed.emit()
	return true


## Takes one item out of slot.
func take_one(slot: int) -> void:
	put(slot, ids[slot], counts[slot] - 1)


## Moves what is in slot from to slot to: onto the same item as far as it fits,
## else the two slots swap.
func move(from: int, to: int) -> void:
	move_to(from, self, to)


## Moves what is in slot from to slot to of other, this backpack or another
## such as a chest's: onto the same item as far as it fits, else the two swap.
func move_to(from: int, other: Backpack, to: int) -> void:
	if (other == self and from == to) or ids[from] == 0:
		return
	var id: int = ids[from]
	var count: int = counts[from]
	if other.ids[to] == id:
		var n: int = mini(count, stack_size(id) - other.counts[to])
		other.put(to, id, other.counts[to] + n)
		put(from, id, count - n)
	else:
		var other_id: int = other.ids[to]
		var other_count: int = other.counts[to]
		other.put(to, id, count)
		put(from, other_id, other_count)


func to_dict() -> Dictionary:
	var slots: Array = []
	for i in SIZE:
		slots.append([ids[i], counts[i]])
	return {"version": 1, "slots": slots}


## Fills the slots from to_dict's output, leaving out any item that is not known.
func from_dict(d: Dictionary) -> void:
	ids.fill(0)
	counts.fill(0)
	var slots_v: Variant = d.get("slots", [])
	if slots_v is Array:
		var slots: Array = slots_v
		for i in mini(slots.size(), SIZE):
			var entry: Variant = slots[i]
			if entry is Array and entry.size() >= 2 and _is_number(entry[0]) and _is_number(entry[1]):
				var id: int = int(entry[0])
				var count: int = int(entry[1])
				if BlockDefs.has_item(id) and count > 0:
					ids[i] = id
					counts[i] = mini(count, stack_size(id))
	changed.emit()


static func _is_number(v: Variant) -> bool:
	return v is int or v is float
