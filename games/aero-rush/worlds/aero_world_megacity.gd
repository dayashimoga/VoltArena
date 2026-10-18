class_name AeroWorldMegacity
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Neo-Cascade Metropolis: Authoritative Stunt-Racing Megacity Environment.
## Replaces prototype geometry with high-speed arcade racing spectacle:
## - Radiant golden-hour / cyberpunk dusk sky and warm directional sunlight
## - Volumetric fog with atmospheric haze scattering between downtown towers
## - Reflective PBR glass skyscrapers with aluminum mullions and illuminated interior night maps
## - Animated metropolitan blimp and city patrol drones in the airspace
## - Elevated stunt highway suspended above an illuminated urban basin
## - Covered racing grandstands with animated crowd camera flashes, floodlights, and billboards
## - Overhead transit sky-bridges spanning above the circuit
## - 360-degree layered perimeter skyline guaranteeing depth and scale cues from every angle.

const URBAN_GROUND_SHADER = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert;

void fragment() {
	vec2 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec2 grid80 = fract(world_pos / 80.0);
	vec2 grid20 = fract(world_pos / 20.0);

	bool is_arterial = (grid80.x < 0.12 || grid80.y < 0.12);
	bool is_street = (grid20.x < 0.14 || grid20.y < 0.14);
	bool is_centerline = (abs(grid80.x - 0.06) < 0.008 || abs(grid80.y - 0.06) < 0.008);

	if (is_centerline && is_arterial) {
		ALBEDO = vec3(1.0, 0.85, 0.2);
		EMISSION = vec3(1.0, 0.85, 0.2) * 1.5;
		ROUGHNESS = 0.3;
		METALLIC = 0.2;
	} else if (is_arterial) {
		ALBEDO = vec3(0.08, 0.09, 0.11);
		ROUGHNESS = 0.55;
		METALLIC = 0.15;
	} else if (is_street) {
		ALBEDO = vec3(0.12, 0.13, 0.15);
		ROUGHNESS = 0.65;
		METALLIC = 0.1;
	} else {
		vec2 block_uv = floor(world_pos / 20.0);
		float block_hash = fract(sin(dot(block_uv, vec2(12.9898, 78.233))) * 43758.5453);
		vec3 block_tone = mix(vec3(0.16, 0.18, 0.21), vec3(0.20, 0.22, 0.26), block_hash);
		vec2 micro_uv = fract(world_pos / 2.5);
		bool is_light_node = (block_hash > 0.65 && micro_uv.x < 0.12 && micro_uv.y < 0.12);

		if (is_light_node) {
			ALBEDO = vec3(0.1, 0.7, 1.0);
			EMISSION = vec3(0.1, 0.7, 1.0) * 1.2;
		} else {
			ALBEDO = block_tone;
		}
		ROUGHNESS = 0.75;
		METALLIC = 0.25;
	}
}
"""

const SKYSCRAPER_PBR_SHADER = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 glass_color : source_color = vec4(0.06, 0.09, 0.14, 1.0);
uniform vec4 mullion_color : source_color = vec4(0.68, 0.72, 0.78, 1.0);
uniform vec4 slab_color : source_color = vec4(0.18, 0.20, 0.24, 1.0);
uniform vec4 window_lit_cyan : source_color = vec4(0.20, 0.85, 1.0, 1.0);
uniform vec4 window_lit_amber : source_color = vec4(1.0, 0.78, 0.40, 1.0);

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_world_normal);
	bool is_roof = (n.y > 0.65);

	if (is_roof) {
		// Rooftop mechanical terrace & maintenance gravel
		vec2 roof_uv = fract(v_world_pos.xz / 6.0);
		bool is_border = (roof_uv.x < 0.08 || roof_uv.y < 0.08);
		ALBEDO = is_border ? vec3(0.25, 0.28, 0.32) : vec3(0.14, 0.15, 0.18);
		METALLIC = 0.70;
		ROUGHNESS = 0.55;
		SPECULAR = 0.40;
	} else {
		// Facade-aligned architectural coordinate projection (no diagonal distortion)
		vec2 facade_uv;
		if (abs(n.x) > abs(n.z)) {
			facade_uv = vec2(v_world_pos.z, v_world_pos.y);
		} else {
			facade_uv = vec2(v_world_pos.x, v_world_pos.y);
		}

		// Modules: 3.2m width per window pane, 3.8m height per story
		vec2 win_uv = fract(facade_uv / vec2(3.2, 3.8));
		vec2 win_id = floor(facade_uv / vec2(3.2, 3.8));

		bool is_floor_slab = (win_uv.y < 0.12);
		bool is_vert_mullion = (win_uv.x < 0.10);

		float h = fract(sin(dot(win_id, vec2(12.9898, 78.233))) * 43758.5453);

		if (is_floor_slab) {
			// Reinforced concrete/aluminum horizontal spandrel slab
			ALBEDO = slab_color.rgb;
			METALLIC = 0.60;
			ROUGHNESS = 0.45;
			SPECULAR = 0.50;
		} else if (is_vert_mullion) {
			// Extruded aluminum vertical mullion
			ALBEDO = mullion_color.rgb;
			METALLIC = 0.92;
			ROUGHNESS = 0.18;
			SPECULAR = 0.75;
		} else {
			// Deep reflective architectural curtain-wall glass
			ALBEDO = glass_color.rgb;
			METALLIC = 0.85;
			ROUGHNESS = 0.08;
			SPECULAR = 0.92;

			// Subtle, crisp interior window lighting
			if (h > 0.64) {
				vec3 lit_col = (h > 0.86) ? window_lit_amber.rgb : window_lit_cyan.rgb;
				float pulse = 0.92 + 0.08 * sin(TIME * 1.2 + h * 30.0);
				EMISSION = lit_col * (1.8 * pulse);
			}
		}
	}
}
"""

var skyscraper_pbr_material: ShaderMaterial = null
var blimp_node: Node3D = null
var blimp_angle: float = 0.0
var drone_nodes: Array[Node3D] = []
var crowd_lights: Array[MeshInstance3D] = []
var crowd_timer: float = 0.0

func _get_skyscraper_material() -> ShaderMaterial:
	if not skyscraper_pbr_material:
		skyscraper_pbr_material = ShaderMaterial.new()
		var s = Shader.new()
		s.code = SKYSCRAPER_PBR_SHADER
		skyscraper_pbr_material.shader = s
	return skyscraper_pbr_material

func _process(delta: float) -> void:
	# 1. Metropolitan Blimp Flight Trajectory
	if blimp_node and is_instance_valid(blimp_node):
		blimp_angle += 0.04 * delta
		var radius = 240.0
		blimp_node.position.x = cos(blimp_angle) * radius
		blimp_node.position.z = -180.0 + sin(blimp_angle) * radius
		blimp_node.rotation.y = -blimp_angle + PI * 0.5

	# 2. Hovering Airspace Drones
	for i in range(drone_nodes.size()):
		var d = drone_nodes[i]
		if is_instance_valid(d):
			d.position.y += sin(Time.get_ticks_msec() * 0.002 + i) * 0.02
			d.rotate_y(0.2 * delta)

	# 3. Crowd Flashlights & Camera Flashes
	crowd_timer += delta
	if crowd_timer > 0.08:
		crowd_timer = 0.0
		for cl in crowd_lights:
			if is_instance_valid(cl) and cl.material_override:
				var cm = cl.material_override as StandardMaterial3D
				if cm:
					cm.emission_energy_multiplier = 4.5 if randf() < 0.18 else 0.0

func build_environment() -> void:
	# 1. Atmospheric Golden Dusk / Cyberpunk Twilight Lighting
	setup_lighting(
		Color(1.0, 0.88, 0.74),                  # Warm Golden Sun Key Light
		2.4,                                     # Sunlight Energy
		Vector3(-28.0, 48.0, 0.0),               # Cinematic 3D Shadow Cast Angle
		Color(0.06, 0.12, 0.32),                 # Sky Top (Sapphire Twilight)
		Color(0.96, 0.54, 0.28),                 # Sky Horizon (Radiant Amber Sunset)
		Color(0.85, 0.70, 0.65),                 # Volumetric Atmospheric Haze
		0.0018                                   # Fog Density
	)

	# Enhanced Volumetric Fog between downtown skyscraper canyons
	if world_env and world_env.environment:
		var env = world_env.environment
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0022
		env.volumetric_fog_albedo = Color(0.92, 0.74, 0.65)
		env.volumetric_fog_emission = Color(0.18, 0.12, 0.25)
		env.volumetric_fog_emission_energy = 0.5
		env.volumetric_fog_anisotropy = 0.45
		env.volumetric_fog_gi_inject = 1.0

	# 2. Elevated Urban Basin Ground Bed with Multi-Tier Street Grid Shader
	var ground_mat = ShaderMaterial.new()
	var g_shader = Shader.new()
	g_shader.code = URBAN_GROUND_SHADER
	ground_mat.shader = g_shader
	create_ground_bed(1800.0, ground_mat, -6.5)

	# 3. Urban Canal / Reflecting River Basin
	_build_urban_waterway()

	# 4. Racing Stadium Sector (Near Ground: Grandstands & Floodlights along Main Straight)
	_build_stadium_starting_sector()

	# 5. Authored Skyscraper City Blocks (Mid Ground: Proportional 50m - 140m towers)
	_build_flanking_skyscrapers()

	# 6. Overhead Transit Sky-Bridges Spanning the Circuit
	_build_overhead_skybridges()

	# 7. Street Infrastructure and Foliage in Plazas
	_build_street_amenities()

	# 8. 360-Degree Continuous Layered Perimeter Skyline
	_build_perimeter_skyline()

	# 9. Dynamic Airspace: Metropolitan Blimp and City Patrol Drones
	_build_airspace_crafts()

	# 10. Multi-Tier Highway Overpasses with Flowing Neon Traffic Trails
	_build_highway_overpasses()

func spawn_building(model_path: String, pos: Vector3, rot_y: float = 0.0, scale_mult: Vector3 = Vector3.ONE) -> Node3D:
	var bld = super.spawn_building(model_path, pos, rot_y, scale_mult)
	if not bld:
		bld = Node3D.new()
		bld.name = "BuildingProcedural"
		bld.position = pos
		bld.rotation_degrees.y = rot_y
		bld.scale = scale_mult
		add_child(bld)
	if bld:
		# Replace flat-colored box surfaces with reflective PBR glass & illuminated night map shader
		if model_path.contains("building") or model_path.contains("skyscraper"):
			_apply_pbr_materials_recursive(bld, _get_skyscraper_material())
			_add_skyscraper_rooftop_details(bld, scale_mult.y)
	return bld

func _add_skyscraper_rooftop_details(bld: Node3D, height_scale: float) -> void:
	# Rooftop communication antenna with pulsing red aviation beacon
	var antenna = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.25
	cyl.height = 12.0
	antenna.mesh = cyl
	var a_mat = StandardMaterial3D.new()
	a_mat.albedo_color = Color(0.70, 0.72, 0.75)
	a_mat.metallic = 0.95
	a_mat.roughness = 0.20
	antenna.material_override = a_mat
	antenna.name = "AntennaSpire"
	antenna.position = Vector3(0.0, height_scale * 3.5 + 6.0, 0.0)
	bld.add_child(antenna)

	var beacon = MeshInstance3D.new()
	beacon.name = "AviationBeacon"
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	beacon.mesh = sphere
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(1.0, 0.08, 0.08)
	b_mat.emission_enabled = true
	b_mat.emission = Color(1.0, 0.08, 0.08)
	b_mat.emission_energy_multiplier = 4.5
	beacon.material_override = b_mat
	beacon.position = Vector3(0.0, height_scale * 3.5 + 12.0, 0.0)
	bld.add_child(beacon)

	# Holographic race sign on facade
	if randf() < 0.45:
		var sign_mesh = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(16.0, 5.0, 0.5)
		sign_mesh.mesh = s_box
		var s_mat = StandardMaterial3D.new()
		var sign_colors = [Color(0.05, 0.85, 1.0), Color(1.0, 0.22, 0.70), Color(1.0, 0.85, 0.1)]
		var chosen_sign_col = sign_colors[randi() % sign_colors.size()]
		s_mat.albedo_color = chosen_sign_col
		s_mat.emission_enabled = true
		s_mat.emission = chosen_sign_col
		s_mat.emission_energy_multiplier = 3.2
		sign_mesh.material_override = s_mat
		sign_mesh.position = Vector3(0.0, height_scale * 2.0, 4.0)
		bld.add_child(sign_mesh)

func _build_highway_overpasses() -> void:
	var highway_root = Node3D.new()
	highway_root.name = "UrbanBasinHighways"
	add_child(highway_root)

	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.12, 0.13, 0.16)
	h_mat.metallic = 0.3
	h_mat.roughness = 0.7

	var trail_mat_white = StandardMaterial3D.new()
	trail_mat_white.albedo_color = Color(0.95, 0.98, 1.0)
	trail_mat_white.emission_enabled = true
	trail_mat_white.emission = Color(0.95, 0.98, 1.0)
	trail_mat_white.emission_energy_multiplier = 3.0

	var trail_mat_red = StandardMaterial3D.new()
	trail_mat_red.albedo_color = Color(1.0, 0.05, 0.05)
	trail_mat_red.emission_enabled = true
	trail_mat_red.emission = Color(1.0, 0.05, 0.05)
	trail_mat_red.emission_energy_multiplier = 3.0

	var overpass_x_lanes = [-180.0, 320.0]
	for hx in overpass_x_lanes:
		var road = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(22.0, 2.0, 1600.0)
		road.mesh = r_box
		road.material_override = h_mat
		road.position = Vector3(hx, -2.5, -200.0)
		highway_root.add_child(road)

		# Traffic light flow streaks
		var headlight_streak = MeshInstance3D.new()
		var h_streak_box = BoxMesh.new()
		h_streak_box.size = Vector3(1.2, 0.2, 1600.0)
		headlight_streak.mesh = h_streak_box
		headlight_streak.material_override = trail_mat_white
		headlight_streak.position = Vector3(hx - 5.0, -1.4, -200.0)
		highway_root.add_child(headlight_streak)

		var taillight_streak = MeshInstance3D.new()
		var t_streak_box = BoxMesh.new()
		t_streak_box.size = Vector3(1.2, 0.2, 1600.0)
		taillight_streak.mesh = t_streak_box
		taillight_streak.material_override = trail_mat_red
		taillight_streak.position = Vector3(hx + 5.0, -1.4, -200.0)
		highway_root.add_child(taillight_streak)

func _apply_pbr_materials_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi = node as MeshInstance3D
		mi.material_override = mat
	for child in node.get_children():
		_apply_pbr_materials_recursive(child, mat)

func _build_urban_waterway() -> void:
	var water_mesh = MeshInstance3D.new()
	water_mesh.name = "UrbanCanalReflectingWater"
	var plane = PlaneMesh.new()
	plane.size = Vector2(160.0, 1400.0)
	water_mesh.mesh = plane

	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.05, 0.14, 0.24)
	water_mat.roughness = 0.08
	water_mat.metallic = 0.85
	water_mesh.material_override = water_mat
	water_mesh.position = Vector3(160.0, -6.35, 0.0)
	add_child(water_mesh)

func _build_stadium_starting_sector() -> void:
	var grandstand_path = "res://assets/models/environment/stadium/grandstand_covered.glb"
	var floodlight_path = "res://assets/models/environment/stadium/floodlight_tower.glb"
	var billboard_path = "res://assets/models/environment/stadium/billboard.glb"
	var barrier_red = "res://assets/models/environment/racing/barrier_red.glb"
	var barrier_white = "res://assets/models/environment/racing/barrier_white.glb"

	# Covered Grandstands flanking the starting boulevard
	var gs_positions = [
		{"pos": Vector3(-24.0, 0.0, -35.0), "rot": 90.0},
		{"pos": Vector3(-24.0, 0.0, 15.0), "rot": 90.0},
		{"pos": Vector3(-24.0, 0.0, 65.0), "rot": 90.0},
		{"pos": Vector3(24.0, 0.0, -35.0), "rot": -90.0},
		{"pos": Vector3(24.0, 0.0, 15.0), "rot": -90.0},
		{"pos": Vector3(24.0, 0.0, 65.0), "rot": -90.0}
	]
	for g in gs_positions:
		spawn_building(grandstand_path, g["pos"], g["rot"], Vector3(2.2, 2.2, 2.2))
		# Animated crowd camera flashes
		for f in range(6):
			var flash = MeshInstance3D.new()
			var fm = SphereMesh.new()
			fm.radius = 0.20
			fm.height = 0.40
			flash.mesh = fm
			var f_mat = StandardMaterial3D.new()
			f_mat.albedo_color = Color(1.0, 1.0, 1.0)
			f_mat.emission_enabled = true
			f_mat.emission = Color(1.0, 1.0, 1.0)
			f_mat.emission_energy_multiplier = 0.0
			flash.material_override = f_mat
			var f_offset = Vector3(randf_range(-5.0, 5.0), randf_range(2.0, 5.5), randf_range(-3.5, 3.5))
			flash.position = g["pos"] + f_offset
			add_child(flash)
			crowd_lights.append(flash)

	# High Stadium Floodlight Towers
	var fl_positions = [
		Vector3(-32.0, 0.0, -50.0),
		Vector3(-32.0, 0.0, 90.0),
		Vector3(32.0, 0.0, -50.0),
		Vector3(32.0, 0.0, 90.0),
		Vector3(-55.0, 0.0, -170.0),
		Vector3(55.0, 0.0, -170.0)
	]
	for fl_pos in fl_positions:
		spawn_building(floodlight_path, fl_pos, 0.0, Vector3(2.4, 2.4, 2.4))

	# High-Speed Racing Billboards on the start and approach corners
	var bb_positions = [
		{"pos": Vector3(-26.0, 3.5, 110.0), "rot": 35.0},
		{"pos": Vector3(26.0, 3.5, 110.0), "rot": -35.0},
		{"pos": Vector3(26.0, 8.5, -95.0), "rot": -25.0}
	]
	for b in bb_positions:
		spawn_building(billboard_path, b["pos"], b["rot"], Vector3(2.0, 2.0, 2.0))

	# Safety Racing Barriers along ground boulevard shoulders
	for z_pos in range(-60, 80, 10):
		var b_path = barrier_red if ((z_pos / 10) % 2 == 0) else barrier_white
		spawn_building(b_path, Vector3(-16.5, 0.0, float(z_pos)), 0.0, Vector3(1.8, 1.8, 1.8))
		spawn_building(b_path, Vector3(16.5, 0.0, float(z_pos)), 180.0, Vector3(1.8, 1.8, 1.8))

func _build_flanking_skyscrapers() -> void:
	var skyscraper_models = [
		"res://assets/models/environment/building_skyscraper_a.glb",
		"res://assets/models/environment/building_skyscraper_b.glb",
		"res://assets/models/environment/building_skyscraper_c.glb",
		"res://assets/models/environment/building_skyscraper_d.glb",
		"res://assets/models/environment/building_skyscraper_e.glb"
	]
	var comm_models = [
		"res://assets/models/environment/building_comm_a.glb",
		"res://assets/models/environment/building_comm_b.glb",
		"res://assets/models/environment/building_comm_c.glb",
		"res://assets/models/environment/building_comm_d.glb",
		"res://assets/models/environment/building_comm_e.glb",
		"res://assets/models/environment/building_comm_f.glb"
	]

	# Realistic boulevard towers flanking track (proportional scale: 8.0x to 12.0x uniform scale)
	var tower_coords = [
		# West side city blocks
		Vector3(-68.0, -6.5, -70.0), Vector3(-78.0, -6.5, -15.0),
		Vector3(-68.0, -6.5, 45.0), Vector3(-85.0, -6.5, 110.0),
		Vector3(-95.0, -6.5, -150.0), Vector3(-110.0, -6.5, -230.0),
		Vector3(-75.0, -6.5, -310.0), Vector3(-120.0, -6.5, 30.0),
		Vector3(-68.0, -6.5, -190.0), Vector3(-85.0, -6.5, -270.0),
		Vector3(-105.0, -6.5, -360.0), Vector3(-75.0, -6.5, -410.0),
		Vector3(-135.0, -6.5, -90.0), Vector3(-140.0, -6.5, -200.0),
		# East side city blocks
		Vector3(245.0, -6.5, -70.0), Vector3(115.0, -6.5, -15.0),
		Vector3(95.0, -6.5, 45.0), Vector3(115.0, -6.5, 110.0),
		Vector3(255.0, -6.5, -150.0), Vector3(265.0, -6.5, -230.0),
		Vector3(245.0, -6.5, -310.0), Vector3(135.0, -6.5, 30.0),
		Vector3(250.0, -6.5, -190.0), Vector3(260.0, -6.5, -270.0),
		Vector3(255.0, -6.5, -360.0), Vector3(240.0, -6.5, -430.0),
		Vector3(265.0, -6.5, -90.0), Vector3(275.0, -6.5, -200.0)
	]

	for i in range(tower_coords.size()):
		var pos = tower_coords[i]
		var model = skyscraper_models[i % skyscraper_models.size()]
		var uniform_scale = randf_range(8.0, 12.0)
		spawn_building(model, pos, float((i * 90) % 360), Vector3(uniform_scale, uniform_scale, uniform_scale))

	# Secondary Commercial Plazas and Mid-Tier Complexes
	var comm_coords = [
		Vector3(-90.0, -6.5, -60.0), Vector3(230.0, -6.5, -60.0),
		Vector3(-105.0, -6.5, 80.0), Vector3(105.0, -6.5, 80.0),
		Vector3(-60.0, -6.5, -220.0), Vector3(240.0, -6.5, -220.0),
		Vector3(-80.0, -6.5, -280.0), Vector3(235.0, -6.5, -280.0),
		Vector3(-62.0, -6.5, -350.0), Vector3(245.0, -6.5, -350.0),
		Vector3(-58.0, -6.5, -120.0), Vector3(230.0, -6.5, -120.0),
		Vector3(-115.0, -6.5, -20.0), Vector3(115.0, -6.5, -20.0)
	]
	for j in range(comm_coords.size()):
		var c_pos = comm_coords[j]
		var c_model = comm_models[j % comm_models.size()]
		var c_scale = randf_range(3.2, 4.8)
		spawn_building(c_model, c_pos, float((j * 90) % 360), Vector3(c_scale, c_scale, c_scale))

func _build_overhead_skybridges() -> void:
	var bridge_z_coords = [-10.0, 110.0, -500.0]
	for z in bridge_z_coords:
		var bridge = MeshInstance3D.new()
		bridge.name = "TransMetropolitanSkybridge_Z%d" % int(z)
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(240.0, 5.0, 8.0)
		bridge.mesh = b_mesh

		var b_mat = StandardMaterial3D.new()
		b_mat.albedo_color = Color(0.14, 0.16, 0.20)
		b_mat.metallic = 0.85
		b_mat.roughness = 0.30
		bridge.material_override = b_mat
		bridge.position = Vector3(0.0, 72.0, z)
		add_child(bridge)

		var win = MeshInstance3D.new()
		var w_mesh = BoxMesh.new()
		w_mesh.size = Vector3(240.0, 1.4, 8.2)
		win.mesh = w_mesh
		var win_mat = StandardMaterial3D.new()
		win_mat.albedo_color = Color(0.08, 0.90, 1.0)
		win_mat.emission_enabled = true
		win_mat.emission = Color(0.08, 0.90, 1.0) * 1.8
		win.material_override = win_mat
		win.position = Vector3(0.0, 72.0, z)
		add_child(win)

func _build_street_amenities() -> void:
	var lightpost_path = "res://assets/models/environment/road_lightposts.glb"
	var palm_path = "res://assets/models/environment/tree_palm.glb"
	var oak_path = "res://assets/models/environment/tree_oak.glb"

	for z_coord in range(-120, 140, 35):
		for x_side in [-38.0, 38.0]:
			spawn_building(lightpost_path, Vector3(x_side, -6.5, float(z_coord)), 90.0 if x_side < 0 else -90.0, Vector3(2.0, 2.0, 2.0))

	var tree_plazas = [
		Vector3(-42.0, -6.5, -45.0), Vector3(42.0, -6.5, -45.0),
		Vector3(-42.0, -6.5, 30.0), Vector3(42.0, -6.5, 30.0),
		Vector3(-70.0, -6.5, 95.0), Vector3(70.0, -6.5, 95.0)
	]
	for t_pos in tree_plazas:
		spawn_tree(palm_path, t_pos, Vector2(1.2, 1.6))
		spawn_tree(oak_path, t_pos + Vector3(6.0, 0, 6.0), Vector2(1.0, 1.4))

func _build_perimeter_skyline() -> void:
	var skyscraper_models = [
		"res://assets/models/environment/building_skyscraper_a.glb",
		"res://assets/models/environment/building_skyscraper_b.glb",
		"res://assets/models/environment/building_skyscraper_c.glb",
		"res://assets/models/environment/building_skyscraper_d.glb",
		"res://assets/models/environment/building_skyscraper_e.glb"
	]
	var tower_count = 24
	var radius = 520.0
	var center_z = -200.0

	for i in range(tower_count):
		var angle = (float(i) / float(tower_count)) * TAU
		var x = cos(angle) * (radius + randf_range(-25.0, 40.0))
		var z = center_z + sin(angle) * (radius + randf_range(-25.0, 40.0))
		var model = skyscraper_models[i % skyscraper_models.size()]
		var scale_val = randf_range(35.0, 58.0)

		spawn_building(model, Vector3(x, -6.5, z), float((i * 47) % 360), Vector3(scale_val, scale_val, scale_val))

func _build_airspace_crafts() -> void:
	var airspace_node = Node3D.new()
	airspace_node.name = "AirspaceCrafts"

	# 1. Metropolitan Advertising Blimp
	blimp_node = Node3D.new()
	blimp_node.name = "MetroDirigible"
	blimp_node.position = Vector3(120.0, 85.0, -180.0)

	var hull_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 8.0
	sphere.height = 36.0
	hull_mesh.mesh = sphere
	hull_mesh.scale = Vector3(1.0, 1.0, 2.4)
	var blimp_mat = StandardMaterial3D.new()
	blimp_mat.albedo_color = Color(0.14, 0.16, 0.22)
	blimp_mat.metallic = 0.85
	blimp_mat.roughness = 0.22
	hull_mesh.material_override = blimp_mat
	blimp_node.add_child(hull_mesh)

	# Illuminated Digital Billboard Screen on Blimp
	var blimp_screen = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(16.5, 4.5, 32.0)
	blimp_screen.mesh = s_mesh
	var screen_mat = StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.05, 0.85, 1.0)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.05, 0.85, 1.0)
	screen_mat.emission_energy_multiplier = 2.4
	blimp_screen.material_override = screen_mat
	blimp_node.add_child(blimp_screen)

	# Gondola with searchlight
	var gondola = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(3.5, 2.5, 12.0)
	gondola.mesh = g_box
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.85, 0.88, 0.92)
	g_mat.metallic = 0.9
	gondola.material_override = g_mat
	gondola.position = Vector3(0, -7.5, 0)
	blimp_node.add_child(gondola)

	var blimp_light = SpotLight3D.new()
	blimp_light.light_color = Color(0.9, 0.95, 1.0)
	blimp_light.light_energy = 4.0
	blimp_light.spot_range = 140.0
	blimp_light.spot_angle = 35.0
	blimp_light.rotation_degrees = Vector3(-75.0, 0.0, 0.0)
	gondola.add_child(blimp_light)

	airspace_node.add_child(blimp_node)

	# 2. Autonomous City Patrol Drones
	var drone_coords = [
		Vector3(-80.0, 48.0, -90.0),
		Vector3(80.0, 56.0, 40.0),
		Vector3(-110.0, 62.0, -280.0),
		Vector3(140.0, 52.0, -200.0)
	]
	for d_i in range(drone_coords.size()):
		var drone = Node3D.new()
		drone.name = "AirDrone_%d" % (d_i + 1)
		drone.position = drone_coords[d_i]

		var d_body = MeshInstance3D.new()
		var d_box = BoxMesh.new()
		d_box.size = Vector3(3.2, 0.8, 4.0)
		d_body.mesh = d_box
		var d_mat = StandardMaterial3D.new()
		d_mat.albedo_color = Color(0.12, 0.14, 0.18)
		d_mat.metallic = 0.8
		d_mat.roughness = 0.3
		d_body.material_override = d_mat
		drone.add_child(d_body)

		# Flashing Nav Strobe
		var strobe = MeshInstance3D.new()
		var s_sph = SphereMesh.new()
		s_sph.radius = 0.3
		s_sph.height = 0.6
		strobe.mesh = s_sph
		var s_mat = StandardMaterial3D.new()
		s_mat.albedo_color = Color(1.0, 0.1, 0.1) if d_i % 2 == 0 else Color(0.1, 1.0, 0.2)
		s_mat.emission_enabled = true
		s_mat.emission = s_mat.albedo_color
		s_mat.emission_energy_multiplier = 4.0
		strobe.material_override = s_mat
		strobe.position = Vector3(0, 0.6, 0)
		drone.add_child(strobe)

		airspace_node.add_child(drone)
		drone_nodes.append(drone)

	add_child(airspace_node)
