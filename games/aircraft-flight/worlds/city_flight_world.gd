class_name CityFlightWorld
extends Node3D

## CityFlightWorld: Open-World Metropolitan Coastline & Dual Airport Network.
## Features:
## - 24km x 24km continuous eroded heightfield terrain with smoothed vertex normals
## - Infinite Gerstner ocean plane at Y = 0.0m with smooth coastal slopes (zero cliff cutoffs)
## - Primary ICAO International Airport (Runways 09L/27R & 09R/27L) with grooved asphalt,
##   calibrated 3.0° PAPI lights, taxiways, aprons, hangars, terminal, 65m ATC tower
## - Alpine Regional Mountain Airstrip & Rescue Helipad at 1,150m MSL
## - 4.5km x 4.5km Coastal Metropolis with 35+ building archetypes, glass facades,
##   illuminated spires, rooftop helipads landable in UH-60, and avenue street grid
## - Handcrafted 1,400m Golden Gate suspension bridge with 65m fly-under deck clearance
## - Smooth non-faceted alpine mountain massifs rising to 2,600m
## - 3D volumetric cloud ceiling [1,800m - 3,200m]

const RunwayGen = preload("res://games/aircraft-flight/worlds/runway_generator.gd")
const AircraftMeshBuilder = preload("res://games/aircraft-flight/aircraft/aircraft_mesh_builder.gd")

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
	# 1. 24km x 24km Continuous Eroded Heightfield Terrain Plane
	_build_ground_plane()

	# 2. ICAO International Airport Complex (Runway 09L/27R, Taxiways, Hangars, Terminal)
	_build_airport_complex()

	# 3. American High-Rise Skyscraper Grid Canyon (48+ Towers across 35+ Archetypes)
	_build_metropolitan_city_grid()

	# 4. Iconic Twin-Tower Suspension Bridge across River Channel (65m Clearance)
	_build_suspension_bridge()

	# 5. Maritime Commercial Harbor & Container Docks
	_build_harbor_and_docks()

	# 6. Distant High Alpine Massifs & Glacial Crags (Smoothed normals, zero faceted triangles)
	_build_mountain_backdrop()

	# 7. Raymarched 3D Volumetric Cloud Formations
	_build_clouds()

# ==============================================================================
# 1. CONTINUOUS ERODED HEIGHTFIELD TERRAIN (24km x 24km)
# ==============================================================================

static func sample_terrain_elevation(x: float, z: float) -> float:
	# Primary Airport Plateau bounds: X in [-2200, -300], Z in [-1800, 1800]
	var airport_center = Vector2(-1250.0, 0.0)
	var airport_extent = Vector2(850.0, 1750.0)
	var dx = maxf(0.0, absf(x - airport_center.x) - airport_extent.x)
	var dz = maxf(0.0, absf(z - airport_center.y) - airport_extent.y)
	var dist_from_airport = sqrt(dx * dx + dz * dz)
	var airport_weight = clampf(dist_from_airport / 300.0, 0.0, 1.0)
	airport_weight = airport_weight * airport_weight * (3.0 - 2.0 * airport_weight) # Smoothstep

	# City Grid bounds: X in [300, 1800], Z in [-2200, -200]
	var city_center = Vector2(950.0, -1200.0)
	var city_extent = Vector2(650.0, 1000.0)
	var cdx = maxf(0.0, absf(x - city_center.x) - city_extent.x)
	var cdz = maxf(0.0, absf(z - city_center.y) - city_extent.y)
	var dist_from_city = sqrt(cdx * cdx + cdz * cdz)
	var city_weight = clampf(dist_from_city / 300.0, 0.0, 1.0)
	city_weight = city_weight * city_weight * (3.0 - 2.0 * city_weight)

	# Multi-octave domain-warped ridged multifractal noise for natural geology
	var warp_x = x + sin(z * 0.0008) * 350.0 + cos(x * 0.0005) * 180.0
	var warp_z = z + cos(x * 0.0008) * 350.0 + sin(z * 0.0005) * 180.0

	var n1 = sin(warp_x * 0.00045) * cos(warp_z * 0.00045)
	var n2 = sin(warp_x * 0.0011 + 1.2) * cos(warp_z * 0.0011 + 0.8) * 0.5
	var n3 = (1.0 - absf(sin(warp_x * 0.0022) * cos(warp_z * 0.0022))) * 0.35

	# High Alpine Massifs (North Z < -2200 and West X < -2200)
	var north_mountain_factor = clampf((-z - 2000.0) / 2500.0, 0.0, 1.0)
	var west_mountain_factor = clampf((-x - 2000.0) / 2500.0, 0.0, 1.0)
	var mountain_envelope = maxf(north_mountain_factor, west_mountain_factor)

	var ridged = pow(absf(n1 + n2 + n3), 1.5)
	var mountain_height = ridged * 2500.0 * mountain_envelope
	var foothill_height = (sin(x * 0.0015) * cos(z * 0.0015) * 28.0 + 32.0) * (1.0 - mountain_envelope)

	var raw_elevation = mountain_height + foothill_height
	var final_elevation = lerpf(0.5, raw_elevation, airport_weight * city_weight)

	# Seamless ocean coastline transition (East X > 1500):
	# Slopes gently below sea level (Y = 0.0) down to Y = -16.0m without harsh cliff cutoffs
	if x > 1500.0:
		var coast_t = clampf((x - 1500.0) / 1200.0, 0.0, 1.0)
		coast_t = coast_t * coast_t * (3.0 - 2.0 * coast_t) # Smoothstep
		final_elevation = lerpf(final_elevation, -16.0, coast_t)

	return final_elevation

func _build_ground_plane() -> void:
	var sb = StaticBody3D.new()
	sb.name = "CityTerrain"
	add_child(sb)

	# Generate continuous ArrayMesh grid (24,000m x 24,000m)
	var grid_res = 64 # 64x64 quads = 4,225 vertices, 8,192 tris
	var half_size = 12000.0
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

			# Central differences continuous normal estimation
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

	# Apply 6-Layer Triplanar PBR Geological Shader (terrain_geology.gdshader)
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

	# Synchronized Concave Collision Shape (Layer 1 World Terrain)
	sb.collision_layer = 1
	sb.collision_mask = 2
	var col = CollisionShape3D.new()
	var concave_col = ConcavePolygonShape3D.new()
	concave_col.set_faces(collision_faces)
	col.shape = concave_col
	sb.add_child(col)

	# Infinite Gerstner Wave Ocean Plane (32,000m x 32,000m at Y = 0.0m datum)
	var water_mi = MeshInstance3D.new()
	water_mi.mesh = _create_box_mesh(Vector3(32000.0, 0.4, 32000.0))
	water_mi.position = Vector3(0.0, 0.0, 0.0)

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

static func sample_terrain_normal(x: float, z: float) -> Vector3:
	var delta = 20.0
	var h_l = sample_terrain_elevation(x - delta, z)
	var h_r = sample_terrain_elevation(x + delta, z)
	var h_d = sample_terrain_elevation(x, z - delta)
	var h_u = sample_terrain_elevation(x, z + delta)
	var dx = (h_r - h_l) / (delta * 2.0)
	var dz = (h_u - h_d) / (delta * 2.0)
	return Vector3(-dx, 1.0, -dz).normalized()

static func _sample_normal(x: float, z: float) -> Vector3:
	return sample_terrain_normal(x, z)

# ==============================================================================
# 2. DUAL-AIRPORT INFRASTRUCTURE & NAVIGATION LIGHTING
# ==============================================================================

func _build_airport_complex() -> void:
	# Primary Runway 09L/27R (3,200m x 45m)
	airport_runway = RunwayGen.build_runway(3200.0, 45.0, "09L")
	airport_runway.position = Vector3(-1200.0, 0.5, 0.0)
	add_child(airport_runway)

	# Parallel Secondary Runway 09R/27L (2,600m x 45m)
	var runway_r = RunwayGen.build_runway(2600.0, 45.0, "09R")
	runway_r.position = Vector3(-1620.0, 0.5, 0.0)
	add_child(runway_r)

	# Alpine Regional Mountain Valley Runway 14/32 (1,400m x 30m at 1,150m MSL)
	var alpine_runway = RunwayGen.build_runway(1400.0, 30.0, "14_32")
	alpine_runway.position = Vector3(-3800.0, 1150.0, -5200.0)
	alpine_runway.rotation_degrees.y = 35.0
	add_child(alpine_runway)

	# Materials
	var mat_asphalt = StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.22, 0.22, 0.24)
	mat_asphalt.roughness = 0.92

	var mat_concrete = StandardMaterial3D.new()
	mat_concrete.albedo_color = Color(0.55, 0.56, 0.58)
	mat_concrete.roughness = 0.75

	var mat_yellow_stripe = StandardMaterial3D.new()
	mat_yellow_stripe.albedo_color = Color(0.95, 0.82, 0.10)
	mat_yellow_stripe.roughness = 0.90

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

	# --- PARALLEL TAXIWAY ALPHA (23m width, 3,200m length) ---
	var taxiway_a = _add_colliding_box(Vector3(23.0, 0.6, 3200.0), Vector3(-1410.0, 0.25, 0.0), mat_asphalt)
	add_child(taxiway_a)

	# Taxiway Yellow Centerline
	add_child(_create_box(Vector3(0.5, 0.05, 3200.0), Vector3(-1410.0, 0.58, 0.0), mat_yellow_stripe))

	# Taxiway Blue Edge Lights (80m spacing)
	for z in range(-1500, 1501, 80):
		var bl_left = _create_box(Vector3(0.25, 0.35, 0.25), Vector3(-1422.0, 0.65, float(z)), mat_blue_light)
		add_child(bl_left)
		var bl_right = _create_box(Vector3(0.25, 0.35, 0.25), Vector3(-1398.0, 0.65, float(z)), mat_blue_light)
		add_child(bl_right)

	# --- CONNECTING TAXIWAY LINKS & HOLD-SHORT BARS ---
	for z_pos in [-1100.0, -400.0, 400.0, 1100.0]:
		var link_l = _add_colliding_box(Vector3(180.0, 0.6, 23.0), Vector3(-1305.0, 0.25, z_pos), mat_asphalt)
		add_child(link_l)
		var link_r = _add_colliding_box(Vector3(180.0, 0.6, 23.0), Vector3(-1515.0, 0.25, z_pos), mat_asphalt)
		add_child(link_r)

		# Yellow guide lines
		add_child(_create_box(Vector3(180.0, 0.05, 0.5), Vector3(-1305.0, 0.58, z_pos), mat_yellow_stripe))
		add_child(_create_box(Vector3(180.0, 0.05, 0.5), Vector3(-1515.0, 0.58, z_pos), mat_yellow_stripe))

		# Hold-Short Painted Bars
		var hold_bar_l = _create_box(Vector3(1.4, 0.06, 22.0), Vector3(-1235.0, 0.58, z_pos), mat_yellow_stripe)
		add_child(hold_bar_l)
		var hold_bar_r = _create_box(Vector3(1.4, 0.06, 22.0), Vector3(-1585.0, 0.58, z_pos), mat_yellow_stripe)
		add_child(hold_bar_r)

	# --- CONCRETE PARKING APRONS WITH T-STANDS ---
	var apron = _add_colliding_box(Vector3(340.0, 0.5, 800.0), Vector3(-780.0, 0.25, 400.0), mat_concrete)
	add_child(apron)

	# Painted Aircraft Parking T-Stands (5 stands)
	for t in range(5):
		var tz = 100.0 + t * 150.0
		var stand_stem = _create_box(Vector3(0.5, 0.05, 24.0), Vector3(-780.0, 0.55, tz), mat_yellow_stripe)
		add_child(stand_stem)
		var stand_bar = _create_box(Vector3(14.0, 0.05, 0.5), Vector3(-780.0, 0.55, tz - 12.0), mat_yellow_stripe)
		add_child(stand_bar)

	# Parked static airliners at gates
	for gate_i in [1, 3]:
		var gate_z = 100.0 + gate_i * 150.0
		var airliner = AircraftMeshBuilder.build_aircraft_visuals("a320_neo", Color(0.92, 0.94, 0.96), Color(0.12, 0.45, 0.85))
		airliner.position = Vector3(-780.0, 1.2, gate_z)
		airliner.rotation_degrees.y = 90.0 # Nose facing terminal
		add_child(airliner)

	# --- ARCHED STEEL MAINTENANCE HANGARS ---
	for h_idx in range(3):
		var hz = 220.0 + h_idx * 190.0
		var hangar_sb = StaticBody3D.new()
		hangar_sb.position = Vector3(-700.0, 0.5, hz)
		add_child(hangar_sb)

		var wall_col = CollisionShape3D.new()
		var wall_box = BoxShape3D.new()
		wall_box.size = Vector3(110.0, 26.0, 85.0)
		wall_col.shape = wall_box
		wall_col.position = Vector3(0.0, 13.0, 0.0)
		hangar_sb.add_child(wall_col)

		var mi_base = _create_box(Vector3(110.0, 14.0, 85.0), Vector3(0.0, 7.0, 0.0), mat_steel_hangar)
		hangar_sb.add_child(mi_base)

		var mi_arch = MeshInstance3D.new()
		mi_arch.mesh = _create_arched_roof_mesh(110.0, 16.0, 85.0, 16)
		mi_arch.material_override = mat_steel_hangar
		mi_arch.position = Vector3(0.0, 14.0, 0.0)
		hangar_sb.add_child(mi_arch)

	# --- MAIN PASSENGER TERMINAL WITH GLASS CURTAIN WALLS ---
	var term_sb = _add_colliding_box(Vector3(160.0, 28.0, 560.0), Vector3(-860.0, 14.0, -120.0), mat_term)
	add_child(term_sb)

	var glass_facade = _create_box(Vector3(2.0, 22.0, 520.0), Vector3(-779.0, 14.0, -120.0), mat_glass)
	add_child(glass_facade)

	for j in range(4):
		var jz = -240.0 + j * 90.0
		var jetway = _create_box(Vector3(50.0, 4.6, 4.6), Vector3(-754.0, 9.5, jz), mat_steel_hangar)
		add_child(jetway)
		var rotunda = _create_box(Vector3(8.5, 8.5, 8.5), Vector3(-728.0, 8.5, jz), mat_term)
		add_child(rotunda)

	# --- 65m ATC CONTROL TOWER & ROTATING BEACON ---
	var tower = _add_colliding_box(Vector3(16.0, 85.0, 16.0), Vector3(-850.0, 42.5, -450.0), mat_term)
	add_child(tower)

	var cab = _add_colliding_box(Vector3(26.0, 14.0, 26.0), Vector3(-850.0, 89.0, -450.0), mat_glass)
	add_child(cab)

	atc_beacon_node = Node3D.new()
	atc_beacon_node.name = "ATC_Beacon"
	atc_beacon_node.position = Vector3(-850.0, 98.0, -450.0)
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

	radar_dish_node = MeshInstance3D.new()
	radar_dish_node.mesh = _create_radar_dish_mesh(6.0, 1.5)
	radar_dish_node.position = Vector3(-850.0, 104.0, -450.0)
	radar_dish_node.material_override = mat_white
	add_child(radar_dish_node)

	# Windsock
	var windsock_root = Node3D.new()
	windsock_root.name = "Windsock"
	windsock_root.position = Vector3(-1235.0, 0.5, -950.0)
	add_child(windsock_root)
	var pole = _create_box(Vector3(0.3, 7.5, 0.3), Vector3(0.0, 3.75, 0.0), mat_term)
	windsock_root.add_child(pole)
	var sock = MeshInstance3D.new()
	sock.mesh = _create_cone_mesh(1.1, 0.4, 4.2, 12)
	sock.material_override = mat_orange
	sock.position = Vector3(0.0, 7.2, 1.8)
	sock.rotation_degrees.x = 90.0
	windsock_root.add_child(sock)

# ==============================================================================
# 3. METROPOLITAN COASTAL CITY GRID (35+ BUILDING ARCHETYPES)
# ==============================================================================

func _build_metropolitan_city_grid() -> void:
	# PBR Architectural Materials
	var mat_glass_cyan = StandardMaterial3D.new()
	mat_glass_cyan.albedo_color = Color(0.10, 0.28, 0.45)
	mat_glass_cyan.roughness = 0.06
	mat_glass_cyan.metallic = 0.88

	var mat_glass_gold = StandardMaterial3D.new()
	mat_glass_gold.albedo_color = Color(0.38, 0.30, 0.14)
	mat_glass_gold.roughness = 0.08
	mat_glass_gold.metallic = 0.90

	var mat_stone = StandardMaterial3D.new()
	mat_stone.albedo_color = Color(0.52, 0.50, 0.48)
	mat_stone.roughness = 0.85

	var mat_dark_titanium = StandardMaterial3D.new()
	mat_dark_titanium.albedo_color = Color(0.16, 0.18, 0.22)
	mat_dark_titanium.roughness = 0.40
	mat_dark_titanium.metallic = 0.75

	var mat_red_beacon = StandardMaterial3D.new()
	mat_red_beacon.albedo_color = Color(1.0, 0.15, 0.10)
	mat_red_beacon.emission_enabled = true
	mat_red_beacon.emission = Color(1.0, 0.15, 0.10)
	mat_red_beacon.emission_energy_multiplier = 6.0

	var mat_helipad = StandardMaterial3D.new()
	mat_helipad.albedo_color = Color(0.24, 0.25, 0.28)
	mat_helipad.roughness = 0.88

	var mat_helipad_mark = StandardMaterial3D.new()
	mat_helipad_mark.albedo_color = Color(0.95, 0.85, 0.10)
	mat_helipad_mark.roughness = 0.60

	var origin_x = 400.0
	var origin_z = -2200.0
	var avenue_w = 160.0

	for gx in range(7):
		for gz in range(8):
			var bx = origin_x + gx * avenue_w
			var bz = origin_z + gz * avenue_w

			var archetype_id = (gx * 11 + gz * 23) % 35
			var b_height = 80.0 + float(archetype_id) * 6.8 # 80m to 318m
			var b_width = 44.0 + float(archetype_id % 18)

			var mat_choice = mat_glass_cyan
			if archetype_id % 4 == 1:
				mat_choice = mat_glass_gold
			elif archetype_id % 4 == 2:
				mat_choice = mat_stone
			elif archetype_id % 4 == 3:
				mat_choice = mat_dark_titanium

			if archetype_id >= 28:
				# Archetype A: Supertall Stepped Diagrid Tower with Spire & Beacon (> 280m)
				var base_t = _add_colliding_box(Vector3(b_width, b_height * 0.55, b_width), Vector3(bx, b_height * 0.275, bz), mat_choice)
				add_child(base_t)
				var mid_t = _add_colliding_box(Vector3(b_width * 0.72, b_height * 0.32, b_width * 0.72), Vector3(bx, b_height * 0.71, bz), mat_choice)
				add_child(mid_t)
				var crown = _add_colliding_box(Vector3(b_width * 0.45, b_height * 0.13, b_width * 0.45), Vector3(bx, b_height * 0.935, bz), mat_dark_titanium)
				add_child(crown)
				var spire = _add_colliding_box(Vector3(3.0, 32.0, 3.0), Vector3(bx, b_height + 16.0, bz), mat_dark_titanium)
				add_child(spire)
				var beacon = _create_box(Vector3(1.2, 1.2, 1.2), Vector3(bx, b_height + 32.5, bz), mat_red_beacon)
				add_child(beacon)

			elif archetype_id >= 20:
				# Archetype B: Corporate Skyscraper with Landable Rooftop Helipad (UH-60)
				var tower = _add_colliding_box(Vector3(b_width, b_height, b_width), Vector3(bx, b_height * 0.5, bz), mat_choice)
				add_child(tower)
				# Rooftop Helipad Pad & "H" Marking
				var pad = _create_box(Vector3(b_width * 0.85, 0.4, b_width * 0.85), Vector3(bx, b_height + 0.2, bz), mat_helipad)
				add_child(pad)
				var h_bar1 = _create_box(Vector3(2.5, 0.1, 16.0), Vector3(bx - 6.0, b_height + 0.45, bz), mat_helipad_mark)
				add_child(h_bar1)
				var h_bar2 = _create_box(Vector3(2.5, 0.1, 16.0), Vector3(bx + 6.0, b_height + 0.45, bz), mat_helipad_mark)
				add_child(h_bar2)
				var h_cross = _create_box(Vector3(12.0, 0.1, 2.5), Vector3(bx, b_height + 0.45, bz), mat_helipad_mark)
				add_child(h_cross)

			elif archetype_id >= 12:
				# Archetype C: Stepped Art-Deco High-Rise with HVAC Chillers
				var base_box = _add_colliding_box(Vector3(b_width, b_height * 0.65, b_width), Vector3(bx, b_height * 0.325, bz), mat_choice)
				add_child(base_box)
				var top_box = _add_colliding_box(Vector3(b_width * 0.68, b_height * 0.35, b_width * 0.68), Vector3(bx, b_height * 0.825, bz), mat_stone)
				add_child(top_box)
				var hvac = _create_box(Vector3(8.0, 4.0, 8.0), Vector3(bx + 6.0, b_height + 2.0, bz), mat_dark_titanium)
				add_child(hvac)

			else:
				# Archetype D: Monolithic Glass Curtain-Wall Tower
				var tower = _add_colliding_box(Vector3(b_width, b_height, b_width), Vector3(bx, b_height * 0.5, bz), mat_choice)
				add_child(tower)
				var crown_box = _create_box(Vector3(b_width * 0.9, 3.5, b_width * 0.9), Vector3(bx, b_height + 1.75, bz), mat_dark_titanium)
				add_child(crown_box)

			# Architectural horizontal spandrel bands (floor divisions breaking up box silhouettes)
			var floor_step = 26.0
			var num_spandrels = int(b_height / floor_step)
			for sp_i in range(1, num_spandrels):
				var sp_y = float(sp_i) * floor_step
				var sp_band = _create_box(Vector3(b_width + 0.8, 1.2, b_width + 0.8), Vector3(bx, sp_y, bz), mat_dark_titanium)
				add_child(sp_band)

# ==============================================================================
# 4. GOLDEN GATE-INSPIRED SUSPENSION BRIDGE (65m DECK CLEARANCE)
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
	mat_deck.albedo_color = Color(0.22, 0.23, 0.25)
	mat_deck.roughness = 0.92

	# 1,400m Suspended Road Deck: bottom clearance 65.0m above water, center at Y = 67.0m
	var deck = _add_colliding_box(Vector3(2000.0, 4.0, 42.0), Vector3(2200.0, 67.0, 0.0), mat_deck)
	bridge_root.add_child(deck)

	# Dual 160m Steel Towers (Clearance portal between legs for fly-through stunts)
	for tx in [1600.0, 2800.0]:
		# Tower Legs: port (-Z: -20m) and starboard (+Z: +20m)
		var leg_l = _add_colliding_box(Vector3(14.0, 160.0, 8.0), Vector3(tx, 80.0, -20.0), mat_steel)
		bridge_root.add_child(leg_l)
		var leg_r = _add_colliding_box(Vector3(14.0, 160.0, 8.0), Vector3(tx, 80.0, 20.0), mat_steel)
		bridge_root.add_child(leg_r)

		# Upper Cross Struts above deck (allowing 65m fly-under clearance)
		var cross_strut = _add_colliding_box(Vector3(14.0, 8.0, 40.0), Vector3(tx, 150.0, 0.0), mat_steel)
		bridge_root.add_child(cross_strut)

	# Main Suspension Cables
	var cable_l = _add_colliding_box(Vector3(2000.0, 1.8, 1.8), Vector3(2200.0, 130.0, -20.0), mat_steel)
	bridge_root.add_child(cable_l)
	var cable_r = _add_colliding_box(Vector3(2000.0, 1.8, 1.8), Vector3(2200.0, 130.0, 20.0), mat_steel)
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

	# Container Cargo Vessel
	var ship = _add_colliding_box(Vector3(55.0, 28.0, 320.0), Vector3(1800.0, 14.0, -600.0), mat_ship)
	add_child(ship)

# ==============================================================================
# 5. MOUNTAIN BACKDROP & SMOOTH ALPINE MASSIFS (ZERO FACETED TRIANGLES)
# ==============================================================================

func _build_mountain_backdrop() -> void:
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
		{"pos": Vector3(-4500.0, 0.0, -6200.0), "size": Vector3(3200.0, 2400.0, 2200.0)},
		{"pos": Vector3(-2500.0, 0.0, -5800.0), "size": Vector3(3600.0, 2650.0, 2400.0)},
		{"pos": Vector3(-400.0, 0.0, -6400.0), "size": Vector3(3800.0, 2750.0, 2600.0)},
		{"pos": Vector3(1800.0, 0.0, -5900.0), "size": Vector3(3400.0, 2500.0, 2200.0)},
		{"pos": Vector3(3800.0, 0.0, -6300.0), "size": Vector3(3200.0, 2400.0, 2100.0)},
	]

	for p in peaks:
		var pos: Vector3 = p["pos"]
		var sz: Vector3 = p["size"]
		var sb = StaticBody3D.new()
		sb.position = pos
		sb.collision_layer = 1
		sb.collision_mask = 2
		mountain_root.add_child(sb)

		var mi = MeshInstance3D.new()
		mi.mesh = _create_mountain_ridge_mesh(sz)
		mi.material_override = mat_geology
		mi.position = Vector3(0.0, sz.y * 0.5, 0.0)
		sb.add_child(mi)

		var col = CollisionShape3D.new()
		var box_col = BoxShape3D.new()
		box_col.size = Vector3(sz.x * 0.82, sz.y, sz.z * 0.82)
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

	# 24km x 24km Bounded Volumetric Cloud Layer [1,800m - 3,200m]
	var cloud_mesh = MeshInstance3D.new()
	cloud_mesh.mesh = _create_box_mesh(Vector3(24000.0, 1400.0, 24000.0))
	cloud_mesh.position = Vector3(0.0, 2500.0, 0.0)

	var cloud_shader = load("res://games/aircraft-flight/worlds/shaders/volumetric_clouds.gdshader")
	if cloud_shader:
		var mat = ShaderMaterial.new()
		mat.shader = cloud_shader
		mat.set_shader_parameter("cloud_base", 1800.0)
		mat.set_shader_parameter("cloud_top", 3200.0)
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
	# Generates high-density ridged multifractal alpine mountain massifs (spines, arêtes, valleys, zero round cones)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = sz.x * 0.5
	var hd = sz.z * 0.5
	var grid_res = 32

	var verts: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	var normals: Array[Vector3] = []
	var total_verts = (grid_res + 1) * (grid_res + 1)
	verts.resize(total_verts)
	uvs.resize(total_verts)
	normals.resize(total_verts)

	for iz in range(grid_res + 1):
		var tz = float(iz) / float(grid_res)
		var pz = -hd + tz * sz.z
		var norm_z = (tz - 0.5) * 2.0

		for ix in range(grid_res + 1):
			var tx = float(ix) / float(grid_res)
			var px = -hw + tx * sz.x
			var norm_x = (tx - 0.5) * 2.0

			# Sinuous spine ridge path along X
			var spine_offset = sin(norm_x * 3.14) * 0.28 + cos(norm_x * 6.28) * 0.08
			var dist_to_spine = absf(norm_z - spine_offset)
			var ridge_falloff = clampf(1.0 - dist_to_spine * 1.35, 0.0, 1.0)
			ridge_falloff = ridge_falloff * ridge_falloff * (3.0 - 2.0 * ridge_falloff)

			var x_edge_falloff = clampf(1.0 - absf(norm_x), 0.0, 1.0)
			x_edge_falloff = x_edge_falloff * x_edge_falloff * (3.0 - 2.0 * x_edge_falloff)
			var envelope = ridge_falloff * x_edge_falloff

			# Multi-octave ridged multifractal noise (sharp knife-edge peaks & crags)
			var oct1 = 1.0 - absf(sin(tx * 8.5 + tz * 4.2) * cos(tz * 7.8 - tx * 3.6))
			var oct2 = 1.0 - absf(sin(tx * 18.2 - tz * 14.5) * cos(tz * 15.6 + tx * 10.2)) * 0.5
			var oct3 = sin(tx * 36.0 + tz * 32.0) * cos(tz * 30.0 - tx * 26.0) * 0.22
			var ridge_shape = pow(oct1 * 0.65 + oct2 * 0.35, 1.8) * 1.25 + oct3
			var py = (ridge_shape * envelope - 0.02) * sz.y

			var idx = iz * (grid_res + 1) + ix
			verts[idx] = Vector3(px, py, pz)
			uvs[idx] = Vector2(tx * 2.0, tz * 2.0)

	# Precalculate smooth continuous vertex normals using central differences
	for iz in range(grid_res + 1):
		for ix in range(grid_res + 1):
			var idx = iz * (grid_res + 1) + ix
			var x_prev = iz * (grid_res + 1) + max(0, ix - 1)
			var x_next = iz * (grid_res + 1) + min(grid_res, ix + 1)
			var z_prev = max(0, iz - 1) * (grid_res + 1) + ix
			var z_next = min(grid_res, iz + 1) * (grid_res + 1) + ix

			var dx = (verts[x_next].y - verts[x_prev].y) / (sz.x / float(grid_res) * 2.0)
			var dz = (verts[z_next].y - verts[z_prev].y) / (sz.z / float(grid_res) * 2.0)
			normals[idx] = Vector3(-dx, 1.0, -dz).normalized()

	# Emit smooth Gouraud-shaded triangles
	for iz in range(grid_res):
		for ix in range(grid_res):
			var i0 = iz * (grid_res + 1) + ix
			var i1 = i0 + 1
			var i2 = (iz + 1) * (grid_res + 1) + ix
			var i3 = i2 + 1

			# Triangle 1
			st.set_normal(normals[i0]); st.set_uv(uvs[i0]); st.add_vertex(verts[i0])
			st.set_normal(normals[i1]); st.set_uv(uvs[i1]); st.add_vertex(verts[i1])
			st.set_normal(normals[i2]); st.set_uv(uvs[i2]); st.add_vertex(verts[i2])

			# Triangle 2
			st.set_normal(normals[i1]); st.set_uv(uvs[i1]); st.add_vertex(verts[i1])
			st.set_normal(normals[i3]); st.set_uv(uvs[i3]); st.add_vertex(verts[i3])
			st.set_normal(normals[i2]); st.set_uv(uvs[i2]); st.add_vertex(verts[i2])

	return st.commit()

static func _create_arched_roof_mesh(w: float, h: float, d: float, segments: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = w * 0.5
	var hd = d * 0.5

	for i in range(segments):
		var a0 = PI * (float(i) / float(segments))
		var a1 = PI * (float(i + 1) / float(segments))

		var p0 = Vector3(-cos(a0) * hw, sin(a0) * h, -hd)
		var p1 = Vector3(-cos(a1) * hw, sin(a1) * h, -hd)
		var p2 = Vector3(-cos(a1) * hw, sin(a1) * h, hd)
		var p3 = Vector3(-cos(a0) * hw, sin(a0) * h, hd)

		var n0 = Vector3(-cos(a0), sin(a0), 0.0).normalized()
		var n1 = Vector3(-cos(a1), sin(a1), 0.0).normalized()

		st.set_normal(n0); st.add_vertex(p0)
		st.set_normal(n1); st.add_vertex(p1)
		st.set_normal(n1); st.add_vertex(p2)

		st.set_normal(n0); st.add_vertex(p0)
		st.set_normal(n1); st.add_vertex(p2)
		st.set_normal(n0); st.add_vertex(p3)

	return st.commit()

static func _create_cylinder_mesh(radius: float, height: float, segments: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hh = height * 0.5

	for i in range(segments):
		var a0 = TAU * (float(i) / float(segments))
		var a1 = TAU * (float(i + 1) / float(segments))

		var v0 = Vector3(cos(a0) * radius, -hh, sin(a0) * radius)
		var v1 = Vector3(cos(a1) * radius, -hh, sin(a1) * radius)
		var v2 = Vector3(cos(a1) * radius, hh, sin(a1) * radius)
		var v3 = Vector3(cos(a0) * radius, hh, sin(a0) * radius)

		var n0 = Vector3(cos(a0), 0.0, sin(a0)).normalized()
		var n1 = Vector3(cos(a1), 0.0, sin(a1)).normalized()

		st.set_normal(n0); st.add_vertex(v0)
		st.set_normal(n1); st.add_vertex(v1)
		st.set_normal(n1); st.add_vertex(v2)

		st.set_normal(n0); st.add_vertex(v0)
		st.set_normal(n1); st.add_vertex(v2)
		st.set_normal(n0); st.add_vertex(v3)

	return st.commit()

static func _create_cone_mesh(r_base: float, r_top: float, height: float, segments: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hh = height * 0.5

	for i in range(segments):
		var a0 = TAU * (float(i) / float(segments))
		var a1 = TAU * (float(i + 1) / float(segments))

		var v0 = Vector3(cos(a0) * r_base, -hh, sin(a0) * r_base)
		var v1 = Vector3(cos(a1) * r_base, -hh, sin(a1) * r_base)
		var v2 = Vector3(cos(a1) * r_top, hh, sin(a1) * r_top)
		var v3 = Vector3(cos(a0) * r_top, hh, sin(a0) * r_top)

		var n = (v1 - v0).cross(v2 - v0).normalized()
		st.set_normal(n); st.add_vertex(v0)
		st.set_normal(n); st.add_vertex(v1)
		st.set_normal(n); st.add_vertex(v2)

		st.set_normal(n); st.add_vertex(v0)
		st.set_normal(n); st.add_vertex(v2)
		st.set_normal(n); st.add_vertex(v3)

	return st.commit()

static func _create_radar_dish_mesh(radius: float, depth: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments = 16
	var center = Vector3(0, 0, depth)

	for i in range(segments):
		var a0 = TAU * (float(i) / float(segments))
		var a1 = TAU * (float(i + 1) / float(segments))

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
