class_name ChestScreen
extends CanvasLayer

## A survival chest's slots over the backpack's. Choose a slot and then another
## to move what is in it, in or out of the chest or within either. Opened by
## using a chest (Props.chest_opened); closing it shuts the chest's lid. The
## screen is built in setup, so that the first open does not stall the game.

const CHEST_TITLE: String = "Chest"
const BACKPACK_TITLE: String = "Backpack (top row is the hotbar)"
const HINT: String = "Choose a slot, then another, to move it"

## The cell of the chest open now
var cell: Vector3i = Vector3i.ZERO
var _props: Props = null
var _chunks: Node3D = null
var _backpack: Backpack = null
var _chest: Backpack = null
## The chest's slots, then the backpack's
var _slots: Array[Button] = []
var _counts: Array[Label] = []
## The slot the next click moves from, or -1
var _picked: int = -1
var _icons: Dictionary = {}


func _ready() -> void:
	# Draw above the HUD
	layer = 2
	visible = false


## Opens when props says a chest was used; backpack is the player's.
func setup(props: Props, backpack: Backpack, chunks: Node3D) -> void:
	_props = props
	_backpack = backpack
	_chunks = chunks
	_backpack.changed.connect(_refresh)
	_props.chest_opened.connect(open)
	_build()


## Shows the slots of the chest at at.
func open(at: Vector3i) -> void:
	cell = at
	_chest = _props.chest_at(at)
	_picked = -1
	visible = true
	_refresh()
	Mouse.mode = Input.MOUSE_MODE_VISIBLE
	# The gamepad starts on the chest's first slot
	_slots[0].grab_focus()


## Hides the slots and shuts the chest.
func close() -> void:
	visible = false
	Mouse.mode = Input.MOUSE_MODE_CAPTURED
	_props.shut_chest(_chunks, cell)


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
		margin.add_theme_constant_override("margin_" + side, BackpackScreen.MARGIN_PX)
	panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	margin.add_child(box)
	box.add_child(_label(HINT))
	box.add_child(_label(CHEST_TITLE))
	box.add_child(_grid(0))
	box.add_child(_label(BACKPACK_TITLE))
	box.add_child(_grid(Backpack.SIZE))
	add_child(PromptBar.new([PromptBar.SELECT, PromptBar.CLOSE]))


func _label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	return label


## A grid of one bag's slots, numbered from first.
func _grid(first: int) -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = BackpackScreen.COLUMNS
	for i in Backpack.SIZE:
		grid.add_child(_make_slot(first + i))
	return grid


func _make_slot(slot: int) -> Button:
	var b: Button = Button.new()
	b.custom_minimum_size = Vector2(BackpackScreen.SLOT_PX, BackpackScreen.SLOT_PX)
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


## The first click picks a slot up, the next moves it to the slot clicked.
## Clicking the picked slot again puts it back.
func _on_slot_pressed(slot: int) -> void:
	if _picked == -1:
		if _bag(slot).ids[slot % Backpack.SIZE] != 0:
			_picked = slot
	else:
		var from: int = _picked
		_picked = -1
		_bag(from).move_to(from % Backpack.SIZE, _bag(slot), slot % Backpack.SIZE)
	_refresh()


## The chest for a slot under Backpack.SIZE, else the backpack.
func _bag(slot: int) -> Backpack:
	return _chest if slot < Backpack.SIZE else _backpack


func _refresh() -> void:
	if not visible:
		return
	for i in _slots.size():
		var bag: Backpack = _bag(i)
		var id: int = bag.ids[i % Backpack.SIZE]
		var count: int = bag.counts[i % Backpack.SIZE]
		_slots[i].icon = _icon(id) if id != 0 else null
		_slots[i].tooltip_text = BlockDefs.display_name(id) if id != 0 else ""
		_slots[i].modulate = BackpackScreen.PICKED if i == _picked else Color.WHITE
		_counts[i].text = str(count) if count > 1 else ""


func _icon(item_id: int) -> Texture2D:
	if not _icons.has(item_id):
		_icons[item_id] = ItemIcon.create(self, item_id)
	return _icons[item_id]
