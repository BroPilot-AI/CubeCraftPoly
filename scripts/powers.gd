class_name Powers
extends RefCounted

## The powers the bosses beaten give. The player sets one (chosen) on the
## villager screen and uses it with the "power" action: it is on for DURATION
## seconds, then ready again COOLDOWN seconds after. Regrowth heals the player,
## Fury doubles their hits and Frost slows the monsters near them.

## Land of a boss: the name of the power beating it gives
const NAMES: Dictionary = {
	ChunkGenerator.BIOME_MEADOW: "Regrowth",
	ChunkGenerator.BIOME_DESERT: "Fury",
	ChunkGenerator.BIOME_SNOW: "Frost",
}
## Seconds a power is on for, and seconds after it until it is ready again
const DURATION: float = 60.0
const COOLDOWN: float = 240.0
## Seconds between each health Regrowth gives back
const HEAL_EVERY: float = 2.0
## What Fury multiplies the player's hits by
const FURY: int = 2
## Blocks from the player Frost slows monsters in, what it multiplies their
## speed by, and seconds each chill holds (it is put on again each tick)
const FROST_RANGE: float = 8.0
const FROST_SLOW: float = 0.5
const FROST_HOLD: float = 0.5

## The land of the power set, or -1 for none
var chosen: int = -1
## Seconds left of the power on, and of the wait after it
var on_left: float = 0.0
var wait_left: float = 0.0
var _heal_left: float = HEAL_EVERY


## The lands in beaten that have a power, in NAMES order
static func earned(beaten: Array[int]) -> Array[int]:
	var lands: Array[int] = []
	for land: int in NAMES:
		if beaten.has(land):
			lands.append(land)
	return lands


## Sets the power earned after chosen, round to the first; -1 when none is
func choose_next(beaten: Array[int]) -> void:
	var lands: Array[int] = earned(beaten)
	chosen = -1 if lands.is_empty() else lands[(lands.find(chosen) + 1) % lands.size()]


## Turns the power set on, when there is one and it is neither on nor waiting;
## true when it did
func use() -> bool:
	if chosen == -1 or on_left > 0.0 or wait_left > 0.0:
		return false
	on_left = DURATION
	_heal_left = HEAL_EVERY
	return true


## True while the power of land is set and on
func is_on(land: int) -> bool:
	return chosen == land and on_left > 0.0


## What the player's hits are multiplied by: FURY while Fury is on, else 1
func damage_scale() -> int:
	return FURY if is_on(ChunkGenerator.BIOME_DESERT) else 1


## Counts the power on down, and the wait once it ends. While Regrowth is on it
## gives player a health each HEAL_EVERY, up to their most; while Frost is on it
## chills each living monster within FROST_RANGE of them.
func tick(player: Player, delta: float) -> void:
	if on_left <= 0.0:
		wait_left = maxf(wait_left - delta, 0.0)
		return
	on_left -= delta
	if on_left <= 0.0:
		on_left = 0.0
		wait_left = COOLDOWN
		return
	if chosen == ChunkGenerator.BIOME_MEADOW:
		_regrow(player, delta)
	elif chosen == ChunkGenerator.BIOME_SNOW:
		_frost(player)


func _regrow(player: Player, delta: float) -> void:
	_heal_left -= delta
	if _heal_left > 0.0:
		return
	_heal_left += HEAL_EVERY
	if player.health < player.bosses.max_health():
		player.health += 1
		player.health_changed.emit(player.health)


func _frost(player: Player) -> void:
	for node: Node in player.get_tree().get_nodes_in_group(Mob.GROUP):
		var mob: Mob = node as Mob
		if mob.health > 0 and MobDefs.is_hostile(mob.kind) and mob.global_position.distance_to(player.global_position) <= FROST_RANGE:
			mob.chill_for(FROST_SLOW, FROST_HOLD)


## The HUD's line: "" with no power set, else "Fury ready", "Fury 42s" while it
## is on or "Fury in 3:10" while it waits
func describe() -> String:
	if chosen == -1:
		return ""
	var power: String = NAMES[chosen]
	if on_left > 0.0:
		return "%s %ds" % [power, ceili(on_left)]
	if wait_left > 0.0:
		var secs: int = ceili(wait_left)
		return "%s in %d:%02d" % [power, floori(secs / 60.0), secs % 60]
	return "%s ready" % power


func to_dict() -> Dictionary:
	return {"chosen": chosen, "on_left": on_left, "wait_left": wait_left}


## Takes back what to_dict gave; a missing or bad save sets no power
func from_dict(saved: Variant) -> void:
	var data: Dictionary = saved if saved is Dictionary else {}
	var land: Variant = data.get("chosen", -1)
	chosen = int(land) if (land is int or land is float) and NAMES.has(int(land)) else -1
	on_left = _seconds(data.get("on_left"), DURATION)
	wait_left = _seconds(data.get("wait_left"), COOLDOWN)
	_heal_left = HEAL_EVERY


static func _seconds(saved: Variant, most: float) -> float:
	return clampf(float(saved), 0.0, most) if saved is int or saved is float else 0.0
