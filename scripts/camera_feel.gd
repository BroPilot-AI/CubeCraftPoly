class_name CameraFeel
extends RefCounted
## Shakes, dips and widens the player's camera, for the feel of hits, landings
## and sprinting.

## Blocks of shake lost each second
const SHAKE_DECAY: float = 0.4
## Blocks the view dips for each block fallen, at most DIP_MAX, and blocks a
## second it comes back up at
const DIP_PER_BLOCK: float = 0.06
const DIP_MAX: float = 0.3
const DIP_RECOVER: float = 1.2
## Degrees the view widens by while sprinting, and degrees a second it eases at
const SPRINT_FOV: float = 6.0
const FOV_RATE: float = 30.0

## Blocks the camera shakes by now
var shake_left: float = 0.0
## Blocks the view is dipped below the eyes
var dip: float = 0.0
## Degrees added to the field of view
var fov_kick: float = 0.0


## Shakes the camera by strength blocks, unless it already shakes harder.
func shake(strength: float) -> void:
	shake_left = maxf(shake_left, strength)


## Dips the view for a landing after a fall of fall blocks.
func land(fall: float) -> void:
	dip = maxf(dip, minf(fall * DIP_PER_BLOCK, DIP_MAX))


## Moves camera on by delta seconds: shaken, dipped, and with a field of view
## of base_fov, widened while sprinting.
func update(camera: Camera3D, delta: float, sprinting: bool, base_fov: float) -> void:
	shake_left = maxf(0.0, shake_left - SHAKE_DECAY * delta)
	dip = maxf(0.0, dip - DIP_RECOVER * delta)
	fov_kick = move_toward(fov_kick, SPRINT_FOV if sprinting else 0.0, FOV_RATE * delta)
	camera.h_offset = randf_range(-shake_left, shake_left)
	camera.v_offset = randf_range(-shake_left, shake_left) - dip
	camera.fov = base_fov + fov_kick
