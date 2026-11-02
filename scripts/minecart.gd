class_name Minecart
extends Node3D

## A cart that runs along the rails at a steady speed, from the centre of one
## rail cell to the next. It keeps straight on where the track allows, else
## turns the corner, climbs or drops a step on a slope, and stops where the
## track ends. The player that rides it calls advance() each physics frame.

## Blocks per second
const SPEED: float = 6.0

## The rail cell the cart last passed the centre of, and the one it runs to
var cell: Vector3i = Vector3i.ZERO
var next: Vector3i = Vector3i.ZERO
## The side step (x, 0, z) the cart runs along
var heading: Vector3i = Vector3i.ZERO
var moving: bool = false
## 0 at the centre of cell, 1 at the centre of next
var _t: float = 0.0
var _cm: Node3D = null


func _ready() -> void:
	var body: MeshInstance3D = MeshInstance3D.new()
	body.mesh = BlockDefs.get_mesh(BlockDefs.MINECART)
	add_child(body)


## Puts the cart on the rail in start_cell, heading for the joined rail that
## lies nearest the look direction (it stays put on a lone rail).
func setup(cm: Node3D, start_cell: Vector3i, look: Vector3) -> void:
	_cm = cm
	cell = start_cell
	next = start_cell
	var sides: Array[Vector3i] = []
	for s: Vector2i in Connections.SIDES:
		sides.append(Vector3i(s.x, 0, s.y))
	sides.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return Vector3(a).dot(look) > Vector3(b).dot(look))
	for side: Vector3i in sides:
		if _run_toward(side):
			moving = true
			break
	_place()


## Runs the cart on by delta seconds.
func advance(delta: float) -> void:
	if not moving:
		return
	_t += SPEED * delta / _centre(cell).distance_to(_centre(next))
	while _t >= 1.0 and moving:
		_t -= 1.0
		cell = next
		var left: Vector3i = Vector3i(heading.z, 0, -heading.x)
		moving = _run_toward(heading) or _run_toward(left) or _run_toward(-left)
	if not moving:
		_t = 0.0
		next = cell
	_place()


## Heads for the rail one step to the side, at the same height or a step up
## or down. Returns false when there is none.
func _run_toward(side: Vector3i) -> bool:
	for dy: int in [0, 1, -1]:
		var c: Vector3i = cell + side + Vector3i(0, dy, 0)
		if _cm.get_block_at(c) == BlockDefs.RAIL:
			next = c
			heading = side
			return true
	return false


## The point the cart's floor passes over in a rail cell: half a step up on a
## slope (a rail with a rail a step above it, as ChunkRenderer draws it).
func _centre(c: Vector3i) -> Vector3:
	var lift: float = 0.0
	for s: Vector2i in Connections.SIDES:
		if _cm.get_block_at(c + Vector3i(s.x, 1, s.y)) == BlockDefs.RAIL:
			lift = 0.5
	return Vector3(c.x + 0.5, c.y + lift, c.z + 0.5)


func _place() -> void:
	global_position = _centre(cell).lerp(_centre(next), _t)
	# The cart model runs along X
	rotation.y = atan2(-heading.z, heading.x)
