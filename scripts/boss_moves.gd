class_name BossMoves
extends Node3D

## A boss's fight, on top of its kind's attack: the colour it glows and the
## light round it, a special move each SPECIAL_TIME seconds that reaches its
## target (MobDefs.boss_specials), the waves of monsters it calls round it as
## its health falls past each of WAVES, and its rage from RAGE_AT of its
## health, when it moves faster, uses its moves more often, may have more of
## them, throws a fan and throbs. A child of the boss (MobSpawner.fight).

## The boss is enraged
signal raged

## The share of its health left at which each of its waves comes
const WAVES: Array[float] = [0.75, 0.5, 0.25]
## Blocks from the boss its monsters come up
const ADD_RANGE: float = 3.0
## The share of its health left at which it is enraged, and what its move
## speed is multiplied by then
const RAGE_AT: float = 0.5
const RAGE_SPEED: float = 1.35
## Seconds between its special moves, and once it is enraged
const SPECIAL_TIME: float = 6.0
const RAGE_SPECIAL_TIME: float = 4.0
## Blocks across the ground its slam reaches, seconds its ring warns before it
## lands, how many times as hard as a hit it throws the player, and blocks
## above or below the boss's feet it reaches
const SLAM_RADIUS: float = 4.5
const SLAM_WARN: float = 1.0
const SLAM_PUSH: float = 2.5
const SLAM_HEIGHT: float = 1.5
## Blocks across the ground it throws from at most, how many it throws at once
## when enraged and radians between them, a throw's share of its hit, and
## seconds it stands to throw
const THROW_RANGE: float = 14.0
const FAN: int = 3
const FAN_TURN: float = 0.3
const THROW_SHARE: float = 0.5
const THROW_HOLD: float = 0.6
## How solid its glow is, and at most as it throbs when enraged, THROB_SPEED
## radians a second
const GLOW_ALPHA: float = 0.2
const RAGE_ALPHA: float = 0.45
const THROB_SPEED: float = 6.0
## Blocks its light reaches, times its size, and how bright it is
const LIGHT_RANGE: float = 3.0
const LIGHT_ENERGY: float = 1.5
## Blocks from a slam the camera shakes within, and how hard
const SHAKE_RANGE: float = 12.0
const SHAKE: float = 0.08

var boss: Mob = null
## The spawner its monsters come up in
var mobs: MobSpawner = null
var enraged: bool = false
## How many of WAVES have come
var waves_called: int = 0
var glow: StandardMaterial3D = null
var light: OmniLight3D = null
## The coming slam's ring on the ground, or null
var ring: ShockRing = null
var _special_left: float = SPECIAL_TIME
## Which of its special moves it tries first next
var _next: int = 0
## Seconds until the coming slam lands
var _slam_left: float = 0.0
## Seconds it has been enraged, which its glow throbs by
var _time: float = 0.0


## The fight of fighter, a boss, whose monsters come up in spawner.
func _init(fighter: Mob, spawner: MobSpawner) -> void:
	name = "BossMoves"
	boss = fighter
	mobs = spawner
	var color: Color = MobDefs.boss_glow(boss.boss)
	glow = StandardMaterial3D.new()
	glow.albedo_color = Color(color, GLOW_ALPHA)
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = LIGHT_ENERGY
	light.omni_range = LIGHT_RANGE * boss.size
	light.position.y = MobDefs.body_size(boss.kind).y * boss.size / 2.0
	add_child(light)
	boss.show_glow(glow)


func _physics_process(delta: float) -> void:
	tick(delta)


## Runs the fight on by delta seconds.
func tick(delta: float) -> void:
	if boss.health <= 0:
		_end()
		return
	_watch_health()
	_throb(delta)
	if ring != null:
		_slam_left -= delta
		if _slam_left <= 0.0:
			_land_slam()
		return
	_special_left -= delta
	if _special_left <= 0.0 and not boss.is_busy():
		_try_special()


## Uses move now: a slam shows its ring and holds the boss still until it
## lands, SLAM_WARN later; a throw goes at once.
func use(move: int) -> void:
	_special_left = RAGE_SPECIAL_TIME if enraged else SPECIAL_TIME
	if move == MobDefs.Special.SLAM:
		_slam_left = SLAM_WARN
		boss.hold_for(SLAM_WARN, "Jump")
		ring = ShockRing.new(SLAM_RADIUS, MobDefs.boss_glow(boss.boss), SLAM_WARN)
		add_child(ring)
		ring.global_position = boss.global_position
	else:
		boss.hold_for(THROW_HOLD, "Attack")
		_throw(move)


## True when target stands on the ground within the slam's reach.
func slam_reaches(target: Player) -> bool:
	var to: Vector3 = target.global_position - boss.global_position
	return target.is_on_floor() and Vector2(to.x, to.z).length() < SLAM_RADIUS and absf(to.y) < SLAM_HEIGHT


## Calls each wave its health has fallen to, and enrages it at RAGE_AT.
func _watch_health() -> void:
	var left: float = float(boss.health) / MobDefs.boss_health(boss.boss)
	while waves_called < WAVES.size() and left <= WAVES[waves_called]:
		_call_wave(MobDefs.boss_waves(boss.boss)[waves_called])
		waves_called += 1
	if not enraged and left <= RAGE_AT:
		enraged = true
		boss.speed_scale = RAGE_SPEED
		_special_left = minf(_special_left, RAGE_SPECIAL_TIME)
		raged.emit()


## Calls count of its monsters up round it, on the ground ADD_RANGE off.
func _call_wave(count: int) -> void:
	for i in count:
		var angle: float = TAU * i / count
		var spot: Vector3 = boss.global_position + Vector3(sin(angle), 0.0, cos(angle)) * ADD_RANGE
		mobs.put_at(MobDefs.boss_adds(boss.boss), Vector2i(floori(spot.x), floori(spot.z)))


## Its glow and its light throb while it is enraged.
func _throb(delta: float) -> void:
	if not enraged:
		return
	_time += delta
	var beat: float = (sin(_time * THROB_SPEED) + 1.0) / 2.0
	glow.albedo_color.a = lerpf(GLOW_ALPHA, RAGE_ALPHA, beat)
	light.light_energy = LIGHT_ENERGY * (1.0 + beat)


## Uses the first of its special moves, from _next on, that reaches its
## target, and tries the one after it first next time; none when none does.
func _try_special() -> void:
	var specials: Array = MobDefs.boss_specials(boss.boss, enraged)
	var to: Vector3 = boss.target.global_position - boss.global_position
	var far: float = Vector2(to.x, to.z).length()
	for i in specials.size():
		var move: int = specials[(_next + i) % specials.size()]
		if far < (SLAM_RADIUS if move == MobDefs.Special.SLAM else THROW_RANGE):
			_next = (_next + i + 1) % specials.size()
			use(move)
			return


## Throws move at its target from up the boss, a fan of FAN once it is enraged,
## each for its share of the boss's hit.
func _throw(move: int) -> void:
	var count: int = FAN if enraged else 1
	var from: Vector3 = boss.global_position + Vector3.UP * MobDefs.body_size(boss.kind).y * boss.size * Mob.THROW_HEIGHT
	for i in count:
		var turn: float = (i - (count - 1) / 2.0) * FAN_TURN
		add_child(ThrownStone.new(boss.target, ceili(boss.strength * THROW_SHARE), from, move, turn))


## The slam lands: its ring fades, and a target on the ground in reach is hurt
## and thrown far, and chilled by a boss that throws ice. The ground booms and
## shakes the camera near it.
func _land_slam() -> void:
	ring.burst()
	ring = null
	var target: Player = boss.target
	if slam_reaches(target):
		target.hurt(boss.strength, boss.global_position, SLAM_PUSH)
		if MobDefs.boss_specials(boss.boss, false).has(MobDefs.Special.ICE):
			target.chill(Mob.CHILL_TIME)
	if boss.global_position.distance_to(target.global_position) < SHAKE_RANGE:
		target.feel.shake(SHAKE)
	if boss.sound != null:
		boss.sound.play("thunder", boss.global_position)


## The boss is dead: its ring, glow and light go, and its moves stop.
func _end() -> void:
	if ring != null:
		ring.queue_free()
		ring = null
	boss.show_glow(null)
	light.visible = false
	set_physics_process(false)
