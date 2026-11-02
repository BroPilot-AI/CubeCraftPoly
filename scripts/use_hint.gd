class_name UseHint
extends RefCounted

## What the use button (a right-click, or LT on a gamepad) does to the block or
## mob in the crosshair, as the line under the crosshair says it, after the
## button's picture. It follows Player._use: blank where the click places the
## held item or eats it.

## Said for a door with no Key in hand, which opens only by a Key, a lever or a button
const LOCKED: String = "Locked: needs a Key, or a lever or button by it"


## The use button's picture: LT on a gamepad, else the right mouse button.
static func button(pad: bool) -> String:
	return InputIcons.of("place_block", pad)


## What use does to the block id with held in hand, such as
## use + " Open chest", or "" when it places or eats. In survival a click
## always opens a chest, to show its slots.
static func for_block(id: int, held: int, use: String, survival: bool = false) -> String:
	var base: int = BlockDefs.VARIANTS.get(id, id)
	# A shut prop is an OPENS key, so a click on it opens it
	var opening: bool = BlockDefs.OPENS.has(id)
	if base == BlockDefs.CHEST:
		return use + (" Open chest" if opening or survival else " Shut chest")
	if id == BlockDefs.OLD_CHEST:
		return use + " Open the old chest"
	if BlockDefs.is_locked(id) and held != BlockDefs.KEY:
		return LOCKED
	if base == BlockDefs.DOOR:
		return use + (" Open door" if opening else " Shut door")
	if base == BlockDefs.LEVER:
		return use + " Pull lever"
	if base == BlockDefs.BUTTON:
		return use + " Press button"
	if base == BlockDefs.RAIL and held == BlockDefs.MINECART:
		return use + " Ride the cart"
	return ""


## What use does to a mob of kind: in survival a villager talks, and the Wizard
## trades.
static func for_mob(kind: String, survival: bool, use: String) -> String:
	if survival and Quests.is_villager(kind):
		return use + " Talk"
	if survival and kind == MobDefs.WIZARD:
		return use + " Trade"
	return ""
