class_name Mouse
extends RefCounted

## The mouse mode the game asks for, read and set in place of Input.mouse_mode.
## With pretend on the mode is only kept here: the playtests turn it on, so the
## real cursor isn't held in their window and moved to its middle while someone
## works at the PC.

static var pretend: bool = false
static var _pretend_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

static var mode: Input.MouseMode:
	get:
		return _pretend_mode if pretend else Input.mouse_mode
	set(value):
		if pretend:
			_pretend_mode = value
		else:
			Input.mouse_mode = value
