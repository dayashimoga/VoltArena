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
		env.background_mode = Environment.BG_SKY

		var sky = Sky.new()
		var sky_mat = ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.35, 0.55, 0.85)
		sky_mat.sky_horizon_color = Color(0.85, 0.65, 0.45)
		sky_mat.ground_bottom_color = Color(0.12, 0.14, 0.16)
		sky_mat.ground_horizon_color = Color(0.32, 0.35, 0.40)
		sky_mat.sun_angle_max = 30.0
		sky.sky_material = sky_mat
		env.sky = sky

		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_color = Color(0.50, 0.52, 0.55)
		env.ambient_light_sky_contribution = 0.65
		env.ambient_light_energy = 1.05
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.15
		env.glow_enabled = false
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		env.fog_density = 0.00030
		env.fog_light_color = Color(0.72, 0.76, 0.82)
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
	# Solar orbital cycle: Sunrise ~05:30, Noon ~12:30, Golden Sunset ~17:30-19:30, Dusk ~19:30-20:30, Night ~20:30-05:00
	var is_daytime = (current_time_hours >= 5.5 and current_time_hours < 20.0)
	var is_sunset = (current_time_hours >= 17.0 and current_time_hours < 20.0)

	var sun_rad = ((current_time_hours - 5.5) / 14.5) * PI
	var sun_elev = sin(clampf(sun_rad, 0.0, PI)) if is_daytime else -0.3
	var sun_azimuth = cos(clampf(sun_rad, 0.0, PI))

	if is_instance_valid(sun_light):
		if is_daytime:
			sun_light.visible = true
			sun_light.rotation = Vector3(-asin(clampf(maxf(sun_elev, 0.08), -1.0, 1.0)), -atan2(sun_azimuth, 0.8), 0)

			if is_sunset:
				# Golden Hour Sunset: Warm amber radiance, elongated shadows, visible sun
				var t = (current_time_hours - 17.0) / 3.0
				sun_light.light_color = Color(1.0, 0.72, 0.38).lerp(Color(0.96, 0.48, 0.22), t)
				sun_light.light_energy = lerpf(1.9, 1.25, t)
			else:
				# High Daylight
				sun_light.light_color = Color(1.0, 0.98, 0.92)
				sun_light.light_energy = clampf(sun_elev * 2.2, 0.8, 1.9)
		else:
			# Nighttime: deactivate direct sun
			sun_light.visible = false
			sun_light.light_energy = 0.0

	if is_instance_valid(moon_light):
		moon_light.visible = not is_daytime or (current_time_hours >= 19.5 or current_time_hours < 6.0)
		moon_light.rotation = Vector3(deg_to_rad(45.0), deg_to_rad(135.0), 0)
		moon_light.light_energy = 0.55 if not is_daytime else 0.15

	# Update Sky & Ambient colors dynamically
	if is_instance_valid(world_environment) and world_environment.environment:
		var env = world_environment.environment
		var sky_mat = env.sky.sky_material as ProceduralSkyMaterial if (env.sky and env.sky.sky_material is ProceduralSkyMaterial) else null

		if is_sunset:
			# Sunset Palette
			var t_s = (current_time_hours - 17.0) / 3.0
			var top_c = Color(0.22, 0.38, 0.65).lerp(Color(0.15, 0.20, 0.40), t_s)
			var horiz_c = Color(0.98, 0.58, 0.25).lerp(Color(0.88, 0.38, 0.20), t_s)
			if sky_mat:
				sky_mat.sky_top_color = top_c
				sky_mat.sky_horizon_color = horiz_c
				sky_mat.ground_horizon_color = horiz_c * 0.55
			env.ambient_light_color = horiz_c * 0.75
			env.ambient_light_energy = lerpf(0.95, 0.70, t_s)
			env.fog_light_color = horiz_c * 0.85
		elif not is_daytime:
			# Neon Night Palette
			if sky_mat:
				sky_mat.sky_top_color = Color(0.04, 0.06, 0.14)
				sky_mat.sky_horizon_color = Color(0.10, 0.14, 0.25)
				sky_mat.ground_horizon_color = Color(0.06, 0.08, 0.15)
			env.ambient_light_color = Color(0.30, 0.35, 0.48)
			env.ambient_light_energy = 0.38 # Calibrated night ambient light energy
			env.tonemap_exposure = 1.20 # Calibrated tonemap exposure preventing black voids
			env.fog_light_color = Color(0.12, 0.16, 0.28)
		else:
			# Clear Day Palette
			if sky_mat:
				sky_mat.sky_top_color = Color(0.35, 0.58, 0.90)
				sky_mat.sky_horizon_color = Color(0.70, 0.82, 0.92)
				sky_mat.ground_horizon_color = Color(0.38, 0.42, 0.46)
			env.ambient_light_color = Color(0.52, 0.55, 0.60)
			env.ambient_light_energy = 1.05
			env.tonemap_exposure = 1.15
			env.fog_light_color = Color(0.70, 0.78, 0.88)

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
