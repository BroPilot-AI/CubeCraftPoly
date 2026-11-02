class_name TitleScreen
extends Control

## The first screen: Continue the saved world, start a New World with a new
## seed, change the Settings or Quit. The splash shows over it at start.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const SettingsMenuScene: PackedScene = preload("res://scenes/settings_menu.tscn")
## New seeds go up to this, which keeps the seed plus the noise and decor
## offsets within 32 bits
const MAX_SEED: int = 1000000000
const TITLE_SIZE: int = 64
const BUTTON_WIDTH: int = 240

## The title and the buttons, hidden while the settings show
var menu: CenterContainer = null
var continue_button: Button = null
var new_button: Button = null
var settings_button: Button = null
var quit_button: Button = null
## Asks before a New World replaces the saved one
var confirm_box: VBoxContainer = null
var yes_button: Button = null
var no_button: Button = null
var settings: SettingsMenu = null
var splash: SplashScreen = null
## The button prompts in the bottom right corner, hidden with the menu
var prompts: PromptBar = null


func _ready() -> void:
	Mouse.mode = Input.MOUSE_MODE_VISIBLE
	_build()
	settings = SettingsMenuScene.instantiate()
	add_child(settings)
	settings.closed.connect(_on_settings_closed)
	# The splash goes last, over everything, and sees keys first
	splash = SplashScreen.new()
	splash.name = "Splash"
	add_child(splash)
	# The gamepad starts on the first button that works
	var first: Button = new_button if continue_button.disabled else continue_button
	first.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	var back: bool = event.is_action_pressed("toggle_pause") or event.is_action_pressed("ui_cancel")
	if back and settings.visible:
		get_viewport().set_input_as_handled()
		settings.close()


func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = SplashScreen.BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	menu = CenterContainer.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	menu.add_child(box)
	_label(box, SplashScreen.TITLE).add_theme_font_size_override("font_size", TITLE_SIZE)
	var panel: PanelContainer = PanelContainer.new()
	box.add_child(panel)
	var buttons: VBoxContainer = VBoxContainer.new()
	buttons.custom_minimum_size.x = BUTTON_WIDTH
	buttons.add_theme_constant_override("separation", 12)
	panel.add_child(buttons)
	continue_button = _button(buttons, "Continue", _play)
	continue_button.disabled = not WorldSave.has_world()
	new_button = _button(buttons, "New World", _on_new_world)
	_build_confirm(buttons)
	settings_button = _button(buttons, "Settings", _open_settings)
	quit_button = _button(buttons, "Quit", _on_quit)
	prompts = PromptBar.new([PromptBar.SELECT])
	add_child(prompts)


func _build_confirm(parent: Container) -> void:
	confirm_box = VBoxContainer.new()
	confirm_box.visible = false
	parent.add_child(confirm_box)
	_label(confirm_box, "Replace your saved world?")
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	confirm_box.add_child(row)
	yes_button = _button(row, "Yes", start_new_world)
	no_button = _button(row, "No", _on_no)


func _label(parent: Container, text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _button(parent: Container, text: String, on_press: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(on_press)
	parent.add_child(button)
	return button


## A New World asks first when it would replace a saved one.
func _on_new_world() -> void:
	if WorldSave.has_world():
		confirm_box.show()
		no_button.grab_focus()
	else:
		start_new_world()


func _on_no() -> void:
	confirm_box.hide()
	new_button.grab_focus()


## Deletes the saved world, saves a new seed and starts the game. It stays on
## the title if the old world can't be deleted, so the two never mix.
func start_new_world() -> void:
	var err: int = WorldSave.delete_world()
	if err != OK:
		push_warning("TitleScreen: deleting the saved world failed err=%d" % err)
		return
	err = WorldSave.save_seed(randi_range(1, MAX_SEED))
	if err != OK:
		push_warning("TitleScreen: saving the seed failed err=%d" % err)
	_play()


func _play() -> void:
	var err: int = get_tree().change_scene_to_file(MAIN_SCENE)
	if err != OK:
		push_warning("TitleScreen: loading the game failed err=%d" % err)


func _open_settings() -> void:
	menu.hide()
	prompts.hide()
	settings.open()


## The settings capture the mouse as they close, for the game; the title needs it.
func _on_settings_closed() -> void:
	Mouse.mode = Input.MOUSE_MODE_VISIBLE
	menu.show()
	prompts.show()
	settings_button.grab_focus()


func _on_quit() -> void:
	get_tree().quit()
