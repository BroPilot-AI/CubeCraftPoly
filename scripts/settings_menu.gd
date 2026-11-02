class_name SettingsMenu
extends CanvasLayer

const SETTINGS_PATH: String = "user://settings.cfg"
const DEFAULT_FOV: float = 75.0
const DEFAULT_SENS: float = 0.002
const DEFAULT_VIEW_RADIUS: int = 4
const MIN_FOV: float = 60.0
const MAX_FOV: float = 110.0
const MIN_SENS: float = 0.0005
const MAX_SENS: float = 0.005
const DEFAULT_VOLUME: float = 1.0
## The music's own volume, under the master one
const DEFAULT_MUSIC: float = 0.7
const MASTER_BUS: StringName = &"Master"

signal fov_changed(fov: float)
signal sensitivity_changed(sens: float)
signal view_radius_changed(radius: int)
signal skin_changed(skin: String)
signal survival_changed(on: bool)
signal closed
## Quit to Title, a button only the game's pause menu shows
signal title_requested

## The controls list, shown in place of the settings
var controls_menu: ControlsMenu = null
## The button prompts in the bottom right corner
var prompts: PromptBar = null

@onready var panel: Panel = $Panel
@onready var fov_slider: HSlider = $Panel/Margin/VBox/FOVRow/FOVSlider
@onready var fov_label: Label = $Panel/Margin/VBox/FOVRow/FOVLabel
@onready var sens_slider: HSlider = $Panel/Margin/VBox/SensRow/SensSlider
@onready var sens_label: Label = $Panel/Margin/VBox/SensRow/SensLabel
@onready var view_slider: HSlider = $Panel/Margin/VBox/ViewRow/ViewSlider
@onready var view_label: Label = $Panel/Margin/VBox/ViewRow/ViewLabel
@onready var volume_slider: HSlider = $Panel/Margin/VBox/VolumeRow/VolumeSlider
@onready var volume_label: Label = $Panel/Margin/VBox/VolumeRow/VolumeLabel
@onready var music_slider: HSlider = $Panel/Margin/VBox/MusicRow/MusicSlider
@onready var music_label: Label = $Panel/Margin/VBox/MusicRow/MusicLabel
@onready var skin_option: OptionButton = $Panel/Margin/VBox/SkinRow/SkinOption
@onready var mode_option: OptionButton = $Panel/Margin/VBox/ModeRow/ModeOption
@onready var smooth_check: CheckButton = $Panel/Margin/VBox/DisplayRow/SmoothCheck
@onready var fullscreen_check: CheckButton = $Panel/Margin/VBox/DisplayRow/FullscreenCheck
@onready var controls_button: Button = $Panel/Margin/VBox/ControlsButton
@onready var back_button: Button = $Panel/Margin/VBox/ButtonRow/BackButton
@onready var title_button: Button = $Panel/Margin/VBox/ButtonRow/TitleButton

var _fov: float = DEFAULT_FOV
var _sens: float = DEFAULT_SENS
var _view_radius: int = DEFAULT_VIEW_RADIUS
## Master volume, 0 (silent) to 1 (full)
var _volume: float = DEFAULT_VOLUME
## Music volume, 0 (silent) to 1 (full)
var _music: float = DEFAULT_MUSIC
## The kit character the player is, one of PlayerBody.SKINS
var _skin: String = PlayerBody.SKINS[0]
## Survival, or creative with free items and flying
var _survival: bool = true
## Smooth edges (4x MSAA) and fullscreen
var _smooth: bool = true
var _fullscreen: bool = false


func _ready() -> void:
	visible = false
	# The title and the game both have this menu, so it sets up the gamepad
	Controls.apply()
	_load_from_disk()
	_apply_volume()
	_apply_display()
	_apply_slider_ranges()
	for skin: String in PlayerBody.SKINS:
		skin_option.add_item(skin.get_file().capitalize())
	mode_option.add_item("Survival")
	mode_option.add_item("Creative")
	_sync_ui_from_state()
	fov_slider.value_changed.connect(_on_fov_slider)
	sens_slider.value_changed.connect(_on_sens_slider)
	view_slider.value_changed.connect(_on_view_slider)
	volume_slider.value_changed.connect(_on_volume_slider)
	music_slider.value_changed.connect(_on_music_slider)
	skin_option.item_selected.connect(_on_skin_selected)
	mode_option.item_selected.connect(_on_mode_selected)
	smooth_check.toggled.connect(set_smooth_edges)
	fullscreen_check.toggled.connect(set_fullscreen)
	back_button.pressed.connect(close)
	title_button.pressed.connect(title_requested.emit)
	controls_button.pressed.connect(_on_controls)
	controls_menu = ControlsMenu.new()
	controls_menu.closed.connect(_on_controls_closed)
	add_child(controls_menu)
	prompts = PromptBar.new([PromptBar.SELECT, PromptBar.BACK])
	add_child(prompts)


func _apply_slider_ranges() -> void:
	fov_slider.min_value = MIN_FOV
	fov_slider.max_value = MAX_FOV
	fov_slider.step = 1.0
	sens_slider.min_value = MIN_SENS
	sens_slider.max_value = MAX_SENS
	sens_slider.step = 0.0001
	view_slider.min_value = 1
	view_slider.max_value = 8
	view_slider.step = 1
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05


func _sync_ui_from_state() -> void:
	fov_slider.value = _fov
	sens_slider.value = _sens
	view_slider.value = _view_radius
	volume_slider.value = _volume
	music_slider.value = _music
	skin_option.selected = PlayerBody.SKINS.find(_skin)
	mode_option.selected = 0 if _survival else 1
	smooth_check.set_pressed_no_signal(_smooth)
	fullscreen_check.set_pressed_no_signal(_fullscreen)
	_update_labels()


func _update_labels() -> void:
	fov_label.text = "%d" % int(round(_fov))
	sens_label.text = "%.4f" % _sens
	view_label.text = "%d chunks" % _view_radius
	volume_label.text = "%d%%" % roundi(_volume * 100.0)
	music_label.text = "%d%%" % roundi(_music * 100.0)


func _on_fov_slider(v: float) -> void:
	_fov = v
	fov_changed.emit(_fov)
	_update_labels()


func _on_sens_slider(v: float) -> void:
	_sens = v
	sensitivity_changed.emit(_sens)
	_update_labels()


func _on_view_slider(v: float) -> void:
	_view_radius = int(v)
	view_radius_changed.emit(_view_radius)
	_update_labels()


func _on_volume_slider(v: float) -> void:
	_volume = v
	_apply_volume()
	_update_labels()


func _on_music_slider(v: float) -> void:
	_music = v
	_apply_volume()
	_update_labels()


func _apply_volume() -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(MASTER_BUS), _volume)
	Music.ensure_bus()
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(Music.BUS), _music)


## True for a press of F11, which turns fullscreen on or off anywhere.
static func is_fullscreen_key(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11


func _input(event: InputEvent) -> void:
	if is_fullscreen_key(event):
		toggle_fullscreen()


## Turns fullscreen on or off, ticks its box to match and saves it to path.
func toggle_fullscreen(path: String = SETTINGS_PATH) -> void:
	_fullscreen = not _fullscreen
	_apply_display()
	fullscreen_check.set_pressed_no_signal(_fullscreen)
	_save_to_disk(path)


## Smooth edges are 4x MSAA on the 3D view.
func set_smooth_edges(on: bool) -> void:
	_smooth = on
	_apply_display()


func set_fullscreen(on: bool) -> void:
	_fullscreen = on
	_apply_display()


## Puts the smooth edges and the window mode in place, changing the window only
## when it is not already as wanted.
func _apply_display() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X if _smooth else Viewport.MSAA_DISABLED
	var full: bool = DisplayServer.window_get_mode() >= DisplayServer.WINDOW_MODE_FULLSCREEN
	if full != _fullscreen:
		var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED
		if _fullscreen:
			mode = DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(mode)


func _on_skin_selected(index: int) -> void:
	_skin = PlayerBody.SKINS[index]
	skin_changed.emit(_skin)


func _on_mode_selected(index: int) -> void:
	_survival = index == 0
	survival_changed.emit(_survival)


## The controls list shows in place of the settings, and its Back shows them
## again.
func _on_controls() -> void:
	panel.hide()
	prompts.hide()
	controls_menu.open()


func _on_controls_closed() -> void:
	panel.show()
	prompts.show()
	controls_button.grab_focus()


func open() -> void:
	visible = true
	# The gamepad starts on Back, so A goes straight back
	back_button.grab_focus()
	Mouse.mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


func close() -> void:
	visible = false
	Mouse.mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	_save_to_disk()
	closed.emit()


func _load_from_disk(path: String = SETTINGS_PATH) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(path)
	if err != OK:
		return
	_fov = float(cfg.get_value("settings", "fov", DEFAULT_FOV))
	_sens = float(cfg.get_value("settings", "sensitivity", DEFAULT_SENS))
	_view_radius = int(cfg.get_value("settings", "view_radius", DEFAULT_VIEW_RADIUS))
	_volume = clampf(float(cfg.get_value("settings", "volume", DEFAULT_VOLUME)), 0.0, 1.0)
	_music = clampf(float(cfg.get_value("settings", "music", DEFAULT_MUSIC)), 0.0, 1.0)
	_skin = str(cfg.get_value("settings", "skin", PlayerBody.SKINS[0]))
	if not PlayerBody.SKINS.has(_skin):
		_skin = PlayerBody.SKINS[0]
	_survival = bool(cfg.get_value("settings", "survival", true))
	_smooth = bool(cfg.get_value("settings", "smooth_edges", true))
	_fullscreen = bool(cfg.get_value("settings", "fullscreen", false))
	Controls.load_from(cfg)


func _save_to_disk(path: String = SETTINGS_PATH) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("settings", "fov", _fov)
	cfg.set_value("settings", "sensitivity", _sens)
	cfg.set_value("settings", "view_radius", _view_radius)
	cfg.set_value("settings", "volume", _volume)
	cfg.set_value("settings", "music", _music)
	cfg.set_value("settings", "skin", _skin)
	cfg.set_value("settings", "survival", _survival)
	cfg.set_value("settings", "smooth_edges", _smooth)
	cfg.set_value("settings", "fullscreen", _fullscreen)
	Controls.save_to(cfg)
	var err: int = cfg.save(path)
	if err != OK:
		push_warning("SettingsMenu: save failed err=%d" % err)


func get_fov() -> float:
	return _fov


func get_sens() -> float:
	return _sens


func get_view_radius() -> int:
	return _view_radius


func get_volume() -> float:
	return _volume


func get_music() -> float:
	return _music


func get_skin() -> String:
	return _skin


func get_survival() -> bool:
	return _survival


func get_smooth_edges() -> bool:
	return _smooth


func get_fullscreen() -> bool:
	return _fullscreen
