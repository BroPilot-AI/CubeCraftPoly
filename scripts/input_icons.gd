class_name InputIcons
extends RefCounted

## Pictures of the keys, mouse buttons and gamepad buttons, from Kenney's Input
## Prompts (CC0), as BBCode for a RichTextLabel or as textures. of() shows what
## does an action now, so a key or button changed in the controls list shows
## too; a key or button with no picture says its name. pad says which of the
## two the player is using, so every line shows the same one, and playstation
## swaps the Xbox pictures for a PlayStation pad's.

const DIR: String = "res://assets/ui/input_prompts/"
## How far a stick or a trigger is pushed before it counts as using the gamepad
const PAD_PUSH: float = 0.5
## How wide the pictures are, in pixels; they are square
const SIZE: int = 24
## The clear border round a picture, in pixels; only a stick's and the mouse
## wheel's go past it
const BORDER: float = 8.0
## How tall the wide pictures are inside their border, in pixels; each sits in
## the middle, as wide as the rest
const WIDE: Dictionary = {
	"keyboard_alt": 36.0,
	"keyboard_backspace": 36.0,
	"keyboard_capslock": 36.0,
	"keyboard_ctrl": 36.0,
	"keyboard_tab": 36.0,
	"keyboard_shift": 32.0,
	"keyboard_space": 28.0,
	"xbox_lb": 32.0,
	"xbox_rb": 32.0,
}
## Keys whose picture is not named after the key
const KEY_FILES: Dictionary = {
	KEY_UP: "arrow_up",
	KEY_DOWN: "arrow_down",
	KEY_LEFT: "arrow_left",
	KEY_RIGHT: "arrow_right",
	KEY_PAGEUP: "page_up",
	KEY_PAGEDOWN: "page_down",
	KEY_EQUAL: "equals",
	KEY_SLASH: "slash_forward",
	KEY_BACKSLASH: "slash_back",
	KEY_BRACKETLEFT: "bracket_open",
	KEY_BRACKETRIGHT: "bracket_close",
	KEY_QUOTELEFT: "tilde",
}
const MOUSE_FILES: Dictionary = {
	MOUSE_BUTTON_LEFT: "mouse_left",
	MOUSE_BUTTON_RIGHT: "mouse_right",
	MOUSE_BUTTON_MIDDLE: "mouse_scroll",
}
## An Xbox pad's buttons, as Godot names them
const BUTTON_FILES: Dictionary = {
	JOY_BUTTON_A: "xbox_button_color_a",
	JOY_BUTTON_B: "xbox_button_color_b",
	JOY_BUTTON_X: "xbox_button_color_x",
	JOY_BUTTON_Y: "xbox_button_color_y",
	JOY_BUTTON_BACK: "xbox_button_view",
	JOY_BUTTON_GUIDE: "xbox_guide",
	JOY_BUTTON_START: "xbox_button_menu",
	JOY_BUTTON_LEFT_STICK: "xbox_ls",
	JOY_BUTTON_RIGHT_STICK: "xbox_rs",
	JOY_BUTTON_LEFT_SHOULDER: "xbox_lb",
	JOY_BUTTON_RIGHT_SHOULDER: "xbox_rb",
	JOY_BUTTON_DPAD_UP: "xbox_dpad_up",
	JOY_BUTTON_DPAD_DOWN: "xbox_dpad_down",
	JOY_BUTTON_DPAD_LEFT: "xbox_dpad_left",
	JOY_BUTTON_DPAD_RIGHT: "xbox_dpad_right",
}
const AXIS_FILES: Dictionary = {
	JOY_AXIS_TRIGGER_LEFT: "xbox_lt",
	JOY_AXIS_TRIGGER_RIGHT: "xbox_rt",
}
## A PlayStation pad's pictures in place of the Xbox ones
const PLAYSTATION_FILES: Dictionary = {
	"xbox_button_color_a": "playstation_button_color_cross",
	"xbox_button_color_b": "playstation_button_color_circle",
	"xbox_button_color_x": "playstation_button_color_square",
	"xbox_button_color_y": "playstation_button_color_triangle",
	"xbox_button_view": "playstation5_button_create",
	"xbox_button_menu": "playstation5_button_options",
	"xbox_ls": "playstation_button_l3",
	"xbox_rs": "playstation_button_r3",
	"xbox_lb": "playstation_trigger_l1",
	"xbox_rb": "playstation_trigger_r1",
	"xbox_lt": "playstation_trigger_l2",
	"xbox_rt": "playstation_trigger_r2",
	"xbox_dpad_up": "playstation_dpad_up",
	"xbox_dpad_down": "playstation_dpad_down",
	"xbox_dpad_left": "playstation_dpad_left",
	"xbox_dpad_right": "playstation_dpad_right",
	"xbox_stick_l_up": "playstation_stick_l_up",
	"xbox_stick_l_down": "playstation_stick_l_down",
	"xbox_stick_l_left": "playstation_stick_l_left",
	"xbox_stick_l_right": "playstation_stick_l_right",
}
## Sony's USB vendor number, and the words in a PlayStation pad's name
const SONY_VENDOR: int = 0x054C
const PLAYSTATION_NAMES: Array[String] = [
	"playstation", "dualshock", "dualsense", "ps3", "ps4", "ps5", "sony",
]
## The dark backing of a line, so the white pictures show on snow and sky
const BACKING: Color = Color(0, 0, 0, 0.45)
const BACKING_ROUND: int = 8
const BACKING_SIDE: float = 10.0
const BACKING_TOP: float = 1.0

## True while the gamepad is the one being used, as the last key, button or
## push says
static var pad: bool = false
## True when the gamepad last used is a PlayStation one, so its pictures show
static var playstation: bool = _first_is_playstation()


## Notes from event whether the player is using the gamepad, or the keys and
## the mouse.
static func note(event: InputEvent) -> void:
	var pushed: bool = event is InputEventJoypadMotion and absf(event.axis_value) > PAD_PUSH
	if event is InputEventJoypadButton or pushed:
		pad = true
		playstation = is_playstation(event.device)
	elif event is InputEventKey or event is InputEventMouseButton:
		pad = false


## The picture of what does action: its key or mouse button, or with on_pad its
## gamepad button or trigger; "" when nothing on that side does it.
static func of(action: String, on_pad: bool) -> String:
	var event: InputEvent = _event_of(action, on_pad)
	return picture(event) if event != null else ""


## The picture of what does action, as of(), as a texture; null when it has
## none.
static func texture_of(action: String, on_pad: bool) -> Texture2D:
	var event: InputEvent = _event_of(action, on_pad)
	return texture(event) if event != null else null


## The picture of event, or its name when there is none.
static func picture(event: InputEvent) -> String:
	var path: String = path_of(_file(event))
	if path != "":
		return "[img=%d]%s[/img]" % [SIZE, path]
	return name_of(event)


## The picture of event as a texture, or null when there is none.
static func texture(event: InputEvent) -> Texture2D:
	return named(_file(event))


## The picture in file, without .png, or null when there is none.
static func named(file: String) -> Texture2D:
	var path: String = path_of(file)
	return load(path) as Texture2D if path != "" else null


## The picture without its clear border, so it fills the space it is given, and
## a wide one without the clear rows above and below it; null stays null.
static func trimmed(picture: Texture2D) -> Texture2D:
	if picture == null:
		return null
	var whole: Vector2 = picture.get_size()
	var tall: float = WIDE.get(picture.resource_path.get_file().get_basename(), whole.y - BORDER * 2.0)
	var cut: AtlasTexture = AtlasTexture.new()
	cut.atlas = picture
	cut.region = Rect2(BORDER, (whole.y - tall) / 2.0, whole.x - BORDER * 2.0, tall)
	return cut


## The path of the picture in file, without .png, or "" when there is none. A
## PlayStation pad's picture shows in place of an Xbox one's.
static func path_of(file: String) -> String:
	if playstation:
		file = PLAYSTATION_FILES.get(file, file)
	var path: String = DIR + file + ".png"
	return path if file != "" and ResourceLoader.exists(path) else ""


## True when the gamepad device is a PlayStation one, by its maker or its name.
static func is_playstation(device: int) -> bool:
	if device not in Input.get_connected_joypads():
		return false
	if int(Input.get_joy_info(device).get("vendor_id", 0)) == SONY_VENDOR:
		return true
	var joy_name: String = Input.get_joy_name(device).to_lower()
	for word: String in PLAYSTATION_NAMES:
		if word in joy_name:
			return true
	return false


## The name of event's key or button.
static func name_of(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode)
	if event is InputEventJoypadButton:
		return Controls.button_name(event.button_index)
	return event.as_text()


## A line of text and pictures that is as wide as what it says, on a dark
## backing; it grows both ways from its anchor, so a centred one stays centred.
static func line() -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	style(label)
	return label


## Makes label a line of text and pictures, as line() does.
static func style(label: RichTextLabel) -> void:
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.scroll_active = false
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The pictures are 64 pixels, shrunk to SIZE
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var backing: StyleBoxFlat = StyleBoxFlat.new()
	backing.bg_color = BACKING
	backing.set_corner_radius_all(BACKING_ROUND)
	backing.content_margin_left = BACKING_SIDE
	backing.content_margin_right = BACKING_SIDE
	backing.content_margin_top = BACKING_TOP
	backing.content_margin_bottom = BACKING_TOP
	label.add_theme_stylebox_override("normal", backing)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)


## The first event of action on the gamepad with on_pad, else on the keys and
## the mouse; null when there is none.
static func _event_of(action: String, on_pad: bool) -> InputEvent:
	for event: InputEvent in InputMap.action_get_events(action):
		if (event is InputEventJoypadButton or event is InputEventJoypadMotion) == on_pad:
			return event
	return null


## The picture's file name, without .png, or "" when there is none.
static func _file(event: InputEvent) -> String:
	if event is InputEventKey:
		var key: Key = event.physical_keycode
		return "keyboard_" + KEY_FILES.get(key, OS.get_keycode_string(key).to_lower())
	if event is InputEventMouseButton:
		return MOUSE_FILES.get(event.button_index, "")
	if event is InputEventJoypadButton:
		return BUTTON_FILES.get(event.button_index, "")
	if event is InputEventJoypadMotion:
		return AXIS_FILES.get(event.axis, "")
	return ""


## True when the first gamepad plugged in is a PlayStation one, so its
## pictures show before a button is pressed.
static func _first_is_playstation() -> bool:
	var pads: Array[int] = Input.get_connected_joypads()
	return not pads.is_empty() and is_playstation(pads[0])
