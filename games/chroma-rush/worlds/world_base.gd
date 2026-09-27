class_name WorldBase
extends Node3D

## Base class for 3D worlds in Chroma Rush
## Provides road spline waypoint networks, checkpoint management,
## environment setup, and traffic spawn coordination.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const CheckpointGate = preload("res://games/chroma-rush/worlds/checkpoint_gate.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")

signal objective_checkpoint_cleared(gate: CheckpointGate, vehicle: ChromaVehicle)

@export var world_id: String = ChromaConstants.WORLD_NEON_CITY
@export var world_name: String = "Neon City"

var waypoints: Array[Vector3] = []
var checkpoints: Array[CheckpointGate] = []
var player_spawn_transform: Transform3D = Transform3D.IDENTITY
var traffic_spawn_data: Array[Dictionary] = []

var road_container: Node3D
var props_container: Node3D
var gates_container: Node3D
var world_environment: WorldEnvironment
var sun_light: DirectionalLight3D

func _ready() -> void:
	road_container = Node3D.new()
	road_container.name = "RoadNetwork"
	add_child(road_container)

	props_container = Node3D.new()
	props_container.name = "EnvironmentProps"
	add_child(props_container)

	gates_container = Node3D.new()
	gates_container.name = "CheckpointGates"
	add_child(gates_container)

	build_world()

func build_world() -> void:
	# Overridden in child classes
	setup_lighting()
	generate_waypoints()
	build_road_mesh()
	build_checkpoints()
	build_props()

func setup_lighting() -> void:
	if not world_environment:
		world_environment = WorldEnvironment.new()
		world_environment.name = "WorldEnv"
		var env = Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.04, 0.05, 0.08)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.35, 0.40, 0.50)
		env.ambient_light_energy = 1.0
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.glow_enabled = true
		env.glow_intensity = 0.8
		env.glow_bloom = 0.25
		world_environment.environment = env
		add_child(world_environment)

	if not sun_light:
		sun_light = DirectionalLight3D.new()
		sun_light.name = "SunLight"
		sun_light.rotation_degrees = Vector3(-45, -30, 0)
		sun_light.light_color = Color(0.95, 0.92, 1.0)
		sun_light.light_energy = 1.2
		sun_light.shadow_enabled = true
		add_child(sun_light)

func generate_waypoints() -> void:
	# Overridden in child classes to populate waypoints array
	pass

func build_road_mesh() -> void:
	# Overridden in child classes
	pass

func build_checkpoints() -> void:
	# Overridden in child classes
	pass

func build_props() -> void:
	# Overridden in child classes
	pass

func get_nearest_waypoint_index(pos: Vector3) -> int:
	if waypoints.is_empty():
		return 0
	var best_idx = 0
	var best_dist = pos.distance_squared_to(waypoints[0])
	for i in range(1, waypoints.size()):
		var d = pos.distance_squared_to(waypoints[i])
		if d < best_dist:
			best_dist = d
			best_idx = i
	return best_idx

func get_waypoint(idx: int) -> Vector3:
	if waypoints.is_empty():
		return Vector3.ZERO
	return waypoints[idx % waypoints.size()]

func get_total_waypoints() -> int:
	return waypoints.size()

func get_checkpoint(idx: int) -> CheckpointGate:
	if checkpoints.is_empty():
		return null
	return checkpoints[idx % checkpoints.size()]

func get_checkpoint_by_id(p_id: String) -> CheckpointGate:
	for cp in checkpoints:
		if cp.gate_id == p_id:
			return cp
	return null

func add_road_segment(start_pos: Vector3, end_pos: Vector3, width: float = 14.0) -> void:
	var segment = StaticBody3D.new()
	segment.name = "RoadSegment"
	segment.collision_layer = GameConstants.LAYER_WORLD

	var dir = (end_pos - start_pos)
	var length = dir.length()
	var center = (start_pos + end_pos) * 0.5

	# Visual Box Mesh
	var mi = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, 0.4, length)
	mi.mesh = box_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.13, 0.16) # Dark asphalt
	mat.roughness = 0.85
	mi.material_override = mat
	segment.add_child(mi)

	# Collision Shape
	var col = CollisionShape3D.new()
	var col_shape = BoxShape3D.new()
	col_shape.size = Vector3(width, 0.4, length)
	col.shape = col_shape
	segment.add_child(col)

	# Position & Orient
	segment.position = center
	if length > 0.01:
		segment.look_at_from_position(center, center + dir, Vector3.UP)

	road_container.add_child(segment)
