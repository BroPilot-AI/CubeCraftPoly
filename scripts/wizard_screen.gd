class_name WizardScreen
extends CanvasLayer

## The Wizard's shop (Legends): a row for each legendary thing, with what it
## does, its price in Diamonds and Cheese, and a Buy that is on only while the
## player can buy it. One owned says so, and one not yet for sale names the
## boss to beat. Built in setup, like the villager's screen.

const TITLE: String = "Wizard"
const OWNED: String = "Owned"
## Said on a gift's button till its land's boss is beaten
const LOCKED: String = "Beat %s"
const BUY: String = "Buy"
const ICON_PX: int = 32
const MARGIN_PX: int = 12
## How wide what a gift does may be before it wraps
const TEXT_PX: int = 400
## How wide a Buy is, so the buttons line up
const BUY_PX: int = 200

## Gift -> its Buy
var buttons: Dictionary = {}
var _player: Player = null
var _icons: Dictionary = {}


func _ready() -> void:
	# Draw above the HUD
	layer = 2
	visible = false


func setup(player: Player) -> void:
	_player = player
	_player.backpack.changed.connect(_refresh)
	_build()


func open() -> void:
	visible = true
	_refresh()
	Mouse.mode = Input.MOUSE_MODE_VISIBLE
	# The gamepad starts on the first Buy that is on, else the first
	var first: Button = buttons[Legends.SHOP.keys()[0]]
	for id: int in Legends.SHOP:
		if not buttons[id].disabled:
			first = buttons[id]
			break
	first.grab_focus()


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
	var title: Label = Label.new()
	title.text = TITLE
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	for id: int in Legends.SHOP:
		box.add_child(HSeparator.new())
		box.add_child(_row(id))
	add_child(PromptBar.new([PromptBar.SELECT, PromptBar.CLOSE]))


## A gift's name over what it does and its price, with its Buy beside them
func _row(id: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", MARGIN_PX)
	var about: VBoxContainer = VBoxContainer.new()
	about.custom_minimum_size.x = TEXT_PX
	row.add_child(about)
	var title: Label = Label.new()
	title.text = Gifts.INFO[id][0]
	title.add_theme_font_size_override("font_size", 20)
	about.add_child(title)
	var does: Label = Label.new()
	var said: String = Gifts.INFO[id][1]
	does.text = said[0].to_upper() + said.substr(1)
	does.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.add_child(does)
	var price: HBoxContainer = HBoxContainer.new()
	price.add_child(_price(Chunk.DIAMOND, Legends.SHOP[id][1]))
	price.add_child(_price(Chunk.CHEESE, Legends.SHOP[id][2]))
	about.add_child(price)
	var buy: Button = Button.new()
	buy.custom_minimum_size.x = BUY_PX
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy.pressed.connect(_on_buy.bind(id))
	row.add_child(buy)
	buttons[id] = buy
	return row


## An item's picture and how many of it the price is
func _price(item_id: int, count: int) -> HBoxContainer:
	var pair: HBoxContainer = HBoxContainer.new()
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon(item_id)
	pair.add_child(icon)
	var label: Label = Label.new()
	label.text = "%d %s" % [count, BlockDefs.display_name(item_id)]
	pair.add_child(label)
	return pair


func _on_buy(id: int) -> void:
	Legends.buy(_player, id)
	_refresh()


## Sets each Buy: Owned, Beat the boss that puts it up for sale, or Buy, on
## only while the backpack holds the price.
func _refresh() -> void:
	if not visible:
		return
	for id: int in Legends.SHOP:
		var buy: Button = buttons[id]
		if _player.gifts.has(id):
			buy.text = OWNED
		elif not Legends.for_sale(_player.bosses, id):
			buy.text = LOCKED % MobDefs.boss_name(Legends.SHOP[id][0])
		else:
			buy.text = BUY
		buy.disabled = not Legends.can_buy(_player, id)


func _icon(item_id: int) -> Texture2D:
	if not _icons.has(item_id):
		_icons[item_id] = ItemIcon.create(self, item_id)
	return _icons[item_id]
