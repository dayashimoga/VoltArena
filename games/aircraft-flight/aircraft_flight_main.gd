class_name AircraftFlightMain
extends Node3D

## AircraftFlightMain: Primary Orchestrator & State Machine for Apex Flight: Open Skies.
## Coordinates hangar selection, open-world loading, flight physics, camera tracking,
## HUD telemetry, mission objectives, and pause/results workflows.

const FlightConst = preload("res://games/aircraft-flight/core/flight_constants.gd")
const FlightPhysicsScript = preload("res://games/aircraft-flight/core/flight_physics.gd")
const FlightCameraScript = preload("res://games/aircraft-flight/core/flight_camera_controller.gd")
const AircraftCatalog = preload("res://games/aircraft-flight/aircraft/aircraft_catalog.gd")
const AircraftMeshBuilder = preload("res://games/aircraft-flight/aircraft/aircraft_mesh_builder.gd")
const AircraftVisualsScript = preload("res://games/aircraft-flight/aircraft/aircraft_visuals.gd")
const FlightWorldManagerScript = preload("res://games/aircraft-flight/worlds/flight_world_manager.gd")
const FlightHUDScript = preload("res://games/aircraft-flight/ui/flight_hud.gd")
const FlightResultsScript = preload("res://games/aircraft-flight/ui/flight_results_screen.gd")
const FlightHangarScript = preload("res://games/aircraft-flight/ui/hangar_menu.gd")
const FlightAutopilotScript = preload("res://games/aircraft-flight/core/flight_autopilot.gd")
const MissionDirectorScript = preload("res://games/aircraft-flight/missions/flight_mission_director.gd")
const MissionDefs = preload("res://games/aircraft-flight/missions/mission_definitions.gd")

enum GameState {
	HANGAR,
	FLIGHT,
	PAUSED,
	RESULTS
}

var current_state: GameState = GameState.HANGAR

# Core Subsystems
var world_manager: Node3D
var player_aircraft: CharacterBody3D
var aircraft_visuals: Node3D
var flight_camera: Node3D
var flight_hud: CanvasLayer
var results_screen: CanvasLayer
var hangar_menu: CanvasLayer
var autopilot: RefCounted
var mission_director: Node

# Session Configuration
var selected_aircraft_id: String = "fa18_hornet"
var selected_mission_id: String = "m1_free_flight"
var selected_world_id: String = "metropolitan_city"
var selected_primary_color: Color = Color(0.45, 0.48, 0.52)
var selected_accent_color: Color = Color(0.1, 0.65, 1.0)

# Input accumulation
var throttle_input_rate: float = 0.5 # throttle change per second holding key

func _ready() -> void:
	_setup_subsystems()
	enter_hangar()

func _setup_subsystems() -> void:
	# Autopilot
	autopilot = FlightAutopilotScript.new()

	# Mission Director
	mission_director = MissionDirectorScript.new()
	mission_director.name = "MissionDirector"
	add_child(mission_director)
	mission_director.objective_updated.connect(_on_objective_updated)
	mission_director.mission_completed.connect(_on_mission_completed)
	mission_director.mission_failed.connect(_on_mission_failed)

	# HUD
	flight_hud = FlightHUDScript.new()
	flight_hud.name = "FlightHUD"
	add_child(flight_hud)
	flight_hud.pause_requested.connect(_on_pause_requested)
	flight_hud.camera_toggle_requested.connect(_on_camera_toggle_requested)
	flight_hud.recover_requested.connect(_on_recover_requested)

	# Results Screen
	results_screen = FlightResultsScript.new()
	results_screen.name = "FlightResultsScreen"
	add_child(results_screen)
	results_screen.replay_requested.connect(restart_current_mission)
	results_screen.hangar_requested.connect(enter_hangar)
	results_screen.launcher_requested.connect(_on_exit_to_launcher)

	# Hangar Menu
	hangar_menu = FlightHangarScript.new()
	hangar_menu.name = "FlightHangarMenu"
	add_child(hangar_menu)
	hangar_menu.launch_requested.connect(_on_hangar_launch)
	hangar_menu.exit_requested.connect(_on_exit_to_launcher)

func enter_hangar() -> void:
	current_state = GameState.HANGAR
	_cleanup_flight_session()

	if flight_hud: flight_hud.visible = false
	if results_screen: results_screen.visible = false
	if hangar_menu: hangar_menu.visible = true

func _on_hangar_launch(ac_id: String, m_id: String, w_id: String, p_col: Color, a_col: Color) -> void:
	selected_aircraft_id = ac_id
	selected_mission_id = m_id
	selected_world_id = w_id
	selected_primary_color = p_col
	selected_accent_color = a_col

	start_flight_session()

func start_flight_session() -> void:
	current_state = GameState.FLIGHT
	if hangar_menu: hangar_menu.visible = false
	if results_screen: results_screen.visible = false
	if flight_hud: flight_hud.visible = true

	# 1. Instantiate World Manager
	if not is_instance_valid(world_manager):
		world_manager = FlightWorldManagerScript.new()
		world_manager.name = "WorldManager"
		add_child(world_manager)
	world_manager.load_world(selected_world_id)

	# 2. Instantiate Player Aircraft Physics Body
	if is_instance_valid(player_aircraft):
		player_aircraft.queue_free()

	player_aircraft = FlightPhysicsScript.new()
	player_aircraft.name = "PlayerAircraft"
	var spec = AircraftCatalog.get_aircraft_spec(selected_aircraft_id)
	player_aircraft.setup_aircraft_specs(spec)

	# Collision shape for aircraft
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(spec.get("wingspan", 12.0) * 0.75, 2.2, 8.5)
	col.shape = box
	player_aircraft.add_child(col)

	# Procedural 3D Visual Mesh
	var mesh_root = AircraftMeshBuilder.build_aircraft_visuals(selected_aircraft_id, selected_primary_color, selected_accent_color)
	player_aircraft.add_child(mesh_root)

	# Visual Articulation Controller
	aircraft_visuals = AircraftVisualsScript.new()
	aircraft_visuals.name = "AircraftVisuals"
	aircraft_visuals.aircraft_physics = player_aircraft
	player_aircraft.add_child(aircraft_visuals)

	add_child(player_aircraft)

	# Position aircraft at safe world spawn
	var m_def = MissionDefs.get_mission(selected_mission_id)
	var spawn_info = world_manager.get_spawn_point(m_def.get("spawn_type", "runway_takeoff"))
	player_aircraft.recover_to_safe_flight(
		spawn_info.get("position", Vector3(0, 2.5, 950)),
		spawn_info.get("heading_deg", 0.0),
		spawn_info.get("airspeed_kmh", 0.0),
		spawn_info.get("airborne", false)
	)

	# Connect HUD to aircraft
	if flight_hud:
		flight_hud.aircraft = player_aircraft

	# 3. Setup Camera Controller
	if not is_instance_valid(flight_camera):
		flight_camera = FlightCameraScript.new()
		flight_camera.name = "FlightCamera"
		add_child(flight_camera)
	flight_camera.target_aircraft = player_aircraft
	flight_camera.set_camera_mode(FlightConst.CameraViewMode.CHASE)

	# 4. Start Mission
	mission_director.start_mission(selected_mission_id, player_aircraft, world_manager.active_world_root)

func _physics_process(delta: float) -> void:
	if current_state != GameState.FLIGHT or not is_instance_valid(player_aircraft) or delta <= 0.0:
		return

	# Handle Continuous Flight Inputs
	_handle_flight_inputs(delta)

	# Update Autopilot if enabled
	if autopilot.enabled:
		var auto_cmds = autopilot.update_autopilot(player_aircraft, delta)
		player_aircraft.set_pilot_inputs(auto_cmds.get("pitch", 0.0), auto_cmds.get("roll", 0.0), auto_cmds.get("yaw", 0.0))
		player_aircraft.set_throttle(auto_cmds.get("throttle", player_aircraft.throttle))

	# Update Mission Objectives & Timers
	mission_director.update_mission(delta, player_aircraft)

func _handle_flight_inputs(delta: float) -> void:
	# Pitch (W / S or Up / Down)
	var p_in: float = 0.0
	if Input.is_action_pressed("move_back") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		p_in += 1.0 # Pull back on stick -> Pitch UP
	if Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		p_in -= 1.0 # Push forward on stick -> Pitch DOWN

	# Roll (A / D or Left / Right)
	var r_in: float = 0.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		r_in -= 1.0 # Bank Left
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		r_in += 1.0 # Bank Right

	# Yaw Rudder (Q / E)
	var y_in: float = 0.0
	if Input.is_key_pressed(KEY_Q):
		y_in -= 1.0 # Rudder Left
	if Input.is_key_pressed(KEY_E):
		y_in += 1.0 # Rudder Right

	player_aircraft.set_pilot_inputs(p_in, r_in, y_in)

	# Throttle (Shift = Increase, Ctrl = Decrease)
	if Input.is_key_pressed(KEY_SHIFT):
		player_aircraft.adjust_throttle(throttle_input_rate * delta)
		if player_aircraft.throttle >= 0.98:
			player_aircraft.set_afterburner(true)
	elif Input.is_key_pressed(KEY_CTRL):
		player_aircraft.adjust_throttle(-throttle_input_rate * delta)
		player_aircraft.set_afterburner(false)

	# Brakes / Airbrakes (Space)
	var brake_held = Input.is_key_pressed(KEY_SPACE)
	player_aircraft.set_airbrake(brake_held)
	player_aircraft.set_wheel_brakes(brake_held)

func _unhandled_input(event: InputEvent) -> void:
	if current_state != GameState.FLIGHT:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_G:
				if is_instance_valid(player_aircraft): player_aircraft.toggle_landing_gear()
			KEY_F:
				if is_instance_valid(player_aircraft): player_aircraft.cycle_flaps()
			KEY_V:
				_on_camera_toggle_requested()
			KEY_R:
				_on_recover_requested()
			KEY_P:
				if is_instance_valid(autopilot): autopilot.enabled = not autopilot.enabled
			KEY_ESCAPE:
				_on_pause_requested()

func _on_objective_updated(text: String) -> void:
	if flight_hud:
		flight_hud.set_objective_text(text)

func _on_mission_completed(summary: Dictionary) -> void:
	current_state = GameState.RESULTS
	if flight_hud: flight_hud.visible = false
	if results_screen:
		results_screen.display_results(summary)

func _on_mission_failed(reason: String) -> void:
	current_state = GameState.RESULTS
	if flight_hud: flight_hud.visible = false
	if results_screen:
		results_screen.display_results({
			"title": "Mission Failed",
			"success": false,
			"score": 0,
			"time_s": mission_director.elapsed_time_s,
			"medal": "None"
		})

func restart_current_mission() -> void:
	start_flight_session()

func _on_recover_requested() -> void:
	if is_instance_valid(player_aircraft) and is_instance_valid(world_manager):
		var m_def = MissionDefs.get_mission(selected_mission_id)
		var spawn_info = world_manager.get_spawn_point(m_def.get("spawn_type", "runway_takeoff"))
		player_aircraft.recover_to_safe_flight(
			spawn_info.get("position", Vector3(0, 2.5, 950)),
			spawn_info.get("heading_deg", 0.0),
			spawn_info.get("airspeed_kmh", 0.0),
			spawn_info.get("airborne", false)
		)

func _on_camera_toggle_requested() -> void:
	if flight_camera:
		flight_camera.toggle_camera_mode()

func _on_pause_requested() -> void:
	current_state = GameState.PAUSED
	# Show pause overlay or return to hangar
	enter_hangar()

func _on_exit_to_launcher() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.return_to_launcher_requested.emit()
	else:
		get_tree().change_scene_to_file("res://launcher/launcher.tscn")

func _cleanup_flight_session() -> void:
	if is_instance_valid(player_aircraft):
		player_aircraft.queue_free()
	if is_instance_valid(world_manager):
		world_manager.queue_free()
