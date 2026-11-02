extends Node3D
## One dusk, once a day: the next unbeaten boss walks far off across the
## player's view (a model only, no collision, no AI), then its name is shown.
class_name BossOmen

const DUSK_FROM: float = 0.42
const DUSK_TO: float = 0.5
const DISTANCE: float = 40.0
const WALK: float = 16.0
const WALK_TIME: float = 14.0
const TEXT: String = "Far off, %s walks the land..."

var player: Player = null
var day_night: DayNight = null
var cm: Node3D = null
var hud: Node = null
var _shown: bool = false
var _figure: Node3D = null
var _from: Vector3 = Vector3.ZERO
var _to: Vector3 = Vector3.ZERO
var _dir: Vector3 = Vector3.ZERO
var _walk_elapsed: float = 0.0


## p: controls/survival state and camera; h: banners.
func setup(p: Player, dn: DayNight, chunks: Node3D, h: Node) -> void:
	player = p
	day_night = dn
	cm = chunks
	hud = h
	if day_night != null and not day_night.day_began.is_connected(_on_day_began):
		day_night.day_began.connect(_on_day_began)


## A new day: the omen may show again at this dusk.
func _on_day_began() -> void:
	_shown = false


func _check_show() -> void:
	if _figure != null or _shown or player == null or cm == null or day_night == null:
		return
	if not player.survival:
		return
	if not (day_night._time >= DUSK_FROM and day_night._time < DUSK_TO):
		return
	if next_land(player.bosses.beaten) < 0:
		return
	show_next()


func _process(delta: float) -> void:
	if _figure != null:
		_walk_elapsed += delta
		var t: float = clamp(_walk_elapsed / WALK_TIME, 0.0, 1.0)
		_figure.position = _from.lerp(_to, t)
		if _walk_elapsed >= WALK_TIME:
			_figure.queue_free()
			_figure = null
		return
	_check_show()


## The first land in meadow, desert, snow with a boss not yet beaten, else -1.
static func next_land(beaten: Array[int]) -> int:
	if not beaten.has(ChunkGenerator.BIOME_MEADOW):
		return ChunkGenerator.BIOME_MEADOW
	if not beaten.has(ChunkGenerator.BIOME_DESERT):
		return ChunkGenerator.BIOME_DESERT
	if not beaten.has(ChunkGenerator.BIOME_SNOW):
		return ChunkGenerator.BIOME_SNOW
	return -1


## Walks the next boss across the player's view, DISTANCE blocks off.
func show_next() -> bool:
	var land := next_land(player.bosses.beaten)
	if land < 0:
		return false
	var look: Vector3
	if player.camera != null:
		look = player.camera.global_transform.basis * Vector3.FORWARD
	look.y = 0.0
	if look.length() < 0.01:
		look = Vector3.FORWARD
	look = look.normalized()
	var origin: Vector3 = player.global_position if player != null else global_position
	var spot: Vector3 = origin + look * DISTANCE
	var ground_y: int = _ground_y(floori(spot.x), floori(spot.z))
	if ground_y < 0:
		return false
	_from = Vector3(spot.x, ground_y, spot.z)
	_dir = look.cross(Vector3.UP).normalized()
	_to = _from + _dir * WALK
	var fig := MobDefs.model(MobDefs.boss_kind(land)).instantiate()
	add_child(fig)
	_figure = fig
	_figure.position = _from
	_figure.scale = Vector3.ONE * BlockDefs.KIT_SCALE * MobDefs.boss_size(land)
	_figure.rotation.y = atan2(_dir.x, _dir.z)
	var children := fig.find_children("*", "AnimationPlayer", true, false)
	if not children.is_empty():
		var ap := children[0] as AnimationPlayer
		var clip_name: String = ""
		for name in ap.get_animation_list():
			if name.ends_with("|Walk"):
				clip_name = name
				break
		if clip_name == "":
			for name in ap.get_animation_list():
				if name.ends_with("|Run"):
					clip_name = name
					break
		if clip_name != "":
			ap.play(clip_name)
	_walk_elapsed = 0.0
	_shown = true
	if hud != null and hud.has_method("show_banner"):
		hud.show_banner(TEXT % MobDefs.boss_name(land))
	return true


## The top solid block at (x, z), or -1 while nothing there is loaded.
func _ground_y(x: int, z: int) -> int:
	var top := ChunkGenerator.CHUNK_Y - 1
	while top >= 0:
		if cm.get_block_at(Vector3i(x, top, z)) != Chunk.AIR:
			return top
		top -= 1
	return -1
