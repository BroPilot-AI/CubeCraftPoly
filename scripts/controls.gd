class_name Controls
extends RefCounted

## The gamepad's buttons, sticks and triggers, added to the actions of
## project.godot beside their keys and mouse buttons. The left stick walks and
## the right stick looks, the triggers break and place, and the shoulders move
## along the hotbar. In the menus the D-pad or the left stick moves along the
## buttons, A presses the one picked out and B goes back. The settings' controls
## list changes the keys and the buttons, and the settings file keeps them.

## An event of the map on this device matches every gamepad
const ALL_DEVICES: int = -1
## How far a stick or trigger goes before it counts, out of 1
const AXIS_DEADZONE: float = 0.2
## How fast the right stick turns the view pushed all the way: as many mouse
## pixels each second, so the look sensitivity setting scales it too
const STICK_LOOK: float = 1250.0
## Action: the button that does it
const BUTTONS: Dictionary = {
	"jump": JOY_BUTTON_A,
	"sprint": JOY_BUTTON_LEFT_STICK,
	"sneak": JOY_BUTTON_RIGHT_STICK,
	"slot_prev": JOY_BUTTON_LEFT_SHOULDER,
	"slot_next": JOY_BUTTON_RIGHT_SHOULDER,
	"toggle_inventory": JOY_BUTTON_Y,
	"toggle_pause": JOY_BUTTON_START,
	"toggle_view": JOY_BUTTON_BACK,
	"power": JOY_BUTTON_X,
	"ui_accept": JOY_BUTTON_A,
	"ui_cancel": JOY_BUTTON_B,
}
## Action: [the stick or trigger axis, the way it is pushed]
const AXES: Dictionary = {
	"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	"move_back": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"look_left": [JOY_AXIS_RIGHT_X, -1.0],
	"look_right": [JOY_AXIS_RIGHT_X, 1.0],
	"look_up": [JOY_AXIS_RIGHT_Y, -1.0],
	"look_down": [JOY_AXIS_RIGHT_Y, 1.0],
	"break_block": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	"place_block": [JOY_AXIS_TRIGGER_LEFT, 1.0],
}
## The actions the controls list can change, by the name it shows
const NAMES: Dictionary = {
	"move_forward": "Walk forward",
	"move_back": "Walk back",
	"move_left": "Walk left",
	"move_right": "Walk right",
	"jump": "Jump",
	"sprint": "Sprint",
	"sneak": "Sneak",
	"toggle_inventory": "Backpack",
	"toggle_view": "Change view",
	"slot_prev": "Hotbar left",
	"slot_next": "Hotbar right",
	"power": "Power",
}
## The gamepad's buttons by name, in JoyButton order
const BUTTON_NAMES: Array[String] = [
	"A", "B", "X", "Y", "Back", "Guide", "Start", "L3", "R3", "LB", "RB",
	"D-pad up", "D-pad down", "D-pad left", "D-pad right",
]
## Where the settings file keeps the keys and the gamepad's buttons
const KEYS_SECTION: String = "keys"
const PAD_SECTION: String = "gamepad"


## Adds the gamepad's events to the input map, once however often it is called.
static func apply() -> void:
	for action: String in BUTTONS:
		var button: InputEventJoypadButton = InputEventJoypadButton.new()
		button.button_index = BUTTONS[action]
		_add(action, button)
	for action: String in AXES:
		var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
		motion.axis = AXES[action][0]
		motion.axis_value = AXES[action][1]
		_add(action, motion)
		InputMap.action_set_deadzone(action, AXIS_DEADZONE)


## The right stick's turn of the view for delta seconds, in mouse pixels: slow
## near the middle and STICK_LOOK each second pushed all the way.
static func stick_look(delta: float) -> Vector2:
	var stick: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	return stick * stick.length() * STICK_LOOK * delta


## Puts every key and button back as the game came.
static func reset() -> void:
	InputMap.load_from_project_settings()
	apply()


## The key that does action, or KEY_NONE when no key does.
static func key_of(action: String) -> Key:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.physical_keycode
	return KEY_NONE


## The gamepad button that does action, or JOY_BUTTON_INVALID when none does.
static func button_of(action: String) -> JoyButton:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return event.button_index
	return JOY_BUTTON_INVALID


## A gamepad button's name, as the controls list shows it.
static func button_name(button: JoyButton) -> String:
	if button >= 0 and button < BUTTON_NAMES.size():
		return BUTTON_NAMES[button]
	return "Button %d" % button


## Makes key do action in place of the key it had.
static func bind_key(action: String, key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	_bind(action, event)


## Makes button do action in place of the gamepad button it had.
static func bind_button(action: String, button: JoyButton) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	_bind(action, event)


## Keeps the keys and buttons of the controls list in cfg.
static func save_to(cfg: ConfigFile) -> void:
	for action: String in NAMES:
		if key_of(action) != KEY_NONE:
			cfg.set_value(KEYS_SECTION, action, key_of(action))
		if BUTTONS.has(action):
			cfg.set_value(PAD_SECTION, action, button_of(action))


## Sets the keys and buttons cfg keeps, passing over any that are not one.
static func load_from(cfg: ConfigFile) -> void:
	for action: String in NAMES:
		var key: Variant = cfg.get_value(KEYS_SECTION, action, KEY_NONE)
		if key is int and key > 0 and key_of(action) != KEY_NONE:
			bind_key(action, key as Key)
		var button: Variant = cfg.get_value(PAD_SECTION, action, JOY_BUTTON_INVALID)
		if button is int and button >= 0 and button < JOY_BUTTON_SDL_MAX and BUTTONS.has(action):
			bind_button(action, button as JoyButton)


## Puts event in place of the action's event of its kind.
static func _bind(action: String, event: InputEvent) -> void:
	for old: InputEvent in InputMap.action_get_events(action):
		if old.get_class() == event.get_class():
			InputMap.action_erase_event(action, old)
	_add(action, event)


static func _add(action: String, event: InputEvent) -> void:
	event.device = ALL_DEVICES
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
