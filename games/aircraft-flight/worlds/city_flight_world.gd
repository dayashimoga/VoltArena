class_name CityFlightWorld
extends Node3D

## CityFlightWorld: Open-World Metropolitan City, Harbor & International Airport.
## Features American/Manhattan skyscraper canyons ($120\text{m}–350\text{m}$),
## suspension bridges, container seaports, and dual paved runways.

const RunwayGen = preload("res://games/aircraft-flight/worlds/runway_generator.gd")

var airport_runway: Node3D
var bridge_root: Node3D
var skyscraper_colliders: Array[StaticBody3D] = []

func _ready() -> void:
	build_world()

func build_world() -> void:
	# 1. Base Ocean & Ground Terrain Plane
	_build_ground_plane()

	# 2. International Airport with Dual ILS Runways
	_build_airport_complex()

	# 3. American / New York Style High-Rise Skyscraper Grid
	_build_metropolitan_city_grid()

	# 4. Iconic Twin-Tower Suspension Bridge across River Canyon
	_build_suspension_bridge()

	# 5. Maritime Commercial Harbor & Container Docks
	_build_harbor_and_docks()

func _build_ground_plane() -> void:
	var sb = StaticBody3D.new()
	sb.name = "CityTerrain"
	add_child(sb)

	var col = CollisionShape3D.new()
	var box_col = BoxShape3D.new()
	box_col.size = Vector3(12000.0, 2.0, 12000.0)
	col.shape = box_col
	col.position = Vector3(0.0, -1.0, 0.0)
	sb.add_child(col)

	var mi = MeshInstance3D.new()
	var plane_mesh = BoxMesh.new()
	plane_mesh.size = Vector3(12000.0, 1.8, 12000.0)
	mi.mesh = plane_mesh
	mi.position = Vector3(0.0, -0.9, 0.0)

	var mat_terrain = StandardMaterial3D.new()
	mat_terrain.albedo_color = Color(0.18, 0.24, 0.22) # Coastal dark green / urban asphalt
	mat_terrain.roughness = 0.95
	mi.material_override = mat_terrain
	add_child(mi)

	# Water Plane (River & Ocean Bay at Y = -0.5)
	var water_mi = MeshInstance3D.new()
	var water_mesh = BoxMesh.new()
	water_mesh.size = Vector3(3200.0, 0.5, 12000.0)
	water_mi.mesh = water_mesh
	water_mi.position = Vector3(2200.0, -0.2, 0.0)
	var mat_water = StandardMaterial3D.new()
	mat_water.albedo_color = Color(0.08, 0.22, 0.35, 0.92)
	mat_water.roughness = 0.08
	mat_water.metallic = 0.85
	water_mi.material_override = mat_water
	add_child(water_mi)

func _build_airport_complex() -> void:
	# Primary Runway 09L ($2,400\text{m} \times 60\text{m}$)
	airport_runway = RunwayGen.build_runway(2400.0, 60.0, "09L")
	airport_runway.position = Vector3(-1200.0, 0.5, 0.0)
	add_child(airport_runway)

	# Secondary Runway 09R (Parallel runway spaced 380m apart)
	var runway_r = RunwayGen.build_runway(2000.0, 50.0, "09R")
	runway_r.position = Vector3(-1580.0, 0.5, 0.0)
	add_child(runway_r)

	# Airport Terminal Building & Control Tower
	var mat_term = StandardMaterial3D.new()
	mat_term.albedo_color = Color(0.85, 0.88, 0.92)
	mat_term.metallic = 0.35
	mat_term.roughness = 0.30

	var terminal = _add_colliding_box(Vector3(120.0, 22.0, 450.0), Vector3(-850.0, 11.0, 0.0), mat_term)
	add_child(terminal)

	# Control Tower with Radar Beacon
	var tower = _add_colliding_box(Vector3(18.0, 85.0, 18.0), Vector3(-850.0, 42.5, -280.0), mat_term)
	add_child(tower)
	var cab = _add_colliding_box(Vector3(28.0, 12.0, 28.0), Vector3(-850.0, 88.0, -280.0), mat_term)
	add_child(cab)

	# Rotating Airport Radar Dish
	var radar_dish = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 6.0
	cyl.bottom_radius = 0.5
	cyl.height = 1.5
	radar_dish.mesh = cyl
	radar_dish.rotation_degrees.z = 90.0
	radar_dish.position = Vector3(-850.0, 96.0, -280.0)
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
	mat_stone.albedo_color = Color(0.48, 0.46, 0.44) # Art Deco limestone
	mat_stone.roughness = 0.80

	var mat_charcoal = StandardMaterial3D.new()
	mat_charcoal.albedo_color = Color(0.20, 0.22, 0.25)
	mat_charcoal.roughness = 0.45

	# Generate 6x7 Skyscraper Grid with broad avenues for low-level flight
	var origin_x = 400.0
	var origin_z = -1800.0
	var avenue_width = 160.0

	for gx in range(6):
		for gz in range(7):
			var bx = origin_x + gx * avenue_width
			var bz = origin_z + gz * avenue_width

			# Skyscraper Height varies between 120m and 350m
			var seed_val = (gx * 13 + gz * 29) % 100
			var b_height = 120.0 + seed_val * 2.3
			var b_width = 45.0 + (seed_val % 15)

			var chosen_mat = mat_glass_blue
			if seed_val % 4 == 1:
				chosen_mat = mat_glass_gold
			elif seed_val % 4 == 2:
				chosen_mat = mat_stone
			elif seed_val % 4 == 3:
				chosen_mat = mat_charcoal

			if seed_val > 70:
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
	mat_steel.albedo_color = Color(0.85, 0.25, 0.15) # International Orange (Golden Gate / Manhattan style)
	mat_steel.roughness = 0.50
	mat_steel.metallic = 0.60

	var mat_deck = StandardMaterial3D.new()
	mat_deck.albedo_color = Color(0.25, 0.26, 0.28)
	mat_deck.roughness = 0.90

	# Bridge Span across water channel (from X = 1200 to X = 3200 at Z = 0)
	var deck = _add_colliding_box(Vector3(2000.0, 4.0, 42.0), Vector3(2200.0, 45.0, 0.0), mat_deck)
	bridge_root.add_child(deck)

	# Twin Suspension Towers (180m height with flight arch opening)
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
	for c in range(5):
		var cz = -1200.0 + c * 250.0
		var crane_box = _add_colliding_box(Vector3(45.0, 75.0, 25.0), Vector3(1400.0, 37.5, cz), mat_crane)
		add_child(crane_box)

	# Cargo Container Ship moored in harbor basin
	var mat_ship = StandardMaterial3D.new()
	mat_ship.albedo_color = Color(0.65, 0.12, 0.15)
	var ship = _add_colliding_box(Vector3(55.0, 28.0, 320.0), Vector3(1800.0, 14.0, -600.0), mat_ship)
	add_child(ship)

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
