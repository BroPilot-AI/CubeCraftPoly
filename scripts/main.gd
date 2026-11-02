class_name Main
extends Node3D

const PlayerScene: PackedScene = preload("res://scenes/player.tscn")
const HUDScene: PackedScene = preload("res://scenes/hud.tscn")
const BreakOverlayScene: PackedScene = preload("res://scenes/break_overlay.tscn")
const CloudRigScene: PackedScene = preload("res://scenes/cloud_rig.tscn")
const SettingsMenuScene: PackedScene = preload("res://scenes/settings_menu.tscn")
const TITLE_SCENE: String = "res://scenes/title_screen.tscn"
## Seconds between saves of the backpacks and the edited chunks
const AUTOSAVE_TIME: float = 30.0
## Seconds between looks at whether a treasure map's chest goes in or was found
const TREASURE_TIME: float = 1.0
## Seconds between looks at whether home's village grows
const VILLAGE_TIME: float = 1.0
## Bits of dust a landing kicks up for each block fallen, and at least and most
const DUST_PER_BLOCK: float = 3.0
const DUST_MIN: int = 4
const DUST_MAX: int = 16
## Knocks while a block is broken, each a wobble of the crack, a click and
## KNOCK_CHIPS chips of the block
const BREAK_KNOCKS: int = 4
const KNOCK_CHIPS: int = 4

@onready var chunks_root: Node3D = $World/Chunks
@onready var chunk_manager: ChunkManager = $World/Chunks/ChunkManager
@onready var player: Player = $World/Player
@onready var hud: CanvasLayer = $HUD
@onready var sound: SoundBank = $SoundBank
@onready var particles: ParticlePool = $ParticlePool
@onready var break_overlay: BreakOverlay = $World/BreakOverlay
@onready var cloud_rig: CloudRig = $Clouds
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var inventory: Inventory = $Inventory
@onready var world_env: WorldEnvironment = $World/WorldEnvironment

var _is_paused: bool = false
## Keeps animals, and at night monsters, about the player
var mobs: MobSpawner = null
## The survival backpack and recipes, opened with E in survival
var backpack_screen: BackpackScreen = null
## A survival chest's slots over the backpack's, opened by using a chest
var chest_screen: ChestScreen = null
## Holds the items lying on the ground
var drops: Node3D = null
## What a villager wants, opened by right-clicking one in survival
var quest_screen: QuestScreen = null
## The Wizard's shop, opened by right-clicking him in survival
var wizard_screen: WizardScreen = null
var end_screen: EndScreen = null
## See-through boxes where the blocks of the build by home still go
var build_ghost: BuildGhost = null
## Wind and birds by day, crickets by night
var ambience: Ambience = null
## The boss's arrival: horn, shake, banner, and the sky darkening
var boss_arrival: BossArrival = null
## Once a day at dusk, the next unbeaten boss walks far off across the view
var boss_omen: BossOmen = null
## On the last quest, the crystal by home and the Skeleton King who comes to it
var final_boss: FinalBoss = null
## Every few dawns once some quests are done, Goblins raid home
var raids: Raids = null
## The tune for the time of day, a Blood Moon or a boss
var music: Music = null
## Rain, snow and storms over the player
var weather: Weather = null
## Knocks so far on the block being broken
var _knocks: int = 0


## The saved world's seed, set before the chunk manager makes the first chunk,
## and the player's spawn moved to the nearest meadow clear of the wild lands
func _enter_tree() -> void:
	ChunkGenerator.world_seed = WorldSave.load_seed()
	var p: Player = get_node("World/Player")
	var start: Vector3 = p.spawn_position
	var column: Vector2i = ChunkGenerator.spawn_column(Vector2i(floori(start.x), floori(start.z)))
	p.spawn_position = Vector3(column.x, start.y, column.y)


func _ready() -> void:
	player.set_chunk_manager(chunk_manager)
	chunk_manager.set_player(player)
	player.day_night = $World/DayNight
	$World/DayNight.day_began.connect(player.new_day)
	mobs = MobSpawner.new()
	mobs.name = "Mobs"
	$World.add_child(mobs)
	mobs.setup(player, chunk_manager, $World/DayNight)
	mobs.sound = sound
	drops = Node3D.new()
	drops.name = "Drops"
	$World.add_child(drops)
	player.slot_changed.connect(_on_slot_changed)
	player.target_state.connect(_on_target_state)
	player.block_broken.connect(_on_block_broken)
	player.block_placed.connect(_on_block_placed)
	player.break_progress.connect(_on_break_progress)
	player.flight_toggled.connect(_on_flight_toggled)
	player.items_dropped.connect(_on_items_dropped)
	player.stepped.connect(_on_stepped)
	player.landed.connect(_on_landed)
	player.picked_up.connect(_on_picked_up)
	player.ate.connect(_on_ate)
	player.pets.tamed.connect(_on_pet_tamed)
	player.health_changed.connect(_on_health_changed)
	mobs.boss_beaten.connect(player.beat_boss)
	if hud != null:
		hud.set_player(player)
		hud.hints.setup(player, chunk_manager)
		player.health_changed.connect(hud.set_health)
		mobs.boss_came.connect(hud.show_boss)
		mobs.boss_beaten.connect(hud.show_beaten)
		mobs.boss_beaten.connect(_tell_wizard_came)
		player.phoenix_rose.connect(hud.show_banner.bind(Legends.RISE_TEXT))
		mobs.boss_woke.connect(hud.show_woken)
		mobs.blood_moon_rose.connect(hud.show_banner.bind(BloodMoon.RISE_TEXT))
		player.blood_moon_survived.connect(hud.show_banner.bind(BloodMoon.DAWN_TEXT))
	ambience = Ambience.new()
	ambience.name = "Ambience"
	add_child(ambience)
	ambience.setup($World/DayNight)
	boss_arrival = BossArrival.new()
	boss_arrival.name = "BossArrival"
	add_child(boss_arrival)
	boss_arrival.setup(player, $World/DayNight, hud, sound)
	mobs.boss_came.connect(boss_arrival.arrive)
	mobs.boss_raged.connect(boss_arrival.enrage)
	boss_omen = BossOmen.new()
	boss_omen.name = "BossOmen"
	$World.add_child(boss_omen)
	boss_omen.setup(player, $World/DayNight, chunk_manager, hud)
	final_boss = FinalBoss.new()
	final_boss.name = "FinalBoss"
	add_child(final_boss)
	final_boss.setup(player, chunk_manager, $World/DayNight, mobs)
	raids = Raids.new()
	raids.name = "Raids"
	add_child(raids)
	raids.setup(player, mobs, $World/DayNight)
	if hud != null:
		raids.raid_came.connect(hud.show_banner.bind(Raids.COME_TEXT))
		raids.raid_beaten.connect(hud.show_banner.bind(Raids.BEAT_TEXT))
	music = Music.new()
	music.name = "Music"
	add_child(music)
	music.setup($World/DayNight, mobs, player)
	weather = Weather.new()
	weather.name = "Weather"
	$World.add_child(weather)
	weather.setup(player, $World/DayNight, chunk_manager, sound)
	inventory.item_chosen.connect(_on_item_chosen)
	backpack_screen = BackpackScreen.new()
	backpack_screen.name = "BackpackScreen"
	add_child(backpack_screen)
	backpack_screen.setup(player.backpack)
	chest_screen = ChestScreen.new()
	chest_screen.name = "ChestScreen"
	add_child(chest_screen)
	chest_screen.setup(player.props, player.backpack, chunk_manager)
	quest_screen = QuestScreen.new()
	quest_screen.name = "QuestScreen"
	add_child(quest_screen)
	quest_screen.setup(player, chunk_manager)
	wizard_screen = WizardScreen.new()
	wizard_screen.name = "WizardScreen"
	add_child(wizard_screen)
	wizard_screen.setup(player)
	build_ghost = BuildGhost.new()
	build_ghost.name = "BuildGhost"
	$World.add_child(build_ghost)
	build_ghost.setup(player, chunk_manager)
	player.villager_used.connect(_on_villager_used)
	player.wizard_used.connect(_on_wizard_used)
	end_screen = EndScreen.new()
	end_screen.name = "EndScreen"
	add_child(end_screen)
	end_screen.title_requested.connect(quit_to_title)
	player.quests_finished.connect(end_screen.open)
	_load_player()
	var autosave: Timer = Timer.new()
	autosave.name = "Autosave"
	autosave.wait_time = AUTOSAVE_TIME
	autosave.autostart = true
	autosave.timeout.connect(save_game)
	add_child(autosave)
	var treasure_tick: Timer = Timer.new()
	treasure_tick.name = "TreasureTick"
	treasure_tick.wait_time = TREASURE_TIME
	treasure_tick.autostart = true
	treasure_tick.timeout.connect(_on_treasure_tick)
	add_child(treasure_tick)
	var village_tick: Timer = Timer.new()
	village_tick.name = "VillageTick"
	village_tick.wait_time = VILLAGE_TIME
	village_tick.autostart = true
	village_tick.timeout.connect(_on_village_tick)
	add_child(village_tick)

	# Apply settings
	_apply_settings()

	# Wire settings menu
	settings_menu.fov_changed.connect(_on_fov_changed)
	settings_menu.sensitivity_changed.connect(_on_sensitivity_changed)
	settings_menu.view_radius_changed.connect(_on_view_radius_changed)
	settings_menu.skin_changed.connect(player.body.set_skin)
	settings_menu.survival_changed.connect(_on_survival_changed)
	settings_menu.closed.connect(_on_settings_closed)
	settings_menu.title_requested.connect(quit_to_title)
	settings_menu.title_button.visible = true


func _apply_settings() -> void:
	player.fov = settings_menu.get_fov()
	player.MOUSE_SENS = settings_menu.get_sens()
	_apply_view_radius(settings_menu.get_view_radius())
	player.body.set_skin(settings_menu.get_skin())
	player.set_survival(settings_menu.get_survival())


## Fills the backpacks from the save, if there is one.
func _load_player() -> void:
	player.load_data(WorldSave.load_player())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


## Saves both backpacks and the edited chunks.
func save_game() -> void:
	var err: int = WorldSave.save_player(player.save_data())
	if err != OK:
		push_warning("Main: saving the player failed err=%d" % err)
	chunk_manager.save_dirty_chunks()


## Saves and goes back to the title screen.
func quit_to_title() -> void:
	settings_menu.close()
	save_game()
	var err: int = get_tree().change_scene_to_file(TITLE_SCENE)
	if err != OK:
		push_warning("Main: loading the title failed err=%d" % err)


## Back in the settings closes them as Escape does.
func _on_settings_closed() -> void:
	_is_paused = false


## Each mode has its own backpack, so a switch is saved at once.
func _on_survival_changed(on: bool) -> void:
	player.set_survival(on)
	save_game()


func _on_fov_changed(v: float) -> void:
	player.fov = v


func _on_sensitivity_changed(v: float) -> void:
	player.MOUSE_SENS = v


func _on_view_radius_changed(r: int) -> void:
	_apply_view_radius(r)


func _apply_view_radius(r: int) -> void:
	chunk_manager.set_view_radius(r)
	# Fog fades the world out before the edge of the loaded chunks
	var env: Environment = world_env.environment
	env.fog_depth_end = (maxi(1, r) - 0.5) * Chunk.CHUNK_X
	env.fog_depth_begin = env.fog_depth_end * 0.6


func _on_slot_changed(block_id: int) -> void:
	if hud != null:
		hud.set_active_block(block_id)


func _on_item_chosen(item_id: int) -> void:
	player.set_hotbar_item(item_id)


func _on_target_state(state: StringName) -> void:
	if hud != null:
		hud.set_target_state(state)


func _on_block_broken(world_cell: Vector3i, block_id: int) -> void:
	sound.play("break", Vector3(world_cell) + Vector3(0.5, 0.5, 0.5))
	particles.burst(Vector3(world_cell) + Vector3(0.5, 0.5, 0.5), BlockDefs.get_mesh(block_id))


func _on_block_placed(world_cell: Vector3i, block_id: int) -> void:
	sound.play("place", Vector3(world_cell) + Vector3(0.5, 0.5, 0.5))


## Each footstep sounds like the ground it lands on.
func _on_stepped(ground_id: int) -> void:
	sound.play(SoundBank.step_sound(ground_id), player.global_position)


## A landing thuds like a footstep and kicks up dust of the ground, more for
## a longer fall.
func _on_landed(fall: float, ground_id: int) -> void:
	sound.play(SoundBank.step_sound(ground_id), player.global_position)
	if ground_id != Chunk.AIR:
		var dust: int = clampi(int(fall * DUST_PER_BLOCK), DUST_MIN, DUST_MAX)
		particles.burst(player.global_position, BlockDefs.get_mesh(ground_id), dust)


## A heartbeat plays while the player is low on health.
func _on_health_changed(health: int) -> void:
	sound.set_heartbeat(health <= Player.LOW_HEALTH)


func _on_items_dropped(item_id: int, count: int, at: Vector3) -> void:
	var drop: ItemDrop = ItemDrop.new()
	drop.setup(player, item_id, count)
	drops.add_child(drop)
	drop.global_position = at


## A pickup pops, flies from where it was into the player, and shows over the
## hotbar.
func _on_picked_up(item_id: int, count: int, from: Vector3) -> void:
	sound.play("pop", player.global_position)
	var pop: ItemPop = ItemPop.new()
	pop.setup(player, item_id, from)
	$World.add_child(pop)
	if hud != null:
		hud.show_pickup(item_id, count)


func _on_ate(_item_id: int) -> void:
	sound.play("munch", player.global_position)


## A bark and a banner for the pet just tamed.
func _on_pet_tamed(kind: String) -> void:
	sound.play("bark", player.global_position)
	if hud != null:
		hud.show_banner(Pets.TEXT % kind)


## The villager stops to face the player, and shows what it wants.
func _on_villager_used(villager: Mob) -> void:
	villager.face(player.global_position)
	quest_screen.open()


## The Wizard stops to face the player, and shows his shop.
func _on_wizard_used(wizard: Mob) -> void:
	wizard.face(player.global_position)
	wizard_screen.open()


## Says the Wizard came home once the boss that brings him is beaten, after
## that boss's own banner has gone.
func _tell_wizard_came(land: int) -> void:
	if land == Legends.BRINGS_WIZARD:
		get_tree().create_timer(Legends.COME_DELAY).timeout.connect(hud.show_banner.bind(Legends.COME_TEXT))


## Buries a treasure map's chest once the player comes near, and says so when
## it is found.
func _on_treasure_tick() -> void:
	if player.treasure.update(chunk_manager, player.global_position) and hud != null:
		hud.show_banner(TreasureMap.FOUND)


## Puts down the parts of home's village the quests done have earned.
func _on_village_tick() -> void:
	player.village_built = Village.build(chunk_manager, player.home, player.quest, player.village_built)


## Shows how far the block is broken, and knocks BREAK_KNOCKS times on the way:
## the crack wobbles, clicks and throws chips of the block.
func _on_break_progress(world_cell: Vector3i, progress: float) -> void:
	if progress <= 0.0:
		_knocks = 0
		break_overlay.hide_overlay()
		return
	var center: Vector3 = Vector3(world_cell) + Vector3(0.5, 0.5, 0.5)
	break_overlay.show_at(center, progress)
	var knocks: int = int(progress * BREAK_KNOCKS) + 1
	# The aim can stay a frame or two on a cell already broken: no knock on air
	var block: Mesh = BlockDefs.get_mesh(chunk_manager.get_block_at(world_cell))
	if knocks > _knocks and block != null:
		break_overlay.wobble()
		sound.play("chip", center)
		particles.burst(center, block, KNOCK_CHIPS)
	_knocks = knocks


func _on_flight_toggled(_is_flying: bool) -> void:
	pass


func _input(event: InputEvent) -> void:
	if end_screen.visible:
		# The end screen keeps the keys until it is closed
		if event.is_action_pressed("toggle_pause") or event.is_action_pressed("ui_cancel"):
			end_screen.close()
	elif event.is_action_pressed("toggle_inventory") and not _is_paused:
		# Survival opens the backpack, creative the item picker
		if chest_screen.visible:
			chest_screen.close()
		elif quest_screen.visible:
			quest_screen.close()
		elif wizard_screen.visible:
			wizard_screen.close()
		elif backpack_screen.visible:
			backpack_screen.close()
		elif inventory.visible:
			inventory.close()
		elif player.survival:
			# By a furnace the backpack makes what the furnace does too
			var feet: Vector3i = Vector3i(player.global_position.floor())
			backpack_screen.open(Recipes.furnace_near(chunk_manager, feet))
		else:
			inventory.open()
	# B goes back out of a menu as Escape does, but does not pause
	elif event.is_action_pressed("toggle_pause") or (event.is_action_pressed("ui_cancel") and _menu_open()):
		if inventory.visible:
			# Escape closes the inventory before it opens the pause menu
			inventory.close()
		elif backpack_screen.visible:
			backpack_screen.close()
		elif chest_screen.visible:
			chest_screen.close()
		elif quest_screen.visible:
			quest_screen.close()
		elif wizard_screen.visible:
			wizard_screen.close()
		elif _is_paused:
			settings_menu.close()
			_is_paused = false
		else:
			settings_menu.open()
			_is_paused = true
			save_game()


## True while a menu shows over the world: the item picker, the backpack, a
## chest, a quest, the Wizard's shop or the pause menu.
func _menu_open() -> bool:
	return (
		inventory.visible or backpack_screen.visible or chest_screen.visible
		or quest_screen.visible or wizard_screen.visible or _is_paused
	)
