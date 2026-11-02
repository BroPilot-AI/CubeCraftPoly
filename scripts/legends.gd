class_name Legends
extends RefCounted

## The Wizard's shop of legendary things: Gifts he sells for Diamonds and
## Cheese, each for sale once the boss of its land is beaten. He comes to live
## at home once the Zombie King is (BRINGS_WIZARD).

## The land whose boss beaten brings the Wizard home
const BRINGS_WIZARD: int = ChunkGenerator.BIOME_MEADOW
## Said once that boss is beaten, COME_DELAY seconds on, when its own banner
## has gone
const COME_TEXT: String = "A Wizard came to your home\nwith legendary things"
const COME_DELAY: float = 4.0
## Said as a Phoenix Feather brings the player back
const RISE_TEXT: String = "You rise from the ashes!"
## Gift -> [land whose boss beaten puts it up for sale, Diamonds, Cheese]
const SHOP: Dictionary = {
	Gifts.FEATHER: [ChunkGenerator.BIOME_MEADOW, 2, 5],
	Gifts.FLAME: [ChunkGenerator.BIOME_DESERT, 4, 8],
	Gifts.PHOENIX: [ChunkGenerator.BIOME_SNOW, 6, 12],
}


## True once the boss that puts id up for sale is beaten.
static func for_sale(bosses: BossLog, id: int) -> bool:
	return bosses.beaten.has(SHOP[id][0])


## True when id is for sale, the player has not got it, and their backpack
## holds its price.
static func can_buy(player: Player, id: int) -> bool:
	var price: Array = SHOP[id]
	var afford: bool = player.backpack.count_of(Chunk.DIAMOND) >= price[1] and player.backpack.count_of(Chunk.CHEESE) >= price[2]
	return for_sale(player.bosses, id) and not player.gifts.has(id) and afford


## Takes id's price out of the backpack and gives the player id. Returns false,
## taking nothing, when they cannot buy it.
static func buy(player: Player, id: int) -> bool:
	if not can_buy(player, id):
		return false
	player.backpack.remove(Chunk.DIAMOND, SHOP[id][1])
	player.backpack.remove(Chunk.CHEESE, SHOP[id][2])
	player.gifts.give(id)
	return true
