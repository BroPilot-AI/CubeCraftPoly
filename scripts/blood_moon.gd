class_name BloodMoon
extends RefCounted

## Counts the days, and tells the nights a Blood Moon rises: the night of day
## FIRST and of every EVERY days after. Under it the light turns red and twice
## the monsters come (MobSpawner), and a player who lives to the dawn after it
## is given REWARD (Player.new_day).

## The day of the first Blood Moon night, and the days from one to the next
const FIRST: int = 3
const EVERY: int = 6
## What the light is multiplied by while it is up
const TINT: Color = Color(1.0, 0.45, 0.4)
## The banners as it rises and at the dawn after it
const RISE_TEXT: String = "A Blood Moon rises!"
const DAWN_TEXT: String = "You lived through the Blood Moon!"
## [item, count] given at the dawn after it
const REWARD: Array = [[Chunk.DIAMOND, 1], [Chunk.CHEESE, 4]]

## Days since the game began
var day: int = 0


## True when the night of day d has a Blood Moon
static func is_blood(d: int) -> bool:
	return d >= FIRST and (d - FIRST) % EVERY == 0


## True when tonight has a Blood Moon
func tonight() -> bool:
	return is_blood(day)


## The dawn: counts one more day, and returns whether the night just ended
## had a Blood Moon.
func new_day() -> bool:
	var was: bool = tonight()
	day += 1
	return was


func to_dict() -> Dictionary:
	return {"day": day}


## A save that is missing or not as it was written starts the count again
func from_dict(saved: Variant) -> void:
	var count: Variant = saved.get("day") if saved is Dictionary else null
	day = int(count) if (count is int or count is float) and count >= 0 else 0
