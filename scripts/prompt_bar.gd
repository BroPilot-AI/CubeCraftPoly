class_name PromptBar
extends RichTextLabel

## The button prompts in a menu's bottom right corner, such as "(A) Select
## (B) Back". Each prompt is [the action on the keys, the action on the
## gamepad, what it does]; the pictures follow the one the player is using
## (InputIcons.pad) and the keys and buttons of the controls list.

## The keys side of a prompt done by a left click
const CLICK: String = "click"
const SELECT: Array = [CLICK, "ui_accept", "Select"]
const BACK: Array = ["toggle_pause", "ui_cancel", "Back"]
const CLOSE: Array = ["toggle_pause", "ui_cancel", "Close"]
## Pixels in from the screen's bottom right corner
const MARGIN: float = 16.0
const GAP: String = "     "

## What it says: a list of prompts, such as [SELECT, BACK]
var prompts: Array = []


func _init(say: Array = []) -> void:
	prompts = say
	InputIcons.style(self)
	# The menus pause the game, and it still follows the player's hands
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = -MARGIN
	offset_right = -MARGIN
	offset_top = -MARGIN
	offset_bottom = -MARGIN


func _ready() -> void:
	_refresh()


func _input(event: InputEvent) -> void:
	InputIcons.note(event)


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_refresh()


## Only a change sets the text, as the line reads its pictures again each time.
func _refresh() -> void:
	var parts: PackedStringArray = []
	for prompt: Array in prompts:
		parts.append("%s %s" % [_picture(prompt[1] if InputIcons.pad else prompt[0]), prompt[2]])
	var said: String = GAP.join(parts)
	if said != text:
		text = said


static func _picture(action: String) -> String:
	if action != CLICK:
		return InputIcons.of(action, InputIcons.pad)
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	return InputIcons.picture(click)
