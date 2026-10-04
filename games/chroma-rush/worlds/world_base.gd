class_name WorldBase
extends Node3D

## Base class for 3D worlds in Chroma Rush
## Provides authoritative continuous road spline ribbons, seamless trimesh collisions,
## checkpoint management, calibrated PBR lighting, and environment prop coordination.

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

var _is_ready_initialized: bool = false

func _ready() -> void:
	if _is_ready_initialized:
		return
	_is_ready_initialized = true

	add_to_group("chroma_world")
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

var spline_samples: Array[Vector3] = []
var mat_barrier: StandardMaterial3D

func _init_materials() -> void:
	mat_asphalt = StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.12, 0.12, 0.14) # Rich dark textured asphalt
	mat_asphalt.roughness = 0.88
	mat_asphalt.metallic = 0.02

	mat_curb = StandardMaterial3D.new()
	mat_curb.albedo_color = Color(0.38, 0.40, 0.42) # Neutral dark concrete curb
	mat_curb.roughness = 0.88
	mat_curb.metallic = 0.01

	mat_sidewalk = StandardMaterial3D.new()
	mat_sidewalk.albedo_color = Color(0.28, 0.30, 0.32) # Dark concrete sidewalk pavers (non-blinding)
	mat_sidewalk.roughness = 0.85
	mat_sidewalk.metallic = 0.01

	mat_marking_white = StandardMaterial3D.new()
	mat_marking_white.albedo_color = Color(0.80, 0.82, 0.85) # Calibrated non-glaring matte road paint
	mat_marking_white.roughness = 0.75
	mat_marking_white.metallic = 0.0

	mat_marking_yellow = StandardMaterial3D.new()
	mat_marking_yellow.albedo_color = Color(0.92, 0.72, 0.10) # Warm matte highway yellow
	mat_marking_yellow.roughness = 0.75
	mat_marking_yellow.metallic = 0.0

	mat_barrier = StandardMaterial3D.new()
	mat_barrier.albedo_color = Color(0.70, 0.73, 0.78) # Galvanized steel crash barrier
	mat_barrier.metallic = 0.90
	mat_barrier.roughness = 0.25

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
		sky_mat.sky_top_color = Color(0.20, 0.42, 0.76)       # Rich azure sky
		sky_mat.sky_horizon_color = Color(0.65, 0.73, 0.82)   # Natural atmospheric haze
		sky_mat.ground_bottom_color = Color(0.14, 0.16, 0.18) # Deep terrain ground tone
		sky_mat.ground_horizon_color = Color(0.50, 0.60, 0.70)
		sky_mat.sun_angle_max = 30.0
		sky.sky_material = sky_mat
		env.sky = sky

		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 0.82
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_exposure = 0.95
		env.glow_enabled = true
		env.glow_intensity = 0.18
		env.glow_bloom = 0.02 # Subtle non-blinding bloom
		env.fog_enabled = true
		env.fog_light_color = Color(0.62, 0.71, 0.82)
		env.fog_density = 0.0006
		world_environment.environment = env
		add_child(world_environment)

	if not sun_light:
		sun_light = DirectionalLight3D.new()
		sun_light.name = "SunLight"
		sun_light.rotation_degrees = Vector3(-45, -35, 0)
		sun_light.light_color = Color(1.0, 0.97, 0.92)
		sun_light.light_energy = 1.0
		sun_light.shadow_enabled = true
		sun_light.shadow_bias = 0.03
		add_child(sun_light)

func setup_ground_plane() -> void:
	var ground = StaticBody3D.new()
	ground.name = "CityGroundPlane"
	ground.collision_layer = GameConstants.LAYER_WORLD

	var mi = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(2800, 2800)
	mi.mesh = plane_mesh

	var mat_ground = StandardMaterial3D.new()
	mat_ground.albedo_color = Color(0.12, 0.13, 0.15)
	mat_ground.roughness = 0.95
	mi.material_override = mat_ground
	ground.add_child(mi)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2800, 1.0, 2800)
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

## Builds an authoritative continuous road spline ribbon with flush trimesh collision,
## yellow dashed centerlines, solid white shoulder lines, and beveled curbs.
## Eliminates all step seams, gaps, and curbs crossing driveable lanes.
func build_continuous_road_network(road_waypoints: Array[Vector3], road_width: float = 15.0) -> Node3D:
	if road_waypoints.size() < 3:
		return null

	var samples: Array[Vector3] = []
	var n_wp = road_waypoints.size()
	var subs_per_segment = 6

	for i in range(n_wp):
		var p0 = road_waypoints[(i - 1 + n_wp) % n_wp]
		var p1 = road_waypoints[i]
		var p2 = road_waypoints[(i + 1) % n_wp]
		var p3 = road_waypoints[(i + 2) % n_wp]

		for s in range(subs_per_segment):
			var t = float(s) / float(subs_per_segment)
			var t2 = t * t
			var t3 = t2 * t
			# Catmull-Rom spline interpolation
			var pt = 0.5 * (
				(2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			)
			samples.append(pt)

	spline_samples = samples
	var total_samples = samples.size()
	var half_w = road_width * 0.5
	var curb_w = 0.25
	var curb_h = 0.10 # Realistic 10cm curb height
	var sidewalk_w = 1.60 # Realistic 1.6m sidewalk
	var barrier_h = 0.90 # Standard highway guardrail height

	var left_road_pts: Array[Vector3] = []
	var right_road_pts: Array[Vector3] = []
	var left_curb_top: Array[Vector3] = []
	var right_curb_top: Array[Vector3] = []
	var left_curb_out: Array[Vector3] = []
	var right_curb_out: Array[Vector3] = []
	var left_sw_out: Array[Vector3] = []
	var right_sw_out: Array[Vector3] = []
	var normals: Array[Vector3] = []

	var dists: Array[float] = []
	var accum_dist: float = 0.0
	dists.append(0.0)
	for i in range(1, total_samples + 1):
		var p_prev = samples[i - 1]
		var p_curr = samples[i % total_samples]
		accum_dist += p_prev.distance_to(p_curr)
		dists.append(accum_dist)

	for i in range(total_samples):
		var p_prev = samples[(i - 1 + total_samples) % total_samples]
		var p_curr = samples[i]
		var p_next = samples[(i + 1) % total_samples]

		var tangent = (p_next - p_prev).normalized()
		var up = Vector3.UP
		var right = tangent.cross(up).normalized()
		if right.length_squared() < 0.01:
			right = Vector3.RIGHT
		var surf_normal = right.cross(tangent).normalized()
		normals.append(surf_normal)

		left_road_pts.append(p_curr - right * half_w)
		right_road_pts.append(p_curr + right * half_w)

		left_curb_top.append(p_curr - right * half_w + surf_normal * curb_h)
		right_curb_top.append(p_curr + right * half_w + surf_normal * curb_h)

		left_curb_out.append(p_curr - right * (half_w + curb_w) + surf_normal * curb_h)
		right_curb_out.append(p_curr + right * (half_w + curb_w) + surf_normal * curb_h)

		left_sw_out.append(p_curr - right * (half_w + curb_w + sidewalk_w) + surf_normal * curb_h)
		right_sw_out.append(p_curr + right * (half_w + curb_w + sidewalk_w) + surf_normal * curb_h)

	var st_road = SurfaceTool.new()
	st_road.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_road.set_material(mat_asphalt)

	var st_curb = SurfaceTool.new()
	st_curb.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_curb.set_material(mat_curb)

	var st_sw = SurfaceTool.new()
	st_sw.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_sw.set_material(mat_sidewalk)

	var st_lines = SurfaceTool.new()
	st_lines.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_lines.set_material(mat_marking_yellow)

	var st_white = SurfaceTool.new()
	st_white.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_white.set_material(mat_marking_white)

	var st_barrier = SurfaceTool.new()
	st_barrier.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_barrier.set_material(mat_barrier)

	var st_fascia = SurfaceTool.new()
	st_fascia.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_fascia.set_material(mat_curb)

	var collision_faces = PackedVector3Array()
	var has_barriers = false
	var road_deck_thickness: float = 0.45

	for i in range(total_samples):
		var next_i = (i + 1) % total_samples
		var d1 = dists[i]
		var d2 = dists[i + 1]
		var n1 = normals[i]
		var n2 = normals[next_i]

		var rl1 = left_road_pts[i]
		var rr1 = right_road_pts[i]
		var rl2 = left_road_pts[next_i]
		var rr2 = right_road_pts[next_i]

		# 1. Main Asphalt Surface
		st_road.set_normal(n1); st_road.set_uv(Vector2(0.0, d1 * 0.08)); st_road.add_vertex(rl1)
		st_road.set_normal(n1); st_road.set_uv(Vector2(1.0, d1 * 0.08)); st_road.add_vertex(rr1)
		st_road.set_normal(n2); st_road.set_uv(Vector2(0.0, d2 * 0.08)); st_road.add_vertex(rl2)

		st_road.set_normal(n1); st_road.set_uv(Vector2(1.0, d1 * 0.08)); st_road.add_vertex(rr1)
		st_road.set_normal(n2); st_road.set_uv(Vector2(1.0, d2 * 0.08)); st_road.add_vertex(rr2)
		st_road.set_normal(n2); st_road.set_uv(Vector2(0.0, d2 * 0.08)); st_road.add_vertex(rl2)

		collision_faces.append(rl1); collision_faces.append(rr1); collision_faces.append(rl2)
		collision_faces.append(rr1); collision_faces.append(rr2); collision_faces.append(rl2)

		# 2. Yellow Centerline Dashes (3m dash, 3m gap)
		var center1 = (rl1 + rr1) * 0.5 + n1 * 0.015
		var center2 = (rl2 + rr2) * 0.5 + n2 * 0.015
		var d_mod = fmod(d1, 6.0)
		if d_mod < 3.2:
			var norm_t = (center2 - center1).normalized()
			var r_t = norm_t.cross(n1).normalized() * 0.14
			var cl1 = center1 - r_t
			var cr1 = center1 + r_t
			var cl2 = center2 - r_t
			var cr2 = center2 + r_t
			st_lines.set_normal(n1); st_lines.set_uv(Vector2(0, 0)); st_lines.add_vertex(cl1)
			st_lines.set_normal(n1); st_lines.set_uv(Vector2(1, 0)); st_lines.add_vertex(cr1)
			st_lines.set_normal(n2); st_lines.set_uv(Vector2(0, 1)); st_lines.add_vertex(cl2)
			st_lines.set_normal(n1); st_lines.set_uv(Vector2(1, 0)); st_lines.add_vertex(cr1)
			st_lines.set_normal(n2); st_lines.set_uv(Vector2(1, 1)); st_lines.add_vertex(cr2)
			st_lines.set_normal(n2); st_lines.set_uv(Vector2(0, 1)); st_lines.add_vertex(cl2)

		# 3. Solid White Shoulder Lines
		var line_w = 0.22
		var l_sh1 = rl1 + (rr1 - rl1).normalized() * 0.45 + n1 * 0.012
		var l_sh2 = rl2 + (rr2 - rl2).normalized() * 0.45 + n2 * 0.012
		var l_out1 = l_sh1 - (rr1 - rl1).normalized() * line_w
		var l_out2 = l_sh2 - (rr2 - rl2).normalized() * line_w
		st_white.set_normal(n1); st_white.set_uv(Vector2(0, 0)); st_white.add_vertex(l_out1)
		st_white.set_normal(n1); st_white.set_uv(Vector2(1, 0)); st_white.add_vertex(l_sh1)
		st_white.set_normal(n2); st_white.set_uv(Vector2(0, 1)); st_white.add_vertex(l_out2)
		st_white.set_normal(n1); st_white.set_uv(Vector2(1, 0)); st_white.add_vertex(l_sh1)
		st_white.set_normal(n2); st_white.set_uv(Vector2(1, 1)); st_white.add_vertex(l_sh2)
		st_white.set_normal(n2); st_white.set_uv(Vector2(0, 1)); st_white.add_vertex(l_out2)

		var r_sh1 = rr1 - (rr1 - rl1).normalized() * 0.45 + n1 * 0.012
		var r_sh2 = rr2 - (rr2 - rl2).normalized() * 0.45 + n2 * 0.012
		var r_out1 = r_sh1 + (rr1 - rl1).normalized() * line_w
		var r_out2 = r_sh2 + (rr2 - rl2).normalized() * line_w
		st_white.set_normal(n1); st_white.set_uv(Vector2(0, 0)); st_white.add_vertex(r_sh1)
		st_white.set_normal(n1); st_white.set_uv(Vector2(1, 0)); st_white.add_vertex(r_out1)
		st_white.set_normal(n2); st_white.set_uv(Vector2(0, 1)); st_white.add_vertex(r_sh2)
		st_white.set_normal(n1); st_white.set_uv(Vector2(1, 0)); st_white.add_vertex(r_out1)
		st_white.set_normal(n2); st_white.set_uv(Vector2(1, 1)); st_white.add_vertex(r_out2)
		st_white.set_normal(n2); st_white.set_uv(Vector2(0, 1)); st_white.add_vertex(r_sh2)

		# 4. Curbs (Beveled 10cm curb stone with valid UVs)
		var lct1 = left_curb_top[i]
		var lco1 = left_curb_out[i]
		var lct2 = left_curb_top[next_i]
		var lco2 = left_curb_out[next_i]

		# Left Curb Incline
		st_curb.set_normal(n1); st_curb.set_uv(Vector2(0.0, d1 * 0.15)); st_curb.add_vertex(rl1)
		st_curb.set_normal(n1); st_curb.set_uv(Vector2(0.5, d1 * 0.15)); st_curb.add_vertex(lct1)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(0.0, d2 * 0.15)); st_curb.add_vertex(rl2)
		st_curb.set_normal(n1); st_curb.set_uv(Vector2(0.5, d1 * 0.15)); st_curb.add_vertex(lct1)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(0.5, d2 * 0.15)); st_curb.add_vertex(lct2)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(0.0, d2 * 0.15)); st_curb.add_vertex(rl2)
		collision_faces.append(rl1); collision_faces.append(lct1); collision_faces.append(rl2)
		collision_faces.append(lct1); collision_faces.append(lct2); collision_faces.append(rl2)

		# Left Curb Top
		st_curb.set_normal(n1); st_curb.set_uv(Vector2(0.5, d1 * 0.15)); st_curb.add_vertex(lct1)
		st_curb.set_normal(n1); st_curb.set_uv(Vector2(1.0, d1 * 0.15)); st_curb.add_vertex(lco1)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(0.5, d2 * 0.15)); st_curb.add_vertex(lct2)
		st_curb.set_normal(n1); st_curb.set_uv(Vector2(1.0, d1 * 0.15)); st_curb.add_vertex(lco1)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(1.0, d2 * 0.15)); st_curb.add_vertex(lco2)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(0.5, d2 * 0.15)); st_curb.add_vertex(lct2)
		collision_faces.append(lct1); collision_faces.append(lco1); collision_faces.append(lct2)
		collision_faces.append(lco1); collision_faces.append(lco2); collision_faces.append(lct2)

		# Right Curb
		var rct1 = right_curb_top[i]
		var rco1 = right_curb_out[i]
		var rct2 = right_curb_top[next_i]
		var rco2 = right_curb_out[next_i]

		st_curb.set_normal(n1); st_curb.set_uv(Vector2(0.0, d1 * 0.15)); st_curb.add_vertex(rct1)
		st_curb.set_normal(n1); st_curb.set_uv(Vector2(0.5, d1 * 0.15)); st_curb.add_vertex(rr1)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(0.0, d2 * 0.15)); st_curb.add_vertex(rct2)
		st_curb.set_normal(n1); st_curb.set_uv(Vector2(0.5, d1 * 0.15)); st_curb.add_vertex(rr1)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(0.5, d2 * 0.15)); st_curb.add_vertex(rr2)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(0.0, d2 * 0.15)); st_curb.add_vertex(rct2)
		collision_faces.append(rct1); collision_faces.append(rr1); collision_faces.append(rct2)
		collision_faces.append(rr1); collision_faces.append(rr2); collision_faces.append(rct2)

		st_curb.set_normal(n1); st_curb.set_uv(Vector2(0.5, d1 * 0.15)); st_curb.add_vertex(rco1)
		st_curb.set_normal(n1); st_curb.set_uv(Vector2(1.0, d1 * 0.15)); st_curb.add_vertex(rct1)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(0.5, d2 * 0.15)); st_curb.add_vertex(rco2)
		st_curb.set_normal(n1); st_curb.set_uv(Vector2(1.0, d1 * 0.15)); st_curb.add_vertex(rct1)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(1.0, d2 * 0.15)); st_curb.add_vertex(rct2)
		st_curb.set_normal(n2); st_curb.set_uv(Vector2(0.5, d2 * 0.15)); st_curb.add_vertex(rco2)
		collision_faces.append(rco1); collision_faces.append(rct1); collision_faces.append(rco2)
		collision_faces.append(rct1); collision_faces.append(rct2); collision_faces.append(rco2)

		# 5. Sidewalks (with valid UVs)
		var lsw1 = left_sw_out[i]
		var lsw2 = left_sw_out[next_i]
		st_sw.set_normal(n1); st_sw.set_uv(Vector2(0.0, d1 * 0.12)); st_sw.add_vertex(lco1)
		st_sw.set_normal(n1); st_sw.set_uv(Vector2(1.0, d1 * 0.12)); st_sw.add_vertex(lsw1)
		st_sw.set_normal(n2); st_sw.set_uv(Vector2(0.0, d2 * 0.12)); st_sw.add_vertex(lco2)
		st_sw.set_normal(n1); st_sw.set_uv(Vector2(1.0, d1 * 0.12)); st_sw.add_vertex(lsw1)
		st_sw.set_normal(n2); st_sw.set_uv(Vector2(1.0, d2 * 0.12)); st_sw.add_vertex(lsw2)
		st_sw.set_normal(n2); st_sw.set_uv(Vector2(0.0, d2 * 0.12)); st_sw.add_vertex(lco2)
		collision_faces.append(lco1); collision_faces.append(lsw1); collision_faces.append(lco2)
		collision_faces.append(lsw1); collision_faces.append(lsw2); collision_faces.append(lco2)

		var rsw1 = right_sw_out[i]
		var rsw2 = right_sw_out[next_i]
		st_sw.set_normal(n1); st_sw.set_uv(Vector2(0.0, d1 * 0.12)); st_sw.add_vertex(rsw1)
		st_sw.set_normal(n1); st_sw.set_uv(Vector2(1.0, d1 * 0.12)); st_sw.add_vertex(rco1)
		st_sw.set_normal(n2); st_sw.set_uv(Vector2(0.0, d2 * 0.12)); st_sw.add_vertex(rsw2)
		st_sw.set_normal(n1); st_sw.set_uv(Vector2(1.0, d1 * 0.12)); st_sw.add_vertex(rco1)
		st_sw.set_normal(n2); st_sw.set_uv(Vector2(1.0, d2 * 0.12)); st_sw.add_vertex(rco2)
		st_sw.set_normal(n2); st_sw.set_uv(Vector2(0.0, d2 * 0.12)); st_sw.add_vertex(rsw2)
		collision_faces.append(rsw1); collision_faces.append(rco1); collision_faces.append(rsw2)
		collision_faces.append(rco1); collision_faces.append(rco2); collision_faces.append(rsw2)

		# 6. Solid Outer Sidewalk Fascia Drops (Eliminates paper-thin edges & under-void clipping)
		var lsw_b1 = lsw1 - n1 * road_deck_thickness
		var lsw_b2 = lsw2 - n2 * road_deck_thickness
		var rsw_b1 = rsw1 - n1 * road_deck_thickness
		var rsw_b2 = rsw2 - n2 * road_deck_thickness

		var r_dir1 = (rr1 - rl1).normalized()
		var r_dir2 = (rr2 - rl2).normalized()

		# Left Outer Fascia
		st_fascia.set_normal(-r_dir1); st_fascia.set_uv(Vector2(0, d1 * 0.1)); st_fascia.add_vertex(lsw1)
		st_fascia.set_normal(-r_dir1); st_fascia.set_uv(Vector2(1, d1 * 0.1)); st_fascia.add_vertex(lsw_b1)
		st_fascia.set_normal(-r_dir2); st_fascia.set_uv(Vector2(0, d2 * 0.1)); st_fascia.add_vertex(lsw2)
		st_fascia.set_normal(-r_dir1); st_fascia.set_uv(Vector2(1, d1 * 0.1)); st_fascia.add_vertex(lsw_b1)
		st_fascia.set_normal(-r_dir2); st_fascia.set_uv(Vector2(1, d2 * 0.1)); st_fascia.add_vertex(lsw_b2)
		st_fascia.set_normal(-r_dir2); st_fascia.set_uv(Vector2(0, d2 * 0.1)); st_fascia.add_vertex(lsw2)
		collision_faces.append(lsw1); collision_faces.append(lsw_b1); collision_faces.append(lsw2)
		collision_faces.append(lsw_b1); collision_faces.append(lsw_b2); collision_faces.append(lsw2)

		# Right Outer Fascia
		st_fascia.set_normal(r_dir1); st_fascia.set_uv(Vector2(0, d1 * 0.1)); st_fascia.add_vertex(rsw_b1)
		st_fascia.set_normal(r_dir1); st_fascia.set_uv(Vector2(1, d1 * 0.1)); st_fascia.add_vertex(rsw1)
		st_fascia.set_normal(r_dir2); st_fascia.set_uv(Vector2(0, d2 * 0.1)); st_fascia.add_vertex(rsw_b2)
		st_fascia.set_normal(r_dir1); st_fascia.set_uv(Vector2(1, d1 * 0.1)); st_fascia.add_vertex(rsw1)
		st_fascia.set_normal(r_dir2); st_fascia.set_uv(Vector2(1, d2 * 0.1)); st_fascia.add_vertex(rsw2)
		st_fascia.set_normal(r_dir2); st_fascia.set_uv(Vector2(0, d2 * 0.1)); st_fascia.add_vertex(rsw_b2)
		collision_faces.append(rsw_b1); collision_faces.append(rsw1); collision_faces.append(rsw_b2)
		collision_faces.append(rsw1); collision_faces.append(rsw2); collision_faces.append(rsw_b2)

		# 7. Solid Underside Road Deck & Concrete Piers on Elevated Sections (samples[i].y > 0.4)
		var is_elevated = (samples[i].y > 0.4 or samples[next_i].y > 0.4)
		if is_elevated:
			has_barriers = true
			# Underside deck facing downward
			st_fascia.set_normal(-n1); st_fascia.set_uv(Vector2(0, d1 * 0.08)); st_fascia.add_vertex(lsw_b2)
			st_fascia.set_normal(-n1); st_fascia.set_uv(Vector2(1, d1 * 0.08)); st_fascia.add_vertex(rsw_b2)
			st_fascia.set_normal(-n2); st_fascia.set_uv(Vector2(0, d2 * 0.08)); st_fascia.add_vertex(lsw_b1)
			st_fascia.set_normal(-n1); st_fascia.set_uv(Vector2(1, d1 * 0.08)); st_fascia.add_vertex(rsw_b2)
			st_fascia.set_normal(-n2); st_fascia.set_uv(Vector2(1, d2 * 0.08)); st_fascia.add_vertex(rsw_b1)
			st_fascia.set_normal(-n2); st_fascia.set_uv(Vector2(0, d2 * 0.08)); st_fascia.add_vertex(lsw_b1)
			collision_faces.append(lsw_b2); collision_faces.append(rsw_b2); collision_faces.append(lsw_b1)
			collision_faces.append(rsw_b2); collision_faces.append(rsw_b1); collision_faces.append(lsw_b1)

			# Continuous Solid Spline Guardrails with Enclosed 3D Geometry
			var bar_thick = 0.20
			var lb_b1 = lsw1; var lb_b2 = lsw2
			var lb_t1 = lsw1 + n1 * barrier_h; var lb_t2 = lsw2 + n2 * barrier_h
			var lb_b1_out = lb_b1 - r_dir1 * bar_thick; var lb_b2_out = lb_b2 - r_dir2 * bar_thick
			var lb_t1_out = lb_t1 - r_dir1 * bar_thick; var lb_t2_out = lb_t2 - r_dir2 * bar_thick

			# Left Inner Barrier Face (facing into road, normal = r_dir)
			st_barrier.set_normal(r_dir1); st_barrier.set_uv(Vector2(0, 0)); st_barrier.add_vertex(lb_b1)
			st_barrier.set_normal(r_dir1); st_barrier.set_uv(Vector2(1, 0)); st_barrier.add_vertex(lb_t1)
			st_barrier.set_normal(r_dir2); st_barrier.set_uv(Vector2(0, 1)); st_barrier.add_vertex(lb_b2)
			st_barrier.set_normal(r_dir1); st_barrier.set_uv(Vector2(1, 0)); st_barrier.add_vertex(lb_t1)
			st_barrier.set_normal(r_dir2); st_barrier.set_uv(Vector2(1, 1)); st_barrier.add_vertex(lb_t2)
			st_barrier.set_normal(r_dir2); st_barrier.set_uv(Vector2(0, 1)); st_barrier.add_vertex(lb_b2)
			collision_faces.append(lb_b1); collision_faces.append(lb_t1); collision_faces.append(lb_b2)
			collision_faces.append(lb_t1); collision_faces.append(lb_t2); collision_faces.append(lb_b2)

			# Left Top Barrier Cap
			st_barrier.set_normal(n1); st_barrier.set_uv(Vector2(0, 0)); st_barrier.add_vertex(lb_t1)
			st_barrier.set_normal(n1); st_barrier.set_uv(Vector2(1, 0)); st_barrier.add_vertex(lb_t1_out)
			st_barrier.set_normal(n2); st_barrier.set_uv(Vector2(0, 1)); st_barrier.add_vertex(lb_t2)
			st_barrier.set_normal(n1); st_barrier.set_uv(Vector2(1, 0)); st_barrier.add_vertex(lb_t1_out)
			st_barrier.set_normal(n2); st_barrier.set_uv(Vector2(1, 1)); st_barrier.add_vertex(lb_t2_out)
			st_barrier.set_normal(n2); st_barrier.set_uv(Vector2(0, 1)); st_barrier.add_vertex(lb_t2)
			collision_faces.append(lb_t1); collision_faces.append(lb_t1_out); collision_faces.append(lb_t2)
			collision_faces.append(lb_t1_out); collision_faces.append(lb_t2_out); collision_faces.append(lb_t2)

			# Right Inner Barrier Face (facing into road, normal = -r_dir)
			var rb_b1 = rsw1; var rb_b2 = rsw2
			var rb_t1 = rsw1 + n1 * barrier_h; var rb_t2 = rsw2 + n2 * barrier_h
			var rb_b1_out = rb_b1 + r_dir1 * bar_thick; var rb_b2_out = rb_b2 + r_dir2 * bar_thick
			var rb_t1_out = rb_t1 + r_dir1 * bar_thick; var rb_t2_out = rb_t2 + r_dir2 * bar_thick

			st_barrier.set_normal(-r_dir1); st_barrier.set_uv(Vector2(0, 0)); st_barrier.add_vertex(rb_t1)
			st_barrier.set_normal(-r_dir1); st_barrier.set_uv(Vector2(1, 0)); st_barrier.add_vertex(rb_b1)
			st_barrier.set_normal(-r_dir2); st_barrier.set_uv(Vector2(0, 1)); st_barrier.add_vertex(rb_t2)
			st_barrier.set_normal(-r_dir1); st_barrier.set_uv(Vector2(1, 0)); st_barrier.add_vertex(rb_b1)
			st_barrier.set_normal(-r_dir2); st_barrier.set_uv(Vector2(1, 1)); st_barrier.add_vertex(rb_b2)
			st_barrier.set_normal(-r_dir2); st_barrier.set_uv(Vector2(0, 1)); st_barrier.add_vertex(rb_t2)
			collision_faces.append(rb_t1); collision_faces.append(rb_b1); collision_faces.append(rb_t2)
			collision_faces.append(rb_b1); collision_faces.append(rb_b2); collision_faces.append(rb_t2)

			# Right Top Barrier Cap
			st_barrier.set_normal(n1); st_barrier.set_uv(Vector2(0, 0)); st_barrier.add_vertex(rb_t1_out)
			st_barrier.set_normal(n1); st_barrier.set_uv(Vector2(1, 0)); st_barrier.add_vertex(rb_t1)
			st_barrier.set_normal(n2); st_barrier.set_uv(Vector2(0, 1)); st_barrier.add_vertex(rb_t2_out)
			st_barrier.set_normal(n1); st_barrier.set_uv(Vector2(1, 0)); st_barrier.add_vertex(rb_t1)
			st_barrier.set_normal(n2); st_barrier.set_uv(Vector2(1, 1)); st_barrier.add_vertex(rb_t2)
			st_barrier.set_normal(n2); st_barrier.set_uv(Vector2(0, 1)); st_barrier.add_vertex(rb_t2_out)
			collision_faces.append(rb_t1_out); collision_faces.append(rb_t1); collision_faces.append(rb_t2_out)
			collision_faces.append(rb_t1); collision_faces.append(rb_t2); collision_faces.append(rb_t2_out)

	st_road.generate_tangents()
	st_curb.generate_normals(); st_curb.generate_tangents()
	st_sw.generate_normals(); st_sw.generate_tangents()
	st_lines.generate_normals(); st_lines.generate_tangents()
	st_white.generate_normals(); st_white.generate_tangents()
	st_fascia.generate_normals(); st_fascia.generate_tangents()
	if has_barriers:
		st_barrier.generate_normals(); st_barrier.generate_tangents()

	var road_body = StaticBody3D.new()
	road_body.name = "ContinuousRoadNetwork"
	road_body.collision_layer = GameConstants.LAYER_WORLD

	var m_road = MeshInstance3D.new(); m_road.name = "RoadMesh"; m_road.mesh = st_road.commit(); road_body.add_child(m_road)
	var m_curb = MeshInstance3D.new(); m_curb.name = "CurbMesh"; m_curb.mesh = st_curb.commit(); road_body.add_child(m_curb)
	var m_sw = MeshInstance3D.new(); m_sw.name = "SidewalkMesh"; m_sw.mesh = st_sw.commit(); road_body.add_child(m_sw)
	var m_lines = MeshInstance3D.new(); m_lines.name = "CenterLinesMesh"; m_lines.mesh = st_lines.commit(); road_body.add_child(m_lines)
	var m_white = MeshInstance3D.new(); m_white.name = "ShoulderLinesMesh"; m_white.mesh = st_white.commit(); road_body.add_child(m_white)
	var m_fascia = MeshInstance3D.new(); m_fascia.name = "FasciaMesh"; m_fascia.mesh = st_fascia.commit(); road_body.add_child(m_fascia)
	if has_barriers:
		var m_bar = MeshInstance3D.new(); m_bar.name = "BarrierMesh"; m_bar.mesh = st_barrier.commit(); road_body.add_child(m_bar)

	var col = CollisionShape3D.new()
	col.name = "ContinuousRoadCollision"
	var concave_shape = ConcavePolygonShape3D.new()
	concave_shape.backface_collision = true
	concave_shape.set_faces(collision_faces)
	col.shape = concave_shape
	road_body.add_child(col)

	# 8. Place solid concrete bridge support piers strictly centered beneath elevated skyway sections
	for i in range(total_samples):
		if i % 6 == 0 and samples[i].y > 2.0:
			var pier_h = samples[i].y - road_deck_thickness
			if pier_h > 0.5:
				var pier = StaticBody3D.new()
				pier.name = "ElevatedSupportPier_%d" % i
				pier.collision_layer = GameConstants.LAYER_WORLD
				var pier_mi = MeshInstance3D.new()
				var pier_box = BoxMesh.new()
				pier_box.size = Vector3(4.0, pier_h, 4.0)
				pier_mi.mesh = pier_box
				pier_mi.material_override = mat_curb
				pier_mi.position = Vector3(0, pier_h * 0.5, 0)
				pier.add_child(pier_mi)

				var pier_col = CollisionShape3D.new()
				var pier_shape = BoxShape3D.new()
				pier_shape.size = Vector3(4.0, pier_h, 4.0)
				pier_col.shape = pier_shape
				pier_col.position = Vector3(0, pier_h * 0.5, 0)
				pier.add_child(pier_col)

				pier.position = Vector3(samples[i].x, 0.0, samples[i].z)
				road_body.add_child(pier)

	road_container.add_child(road_body)
	return road_body

func get_nearest_spline_index(pos: Vector3) -> int:
	if spline_samples.is_empty():
		return get_nearest_waypoint_index(pos)
	var best_idx = 0
	var best_dist = pos.distance_squared_to(spline_samples[0])
	for i in range(1, spline_samples.size()):
		var d = pos.distance_squared_to(spline_samples[i])
		if d < best_dist:
			best_dist = d
			best_idx = i
	return best_idx

func get_spline_point(idx: int) -> Vector3:
	if spline_samples.is_empty():
		return get_waypoint(idx)
	return spline_samples[idx % spline_samples.size()]

func get_total_spline_points() -> int:
	return spline_samples.size() if not spline_samples.is_empty() else waypoints.size()

func get_spline_samples() -> Array[Vector3]:
	if not spline_samples.is_empty():
		return spline_samples
	return waypoints

func get_lane_point(spline_idx: int, lane_offset: float = -3.5) -> Vector3:
	var total = get_total_spline_points()
	if total < 2:
		return get_spline_point(spline_idx)
	var p_prev = get_spline_point((spline_idx - 1 + total) % total)
	var p_curr = get_spline_point(spline_idx)
	var p_next = get_spline_point((spline_idx + 1) % total)
	var tangent = (p_next - p_prev).normalized()
	var right = tangent.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.01:
		right = Vector3.RIGHT
	return p_curr + right * lane_offset

## Fallback standalone segment with smooth, flush collision and beveled curbs
func add_road_segment(start_pos: Vector3, end_pos: Vector3, road_width: float = 14.0) -> void:
	var segment = StaticBody3D.new()
	segment.name = "RoadSegment"
	segment.collision_layer = GameConstants.LAYER_WORLD

	var dir = end_pos - start_pos
	var length = dir.length()
	if length < 0.1:
		return
	var center = (start_pos + end_pos) * 0.5

	var road_mi = MeshInstance3D.new()
	var road_mesh = BoxMesh.new()
	road_mesh.size = Vector3(road_width, 0.4, length)
	road_mi.mesh = road_mesh
	road_mi.material_override = mat_asphalt
	segment.add_child(road_mi)

	var col = CollisionShape3D.new()
	var col_shape = BoxShape3D.new()
	col_shape.size = Vector3(road_width, 0.4, length)
	col.shape = col_shape
	segment.add_child(col)

	# Dashed Yellow Centerlines
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

	# White Solid Shoulder Lines
	for side in [-1.0, 1.0]:
		var edge_mi = MeshInstance3D.new()
		var edge_box = BoxMesh.new()
		edge_box.size = Vector3(0.20, 0.02, length)
		edge_mi.mesh = edge_box
		edge_mi.material_override = mat_marking_white
		edge_mi.position = Vector3(side * (road_width * 0.5 - 0.4), 0.21, 0.0)
		segment.add_child(edge_mi)

	# Raised 12cm Curbs & Sidewalks
	var sidewalk_width = 2.4
	for side in [-1.0, 1.0]:
		var sw_x = side * (road_width * 0.5 + sidewalk_width * 0.5)
		var sw_mi = MeshInstance3D.new()
		var sw_box = BoxMesh.new()
		sw_box.size = Vector3(sidewalk_width, 0.36, length)
		sw_mi.mesh = sw_box
		sw_mi.material_override = mat_sidewalk
		sw_mi.position = Vector3(sw_x, 0.18, 0.0)
		segment.add_child(sw_mi)

		var curb_x = side * (road_width * 0.5 + 0.15)
		var curb_mi = MeshInstance3D.new()
		var curb_box = BoxMesh.new()
		curb_box.size = Vector3(0.30, 0.24, length)
		curb_mi.mesh = curb_box
		curb_mi.material_override = mat_curb
		curb_mi.position = Vector3(curb_x, 0.12, 0.0)
		segment.add_child(curb_mi)

	segment.position = center
	segment.look_at_from_position(center, center + dir, Vector3.UP)
	road_container.add_child(segment)

func get_nearest_safe_road_transform(pos: Vector3) -> Transform3D:
	if waypoints.size() < 2:
		return Transform3D(Basis.IDENTITY, pos + Vector3(0, 0.20, 0))

	var best_dist_sq = 1e12
	var best_point = waypoints[0]
	var best_fwd = Vector3.FORWARD

	var samples = spline_samples if spline_samples.size() > 4 else waypoints
	var n_s = samples.size()
	for i in range(n_s):
		var p1 = samples[i]
		var p2 = samples[(i + 1) % n_s]
		var seg = p2 - p1
		var seg_len_sq = seg.length_squared()
		var proj_t = 0.0
		if seg_len_sq > 0.001:
			proj_t = clampf((pos - p1).dot(seg) / seg_len_sq, 0.0, 1.0)
		var closest = p1 + seg * proj_t
		var d_sq = (pos - closest).length_squared()
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			best_point = closest
			best_fwd = seg.normalized() if seg_len_sq > 0.001 else Vector3.FORWARD

	# Ensure forward direction is strictly horizontal or aligned with road slope
	if best_fwd.length_squared() < 0.001:
		best_fwd = Vector3.FORWARD

	var xf = Transform3D().looking_at(best_fwd, Vector3.UP)
	xf.origin = best_point + Vector3(0, 0.20, 0)
	return xf


