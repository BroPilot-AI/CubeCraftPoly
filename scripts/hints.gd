class_name Hints
extends Control

## Tells the player what the buttons do: under the crosshair, what the use
## button does to the block or villager in it (UseHint), and over the hotbar the
## main controls, till the player has broken a block and placed one. Both show
## the pictures of the gamepad's buttons while it is the one being used.

## The player took up the gamepad, or put it down for the keys and the mouse
signal pad_changed

## Pixels from the middle of the screen down to the use line
const USE_TOP: float = 18.0
## Pixels from the bottom of the screen up to the controls line, over the pickup line
const TIPS_BOTTOM: float = 136.0
## The controls line: each action, and what it does
const TIPS: Array = [
	["break_block", "Break"],
	["place_block", "Place / use"],
	["toggle_inventory", "Backpack"],
	["toggle_pause", "Menu"],
]
const TIPS_GAP: String = "     "

## The controls line over the hotbar
var tips: RichTextLabel = null
## The line under the crosshair saying what the use button does, hidden while
## it says nothing
var use: RichTextLabel = null
## True while the gamepad is the one being used
var pad: bool = false
## True while the pictures are a PlayStation pad's
var _playstation: bool = false
var _player: Player = null
var _chunks: Node3D = null
var _broke: bool = false
var _placed: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	use = _line(Control.PRESET_CENTER, USE_TOP)
	use.visible = false
	tips = _line(Control.PRESET_CENTER_BOTTOM, -TIPS_BOTTOM)
	_refresh_tips()


## Follows what player aims at in chunks, and what they break and place.
func setup(player: Player, chunks: Node3D) -> void:
	_player = player
	_chunks = chunks
	player.block_broken.connect(_on_broken)
	player.block_placed.connect(_on_placed)


func _process(_delta: float) -> void:
	set_pad(InputIcons.pad)
	var said: String = _use_text() if _player != null else ""
	# Only a change sets it, as the line reads its pictures again each time
	if said != use.text:
		use.text = said
		use.visible = said != ""
	if tips.visible:
		_refresh_tips()


func _input(event: InputEvent) -> void:
	InputIcons.note(event)
	set_pad(InputIcons.pad)


## Says the gamepad's buttons when on is true, else the keys and the mouse.
func set_pad(on: bool) -> void:
	InputIcons.pad = on
	if on == pad and InputIcons.playstation == _playstation:
		return
	pad = on
	_playstation = InputIcons.playstation
	pad_changed.emit()
	_refresh_tips()


## Says each action of TIPS after the picture of its key or button, so a key
## changed in the controls list shows when the list closes.
func _refresh_tips() -> void:
	var parts: PackedStringArray = []
	for tip: Array in TIPS:
		parts.append("%s %s" % [InputIcons.of(tip[0], pad), tip[1]])
	var said: String = TIPS_GAP.join(parts)
	if said != tips.text:
		tips.text = said


func _use_text() -> String:
	var aim: BlockAim = _player.aim
	var button: String = UseHint.button(pad)
	if aim.mob != null:
		return UseHint.for_mob(aim.mob.kind, _player.survival, button)
	if aim.state != &"block" or _chunks == null:
		return ""
	return UseHint.for_block(_chunks.get_block_at(aim.cell), _player.held(), button, _player.survival)


func _on_broken(_cell: Vector3i, _id: int) -> void:
	_broke = true
	tips.visible = not (_broke and _placed)


func _on_placed(_cell: Vector3i, _id: int) -> void:
	_placed = true
	tips.visible = not (_broke and _placed)


## A centred line of text and pictures anchored at preset, top pixels down
## from it.
func _line(preset: Control.LayoutPreset, top: float) -> RichTextLabel:
	var line: RichTextLabel = InputIcons.line()
	line.set_anchors_preset(preset)
	line.offset_top = top
	line.offset_bottom = top
	add_child(line)
	return line
