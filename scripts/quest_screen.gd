class_name QuestScreen
extends CanvasLayer

## What a villager asks for: the quest being done with how much of it the
## backpack holds, the tool or gift it gives, and a Give button that hands the
## items over once there are enough; under it today's request, with a Give of
## its own; beside them the build wanted by home and the bounty, each with a
## Claim, and under all of it the power set with a Change. Built in setup,
## like the backpack screen.

const TITLE: String = "Villager"
const REQUEST_TITLE: String = "Today's request"
const BOUNTY_TITLE: String = "Bounty"
const BUILD_TITLE: String = "Build"
const ICON_PX: int = 48
const MARGIN_PX: int = 12
## How wide each column is; a longer line, like a boss quest's, wraps
const COLUMN_PX: int = 420

var _player: Player = null
var _wants: Label = null
var _wants_icon: TextureRect = null
var _reward: Label = null
var _reward_icon: TextureRect = null
var _give: Button = null
var _ask: Label = null
var _ask_icon: TextureRect = null
var _ask_reward: Label = null
var _ask_reward_icon: TextureRect = null
var _ask_give: Button = null
var _bounty: Label = null
var _bounty_reward: Label = null
var _bounty_reward_icon: TextureRect = null
var _claim: Button = null
## The build wanted by home, how much of it is in place, and its Claim
var _wanted_build: Label = null
var _build_reward: Label = null
var _build_reward_icon: TextureRect = null
var _claim_build: Button = null
## Holds the blocks of the build by home
var _cm: Node3D = null
## The power set, in a box with its Change that is hidden till one is earned
var _power: Label = null
var _power_box: VBoxContainer = null
var _icons: Dictionary = {}


func _ready() -> void:
	# Draw above the HUD
	layer = 2
	visible = false


func setup(player: Player, cm: Node3D = null) -> void:
	_player = player
	_cm = cm
	_player.backpack.changed.connect(_refresh)
	_player.quest_changed.connect(_refresh.unbind(1))
	_player.request_changed.connect(_refresh)
	_player.bounty_changed.connect(_refresh)
	_build()


func open() -> void:
	visible = true
	_refresh()
	Mouse.mode = Input.MOUSE_MODE_VISIBLE
	# The gamepad starts on the quest's Give, when it has something to give,
	# or else the request's
	if _give.visible:
		_give.grab_focus()
	else:
		_ask_give.grab_focus()


func close() -> void:
	visible = false
	Mouse.mode = Input.MOUSE_MODE_CAPTURED


func _build() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.4)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	center.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN_PX)
	panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	# Two columns, so the screen fits in a 720 high window
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", MARGIN_PX)
	box.add_child(columns)
	var left: VBoxContainer = _column(columns)
	var title: Label = Label.new()
	title.text = TITLE
	title.add_theme_font_size_override("font_size", 24)
	left.add_child(title)
	_wants_icon = _make_icon()
	_wants = Label.new()
	left.add_child(_row(_wants_icon, _wants))
	_reward_icon = _make_icon()
	_reward = Label.new()
	left.add_child(_row(_reward_icon, _reward))
	_give = Button.new()
	_give.text = "Give"
	_give.pressed.connect(_player.hand_in)
	left.add_child(_give)
	_build_request(left)
	# The D-pad goes down the column, not over to a Claim that is nearer
	_give.focus_neighbor_bottom = _give.get_path_to(_ask_give)
	_ask_give.focus_neighbor_top = _ask_give.get_path_to(_give)
	columns.add_child(VSeparator.new())
	var right: VBoxContainer = _column(columns)
	_build_builds(right)
	_build_bounty(right)
	_build_power(box)
	add_child(PromptBar.new([PromptBar.SELECT, PromptBar.CLOSE]))


## A column COLUMN_PX wide, its rows 8 apart
func _column(columns: HBoxContainer) -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size.x = COLUMN_PX
	column.add_theme_constant_override("separation", 8)
	columns.add_child(column)
	return column


## Today's request under the quest, with a Give of its own
func _build_request(box: VBoxContainer) -> void:
	box.add_child(HSeparator.new())
	var title: Label = Label.new()
	title.text = REQUEST_TITLE
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	_ask_icon = _make_icon()
	_ask = Label.new()
	box.add_child(_row(_ask_icon, _ask))
	_ask_reward_icon = _make_icon()
	_ask_reward = Label.new()
	box.add_child(_row(_ask_reward_icon, _ask_reward))
	_ask_give = Button.new()
	_ask_give.text = "Give"
	_ask_give.pressed.connect(_player.hand_in_request)
	box.add_child(_ask_give)


## The build wanted by home, at the top of its column, with what it pays and a
## Claim of its own, enabled only once every block of it is in place
func _build_builds(box: VBoxContainer) -> void:
	var title: Label = Label.new()
	title.text = BUILD_TITLE
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	_wanted_build = Label.new()
	_wrap(_wanted_build)
	box.add_child(_wanted_build)
	_build_reward_icon = _make_icon()
	_build_reward = Label.new()
	box.add_child(_row(_build_reward_icon, _build_reward))
	_claim_build = Button.new()
	_claim_build.text = "Claim"
	_claim_build.pressed.connect(_on_claim_build)
	box.add_child(_claim_build)


## The monster bounty under the build, with what it pays and a Claim of its
## own, enabled only once enough of the creature are killed
func _build_bounty(box: VBoxContainer) -> void:
	box.add_child(HSeparator.new())
	var title: Label = Label.new()
	title.text = "Bounty"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	_bounty = Label.new()
	_wrap(_bounty)
	box.add_child(_bounty)
	_bounty_reward_icon = _make_icon()
	_bounty_reward = Label.new()
	box.add_child(_row(_bounty_reward_icon, _bounty_reward))
	_claim = Button.new()
	_claim.text = "Claim"
	_claim.pressed.connect(_player.claim_bounty)
	box.add_child(_claim)


## The power set under both columns, with a Change that sets the next earned
func _build_power(box: VBoxContainer) -> void:
	_power_box = VBoxContainer.new()
	_power_box.add_child(HSeparator.new())
	_power = Label.new()
	_power_box.add_child(_power)
	var change: Button = Button.new()
	change.text = "Change"
	change.pressed.connect(_on_change_power)
	_power_box.add_child(change)
	box.add_child(_power_box)


## Pays for the build the villagers asked for, once every block is in place;
## what does not fit in the backpack drops at the player.
func _on_claim_build() -> void:
	if not _player.builds.can_claim(_cm, _player.quest):
		return
	var build: Array = _player.builds.claim()
	var left: int = _player.take(build[2], build[3], _player.global_position)
	if left > 0:
		_player.items_dropped.emit(build[2], left, _player.global_position)
	_player.request_changed.emit()


func _on_change_power() -> void:
	_player.powers.choose_next(_player.bosses.beaten)
	_refresh()


func _make_icon() -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


## The label wraps to fit the width of its column
func _row(icon: TextureRect, label: Label) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_child(icon)
	_wrap(label)
	row.add_child(label)
	return row


## A long line, like a boss quest's, goes on to the next line rather than
## widen its column
func _wrap(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL


## Shows the quest being done, or that every one is, with Give enabled only
## when the backpack holds enough, and today's request. A shelter or a boss
## has nothing to give, and a gift no icon.
func _refresh() -> void:
	if not visible:
		return
	var index: int = _player.quest
	var done: bool = Quests.all_done(index)
	var nothing: bool = Quests.wants_shelter(index) or Quests.wants_boss(index)
	_wants.text = Quests.describe(_player.backpack, index)
	_wants_icon.texture = null if done or nothing else _icon(Quests.LIST[index][0])
	_reward.text = "" if done else "Reward: %s and %d Cheese" % [Quests.reward(index), Quests.REWARD_CHEESE]
	_reward_icon.texture = null if done or Gifts.is_gift(Quests.LIST[index][2]) else _icon(Quests.LIST[index][2])
	_give.visible = not done and not nothing
	_give.disabled = not Quests.can_hand_in(_player.backpack, index)
	_refresh_request()
	_refresh_build()
	_refresh_bounty()
	_refresh_power()


## Shows today's request, or that the next comes tomorrow once it is handed in,
## with its Give off then so the gamepad stays on it.
func _refresh_request() -> void:
	var request: Array = _player.requests.today(_player.quest)
	var waiting: bool = _player.requests.waiting
	_ask.text = Requests.WAITING if waiting else Requests.describe(_player.backpack, request)
	_ask_icon.texture = null if waiting else _icon(request[0])
	_ask_reward.text = "" if waiting else "Reward: %d %s" % [request[3], BlockDefs.display_name(request[2])]
	_ask_reward_icon.texture = null if waiting else _icon(request[2])
	_ask_give.disabled = waiting or not Requests.can_hand_in(_player.backpack, request)


## Shows the build wanted and how much of it is in place, with Claim off until
## all of it is
func _refresh_build() -> void:
	var build: Array = _player.builds.current(_player.quest)
	_wanted_build.text = Builds.describe(build, _player.builds.placed(_cm, build))
	_build_reward.text = "" if build.is_empty() else "Reward: %d %s" % [build[3], BlockDefs.display_name(build[2])]
	_build_reward_icon.texture = null if build.is_empty() else _icon(build[2])
	_claim_build.disabled = not _player.builds.can_claim(_cm, _player.quest)


## Shows the bounty, with Claim off until enough of the creature are killed
func _refresh_bounty() -> void:
	var bounty: Array = _player.bounties.current(_player.quest)
	if bounty.is_empty():
		_bounty.text = Bounties.NONE
		_bounty_reward.text = ""
		_bounty_reward_icon.texture = null
		_claim.disabled = true
		return
	_bounty.text = Bounties.describe(bounty, _player.bounties.kills)
	_bounty_reward.text = "Reward: %d %s" % [bounty[3], BlockDefs.display_name(bounty[2])]
	_bounty_reward_icon.texture = _icon(bounty[2])
	_claim.disabled = not _player.bounties.can_claim(_player.quest)


## Shows the power set, once a boss beaten has earned one
func _refresh_power() -> void:
	_power_box.visible = not Powers.earned(_player.bosses.beaten).is_empty()
	_power.text = "Power: %s" % Powers.NAMES.get(_player.powers.chosen, "none")


func _icon(item_id: int) -> Texture2D:
	if not _icons.has(item_id):
		_icons[item_id] = ItemIcon.create(self, item_id)
	return _icons[item_id]
