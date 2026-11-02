class_name Ambience
extends Node
## Wind and birdsong by day and crickets by night, faded across with the daylight.

const SAMPLE_RATE: int = SoundBank.SAMPLE_RATE
## Seconds of each loop
const DAY_LENGTH: float = 4.0
const NIGHT_LENGTH: float = 2.0
## How loud each loop plays at full day or full night
const DAY_VOLUME: float = 0.35
const NIGHT_VOLUME: float = 0.3
## How much of each new noise sample the wind takes in; less is a lower rush
const WIND_SMOOTHING: float = 0.05
const WIND_VOLUME: float = 2.0
## Seconds into the day loop a bird sings twice, and the whistle of each chirp
const CHIRPS: Array[float] = [0.4, 2.3, 3.1]
const CHIRP_TIME: float = 0.08
const CHIRP_LOW: float = 2500.0
const CHIRP_HIGH: float = 4000.0
const CHIRP_VOLUME: float = 0.25
## Every CRICKET_EVERY seconds a cricket chirps CRICKET_PULSES short high pulses
const CRICKET_NOTE: float = 4400.0
const CRICKET_PULSE: float = 0.025
const CRICKET_PULSES: int = 3
const CRICKET_EVERY: float = 0.5
const CRICKET_VOLUME: float = 0.3

var day: AudioStreamPlayer = null
var night: AudioStreamPlayer = null
var _day_night: DayNight = null


func _ready() -> void:
	day = _make_loop(SoundBank.to_wav(_day_samples(), true))
	night = _make_loop(SoundBank.to_wav(_night_samples(), true))


## Follows the daylight of day_night.
func setup(day_night: DayNight) -> void:
	_day_night = day_night


func _process(_delta: float) -> void:
	if _day_night == null:
		return
	var light: float = _day_night.daylight()
	day.volume_linear = DAY_VOLUME * light
	night.volume_linear = NIGHT_VOLUME * (1.0 - light)


## A player looping stream, silent till the daylight is known.
func _make_loop(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = "Master"
	p.stream = stream
	p.volume_linear = 0.0
	add_child(p)
	p.play()
	return p


## Wind that swells and dies down over the loop, with birds singing in it.
func _day_samples() -> PackedFloat32Array:
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(int(DAY_LENGTH * SAMPLE_RATE))
	var n: int = samples.size()
	var wind: float = 0.0
	for i in n:
		wind = lerpf(wind, randf_range(-1.0, 1.0), WIND_SMOOTHING)
		samples[i] = wind
	# Lean the wind back to where it started, so the loop has no click
	var end: float = samples[n - 1]
	for i in n:
		var swell: float = 0.6 + 0.4 * sin(float(i) / n * TAU)
		samples[i] = (samples[i] - end * i / (n - 1)) * swell * WIND_VOLUME
	for at in CHIRPS:
		_add_chirp(samples, at)
		_add_chirp(samples, at + CHIRP_TIME * 1.5)
	return samples


## Adds a bird's chirp at second at: a quick whistle sweeping up.
func _add_chirp(samples: PackedFloat32Array, at: float) -> void:
	var start: int = int(at * SAMPLE_RATE)
	var phase: float = 0.0
	for i in int(CHIRP_TIME * SAMPLE_RATE):
		var k: float = float(i) / (CHIRP_TIME * SAMPLE_RATE)
		phase += lerpf(CHIRP_LOW, CHIRP_HIGH, k) / SAMPLE_RATE
		samples[start + i] += sin(phase * TAU) * sin(k * PI) * CHIRP_VOLUME


## A cricket chirping CRICKET_PULSES pulses every CRICKET_EVERY seconds.
func _night_samples() -> PackedFloat32Array:
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(int(NIGHT_LENGTH * SAMPLE_RATE))
	for i in samples.size():
		var t: float = float(i) / SAMPLE_RATE
		var in_chirp: float = fmod(t, CRICKET_EVERY)
		var pulse: int = int(in_chirp / (CRICKET_PULSE * 2.0))
		var in_pulse: float = fmod(in_chirp, CRICKET_PULSE * 2.0)
		if pulse < CRICKET_PULSES and in_pulse < CRICKET_PULSE:
			samples[i] = sin(t * CRICKET_NOTE * TAU) * sin(in_pulse / CRICKET_PULSE * PI) * CRICKET_VOLUME
	return samples
