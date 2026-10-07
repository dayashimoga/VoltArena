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

	bool is_window = (tex.r < 0.14 && tex.g < 0.14 && tex.b < 0.14);
	bool is_teal_base = (tex.g > 0.48 && tex.r < 0.42);
	bool is_orange_band = (tex.r > 0.88 && tex.g < 0.66 && tex.b < 0.45);

	if (is_window) {
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

func _is_clear_of_spline(pt: Vector3, min_clearance: float, ignore_s_idx: int = -1, ignore_window: int = 6) -> bool:
	var pt_2d = Vector2(pt.x, pt.z)
	var pts_to_check = spline_samples if not spline_samples.is_empty() else waypoints
	var n_s = pts_to_check.size()
	if n_s < 2:
		return true
	for i in range(n_s):
		if ignore_s_idx >= 0 and not spline_samples.is_empty():
			var diff = abs(i - ignore_s_idx)
			var cyclic_diff = min(diff, n_s - diff)
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

	# 1. Primary Street-Facing City Blocks (Positioned at safe setback >= 24.5m with complete block parcels)
	var building_interval = 4 # every ~24m along spline for dense, continuous urban fabric
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
			var setback = 27.5 + float((s_idx + int(side > 0)) % 3) * 3.0
			var b_pos = p_curr + right * (side * setback)
			b_pos.y = p_curr.y

			# Enforce strict geometric clearance across the entire spline network (>= 26.0m on non-local segments prevents any road/curb intrusion)
			if not _is_clear_of_spline(b_pos, 26.0, s_idx, 6):
				continue

			var theme_idx = (s_idx * 3 + int(side > 0) * 2 + wp_nearest) % ARCHITECTURAL_THEMES.size()
			var side_str = "Left" if side < 0 else "Right"
			var b_node = _create_district_building(wp_nearest, s_idx, skyscraper_paths, commercial_paths, residential_paths, theme_idx, side_str)
			b_node.position = b_pos
			b_node.rotation_degrees.y = rot_y + (90.0 if side < 0 else -90.0)
			props_container.add_child(b_node)

			# Contiguous urban block parcel connecting road sidewalk to building with esplanade, plinth, verge & parking
			_build_urban_block_parcel(p_curr, right * side, setback, b_pos, b_node.rotation_degrees.y, wp_nearest, s_idx)

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

		elif s_idx % 16 == 8:
			# Modern Bus Stop Shelter on pedestrian sidewalk verge at -12.0m
			var shelter_pos = p_curr - right * 12.0
			if _is_clear_of_spline(shelter_pos, 9.0):
				var shelter = _build_bus_stop_shelter()
				shelter.position = shelter_pos
				shelter.position.y = p_curr.y
				shelter.rotation_degrees.y = rot_y + 90.0
				props_container.add_child(shelter)

		elif s_idx % 8 == 2:
			# Modern Fire Hydrant on sidewalk verge at -11.0m
			var hydrant_pos = p_curr - right * 11.0
			if _is_clear_of_spline(hydrant_pos, 8.5):
				var hydrant = _build_fire_hydrant()
				hydrant.position = hydrant_pos
				hydrant.position.y = p_curr.y
				props_container.add_child(hydrant)

			# Street Trash Receptacle at +11.0m
			var bin_pos = p_curr + right * 11.0
			if _is_clear_of_spline(bin_pos, 8.5):
				var bin = _build_trash_bin()
				bin.position = bin_pos
				bin.position.y = p_curr.y
				props_container.add_child(bin)

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

func _create_district_building(i: int, s: int, skyscrapers: Array, commercials: Array, residentials: Array, theme_idx: int, side_name: String) -> Node3D:
	var b_node: Node3D = null
	var pick_type = (i + s) % 3

	# District-specific architectural selection
	if (i <= 5 or (i >= 17 and i <= 21)) and pick_type != 2:
		# CBD & Neon Strip: High-Rise Skyscraper Glass Towers
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
	elif (i >= 22 and i <= 31) and pick_type == 1:
		# Marina & Old Town: Mid-Rise Classical / Residential Masonry
		var m_idx = (i * 2 + s) % residentials.size()
		var glb_model = ModelCache.get_model(residentials[m_idx])
		if glb_model:
			glb_model.scale = Vector3(7.0, 7.5, 7.0)
			_style_building(glb_model, theme_idx)
			var b_body = StaticBody3D.new()
			b_body.name = "Residential%s_%d_%d" % [side_name, i, s]
			b_body.collision_layer = GameConstants.LAYER_WORLD
			b_body.add_child(glb_model)
			var col = CollisionShape3D.new()
			var b_shape = BoxShape3D.new()
			b_shape.size = Vector3(14.0, 24.0, 14.0)
			col.shape = b_shape
			col.position = Vector3(0, 12.0, 0)
			b_body.add_child(col)
			b_node = b_body
	else:
		# Commercial Promenade & Mixed-Use Districts
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

		var block = _build_procedural_commercial_block(cfg["h"], cfg["w"], cfg["theme"])
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
	# GPU MultiMesh dual perimeter rings creating 360° architectural skyline (zero empty space)
	var tower_count = 128
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = _create_stepped_skyline_mesh()
	multimesh.instance_count = tower_count

	var mat_distant = StandardMaterial3D.new()
	mat_distant.albedo_color = Color(0.14, 0.20, 0.28)
	mat_distant.metallic = 0.85
	mat_distant.roughness = 0.16
	mat_distant.emission_enabled = true
	mat_distant.emission = Color(0.10, 0.18, 0.26)
	mat_distant.emission_energy_multiplier = 1.35
	mat_distant.vertex_color_use_as_albedo = true

	for t in range(tower_count):
		var ring_idx = t % 2
		var radius = 480.0 if ring_idx == 0 else 660.0
		var angle = (float(t) / float(tower_count)) * TAU
		var dist_var = radius + float(t % 5) * 30.0
		var tx = cos(angle) * dist_var
		var tz = sin(angle) * dist_var
		var scale_y = 0.65 + float((t * 7) % 13) * 0.12

		var xf = Transform3D()
		xf = xf.scaled(Vector3(1.0 + float(t % 3) * 0.22, scale_y, 1.0 + float((t + 1) % 3) * 0.22))
		xf.origin = Vector3(tx, 0.0, tz)
		multimesh.set_instance_transform(t, xf)

		var shade = 0.75 + float(t % 4) * 0.12
		var is_amber = (t % 3 == 0)
		var col = Color(0.24 * shade, 0.20 * shade, 0.12 * shade, 1.0) if is_amber else Color(0.10 * shade, 0.24 * shade, 0.38 * shade, 1.0)
		multimesh.set_instance_color(t, col)

	var mm_inst = MultiMeshInstance3D.new()
	mm_inst.name = "DistantSkylineMultiMesh"
	mm_inst.multimesh = multimesh
	mm_inst.material_override = mat_distant
	props_container.add_child(mm_inst)

static func _create_stepped_skyline_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 1. Base Stepped Podium (36 x 24 x 36, center y = 12)
	_add_box_to_st(st, Vector3(36.0, 24.0, 36.0), Vector3(0.0, 12.0, 0.0))
	# 2. Main High-Rise Shaft (26 x 60 x 26, center y = 54)
	_add_box_to_st(st, Vector3(26.0, 60.0, 26.0), Vector3(0.0, 54.0, 0.0))
	# 3. Setback Penthouse Crown (16 x 26 x 16, center y = 97)
	_add_box_to_st(st, Vector3(16.0, 26.0, 16.0), Vector3(0.0, 97.0, 0.0))
	# 4. Rooftop Spire Mast (2.4 x 28 x 2.4, center y = 124)
	_add_box_to_st(st, Vector3(2.4, 28.0, 2.4), Vector3(0.0, 124.0, 0.0))

	st.generate_normals()
	return st.commit()

static func _add_box_to_st(st: SurfaceTool, size: Vector3, center: Vector3) -> void:
	var h = size * 0.5
	var v0 = center + Vector3(-h.x, -h.y, -h.z)
	var v1 = center + Vector3( h.x, -h.y, -h.z)
	var v2 = center + Vector3( h.x,  h.y, -h.z)
	var v3 = center + Vector3(-h.x,  h.y, -h.z)
	var v4 = center + Vector3(-h.x, -h.y,  h.z)
	var v5 = center + Vector3( h.x, -h.y,  h.z)
	var v6 = center + Vector3( h.x,  h.y,  h.z)
	var v7 = center + Vector3(-h.x,  h.y,  h.z)

	_add_quad_to_st(st, v0, v1, v2, v3, Vector3.BACK)
	_add_quad_to_st(st, v5, v4, v7, v6, Vector3.FORWARD)
	_add_quad_to_st(st, v4, v0, v3, v7, Vector3.LEFT)
	_add_quad_to_st(st, v1, v5, v6, v2, Vector3.RIGHT)
	_add_quad_to_st(st, v3, v2, v6, v7, Vector3.UP)
	_add_quad_to_st(st, v4, v5, v1, v0, Vector3.DOWN)

static func _add_quad_to_st(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	st.set_normal(normal)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(a)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(b)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(c)

	st.set_normal(normal)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(a)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(c)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(d)

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

	# 3. Authentic 3D Tree Mesh Asset
	var tree_path = "res://assets/models/environment/tree_oak.glb"
	match species:
		"palm": tree_path = "res://assets/models/environment/tree_palm.glb"
		"pine": tree_path = "res://assets/models/environment/tree_pine.glb"
		"birch": tree_path = "res://assets/models/environment/tree_detailed.glb"
		"cherry": tree_path = "res://assets/models/environment/tree_detailed.glb"
		"linden": tree_path = "res://assets/models/environment/tree_tall.glb"
		_: tree_path = "res://assets/models/environment/tree_oak.glb"

	var tree_model = ModelCache.get_model(tree_path)
	if tree_model:
		tree_model.name = "AuthoredTree"
		var sc = height * 0.28
		tree_model.scale = Vector3(sc, sc, sc)
		tree_model.rotation_degrees.y = float(seed_val * 47 % 360)
		tree_model.position = Vector3(0, 0.1, 0)
		root.add_child(tree_model)

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

	# 2. Continuous Pedestrian Apron connecting road sidewalk to building front
	var apron = MeshInstance3D.new()
	apron.name = "SidewalkApron"
	var apron_box = BoxMesh.new()
	apron_box.size = Vector3(26.0, 0.14, 18.0)
	apron.mesh = apron_box
	apron.material_override = mat_sidewalk
	apron.position = Vector3(0.0, 0.07, -18.0)
	parcel_root.add_child(apron)

	# 3. Manicured Green Verge & Landscaping along frontage
	var verge_mi = MeshInstance3D.new()
	var verge_box = BoxMesh.new()
	verge_box.size = Vector3(24.0, 0.16, 2.8)
	verge_mi.mesh = verge_box
	var mat_grass = StandardMaterial3D.new()
	mat_grass.albedo_color = Color(0.18, 0.36, 0.16)
	mat_grass.roughness = 0.95
	verge_mi.material_override = mat_grass
	verge_mi.position = Vector3(0.0, 0.08, -11.0)
	parcel_root.add_child(verge_mi)

	# 4. Modern Decorative Bollards along sidewalk curb
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
		bollard_mi.position = Vector3(bx, 0.35, -26.0)
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
