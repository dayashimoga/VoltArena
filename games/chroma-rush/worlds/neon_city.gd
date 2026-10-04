class_name NeonCity
extends "res://games/chroma-rush/worlds/world_base.gd"

## World 1: Neon City — Metropolitan Urban District
## A dense, varied, highly polished driving world with distinct urban districts,
## complete populated city blocks, secondary structures, courtyards, parking,
## realistic branching trees, architectural landmarks, distant skyline depth,
## and 100% collision-free drivable road lanes.

const ARCHITECTURAL_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 color_wall_primary : source_color;
uniform vec4 color_wall_secondary : source_color;
uniform vec4 color_window : source_color;
uniform vec4 color_trim : source_color;

uniform float wall_metallic : hint_range(0.0, 1.0) = 0.05;
uniform float wall_roughness : hint_range(0.0, 1.0) = 0.82;
uniform float window_metallic : hint_range(0.0, 1.0) = 0.85;
uniform float window_roughness : hint_range(0.0, 1.0) = 0.08;
uniform float window_clearcoat : hint_range(0.0, 1.0) = 0.90;

void fragment() {
	vec4 tex = texture(albedo_texture, UV);

	bool is_window = (tex.r < 0.14 && tex.g < 0.14 && tex.b < 0.14);
	bool is_teal_base = (tex.g > 0.48 && tex.r < 0.42);
	bool is_orange_band = (tex.r > 0.88 && tex.g < 0.66 && tex.b < 0.45);

	if (is_window) {
		ALBEDO = color_window.rgb;
		METALLIC = window_metallic;
		ROUGHNESS = window_roughness;
		CLEARCOAT = window_clearcoat;
		SPECULAR = 0.7;
	} else if (is_teal_base) {
		ALBEDO = color_wall_secondary.rgb;
		METALLIC = 0.20;
		ROUGHNESS = 0.65;
	} else if (is_orange_band) {
		ALBEDO = color_trim.rgb;
		METALLIC = 0.50;
		ROUGHNESS = 0.35;
	} else {
		float lum = (tex.r * 0.299 + tex.g * 0.587 + tex.b * 0.114);
		float factor = clamp(lum / 0.82, 0.88, 1.15);
		ALBEDO = color_wall_primary.rgb * factor;
		METALLIC = wall_metallic;
		ROUGHNESS = wall_roughness;
	}
}
"""

const ARCHITECTURAL_THEMES = [
	# 0. Modern Sapphire Glass Tower (Reflective deep blue curtain wall)
	{
		"wall_primary": Color(0.12, 0.22, 0.36),
		"wall_secondary": Color(0.68, 0.72, 0.76),
		"window": Color(0.06, 0.14, 0.26),
		"trim": Color(0.85, 0.88, 0.92),
		"wall_metallic": 0.85,
		"wall_roughness": 0.10,
		"window_metallic": 0.90,
		"window_roughness": 0.05,
		"window_clearcoat": 1.0,
		"name": "sapphire_glass"
	},
	# 1. Warm Limestone & Dark Bronze Executive Center
	{
		"wall_primary": Color(0.82, 0.78, 0.72),
		"wall_secondary": Color(0.28, 0.26, 0.24),
		"window": Color(0.14, 0.13, 0.11),
		"trim": Color(0.42, 0.34, 0.24),
		"wall_metallic": 0.02,
		"wall_roughness": 0.88,
		"window_metallic": 0.75,
		"window_roughness": 0.12,
		"window_clearcoat": 0.8,
		"name": "limestone_bronze"
	},
	# 2. Obsidian Tech Tower (Matte charcoal composite with cyan polarized glazing)
	{
		"wall_primary": Color(0.18, 0.20, 0.22),
		"wall_secondary": Color(0.12, 0.13, 0.14),
		"window": Color(0.10, 0.32, 0.40),
		"trim": Color(0.24, 0.55, 0.65),
		"wall_metallic": 0.45,
		"wall_roughness": 0.42,
		"window_metallic": 0.88,
		"window_roughness": 0.08,
		"window_clearcoat": 0.9,
		"name": "obsidian_tech"
	},
	# 3. Emerald Eco-Terrace Tower (Crisp Scandinavian White Stone & Cedar Wood)
	{
		"wall_primary": Color(0.92, 0.93, 0.92),
		"wall_secondary": Color(0.48, 0.32, 0.20),
		"window": Color(0.12, 0.24, 0.16),
		"trim": Color(0.22, 0.45, 0.28),
		"wall_metallic": 0.05,
		"wall_roughness": 0.75,
		"window_metallic": 0.65,
		"window_roughness": 0.15,
		"window_clearcoat": 0.7,
		"name": "eco_terrace"
	},
	# 4. Terracotta & Patina Copper Metro Tower
	{
		"wall_primary": Color(0.68, 0.34, 0.22),
		"wall_secondary": Color(0.32, 0.20, 0.14),
		"window": Color(0.16, 0.15, 0.12),
		"trim": Color(0.35, 0.52, 0.44),
		"wall_metallic": 0.15,
		"wall_roughness": 0.92,
		"window_metallic": 0.60,
		"window_roughness": 0.18,
		"window_clearcoat": 0.6,
		"name": "terracotta_copper"
	},
	# 5. Titanium Modernist High-Rise (Brushed aerospace metal & smoked glass)
	{
		"wall_primary": Color(0.62, 0.65, 0.68),
		"wall_secondary": Color(0.25, 0.28, 0.32),
		"window": Color(0.07, 0.08, 0.10),
		"trim": Color(0.80, 0.84, 0.88),
		"wall_metallic": 0.85,
		"wall_roughness": 0.32,
		"window_metallic": 0.80,
		"window_roughness": 0.10,
		"window_clearcoat": 0.85,
		"name": "titanium_modernist"
	}
]

static var _cached_building_shader: Shader = null

static func _get_architectural_shader() -> Shader:
	if not _cached_building_shader:
		_cached_building_shader = Shader.new()
		_cached_building_shader.code = ARCHITECTURAL_SHADER_CODE
	return _cached_building_shader

func _init() -> void:
	world_id = ChromaConstants.WORLD_NEON_CITY
	world_name = "Neon City"

func generate_waypoints() -> void:
	waypoints.clear()
	# 16-point connected urban avenue circuit with straights, 90-degree corners, and an underpass
	var raw_points = [
		Vector3(0, 0, 0),         # 0 Start/Finish line Avenue (Financial District)
		Vector3(0, 0, -80),       # 1 North Boulevard
		Vector3(0, 0, -180),      # 2 Central Square Intersection
		Vector3(60, 0, -230),     # 3 Northeast Curve
		Vector3(140, 0, -230),    # 4 Financial Plaza East (Commercial Corridor)
		Vector3(200, 0, -170),    # 5 East Flyover Incline
		Vector3(200, 4, -80),     # 6 Elevated Skyway (Industrial / Logistics)
		Vector3(200, 4, 10),      # 7 Skyway South
		Vector3(150, 2, 90),      # 8 Skyway Descent Ramp
		Vector3(80, 0, 110),      # 9 City Plaza Entry (Neon & Entertainment District)
		Vector3(10, -2, 110),     # 10 Subterranean Avenue Underpass
		Vector3(-60, -2, 110),    # 11 Tunnel Midpoint
		Vector3(-120, 0, 80),     # 12 Tunnel Exit / West Marina Plaza (Waterfront District)
		Vector3(-120, 0, 0),      # 13 West Boulevard
		Vector3(-90, 0, -45),     # 14 Grand Avenue Chicane (Historic Old Town)
		Vector3(-40, 0, 0)        # 15 Home Stretch
	]
	for p in raw_points:
		waypoints.append(p)

	# Orient player spawn strictly facing forward down North Boulevard (towards waypoints[1])
	var p0 = waypoints[0]
	var p1 = waypoints[1]
	var fwd = (p1 - p0).normalized()
	player_spawn_transform = Transform3D().looking_at(fwd, Vector3.UP)
	player_spawn_transform.origin = p0 + Vector3(0.0, 0.05, 0.0)

	# Pre-configure traffic spawners along various segments with distinct colors and speeds
	traffic_spawn_data = [
		{"waypoint_idx": 2, "color": ChromaConstants.ChromaColor.COBALT, "speed": 22.0},
		{"waypoint_idx": 4, "color": ChromaConstants.ChromaColor.SOLAR, "speed": 20.0},
		{"waypoint_idx": 7, "color": ChromaConstants.ChromaColor.EMERALD, "speed": 24.0},
		{"waypoint_idx": 11, "color": ChromaConstants.ChromaColor.MAGENTA, "speed": 21.0},
		{"waypoint_idx": 13, "color": ChromaConstants.ChromaColor.CYAN, "speed": 23.0}
	]

func build_road_mesh() -> void:
	var road_w = 15.0
	build_continuous_road_network(waypoints, road_w)

func build_checkpoints() -> void:
	checkpoints.clear()
	# Checkpoint gates positioned on straight segments with tangent alignment and 24m clear span
	var gate_defs = [
		{"id": "gate_1", "wp_a": 1, "wp_b": 2, "color": ChromaConstants.ChromaColor.CRIMSON},  # North Blvd straight
		{"id": "gate_2", "wp_a": 4, "wp_b": 5, "color": ChromaConstants.ChromaColor.COBALT},   # Financial Plaza East
		{"id": "gate_3", "wp_a": 7, "wp_b": 8, "color": ChromaConstants.ChromaColor.SOLAR},    # Skyway Descent
		{"id": "gate_4", "wp_a": 9, "wp_b": 10, "color": ChromaConstants.ChromaColor.EMERALD}, # Plaza Approach
		{"id": "gate_5", "wp_a": 11, "wp_b": 12, "color": ChromaConstants.ChromaColor.MAGENTA},# Underpass Exit
		{"id": "gate_6", "wp_a": 14, "wp_b": 15, "color": ChromaConstants.ChromaColor.CYAN}   # Home Stretch straight
	]

	for g in gate_defs:
		var gate = CheckpointGate.new()
		gate.gate_id = g["id"]
		gate.target_color = g["color"]
		gate.gate_width = 24.0 # 24m clear-span places support columns safely 4.5m outside road edge

		var p_a = waypoints[g["wp_a"]]
		var p_b = waypoints[g["wp_b"]]
		var center_pt = (p_a + p_b) * 0.5
		var dir = (p_b - p_a).normalized()
		dir.y = 0.0
		if dir.length_squared() < 0.001:
			dir = Vector3.FORWARD
		dir = dir.normalized()

		gate.position = center_pt + Vector3(0.0, 0.15, 0.0)
		gate.look_at_from_position(gate.position, gate.position + dir, Vector3.UP)

		gates_container.add_child(gate)
		checkpoints.append(gate)

func build_props() -> void:
	var skyscraper_paths = [
		"res://assets/models/environment/building_skyscraper_a.glb",
		"res://assets/models/environment/building_skyscraper_b.glb",
		"res://assets/models/environment/building_skyscraper_c.glb",
		"res://assets/models/environment/building_skyscraper_d.glb",
		"res://assets/models/environment/building_skyscraper_e.glb"
	]
	var commercial_paths = [
		"res://assets/models/environment/building_comm_a.glb",
		"res://assets/models/environment/building_comm_b.glb",
		"res://assets/models/environment/building_comm_c.glb",
		"res://assets/models/environment/building_comm_d.glb",
		"res://assets/models/environment/building_comm_e.glb",
		"res://assets/models/environment/building_comm_f.glb"
	]

	var n_wp = waypoints.size()

	# 1. Primary Street-Facing City Blocks (Lined on both sides with generous safety setbacks >= 14.5m)
	for i in range(n_wp):
		var p1 = waypoints[i]
		var p2 = waypoints[(i + 1) % n_wp]
		var seg_vec = p2 - p1
		var seg_len = seg_vec.length()
		if seg_len < 10.0:
			continue
		var dir = seg_vec.normalized()
		var right = Vector3(-dir.z, 0, dir.x).normalized()
		var rot_base = rad_to_deg(atan2(-dir.x, -dir.z))

		var num_slots = max(1, int(seg_len / 28.0))
		var step = seg_len / float(num_slots)

		for s in range(num_slots):
			var dist_along = (float(s) + 0.5) * step
			var center_pt = p1 + dir * dist_along

			# Left Side Primary Building (setback 22.0m -> completely clear of 7.5m road & 9.35m sidewalk)
			var setback_l = 22.0 + float((i + s) % 3) * 3.0
			var pos_l = center_pt - right * setback_l
			pos_l.y = p1.y
			var theme_l = (i * 3 + s) % ARCHITECTURAL_THEMES.size()
			var b_l = _create_district_building(i, s, skyscraper_paths, commercial_paths, theme_l, "Left")
			b_l.position = pos_l
			b_l.rotation_degrees.y = rot_base + 90.0
			props_container.add_child(b_l)

			# Urban Plaza Foundation beneath left building (anchored to ground y=0, non-blocking)
			var plaza_l = _build_urban_plaza_foundation(32.0, 32.0, 0.0, p1.y + 0.08)
			plaza_l.position = Vector3(pos_l.x, 0.0, pos_l.z)
			plaza_l.rotation_degrees.y = rot_base + 90.0
			props_container.add_child(plaza_l)

			# Right Side Primary Building (setback 22.0m)
			var setback_r = 22.0 + float((i + s + 1) % 3) * 3.0
			var pos_r = center_pt + right * setback_r
			pos_r.y = p1.y
			var theme_r = (i * 3 + s + 1) % ARCHITECTURAL_THEMES.size()
			var b_r = _create_district_building(i, s + 1, skyscraper_paths, commercial_paths, theme_r, "Right")
			b_r.position = pos_r
			b_r.rotation_degrees.y = rot_base - 90.0
			props_container.add_child(b_r)

			# Urban Plaza Foundation beneath right building
			var plaza_r = _build_urban_plaza_foundation(32.0, 32.0, 0.0, p1.y + 0.08)
			plaza_r.position = Vector3(pos_r.x, 0.0, pos_r.z)
			plaza_r.rotation_degrees.y = rot_base - 90.0
			props_container.add_child(plaza_r)

			# Realistic Natural Street Trees planted safely on sidewalk verge (offset 11.5m, giving 4m road clearance!)
			if s % 2 == 0 and p1.y < 1.0:
				var species_l = _get_district_tree_species(i)
				var tree_l = _build_realistic_tree(species_l, 6.2 + float(i % 3) * 0.8, i * 17 + s)
				tree_l.position = center_pt - right * 11.6
				tree_l.position.y = p1.y
				props_container.add_child(tree_l)

				var species_r = _get_district_tree_species((i + 2) % n_wp)
				var tree_r = _build_realistic_tree(species_r, 6.0 + float((i + 1) % 3) * 0.8, i * 23 + s)
				tree_r.position = center_pt + right * 11.6
				tree_r.position.y = p1.y
				props_container.add_child(tree_r)

			# Modern Street Furniture & Amenities (Benches, Hydrants, Waste Bins)
			if s % 2 == 1 and p1.y < 1.0:
				var bench = _build_street_bench()
				bench.position = center_pt - right * 11.2
				bench.position.y = p1.y + 0.10
				bench.rotation_degrees.y = rot_base + 90.0
				props_container.add_child(bench)

	# 2. Modern Street Light Posts (Safely positioned at ±11.0m with cantilever arm)
	for i in range(waypoints.size()):
		var wp = waypoints[i]
		var next_wp = waypoints[(i + 1) % waypoints.size()]
		var dir = (next_wp - wp).normalized()
		var right = Vector3(-dir.z, 0, dir.x).normalized()

		for side in [-1.0, 1.0]:
			var lamp_pos = wp + right * (side * 11.0) + Vector3(0.0, 0.1, 0.0)
			var lamp = _build_procedural_streetlight()
			lamp.position = lamp_pos
			lamp.rotation_degrees.y = rad_to_deg(atan2(-dir.x, -dir.z)) + (90.0 if side > 0 else -90.0)
			props_container.add_child(lamp)

	# 3. Secondary City Blocks & Courtyards (Deep urban density behind street-facing row)
	_build_secondary_city_blocks()

	# 4. Iconic Navigation Landmarks
	_build_city_landmarks()

	# 5. 360-Degree Distant City Skyline & Atmospheric Perimeter
	_build_distant_skyline_backdrop()

func _create_district_building(i: int, s: int, skyscrapers: Array, commercials: Array, theme_idx: int, side_name: String) -> Node3D:
	var b_node: Node3D = null
	if (i + s) % 2 == 0:
		var m_idx = (i * 2 + s) % skyscrapers.size()
		var glb_model = ModelCache.get_model(skyscrapers[m_idx])
		if glb_model:
			glb_model.scale = Vector3(10.0, 12.5, 10.0)
			_style_building(glb_model, theme_idx)
			var b_body = StaticBody3D.new()
			b_body.name = "Skyscraper%s_%d_%d" % [side_name, i, s]
			b_body.collision_layer = GameConstants.LAYER_WORLD
			b_body.add_child(glb_model)
			var col = CollisionShape3D.new()
			var b_shape = BoxShape3D.new()
			b_shape.size = Vector3(20.0, 50.0, 20.0)
			col.shape = b_shape
			col.position = Vector3(0, 25.0, 0)
			b_body.add_child(col)
			b_node = b_body
	else:
		var m_idx = (i * 2 + s) % commercials.size()
		var glb_model = ModelCache.get_model(commercials[m_idx])
		if glb_model:
			glb_model.scale = Vector3(8.0, 8.5, 8.0)
			_style_building(glb_model, theme_idx)
			var b_body = StaticBody3D.new()
			b_body.name = "Commercial%s_%d_%d" % [side_name, i, s]
			b_body.collision_layer = GameConstants.LAYER_WORLD
			b_body.add_child(glb_model)
			var col = CollisionShape3D.new()
			var b_shape = BoxShape3D.new()
			b_shape.size = Vector3(16.0, 30.0, 16.0)
			col.shape = b_shape
			col.position = Vector3(0, 15.0, 0)
			b_body.add_child(col)
			b_node = b_body

	if not b_node:
		var h = 36.0 + float((i + s) % 5) * 8.0
		b_node = _build_procedural_commercial_block(h, 22.0, theme_idx)

	return b_node

func _build_secondary_city_blocks() -> void:
	# Secondary buildings, parking courtyards, and warehouse blocks filling interior space
	var block_configs = [
		{"pos": Vector3(70, 0, -80), "h": 58.0, "w": 30.0, "theme": 0},
		{"pos": Vector3(110, 0, -110), "h": 68.0, "w": 34.0, "theme": 2},
		{"pos": Vector3(80, 0, -170), "h": 50.0, "w": 28.0, "theme": 1},
		{"pos": Vector3(130, 0, -170), "h": 44.0, "w": 26.0, "theme": 4},
		{"pos": Vector3(-60, 0, -120), "h": 62.0, "w": 32.0, "theme": 0},
		{"pos": Vector3(-80, 0, -180), "h": 54.0, "w": 30.0, "theme": 5},
		{"pos": Vector3(-130, 0, -80), "h": 46.0, "w": 26.0, "theme": 1},
		{"pos": Vector3(-150, 0, -40), "h": 38.0, "w": 24.0, "theme": 4},
		{"pos": Vector3(70, 0, 50), "h": 42.0, "w": 28.0, "theme": 3},
		{"pos": Vector3(110, 0, 40), "h": 52.0, "w": 30.0, "theme": 0},
		{"pos": Vector3(-40, 0, 60), "h": 36.0, "w": 24.0, "theme": 1},
		{"pos": Vector3(-80, 0, 40), "h": 40.0, "w": 26.0, "theme": 3},
		{"pos": Vector3(250, 0, -120), "h": 32.0, "w": 40.0, "theme": 1},
		{"pos": Vector3(260, 0, -50), "h": 28.0, "w": 44.0, "theme": 5},
		{"pos": Vector3(250, 0, 40), "h": 34.0, "w": 38.0, "theme": 1}
	]

	for cfg in block_configs:
		var block = _build_procedural_commercial_block(cfg["h"], cfg["w"], cfg["theme"])
		block.position = cfg["pos"]
		props_container.add_child(block)

		var plaza = _build_urban_plaza_foundation(cfg["w"] + 8.0, cfg["w"] + 8.0, 0.0, 0.06)
		plaza.position = cfg["pos"]
		props_container.add_child(plaza)

		# Add parked service vehicles and low-poly cars in parking courtyards
		var car_pos = cfg["pos"] + Vector3(cfg["w"] * 0.45, 0.1, cfg["w"] * 0.45)
		var parked_car = _build_parked_vehicle_prop()
		parked_car.position = car_pos
		props_container.add_child(parked_car)

func _build_city_landmarks() -> void:
	# 1. Apex Spire (110m Iconic Metropolitan Centerpiece)
	var spire_root = StaticBody3D.new()
	spire_root.name = "ApexSpireLandmark"
	spire_root.collision_layer = GameConstants.LAYER_WORLD

	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(36.0, 115.0, 36.0)
	col.shape = col_box
	col.position = Vector3(0, 57.5, 0)
	spire_root.add_child(col)

	var mat_spire = StandardMaterial3D.new()
	mat_spire.albedo_color = Color(0.12, 0.20, 0.32)
	mat_spire.metallic = 0.90
	mat_spire.roughness = 0.12
	mat_spire.clearcoat_enabled = true
	mat_spire.clearcoat = 1.0

	var tower_mi = MeshInstance3D.new()
	var tower_box = BoxMesh.new()
	tower_box.size = Vector3(28.0, 85.0, 28.0)
	tower_mi.mesh = tower_box
	tower_mi.material_override = mat_spire
	tower_mi.position = Vector3(0, 42.5, 0)
	spire_root.add_child(tower_mi)

	# Needle crown
	var needle_mi = MeshInstance3D.new()
	var needle_cyl = CylinderMesh.new()
	needle_cyl.top_radius = 0.2
	needle_cyl.bottom_radius = 2.4
	needle_cyl.height = 32.0
	needle_mi.mesh = needle_cyl
	needle_mi.position = Vector3(0, 85.0 + 16.0, 0)
	var mat_needle = StandardMaterial3D.new()
	mat_needle.albedo_color = Color(0.85, 0.88, 0.92)
	mat_needle.metallic = 0.95
	mat_needle.roughness = 0.15
	needle_mi.material_override = mat_needle
	spire_root.add_child(needle_mi)

	# Crown aviation beacon (glowing cyan / amber)
	var beacon = OmniLight3D.new()
	beacon.light_color = Color(0.0, 0.85, 1.0)
	beacon.light_energy = 4.0
	beacon.omni_range = 60.0
	beacon.position = Vector3(0, 118.0, 0)
	spire_root.add_child(beacon)

	spire_root.position = Vector3(70.0, 0.0, -110.0)
	props_container.add_child(spire_root)

	# 2. Historic Station Clocktower (Civic Square Landmark at WP 14)
	var clocktower = StaticBody3D.new()
	clocktower.name = "HistoricClocktower"
	clocktower.collision_layer = GameConstants.LAYER_WORLD

	var ct_col = CollisionShape3D.new()
	var ct_shape = BoxShape3D.new()
	ct_shape.size = Vector3(14.0, 48.0, 14.0)
	ct_col.shape = ct_shape
	ct_col.position = Vector3(0, 24.0, 0)
	clocktower.add_child(ct_col)

	var mat_brick = StandardMaterial3D.new()
	mat_brick.albedo_color = Color(0.68, 0.35, 0.22)
	mat_brick.roughness = 0.92

	var ct_body = MeshInstance3D.new()
	var ct_box = BoxMesh.new()
	ct_box.size = Vector3(12.0, 42.0, 12.0)
	ct_body.mesh = ct_box
	ct_body.material_override = mat_brick
	ct_body.position = Vector3(0, 21.0, 0)
	clocktower.add_child(ct_body)

	# Illuminated clock face
	var mat_clock = StandardMaterial3D.new()
	mat_clock.albedo_color = Color(1.0, 0.98, 0.88)
	mat_clock.emission_enabled = true
	mat_clock.emission = Color(1.0, 0.95, 0.80)
	mat_clock.emission_energy_multiplier = 1.5

	for side_rot in [0.0, 90.0, 180.0, 270.0]:
		var face = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 2.2
		cyl.bottom_radius = 2.2
		cyl.height = 0.2
		face.mesh = cyl
		face.material_override = mat_clock
		face.rotation_degrees = Vector3(90, side_rot, 0)
		face.position = Vector3(0, 36.0, 0) + Transform3D().rotated(Vector3.UP, deg_to_rad(side_rot)).basis.z * 6.05
		clocktower.add_child(face)

	clocktower.position = Vector3(-65.0, 0.0, -60.0)
	props_container.add_child(clocktower)

func _build_distant_skyline_backdrop() -> void:
	# MultiMesh perimeter ring creating dense horizon skyline depth (zero empty space)
	var tower_count = 36
	var radius = 340.0

	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = BoxMesh.new()
	(multimesh.mesh as BoxMesh).size = Vector3(26.0, 80.0, 26.0)
	multimesh.instance_count = tower_count

	var mat_distant = StandardMaterial3D.new()
	mat_distant.albedo_color = Color(0.18, 0.24, 0.32)
	mat_distant.metallic = 0.50
	mat_distant.roughness = 0.60
	mat_distant.vertex_color_use_as_albedo = true

	for t in range(tower_count):
		var angle = (float(t) / float(tower_count)) * TAU
		var dist_var = radius + float(t % 5) * 25.0
		var tx = cos(angle) * dist_var
		var tz = sin(angle) * dist_var
		var scale_y = 0.7 + float((t * 7) % 10) * 0.12
		var height = 80.0 * scale_y

		var xf = Transform3D()
		xf = xf.scaled(Vector3(1.0 + float(t % 3) * 0.2, scale_y, 1.0 + float((t + 1) % 3) * 0.2))
		xf.origin = Vector3(tx, height * 0.5, tz)
		multimesh.set_instance_transform(t, xf)

		var shade = 0.75 + float(t % 4) * 0.08
		var col = Color(0.14 * shade, 0.20 * shade, 0.30 * shade, 1.0)
		multimesh.set_instance_color(t, col)

	var mm_inst = MultiMeshInstance3D.new()
	mm_inst.name = "DistantSkylineMultiMesh"
	mm_inst.multimesh = multimesh
	mm_inst.material_override = mat_distant
	props_container.add_child(mm_inst)

func _get_district_tree_species(wp_idx: int) -> String:
	match wp_idx:
		12, 13:
			return "palm"       # Marina Waterfront
		9, 10, 11:
			return "cherry"     # Neon Entertainment District
		14, 15, 0:
			return "birch"      # Historic Old Town & Central Park
		5, 6, 7, 8:
			return "pine"       # Skyway Outskirts
		_:
			return "oak"        # Metropolitan Financial & Commercial

func _build_realistic_tree(species: String, height: float, seed_val: int) -> Node3D:
	var root = StaticBody3D.new()
	root.name = "RealisticStreetTree_%s_%d" % [species, seed_val]
	root.collision_layer = GameConstants.LAYER_WORLD

	# Solid Trunk Collider strictly protecting tree trunk
	var col = CollisionShape3D.new()
	col.name = "TreeTrunkCollision"
	var col_shape = CylinderShape3D.new()
	col_shape.height = height * 0.75
	col_shape.radius = 0.40
	col.shape = col_shape
	col.position = Vector3(0, col_shape.height * 0.5, 0)
	root.add_child(col)

	# 1. Circular Stone Planter Curb on Sidewalk
	var planter = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 1.30
	p_cyl.bottom_radius = 1.35
	p_cyl.height = 0.20
	planter.mesh = p_cyl
	planter.material_override = mat_curb
	planter.position = Vector3(0, 0.10, 0)
	root.add_child(planter)

	# 2. Rich Dark Loamy Soil
	var soil = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 1.20
	s_cyl.bottom_radius = 1.20
	s_cyl.height = 0.21
	soil.mesh = s_cyl
	var mat_soil = StandardMaterial3D.new()
	mat_soil.albedo_color = Color(0.14, 0.11, 0.09)
	mat_soil.roughness = 0.98
	soil.material_override = mat_soil
	soil.position = Vector3(0, 0.11, 0)
	root.add_child(soil)

	# 3. Organic Fluted Wood Trunk
	var trunk = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.18
	t_cyl.bottom_radius = 0.36
	t_cyl.height = height * 0.70
	trunk.mesh = t_cyl
	var mat_bark = StandardMaterial3D.new()
	mat_bark.albedo_color = Color(0.24, 0.18, 0.13)
	mat_bark.roughness = 0.92
	trunk.material_override = mat_bark
	trunk.position = Vector3(0, t_cyl.height * 0.5, 0)
	root.add_child(trunk)

	# 4. Multi-Layer Branching Foliage Canopy (BURLEY diffuse, naturalistic cluster layers)
	var leaf_color = Color(0.14, 0.40, 0.16)
	match species:
		"cherry":
			leaf_color = Color(0.85, 0.42, 0.65) # Japanese Cherry Blossom Pink
		"birch":
			leaf_color = Color(0.82, 0.68, 0.18) # Autumn Golden Amber
		"pine":
			leaf_color = Color(0.09, 0.28, 0.14) # Deep Conifer Green
		"palm":
			leaf_color = Color(0.18, 0.46, 0.20) # Coastal Tropical Palm Frond

	var clusters = [
		{"pos": Vector3(0.0, height * 0.85, 0.0), "r": 2.2, "h": 2.4},
		{"pos": Vector3(-0.9, height * 0.75, 0.5), "r": 1.6, "h": 1.8},
		{"pos": Vector3(0.85, height * 0.78, -0.4), "r": 1.7, "h": 1.9},
		{"pos": Vector3(0.2, height * 1.05, 0.2), "r": 1.4, "h": 1.6},
		{"pos": Vector3(0.4, height * 0.88, 0.8), "r": 1.3, "h": 1.5}
	]

	for c in clusters:
		var fol = MeshInstance3D.new()
		var sp = SphereMesh.new()
		sp.radius = c["r"]
		sp.height = c["h"]
		sp.radial_segments = 14
		sp.rings = 8
		fol.mesh = sp
		var mat_fol = StandardMaterial3D.new()
		mat_fol.albedo_color = leaf_color
		mat_fol.roughness = 0.82
		mat_fol.specular = 0.12
		mat_fol.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
		fol.material_override = mat_fol
		fol.position = c["pos"]
		root.add_child(fol)

	return root

func _build_street_bench() -> Node3D:
	var bench = Node3D.new()
	var seat = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 0.08, 0.6)
	seat.mesh = box
	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.42, 0.26, 0.16)
	mat_wood.roughness = 0.75
	seat.material_override = mat_wood
	seat.position = Vector3(0, 0.45, 0)
	bench.add_child(seat)

	var leg_mat = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.2, 0.22, 0.24)
	leg_mat.metallic = 0.90
	leg_mat.roughness = 0.35

	for lx in [-0.85, 0.85]:
		var leg = MeshInstance3D.new()
		var leg_box = BoxMesh.new()
		leg_box.size = Vector3(0.10, 0.45, 0.55)
		leg.mesh = leg_box
		leg.material_override = leg_mat
		leg.position = Vector3(lx, 0.225, 0)
		bench.add_child(leg)

	return bench

func _build_parked_vehicle_prop() -> Node3D:
	var root = Node3D.new()
	var body_mi = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.8, 1.3, 4.0)
	body_mi.mesh = b_box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.35, 0.48)
	mat.metallic = 0.70
	mat.roughness = 0.30
	body_mi.material_override = mat
	body_mi.position = Vector3(0, 0.65, 0)
	root.add_child(body_mi)
	return root

func _style_building(building: Node3D, theme_idx: int) -> void:
	if not building:
		return
	var theme = ARCHITECTURAL_THEMES[theme_idx % ARCHITECTURAL_THEMES.size()]
	var shader = _get_architectural_shader()
	var colormap_tex = load("res://assets/models/environment/Textures/colormap.png")

	var meshes: Array[MeshInstance3D] = []
	_gather_meshes(building, meshes)

	for mi in meshes:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		if colormap_tex:
			mat.set_shader_parameter("albedo_texture", colormap_tex)
		mat.set_shader_parameter("color_wall_primary", theme["wall_primary"])
		mat.set_shader_parameter("color_wall_secondary", theme["wall_secondary"])
		mat.set_shader_parameter("color_window", theme["window"])
		mat.set_shader_parameter("color_trim", theme["trim"])
		mat.set_shader_parameter("wall_metallic", theme["wall_metallic"])
		mat.set_shader_parameter("wall_roughness", theme["wall_roughness"])
		mat.set_shader_parameter("window_metallic", theme["window_metallic"])
		mat.set_shader_parameter("window_roughness", theme["window_roughness"])
		mat.set_shader_parameter("window_clearcoat", theme["window_clearcoat"])
		mi.material_override = mat

func _gather_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_gather_meshes(child, result)

func _build_urban_plaza_foundation(width: float, depth: float, base_y: float = 0.0, top_y: float = 0.16) -> Node3D:
	var root = StaticBody3D.new()
	root.name = "UrbanPlazaFoundation"
	root.collision_layer = GameConstants.LAYER_WORLD

	var total_h = maxf(0.24, top_y - base_y)
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(width, total_h, depth)
	mi.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.27, 0.29)
	mat.roughness = 0.85
	mat.metallic = 0.02
	mi.material_override = mat
	mi.position = Vector3(0, total_h * 0.5, 0)
	root.add_child(mi)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(width, total_h, depth)
	col.shape = shape
	col.position = mi.position
	root.add_child(col)

	return root

func _build_procedural_commercial_block(height: float, width: float, theme_idx: int = 0) -> Node3D:
	var root = StaticBody3D.new()
	root.name = "ProceduralCommercialTower"
	root.collision_layer = GameConstants.LAYER_WORLD

	var theme = ARCHITECTURAL_THEMES[theme_idx % ARCHITECTURAL_THEMES.size()]

	var mat_wall = StandardMaterial3D.new()
	mat_wall.albedo_color = theme["wall_primary"]
	mat_wall.metallic = theme["wall_metallic"]
	mat_wall.roughness = theme["wall_roughness"]

	var mat_podium = StandardMaterial3D.new()
	mat_podium.albedo_color = theme["wall_secondary"]
	mat_podium.metallic = 0.20
	mat_podium.roughness = 0.65

	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = theme["window"]
	mat_glass.metallic = theme["window_metallic"]
	mat_glass.roughness = theme["window_roughness"]
	mat_glass.clearcoat_enabled = true
	mat_glass.clearcoat = theme["window_clearcoat"]

	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(width, height + 4.0, width * 0.95)
	col.shape = col_box
	col.position = Vector3(0, (height + 4.0) * 0.5, 0)
	root.add_child(col)

	# 1. Ground Level Retail Podium (4.5m height)
	var podium_mi = MeshInstance3D.new()
	var podium_box = BoxMesh.new()
	podium_box.size = Vector3(width, 4.5, width * 0.95)
	podium_mi.mesh = podium_box
	podium_mi.material_override = mat_podium
	podium_mi.position = Vector3(0, 2.25, 0)
	root.add_child(podium_mi)

	var shop_mi = MeshInstance3D.new()
	var shop_box = BoxMesh.new()
	shop_box.size = Vector3(width + 0.1, 2.8, width * 0.95 + 0.1)
	shop_mi.mesh = shop_box
	shop_mi.material_override = mat_glass
	shop_mi.position = Vector3(0, 1.8, 0)
	root.add_child(shop_mi)

	# 2. Main High-Rise Tower Body
	var body_h = height - 4.5
	var body_w = width * 0.90
	var body_mi = MeshInstance3D.new()
	var body_box = BoxMesh.new()
	body_box.size = Vector3(body_w, body_h, body_w * 0.92)
	body_mi.mesh = body_box
	body_mi.material_override = mat_wall
	body_mi.position = Vector3(0, 4.5 + body_h * 0.5, 0)
	root.add_child(body_mi)

	# 3. Ribbon Glass Windows Across Tower Floors
	var floors = int(body_h / 3.8)
	for f in range(floors):
		var w_mi = MeshInstance3D.new()
		var w_box = BoxMesh.new()
		w_box.size = Vector3(body_w + 0.12, 1.8, body_w * 0.92 + 0.12)
		w_mi.mesh = w_box
		w_mi.material_override = mat_glass
		w_mi.position = Vector3(0, 4.5 + float(f) * 3.8 + 2.0, 0)
		root.add_child(w_mi)

	# 4. Rooftop Mechanical Bulkhead & Architectural Antenna
	var roof_y = 4.5 + body_h
	var roof_bulk = MeshInstance3D.new()
	var bulk_box = BoxMesh.new()
	bulk_box.size = Vector3(body_w * 0.5, 3.2, body_w * 0.45)
	roof_bulk.mesh = bulk_box
	roof_bulk.material_override = mat_podium
	roof_bulk.position = Vector3(0, roof_y + 1.6, 0)
	root.add_child(roof_bulk)

	var mast_mi = MeshInstance3D.new()
	var mast_cyl = CylinderMesh.new()
	mast_cyl.top_radius = 0.08
	mast_cyl.bottom_radius = 0.16
	mast_cyl.height = 7.5
	mast_mi.mesh = mast_cyl
	var mat_mast = StandardMaterial3D.new()
	mat_mast.albedo_color = Color(0.70, 0.72, 0.75)
	mat_mast.metallic = 0.95
	mat_mast.roughness = 0.20
	mast_mi.material_override = mat_mast
	mast_mi.position = Vector3(0, roof_y + 3.2 + 3.75, 0)
	root.add_child(mast_mi)

	return root

func _build_procedural_streetlight() -> Node3D:
	var root = StaticBody3D.new()
	root.name = "StreetLight"
	root.collision_layer = GameConstants.LAYER_WORLD

	var col = CollisionShape3D.new()
	col.name = "PostCollision"
	var col_shape = CylinderShape3D.new()
	col_shape.height = 7.0
	col_shape.radius = 0.20
	col.shape = col_shape
	col.position = Vector3(0, 3.5, 0)
	root.add_child(col)

	var mat_pole = StandardMaterial3D.new()
	mat_pole.albedo_color = Color(0.35, 0.38, 0.42)
	mat_pole.metallic = 0.85
	mat_pole.roughness = 0.3

	var post_mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.10
	cyl.bottom_radius = 0.14
	cyl.height = 7.0
	post_mi.mesh = cyl
	post_mi.material_override = mat_pole
	post_mi.position = Vector3(0, 3.5, 0)
	root.add_child(post_mi)

	var arm_mi = MeshInstance3D.new()
	var arm_cyl = CylinderMesh.new()
	arm_cyl.top_radius = 0.08
	arm_cyl.bottom_radius = 0.08
	arm_cyl.height = 2.5
	arm_mi.mesh = arm_cyl
	arm_mi.material_override = mat_pole
	arm_mi.rotation_degrees.z = 90.0
	arm_mi.position = Vector3(1.2, 6.8, 0)
	root.add_child(arm_mi)

	var lamp_mi = MeshInstance3D.new()
	var lamp_box = BoxMesh.new()
	lamp_box.size = Vector3(0.5, 0.15, 0.3)
	lamp_mi.mesh = lamp_box
	var mat_lamp = StandardMaterial3D.new()
	mat_lamp.albedo_color = Color(1.0, 0.96, 0.85)
	mat_lamp.emission_enabled = true
	mat_lamp.emission = Color(1.0, 0.94, 0.80)
	mat_lamp.emission_energy_multiplier = 2.0
	lamp_mi.material_override = mat_lamp
	lamp_mi.position = Vector3(2.3, 6.7, 0)
	root.add_child(lamp_mi)

	return root
