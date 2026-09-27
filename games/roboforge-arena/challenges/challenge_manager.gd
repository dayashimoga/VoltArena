class_name ChallengeManager
extends Node3D

## ChallengeManager: Generates and evaluates the 7 competitive engineering challenge courses
## in RoboForge Arena with distinct physical and engineering tradeoffs.

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
	cargo_crates.clear()
	energy_cores.clear()

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
# 1. OBSTACLE COURSE (High-Incline Ramps, Speed Bumps, Debris)
# ==============================================================================
func _build_obstacle_course(parent: Node3D) -> void:
	# Starting floor with hazard yellow grid
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(14.0, 1.0, 14.0), "chassis_carbon")

	# Inclined Ramp 1 (22 degrees - requires high torque or crawler tracks)
	var ramp1 = _add_slab(parent, Vector3(0, 2.2, -14.0), Vector3(9.0, 0.6, 14.0), "hazard_yellow")
	ramp1.rotation_degrees.x = 22.0

	# Elevated Plateau 1
	_add_slab(parent, Vector3(0, 4.8, -26.0), Vector3(12.0, 1.0, 12.0), "dark_hull")

	# Staggered Debris Speed Bumps
	for i in range(4):
		var bump = _add_slab(parent, Vector3((i % 2 - 0.5) * 2.0, 5.5, -34.0 - i * 3.5), Vector3(9.0, 0.8, 1.2), "sci_fi_metal")
		bump.rotation_degrees.z = (i % 2 - 0.5) * 8.0

	# Elevated Plateau 2 & Finish
	_add_slab(parent, Vector3(0, 4.8, -52.0), Vector3(14.0, 1.0, 14.0), "chassis_carbon")
	_create_finish_zone(parent, Vector3(0, 5.0, -52.0), 6.5)

# ==============================================================================
# 2. CARGO DELIVERY (Heavy Magnetic Crates over Narrow Bridge)
# ==============================================================================
func _build_cargo_delivery(parent: Node3D) -> void:
	# Depot Origin
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(18.0, 1.0, 18.0), "chassis_carbon")

	# Narrow Suspension Bridge over Chasm
	_add_slab(parent, Vector3(0, -0.5, -20.0), Vector3(4.5, 0.8, 22.0), "hazard_yellow")

	# Side Guardrails
	_add_wall(parent, Vector3(-2.4, 0.5, -20.0), Vector3(0.3, 1.2, 22.0))
	_add_wall(parent, Vector3(2.4, 0.5, -20.0), Vector3(0.3, 1.2, 22.0))

	# Destination Loading Bay
	_add_slab(parent, Vector3(0, -0.5, -40.0), Vector3(18.0, 1.0, 18.0), "dark_hull")

	# 2 Heavy Physics Cargo Crates
	_spawn_crate(parent, Vector3(-4.0, 1.2, 3.0))
	_spawn_crate(parent, Vector3(4.0, 1.2, 3.0))

	# Destination Depot Receptacle
	_create_cargo_depot(parent, Vector3(0, 0.5, -40.0), 2)

# ==============================================================================
# 3. ENERGY COMPETITION (Timed Collection of Scattered Cores)
# ==============================================================================
func _build_energy_competition(parent: Node3D) -> void:
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(34.0, 1.0, 34.0), "chassis_carbon")

	# Peripheral barrier walls
	_add_wall(parent, Vector3(0, 1.5, -17.0), Vector3(34.0, 3.0, 1.0))
	_add_wall(parent, Vector3(0, 1.5, 17.0), Vector3(34.0, 3.0, 1.0))
	_add_wall(parent, Vector3(-17.0, 1.5, 0), Vector3(1.0, 3.0, 34.0))
	_add_wall(parent, Vector3(17.0, 1.5, 0), Vector3(1.0, 3.0, 34.0))

	# 3 Glowing Energy Cores scattered in arena
	_spawn_energy_core(parent, Vector3(-10.0, 1.0, -10.0))
	_spawn_energy_core(parent, Vector3(10.0, 1.0, -10.0))
	_spawn_energy_core(parent, Vector3(0.0, 1.0, 12.0))

	# Central Generator Receptacle
	_create_core_receptacle(parent, Vector3(0, 0.5, 0), 3)

# ==============================================================================
# 4. MAZE ESCAPE (Tight Labyrinth with Dead Ends)
# ==============================================================================
func _build_maze_escape(parent: Node3D) -> void:
	_add_slab(parent, Vector3(0, -0.5, -18.0), Vector3(36.0, 1.0, 42.0), "dark_hull")

	# Labyrinth Wall Layout
	_add_wall(parent, Vector3(-8.0, 1.8, -6.0), Vector3(1.0, 3.6, 16.0))
	_add_wall(parent, Vector3(8.0, 1.8, -14.0), Vector3(1.0, 3.6, 20.0))
	_add_wall(parent, Vector3(0.0, 1.8, -24.0), Vector3(16.0, 3.6, 1.0))
	_add_wall(parent, Vector3(-12.0, 1.8, -20.0), Vector3(8.0, 3.6, 1.0))
	_add_wall(parent, Vector3(4.0, 1.8, -32.0), Vector3(12.0, 3.6, 1.0))

	# Finish zone at far end of labyrinth
	_create_finish_zone(parent, Vector3(0, 0.5, -36.0), 5.5)

# ==============================================================================
# 5. PHYSICS PUZZLE (Weight Balance Platform)
# ==============================================================================
func _build_physics_puzzle(parent: Node3D) -> void:
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(26.0, 1.0, 36.0), "chassis_carbon")

	# Balance Plate Area
	var plate = Area3D.new()
	plate.position = Vector3(0, 0.1, -12.0)
	var col = CollisionShape3D.new()
	var b = BoxShape3D.new()
	b.size = Vector3(6.0, 0.6, 6.0)
	col.shape = b
	plate.add_child(col)
	parent.add_child(plate)

	# 2 Heavy weight blocks
	_spawn_crate(parent, Vector3(-7.0, 1.2, 5.0))
	_spawn_crate(parent, Vector3(7.0, 1.2, 5.0))

	_create_finish_zone(parent, Vector3(0, 0.5, -26.0), 5.5)

# ==============================================================================
# 6. PRECISION PLATFORM (Narrow Beams & Elevated Steps)
# ==============================================================================
func _build_precision_platform(parent: Node3D) -> void:
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(9.0, 1.0, 9.0), "dark_hull")
	# Narrow beam 1
	_add_slab(parent, Vector3(0, 1.2, -14.0), Vector3(2.8, 0.6, 14.0), "hazard_yellow")
	# Mid plateau
	_add_slab(parent, Vector3(0, 2.8, -28.0), Vector3(7.0, 0.8, 7.0), "chassis_carbon")
	# Narrow beam 2
	_add_slab(parent, Vector3(0, 4.4, -42.0), Vector3(2.8, 0.6, 14.0), "hazard_yellow")
	# Finish apex
	_add_slab(parent, Vector3(0, 5.2, -54.0), Vector3(10.0, 1.0, 10.0), "dark_hull")
	_create_finish_zone(parent, Vector3(0, 5.4, -54.0), 6.5)

# ==============================================================================
# 7. MACHINE REPAIR (Generator Drone Stations)
# ==============================================================================
func _build_machine_repair(parent: Node3D) -> void:
	_add_slab(parent, Vector3(0, -0.5, 0), Vector3(32.0, 1.0, 32.0), "chassis_carbon")

	# Generator Drone Station
	var gen = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 2.2
	cyl.bottom_radius = 2.8
	cyl.height = 4.2
	gen.mesh = cyl
	gen.material_override = MaterialGenerator.get_material("sci_fi_metal")
	gen.position = Vector3(0, 2.1, -12.0)
	parent.add_child(gen)

	# 2 Power Cores to install
	_spawn_crate(parent, Vector3(-9.0, 1.2, 6.0))
	_spawn_crate(parent, Vector3(9.0, 1.2, 6.0))

	_create_cargo_depot(parent, Vector3(0, 0.5, -12.0), 2)

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
	box.size = Vector3(1.3, 1.3, 1.3)
	mi.mesh = box
	mi.material_override = MaterialGenerator.get_material("hazard_yellow")
	rb.add_child(mi)

	var col = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(1.3, 1.3, 1.3)
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
	sphere.radius = 0.65
	sphere.height = 1.3
	mi.mesh = sphere
	mi.material_override = MaterialGenerator.get_material("neon_cyan")
	rb.add_child(mi)

	var col = CollisionShape3D.new()
	var ss = SphereShape3D.new()
	ss.radius = 0.65
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
	torus.inner_radius = radius - 0.5
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
	box.size = Vector3(7.0, 3.5, 7.0)
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
	box.size = Vector3(6.0, 3.0, 6.0)
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
