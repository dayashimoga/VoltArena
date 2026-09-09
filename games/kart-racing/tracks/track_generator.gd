class_name TrackGenerator
extends Node3D

## TrackGenerator: Procedurally synthesizes championship racing circuits for Drift Storm.
## Consumes the authoritative RaceSpline model for all 3 circuits:
## 1. Volt Speedway (Championship stadium raceway with asphalt, pit wall, grandstands, and floodlights)
## 2. Canyon Run (Expansive red rock mesa with elevation changes and rock arches)
## 3. Skyline Drift (High-altitude twilight expressway through skyscrapers)

signal track_built(waypoints: Array[Vector3], checkpoints: Array[RaceCheckpoint])

@export var track_theme: String = "metropolis" # "metropolis"/"speedway", "canyon", "skyline"
@export var track_width: float = 14.0

var waypoints: Array[Vector3] = []
var checkpoints: Array[RaceCheckpoint] = []
var race_spline = null # Instance of RaceSpline

const RaceSplineScript = preload("res://games/kart-racing/tracks/race_spline.gd")
const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

func _ready() -> void:
	build_circuit()

func build_circuit() -> void:
	var circuit_nodes: Array[Vector3] = []
	var norm_theme = track_theme.to_lower()
	if norm_theme == "volt_speedway" or norm_theme == "speedway" or norm_theme == "neon":
		norm_theme = "metropolis"

	match norm_theme:
		"canyon":
			circuit_nodes = [
				Vector3(0, 0, 0),
				Vector3(0, 0, -45),
				Vector3(10, 0.5, -80),
				Vector3(35, 2.0, -120),
				Vector3(75, 4.5, -150),
				Vector3(125, 7.0, -170),
				Vector3(180, 8.5, -150),
				Vector3(225, 8.0, -100),
				Vector3(240, 7.0, -45),
				Vector3(225, 5.0, 15),
				Vector3(185, 3.5, 65),
				Vector3(145, 2.0, 100),
				Vector3(95, 0.8, 105),
				Vector3(50, 0.0, 80),
				Vector3(20, 0.0, 50),
				Vector3(0, 0, 30)
			]
			# Canyon ground terrain: Red rock sandstone floor (not green turf!)
			create_box(Vector3(110.0, -1.8, -25.0), Vector3(600.0, 3.0, 600.0), "canyon_rock")
			# Majestic Canyon rock mesas and natural tunnel arches
			var mesa_coords = [
				Vector3(-55, 18, -80), Vector3(85, 26, -200), Vector3(275, 24, -40),
				Vector3(85, 22, 145), Vector3(-45, 16, 60), Vector3(185, 16, 25),
				Vector3(140, 30, -85), Vector3(25, 15, -165)
			]
			for p in mesa_coords:
				create_box(p, Vector3(56.0, 42.0, 56.0), "canyon_rock")

		"skyline":
			circuit_nodes = [
				Vector3(0, 0, 0),
				Vector3(0, 0, -50),
				Vector3(5, 0.5, -90),
				Vector3(25, 1.5, -130),
				Vector3(60, 4.0, -170),
				Vector3(110, 6.5, -200),
				Vector3(170, 8.0, -200),
				Vector3(220, 6.5, -165),
				Vector3(250, 4.5, -110),
				Vector3(240, 2.0, -50),
				Vector3(210, 0.5, 5),
				Vector3(165, 0.0, 50),
				Vector3(115, 0.0, 80),
				Vector3(60, 0.0, 70),
				Vector3(20, 0.0, 50),
				Vector3(0, 0, 30)
			]
			# Skyline high-altitude foundation: Dark asphalt metropolis deck
			create_box(Vector3(115.0, -1.8, -55.0), Vector3(600.0, 3.0, 600.0), "asphalt_track")
			var building_coords = [
				[Vector3(-50, 0, -80), "a", Vector3(6, 14, 6)],
				[Vector3(80, 0, -225), "b", Vector3(7, 16, 7)],
				[Vector3(185, 0, -225), "c", Vector3(6, 15, 6)],
				[Vector3(280, 0, -60), "d", Vector3(7, 18, 7)],
				[Vector3(160, 0, 105), "a", Vector3(6, 12, 6)],
				[Vector3(-35, 0, 75), "c", Vector3(5, 8, 5)],
				[Vector3(90, 0, -40), "b", Vector3(8, 20, 8)]
			]
			for bc in building_coords:
				var bld = ModelCacheScript.get_building(bc[1])
				if bld:
					bld.position = bc[0]
					bld.scale = bc[2]
					add_child(bld)
				else:
					create_box(bc[0] + Vector3(0, 30, 0), Vector3(45, 60, 45), "dark_hull")

		_: # "metropolis" / "speedway" -> VOLT SPEEDWAY
			circuit_nodes = [
				Vector3(0, 0, 0),
				Vector3(0, 0, -45),
				Vector3(0, 0, -85),
				Vector3(18, 0, -125),
				Vector3(50, 0.2, -155),
				Vector3(95, 0.5, -175),
				Vector3(150, 0.5, -175),
				Vector3(205, 0.2, -145),
				Vector3(225, 0.0, -90),
				Vector3(215, 0.0, -35),
				Vector3(175, 0.0, 18),
				Vector3(130, 0.0, 48),
				Vector3(85, 0.0, 68),
				Vector3(45, 0.0, 58),
				Vector3(18, 0.0, 48),
				Vector3(0, 0, 30)
			]
			# Paddock & stadium asphalt lot foundation (NOT green lawn turf!)
			create_box(Vector3(110.0, -1.8, -50.0), Vector3(650.0, 3.0, 650.0), "asphalt_track")
			# Runoff apron in infield and outfield
			create_box(Vector3(110.0, -0.08, -50.0), Vector3(480.0, 0.16, 480.0), "grimy_concrete")
			# Paddock architecture buildings in the background
			var stadium_buildings = [
				[Vector3(-45, 0, -85), "c", Vector3(5, 6, 5)],
				[Vector3(75, 0, -205), "a", Vector3(6, 10, 6)],
				[Vector3(170, 0, -205), "b", Vector3(6, 11, 6)],
				[Vector3(250, 0, -60), "c", Vector3(6, 12, 6)],
				[Vector3(155, 0, 95), "d", Vector3(6, 10, 6)]
			]
			for np in stadium_buildings:
				var b = ModelCacheScript.get_building(np[1])
				if b:
					b.position = np[0]
					b.scale = np[2]
					add_child(b)
				else:
					create_box(np[0] + Vector3(0, 20, 0), Vector3(40, 40, 40), "dark_hull")

	waypoints = circuit_nodes

	# Instantiate single authoritative RaceSpline
	race_spline = RaceSplineScript.new(circuit_nodes, track_width)

	# Build continuous seamless road ribbon with matching collision and verified +Y normals
	_build_continuous_road_foundation()

	# Build Checkpoints at each authored node along the spline
	for i in range(circuit_nodes.size()):
		var p1 = circuit_nodes[i]
		var p2 = circuit_nodes[(i + 1) % circuit_nodes.size()]
		build_track_segment(p1, p2, i)

	# Checkered Start/Finish Line spanning the asphalt road
	var fl_overlay = MeshInstance3D.new()
	var fl_plane = QuadMesh.new()
	fl_plane.size = Vector2(track_width, 3.2)
	fl_plane.orientation = PlaneMesh.FACE_Y
	fl_overlay.mesh = fl_plane
	fl_overlay.position = circuit_nodes[0] + Vector3(0, 0.08, 0)
	fl_overlay.material_override = MaterialGenerator.get_material("checkered_flag")
	add_child(fl_overlay)

	# Painted Starting Grid Boxes along the home straight
	for grid_idx in range(6):
		var gz = 6.0 + grid_idx * 3.5
		var gx = -2.2 if grid_idx % 2 == 0 else 2.2
		var g_box = MeshInstance3D.new()
		var g_mesh = QuadMesh.new()
		g_mesh.size = Vector2(2.4, 3.5)
		g_mesh.orientation = PlaneMesh.FACE_Y
		g_box.mesh = g_mesh
		g_box.position = Vector3(gx, 0.085, gz)
		g_box.material_override = MaterialGenerator.create_pbr_material(Color(0.96, 0.96, 0.98, 0.85), 0.1, 0.4)
		add_child(g_box)

	# Production Start/Finish Overhead Gantry with Turbo Kart Rush banner & lights
	var gantry = MeshBuilder.build_start_gantry(track_width)
	gantry.position = circuit_nodes[0] + Vector3(0, 0, -2.0)
	add_child(gantry)

	# Trackside Sponsor Advertising Boards on Barriers along the straight
	for sb_z in [-35.0, -15.0, 15.0, 35.0]:
		var sb_l = MeshInstance3D.new()
		var sb_mesh = BoxMesh.new()
		sb_mesh.size = Vector3(0.08, 1.1, 8.0)
		sb_l.mesh = sb_mesh
		sb_l.position = Vector3(-track_width * 0.5 - 1.25, 0.75, sb_z)
		sb_l.material_override = MaterialGenerator.get_material("stadium_banner_blue" if sb_z < 0 else "stadium_banner_orange")
		add_child(sb_l)

		var sb_r = MeshInstance3D.new()
		sb_r.mesh = sb_mesh
		sb_r.position = Vector3(track_width * 0.5 + 1.25, 0.75, sb_z)
		sb_r.material_override = MaterialGenerator.get_material("stadium_banner_orange" if sb_z < 0 else "stadium_banner_blue")
		add_child(sb_r)

	# Production Grandstands with Spectator Crowds along the home straight
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

	# PowerUp Item Pickups placed along the circuit
	var item_indices = [1, int(circuit_nodes.size() * 0.35), int(circuit_nodes.size() * 0.65), int(circuit_nodes.size() * 0.85)]
	for idx in item_indices:
		var item = PowerUpItem.new()
		item.position = circuit_nodes[idx] + Vector3(0, 0.4, 0)
		add_child(item)

	setup_racing_environment()
	track_built.emit(waypoints, checkpoints)

func _build_continuous_road_foundation() -> void:
	if not race_spline or race_spline.samples.is_empty():
		return

	var samples = race_spline.samples
	var n = samples.size()
	var total_dist = race_spline.track_length

	var curb_w = 1.2
	var curb_h = 0.08
	var wall_h = 1.8
	var road_y_offset = Vector3.UP * 0.06 # Elevates road above ground plane to prevent z-fighting

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
		var s = samples[i]
		var rl = s["left"] + road_y_offset
		var rr = s["right"] + road_y_offset
		var binormal = s["binormal"]
		var normal = s["normal"]

		road_left.append(rl)
		road_right.append(rr)

		# 3D Rumble Curbs (raised slightly above asphalt with bevel)
		var cli = rl + normal * 0.02
		var clo = rl - binormal * curb_w + normal * curb_h
		curb_left_inner.append(cli)
		curb_left_outer.append(clo)

		var cri = rr + normal * 0.02
		var cro = rr + binormal * curb_w + normal * curb_h
		curb_right_inner.append(cri)
		curb_right_outer.append(cro)

		# Metallic Safety Barriers placed outside the curbs
		var wlb = clo - binormal * 0.08
		var wlt = wlb + Vector3.UP * wall_h
		wall_left_bot.append(wlb)
		wall_left_top.append(wlt)

		var wrb = cro + binormal * 0.08
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
		var d1 = samples[i]["dist"]
		var d2 = samples[next_idx]["dist"] if next_idx != 0 else total_dist

		# --- 1. Road Surface Ribbon ---
		# Counter-clockwise winding: (v_rl1, v_rr1, v_rl2) and (v_rr1, v_rr2, v_rl2)
		# Guarantees surface normal points strictly UP (+Y)
		var v_rl1 = road_left[i]
		var v_rr1 = road_right[i]
		var v_rl2 = road_left[next_idx]
		var v_rr2 = road_right[next_idx]

		var uv_rl1 = Vector2(0.0, d1 / 12.0)
		var uv_rr1 = Vector2(1.0, d1 / 12.0)
		var uv_rl2 = Vector2(0.0, d2 / 12.0)
		var uv_rr2 = Vector2(1.0, d2 / 12.0)

		# Triangle 1
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rl1)
		st_road.add_vertex(v_rl1)
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rr1)
		st_road.add_vertex(v_rr1)
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rl2)
		st_road.add_vertex(v_rl2)

		# Triangle 2
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rr1)
		st_road.add_vertex(v_rr1)
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rr2)
		st_road.add_vertex(v_rr2)
		st_road.set_normal(Vector3.UP)
		st_road.set_uv(uv_rl2)
		st_road.add_vertex(v_rl2)

		# Add road surface to collision faces
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

		st_curb.set_uv(uv_clo1)
		st_curb.add_vertex(v_clo1)
		st_curb.set_uv(uv_cli1)
		st_curb.add_vertex(v_cli1)
		st_curb.set_uv(uv_clo2)
		st_curb.add_vertex(v_clo2)

		st_curb.set_uv(uv_cli1)
		st_curb.add_vertex(v_cli1)
		st_curb.set_uv(uv_cli2)
		st_curb.add_vertex(v_cli2)
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

		st_curb.set_uv(uv_cri1)
		st_curb.add_vertex(v_cri1)
		st_curb.set_uv(uv_cro1)
		st_curb.add_vertex(v_cro1)
		st_curb.set_uv(uv_cri2)
		st_curb.add_vertex(v_cri2)

		st_curb.set_uv(uv_cro1)
		st_curb.add_vertex(v_cro1)
		st_curb.set_uv(uv_cro2)
		st_curb.add_vertex(v_cro2)
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

	# Generate tangents for proper rendering across all view angles
	st_road.generate_tangents()

	st_curb.generate_normals()
	st_curb.generate_tangents()

	st_barrier.generate_normals()
	st_barrier.generate_tangents()

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
	var norm_theme = track_theme.to_lower()

	match norm_theme:
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
		_: # "metropolis" / "speedway" -> VOLT SPEEDWAY
			sky_mat.sky_top_color = Color(0.10, 0.16, 0.32)
			sky_mat.sky_horizon_color = Color(0.20, 0.32, 0.55)
			sky_mat.ground_bottom_color = Color(0.08, 0.10, 0.16)
			sky_mat.ground_horizon_color = Color(0.14, 0.20, 0.32)
			environment.ambient_light_color = Color(0.55, 0.65, 0.85)
			environment.ambient_light_energy = 1.4
			environment.fog_enabled = true
			environment.fog_light_color = Color(0.15, 0.22, 0.38)
			environment.fog_density = 0.0008

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
	if norm_theme == "canyon":
		sun.rotation_degrees = Vector3(-45, 55, 0)
		sun.light_color = Color(1.0, 0.92, 0.80)
		sun.light_energy = 2.4
	elif norm_theme == "skyline":
		sun.rotation_degrees = Vector3(-50, 40, 0)
		sun.light_color = Color(1.0, 0.88, 0.82)
		sun.light_energy = 2.0
	else: # "metropolis"
		sun.rotation_degrees = Vector3(-60, 30, 0)
		sun.light_color = Color(0.90, 0.95, 1.0)
		sun.light_energy = 2.2
	sun.shadow_enabled = true
	add_child(sun)

	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(40, -140, 0)
	fill.light_color = Color(0.35, 0.50, 0.80)
	fill.light_energy = 0.7
	fill.shadow_enabled = false
	add_child(fill)
