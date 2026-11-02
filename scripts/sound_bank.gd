class_name SoundBank
extends Node

const Chunk: GDScript = preload("res://scripts/chunk.gd")

const SAMPLE_RATE: int = 22050
const BREAK_DURATION: float = 0.18
const PLACE_DURATION: float = 0.10
const STEP_DURATION: float = 0.08
const POP_DURATION: float = 0.12
const CHIP_DURATION: float = 0.05
const MUNCH_DURATION: float = 0.3
## How long the boss arrival horn sounds for
const HORN_DURATION: float = 1.6
## Two short yelps
const BARK_DURATION: float = 0.4
## A rising then falling cry
const MEOW_DURATION: float = 0.5
## A crack and a long low rumble
const THUNDER_DURATION: float = 2.5
## A boss's growl as it is enraged, swelling then dying away
const ROAR_DURATION: float = 1.2
## Each sound plays up to this much higher or lower, so repeats are not all alike
const PITCH_SPREAD: float = 0.1
## Players per sound, so quick repeats do not cut each other off
const VOICES: int = 3
## What the feet sound like on each kind of ground; anything else is hard
const SOFT_GROUND: Array[int] = [Chunk.DIRT, Chunk.GRASS, Chunk.WOOL, Chunk.CHEESE]
const CRUNCHY_GROUND: Array[int] = [Chunk.SAND, Chunk.SNOW]
const WOODEN_GROUND: Array[int] = [Chunk.WOOD_PLANKS, Chunk.CRATE]
## Seconds from one heartbeat to the next, and from its lub to its dub
const HEARTBEAT_TIME: float = 0.9
const HEARTBEAT_DUB: float = 0.25

## sound name -> its AudioStreamPlayer3D voices
var _voices: Dictionary = {}
## sound name -> index of the voice to play next
var _next: Dictionary = {}
## Loops while the player is low on health
var _heartbeat: AudioStreamPlayer = null
## The thunder's noise so far, smoothed so it rumbles low
var _rumble: float = 0.0


func _ready() -> void:
	_add("break", _gen_break, BREAK_DURATION)
	_add("place", _gen_place, PLACE_DURATION)
	_add("step_soft", _gen_step_soft, STEP_DURATION)
	_add("step_crunch", _gen_step_crunch, STEP_DURATION)
	_add("step_wood", _gen_step_wood, STEP_DURATION)
	_add("step_hard", _gen_step_hard, STEP_DURATION)
	_add("pop", _gen_pop, POP_DURATION)
	_add("chip", _gen_chip, CHIP_DURATION)
	_add("munch", _gen_munch, MUNCH_DURATION)
	_add("horn", _gen_horn, HORN_DURATION)
	_add("bark", _gen_bark, BARK_DURATION)
	_add("meow", _gen_meow, MEOW_DURATION)
	_add("thunder", _gen_thunder, THUNDER_DURATION)
	_add("roar", _gen_roar, ROAR_DURATION)
	_heartbeat = AudioStreamPlayer.new()
	_heartbeat.bus = "Master"
	_heartbeat.stream = to_wav(_samples(_gen_heartbeat, HEARTBEAT_TIME), true)
	add_child(_heartbeat)


## Plays the sound called sound_name at position, a little higher or lower each time.
func play(sound_name: String, position: Vector3) -> void:
	if not _voices.has(sound_name):
		push_warning("SoundBank: no sound called %s" % sound_name)
		return
	var voices: Array = _voices[sound_name]
	var p: AudioStreamPlayer3D = voices[_next[sound_name]]
	_next[sound_name] = (_next[sound_name] + 1) % voices.size()
	p.global_position = position
	p.pitch_scale = randf_range(1.0 - PITCH_SPREAD, 1.0 + PITCH_SPREAD)
	p.play()


## The footstep sound for walking on the block ground_id.
static func step_sound(ground_id: int) -> String:
	if ground_id in SOFT_GROUND:
		return "step_soft"
	if ground_id in CRUNCHY_GROUND:
		return "step_crunch"
	if ground_id in WOODEN_GROUND:
		return "step_wood"
	return "step_hard"


## Loops the heartbeat while on is true.
func set_heartbeat(on: bool) -> void:
	if on and not _heartbeat.playing:
		_heartbeat.play()
	elif not on and _heartbeat.playing:
		_heartbeat.stop()


## A 16-bit mono sound of samples between -1 and 1, played over and over
## when loop is true.
static func to_wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples.size()
	return stream


## VOICES players of the sound generator makes over duration seconds.
func _add(sound_name: String, generator: Callable, duration: float) -> void:
	var stream: AudioStreamWAV = to_wav(_samples(generator, duration))
	var voices: Array[AudioStreamPlayer3D] = []
	for i in VOICES:
		var p: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		p.bus = "Master"
		p.max_distance = 40.0
		p.unit_size = 4.0
		p.stream = stream
		add_child(p)
		voices.append(p)
	_voices[sound_name] = voices
	_next[sound_name] = 0


## What generator gives for each moment t over duration seconds.
func _samples(generator: Callable, duration: float) -> PackedFloat32Array:
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(int(duration * SAMPLE_RATE))
	for i in samples.size():
		samples[i] = generator.call(float(i) / SAMPLE_RATE)
	return samples


func _gen_break(t: float) -> float:
	var env: float = exp(-t * 18.0)
	return randf_range(-1.0, 1.0) * env * 0.4


func _gen_place(t: float) -> float:
	var env: float = exp(-t * 35.0)
	return sin(t * 600.0 * TAU) * env * 0.2


## Grass and dirt: a dull thud, a low note under a little noise
func _gen_step_soft(t: float) -> float:
	var env: float = exp(-t * 60.0)
	return (sin(t * 90.0 * TAU) * 0.6 + randf_range(-1.0, 1.0) * 0.25) * env * 0.35


## Sand and snow: noise that crackles on and off
func _gen_step_crunch(t: float) -> float:
	var env: float = exp(-t * 35.0)
	var grain: float = 1.0 if randf() < 0.3 else 0.2
	return randf_range(-1.0, 1.0) * grain * env * 0.3


## Wood: a hollow knock of two short notes
func _gen_step_wood(t: float) -> float:
	var env: float = exp(-t * 70.0)
	return (sin(t * 220.0 * TAU) + sin(t * 470.0 * TAU) * 0.5) * env * 0.25


## Stone and the rest: a sharp tap
func _gen_step_hard(t: float) -> float:
	var env: float = exp(-t * 110.0)
	return (randf_range(-1.0, 1.0) * 0.6 + sin(t * 900.0 * TAU) * 0.3) * env * 0.3


## A pickup: a quick note sweeping up from 400 Hz
func _gen_pop(t: float) -> float:
	var env: float = exp(-t * 25.0)
	return sin((400.0 * t + 3300.0 * t * t) * TAU) * env * 0.25


## A knock on a block being mined: a tick of noise over a high note
func _gen_chip(t: float) -> float:
	var env: float = exp(-t * 150.0)
	return (randf_range(-1.0, 1.0) * 0.5 + sin(t * 1500.0 * TAU) * 0.5) * env * 0.3


## Eating: three quick crunchy bites of noise
func _gen_munch(t: float) -> float:
	var bite: float = fmod(t, MUNCH_DURATION / 3.0)
	return randf_range(-1.0, 1.0) * exp(-bite * 40.0) * 0.3


## The boss arrival: a low brassy horn, a slow attack, a long fall, a slight drop in pitch at the end
func _gen_horn(t: float) -> float:
	# 0.15 s attack, then a slow exponential fall to the end of the clip
	var attack: float = clamp(t / 0.15, 0.0, 1.0)
	var fall: float = exp(-(t - 0.15) * 2.0) if t > 0.15 else 1.0
	var env: float = attack * fall
	# The note slips down over the last ~0.6s so it ends lower than it began
	var f0: float = 110.0 - 20.0 * clamp((t - (HORN_DURATION - 0.6)) / 0.6, 0.0, 1.0)
	# Fundamental plus a bit of the 2nd and 3rd harmonics for a brass-like brightness
	return (sin(t * f0 * TAU) + sin(t * f0 * 2.0 * TAU) * 0.4 + sin(t * f0 * 3.0 * TAU) * 0.2) * env * 0.5


## A dog's bark: two short yelps, each falling in pitch, with a little rasp
func _gen_bark(t: float) -> float:
	var yelp: float = fmod(t, BARK_DURATION / 2.0)
	var env: float = minf(yelp / 0.01, 1.0) * exp(-yelp * 18.0)
	# 520 Hz falling to 340 Hz over each yelp
	var phase: float = (520.0 * yelp - 450.0 * yelp * yelp) * TAU
	var tone: float = sin(phase) + sin(phase * 2.0) * 0.5 + sin(phase * 3.0) * 0.25
	return (tone + randf_range(-1.0, 1.0) * 0.15) * env * 0.35


## A cat's meow: a tone rising from 600 Hz to 800 Hz and falling back, swelling
## and fading
func _gen_meow(t: float) -> float:
	var env: float = sin(PI * t / MEOW_DURATION)
	var phase: float = (600.0 * t + 200.0 * MEOW_DURATION / PI * (1.0 - cos(PI * t / MEOW_DURATION))) * TAU
	return (sin(phase) + sin(phase * 2.0) * 0.3) * env * 0.3


## Thunder: noise smoothed down to a low rumble, cracking in fast and dying
## away slowly
func _gen_thunder(t: float) -> float:
	if t == 0.0:
		_rumble = 0.0
	_rumble = lerpf(_rumble, randf_range(-1.0, 1.0), 0.04)
	var env: float = clampf(t / 0.02, 0.0, 1.0) * exp(-t * 1.6)
	return clampf(_rumble * 5.0 * env, -1.0, 1.0) * 0.6


## A deep growl: a low buzz with a rasp of noise, wavering, that swells for
## 0.3 s and then dies away
func _gen_roar(t: float) -> float:
	var env: float = clampf(t / 0.3, 0.0, 1.0) * exp(-maxf(t - 0.3, 0.0) * 2.5)
	var buzz: float = 2.0 * fmod(t * 70.0, 1.0) - 1.0
	var waver: float = 1.0 + 0.3 * sin(t * TAU * 7.0)
	return clampf((buzz * 0.6 + randf_range(-1.0, 1.0) * 0.4) * waver * env, -1.0, 1.0) * 0.5


## Lub-dub: two low thumps, the second softer, then quiet till the next beat
func _gen_heartbeat(t: float) -> float:
	return _thump(t, 1.0) + _thump(t - HEARTBEAT_DUB, 0.7)


func _thump(t: float, loudness: float) -> float:
	if t < 0.0:
		return 0.0
	var env: float = exp(-t * 25.0)
	return (sin(t * 60.0 * TAU) + sin(t * 120.0 * TAU) * 0.5) * env * loudness * 0.6
