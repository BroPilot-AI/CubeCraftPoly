class_name SkyClock
extends Control

## The clock of the day and night in the top right corner: a dial of sky and
## night with the sun or the moon going round it (sunrise on the left, noon at
## the top), and under it how long till night falls or the day comes. Before
## and on a Blood Moon night the dial's night and its moon are red.

## Pixels from the screen's top right corner, and the clock's size
const MARGIN: float = 12.0
const CLOCK_SIZE: Vector2 = Vector2(180.0, 84.0)
const RADIUS: float = 26.0
## The sun's or the moon's radius, inside the dial's rim
const BODY: float = 6.0
## Points along the sky's edge
const STEPS: int = 32
const DAY_COLOR: Color = Color(0.45, 0.7, 0.95, 1.0)
const NIGHT_COLOR: Color = Color(0.08, 0.1, 0.25, 1.0)
const SUN_COLOR: Color = Color(1.0, 0.85, 0.2, 1.0)
const MOON_COLOR: Color = Color(0.9, 0.92, 1.0, 1.0)
const RIM_COLOR: Color = Color(0.0, 0.0, 0.0, 0.7)
## The night and the moon on a Blood Moon day
const BLOOD_NIGHT: Color = Color(0.3, 0.03, 0.05, 1.0)
const BLOOD_MOON: Color = Color(1.0, 0.3, 0.25, 1.0)

## "Night in 5:49", "Blood Moon in 5:49" or "Day in 4:12"
var label: Label = null
var _day_night: DayNight = null
var _blood: BloodMoon = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -CLOCK_SIZE.x - MARGIN
	offset_right = -MARGIN
	offset_top = MARGIN
	offset_bottom = MARGIN + CLOCK_SIZE.y
	label = Label.new()
	label.position = Vector2(0.0, RADIUS * 2.0 + 6.0)
	label.size = Vector2(CLOCK_SIZE.x, 22.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func setup(day_night: DayNight, blood: BloodMoon = null) -> void:
	_day_night = day_night
	_blood = blood


## Says how long till the change, and moves the sun or the moon once a second.
func _process(_delta: float) -> void:
	if _day_night == null:
		return
	var night: bool = _day_night.is_night()
	var text: String = text_for(night, ceili(_day_night.seconds_to_change()), _is_blood())
	if text != label.text:
		label.text = text
		queue_redraw()


## "Night in m:ss" by day, "Day in m:ss" by night; "Blood Moon in m:ss" by day
## when blood is true.
static func text_for(night: bool, seconds: int, blood: bool = false) -> String:
	var next: String = "Day" if night else ("Blood Moon" if blood else "Night")
	return "%s in %d:%02d" % [next, floori(seconds / 60.0), seconds % 60]


## The dial's night: red when tonight is a Blood Moon.
func night_color() -> Color:
	return BLOOD_NIGHT if _is_blood() else NIGHT_COLOR


## The moon: red on a Blood Moon night, the sun by day.
func moon_color() -> Color:
	if not _day_night.is_night():
		return SUN_COLOR
	return BLOOD_MOON if _is_blood() else MOON_COLOR


func _draw() -> void:
	if _day_night == null:
		return
	var center: Vector2 = Vector2(CLOCK_SIZE.x / 2.0, RADIUS + 2.0)
	draw_circle(center, RADIUS, night_color(), true, -1.0, true)
	# The sky: the dial from where night ends round over the top to where it falls
	var edge: float = DayNight.night_edge()
	var sky: PackedVector2Array = PackedVector2Array()
	for i in STEPS + 1:
		sky.append(center + _toward(lerpf(-edge, 0.5 + edge, float(i) / STEPS)) * RADIUS)
	draw_colored_polygon(sky, DAY_COLOR)
	var body_at: Vector2 = center + _toward(_day_night._time) * (RADIUS - BODY - 2.0)
	draw_circle(body_at, BODY, moon_color(), true, -1.0, true)
	draw_arc(center, RADIUS, 0.0, TAU, STEPS * 2, RIM_COLOR, 2.0, true)


## Out from the dial's middle to the time of day: left at sunrise, up at noon.
static func _toward(time: float) -> Vector2:
	return Vector2(-cos(time * TAU), -sin(time * TAU))


func _is_blood() -> bool:
	return _blood != null and _blood.tonight()
