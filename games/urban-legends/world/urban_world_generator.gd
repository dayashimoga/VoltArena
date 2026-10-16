class_name UrbanWorldGenerator
extends Node3D

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanDistrictDefinitions = preload("res://games/urban-legends/world/urban_district_definitions.gd")
const UrbanRoadNetwork = preload("res://games/urban-legends/world/urban_road_network.gd")
const UrbanPropFactory = preload("res://games/urban-legends/world/urban_prop_factory.gd")

## Massive 2000m x 2000m Open-World Scene Generator for Urban Legends.
## Assembles 8 contiguous districts, procedural roads, elevated flyovers,
## PBR architecture, stunt kickers, vegetation, and zero-obstruction collision.
## STRICT ZERO-PRIMITIVE MANDATE: All visible terrain, roads, curbs, and backdrop mountains use ArrayMeshes.

var road_network: UrbanRoadNetwork = null
var props_container: Node3D = null
var roads_container: Node3D = null
var terrain_container: Node3D = null

# Safe spawn point registry (100+ points)
var verified_spawn_points: Array[Transform3D] = []

func _ready() -> void:
	generate_world()

func generate_world() -> void:
	_cleanup_children()

	road_network = UrbanRoadNetwork.new()

	terrain_container = Node3D.new()
	terrain_container.name = "TerrainContainer"
	add_child(terrain_container)

	roads_container = Node3D.new()
	roads_container.name = "RoadsContainer"
	add_child(roads_container)

	props_container = Node3D.new()
	props_container.name = "PropsContainer"
	add_child(props_container)

	_build_ground_planes()
	_build_road_meshes()
	_populate_district_props()
	_populate_stunt_kickers()
	_build_verified_spawns()

func _cleanup_children() -> void:
	for c in get_children():
		c.queue_free()

func _build_ground_planes() -> void:
	# Main base terrain plate (2200m x 2200m)
	var ground = StaticBody3D.new()
	ground.name = "MainGroundTerrain"
	ground.collision_layer = UrbanConstants.LAYER_WORLD
	ground.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES

	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.24, 0.30, 0.22) # Parkland grass / urban soil
	g_mat.roughness = 0.9

	var mi = MeshInstance3D.new()
	mi.mesh = _create_ground_array_mesh(2200.0, 2.0, 2200.0)
	mi.material_override = g_mat
	mi.position = Vector3(0, -1.0, 0)
	ground.add_child(mi)

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2200.0, 2.0, 2200.0)
	col.shape = box
	col.position = Vector3(0, -1.0, 0)
	ground.add_child(col)

	terrain_container.add_child(ground)

	# South Ocean Water Plane (Bayview Promenade Coast)
	var ocean_mi = MeshInstance3D.new()
	ocean_mi.mesh = _create_ground_array_mesh(2500.0, 0.2, 800.0)
	var ocean_mat = StandardMaterial3D.new()
	ocean_mat.albedo_color = Color(0.08, 0.32, 0.55, 0.88)
	ocean_mat.metallic = 0.9
	ocean_mat.roughness = 0.08
	ocean_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ocean_mi.material_override = ocean_mat
	ocean_mi.position = Vector3(0, 0.1, -1350.0)
	terrain_container.add_child(ocean_mi)

	_build_perimeter_mountain_backdrop()

func _build_perimeter_mountain_backdrop() -> void:
	var mat_mountain = StandardMaterial3D.new()
	mat_mountain.albedo_color = Color(0.26, 0.28, 0.24) # Pine green / granite rock
	mat_mountain.roughness = 0.92

	var mat_granite = StandardMaterial3D.new()
	mat_granite.albedo_color = Color(0.38, 0.35, 0.32) # Rocky cliff face
	mat_granite.roughness = 0.95

	# North Mountain Wall (Z = -1150 to -1600)
	for i in range(8):
		var mx = -1000.0 + i * 280.0
		var mz = -1250.0 - (i * 37 % 200)
		var mh = 220.0 + (i * 53 % 140)
		var mw = 360.0 + (i * 29 % 100)

		var mi = MeshInstance3D.new()
		mi.mesh = _create_ridge_mountain_mesh(mw, mh, 350.0)
		mi.material_override = mat_mountain if i % 2 == 0 else mat_granite
		mi.position = Vector3(mx, 0.0, mz)
		terrain_container.add_child(mi)

	# East Mountain Ridge (X = 1150 to 1550)
	for i in range(7):
		var mx = 1250.0 + (i * 41 % 180)
		var mz = -800.0 + i * 260.0
		var mh = 190.0 + (i * 47 % 130)
		var mw = 340.0 + (i * 31 % 90)

		var mi = MeshInstance3D.new()
		mi.mesh = _create_ridge_mountain_mesh(320.0, mh, mw)
		mi.material_override = mat_mountain
		mi.position = Vector3(mx, 0.0, mz)
		terrain_container.add_child(mi)

	# West Horizon Hills (X = -1150 to -1550)
	for i in range(7):
		var mx = -1250.0 - (i * 43 % 160)
		var mz = -800.0 + i * 260.0
		var mh = 180.0 + (i * 39 % 120)
		var mw = 330.0 + (i * 23 % 90)

		var mi = MeshInstance3D.new()
		mi.mesh = _create_ridge_mountain_mesh(320.0, mh, mw)
		mi.material_override = mat_mountain if i % 2 == 0 else mat_granite
		mi.position = Vector3(mx, 0.0, mz)
		terrain_container.add_child(mi)

func _build_road_meshes() -> void:
	for seg in road_network.get_road_segments():
		var st: Vector3 = seg["start"]
		var en: Vector3 = seg["end"]
		var w: float = seg["width"]
		var dist = seg["length"]
		var center = (st + en) * 0.5
		var dir = seg["direction"]

		# Road Surface Mesh (Crowned asphalt deck, ArrayMesh)
		var road_mi = MeshInstance3D.new()
		road_mi.mesh = _create_crowned_road_mesh(w, 0.25, dist)
		var r_mat = StandardMaterial3D.new()
		var s_type = seg["surface"]
		if s_type == UrbanConstants.SURFACE_GRASS:
			r_mat.albedo_color = Color(0.28, 0.42, 0.18) # Grass drift path
			r_mat.roughness = 0.95
		elif s_type == UrbanConstants.SURFACE_DIRT:
			r_mat.albedo_color = Color(0.48, 0.38, 0.25) # Mountain gravel
			r_mat.roughness = 0.9
		else:
			var road_shader = load("res://games/urban-legends/world/shaders/road_asphalt.gdshader")
			if road_shader:
				var sm = ShaderMaterial.new()
				sm.shader = road_shader
				sm.set_shader_parameter("road_lanes", 4 if w >= 14.0 else 2)
				sm.set_shader_parameter("road_width_meters", w)
				sm.set_shader_parameter("wetness", 0.0)
				r_mat = sm
			else:
				r_mat.albedo_color = Color(0.19, 0.19, 0.21) # Crowned weathered asphalt
				r_mat.roughness = 0.76
				r_mat.metallic = 0.10

		road_mi.material_override = r_mat
		road_mi.position = center

		if dir.length_squared() > 0.001:
			var up_vec = Vector3.UP
			if absf(dir.dot(up_vec)) > 0.9:
				up_vec = Vector3.RIGHT
			road_mi.look_at_from_position(center, center + dir, up_vec)

		roads_container.add_child(road_mi)

		# Road Physical Collision Box (Invisible physics proxy)
		var body = StaticBody3D.new()
		body.collision_layer = UrbanConstants.LAYER_WORLD
		body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
		body.position = center
		if dir.length_squared() > 0.001:
			var up_vec = Vector3.UP
			if absf(dir.dot(up_vec)) > 0.9:
				up_vec = Vector3.RIGHT
			body.look_at_from_position(center, center + dir, up_vec)

		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = Vector3(w, 0.25, dist)
		col.shape = col_box
		body.add_child(col)
		roads_container.add_child(body)

		# Yellow Centerline Striping for Paved Asphalt Roads (Double-Yellow ArrayMesh)
		if s_type == UrbanConstants.SURFACE_ASPHALT:
			var stripe_mi = MeshInstance3D.new()
			stripe_mi.mesh = _create_double_yellow_stripes_mesh(0.42, 0.02, dist)
			var y_mat = StandardMaterial3D.new()
			y_mat.albedo_color = Color(0.95, 0.80, 0.12)
			y_mat.roughness = 0.50
			stripe_mi.material_override = y_mat
			stripe_mi.position = center + Vector3(0.0, 0.14, 0.0)
			if dir.length_squared() > 0.001:
				var up_vec = Vector3.UP
				if absf(dir.dot(up_vec)) > 0.9:
					up_vec = Vector3.RIGHT
				stripe_mi.look_at_from_position(stripe_mi.position, stripe_mi.position + dir, up_vec)
			roads_container.add_child(stripe_mi)

			# Raised Concrete Sidewalks and White Road Edge Markings
			var white_mat = StandardMaterial3D.new()
			white_mat.albedo_color = Color(0.90, 0.92, 0.95)
			white_mat.roughness = 0.55

			var sw_mat = StandardMaterial3D.new()
			sw_mat.albedo_color = Color(0.68, 0.67, 0.65) # Concrete pavement
			sw_mat.roughness = 0.85

			var right_dir = dir.cross(Vector3.UP).normalized()
			if right_dir.length_squared() > 0.01:
				var sw_w = 3.0 # 3m sidewalks
				for side in [-1.0, 1.0]:
					# White Edge Striping (ArrayMesh)
					var edge_mi = MeshInstance3D.new()
					edge_mi.mesh = _create_strip_mesh(0.18, 0.02, dist)
					edge_mi.material_override = white_mat
					edge_mi.position = center + right_dir * (side * (w * 0.5 - 0.22)) + Vector3(0.0, 0.14, 0.0)
					if dir.length_squared() > 0.001:
						var up_vec = Vector3.UP
						if absf(dir.dot(up_vec)) > 0.9:
							up_vec = Vector3.RIGHT
						edge_mi.look_at_from_position(edge_mi.position, edge_mi.position + dir, up_vec)
					roads_container.add_child(edge_mi)

					# 45-degree Chamfered Curb Bevel (0.14m vertical, zero car snagging, ArrayMesh)
					var curb_bevel_mi = MeshInstance3D.new()
					curb_bevel_mi.mesh = _create_curb_bevel_mesh(0.20, 0.14, dist)
					curb_bevel_mi.material_override = sw_mat
					curb_bevel_mi.position = center + right_dir * (side * (w * 0.5 + 0.10)) + Vector3(0.0, 0.07, 0.0)
					if dir.length_squared() > 0.001:
						var up_vec = Vector3.UP
						if absf(dir.dot(up_vec)) > 0.9:
							up_vec = Vector3.RIGHT
						curb_bevel_mi.look_at_from_position(curb_bevel_mi.position, curb_bevel_mi.position + dir, up_vec)
					roads_container.add_child(curb_bevel_mi)

					# Pedestrian Sidewalk (0.14m height, ArrayMesh)
					var sw_mi = MeshInstance3D.new()
					sw_mi.mesh = _create_sidewalk_mesh(sw_w - 0.20, 0.14, dist)
					sw_mi.material_override = sw_mat
					sw_mi.position = center + right_dir * (side * (w * 0.5 + 0.20 + (sw_w - 0.20) * 0.5)) + Vector3(0.0, 0.07, 0.0)
					if dir.length_squared() > 0.001:
						var up_vec = Vector3.UP
						if absf(dir.dot(up_vec)) > 0.9:
							up_vec = Vector3.RIGHT
						sw_mi.look_at_from_position(sw_mi.position, sw_mi.position + dir, up_vec)
					roads_container.add_child(sw_mi)

				# Streetlights along ground boulevards (every 30m)
				if center.y < 8.0 and dist >= 30.0:
					var lamp_spacing = 30.0
					var num_lamps = int(dist / lamp_spacing)
					for l in range(num_lamps):
						var t = (float(l) + 0.5) / float(num_lamps)
						var lamp_center = st.lerp(en, t)
						var lamp_side = 1.0 if l % 2 == 0 else -1.0
						var lamp_pos = lamp_center + right_dir * (lamp_side * (w * 0.5 + 1.8))
						var lamp = UrbanPropFactory.build_street_lamp(6.8)
						lamp.position = lamp_pos
						props_container.add_child(lamp)

		# Elevated viaduct support pillars
		if st.y > 10.0 and en.y > 10.0:
			var flyover = UrbanPropFactory.build_flyover_viaduct(dist, center.y, w)
			flyover.position = center
			if dir.length_squared() > 0.001:
				var up_vec = Vector3.UP
				if absf(dir.dot(up_vec)) > 0.9:
					up_vec = Vector3.RIGHT
				flyover.look_at_from_position(center, center + dir, up_vec)
			roads_container.add_child(flyover)

func _populate_district_props() -> void:
	# 1. District 1: Midtown & Financial Skyscraper Core (Manhattan-Inspired)
	var downtown_grid_x = [-480.0, -410.0, -340.0, -270.0, -200.0, -130.0, -60.0, 10.0, 80.0]
	var downtown_grid_z = [-480.0, -410.0, -340.0, -270.0, -200.0, -130.0, -60.0, 10.0, 80.0]
	for gx in downtown_grid_x:
		for gz in downtown_grid_z:
			var p = Vector3(gx, 0.0, gz)
			if not _is_obstructing_road(p, 17.5):
				# Alternate between Art Deco limestone towers with water tanks and steel curtain-wall skyscrapers
				if int(absf(gx + gz)) % 2 == 0:
					var ad_h = randf_range(85.0, 160.0)
					var ad_w = randf_range(26.0, 34.0)
					var ad_tower = UrbanPropFactory.build_art_deco_skyscraper(ad_h, ad_w, ad_w, Color(1.0, 0.88, 0.65))
					ad_tower.position = p
					props_container.add_child(ad_tower)
				else:
					var tower_h = randf_range(65.0, 135.0)
					var tower_w = randf_range(20.0, 28.0)
					var tower = UrbanPropFactory.build_skyscraper(tower_h, tower_w, tower_w, Color(0.2, 0.6, 1.0))
					tower.position = p
					props_container.add_child(tower)

	# 2. District 2: Historic Brownstone & Mixed-Use Neighborhood (Brooklyn / Greenwich Village)
	var brownstone_x = [220.0, 280.0, 340.0, 400.0, 460.0, 520.0, 580.0]
	var brownstone_z = [220.0, 290.0, 360.0, 430.0, 500.0, 570.0]
	for bx in brownstone_x:
		for bz in brownstone_z:
			var p = Vector3(bx, 0.0, bz)
			if not _is_obstructing_road(p, 14.0):
				var has_bodega = (int(absf(bx * 7.0 + bz)) % 5 == 0)
				var bs = UrbanPropFactory.build_brownstone_rowhouse(randf_range(16.0, 22.0), 12.0, 16.0, has_bodega)
				bs.position = p
				props_container.add_child(bs)

				# Historic Acorn streetlights along brownstone sidewalks
				if int(absf(bx + bz)) % 3 == 0:
					var acorn = UrbanPropFactory.build_acorn_streetlight(4.8)
					acorn.position = p + Vector3(7.0, 0.0, 0.0)
					props_container.add_child(acorn)

	# 3. District 3: Commercial Shopping & Theater Avenue (Broadway / Times Square)
	var theater_x = [-450.0, -350.0, -250.0, -150.0, -50.0, 50.0, 150.0]
	var theater_z = [120.0, 200.0, 280.0, 360.0, 440.0]
	for tx in theater_x:
		for tz in theater_z:
			var p = Vector3(tx, 0.0, tz)
			if not _is_obstructing_road(p, 16.0):
				var th = UrbanPropFactory.build_theater_marquee_store(randf_range(22.0, 38.0), 22.0, 20.0)
				th.position = p
				props_container.add_child(th)

				# Street furniture clusters & fire hydrants
				if int(absf(tx * 3.0 + tz)) % 4 == 0:
					var furn = UrbanPropFactory.build_street_furniture_cluster()
					furn.position = p + Vector3(0.0, 0.0, 11.5)
					props_container.add_child(furn)

				if int(absf(tx + tz * 2.0)) % 5 == 0:
					var hyd = UrbanPropFactory.build_fire_hydrant()
					hyd.position = p + Vector3(-9.0, 0.0, 11.5)
					props_container.add_child(hyd)

	# Subway entrance kiosks at key intersections
	var subway_spots = [
		Vector3(-100.0, 1.0, -120.0),
		Vector3(-100.0, 1.0, 120.0),
		Vector3(-250.0, 1.0, -250.0),
		Vector3(80.0, 1.0, 80.0)
	]
	for sp in subway_spots:
		var kiosk = UrbanPropFactory.build_subway_kiosk()
		kiosk.position = sp
		props_container.add_child(kiosk)

	# Cantilevered traffic signal mast arms at major intersections
	var signal_spots = [
		Vector3(-100.0, 1.0, -350.0),
		Vector3(-100.0, 1.0, -100.0),
		Vector3(-100.0, 1.0, 150.0),
		Vector3(-450.0, 1.0, -450.0),
		Vector3(100.0, 1.0, -450.0),
		Vector3(100.0, 1.0, 100.0)
	]
	for sig_pos in signal_spots:
		var sig = UrbanPropFactory.build_traffic_signal_mast(5.8, 7.5)
		sig.position = sig_pos + Vector3(9.0, 0.0, 0.0)
		props_container.add_child(sig)

	# 4. District 4: Central Metropolitan Park & Residential Courtyards
	var tree_spots = [
		Vector3(260, 6.0, -350), Vector3(340, 9.0, -260), Vector3(440, 13.0, -160),
		Vector3(520, 17.0, -60), Vector3(220, 5.0, -220), Vector3(320, 8.0, -120),
		Vector3(420, 12.0, -20), Vector3(500, 15.0, 40), Vector3(280, 7.0, -180),
		Vector3(360, 10.0, -80), Vector3(460, 14.0, 10), Vector3(540, 18.0, 90)
	]
	for p in tree_spots:
		if not _is_obstructing_road(p, 5.5):
			var tree = UrbanPropFactory.build_tree(randf_range(8.5, 12.0))
			tree.position = p
			props_container.add_child(tree)

	# Park Perimeter Ashlar Granite Stone Walls
	var wall_segments = [
		Vector3(200.0, 3.0, -480.0),
		Vector3(200.0, 6.0, -300.0),
		Vector3(200.0, 9.0, -100.0),
		Vector3(200.0, 12.0, 100.0)
	]
	for wp in wall_segments:
		var p_wall = UrbanPropFactory.build_park_stone_wall(40.0, 1.4)
		p_wall.position = wp
		props_container.add_child(p_wall)

	var bridge = UrbanPropFactory.build_stone_bridge(24.0, 10.0)
	bridge.position = Vector3(480, 15.0, 80)
	props_container.add_child(bridge)

	# 5. District 5: Industrial Waterfront, Docks & Suspension Bridge
	# Dockside Rail-Mounted Gantry Container Cranes
	var gantry_spots = [
		Vector3(-850.0, 0.0, 320.0),
		Vector3(-700.0, 0.0, 320.0)
	]
	for gp in gantry_spots:
		var gantry = UrbanPropFactory.build_gantry_crane(38.0, 32.0)
		gantry.position = gp
		props_container.add_child(gantry)

	# Shipping Containers
	var container_spots = [
		Vector3(-850, 0, 420), Vector3(-850, 2.9, 420),
		Vector3(-780, 0, 520), Vector3(-680, 0, 620),
		Vector3(-880, 0, 600), Vector3(-620, 0, 720),
		Vector3(-760, 0, 680), Vector3(-820, 0, 540)
	]
	var colors = [Color(0.8, 0.2, 0.15), Color(0.15, 0.45, 0.8), Color(0.2, 0.65, 0.25), Color(0.85, 0.65, 0.1)]
	for i in range(container_spots.size()):
		var p = container_spots[i]
		if not _is_obstructing_road(p, 7.0):
			var c = UrbanPropFactory.build_shipping_container(colors[i % colors.size()])
			c.position = p
			props_container.add_child(c)

	# Iconic Multi-Span Steel Suspension Bridge (450m span, 35m water clearance)
	var bridge_susp = UrbanPropFactory.build_suspension_bridge(450.0, 35.0, 24.0)
	bridge_susp.position = Vector3(0.0, 24.0, -1050.0)
	props_container.add_child(bridge_susp)

	# Tiled Vehicular Underpass Tunnel
	var tunnel = UrbanPropFactory.build_underpass_tunnel(80.0, 16.0, 6.0)
	tunnel.position = Vector3(-600.0, 1.0, -80.0)
	props_container.add_child(tunnel)

	# Horizon Skyline Continuity: Low-Draw-Call LOD2 Skyline Silhouettes across water
	var skyline = UrbanPropFactory.build_distant_skyline(1400.0)
	props_container.add_child(skyline)

	# 6. Continuous Modern Street Lamps along Grand Ave
	var lamp_z_coords = [-550, -475, -400, -325, -250, -175, -100, -25, 50, 125, 200, 275, 350]
	for z_val in lamp_z_coords:
		for x_side in [-1.0, 1.0]:
			var lamp_pos = Vector3(-100 + x_side * 9.5, 1.0, z_val)
			if not _is_obstructing_road(lamp_pos, 4.0):
				var lamp = UrbanPropFactory.build_street_lamp(6.8)
				lamp.position = lamp_pos
				lamp.rotation.y = PI * 0.5 if x_side > 0 else -PI * 0.5
				props_container.add_child(lamp)

func _populate_stunt_kickers() -> void:
	var colinas_ramp = UrbanPropFactory.build_stunt_ramp(8.0, 14.0, 3.8, 28.0)
	colinas_ramp.name = "StuntRamp_Colinas"
	colinas_ramp.position = Vector3(450.0, 52.0, 620.0)
	colinas_ramp.rotation.y = deg_to_rad(15.0)
	props_container.add_child(colinas_ramp)

	var freeway_ramp = UrbanPropFactory.build_stunt_ramp(10.0, 16.0, 3.5, 22.0)
	freeway_ramp.name = "StuntRamp_Freeway"
	freeway_ramp.position = Vector3(150.0, 18.0, 20.0)
	freeway_ramp.rotation.y = deg_to_rad(90.0)
	props_container.add_child(freeway_ramp)

	var glen_ramp = UrbanPropFactory.build_stunt_ramp(7.5, 12.0, 3.2, 25.0)
	glen_ramp.name = "StuntRamp_Glen"
	glen_ramp.position = Vector3(380.0, 11.0, -220.0)
	glen_ramp.rotation.y = deg_to_rad(-45.0)
	props_container.add_child(glen_ramp)

	var airport_ramp = UrbanPropFactory.build_stunt_ramp(14.0, 18.0, 4.2, 30.0)
	airport_ramp.name = "StuntRamp_Airport"
	airport_ramp.position = Vector3(-250.0, 1.0, -520.0)
	airport_ramp.rotation.y = deg_to_rad(-90.0)
	props_container.add_child(airport_ramp)

func _is_obstructing_road(pos: Vector3, clearance: float) -> bool:
	if not road_network:
		return false
	var nearest = road_network.get_nearest_road_point(pos)
	return nearest["distance"] < clearance

func _build_verified_spawns() -> void:
	verified_spawn_points.clear()

	var all_district_spawns = UrbanDistrictDefinitions.get_all_spawn_points()
	for sp in all_district_spawns:
		var pos = sp.origin
		var near = road_network.get_nearest_road_point(pos)
		if near["distance"] <= 35.0:
			var safe_t = Transform3D()
			safe_t.origin = near["point"] + Vector3(0, 0.4, 0)
			var dir: Vector3 = near["direction"]
			if dir.length_squared() > 0.001:
				safe_t = safe_t.looking_at(safe_t.origin + dir, Vector3.UP)
			verified_spawn_points.append(safe_t)

	var waypoints = road_network.get_traffic_waypoints()
	var step_stride = maxi(1, waypoints.size() / 60)
	for i in range(0, waypoints.size(), step_stride):
		var wp = waypoints[i]
		if verified_spawn_points.size() < 120:
			var p = wp.origin + Vector3(0, 0.4, 0)
			var safe_t = Transform3D()
			safe_t.origin = p
			var fwd = -wp.basis.z
			if fwd.length_squared() > 0.001:
				safe_t = safe_t.looking_at(p + fwd, Vector3.UP)
			verified_spawn_points.append(safe_t)

func get_verified_spawn_count() -> int:
	return verified_spawn_points.size()

func get_spawn_point(index: int) -> Transform3D:
	if verified_spawn_points.is_empty():
		return Transform3D(Basis.IDENTITY, Vector3(0, 1.5, 0))
	return verified_spawn_points[index % verified_spawn_points.size()]

func get_random_spawn_point() -> Transform3D:
	if verified_spawn_points.is_empty():
		return Transform3D(Basis.IDENTITY, Vector3(0, 1.5, 0))
	return verified_spawn_points[randi() % verified_spawn_points.size()]

# ==============================================================================
# PROCEDURAL ARRAYMESH GENERATORS FOR TERRAIN AND ROADS
# ==============================================================================

static func _create_ground_array_mesh(width: float, height: float, depth: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var hh = height * 0.5
	var hd = depth * 0.5

	# Top face (primary ground surface)
	var v0 = Vector3(-hw, hh, -hd)
	var v1 = Vector3(hw, hh, -hd)
	var v2 = Vector3(hw, hh, hd)
	var v3 = Vector3(-hw, hh, hd)

	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(0, 0)); st.add_vertex(v0)
	st.set_uv(Vector2(50, 0)); st.add_vertex(v1)
	st.set_uv(Vector2(50, 50)); st.add_vertex(v2)

	st.set_uv(Vector2(0, 0)); st.add_vertex(v0)
	st.set_uv(Vector2(50, 50)); st.add_vertex(v2)
	st.set_uv(Vector2(0, 50)); st.add_vertex(v3)

	return st.commit()

static func _create_ridge_mountain_mesh(width: float, height: float, depth: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var hd = depth * 0.5

	# Peak ridge line
	var r0 = Vector3(-hw * 0.25, height, 0.0)
	var r1 = Vector3(hw * 0.25, height * 0.95, 0.0)

	# Base footprint
	var b_fl = Vector3(-hw, 0.0, -hd)
	var b_fr = Vector3(hw, 0.0, -hd)
	var b_rr = Vector3(hw, 0.0, hd)
	var b_rl = Vector3(-hw, 0.0, hd)

	# Front slope (-Z)
	var n_front = Vector3(0, depth, -height).normalized()
	st.set_normal(n_front)
	st.set_uv(Vector2(0.5, 1)); st.add_vertex(r0)
	st.set_uv(Vector2(1, 0)); st.add_vertex(b_fr)
	st.set_uv(Vector2(0, 0)); st.add_vertex(b_fl)

	st.set_uv(Vector2(0.5, 1)); st.add_vertex(r0)
	st.set_uv(Vector2(1, 1)); st.add_vertex(r1)
	st.set_uv(Vector2(1, 0)); st.add_vertex(b_fr)

	# Back slope (+Z)
	var n_back = Vector3(0, depth, height).normalized()
	st.set_normal(n_back)
	st.set_uv(Vector2(0.5, 1)); st.add_vertex(r1)
	st.set_uv(Vector2(0, 0)); st.add_vertex(b_rl)
	st.set_uv(Vector2(1, 0)); st.add_vertex(b_rr)

	st.set_uv(Vector2(0.5, 1)); st.add_vertex(r1)
	st.set_uv(Vector2(0, 1)); st.add_vertex(r0)
	st.set_uv(Vector2(0, 0)); st.add_vertex(b_rl)

	# Left slope (-X)
	var n_left = Vector3(-height, width * 0.5, 0).normalized()
	st.set_normal(n_left)
	st.set_uv(Vector2(0.5, 1)); st.add_vertex(r0)
	st.set_uv(Vector2(0, 0)); st.add_vertex(b_fl)
	st.set_uv(Vector2(1, 0)); st.add_vertex(b_rl)

	# Right slope (+X)
	var n_right = Vector3(height, width * 0.5, 0).normalized()
	st.set_normal(n_right)
	st.set_uv(Vector2(0.5, 1)); st.add_vertex(r1)
	st.set_uv(Vector2(1, 0)); st.add_vertex(b_rr)
	st.set_uv(Vector2(0, 0)); st.add_vertex(b_fr)

	return st.commit()

static func _create_crowned_road_mesh(width: float, height: float, length: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var hl = length * 0.5
	var hh = height * 0.5
	var crown_h = 0.03 # 3cm crown elevation at road centerline for realistic drainage crossfall

	# Left edge, Center crest, Right edge
	var v_cl_front = Vector3(0, hh + crown_h, -hl)
	var v_cl_back  = Vector3(0, hh + crown_h, hl)
	var v_le_front = Vector3(-hw, hh, -hl)
	var v_le_back  = Vector3(-hw, hh, hl)
	var v_re_front = Vector3(hw, hh, -hl)
	var v_re_back  = Vector3(hw, hh, hl)

	# Left lane
	var n_left = Vector3(-crown_h, hw, 0).normalized()
	st.set_normal(n_left)
	st.set_uv(Vector2(0, 0)); st.add_vertex(v_le_front)
	st.set_uv(Vector2(0.5, 0)); st.add_vertex(v_cl_front)
	st.set_uv(Vector2(0.5, length * 0.2)); st.add_vertex(v_cl_back)

	st.set_uv(Vector2(0, 0)); st.add_vertex(v_le_front)
	st.set_uv(Vector2(0.5, length * 0.2)); st.add_vertex(v_cl_back)
	st.set_uv(Vector2(0, length * 0.2)); st.add_vertex(v_le_back)

	# Right lane
	var n_right = Vector3(crown_h, hw, 0).normalized()
	st.set_normal(n_right)
	st.set_uv(Vector2(0.5, 0)); st.add_vertex(v_cl_front)
	st.set_uv(Vector2(1, 0)); st.add_vertex(v_re_front)
	st.set_uv(Vector2(1, length * 0.2)); st.add_vertex(v_re_back)

	st.set_uv(Vector2(0.5, 0)); st.add_vertex(v_cl_front)
	st.set_uv(Vector2(1, length * 0.2)); st.add_vertex(v_re_back)
	st.set_uv(Vector2(0.5, length * 0.2)); st.add_vertex(v_cl_back)

	return st.commit()

static func _create_double_yellow_stripes_mesh(width: float, height: float, length: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stripe_w = 0.12 # 12cm stripe width
	var gap = 0.10     # 10cm gap between double-yellows
	var hl = length * 0.5
	var hh = height * 0.5

	# Left Stripe
	var lx0 = -(gap * 0.5 + stripe_w)
	var lx1 = -gap * 0.5
	st.set_normal(Vector3.UP)
	st.add_vertex(Vector3(lx0, hh, -hl)); st.add_vertex(Vector3(lx1, hh, -hl)); st.add_vertex(Vector3(lx1, hh, hl))
	st.add_vertex(Vector3(lx0, hh, -hl)); st.add_vertex(Vector3(lx1, hh, hl)); st.add_vertex(Vector3(lx0, hh, hl))

	# Right Stripe
	var rx0 = gap * 0.5
	var rx1 = gap * 0.5 + stripe_w
	st.set_normal(Vector3.UP)
	st.add_vertex(Vector3(rx0, hh, -hl)); st.add_vertex(Vector3(rx1, hh, -hl)); st.add_vertex(Vector3(rx1, hh, hl))
	st.add_vertex(Vector3(rx0, hh, -hl)); st.add_vertex(Vector3(rx1, hh, hl)); st.add_vertex(Vector3(rx0, hh, hl))

	return st.commit()

static func _create_strip_mesh(width: float, height: float, length: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var hl = length * 0.5
	var hh = height * 0.5

	st.set_normal(Vector3.UP)
	st.add_vertex(Vector3(-hw, hh, -hl)); st.add_vertex(Vector3(hw, hh, -hl)); st.add_vertex(Vector3(hw, hh, hl))
	st.add_vertex(Vector3(-hw, hh, -hl)); st.add_vertex(Vector3(hw, hh, hl)); st.add_vertex(Vector3(-hw, hh, hl))

	return st.commit()

static func _create_curb_bevel_mesh(width: float, height: float, length: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var hl = length * 0.5
	var hh = height * 0.5

	# 45-degree chamfered bevel face
	var v0 = Vector3(-hw, -hh, -hl)
	var v1 = Vector3(hw, hh, -hl)
	var v2 = Vector3(hw, hh, hl)
	var v3 = Vector3(-hw, -hh, hl)

	var bevel_n = Vector3(height, width, 0.0).normalized()
	st.set_normal(bevel_n)
	st.add_vertex(v0); st.add_vertex(v1); st.add_vertex(v2)
	st.add_vertex(v0); st.add_vertex(v2); st.add_vertex(v3)

	return st.commit()

static func _create_sidewalk_mesh(width: float, height: float, length: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var hl = length * 0.5
	var hh = height * 0.5

	# Top pavement surface
	var v0 = Vector3(-hw, hh, -hl)
	var v1 = Vector3(hw, hh, -hl)
	var v2 = Vector3(hw, hh, hl)
	var v3 = Vector3(-hw, hh, hl)

	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(0, 0)); st.add_vertex(v0)
	st.set_uv(Vector2(width * 0.5, 0)); st.add_vertex(v1)
	st.set_uv(Vector2(width * 0.5, length * 0.5)); st.add_vertex(v2)

	st.set_uv(Vector2(0, 0)); st.add_vertex(v0)
	st.set_uv(Vector2(width * 0.5, length * 0.5)); st.add_vertex(v2)
	st.set_uv(Vector2(0, length * 0.5)); st.add_vertex(v3)

	return st.commit()
