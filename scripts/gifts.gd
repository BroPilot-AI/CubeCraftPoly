class_name Gifts
extends RefCounted

## What villagers give for some quests in place of a tool, and the legendary
## things the Wizard sells (Legends): things no recipe makes, which the player
## keeps for good. Their ids go in Quests.LIST with the tools', past the items'.

const SWIFT: int = 201
const LUCKY: int = 202
const WARM: int = 203
## The Wizard's: a cloak to glide on, a blade that burns, a feather to rise by
const FEATHER: int = 204
const FLAME: int = 205
const PHOENIX: int = 206
## id -> [name, what it does]
const INFO: Dictionary = {
	SWIFT: ["Swift Boots", "walk and run faster"],
	LUCKY: ["Lucky Clover", "every animal leaves a Cheese"],
	WARM: ["Fur Cloak", "a yeti's hit does not slow you"],
	FEATHER: ["Feather Cloak", "hold jump to fall slowly, and no fall hurts you"],
	FLAME: ["Flame Blade", "your sword's hits set monsters on fire"],
	PHOENIX: ["Phoenix Feather", "once a day, rise again where you fall"],
}
## Walking and running speed with Swift Boots, as a share of without
const SWIFT_SHARE: float = 1.25
## Blocks a second the player falls at most, gliding with a Feather Cloak
const GLIDE_FALL: float = 2.0

## The gifts the player has, in the order given
var list: Array[int] = []


static func is_gift(id: int) -> bool:
	return INFO.has(id)


## A gift's name and what it does, such as "Swift Boots (walk and run faster)"
static func describe(id: int) -> String:
	return "%s (%s)" % INFO[id]


func has(id: int) -> bool:
	return list.has(id)


## Gives the gift id. Returns false when the player already has it.
func give(id: int) -> bool:
	if has(id):
		return false
	list.append(id)
	return true


## Fills the list from a saved one, keeping the known gifts and no repeats.
func load_list(saved: Variant) -> void:
	list = []
	if not saved is Array:
		return
	for id: Variant in saved:
		if (id is int or id is float) and is_gift(int(id)):
			give(int(id))
