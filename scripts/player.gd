class_name Player
extends CharacterBody3D

const Chunk: GDScript = preload("res://scripts/chunk.gd")

const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const FLY_SPEED: float = 10.0
const FLY_SPRINT_SPEED: float = 18.0
const JUMP_VELOCITY: float = 6.0
const GRAVITY: float = 20.0
const FLY_VERTICAL_SPEED: float = 8.0
const PITCH_LIMIT: float = 1.5533  # ~89 deg
## Seconds from one hit on a mob to the next
const SWING_TIME: float = 0.5
const DOUBLE_TAP_WINDOW: float = 0.3
## Height of the player's feet above the floor of the cart it rides
const SEAT_HEIGHT: float = 0.3
## Where the eyes are, above the feet
const EYE: Vector3 = Vector3(0.0, 1.6, 0.0)
## Blocks the third-person camera sits behind the eyes, and keeps off a wall by
const THIRD_PERSON_DISTANCE: float = 4.0
const CAMERA_MARGIN: float = 0.2
## Health points with no boss beaten; the HUD shows two to a heart
const MAX_HEALTH: int = 20
## At this health or less the hearts shake and a heartbeat plays
const LOW_HEALTH: int = 4
## Seconds to heal one point by day, counted from the last hit
const REGEN_TIME: float = 4.0
## Speed (blocks/s) a hit knocks the player away at, and up at
const KNOCKBACK: float = 6.0
const KNOCKBACK_UP: float = 5.0
## Seconds the knockback carries the player before walking takes over
const KNOCKBACK_TIME: float = 0.2
## Blocks the camera shakes by when the player is hurt, and when a hit lands on a mob
const HURT_SHAKE: float = 0.12
const HIT_SHAKE: float = 0.04
## Blocks a fall in survival drops without hurting; each block more is a point
const SAFE_FALL: float = 3.0
## Blocks walked from one footstep to the next
const STEP_DISTANCE: float = 1.8
## Blocks of fall that make a landing: a dip of the view, a thud and dust
const LAND_FALL: float = 1.2
## Seconds between checks that the player stands shut in, for a shelter quest
const SHELTER_CHECK: float = 0.5
## Share of its speed the player walks at while a yeti's hit chills them
const CHILL_SHARE: float = 0.5
## What a creative player with nothing in the backpack starts with
const CREATIVE_HOTBAR: Array[int] = [
	Chunk.GRASS, Chunk.DIRT, Chunk.STONE, Chunk.WOOD_PLANKS, Chunk.BRICK,
	Chunk.GREY_BRICK, Chunk.COAL, Chunk.DIAMOND, Chunk.SAND
]

var MOUSE_SENS: float = 0.002

signal target_state(state: StringName)
signal slot_changed(block_id: int)
signal block_broken(world_cell: Vector3i, block_id: int)
signal block_placed(world_cell: Vector3i, block_id: int)
signal flight_toggled(is_flying: bool)
signal break_progress(world_cell: Vector3i, progress: float)
signal health_changed(health: int)
## What a full backpack could not take, to lie on the ground at the point
signal items_dropped(item_id: int, count: int, at: Vector3)
## A right-click on a villager in survival, to show its quest
signal villager_used(villager: Mob)
## A right-click on the Wizard in survival, to show his shop
signal wizard_used(wizard: Mob)
## At no health, a Phoenix Feather brought the player back where they fell
signal phoenix_rose
## The quest being done moved on to index
signal quest_changed(index: int)
## A footstep on the block ground_id
signal stepped(ground_id: int)
## Came down on the block ground_id after falling fall blocks
signal landed(fall: float, ground_id: int)
## Took count of item_id into the backpack, from where it lay or was got
signal picked_up(item_id: int, count: int, from: Vector3)
## Ate one of item_id for health
signal ate(item_id: int)
## Finished the shelter quest, and its room became home
signal home_made
## Finished the last quest, and won the game
signal quests_finished
## Handed a villager's request in, or a new day brought the next
signal request_changed
signal bounty_changed
signal blood_moon_survived
## At no health, as the player starts again at home
signal died

@export var spawn_position: Vector3 = Vector3(8, 25, 8)
@export var fov: float = 75.0:
	set(value):
		fov = value
		if camera != null:
			camera.fov = value
@export var default_block_id: int = Chunk.GRASS

var current_slot: int = 0
## What the player carries; its first Backpack.HOTBAR slots are the hotbar
var backpack: Backpack = Backpack.new()
## In survival what is broken goes into the backpack and what is placed comes
## out of it, there is no flying and long falls hurt
var survival: bool = false
## Index in Quests.LIST of the quest being done; LIST.size() once all are
var quest: int = 0
## Where the player starts again, in the room the shelter quest was done in;
## Vector3.INF before then, when spawn_position is used
var home: Vector3 = Vector3.INF
## The bosses beaten, each a heart more health at the most
var bosses: BossLog = BossLog.new()
## The gifts quests gave, and the Wizard's bought
var gifts: Gifts = Gifts.new()
## True while a Phoenix Feather can bring the player back today
var phoenix_ready: bool = true
## The villagers' requests handed in
var requests: Requests = Requests.new()
var bounties: Bounties = Bounties.new()
var blood_moon: BloodMoon = BloodMoon.new()
## How many of Village.PARTS are put down round home
var village_built: int = 0
## The power the bosses beaten give, set on the villager screen (Powers)
var powers: Powers = Powers.new()
## The treasure map a request gave, if any
var treasure: TreasureMap = TreasureMap.new()
var builds: Builds = Builds.new()
## The animals tamed, one of each kind at the most
var pets: Pets = Pets.new()
## The horse ridden, and where the tamed one waits
var riding: Riding = Riding.new()
## The chests, doors, levers and buttons used, and what each chest holds
var props: Props = Props.new()
var _shelter_left: float = SHELTER_CHECK
## The backpack of the mode not being played, as Backpack.to_dict: survival
## and creative each keep their own
var _other_backpack: Dictionary = {}
## Highest point since the player last stood on the floor. INF after a spawn,
## so the first drop to the ground does not hurt.
var _fall_top: float = INF
var is_flying: bool = false
var _last_jump_press_time: float = -10.0
var _break_elapsed: float = 0.0
## Seconds until the next hit on a mob can land
var _swing_left: float = 0.0
## Rolls for what killed mobs leave and what broken crystals give
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var health: int = MAX_HEALTH
var _regen_left: float = REGEN_TIME
var _knock_left: float = 0.0
## Seconds left of a yeti's chill
var _chill_left: float = 0.0
## Blocks left to walk before the next footstep
var _step_left: float = STEP_DISTANCE
## Sprinting: once sprint is pressed it stays on until the player stops
## moving, so a click of the stick starts it as a held key does
var _sprint_on: bool = false
## True when the camera looks on from behind the player
var third_person: bool = false
## The kit character the player is, shown in the third-person view
var body: PlayerBody = null
## Shakes, dips and widens the camera
var feel: CameraFeel = CameraFeel.new()

@onready var camera: Camera3D = $Camera3D
## What the crosshair is on
@onready var aim: BlockAim = BlockAim.new($Camera3D/BlockHighlight)
@onready var hand: HeldHand = $Camera3D/Hand

var _chunk_manager: Node3D = null
## The minecart the player rides, or null
var cart: Minecart = null
## Tells night, when no health comes back, from day; with none it is always day
var day_night: DayNight = null
var material_lookup: Callable = func(_id: int) -> Material: return null


func _ready() -> void:
	position = spawn_position
	Mouse.mode = Input.MOUSE_MODE_CAPTURED
	camera.fov = fov
	_update_hand()
	backpack.changed.connect(_update_hand)
	block_broken.connect(func(cell: Vector3i, id: int) -> void: props.spill(self, cell, id))
	body = PlayerBody.new()
	body.visible = false
	add_child(body)


func set_chunk_manager(cm: Node3D) -> void:
	_chunk_manager = cm


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Mouse.mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event.relative)

	# Over a menu A presses a button, and does not jump or fly
	if event.is_action_pressed("jump") and Mouse.mode == Input.MOUSE_MODE_CAPTURED:
		_handle_jump_pressed()

	if event.is_action_pressed("toggle_view"):
		set_third_person(not third_person)

	for i in 9:
		if event.is_action_pressed("slot_%d" % (i + 1)):
			_set_slot(i)

	if event is InputEventMouseButton and event.pressed and Mouse.mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_slot(posmod(current_slot - 1, Backpack.HOTBAR))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_slot(posmod(current_slot + 1, Backpack.HOTBAR))
	if event.is_action_pressed("slot_prev") and Mouse.mode == Input.MOUSE_MODE_CAPTURED:
		_set_slot(posmod(current_slot - 1, Backpack.HOTBAR))
	if event.is_action_pressed("slot_next") and Mouse.mode == Input.MOUSE_MODE_CAPTURED:
		_set_slot(posmod(current_slot + 1, Backpack.HOTBAR))

	if _just_pressed(event, "break_block") and Mouse.mode == Input.MOUSE_MODE_CAPTURED:
		_start_break()
	if event.is_action_released("break_block"):
		_cancel_break()

	if _just_pressed(event, "place_block") and Mouse.mode == Input.MOUSE_MODE_CAPTURED:
		_use()
	if event.is_action_pressed("power") and Mouse.mode == Input.MOUSE_MODE_CAPTURED and survival:
		powers.use()


## True when event presses action. A trigger sends events all the while it is
## held, so only the one that first presses it counts.
func _just_pressed(event: InputEvent, action: StringName) -> bool:
	return event.is_action_pressed(action) and (not (event is InputEventJoypadMotion) or Input.is_action_just_pressed(action))


func _physics_process(delta: float) -> void:
	powers.tick(self, delta)
	if riding.horse != null:
		# The horse carries the player the way they look; sneak gets off
		var steer: bool = Mouse.mode == Input.MOUSE_MODE_CAPTURED
		if steer and Input.is_action_just_pressed("sneak"):
			riding.get_off(self)
		else:
			var way: Vector3 = transform.basis * _read_move_input() if steer else Vector3.ZERO
			riding.carry(self, way, steer and Input.is_action_pressed("jump"), delta)
		_fall_top = global_position.y
		_process_aim()
		return
	riding.tick(delta)
	if cart != null:
		# The cart carries the player: no walking, falling or flying
		cart.advance(delta)
		velocity = Vector3.ZERO
		global_position = cart.global_position + Vector3.UP * SEAT_HEIGHT
		_process_aim()
		return
	if Mouse.mode != Input.MOUSE_MODE_CAPTURED:
		velocity = Vector3.ZERO
		move_and_slide()
		_process_aim()
		return

	_update_sprint()
	if is_flying:
		_apply_fly_movement(delta)
	else:
		_apply_walk_movement(delta)

	move_and_slide()
	_track_fall()
	_track_steps(delta)
	_process_aim()


func _process(delta: float) -> void:
	if Mouse.mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(Controls.stick_look(delta))
	hand.bob(is_flying, Vector2(velocity.x, velocity.z).length())
	_process_break(delta)
	_regenerate(delta)
	_check_shelter(delta)
	_swing_left -= delta
	_chill_left -= delta
	feel.update(camera, delta, _is_sprinting(), fov)
	_place_camera()
	body.animate(Vector2(velocity.x, velocity.z).length())


## Looks on from behind the player, showing the body, or out of the eyes,
## showing the hand.
func set_third_person(on: bool) -> void:
	third_person = on
	body.visible = on
	hand.visible = not on
	_place_camera()


## Puts the camera at the eyes, or THIRD_PERSON_DISTANCE behind them in the
## third-person view, short of any cube in the way.
func _place_camera() -> void:
	if not third_person:
		camera.position = EYE
		return
	var eye: Vector3 = global_position + EYE
	var back: Vector3 = global_transform.basis * camera.transform.basis.z
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(eye, eye + back * THIRD_PERSON_DISTANCE)
	query.collision_mask = 1
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var distance: float = THIRD_PERSON_DISTANCE
	if not hit.is_empty():
		distance = maxf(0.0, eye.distance_to(hit.position) - CAMERA_MARGIN)
	camera.position = EYE + camera.transform.basis.z * distance


## Takes damage from a hit by something at from, which knocks the player up and
## away (off any horse), push times as hard and as long as a plain hit. At no
## health the player starts again at home.
func hurt(damage: int, from: Vector3, push: float = 1.0) -> void:
	riding.throw_off(self)
	if not _lose_health(damage):
		return
	var away: Vector3 = Vector3(global_position.x - from.x, 0.0, global_position.z - from.z).normalized()
	velocity = (away * KNOCKBACK + Vector3.UP * KNOCKBACK_UP) * push
	_knock_left = KNOCKBACK_TIME * push


## Slows the player's walking to CHILL_SHARE for time seconds, or for what is
## left of a chill already on them when that is longer. A Fur Cloak keeps it
## off.
func chill(time: float) -> void:
	if gifts.has(Gifts.WARM):
		return
	_chill_left = maxf(_chill_left, time)


## True while a yeti's chill slows the player.
func is_chilled() -> bool:
	return _chill_left > 0.0


## Takes damage off the health and returns true, or at no health starts again
## at the spawn and returns false; once a day a Phoenix Feather brings the
## player back where they are instead, at full health.
func _lose_health(damage: int) -> bool:
	health -= damage
	_regen_left = REGEN_TIME
	feel.shake(HURT_SHAKE)
	if health <= 0 and phoenix_ready and gifts.has(Gifts.PHOENIX):
		phoenix_ready = false
		health = bosses.max_health()
		health_changed.emit(health)
		phoenix_rose.emit()
		return true
	if health <= 0:
		died.emit()
		_respawn()
		return false
	health_changed.emit(health)
	return true


## Lands on coming down from LAND_FALL blocks or more, and in survival hurts
## the player on landing from more than SAFE_FALL blocks up, but for one in a
## Feather Cloak.
func _track_fall() -> void:
	if not is_on_floor() and not is_flying:
		_fall_top = maxf(_fall_top, global_position.y)
		return
	var fall: float = _fall_top - global_position.y
	_fall_top = global_position.y
	if is_inf(fall):
		return
	if fall >= LAND_FALL:
		feel.land(fall)
		landed.emit(fall, ground())
	if not survival or gifts.has(Gifts.FEATHER):
		return
	var damage: int = int(fall - SAFE_FALL)
	if damage > 0:
		_lose_health(damage)


## Counts the blocks walked on the floor, and steps every STEP_DISTANCE.
func _track_steps(delta: float) -> void:
	if is_flying or not is_on_floor():
		return
	_step_left -= Vector2(velocity.x, velocity.z).length() * delta
	if _step_left <= 0.0:
		_step_left += STEP_DISTANCE
		stepped.emit(ground())


## True while the player sprints and moves.
func _is_sprinting() -> bool:
	return _sprint_on and Vector2(velocity.x, velocity.z).length() > 0.1


## Starts sprinting when sprint is pressed while moving, and stops when the
## player stops moving.
func _update_sprint() -> void:
	var moving: bool = _read_move_input().length() > 0.1
	_sprint_on = moving and (_sprint_on or Input.is_action_pressed("sprint"))


## The block under the player's feet, or AIR with no world.
func ground() -> int:
	if _chunk_manager == null:
		return Chunk.AIR
	return _chunk_manager.get_block_at(Vector3i((global_position + Vector3.DOWN * 0.1).floor()))


## Starts again at home with full health, out of any cart or saddle. What the
## player carries stays in the backpack.
func _respawn() -> void:
	if cart != null:
		_leave_cart()
	riding.get_off(self)
	_go_home()
	velocity = Vector3.ZERO
	_chill_left = 0.0
	_fall_top = INF
	health = bosses.max_health()
	health_changed.emit(health)


## Heals one point each REGEN_TIME seconds while short of the most health
## (BossLog.max_health), but not at night, when only food heals.
func _regenerate(delta: float) -> void:
	if health >= bosses.max_health() or (day_night != null and day_night.is_night()):
		return
	_regen_left -= delta
	if _regen_left <= 0.0:
		_regen_left = REGEN_TIME
		health += 1
		health_changed.emit(health)


func _handle_mouse_look(relative: Vector2) -> void:
	rotate_y(-relative.x * MOUSE_SENS)
	camera.rotate_x(-relative.y * MOUSE_SENS)
	camera.rotation.x = clamp(camera.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)


func _handle_jump_pressed() -> void:
	if cart != null:
		_leave_cart()
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	# Only creative players fly
	if not survival and now - _last_jump_press_time < DOUBLE_TAP_WINDOW:
		is_flying = not is_flying
		_last_jump_press_time = -10.0
		flight_toggled.emit(is_flying)
		if is_flying:
			velocity.y = 0
	else:
		_last_jump_press_time = now
		if not is_flying and is_on_floor():
			velocity.y = JUMP_VELOCITY


func _set_slot(idx: int) -> void:
	if idx < 0 or idx >= Backpack.HOTBAR:
		return
	current_slot = idx
	_update_hand()
	slot_changed.emit(held())


## The item in the selected hotbar slot, or 0 when it is empty.
func held() -> int:
	return backpack.ids[current_slot]


## Puts item_id in the current hotbar slot and holds it.
func set_hotbar_item(item_id: int) -> void:
	backpack.put(current_slot, item_id, 1)
	_set_slot(current_slot)


## Switches between survival and creative, each with its own backpack. Survival
## ends any flight; a creative player with an empty backpack gets CREATIVE_HOTBAR.
func set_survival(on: bool) -> void:
	riding.get_off(self)
	var was: bool = survival
	# Set before the swap, so what the swap tells sees the new mode
	survival = on
	if on != was:
		var now: Dictionary = backpack.to_dict()
		backpack.from_dict(_other_backpack)
		_other_backpack = now
	if on and is_flying:
		is_flying = false
		flight_toggled.emit(false)
	if not on and backpack.ids.max() == 0:
		for i in CREATIVE_HOTBAR.size():
			backpack.put(i, CREATIVE_HOTBAR[i], 1)
	_set_slot(current_slot)


## Hands a villager what the quest wants for its reward. Returns false, and
## takes nothing, when the backpack holds too little.
func hand_in() -> bool:
	if not Quests.can_hand_in(backpack, quest):
		return false
	var wanted: Array = Quests.LIST[quest]
	backpack.remove(wanted[0], wanted[1])
	_reward_quest()
	return true


## Hands a villager what today's request wants for what it gives. Returns
## false, and takes nothing, when one was handed in today or the backpack
## holds too little.
func hand_in_request() -> bool:
	var request: Array = requests.today(quest)
	if requests.waiting or not Requests.can_hand_in(backpack, request):
		return false
	backpack.remove(request[0], request[1])
	give(request[2], request[3], global_position)
	if quest >= TreasureMap.FROM_QUEST and not treasure.active:
		treasure.make(global_position, _rng)
	requests.hand_in()
	request_changed.emit()
	return true


func claim_bounty() -> void:
	var bounty: Array = bounties.claim(quest)
	if bounty.is_empty():
		return
	give(bounty[2], bounty[3], global_position)
	bounty_changed.emit()


## A new day, with a new request from the villagers, and a Phoenix Feather
## ready again
func new_day() -> void:
	phoenix_ready = true
	requests.waiting = false
	request_changed.emit()
	if blood_moon.new_day() and survival:
		for item: Array in BloodMoon.REWARD:
			give(item[0], item[1], global_position)
		blood_moon_survived.emit()


## Finishes a shelter quest when the player stands in a shut-in room with as
## many cells as it wants, and makes that room home. Returns whether it did.
func finish_shelter() -> bool:
	if not Quests.wants_shelter(quest):
		return false
	var feet: Vector3i = Vector3i((global_position + Vector3.UP * 0.1).floor())
	if Shelter.room_size(_chunk_manager, feet) < Quests.LIST[quest][1]:
		return false
	home = Vector3(feet.x + 0.5, feet.y, feet.z + 0.5)
	_reward_quest()
	home_made.emit()
	return true


## Gives the quest's tool or gift and REWARD_CHEESE Cheese, which drop at the
## player's feet when the backpack is full, and moves on to the next quest: past it
## too when it is a boss already beaten. After the last, quests_finished.
func _reward_quest() -> void:
	var reward: int = Quests.LIST[quest][2]
	if Gifts.is_gift(reward):
		gifts.give(reward)
	else:
		give(reward, 1, global_position)
	give(Chunk.CHEESE, Quests.REWARD_CHEESE, global_position)
	quest += 1
	quest_changed.emit(quest)
	if Quests.boss_done(quest, bosses.beaten):
		_reward_quest()
	elif Quests.all_done(quest):
		quests_finished.emit()


## Tries finish_shelter each SHELTER_CHECK seconds in survival.
func _check_shelter(delta: float) -> void:
	_shelter_left -= delta
	if _shelter_left > 0.0:
		return
	_shelter_left = SHELTER_CHECK
	if survival:
		finish_shelter()


## Puts the player at home, or at spawn_position before there is one, with
## the chunk there loaded to stand on.
func _go_home() -> void:
	global_position = home if home.is_finite() else spawn_position
	if _chunk_manager != null:
		_chunk_manager.ensure_chunk_at_world(global_position)


## Beats the boss of land: the first time it is a heart container, and the
## player heals to the new most health. Its power is set when none is. It
## finishes a quest to beat it.
func beat_boss(land: int) -> void:
	if bosses.beat(land):
		health = bosses.max_health()
		health_changed.emit(health)
	if powers.chosen == -1:
		powers.choose_next(bosses.beaten)
	if Quests.boss_done(quest, bosses.beaten):
		_reward_quest()


## Both backpacks, the quest, any home, the bosses woken and beaten, the gifts
## and the requests, for WorldSave.save_player
func save_data() -> Dictionary:
	var now: Dictionary = backpack.to_dict()
	var data: Dictionary = {"survival": now, "creative": _other_backpack, "quest": quest}
	if not survival:
		data = {"survival": _other_backpack, "creative": now, "quest": quest}
	if home.is_finite():
		data["home"] = [home.x, home.y, home.z]
	data["bosses"] = bosses.beaten.duplicate()
	data["woken"] = bosses.woken.duplicate()
	data["gifts"] = gifts.list.duplicate()
	data["requests"] = requests.to_dict()
	data["bounties"] = bounties.to_dict()
	data["pets"] = pets.to_dict()
	data["riding"] = riding.to_dict()
	data["blood_moon"] = blood_moon.to_dict()
	data["village_built"] = village_built
	data["powers"] = powers.to_dict()
	data["treasure"] = treasure.to_dict()
	data["builds"] = builds.to_dict()
	data["chests"] = props.to_dict()
	return data


## Fills both backpacks, the quest, the home, the bosses, the gifts and the
## requests from what save_data gave, and puts the player at a home with full
## health. An older save has one "backpack", which is the survival one, and
## none of the rest.
func load_data(data: Dictionary) -> void:
	var kept: Dictionary = _backpack_dict(data.get("survival", data.get("backpack")))
	var made: Dictionary = _backpack_dict(data.get("creative"))
	backpack.from_dict(kept if survival else made)
	_other_backpack = made if survival else kept
	var saved_quest: Variant = data.get("quest")
	quest = 0
	if saved_quest is int or saved_quest is float:
		quest = clampi(int(saved_quest), 0, Quests.LIST.size())
	var saved_home: Variant = data.get("home")
	home = Vector3.INF
	if saved_home is Array and saved_home.size() == 3:
		if saved_home.all(func(n: Variant) -> bool: return n is int or n is float):
			home = Vector3(saved_home[0], saved_home[1], saved_home[2])
			_go_home()
	bosses.load_list(data.get("bosses"))
	bosses.load_woken(data.get("woken"))
	gifts.load_list(data.get("gifts"))
	requests.from_dict(data.get("requests"))
	bounties.from_dict(data.get("bounties"))
	pets.from_dict(data.get("pets"))
	riding.from_dict(data.get("riding"))
	blood_moon.from_dict(data.get("blood_moon"))
	village_built = Village.load_built(data.get("village_built"))
	props.from_dict(data.get("chests"))
	powers.from_dict(data.get("powers"))
	treasure.from_dict(data.get("treasure"))
	builds.from_dict(data.get("builds"))
	health = bosses.max_health()
	health_changed.emit(health)
	quest_changed.emit(quest)


## saved checked as a backpack: its to_dict, or an empty backpack's
static func _backpack_dict(saved: Variant) -> Dictionary:
	var out: Backpack = Backpack.new()
	if saved is Dictionary:
		out.from_dict(saved)
	return out.to_dict()


## Walking or running speed: Swift Boots make it faster and a yeti's chill
## slower.
func _walk_speed() -> float:
	var speed: float = SPRINT_SPEED if _sprint_on else WALK_SPEED
	if gifts.has(Gifts.SWIFT):
		speed *= Gifts.SWIFT_SHARE
	if _chill_left > 0.0:
		# A yeti's hit slows the player for a while
		speed *= CHILL_SHARE
	return speed


## A roll for whether a killed animal leaves a Cheese (MobDefs.leaves_cheese):
## with a Lucky Clover always one that does.
func _cheese_roll() -> float:
	return 0.0 if gifts.has(Gifts.LUCKY) else _rng.randf()


func _apply_walk_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		if gifts.has(Gifts.FEATHER) and Input.is_action_pressed("jump"):
			# A Feather Cloak glides the player down
			velocity.y = maxf(velocity.y, -Gifts.GLIDE_FALL)

	var input_dir: Vector3 = _read_move_input()
	var speed: float = _walk_speed()
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()
	if _knock_left > 0.0:
		# A hit carries the player for a moment
		_knock_left -= delta
	elif direction.length() > 0.01:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)


func _apply_fly_movement(delta: float) -> void:
	velocity.y = 0
	var input_dir: Vector3 = _read_move_input()
	var speed: float = FLY_SPRINT_SPEED if _sprint_on else FLY_SPEED
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()
	if direction.length() > 0.01:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0
		velocity.z = 0
	if Input.is_action_pressed("jump"):
		velocity.y = FLY_VERTICAL_SPEED
	elif Input.is_action_pressed("sneak"):
		velocity.y = -FLY_VERTICAL_SPEED


func _read_move_input() -> Vector3:
	return Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)


## Aims from the eyes, which in the third-person view are in front of the
## camera, and says when what is aimed at changes.
func _process_aim() -> void:
	var forward: Vector3 = -camera.global_transform.basis.z
	if aim.update(get_world_3d().direct_space_state, global_position + EYE, forward):
		target_state.emit(aim.state)


func _start_break() -> void:
	if aim.mob != null:
		# Left-click on a mob hits it, once each SWING_TIME; never a tamed one
		if _swing_left > 0.0 or aim.mob.tamed:
			return
		_swing_left = SWING_TIME
		_swing_hand()
		var was_alive: bool = aim.mob.health > 0
		aim.mob.hurt(BlockDefs.attack_damage(held()) * powers.damage_scale(), global_position)
		if was_alive:
			feel.shake(HIT_SHAKE)
		if gifts.has(Gifts.FLAME) and BlockDefs.TOOLS.get(held(), [0])[0] == BlockDefs.TOOL_SWORD:
			# A Flame Blade's sword sets the monster on fire
			Burn.light(aim.mob)
		if survival and was_alive and aim.mob.health <= 0:
			# A killed mob's drop goes into the backpack, or by its feet when full
			var got: Array = MobDefs.drop(aim.mob.kind)
			if got[0] != 0:
				give(got[0], got[1], aim.mob.global_position)
			if MobDefs.leaves_cheese(aim.mob.kind, _cheese_roll()):
				give(Chunk.CHEESE, 1, aim.mob.global_position)
			if bounties.count_kill(aim.mob.kind, quest):
				bounty_changed.emit()
		return
	if aim.chunk == null:
		return
	_break_elapsed = 0.0
	break_progress.emit(aim.cell, 0.0)


func _cancel_break() -> void:
	if _break_elapsed > 0.0:
		break_progress.emit(aim.cell, 0.0)
	_break_elapsed = 0.0


func _process_break(delta: float) -> void:
	if aim.chunk == null:
		return
	if not Input.is_action_pressed("break_block"):
		if _break_elapsed > 0.0:
			_break_elapsed = 0.0
			break_progress.emit(aim.cell, 0.0)
		return
	_break_elapsed += delta
	var time: float = _break_time()
	if _break_elapsed >= time:
		_perform_break()
		_break_elapsed = 0.0
		break_progress.emit(aim.cell, 0.0)
		return
	break_progress.emit(aim.cell, _break_elapsed / time)


## Seconds to break the target with the held item.
func _break_time() -> float:
	if _chunk_manager == null:
		return BlockDefs.HAND_BREAK_TIME
	return BlockDefs.break_time(_chunk_manager.get_block_at(aim.cell), held())


func _perform_break() -> void:
	if aim.chunk == null or _chunk_manager == null:
		return
	var id: int = _chunk_manager.get_block_at(aim.cell)
	if id == Chunk.AIR:
		return
	_chunk_manager.set_block_at(aim.cell, Chunk.AIR)
	_swing_hand()
	_collect(id, aim.cell)
	block_broken.emit(aim.cell, id)
	# Plants and props standing on the block go with it
	var above: Vector3i = aim.cell + Vector3i.UP
	var above_id: int = _chunk_manager.get_block_at(above)
	if above_id != Chunk.AIR and not BlockDefs.is_cube(above_id):
		_chunk_manager.set_block_at(above, Chunk.AIR)
		_collect(above_id, above)
		block_broken.emit(above, above_id)


## In survival, puts what breaking id at cell gives into the backpack. What
## does not fit lies on the ground in the cell.
func _collect(id: int, cell: Vector3i) -> void:
	if not survival:
		return
	var got: Array = BlockDefs.drop(id, held(), _rng.randf())
	if got[0] != 0:
		give(got[0], got[1], Vector3(cell) + Vector3(0.5, 0.0, 0.5))


## Puts as much of count of item_id into the backpack as fits, saying so when
## any goes in; returns how many did not fit.
func take(item_id: int, count: int, from: Vector3) -> int:
	var left: int = backpack.add(item_id, count)
	if left < count:
		picked_up.emit(item_id, count - left, from)
	return left


## Puts count of item_id into the backpack; what does not fit drops at the point.
func give(item_id: int, count: int, at: Vector3) -> void:
	var left: int = take(item_id, count, at)
	if left > 0:
		items_dropped.emit(item_id, left, at)


## Right-click: in survival talk to the villager or the Wizard in the
## crosshair, else use the targeted prop, get on the horse or feed the mob in
## the crosshair, eat the food in hand, or place the held item (always when
## sneaking).
func _use() -> void:
	if survival and aim.mob != null and Quests.is_villager(aim.mob.kind):
		villager_used.emit(aim.mob)
	elif survival and aim.mob != null and aim.mob.kind == MobDefs.WIZARD:
		wizard_used.emit(aim.mob)
	elif Input.is_action_pressed("sneak") or not (_try_interact() or riding.try_mount(self, aim.mob) or pets.feed(self, aim.mob) or _eat()):
		_try_place()


## In survival, eats one of the food in hand for its health when short of
## the most health. Returns true when the click is used up.
func _eat() -> bool:
	var id: int = held()
	var food: int = BlockDefs.food_value(id)
	if not survival or food == 0 or health >= bosses.max_health():
		return false
	backpack.take_one(current_slot)
	health = mini(health + food, bosses.max_health())
	health_changed.emit(health)
	_swing_hand()
	ate.emit(id)
	return true


## Gets in a cart on a rail with the Minecart in hand, or uses the targeted
## chest, door, lever or button (see Props.use). Returns true when the click is
## used up.
func _try_interact() -> bool:
	if aim.chunk == null or aim.state != &"block" or _chunk_manager == null:
		return false
	var id: int = _chunk_manager.get_block_at(aim.cell)
	if BlockDefs.VARIANTS.get(id, id) == BlockDefs.RAIL and held() == BlockDefs.MINECART:
		_board(aim.cell)
	elif not props.use(self, _chunk_manager, aim.cell):
		return false
	_swing_hand()
	return true


## Puts a cart on the rail in cell and gets in; it sets off along the track the
## way the player looks.
func _board(cell: Vector3i) -> void:
	if cart != null or riding.horse != null:
		return
	cart = Minecart.new()
	get_parent().add_child(cart)
	cart.setup(_chunk_manager, cell, -global_transform.basis.z)


## Gets out onto the rail cell the cart last passed. The cart goes; the
## minecart stays in the hand.
func _leave_cart() -> void:
	global_position = Vector3(cart.cell) + Vector3(0.5, 0.0, 0.5)
	_fall_top = global_position.y
	cart.queue_free()
	cart = null


func _try_place() -> void:
	if aim.chunk == null or aim.state != &"block":
		return
	var block_id: int = BlockDefs.placed_as(held())
	# Tools and the key are held, never placed
	if not BlockDefs.is_placeable(block_id):
		return
	if _chunk_manager == null:
		return
	var place_cell: Vector3i = aim.cell + Vector3i(aim.normal.round())
	# Placing into a plant replaces it
	if BlockDefs.is_replaceable(_chunk_manager.get_block_at(aim.cell)):
		place_cell = aim.cell
	if BlockDefs.is_solid(block_id) and would_be_inside(place_cell):
		return
	var existing: int = _chunk_manager.get_block_at(place_cell)
	if existing != Chunk.AIR and not BlockDefs.is_replaceable(existing):
		return
	# Items that are not cubes need a cube to stand on
	var below: int = _chunk_manager.get_block_at(place_cell + Vector3i.DOWN)
	if not BlockDefs.is_cube(block_id) and not BlockDefs.is_cube(below):
		return
	if not _chunk_manager.set_block_at(place_cell, block_id):
		return
	if BlockDefs.has_facing(block_id):
		# Turn the prop's front toward the player
		_chunk_manager.set_facing_at(place_cell, roundi(rotation.y / (PI / 2.0)))
	if survival:
		backpack.take_one(current_slot)
	_swing_hand()
	block_placed.emit(place_cell, block_id)


func would_be_inside(world_cell: Vector3i) -> bool:
	# Player AABB in world space: capsule radius 0.3, height 1.8, origin at the feet.
	var block_min: Vector3 = Vector3(world_cell)
	var block_max: Vector3 = block_min + Vector3.ONE
	var player_min: Vector3 = global_position - Vector3(0.3, 0.0, 0.3)
	var player_max: Vector3 = global_position + Vector3(0.3, 1.8, 0.3)
	return (
		block_min.x < player_max.x
		and block_max.x > player_min.x
		and block_min.y < player_max.y
		and block_max.y > player_min.y
		and block_min.z < player_max.z
		and block_max.z > player_min.z
	)


## Shows the selected hotbar item in the hand.
func _update_hand() -> void:
	if hand == null:
		return
	hand.hold(held())


func _swing_hand() -> void:
	body.punch()
	hand.swing()
