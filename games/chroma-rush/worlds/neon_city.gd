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
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 color_wall_primary : source_color;
uniform vec4 color_wall_secondary : source_color;
uniform vec4 color_window : source_color;
uniform vec4 color_trim : source_color;

uniform float wall_metallic : hint_range(0.0, 1.0) = 0.05;
uniform float wall_roughness : hint_range(0.0, 1.0) = 0.82;
uniform float window_metallic : hint_range(0.0, 1.0) = 0.85;
uniform float window_roughness : hint_range(0.0, 1.0) = 0.08;

void fragment() {
	vec4 tex = texture(albedo_texture, UV);

	bool is_window = (tex.a > 0.5 && tex.r < 0.18 && tex.g < 0.18 && tex.b < 0.18 && length(tex.rgb) > 0.04);
	bool is_teal_base = (tex.g > 0.48 && tex.r < 0.42);
	bool is_orange_band = (tex.r > 0.88 && tex.g < 0.66 && tex.b < 0.45);

	if (tex.a < 0.1 || length(tex.rgb) < 0.04) {
		// Missing texture fallback: use vibrant primary wall color directly
		ALBEDO = color_wall_primary.rgb;
		METALLIC = wall_metallic;
		ROUGHNESS = wall_roughness;
	} else if (is_window) {

		ALBEDO = color_window.rgb;
		METALLIC = window_metallic;
		ROUGHNESS = window_roughness;
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
		"wall_primary": Color(0.28, 0.50, 0.75),
		"wall_secondary": Color(0.78, 0.82, 0.86),
		"window": Color(0.12, 0.28, 0.48),
		"trim": Color(0.90, 0.93, 0.96),
		"wall_metallic": 0.65,
		"wall_roughness": 0.20,
		"window_metallic": 0.90,
		"window_roughness": 0.05,
		"window_clearcoat": 1.0,
		"name": "sapphire_glass"
	},
	# 1. Warm Limestone & Dark Bronze Executive Center
	{
		"wall_primary": Color(0.88, 0.85, 0.80),
		"wall_secondary": Color(0.35, 0.32, 0.28),
		"window": Color(0.20, 0.18, 0.16),
		"trim": Color(0.55, 0.45, 0.32),
		"wall_metallic": 0.02,
		"wall_roughness": 0.85,
		"window_metallic": 0.75,
		"window_roughness": 0.12,
		"window_clearcoat": 0.8,
		"name": "limestone_bronze"
	},
	# 2. Obsidian Tech Tower (Sleek slate composite with vibrant cyan trim)
	{
		"wall_primary": Color(0.35, 0.38, 0.42),
		"wall_secondary": Color(0.22, 0.24, 0.26),
		"window": Color(0.15, 0.45, 0.55),
		"trim": Color(0.20, 0.85, 0.95),
		"wall_metallic": 0.40,
		"wall_roughness": 0.45,
		"window_metallic": 0.88,
		"window_roughness": 0.08,
		"window_clearcoat": 0.9,
		"name": "obsidian_tech"
	},
	# 3. Emerald Eco-Terrace Tower (Crisp Scandinavian White Stone & Cedar Wood)
	{
		"wall_primary": Color(0.94, 0.95, 0.94),
		"wall_secondary": Color(0.55, 0.38, 0.24),
		"window": Color(0.15, 0.35, 0.22),
		"trim": Color(0.28, 0.60, 0.36),
		"wall_metallic": 0.05,
		"wall_roughness": 0.72,
		"window_metallic": 0.65,
		"window_roughness": 0.15,
		"window_clearcoat": 0.7,
		"name": "eco_terrace"
	},
	# 4. Terracotta & Patina Copper Metro Tower
	{
		"wall_primary": Color(0.75, 0.42, 0.28),
		"wall_secondary": Color(0.38, 0.24, 0.18),
		"window": Color(0.22, 0.20, 0.16),
		"trim": Color(0.40, 0.65, 0.55),
		"wall_metallic": 0.15,
		"wall_roughness": 0.88,
		"window_metallic": 0.60,
		"window_roughness": 0.18,
		"window_clearcoat": 0.6,
		"name": "terracotta_copper"
	},
	# 5. Titanium Modernist High-Rise (Brushed aerospace metal & glass)
	{
		"wall_primary": Color(0.75, 0.78, 0.82),
		"wall_secondary": Color(0.32, 0.36, 0.40),
		"window": Color(0.12, 0.15, 0.20),
		"trim": Color(0.90, 0.93, 0.96),
		"wall_metallic": 0.85,
		"wall_roughness": 0.30,
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

func _build_track_waypoints() -> Array[Vector3]:
	if waypoints.is_empty():
		generate_waypoints()
	return waypoints

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
		Vector3(-80, 0, -100),    # 29 Historic Masonry Avenue
		Vector3(-45, 0, 80),      # 30 Cathedral Park South
		Vector3(0, 0, 75)         # 31 Grand Boulevard South Approach (straight into WP 0)
	]
	for p in raw_points:
		waypoints.append(p)

	# Orient player spawn strictly facing forward down North Financial Avenue
	var p0 = waypoints[0]
	var p1 = waypoints[1]
	var fwd = (p1 - p0).normalized()
	player_spawn_transform = Transform3D().looking_at(fwd, Vector3.UP)
	player_spawn_transform.origin = p0 + Vector3(0.0, 0.20, 0.0)

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

func setup_ground_plane() -> void:
	var ground = StaticBody3D.new()
	ground.name = "CityGroundPlane"
	ground.collision_layer = GameConstants.LAYER_WORLD
	ground.position = Vector3(0, -0.35, 0)

	var mi = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(3200, 3200)
	mi.mesh = plane_mesh

	var mat_ground = StandardMaterial3D.new()
	mat_ground.albedo_color = Color(0.18, 0.20, 0.23) # Deep dark metropolitan asphalt/slate urban bed
	mat_ground.roughness = 0.90
	mat_ground.metallic = 0.05
	mi.material_override = mat_ground
	ground.add_child(mi)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(3200, 1.0, 3200)
	col.shape = shape
	col.position = Vector3(0, -0.5, 0)
	ground.add_child(col)

	props_container.add_child(ground)

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

func _is_clear_of_spline(pt: Vector3, min_clearance: float, ignore_s_idx: int = -1, ignore_window: int = 0) -> bool:
	var pt_2d = Vector2(pt.x, pt.z)
	var pts_to_check = spline_samples if not spline_samples.is_empty() else waypoints
	var n_s = pts_to_check.size()
	if n_s < 2:
		return true
	for i in range(n_s):
		if ignore_s_idx >= 0 and ignore_window > 0:
			var diff = absi(i - ignore_s_idx)
			var cyclic_diff = mini(diff, n_s - diff)
			if cyclic_diff <= ignore_window:
				continue
		var s1 = pts_to_check[i]
		var s2 = pts_to_check[(i + 1) % n_s]
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
	var residential_paths = [
		"res://assets/models/environment/building_a.glb",
		"res://assets/models/environment/building_b.glb",
		"res://assets/models/environment/building_c.glb",
		"res://assets/models/environment/building_d.glb"
	]

	var n_spline = spline_samples.size()
	if n_spline < 10:
		return

	# 1. Primary Street-Facing City Blocks flanking both sides of the boulevard
	var building_interval = 8
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

		# Build buildings on BOTH sides to form an authentic dense metropolitan streetwall
		for side in [-1.0, 1.0]:
			var setback = 25.0 + float((s_idx) % 3) * 2.0
			var b_pos = p_curr + right * (side * setback)
			b_pos.y = p_curr.y

			if not _is_clear_of_spline(b_pos, 16.0, s_idx, 6):
				continue

			var theme_idx = (s_idx * 3 + wp_nearest + (1 if side > 0 else 0)) % ARCHITECTURAL_THEMES.size()
			var side_str = "Left" if side < 0 else "Right"
			var b_node = _create_district_building(wp_nearest, s_idx, skyscraper_paths, commercial_paths, residential_paths, theme_idx, side_str)
			if b_node:
				b_node.position = b_pos
				b_node.rotation_degrees.y = rot_y + (90.0 if side < 0 else -90.0)
				props_container.add_child(b_node)

			_build_urban_block_parcel(p_curr, right * side, setback, b_pos, rot_y + (90.0 if side < 0 else -90.0), wp_nearest, s_idx + (100 if side > 0 else 0))

	# 2. Dense mature street trees along both sidewalk verges
	var tree_interval = 8
	for s_idx in range(0, n_spline, tree_interval):
		var p_curr = spline_samples[s_idx]
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

		var wp_nearest = get_nearest_waypoint_index(p_curr)
		var species = _get_district_tree_species(wp_nearest)
		for t_side in [-1.0, 1.0]:
			var pos_t = p_curr + right * (t_side * 9.2)
			if _is_clear_of_spline(pos_t, 8.0):
				var tree = _build_realistic_tree(species, 9.0, s_idx * 17 + (50 if t_side > 0 else 0))
				tree.position = pos_t
				tree.position.y = p_curr.y
				props_container.add_child(tree)

	# 3. Modern Street Light Posts along curbs
	var lamp_interval = 12
	for s_idx in range(4, n_spline, lamp_interval):
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

		for l_side in [-1.0, 1.0]:
			var lamp_pos = p_curr + right * (l_side * 8.6)
			if _is_clear_of_spline(lamp_pos, 7.8):
				var lamp = _build_procedural_streetlight()
				lamp.position = lamp_pos
				lamp.rotation_degrees.y = rot_y + (90.0 if l_side > 0 else -90.0)
				props_container.add_child(lamp)

	# 4. Secondary City Blocks & District Interior Hubs (Fill inner plazas, vistas, parking)
	_build_secondary_city_blocks()

	# 5. Iconic Navigation Landmarks
	_build_city_landmarks()

	# 6. 360-Degree Distant City Skyline Ring (Towering high-rises on horizon)
	_build_distant_skyline_backdrop()

func _create_district_building(i: int, s: int, skyscrapers: Array, commercials: Array, residentials: Array, theme_idx: int, side_name: String) -> Node3D:
	var b_node: Node3D = null
	var pick_type = (i + s) % 3

	# District-specific architectural selection
	if (i <= 5 or (i >= 17 and i <= 21)) and pick_type != 2:
		# CBD & Neon Strip: High-Rise Skyscraper Glass Towers
		var m_idx = (i * 2 + s) % skyscrapers.size()
		var glb_model = ModelCache.get_model(skyscrapers[m_idx])
		if glb_model:
			var sc = 5.8 + float((i + s) % 3) * 0.5
			glb_model.scale = Vector3(sc, sc, sc)
			_style_building(glb_model, theme_idx)
			var b_body = StaticBody3D.new()
			b_body.name = "Skyscraper%s_%d_%d" % [side_name, i, s]
			b_body.collision_layer = GameConstants.LAYER_WORLD
			b_body.add_child(glb_model)
			var col = CollisionShape3D.new()
			var b_shape = BoxShape3D.new()
			b_shape.size = Vector3(18.0, 56.0, 18.0)
			col.shape = b_shape
			col.position = Vector3(0, 28.0, 0)
			b_body.add_child(col)
			b_node = b_body
	elif (i >= 22 and i <= 31) and pick_type == 1:
		# Marina & Old Town: Mid-Rise Classical / Residential Masonry
		var m_idx = (i * 2 + s) % residentials.size()
		var glb_model = ModelCache.get_model(residentials[m_idx])
		if glb_model:
			var sc = 5.2 + float((i + s) % 3) * 0.4
			glb_model.scale = Vector3(sc, sc, sc)
			_style_building(glb_model, theme_idx)
			var b_body = StaticBody3D.new()
			b_body.name = "Residential%s_%d_%d" % [side_name, i, s]
			b_body.collision_layer = GameConstants.LAYER_WORLD
			b_body.add_child(glb_model)
			var col = CollisionShape3D.new()
			var b_shape = BoxShape3D.new()
			b_shape.size = Vector3(16.0, 36.0, 16.0)
			col.shape = b_shape
			col.position = Vector3(0, 18.0, 0)
			b_body.add_child(col)
			b_node = b_body
	else:
		# Commercial Promenade & Mixed-Use Districts
		var m_idx = (i * 2 + s) % commercials.size()
		var glb_model = ModelCache.get_model(commercials[m_idx])
		if glb_model:
			var sc = 5.2 + float((i + s) % 3) * 0.4
			glb_model.scale = Vector3(sc, sc, sc)
			_style_building(glb_model, theme_idx)
			var b_body = StaticBody3D.new()
			b_body.name = "Commercial%s_%d_%d" % [side_name, i, s]
			b_body.collision_layer = GameConstants.LAYER_WORLD
			b_body.add_child(glb_model)
			var col = CollisionShape3D.new()
			var b_shape = BoxShape3D.new()
			b_shape.size = Vector3(16.0, 36.0, 16.0)
			col.shape = b_shape
			col.position = Vector3(0, 18.0, 0)
			b_body.add_child(col)
			b_node = b_body

	if not b_node:
		var fallback_path = commercials[0] if commercials.size() > 0 else skyscrapers[0]
		var fallback_glb = ModelCache.get_model(fallback_path)
		if fallback_glb:
			var sc = 5.2
			fallback_glb.scale = Vector3(sc, sc, sc)
			_style_building(fallback_glb, theme_idx)
			var b_body = StaticBody3D.new()
			b_body.name = "AuthoredFallback%s_%d_%d" % [side_name, i, s]
			b_body.collision_layer = GameConstants.LAYER_WORLD
			b_body.add_child(fallback_glb)
			var col = CollisionShape3D.new()
			var b_shape = BoxShape3D.new()
			b_shape.size = Vector3(16.0, 36.0, 16.0)
			col.shape = b_shape
			col.position = Vector3(0, 18.0, 0)
			b_body.add_child(col)
			b_node = b_body
		else:
			var h = 42.0 + float((i + s) % 5) * 6.0
			b_node = _build_procedural_commercial_block(h, 20.0, theme_idx)

	return b_node

func _build_secondary_city_blocks() -> void:
	# Secondary buildings, logistics warehouses, parking courtyards filling interior space
	var block_configs = [
		# 1. Downtown Financial Core Interior (WP 0-5)
		{"pos": Vector3(80, 0, -80), "h": 68.0, "w": 26.0, "theme": 0},
		{"pos": Vector3(120, 0, -140), "h": 78.0, "w": 28.0, "theme": 2},
		{"pos": Vector3(100, 0, -220), "h": 58.0, "w": 24.0, "theme": 1},
		{"pos": Vector3(180, 0, -240), "h": 52.0, "w": 22.0, "theme": 5},
		{"pos": Vector3(140, 0, -80), "h": 62.0, "w": 24.0, "theme": 0},
		{"pos": Vector3(70, 0, -280), "h": 54.0, "w": 22.0, "theme": 2},
		{"pos": Vector3(220, 0, -180), "h": 48.0, "w": 26.0, "theme": 1},

		# 2. Commercial Promenade & Retail Center (WP 6-10)
		{"pos": Vector3(360, 0, -180), "h": 46.0, "w": 24.0, "theme": 1},
		{"pos": Vector3(400, 0, -100), "h": 42.0, "w": 26.0, "theme": 3},
		{"pos": Vector3(340, 0, -40), "h": 44.0, "w": 22.0, "theme": 4},
		{"pos": Vector3(440, 0, -160), "h": 38.0, "w": 24.0, "theme": 1},
		{"pos": Vector3(320, 0, -120), "h": 40.0, "w": 22.0, "theme": 3},
		{"pos": Vector3(420, 0, 40), "h": 36.0, "w": 26.0, "theme": 4},
		{"pos": Vector3(360, 0, 60), "h": 34.0, "w": 22.0, "theme": 1},

		# 3. Logistics Hub Freight Yards & Skyway Underpass (WP 11-16)
		{"pos": Vector3(240, 0, 240), "h": 22.0, "w": 34.0, "theme": 1},
		{"pos": Vector3(180, 0, 300), "h": 26.0, "w": 36.0, "theme": 5},
		{"pos": Vector3(120, 0, 340), "h": 20.0, "w": 32.0, "theme": 1},
		{"pos": Vector3(280, 0, 320), "h": 24.0, "w": 30.0, "theme": 5},
		{"pos": Vector3(80, 0, 380), "h": 22.0, "w": 28.0, "theme": 1},
		{"pos": Vector3(200, 0, 380), "h": 18.0, "w": 34.0, "theme": 5},

		# 4. Neon District Interior & Cyber Concourse (WP 17-21)
		{"pos": Vector3(-200, 0, 160), "h": 54.0, "w": 24.0, "theme": 2},
		{"pos": Vector3(-260, 0, 140), "h": 60.0, "w": 26.0, "theme": 0},
		{"pos": Vector3(-180, 0, 240), "h": 48.0, "w": 22.0, "theme": 2},
		{"pos": Vector3(-140, 0, 200), "h": 44.0, "w": 24.0, "theme": 0},
		{"pos": Vector3(-220, 0, 80), "h": 50.0, "w": 22.0, "theme": 2},
		{"pos": Vector3(-280, 0, 220), "h": 46.0, "w": 24.0, "theme": 0},

		# 5. Marina Waterfront Coastal District (WP 22-26)
		{"pos": Vector3(-300, 0, -160), "h": 36.0, "w": 24.0, "theme": 3},
		{"pos": Vector3(-320, 0, -220), "h": 32.0, "w": 22.0, "theme": 3},
		{"pos": Vector3(-240, 0, -180), "h": 38.0, "w": 24.0, "theme": 3},
		{"pos": Vector3(-260, 0, -260), "h": 34.0, "w": 22.0, "theme": 3},
		{"pos": Vector3(-340, 0, -120), "h": 30.0, "w": 20.0, "theme": 3},

		# 6. Historic Old Town Interior (WP 27-31)
		{"pos": Vector3(-140, 0, -280), "h": 34.0, "w": 20.0, "theme": 4},
		{"pos": Vector3(-160, 0, -340), "h": 30.0, "w": 22.0, "theme": 4},
		{"pos": Vector3(-120, 0, -180), "h": 38.0, "w": 20.0, "theme": 4},
		{"pos": Vector3(-160, 0, -220), "h": 32.0, "w": 20.0, "theme": 4},
		{"pos": Vector3(-100, 0, -140), "h": 36.0, "w": 22.0, "theme": 4},

		# 7. Metropolitan Outer Anchors (Filling all distant vistas)
		{"pos": Vector3(560, 0, -180), "h": 72.0, "w": 30.0, "theme": 0},
		{"pos": Vector3(540, 0, 60), "h": 58.0, "w": 28.0, "theme": 1},
		{"pos": Vector3(-480, 0, 180), "h": 56.0, "w": 26.0, "theme": 2},
		{"pos": Vector3(-500, 0, -180), "h": 44.0, "w": 24.0, "theme": 3},
		{"pos": Vector3(480, 0, -320), "h": 64.0, "w": 28.0, "theme": 0},
		{"pos": Vector3(-380, 0, 340), "h": 50.0, "w": 24.0, "theme": 2}
	]

	for cfg in block_configs:
		# Strict clearance from all spline samples: width/2 + road_half_w(7.5) + sidewalk(3.5) + buffer(2.5) = width/2 + 13.5
		if not _is_clear_of_spline(cfg["pos"], cfg["w"] * 0.5 + 13.5):
			continue

		var is_tall = cfg["h"] > 45.0
		var model_list = [
			"res://assets/models/environment/building_skyscraper_a.glb",
			"res://assets/models/environment/building_skyscraper_b.glb",
			"res://assets/models/environment/building_skyscraper_c.glb",
			"res://assets/models/environment/building_skyscraper_d.glb",
			"res://assets/models/environment/building_skyscraper_e.glb"
		] if is_tall else [
			"res://assets/models/environment/building_comm_a.glb",
			"res://assets/models/environment/building_comm_b.glb",
			"res://assets/models/environment/building_comm_c.glb",
			"res://assets/models/environment/building_comm_d.glb",
			"res://assets/models/environment/building_comm_e.glb",
			"res://assets/models/environment/building_comm_f.glb"
		]
		var m_path = model_list[cfg["theme"] % model_list.size()]
		var glb = ModelCache.get_model(m_path)
		var block: Node3D = null
		if glb:
			var sc = 5.8 if is_tall else 4.8
			glb.scale = Vector3(sc, sc, sc)
			_style_building(glb, cfg["theme"])
			var b_body = StaticBody3D.new()
			b_body.name = "SecondaryBlock_%d" % cfg["theme"]
			b_body.collision_layer = GameConstants.LAYER_WORLD
			b_body.add_child(glb)
			var col = CollisionShape3D.new()
			var b_shape = BoxShape3D.new()
			b_shape.size = Vector3(cfg["w"], cfg["h"], cfg["w"])
			col.shape = b_shape
			col.position = Vector3(0, cfg["h"] * 0.5, 0)
			b_body.add_child(col)
			block = b_body
		else:
			block = _build_procedural_commercial_block(cfg["h"], cfg["w"], cfg["theme"])
		block.position = cfg["pos"]
		props_container.add_child(block)

		var plaza = _build_urban_plaza_foundation(cfg["w"] + 6.0, cfg["w"] + 6.0, 0.0, 0.04)
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
	# 360-degree monumental skyline silhouette instanced from real skyscraper models
	var skyscraper_models = [
		"res://assets/models/environment/building_skyscraper_a.glb",
		"res://assets/models/environment/building_skyscraper_b.glb",
		"res://assets/models/environment/building_skyscraper_c.glb",
		"res://assets/models/environment/building_skyscraper_d.glb",
		"res://assets/models/environment/building_skyscraper_e.glb"
	]
	var tower_count = 32
	var radius = 450.0

	for i in range(tower_count):
		var angle = (float(i) / float(tower_count)) * TAU
		var m_path = skyscraper_models[i % skyscraper_models.size()]
		var dist = radius + float((i * 13) % 7) * 20.0
		var pos = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		var sc = 22.0 + float(i % 5) * 4.0
		var rot_y = float((i * 45) % 360)
		var b_glb = ModelCache.get_model(m_path)
		if b_glb:
			b_glb.scale = Vector3(sc, sc * 1.6, sc)
			b_glb.position = pos
			b_glb.rotation_degrees.y = rot_y
			_style_building(b_glb, i % ARCHITECTURAL_THEMES.size())
			props_container.add_child(b_glb)

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

	# Trunk Collider strictly protecting trunk core on the sidewalk plaza
	var col = CollisionShape3D.new()
	col.name = "TreeTrunkCollision"
	var col_shape = CylinderShape3D.new()
	col_shape.height = height * 0.85
	col_shape.radius = 0.35
	col.shape = col_shape
	col.position = Vector3(0, col_shape.height * 0.5, 0)
	root.add_child(col)

	# 1. Circular Stone Planter Curb on Sidewalk Verge
	var planter = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 1.35
	p_cyl.bottom_radius = 1.40
	p_cyl.height = 0.20
	planter.mesh = p_cyl
	planter.material_override = mat_curb
	planter.position = Vector3(0, 0.10, 0)
	root.add_child(planter)

	# 2. Rich Dark Loamy Soil
	var soil = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 1.25
	s_cyl.bottom_radius = 1.25
	s_cyl.height = 0.22
	soil.mesh = s_cyl
	var mat_soil = StandardMaterial3D.new()
	mat_soil.albedo_color = Color(0.14, 0.11, 0.09)
	mat_soil.roughness = 0.98
	soil.material_override = mat_soil
	soil.position = Vector3(0, 0.11, 0)
	root.add_child(soil)

	# 3. Authentic 3D Tree Mesh Asset (all 6 distinct species)
	var tree_path = "res://assets/models/environment/tree_oak.glb"
	match species:
		"palm": tree_path = "res://assets/models/environment/tree_palm.glb"
		"pine": tree_path = "res://assets/models/environment/tree_pine.glb"
		"birch": tree_path = "res://assets/models/environment/tree_detailed.glb"
		"cherry": tree_path = "res://assets/models/environment/tree_fat.glb"
		"linden": tree_path = "res://assets/models/environment/tree_tall.glb"
		_: tree_path = "res://assets/models/environment/tree_oak.glb"

	var tree_model = ModelCache.get_model(tree_path)
	if tree_model:
		tree_model.name = "AuthoredTree"
		var sc = height * 0.65
		tree_model.scale = Vector3(sc, sc, sc)
		tree_model.rotation_degrees.y = float(seed_val * 47 % 360)
		tree_model.position = Vector3(0, 0.1, 0)
		_style_tree_materials(tree_model, species)
		root.add_child(tree_model)

	# 4. Lush flowering shrub bushes around base in planter
	var mat_bush = StandardMaterial3D.new()
	mat_bush.albedo_color = Color(0.20, 0.46, 0.18)
	mat_bush.roughness = 0.85
	for b_i in range(3):
		var b_angle = deg_to_rad(float(b_i * 120 + (seed_val * 31 % 60)))
		var b_rad = 0.75
		var bush = MeshInstance3D.new()
		var b_sphere = SphereMesh.new()
		b_sphere.radius = 0.26
		b_sphere.height = 0.36
		bush.mesh = b_sphere
		bush.material_override = mat_bush
		bush.position = Vector3(cos(b_angle) * b_rad, 0.22, sin(b_angle) * b_rad)
		root.add_child(bush)

	return root

func _style_tree_materials(tree_model: Node3D, species: String) -> void:
	if not tree_model:
		return
	var mat_bark = StandardMaterial3D.new()
	mat_bark.albedo_color = Color(0.24, 0.17, 0.11)
	mat_bark.roughness = 0.95
	mat_bark.metallic = 0.02

	var mat_leaves = StandardMaterial3D.new()
	mat_leaves.roughness = 0.72
	mat_leaves.metallic = 0.0
	match species:
		"cherry":
			mat_leaves.albedo_color = Color(0.92, 0.48, 0.65)
		"palm":
			mat_leaves.albedo_color = Color(0.18, 0.48, 0.16)
		"pine":
			mat_leaves.albedo_color = Color(0.10, 0.30, 0.14)
		_: # oak, birch, linden
			mat_leaves.albedo_color = Color(0.16, 0.44, 0.18)

	var meshes: Array[MeshInstance3D] = []
	_gather_meshes(tree_model, meshes)
	for mi in meshes:
		if mi.mesh:
			var sc = mi.mesh.get_surface_count()
			for s in range(sc):
				var orig_mat = mi.mesh.surface_get_material(s)
				var mat_name = orig_mat.resource_name.to_lower() if orig_mat else ""
				if "bark" in mat_name or "wood" in mat_name or (species != "palm" and s == 1) or (species == "palm" and s == 0):
					mi.set_surface_override_material(s, mat_bark)
				else:
					mi.set_surface_override_material(s, mat_leaves)

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

static var _cached_colormap_tex: Texture2D = null
static var _cached_theme_materials: Dictionary = {}

static func _get_theme_material(theme_idx: int) -> StandardMaterial3D:
	var idx = theme_idx % ARCHITECTURAL_THEMES.size()
	if _cached_theme_materials.has(idx):
		return _cached_theme_materials[idx]
	if not _cached_colormap_tex:
		_cached_colormap_tex = load("res://assets/models/environment/Textures/colormap.png")
	var theme = ARCHITECTURAL_THEMES[idx]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = theme["wall_primary"]
	mat.metallic = theme["wall_metallic"]
	mat.roughness = theme["wall_roughness"]
	if _cached_colormap_tex:
		mat.albedo_texture = _cached_colormap_tex
	_cached_theme_materials[idx] = mat
	return mat

func _style_building(building: Node3D, theme_idx: int) -> void:
	if not building:
		return
	var mat = _get_theme_material(theme_idx)
	var meshes: Array[MeshInstance3D] = []
	_gather_meshes(building, meshes)
	for mi in meshes:
		mi.material_override = mat


func _gather_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_gather_meshes(child, result)

func _build_urban_plaza_foundation_node(b_pos: Vector3, b_rot_y: float) -> Node3D:
	if not mat_sidewalk:
		_init_materials()
	var plaza = StaticBody3D.new()
	plaza.name = "UrbanPlazaFoundation"
	plaza.collision_layer = GameConstants.LAYER_WORLD
	plaza.position = b_pos
	plaza.rotation_degrees.y = b_rot_y

	var plinth = MeshInstance3D.new()
	plinth.name = "PlinthFoundation"
	var plinth_box = BoxMesh.new()
	plinth_box.size = Vector3(30.0, 0.22, 30.0)
	plinth.mesh = plinth_box
	var mat_plinth = StandardMaterial3D.new()
	mat_plinth.albedo_color = Color(0.24, 0.26, 0.28)
	mat_plinth.roughness = 0.82
	plinth.material_override = mat_plinth
	plinth.position = Vector3(0.0, 0.11, 0.0)
	plaza.add_child(plinth)

	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(30.0, 0.4, 30.0)
	col.shape = col_box
	col.position = Vector3(0.0, 0.0, 0.0)
	plaza.add_child(col)
	return plaza

func _build_urban_block_parcel(p_curr: Vector3, right_dir: Vector3, setback: float, b_pos: Vector3, b_rot_y: float, wp_idx: int, seed_val: int) -> void:
	if not mat_sidewalk or not mat_asphalt:
		_init_materials()
	var parcel_root = Node3D.new()
	parcel_root.name = "UrbanParcel_%d_%d" % [wp_idx, seed_val]
	parcel_root.position = Vector3(b_pos.x, b_pos.y, b_pos.z)
	parcel_root.rotation_degrees.y = b_rot_y

	# 1. Main Plaza Plinth under building (30m x 0.22m x 30m)
	var plinth = MeshInstance3D.new()
	plinth.name = "PlinthFoundation"
	var plinth_box = BoxMesh.new()
	plinth_box.size = Vector3(30.0, 0.22, 30.0)
	plinth.mesh = plinth_box
	var mat_plinth = StandardMaterial3D.new()
	mat_plinth.albedo_color = Color(0.24, 0.26, 0.28)
	mat_plinth.roughness = 0.82
	plinth.material_override = mat_plinth
	plinth.position = Vector3(0.0, 0.11, 0.0)
	parcel_root.add_child(plinth)

	# 2. Pedestrian Plaza Promenade connecting building frontage to road sidewalk without crossing road edge
	# Setback is 27.5m, plinth front is at 12.5m, road sidewalk outer edge is at 9.5m.
	# Promenade size 5.0m centered at Z = -14.0m sits safely from 11.5m to 16.5m from road centerline.
	var promenade = MeshInstance3D.new()
	promenade.name = "SidewalkApron"
	var prom_box = BoxMesh.new()
	prom_box.size = Vector3(26.0, 0.12, 5.0)
	promenade.mesh = prom_box
	promenade.material_override = mat_sidewalk
	promenade.position = Vector3(0.0, 0.06, -14.0)
	parcel_root.add_child(promenade)

	# 3. Manicured Green Verge & Landscaping along frontage
	var verge_mi = MeshInstance3D.new()
	var verge_box = BoxMesh.new()
	verge_box.size = Vector3(24.0, 0.16, 2.4)
	verge_mi.mesh = verge_box
	var mat_grass = StandardMaterial3D.new()
	mat_grass.albedo_color = Color(0.18, 0.36, 0.16)
	mat_grass.roughness = 0.95
	verge_mi.material_override = mat_grass
	verge_mi.position = Vector3(0.0, 0.08, -10.5)
	parcel_root.add_child(verge_mi)

	# 4. Modern Decorative Bollards along pedestrian promenade outer boundary (Z = -13.5, 14m from road centerline)
	for bx in [-9.0, -4.5, 0.0, 4.5, 9.0]:
		var bollard_mi = MeshInstance3D.new()
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.10
		b_cyl.bottom_radius = 0.12
		b_cyl.height = 0.70
		bollard_mi.mesh = b_cyl
		var mat_bollard = StandardMaterial3D.new()
		mat_bollard.albedo_color = Color(0.75, 0.78, 0.82)
		mat_bollard.metallic = 0.88
		mat_bollard.roughness = 0.22
		bollard_mi.material_override = mat_bollard
		bollard_mi.position = Vector3(bx, 0.35, -13.5)
		parcel_root.add_child(bollard_mi)

	# 5. Side Parking Stall with Parked Vehicle (alternate blocks)
	if seed_val % 2 == 0:
		var parking_mi = MeshInstance3D.new()
		var park_box = BoxMesh.new()
		park_box.size = Vector3(8.0, 0.10, 14.0)
		parking_mi.mesh = park_box
		parking_mi.material_override = mat_asphalt
		parking_mi.position = Vector3(18.0, 0.05, -2.0)
		parcel_root.add_child(parking_mi)

		var car = _build_parked_vehicle_prop()
		car.position = Vector3(18.0, 0.05, -2.0)
		car.rotation_degrees.y = 90.0
		parcel_root.add_child(car)

	# 6. Street Furniture on pedestrian plaza
	if seed_val % 3 == 0:
		var bench = _build_street_bench()
		bench.position = Vector3(-6.0, 0.12, -14.0)
		parcel_root.add_child(bench)
		var trash = _build_trash_bin()
		trash.position = Vector3(-8.0, 0.12, -14.0)
		parcel_root.add_child(trash)
	elif seed_val % 3 == 1:
		var shelter = _build_bus_stop_shelter()
		shelter.position = Vector3(0.0, 0.12, -14.0)
		parcel_root.add_child(shelter)
	else:
		var hydrant = _build_fire_hydrant()
		hydrant.position = Vector3(7.0, 0.12, -14.0)
		parcel_root.add_child(hydrant)

	if is_instance_valid(props_container):
		props_container.add_child(parcel_root)
	else:
		props_container = Node3D.new()
		props_container.name = "EnvironmentProps"
		add_child(props_container)
		props_container.add_child(parcel_root)

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
	var root = Node3D.new()
	root.name = "StreetLight"

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

func _build_bus_stop_shelter() -> Node3D:
	var shelter = Node3D.new()
	shelter.name = "BusStopShelter"

	var mat_frame = StandardMaterial3D.new()
	mat_frame.albedo_color = Color(0.20, 0.22, 0.25)
	mat_frame.metallic = 0.85
	mat_frame.roughness = 0.30

	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.65, 0.85, 0.95, 0.45)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.roughness = 0.05

	# Roof Canopy
	var roof = MeshInstance3D.new()
	var roof_box = BoxMesh.new()
	roof_box.size = Vector3(4.2, 0.12, 2.2)
	roof.mesh = roof_box
	roof.material_override = mat_frame
	roof.position = Vector3(0.0, 2.7, 0.0)
	shelter.add_child(roof)

	# Rear Glass Panel
	var rear_glass = MeshInstance3D.new()
	var rg_box = BoxMesh.new()
	rg_box.size = Vector3(4.0, 2.5, 0.08)
	rear_glass.mesh = rg_box
	rear_glass.material_override = mat_glass
	rear_glass.position = Vector3(0.0, 1.35, -1.0)
	shelter.add_child(rear_glass)

	# Side Support Posts
	for px in [-2.0, 2.0]:
		var post = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.08
		p_cyl.bottom_radius = 0.08
		p_cyl.height = 2.7
		post.mesh = p_cyl
		post.material_override = mat_frame
		post.position = Vector3(px, 1.35, -1.0)
		shelter.add_child(post)

	# Integrated Wooden Bench
	var bench = _build_street_bench()
	bench.position = Vector3(0.0, 0.0, -0.4)
	shelter.add_child(bench)

	return shelter

func _build_fire_hydrant() -> Node3D:
	var hydrant = Node3D.new()
	hydrant.name = "FireHydrant"

	var mat_hydrant = StandardMaterial3D.new()
	mat_hydrant.albedo_color = Color(0.88, 0.15, 0.12)
	mat_hydrant.roughness = 0.45
	mat_hydrant.metallic = 0.65

	var body = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.22
	cyl.height = 0.75
	body.mesh = cyl
	body.material_override = mat_hydrant
	body.position = Vector3(0.0, 0.375, 0.0)
	hydrant.add_child(body)

	var cap = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.20
	sphere.height = 0.25
	cap.mesh = sphere
	cap.material_override = mat_hydrant
	cap.position = Vector3(0.0, 0.75, 0.0)
	hydrant.add_child(cap)

	for side in [-1.0, 1.0]:
		var nozzle = MeshInstance3D.new()
		var n_cyl = CylinderMesh.new()
		n_cyl.top_radius = 0.08
		n_cyl.bottom_radius = 0.08
		n_cyl.height = 0.20
		nozzle.mesh = n_cyl
		nozzle.material_override = mat_hydrant
		nozzle.rotation_degrees.z = 90.0
		nozzle.position = Vector3(side * 0.22, 0.48, 0.0)
		hydrant.add_child(nozzle)

	return hydrant

func _build_trash_bin() -> Node3D:
	var bin = Node3D.new()
	bin.name = "StreetTrashBin"

	var mat_bin = StandardMaterial3D.new()
	mat_bin.albedo_color = Color(0.24, 0.28, 0.32)
	mat_bin.roughness = 0.55
	mat_bin.metallic = 0.75

	var body = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.26
	cyl.bottom_radius = 0.22
	cyl.height = 0.85
	body.mesh = cyl
	body.material_override = mat_bin
	body.position = Vector3(0.0, 0.425, 0.0)
	bin.add_child(body)

	var lid = MeshInstance3D.new()
	var dome = SphereMesh.new()
	dome.radius = 0.27
	dome.height = 0.20
	lid.mesh = dome
	lid.material_override = mat_bin
	lid.position = Vector3(0.0, 0.85, 0.0)
	bin.add_child(lid)

	return bin
