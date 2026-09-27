class_name NeonCity
extends "res://games/chroma-rush/worlds/world_base.gd"

## World 1: Neon City — Metropolitan Urban District
## A bustling realistic metropolis with connected multi-lane asphalt avenues,
## high-rise commercial buildings, modern architecture, street light posts,
## tunnels, elevated flyovers, and urban pursuit routes.

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
	player_spawn_transform.origin = p0 + Vector3(0.0, 0.45, 0.0)

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

			# Left Side: Towering Skyscraper or Commercial Block
			var setback_l = 18.5 + float((i + s) % 3) * 3.0
			var pos_l = center_pt - right * setback_l
			pos_l.y = p1.y
			var b_l: Node3D = null
			if (i + s) % 2 == 0:
				var m_idx = (i * 2 + s) % skyscraper_paths.size()
				b_l = ModelCache.get_model(skyscraper_paths[m_idx])
				if b_l:
					b_l.scale = Vector3(11.0, 13.0, 11.0)
			else:
				var m_idx = (i * 2 + s) % commercial_paths.size()
				b_l = ModelCache.get_model(commercial_paths[m_idx])
				if b_l:
					b_l.scale = Vector3(8.5, 9.0, 8.5)

			if not b_l:
				b_l = _build_procedural_commercial_block(35.0, 20.0)

			b_l.position = pos_l
			b_l.rotation_degrees.y = rot_base + 90.0
			props_container.add_child(b_l)

			# Right Side: Towering Skyscraper or Commercial Block
			var setback_r = 18.5 + float((i + s + 1) % 3) * 3.0
			var pos_r = center_pt + right * setback_r
			pos_r.y = p1.y
			var b_r: Node3D = null
			if (i + s + 1) % 2 == 0:
				var m_idx = (i * 2 + s + 1) % skyscraper_paths.size()
				b_r = ModelCache.get_model(skyscraper_paths[m_idx])
				if b_r:
					b_r.scale = Vector3(11.0, 13.0, 11.0)
			else:
				var m_idx = (i * 2 + s + 1) % commercial_paths.size()
				b_r = ModelCache.get_model(commercial_paths[m_idx])
				if b_r:
					b_r.scale = Vector3(8.5, 9.0, 8.5)

			if not b_r:
				b_r = _build_procedural_commercial_block(38.0, 22.0)

			b_r.position = pos_r
			b_r.rotation_degrees.y = rot_base - 90.0
			props_container.add_child(b_r)

			# Landscaped Street Trees along sidewalk verge
			if s % 2 == 0 and p1.y < 1.0:
				var tree_l = _build_street_tree()
				tree_l.position = center_pt - right * 9.5
				tree_l.position.y = p1.y
				props_container.add_child(tree_l)

				var tree_r = _build_street_tree()
				tree_r.position = center_pt + right * 9.5
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
			var lamp = ModelCache.get_model("res://assets/models/environment/road_lightposts.glb")
			if not lamp:
				lamp = _build_procedural_streetlight()
			lamp.position = lamp_pos
			lamp.rotation_degrees.y = rad_to_deg(atan2(-dir.x, -dir.z)) + (90.0 if side > 0 else -90.0)
			props_container.add_child(lamp)

func _create_barrier(pos: Vector3, dir: Vector3, length: float) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.collision_layer = GameConstants.LAYER_WORLD

	var mi = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.35, 1.1, length)
	mi.mesh = b_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.78, 0.82)
	mat.metallic = 0.90
	mat.roughness = 0.25
	mi.material_override = mat
	sb.add_child(mi)

	var col = CollisionShape3D.new()
	var col_shape = BoxShape3D.new()
	col_shape.size = Vector3(0.35, 1.1, length)
	col.shape = col_shape
	sb.add_child(col)

	sb.position = pos + Vector3(0, 0.55, 0)
	if dir.length_squared() > 0.001:
		sb.look_at_from_position(sb.position, sb.position + dir, Vector3.UP)

	return sb

func _build_street_tree() -> Node3D:
	var tree_paths = [
		"res://assets/models/environment/tree_oak.glb",
		"res://assets/models/environment/tree_detailed.glb"
	]
	var p = tree_paths[randi() % tree_paths.size()]
	var tree_model = ModelCache.get_model(p)
	if tree_model:
		tree_model.scale = Vector3(5.5, 5.5, 5.5)
		return tree_model

	# Fallback branching tree
	var root = Node3D.new()
	var trunk_mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.24
	cyl.height = 4.2
	trunk_mi.mesh = cyl
	var mat_trunk = StandardMaterial3D.new()
	mat_trunk.albedo_color = Color(0.24, 0.17, 0.12)
	mat_trunk.roughness = 0.92
	trunk_mi.material_override = mat_trunk
	trunk_mi.position = Vector3(0, 2.1, 0)
	root.add_child(trunk_mi)

	var crown_mi = MeshInstance3D.new()
	var pyr = PrismMesh.new()
	pyr.size = Vector3(3.2, 4.8, 3.2)
	crown_mi.mesh = pyr
	var mat_crown = StandardMaterial3D.new()
	mat_crown.albedo_color = Color(0.12, 0.38, 0.18)
	mat_crown.roughness = 0.82
	crown_mi.material_override = mat_crown
	crown_mi.position = Vector3(0, 4.6, 0)
	root.add_child(crown_mi)
	return root

	# Planter concrete rim
	var rim_mi = MeshInstance3D.new()
	var rim_mesh = BoxMesh.new()
	rim_mesh.size = Vector3(1.2, 0.15, 1.2)
	rim_mi.mesh = rim_mesh
	var mat_rim = StandardMaterial3D.new()
	mat_rim.albedo_color = Color(0.50, 0.52, 0.54)
	mat_rim.roughness = 0.88
	rim_mi.material_override = mat_rim
	rim_mi.position = Vector3(0, 0.08, 0)
	root.add_child(rim_mi)

	return root

func _build_procedural_commercial_block(height: float, width: float) -> Node3D:
	var root = Node3D.new()
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(width, height, width * 0.9)
	mi.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.25, 0.30)
	mat.roughness = 0.55
	mat.metallic = 0.35
	mi.material_override = mat
	mi.position = Vector3(0, height * 0.5, 0)
	root.add_child(mi)

	# Glass window bands
	var floors = int(height / 4.0)
	for f in range(floors):
		var w_mi = MeshInstance3D.new()
		var w_box = BoxMesh.new()
		w_box.size = Vector3(width + 0.1, 1.4, width * 0.9 + 0.1)
		w_mi.mesh = w_box
		var w_mat = StandardMaterial3D.new()
		w_mat.albedo_color = Color(0.35, 0.55, 0.70)
		w_mat.metallic = 0.90
		w_mat.roughness = 0.12
		w_mat.clearcoat_enabled = true
		w_mat.clearcoat = 0.9
		w_mi.material_override = w_mat
		w_mi.position = Vector3(0, float(f) * 4.0 + 2.0, 0)
		root.add_child(w_mi)

	return root

func _build_procedural_streetlight() -> Node3D:
	var root = Node3D.new()
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
