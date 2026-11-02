class_name Quests
extends RefCounted

## The villagers' quests, done one after another in survival. Each wants some
## of an item from the backpack, a shelter built or a boss beaten, and gives a
## tool for it, one that helps with the quests after it, or a gift (see Gifts)
## that no recipe makes. Each is [item wanted, how many, tool or gift given]; a
## shelter's is [SHELTER, cells of room it needs, tool given] and a boss's
## [BOSS, its land, tool given]. The last is the Skeleton
## King (FinalBoss), and beating it wins the game.

## In place of an item wanted: wall and roof yourself in
const SHELTER: int = -1
## In place of an item wanted: beat the boss of the land
const BOSS: int = -2
const LIST: Array = [
	# Wood Sword, for the first night; the shelter becomes home
	[SHELTER, 4, 113],
	# Wood Pickaxe, to mine stone
	[Chunk.WOOD_PLANKS, 12, 101],
	# Swift Boots
	[Chunk.STONE, 16, Gifts.SWIFT],
	# Stone Sword, which wakes the Zombie King
	[Chunk.COAL, 8, 114],
	# Lucky Clover, for more Cheese
	[Chunk.WOOL, 3, Gifts.LUCKY],
	# Gold Pickaxe, to mine diamond
	[BOSS, ChunkGenerator.BIOME_MEADOW, 103],
	# Gold Sword, which wakes the Demon Lord
	[Chunk.CRYSTAL, 4, 115],
	# Fur Cloak, against the Frost Giant's yetis
	[Chunk.ICE, 6, Gifts.WARM],
	# Diamond Sword, which wakes the Frost Giant
	[BOSS, ChunkGenerator.BIOME_DESERT, 116],
	# Diamond Pickaxe
	[BOSS, ChunkGenerator.BIOME_SNOW, 104],
	# Diamond Axe, for the world kept after the end
	[BOSS, MobDefs.FINAL_LAND, 108],
]
## Kit models of the mobs that give the quests
const VILLAGERS: Array[String] = ["Steve", "Cube Woman Character"]
## Cheese every quest gives as well as its tool or gift
const REWARD_CHEESE: int = 2
const ALL_DONE: String = "Every quest is done. Thank you!"


static func is_villager(kind: String) -> bool:
	return VILLAGERS.has(kind)


## True once the quest at index is past the last one
static func all_done(index: int) -> bool:
	return index >= LIST.size()


## True when the quest at index is a shelter to build
static func wants_shelter(index: int) -> bool:
	return not all_done(index) and LIST[index][0] == SHELTER


## True when the quest at index is a boss to beat
static func wants_boss(index: int) -> bool:
	return not all_done(index) and LIST[index][0] == BOSS


## True when the quest at index is the Skeleton King, the last boss
static func wants_final(index: int) -> bool:
	return wants_boss(index) and LIST[index][1] == MobDefs.FINAL_LAND


## True when the quest at index is a boss whose land is in beaten
static func boss_done(index: int, beaten: Array[int]) -> bool:
	return wants_boss(index) and beaten.has(LIST[index][1])


## True when bp holds what the quest at index wants. A shelter or a boss is
## never handed in.
static func can_hand_in(bp: Backpack, index: int) -> bool:
	if all_done(index) or wants_shelter(index) or wants_boss(index):
		return false
	return bp.count_of(LIST[index][0]) >= LIST[index][1]


## What the quest at index gives besides Cheese, such as "Wood Sword" or
## "Swift Boots (walk and run faster)"
static func reward(index: int) -> String:
	var id: int = LIST[index][2]
	return Gifts.describe(id) if Gifts.is_gift(id) else BlockDefs.display_name(id)


## The quest at index as a line of text, such as "Bring 12 Wood Planks to a
## villager (have 3)", or ALL_DONE once every quest is done.
static func describe(bp: Backpack, index: int) -> String:
	if all_done(index):
		return ALL_DONE
	var quest: Array = LIST[index]
	if quest[0] == SHELTER:
		return "Wall and roof yourself in, with %d or more blocks of room" % quest[1]
	if quest[0] == BOSS:
		var where: String = "to the crystal by home" if wants_final(index) else "in its land"
		return "Beat %s, who comes at night %s" % [MobDefs.boss_name(quest[1]), where]
	var have: int = mini(bp.count_of(quest[0]), quest[1])
	return "Bring %d %s to a villager (have %d)" % [quest[1], BlockDefs.display_name(quest[0]), have]


## What to do once bp holds enough for the quest at index, with use the use
## button's picture: " - (picture) on a villager to hand in", else "".
static func hand_in_hint(bp: Backpack, index: int, use: String) -> String:
	return " - %s on a villager to hand in" % use if can_hand_in(bp, index) else ""
