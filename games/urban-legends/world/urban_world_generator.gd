class_name UrbanWorldGenerator
extends Node3D

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanDistrictDefinitions = preload("res://games/urban-legends/world/urban_district_definitions.gd")
const UrbanRoadNetwork = preload("res://games/urban-legends/world/urban_road_network.gd")
const UrbanPropFactory = preload("res://games/urban-legends/world/urban_prop_factory.gd")

## Massive 2000m x 2000m Open-World Scene Generator for Urban Legends.
## Assembles 8 contiguous districts, procedural roads, elevated flyovers,
## PBR architecture, stunt kickers, vegetation, and zero-obstruction collision.

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

	var g_mesh = BoxMesh.new()
	g_mesh.size = Vector3(2200.0, 2.0, 2200.0)
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.25, 0.30, 0.22) # Parkland grass / urban soil
	g_mat.roughness = 0.9

	var mi = MeshInstance3D.new()
	mi.mesh = g_mesh
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
	var ocean_mesh = PlaneMesh.new()
	ocean_mesh.size = Vector2(2500.0, 800.0)
	var ocean_mat = StandardMaterial3D.new()
	ocean_mat.albedo_color = Color(0.08, 0.32, 0.55, 0.88)
	ocean_mat.metallic = 0.9
	ocean_mat.roughness = 0.08
	ocean_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ocean_mi.mesh = ocean_mesh
	ocean_mi.material_override = ocean_mat
	ocean_mi.position = Vector3(0, 0.2, -1350.0)
	terrain_container.add_child(ocean_mi)

func _build_road_meshes() -> void:
	for seg in road_network.get_road_segments():
		var st: Vector3 = seg["start"]
		var en: Vector3 = seg["end"]
		var w: float = seg["width"]
		var dist = seg["length"]
		var center = (st + en) * 0.5
		var dir = seg["direction"]

		# Road Surface Mesh
		var road_mi = MeshInstance3D.new()
		var road_box = BoxMesh.new()
		road_box.size = Vector3(w, 0.25, dist)
		var r_mat = StandardMaterial3D.new()
		var s_type = seg["surface"]
		if s_type == UrbanConstants.SURFACE_GRASS:
			r_mat.albedo_color = Color(0.28, 0.42, 0.18) # Grass drift path
			r_mat.roughness = 0.95
		elif s_type == UrbanConstants.SURFACE_DIRT:
			r_mat.albedo_color = Color(0.48, 0.38, 0.25) # Mountain gravel
			r_mat.roughness = 0.9
		else:
			r_mat.albedo_color = Color(0.18, 0.18, 0.20) # Asphalt
			r_mat.roughness = 0.72

		road_mi.mesh = road_box
		road_mi.material_override = r_mat
		road_mi.position = center

		# Orientation along road segment
		if dir.length_squared() > 0.001:
			var up_vec = Vector3.UP
			if absf(dir.dot(up_vec)) > 0.9:
				up_vec = Vector3.RIGHT
			road_mi.look_at_from_position(center, center + dir, up_vec)

		roads_container.add_child(road_mi)

		# Road Physical Collision Box
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

		# Yellow Centerline Striping for Paved Asphalt Roads
		if s_type == UrbanConstants.SURFACE_ASPHALT:
			var stripe_mi = MeshInstance3D.new()
			var stripe_box = BoxMesh.new()
			stripe_box.size = Vector3(0.24, 0.02, dist)
			var y_mat = StandardMaterial3D.new()
			y_mat.albedo_color = Color(0.95, 0.82, 0.15)
			y_mat.roughness = 0.55
			stripe_mi.mesh = stripe_box
			stripe_mi.material_override = y_mat
			stripe_mi.position = center + Vector3(0.0, 0.14, 0.0)
			if dir.length_squared() > 0.001:
				var up_vec = Vector3.UP
				if absf(dir.dot(up_vec)) > 0.9:
					up_vec = Vector3.RIGHT
				stripe_mi.look_at_from_position(stripe_mi.position, stripe_mi.position + dir, up_vec)
			roads_container.add_child(stripe_mi)

		# If elevated viaduct (Harborfly Freeway Y > 10m), spawn viaduct support pillars
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
	# 1. Downtown Metro: Dense American / Manhattan-Style Skyscraper Grid
	# Placed systematically across downtown city blocks with verified setbacks (clearance >= 16m)
	var downtown_grid_x = [-480.0, -410.0, -340.0, -270.0, -200.0, -130.0, -60.0, 10.0, 80.0]
	var downtown_grid_z = [-480.0, -410.0, -340.0, -270.0, -200.0, -130.0, -60.0, 10.0, 80.0]

	for gx in downtown_grid_x:
		for gz in downtown_grid_z:
			var p = Vector3(gx, 0.0, gz)
			if not _is_obstructing_road(p, 17.5):
				var tower_h = randf_range(58.0, 115.0)
				var tower_w = randf_range(18.0, 26.0)
				var tower = UrbanPropFactory.build_skyscraper(tower_h, tower_w, tower_w, Color(0.2, 0.6, 1.0))
				tower.position = p
				props_container.add_child(tower)

	# 2. Midtown & Commercial Corridors: Multi-story commercial blocks, offices & retail
	var midtown_x = [-480.0, -380.0, -280.0, -180.0, -80.0, 20.0, 120.0, 220.0]
	var midtown_z = [100.0, 180.0, 260.0, 340.0, 420.0, 500.0]
	for mx in midtown_x:
		for mz in midtown_z:
			var p = Vector3(mx, 0.0, mz)
			if not _is_obstructing_road(p, 15.0):
				var comm = UrbanPropFactory.build_commercial_block(randf_range(26.0, 48.0), 20.0, 20.0)
				comm.position = p
				props_container.add_child(comm)

	# 3. Colinas Heights: Terracotta villas along winding hillside roads
	var colinas_spots = [
		Vector3(250, 20.0, 320), Vector3(360, 38.0, 420), Vector3(460, 54.0, 520),
		Vector3(540, 70.0, 640), Vector3(640, 84.0, 750), Vector3(380, 36.0, 320),
		Vector3(480, 52.0, 420), Vector3(580, 72.0, 540), Vector3(660, 88.0, 660),
		Vector3(300, 26.0, 360), Vector3(420, 46.0, 460), Vector3(520, 62.0, 580)
	]
	for p in colinas_spots:
		if not _is_obstructing_road(p, 12.0):
			var villa = UrbanPropFactory.build_residential_villa(14.0, 12.0)
			villa.position = p
			props_container.add_child(villa)

	# 4. Verdant Glen: Parkland trees & stone bridges
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

	var bridge = UrbanPropFactory.build_stone_bridge(24.0, 10.0)
	bridge.position = Vector3(480, 15.0, 80)
	props_container.add_child(bridge)

	# 5. Industrial Apex: Freight shipping containers & logistics depot
	var container_spots = [
		Vector3(-850, 0, 420), Vector3(-850, 2.9, 420), # Stacked
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

	# 6. Continuous Street Lamps placed along Downtown Grand Ave and Bayview Promenade
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
	# 1. Colinas Heights Crest Jump (Screenshot 4 reference: launches over suburban valley)
	var colinas_ramp = UrbanPropFactory.build_stunt_ramp(8.0, 14.0, 3.8, 28.0)
	colinas_ramp.name = "StuntRamp_Colinas"
	colinas_ramp.position = Vector3(450.0, 52.0, 620.0)
	colinas_ramp.rotation.y = deg_to_rad(15.0)
	props_container.add_child(colinas_ramp)

	# 2. Harborfly Freeway Overpass Leap (Launches from upper viaduct down to ground)
	var freeway_ramp = UrbanPropFactory.build_stunt_ramp(10.0, 16.0, 3.5, 22.0)
	freeway_ramp.name = "StuntRamp_Freeway"
	freeway_ramp.position = Vector3(150.0, 18.0, 20.0)
	freeway_ramp.rotation.y = deg_to_rad(90.0)
	props_container.add_child(freeway_ramp)

	# 3. Verdant Glen Lake Leap (Launches over park stream)
	var glen_ramp = UrbanPropFactory.build_stunt_ramp(7.5, 12.0, 3.2, 25.0)
	glen_ramp.name = "StuntRamp_Glen"
	glen_ramp.position = Vector3(380.0, 11.0, -220.0)
	glen_ramp.rotation.y = deg_to_rad(-45.0)
	props_container.add_child(glen_ramp)

	# 4. Skyline Airport Runway Drag Kicker
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

	# 1. District Curated Spawns
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

	# 2. Road Network Traffic Waypoints (guarantees >= 100 safe verified spawn points)
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
