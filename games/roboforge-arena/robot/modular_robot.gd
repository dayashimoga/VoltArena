class_name ModularRobot
extends CharacterBody3D

## ModularRobot: Physically simulated customizable robot entity.
## Assembles chassis, locomotion, power core, and modules from blueprints.
## Real physics: mass, acceleration, traction, grabbing, boosting, and self-righting.

signal power_updated(current: float, max_pwr: float)
signal object_grabbed(obj: Node3D)
signal object_released()

const RobotDataScript = preload("res://games/roboforge-arena/robot/robot_data.gd")

@export var is_player_controlled: bool = true

var blueprint: Dictionary = {}
var stats: Dictionary = {}

var current_power: float = 100.0
var forward_speed: float = 0.0
var is_boosting: bool = false
var is_magnetic_active: bool = false
var grabbed_object: RigidBody3D = null

# Visual & Attachment Nodes
var visual_root: Node3D
var front_socket: Marker3D
var top_socket: Marker3D
var rear_socket: Marker3D
var grab_area: Area3D
var magnet_area: Area3D

func _ready() -> void:
	collision_layer = GameConstants.LAYER_PLAYER if is_player_controlled else GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PICKUPS | GameConstants.LAYER_BALL
	if blueprint.is_empty():
		load_blueprint(RobotDataScript.get_default_blueprint())

func load_blueprint(bp: Dictionary) -> void:
	blueprint = bp.duplicate()
	stats = RobotDataScript.calculate_stats(blueprint)
	current_power = stats.get("power_capacity", 100.0)
	rebuild_visuals()

func rebuild_visuals() -> void:
	if visual_root:
		visual_root.queue_free()

	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	var ch_id = blueprint.get("chassis", "scout")
	var loc_id = blueprint.get("locomotion", "wheels")
	var modules: Array = blueprint.get("modules", [])

	# 1. Main Chassis Mesh
	var ch_mesh = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	var ch_size = Vector3(1.8, 0.7, 2.4)
	if ch_id == "titan":
		ch_size = Vector3(2.4, 0.9, 3.2)
	elif ch_id == "scout":
		ch_size = Vector3(1.4, 0.55, 1.8)
	b_box.size = ch_size
	ch_mesh.mesh = b_box
	ch_mesh.material_override = MaterialGenerator.get_material("chassis_carbon")
	ch_mesh.position = Vector3(0, 0.6, 0)
	visual_root.add_child(ch_mesh)

	# Hazard yellow decorative trim
	var trim = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(ch_size.x + 0.05, 0.1, ch_size.z * 0.8)
	trim.mesh = t_box
	trim.material_override = MaterialGenerator.get_material("hazard_yellow")
	trim.position = Vector3(0, 0.7, 0)
	visual_root.add_child(trim)

	# 2. Locomotion Assemblies
	if loc_id == "wheels":
		_build_wheels(ch_size)
	elif loc_id == "tracks":
		_build_tracks(ch_size)
	elif loc_id == "legs":
		_build_legs(ch_size)

	# 3. Sockets for Modules
	front_socket = Marker3D.new()
	front_socket.position = Vector3(0, 0.6, -ch_size.z * 0.5 - 0.2)
	visual_root.add_child(front_socket)

	top_socket = Marker3D.new()
	top_socket.position = Vector3(0, 0.6 + ch_size.y * 0.5 + 0.1, 0)
	visual_root.add_child(top_socket)

	rear_socket = Marker3D.new()
	rear_socket.position = Vector3(0, 0.6, ch_size.z * 0.5 + 0.2)
	visual_root.add_child(rear_socket)

	# 4. Attach Installed Modules
	for mod_id in modules:
		_attach_module(mod_id)

	# Update collision shape
	for c in get_children():
		if c is CollisionShape3D:
			c.queue_free()

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(ch_size.x + 0.4, ch_size.y + 0.8, ch_size.z + 0.4)
	col.shape = box_shape
	col.position = Vector3(0, 0.7, 0)
	add_child(col)

func _build_wheels(ch_size: Vector3) -> void:
	var positions = [
		Vector3(-ch_size.x * 0.5 - 0.2, 0.35, -ch_size.z * 0.35),
		Vector3(ch_size.x * 0.5 + 0.2, 0.35, -ch_size.z * 0.35),
		Vector3(-ch_size.x * 0.5 - 0.2, 0.35, ch_size.z * 0.35),
		Vector3(ch_size.x * 0.5 + 0.2, 0.35, ch_size.z * 0.35)
	]
	for p in positions:
		var w = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.35
		cyl.bottom_radius = 0.35
		cyl.height = 0.25
		w.mesh = cyl
		w.material_override = MaterialGenerator.get_material("tread_rubber")
		w.rotation_degrees.z = 90.0
		w.position = p
		visual_root.add_child(w)

func _build_tracks(ch_size: Vector3) -> void:
	for side in [-1.0, 1.0]:
		var tr = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.35, 0.55, ch_size.z * 0.95)
		tr.mesh = box
		tr.material_override = MaterialGenerator.get_material("dark_hull")
		tr.position = Vector3(side * (ch_size.x * 0.5 + 0.2), 0.32, 0)
		visual_root.add_child(tr)

func _build_legs(ch_size: Vector3) -> void:
	for side in [-1.0, 1.0]:
		for fwd in [-1.0, 1.0]:
			var leg = Node3D.new()
			leg.position = Vector3(side * (ch_size.x * 0.5 + 0.1), 0.4, fwd * (ch_size.z * 0.35))

			var upper = MeshInstance3D.new()
			var cyl1 = CylinderMesh.new()
			cyl1.top_radius = 0.08
			cyl1.bottom_radius = 0.08
			cyl1.height = 0.5
			upper.mesh = cyl1
			upper.material_override = MaterialGenerator.get_material("hydraulic_chrome")
			upper.rotation_degrees.x = 25.0 * fwd
			upper.position = Vector3(0, -0.1, 0)
			leg.add_child(upper)
			visual_root.add_child(leg)

func _attach_module(mod_id: String) -> void:
	match mod_id:
		"hydraulic_grabber":
			var claw = MeshInstance3D.new()
			var c_box = BoxMesh.new()
			c_box.size = Vector3(0.8, 0.35, 0.6)
			claw.mesh = c_box
			claw.material_override = MaterialGenerator.get_material("hydraulic_chrome")
			front_socket.add_child(claw)

			grab_area = Area3D.new()
			grab_area.collision_layer = 0
			grab_area.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_BALL | GameConstants.LAYER_PICKUPS
			var col = CollisionShape3D.new()
			var b = BoxShape3D.new()
			b.size = Vector3(1.2, 1.0, 1.2)
			col.shape = b
			col.position = Vector3(0, 0, -0.6)
			grab_area.add_child(col)
			front_socket.add_child(grab_area)
		"magnetic_arm":
			var arm = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.12
			cyl.bottom_radius = 0.15
			cyl.height = 0.7
			arm.mesh = cyl
			arm.material_override = MaterialGenerator.get_material("copper_core")
			arm.position = Vector3(0, 0.35, 0)
			top_socket.add_child(arm)

			magnet_area = Area3D.new()
			magnet_area.collision_layer = 0
			magnet_area.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_BALL | GameConstants.LAYER_PICKUPS
			var col = CollisionShape3D.new()
			var s = SphereShape3D.new()
			s.radius = 5.0
			col.shape = s
			magnet_area.add_child(col)
			top_socket.add_child(magnet_area)
		"rocket_booster":
			var thruster = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.18
			cyl.bottom_radius = 0.28
			cyl.height = 0.5
			thruster.mesh = cyl
			thruster.material_override = MaterialGenerator.get_material("neon_orange")
			thruster.rotation_degrees.x = 90.0
			rear_socket.add_child(thruster)
		"cargo_bed":
			var bed = MeshInstance3D.new()
			var b_box = BoxMesh.new()
			b_box.size = Vector3(1.2, 0.15, 1.0)
			bed.mesh = b_box
			bed.material_override = MaterialGenerator.get_material("dark_hull")
			rear_socket.add_child(bed)
		"kinetic_shield":
			var shield = MeshInstance3D.new()
			var torus = TorusMesh.new()
			torus.inner_radius = 1.0
			torus.outer_radius = 1.2
			shield.mesh = torus
			shield.material_override = MaterialGenerator.get_material("neon_cyan")
			shield.position = Vector3(0, 0.6, 0)
			top_socket.add_child(shield)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 24.0 * delta

	# Regenerate power
	var rech = stats.get("recharge_rate", 15.0)
	var max_p = stats.get("power_capacity", 100.0)
	current_power = minf(max_p, current_power + rech * delta)
	power_updated.emit(current_power, max_p)

	if is_player_controlled:
		handle_player_input(delta)

	# Handle grabbed object physical tracking
	if grabbed_object and is_instance_valid(grabbed_object):
		var hold_pos = front_socket.global_position - global_transform.basis.z * 0.8
		grabbed_object.global_position = grabbed_object.global_position.lerp(hold_pos, delta * 18.0)
		grabbed_object.linear_velocity = velocity

	# Magnetic attraction field
	if is_magnetic_active and magnet_area:
		for b in magnet_area.get_overlapping_bodies():
			if b is RigidBody3D and b != grabbed_object:
				var to_magnet = (top_socket.global_position - b.global_position).normalized()
				b.apply_central_force(to_magnet * 45.0)

	move_and_slide()

func handle_player_input(delta: float) -> void:
	var im = GameConstants.get_autoload(self, "InputManager")
	var throttle = 0.0
	var steer = 0.0

	if Input.is_action_pressed("move_forward"): throttle += 1.0
	if Input.is_action_pressed("move_back"): throttle -= 1.0
	if Input.is_action_pressed("move_left"): steer += 1.0
	if Input.is_action_pressed("move_right"): steer -= 1.0

	if im and im.virtual_move_vector.length_squared() > 0.01:
		steer = -im.virtual_move_vector.x
		throttle = -im.virtual_move_vector.y

	# Steer
	var turn_rate = stats.get("turning_speed", 2.8)
	if abs(forward_speed) > 0.2 or is_on_floor():
		rotate_y(steer * turn_rate * delta)

	# Acceleration & Braking
	var top_spd = stats.get("top_speed", 18.0)
	var accel = stats.get("acceleration", 25.0)
	if is_boosting and current_power > 15.0:
		top_spd *= 1.65
		current_power = maxf(0.0, current_power - 40.0 * delta)

	if throttle > 0.0:
		forward_speed = move_toward(forward_speed, top_spd, accel * delta)
	elif throttle < 0.0:
		forward_speed = move_toward(forward_speed, -top_spd * 0.5, accel * 1.2 * delta)
	else:
		forward_speed = move_toward(forward_speed, 0.0, 18.0 * delta)

	var fwd = -transform.basis.z
	velocity.x = fwd.x * forward_speed
	velocity.z = fwd.z * forward_speed

	# Jump (legs locomotion)
	var j_force = stats.get("jump_force", 0.0)
	if Input.is_action_just_pressed("jump") and is_on_floor() and j_force > 0.0:
		velocity.y = j_force
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("jump", 0.9, 1.1)

	# Tool / Module inputs
	if Input.is_action_just_pressed("fire"):
		toggle_grab()

	is_boosting = Input.is_action_pressed("boost") and blueprint.get("modules", []).has("rocket_booster")
	is_magnetic_active = Input.is_action_pressed("crouch") and blueprint.get("modules", []).has("magnetic_arm")

	# Self-righting recovery
	if Input.is_action_just_pressed("interact"):
		self_right()

func toggle_grab() -> void:
	if grabbed_object:
		release_object()
	else:
		try_grab_object()

func try_grab_object() -> void:
	if not grab_area:
		return
	for b in grab_area.get_overlapping_bodies():
		if b is RigidBody3D and b != self:
			grabbed_object = b
			grabbed_object.freeze = false
			object_grabbed.emit(b)
			var am = GameConstants.get_autoload(self, "AudioManager")
			if am:
				am.play_sound("pickup_ammo", 1.2, 1.2)
			break

func release_object() -> void:
	if grabbed_object:
		grabbed_object.linear_velocity = -global_transform.basis.z * 5.0 + Vector3.UP * 2.0
		grabbed_object = null
		object_released.emit()
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("pickup_health", 0.9, 1.0)

func self_right() -> void:
	rotation.x = 0.0
	rotation.z = 0.0
	velocity = Vector3.ZERO
	global_position.y += 0.5
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("respawn", 1.2, 1.0)
