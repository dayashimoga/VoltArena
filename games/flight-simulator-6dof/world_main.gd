class_name FlightSimWorldMain
extends Node3D

## World coordinator for the 6-DoF Aircraft Flight Simulator.
## Integrates atmospheric lighting, runway system, terrain, aircraft physics,
## floating origin rebasing, and mission flight director.

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var terrain_system: Node3D = $TerrainSystem
@onready var runway_complex: Node3D = $RunwayComplex
@onready var aircraft_rig: AircraftController = $AircraftRig
@onready var floating_origin: FloatingOrigin = $FloatingOrigin

var flight_director: Node3D

func _ready() -> void:
	Engine.physics_ticks_per_second = 120
	Engine.max_physics_steps_per_frame = 16
	_setup_camera_hud_binding()
	_setup_floating_origin()
	_setup_flight_director()

func _exit_tree() -> void:
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 8

func _setup_camera_hud_binding() -> void:
	if not aircraft_rig:
		return
	var hud = aircraft_rig.get_node_or_null("CockpitHUDLayer/CockpitHUD") as CockpitHUD
	if hud:
		hud.aircraft = aircraft_rig
		hud.camera = aircraft_rig.cockpit_camera

func _setup_floating_origin() -> void:
	if not floating_origin or not aircraft_rig:
		return
	floating_origin.target_node = aircraft_rig
	if terrain_system:
		floating_origin.register_shifting_node(terrain_system)
	if runway_complex:
		floating_origin.register_shifting_node(runway_complex)

func _setup_flight_director() -> void:
	var director_script = load("res://games/flight-simulator-6dof/flight_school_director.gd")
	if director_script:
		flight_director = director_script.new()
		flight_director.name = "FlightSchoolDirector"
		flight_director.aircraft = aircraft_rig
		add_child(flight_director)
