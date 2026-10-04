class_name NeonCity
extends "res://games/chroma-rush/worlds/world_base.gd"

## World 1: Neon City — Metropolitan Urban District
## A dense, varied, highly polished driving world with 6 distinct urban districts:
## 1. Downtown Financial Core & Grand Central Plaza (WP 0-5)
## 2. Commercial Promenade & Retail District (WP 6-10)
## 3. Industrial Logistics & Elevated Skyway Viaduct (WP 11-16)
## 4. Neon Entertainment Strip & Nightlife Chicanes (WP 17-21)
## 5. Waterfront Marina & Coastal Promenade (WP 22-26)
## 6. Historic Old Town & Cultural Quarter (WP 27-31)
##
## Features complete populated city blocks, secondary structures, courtyards, parking,
## organic branching trees (no sphere blobs), architectural landmarks, 360° distant skyline,
## and 100% collision-free drivable road lanes with zero obstructions.

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
	# 32-point interconnected metropolitan road network across 6 distinct districts (>3.5km total driving circuit)
	var raw_points = [
		Vector3(0, 0, 0),         # 0 Start/Finish Grand Boulevard (Downtown Financial Core)
		Vector3(0, 0, -80),       # 1 North Financial Avenue (Preserves exact test contract)
		Vector3(0, 0, -180),      # 2 Downtown Central Plaza
		Vector3(60, 0, -280),     # 3 Financial East Curve
		Vector3(160, 0, -360),    # 4 East Executive Parkway
		Vector3(280, 0, -380),    # 5 Gateway to Commercial District
		Vector3(400, 0, -340),    # 6 Retail Boulevard North (Commercial District)
		Vector3(480, 0, -240),    # 7 Plaza Square East
		Vector3(500, 0, -120),    # 8 Commercial South Avenue
		Vector3(460, 0, 0),       # 9 Grand Shopping Concourse
		Vector3(380, 0, 100),     # 10 Logistics Approach Junction
		Vector3(360, 1.5, 200),   # 11 Skyway Incline Ramp (Industrial Logistics District)
		Vector3(340, 5.0, 320),   # 12 Elevated Viaduct North
		Vector3(280, 6.0, 420),   # 13 High Skyway Flyover
		Vector3(180, 6.0, 460),   # 14 Logistics Hub Overpass
		Vector3(60, 4.0, 440),    # 15 Skyway Descent Ramp West
		Vector3(-40, 1.0, 400),   # 16 Viaduct Touchdown / Freight Terminal
		Vector3(-140, 0, 360),    # 17 Neon Boulevard Entrance (Neon Entertainment Strip)
		Vector3(-240, 0, 300),    # 18 Cyber Plaza & Nightlife Strip
		Vector3(-320, 0, 220),    # 19 Neon Chicanes Midpoint
		Vector3(-380, 0, 120),    # 20 Entertainment South Avenue
		Vector3(-420, 0, 0),      # 21 Marina Coastal Junction
		Vector3(-440, -0.5, -120),# 22 Coastal Bay Boulevard (Waterfront Marina)
		Vector3(-420, -1.0, -240),# 23 Marina Harbor Promenade
		Vector3(-360, -1.0, -340),# 24 Bayview Pier Turn
		Vector3(-280, -0.5, -420),# 25 Coastal Causeway North
		Vector3(-180, 0, -440),   # 26 Old Town Waterfront Gate
		Vector3(-100, 0, -380),   # 27 Old Town Terracotta Gate (Historic Old Town)
		Vector3(-80, 0, -260),    # 28 Clocktower Piazza
		Vector3(-80, 0, -120),    # 29 Historic Masonry Avenue
		Vector3(-60, 0, 0),       # 30 Cathedral Park South
		Vector3(0, 0, 70)         # 31 Grand Boulevard South Approach (250m straight into WP 0)
	]
	for p in raw_points:
		waypoints.append(p)

	# Orient player spawn strictly facing forward down North Financial Avenue
	var p0 = waypoints[0]
	var p1 = waypoints[1]
	var fwd = (p1 - p0).normalized()
	player_spawn_transform = Transform3D().looking_at(fwd, Vector3.UP)
	player_spawn_transform.origin = p0 + Vector3(0.0, 0.05, 0.0)

	# Dynamic traffic spawners distributed across all 6 districts
	traffic_spawn_data = [
		{"waypoint_idx": 2, "color": ChromaConstants.ChromaColor.COBALT, "speed": 22.0},
		{"waypoint_idx": 5, "color": ChromaConstants.ChromaColor.SOLAR, "speed": 20.0},
		{"waypoint_idx": 8, "color": ChromaConstants.ChromaColor.EMERALD, "speed": 24.0},
		{"waypoint_idx": 12, "color": ChromaConstants.ChromaColor.MAGENTA, "speed": 26.0},
		{"waypoint_idx": 15, "color": ChromaConstants.ChromaColor.CYAN, "speed": 22.0},
		{"waypoint_idx": 18, "color": ChromaConstants.ChromaColor.CRIMSON, "speed": 25.0},
		{"waypoint_idx": 22, "color": ChromaConstants.ChromaColor.SOLAR, "speed": 21.0},
		{"waypoint_idx": 25, "color": ChromaConstants.ChromaColor.COBALT, "speed": 23.0},
		{"waypoint_idx": 29, "color": ChromaConstants.ChromaColor.EMERALD, "speed": 19.0}
	]

func build_road_mesh() -> void:
	var road_w = 15.0
	build_continuous_road_network(waypoints, road_w)

func build_checkpoints() -> void:
	checkpoints.clear()
	# 6 Checkpoint gates positioned on straight segments with tangent alignment and 24m clear span
	var gate_defs = [
		{"id": "gate_1", "wp_a": 1, "wp_b": 2, "color": ChromaConstants.ChromaColor.CRIMSON},  # North Blvd straight (Downtown)
		{"id": "gate_2", "wp_a": 4, "wp_b": 5, "color": ChromaConstants.ChromaColor.COBALT},   # East Executive Parkway (Commercial)
		{"id": "gate_3", "wp_a": 8, "wp_b": 9, "color": ChromaConstants.ChromaColor.SOLAR},    # Commercial South Concourse
		{"id": "gate_4", "wp_a": 13, "wp_b": 14, "color": ChromaConstants.ChromaColor.EMERALD}, # Skyway Flyover Overpass (Logistics)
		{"id": "gate_5", "wp_a": 18, "wp_b": 19, "color": ChromaConstants.ChromaColor.MAGENTA},# Cyber Plaza Straight (Neon Strip)
		{"id": "gate_6", "wp_a": 28, "wp_b": 29, "color": ChromaConstants.ChromaColor.CYAN}   # Historic Masonry Avenue (Old Town)
	]

	for g in gate_defs:
		var gate = CheckpointGate.new()
		gate.gate_id = g["id"]
		gate.target_color = g["color"]
		gate.gate_width = 24.0 # 24m clear-span places support columns at ±12m (4.5m outside road edge)

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

func _is_clear_of_spline(pt: Vector3, min_clearance: float) -> bool:
	var pt_2d = Vector2(pt.x, pt.z)
	var n_s = spline_samples.size()
	for i in range(n_s):
		var s1 = spline_samples[i]
		var s2 = spline_samples[(i + 1) % n_s]
		var s1_2d = Vector2(s1.x, s1.z)
		var s2_2d = Vector2(s2.x, s2.z)
		var seg = s2_2d - s1_2d
		var seg_len_sq = seg.length_squared()
		var d = 0.0
		if seg_len_sq < 0.001:
			d = pt_2d.distance_to(s1_2d)
		else:
			var t = clampf((pt_2d - s1_2d).dot(seg) / seg_len_sq, 0.0, 1.0)
			var proj = s1_2d + seg * t
			d = pt_2d.distance_to(proj)
		if d < min_clearance:
			return false
	return true

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

	var n_spline = spline_samples.size()
	if n_spline < 10:
		return

	# 1. Primary Street-Facing City Blocks (Positioned at safe setback >= 24.0m, outside all sidewalks)
	var building_interval = 6 # every ~35m along spline
	for s_idx in range(0, n_spline, building_interval):
		var p_curr = spline_samples[s_idx]
		var p_next = spline_samples[(s_idx + 1) % n_spline]
		var p_prev = spline_samples[(s_idx - 1 + n_spline) % n_spline]
		var tangent = (p_next - p_prev).normalized()
		tangent.y = 0.0
		if tangent.length_squared() < 0.001:
			tangent = Vector3.FORWARD
		tangent = tangent.normalized()
		var right = tangent.cross(Vector3.UP).normalized()
		var rot_y = rad_to_deg(atan2(-tangent.x, -tangent.z))

		var wp_nearest = get_nearest_waypoint_index(p_curr)

		for side in [-1.0, 1.0]:
			var setback = 25.0 + float((s_idx + int(side > 0)) % 3) * 3.0
			var b_pos = p_curr + right * (side * setback)
			b_pos.y = p_curr.y

			# Enforce strict geometric clearance across the entire spline network
			if not _is_clear_of_spline(b_pos, 17.5):
				continue

			var theme_idx = (s_idx * 3 + int(side > 0) * 2 + wp_nearest) % ARCHITECTURAL_THEMES.size()
			var side_str = "Left" if side < 0 else "Right"
			var b_node = _create_district_building(wp_nearest, s_idx, skyscraper_paths, commercial_paths, theme_idx, side_str)
			b_node.position = b_pos
			b_node.rotation_degrees.y = rot_y + (90.0 if side < 0 else -90.0)
			props_container.add_child(b_node)

			# Urban Plaza Foundation beneath building: flush with ground, width 18m centered at 25m setback -> edge at 16m (6.6m clear of sidewalk!)
			var plaza = _build_urban_plaza_foundation(18.0, 18.0, 0.0, b_pos.y + 0.04)
			plaza.position = Vector3(b_pos.x, 0.0, b_pos.z)
			plaza.rotation_degrees.y = b_node.rotation_degrees.y
			props_container.add_child(plaza)

	# 2. Organic Branching Trees & Street Amenities (Positioned at lateral offset ±12.5m on verge/plaza)
	var tree_interval = 4 # every ~24m along spline
	for s_idx in range(0, n_spline, tree_interval):
		var p_curr = spline_samples[s_idx]
		# Only plant trees on ground level roads (avoid skyway elevated sections y > 2.0)
		if p_curr.y > 2.0:
			continue

		var p_next = spline_samples[(s_idx + 1) % n_spline]
		var p_prev = spline_samples[(s_idx - 1 + n_spline) % n_spline]
		var tangent = (p_next - p_prev).normalized()
		tangent.y = 0.0
		if tangent.length_squared() < 0.001:
			tangent = Vector3.FORWARD
		tangent = tangent.normalized()
		var right = tangent.cross(Vector3.UP).normalized()
		var rot_y = rad_to_deg(atan2(-tangent.x, -tangent.z))

		var wp_nearest = get_nearest_waypoint_index(p_curr)
		var species = _get_district_tree_species(wp_nearest)

		if s_idx % 8 == 0:
			# Left Tree at offset -12.5m
			var pos_l = p_curr - right * 12.5
			if _is_clear_of_spline(pos_l, 9.5):
				var tree_l = _build_realistic_tree(species, 6.5 + float(s_idx % 3) * 0.8, s_idx * 17)
				tree_l.position = pos_l
				tree_l.position.y = p_curr.y
				props_container.add_child(tree_l)

			# Right Tree at offset +12.5m
			var pos_r = p_curr + right * 12.5
			if _is_clear_of_spline(pos_r, 9.5):
				var tree_r = _build_realistic_tree(species, 6.2 + float((s_idx + 1) % 3) * 0.8, s_idx * 23)
				tree_r.position = pos_r
				tree_r.position.y = p_curr.y
				props_container.add_child(tree_r)

		elif s_idx % 8 == 4:
			# Modern street benches safely placed at ±11.2m
			var bench_pos = p_curr - right * 11.2
			if _is_clear_of_spline(bench_pos, 8.5):
				var bench = _build_street_bench()
				bench.position = bench_pos
				bench.position.y = p_curr.y + 0.10
				bench.rotation_degrees.y = rot_y + 90.0
				props_container.add_child(bench)

	# 3. Modern Street Light Posts (Positioned via Spline Frenet frame at strictly ±10.8m with arm extending inward)
	var lamp_interval = 5 # every ~30m along spline
	for s_idx in range(0, n_spline, lamp_interval):
		var p_curr = spline_samples[s_idx]
		var p_next = spline_samples[(s_idx + 1) % n_spline]
		var p_prev = spline_samples[(s_idx - 1 + n_spline) % n_spline]
		var tangent = (p_next - p_prev).normalized()
		tangent.y = 0.0
		if tangent.length_squared() < 0.001:
			tangent = Vector3.FORWARD
		tangent = tangent.normalized()
		var right = tangent.cross(Vector3.UP).normalized()
		var rot_y = rad_to_deg(atan2(-tangent.x, -tangent.z))

		for side in [-1.0, 1.0]:
			var lamp_pos = p_curr + right * (side * 10.8) + Vector3(0.0, 0.1, 0.0)
			# Strictly ensure pole base clears all road splines by >= 8.5m
			if not _is_clear_of_spline(lamp_pos, 8.5):
				continue

			var lamp = _build_procedural_streetlight()
			lamp.position = lamp_pos
			lamp.rotation_degrees.y = rot_y + (90.0 if side > 0 else -90.0)
			props_container.add_child(lamp)

	# 4. Deep Secondary City Blocks & Courtyards
	_build_secondary_city_blocks()

	# 5. Iconic Navigation Landmarks
	_build_city_landmarks()

	# 6. 360-Degree Distant City Skyline Ring (MultiMesh GPU Instanced)
	_build_distant_skyline_backdrop()

func _create_district_building(i: int, s: int, skyscrapers: Array, commercials: Array, theme_idx: int, side_name: String) -> Node3D:
	var b_node: Node3D = null
	if (i + s) % 2 == 0:
		var m_idx = (i * 2 + s) % skyscrapers.size()
		var glb_model = ModelCache.get_model(skyscrapers[m_idx])
		if glb_model:
			glb_model.scale = Vector3(8.5, 11.0, 8.5)
			_style_building(glb_model, theme_idx)
			var b_body = StaticBody3D.new()
			b_body.name = "Skyscraper%s_%d_%d" % [side_name, i, s]
			b_body.collision_layer = GameConstants.LAYER_WORLD
			b_body.add_child(glb_model)
			var col = CollisionShape3D.new()
			var b_shape = BoxShape3D.new()
			b_shape.size = Vector3(16.0, 45.0, 16.0)
			col.shape = b_shape
			col.position = Vector3(0, 22.5, 0)
			b_body.add_child(col)
			b_node = b_body
	else:
		var m_idx = (i * 2 + s) % commercials.size()
		var glb_model = ModelCache.get_model(commercials[m_idx])
		if glb_model:
			glb_model.scale = Vector3(7.5, 8.0, 7.5)
			_style_building(glb_model, theme_idx)
			var b_body = StaticBody3D.new()
			b_body.name = "Commercial%s_%d_%d" % [side_name, i, s]
			b_body.collision_layer = GameConstants.LAYER_WORLD
			b_body.add_child(glb_model)
			var col = CollisionShape3D.new()
			var b_shape = BoxShape3D.new()
			b_shape.size = Vector3(14.0, 28.0, 14.0)
			col.shape = b_shape
			col.position = Vector3(0, 14.0, 0)
			b_body.add_child(col)
			b_node = b_body

	if not b_node:
		var h = 32.0 + float((i + s) % 5) * 6.0
		b_node = _build_procedural_commercial_block(h, 16.0, theme_idx)

	return b_node

func _build_secondary_city_blocks() -> void:
	# Secondary buildings, logistics warehouses, parking courtyards filling interior space
	var block_configs = [
		# Downtown Financial interior (Z: -100 to -300, X: 50 to 180)
		{"pos": Vector3(80, 0, -80), "h": 58.0, "w": 26.0, "theme": 0},
		{"pos": Vector3(120, 0, -140), "h": 68.0, "w": 28.0, "theme": 2},
		{"pos": Vector3(100, 0, -220), "h": 52.0, "w": 24.0, "theme": 1},
		{"pos": Vector3(180, 0, -240), "h": 46.0, "w": 22.0, "theme": 5},
		# Commercial Promenade interior (X: 300 to 450, Z: -200 to 0)
		{"pos": Vector3(360, 0, -180), "h": 44.0, "w": 24.0, "theme": 1},
		{"pos": Vector3(400, 0, -100), "h": 38.0, "w": 26.0, "theme": 3},
		{"pos": Vector3(340, 0, -40), "h": 42.0, "w": 22.0, "theme": 4},
		# Logistics Hub freight yards (X: 100 to 300, Z: 200 to 380)
		{"pos": Vector3(240, 0, 240), "h": 22.0, "w": 34.0, "theme": 1},
		{"pos": Vector3(180, 0, 300), "h": 26.0, "w": 36.0, "theme": 5},
		{"pos": Vector3(120, 0, 340), "h": 20.0, "w": 32.0, "theme": 1},
		# Neon District interior (X: -150 to -300, Z: 100 to 260)
		{"pos": Vector3(-200, 0, 160), "h": 50.0, "w": 24.0, "theme": 2},
		{"pos": Vector3(-260, 0, 140), "h": 56.0, "w": 26.0, "theme": 0},
		{"pos": Vector3(-180, 0, 240), "h": 44.0, "w": 22.0, "theme": 2},
		# Marina Waterfront interior (X: -240 to -380, Z: -100 to -260)
		{"pos": Vector3(-300, 0, -160), "h": 36.0, "w": 24.0, "theme": 3},
		{"pos": Vector3(-320, 0, -220), "h": 32.0, "w": 22.0, "theme": 3},
		# Historic Old Town interior (X: -80 to -200, Z: -250 to -380)
		{"pos": Vector3(-140, 0, -280), "h": 34.0, "w": 20.0, "theme": 4},
		{"pos": Vector3(-160, 0, -340), "h": 30.0, "w": 22.0, "theme": 4},
		{"pos": Vector3(-120, 0, -180), "h": 38.0, "w": 20.0, "theme": 4},
		# Outer perimeter skyline anchors
		{"pos": Vector3(560, 0, -180), "h": 62.0, "w": 30.0, "theme": 0},
		{"pos": Vector3(540, 0, 60), "h": 48.0, "w": 28.0, "theme": 1},
		{"pos": Vector3(-480, 0, 180), "h": 46.0, "w": 26.0, "theme": 2},
		{"pos": Vector3(-500, 0, -180), "h": 38.0, "w": 24.0, "theme": 3}
	]

	for cfg in block_configs:
		if not _is_clear_of_spline(cfg["pos"], cfg["w"] * 0.5 + 8.5):
			continue

		var block = _build_procedural_commercial_block(cfg["h"], cfg["w"], cfg["theme"])
		block.position = cfg["pos"]
		props_container.add_child(block)

		var plaza = _build_urban_plaza_foundation(cfg["w"] + 4.0, cfg["w"] + 4.0, 0.0, 0.04)
		plaza.position = cfg["pos"]
		props_container.add_child(plaza)

		# Parked vehicles in parking courtyards
		var car_pos = cfg["pos"] + Vector3(cfg["w"] * 0.42, 0.05, cfg["w"] * 0.42)
		var parked_car = _build_parked_vehicle_prop()
		parked_car.position = car_pos
		props_container.add_child(parked_car)

func _build_city_landmarks() -> void:
	# 1. Apex Spire (110m Iconic Metropolitan Centerpiece in Downtown Central Plaza)
	var spire_pos = Vector3(55.0, 0.0, -180.0)
	if _is_clear_of_spline(spire_pos, 22.0):
		var spire_root = StaticBody3D.new()
		spire_root.name = "ApexSpireLandmark"
		spire_root.collision_layer = GameConstants.LAYER_WORLD

		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = Vector3(28.0, 115.0, 28.0)
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
		tower_box.size = Vector3(24.0, 85.0, 24.0)
		tower_mi.mesh = tower_box
		tower_mi.material_override = mat_spire
		tower_mi.position = Vector3(0, 42.5, 0)
		spire_root.add_child(tower_mi)

		var needle_mi = MeshInstance3D.new()
		var needle_cyl = CylinderMesh.new()
		needle_cyl.top_radius = 0.2
		needle_cyl.bottom_radius = 2.0
		needle_cyl.height = 32.0
		needle_mi.mesh = needle_cyl
		needle_mi.position = Vector3(0, 85.0 + 16.0, 0)
		var mat_needle = StandardMaterial3D.new()
		mat_needle.albedo_color = Color(0.85, 0.88, 0.92)
		mat_needle.metallic = 0.95
		mat_needle.roughness = 0.15
		needle_mi.material_override = mat_needle
		spire_root.add_child(needle_mi)

		var beacon = OmniLight3D.new()
		beacon.light_color = Color(0.0, 0.85, 1.0)
		beacon.light_energy = 4.0
		beacon.omni_range = 60.0
		beacon.position = Vector3(0, 118.0, 0)
		spire_root.add_child(beacon)

		spire_root.position = spire_pos
		props_container.add_child(spire_root)

	# 2. Historic Station Clocktower (Civic Square Landmark in Old Town at WP 28)
	var ct_pos = Vector3(-115.0, 0.0, -260.0)
	if _is_clear_of_spline(ct_pos, 15.0):
		var clocktower = StaticBody3D.new()
		clocktower.name = "HistoricClocktower"
		clocktower.collision_layer = GameConstants.LAYER_WORLD

		var ct_col = CollisionShape3D.new()
		var ct_shape = BoxShape3D.new()
		ct_shape.size = Vector3(12.0, 48.0, 12.0)
		ct_col.shape = ct_shape
		ct_col.position = Vector3(0, 24.0, 0)
		clocktower.add_child(ct_col)

		var mat_brick = StandardMaterial3D.new()
		mat_brick.albedo_color = Color(0.68, 0.35, 0.22)
		mat_brick.roughness = 0.92

		var ct_body = MeshInstance3D.new()
		var ct_box = BoxMesh.new()
		ct_box.size = Vector3(10.0, 42.0, 10.0)
		ct_body.mesh = ct_box
		ct_body.material_override = mat_brick
		ct_body.position = Vector3(0, 21.0, 0)
		clocktower.add_child(ct_body)

		var mat_clock = StandardMaterial3D.new()
		mat_clock.albedo_color = Color(1.0, 0.98, 0.88)
		mat_clock.emission_enabled = true
		mat_clock.emission = Color(1.0, 0.95, 0.80)
		mat_clock.emission_energy_multiplier = 1.5

		for side_rot in [0.0, 90.0, 180.0, 270.0]:
			var face = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 1.8
			cyl.bottom_radius = 1.8
			cyl.height = 0.2
			face.mesh = cyl
			face.material_override = mat_clock
			face.rotation_degrees = Vector3(90, side_rot, 0)
			face.position = Vector3(0, 36.0, 0) + Transform3D().rotated(Vector3.UP, deg_to_rad(side_rot)).basis.z * 5.05
			clocktower.add_child(face)

		clocktower.position = ct_pos
		props_container.add_child(clocktower)

func _build_distant_skyline_backdrop() -> void:
	# GPU MultiMesh perimeter ring creating 360° metropolitan horizon depth (zero empty space)
	var tower_count = 64
	var radius = 540.0

	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = BoxMesh.new()
	(multimesh.mesh as BoxMesh).size = Vector3(32.0, 100.0, 32.0)
	multimesh.instance_count = tower_count

	var mat_distant = StandardMaterial3D.new()
	mat_distant.albedo_color = Color(0.18, 0.24, 0.32)
	mat_distant.metallic = 0.50
	mat_distant.roughness = 0.60
	mat_distant.vertex_color_use_as_albedo = true

	for t in range(tower_count):
		var angle = (float(t) / float(tower_count)) * TAU
		var dist_var = radius + float(t % 7) * 35.0
		var tx = cos(angle) * dist_var
		var tz = sin(angle) * dist_var
		var scale_y = 0.7 + float((t * 7) % 11) * 0.12
		var height = 100.0 * scale_y

		var xf = Transform3D()
		xf = xf.scaled(Vector3(1.0 + float(t % 3) * 0.25, scale_y, 1.0 + float((t + 1) % 3) * 0.25))
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
		22, 23, 24, 25, 26:
			return "palm"       # Marina Waterfront
		17, 18, 19, 20, 21:
			return "cherry"     # Neon Entertainment Strip
		27, 28, 29, 30, 31:
			return "birch"      # Historic Old Town
		11, 12, 13, 14, 15, 16:
			return "pine"       # Skyway & Logistics Outskirts
		6, 7, 8, 9, 10:
			return "linden"     # Commercial District
		_:
			return "oak"        # Downtown Financial Core

func _build_realistic_tree(species: String, height: float, seed_val: int) -> Node3D:
	var root = StaticBody3D.new()
	root.name = "RealisticStreetTree_%s_%d" % [species, seed_val]
	root.collision_layer = GameConstants.LAYER_WORLD

	# Trunk Collider strictly protecting trunk core
	var col = CollisionShape3D.new()
	col.name = "TreeTrunkCollision"
	var col_shape = CylinderShape3D.new()
	col_shape.height = height * 0.75
	col_shape.radius = 0.35
	col.shape = col_shape
	col.position = Vector3(0, col_shape.height * 0.5, 0)
	root.add_child(col)

	# 1. Circular Stone Planter Curb on Sidewalk Verge
	var planter = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 1.25
	p_cyl.bottom_radius = 1.30
	p_cyl.height = 0.18
	planter.mesh = p_cyl
	planter.material_override = mat_curb
	planter.position = Vector3(0, 0.09, 0)
	root.add_child(planter)

	# 2. Rich Dark Loamy Soil
	var soil = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 1.15
	s_cyl.bottom_radius = 1.15
	s_cyl.height = 0.20
	soil.mesh = s_cyl
	var mat_soil = StandardMaterial3D.new()
	mat_soil.albedo_color = Color(0.14, 0.11, 0.09)
	mat_soil.roughness = 0.98
	soil.material_override = mat_soil
	soil.position = Vector3(0, 0.10, 0)
	root.add_child(soil)

	# 3. Organic Fluted Wood Trunk
	var trunk = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.18
	t_cyl.bottom_radius = 0.35
	t_cyl.height = height * 0.65
	trunk.mesh = t_cyl
	var mat_bark = StandardMaterial3D.new()
	if species == "birch":
		mat_bark.albedo_color = Color(0.78, 0.78, 0.75) # Authentic birch bark
	else:
		mat_bark.albedo_color = Color(0.24, 0.18, 0.13) # Natural dark wood bark
	mat_bark.roughness = 0.92
	trunk.material_override = mat_bark
	trunk.position = Vector3(0, t_cyl.height * 0.5, 0)
	root.add_child(trunk)

	# 4. Organic Branch Limbs (Angled outward from trunk fork)
	if species != "palm":
		for b_i in range(3):
			var b_ang = float(b_i) * (TAU / 3.0) + float(seed_val % 7) * 0.2
			var branch = MeshInstance3D.new()
			var b_mesh = CylinderMesh.new()
			b_mesh.top_radius = 0.08
			b_mesh.bottom_radius = 0.14
			b_mesh.height = 1.6
			branch.mesh = b_mesh
			branch.material_override = mat_bark
			branch.position = Vector3(cos(b_ang) * 0.45, t_cyl.height * 0.85, sin(b_ang) * 0.45)
			branch.rotation = Vector3(sin(b_ang) * deg_to_rad(28.0), b_ang, cos(b_ang) * deg_to_rad(-28.0))
			root.add_child(branch)

	# 5. Natural Organic Foliage Canopies (Zero SphereMesh blobs!)
	var leaf_color = Color(0.12, 0.36, 0.15) # Rich Forest Oak Green
	match species:
		"cherry":
			leaf_color = Color(0.88, 0.46, 0.62) # Japanese Cherry Blossom Pink
		"birch":
			leaf_color = Color(0.32, 0.55, 0.26) # Fresh Spring Sage Green (NOT yellow!)
		"pine":
			leaf_color = Color(0.08, 0.24, 0.12) # Deep Conifer Green
		"palm":
			leaf_color = Color(0.16, 0.45, 0.18) # Coastal Tropical Palm Green
		"linden":
			leaf_color = Color(0.18, 0.48, 0.18) # Lush Summer Commercial Green

	var mat_fol = StandardMaterial3D.new()
	mat_fol.albedo_color = leaf_color
	mat_fol.roughness = 0.82
	mat_fol.specular = 0.12
	mat_fol.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY

	if species == "pine":
		# Conical tiered conifer foliage layers
		var pine_tiers = [
			{"y": height * 0.55, "r": 2.2, "h": 1.6},
			{"y": height * 0.72, "r": 1.7, "h": 1.5},
			{"y": height * 0.88, "r": 1.2, "h": 1.4},
			{"y": height * 1.02, "r": 0.6, "h": 1.2}
		]
		for pt in pine_tiers:
			var fol = MeshInstance3D.new()
			var cone = CylinderMesh.new()
			cone.top_radius = 0.05
			cone.bottom_radius = pt["r"]
			cone.height = pt["h"]
			fol.mesh = cone
			fol.material_override = mat_fol
			fol.position = Vector3(0, pt["y"], 0)
			root.add_child(fol)

	elif species == "palm":
		# Tropical Palm: 8 radial drooping palm fronds
		var crown_y = t_cyl.height * 0.95
		for frond_i in range(8):
			var frond_ang = float(frond_i) * (TAU / 8.0)
			var frond = MeshInstance3D.new()
			var f_box = BoxMesh.new()
			f_box.size = Vector3(0.40, 0.05, 2.2)
			frond.mesh = f_box
			frond.material_override = mat_fol
			frond.rotation = Vector3(deg_to_rad(-24.0), frond_ang, 0)
			frond.position = Vector3(cos(frond_ang) * 0.8, crown_y, sin(frond_ang) * 0.8)
			root.add_child(frond)

	else:
		# Multi-Tiered Organic Faceted Foliage Clusters
		var clusters = [
			{"pos": Vector3(0.0, height * 0.88, 0.0), "sx": 2.6, "sy": 1.8, "sz": 2.6, "rot": 0.0},
			{"pos": Vector3(-0.9, height * 0.74, 0.5), "sx": 1.9, "sy": 1.5, "sz": 1.9, "rot": 42.0},
			{"pos": Vector3(0.85, height * 0.76, -0.4), "sx": 2.0, "sy": 1.5, "sz": 2.0, "rot": -35.0},
			{"pos": Vector3(0.2, height * 1.02, 0.2), "sx": 1.8, "sy": 1.6, "sz": 1.8, "rot": 18.0},
			{"pos": Vector3(0.4, height * 0.82, 0.8), "sx": 1.7, "sy": 1.4, "sz": 1.7, "rot": 75.0}
		]
		for c in clusters:
			var fol = MeshInstance3D.new()
			var poly = CylinderMesh.new()
			poly.top_radius = c["sx"] * 0.42
			poly.bottom_radius = c["sx"] * 0.50
			poly.height = c["sy"]
			poly.radial_segments = 7 # Organic faceted geometry
			fol.mesh = poly
			fol.material_override = mat_fol
			fol.position = c["pos"]
			fol.rotation_degrees.y = c["rot"]
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

func _build_urban_plaza_foundation(width: float, depth: float, base_y: float = 0.0, top_y: float = 0.04) -> Node3D:
	var root = StaticBody3D.new()
	root.name = "UrbanPlazaFoundation"
	root.collision_layer = GameConstants.LAYER_WORLD

	var total_h = maxf(0.12, top_y - base_y)
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

	# 1. Ground Level Retail Podium (4.0m height)
	var podium_mi = MeshInstance3D.new()
	var podium_box = BoxMesh.new()
	podium_box.size = Vector3(width, 4.0, width * 0.95)
	podium_mi.mesh = podium_box
	podium_mi.material_override = mat_podium
	podium_mi.position = Vector3(0, 2.0, 0)
	root.add_child(podium_mi)

	var shop_mi = MeshInstance3D.new()
	var shop_box = BoxMesh.new()
	shop_box.size = Vector3(width + 0.1, 2.6, width * 0.95 + 0.1)
	shop_mi.mesh = shop_box
	shop_mi.material_override = mat_glass
	shop_mi.position = Vector3(0, 1.6, 0)
	root.add_child(shop_mi)

	# 2. Main High-Rise Tower Body
	var body_h = height - 4.0
	var body_w = width * 0.90
	var body_mi = MeshInstance3D.new()
	var body_box = BoxMesh.new()
	body_box.size = Vector3(body_w, body_h, body_w * 0.92)
	body_mi.mesh = body_box
	body_mi.material_override = mat_wall
	body_mi.position = Vector3(0, 4.0 + body_h * 0.5, 0)
	root.add_child(body_mi)

	# 3. Ribbon Glass Windows Across Tower Floors
	var floors = int(body_h / 3.8)
	for f in range(floors):
		var w_mi = MeshInstance3D.new()
		var w_box = BoxMesh.new()
		w_box.size = Vector3(body_w + 0.12, 1.8, body_w * 0.92 + 0.12)
		w_mi.mesh = w_box
		w_mi.material_override = mat_glass
		w_mi.position = Vector3(0, 4.0 + float(f) * 3.8 + 2.0, 0)
		root.add_child(w_mi)

	# 4. Rooftop Mechanical Bulkhead & Architectural Antenna
	var roof_y = 4.0 + body_h
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
	col_shape.height = 6.8
	col_shape.radius = 0.16
	col.shape = col_shape
	col.position = Vector3(0, 3.4, 0)
	root.add_child(col)

	var mat_pole = StandardMaterial3D.new()
	mat_pole.albedo_color = Color(0.35, 0.38, 0.42)
	mat_pole.metallic = 0.85
	mat_pole.roughness = 0.3

	var post_mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.10
	cyl.bottom_radius = 0.14
	cyl.height = 6.8
	post_mi.mesh = cyl
	post_mi.material_override = mat_pole
	post_mi.position = Vector3(0, 3.4, 0)
	root.add_child(post_mi)

	var arm_mi = MeshInstance3D.new()
	var arm_cyl = CylinderMesh.new()
	arm_cyl.top_radius = 0.07
	arm_cyl.bottom_radius = 0.07
	arm_cyl.height = 2.4
	arm_mi.mesh = arm_cyl
	arm_mi.material_override = mat_pole
	arm_mi.rotation_degrees.z = 90.0
	arm_mi.position = Vector3(1.15, 6.7, 0)
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
	lamp_mi.position = Vector3(2.2, 6.6, 0)
	root.add_child(lamp_mi)

	return root
