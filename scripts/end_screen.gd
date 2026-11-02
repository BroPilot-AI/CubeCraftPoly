class_name EndScreen
extends CanvasLayer

## Shown when the last quest is done: the lands are safe and the game is won.
## The world stops behind it. Keep Playing goes back to the world, and Back to
## Title saves and leaves.

signal title_requested

const TITLE: String = "The lands are safe!"
const TEXT: String = "You beat the Zombie King, the Demon Lord, the Frost Giant and the Skeleton King.\nThe world is yours to keep building in. Thanks for playing!"
const CREDITS: String = "Models: Cube World Kit by Quaternius. UI: Kenney. Font: Fredoka."
const MARGIN_PX: int = 16

var keep_button: Button = null
var title_button: Button = null


func _ready() -> void:
	# Draw above the HUD
	layer = 2
	visible = false
	_build()


func open() -> void:
	visible = true
	Mouse.mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	# The gamepad starts on Keep Playing
	keep_button.grab_focus()


func close() -> void:
	visible = false
	Mouse.mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false


func _build() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
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
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	box.add_child(_label(TITLE, 32))
	box.add_child(_label(TEXT, 18))
	var credits: Label = _label(CREDITS, 14)
	credits.modulate = Color(1, 1, 1, 0.7)
	box.add_child(credits)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	keep_button = _button("Keep Playing")
	keep_button.pressed.connect(close)
	row.add_child(keep_button)
	title_button = _button("Back to Title")
	title_button.pressed.connect(title_requested.emit)
	row.add_child(title_button)
	add_child(PromptBar.new([PromptBar.SELECT, PromptBar.CLOSE]))


func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	return button
