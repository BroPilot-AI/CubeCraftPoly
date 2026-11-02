class_name ItemPop
extends MeshInstance3D

## A picked up item flying in an arc from where it was to the player's chest,
## shrinking as it goes, then gone.

## Seconds the flight takes
const FLY_TIME: float = 0.25
## Blocks the arc rises over the straight line at its middle
const ARC: float = 0.5
## Size of the item against a full block when it sets off
const SIZE: float = 0.3
## Blocks above the player's feet it flies to
const CHEST: float = 1.0

var _player: Player = null
var _from: Vector3 = Vector3.ZERO
var _age: float = 0.0


## Call before adding it to the tree.
func setup(player: Player, item_id: int, from: Vector3) -> void:
	_player = player
	_from = from
	mesh = BlockDefs.get_mesh(item_id)


func _ready() -> void:
	# Placed at once, so it never shows a frame at the origin
	_fly(0.0)


func _process(delta: float) -> void:
	_age += delta
	if _age >= FLY_TIME:
		queue_free()
		return
	_fly(_age / FLY_TIME)


## Puts it the part t of the way along the arc, smaller the further it is.
func _fly(t: float) -> void:
	var to: Vector3 = _player.global_position + Vector3.UP * CHEST
	global_position = _from.lerp(to, t) + Vector3.UP * ARC * 4.0 * t * (1.0 - t)
	scale = Vector3.ONE * SIZE * (1.0 - t * 0.5)
