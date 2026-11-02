class_name BossLog
extends RefCounted

## The lands whose bosses the player has woken, by having a sword that hurts
## them, and beaten. Each beaten the first time is a heart container: HEART
## more health at the most.

## Health a heart container adds to the most the player can have
const HEART: int = 2

## Lands, keys of MobDefs.BOSSES, each once
var beaten: Array[int] = []
## Lands whose bosses come up at night, as beaten
var woken: Array[int] = []


## The most health the player can have: Player.MAX_HEALTH and a heart for each
## boss beaten
func max_health() -> int:
	return Player.MAX_HEALTH + HEART * beaten.size()


## Adds land to the beaten; true the first time, false when it already was.
func beat(land: int) -> bool:
	if beaten.has(land):
		return false
	beaten.append(land)
	return true


## Wakes each land's boss not woken or beaten yet whose sword, or a better one,
## is in bp, and gives the lands it woke. The Skeleton King comes by FinalBoss.
func wake(bp: Backpack) -> Array[int]:
	var woke: Array[int] = []
	for land: int in MobDefs.BOSSES:
		if land == MobDefs.FINAL_LAND:
			continue
		if not woken.has(land) and not beaten.has(land) and _holds_sword(bp, MobDefs.boss_tier(land)):
			woken.append(land)
			woke.append(land)
	return woke


## Fills the beaten from a saved list, keeping only lands with a boss, each
## once; anything else, or no list, leaves none beaten.
func load_list(saved: Variant) -> void:
	beaten = _lands(saved)


## Fills the woken from a saved list as load_list does the beaten.
func load_woken(saved: Variant) -> void:
	woken = _lands(saved)


## True when bp holds a sword of tier or better.
static func _holds_sword(bp: Backpack, tier: int) -> bool:
	for id: int in BlockDefs.TOOLS:
		var tool: Array = BlockDefs.TOOLS[id]
		if tool[0] == BlockDefs.TOOL_SWORD and tool[1] >= tier and bp.count_of(id) > 0:
			return true
	return false


## The lands with a boss in saved, each once; none when it is not a list.
static func _lands(saved: Variant) -> Array[int]:
	var out: Array[int] = []
	if not saved is Array:
		return out
	for land: Variant in saved:
		if (land is int or land is float) and MobDefs.BOSSES.has(int(land)) and not out.has(int(land)):
			out.append(int(land))
	return out
