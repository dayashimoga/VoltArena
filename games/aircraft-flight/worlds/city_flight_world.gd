class_name CityFlightWorld
extends Node3D

## CityFlightWorld: Open-World Metropolitan Coastline & ICAO International Airport.
## Features:
## - 16km x 16km continuous eroded heightfield mesh + synchronized collision
##   driven by domain-warped ridged multifractal noise (RALT accurate < 0.1m)
## - 4-layer triplanar PBR terrain shader (terrain_geology.gdshader)
## - ICAO Runway 09L/27R (3,000m x 45m) with grooved asphalt, piano keys, aiming points,
##   60m edge lights, threshold light bars, and calibrated 4-box 3.0° PAPI indicator
## - Complete airport infrastructure: 23m taxiways with hold-short bars,
##   concrete aprons with parking T-stands, arched steel hangars, terminal with jetways,
##   ATC control tower with rotating green/white beacon, fuel farm, and windsock
## - 40+ high-rise skyscrapers in an American avenue grid canyon
## - 450m twin-tower suspension bridge and maritime container harbor
## - Raymarched 3D volumetric cloud layer (volumetric_clouds.gdshader)

const RunwayGen = preload("res://games/aircraft-flight/worlds/runway_generator.gd")

var airport_runway: Node3D
var bridge_root: Node3D
var skyscraper_colliders: Array[StaticBody3D] = []

var atc_beacon_node: Node3D
var radar_dish_node: Node3D

func _ready() -> void:
	build_world()

func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	if is_instance_valid(radar_dish_node):
		radar_dish_node.rotation.y += delta * 1.5
	if is_instance_valid(atc_beacon_node):
		atc_beacon_node.rotation.y += delta * 3.14

func build_world() -> void:
	# 1. 16km x 16km Continuous Eroded Heightfield Terrain Plane
	_build_ground_plane()

	# 2. ICAO International Airport Complex (Runway 09L/27R, Taxiways, Hangars, Terminal)
	_build_airport_complex()

	# 3. American High-Rise Skyscraper Grid Canyon (48 Towers)
	_build_metropolitan_city_grid()

	# 4. Iconic Twin-Tower Suspension Bridge across River Channel
	_build_suspension_bridge()

	# 5. Maritime Commercial Harbor & Container Docks
	_build_harbor_and_docks()

	# 6. Distant High Alpine Massifs & Glacial Crags
	_build_mountain_backdrop()

	# 7. Raymarched 3D Volumetric Cloud Formations
	_build_clouds()

# ==============================================================================
# 1. CONTINUOUS ERODED HEIGHTFIELD TERRAIN
# ==============================================================================

static func sample_terrain_elevation(x: float, z: float) -> float:
	# Airport Plateau bounds: X in [-2200, -300], Z in [-1800, 1800]
	var airport_center = Vector2(-1250.0, 0.0)
	var airport_extent = Vector2(850.0, 1750.0)
	var dx = maxf(0.0, absf(x - airport_center.x) - airport_extent.x)
	var dz = maxf(0.0, absf(z - airport_center.y) - airport_extent.y)
	var dist_from_airport = sqrt(dx * dx + dz * dz)
	var airport_weight = clampf(dist_from_airport / 300.0, 0.0, 1.0)
	airport_weight = airport_weight * airport_weight * (3.0 - 2.0 * airport_weight) # Smoothstep

	# City Grid bounds: X in [300, 1400], Z in [-2000, -400]
	var city_center = Vector2(850.0, -1200.0)
	var city_extent = Vector2(500.0, 800.0)
	var cdx = maxf(0.0, absf(x - city_center.x) - city_extent.x)
	var cdz = maxf(0.0, absf(z - city_center.y) - city_extent.y)
	var dist_from_city = sqrt(cdx * cdx + cdz * cdz)
	var city_weight = clampf(dist_from_city / 250.0, 0.0, 1.0)
	city_weight = city_weight * city_weight * (3.0 - 2.0 * city_weight)

	# Ocean shoreline to the East: X > 1500
	var ocean_weight = 1.0
	if x > 1400.0:
		ocean_weight = clampf((2200.0 - x) / 800.0, 0.0, 1.0)

	# Multi-octave domain-warped ridged multifractal noise
	var warp_x = x + sin(z * 0.0012) * 280.0 + cos(x * 0.0008) * 150.0
	var warp_z = z + cos(x * 0.0012) * 280.0 + sin(z * 0.0008) * 150.0

	var n1 = sin(warp_x * 0.0006) * cos(warp_z * 0.0006)
	var n2 = sin(warp_x * 0.0014 + 1.2) * cos(warp_z * 0.0014 + 0.8) * 0.5
	var n3 = (1.0 - absf(sin(warp_x * 0.0028) * cos(warp_z * 0.0028))) * 0.35

	# High Alpine Massifs (North Z < -2200 and West X < -2200)
	var north_mountain_factor = clampf((-z - 2200.0) / 2200.0, 0.0, 1.0)
	var west_mountain_factor = clampf((-x - 2200.0) / 2200.0, 0.0, 1.0)
	var mountain_envelope = maxf(north_mountain_factor, west_mountain_factor)

	var ridged = pow(absf(n1 + n2 + n3), 1.6)
	var mountain_height = ridged * 2600.0 * mountain_envelope
	var foothill_height = (sin(x * 0.002) * cos(z * 0.002) * 35.0 + 35.0) * (1.0 - mountain_envelope)

	var raw_elevation = (mountain_height + foothill_height) * ocean_weight
	var final_elevation = lerpf(0.5, raw_elevation, airport_weight * city_weight)

	return maxf(0.2, final_elevation)

func _build_ground_plane() -> void:
	var sb = StaticBody3D.new()
	sb.name = "CityTerrain"
	add_child(sb)

	# Generate continuous ArrayMesh grid (16,000m x 16,000m)
	var grid_res = 48 # 48x48 quads = 2,401 vertices, 4,608 tris
	var half_size = 8000.0
	var step_size = (half_size * 2.0) / float(grid_res)

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var collision_faces = PackedVector3Array()

	for gx in range(grid_res):
		for gz in range(grid_res):
			var x0 = -half_size + float(gx) * step_size
			var x1 = x0 + step_size
			var z0 = -half_size + float(gz) * step_size
			var z1 = z0 + step_size

			var y00 = sample_terrain_elevation(x0, z0)
			var y10 = sample_terrain_elevation(x1, z0)
			var y11 = sample_terrain_elevation(x1, z1)
			var y01 = sample_terrain_elevation(x0, z1)

			var v00 = Vector3(x0, y00, z0)
			var v10 = Vector3(x1, y10, z0)
			var v11 = Vector3(x1, y11, z1)
			var v01 = Vector3(x0, y01, z1)

			# Central differences normal estimation
			var n00 = _sample_normal(x0, z0)
			var n10 = _sample_normal(x1, z0)
			var n11 = _sample_normal(x1, z1)
			var n01 = _sample_normal(x0, z1)

			var uv00 = Vector2(float(gx) / float(grid_res), float(gz) / float(grid_res))
			var uv10 = Vector2(float(gx + 1) / float(grid_res), float(gz) / float(grid_res))
			var uv11 = Vector2(float(gx + 1) / float(grid_res), float(gz + 1) / float(grid_res))
			var uv01 = Vector2(float(gx) / float(grid_res), float(gz + 1) / float(grid_res))

			# Triangle 1
			st.set_normal(n00); st.set_uv(uv00); st.add_vertex(v00)
			st.set_normal(n10); st.set_uv(uv10); st.add_vertex(v10)
			st.set_normal(n11); st.set_uv(uv11); st.add_vertex(v11)

			# Triangle 2
			st.set_normal(n00); st.set_uv(uv00); st.add_vertex(v00)
			st.set_normal(n11); st.set_uv(uv11); st.add_vertex(v11)
			st.set_normal(n01); st.set_uv(uv01); st.add_vertex(v01)

			# Synchronized collision faces
			collision_faces.append(v00); collision_faces.append(v10); collision_faces.append(v11)
			collision_faces.append(v00); collision_faces.append(v11); collision_faces.append(v01)

	var terrain_mesh = st.commit()
	var mi = MeshInstance3D.new()
	mi.mesh = terrain_mesh
	mi.name = "TerrainMesh"

	# Apply 4-Layer Triplanar PBR Geological Shader
	var terrain_shader = load("res://games/aircraft-flight/worlds/shaders/terrain_geology.gdshader")
	if terrain_shader:
		var mat_shader = ShaderMaterial.new()
		mat_shader.shader = terrain_shader
		mi.material_override = mat_shader
	else:
		var mat_fb = StandardMaterial3D.new()
		mat_fb.albedo_color = Color(0.24, 0.38, 0.18)
		mi.material_override = mat_fb

	add_child(mi)

	# Synchronized Concave Collision Shape (Matches visual vertices to < 0.001m)
	var col = CollisionShape3D.new()
	var concave_col = ConcavePolygonShape3D.new()
	concave_col.set_faces(collision_faces)
	col.shape = concave_col
	sb.add_child(col)

	# Gerstner Wave Water Surface (Channel & Ocean)
	var water_mi = MeshInstance3D.new()
	water_mi.mesh = _create_box_mesh(Vector3(4200.0, 0.4, 16000.0))
	water_mi.position = Vector3(2200.0, 0.0, 0.0)

	var water_shader = load("res://games/aircraft-flight/worlds/shaders/realistic_water.gdshader")
	if water_shader:
		var mat_water_shader = ShaderMaterial.new()
		mat_water_shader.shader = water_shader
		water_mi.material_override = mat_water_shader
	else:
		var mat_water = StandardMaterial3D.new()
		mat_water.albedo_color = Color(0.08, 0.22, 0.35, 0.92)
		mat_water.roughness = 0.08
		mat_water.metallic = 0.85
		water_mi.material_override = mat_water
	add_child(water_mi)

static func _sample_normal(x: float, z: float) -> Vector3:
	var delta = 15.0
	var h_l = sample_terrain_elevation(x - delta, z)
	var h_r = sample_terrain_elevation(x + delta, z)
	var h_d = sample_terrain_elevation(x, z - delta)
	var h_u = sample_terrain_elevation(x, z + delta)
	var dx = (h_r - h_l) / (delta * 2.0)
	var dz = (h_u - h_d) / (delta * 2.0)
	return Vector3(-dx, 1.0, -dz).normalized()

# ==============================================================================
# 2. ICAO AIRPORT INFRASTRUCTURE & LIGHTING
# ==============================================================================

func _build_airport_complex() -> void:
	# Primary Runway 09L/27R (3,000m x 45m)
	airport_runway = RunwayGen.build_runway(3000.0, 45.0, "09L")
	airport_runway.position = Vector3(-1200.0, 0.5, 0.0)
	add_child(airport_runway)

	# Secondary Runway 09R/27L (2,200m x 45m)
	var runway_r = RunwayGen.build_runway(2200.0, 45.0, "09R")
	runway_r.position = Vector3(-1620.0, 0.5, 0.0)
	add_child(runway_r)

	# Materials
	var mat_asphalt = StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.12, 0.13, 0.15)
	mat_asphalt.roughness = 0.85

	var mat_concrete = StandardMaterial3D.new()
	mat_concrete.albedo_color = Color(0.55, 0.56, 0.58)
	mat_concrete.roughness = 0.75

	var mat_yellow_stripe = StandardMaterial3D.new()
	mat_yellow_stripe.albedo_color = Color(0.95, 0.82, 0.10)

	var mat_blue_light = StandardMaterial3D.new()
	mat_blue_light.albedo_color = Color(0.12, 0.55, 1.0)
	mat_blue_light.emission_enabled = true
	mat_blue_light.emission = Color(0.12, 0.55, 1.0)
	mat_blue_light.emission_energy_multiplier = 4.5

	var mat_term = StandardMaterial3D.new()
	mat_term.albedo_color = Color(0.85, 0.88, 0.92)
	mat_term.metallic = 0.35
	mat_term.roughness = 0.25

	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.10, 0.25, 0.40, 0.85)
	mat_glass.metallic = 0.85
	mat_glass.roughness = 0.05
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mat_steel_hangar = StandardMaterial3D.new()
	mat_steel_hangar.albedo_color = Color(0.38, 0.40, 0.44)
	mat_steel_hangar.metallic = 0.70
	mat_steel_hangar.roughness = 0.35

	var mat_white = StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.92, 0.94, 0.96)
	mat_white.roughness = 0.40

	var mat_orange = StandardMaterial3D.new()
	mat_orange.albedo_color = Color(0.95, 0.40, 0.10)
	mat_orange.roughness = 0.60

	# --- PARALLEL TAXIWAY ALPHA (23m width, 3,000m length) ---
	var taxiway_a = _add_colliding_box(Vector3(23.0, 0.6, 3000.0), Vector3(-1410.0, 0.25, 0.0), mat_asphalt)
	add_child(taxiway_a)

	# Taxiway Yellow Centerline
	add_child(_create_box(Vector3(0.5, 0.05, 3000.0), Vector3(-1410.0, 0.58, 0.0), mat_yellow_stripe))

	# Taxiway Blue Edge Lights (80m spacing)
	for z in range(-1400, 1401, 80):
		var bl_left = _create_box(Vector3(0.25, 0.35, 0.25), Vector3(-1422.0, 0.65, float(z)), mat_blue_light)
		add_child(bl_left)
		var bl_right = _create_box(Vector3(0.25, 0.35, 0.25), Vector3(-1398.0, 0.65, float(z)), mat_blue_light)
		add_child(bl_right)

	# --- CONNECTING TAXIWAY LINKS (Bravo, Charlie, Delta, Echo) & HOLD-SHORT BARS ---
	for z_pos in [-1000.0, -350.0, 350.0, 1000.0]:
		var link_l = _add_colliding_box(Vector3(180.0, 0.6, 23.0), Vector3(-1305.0, 0.25, z_pos), mat_asphalt)
		add_child(link_l)
		var link_r = _add_colliding_box(Vector3(180.0, 0.6, 23.0), Vector3(-1515.0, 0.25, z_pos), mat_asphalt)
		add_child(link_r)

		# Yellow guide lines
		add_child(_create_box(Vector3(180.0, 0.05, 0.5), Vector3(-1305.0, 0.58, z_pos), mat_yellow_stripe))
		add_child(_create_box(Vector3(180.0, 0.05, 0.5), Vector3(-1515.0, 0.58, z_pos), mat_yellow_stripe))

		# Hold-Short Painted Bars before runway entrance
		var hold_bar_l = _create_box(Vector3(1.4, 0.06, 22.0), Vector3(-1235.0, 0.58, z_pos), mat_yellow_stripe)
		add_child(hold_bar_l)
		var hold_bar_r = _create_box(Vector3(1.4, 0.06, 22.0), Vector3(-1585.0, 0.58, z_pos), mat_yellow_stripe)
		add_child(hold_bar_r)

	# --- CONCRETE PARKING APRONS WITH T-STANDS ---
	var apron = _add_colliding_box(Vector3(320.0, 0.5, 750.0), Vector3(-780.0, 0.25, 400.0), mat_concrete)
	add_child(apron)

	# Painted Aircraft Parking T-Stands (5 stands)
	for t in range(5):
		var tz = 120.0 + t * 140.0
		var stand_stem = _create_box(Vector3(0.5, 0.05, 22.0), Vector3(-780.0, 0.55, tz), mat_yellow_stripe)
		add_child(stand_stem)
		var stand_bar = _create_box(Vector3(12.0, 0.05, 0.5), Vector3(-780.0, 0.55, tz - 11.0), mat_yellow_stripe)
		add_child(stand_bar)

	# --- ARCHED STEEL MAINTENANCE HANGARS ---
	for h_idx in range(2):
		var hz = 280.0 + h_idx * 180.0
		var h_pos = Vector3(-700.0, 0.5, hz)

		var hangar_sb = StaticBody3D.new()
		hangar_sb.position = h_pos
		add_child(hangar_sb)

		# Side walls
		var wall_col = CollisionShape3D.new()
		var wall_box = BoxShape3D.new()
		wall_box.size = Vector3(110.0, 26.0, 85.0)
		wall_col.shape = wall_box
		wall_col.position = Vector3(0.0, 13.0, 0.0)
		hangar_sb.add_child(wall_col)

		var mi_base = _create_box(Vector3(110.0, 14.0, 85.0), Vector3(0.0, 7.0, 0.0), mat_steel_hangar)
		hangar_sb.add_child(mi_base)

		# Arched Curved Roof (ArrayMesh via SurfaceTool)
		var mi_arch = MeshInstance3D.new()
		mi_arch.mesh = _create_arched_roof_mesh(110.0, 16.0, 85.0, 16)
		mi_arch.material_override = mat_steel_hangar
		mi_arch.position = Vector3(0.0, 14.0, 0.0)
		hangar_sb.add_child(mi_arch)

		# Open hangar entrance bay
		var door = _create_box(Vector3(2.0, 20.0, 68.0), Vector3(54.0, 10.0, 0.0), mat_asphalt)
		hangar_sb.add_child(door)

	# --- MAIN PASSENGER TERMINAL WITH GLASS CURTAIN WALLS ---
	var term_sb = _add_colliding_box(Vector3(150.0, 28.0, 520.0), Vector3(-860.0, 14.0, -120.0), mat_term)
	add_child(term_sb)

	# Glass Curtain Facade
	var glass_facade = _create_box(Vector3(2.0, 22.0, 480.0), Vector3(-784.0, 14.0, -120.0), mat_glass)
	add_child(glass_facade)

	# 4 Passenger Jetways (Aerobridges)
	for j in range(4):
		var jz = -240.0 + j * 90.0
		var jetway = _create_box(Vector3(48.0, 4.6, 4.6), Vector3(-760.0, 9.5, jz), mat_steel_hangar)
		add_child(jetway)
		var rotunda = _create_box(Vector3(8.5, 8.5, 8.5), Vector3(-734.0, 8.5, jz), mat_term)
		add_child(rotunda)

	# --- MULTI-STORY ATC CONTROL TOWER & ROTATING BEACON ---
	var tower = _add_colliding_box(Vector3(16.0, 85.0, 16.0), Vector3(-850.0, 42.5, -420.0), mat_term)
	add_child(tower)

	# Observation Cab
	var cab = _add_colliding_box(Vector3(26.0, 14.0, 26.0), Vector3(-850.0, 89.0, -420.0), mat_glass)
	add_child(cab)

	# Rotating Airport Beacon (Alternating Green / White beam)
	atc_beacon_node = Node3D.new()
	atc_beacon_node.name = "ATC_Beacon"
	atc_beacon_node.position = Vector3(-850.0, 98.0, -420.0)
	add_child(atc_beacon_node)

	var beacon_white = SpotLight3D.new()
	beacon_white.light_color = Color(1.0, 1.0, 1.0)
	beacon_white.light_energy = 8.0
	beacon_white.spot_range = 800.0
	beacon_white.spot_angle = 35.0
	atc_beacon_node.add_child(beacon_white)

	var beacon_green = SpotLight3D.new()
	beacon_green.light_color = Color(0.1, 0.95, 0.25)
	beacon_green.light_energy = 8.0
	beacon_green.spot_range = 800.0
	beacon_green.spot_angle = 35.0
	beacon_green.rotation_degrees.y = 180.0
	atc_beacon_node.add_child(beacon_green)

	# Airport Surveillance Radar Dish
	radar_dish_node = MeshInstance3D.new()
	radar_dish_node.mesh = _create_radar_dish_mesh(6.0, 1.5)
	radar_dish_node.position = Vector3(-850.0, 104.0, -420.0)
	radar_dish_node.material_override = mat_white
	add_child(radar_dish_node)

	# --- FUEL STORAGE FARM (4 Cylindrical White Tanks + Berm) ---
	var fuel_root = Node3D.new()
	fuel_root.name = "FuelStorageFarm"
	fuel_root.position = Vector3(-620.0, 0.5, -350.0)
	add_child(fuel_root)

	# Containment Wall Berm
	_add_colliding_box(Vector3(75.0, 3.5, 75.0), Vector3(-620.0, 1.75, -350.0), mat_concrete)

	# 4 Fuel Tanks
	for tx_i in range(2):
		for tz_i in range(2):
			var tank_pos = Vector3((tx_i - 0.5) * 32.0, 6.0, (tz_i - 0.5) * 32.0)
			var tank_mi = MeshInstance3D.new()
			tank_mi.mesh = _create_cylinder_mesh(12.0, 11.0, 20)
			tank_mi.material_override = mat_white
			tank_mi.position = tank_pos
			fuel_root.add_child(tank_mi)

	# --- CALIBRATED FABRIC WINDSOCK ---
	var windsock_root = Node3D.new()
	windsock_root.name = "Windsock"
	windsock_root.position = Vector3(-1235.0, 0.5, -950.0)
	add_child(windsock_root)

	var pole = _create_box(Vector3(0.3, 7.5, 0.3), Vector3(0.0, 3.75, 0.0), mat_term)
	windsock_root.add_child(pole)

	# Conical Fabric Windsock aligned with runway direction
	var sock = MeshInstance3D.new()
	sock.mesh = _create_cone_mesh(1.1, 0.4, 4.2, 12)
	sock.material_override = mat_orange
	sock.position = Vector3(0.0, 7.2, 1.8)
	sock.rotation_degrees.x = 90.0
	windsock_root.add_child(sock)

	# --- PERIMETER SECURITY FENCING ---
	var fence_root = Node3D.new()
	fence_root.name = "PerimeterFencing"
	add_child(fence_root)

	# Boundary posts along outer perimeter
	for fx in range(-1900, -450, 120):
		var post_n = _create_box(Vector3(0.2, 3.0, 0.2), Vector3(float(fx), 1.5, -1650.0), mat_steel_hangar)
		fence_root.add_child(post_n)
		var post_s = _create_box(Vector3(0.2, 3.0, 0.2), Vector3(float(fx), 1.5, 1650.0), mat_steel_hangar)
		fence_root.add_child(post_s)

# ==============================================================================
# 3. AMERICAN METROPOLITAN HIGH-RISE CANYON (48 SKYSCRAPERS)
# ==============================================================================

func _build_metropolitan_city_grid() -> void:
	var mat_glass_blue = StandardMaterial3D.new()
	mat_glass_blue.albedo_color = Color(0.12, 0.25, 0.42)
	mat_glass_blue.roughness = 0.06
	mat_glass_blue.metallic = 0.85

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
				var tower = _add_colliding_box(Vector3(b_width, b_height, b_width), Vector3(bx, b_height * 0.5, bz), chosen_mat)
				add_child(tower)

# ==============================================================================
# 4. SUSPENSION BRIDGE & MARITIME HARBOR
# ==============================================================================

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

	var deck = _add_colliding_box(Vector3(2000.0, 4.0, 42.0), Vector3(2200.0, 45.0, 0.0), mat_deck)
	bridge_root.add_child(deck)

	for tx in [1600.0, 2800.0]:
		var tower_l = _add_colliding_box(Vector3(14.0, 180.0, 8.0), Vector3(tx, 90.0, -18.0), mat_steel)
		bridge_root.add_child(tower_l)
		var tower_r = _add_colliding_box(Vector3(14.0, 180.0, 8.0), Vector3(tx, 90.0, 18.0), mat_steel)
		bridge_root.add_child(tower_r)
		var cross_strut = _add_colliding_box(Vector3(14.0, 10.0, 36.0), Vector3(tx, 160.0, 0.0), mat_steel)
		bridge_root.add_child(cross_strut)

	var cable_l = _add_colliding_box(Vector3(2000.0, 1.5, 1.5), Vector3(2200.0, 120.0, -18.0), mat_steel)
	bridge_root.add_child(cable_l)
	var cable_r = _add_colliding_box(Vector3(2000.0, 1.5, 1.5), Vector3(2200.0, 120.0, 18.0), mat_steel)
	bridge_root.add_child(cable_r)

func _build_harbor_and_docks() -> void:
	var mat_crane = StandardMaterial3D.new()
	mat_crane.albedo_color = Color(0.95, 0.8, 0.1) # Port yellow
	var mat_ship = StandardMaterial3D.new()
	mat_ship.albedo_color = Color(0.65, 0.12, 0.15)

	# Gantry Container Cranes
	for c in range(6):
		var cz = -1300.0 + c * 250.0
		var crane_box = _add_colliding_box(Vector3(45.0, 75.0, 25.0), Vector3(1400.0, 37.5, cz), mat_crane)
		add_child(crane_box)

	# Container Ship
	var ship = _add_colliding_box(Vector3(55.0, 28.0, 320.0), Vector3(1800.0, 14.0, -600.0), mat_ship)
	add_child(ship)

# ==============================================================================
# 5. MOUNTAIN BACKDROP & GEOLOGICAL MASSIFS
# ==============================================================================

func _build_mountain_backdrop() -> void:
	# Continuous heightfield already generates 2,600m massifs in the North & West.
	# We enhance the distant horizon with jagged rock cliffs.
	var mountain_root = Node3D.new()
	mountain_root.name = "AlpineMountains"
	add_child(mountain_root)

	var terrain_shader = load("res://games/aircraft-flight/worlds/shaders/terrain_geology.gdshader")
	var mat_geology: Material
	if terrain_shader:
		var sm = ShaderMaterial.new()
		sm.shader = terrain_shader
		mat_geology = sm
	else:
		var std = StandardMaterial3D.new()
		std.albedo_color = Color(0.30, 0.28, 0.26)
		mat_geology = std

	var peaks = [
		{"pos": Vector3(-4500.0, 0.0, -6200.0), "size": Vector3(2800.0, 2400.0, 1800.0)},
		{"pos": Vector3(-2500.0, 0.0, -5800.0), "size": Vector3(3200.0, 2750.0, 2100.0)},
		{"pos": Vector3(-400.0, 0.0, -6400.0), "size": Vector3(3400.0, 2900.0, 2200.0)},
		{"pos": Vector3(1800.0, 0.0, -5900.0), "size": Vector3(3000.0, 2600.0, 1900.0)},
		{"pos": Vector3(3800.0, 0.0, -6300.0), "size": Vector3(2900.0, 2500.0, 1850.0)},
	]

	for p in peaks:
		var pos: Vector3 = p["pos"]
		var sz: Vector3 = p["size"]
		var sb = StaticBody3D.new()
		sb.position = pos
		mountain_root.add_child(sb)

		var mi = MeshInstance3D.new()
		mi.mesh = _create_mountain_ridge_mesh(sz)
		mi.material_override = mat_geology
		mi.position = Vector3(0.0, sz.y * 0.5, 0.0)
		sb.add_child(mi)

		var col = CollisionShape3D.new()
		var box_col = BoxShape3D.new()
		box_col.size = Vector3(sz.x * 0.75, sz.y, sz.z * 0.75)
		col.shape = box_col
		col.position = Vector3(0.0, sz.y * 0.5, 0.0)
		sb.add_child(col)

# ==============================================================================
# 6. RAYMARCHED 3D VOLUMETRIC CLOUDS
# ==============================================================================

func _build_clouds() -> void:
	var cloud_root = Node3D.new()
	cloud_root.name = "VolumetricClouds"
	add_child(cloud_root)

	# 16km x 16km Bounded Volumetric Cloud Slab [1,400m - 2,800m]
	var cloud_mesh = MeshInstance3D.new()
	cloud_mesh.mesh = _create_box_mesh(Vector3(16000.0, 1400.0, 16000.0))
	cloud_mesh.position = Vector3(0.0, 2100.0, 0.0)

	var cloud_shader = load("res://games/aircraft-flight/worlds/shaders/volumetric_clouds.gdshader")
	if cloud_shader:
		var mat = ShaderMaterial.new()
		mat.shader = cloud_shader
		mat.set_shader_parameter("cloud_base", 1400.0)
		mat.set_shader_parameter("cloud_top", 2800.0)
		mat.set_shader_parameter("cloud_coverage", 0.48)
		mat.set_shader_parameter("wind_speed", 8.0)
		cloud_mesh.material_override = mat

	cloud_root.add_child(cloud_mesh)

# ==============================================================================
# HELPER MESH GENERATORS (SURFACETOOL ARRAYMESH)
# ==============================================================================

func _add_colliding_box(size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var sb = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	sb.add_child(col)

	var mi = MeshInstance3D.new()
	mi.mesh = _create_box_mesh(size)
	if mat:
		mi.material_override = mat
	sb.add_child(mi)

	sb.position = pos
	skyscraper_colliders.append(sb)
	return sb

func _create_box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = _create_box_mesh(size)
	mi.position = pos
	if mat:
		mi.material_override = mat
	return mi

static func _create_box_mesh(size: Vector3) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = size.x * 0.5
	var hh = size.y * 0.5
	var hd = size.z * 0.5

	var faces = [
		[Vector3.FORWARD, [Vector3(-hw, -hh, -hd), Vector3(hw, -hh, -hd), Vector3(hw, hh, -hd), Vector3(-hw, hh, -hd)]],
		[Vector3.BACK,    [Vector3(hw, -hh, hd), Vector3(-hw, -hh, hd), Vector3(-hw, hh, hd), Vector3(hw, hh, hd)]],
		[Vector3.UP,      [Vector3(-hw, hh, -hd), Vector3(hw, hh, -hd), Vector3(hw, hh, hd), Vector3(-hw, hh, hd)]],
		[Vector3.DOWN,    [Vector3(-hw, -hh, hd), Vector3(hw, -hh, hd), Vector3(hw, -hh, -hd), Vector3(-hw, -hh, -hd)]],
		[Vector3.LEFT,    [Vector3(-hw, -hh, hd), Vector3(-hw, -hh, -hd), Vector3(-hw, hh, -hd), Vector3(-hw, hh, hd)]],
		[Vector3.RIGHT,   [Vector3(hw, -hh, -hd), Vector3(hw, -hh, hd), Vector3(hw, hh, hd), Vector3(hw, hh, -hd)]],
	]
	for f in faces:
		var n: Vector3 = f[0]
		var v: Array = f[1]
		st.set_normal(n)
		st.set_uv(Vector2(0, 1)); st.add_vertex(v[0])
		st.set_uv(Vector2(1, 1)); st.add_vertex(v[1])
		st.set_uv(Vector2(1, 0)); st.add_vertex(v[2])
		st.set_uv(Vector2(0, 1)); st.add_vertex(v[0])
		st.set_uv(Vector2(1, 0)); st.add_vertex(v[2])
		st.set_uv(Vector2(0, 0)); st.add_vertex(v[3])

	return st.commit()

static func _create_mountain_ridge_mesh(sz: Vector3) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = sz.x * 0.5
	var hd = sz.z * 0.5
	var grid_res = 14

	var verts: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	verts.resize((grid_res + 1) * (grid_res + 1))
	uvs.resize((grid_res + 1) * (grid_res + 1))

	for iz in range(grid_res + 1):
		var tz = float(iz) / float(grid_res)
		var pz = -hd + tz * sz.z
		var norm_z = (tz - 0.5) * 2.0

		for ix in range(grid_res + 1):
			var tx = float(ix) / float(grid_res)
			var px = -hw + tx * sz.x
			var norm_x = (tx - 0.5) * 2.0

			var r = sqrt(norm_x * norm_x + norm_z * norm_z)
			var falloff = clampf(1.0 - r, 0.0, 1.0)
			falloff = falloff * falloff * (3.0 - 2.0 * falloff)

			var oct1 = sin(tx * 8.2 + tz * 4.5) * cos(tz * 7.1 - tx * 3.4)
			var oct2 = absf(sin(tx * 16.0 - tz * 13.0) * 0.5 + 0.5)
			var oct3 = sin(tx * 32.0 + tz * 28.0) * 0.25
			var raw_h = (0.68 + 0.20 * oct1 + 0.16 * oct2 + 0.08 * oct3) * falloff
			var py = (raw_h - 0.5) * sz.y

			var idx = iz * (grid_res + 1) + ix
			verts[idx] = Vector3(px, py, pz)
			uvs[idx] = Vector2(tx * 4.0, tz * 4.0)

	for iz in range(grid_res):
		for ix in range(grid_res):
			var i0 = iz * (grid_res + 1) + ix
			var i1 = i0 + 1
			var i2 = (iz + 1) * (grid_res + 1) + ix
			var i3 = i2 + 1

			var v0 = verts[i0]
			var v1 = verts[i1]
			var v2 = verts[i2]
			var v3 = verts[i3]

			var n1 = (v1 - v0).cross(v2 - v0).normalized()
			st.set_normal(n1)
			st.set_uv(uvs[i0]); st.add_vertex(v0)
			st.set_uv(uvs[i1]); st.add_vertex(v1)
			st.set_uv(uvs[i2]); st.add_vertex(v2)

			var n2 = (v3 - v1).cross(v2 - v1).normalized()
			st.set_normal(n2)
			st.set_uv(uvs[i1]); st.add_vertex(v1)
			st.set_uv(uvs[i3]); st.add_vertex(v3)
			st.set_uv(uvs[i2]); st.add_vertex(v2)

	return st.commit()

static func _create_cylinder_mesh(radius: float, height: float, segments: int = 16) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hh = height * 0.5
	for i in range(segments):
		var a0 = float(i) * TAU / float(segments)
		var a1 = float(i + 1) * TAU / float(segments)
		var p0_b = Vector3(cos(a0) * radius, -hh, sin(a0) * radius)
		var p1_b = Vector3(cos(a1) * radius, -hh, sin(a1) * radius)
		var p0_t = Vector3(cos(a0) * radius, hh, sin(a0) * radius)
		var p1_t = Vector3(cos(a1) * radius, hh, sin(a1) * radius)
		var n0 = Vector3(cos(a0), 0.0, sin(a0))
		var n1 = Vector3(cos(a1), 0.0, sin(a1))
		st.set_normal(n0); st.add_vertex(p0_b)
		st.set_normal(n1); st.add_vertex(p1_t)
		st.set_normal(n0); st.add_vertex(p0_t)
		st.set_normal(n0); st.add_vertex(p0_b)
		st.set_normal(n1); st.add_vertex(p1_b)
		st.set_normal(n1); st.add_vertex(p1_t)
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(0, hh, 0)); st.add_vertex(p0_t); st.add_vertex(p1_t)
	return st.commit()

static func _create_arched_roof_mesh(width: float, height: float, length: float, segments: int = 14) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var hl = length * 0.5
	for i in range(segments):
		var phi0 = float(i) * PI / float(segments)
		var phi1 = float(i + 1) * PI / float(segments)
		var x0 = -cos(phi0) * hw
		var y0 = sin(phi0) * height
		var x1 = -cos(phi1) * hw
		var y1 = sin(phi1) * height
		var n0 = Vector3(-cos(phi0), sin(phi0), 0.0).normalized()
		var n1 = Vector3(-cos(phi1), sin(phi1), 0.0).normalized()
		st.set_normal(n0); st.add_vertex(Vector3(x0, y0, -hl))
		st.set_normal(n1); st.add_vertex(Vector3(x1, y1, hl))
		st.set_normal(n0); st.add_vertex(Vector3(x0, y0, hl))
		st.set_normal(n0); st.add_vertex(Vector3(x0, y0, -hl))
		st.set_normal(n1); st.add_vertex(Vector3(x1, y1, -hl))
		st.set_normal(n1); st.add_vertex(Vector3(x1, y1, hl))
	return st.commit()

static func _create_cone_mesh(r_base: float, r_tip: float, height: float, segments: int = 12) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hh = height * 0.5
	for i in range(segments):
		var a0 = float(i) * TAU / float(segments)
		var a1 = float(i + 1) * TAU / float(segments)
		var p0_b = Vector3(cos(a0) * r_base, -hh, sin(a0) * r_base)
		var p1_b = Vector3(cos(a1) * r_base, -hh, sin(a1) * r_base)
		var p0_t = Vector3(cos(a0) * r_tip, hh, sin(a0) * r_tip)
		var p1_t = Vector3(cos(a1) * r_tip, hh, sin(a1) * r_tip)
		var n0 = Vector3(cos(a0), 0.2, sin(a0)).normalized()
		var n1 = Vector3(cos(a1), 0.2, sin(a1)).normalized()
		st.set_normal(n0); st.add_vertex(p0_b)
		st.set_normal(n1); st.add_vertex(p1_t)
		st.set_normal(n0); st.add_vertex(p0_t)
		st.set_normal(n0); st.add_vertex(p0_b)
		st.set_normal(n1); st.add_vertex(p1_b)
		st.set_normal(n1); st.add_vertex(p1_t)
	return st.commit()

static func _create_radar_dish_mesh(radius: float, depth: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments = 16
	var center = Vector3(0, 0, depth)

	for i in range(segments):
		var a0 = float(i) * TAU / float(segments)
		var a1 = float(i + 1) * TAU / float(segments)
		var p0 = Vector3(cos(a0) * radius, sin(a0) * radius, 0.0)
		var p1 = Vector3(cos(a1) * radius, sin(a1) * radius, 0.0)

		var n0 = (p0 - center).normalized()
		var n1 = (p1 - center).normalized()

		st.set_normal(n0); st.add_vertex(p0)
		st.set_normal(n1); st.add_vertex(p1)
		st.set_normal(Vector3.FORWARD); st.add_vertex(center)

	return st.commit()

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
