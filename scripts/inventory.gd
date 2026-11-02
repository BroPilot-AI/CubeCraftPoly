class_name Inventory
extends CanvasLayer

## The creative inventory: a grid with a button for every item. Choosing one
## puts it in the current hotbar slot. The grid is built the first time it opens.

signal item_chosen(item_id: int)

const COLUMNS: int = 9
const SLOT_PX: int = 48
const HINT: String = "Choose an item to put it in the selected hotbar slot"

var _grid: GridContainer = null


func _ready() -> void:
	# Draw above the HUD
	layer = 2
	visible = false


func open() -> void:
	if _grid == null:
		_build()
	visible = true
	Mouse.mode = Input.MOUSE_MODE_VISIBLE
	# The gamepad starts on the first item
	_grid.get_child(0).grab_focus()


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
	var box: VBoxContainer = VBoxContainer.new()
	panel.add_child(box)
	var hint: Label = Label.new()
	hint.text = HINT
	box.add_child(hint)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	box.add_child(_grid)
	var ids: Array = BlockDefs.ITEMS.keys()
	ids.sort()
	for id: int in ids:
		# An open chest or a pulled lever is not an item of its own, and an Old
		# Chest is found, not made
		if not BlockDefs.VARIANTS.has(id) and id != BlockDefs.OLD_CHEST:
			_grid.add_child(_make_button(id))
	add_child(PromptBar.new([PromptBar.SELECT, PromptBar.CLOSE]))


func _make_button(item_id: int) -> Button:
	var b: Button = Button.new()
	b.custom_minimum_size = Vector2(SLOT_PX, SLOT_PX)
	b.icon = ItemIcon.create(self, item_id)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.tooltip_text = BlockDefs.ITEMS[item_id][0]
	b.pressed.connect(func() -> void: item_chosen.emit(item_id))
	return b
