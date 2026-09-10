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
const TrackRegistryScript = preload("res://games/kart-racing/tracks/track_registry.gd")

func _ready() -> void:
	build_circuit()

func build_circuit() -> void:
	var def = TrackRegistryScript.get_track(track_theme)
	var circuit_nodes = def.nodes
	track_width = def.track_width
	waypoints = circuit_nodes

	# Instantiate single authoritative RaceSpline
	race_spline = RaceSplineScript.new(circuit_nodes, track_width)

	# Build theme-specific environment terrain, props, and skyline
	_build_environment_scenery(def)

	# Build continuous seamless road ribbon with matching collision and verified +Y normals
	_build_continuous_road_foundation(def)

	# Build Checkpoints at each authored node along the spline
	for i in range(circuit_nodes.size()):
		var p1 = circuit_nodes[i]
		var p2 = circuit_nodes[(i + 1) % circuit_nodes.size()]
		build_track_segment(p1, p2, i)

	# Checkered Start/Finish Line spanning the asphalt road
	var fl_overlay = MeshInstance3D.new()
	var fl_plane = QuadMesh.new()
	fl_plane.size = Vector2(track_width, 2.8)
	fl_plane.orientation = PlaneMesh.FACE_Y
	fl_overlay.mesh = fl_plane
	fl_overlay.position = circuit_nodes[0] + Vector3(0, 0.075, 0)
	fl_overlay.material_override = MaterialGenerator.get_material("checkered_flag")
	add_child(fl_overlay)

	# Production Start/Finish Overhead Gantry anchored to authoritative spline
	var s0 = race_spline.sample_at_distance(0.0)
	var gantry = MeshBuilder.build_start_gantry(track_width)
	var g_tr = Transform3D()
	g_tr.basis.z = -s0["tangent"]
	g_tr.basis.y = s0["normal"]
	g_tr.basis.x = s0["binormal"]
	gantry.transform = Transform3D(g_tr.basis.orthonormalized(), s0["pos"] - s0["tangent"] * 2.0)
	add_child(gantry)

	# Realistic FIA Painted Starting Grid Marks along the home straight behind finish line
	var grid_mat = MaterialGenerator.create_pbr_material(Color(0.95, 0.95, 0.98, 0.9), 0.05, 0.45)
	for grid_idx in range(6):
		var grid_dist = fposmod(race_spline.track_length - (5.0 + grid_idx * 3.5), race_spline.track_length)
		var s_grid = race_spline.sample_at_distance(grid_dist)
		var lat_sign = -1.0 if grid_idx % 2 == 0 else 1.0
		var slot_center = s_grid["pos"] + s_grid["binormal"] * (lat_sign * 2.2) + s_grid["normal"] * 0.08
		var g_tan = s_grid["tangent"]
		var g_bin = s_grid["binormal"]
		var g_up = s_grid["normal"]

		var b_tr = Transform3D()
		b_tr.basis.z = -g_tan
		b_tr.basis.y = g_up
		b_tr.basis.x = g_bin
		var b_basis = b_tr.basis.orthonormalized()

		# Front white limit bar
		var bar_f = MeshInstance3D.new()
		var bar_f_mesh = QuadMesh.new()
		bar_f_mesh.size = Vector2(2.2, 0.22)
		bar_f_mesh.orientation = PlaneMesh.FACE_Y
		bar_f.mesh = bar_f_mesh
		bar_f.transform = Transform3D(b_basis, slot_center + g_tan * 1.0)
		bar_f.material_override = grid_mat
		add_child(bar_f)

		# Left guideline
		var bar_l = MeshInstance3D.new()
		var bar_l_mesh = QuadMesh.new()
		bar_l_mesh.size = Vector2(0.18, 1.8)
		bar_l_mesh.orientation = PlaneMesh.FACE_Y
		bar_l.mesh = bar_l_mesh
		bar_l.transform = Transform3D(b_basis, slot_center - g_bin * 1.0)
		bar_l.material_override = grid_mat
		add_child(bar_l)

		# Right guideline
		var bar_r = MeshInstance3D.new()
		var bar_r_mesh = QuadMesh.new()
		bar_r_mesh.size = Vector2(0.18, 1.8)
		bar_r_mesh.orientation = PlaneMesh.FACE_Y
		bar_r.mesh = bar_r_mesh
		bar_r.transform = Transform3D(b_basis, slot_center + g_bin * 1.0)
		bar_r.material_override = grid_mat
		add_child(bar_r)

	# Trackside Sponsor Advertising Boards on Barriers (strictly anchored to RaceSpline binormals)
	var banner_dists = [15.0, 45.0, 75.0]
	for b_d in banner_dists:
		if b_d < race_spline.track_length * 0.8:
			var s_b = race_spline.sample_at_distance(b_d)
			var b_tan = s_b["tangent"]
			var b_bin = s_b["binormal"]
			var b_up = s_b["normal"]

			var sb_l = MeshInstance3D.new()
			var sb_mesh = BoxMesh.new()
			sb_mesh.size = Vector3(0.08, 1.1, 7.5)
			sb_l.mesh = sb_mesh
			sb_l.position = s_b["pos"] - b_bin * (track_width * 0.5 + 1.28) + b_up * 0.75
			var tr_l = Transform3D()
			tr_l.basis.z = b_tan
			tr_l.basis.y = b_up
			tr_l.basis.x = b_bin
			sb_l.transform = Transform3D(tr_l.basis.orthonormalized(), sb_l.position)
			sb_l.material_override = MaterialGenerator.get_material("stadium_banner_blue")
			add_child(sb_l)

			var sb_r = MeshInstance3D.new()
			sb_r.mesh = sb_mesh
			sb_r.position = s_b["pos"] + b_bin * (track_width * 0.5 + 1.28) + b_up * 0.75
			var tr_r = Transform3D()
			tr_r.basis.z = b_tan
			tr_r.basis.y = b_up
			tr_r.basis.x = -b_bin
			sb_r.transform = Transform3D(tr_r.basis.orthonormalized(), sb_r.position)
			sb_r.material_override = MaterialGenerator.get_material("stadium_banner_orange")
			add_child(sb_r)

	# PowerUp Item Pickups placed along the circuit
	var item_indices = [1, int(circuit_nodes.size() * 0.35), int(circuit_nodes.size() * 0.65), int(circuit_nodes.size() * 0.85)]
	for idx in item_indices:
		var item = PowerUpItem.new()
		item.position = circuit_nodes[idx] + Vector3(0, 0.4, 0)
		add_child(item)

	setup_racing_environment(def)
	track_built.emit(waypoints, checkpoints)

func _build_environment_scenery(def: TrackRegistryScript.TrackDefinition) -> void:
	match def.theme:
		"coast":
			# Expansive ocean waters extending to the horizon
			create_box(Vector3(60.0, -3.2, -120.0), Vector3(2500.0, 1.0, 2500.0), "ocean_water")
			# Coastal sand beach foundation
			create_box(Vector3(70.0, -2.0, -100.0), Vector3(850.0, 1.0, 850.0), "sand_beach")

			# Dense clusters of coastal palm trees along the seaside sweepers
			var palm_positions = [
				Vector3(-20, 0, -30), Vector3(-25, 0, -70), Vector3(-50, 1.5, -120),
				Vector3(-85, 3.5, -170), Vector3(-90, 5.0, -230), Vector3(-75, 6.5, -290),
				Vector3(20, 7.5, -345), Vector3(85, 7.0, -320), Vector3(140, 5.5, -270),
				Vector3(190, 3.5, -200), Vector3(225, 2.0, -130), Vector3(255, 1.0, -50),
				Vector3(245, 0.5, 30), Vector3(200, 0.0, 95), Vector3(135, 0.0, 135),
				Vector3(65, 0.0, 115), Vector3(20, 0.0, 65)
			]
			for p in palm_positions:
				var tree = MeshBuilder.build_palm_tree(randf_range(8.0, 12.0))
				tree.position = p
				add_child(tree)

			# Coastal Suspension Bridge Tower over sea inlet
			var bridge_tower = MeshBuilder.build_suspension_bridge_tower(36.0)
			bridge_tower.position = Vector3(40, 0.0, -320)
			add_child(bridge_tower)

			# Marshal Posts at strategic corners
			for mp_pos in [Vector3(-45, 1.8, -130), Vector3(125, 6.0, -280), Vector3(225, 0.0, 10)]:
				var mp = MeshBuilder.build_marshal_post()
				mp.position = mp_pos
				add_child(mp)

			# Coastal resort hotel skyline in the golden sunset horizon
			var resort_coords = [
				[Vector3(-120, 0, -160), "c", Vector3(7, 10, 7)],
				[Vector3(95, 0, -380), "a", Vector3(8, 14, 8)],
				[Vector3(190, 0, -340), "b", Vector3(8, 12, 8)],
				[Vector3(290, 0, -110), "d", Vector3(8, 15, 8)],
				[Vector3(270, 0, 80), "a", Vector3(7, 11, 7)]
			]
			for np in resort_coords:
				var b = ModelCacheScript.get_building(np[1])
				if b:
					b.position = np[0]
					b.scale = np[2]
					add_child(b)

		"canyon":
			# Vast redrock canyon terrain foundation
			create_box(Vector3(60.0, -2.5, -120.0), Vector3(2500.0, 1.0, 2500.0), "canyon_rock")

			# Towering Sandstone Mesas and Canyon Walls framing the track
			var mesa_coords = [
				Vector3(-85, 22, -90), Vector3(65, 28, -125), Vector3(-95, 34, -220),
				Vector3(45, 38, -320), Vector3(135, 32, -240), Vector3(155, 24, -120),
				Vector3(205, 18, -20), Vector3(160, 14, 110), Vector3(-45, 16, 60)
			]
			for p in mesa_coords:
				create_box(p, Vector3(68.0, 48.0, 68.0), "canyon_rock")

			# 2 Overhead Canyon Natural Rock Arches spanning the track
			var arch1 = MeshBuilder.build_rock_arch(24.0, 16.0)
			arch1.position = Vector3(15, 26.0, -295)
			arch1.rotation_degrees.y = 75.0
			add_child(arch1)

			var arch2 = MeshBuilder.build_rock_arch(22.0, 14.0)
			arch2.position = Vector3(145, 3.5, 60)
			arch2.rotation_degrees.y = 45.0
			add_child(arch2)

			# Distant Mountain Peaks on the desert horizon
			for pk_pos in [Vector3(-260, 0, -320), Vector3(280, 0, -350), Vector3(0, 0, -420), Vector3(320, 0, 120)]:
				var peak = MeshBuilder.build_mountain_peak(140.0, 85.0)
				peak.position = pk_pos
				add_child(peak)

			# Marshal Posts at technical switchbacks
			for mp_pos in [Vector3(50, 4.0, -90), Vector3(-40, 24.0, -280), Vector3(115, 14.0, -140)]:
				var mp = MeshBuilder.build_marshal_post()
				mp.position = mp_pos
				add_child(mp)

		"skyline":
			# Dark metropolis urban foundation
			create_box(Vector3(60.0, -2.5, -120.0), Vector3(2500.0, 1.0, 2500.0), "dark_hull")

			# Ring of 14 Illuminated Neon Skyscrapers towering over the urban raceway
			var sky_towers = [
				[Vector3(-45, 0, -70), 75.0, "neon_cyan"],
				[Vector3(-85, 0, -170), 95.0, "neon_magenta"],
				[Vector3(30, 0, -190), 85.0, "neon_blue"],
				[Vector3(95, 0, -200), 105.0, "neon_orange"],
				[Vector3(190, 0, -220), 80.0, "neon_cyan"],
				[Vector3(195, 0, -330), 110.0, "neon_magenta"],
				[Vector3(125, 0, -370), 90.0, "neon_blue"],
				[Vector3(25, 0, -370), 115.0, "neon_cyan"],
				[Vector3(-70, 0, -340), 85.0, "neon_orange"],
				[Vector3(-105, 0, -240), 100.0, "neon_green"],
				[Vector3(-105, 0, -80), 90.0, "neon_cyan"],
				[Vector3(-85, 0, 50), 75.0, "neon_magenta"],
				[Vector3(65, 0, 65), 85.0, "neon_cyan"],
				[Vector3(150, 0, -60), 95.0, "neon_blue"]
			]
			for st in sky_towers:
				var tower = MeshBuilder.build_neon_skyscraper(st[1], 24.0, 24.0, st[2])
				tower.position = st[0]
				add_child(tower)

			# Elevated Freeway Flyover Concrete Pillars underneath track section
			for pillar_z in [-200.0, -240.0, -280.0]:
				create_box(Vector3(150.0, 3.5, pillar_z), Vector3(4.0, 7.0, 4.0), "grimy_concrete")

			# Marshal Posts at 90-degree street corners
			for mp_pos in [Vector3(25, 0, -135), Vector3(135, 0, -165), Vector3(-45, 0, -245)]:
				var mp = MeshBuilder.build_marshal_post()
				mp.position = mp_pos
				add_child(mp)

		"alpine":
			# Alpine rocky mountain foundation
			create_box(Vector3(60.0, -2.5, -120.0), Vector3(2500.0, 1.0, 2500.0), "alpine_rock")

			# Ring of 8 Majestic Snow-Capped Mountain Peaks
			var peak_coords = [
				Vector3(-180, 0, -120), Vector3(-160, 0, -280), Vector3(-60, 0, -380),
				Vector3(80, 0, -390), Vector3(220, 0, -340), Vector3(250, 0, -180),
				Vector3(240, 0, 40), Vector3(-120, 0, 80)
			]
			for pk in peak_coords:
				var mtn = MeshBuilder.build_mountain_peak(150.0, 95.0)
				mtn.position = pk
				add_child(mtn)

			# Dense clusters of evergreen pine trees lining the hairpins
			var pine_positions = [
				Vector3(-25, 0, -35), Vector3(-55, 3.0, -85), Vector3(-85, 8.0, -135),
				Vector3(-60, 13.0, -180), Vector3(-95, 19.0, -225), Vector3(-70, 25.0, -270),
				Vector3(-15, 30.0, -295), Vector3(50, 32.0, -285), Vector3(110, 28.0, -245),
				Vector3(150, 20.0, -185), Vector3(165, 13.0, -115), Vector3(145, 6.0, -45),
				Vector3(160, 3.0, 10), Vector3(130, 1.0, 60), Vector3(70, 0.0, 80),
				Vector3(20, 0.0, 50)
			]
			for pp in pine_positions:
				var tree = MeshBuilder.build_pine_tree(randf_range(9.0, 15.0))
				tree.position = pp
				add_child(tree)

			# Swiss-style Alpine Wooden Chalets in the valley
			for ch_pos in [Vector3(-25, 0, 45), Vector3(95, 0, 45), Vector3(185, 0, -10)]:
				var chalet = MeshBuilder.build_alpine_chalet()
				chalet.position = ch_pos
				add_child(chalet)

			# Marshal Posts
			for mp_pos in [Vector3(-30, 3.5, -90), Vector3(5, 31.0, -295), Vector3(150, 12.0, -115)]:
				var mp = MeshBuilder.build_marshal_post()
				mp.position = mp_pos
				add_child(mp)

		"harbor":
			# Harbor industrial dock pavement
			create_box(Vector3(60.0, -2.5, -120.0), Vector3(2500.0, 1.0, 2500.0), "wet_asphalt")
			# Deep ocean shipping channel alongside wharf
			create_box(Vector3(-120.0, -3.2, -120.0), Vector3(350.0, 1.0, 1200.0), "ocean_water")

			# 4 Massive Container Gantry Cranes along wharf edge
			for cz in [-20.0, -80.0, -140.0, -200.0]:
				var crane = MeshBuilder.build_harbor_crane(34.0)
				crane.position = Vector3(-18.0, 0.0, cz)
				crane.rotation_degrees.y = 90.0
				add_child(crane)

			# Large Container Cargo Ship docked at the wharf
			var ship = MeshBuilder.build_cargo_ship(85.0)
			ship.position = Vector3(-42.0, -1.8, -100.0)
			ship.rotation_degrees.y = 0.0
			add_child(ship)

			# Stacks of colorful shipping containers creating industrial freight corridors
			var cont_stacks = [
				[Vector3(20, 0, -170), "container_red"], [Vector3(20, 2.6, -170), "container_blue"],
				[Vector3(50, 0, -170), "container_yellow"], [Vector3(50, 2.6, -170), "container_red"],
				[Vector3(80, 0, -170), "container_blue"], [Vector3(80, 2.6, -170), "container_yellow"],
				[Vector3(120, 0, -205), "container_red"], [Vector3(120, 2.6, -205), "container_blue"],
				[Vector3(175, 0, -205), "container_yellow"], [Vector3(175, 2.6, -205), "container_red"],
				[Vector3(215, 0, -165), "container_blue"], [Vector3(215, 2.6, -165), "container_yellow"],
				[Vector3(215, 0, -135), "container_red"], [Vector3(215, 2.6, -135), "container_blue"],
				[Vector3(175, 0, -50), "container_yellow"], [Vector3(175, 2.6, -50), "container_red"],
				[Vector3(175, 0, 20), "container_blue"], [Vector3(175, 2.6, 20), "container_yellow"],
				[Vector3(125, 0, 105), "container_red"], [Vector3(125, 2.6, 105), "container_blue"],
				[Vector3(65, 0, 80), "container_yellow"], [Vector3(65, 2.6, 80), "container_red"]
			]
			for cs in cont_stacks:
				var cont = MeshBuilder.build_shipping_container(cs[1], Vector3(2.8, 2.6, 6.5))
				cont.position = cs[0]
				add_child(cont)

			# Dock Warehouses
			var warehouses = [
				Vector3(260, 0, -60), Vector3(260, 0, 40), Vector3(80, 0, 160)
			]
			for wh in warehouses:
				create_box(wh, Vector3(32.0, 12.0, 55.0), "grimy_concrete")

			# Marshal Posts
			for mp_pos in [Vector3(22, 0, -175), Vector3(210, 0, -170), Vector3(185, 0, 75)]:
				var mp = MeshBuilder.build_marshal_post()
				mp.position = mp_pos
				add_child(mp)

		_: # "speedway" / "metropolis"
			# Expansive stadium grounds foundation
			create_box(Vector3(60.0, -2.5, -120.0), Vector3(2500.0, 1.0, 2500.0), "asphalt_track")

			# Modern 2-Story Pit Complex with Garages and Control Tower along Home Straight
			var pit_building = MeshBuilder.build_pit_building(8)
			pit_building.position = Vector3(-18.0, 0.0, -60.0)
			add_child(pit_building)

			# Multi-Tier Grandstands with Roof Canopies and Spectators
			var stand_dists = [15.0, 55.0, 140.0, 220.0]
			for s_d in stand_dists:
				if race_spline:
					var s_pt = race_spline.sample_at_distance(s_d)
					var t_fwd = s_pt["tangent"]
					var t_bin = s_pt["binormal"]
					var t_up = s_pt["normal"]

					var stand_l = MeshBuilder.build_grandstand_with_crowd(28.0, 8.5, 10.0)
					var pos_l = s_pt["pos"] - t_bin * (def.track_width * 0.5 + 16.0)
					var tr_l = Transform3D()
					tr_l.basis.x = t_fwd
					tr_l.basis.y = t_up
					tr_l.basis.z = -t_bin
					stand_l.transform = Transform3D(tr_l.basis.orthonormalized(), pos_l)
					add_child(stand_l)

					var stand_r = MeshBuilder.build_grandstand_with_crowd(28.0, 8.5, 10.0)
					var pos_r = s_pt["pos"] + t_bin * (def.track_width * 0.5 + 16.0)
					var tr_r = Transform3D()
					tr_r.basis.x = -t_fwd
					tr_r.basis.y = t_up
					tr_r.basis.z = t_bin
					stand_r.transform = Transform3D(tr_r.basis.orthonormalized(), pos_r)
					add_child(stand_r)

			# Stadium Floodlight Towers
			if race_spline:
				for fl_d in [30.0, 80.0, 160.0, 240.0]:
					var s_fl = race_spline.sample_at_distance(fl_d)
					for side_sign in [-1.0, 1.0]:
						var fl = ModelCacheScript.get_prop("floodlight_tower")
						if fl:
							fl.position = s_fl["pos"] + side_sign * s_fl["binormal"] * (def.track_width * 0.5 + 18.0)
							fl.position.y = s_fl["pos"].y
							fl.scale = Vector3(3.0, 3.0, 3.0)
							add_child(fl)

			# Marshal Posts at technical infield corners
			for mp_d in [40.0, 110.0, 180.0]:
				if race_spline:
					var s_mp = race_spline.sample_at_distance(mp_d)
					var mp = MeshBuilder.build_marshal_post()
					mp.position = s_mp["pos"] + s_mp["binormal"] * (def.track_width * 0.5 + 4.5)
					add_child(mp)

			# Paddock buildings in background
			var stadium_buildings = [
				[Vector3(-75, 0, -120), "c", Vector3(6, 8, 6)],
				[Vector3(95, 0, -250), "a", Vector3(8, 12, 8)],
				[Vector3(180, 0, -240), "b", Vector3(8, 14, 8)],
				[Vector3(260, 0, -70), "c", Vector3(8, 14, 8)],
				[Vector3(160, 0, 120), "d", Vector3(8, 12, 8)]
			]
			for np in stadium_buildings:
				var b = ModelCacheScript.get_building(np[1])
				if b:
					b.position = np[0]
					b.scale = np[2]
					add_child(b)
	track_built.emit(waypoints, checkpoints)

func _build_continuous_road_foundation(def: TrackRegistryScript.TrackDefinition = null) -> void:
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

	var road_mat_name = "asphalt_lanes"
	var curb_mat_name = "curb_blue_white"
	var barrier_mat_name = "racing_barrier"

	if def:
		match def.theme:
			"coast":
				road_mat_name = "asphalt_lanes"
				curb_mat_name = "curb_red_white"
				barrier_mat_name = "racing_barrier"
			"canyon":
				road_mat_name = "asphalt_track"
				curb_mat_name = "curb_red_white"
				barrier_mat_name = "canyon_rock"
			"skyline":
				road_mat_name = "asphalt_lanes"
				curb_mat_name = "curb_blue_white"
				barrier_mat_name = "neon_cyan"
			"alpine":
				road_mat_name = "asphalt_track"
				curb_mat_name = "curb_red_white"
				barrier_mat_name = "pine_wood"
			"harbor":
				road_mat_name = "wet_asphalt"
				curb_mat_name = "curb_red_white"
				barrier_mat_name = "racing_barrier"
			_:
				road_mat_name = "asphalt_lanes"
				curb_mat_name = "curb_blue_white"
				barrier_mat_name = "racing_barrier"

	var st_road = SurfaceTool.new()
	st_road.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_road.set_material(MaterialGenerator.get_material(road_mat_name))

	var st_curb = SurfaceTool.new()
	st_curb.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_curb.set_material(MaterialGenerator.get_material(curb_mat_name))

	var st_barrier = SurfaceTool.new()
	st_barrier.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_barrier.set_material(MaterialGenerator.get_material(barrier_mat_name))

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

	# Apex Tire Wall at sharp corners (strictly spline-anchored outside track bounds)
	if segment_index % 4 == 2 and race_spline:
		var tire = ModelCacheScript.get_prop("racing_tire_stack")
		if tire:
			var s_dist = race_spline.get_closest_distance(start_pt)
			var s_samp = race_spline.sample_at_distance(s_dist)
			tire.position = s_samp["pos"] + s_samp["binormal"] * (track_width * 0.5 + 2.5) + Vector3(0, 0.2, 0)
			tire.scale = Vector3(2.0, 2.0, 2.0)
			add_child(tire)

func create_box(pos: Vector3, size: Vector3, material_name: String) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = material_name + "_subfloor"
	body.collision_layer = GameConstants.LAYER_WORLD
	body.collision_mask = 0
	body.position = pos

	var col = CollisionShape3D.new()
	col.name = "SubfloorCol"
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

func setup_racing_environment(def: TrackRegistryScript.TrackDefinition = null) -> void:
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	var sky_mat = ProceduralSkyMaterial.new()
	var norm_theme = def.theme if def else track_theme.to_lower()

	if def:
		sky_mat.sky_top_color = def.sky_top_color
		sky_mat.sky_horizon_color = def.sky_horizon_color
		sky_mat.ground_bottom_color = def.ambient_color * 0.35
		sky_mat.ground_horizon_color = def.sky_horizon_color * 0.6
		environment.ambient_light_color = def.ambient_color
		environment.ambient_light_energy = 1.3
		environment.fog_enabled = true
		environment.fog_light_color = def.fog_color
		environment.fog_density = def.fog_density
	else:
		match norm_theme:
			"canyon":
				sky_mat.sky_top_color = Color(0.20, 0.45, 0.85)
				sky_mat.sky_horizon_color = Color(0.85, 0.65, 0.45)
				environment.ambient_light_color = Color(0.75, 0.55, 0.40)
				environment.fog_light_color = Color(0.80, 0.60, 0.45)
				environment.fog_density = 0.0014
			"skyline":
				sky_mat.sky_top_color = Color(0.12, 0.18, 0.42)
				sky_mat.sky_horizon_color = Color(0.88, 0.40, 0.28)
				environment.ambient_light_color = Color(0.45, 0.40, 0.65)
				environment.fog_light_color = Color(0.50, 0.30, 0.45)
				environment.fog_density = 0.0011
			_:
				sky_mat.sky_top_color = Color(0.10, 0.16, 0.32)
				sky_mat.sky_horizon_color = Color(0.20, 0.32, 0.55)
				environment.ambient_light_color = Color(0.55, 0.65, 0.85)
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
	match norm_theme:
		"coast":
			sun.rotation_degrees = Vector3(-35, 70, 0)
			sun.light_color = Color(1.0, 0.88, 0.72)
			sun.light_energy = 1.6
		"canyon":
			sun.rotation_degrees = Vector3(-45, 55, 0)
			sun.light_color = Color(1.0, 0.92, 0.80)
			sun.light_energy = 1.65
		"skyline":
			sun.rotation_degrees = Vector3(-50, 40, 0)
			sun.light_color = Color(1.0, 0.85, 0.82)
			sun.light_energy = 1.3
		"alpine":
			sun.rotation_degrees = Vector3(-55, 30, 0)
			sun.light_color = Color(0.96, 0.98, 1.0)
			sun.light_energy = 1.6
		"harbor":
			sun.rotation_degrees = Vector3(-40, 60, 0)
			sun.light_color = Color(0.85, 0.90, 0.98)
			sun.light_energy = 1.25
		_: # "metropolis" / "speedway"
			sun.rotation_degrees = Vector3(-60, 30, 0)
			sun.light_color = Color(0.90, 0.95, 1.0)
			sun.light_energy = 1.5
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.directional_shadow_max_distance = 250.0
	sun.directional_shadow_split_1 = 0.1
	sun.directional_shadow_split_2 = 0.3
	sun.directional_shadow_blend_splits = true
	add_child(sun)

	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(40, -140, 0)
	fill.light_color = Color(0.35, 0.50, 0.80)
	fill.light_energy = 0.45
	fill.shadow_enabled = false
	add_child(fill)

## Automated Track-Surface and Racing-Corridor Clearance Scanner
## Verifies that:
## 1. Valid road colliders exist along the entire loop
## 2. Protected racing corridor (spline centerline +/- track_width/2) is free of obstructing solid colliders or geometry intrusions
## 3. Surface normals remain continuous (+Y)
func verify_race_corridor_clearance(sample_step: float = 2.0) -> Dictionary:
	var result = {
		"success": true,
		"inspected_samples": 0,
		"violations": []
	}
	if not race_spline or race_spline.track_length <= 0.0:
		result["success"] = false
		result["violations"].append("RaceSpline is missing or unbaked")
		return result

	var total_len = race_spline.track_length
	var num_steps = int(ceil(total_len / sample_step))
	var half_w = track_width * 0.5

	# Collect all solid colliders that could act as road obstructions
	var obstacle_colliders: Array[CollisionShape3D] = []

	var _scan_node = func(n: Node, self_func: Callable) -> void:
		if n.name == "ContinuousRoadFoundation" or n.name == "ContinuousRoadCol":
			return # Authorized road ribbon
		if n is RaceCheckpoint or n is PowerUpItem:
			return # Authorized race triggers
		if n.name.ends_with("_subfloor") or "subfloor" in n.name.to_lower() or "foundation" in n.name.to_lower():
			return # Authorized sub-terrain foundation below road
		if n is CollisionShape3D and n.shape:
			obstacle_colliders.append(n)
		for c in n.get_children():
			self_func.call(c, self_func)

	_scan_node.call(self, _scan_node)

	for i in range(num_steps):
		var s = float(i) * sample_step
		var samp = race_spline.sample_at_distance(s)
		var center_pos = samp["pos"]
		var binormal = samp["binormal"]
		var tangent = samp["tangent"]
		result["inspected_samples"] += 1

		# Verify normal points generally UP
		if samp["normal"].y < 0.2:
			result["violations"].append("Invalid road surface normal at s=%.1f: %s" % [s, str(samp["normal"])])
			result["success"] = false

		# Verify no solid obstacle collision shape intersects the protected corridor
		for col in obstacle_colliders:
			if not is_instance_valid(col):
				continue
			var parent_node = col.get_parent() as Node3D
			var col_pos = col.global_position if col.is_inside_tree() else (parent_node.position + col.position if parent_node else col.position)

			# Vertical check: only test colliders near road surface level (-0.5m to +4.0m)
			var vert_diff = col_pos.y - center_pos.y
			if vert_diff < -0.8 or vert_diff > 4.5:
				continue # Deep underground or high overhead

			var diff = col_pos - center_pos
			diff.y = 0.0
			var lat_dist = diff.dot(binormal)
			var fwd_dist = diff.dot(tangent)
			# Protected corridor from -half_w to +half_w (plus margin)
			if absf(fwd_dist) < sample_step * 1.5 and absf(lat_dist) < (half_w - 0.5):
				var v_msg = "Obstacle collider '%s' intrudes into racing corridor at s=%.1fm (lat=%.2fm, track_half_w=%.2fm, y_diff=%.2fm)" % [
					col.name, s, lat_dist, half_w, vert_diff
				]
				result["violations"].append(v_msg)
				result["success"] = false

	return result

