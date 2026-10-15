class_name UrbanWeatherSystem
extends Node3D

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")

## Dynamic 24-hour time of day, dynamic celestial lighting, golden-hour sunsets,
## and atmospheric weather simulation for Urban Legends open world.
## Supports:
## - 24-Hour Cycle with orbital directional sun & moon
## - Golden Hour Sunset (17:30 - 19:30): Warm amber/crimson haze and elongated shadows (Screenshots 1 & 4)
## - Neon Night (20:00 - 05:00): Atmospheric sky with city ambient luminescence
## - Wet Road Specular Modulation: Drops asphalt roughness to 0.15 for puddle reflections
## - Time warp and preset locks (Clear Noon, Sunset, Night, Drizzle)

signal hour_changed(in_game_hour: int)
signal weather_preset_changed(preset_name: String)

@export var day_length_seconds: float = 600.0 # 10 real minutes = 24 in-game hours
@export var current_time_hours: float = 17.5 # Starts at dramatic Golden Hour (5:30 PM)
@export var current_preset: String = UrbanConstants.WEATHER_GOLDEN_SUNSET
@export var is_time_paused: bool = false

var sun_light: DirectionalLight3D = null
var moon_light: DirectionalLight3D = null
var world_environment: WorldEnvironment = null

var _last_reported_hour: int = -1
var wetness_factor: float = 0.0 # 0.0 (bone dry) to 1.0 (storm puddles)

func _init() -> void:
	_setup_celestial_lights()
	_setup_environment()
	apply_preset(current_preset)

func _ready() -> void:
	_setup_celestial_lights()
	_setup_environment()
	apply_preset(current_preset)

func _setup_celestial_lights() -> void:
	sun_light = get_node_or_null("SunLight")
	if not sun_light:
		sun_light = DirectionalLight3D.new()
		sun_light.name = "SunLight"
		sun_light.shadow_enabled = true
		sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun_light.directional_shadow_max_distance = 250.0
		add_child(sun_light)

	moon_light = get_node_or_null("MoonLight")
	if not moon_light:
		moon_light = DirectionalLight3D.new()
		moon_light.name = "MoonLight"
		moon_light.shadow_enabled = false
		moon_light.light_color = Color(0.45, 0.55, 0.75)
		moon_light.light_energy = 0.25
		add_child(moon_light)

func _setup_environment() -> void:
	world_environment = get_node_or_null("WorldEnv")
	if not world_environment:
		world_environment = WorldEnvironment.new()
		world_environment.name = "WorldEnv"
		var env = Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.55, 0.68, 0.85)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.35, 0.38, 0.45)
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.glow_enabled = true
		env.glow_intensity = 0.4
		env.glow_bloom = 0.15
		world_environment.environment = env
		add_child(world_environment)

func _physics_process(delta: float) -> void:
	if not is_time_paused:
		# Advance time
		var hours_per_sec = 24.0 / maxf(10.0, day_length_seconds)
		current_time_hours = fposmod(current_time_hours + (hours_per_sec * delta), 24.0)

	_update_lighting_for_time()

	var int_hour = int(floor(current_time_hours))
	if int_hour != _last_reported_hour:
		_last_reported_hour = int_hour
		hour_changed.emit(int_hour)

func _update_lighting_for_time() -> void:
	var sun_angle = ((current_time_hours - 6.0) / 24.0) * TAU
	var sun_elev = sin(sun_angle)
	var sun_azimuth = cos(sun_angle)

	if is_instance_valid(sun_light):
		sun_light.rotation = Vector3(-asin(clampf(sun_elev, -1.0, 1.0)), -atan2(sun_azimuth, 0.8), 0)

		# Sun energy and color based on altitude
		if sun_elev > 0.05:
			# Daytime
			sun_light.visible = true
			if current_time_hours >= 17.0 and current_time_hours <= 19.5:
				# Golden Hour Sunset (Screenshots 1 & 4)
				var t = (current_time_hours - 17.0) / 2.5
				sun_light.light_color = Color(1.0, 0.65, 0.28).lerp(Color(0.95, 0.35, 0.18), t)
				sun_light.light_energy = lerpf(2.2, 1.2, t)
			else:
				# Normal Daylight
				sun_light.light_color = Color(1.0, 0.98, 0.92)
				sun_light.light_energy = clampf(sun_elev * 2.5, 0.4, 2.0)
		else:
			# Night
			sun_light.visible = false
			sun_light.light_energy = 0.0

	if is_instance_valid(moon_light):
		moon_light.visible = (sun_elev <= 0.05)
		moon_light.rotation = Vector3(deg_to_rad(45.0), deg_to_rad(135.0), 0)

	# Atmospheric sky color
	if is_instance_valid(world_environment) and world_environment.environment:
		var env = world_environment.environment
		if current_time_hours >= 17.0 and current_time_hours <= 19.5:
			# Sunset Amber
			env.background_color = Color(0.95, 0.52, 0.22)
			env.ambient_light_color = Color(0.55, 0.38, 0.28)
		elif current_time_hours >= 20.0 or current_time_hours < 5.5:
			# Neon Night
			env.background_color = Color(0.04, 0.06, 0.12)
			env.ambient_light_color = Color(0.12, 0.15, 0.22)
		else:
			# Clear Day
			env.background_color = Color(0.50, 0.68, 0.88)
			env.ambient_light_color = Color(0.38, 0.42, 0.48)

func apply_preset(preset_name: String) -> void:
	if not is_instance_valid(sun_light):
		_setup_celestial_lights()
	if not is_instance_valid(world_environment):
		_setup_environment()
	current_preset = preset_name
	match preset_name:
		UrbanConstants.WEATHER_CLEAR_NOON:
			current_time_hours = 12.0
			wetness_factor = 0.0
		UrbanConstants.WEATHER_GOLDEN_SUNSET:
			current_time_hours = 18.0
			wetness_factor = 0.0
		UrbanConstants.WEATHER_NEON_NIGHT:
			current_time_hours = 22.5
			wetness_factor = 0.0
		UrbanConstants.WEATHER_OVERCAST_DRIZZLE:
			current_time_hours = 14.0
			wetness_factor = 0.85
		_:
			current_time_hours = 18.0

	_update_lighting_for_time()
	weather_preset_changed.emit(preset_name)

func set_time(hours: float) -> void:
	current_time_hours = clampf(hours, 0.0, 24.0)
	_update_lighting_for_time()

func get_formatted_clock() -> String:
	var h = int(floor(current_time_hours))
	var m = int(floor((current_time_hours - float(h)) * 60.0))
	return "%02d:%02d" % [h, m]

func get_wetness_factor() -> float:
	return wetness_factor

func is_night() -> bool:
	return current_time_hours >= 20.0 or current_time_hours < 5.5
