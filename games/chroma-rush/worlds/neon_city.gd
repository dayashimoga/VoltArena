class_name NeonCity
extends "res://games/chroma-rush/worlds/world_base.gd"

## World 1: Neon City — Metropolitan Urban District
## A bustling realistic metropolis with connected multi-lane asphalt avenues,
## high-rise commercial buildings, modern architecture, street light posts,
## tunnels, elevated flyovers, and urban pursuit routes.

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

	// Segment Kenney building colormap colors:
	// 1. Dark/black window cutouts: lum < 0.14
	// 2. Teal / cyan ground base: tex.g > 0.48 && tex.r < 0.42
	// 3. Orange accent band: tex.r > 0.88 && tex.g < 0.66 && tex.b < 0.45
	// 4. Cream/peach main facade: remainder

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
		Vector3(0, 0, 0),         # 0 Start/Finish line Avenue
		Vector3(0, 0, -80),       # 1 North Boulevard
		Vector3(0, 0, -180),      # 2 Central Square Intersection
		Vector3(60, 0, -230),     # 3 Northeast Curve
		Vector3(140, 0, -230),    # 4 Financial Plaza East
		Vector3(200, 0, -170),    # 5 East Flyover Incline
		Vector3(200, 4, -80),     # 6 Elevated Skyway
		Vector3(200, 4, 10),      # 7 Skyway South
		Vector3(150, 2, 90),      # 8 Skyway Descent Ramp
		Vector3(80, 0, 110),      # 9 City Plaza Entry
		Vector3(10, -2, 110),     # 10 Subterranean Avenue Underpass
		Vector3(-60, -2, 110),    # 11 Tunnel Midpoint
		Vector3(-120, 0, 80),     # 12 Tunnel Exit / West Marina Plaza
		Vector3(-120, 0, 0),      # 13 West Boulevard
		Vector3(-90, 0, -45),     # 14 Grand Avenue Chicane
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
	# 6 Gate locations distributed around the city avenues
	var gate_defs = [
		{"id": "gate_1", "wp_idx": 2, "color": ChromaConstants.ChromaColor.CRIMSON},
		{"id": "gate_2", "wp_idx": 4, "color": ChromaConstants.ChromaColor.COBALT},
		{"id": "gate_3", "wp_idx": 7, "color": ChromaConstants.ChromaColor.SOLAR},
		{"id": "gate_4", "wp_idx": 9, "color": ChromaConstants.ChromaColor.EMERALD},
		{"id": "gate_5", "wp_idx": 11, "color": ChromaConstants.ChromaColor.MAGENTA},
		{"id": "gate_6", "wp_idx": 14, "color": ChromaConstants.ChromaColor.CYAN}
	]

	for g in gate_defs:
		var gate = CheckpointGate.new()
		gate.gate_id = g["id"]
		gate.target_color = g["color"]

		var wp = waypoints[g["wp_idx"]]
		var next_wp = waypoints[(g["wp_idx"] + 1) % waypoints.size()]
		var dir = (next_wp - wp).normalized()

		gate.position = wp + Vector3(0.0, 0.2, 0.0)
		if dir.length_squared() > 0.001:
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

	# 1. Procedurally line BOTH sides of all avenue segments with realistic skyscrapers and commercial towers
	var n_wp = waypoints.size()
	for i in range(n_wp):
		var p1 = waypoints[i]
		var p2 = waypoints[(i + 1) % n_wp]
		var seg_vec = p2 - p1
		var seg_len = seg_vec.length()
		if seg_len < 12.0:
			continue
		var dir = seg_vec.normalized()
		var right = Vector3(-dir.z, 0, dir.x).normalized()
		var rot_base = rad_to_deg(atan2(-dir.x, -dir.z))

		var num_slots = max(1, int(seg_len / 26.0))
		var step = seg_len / float(num_slots)

		for s in range(num_slots):
			var dist_along = (float(s) + 0.5) * step
			var center_pt = p1 + dir * dist_along

			# Left Side Building: Diverse architecture and distinct PBR styling
			var setback_l = 21.0 + float((i + s) % 3) * 3.5
			var pos_l = center_pt - right * setback_l
			pos_l.y = p1.y
			var theme_l = (i * 3 + s) % ARCHITECTURAL_THEMES.size()
			var b_l: Node3D = null

			if (i + s) % 2 == 0:
				var m_idx = (i * 2 + s) % skyscraper_paths.size()
				var glb_model = ModelCache.get_model(skyscraper_paths[m_idx])
				if glb_model:
					glb_model.scale = Vector3(11.0, 13.0, 11.0)
					_style_building(glb_model, theme_l)
					var b_body = StaticBody3D.new()
					b_body.name = "SkyscraperLeft_%d_%d" % [i, s]
					b_body.collision_layer = GameConstants.LAYER_WORLD
					b_body.add_child(glb_model)
					var col = CollisionShape3D.new()
					var b_shape = BoxShape3D.new()
					b_shape.size = Vector3(22.0, 52.0, 22.0)
					col.shape = b_shape
					col.position = Vector3(0, 26.0, 0)
					b_body.add_child(col)
					b_l = b_body
			else:
				var m_idx = (i * 2 + s) % commercial_paths.size()
				var glb_model = ModelCache.get_model(commercial_paths[m_idx])
				if glb_model:
					glb_model.scale = Vector3(8.5, 9.0, 8.5)
					_style_building(glb_model, theme_l)
					var b_body = StaticBody3D.new()
					b_body.name = "CommercialLeft_%d_%d" % [i, s]
					b_body.collision_layer = GameConstants.LAYER_WORLD
					b_body.add_child(glb_model)
					var col = CollisionShape3D.new()
					var b_shape = BoxShape3D.new()
					b_shape.size = Vector3(18.0, 32.0, 18.0)
					col.shape = b_shape
					col.position = Vector3(0, 16.0, 0)
					b_body.add_child(col)
					b_l = b_body

			if not b_l:
				b_l = _build_procedural_commercial_block(36.0 + float((i + s) % 5) * 8.0, 22.0, theme_l)

			b_l.position = pos_l
			b_l.rotation_degrees.y = rot_base + 90.0
			props_container.add_child(b_l)

			# Urban Plaza Foundation beneath left building (anchored to ground y=0 so no hollow under-slabs)
			var plaza_l = _build_urban_plaza_foundation(30.0, 30.0, 0.0, p1.y + 0.10)
			plaza_l.position = Vector3(pos_l.x, 0.0, pos_l.z)
			plaza_l.rotation_degrees.y = rot_base + 90.0
			props_container.add_child(plaza_l)

			# Right Side Building: Diverse architecture and distinct PBR styling
			var setback_r = 21.0 + float((i + s + 1) % 3) * 3.5
			var pos_r = center_pt + right * setback_r
			pos_r.y = p1.y
			var theme_r = (i * 3 + s + 1) % ARCHITECTURAL_THEMES.size()
			var b_r: Node3D = null

			if (i + s + 1) % 2 == 0:
				var m_idx = (i * 2 + s + 1) % skyscraper_paths.size()
				var glb_model = ModelCache.get_model(skyscraper_paths[m_idx])
				if glb_model:
					glb_model.scale = Vector3(11.0, 13.0, 11.0)
					_style_building(glb_model, theme_r)
					var b_body = StaticBody3D.new()
					b_body.name = "SkyscraperRight_%d_%d" % [i, s]
					b_body.collision_layer = GameConstants.LAYER_WORLD
					b_body.add_child(glb_model)
					var col = CollisionShape3D.new()
					var b_shape = BoxShape3D.new()
					b_shape.size = Vector3(22.0, 52.0, 22.0)
					col.shape = b_shape
					col.position = Vector3(0, 26.0, 0)
					b_body.add_child(col)
					b_r = b_body
			else:
				var m_idx = (i * 2 + s + 1) % commercial_paths.size()
				var glb_model = ModelCache.get_model(commercial_paths[m_idx])
				if glb_model:
					glb_model.scale = Vector3(8.5, 9.0, 8.5)
					_style_building(glb_model, theme_r)
					var b_body = StaticBody3D.new()
					b_body.name = "CommercialRight_%d_%d" % [i, s]
					b_body.collision_layer = GameConstants.LAYER_WORLD
					b_body.add_child(glb_model)
					var col = CollisionShape3D.new()
					var b_shape = BoxShape3D.new()
					b_shape.size = Vector3(18.0, 32.0, 18.0)
					col.shape = b_shape
					col.position = Vector3(0, 16.0, 0)
					b_body.add_child(col)
					b_r = b_body

			if not b_r:
				b_r = _build_procedural_commercial_block(40.0 + float((i + s + 1) % 5) * 8.0, 24.0, theme_r)

			b_r.position = pos_r
			b_r.rotation_degrees.y = rot_base - 90.0
			props_container.add_child(b_r)

			# Urban Plaza Foundation beneath right building (anchored to ground y=0 so no hollow under-slabs)
			var plaza_r = _build_urban_plaza_foundation(30.0, 30.0, 0.0, p1.y + 0.10)
			plaza_r.position = Vector3(pos_r.x, 0.0, pos_r.z)
			plaza_r.rotation_degrees.y = rot_base - 90.0
			props_container.add_child(plaza_r)

			# Landscaped Green Verge between Sidewalk and Buildings
			if p1.y < 1.0:
				var verge_w = 5.5
				var verge_len = step * 0.95
				var verge_l = _build_landscaped_verge(verge_len, verge_w)
				verge_l.position = center_pt - right * (11.0 + verge_w * 0.5)
				verge_l.position.y = p1.y + 0.04
				verge_l.rotation_degrees.y = rot_base
				props_container.add_child(verge_l)

				var verge_r = _build_landscaped_verge(verge_len, verge_w)
				verge_r.position = center_pt + right * (11.0 + verge_w * 0.5)
				verge_r.position.y = p1.y + 0.04
				verge_r.rotation_degrees.y = rot_base
				props_container.add_child(verge_r)

			# Realistic Natural Street Trees along sidewalk verge
			if s % 2 == 0 and p1.y < 1.0:
				var tree_l = _build_street_tree()
				tree_l.position = center_pt - right * 9.6
				tree_l.position.y = p1.y
				props_container.add_child(tree_l)

				var tree_r = _build_street_tree()
				tree_r.position = center_pt + right * 9.6
				tree_r.position.y = p1.y
				props_container.add_child(tree_r)

	# 2. Place street light posts along sidewalks
	for i in range(waypoints.size()):
		var wp = waypoints[i]
		var next_wp = waypoints[(i + 1) % waypoints.size()]
		var dir = (next_wp - wp).normalized()
		var right = Vector3(-dir.z, 0, dir.x).normalized()

		for side in [-1.0, 1.0]:
			var lamp_pos = wp + right * (side * 9.6) + Vector3(0.0, 0.1, 0.0)
			var lamp = _build_procedural_streetlight()
			lamp.position = lamp_pos
			lamp.rotation_degrees.y = rad_to_deg(atan2(-dir.x, -dir.z)) + (90.0 if side > 0 else -90.0)
			props_container.add_child(lamp)


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
	mat.albedo_color = Color(0.25, 0.27, 0.29) # Granite paver plaza
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

func _build_landscaped_verge(length: float, width: float) -> Node3D:
	var root = Node3D.new()
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(width, 0.10, length)
	mi.mesh = box
	var mat_grass = StandardMaterial3D.new()
	mat_grass.albedo_color = Color(0.18, 0.44, 0.16) # Lush manicured turf green
	mat_grass.roughness = 0.90
	mat_grass.specular = 0.10
	mat_grass.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	mi.material_override = mat_grass
	mi.position = Vector3(0, 0.05, 0)
	root.add_child(mi)

	# Add small ornamental shrubs along the verge
	var num_shrubs = max(1, int(length / 7.0))
	for s in range(num_shrubs):
		var shrub = MeshInstance3D.new()
		var sp = SphereMesh.new()
		sp.radius = 0.65
		sp.height = 0.85
		sp.radial_segments = 12
		sp.rings = 8
		shrub.mesh = sp
		var mat_shrub = StandardMaterial3D.new()
		mat_shrub.albedo_color = Color(0.13, 0.35, 0.15) if s % 2 == 0 else Color(0.15, 0.40, 0.18)
		mat_shrub.roughness = 0.82
		shrub.material_override = mat_shrub
		shrub.position = Vector3(0.0, 0.40, -length * 0.5 + float(s + 0.5) * (length / float(num_shrubs)))
		root.add_child(shrub)

	return root

func _build_street_tree() -> Node3D:
	var root = StaticBody3D.new()
	root.name = "RealisticStreetTree"
	root.collision_layer = GameConstants.LAYER_WORLD

	# Solid Trunk Collider (prevents vehicles driving into tree trunks)
	var col = CollisionShape3D.new()
	col.name = "TreeTrunkCollision"
	var col_shape = CylinderShape3D.new()
	col_shape.height = 4.2
	col_shape.radius = 0.45
	col.shape = col_shape
	col.position = Vector3(0, 2.1, 0)
	root.add_child(col)

	# 1. Circular Stone Planter Curb on Sidewalk
	var planter = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 1.35
	p_cyl.bottom_radius = 1.40
	p_cyl.height = 0.22
	planter.mesh = p_cyl
	planter.material_override = mat_curb
	planter.position = Vector3(0, 0.11, 0)
	root.add_child(planter)

	# 2. Rich Loamy Soil
	var soil = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 1.25
	s_cyl.bottom_radius = 1.25
	s_cyl.height = 0.23
	soil.mesh = s_cyl
	var mat_soil = StandardMaterial3D.new()
	mat_soil.albedo_color = Color(0.16, 0.13, 0.10)
	mat_soil.roughness = 0.96
	soil.material_override = mat_soil
	soil.position = Vector3(0, 0.12, 0)
	root.add_child(soil)

	# 3. Organic Tapered Wood Trunk with Root Flare
	var trunk = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.18
	t_cyl.bottom_radius = 0.32
	t_cyl.height = 4.2
	trunk.mesh = t_cyl
	var mat_trunk = StandardMaterial3D.new()
	mat_trunk.albedo_color = Color(0.24, 0.17, 0.12)
	mat_trunk.roughness = 0.94
	trunk.material_override = mat_trunk
	trunk.position = Vector3(0, 2.2, 0)
	root.add_child(trunk)

	# Root flare base
	var flare = MeshInstance3D.new()
	var f_cyl = CylinderMesh.new()
	f_cyl.top_radius = 0.32
	f_cyl.bottom_radius = 0.52
	f_cyl.height = 0.7
	flare.mesh = f_cyl
	flare.material_override = mat_trunk
	flare.position = Vector3(0, 0.45, 0)
	root.add_child(flare)

	# 4. Multi-Volume Organic Foliage Canopy (Non-blocking decorative clusters)
	var foliage_clusters = [
		{"pos": Vector3(0.0, 4.4, 0.0), "r": 2.2, "h": 2.4, "col": Color(0.12, 0.38, 0.15)},
		{"pos": Vector3(-0.85, 3.8, 0.45), "r": 1.65, "h": 1.9, "col": Color(0.10, 0.33, 0.13)},
		{"pos": Vector3(0.80, 4.0, -0.40), "r": 1.70, "h": 1.95, "col": Color(0.14, 0.42, 0.17)},
		{"pos": Vector3(0.10, 5.4, 0.15), "r": 1.45, "h": 1.7, "col": Color(0.17, 0.46, 0.20)},
		{"pos": Vector3(0.35, 4.5, 0.75), "r": 1.35, "h": 1.6, "col": Color(0.13, 0.39, 0.16)}
	]

	for cluster in foliage_clusters:
		var fol = MeshInstance3D.new()
		var sp = SphereMesh.new()
		sp.radius = cluster["r"]
		sp.height = cluster["h"]
		sp.radial_segments = 16
		sp.rings = 10
		fol.mesh = sp
		var mat_fol = StandardMaterial3D.new()
		mat_fol.albedo_color = cluster["col"]
		mat_fol.roughness = 0.80
		mat_fol.specular = 0.15
		mat_fol.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
		fol.material_override = mat_fol
		fol.position = cluster["pos"]
		root.add_child(fol)

	# Scale up for grand metropolitan street presence
	root.scale = Vector3(1.35, 1.35, 1.35)
	return root

func _build_procedural_commercial_block(height: float, width: float, theme_idx: int = 0) -> Node3D:
	var root = StaticBody3D.new()
	root.name = "ProceduralCommercialTower"
	root.collision_layer = GameConstants.LAYER_WORLD

	var theme = ARCHITECTURAL_THEMES[theme_idx % ARCHITECTURAL_THEMES.size()]

	# Wall PBR Material
	var mat_wall = StandardMaterial3D.new()
	mat_wall.albedo_color = theme["wall_primary"]
	mat_wall.metallic = theme["wall_metallic"]
	mat_wall.roughness = theme["wall_roughness"]

	# Ground Podium Material
	var mat_podium = StandardMaterial3D.new()
	mat_podium.albedo_color = theme["wall_secondary"]
	mat_podium.metallic = 0.20
	mat_podium.roughness = 0.65

	# Glass Curtain Wall Material
	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = theme["window"]
	mat_glass.metallic = theme["window_metallic"]
	mat_glass.roughness = theme["window_roughness"]
	mat_glass.clearcoat_enabled = true
	mat_glass.clearcoat = theme["window_clearcoat"]

	# Solid Box Collider for the entire building footprint
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(width, height + 4.0, width * 0.95)
	col.shape = col_box
	col.position = Vector3(0, (height + 4.0) * 0.5, 0)
	root.add_child(col)

	# 1. Ground Level Retail Podium (4m height)
	var podium_mi = MeshInstance3D.new()
	var podium_box = BoxMesh.new()
	podium_box.size = Vector3(width, 4.5, width * 0.95)
	podium_mi.mesh = podium_box
	podium_mi.material_override = mat_podium
	podium_mi.position = Vector3(0, 2.25, 0)
	root.add_child(podium_mi)

	# Ground display windows
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

	# Solid Post Collider
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

	# Vertical Post
	var post_mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.10
	cyl.bottom_radius = 0.14
	cyl.height = 7.0
	post_mi.mesh = cyl
	post_mi.material_override = mat_pole
	post_mi.position = Vector3(0, 3.5, 0)
	root.add_child(post_mi)

	# Horizontal Arm
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

	# Light Lamp Head
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

