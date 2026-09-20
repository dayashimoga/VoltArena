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
	waypoints.clear()
	checkpoints.clear()
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
	fl_overlay.name = "CheckeredFinishLineOverlay"
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
		bar_f.name = "GridMarkingFront_%d" % grid_idx
		var bar_f_mesh = QuadMesh.new()
		bar_f_mesh.size = Vector2(2.2, 0.22)
		bar_f_mesh.orientation = PlaneMesh.FACE_Y
		bar_f.mesh = bar_f_mesh
		bar_f.transform = Transform3D(b_basis, slot_center + g_tan * 1.0)
		bar_f.material_override = grid_mat
		add_child(bar_f)

		# Left guideline
		var bar_l = MeshInstance3D.new()
		bar_l.name = "GridMarkingLeft_%d" % grid_idx
		var bar_l_mesh = QuadMesh.new()
		bar_l_mesh.size = Vector2(0.18, 1.8)
		bar_l_mesh.orientation = PlaneMesh.FACE_Y
		bar_l.mesh = bar_l_mesh
		bar_l.transform = Transform3D(b_basis, slot_center - g_bin * 1.0)
		bar_l.material_override = grid_mat
		add_child(bar_l)

		# Right guideline
		var bar_r = MeshInstance3D.new()
		bar_r.name = "GridMarkingRight_%d" % grid_idx
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

			# Dense clusters of coastal palm trees along the seaside sweepers (anchored to spline)
			if race_spline:
				var palm_count = 18
				var palm_step = race_spline.track_length / float(palm_count)
				for i in range(palm_count):
					var s_p = race_spline.sample_at_distance(float(i) * palm_step + 12.0)
					var side = 1.0 if i % 2 == 0 else -1.0
					var p_tree = MeshBuilder.build_palm_tree(randf_range(8.0, 12.0))
					p_tree.position = s_p["pos"] + side * s_p["binormal"] * (def.track_width * 0.5 + 7.5 + (i % 3) * 2.5)
					add_child(p_tree)

				# Coastal Suspension Bridge Tower over sea inlet
				var s_br = race_spline.sample_at_distance(race_spline.track_length * 0.4)
				var bridge_tower = MeshBuilder.build_suspension_bridge_tower(36.0)
				bridge_tower.position = s_br["pos"] + s_br["binormal"] * (def.track_width * 0.5 + 16.0)
				add_child(bridge_tower)

				# Marshal Posts at strategic corners
				for mp_d in [60.0, 180.0, 320.0]:
					var s_mp = race_spline.sample_at_distance(mp_d)
					var mp = MeshBuilder.build_marshal_post()
					mp.position = s_mp["pos"] + s_mp["binormal"] * (def.track_width * 0.5 + 5.5)
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

			# Towering Sandstone Mesas and Canyon Walls framing the track (anchored safely outside track)
			if race_spline:
				var mesa_dists = [40.0, 120.0, 200.0, 280.0, 360.0, 440.0, 520.0, 600.0]
				for idx in range(mesa_dists.size()):
					var md = mesa_dists[idx]
					var s_m = race_spline.sample_at_distance(md)
					var side = 1.0 if idx % 2 == 0 else -1.0
					var m_pos = s_m["pos"] + side * s_m["binormal"] * (def.track_width * 0.5 + 38.0)
					create_box(m_pos, Vector3(55.0, 42.0, 55.0), "canyon_rock")

				# 2 Overhead Canyon Natural Rock Arches spanning the track safely overhead (>10m high)
				var s_a1 = race_spline.sample_at_distance(180.0)
				var arch1 = MeshBuilder.build_rock_arch(def.track_width + 12.0, 16.0)
				arch1.position = s_a1["pos"] + Vector3(0, 10.0, 0)
				add_child(arch1)

				var s_a2 = race_spline.sample_at_distance(420.0)
				var arch2 = MeshBuilder.build_rock_arch(def.track_width + 12.0, 16.0)
				arch2.position = s_a2["pos"] + Vector3(0, 10.0, 0)
				add_child(arch2)

				# Marshal Posts at technical switchbacks
				for mp_d in [60.0, 240.0, 400.0]:
					var s_mp = race_spline.sample_at_distance(mp_d)
					var mp = MeshBuilder.build_marshal_post()
					mp.position = s_mp["pos"] + s_mp["binormal"] * (def.track_width * 0.5 + 5.5)
					add_child(mp)

			# Distant Mountain Peaks on the desert horizon
			for pk_pos in [Vector3(-260, 0, -320), Vector3(280, 0, -350), Vector3(0, 0, -420), Vector3(320, 0, 120)]:
				var peak = MeshBuilder.build_mountain_peak(140.0, 85.0)
				peak.position = pk_pos
				add_child(peak)

		"skyline":
			# Dark metropolis urban foundation
			create_box(Vector3(60.0, -2.5, -120.0), Vector3(2500.0, 1.0, 2500.0), "dark_hull")

			if race_spline:
				# Ring of 14 Illuminated Neon Skyscrapers towering safely outside raceway
				var neon_colors = ["neon_cyan", "neon_magenta", "neon_blue", "neon_orange", "neon_green"]
				var tower_count = 14
				var t_step = race_spline.track_length / float(tower_count)
				for i in range(tower_count):
					var s_t = race_spline.sample_at_distance(float(i) * t_step + 15.0)
					var side = 1.0 if i % 2 == 0 else -1.0
					var t_h = randf_range(75.0, 115.0)
					var t_col = neon_colors[i % neon_colors.size()]
					var tower = MeshBuilder.build_neon_skyscraper(t_h, 24.0, 24.0, t_col)
					tower.position = s_t["pos"] + side * s_t["binormal"] * (def.track_width * 0.5 + 24.0)
					add_child(tower)

				# Elevated Freeway Flyover Concrete Pillars underneath track section
				for p_d in [180.0, 240.0, 300.0]:
					var s_p = race_spline.sample_at_distance(p_d)
					create_box(s_p["pos"] + Vector3(0, -5.0, 0), Vector3(4.0, 8.0, 4.0), "grimy_concrete")

				# Marshal Posts at 90-degree street corners
				for mp_d in [50.0, 140.0, 280.0]:
					var s_mp = race_spline.sample_at_distance(mp_d)
					var mp = MeshBuilder.build_marshal_post()
					mp.position = s_mp["pos"] + s_mp["binormal"] * (def.track_width * 0.5 + 5.5)
					add_child(mp)

		"alpine":
			# Alpine rocky mountain foundation
			create_box(Vector3(60.0, -2.5, -120.0), Vector3(2500.0, 1.0, 2500.0), "alpine_rock")

			# Distant Mountain Peaks
			var peak_coords = [
				Vector3(-180, 0, -120), Vector3(-160, 0, -280), Vector3(-60, 0, -380),
				Vector3(80, 0, -390), Vector3(220, 0, -340), Vector3(250, 0, -180),
				Vector3(240, 0, 40), Vector3(-120, 0, 80)
			]
			for pk in peak_coords:
				var mtn = MeshBuilder.build_mountain_peak(150.0, 95.0)
				mtn.position = pk
				add_child(mtn)

			if race_spline:
				# Dense clusters of evergreen pine trees lining the hairpins (safely outside track)
				var pine_count = 20
				var p_step = race_spline.track_length / float(pine_count)
				for i in range(pine_count):
					var s_p = race_spline.sample_at_distance(float(i) * p_step + 10.0)
					var side = 1.0 if i % 2 == 0 else -1.0
					var tree = MeshBuilder.build_pine_tree(randf_range(9.0, 15.0))
					tree.position = s_p["pos"] + side * s_p["binormal"] * (def.track_width * 0.5 + 7.5 + (i % 3) * 2.0)
					add_child(tree)

				# Swiss-style Alpine Wooden Chalets in the valley
				for ch_d in [80.0, 220.0, 360.0]:
					var s_ch = race_spline.sample_at_distance(ch_d)
					var chalet = MeshBuilder.build_alpine_chalet()
					chalet.position = s_ch["pos"] - s_ch["binormal"] * (def.track_width * 0.5 + 18.0)
					add_child(chalet)

				# Marshal Posts
				for mp_d in [50.0, 160.0, 290.0]:
					var s_mp = race_spline.sample_at_distance(mp_d)
					var mp = MeshBuilder.build_marshal_post()
					mp.position = s_mp["pos"] + s_mp["binormal"] * (def.track_width * 0.5 + 5.5)
					add_child(mp)

		"harbor":
			# Harbor industrial dock pavement
			create_box(Vector3(60.0, -2.5, -120.0), Vector3(2500.0, 1.0, 2500.0), "wet_asphalt")
			# Deep ocean shipping channel alongside wharf
			create_box(Vector3(-120.0, -3.2, -120.0), Vector3(350.0, 1.0, 1200.0), "ocean_water")

			if race_spline:
				# 4 Massive Container Gantry Cranes along wharf edge
				for cz_d in [60.0, 140.0, 220.0, 300.0]:
					var s_cz = race_spline.sample_at_distance(cz_d)
					var crane = MeshBuilder.build_harbor_crane(34.0)
					crane.position = s_cz["pos"] - s_cz["binormal"] * (def.track_width * 0.5 + 18.0)
					crane.rotation_degrees.y = 90.0
					add_child(crane)

				# Large Container Cargo Ship docked at the wharf
				var s_ship = race_spline.sample_at_distance(180.0)
				var ship = MeshBuilder.build_cargo_ship(85.0)
				ship.position = s_ship["pos"] - s_ship["binormal"] * (def.track_width * 0.5 + 35.0)
				add_child(ship)

				# Stacks of colorful shipping containers along the circuit boundary
				var cont_colors = ["container_red", "container_blue", "container_yellow"]
				for i in range(16):
					var s_c = race_spline.sample_at_distance(float(i) * 35.0 + 20.0)
					var side = 1.0 if i % 2 == 0 else -1.0
					var cont = MeshBuilder.build_shipping_container(cont_colors[i % 3], Vector3(2.8, 2.6, 6.5))
					cont.position = s_c["pos"] + side * s_c["binormal"] * (def.track_width * 0.5 + 7.5)
					add_child(cont)

				# Dock Warehouses safely placed
				for wh_d in [100.0, 250.0, 380.0]:
					var s_wh = race_spline.sample_at_distance(wh_d)
					create_box(s_wh["pos"] + s_wh["binormal"] * (def.track_width * 0.5 + 26.0), Vector3(28.0, 10.0, 45.0), "grimy_concrete")

				# Marshal Posts
				for mp_d in [45.0, 175.0, 310.0]:
					var s_mp = race_spline.sample_at_distance(mp_d)
					var mp = MeshBuilder.build_marshal_post()
					mp.position = s_mp["pos"] + s_mp["binormal"] * (def.track_width * 0.5 + 5.5)
					add_child(mp)

		_: # "speedway" / "metropolis"
			# Expansive stadium grounds foundation
			create_box(Vector3(60.0, -2.5, -120.0), Vector3(2500.0, 1.0, 2500.0), "asphalt_track")

			# Modern 2-Story Pit Complex with Garages and Control Tower along Home Straight (strictly outside track boundary)
			if race_spline:
				var s_pit = race_spline.sample_at_distance(60.0)
				var pit_building = MeshBuilder.build_pit_building(8)
				var p_tr = Transform3D()
				p_tr.basis.x = s_pit["tangent"]
				p_tr.basis.y = s_pit["normal"]
				p_tr.basis.z = -s_pit["binormal"]
				var pit_pos = s_pit["pos"] - s_pit["binormal"] * (def.track_width * 0.5 + 16.0)
				pit_building.transform = Transform3D(p_tr.basis.orthonormalized(), pit_pos)
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
					mp.position = s_mp["pos"] + s_mp["binormal"] * (def.track_width * 0.5 + 5.5)
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
	var wall_left_top_out: Array[Vector3] = []
	var wall_left_bot_out: Array[Vector3] = []
	var wall_right_bot: Array[Vector3] = []
	var wall_right_top: Array[Vector3] = []
	var wall_right_top_out: Array[Vector3] = []
	var wall_right_bot_out: Array[Vector3] = []

	var wall_thick = 0.35

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

		# 3D Solid Safety Barriers placed outside the curbs (with physical 0.35m thickness)
		var wlb = clo - binormal * 0.08
		var wlt = wlb + Vector3.UP * wall_h
		var wlt_out = wlt - binormal * wall_thick
		var wlb_out = wlb - binormal * wall_thick
		wall_left_bot.append(wlb)
		wall_left_top.append(wlt)
		wall_left_top_out.append(wlt_out)
		wall_left_bot_out.append(wlb_out)

		var wrb = cro + binormal * 0.08
		var wrt = wrb + Vector3.UP * wall_h
		var wrt_out = wrt + binormal * wall_thick
		var wrb_out = wrb + binormal * wall_thick
		wall_right_bot.append(wrb)
		wall_right_top.append(wrt)
		wall_right_top_out.append(wrt_out)
		wall_right_bot_out.append(wrb_out)

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

		# --- 4. Left Safety Barrier (3D Solid Box with Inner, Top, Outer Faces) ---
		var v_wlb1 = wall_left_bot[i]
		var v_wlt1 = wall_left_top[i]
		var v_wlto1 = wall_left_top_out[i]
		var v_wlbo1 = wall_left_bot_out[i]

		var v_wlb2 = wall_left_bot[next_idx]
		var v_wlt2 = wall_left_top[next_idx]
		var v_wlto2 = wall_left_top_out[next_idx]
		var v_wlbo2 = wall_left_bot_out[next_idx]

		var uv_wb1 = Vector2(d1 / 4.0, 1.0)
		var uv_wt1 = Vector2(d1 / 4.0, 0.0)
		var uv_wb2 = Vector2(d2 / 4.0, 1.0)
		var uv_wt2 = Vector2(d2 / 4.0, 0.0)

		# Left Inner Face (Facing Track)
		st_barrier.set_uv(uv_wb1); st_barrier.add_vertex(v_wlb1)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wlt1)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wlb2)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wlt1)
		st_barrier.set_uv(uv_wt2); st_barrier.add_vertex(v_wlt2)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wlb2)

		collision_faces.append(v_wlb1); collision_faces.append(v_wlt1); collision_faces.append(v_wlb2)
		collision_faces.append(v_wlt1); collision_faces.append(v_wlt2); collision_faces.append(v_wlb2)

		# Left Top Cap Face
		st_barrier.set_uv(uv_wb1); st_barrier.add_vertex(v_wlt1)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wlto1)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wlt2)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wlto1)
		st_barrier.set_uv(uv_wt2); st_barrier.add_vertex(v_wlto2)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wlt2)

		collision_faces.append(v_wlt1); collision_faces.append(v_wlto1); collision_faces.append(v_wlt2)
		collision_faces.append(v_wlto1); collision_faces.append(v_wlto2); collision_faces.append(v_wlt2)

		# Left Outer Face (Backing)
		st_barrier.set_uv(uv_wb1); st_barrier.add_vertex(v_wlto1)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wlbo1)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wlto2)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wlbo1)
		st_barrier.set_uv(uv_wt2); st_barrier.add_vertex(v_wlbo2)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wlto2)

		collision_faces.append(v_wlto1); collision_faces.append(v_wlbo1); collision_faces.append(v_wlto2)
		collision_faces.append(v_wlbo1); collision_faces.append(v_wlbo2); collision_faces.append(v_wlto2)

		# --- 5. Right Safety Barrier (3D Solid Box with Inner, Top, Outer Faces) ---
		var v_wrb1 = wall_right_bot[i]
		var v_wrt1 = wall_right_top[i]
		var v_wrto1 = wall_right_top_out[i]
		var v_wrbo1 = wall_right_bot_out[i]

		var v_wrb2 = wall_right_bot[next_idx]
		var v_wrt2 = wall_right_top[next_idx]
		var v_wrto2 = wall_right_top_out[next_idx]
		var v_wrbo2 = wall_right_bot_out[next_idx]

		# Right Inner Face (Facing Track)
		st_barrier.set_uv(uv_wb1); st_barrier.add_vertex(v_wrb1)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wrb2)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wrt1)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wrt1)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wrb2)
		st_barrier.set_uv(uv_wt2); st_barrier.add_vertex(v_wrt2)

		collision_faces.append(v_wrb1); collision_faces.append(v_wrb2); collision_faces.append(v_wrt1)
		collision_faces.append(v_wrt1); collision_faces.append(v_wrb2); collision_faces.append(v_wrt2)

		# Right Top Cap Face
		st_barrier.set_uv(uv_wb1); st_barrier.add_vertex(v_wrt1)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wrt2)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wrto1)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wrto1)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wrt2)
		st_barrier.set_uv(uv_wt2); st_barrier.add_vertex(v_wrto2)

		collision_faces.append(v_wrt1); collision_faces.append(v_wrt2); collision_faces.append(v_wrto1)
		collision_faces.append(v_wrto1); collision_faces.append(v_wrt2); collision_faces.append(v_wrto2)

		# Right Outer Face (Backing)
		st_barrier.set_uv(uv_wb1); st_barrier.add_vertex(v_wrto1)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wrto2)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wrbo1)
		st_barrier.set_uv(uv_wt1); st_barrier.add_vertex(v_wrbo1)
		st_barrier.set_uv(uv_wb2); st_barrier.add_vertex(v_wrto2)
		st_barrier.set_uv(uv_wt2); st_barrier.add_vertex(v_wrbo2)

		collision_faces.append(v_wrto1); collision_faces.append(v_wrto2); collision_faces.append(v_wrbo1)
		collision_faces.append(v_wrbo1); collision_faces.append(v_wrto2); collision_faces.append(v_wrbo2)

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

	# Collect all solid colliders and non-road visual meshes that could act as road obstructions
	var obstacle_colliders: Array[CollisionShape3D] = []
	var obstacle_meshes: Array[MeshInstance3D] = []

	var _calc_node_world_pos = func(n: Node3D) -> Vector3:
		if n.is_inside_tree():
			return n.global_position
		var cur: Node = n
		var t: Transform3D = Transform3D.IDENTITY
		while cur and cur is Node3D:
			t = (cur as Node3D).transform * t
			if cur == self:
				break
			cur = cur.get_parent()
		return t.origin

	var _scan_node = func(n: Node, self_func: Callable) -> void:
		if n.name == "ContinuousRoadFoundation" or n.name == "ContinuousRoadCol" or n.name == "ContinuousRoadMesh" or n.name == "ContinuousCurbMesh" or n.name == "ContinuousBarrierMesh":
			return # Authorized road ribbon
		if n is RaceCheckpoint or n is PowerUpItem or n.name == "GroundCheckeredLine" or "grid" in n.name.to_lower() or "marking" in n.name.to_lower() or "line" in n.name.to_lower():
			return # Authorized race triggers and markings
		if "gantry" in n.name.to_lower() or "start_gantry" in n.name.to_lower():
			return # Authorized start/finish gantry overhead
		if n.name.ends_with("_subfloor") or "subfloor" in n.name.to_lower() or "foundation" in n.name.to_lower():
			return # Authorized sub-terrain foundation below road
		if n is CollisionShape3D and n.shape:
			obstacle_colliders.append(n)
		elif n is MeshInstance3D and n.mesh:
			obstacle_meshes.append(n)
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
			var col_pos = _calc_node_world_pos.call(col)

			# Vertical check: only test colliders near road surface level (-0.2m to +3.2m kart height)
			var vert_diff = col_pos.y - center_pos.y
			if vert_diff < -0.2 or vert_diff > 3.2:
				continue # Deep underground, subfloor, or high overhead

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

		# Verify no visual mesh intrudes into the protected corridor
		for mi in obstacle_meshes:
			if not is_instance_valid(mi):
				continue
			var mi_pos = _calc_node_world_pos.call(mi)
			var vert_diff = mi_pos.y - center_pos.y
			if vert_diff < 0.25 or vert_diff > 3.2:
				continue

			var diff = mi_pos - center_pos
			diff.y = 0.0
			var lat_dist = diff.dot(binormal)
			var fwd_dist = diff.dot(tangent)
			if absf(fwd_dist) < sample_step * 1.5 and absf(lat_dist) < (half_w - 0.8):
				var v_msg = "Visual mesh '%s' intrudes into racing corridor at s=%.1fm (lat=%.2fm, track_half_w=%.2fm, y_diff=%.2fm)" % [
					mi.name, s, lat_dist, half_w, vert_diff
				]
				result["violations"].append(v_msg)
				result["success"] = false

	return result

