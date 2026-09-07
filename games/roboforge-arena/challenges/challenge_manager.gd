class_name ChallengeManager
extends Node3D

## ChallengeManager: Generates and evaluates the 7 competitive engineering challenge courses
## in RoboForge Arena.

signal challenge_completed(challenge_id: String, time_taken: float, score: int)
signal challenge_failed(challenge_id: String)
signal objective_progress(cur: int, req: int)

var active_challenge_id: String = ""
var challenge_time: float = 0.0
var is_active: bool = false

# Interactive entities
var cargo_crates: Array[RigidBody3D] = []
var energy_cores: Array[RigidBody3D] = []
var ai_helper: Node3D = null
var finish_zone: Area3D = null

func _process(delta: float) -> void:
	if is_active:
		challenge_time += delta

func load_challenge(ch_id: String, arena_parent: Node3D) -> void:
	active_challenge_id = ch_id
	challenge_time = 0.0
	is_active = true

	# Clean previous challenge objects
	for child in arena_parent.get_children():
		child.queue_free()

	match ch_id:
		"obstacle_course":
			_build_obstacle_course(arena_parent)
		"cargo_delivery":
			_build_cargo_delivery(arena_parent)
		"energy_competition":
			_build_energy_competition(arena_parent)
		"maze_escape":
			_build_maze_escape(arena_parent)
		"physics_puzzle":
			_build_physics_puzzle(arena_parent)
		"precision_platform":
			_build_precision_platform(arena_parent)
		"machine_repair":
			_build_machine_repair(arena_parent)
		_:
			_build_obstacle_course(arena_parent)

# ==============================================================================
# 1. OBSTACLE COURSE
# ==============================================================================
func _build_obstacle_course(parent: Node3D) -> void:
	# Starting floor
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(12.0, 1.0, 12.0))

	# Inclined Ramp 1 (requiring torque / grip)
	var ramp1 = _add_slab(parent, Vector3(0, 1.5, -12.0), Vector3(8.0, 0.5, 12.0), "hazard_yellow")
	ramp1.rotation_degrees.x = 18.0

	# Elevated Plateau
	_add_slab(parent, Vector3(0, 3.2, -24.0), Vector3(10.0, 1.0, 10.0))

	# Speed bumps / debris barrier
	for i in range(3):
		_add_slab(parent, Vector3(0, 3.8, -32.0 - i * 3.0), Vector3(8.0, 0.6, 0.8), "dark_hull")

	# Finish pad
	_create_finish_zone(parent, Vector3(0, 3.2, -45.0), 6.0)

# ==============================================================================
# 2. CARGO DELIVERY
# ==============================================================================
func _build_cargo_delivery(parent: Node3D) -> void:
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(16.0, 1.0, 16.0))
	_add_slab(parent, Vector3(0, -0.5, -30.0), Vector3(16.0, 1.0, 16.0))

	# Connecting bridge
	_add_slab(parent, Vector3(0, -0.5, -15.0), Vector3(4.0, 0.8, 16.0), "chassis_carbon")

	# Spawn 2 Heavy Physics Cargo Crates
	_spawn_crate(parent, Vector3(-3.0, 1.0, 2.0))
	_spawn_crate(parent, Vector3(3.0, 1.0, 2.0))

	# Destination Depot Trigger
	_create_cargo_depot(parent, Vector3(0, 0.5, -30.0), 2)

# ==============================================================================
# 3. ENERGY COMPETITION
# ==============================================================================
func _build_energy_competition(parent: Node3D) -> void:
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(28.0, 1.0, 28.0), "chassis_carbon")

	# 3 Glowing Energy Cores scattered
	_spawn_energy_core(parent, Vector3(-8.0, 1.0, -8.0))
	_spawn_energy_core(parent, Vector3(8.0, 1.0, -8.0))
	_spawn_energy_core(parent, Vector3(0.0, 1.0, 10.0))

	# Central Generator Receptacle
	_create_core_receptacle(parent, Vector3(0, 0.5, 0), 3)

# ==============================================================================
# 4. MAZE ESCAPE
# ==============================================================================
func _build_maze_escape(parent: Node3D) -> void:
	_add_slab(parent, Vector3(0, -0.5, -15.0), Vector3(30.0, 1.0, 36.0))

	# Labyrinth Wall Segments
	_add_wall(parent, Vector3(-6.0, 1.5, -5.0), Vector3(1.0, 3.0, 14.0))
	_add_wall(parent, Vector3(6.0, 1.5, -12.0), Vector3(1.0, 3.0, 16.0))
	_add_wall(parent, Vector3(0.0, 1.5, -20.0), Vector3(14.0, 3.0, 1.0))

	# Exit finish zone
	_create_finish_zone(parent, Vector3(0, 0.5, -30.0), 5.0)

# ==============================================================================
# 5. PHYSICS PUZZLE (WEIGHT BALANCE)
# ==============================================================================
func _build_physics_puzzle(parent: Node3D) -> void:
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(24.0, 1.0, 32.0))

	# Weight scale plate
	var plate = Area3D.new()
	plate.position = Vector3(0, 0.1, -10.0)
	var col = CollisionShape3D.new()
	var b = BoxShape3D.new()
	b.size = Vector3(5.0, 0.5, 5.0)
	col.shape = b
	plate.add_child(col)
	parent.add_child(plate)

	# 2 Heavy weight blocks
	_spawn_crate(parent, Vector3(-6.0, 1.0, 4.0))
	_spawn_crate(parent, Vector3(6.0, 1.0, 4.0))

	_create_finish_zone(parent, Vector3(0, 0.5, -22.0), 5.0)

# ==============================================================================
# 6. PRECISION PLATFORM
# ==============================================================================
func _build_precision_platform(parent: Node3D) -> void:
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(8.0, 1.0, 8.0))
	_add_slab(parent, Vector3(0, 1.0, -12.0), Vector3(2.5, 0.6, 12.0), "hazard_yellow") # Narrow beam
	_add_slab(parent, Vector3(0, 2.5, -24.0), Vector3(6.0, 0.8, 6.0))
	_add_slab(parent, Vector3(0, 4.0, -36.0), Vector3(2.5, 0.6, 12.0), "hazard_yellow")
	_create_finish_zone(parent, Vector3(0, 4.5, -46.0), 6.0)

# ==============================================================================
# 7. COOPERATIVE MACHINE REPAIR
# ==============================================================================
func _build_machine_repair(parent: Node3D) -> void:
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(30.0, 1.0, 30.0), "chassis_carbon")

	# Malfunctioning Generator Core
	var gen = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 2.0
	cyl.bottom_radius = 2.5
	cyl.height = 4.0
	gen.mesh = cyl
	gen.material_override = MaterialGenerator.get_material("sci_fi_metal")
	gen.position = Vector3(0, 2.0, -10.0)
	parent.add_child(gen)

	# 2 Repair parts
	_spawn_crate(parent, Vector3(-8.0, 1.0, 5.0))
	_spawn_crate(parent, Vector3(8.0, 1.0, 5.0))

	_create_cargo_depot(parent, Vector3(0, 0.5, -10.0), 2)

# ==============================================================================
# HELPER BUILDERS
# ==============================================================================
func _add_slab(parent: Node3D, pos: Vector3, size: Vector3, mat_name: String = "dark_hull") -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.position = pos

	var mi = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = MaterialGenerator.get_material(mat_name)
	sb.add_child(mi)

	var col = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = size
	col.shape = bs
	sb.add_child(col)

	parent.add_child(sb)
	return sb

func _add_wall(parent: Node3D, pos: Vector3, size: Vector3) -> StaticBody3D:
	return _add_slab(parent, pos, size, "sci_fi_metal")

func _spawn_crate(parent: Node3D, pos: Vector3) -> RigidBody3D:
	var rb = RigidBody3D.new()
	rb.collision_layer = GameConstants.LAYER_WORLD | GameConstants.LAYER_BALL
	rb.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_BALL
	rb.mass = 35.0
	rb.position = pos

	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.2, 1.2, 1.2)
	mi.mesh = box
	mi.material_override = MaterialGenerator.get_material("hazard_yellow")
	rb.add_child(mi)

	var col = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(1.2, 1.2, 1.2)
	col.shape = bs
	rb.add_child(col)

	parent.add_child(rb)
	cargo_crates.append(rb)
	return rb

func _spawn_energy_core(parent: Node3D, pos: Vector3) -> RigidBody3D:
	var rb = RigidBody3D.new()
	rb.collision_layer = GameConstants.LAYER_WORLD | GameConstants.LAYER_BALL
	rb.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_BALL
	rb.mass = 20.0
	rb.position = pos

	var mi = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.2
	mi.mesh = sphere
	mi.material_override = MaterialGenerator.get_material("crystal_cyan")
	rb.add_child(mi)

	var col = CollisionShape3D.new()
	var ss = SphereShape3D.new()
	ss.radius = 0.6
	col.shape = ss
	rb.add_child(col)

	parent.add_child(rb)
	energy_cores.append(rb)
	return rb

func _create_finish_zone(parent: Node3D, pos: Vector3, radius: float) -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = GameConstants.LAYER_PLAYER
	area.position = pos

	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 2.0
	col.shape = cyl
	area.add_child(col)

	var marker = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = radius - 0.4
	torus.outer_radius = radius
	marker.mesh = torus
	marker.material_override = MaterialGenerator.get_material("neon_cyan")
	marker.position = Vector3(0, 0.05, 0)
	area.add_child(marker)

	area.body_entered.connect(func(body: Node3D):
		if body.is_in_group("players") or body.name == "PlayerRobot" or body.has_method("load_blueprint"):
			_complete_active_challenge()
	)
	parent.add_child(area)
	finish_zone = area

func _create_cargo_depot(parent: Node3D, pos: Vector3, target_count: int) -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_BALL
	area.position = pos

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(6.0, 3.0, 6.0)
	col.shape = box
	area.add_child(col)

	var delivered = 0
	area.body_entered.connect(func(body: Node3D):
		if body in cargo_crates:
			delivered += 1
			objective_progress.emit(delivered, target_count)
			if delivered >= target_count:
				_complete_active_challenge()
	)
	parent.add_child(area)

func _create_core_receptacle(parent: Node3D, pos: Vector3, target_count: int) -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_BALL
	area.position = pos

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(5.0, 2.5, 5.0)
	col.shape = box
	area.add_child(col)

	var deposited = 0
	area.body_entered.connect(func(body: Node3D):
		if body in energy_cores:
			deposited += 1
			objective_progress.emit(deposited, target_count)
			if deposited >= target_count:
				_complete_active_challenge()
	)
	parent.add_child(area)

func _complete_active_challenge() -> void:
	if not is_active:
		return
	is_active = false
	var score = maxi(100, int(1000.0 - challenge_time * 10.0))
	challenge_completed.emit(active_challenge_id, challenge_time, score)

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.show_toast_requested.emit("CHALLENGE COMPLETE! (%.1fs)" % challenge_time, Color(0.2, 1.0, 0.4))
