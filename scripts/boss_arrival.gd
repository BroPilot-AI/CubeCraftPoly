class_name BossArrival
extends Node

## The player, the sky, the banner, and the sound, or null in tests

var player: Player = null
var day_night: DayNight = null
var hud: CanvasLayer = null
var sound: SoundBank = null
## The camera shake on a boss's arrival, about 3x a hit shake
const SHAKE: float = 0.12
## Seconds the gloom rises when a boss arrives
const GLOOM_IN: float = 2.0
## Seconds the gloom falls when a boss is gone
const GLOOM_OUT: float = 3.0
## The banner text, with the boss's name in place
const TEXT: String = "%s has come!"
## The banner text when a boss is enraged, and its camera shake
const RAGE_TEXT: String = "%s is enraged!"
const RAGE_SHAKE: float = 0.1
## The running gloom tween, to kill before starting a new one
var _gloom_tween: Tween = null


func setup(p: Player, dn: DayNight, h: CanvasLayer, s: SoundBank) -> void:
	player = p
	day_night = dn
	hud = h
	sound = s


## A boss arrived: horn, shake, banner, and the gloom rising to its darkest.
func arrive(boss: Mob) -> void:
	if sound != null:
		sound.play("horn", boss.global_position)
	if player != null and player.feel != null:
		player.feel.shake(SHAKE)
	if hud != null:
		hud.show_banner(TEXT % MobDefs.boss_name(boss.boss))
	if day_night != null:
		_start_gloom(1.0, GLOOM_IN)
		boss.died.connect(_on_boss_gone, CONNECT_ONE_SHOT)
		boss.tree_exiting.connect(_on_boss_gone, CONNECT_ONE_SHOT)


## A boss is enraged (BossMoves): roar, shake and banner.
func enrage(boss: Mob) -> void:
	if sound != null:
		sound.play("roar", boss.global_position)
	if player != null and player.feel != null:
		player.feel.shake(RAGE_SHAKE)
	if hud != null:
		hud.show_banner(RAGE_TEXT % MobDefs.boss_name(boss.boss))


## The gloom falls once, whenever the boss is gone.
func _on_boss_gone() -> void:
	if day_night != null:
		_start_gloom(0.0, GLOOM_OUT)


## Tweens the sky to target, killing any gloom tween still running.
func _start_gloom(target: float, duration: float) -> void:
	if _gloom_tween != null and _gloom_tween.is_valid():
		_gloom_tween.kill()
	_gloom_tween = create_tween()
	_gloom_tween.tween_property(day_night, "gloom", target, duration)
