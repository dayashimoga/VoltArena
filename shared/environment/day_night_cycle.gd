class_name DayNightCycle3D
extends Node3D

## Dynamic Celestial Dome and Time-of-Day Subsystem for VoltArena
## Governs directional sun/moon rotation, ambient energy, shadow angles, and sky coloring.

signal time_updated(hour: int, minute: int)
signal day_phase_changed(phase_name: String)

@export var time_of_day: float = 12.0 # 0.0 to 24.0 hours
@export var day_length_seconds: float = 600.0 # 10 real minutes = 24 game hours
@export var sun_color_day: Color = Color(1.0, 0.96, 0.88)
@export var sun_color_sunset: Color = Color(1.0, 0.55, 0.2)
@export var sun_color_night: Color = Color(0.2, 0.35, 0.6)

var sun_light: DirectionalLight3D
var env_node: WorldEnvironment
var current_phase: String = "day"

func _ready() -> void:
	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.shadow_enabled = true
	add_child(sun_light)
	update_lighting(0.0)

func _process(delta: float) -> void:
	var hours_per_sec = 24.0 / maxf(day_length_seconds, 1.0)
	time_of_day = fmod(time_of_day + hours_per_sec * delta, 24.0)
	update_lighting(delta)

	var hour = int(time_of_day)
	var minute = int((time_of_day - hour) * 60.0)
	time_updated.emit(hour, minute)

func update_lighting(_delta: float) -> void:
	var sun_angle = ((time_of_day - 6.0) / 24.0) * TAU
	sun_light.rotation = Vector3(-sin(sun_angle), sun_angle * 0.5, 0)

	var new_phase = "day"
	if time_of_day >= 5.0 and time_of_day < 8.0:
		new_phase = "morning"
		sun_light.light_color = sun_color_sunset.lerp(sun_color_day, (time_of_day - 5.0) / 3.0)
		sun_light.light_energy = 0.85
	elif time_of_day >= 8.0 and time_of_day < 17.0:
		new_phase = "day"
		sun_light.light_color = sun_color_day
		sun_light.light_energy = 1.2
	elif time_of_day >= 17.0 and time_of_day < 20.0:
		new_phase = "sunset"
		sun_light.light_color = sun_color_day.lerp(sun_color_sunset, (time_of_day - 17.0) / 3.0)
		sun_light.light_energy = 0.9
	else:
		new_phase = "night"
		sun_light.light_color = sun_color_night
		sun_light.light_energy = 0.25

	if new_phase != current_phase:
		current_phase = new_phase
		day_phase_changed.emit(current_phase)

func set_time_hours(hours: float) -> void:
	time_of_day = clampf(hours, 0.0, 24.0)
	update_lighting(0.0)
