class_name WorldBase
extends Node3D

## Base class for 3D worlds in Chroma Rush
## Provides road spline waypoint networks, checkpoint management,
## realistic lighting, asphalt roads with lane markings, curbs, sidewalks,
## and environment prop coordination.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const CheckpointGate = preload("res://games/chroma-rush/worlds/checkpoint_gate.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const ModelCache = preload("res://shared/graphics/model_cache.gd")
const MaterialGenerator = preload("res://shared/graphics/material_generator.gd")

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

# Shared PBR Road Materials
var mat_asphalt: StandardMaterial3D
var mat_curb: StandardMaterial3D
var mat_sidewalk: StandardMaterial3D
var mat_marking_white: StandardMaterial3D
var mat_marking_yellow: StandardMaterial3D

func _ready() -> void:
	_init_materials()

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

func _init_materials() -> void:
	mat_asphalt = StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.14, 0.14, 0.16) # Dark road asphalt
	mat_asphalt.roughness = 0.84
	mat_asphalt.metallic = 0.05

	mat_curb = StandardMaterial3D.new()
	mat_curb.albedo_color = Color(0.48, 0.50, 0.52) # Concrete curb
	mat_curb.roughness = 0.90

	mat_sidewalk = StandardMaterial3D.new()
	mat_sidewalk.albedo_color = Color(0.60, 0.62, 0.65) # Paved sidewalk
	mat_sidewalk.roughness = 0.88

	mat_marking_white = StandardMaterial3D.new()
	mat_marking_white.albedo_color = Color(0.92, 0.94, 0.96)
	mat_marking_white.roughness = 0.60

	mat_marking_yellow = StandardMaterial3D.new()
	mat_marking_yellow.albedo_color = Color(0.95, 0.80, 0.10)
	mat_marking_yellow.roughness = 0.60

func build_world() -> void:
	setup_lighting()
	setup_ground_plane()
	generate_waypoints()
	build_road_mesh()
	build_checkpoints()
	build_props()

func setup_lighting() -> void:
	if not world_environment:
		world_environment = WorldEnvironment.new()
		world_environment.name = "WorldEnv"
		var env = Environment.new()
		env.background_mode = Environment.BG_SKY

		var sky = Sky.new()
		var sky_mat = ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.24, 0.46, 0.86)       # Daylight azure blue
		sky_mat.sky_horizon_color = Color(0.68, 0.78, 0.90)   # Atmospheric horizon
		sky_mat.ground_bottom_color = Color(0.12, 0.14, 0.16) # Dark city terrain base
		sky_mat.ground_horizon_color = Color(0.58, 0.68, 0.78)
		sky_mat.sun_angle_max = 30.0
		sky.sky_material = sky_mat
		env.sky = sky

		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 1.15
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_exposure = 1.05
		env.glow_enabled = true
		env.glow_intensity = 0.4
		env.glow_bloom = 0.15
		env.fog_enabled = true
		env.fog_light_color = Color(0.68, 0.76, 0.86)
		env.fog_density = 0.0012
		world_environment.environment = env
		add_child(world_environment)

	if not sun_light:
		sun_light = DirectionalLight3D.new()
		sun_light.name = "SunLight"
		sun_light.rotation_degrees = Vector3(-45, -35, 0)
		sun_light.light_color = Color(1.0, 0.97, 0.92)
		sun_light.light_energy = 1.45
		sun_light.shadow_enabled = true
		sun_light.shadow_bias = 0.03
		add_child(sun_light)

func setup_ground_plane() -> void:
	# Solid city foundation terrain plane so roads never hover above empty void
	var ground = StaticBody3D.new()
	ground.name = "CityGroundPlane"
	ground.collision_layer = GameConstants.LAYER_WORLD

	var mi = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(1600, 1600)
	mi.mesh = plane_mesh

	var mat_ground = StandardMaterial3D.new()
	mat_ground.albedo_color = Color(0.10, 0.11, 0.13)
	mat_ground.roughness = 0.95
	mi.material_override = mat_ground
	ground.add_child(mi)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1600, 1.0, 1600)
	col.shape = shape
	col.position = Vector3(0, -0.5, 0)
	ground.add_child(col)

	props_container.add_child(ground)

func generate_waypoints() -> void:
	pass

func build_road_mesh() -> void:
	pass

func build_checkpoints() -> void:
	pass

func build_props() -> void:
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

## Creates an authentic multi-lane asphalt road segment with
## dashed centerlines, solid edge lines, curbs, and sidewalks.
func add_road_segment(start_pos: Vector3, end_pos: Vector3, road_width: float = 14.0) -> void:
	var segment = StaticBody3D.new()
	segment.name = "RoadSegment"
	segment.collision_layer = GameConstants.LAYER_WORLD

	var dir = end_pos - start_pos
	var length = dir.length()
	if length < 0.1:
		return
	var center = (start_pos + end_pos) * 0.5
	var norm_dir = dir.normalized()
	var right = Vector3(-norm_dir.z, 0, norm_dir.x).normalized()

	# 1. Main Asphalt Road Surface
	var road_mi = MeshInstance3D.new()
	var road_mesh = BoxMesh.new()
	road_mesh.size = Vector3(road_width, 0.4, length)
	road_mi.mesh = road_mesh
	road_mi.material_override = mat_asphalt
	segment.add_child(road_mi)

	# 2. Main Road Collider
	var col = CollisionShape3D.new()
	var col_shape = BoxShape3D.new()
	col_shape.size = Vector3(road_width, 0.4, length)
	col.shape = col_shape
	segment.add_child(col)

	# 3. Yellow Dashed Centerline Markings
	var dash_length = 3.5
	var dash_gap = 2.5
	var total_period = dash_length + dash_gap
	var dash_count = int(length / total_period)
	for d in range(dash_count):
		var z_offset = -length * 0.5 + d * total_period + dash_length * 0.5 + 1.0
		var dash_mi = MeshInstance3D.new()
		var dash_box = BoxMesh.new()
		dash_box.size = Vector3(0.24, 0.02, dash_length)
		dash_mi.mesh = dash_box
		dash_mi.material_override = mat_marking_yellow
		dash_mi.position = Vector3(0.0, 0.21, z_offset)
		segment.add_child(dash_mi)

	# 4. White Solid Road Shoulder / Edge Lines
	for side in [-1.0, 1.0]:
		var edge_mi = MeshInstance3D.new()
		var edge_box = BoxMesh.new()
		edge_box.size = Vector3(0.20, 0.02, length)
		edge_mi.mesh = edge_box
		edge_mi.material_override = mat_marking_white
		edge_mi.position = Vector3(side * (road_width * 0.5 - 0.4), 0.21, 0.0)
		segment.add_child(edge_mi)

	# 5. Raised Curbs and Concrete Sidewalks on Both Flanks
	var sidewalk_width = 2.4
	for side in [-1.0, 1.0]:
		var sw_x = side * (road_width * 0.5 + sidewalk_width * 0.5)

		# Raised Sidewalk Slab
		var sw_mi = MeshInstance3D.new()
		var sw_box = BoxMesh.new()
		sw_box.size = Vector3(sidewalk_width, 0.55, length)
		sw_mi.mesh = sw_box
		sw_mi.material_override = mat_sidewalk
		sw_mi.position = Vector3(sw_x, 0.08, 0.0)
		segment.add_child(sw_mi)

		# Curb Stone Line
		var curb_x = side * (road_width * 0.5 + 0.15)
		var curb_mi = MeshInstance3D.new()
		var curb_box = BoxMesh.new()
		curb_box.size = Vector3(0.30, 0.60, length)
		curb_mi.mesh = curb_box
		curb_mi.material_override = mat_curb
		curb_mi.position = Vector3(curb_x, 0.10, 0.0)
		segment.add_child(curb_mi)

	# Position & Orient Segment along road trajectory
	segment.position = center
	segment.look_at_from_position(center, center + dir, Vector3.UP)
	road_container.add_child(segment)
