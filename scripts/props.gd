class_name Props
extends RefCounted

## What the use button does to the props a player can use: chests, a ruin's
## Old Chests, doors, levers and buttons. In survival each chest holds its own
## slots, kept here by cell; creative keeps no chest slots, as its backpack is
## kept apart from the survival one.

## In survival a chest at cell opened, for its slots to show
signal chest_opened(cell: Vector3i)

## Seconds a button holds the doors next to it open
const BUTTON_TIME: float = 1.5

## Cell -> the Backpack of the chest there
var _chests: Dictionary = {}


## Uses the prop in cell of chunks for player: opens a chest (in survival its
## slots too) or shuts it, opens an Old Chest, opens or shuts a door (a ruin's
## only with the Key in hand), pulls a lever or presses a button. Returns false
## when cell holds none of them.
func use(player: Player, chunks: Node3D, cell: Vector3i) -> bool:
	var id: int = chunks.get_block_at(cell)
	var base: int = BlockDefs.VARIANTS.get(id, id)
	# A shut prop is an OPENS key, so a click on it opens it
	var opening: bool = BlockDefs.OPENS.has(id)
	if base == BlockDefs.CHEST and player.survival:
		set_open(player, chunks, cell, true)
		chest_opened.emit(cell)
	elif base == BlockDefs.CHEST:
		set_open(player, chunks, cell, opening)
	elif id == BlockDefs.OLD_CHEST:
		open_old_chest(player, chunks, cell)
	elif BlockDefs.is_locked(id) and player.held() != BlockDefs.KEY:
		pass
	elif base == BlockDefs.DOOR:
		set_open(player, chunks, cell, opening)
	elif base == BlockDefs.LEVER:
		set_open(player, chunks, cell, opening)
		_open_doors_near(player, chunks, cell, opening)
	elif base == BlockDefs.BUTTON:
		_open_doors_near(player, chunks, cell, true)
		player.get_tree().create_timer(BUTTON_TIME).timeout.connect(_unpress.bind(player, chunks, cell))
	else:
		return false
	return true


## Puts the open or shut model of the prop in cell, keeping its facing. A door
## does not shut on the player.
func set_open(player: Player, chunks: Node3D, cell: Vector3i, open: bool) -> void:
	var id: int = chunks.get_block_at(cell)
	var shut: int = BlockDefs.shut_of(id)
	var new_id: int = BlockDefs.OPENS[shut] if open else shut
	if new_id == id:
		return
	if BlockDefs.is_solid(new_id) and player.would_be_inside(cell):
		return
	chunks.set_block_at(cell, new_id)


## Opens a ruin's Old Chest for good; in survival its land's loot comes out.
func open_old_chest(player: Player, chunks: Node3D, cell: Vector3i) -> void:
	chunks.set_block_at(cell, BlockDefs.OPENS[BlockDefs.CHEST])
	if player.survival:
		for item: Array in Ruins.loot(ChunkGenerator.biome_at(cell.x, cell.z)):
			player.give(item[0], item[1], Vector3(cell) + Vector3(0.5, 1.0, 0.5))


## The slots of the chest at cell, new and empty the first time.
func chest_at(cell: Vector3i) -> Backpack:
	if not _chests.has(cell):
		_chests[cell] = Backpack.new()
	return _chests[cell]


## Shuts the lid of the chest at cell once its slots are put away. An empty
## chest keeps no slots.
func shut_chest(chunks: Node3D, cell: Vector3i) -> void:
	if chunks.get_block_at(cell) == BlockDefs.OPENS[BlockDefs.CHEST]:
		chunks.set_block_at(cell, BlockDefs.CHEST)
	if _chests.has(cell) and _is_empty(_chests[cell]):
		_chests.erase(cell)


## When the block id broken at cell was a chest, drops what it held there.
func spill(player: Player, cell: Vector3i, id: int) -> void:
	if BlockDefs.VARIANTS.get(id, id) != BlockDefs.CHEST or not _chests.has(cell):
		return
	var chest: Backpack = _chests[cell]
	_chests.erase(cell)
	for i in Backpack.SIZE:
		if chest.ids[i] != 0:
			player.items_dropped.emit(chest.ids[i], chest.counts[i], Vector3(cell) + Vector3(0.5, 0.5, 0.5))


## "x,y,z" -> each chest's slots, leaving out empty chests, for the save.
func to_dict() -> Dictionary:
	var d: Dictionary = {}
	for cell: Vector3i in _chests:
		if not _is_empty(_chests[cell]):
			d["%d,%d,%d" % [cell.x, cell.y, cell.z]] = _chests[cell].to_dict()
	return d


## Fills the chests from to_dict's output, leaving out any entry that is not one.
func from_dict(d: Variant) -> void:
	_chests.clear()
	if not d is Dictionary:
		return
	for key: Variant in d:
		var parts: PackedStringArray = str(key).split(",")
		var slots: Variant = d[key]
		var whole: bool = Array(parts).all(func(p: String) -> bool: return p.is_valid_int())
		if parts.size() != 3 or not slots is Dictionary or not whole:
			continue
		var chest: Backpack = Backpack.new()
		chest.from_dict(slots)
		if not _is_empty(chest):
			_chests[Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))] = chest


## Lets the button's doors shut again, unless the game has gone on without them.
func _unpress(player: Player, chunks: Node3D, cell: Vector3i) -> void:
	if is_instance_valid(player) and is_instance_valid(chunks):
		_open_doors_near(player, chunks, cell, false)


## Opens or shuts the doors in the 8 cells around cell (a lever or a button).
func _open_doors_near(player: Player, chunks: Node3D, cell: Vector3i, open: bool) -> void:
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var c: Vector3i = cell + Vector3i(dx, 0, dz)
			var id: int = chunks.get_block_at(c)
			if BlockDefs.VARIANTS.get(id, id) == BlockDefs.DOOR:
				set_open(player, chunks, c, open)


static func _is_empty(chest: Backpack) -> bool:
	return chest.ids.count(0) == Backpack.SIZE
