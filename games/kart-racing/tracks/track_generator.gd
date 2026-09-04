class_name TrackGenerator
extends Node3D

signal track_built(waypoints: Array[Vector3], checkpoints: Array[RaceCheckpoint])

@export var track_width: float = 14.0

var waypoints: Array[Vector3] = []
var checkpoints: Array[RaceCheckpoint] = []

func _ready() -> void:
	build_circuit()

func build_circuit() -> void:
	var circuit_nodes: Array[Vector3] = [
		Vector3(0, 0, 0),        # 0: Start/Finish straight
		Vector3(0, 0, -40),      # 1: Straightaway
		Vector3(20, 0, -75),     # 2: Turn 1 (Right curve)
		Vector3(60, 0, -75),     # 3: North Straight
		Vector3(85, 0, -40),     # 4: Turn 2 (Hairpin entry)
		Vector3(85, 0, 10),      # 5: Hairpin apex
		Vector3(60, 0, 45),      # 6: Turn 3
		Vector3(20, 0, 45)       # 7: Final chicane back to 0
	]

	waypoints = circuit_nodes

	# Build track segments between sequential nodes
	for i in range(circuit_nodes.size()):
		var p1 = circuit_nodes[i]
		var p2 = circuit_nodes[(i + 1) % circuit_nodes.size()]
		build_track_segment(p1, p2, i)

	# Place item box powerups
	var item_spots = [
		Vector3(0, 0.2, -25),
		Vector3(40, 0.2, -75),
		Vector3(85, 0.2, -15),
		Vector3(40, 0.2, 45)
	]
	for spot in item_spots:
		var item = PowerUpItem.new()
		item.position = spot
		add_child(item)

	setup_racing_environment()
	track_built.emit(waypoints, checkpoints)

func build_track_segment(start_pt: Vector3, end_pt: Vector3, segment_index: int) -> void:
	var delta = end_pt - start_pt
	var seg_length = delta.length()
	var center = start_pt + delta * 0.5
	var angle_y = atan2(-delta.x, -delta.z)

	# Asphalt road slab
	var road = StaticBody3D.new()
	road.collision_layer = GameConstants.LAYER_WORLD
	road.position = center
	road.rotation.y = angle_y

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(track_width, 0.5, seg_length + 2.0)
	col.shape = box
	road.add_child(col)

	var mesh = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(track_width, 0.5, seg_length + 2.0)
	mesh.mesh = b_mesh
	mesh.material_override = MaterialGenerator.get_material("asphalt_track")
	road.add_child(mesh)

	# Outer Guard Rails
	var rail_w = 0.5
	var rail_h = 1.4
	var left_rail = MeshInstance3D.new()
	var r_mesh = BoxMesh.new()
	r_mesh.size = Vector3(rail_w, rail_h, seg_length + 2.0)
	left_rail.mesh = r_mesh
	left_rail.position = Vector3(-track_width * 0.5, rail_h * 0.5, 0)
	left_rail.material_override = MaterialGenerator.get_material("neon_magenta")
	road.add_child(left_rail)

	var right_rail = MeshInstance3D.new()
	right_rail.mesh = r_mesh
	right_rail.position = Vector3(track_width * 0.5, rail_h * 0.5, 0)
	right_rail.material_override = MaterialGenerator.get_material("neon_cyan")
	road.add_child(right_rail)

	add_child(road)

	# Add checkpoint at the start of each segment
	var cp = RaceCheckpoint.new()
	cp.checkpoint_index = segment_index
	cp.is_finish_line = (segment_index == 0)
	cp.checkpoint_width = track_width
	cp.position = start_pt + Vector3(0, 0.5, 0)
	cp.rotation.y = angle_y
	add_child(cp)
	checkpoints.append(cp)

func setup_racing_environment() -> void:
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.04, 0.05, 0.09)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.25, 0.3, 0.4)
	environment.ambient_light_energy = 1.0
	environment.glow_enabled = true
	env.environment = environment
	add_child(env)

	# Sun
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 45, 0)
	sun.light_color = Color(1.0, 0.96, 0.9)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	add_child(sun)
