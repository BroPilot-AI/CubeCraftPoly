class_name BackpackScreen
extends CanvasLayer

## The survival backpack: every slot, the hotbar as the top row, and the
## recipes beside them. Choose a slot and then another to move what is in it.
## Choose a recipe to make it; opened by a furnace, the screen lists what the
## furnace makes too. The screen is built in setup, so that the first open
## does not stall the game.

const COLUMNS: int = 9
const SLOT_PX: int = 48
const RECIPES_PX: Vector2 = Vector2(320, 240)
const RECIPE_ICON_PX: int = 32
const MARGIN_PX: int = 12
const SLOTS_HINT: String = "Top row is the hotbar. Choose a slot, then another, to move it"
const RECIPES_HINT: String = "Choose a recipe to make it"
## Over the recipes made only by a furnace
const FURNACE_TITLE: String = "-- Furnace --"
## Tint of the slot picked up to be moved
const PICKED: Color = Color(1.0, 0.85, 0.3)

var _backpack: Backpack = null
var _slots: Array[Button] = []
var _counts: Array[Label] = []
var _recipe_buttons: Array[Button] = []
var _recipes: Array = Recipes.all()
var _furnace_title: Label = null
## True while the screen is open by a furnace
var _at_furnace: bool = false
## The slot the next click moves from, or -1
var _picked: int = -1
var _icons: Dictionary = {}


func _ready() -> void:
	# Draw above the HUD
	layer = 2
	visible = false


func setup(backpack: Backpack) -> void:
	_backpack = backpack
	_backpack.changed.connect(_refresh)
	_build()


## Opens the screen; at_furnace lists what a furnace makes too.
func open(at_furnace: bool = false) -> void:
	_picked = -1
	_at_furnace = at_furnace
	visible = true
	_refresh()
	Mouse.mode = Input.MOUSE_MODE_VISIBLE
	# The gamepad starts on the first slot
	_slots[0].grab_focus()


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
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)
	var left: VBoxContainer = VBoxContainer.new()
	row.add_child(left)
	var slots_hint: Label = Label.new()
	slots_hint.text = SLOTS_HINT
	left.add_child(slots_hint)
	var grid: GridContainer = GridContainer.new()
	grid.columns = COLUMNS
	left.add_child(grid)
	for i in Backpack.SIZE:
		grid.add_child(_make_slot(i))
	row.add_child(_build_recipes())
	add_child(PromptBar.new([PromptBar.SELECT, PromptBar.CLOSE]))


func _build_recipes() -> VBoxContainer:
	var right: VBoxContainer = VBoxContainer.new()
	var hint: Label = Label.new()
	hint.text = RECIPES_HINT
	right.add_child(hint)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = RECIPES_PX
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for i in _recipes.size():
		if i == Recipes.LIST.size():
			_furnace_title = Label.new()
			_furnace_title.text = FURNACE_TITLE
			list.add_child(_furnace_title)
		list.add_child(_make_recipe(i))
	return right


func _make_slot(slot: int) -> Button:
	var b: Button = Button.new()
	b.custom_minimum_size = Vector2(SLOT_PX, SLOT_PX)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(_on_slot_pressed.bind(slot))
	var count: Label = Label.new()
	count.position = Vector2(4, 24)
	count.size = Vector2(40, 22)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	count.add_theme_constant_override("outline_size", 4)
	b.add_child(count)
	_slots.append(b)
	_counts.append(count)
	return b


func _make_recipe(index: int) -> Button:
	var recipe: Array = _recipes[index]
	var b: Button = Button.new()
	b.text = Recipes.describe(recipe)
	b.icon = _icon(recipe[0])
	b.add_theme_constant_override("icon_max_width", RECIPE_ICON_PX)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(_on_recipe_pressed.bind(index))
	_recipe_buttons.append(b)
	return b


## The first click picks a slot up, the next moves it to the slot clicked.
## Clicking the picked slot again puts it back.
func _on_slot_pressed(slot: int) -> void:
	if _picked == -1:
		if _backpack.ids[slot] != 0:
			_picked = slot
	else:
		var from: int = _picked
		_picked = -1
		_backpack.move(from, slot)
	_refresh()


func _on_recipe_pressed(index: int) -> void:
	Recipes.make(_backpack, _recipes[index])


func _refresh() -> void:
	if not visible:
		return
	# Making something can empty the picked slot
	if _picked != -1 and _backpack.ids[_picked] == 0:
		_picked = -1
	for i in Backpack.SIZE:
		var id: int = _backpack.ids[i]
		var count: int = _backpack.counts[i]
		_slots[i].icon = _icon(id) if id != 0 else null
		_slots[i].tooltip_text = BlockDefs.display_name(id) if id != 0 else ""
		_slots[i].modulate = PICKED if i == _picked else Color.WHITE
		_counts[i].text = str(count) if count > 1 else ""
	_furnace_title.visible = _at_furnace
	for i in _recipes.size():
		_recipe_buttons[i].visible = _at_furnace or i < Recipes.LIST.size()
		_recipe_buttons[i].disabled = not Recipes.can_make(_backpack, _recipes[i])


func _icon(item_id: int) -> Texture2D:
	if not _icons.has(item_id):
		_icons[item_id] = ItemIcon.create(self, item_id)
	return _icons[item_id]
