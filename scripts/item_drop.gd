class_name ItemDrop
extends Node3D

## An item lying on the ground, turning and bobbing: what a full backpack could
## not take. A survival player standing within PICKUP_RANGE picks it up once
## the backpack has room, and it goes after LIFETIME seconds. It is not saved.

## Seconds before a drop nobody picked up goes
const LIFETIME: float = 300.0
## How near (blocks) the player has to come to pick it up
const PICKUP_RANGE: float = 1.5
## Turns a second
const SPIN_SPEED: float = 0.5
## How high (blocks) it bobs up off the ground
const BOB_HEIGHT: float = 0.2
## Size of the item against a full block
const SIZE: float = 0.3

var item_id: int = 0
var count: int = 0
var _player: Player = null
var _age: float = 0.0
var _mesh: MeshInstance3D = null


## Call before adding the drop to the tree
func setup(player: Player, id: int, how_many: int) -> void:
	_player = player
	item_id = id
	count = how_many


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.mesh = BlockDefs.get_mesh(item_id)
	_mesh.scale = Vector3.ONE * SIZE
	add_child(_mesh)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	_mesh.rotation.y = fmod(_age * SPIN_SPEED, 1.0) * TAU
	_mesh.position.y = BOB_HEIGHT * 0.5 * (1.0 + sin(_age * TAU))
	_try_pickup()


## Into the backpack, as much as fits, when the player stands by it in survival
func _try_pickup() -> void:
	if _player == null or not _player.survival:
		return
	if _player.global_position.distance_to(global_position) > PICKUP_RANGE:
		return
	# A full backpack is left alone, so it does not report a change every frame
	if _player.backpack.room_for(item_id) == 0:
		return
	count = _player.take(item_id, count, global_position)
	if count == 0:
		queue_free()
