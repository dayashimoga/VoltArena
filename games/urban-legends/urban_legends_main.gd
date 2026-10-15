class_name UrbanLegendsMain
extends Node3D

## Master Scene Controller for Urban Legends: Production-Grade Open-World Driving Game.
## Assembles and orchestrates:
## - Contiguous 2000m x 2000m procedural open world across 8 coherent districts
## - 4-wheel raycast vehicle physics, audio synthesis, and visual archetype meshes
## - Critically damped chase camera with pitch leveling and obstacle raycast culling
## - Dynamic 24-hr day/night cycle with golden hour sunset & wet road reflections
## - Metropolitan civilian traffic AI with waypoint navigation and obstacle avoidance
## - Stunt detector (big air, spins, barrel rolls, drift combos) and 6 mission archetypes
## - Full telemetry HUD, circular minimap, garage tuning kiosk, and district map

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanEvents = preload("res://games/urban-legends/core/urban_events.gd")
const UrbanSaveData = preload("res://games/urban-legends/core/urban_save_data.gd")
const UrbanDistrictDefinitions = preload("res://games/urban-legends/world/urban_district_definitions.gd")
const UrbanRoadNetwork = preload("res://games/urban-legends/world/urban_road_network.gd")
const UrbanWorldGenerator = preload("res://games/urban-legends/world/urban_world_generator.gd")
const UrbanWeatherSystem = preload("res://games/urban-legends/world/urban_weather_system.gd")
const UrbanVehicle = preload("res://games/urban-legends/vehicles/urban_vehicle.gd")
const UrbanVehicleVisuals = preload("res://games/urban-legends/vehicles/urban_vehicle_visuals.gd")
const UrbanVehicleAudio = preload("res://games/urban-legends/vehicles/urban_vehicle_audio.gd")
const UrbanChaseCamera = preload("res://games/urban-legends/vehicles/urban_chase_camera.gd")
const TrafficManager = preload("res://games/urban-legends/traffic/traffic_manager.gd")
const StuntDetector = preload("res://games/urban-legends/gameplay/stunt_detector.gd")
const UrbanMissionDirector = preload("res://games/urban-legends/gameplay/mission_director.gd")
const ProgressionManager = preload("res://games/urban-legends/gameplay/progression_manager.gd")

const UrbanHUD = preload("res://games/urban-legends/ui/urban_hud.gd")
const UrbanGarageMenu = preload("res://games/urban-legends/ui/urban_garage_menu.gd")
const UrbanMapMenu = preload("res://games/urban-legends/ui/urban_map_menu.gd")
const UrbanPauseMenu = preload("res://games/urban-legends/ui/urban_pause_menu.gd")

# Subsystem Instances
var world_generator: UrbanWorldGenerator = null
var weather_system: UrbanWeatherSystem = null
var road_network: UrbanRoadNetwork = null
var player_vehicle: UrbanVehicle = null
var chase_camera: UrbanChaseCamera = null
var traffic_manager: TrafficManager = null
var stunt_detector: StuntDetector = null
var mission_director: UrbanMissionDirector = null
var progression_manager: ProgressionManager = null
var save_data: UrbanSaveData = null

# UI Subsystems
var hud: UrbanHUD = null
var garage_menu: UrbanGarageMenu = null
var map_menu: UrbanMapMenu = null
var pause_menu: UrbanPauseMenu = null

var is_paused: bool = false
var is_in_garage: bool = false
var is_in_map: bool = false

func _ready() -> void:
	_init_save_and_progression()
	_build_world_environment()
	_spawn_player_vehicle()
	_setup_traffic_ai()
	_setup_gameplay_and_stunts()
	_setup_ui_overlays()
	_connect_subsystem_events()

func _init_save_and_progression() -> void:
	save_data = UrbanSaveData.new()
	progression_manager = ProgressionManager.new(save_data)

func _build_world_environment() -> void:
	# Weather & Lighting System (Golden Sunset preset by default)
	weather_system = UrbanWeatherSystem.new()
	weather_system.name = "WeatherSystem"
	add_child(weather_system)

	# World Generator & Road Network
	world_generator = UrbanWorldGenerator.new()
	world_generator.name = "WorldGenerator"
	add_child(world_generator)
	world_generator.generate_world()

	road_network = world_generator.road_network

func _spawn_player_vehicle() -> void:
	player_vehicle = UrbanVehicle.new()
	player_vehicle.name = "PlayerVehicle"
	player_vehicle.vehicle_id = save_data.current_vehicle_id

	# Spawn at Downtown Metro origin
	var spawn_pos = Vector3(-100.0, 1.2, -150.0)
	player_vehicle.position = spawn_pos
	add_child(player_vehicle)

	# Apply Upgrades & Custom Color
	player_vehicle.apply_upgrades(save_data.vehicle_upgrades.get(player_vehicle.vehicle_id, {}))
	var col = save_data.get_vehicle_color(player_vehicle.vehicle_id)
	UrbanVehicleVisuals.build_vehicle_visual(player_vehicle, player_vehicle.vehicle_id, col)

	# Chase Camera
	chase_camera = UrbanChaseCamera.new()
	chase_camera.name = "UrbanChaseCamera"
	chase_camera.position = spawn_pos + Vector3(0, 3.0, 7.0)
	add_child(chase_camera)
	chase_camera.set_target(player_vehicle)

func _setup_traffic_ai() -> void:
	traffic_manager = TrafficManager.new()
	traffic_manager.name = "TrafficManager"
	add_child(traffic_manager)
	traffic_manager.setup_traffic(road_network, player_vehicle, 14)

func _setup_gameplay_and_stunts() -> void:
	stunt_detector = StuntDetector.new()
	stunt_detector.setup(player_vehicle, save_data)

	mission_director = UrbanMissionDirector.new()
	mission_director.name = "MissionDirector"
	add_child(mission_director)
	mission_director.setup(player_vehicle, save_data)

func _setup_ui_overlays() -> void:
	# Telemetry HUD
	hud = UrbanHUD.new()
	hud.name = "UrbanHUD"
	add_child(hud)
	hud.setup(player_vehicle, road_network, weather_system)

	# Garage Menu
	garage_menu = UrbanGarageMenu.new()
	garage_menu.name = "UrbanGarageMenu"
	garage_menu.visible = false
	add_child(garage_menu)
	garage_menu.setup(save_data, progression_manager)

	# District Map Menu
	map_menu = UrbanMapMenu.new()
	map_menu.name = "UrbanMapMenu"
	map_menu.visible = false
	add_child(map_menu)
	map_menu.setup(save_data, road_network, player_vehicle)

	# Pause Menu
	pause_menu = UrbanPauseMenu.new()
	pause_menu.name = "UrbanPauseMenu"
	pause_menu.visible = false
	add_child(pause_menu)

func _connect_subsystem_events() -> void:
	# Stunt Rewards -> HUD toast
	stunt_detector.stunt_rewarded.connect(func(title: String, cash: int, _details: Dictionary):
		if hud:
			hud.show_stunt_reward(title, cash)
			hud.update_wallet(save_data.career_cash)
	)

	# Garage events
	garage_menu.vehicle_selected.connect(_on_garage_vehicle_changed)
	garage_menu.vehicle_customized.connect(_on_garage_vehicle_customized)
	garage_menu.garage_closed.connect(_close_garage)

	# Map events
	map_menu.fast_travel_requested.connect(_on_fast_travel)
	map_menu.map_closed.connect(_close_map)

	# Pause menu events
	pause_menu.resume_requested.connect(_toggle_pause)
	pause_menu.reset_vehicle_requested.connect(_on_reset_vehicle)
	pause_menu.open_garage_requested.connect(_open_garage)
	pause_menu.open_map_requested.connect(_open_map)
	pause_menu.quit_to_launcher_requested.connect(_on_quit_to_launcher)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player_vehicle):
		return

	# Surface friction & input handling
	var p_pos = player_vehicle.global_position if player_vehicle.is_inside_tree() else player_vehicle.position
	if road_network:
		var s_fric = road_network.get_surface_friction_at_point(p_pos)
		player_vehicle.surface_friction = s_fric

	if stunt_detector:
		stunt_detector.process_stunt_frame(_delta)

	# Sync Touch Controls to Player Vehicle
	if hud and hud.touch_controls_root and hud.touch_controls_root.visible:
		var t_steer = hud.touch_steer
		var t_throt = hud.touch_throttle
		var t_brk = hud.touch_brake
		var t_hand = hud.touch_handbrake
		var t_nit = hud.touch_nitro
		player_vehicle.set_inputs(t_steer, t_throt, t_brk, t_hand, t_nit)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if is_in_garage:
			_close_garage()
		elif is_in_map:
			_close_map()
		else:
			_toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_M:
		if not is_in_garage and not is_paused:
			if is_in_map:
				_close_map()
			else:
				_open_map()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if not is_paused and not is_in_garage and not is_in_map:
			_on_reset_vehicle()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_C:
		if chase_camera:
			chase_camera.cycle_camera_mode()
			get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	is_paused = not is_paused
	pause_menu.visible = is_paused
	Engine.time_scale = 0.0 if is_paused else 1.0

func _open_garage() -> void:
	if is_paused:
		_toggle_pause()
	is_in_garage = true
	garage_menu.visible = true
	garage_menu._refresh_display()
	Engine.time_scale = 0.0

func _close_garage() -> void:
	is_in_garage = false
	garage_menu.visible = false
	Engine.time_scale = 1.0

func _open_map() -> void:
	if is_paused:
		_toggle_pause()
	is_in_map = true
	map_menu.visible = true
	map_menu.select_district(map_menu.selected_district_id)
	Engine.time_scale = 0.0

func _close_map() -> void:
	is_in_map = false
	map_menu.visible = false
	Engine.time_scale = 1.0

func _on_reset_vehicle() -> void:
	if player_vehicle:
		player_vehicle.recover_vehicle()

func _on_fast_travel(dest: Vector3) -> void:
	if player_vehicle:
		player_vehicle.global_position = dest + Vector3(0, 1.5, 0)
		player_vehicle.linear_velocity = Vector3.ZERO
		player_vehicle.angular_velocity = Vector3.ZERO
		player_vehicle.forward_speed = 0.0
		if chase_camera:
			chase_camera.position = dest + Vector3(0, 3.5, 7.0)

func _on_garage_vehicle_changed(veh_id: String) -> void:
	if player_vehicle:
		player_vehicle.vehicle_id = veh_id
		player_vehicle.apply_upgrades(save_data.vehicle_upgrades.get(veh_id, {}))
		var old_chassis = player_vehicle.get_node_or_null("ChassisMeshRoot")
		if old_chassis:
			old_chassis.queue_free()
		var col = save_data.get_vehicle_color(veh_id)
		UrbanVehicleVisuals.build_vehicle_visual(player_vehicle, veh_id, col)

func _on_garage_vehicle_customized(veh_id: String) -> void:
	if player_vehicle and player_vehicle.vehicle_id == veh_id:
		player_vehicle.apply_upgrades(save_data.vehicle_upgrades.get(veh_id, {}))
		var old_chassis = player_vehicle.get_node_or_null("ChassisMeshRoot")
		if old_chassis:
			old_chassis.queue_free()
		var col = save_data.get_vehicle_color(veh_id)
		UrbanVehicleVisuals.build_vehicle_visual(player_vehicle, veh_id, col)

func _on_quit_to_launcher() -> void:
	Engine.time_scale = 1.0
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.return_to_launcher_requested.emit()
