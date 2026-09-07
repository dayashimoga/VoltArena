class_name TrackGenerator
extends Node3D

## TrackGenerator: Procedurally synthesizes championship racing circuits for Drift Storm.
## Features 3 high-detail environments:
## 1. Neon Circuit (Metropolitan Night Stadium with grandstands and floodlights)
## 2. Canyon Run (Expansive red rock mesa with elevation changes and rock arches)
## 3. Skyline Drift (High-altitude twilight expressway through skyscrapers)
## Built with production 3D racing and architecture kit pieces.

signal track_built(waypoints: Array[Vector3], checkpoints: Array[RaceCheckpoint])

@export var track_theme: String = "metropolis" # "metropolis", "canyon", "skyline"
@export var track_width: float = 14.0

var waypoints: Array[Vector3] = []
var checkpoints: Array[RaceCheckpoint] = []

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

func _ready() -> void:
	build_circuit()

func build_circuit() -> void:
	var circuit_nodes: Array[Vector3] = []
	match track_theme.to_lower():
		"canyon":
			circuit_nodes = [
				Vector3(0, 0, 0),
				Vector3(0, 0, -40),
				Vector3(0, 0, -75),
				Vector3(25, 1.5, -115),
				Vector3(65, 3.5, -145),
				Vector3(115, 6.0, -165),
				Vector3(170, 7.5, -150),
				Vector3(220, 8.0, -105),
				Vector3(235, 7.5, -50),
				Vector3(225, 6.0, 10),
				Vector3(190, 4.0, 60),
				Vector3(150, 2.5, 95),
				Vector3(100, 1.0, 105),
				Vector3(55, 0.0, 85),
				Vector3(25, 0.0, 55),
				Vector3(0, 0, 35)
			]
			create_box(Vector3(110.0, -1.5, -25.0), Vector3(550.0, 3.0, 550.0), "canyon_rock")
			for p in [Vector3(-45, 18, -80), Vector3(85, 24, -190), Vector3(260, 22, -40), Vector3(85, 20, 135), Vector3(-35, 16, 60), Vector3(175, 14, 25)]:
				create_box(p, Vector3(52.0, 36.0, 52.0), "canyon_rock")

		"skyline":
			circuit_nodes = [
				Vector3(0, 0, 0),
				Vector3(0, 0, -45),
				Vector3(0, 0, -80),
				Vector3(20, 1.0, -120),
				Vector3(50, 3.5, -160),
				Vector3(100, 6.0, -190),
				Vector3(160, 7.5, -195),
				Vector3(210, 6.5, -170),
				Vector3(240, 4.5, -115),
				Vector3(235, 2.0, -55),
				Vector3(205, 0.5, 0),
				Vector3(165, 0.0, 45),
				Vector3(115, 0.0, 75),
				Vector3(65, 0.0, 65),
				Vector3(25, 0.0, 48),
				Vector3(0, 0, 35)
			]
			create_box(Vector3(115.0, -1.5, -55.0), Vector3(550.0, 3.0, 550.0), "asphalt")
			var building_coords = [
				[Vector3(-45, 0, -75), "a", Vector3(5, 10, 5)],
				[Vector3(75, 0, -210), "b", Vector3(6, 12, 6)],
				[Vector3(175, 0, -215), "c", Vector3(5, 11, 5)],
				[Vector3(265, 0, -60), "d", Vector3(6, 14, 6)],
				[Vector3(155, 0, 95), "a", Vector3(5, 9, 5)],
				[Vector3(-30, 0, 70), "c", Vector3(4, 4, 4)]
			]
			for bc in building_coords:
				var bld = ModelCacheScript.get_building(bc[1])
				if bld:
					bld.position = bc[0]
					bld.scale = bc[2]
					add_child(bld)
				else:
					create_box(bc[0] + Vector3(0, 25, 0), Vector3(40, 50, 40), "dark_concrete")

		_: # "metropolis" / "neon"
			circuit_nodes = [
				Vector3(0, 0, 0),
				Vector3(0, 0, -40),
				Vector3(0, 0, -75),
				Vector3(15, 0, -115),
				Vector3(45, 0.5, -145),
				Vector3(90, 1.0, -165),
				Vector3(145, 1.0, -165),
				Vector3(195, 0.5, -135),
				Vector3(215, 0.0, -85),
				Vector3(205, 0.0, -30),
				Vector3(170, 0.0, 20),
				Vector3(125, 0.0, 45),
				Vector3(80, 0.0, 65),
				Vector3(45, 0.0, 55),
				Vector3(18, 0.0, 45),
				Vector3(0, 0, 35)
			]
			create_box(Vector3(105.0, -1.65, -50.0), Vector3(500.0, 3.0, 500.0), "asphalt")
			var neon_props = [
				[Vector3(-35, 0, -70), "c", Vector3(4, 4, 4)],
				[Vector3(70, 0, -190), "a", Vector3(5, 8, 5)],
				[Vector3(160, 0, -190), "b", Vector3(5, 9, 5)],
				[Vector3(235, 0, -55), "c", Vector3(5, 10, 5)],
				[Vector3(150, 0, 80), "d", Vector3(5, 8, 5)]
			]
			for np in neon_props:
				var b = ModelCacheScript.get_building(np[1])
				if b:
					b.position = np[0]
					b.scale = np[2]
					add_child(b)
				else:
					create_box(np[0] + Vector3(0, 20, 0), Vector3(36, 40, 36), "dark_concrete")

	waypoints = circuit_nodes

	# Build continuous seamless road ribbon with matching collision
	_build_continuous_road_foundation(circuit_nodes)

	# Build track segments
	for i in range(circuit_nodes.size()):
		var p1 = circuit_nodes[i]
		var p2 = circuit_nodes[(i + 1) % circuit_nodes.size()]
		build_track_segment(p1, p2, i)

	# Production Start/Finish Overhead Gantry with Turbo Kart Rush banner & lights
	var gantry = MeshBuilder.build_start_gantry(track_width)
	gantry.position = circuit_nodes[0] + Vector3(0, 0, -2.0)
	add_child(gantry)

	# Authentic 3D rumble curbs along track
	var curb_model = ModelCacheScript.get_prop("racing_curb")
	if curb_model:
		curb_model.position = circuit_nodes[0] + Vector3(-track_width * 0.5 - 1.5, 0, 0)
		curb_model.scale = Vector3(2.0, 2.0, 2.0)
		add_child(curb_model)

	# Production Grandstands with Spectator Crowds along the home straight facing inward toward track
	for z_pos in [-50.0, -25.0, 0.0, 25.0]:
		var stand_l = MeshBuilder.build_grandstand_with_crowd(24.0, 7.0, 9.0)
		stand_l.position = Vector3(-track_width * 0.5 - 6.5, 0.0, z_pos)
		stand_l.rotation_degrees.y = -90.0
		add_child(stand_l)

		var stand_r = MeshBuilder.build_grandstand_with_crowd(24.0, 7.0, 9.0)
		stand_r.position = Vector3(track_width * 0.5 + 6.5, 0.0, z_pos)
		stand_r.rotation_degrees.y = 90.0
		add_child(stand_r)

	# Production Stadium Floodlight Towers
	for fl_pos in [Vector3(-track_width * 0.5 - 12.0, 0.0, -48.0), Vector3(track_width * 0.5 + 12.0, 0.0, -48.0)]:
		var fl = ModelCacheScript.get_prop("floodlight_tower")
		if fl:
			fl.position = fl_pos
			fl.scale = Vector3(3.0, 3.0, 3.0)
			add_child(fl)

	# PowerUp Item Pickups
	var item_indices = [1, int(circuit_nodes.size() * 0.35), int(circuit_nodes.size() * 0.65), int(circuit_nodes.size() * 0.85)]
	for idx in item_indices:
		var item = PowerUpItem.new()
		item.position = circuit_nodes[idx] + Vector3(0, 0.3, 0)
		add_child(item)

	setup_racing_environment()
	track_built.emit(waypoints, checkpoints)

func _build_continuous_road_foundation(nodes: Array[Vector3]) -> void:
	var n = nodes.size()
	if n < 3:
		return

	# Precompute cumulative distance along track centerline for seamless UV tiling
	var total_dist = 0.0
	var node_dists: Array[float] = [0.0]
	for i in range(n):
		var next_pt = nodes[(i + 1) % n]
		total_dist += nodes[i].distance_to(next_pt)
		if i < n - 1:
			node_dists.append(total_dist)

	var half_w = track_width * 0.5
	var curb_w = 1.2
	var curb_h = 0.06
	var wall_h = 1.8

	# Compute track cross-section points at each node
	var road_left: Array[Vector3] = []
	var road_right: Array[Vector3] = []
	var curb_left_inner: Array[Vector3] = []
	var curb_left_outer: Array[Vector3] = []
	var curb_right_inner: Array[Vector3] = []
	var curb_right_outer: Array[Vector3] = []
	var wall_left_bot: Array[Vector3] = []
	var wall_left_top: Array[Vector3] = []
	var wall_right_bot: Array[Vector3] = []
	var wall_right_top: Array[Vector3] = []

	for i in range(n):
		var prev = nodes[(i - 1 + n) % n]
		var curr = nodes[i]
		var next = nodes[(i + 1) % n]
		var dir_prev = (curr - prev).normalized()
		var dir_next = (next - curr).normalized()
		var tangent = (dir_prev + dir_next).normalized()
		var normal = Vector3.UP
		var side = tangent.cross(normal).normalized()

		var rl = curr - side * half_w
		var rr = curr + side * half_w
		road_left.append(rl)
		road_right.append(rr)

		# 3D Rumble Curbs (raised slightly above asphalt with bevel)
		var cli = rl + Vector3.UP * 0.02
		var clo = rl - side * curb_w + Vector3.UP * curb_h
		curb_left_inner.append(cli)
		curb_left_outer.append(clo)

		var cri = rr + Vector3.UP * 0.02
		var cro = rr + side * curb_w + Vector3.UP * curb_h
		curb_right_inner.append(cri)
		curb_right_outer.append(cro)

		# Metallic Safety Barriers placed outside the curbs
		var wlb = clo - side * 0.08
		var wlt = wlb + Vector3.UP * wall_h
		wall_left_bot.append(wlb)
		wall_left_top.append(wlt)

		var wrb = cro + side * 0.08
		var wrt = wrb + Vector3.UP * wall_h
		wall_right_bot.append(wrb)
		wall_right_top.append(wrt)

	var road_body = StaticBody3D.new()
	road_body.name = "ContinuousRoadFoundation"
	road_body.collision_layer = GameConstants.LAYER_WORLD
	road_body.collision_mask = 0

	var st_road = SurfaceTool.new()
	st_road.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_road.set_material(MaterialGenerator.get_material("asphalt_lanes"))

	var st_curb = SurfaceTool.new()
	st_curb.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_curb.set_material(MaterialGenerator.get_material("curb_blue_white"))

	var st_barrier = SurfaceTool.new()
	st_barrier.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_barrier.set_material(MaterialGenerator.get_material("racing_barrier"))

	var collision_faces = PackedVector3Array()

	for i in range(n):
		var next_idx = (i + 1) % n
		var d1 = node_dists[i]
		var d2 = node_dists[next_idx] if next_idx != 0 else total_dist

		# --- 1. Road Surface Ribbon ---
		var v_rl1 = road_left[i]
		var v_rr1 = road_right[i]
		var v_rl2 = road_left[next_idx]
		var v_rr2 = road_right[next_idx]

		var uv_rl1 = Vector2(0.0, d1 / 12.0)
		var uv_rr1 = Vector2(1.0, d1 / 12.0)
		var uv_rl2 = Vector2(0.0, d2 / 12.0)
		var uv_rr2 = Vector2(1.0, d2 / 12.0)

		# Road Triangle 1
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rl1)
		st_road.add_vertex(v_rl1)
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rr1)
		st_road.add_vertex(v_rr1)
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rl2)
		st_road.add_vertex(v_rl2)

		# Road Triangle 2
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rr1)
		st_road.add_vertex(v_rr1)
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rr2)
		st_road.add_vertex(v_rr2)
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rl2)
		st_road.add_vertex(v_rl2)

		# Add to collision
		collision_faces.append(v_rl1)
		collision_faces.append(v_rr1)
		collision_faces.append(v_rl2)
		collision_faces.append(v_rr1)
		collision_faces.append(v_rr2)
		collision_faces.append(v_rl2)

		# --- 2. Left Rumble Curb Ribbon ---
		var v_clo1 = curb_left_outer[i]
		var v_cli1 = curb_left_inner[i]
		var v_clo2 = curb_left_outer[next_idx]
		var v_cli2 = curb_left_inner[next_idx]

		var uv_clo1 = Vector2(d1 / 2.0, 0.0)
		var uv_cli1 = Vector2(d1 / 2.0, 1.0)
		var uv_clo2 = Vector2(d2 / 2.0, 0.0)
		var uv_cli2 = Vector2(d2 / 2.0, 1.0)

		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_clo1)
		st_curb.add_vertex(v_clo1)
		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_cli1)
		st_curb.add_vertex(v_cli1)
		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_clo2)
		st_curb.add_vertex(v_clo2)

		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_cli1)
		st_curb.add_vertex(v_cli1)
		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_cli2)
		st_curb.add_vertex(v_cli2)
		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_clo2)
		st_curb.add_vertex(v_clo2)

		collision_faces.append(v_clo1)
		collision_faces.append(v_cli1)
		collision_faces.append(v_clo2)
		collision_faces.append(v_cli1)
		collision_faces.append(v_cli2)
		collision_faces.append(v_clo2)

		# --- 3. Right Rumble Curb Ribbon ---
		var v_cro1 = curb_right_outer[i]
		var v_cri1 = curb_right_inner[i]
		var v_cro2 = curb_right_outer[next_idx]
		var v_cri2 = curb_right_inner[next_idx]

		var uv_cri1 = Vector2(d1 / 2.0, 0.0)
		var uv_cro1 = Vector2(d1 / 2.0, 1.0)
		var uv_cri2 = Vector2(d2 / 2.0, 0.0)
		var uv_cro2 = Vector2(d2 / 2.0, 1.0)

		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_cri1)
		st_curb.add_vertex(v_cri1)
		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_cro1)
		st_curb.add_vertex(v_cro1)
		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_cri2)
		st_curb.add_vertex(v_cri2)

		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_cro1)
		st_curb.add_vertex(v_cro1)
		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_cro2)
		st_curb.add_vertex(v_cro2)
		st_curb.set_normal(Vector3.UP)
		st_curb.set_uv(uv_cri2)
		st_curb.add_vertex(v_cri2)

		collision_faces.append(v_cri1)
		collision_faces.append(v_cro1)
		collision_faces.append(v_cri2)
		collision_faces.append(v_cro1)
		collision_faces.append(v_cro2)
		collision_faces.append(v_cri2)

		# --- 4. Left Safety Barrier Ribbon ---
		var v_wlb1 = wall_left_bot[i]
		var v_wlt1 = wall_left_top[i]
		var v_wlb2 = wall_left_bot[next_idx]
		var v_wlt2 = wall_left_top[next_idx]

		var uv_wb1 = Vector2(d1 / 4.0, 1.0)
		var uv_wt1 = Vector2(d1 / 4.0, 0.0)
		var uv_wb2 = Vector2(d2 / 4.0, 1.0)
		var uv_wt2 = Vector2(d2 / 4.0, 0.0)

		st_barrier.set_uv(uv_wb1)
		st_barrier.add_vertex(v_wlb1)
		st_barrier.set_uv(uv_wt1)
		st_barrier.add_vertex(v_wlt1)
		st_barrier.set_uv(uv_wb2)
		st_barrier.add_vertex(v_wlb2)

		st_barrier.set_uv(uv_wt1)
		st_barrier.add_vertex(v_wlt1)
		st_barrier.set_uv(uv_wt2)
		st_barrier.add_vertex(v_wlt2)
		st_barrier.set_uv(uv_wb2)
		st_barrier.add_vertex(v_wlb2)

		collision_faces.append(v_wlb1)
		collision_faces.append(v_wlt1)
		collision_faces.append(v_wlb2)
		collision_faces.append(v_wlt1)
		collision_faces.append(v_wlt2)
		collision_faces.append(v_wlb2)

		# --- 5. Right Safety Barrier Ribbon ---
		var v_wrb1 = wall_right_bot[i]
		var v_wrt1 = wall_right_top[i]
		var v_wrb2 = wall_right_bot[next_idx]
		var v_wrt2 = wall_right_top[next_idx]

		st_barrier.set_uv(uv_wb1)
		st_barrier.add_vertex(v_wrb1)
		st_barrier.set_uv(uv_wb2)
		st_barrier.add_vertex(v_wrb2)
		st_barrier.set_uv(uv_wt1)
		st_barrier.add_vertex(v_wrt1)

		st_barrier.set_uv(uv_wt1)
		st_barrier.add_vertex(v_wrt1)
		st_barrier.set_uv(uv_wb2)
		st_barrier.add_vertex(v_wrb2)
		st_barrier.set_uv(uv_wt2)
		st_barrier.add_vertex(v_wrt2)

		collision_faces.append(v_wrb1)
		collision_faces.append(v_wrb2)
		collision_faces.append(v_wrt1)
		collision_faces.append(v_wrt1)
		collision_faces.append(v_wrb2)
		collision_faces.append(v_wrt2)

	# Generate smooth vertex normals and tangents for safety barriers
	st_barrier.generate_normals()

	var mesh_road = MeshInstance3D.new()
	mesh_road.name = "ContinuousRoadMesh"
	mesh_road.mesh = st_road.commit()
	road_body.add_child(mesh_road)

	var mesh_curb = MeshInstance3D.new()
	mesh_curb.name = "ContinuousCurbMesh"
	mesh_curb.mesh = st_curb.commit()
	road_body.add_child(mesh_curb)

	var mesh_barrier = MeshInstance3D.new()
	mesh_barrier.name = "ContinuousBarrierMesh"
	mesh_barrier.mesh = st_barrier.commit()
	road_body.add_child(mesh_barrier)

	# Continuous collision shape matching road, curbs, and barriers 1:1
	var col = CollisionShape3D.new()
	col.name = "ContinuousRoadCol"
	var concave_shape = ConcavePolygonShape3D.new()
	concave_shape.backface_collision = true
	concave_shape.set_faces(collision_faces)
	col.shape = concave_shape
	road_body.add_child(col)

	add_child(road_body)

func build_track_segment(start_pt: Vector3, end_pt: Vector3, segment_index: int) -> void:
	var delta = end_pt - start_pt
	var angle_y = atan2(-delta.x, -delta.z)

	# Checkpoint
	var cp = RaceCheckpoint.new()
	cp.checkpoint_index = segment_index
	cp.is_finish_line = (segment_index == 0)
	cp.checkpoint_width = track_width
	cp.position = start_pt + Vector3(0, 0.5, 0)
	cp.rotation.y = angle_y
	add_child(cp)
	checkpoints.append(cp)

	# Apex Tire Wall at sharp corners
	if segment_index % 4 == 2:
		var tire = ModelCacheScript.get_prop("racing_tire_stack")
		if tire:
			tire.position = start_pt + Vector3(track_width * 0.5 + 2.0, 0.2, 0)
			tire.scale = Vector3(2.0, 2.0, 2.0)
			add_child(tire)



func create_box(pos: Vector3, size: Vector3, material_name: String) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = GameConstants.LAYER_WORLD
	body.collision_mask = 0
	body.position = pos

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	body.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = MaterialGenerator.get_material(material_name)
	body.add_child(mesh_inst)

	add_child(body)
	return body

func setup_racing_environment() -> void:
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	var sky_mat = ProceduralSkyMaterial.new()

	match track_theme.to_lower():
		"canyon":
			sky_mat.sky_top_color = Color(0.20, 0.45, 0.85)
			sky_mat.sky_horizon_color = Color(0.85, 0.65, 0.45)
			sky_mat.ground_bottom_color = Color(0.35, 0.20, 0.12)
			sky_mat.ground_horizon_color = Color(0.70, 0.45, 0.30)
			environment.ambient_light_color = Color(0.75, 0.55, 0.40)
			environment.ambient_light_energy = 1.2
			environment.fog_enabled = true
			environment.fog_light_color = Color(0.80, 0.60, 0.45)
			environment.fog_density = 0.0015
		"skyline":
			sky_mat.sky_top_color = Color(0.12, 0.18, 0.42)
			sky_mat.sky_horizon_color = Color(0.88, 0.40, 0.28)
			sky_mat.ground_bottom_color = Color(0.08, 0.08, 0.15)
			sky_mat.ground_horizon_color = Color(0.40, 0.22, 0.35)
			environment.ambient_light_color = Color(0.45, 0.40, 0.65)
			environment.ambient_light_energy = 1.1
			environment.fog_enabled = true
			environment.fog_light_color = Color(0.50, 0.30, 0.45)
			environment.fog_density = 0.0012
		_: # "metropolis" / "neon"
			sky_mat.sky_top_color = Color(0.12, 0.20, 0.42)
			sky_mat.sky_horizon_color = Color(0.24, 0.38, 0.65)
			sky_mat.ground_bottom_color = Color(0.10, 0.14, 0.22)
			sky_mat.ground_horizon_color = Color(0.16, 0.24, 0.38)
			environment.ambient_light_color = Color(0.60, 0.70, 0.90)
			environment.ambient_light_energy = 1.6
			environment.fog_enabled = false

	var sky = Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.35
	environment.tonemap_white = 6.0

	environment.glow_enabled = true
	environment.glow_intensity = 0.45
	environment.glow_bloom = 0.18

	env.environment = environment
	add_child(env)

	var sun = DirectionalLight3D.new()
	if track_theme.to_lower() == "neon":
		sun.rotation_degrees = Vector3(-65, 30, 0)
		sun.light_color = Color(0.85, 0.92, 1.0)
		sun.light_energy = 1.8
	elif track_theme.to_lower() == "canyon":
		sun.rotation_degrees = Vector3(-45, 55, 0)
		sun.light_color = Color(1.0, 0.92, 0.80)
		sun.light_energy = 2.4
	else:
		sun.rotation_degrees = Vector3(-50, 40, 0)
		sun.light_color = Color(1.0, 0.88, 0.82)
		sun.light_energy = 2.0
	sun.shadow_enabled = true
	add_child(sun)

	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(40, -140, 0)
	fill.light_color = Color(0.35, 0.50, 0.80)
	fill.light_energy = 0.7
	fill.shadow_enabled = false
	add_child(fill)
