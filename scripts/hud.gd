extends CanvasLayer

const Chunk: GDScript = preload("res://scripts/chunk.gd")

const HOTBAR_BLOCKS: Array[int] = [
	Chunk.GRASS, Chunk.DIRT, Chunk.STONE, Chunk.WOOD_PLANKS, Chunk.BRICK,
	Chunk.GREY_BRICK, Chunk.COAL, Chunk.DIAMOND, Chunk.SAND
]
const HEART_SIZE: float = 18.0
const HEART_GAP: float = 2.0
## Points along each half of a heart's outline
const HEART_STEPS: int = 16
const HEART_COLOR: Color = Color(0.9, 0.1, 0.15, 1.0)
const HEART_EMPTY_COLOR: Color = Color(0.1, 0.0, 0.0, 0.6)
## The red the screen flashes when the player is hit, fading over HURT_FLASH_TIME
const HURT_FLASH_COLOR: Color = Color(0.8, 0.0, 0.0, 0.35)
const HURT_FLASH_TIME: float = 0.4
## Pixels each heart jumps up or down by while health is low
const HEART_SHAKE: float = 2.0
## Pixels from the top left corner to the quest line
const QUEST_MARGIN: float = 12.0
## Pixels from the top to the treasure line under it, and seconds between
## updates of that line
const TREASURE_TOP: float = 40.0
const TREASURE_EVERY: float = 0.25
## Pixels from the top to the power line, under the treasure line
const POWER_TOP: float = 68.0
## Seconds the line over the hearts shows a pickup for, and seconds it fades over
const PICKUP_TIME: float = 1.5
const PICKUP_FADE: float = 0.5
## How much bigger a hotbar icon jumps on a pickup, and seconds it eases back in
const BOUNCE_GROW: float = 0.3
const BOUNCE_TIME: float = 0.15
## Each land's name, by its ChunkGenerator.BIOME_ number, shown big when the
## player walks into it, and the final boss's place (MobDefs.FINAL_LAND);
## seconds it fades in and out over, and holds for
const LAND_NAMES: Array[String] = ["The Meadow", "The Desert", "The Snowfields", "The Crystal"]
const BANNER_FADE: float = 0.5
const BANNER_TIME: float = 3.0
const BANNER_FONT_SIZE: int = 44
## Pixels from the top of the screen to the land's name, and its width
const BANNER_TOP: float = 120.0
const BANNER_WIDTH: float = 600.0
## Shown when the player's shelter becomes home
const HOME_TEXT: String = "This shelter is your home"
## The pale blue over the screen while a yeti's chill slows the player
const FROST_COLOR: Color = Color(0.6, 0.85, 1.0, 0.2)
## Pixels from the top of the screen to a boss's health bar, its size and red;
## its name and the sword it takes show over it
const BOSS_TOP: float = 40.0
const BOSS_BAR_SIZE: Vector2 = Vector2(400.0, 16.0)
const BOSS_COLOR: Color = Color(0.8, 0.1, 0.1, 1.0)
const BOSS_TEXT: String = "%s  (%s or better)"
## Shown when a boss is beaten, for the heart it gave
const BEATEN_TEXT: String = "%s is beaten: one more heart!"
## Shown when a boss wakes, with the land it hunts
const WOKEN_TEXT: String = "%s hunts %s by night"
## The screen when the player dies: where they are back, held for DEATH_TIME
## seconds and then faded out over DEATH_FADE, over a dark red
const DEATH_HOME: String = "You died\nBack home"
const DEATH_START: String = "You died\nBack at the start"
const DEATH_TIME: float = 2.0
const DEATH_FADE: float = 0.6
const DEATH_COLOR: Color = Color(0.25, 0.0, 0.0, 0.6)

## The lines that say what the buttons do
var hints: Hints = null

var _player: Player = null
var _slot_panels: Array = []
var _slot_icons: Array[TextureRect] = []
var _slot_counts: Array[Label] = []
var _style_normal: StyleBoxFlat = null
var _style_selected: StyleBoxFlat = null
var _crosshair: Control = null
var _hearts: Control = null
var _hurt_flash: ColorRect = null
## Shows FROST_COLOR while the player is chilled
var _frost: ColorRect = null
## The quest being done, shown in survival
var _quest: RichTextLabel = null
## How far and which way a treasure map's treasure is, shown while there is one
var _treasure: Label = null
var _treasure_wait: float = 0.0
## The power set and how it is (Powers.describe), shown in survival while set
var _power: Label = null
## "+N name" for the last pickup, the item and how many, and the fade of it
var _pickup: Label = null
var _pickup_id: int = 0
var _pickup_count: int = 0
var _pickup_tween: Tween = null
## The land's name, the land and column the player was last in, and the fade
var _banner: Label = null
var _land: int = -1
var _column: Vector2i = Vector2i.MAX
var _banner_tween: Tween = null
## The boss about, or null, its health bar and its name over the bar
var _boss: Mob = null
var _boss_bar: ProgressBar = null
var _boss_name: Label = null
var _health: int = Player.MAX_HEALTH
## item id -> icon texture, so each item is rendered once
var _icons: Dictionary = {}
## The clock of the day and night
var _clock: SkyClock = null
## The death screen and its words
var _death: ColorRect = null
var _death_label: Label = null
var _death_tween: Tween = null


func _ready() -> void:
	_build_crosshair()
	_build_hotbar()
	_build_hearts()
	_build_quest()
	_build_treasure()
	_build_power()
	_build_pickup()
	_build_banner()
	_build_boss_bar()
	_build_death()
	hints = Hints.new()
	add_child(hints)
	_clock = SkyClock.new()
	add_child(_clock)


## Redraws the hearts each frame while they shake, names the land when the
## player walks into a new one, frosts the screen while they are chilled, and
## shows a boss's health while it lives, and says where a map's treasure is
## and how the power set is.
func _process(delta: float) -> void:
	if _health <= Player.LOW_HEALTH:
		_hearts.queue_redraw()
	if _player != null:
		_check_land()
		_frost.visible = _player.is_chilled()
		_treasure_wait -= delta
		if _treasure_wait <= 0.0:
			_treasure_wait = TREASURE_EVERY
			_treasure.text = _player.treasure.describe(_player.global_position)
			_treasure.visible = _player.survival and _treasure.text != ""
			_power.text = _player.powers.describe()
			_power.visible = _player.survival and _power.text != ""
	_boss_bar.visible = is_instance_valid(_boss) and _boss.health > 0
	if _boss_bar.visible:
		_boss_bar.value = _boss.health


func set_player(p: Player) -> void:
	_player = p
	p.backpack.changed.connect(_refresh_slots)
	p.backpack.changed.connect(_refresh_quest)
	p.quest_changed.connect(_refresh_quest.unbind(1))
	p.home_made.connect(show_banner.bind(HOME_TEXT))
	p.died.connect(show_death)
	hints.pad_changed.connect(_refresh_quest)
	_clock.setup(p.day_night, p.blood_moon)
	_refresh_slots()
	_refresh_quest()
	_highlight_slot(p.current_slot)
	_set_active_block_internal(p.held())


func set_active_block(block_id: int) -> void:
	if _player != null:
		_highlight_slot(_player.current_slot)
	_set_active_block_internal(block_id)


## Shows each hotbar slot's item, and how many when it is more than one.
func _refresh_slots() -> void:
	for i in _slot_icons.size():
		var id: int = _player.backpack.ids[i]
		var count: int = _player.backpack.counts[i]
		_slot_icons[i].texture = _icon(id) if id != 0 else null
		_slot_counts[i].text = str(count) if count > 1 else ""


## Shows the quest being done and how much of it the backpack holds, and once
## it holds enough where to hand it in; in survival only.
func _refresh_quest() -> void:
	_quest.visible = _player.survival
	_quest.text = "Quest: " + Quests.describe(_player.backpack, _player.quest)
	_quest.text += Quests.hand_in_hint(_player.backpack, _player.quest, UseHint.button(hints.pad))


## Shows health as hearts, and flashes the screen red when it drops.
func set_health(health: int) -> void:
	if health < _health:
		_hurt_flash.color = HURT_FLASH_COLOR
		create_tween().tween_property(_hurt_flash, "color:a", 0.0, HURT_FLASH_TIME)
	_health = health
	_hearts.queue_redraw()


## Shows "+count name" over the hearts for a pickup, adding to the count while
## the same item still shows, and bounces the hotbar slot it went in.
func show_pickup(item_id: int, count: int) -> void:
	if item_id == _pickup_id and _pickup.modulate.a > 0.0:
		_pickup_count += count
	else:
		_pickup_id = item_id
		_pickup_count = count
	_pickup.text = "+%d %s" % [_pickup_count, BlockDefs.display_name(item_id)]
	_pickup.modulate.a = 1.0
	if _pickup_tween != null:
		_pickup_tween.kill()
	_pickup_tween = create_tween()
	_pickup_tween.tween_interval(PICKUP_TIME)
	_pickup_tween.tween_property(_pickup, "modulate:a", 0.0, PICKUP_FADE)
	_bounce(item_id)


func set_target_state(state: StringName) -> void:
	if _crosshair == null:
		return
	if state == &"block":
		_crosshair.modulate = Color(0.4, 0.9, 0.4, 1.0)
	elif state == &"mob":
		_crosshair.modulate = Color(1.0, 0.35, 0.3, 1.0)
	else:
		_crosshair.modulate = Color(1, 1, 1, 0.8)


func _build_crosshair() -> void:
	_crosshair = Control.new()
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crosshair)
	var line_h: ColorRect = ColorRect.new()
	line_h.color = Color(1, 1, 1, 0.8)
	line_h.size = Vector2(8, 2)
	line_h.position = Vector2(-4, -1)
	_crosshair.add_child(line_h)
	var line_v: ColorRect = ColorRect.new()
	line_v.color = Color(1, 1, 1, 0.8)
	line_v.size = Vector2(2, 8)
	line_v.position = Vector2(-1, -4)
	_crosshair.add_child(line_v)


func _build_hotbar() -> void:
	_style_normal = _make_slot_style(Color(0.6, 0.6, 0.6, 1), 2)
	_style_selected = _make_slot_style(Color(1, 1, 1, 1), 3)
	var bar: HBoxContainer = HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	# 9 slots of 48 px plus 8 gaps of 4 px = 464 px wide
	bar.position = Vector2(-232, -56)
	bar.add_theme_constant_override("separation", 4)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	for i in 9:
		var panel: Panel = Panel.new()
		panel.custom_minimum_size = Vector2(48, 48)
		panel.add_theme_stylebox_override("panel", _style_normal)
		bar.add_child(panel)
		var icon: TextureRect = TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 4
		icon.offset_top = 4
		icon.offset_right = -4
		icon.offset_bottom = -4
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Bounces from its middle
		icon.pivot_offset_ratio = Vector2(0.5, 0.5)
		panel.add_child(icon)
		_slot_icons.append(icon)
		var label: Label = Label.new()
		label.text = str(i + 1)
		label.position = Vector2(4, 2)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 4)
		panel.add_child(label)
		var count: Label = Label.new()
		count.position = Vector2(4, 24)
		count.size = Vector2(40, 22)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		count.add_theme_constant_override("outline_size", 4)
		panel.add_child(count)
		_slot_counts.append(count)
		_slot_panels.append(panel)


## The hearts over the hotbar's left end, and behind everything the red the
## screen flashes on a hit and the frost of a chill.
func _build_hearts() -> void:
	_hurt_flash = ColorRect.new()
	_hurt_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hurt_flash.color = Color(HURT_FLASH_COLOR, 0.0)
	_hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hurt_flash)
	move_child(_hurt_flash, 0)
	_frost = ColorRect.new()
	_frost.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frost.color = FROST_COLOR
	_frost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frost.visible = false
	add_child(_frost)
	move_child(_frost, 0)
	_hearts = Control.new()
	_hearts.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hearts.position = Vector2(-232, -60 - HEART_SIZE)
	_hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hearts.draw.connect(_draw_hearts)
	add_child(_hearts)


## The quest line in the top left corner, on a backing to read against the sky
## with the use button's picture.
func _build_quest() -> void:
	_quest = InputIcons.line()
	# Wider to the right only, as it starts in the corner
	_quest.grow_horizontal = Control.GROW_DIRECTION_END
	_quest.position = Vector2(QUEST_MARGIN, QUEST_MARGIN)
	_quest.visible = false
	add_child(_quest)


## The treasure line under the quest line, outlined like it.
func _build_treasure() -> void:
	_treasure = Label.new()
	_treasure.position = Vector2(QUEST_MARGIN, TREASURE_TOP)
	_treasure.add_theme_constant_override("outline_size", 4)
	_treasure.add_theme_color_override("font_outline_color", Color.BLACK)
	_treasure.visible = false
	add_child(_treasure)


func _build_power() -> void:
	_power = Label.new()
	_power.position = Vector2(QUEST_MARGIN, POWER_TOP)
	_power.add_theme_constant_override("outline_size", 4)
	_power.add_theme_color_override("font_outline_color", Color.BLACK)
	_power.visible = false
	add_child(_power)


## The line that shows each pickup, as wide as the hotbar and just over the
## hearts; clear till the first one.
func _build_pickup() -> void:
	_pickup = Label.new()
	_pickup.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_pickup.position = Vector2(-232, -106)
	_pickup.size = Vector2(464, 24)
	_pickup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pickup.add_theme_constant_override("outline_size", 4)
	_pickup.add_theme_color_override("font_outline_color", Color.BLACK)
	_pickup.modulate.a = 0.0
	add_child(_pickup)


## Shows the death screen a moment, saying where the player is back: home, or
## the start when there is none.
func show_death() -> void:
	_death_label.text = DEATH_HOME if _player.home.is_finite() else DEATH_START
	_death.visible = true
	_death.modulate.a = 1.0
	if _death_tween != null:
		_death_tween.kill()
	_death_tween = create_tween()
	_death_tween.tween_interval(DEATH_TIME)
	_death_tween.tween_property(_death, "modulate:a", 0.0, DEATH_FADE)
	_death_tween.tween_callback(_death.hide)


## The death screen, a dark red over all with big words in the middle; hidden
## till the player dies.
func _build_death() -> void:
	_death = ColorRect.new()
	_death.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_death.color = DEATH_COLOR
	_death.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death.visible = false
	add_child(_death)
	_death_label = Label.new()
	_death_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_death_label.add_theme_font_size_override("font_size", BANNER_FONT_SIZE)
	_death_label.add_theme_constant_override("outline_size", 8)
	_death_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_death_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death.add_child(_death_label)


## The land's name, big in the upper middle of the screen; clear till the first.
func _build_banner() -> void:
	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.position = Vector2(-BANNER_WIDTH / 2.0, BANNER_TOP)
	_banner.size = Vector2(BANNER_WIDTH, BANNER_FONT_SIZE * 1.5)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# A text wider than BANNER_WIDTH grows both ways, so it stays in the middle
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.add_theme_font_size_override("font_size", BANNER_FONT_SIZE)
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	add_child(_banner)


## A boss's health bar in the top middle of the screen, with its name over it;
## hidden till a boss comes.
func _build_boss_bar() -> void:
	_boss_bar = ProgressBar.new()
	_boss_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_bar.position = Vector2(-BOSS_BAR_SIZE.x / 2.0, BOSS_TOP)
	_boss_bar.size = BOSS_BAR_SIZE
	_boss_bar.show_percentage = false
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = BOSS_COLOR
	_boss_bar.add_theme_stylebox_override("fill", fill)
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar.visible = false
	add_child(_boss_bar)
	_boss_name = Label.new()
	_boss_name.position = Vector2(0.0, -24.0)
	_boss_name.size = Vector2(BOSS_BAR_SIZE.x, 24.0)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.add_theme_constant_override("outline_size", 4)
	_boss_name.add_theme_color_override("font_outline_color", Color.BLACK)
	_boss_bar.add_child(_boss_name)


## Shows the land's name when the player's column is in another land than
## the last one.
func _check_land() -> void:
	var at: Vector3 = _player.global_position
	var column: Vector2i = Vector2i(floori(at.x), floori(at.z))
	if column == _column:
		return
	_column = column
	var land: int = ChunkGenerator.biome_at(column.x, column.y)
	if land == _land:
		return
	_land = land
	show_banner(LAND_NAMES[land])


## Shows text big in the upper middle of the screen, fading in and out.
func show_banner(text: String) -> void:
	_banner.text = text
	_banner.modulate.a = 0.0
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, BANNER_FADE)
	_banner_tween.tween_interval(BANNER_TIME)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, BANNER_FADE)


## Names a boss that came up, big, and shows its health while it lives, under
## its name and the sword it takes.
func show_boss(boss: Mob) -> void:
	_boss = boss
	var sword: String = BlockDefs.display_name(MobDefs.boss_sword(boss.boss))
	_boss_name.text = BOSS_TEXT % [MobDefs.boss_name(boss.boss), sword]
	_boss_bar.max_value = boss.health
	show_banner(MobDefs.boss_name(boss.boss))


## Shows that the boss of land is beaten and gave a heart.
func show_beaten(land: int) -> void:
	show_banner(BEATEN_TEXT % MobDefs.boss_name(land))


## Shows that the boss of land woke, and that it hunts its land by night.
func show_woken(land: int) -> void:
	show_banner(WOKEN_TEXT % [MobDefs.boss_name(land), LAND_NAMES[land].to_lower()])


## Makes the icon of the first hotbar slot holding item_id jump and ease back.
func _bounce(item_id: int) -> void:
	var slot: int = _player.backpack.ids.find(item_id)
	if slot < 0 or slot >= _slot_icons.size():
		return
	var icon: TextureRect = _slot_icons[slot]
	icon.scale = Vector2.ONE * (1.0 + BOUNCE_GROW)
	icon.create_tween().tween_property(icon, "scale", Vector2.ONE, BOUNCE_TIME)


## Draws each heart whole, half or empty for the two health points it stands
## for, each a little up or down while health is low.
func _draw_hearts() -> void:
	var shake: float = HEART_SHAKE if _health <= Player.LOW_HEALTH else 0.0
	for i in _heart_count():
		var origin: Vector2 = Vector2(i * (HEART_SIZE + HEART_GAP), randf_range(-shake, shake))
		var whole: PackedVector2Array = _heart_points(origin, false)
		var points: int = clampi(_health - i * 2, 0, 2)
		_hearts.draw_colored_polygon(whole, HEART_EMPTY_COLOR)
		if points == 2:
			_hearts.draw_colored_polygon(whole, HEART_COLOR)
		elif points == 1:
			_hearts.draw_colored_polygon(_heart_points(origin, true), HEART_COLOR)
		_hearts.draw_polyline(whole + PackedVector2Array([whole[0]]), Color.BLACK, 1.5, true)


## Hearts in a row over the hotbar, each standing for two health points: enough
## for the most health the player can have.
func _heart_count() -> int:
	var top: int = Player.MAX_HEALTH if _player == null else _player.bosses.max_health()
	return ceili(float(top) / 2.0)


## A heart HEART_SIZE across with its top left at origin, or only its left half,
## along the curve x = 16 sin^3 t, y = 13 cos t - 5 cos 2t - 2 cos 3t - cos 4t.
func _heart_points(origin: Vector2, half: bool) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var k: float = HEART_SIZE / 32.0
	# t = 0 is the notch at the top and t = PI the tip at the bottom
	var start: float = PI if half else 0.0
	var count: int = HEART_STEPS + 1 if half else HEART_STEPS * 2
	for i in count:
		var t: float = start + PI * i / HEART_STEPS
		var x: float = 16.0 * pow(sin(t), 3.0)
		var y: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		points.append(origin + Vector2(16.0 + x, 12.0 - y) * k)
	return points


func _icon(item_id: int) -> Texture2D:
	if not _icons.has(item_id):
		_icons[item_id] = ItemIcon.create(self, item_id)
	return _icons[item_id]


func _make_slot_style(border: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.border_color = border
	style.set_border_width_all(width)
	return style


func _highlight_slot(idx: int) -> void:
	for i in _slot_panels.size():
		var panel: Panel = _slot_panels[i]
		panel.add_theme_stylebox_override("panel", _style_selected if i == idx else _style_normal)


func _set_active_block_internal(block_id: int) -> void:
	pass
