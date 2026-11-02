class_name DayNight
extends Node3D

## _time 0 = sunrise, 0.25 = noon, 0.5 = sunset, 0.75 = midnight.

## The sun came up on a new day
signal day_began

const MORNING: float = 0.1
const NIGHT_SKY_ENERGY: float = 0.1
## How much darker the world gets at full gloom
const GLOOM_DARKEN: float = 0.6
## How much darker the world gets under full cloud
const OVERCAST_DARKEN: float = 0.35

@export_node_path("DirectionalLight3D") var sun_path: NodePath
@export_node_path("WorldEnvironment") var environment_path: NodePath
## Seconds a whole day and night last
@export var day_length_seconds: float = 1200.0
@export var start_at_dawn: bool = true
@export var max_light_energy: float = 1.1
@export var min_light_energy: float = 0.05
@export var day_light_color: Color = Color(1.0, 0.97, 0.92, 1)
@export var night_light_color: Color = Color(0.45, 0.55, 0.85, 1)

var sun: DirectionalLight3D = null
var environment: WorldEnvironment = null
var _time: float = 0.0
## 0 to 1: how dark a boss has pulled the sky down
var gloom: float = 0.0
## 0 to 1: how much of the sky the weather has clouded over
var overcast: float = 0.0
## Light a lightning strike adds to the world, fading to 0
var flash: float = 0.0
## What the light is multiplied by: red under a Blood Moon, else WHITE
var tint: Color = Color.WHITE


func _ready() -> void:
	if sun_path != NodePath(""):
		sun = get_node_or_null(sun_path) as DirectionalLight3D
	if environment_path != NodePath(""):
		environment = get_node_or_null(environment_path) as WorldEnvironment
	if start_at_dawn:
		_time = MORNING
	_apply_time()


func _process(delta: float) -> void:
	var was: float = _time
	_time = fmod(_time + delta / day_length_seconds, 1.0)
	if _time < was:
		day_began.emit()
	_apply_time()


## True from a little after sunset to a little before sunrise, while there is no daylight.
func is_night() -> bool:
	return daylight() == 0.0


## 0.5 at sunrise and sunset, 1 once the sun is 15 degrees up, 0 at night
func daylight() -> float:
	return clamp(sin(_time * TAU) * 2.0 + 0.5, 0.0, 1.0)


## How far into the day past sunset night falls, and before sunrise it ends:
## where daylight() reaches 0, at a sin of -0.25.
static func night_edge() -> float:
	return asin(0.25) / TAU


## Seconds till night falls by day, or till the day comes by night.
func seconds_to_change() -> float:
	var edge: float = night_edge()
	var change: float = 1.0 - edge if is_night() else 0.5 + edge
	return fposmod(change - _time, 1.0) * day_length_seconds


func _apply_time() -> void:
	var angle: float = _time * TAU
	var light: float = daylight()
	var dark: float = (1.0 - GLOOM_DARKEN * gloom) * (1.0 - OVERCAST_DARKEN * overcast)
	if sun != null:
		# The light points along its -Z: level at sunrise, straight down at noon
		sun.rotation.x = -angle
		sun.light_energy = lerp(min_light_energy, max_light_energy, light) * dark
		sun.light_color = night_light_color.lerp(day_light_color, light) * tint
	if environment != null and environment.environment != null:
		var env: Environment = environment.environment
		env.background_energy_multiplier = lerp(NIGHT_SKY_ENERGY, 1.0, light) * dark
		env.fog_light_energy = env.background_energy_multiplier
		env.ambient_light_color = (night_light_color * tint if sun == null else sun.light_color)
		env.ambient_light_energy = (0.15 + 0.35 * light) * dark + flash
