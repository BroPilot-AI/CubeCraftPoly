class_name PlayerBody
extends Node3D

## The player's body, seen in the third-person view: one of the kit's three
## characters. It stands, walks or runs with the player's speed, and punches
## when the player swings.

## Kit models the player can wear, under BlockDefs.KIT_DIR without ".glb"
const SKINS: Array[String] = ["player/character", "decor/Steve", "decor/Cube Woman Character"]
## Speed (blocks/s) across the ground the body walks from, and runs from
const WALK_FROM: float = 0.5
const RUN_FROM: float = 6.0
## Seconds to blend from one clip to the next
const BLEND: float = 0.2

## The kit model worn, one of SKINS
var skin: String = ""
var _model: Node3D = null
var _anims: AnimationPlayer = null


func _init() -> void:
	set_skin(SKINS[0])


## Takes off the model worn and puts on the kit model new_skin, one of SKINS.
func set_skin(new_skin: String) -> void:
	skin = new_skin
	if _model != null:
		remove_child(_model)
		_model.queue_free()
	_model = load(BlockDefs.KIT_DIR + skin + ".glb").instantiate()
	_model.scale = Vector3.ONE * BlockDefs.KIT_SCALE
	# The kit models face +Z; the player looks down -Z
	_model.rotation.y = PI
	add_child(_model)
	_anims = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip: String in ["Idle", "Walk", "Run"]:
		_anims.get_animation(_clip(clip)).loop_mode = Animation.LOOP_LINEAR
	_anims.play(_clip("Idle"))


## Stands, walks or runs for speed (blocks/s) across the ground, once any punch
## has played through.
func animate(speed: float) -> void:
	if _anims.is_playing() and _anims.current_animation == _clip("Punch"):
		return
	var clip: String = "Idle"
	if speed > RUN_FROM:
		clip = "Run"
	elif speed > WALK_FROM:
		clip = "Walk"
	var clip_name: String = _clip(clip)
	if _anims.current_animation != clip_name:
		_anims.play(clip_name, BLEND)


## Plays the punch through once from the start.
func punch() -> void:
	_anims.play(_clip("Punch"), BLEND)
	_anims.seek(0.0, true)


## The full name of the model's clip that ends in |clip, or "" when it has none.
func _clip(clip: String) -> String:
	for clip_name: String in _anims.get_animation_list():
		if clip_name.ends_with("|" + clip):
			return clip_name
	return ""
