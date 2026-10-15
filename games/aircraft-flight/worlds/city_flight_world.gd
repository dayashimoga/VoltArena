class_name CityFlightWorld
extends Node3D

## CityFlightWorld: Open-World Metropolitan City, Harbor & International Airport.
## Features American/Manhattan skyscraper canyons, suspension bridges,
## container seaports, dual paved runways, connecting taxiways, hangars,
## mountain backdrops, and volumetric cloud formations.

const RunwayGen = preload("res://games/aircraft-flight/worlds/runway_generator.gd")

var airport_runway: Node3D
var bridge_root: Node3D
var skyscraper_colliders: Array[StaticBody3D] = []

func _ready() -> void:
	build_world()

func build_world() -> void:
	# 1. Base Ocean & Ground Terrain Plane
	_build_ground_plane()

	# 2. International Airport with Dual ILS Runways, Taxiways & Hangars
	_build_airport_complex()

	# 3. American / New York Style High-Rise Skyscraper Grid
	_build_metropolitan_city_grid()

	# 4. Iconic Twin-Tower Suspension Bridge across River Canyon
	_build_suspension_bridge()

	# 5. Maritime Commercial Harbor & Container Docks
	_build_harbor_and_docks()

	# 6. Distant Alpine Mountain Ridgeline on North Rim
	_build_mountain_backdrop()

	# 7. Cumulus Cloud Formations at Altitude
	_build_clouds()

func _build_ground_plane() -> void:
	var sb = StaticBody3D.new()
	sb.name = "CityTerrain"
	add_child(sb)

	var col = CollisionShape3D.new()
	var box_col = BoxShape3D.new()
	box_col.size = Vector3(14000.0, 2.0, 14000.0)
	col.shape = box_col
	col.position = Vector3(0.0, -1.0, 0.0)
	sb.add_child(col)

	var mi = MeshInstance3D.new()
	var plane_mesh = BoxMesh.new()
	plane_mesh.size = Vector3(14000.0, 1.8, 14000.0)
	mi.mesh = plane_mesh
	mi.position = Vector3(0.0, -0.9, 0.0)

	var mat_terrain = StandardMaterial3D.new()
	mat_terrain.albedo_color = Color(0.18, 0.24, 0.22) # Coastal dark green / urban asphalt
	mat_terrain.roughness = 0.95
	mi.material_override = mat_terrain
	add_child(mi)

	# Water Plane (River & Ocean Bay at Y = -0.2)
	var water_mi = MeshInstance3D.new()
	var water_mesh = BoxMesh.new()
	water_mesh.size = Vector3(3600.0, 0.5, 14000.0)
	water_mi.mesh = water_mesh
	water_mi.position = Vector3(2200.0, -0.2, 0.0)
	var mat_water = StandardMaterial3D.new()
	mat_water.albedo_color = Color(0.08, 0.22, 0.35, 0.92)
	mat_water.roughness = 0.08
	mat_water.metallic = 0.85
	water_mi.material_override = mat_water
	add_child(water_mi)

func _build_airport_complex() -> void:
	# Primary Runway 09L (2,400m x 60m)
	airport_runway = RunwayGen.build_runway(2400.0, 60.0, "09L")
	airport_runway.position = Vector3(-1200.0, 0.5, 0.0)
	add_child(airport_runway)

	# Secondary Runway 09R (2,000m x 50m)
	var runway_r = RunwayGen.build_runway(2000.0, 50.0, "09R")
	runway_r.position = Vector3(-1620.0, 0.5, 0.0)
	add_child(runway_r)

	# Materials
	var mat_asphalt = StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.13, 0.14, 0.16)
	mat_asphalt.roughness = 0.88

	var mat_yellow_stripe = StandardMaterial3D.new()
	mat_yellow_stripe.albedo_color = Color(0.95, 0.82, 0.1)

	var mat_blue_light = StandardMaterial3D.new()
	mat_blue_light.albedo_color = Color(0.1, 0.5, 1.0)
	mat_blue_light.emission_enabled = true
	mat_blue_light.emission = Color(0.1, 0.5, 1.0)
	mat_blue_light.emission_energy_multiplier = 4.0

	var mat_term = StandardMaterial3D.new()
	mat_term.albedo_color = Color(0.85, 0.88, 0.92)
	mat_term.metallic = 0.35
	mat_term.roughness = 0.30

	var mat_hangar = StandardMaterial3D.new()
	mat_hangar.albedo_color = Color(0.35, 0.38, 0.42)
	mat_hangar.metallic = 0.65
	mat_hangar.roughness = 0.40

	var mat_hangar_door = StandardMaterial3D.new()
	mat_hangar_door.albedo_color = Color(0.12, 0.13, 0.15)
	mat_hangar_door.roughness = 0.90

	# --- PARALLEL TAXIWAY ALPHA (2,400m x 30m) ---
	var taxiway_a = _add_colliding_box(Vector3(30.0, 0.6, 2400.0), Vector3(-1410.0, 0.25, 0.0), mat_asphalt)
	add_child(taxiway_a)
	# Yellow Centerline
	var tw_line = _create_box(Vector3(0.6, 0.05, 2400.0), Vector3(-1410.0, 0.58, 0.0), mat_yellow_stripe)
	add_child(tw_line)

	# Blue Taxiway Edge Lights
	for z in range(-1100, 1101, 80):
		var bl_left = _create_box(Vector3(0.3, 0.3, 0.3), Vector3(-1424.0, 0.65, float(z)), mat_blue_light)
		add_child(bl_left)
		var bl_right = _create_box(Vector3(0.3, 0.3, 0.3), Vector3(-1396.0, 0.65, float(z)), mat_blue_light)
		add_child(bl_right)

	# --- CONNECTING TAXIWAY LINKS (Bravo, Charlie, Delta, Echo) ---
	for z_pos in [-800.0, -250.0, 250.0, 800.0]:
		var link_l = _add_colliding_box(Vector3(180.0, 0.6, 28.0), Vector3(-1305.0, 0.25, z_pos), mat_asphalt)
		add_child(link_l)
		var link_r = _add_colliding_box(Vector3(180.0, 0.6, 28.0), Vector3(-1515.0, 0.25, z_pos), mat_asphalt)
		add_child(link_r)
		# Yellow guide turns
		add_child(_create_box(Vector3(180.0, 0.05, 0.6), Vector3(-1305.0, 0.58, z_pos), mat_yellow_stripe))
		add_child(_create_box(Vector3(180.0, 0.05, 0.6), Vector3(-1515.0, 0.58, z_pos), mat_yellow_stripe))

	# --- AIRLINE MAINTENANCE HANGARS ---
	# Hangar 1 (North Maintenance Bay)
	var h1 = _add_colliding_box(Vector3(120.0, 28.0, 95.0), Vector3(-720.0, 14.0, 360.0), mat_hangar)
	add_child(h1)
	add_child(_create_box(Vector3(4.0, 22.0, 75.0), Vector3(-658.0, 11.0, 360.0), mat_hangar_door)) # Open bay

	# Hangar 2 (South Maintenance Bay)
	var h2 = _add_colliding_box(Vector3(120.0, 28.0, 95.0), Vector3(-720.0, 14.0, 520.0), mat_hangar)
	add_child(h2)
	add_child(_create_box(Vector3(4.0, 22.0, 75.0), Vector3(-658.0, 11.0, 520.0), mat_hangar_door))

	# Aircraft Parking Apron Tarmac
	var apron = _add_colliding_box(Vector3(260.0, 0.5, 600.0), Vector3(-780.0, 0.25, 440.0), mat_asphalt)
	add_child(apron)

	# --- AIRPORT TERMINAL & CONTROL TOWER ---
	var terminal = _add_colliding_box(Vector3(140.0, 24.0, 480.0), Vector3(-850.0, 12.0, -100.0), mat_term)
	add_child(terminal)

	# Aerobridge Jetways (Passenger boarding gates)
	for j in range(4):
		var jz = -220.0 + j * 90.0
		var jetway = _create_box(Vector3(45.0, 4.5, 4.5), Vector3(-760.0, 9.0, jz), mat_hangar)
		add_child(jetway)
		var rotunda = _create_box(Vector3(8.0, 8.0, 8.0), Vector3(-735.0, 8.0, jz), mat_term)
		add_child(rotunda)

	# Control Tower with Glass Observation Cab
	var tower = _add_colliding_box(Vector3(18.0, 90.0, 18.0), Vector3(-850.0, 45.0, -380.0), mat_term)
	add_child(tower)
	var cab = _add_colliding_box(Vector3(28.0, 14.0, 28.0), Vector3(-850.0, 94.0, -380.0), mat_term)
	add_child(cab)

	# Rotating Airport Surveillance Radar Dish
	var radar_dish = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 6.0
	cyl.bottom_radius = 0.5
	cyl.height = 1.5
	radar_dish.mesh = cyl
	radar_dish.rotation_degrees.z = 90.0
	radar_dish.position = Vector3(-850.0, 103.0, -380.0)
	add_child(radar_dish)

func _build_metropolitan_city_grid() -> void:
	# Materials for Skyscraper Facades
	var mat_glass_blue = StandardMaterial3D.new()
	mat_glass_blue.albedo_color = Color(0.12, 0.25, 0.42)
	mat_glass_blue.roughness = 0.06
	mat_glass_blue.metallic = 0.85
	mat_glass_blue.clearcoat_enabled = true
	mat_glass_blue.clearcoat = 1.0

	var mat_glass_gold = StandardMaterial3D.new()
	mat_glass_gold.albedo_color = Color(0.35, 0.28, 0.14)
	mat_glass_gold.roughness = 0.08
	mat_glass_gold.metallic = 0.90

	var mat_stone = StandardMaterial3D.new()
	mat_stone.albedo_color = Color(0.48, 0.46, 0.44)
	mat_stone.roughness = 0.80

	var mat_charcoal = StandardMaterial3D.new()
	mat_charcoal.albedo_color = Color(0.20, 0.22, 0.25)
	mat_charcoal.roughness = 0.45

	# Generate 6x8 Skyscraper Grid with broad avenues for low-level flight
	var origin_x = 400.0
	var origin_z = -1800.0
	var avenue_width = 160.0

	for gx in range(6):
		for gz in range(8):
			var bx = origin_x + gx * avenue_width
			var bz = origin_z + gz * avenue_width

			var seed_val = (gx * 13 + gz * 29) % 100
			var b_height = 130.0 + seed_val * 2.4
			var b_width = 46.0 + (seed_val % 16)

			var chosen_mat = mat_glass_blue
			if seed_val % 4 == 1:
				chosen_mat = mat_glass_gold
			elif seed_val % 4 == 2:
				chosen_mat = mat_stone
			elif seed_val % 4 == 3:
				chosen_mat = mat_charcoal

			if seed_val > 68:
				# Tiered Stepped Skyscraper (Empire / Chrysler style)
				var base_box = _add_colliding_box(Vector3(b_width, b_height * 0.5, b_width), Vector3(bx, b_height * 0.25, bz), chosen_mat)
				add_child(base_box)
				var mid_box = _add_colliding_box(Vector3(b_width * 0.75, b_height * 0.35, b_width * 0.75), Vector3(bx, b_height * 0.675, bz), chosen_mat)
				add_child(mid_box)
				var spire = _add_colliding_box(Vector3(4.0, b_height * 0.15, 4.0), Vector3(bx, b_height * 0.925, bz), mat_charcoal)
				add_child(spire)
			else:
				# Monolithic Glass Curtain Wall Office Tower
				var tower = _add_colliding_box(Vector3(b_width, b_height, b_width), Vector3(bx, b_height * 0.5, bz), chosen_mat)
				add_child(tower)

func _build_suspension_bridge() -> void:
	bridge_root = Node3D.new()
	bridge_root.name = "SuspensionBridge"
	add_child(bridge_root)

	var mat_steel = StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.85, 0.25, 0.15) # International Orange
	mat_steel.roughness = 0.50
	mat_steel.metallic = 0.60

	var mat_deck = StandardMaterial3D.new()
	mat_deck.albedo_color = Color(0.25, 0.26, 0.28)
	mat_deck.roughness = 0.90

	# Bridge Span across water channel
	var deck = _add_colliding_box(Vector3(2000.0, 4.0, 42.0), Vector3(2200.0, 45.0, 0.0), mat_deck)
	bridge_root.add_child(deck)

	# Twin Suspension Towers (180m height)
	for tx in [1600.0, 2800.0]:
		var tower_l = _add_colliding_box(Vector3(14.0, 180.0, 8.0), Vector3(tx, 90.0, -18.0), mat_steel)
		bridge_root.add_child(tower_l)
		var tower_r = _add_colliding_box(Vector3(14.0, 180.0, 8.0), Vector3(tx, 90.0, 18.0), mat_steel)
		bridge_root.add_child(tower_r)
		var cross_strut = _add_colliding_box(Vector3(14.0, 10.0, 36.0), Vector3(tx, 160.0, 0.0), mat_steel)
		bridge_root.add_child(cross_strut)

	# Main Suspension Cable Arcs
	var cable = _add_colliding_box(Vector3(2000.0, 1.5, 1.5), Vector3(2200.0, 120.0, -18.0), mat_steel)
	bridge_root.add_child(cable)
	var cable_r = _add_colliding_box(Vector3(2000.0, 1.5, 1.5), Vector3(2200.0, 120.0, 18.0), mat_steel)
	bridge_root.add_child(cable_r)

func _build_harbor_and_docks() -> void:
	var mat_crane = StandardMaterial3D.new()
	mat_crane.albedo_color = Color(0.95, 0.8, 0.1) # Port yellow
	var mat_container = StandardMaterial3D.new()
	mat_container.albedo_color = Color(0.15, 0.45, 0.85)

	# Gantry Container Cranes
	for c in range(6):
		var cz = -1300.0 + c * 250.0
		var crane_box = _add_colliding_box(Vector3(45.0, 75.0, 25.0), Vector3(1400.0, 37.5, cz), mat_crane)
		add_child(crane_box)

	# Cargo Container Ship moored in harbor basin
	var mat_ship = StandardMaterial3D.new()
	mat_ship.albedo_color = Color(0.65, 0.12, 0.15)
	var ship = _add_colliding_box(Vector3(55.0, 28.0, 320.0), Vector3(1800.0, 14.0, -600.0), mat_ship)
	add_child(ship)

func _build_mountain_backdrop() -> void:
	var mat_rock = StandardMaterial3D.new()
	mat_rock.albedo_color = Color(0.30, 0.28, 0.26)
	mat_rock.roughness = 0.95

	var mat_snow = StandardMaterial3D.new()
	mat_snow.albedo_color = Color(0.92, 0.94, 0.98)
	mat_snow.roughness = 0.85

	# Mountain Ridgeline peaks on north border (Z = -4500m to -5500m)
	for m in range(12):
		var mx = -4000.0 + m * 750.0
		var mz = -4800.0 + (m * 41 % 800)
		var m_height = 1400.0 + (m * 73 % 900)
		var m_base = 700.0 + (m * 17 % 250)

		# Mountain base
		var peak_sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var cyl_shape = CylinderShape3D.new()
		cyl_shape.height = m_height
		cyl_shape.radius = m_base * 0.5
		col.shape = cyl_shape
		peak_sb.add_child(col)

		var mi = MeshInstance3D.new()
		var cyl_mesh = CylinderMesh.new()
		cyl_mesh.top_radius = 20.0
		cyl_mesh.bottom_radius = m_base
		cyl_mesh.height = m_height
		mi.mesh = cyl_mesh
		mi.material_override = mat_rock
		peak_sb.add_child(mi)

		# Snowcap top
		var cap_mesh = MeshInstance3D.new()
		var cap = CylinderMesh.new()
		cap.top_radius = 5.0
		cap.bottom_radius = m_base * 0.35
		cap.height = m_height * 0.30
		cap_mesh.mesh = cap
		cap_mesh.position = Vector3(0.0, m_height * 0.35, 0.0)
		cap_mesh.material_override = mat_snow
		peak_sb.add_child(cap_mesh)

		peak_sb.position = Vector3(mx, m_height * 0.5, mz)
		add_child(peak_sb)

func _build_clouds() -> void:
	var mat_cloud = StandardMaterial3D.new()
	mat_cloud.albedo_color = Color(0.95, 0.96, 0.98, 0.75)
	mat_cloud.roughness = 0.95
	mat_cloud.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var cloud_root = Node3D.new()
	cloud_root.name = "CumulusClouds"
	add_child(cloud_root)

	# 14 Scattered Cloud Clusters at Altitude 1200m - 1600m
	for c in range(14):
		var cx = -3500.0 + c * 550.0
		var cz = -3000.0 + ((c * 67) % 5500)
		var cy = 1300.0 + ((c * 31) % 400)

		var cluster = Node3D.new()
		cluster.position = Vector3(cx, cy, cz)
		cloud_root.add_child(cluster)

		# 5 overlapping soft puffs per cloud cluster
		for p in range(5):
			var puff = MeshInstance3D.new()
			var sph = SphereMesh.new()
			var r = 180.0 + (p * 23 % 80)
			sph.radius = r
			sph.height = r * 1.4
			puff.mesh = sph
			puff.position = Vector3((p - 2) * 120.0, 0.0, (p % 3 - 1) * 90.0)
			puff.material_override = mat_cloud
			cluster.add_child(puff)

func _add_colliding_box(size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var sb = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	sb.add_child(col)

	var mi = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mi.mesh = box_mesh
	if mat:
		mi.material_override = mat
	sb.add_child(mi)

	sb.position = pos
	skyscraper_colliders.append(sb)
	return sb

func _create_box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	if mat:
		mi.material_override = mat
	return mi

# Safe Spawn Position Lookup
func get_spawn_point(spawn_type: String) -> Dictionary:
	match spawn_type:
		"runway_takeoff":
			# Threshold of Runway 09L facing forward (-Z)
			return {
				"position": Vector3(-1200.0, 1.8, 1050.0),
				"heading_deg": 0.0,
				"airspeed_kmh": 0.0,
				"airborne": false
			}
		"airborne_approach":
			# 4km back along 3-degree glide slope to runway
			return {
				"position": Vector3(-1200.0, 380.0, 3500.0),
				"heading_deg": 0.0,
				"airspeed_kmh": 320.0,
				"airborne": true
			}
		"city_skimming":
			# Cruising over central skyscraper canyon
			return {
				"position": Vector3(880.0, 260.0, 1500.0),
				"heading_deg": 0.0,
				"airspeed_kmh": 520.0,
				"airborne": true
			}
		_:
			return {
				"position": Vector3(-1200.0, 1.8, 1050.0),
				"heading_deg": 0.0,
				"airspeed_kmh": 0.0,
				"airborne": false
			}
