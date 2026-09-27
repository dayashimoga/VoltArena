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

	# Add protective guardrails on elevated flyovers and bridge ramps
	for i in range(waypoints.size()):
		var p1 = waypoints[i]
		var p2 = waypoints[(i + 1) % waypoints.size()]
		if p1.y > 0.5 or p2.y > 0.5 or i in [5, 6, 7, 8]:
			var dir = (p2 - p1).normalized()
			var right = Vector3(-dir.z, 0, dir.x).normalized()
			var center = (p1 + p2) * 0.5
			var seg_len = p1.distance_to(p2)

			var barrier_l = _create_barrier(center - right * (road_w * 0.5 + 2.8), dir, seg_len)
			road_container.add_child(barrier_l)

			var barrier_r = _create_barrier(center + right * (road_w * 0.5 + 2.8), dir, seg_len)
			road_container.add_child(barrier_r)

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
	# 1. Place real architectural commercial buildings along the city avenues
	var building_specs = [
		{"path": "res://assets/models/environment/building_a.glb", "pos": Vector3(-28, 0, -45), "rot": 0.0, "scale": 1.2},
		{"path": "res://assets/models/environment/building_b.glb", "pos": Vector3(28, 0, -45), "rot": 180.0, "scale": 1.4},
		{"path": "res://assets/models/environment/building_c.glb", "pos": Vector3(-32, 0, -135), "rot": 90.0, "scale": 1.1},
		{"path": "res://assets/models/environment/building_d.glb", "pos": Vector3(32, 0, -135), "rot": -90.0, "scale": 1.3},
		{"path": "res://assets/models/environment/building_b.glb", "pos": Vector3(75, 0, -280), "rot": 0.0, "scale": 1.5},
		{"path": "res://assets/models/environment/building_a.glb", "pos": Vector3(150, 0, -280), "rot": 0.0, "scale": 1.3},
		{"path": "res://assets/models/environment/building_c.glb", "pos": Vector3(245, 0, -170), "rot": -90.0, "scale": 1.2},
		{"path": "res://assets/models/environment/building_d.glb", "pos": Vector3(250, 0, 10), "rot": -90.0, "scale": 1.4},
		{"path": "res://assets/models/environment/building_garage.glb", "pos": Vector3(115, 0, 145), "rot": 180.0, "scale": 1.2},
		{"path": "res://assets/models/environment/building_a.glb", "pos": Vector3(-165, 0, 80), "rot": 90.0, "scale": 1.3},
		{"path": "res://assets/models/environment/building_b.glb", "pos": Vector3(-165, 0, -30), "rot": 90.0, "scale": 1.4},
		{"path": "res://assets/models/environment/building_c.glb", "pos": Vector3(-65, 0, 45), "rot": 180.0, "scale": 1.1}
	]

	for spec in building_specs:
		var b_node = ModelCache.get_model(spec["path"])
		if not b_node:
			# Fallback to realistic procedural building block
			b_node = _build_procedural_commercial_block(spec["scale"] * 30.0, spec["scale"] * 18.0)
		b_node.position = spec["pos"]
		b_node.rotation_degrees.y = spec["rot"]
		b_node.scale = Vector3.ONE * spec["scale"]
		props_container.add_child(b_node)

	# 2. Place street light posts along sidewalks
	for i in range(waypoints.size()):
		var wp = waypoints[i]
		var next_wp = waypoints[(i + 1) % waypoints.size()]
		var dir = (next_wp - wp).normalized()
		var right = Vector3(-dir.z, 0, dir.x).normalized()

		for side in [-1.0, 1.0]:
			var lamp_pos = wp + right * (side * 10.2) + Vector3(0.0, 0.1, 0.0)
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
	mat.albedo_color = Color(0.75, 0.78, 0.82) # Galvanized steel crash barrier
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

func _build_procedural_commercial_block(height: float, width: float) -> Node3D:
	var root = Node3D.new()
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(width, height, width * 0.9)
	mi.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.24, 0.28, 0.35)
	mat.roughness = 0.5
	mat.metallic = 0.3
	mi.material_override = mat
	mi.position = Vector3(0, height * 0.5, 0)
	root.add_child(mi)

	# Window bands
	var floors = int(height / 4.0)
	for f in range(floors):
		var w_mi = MeshInstance3D.new()
		var w_box = BoxMesh.new()
		w_box.size = Vector3(width + 0.1, 1.4, width * 0.9 + 0.1)
		w_mi.mesh = w_box
		var w_mat = StandardMaterial3D.new()
		w_mat.albedo_color = Color(0.70, 0.85, 0.95)
		w_mat.metallic = 0.85
		w_mat.roughness = 0.15
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
