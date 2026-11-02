class_name SplashScreen
extends CanvasLayer

## The game's name and "Made with Godot Engine" over the first moments of the
## game, while the world loads behind it. It fades out after SHOW_TIME seconds,
## or at once on a key or mouse press, which it keeps from the game, then frees
## itself.

const SHOW_TIME: float = 2.0
const FADE_TIME: float = 0.5
const TITLE: String = "CubeCraftPoly"
const GODOT_ICON: String = "res://assets/ui/godot_icon.svg"
## The Godot logo's licence asks for this credit
const LOGO_CREDIT: String = "Godot Engine logo © 2017 Andrea Calabró, CC BY 4.0"
const BACKGROUND: Color = Color(0.1, 0.12, 0.16)

var _root: ColorRect = null
var _fading: bool = false


func _ready() -> void:
	layer = 100
	_root = ColorRect.new()
	_root.color = BACKGROUND
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	box.add_child(_label(TITLE, 64))
	var icon: TextureRect = TextureRect.new()
	icon.texture = load(GODOT_ICON)
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)
	box.add_child(_label("Made with Godot Engine", 24))
	var credit: Label = _label(LOGO_CREDIT, 14)
	credit.modulate.a = 0.6
	box.add_child(credit)
	get_tree().create_timer(SHOW_TIME).timeout.connect(fade_out)


func _input(event: InputEvent) -> void:
	if _fading:
		return
	var button: bool = event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton
	if button and event.is_pressed():
		get_viewport().set_input_as_handled()
		fade_out()


## Fades the splash out over FADE_TIME and frees it; a second call does nothing
func fade_out() -> void:
	if _fading:
		return
	_fading = true
	var tween: Tween = create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)


func _label(text: String, size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	return label
