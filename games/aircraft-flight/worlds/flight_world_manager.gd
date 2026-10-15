class_name FlightWorldManager
extends Node3D

## FlightWorldManager: Master Procedural World Director & Atmosphere Engine.
## Coordinates 8 expansive flight environments ($8\text{km} \times 8\text{km}$ airspace),
## dynamic day/night atmospheric scattering, volumetric fog, and runway lighting.

const CityFlightWorldScript = preload("res://games/aircraft-flight/worlds/city_flight_world.gd")
const RunwayGen = preload("res://games/aircraft-flight/worlds/runway_generator.gd")

@export var current_world_id: String = "metropolitan_city"
@export var time_of_day: String = "sunset" # "noon", "sunset", "night", "overcast"

var active_world_root: Node3D
var sun_light: DirectionalLight3D
var world_environment: WorldEnvironment

const WORLD_BIOME_CATALOG: Dictionary = {
	"metropolitan_city": {
		"name": "Metropolitan Harbor City",
		"desc": "American skyscraper canyons, suspension bridges, maritime shipping port, and dual ILS runways.",
		"ambient_color": Color(0.12, 0.16, 0.22),
		"fog_color": Color(0.72, 0.78, 0.85),
		"fog_density": 0.00008,
		"sun_energy": 2.2,
		"sun_angle": Vector3(-25.0, -45.0, 0.0)
	},
	"alpine_mountains": {
		"name": "Alpine Mountain Peaks",
		"desc": "Snow-capped 3,000m summits, deep glacial valleys, crystal mountain lakes, and high-altitude plateau runway.",
		"ambient_color": Color(0.15, 0.20, 0.28),
		"fog_color": Color(0.85, 0.90, 0.98),
		"fog_density": 0.00006,
		"sun_energy": 2.6,
		"sun_angle": Vector3(-35.0, -60.0, 0.0)
	},
	"arctic_snow": {
		"name": "Arctic Fjord & Glacier",
		"desc": "Endless frozen ice sheets, polar research station, sub-zero blizzard visibility, and packed-snow runway.",
		"ambient_color": Color(0.18, 0.22, 0.30),
		"fog_color": Color(0.90, 0.94, 1.0),
		"fog_density": 0.00015,
		"sun_energy": 1.6,
		"sun_angle": Vector3(-15.0, -30.0, 0.0)
	},
	"tropical_beach": {
		"name": "Tropical Beach & Atolls",
		"desc": "Turquoise coral lagoons, white sand archipelagos, coastal resort towers, and palm-lined island strip.",
		"ambient_color": Color(0.10, 0.22, 0.30),
		"fog_color": Color(0.75, 0.88, 0.95),
		"fog_density": 0.00005,
		"sun_energy": 2.8,
		"sun_angle": Vector3(-55.0, -35.0, 0.0)
	},
	"desert_canyon": {
		"name": "Redrock Desert Canyons",
		"desc": "Towering sandstone mesas, serpentine river chasms, natural stone arches, and remote desert airfield.",
		"ambient_color": Color(0.25, 0.18, 0.14),
		"fog_color": Color(0.92, 0.75, 0.60),
		"fog_density": 0.00009,
		"sun_energy": 2.7,
		"sun_angle": Vector3(-30.0, -50.0, 0.0)
	},
	"volcanic_underworld": {
		"name": "Volcanic Calderas & Lava",
		"desc": "Active volcanic calderas, incandescent lava rivers, geothermal power stations, and thermal updraft pillars.",
		"ambient_color": Color(0.25, 0.10, 0.08),
		"fog_color": Color(0.55, 0.25, 0.15),
		"fog_density": 0.00018,
		"sun_energy": 1.4,
		"sun_angle": Vector3(-20.0, -80.0, 0.0)
	},
	"dense_forest": {
		"name": "Redwood Forest & Gorges",
		"desc": "Ancient thousand-year redwood forests, rushing river canyons, cascading waterfalls, and tree-top skimming corridors.",
		"ambient_color": Color(0.12, 0.22, 0.15),
		"fog_color": Color(0.68, 0.80, 0.72),
		"fog_density": 0.00010,
		"sun_energy": 2.3,
		"sun_angle": Vector3(-40.0, -45.0, 0.0)
	},
	"alien_planet": {
		"name": "Xenon Outpost & Rings",
		"desc": "Low-gravity alien planetscape with floating monolithic arches, crystalline spires, and luminescent atmospheric scattering.",
		"ambient_color": Color(0.18, 0.08, 0.28),
		"fog_color": Color(0.65, 0.35, 0.85),
		"fog_density": 0.00012,
		"sun_energy": 2.0,
		"sun_angle": Vector3(-45.0, -70.0, 0.0)
	}
}

func _ready() -> void:
	setup_lighting_and_atmosphere()
	load_world(current_world_id)

func setup_lighting_and_atmosphere() -> void:
	if not sun_light:
		sun_light = DirectionalLight3D.new()
		sun_light.name = "SunLight"
		sun_light.shadow_enabled = true
		sun_light.directional_shadow_max_distance = 1200.0
		sun_light.light_color = Color(1.0, 0.96, 0.90)
		sun_light.light_energy = 2.2
		sun_light.rotation_degrees = Vector3(-35.0, -45.0, 0.0)
		add_child(sun_light)

	if not world_environment:
		world_environment = WorldEnvironment.new()
		world_environment.name = "WorldEnv"
		var env = Environment.new()
		var sky = Sky.new()
		var sky_mat = ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.20, 0.44, 0.82)
		sky_mat.sky_horizon_color = Color(0.65, 0.76, 0.88)
		sky_mat.ground_bottom_color = Color(0.12, 0.15, 0.18)
		sky_mat.ground_horizon_color = Color(0.55, 0.65, 0.74)
		sky_mat.sun_angle_max = 30.0
		sky_mat.sun_curve = 0.15
		sky.sky_material = sky_mat

		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_color = Color(0.40, 0.45, 0.52)
		env.ambient_light_sky_contribution = 0.75
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		env.fog_light_color = Color(0.72, 0.80, 0.90)
		env.fog_density = 0.00005
		world_environment.environment = env
		add_child(world_environment)

func load_world(world_id: String) -> void:
	current_world_id = world_id
	if is_instance_valid(active_world_root):
		active_world_root.queue_free()

	active_world_root = Node3D.new()
	active_world_root.name = "ActiveWorld_" + world_id
	add_child(active_world_root)

	var biome_data = WORLD_BIOME_CATALOG.get(world_id, WORLD_BIOME_CATALOG["metropolitan_city"])
	_apply_atmosphere(biome_data)

	match world_id:
		"metropolitan_city":
			var city_world = CityFlightWorldScript.new()
			active_world_root.add_child(city_world)
		"alpine_mountains":
			_build_mountain_biome()
		"arctic_snow":
			_build_arctic_biome()
		"tropical_beach":
			_build_tropical_biome()
		"desert_canyon":
			_build_desert_biome()
		"volcanic_underworld":
			_build_volcanic_biome()
		"dense_forest":
			_build_forest_biome()
		"alien_planet":
			_build_alien_biome()
		_:
			var default_city = CityFlightWorldScript.new()
			active_world_root.add_child(default_city)

func _apply_atmosphere(biome: Dictionary) -> void:
	if sun_light:
		sun_light.light_energy = biome.get("sun_energy", 2.2)
		var angle = biome.get("sun_angle", Vector3(-35.0, -45.0, 0.0))
		sun_light.rotation_degrees = angle

	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.ambient_light_color = biome.get("ambient_color", Color(0.35, 0.40, 0.48))
		env.fog_light_color = biome.get("fog_color", Color(0.75, 0.82, 0.90))
		env.fog_density = biome.get("fog_density", 0.00008)

func _build_mountain_biome() -> void:
	# Paved Alpine Runway ($2,200\text{m}$)
	var rwy = RunwayGen.build_runway(2200.0, 50.0, "18M")
	rwy.position = Vector3(0.0, 450.0, 0.0) # Elevated mountain plateau
	active_world_root.add_child(rwy)

	var mat_snow = StandardMaterial3D.new()
	mat_snow.albedo_color = Color(0.92, 0.95, 0.98) # Alpine glacial snow
	mat_snow.roughness = 0.85

	var mat_rock = StandardMaterial3D.new()
	mat_rock.albedo_color = Color(0.32, 0.30, 0.28) # Granite cliff
	mat_rock.roughness = 0.90

	# Ground plateau plane
	_create_terrain_plane(Vector3(12000.0, 10.0, 12000.0), Vector3(0.0, 445.0, 0.0), mat_rock)

	# Mountain Peaks (Pyramidal / Conical peaks rising to 2,800m)
	for p in range(16):
		var p_angle = p * (PI * 2.0 / 16.0)
		var p_dist = 1800.0 + (p % 4) * 600.0
		var px = cos(p_angle) * p_dist
		var pz = sin(p_angle) * p_dist
		var p_height = 1400.0 + (p * 73 % 900)

		var peak = _create_peak(px, pz, p_height, 650.0, mat_snow)
		active_world_root.add_child(peak)

func _build_arctic_biome() -> void:
	var rwy = RunwayGen.build_runway(2400.0, 60.0, "36A")
	rwy.position = Vector3(0.0, 2.0, 0.0)
	active_world_root.add_child(rwy)

	var mat_ice = StandardMaterial3D.new()
	mat_ice.albedo_color = Color(0.85, 0.92, 0.98)
	mat_ice.roughness = 0.20
	mat_ice.metallic = 0.35

	_create_terrain_plane(Vector3(12000.0, 4.0, 12000.0), Vector3(0.0, 0.0, 0.0), mat_ice)

	# Polar Iceberg & Glacier Monoliths
	for i in range(14):
		var ix = -3000.0 + i * 450.0
		var iz = -2500.0 + (i * 37 % 5000)
		var iceberg = _create_colliding_box(Vector3(250.0, 180.0, 250.0), Vector3(ix, 90.0, iz), mat_ice)
		active_world_root.add_child(iceberg)

func _build_tropical_biome() -> void:
	var rwy = RunwayGen.build_runway(1800.0, 45.0, "12T")
	rwy.position = Vector3(0.0, 3.0, 0.0)
	active_world_root.add_child(rwy)

	var mat_sand = StandardMaterial3D.new()
	mat_sand.albedo_color = Color(0.92, 0.88, 0.72) # Coral sand
	var mat_water = StandardMaterial3D.new()
	mat_water.albedo_color = Color(0.05, 0.45, 0.55, 0.9) # Turquoise tropical ocean
	mat_water.roughness = 0.05
	mat_water.metallic = 0.85

	_create_terrain_plane(Vector3(12000.0, 1.0, 12000.0), Vector3(0.0, 0.0, 0.0), mat_water)

	# Tropical Atoll Islands
	for a in range(8):
		var ax = -2500.0 + (a * 550.0)
		var az = -2000.0 + ((a * 29) % 4000)
		var island = _create_colliding_box(Vector3(800.0, 15.0, 800.0), Vector3(ax, 7.5, az), mat_sand)
		active_world_root.add_child(island)

func _build_desert_biome() -> void:
	var rwy = RunwayGen.build_runway(2000.0, 50.0, "24D")
	rwy.position = Vector3(0.0, 5.0, 0.0)
	active_world_root.add_child(rwy)

	var mat_redrock = StandardMaterial3D.new()
	mat_redrock.albedo_color = Color(0.72, 0.35, 0.18) # Red sandstone mesa
	mat_redrock.roughness = 0.92

	_create_terrain_plane(Vector3(12000.0, 2.0, 12000.0), Vector3(0.0, 0.0, 0.0), mat_redrock)

	# Towering Canyon Mesas and Flight Arches
	for c in range(12):
		var cx = -2800.0 + c * 480.0
		var cz = -2200.0 + ((c * 43) % 4400)
		var mesa = _create_colliding_box(Vector3(350.0, 420.0, 450.0), Vector3(cx, 210.0, cz), mat_redrock)
		active_world_root.add_child(mesa)

func _build_volcanic_biome() -> void:
	var rwy = RunwayGen.build_runway(2000.0, 50.0, "06V")
	rwy.position = Vector3(0.0, 8.0, 0.0)
	active_world_root.add_child(rwy)

	var mat_basalt = StandardMaterial3D.new()
	mat_basalt.albedo_color = Color(0.12, 0.11, 0.12) # Black volcanic basalt
	var mat_lava = StandardMaterial3D.new()
	mat_lava.albedo_color = Color(1.0, 0.25, 0.05)
	mat_lava.emission_enabled = true
	mat_lava.emission = Color(1.0, 0.25, 0.05)
	mat_lava.emission_energy_multiplier = 5.0

	_create_terrain_plane(Vector3(12000.0, 2.0, 12000.0), Vector3(0.0, 0.0, 0.0), mat_basalt)

	# Volcanic Calderas & Lava Fissures
	for v in range(10):
		var vx = -2600.0 + v * 520.0
		var vz = -2400.0 + ((v * 37) % 4800)
		var caldera = _create_peak(vx, vz, 650.0, 480.0, mat_basalt)
		active_world_root.add_child(caldera)
		var lava_strip = _create_colliding_box(Vector3(45.0, 1.0, 600.0), Vector3(vx, 2.0, vz), mat_lava)
		active_world_root.add_child(lava_strip)

func _build_forest_biome() -> void:
	var rwy = RunwayGen.build_runway(1800.0, 45.0, "15F")
	rwy.position = Vector3(0.0, 4.0, 0.0)
	active_world_root.add_child(rwy)

	var mat_forest = StandardMaterial3D.new()
	mat_forest.albedo_color = Color(0.12, 0.32, 0.15) # Deep forest floor
	_create_terrain_plane(Vector3(12000.0, 2.0, 12000.0), Vector3(0.0, 0.0, 0.0), mat_forest)

	# Mountain ridges and forest canopy pillars
	for f in range(12):
		var fx = -2800.0 + f * 480.0
		var fz = -2000.0 + ((f * 51) % 4000)
		var ridge = _create_colliding_box(Vector3(500.0, 220.0, 250.0), Vector3(fx, 110.0, fz), mat_forest)
		active_world_root.add_child(ridge)

func _build_alien_biome() -> void:
	var rwy = RunwayGen.build_runway(2200.0, 50.0, "99X")
	rwy.position = Vector3(0.0, 6.0, 0.0)
	active_world_root.add_child(rwy)

	var mat_alien_rock = StandardMaterial3D.new()
	mat_alien_rock.albedo_color = Color(0.22, 0.12, 0.32) # Exotic violet regolith
	var mat_neon_ring = StandardMaterial3D.new()
	mat_neon_ring.albedo_color = Color(0.2, 0.9, 1.0)
	mat_neon_ring.emission_enabled = true
	mat_neon_ring.emission = Color(0.2, 0.9, 1.0)
	mat_neon_ring.emission_energy_multiplier = 6.0

	_create_terrain_plane(Vector3(12000.0, 2.0, 12000.0), Vector3(0.0, 0.0, 0.0), mat_alien_rock)

	# Floating Monoliths & Giant Energy Rings
	for a in range(8):
		var ax = -2500.0 + a * 620.0
		var az = -2200.0 + ((a * 47) % 4400)
		var monolith = _create_colliding_box(Vector3(120.0, 550.0, 120.0), Vector3(ax, 275.0, az), mat_alien_rock)
		active_world_root.add_child(monolith)
		var ring = _create_colliding_box(Vector3(160.0, 10.0, 160.0), Vector3(ax, 380.0, az), mat_neon_ring)
		active_world_root.add_child(ring)

# Helper Primitive Builders
func _create_terrain_plane(size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	return _create_colliding_box(size, pos, mat)

func _create_colliding_box(size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var sb = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	col.shape = box
	sb.add_child(col)

	var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	if mat:
		mi.material_override = mat
	sb.add_child(mi)
	sb.position = pos
	active_world_root.add_child(sb)
	return sb

func _create_peak(px: float, pz: float, height: float, base_radius: float, mat: Material) -> StaticBody3D:
	var sb = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.height = height
	cyl_shape.radius = base_radius * 0.5
	col.shape = cyl_shape
	sb.add_child(col)

	var mi = MeshInstance3D.new()
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.top_radius = 5.0
	cyl_mesh.bottom_radius = base_radius
	cyl_mesh.height = height
	mi.mesh = cyl_mesh
	if mat:
		mi.material_override = mat
	sb.add_child(mi)
	sb.position = Vector3(px, height * 0.5, pz)
	return sb

func get_spawn_point(spawn_type: String) -> Dictionary:
	if is_instance_valid(active_world_root):
		var child = active_world_root.get_child(0)
		if child and child.has_method("get_spawn_point"):
			return child.get_spawn_point(spawn_type)

	# Default Runway 09L Threshold
	return {
		"position": Vector3(0.0, 2.5, 950.0),
		"heading_deg": 0.0,
		"airspeed_kmh": 0.0 if spawn_type == "runway_takeoff" else 350.0,
		"airborne": spawn_type != "runway_takeoff"
	}
