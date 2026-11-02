class_name Weather
extends Node3D

## The sky: clear most of the time, now and then rain (snow in the snowfields,
## nothing in the desert), and sometimes a storm with lightning and thunder. It
## changes every CHANGE_MIN to CHANGE_MAX seconds. Rain and snow fall from
## HEIGHT above the player over an AREA square, and not under a roof; cloud
## darkens the DayNight while anything falls.

const CLEAR: int = 0
const RAIN: int = 1
const STORM: int = 2
## Seconds from one change of the weather to the next
const CHANGE_MIN: float = 180.0
const CHANGE_MAX: float = 360.0
## At each change, how likely rain and a storm are; else it clears
const RAIN_CHANCE: float = 0.3
const STORM_CHANCE: float = 0.1
## How far above the player rain and snow start, and the width they fall over
const HEIGHT: float = 14.0
const AREA: float = 28.0
## Seconds between looks at the land and the roof
const LOOK: float = 0.5
## How many blocks over the player's head make a roof
const ROOF_REACH: int = 12
## Seconds the cloud takes to come over or clear
const OVERCAST_TIME: float = 10.0
## Seconds from one lightning strike to the next in a storm
const STRIKE_MIN: float = 8.0
const STRIKE_MAX: float = 20.0
## How bright a strike makes the world, and the seconds it fades over
const FLASH: float = 0.8
const FLASH_FADE: float = 0.3
## Seconds from a strike to its thunder
const THUNDER_MIN: float = 0.5
const THUNDER_MAX: float = 2.0
const PARTICLES: int = 500

## CLEAR, RAIN or STORM
var state: int = CLEAR
var _player: Player = null
var _day_night: DayNight = null
var _cm: Node3D = null
## May be null, and then the thunder is not heard
var _sound: SoundBank = null
var _rain: CPUParticles3D = null
var _snow: CPUParticles3D = null
var _change_in: float = CHANGE_MIN
var _look_in: float = 0.0
var _strike_in: float = STRIKE_MAX


func setup(player: Player, day_night: DayNight, cm: Node3D, sound: SoundBank) -> void:
	_player = player
	_day_night = day_night
	_cm = cm
	_sound = sound
	_rain = _make_fall(Vector2(0.03, 0.6), Color(0.75, 0.85, 1.0, 0.5), 20.0, 0.0, 0.7)
	_rain.name = "Rain"
	_snow = _make_fall(Vector2(0.12, 0.12), Color(1.0, 1.0, 1.0, 0.9), 2.0, 15.0, 7.0)
	_snow.name = "Snow"
	_change_in = randf_range(CHANGE_MIN, CHANGE_MAX)


## A particle fall over the AREA square, off at first: quads of size and colour
## dropping at speed, spread degrees off straight down, each for lifetime seconds.
func _make_fall(size: Vector2, colour: Color, speed: float, spread: float, lifetime: float) -> CPUParticles3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = colour
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	var quad: QuadMesh = QuadMesh.new()
	quad.size = size
	quad.material = material
	var fall: CPUParticles3D = CPUParticles3D.new()
	fall.mesh = quad
	fall.amount = PARTICLES
	fall.lifetime = lifetime
	fall.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	fall.emission_box_extents = Vector3(AREA / 2.0, 0.5, AREA / 2.0)
	fall.direction = Vector3.DOWN
	fall.spread = spread
	fall.gravity = Vector3.ZERO
	fall.initial_velocity_min = speed * 0.9
	fall.initial_velocity_max = speed * 1.1
	fall.emitting = false
	add_child(fall)
	return fall


## The weather a change brings for roll, a number from 0 to 1.
static func pick(roll: float) -> int:
	if roll < STORM_CHANCE:
		return STORM
	if roll < STORM_CHANCE + RAIN_CHANCE:
		return RAIN
	return CLEAR


## What falls in state on land: "rain", "snow", or "" for none.
static func falls(weather: int, land: int) -> String:
	if weather == CLEAR or land == ChunkGenerator.BIOME_DESERT:
		return ""
	return "snow" if land == ChunkGenerator.BIOME_SNOW else "rain"


## Turns to weather now, and starts the wait for the next change.
func set_state(weather: int) -> void:
	state = weather
	_change_in = randf_range(CHANGE_MIN, CHANGE_MAX)
	_strike_in = randf_range(STRIKE_MIN, STRIKE_MAX)
	_update_fall()


func _process(delta: float) -> void:
	if _player == null:
		return
	global_position = _player.global_position + Vector3.UP * HEIGHT
	_change_in -= delta
	if _change_in <= 0.0:
		set_state(pick(randf()))
	_look_in -= delta
	if _look_in <= 0.0:
		_look_in = LOOK
		_update_fall()
	var cloud: float = 0.0 if state == CLEAR else 1.0
	_day_night.overcast = move_toward(_day_night.overcast, cloud, delta / OVERCAST_TIME)
	_day_night.flash = move_toward(_day_night.flash, 0.0, delta * FLASH / FLASH_FADE)
	if state == STORM:
		_strike_in -= delta
		if _strike_in <= 0.0:
			_strike()


## Turns the rain and the snow on or off for the player's land and roof.
func _update_fall() -> void:
	var feet: Vector3i = Vector3i(_player.global_position.floor())
	var wanted: String = "" if _roofed(feet) else falls(state, ChunkGenerator.biome_at(feet.x, feet.z))
	if _rain.emitting != (wanted == "rain"):
		_rain.emitting = wanted == "rain"
	if _snow.emitting != (wanted == "snow"):
		_snow.emitting = wanted == "snow"


## Whether any block in the ROOF_REACH over the head of a player standing in
## feet is not air.
func _roofed(feet: Vector3i) -> bool:
	for up in ROOF_REACH:
		if _cm.get_block_at(feet + Vector3i(0, 2 + up, 0)) != Chunk.AIR:
			return true
	return false


## Lights the world up and sends the thunder after it.
func _strike() -> void:
	_strike_in = randf_range(STRIKE_MIN, STRIKE_MAX)
	_day_night.flash = FLASH
	get_tree().create_timer(randf_range(THUNDER_MIN, THUNDER_MAX)).timeout.connect(_thunder)


func _thunder() -> void:
	if _sound != null:
		_sound.play("thunder", _player.global_position)
