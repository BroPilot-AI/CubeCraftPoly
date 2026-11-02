class_name FinalBoss
extends Node

## The last quest: from it on a Big Crystal stands by home, or by the world's
## spawn when there is no home, and at night the Skeleton King comes out beside
## it when the player is near. It fights as a land's boss does (BossMoves),
## calling Skeletons round it, and is beaten as one is
## (MobSpawner.boss_beaten), which wins the game.

## Blocks across the ground from the crystal the player wakes the King within
const NEAR: float = 24.0
## Where the crystal stands from home, across the ground
const CRYSTAL_OFFSET: Vector2i = Vector2i(0, -6)
## Seconds between looks
const EVERY: float = 1.0
## Where the King comes out from the crystal, across the ground
const KING_OFFSET: Vector2i = Vector2i(3, 0)

## The Skeleton King while one is out, else null or freed
var king: Mob = null
var _player: Player = null
var _cm: Node3D = null
var _day_night: DayNight = null
var _mobs: MobSpawner = null
## Whether the crystal was put down, or found there, this game: once mined it
## does not come back, so it cannot be mined over and over
var _crystal_put: bool = false
var _wait: float = 0.0


func setup(player: Player, cm: Node3D, day_night: DayNight, mobs: MobSpawner) -> void:
	_player = player
	_cm = cm
	_day_night = day_night
	_mobs = mobs


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = EVERY
	step()


## On the final quest in survival: puts the crystal down, and brings the King
## out at night when the player is near it and no King is out.
func step() -> void:
	if _player == null or not _player.survival or not Quests.wants_final(_player.quest):
		return
	var column: Vector2i = crystal_column()
	if not _crystal_put:
		_put_crystal(column)
	if is_instance_valid(king) and king.health > 0:
		return
	var off := Vector2(_player.global_position.x - column.x - 0.5, _player.global_position.z - column.y - 0.5)
	if _day_night.is_night() and off.length() <= NEAR:
		_bring_king(column)


## The column the crystal stands in: CRYSTAL_OFFSET from home, or from the
## world's spawn when there is no home
func crystal_column() -> Vector2i:
	var base: Vector3 = _player.home if _player.home.is_finite() else _player.spawn_position
	return Vector2i(floori(base.x), floori(base.z)) + CRYSTAL_OFFSET


## Puts the Big Crystal on the ground of column once it is loaded and the cell
## over it is empty or a plant; one there already counts as put.
func _put_crystal(column: Vector2i) -> void:
	var top: int = Village.ground(_cm, column.x, column.y)
	if top == -1 or top + 1 >= Chunk.CHUNK_Y:
		return
	var cell := Vector3i(column.x, top + 1, column.y)
	var id: int = _cm.get_block_at(cell)
	if _cm.get_block_at(Vector3i(column.x, top, column.y)) == Village.BIG_CRYSTAL:
		_crystal_put = true
	elif id == Chunk.AIR or BlockDefs.is_replaceable(id):
		_cm.set_block_at(cell, Village.BIG_CRYSTAL)
		_crystal_put = true


## Brings the King out KING_OFFSET from the crystal at column, once that ground
## is loaded, to fight the player as a land's boss does (MobSpawner.fight).
func _bring_king(column: Vector2i) -> void:
	var spot: Vector2i = column + KING_OFFSET
	var top: int = Village.ground(_cm, spot.x, spot.y)
	if top == -1:
		return
	king = _mobs.fight(MobDefs.FINAL_LAND, Vector3(spot.x + 0.5, top + 1, spot.y + 0.5))
