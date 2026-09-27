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
	# 1. Directional Sun/Moon Light with Shadows
	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.shadow_enabled = true
	add_child(sun_light)

	# 2. Celestial World Environment with Procedural Sky Dome
	env_node = WorldEnvironment.new()
	env_node.name = "CelestialEnvironment"
	var env = Environment.new()
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.25, 0.55, 0.95)
	sky_mat.sky_horizon_color = Color(0.72, 0.82, 0.92)
	sky_mat.ground_bottom_color = Color(0.18, 0.20, 0.22)
	sky_mat.ground_horizon_color = Color(0.65, 0.75, 0.85)
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.82, 0.90)
	env.fog_density = 0.003
	env_node.environment = env
	add_child(env_node)

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
	var sky_mat: ProceduralSkyMaterial = null
	if env_node and env_node.environment and env_node.environment.sky:
		sky_mat = env_node.environment.sky.sky_material as ProceduralSkyMaterial

	if time_of_day >= 5.0 and time_of_day < 8.0:
		new_phase = "morning"
		var t = (time_of_day - 5.0) / 3.0
		sun_light.light_color = sun_color_sunset.lerp(sun_color_day, t)
		sun_light.light_energy = 0.85
		if sky_mat:
			sky_mat.sky_top_color = Color(0.28, 0.45, 0.82).lerp(Color(0.25, 0.55, 0.95), t)
			sky_mat.sky_horizon_color = Color(0.95, 0.70, 0.45).lerp(Color(0.72, 0.82, 0.92), t)
		if env_node and env_node.environment:
			env_node.environment.ambient_light_energy = 0.85
			env_node.environment.fog_light_color = Color(0.90, 0.75, 0.60)
	elif time_of_day >= 8.0 and time_of_day < 17.0:
		new_phase = "day"
		sun_light.light_color = sun_color_day
		sun_light.light_energy = 1.2
		if sky_mat:
			sky_mat.sky_top_color = Color(0.25, 0.55, 0.95)
			sky_mat.sky_horizon_color = Color(0.72, 0.82, 0.92)
		if env_node and env_node.environment:
			env_node.environment.ambient_light_energy = 1.0
			env_node.environment.fog_light_color = Color(0.75, 0.82, 0.90)
	elif time_of_day >= 17.0 and time_of_day < 20.0:
		new_phase = "sunset"
		var t = (time_of_day - 17.0) / 3.0
		sun_light.light_color = sun_color_day.lerp(sun_color_sunset, t)
		sun_light.light_energy = 0.9
		if sky_mat:
			sky_mat.sky_top_color = Color(0.25, 0.55, 0.95).lerp(Color(0.35, 0.22, 0.55), t)
			sky_mat.sky_horizon_color = Color(0.72, 0.82, 0.92).lerp(Color(1.0, 0.50, 0.15), t)
		if env_node and env_node.environment:
			env_node.environment.ambient_light_energy = 0.8
			env_node.environment.fog_light_color = Color(0.95, 0.55, 0.25)
	else:
		new_phase = "night"
		sun_light.light_color = sun_color_night
		sun_light.light_energy = 0.25
		if sky_mat:
			sky_mat.sky_top_color = Color(0.04, 0.06, 0.14)
			sky_mat.sky_horizon_color = Color(0.08, 0.12, 0.22)
		if env_node and env_node.environment:
			env_node.environment.ambient_light_energy = 0.4
			env_node.environment.fog_light_color = Color(0.08, 0.12, 0.22)

	if new_phase != current_phase:
		current_phase = new_phase
		day_phase_changed.emit(current_phase)

func set_time_hours(hours: float) -> void:
	time_of_day = clampf(hours, 0.0, 24.0)
	update_lighting(0.0)
