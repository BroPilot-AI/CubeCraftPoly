class_name MobDefs
extends RefCounted

## The Cube World Kit's animals, villagers and monsters, by kit model name, the
## hunters among the monsters and the animals they hunt, and each land's boss.

## How a monster hurts the player: it hits what is in reach, throws stones from
## afar, leaps at the player, chills the player with its hits so they walk
## slower, or stomps the ground by the player, throwing them far
enum Attack { HIT, THROW, LEAP, CHILL, STOMP }
## A boss's special moves, on top of its kind's attack (BossMoves): it slams
## the ground round it, which the player jumps or runs from, or throws fire,
## ice that chills, or bones
enum Special { SLAM, FIRE, ICE, BONES }

const KIT_DIR: String = "res://assets/cubeworld/decor/"
## The Wizard, who comes to live at home once the Zombie King is beaten and
## sells legendary things (Legends). The kit has no model of him, so he wears
## Steve's, dressed as a wizard (WizardLook).
const WIZARD: String = "Wizard"
## Kind -> the kit model it wears, for a kind that is not itself a kit model
const MODELS: Dictionary = {WIZARD: "Steve"}
## Collision layer value of mobs
const LAYER: int = 8

## kit model -> [hostile, health, walk speed (blocks/s), body width, body height, attack damage]
const MOBS: Dictionary = {
	"Cat": [false, 10, 1.2, 0.5, 0.7, 0],
	"Chick": [false, 4, 0.8, 0.3, 0.35, 0],
	"Chicken": [false, 4, 1.0, 0.35, 0.5, 0],
	"Dog": [false, 8, 1.4, 0.5, 0.8, 0],
	"Horse": [false, 20, 1.8, 0.8, 1.4, 0],
	"Pig": [false, 10, 1.0, 0.6, 0.7, 0],
	"Raccoon": [false, 8, 1.2, 0.5, 0.6, 0],
	"Sheep": [false, 8, 1.0, 0.6, 0.8, 0],
	"Hedgehog": [false, 6, 0.6, 0.4, 0.35, 0],
	# Villagers: two of the kit's characters, which the player can also wear
	"Steve": [false, 20, 1.0, 0.5, 1.35, 0],
	"Cube Woman Character": [false, 20, 1.0, 0.5, 1.35, 0],
	WIZARD: [false, 20, 1.0, 0.5, 1.35, 0],
	"Demon": [true, 48, 1.5, 0.6, 1.5, 5],
	"Giant": [true, 100, 1.0, 0.9, 2.2, 8],
	"Goblin": [true, 10, 1.75, 0.5, 1.1, 2],
	"Skeleton": [true, 32, 1.25, 0.5, 1.5, 4],
	"Yeti": [true, 64, 1.25, 0.9, 1.7, 6],
	"Zombie": [true, 16, 1.1, 0.5, 1.4, 3],
	# A hunter (HUNTERS)
	"Wolf": [true, 8, 1.4, 0.5, 0.8, 2],
}
## Monsters with no land, which come in packs on the grass by day, hunt the
## PREY, and go after only a player they see
const HUNTERS: Array[String] = ["Wolf"]
## The animals the hunters kill and eat
const PREY: Array[String] = ["Sheep", "Pig", "Chicken", "Chick"]
## Land -> [the ground its monsters come up on, its monsters]. The meadow's come
## only at night; the desert's and the snow's are tougher and about day and night.
const HOMES: Dictionary = {
	ChunkGenerator.BIOME_MEADOW: [Chunk.GRASS, ["Goblin", "Zombie"]],
	ChunkGenerator.BIOME_DESERT: [Chunk.SAND, ["Skeleton", "Demon"]],
	ChunkGenerator.BIOME_SNOW: [Chunk.SNOW, ["Yeti", "Giant"]],
}
## kit model -> share of a hit's knockback it takes, for the big monsters a hit
## barely moves; the rest take it all
const KNOCKBACK_TAKEN: Dictionary = {
	"Skeleton": 0.6,
	"Demon": 0.5,
	"Yeti": 0.25,
	"Giant": 0.0,
}
## kit model -> its Attack; a monster not listed hits
const ATTACKS: Dictionary = {
	"Skeleton": Attack.THROW,
	"Demon": Attack.LEAP,
	"Yeti": Attack.CHILL,
	"Giant": Attack.STOMP,
}
## kit model -> [item it leaves when killed in survival, how many]; a mob not
## listed leaves nothing
const DROPS: Dictionary = {
	"Sheep": [Chunk.WOOL, 1],
	"Goblin": [Chunk.COAL, 2],
	"Zombie": [Chunk.COAL, 2],
	"Skeleton": [Chunk.METAL, 2],
	"Demon": [Chunk.CRYSTAL, 2],
	"Yeti": [Chunk.ICE, 3],
	"Giant": [Chunk.DIAMOND, 1],
}
## Chance a killed animal leaves a Cheese as well as its drop
const CHEESE_CHANCE: float = 0.5
## In place of a land: the Skeleton King, the last boss, who has no land of
## its own but comes to a crystal by home (FinalBoss)
const FINAL_LAND: int = 3
## Land -> [kit model, name, times as big as that monster, health, attack
## damage, sword tier it takes to hurt]: each land's boss, a big one of its
## monsters that only that sword or a better one hurts, and FINAL_LAND's
const BOSSES: Dictionary = {
	ChunkGenerator.BIOME_MEADOW: ["Zombie", "The Zombie King", 2.0, 30, 4, 2],
	ChunkGenerator.BIOME_DESERT: ["Demon", "The Demon Lord", 1.75, 45, 6, 3],
	ChunkGenerator.BIOME_SNOW: ["Giant", "The Frost Giant", 2.0, 60, 9, 4],
	FINAL_LAND: ["Skeleton", "The Skeleton King", 2.5, 90, 10, 4],
}
## Land -> [its special moves, its special moves from half its health on, the
## monster it calls round it, how many come in each of its waves, the colour
## it glows]
const BOSS_FIGHTS: Dictionary = {
	ChunkGenerator.BIOME_MEADOW: [[Special.SLAM], [Special.SLAM], "Zombie", [2, 3, 4], Color(0.4, 1.0, 0.3)],
	ChunkGenerator.BIOME_DESERT: [[Special.FIRE], [Special.FIRE], "Demon", [1, 2, 2], Color(1.0, 0.35, 0.1)],
	ChunkGenerator.BIOME_SNOW: [[Special.ICE], [Special.ICE, Special.SLAM], "Yeti", [1, 1, 2], Color(0.45, 0.8, 1.0)],
	FINAL_LAND: [[Special.BONES], [Special.BONES, Special.SLAM], "Skeleton", [2, 3, 3], Color(0.7, 0.3, 1.0)],
}


static func is_hostile(kind: String) -> bool:
	return MOBS[kind][0]


static func health(kind: String) -> int:
	return MOBS[kind][1]


static func speed(kind: String) -> float:
	return MOBS[kind][2]


## True for a hunter (HUNTERS)
static func hunts(kind: String) -> bool:
	return HUNTERS.has(kind)


## True for an animal the hunters hunt (PREY)
static func is_prey(kind: String) -> bool:
	return PREY.has(kind)


## Health a monster's hit takes off; 0 for an animal
static func damage(kind: String) -> int:
	return MOBS[kind][5]


## What the mob leaves when killed: [item, how many], or [0, 0]
static func drop(kind: String) -> Array:
	return DROPS.get(kind, [0, 0])


## True when a mob killed with roll, from 0 to 1, leaves a Cheese: an animal
## does on a roll under CHEESE_CHANCE, a monster, villager or the Wizard never.
static func leaves_cheese(kind: String, roll: float) -> bool:
	return not is_hostile(kind) and not Quests.is_villager(kind) and kind != WIZARD and roll < CHEESE_CHANCE


## Share of a hit's knockback the mob takes, 0 to 1
static func knockback(kind: String) -> float:
	return KNOCKBACK_TAKEN.get(kind, 1.0)


## How the monster attacks, one of Attack
static func attack(kind: String) -> int:
	return ATTACKS.get(kind, Attack.HIT)


## The ground a land's monsters come up on
static func home_ground(biome: int) -> int:
	return HOMES[biome][0]


## A land's monsters
static func monsters_of(biome: int) -> Array[String]:
	var out: Array[String] = []
	out.assign(HOMES[biome][1])
	return out


## The land a monster comes from, or -1 for an animal, villager or hunter
static func home_of(kind: String) -> int:
	for biome: int in HOMES:
		if HOMES[biome][1].has(kind):
			return biome
	return -1


## Size of the mob's collision box
static func body_size(kind: String) -> Vector3:
	return Vector3(MOBS[kind][3], MOBS[kind][4], MOBS[kind][3])


## The monsters, hunters too, when hostile is true, else the animals and
## villagers; never the Wizard, who comes only to live at home
static func kinds(hostile: bool) -> Array[String]:
	var out: Array[String] = []
	for kind: String in MOBS:
		if MOBS[kind][0] == hostile and kind != WIZARD:
			out.append(kind)
	return out


static func model(kind: String) -> PackedScene:
	return load(KIT_DIR + MODELS.get(kind, kind) + ".glb")


## The monster a land's boss is a big one of
static func boss_kind(land: int) -> String:
	return BOSSES[land][0]


static func boss_name(land: int) -> String:
	return BOSSES[land][1]


## Times as big as its kind a land's boss is
static func boss_size(land: int) -> float:
	return BOSSES[land][2]


## Blocks from the middle of a land's boss to its side
static func boss_half_width(land: int) -> float:
	return body_size(boss_kind(land)).x * boss_size(land) / 2.0


static func boss_health(land: int) -> int:
	return BOSSES[land][3]


## Health a land's boss's attack takes off
static func boss_damage(land: int) -> int:
	return BOSSES[land][4]


## The sword tier it takes to hurt a land's boss
static func boss_tier(land: int) -> int:
	return BOSSES[land][5]


## How much of each hit on a land's boss does nothing: what a sword a tier
## below the one it takes does, so that sword does not hurt it
static func boss_armor(land: int) -> int:
	return BlockDefs.SWORD_DAMAGE[boss_tier(land) - 2]


## The weakest sword that hurts a land's boss
static func boss_sword(land: int) -> int:
	return BlockDefs.TOOLS.find_key([BlockDefs.TOOL_SWORD, boss_tier(land)])


## A land's boss's special moves, or with enraged the ones it has from half its
## health on
static func boss_specials(land: int, enraged: bool) -> Array:
	return BOSS_FIGHTS[land][1 if enraged else 0]


## The monster a land's boss calls round it
static func boss_adds(land: int) -> String:
	return BOSS_FIGHTS[land][2]


## How many monsters come in each of a land's boss's waves (BossMoves.WAVES)
static func boss_waves(land: int) -> Array:
	return BOSS_FIGHTS[land][3]


## The colour a land's boss glows
static func boss_glow(land: int) -> Color:
	return BOSS_FIGHTS[land][4]
