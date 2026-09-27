class_name NeonCity
extends "res://games/chroma-rush/worlds/world_base.gd"

## World 1: Neon City
## Cyberpunk urban grid with multi-lane highways, underpass tunnels,
## glowing skyscrapers, illuminated intersections, and urban pursuit routes.

func _init() -> void:
	world_id = ChromaConstants.WORLD_NEON_CITY
	world_name = "Neon City"

func generate_waypoints() -> void:
	waypoints.clear()
	# 16-point urban highway loop with straights, 90-degree corners, and an underpass
	var raw_points = [
		Vector3(0, 0, 0),         # 0 Start/Finish line
		Vector3(0, 0, -80),       # 1 North Boulevard
		Vector3(0, 0, -160),      # 2 Central Intersection
		Vector3(50, 0, -210),     # 3 Northeast Curve
		Vector3(120, 0, -210),    # 4 Tech Plaza East
		Vector3(180, 0, -160),    # 5 East Overpass Incline
		Vector3(180, 4, -80),     # 6 Elevated Skyway
		Vector3(180, 4, 0),       # 7 Skyway South
		Vector3(140, 2, 70),      # 8 Skyway Descent Ramp
		Vector3(80, 0, 100),      # 9 Neon Alley Entry
		Vector3(20, -2, 100),     # 10 Subterranean Tunnel Underpass
		Vector3(-50, -2, 100),    # 11 Tunnel Midpoint
		Vector3(-100, 0, 80),     # 12 Tunnel Exit / West Plaza
		Vector3(-100, 0, 0),      # 13 West Boulevard
		Vector3(-80, 0, -40),     # 14 Shortcut Chicane
		Vector3(-30, 0, 0)        # 15 Home Stretch
	]
	for p in raw_points:
		waypoints.append(p)

	player_spawn_transform = Transform3D(Basis(), Vector3(0, 0.4, 0))

	# Pre-configure traffic spawners along various segments
	traffic_spawn_data = [
		{"waypoint_idx": 2, "color": ChromaConstants.ChromaColor.COBALT, "speed": 22.0},
		{"waypoint_idx": 4, "color": ChromaConstants.ChromaColor.SOLAR, "speed": 20.0},
		{"waypoint_idx": 7, "color": ChromaConstants.ChromaColor.EMERALD, "speed": 24.0},
		{"waypoint_idx": 11, "color": ChromaConstants.ChromaColor.MAGENTA, "speed": 21.0},
		{"waypoint_idx": 13, "color": ChromaConstants.ChromaColor.CYAN, "speed": 23.0}
	]

func build_road_mesh() -> void:
	for i in range(waypoints.size()):
		var p1 = waypoints[i]
		var p2 = waypoints[(i + 1) % waypoints.size()]
		add_road_segment(p1, p2, 14.0)

		# Add outer guardrails
		var dir = (p2 - p1).normalized()
		var right = Vector3(-dir.z, 0, dir.x)
		var center = (p1 + p2) * 0.5
		var barrier_len = p1.distance_to(p2)

		var barrier_l = _create_barrier(center - right * 7.2, dir, barrier_len)
		road_container.add_child(barrier_l)

		var barrier_r = _create_barrier(center + right * 7.2, dir, barrier_len)
		road_container.add_child(barrier_r)

func build_checkpoints() -> void:
	checkpoints.clear()
	# 6 Gate locations distributed around the city
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

		gate.position = wp
		if dir.length_squared() > 0.001:
			gate.look_at_from_position(wp, wp + dir, Vector3.UP)

		gates_container.add_child(gate)
		checkpoints.append(gate)

func build_props() -> void:
	# Add neon skyscrapers around city perimeter
	var building_positions = [
		Vector3(-35, 0, -90),
		Vector3(35, 0, -90),
		Vector3(60, 0, -150),
		Vector3(-60, 0, -150),
		Vector3(150, 0, -250),
		Vector3(220, 0, -120),
		Vector3(220, 0, -30),
		Vector3(100, 0, 140),
		Vector3(-140, 0, 120),
		Vector3(-140, 0, -20)
	]
	var colors = ["neon_cyan", "neon_magenta", "neon_orange", "neon_blue"]

	for i in range(building_positions.size()):
		var b_pos = building_positions[i]
		var col_name = colors[i % colors.size()]
		var b = MeshBuilder.build_neon_skyscraper(randf_range(40.0, 75.0), 22.0, 22.0, col_name)
		b.position = b_pos
		props_container.add_child(b)

func _create_barrier(pos: Vector3, dir: Vector3, length: float) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.collision_layer = GameConstants.LAYER_WORLD

	var mi = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.4, 1.2, length)
	mi.mesh = b_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.22, 0.28)
	mat.metallic = 0.8
	mi.material_override = mat
	sb.add_child(mi)

	var col = CollisionShape3D.new()
	var col_shape = BoxShape3D.new()
	col_shape.size = Vector3(0.4, 1.2, length)
	col.shape = col_shape
	sb.add_child(col)

	sb.position = pos + Vector3(0, 0.6, 0)
	if dir.length_squared() > 0.001:
		sb.look_at_from_position(sb.position, sb.position + dir, Vector3.UP)

	return sb
