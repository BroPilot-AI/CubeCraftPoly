class_name Music
extends Node

## Quiet music made in code: a gentle tune by day, a slow dark one by night, a
## harsh one on a Blood Moon night and a fast tense one while a boss is alive.
## Once a second it works out which is wanted, and when that changes fades the
## new loop in and the old one out over FADE, on two players that swap. The
## loops are all made at setup (warm) and kept.

const BUS: StringName = &"Music"
## Seconds one loop takes to fade into the next
const FADE: float = 2.0
const LOOP_SECONDS: float = 8.0
## How loud a loop plays once faded in
const VOLUME_DB: float = -14.0
## Seconds between looks at the mood
const TICK: float = 1.0
## The tunes
const DAY: int = 0
const NIGHT: int = 1
const BOSS: int = 2
const BLOOD: int = 3
## No sample of a loop is louder than this
const PEAK: float = 0.6
## Semitones over the root of the notes each tune picks from
const PENTATONIC: Array[int] = [0, 2, 4, 7, 9, 12, 14, 16]
const MINOR: Array[int] = [0, 2, 3, 5, 7, 8, 10, 12]
## The root of each tune in Hz: C4, A2 and D2
const DAY_ROOT: float = 261.63
const NIGHT_ROOT: float = 110.0
const BOSS_ROOT: float = 73.42
## The places in the scale each tune runs through, over and over
const DAY_RUN: Array[int] = [0, 2, 4, 6, 5, 3, 4, 1]
const NIGHT_RUN: Array[int] = [0, 4, 2, 5, 3, 1, 4, 0]
const BOSS_RUN: Array[int] = [0, 0, 4, 0, 5, 0, 4, 2]
## On a Blood Moon every BLOOD_SOUR-th note is a semitone sharp
const BLOOD_SOUR: int = 3

## Mood -> its AudioStreamWAV, once made
static var _loops: Dictionary = {}

## The mood playing now, or -1 before the first
var mood: int = -1
var _players: Array[AudioStreamPlayer] = []
## Which of _players plays mood
var _front: int = 0
var _fade: Tween = null
var _left: float = 0.0
var _day_night: DayNight = null
var _player: Player = null
## The bosses alive now
var _bosses: Array[Mob] = []


## Adds the Music bus, sent to Master, when there is none yet.
static func ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return
	AudioServer.add_bus()
	var bus: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus, BUS)
	AudioServer.set_bus_send(bus, &"Master")


## The tune wanted: a boss's while one is alive, else the Blood Moon's on its
## night, else night's or day's.
static func mood_for(night: bool, boss_alive: bool, blood: bool) -> int:
	if boss_alive:
		return BOSS
	if night and blood:
		return BLOOD
	return NIGHT if night else DAY


## The looping LOOP_SECONDS of mood, made the first time it is asked for.
static func make_loop(mood_id: int) -> AudioStreamWAV:
	if not _loops.has(mood_id):
		_loops[mood_id] = SoundBank.to_wav(_samples(mood_id), true)
	return _loops[mood_id]


## Makes every mood's loop now, at load, so none stalls the game when it is
## first wanted.
static func warm() -> void:
	for mood_id: int in [DAY, NIGHT, BOSS, BLOOD]:
		make_loop(mood_id)


static func _samples(mood_id: int) -> PackedFloat32Array:
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(int(LOOP_SECONDS * SoundBank.SAMPLE_RATE))
	match mood_id:
		DAY:
			# A soft arpeggio, 4 notes a second, with a little of the octave in it
			for i in int(LOOP_SECONDS * 4):
				var hz: float = _pitch(DAY_ROOT, PENTATONIC[DAY_RUN[i % DAY_RUN.size()]])
				_note(samples, i * 0.25, hz, 0.2, 6.0)
				_note(samples, i * 0.25, hz * 2.0, 0.04, 9.0)
		BOSS:
			# A fast low ostinato, 8 notes a second, and a noise hit on each beat
			for i in int(LOOP_SECONDS * 8):
				var hz: float = _pitch(BOSS_ROOT, MINOR[BOSS_RUN[i % BOSS_RUN.size()]])
				_note(samples, i * 0.125, hz, 0.3, 14.0)
				_note(samples, i * 0.125, hz * 3.0, 0.1, 18.0)
			for beat in int(LOOP_SECONDS * 2):
				_hit(samples, beat * 0.5)
		_:
			# Slow low notes, 2 a second, over a soft pad; on a Blood Moon some go sour
			for i in int(LOOP_SECONDS * 2):
				var step: int = MINOR[NIGHT_RUN[i % NIGHT_RUN.size()]]
				if mood_id == BLOOD and i % BLOOD_SOUR == BLOOD_SOUR - 1:
					step += 1
				_note(samples, i * 0.5, _pitch(NIGHT_ROOT * 2.0, step), 0.2, 3.0)
			_pad(samples, NIGHT_ROOT)
	var loudest: float = 0.0
	for s: float in samples:
		loudest = maxf(loudest, absf(s))
	if loudest > PEAK:
		for i in samples.size():
			samples[i] *= PEAK / loudest
	return samples


static func _pitch(root: float, semitones: int) -> float:
	return root * pow(2.0, semitones / 12.0)


## Adds a sine note at start seconds that rises fast and falls away at fall,
## running on past the end of the loop into its start, so the loop has no seam.
static func _note(samples: PackedFloat32Array, start: float, hz: float, gain: float, fall: float) -> void:
	var rate: float = SoundBank.SAMPLE_RATE
	var first: int = int(start * rate)
	var length: int = int(6.0 / fall * rate)
	var attack: float = 0.01 * rate
	var drop: float = exp(-fall / rate)
	var env: float = gain
	for i in length:
		var rise: float = minf(i / attack, 1.0)
		samples[(first + i) % samples.size()] += sin(TAU * hz * i / rate) * env * rise
		env *= drop


## Adds a short burst of noise at start seconds.
static func _hit(samples: PackedFloat32Array, start: float) -> void:
	var rate: float = SoundBank.SAMPLE_RATE
	var first: int = int(start * rate)
	for i in int(0.08 * rate):
		samples[(first + i) % samples.size()] += randf_range(-1.0, 1.0) * 0.12 * exp(-i / rate * 40.0)


## Adds the root and its octave, held under the loop and swelling twice in it.
static func _pad(samples: PackedFloat32Array, root: float) -> void:
	var rate: float = SoundBank.SAMPLE_RATE
	for i in samples.size():
		var t: float = i / rate
		var swell: float = 0.5 + 0.5 * sin(TAU * 2.0 * t / LOOP_SECONDS)
		samples[i] += (sin(TAU * root * t) + 0.5 * sin(TAU * root * 2.0 * t)) * 0.05 * swell


func _ready() -> void:
	ensure_bus()
	for i in 2:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = BUS
		p.volume_linear = 0.0
		add_child(p)
		_players.append(p)


## Follows the time of day, the bosses mobs brings and the player's Blood Moon,
## with every loop made up front.
func setup(day_night: DayNight, mobs: MobSpawner, player: Player) -> void:
	_day_night = day_night
	_player = player
	mobs.boss_came.connect(_on_boss_came)
	warm()


func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0 or _day_night == null:
		return
	_left = TICK
	play_mood(mood_for(_day_night.is_night(), not _bosses.is_empty(), _player.blood_moon.tonight()))


## Fades the loop of wanted in over FADE and the one playing out, unless
## wanted is playing already.
func play_mood(wanted: int) -> void:
	if wanted == mood:
		return
	mood = wanted
	var old: AudioStreamPlayer = _players[_front]
	_front = 1 - _front
	var new: AudioStreamPlayer = _players[_front]
	new.stream = make_loop(wanted)
	new.volume_linear = 0.0
	new.play()
	if _fade != null:
		_fade.kill()
	_fade = create_tween().set_parallel()
	_fade.tween_property(new, "volume_linear", db_to_linear(VOLUME_DB), FADE)
	_fade.tween_property(old, "volume_linear", 0.0, FADE)
	_fade.chain().tween_callback(old.stop)


## A boss counts as alive from when it comes till it dies or goes.
func _on_boss_came(boss: Mob) -> void:
	_bosses.append(boss)
	boss.died.connect(_on_boss_gone.bind(boss))
	boss.tree_exiting.connect(_on_boss_gone.bind(boss))


func _on_boss_gone(boss: Mob) -> void:
	_bosses.erase(boss)
