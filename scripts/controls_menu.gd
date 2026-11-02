class_name ControlsMenu
extends CanvasLayer

## The settings' controls list: each action with the pictures of its key and its
## gamepad button. Pressing one waits for the key or the button to put in its
## place, and Escape or Start keeps the old one. Reset puts them all back.

signal closed

const MARGIN_PX: int = 16
## How wide a key, a button or a fixed control is
const CELL_PX: int = 150
## How big the pictures of the keys and the buttons are
const ICON_PX: int = 24
const WAIT_KEY: String = "Press a key"
const WAIT_BUTTON: String = "Press a button"
## The controls that cannot be changed: [name, action]
const FIXED: Array = [
	["Break / hit", "break_block"],
	["Place / use", "place_block"],
]
## F11 turns fullscreen on and off, with no gamepad button
const FULLSCREEN: Array = ["Fullscreen", "keyboard_f11", "-"]
## The walk actions are the left stick on the gamepad, and the hotbar ones the
## mouse wheel on the keys: action: its picture
const STICK: Dictionary = {
	"move_forward": "xbox_stick_l_up",
	"move_back": "xbox_stick_l_down",
	"move_left": "xbox_stick_l_left",
	"move_right": "xbox_stick_l_right",
}
const WHEEL: Dictionary = {
	"slot_prev": "mouse_scroll_up",
	"slot_next": "mouse_scroll_down",
}
## A button's picture takes the colour of its text: icon colour: text colour
const ICON_COLORS: Dictionary = {
	"icon_normal_color": "font_color",
	"icon_focus_color": "font_focus_color",
	"icon_hover_color": "font_hover_color",
	"icon_pressed_color": "font_pressed_color",
	"icon_hover_pressed_color": "font_hover_pressed_color",
	"icon_disabled_color": "font_disabled_color",
}
## The prompts at the foot, and while it waits for a key or a button
const PROMPTS: Array = [[PromptBar.CLICK, "ui_accept", "Change"], PromptBar.BACK]
const WAIT_PROMPTS: Array = [["toggle_pause", "toggle_pause", "Cancel"]]

var reset_button: Button = null
var back_button: Button = null
## Action: the button that shows its key
var key_buttons: Dictionary = {}
## Action: the button that shows its gamepad button
var pad_buttons: Dictionary = {}
var prompts: PromptBar = null
## The gamepad side's fixed pictures: each one: what gives its picture, so a
## PlayStation pad's show when it is the one in use
var _pad_pictures: Dictionary = {}
## The action waiting for a key or a button, or "" when none is
var _waiting: String = ""
## True while it waits for a key, false while it waits for a gamepad button
var _for_key: bool = false


func _ready() -> void:
	# Draw above the settings
	layer = 2
	visible = false
	_build()


func open() -> void:
	visible = true
	_refresh()
	# The gamepad starts on the first key
	key_buttons.values()[0].grab_focus()


func close() -> void:
	visible = false
	_waiting = ""
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _waiting != "":
		_capture(event)
	elif event.is_action_pressed("toggle_pause") or event.is_action_pressed("ui_cancel"):
		# Escape and B go back to the settings, not out of them
		get_viewport().set_input_as_handled()
		close()


## While it waits every event stops here. A key or a gamepad button pressed
## ends the wait and takes the action's place, unless it is Escape or Start.
func _capture(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey and _for_key and event.physical_keycode not in [KEY_NONE, KEY_ESCAPE]:
		Controls.bind_key(_waiting, event.physical_keycode)
	elif event is InputEventJoypadButton and not _for_key and event.button_index != JOY_BUTTON_START:
		Controls.bind_button(_waiting, event.button_index)
	elif not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton):
		return
	_waiting = ""
	_refresh()


func _start_wait(action: String, for_key: bool) -> void:
	_waiting = action
	_for_key = for_key
	_refresh()


func _refresh() -> void:
	for action: String in key_buttons:
		var key: InputEventKey = InputEventKey.new()
		key.physical_keycode = Controls.key_of(action)
		_show(key_buttons[action], key, WAIT_KEY if _waiting == action and _for_key else "")
	for action: String in pad_buttons:
		var button: InputEventJoypadButton = InputEventJoypadButton.new()
		button.button_index = Controls.button_of(action)
		_show(pad_buttons[action], button, WAIT_BUTTON if _waiting == action and not _for_key else "")
	for rect: TextureRect in _pad_pictures:
		rect.texture = _pad_pictures[rect].call()
	prompts.prompts = WAIT_PROMPTS if _waiting != "" else PROMPTS


## Shows event's picture on button, or its name when it has none, or wait in
## place of both while it waits. A wide picture, like Space's, is as tall as
## the rest.
func _show(button: Button, event: InputEvent, wait: String) -> void:
	button.icon = InputIcons.trimmed(InputIcons.texture(event)) if wait == "" else null
	if wait != "":
		button.text = wait
	elif button.icon == null:
		button.text = InputIcons.name_of(event)
	else:
		button.text = ""
		var wide: float = float(button.icon.get_width()) / button.icon.get_height()
		button.add_theme_constant_override("icon_max_width", roundi(ICON_PX * wide))


func _on_reset() -> void:
	Controls.reset()
	_refresh()


func _build() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	# The pictures are 64 pixels, shrunk to ICON_PX
	center.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	center.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN_PX)
	panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	# Tight rows, so the list fits in a 720 high window
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title: Label = _label("Controls")
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	box.add_child(_grid())
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	reset_button = _button(row, "Reset", _on_reset)
	back_button = _button(row, "Back", close)
	# Left and right go between the two, not up to the list close above them
	reset_button.focus_neighbor_right = reset_button.get_path_to(back_button)
	back_button.focus_neighbor_left = back_button.get_path_to(reset_button)
	prompts = PromptBar.new(PROMPTS)
	add_child(prompts)


## Each action's name, key and gamepad button, under a heading row.
func _grid() -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 2)
	for text: String in ["", "Keyboard", "Gamepad"]:
		grid.add_child(_label(text))
	for row: Array in FIXED:
		grid.add_child(_label(row[0], HORIZONTAL_ALIGNMENT_LEFT))
		grid.add_child(_picture(_trimmed_of(row[1], false)))
		grid.add_child(_pad_picture(_trimmed_of.bind(row[1], true)))
	grid.add_child(_label(FULLSCREEN[0], HORIZONTAL_ALIGNMENT_LEFT))
	grid.add_child(_picture(InputIcons.trimmed(InputIcons.named(FULLSCREEN[1]))))
	grid.add_child(_label(FULLSCREEN[2]))
	for action: String in Controls.NAMES:
		grid.add_child(_label(Controls.NAMES[action], HORIZONTAL_ALIGNMENT_LEFT))
		if Controls.key_of(action) != KEY_NONE:
			key_buttons[action] = _picture_button(grid, _start_wait.bind(action, true))
		else:
			grid.add_child(_picture(InputIcons.named(WHEEL[action])))
		if Controls.BUTTONS.has(action):
			pad_buttons[action] = _picture_button(grid, _start_wait.bind(action, false))
		else:
			grid.add_child(_pad_picture(InputIcons.named.bind(STICK[action])))
	return grid


func _label(text: String, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = align
	return label


## A control that cannot be changed: its picture, in the middle of its cell.
func _picture(picture: Texture2D) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.texture = picture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(CELL_PX, ICON_PX)
	return rect


## A gamepad picture that cannot be changed, from source, which _refresh calls
## again.
func _pad_picture(source: Callable) -> TextureRect:
	var rect: TextureRect = _picture(source.call())
	_pad_pictures[rect] = source
	return rect


## The picture of what does action, as InputIcons.texture_of, without its clear
## border.
func _trimmed_of(action: String, on_pad: bool) -> Texture2D:
	return InputIcons.trimmed(InputIcons.texture_of(action, on_pad))


func _button(parent: Control, text: String, on_press: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(CELL_PX, 0)
	button.pressed.connect(on_press)
	parent.add_child(button)
	return button


## A button showing the picture of a key or a gamepad button, drawn in the
## colour of a button's text, so it shows on the light button and on the blue.
func _picture_button(parent: Control, on_press: Callable) -> Button:
	var button: Button = _button(parent, "", on_press)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", ICON_PX)
	for icon_color: String in ICON_COLORS:
		button.add_theme_color_override(icon_color, button.get_theme_color(ICON_COLORS[icon_color]))
	return button
