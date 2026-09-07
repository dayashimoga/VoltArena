class_name SkyCharacter
extends CharacterBody3D

## SkyCharacter: Third-person 3D exploration and platforming controller for Skybound Odyssey.
## Implements acceleration, sprint, variable-height jump, coyote time, jump buffering,
## double-jump, ledge grab / mantling, glider mechanics, and grappling hook.

signal shard_collected(total: int, amount: int)
signal upgrade_unlocked(upgrade_name: String)
signal energy_changed(current: float, max_energy: float)

@export var walk_speed: float = 6.0
@export var sprint_speed: float = 10.5
@export var acceleration: float = 32.0
@export var friction: float = 28.0
@export var jump_impulse: float = 11.5
@export var double_jump_impulse: float = 10.0
@export var gravity: float = 24.0
@export var glider_gravity: float = 4.0
@export var glider_speed: float = 12.0

# Traversal Upgrade Flags
@export var has_double_jump: bool = true
@export var has_glider: bool = true
@export var has_grapple: bool = true

# State
var can_double_jump: bool = false
var is_gliding: bool = false
var is_grappling: bool = false
var is_mantling: bool = false
var grapple_target: Vector3 = Vector3.ZERO
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var last_safe_grounded_transform: Transform3D = Transform3D()

# Collectibles & Energy
var shards_collected: int = 0
var max_stamina: float = 100.0
var current_stamina: float = 100.0

# Visuals & Components
var visual_node: Node3D
var glider_mesh: Node3D
var ledge_ray_forward: RayCast3D
var ledge_ray_down: RayCast3D

func _ready() -> void:
	add_to_group("players")
	collision_layer = GameConstants.LAYER_PLAYER
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PICKUPS

	last_safe_grounded_transform = global_transform
	setup_visuals()
	setup_ledge_detectors()

func setup_visuals() -> void:
	visual_node = Node3D.new()
	visual_node.name = "CharacterVisual"
	add_child(visual_node)

	# Articulated Adventurer Model
	var body_mat = MaterialGenerator.get_material("ancient_stone")
	var cloak_mat = MaterialGenerator.get_material("neon_cyan")
	var skin_mat = MaterialGenerator.get_material("temple_gold")

	# Torso
	var torso = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.55, 0.75, 0.35)
	torso.mesh = t_box
	torso.material_override = body_mat
	torso.position = Vector3(0, 1.05, 0)
	visual_node.add_child(torso)

	# Head
	var head = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.35, 0.38, 0.35)
	head.mesh = h_box
	head.material_override = skin_mat
	head.position = Vector3(0, 1.62, 0)
	visual_node.add_child(head)

	# Flowing Adventurer Cloak / Cape
	var cape = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.5, 0.85, 0.06)
	cape.mesh = c_box
	cape.material_override = cloak_mat
	cape.position = Vector3(0, 0.95, 0.20)
	visual_node.add_child(cape)

	# Foldable Glider Wings
	glider_mesh = Node3D.new()
	glider_mesh.name = "GliderWings"
	glider_mesh.visible = false
	var wing_l = MeshInstance3D.new()
	var w_box = BoxMesh.new()
	w_box.size = Vector3(1.4, 0.04, 0.7)
	wing_l.mesh = w_box
	wing_l.material_override = cloak_mat
	wing_l.position = Vector3(-0.9, 1.35, 0.1)
	wing_l.rotation_degrees.z = -12.0
	glider_mesh.add_child(wing_l)

	var wing_r = MeshInstance3D.new()
	wing_r.mesh = w_box
	wing_r.material_override = cloak_mat
	wing_r.position = Vector3(0.9, 1.35, 0.1)
	wing_r.rotation_degrees.z = 12.0
	glider_mesh.add_child(wing_r)
	visual_node.add_child(glider_mesh)

	# Collision shape
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.75
	col.shape = cap
	col.position = Vector3(0, 0.88, 0)
	add_child(col)

func setup_ledge_detectors() -> void:
	# Forward raycast at chest height to detect wall
	ledge_ray_forward = RayCast3D.new()
	ledge_ray_forward.target_position = Vector3(0, 0, -0.9)
	ledge_ray_forward.position = Vector3(0, 1.3, 0)
	ledge_ray_forward.collision_mask = GameConstants.LAYER_WORLD
	add_child(ledge_ray_forward)

	# Downward raycast above forward ray to find ledge top
	ledge_ray_down = RayCast3D.new()
	ledge_ray_down.target_position = Vector3(0, -0.9, 0)
	ledge_ray_down.position = Vector3(0, 2.0, -0.85)
	ledge_ray_down.collision_mask = GameConstants.LAYER_WORLD
	add_child(ledge_ray_down)

func _physics_process(delta: float) -> void:
	# Kill-plane fail-safe recovery
	if global_position.y < -15.0:
		recover_to_safe_ground()
		return

	if is_mantling:
		return

	var on_floor = is_on_floor()

	# Safe grounded transform tracking
	if on_floor:
		coyote_timer = 0.15
		can_double_jump = true
		is_gliding = false
		if glider_mesh:
			glider_mesh.visible = false
		if velocity.length_squared() < 4.0 and global_position.y > -5.0:
			last_safe_grounded_transform = global_transform
		current_stamina = minf(max_stamina, current_stamina + 25.0 * delta)
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		if not is_grappling:
			var effective_gravity = glider_gravity if is_gliding else gravity
			velocity.y -= effective_gravity * delta

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	handle_input(delta)
	check_ledge_mantle()

	move_and_slide()

func handle_input(delta: float) -> void:
	var im = GameConstants.get_autoload(self, "InputManager")
	var move_dir = Vector3.ZERO
	var raw_x = 0.0
	var raw_z = 0.0

	if Input.is_action_pressed("move_forward"): raw_z -= 1.0
	if Input.is_action_pressed("move_back"): raw_z += 1.0
	if Input.is_action_pressed("move_left"): raw_x -= 1.0
	if Input.is_action_pressed("move_right"): raw_x += 1.0

	if im and im.virtual_move_vector.length_squared() > 0.01:
		raw_x = im.virtual_move_vector.x
		raw_z = im.virtual_move_vector.y

	# Camera relative direction
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_basis = cam.global_transform.basis
		var fwd = -cam_basis.z
		fwd.y = 0.0
		fwd = fwd.normalized()
		var right = cam_basis.x
		right.y = 0.0
		right = right.normalized()
		move_dir = (right * raw_x + fwd * -raw_z).normalized()
	else:
		move_dir = Vector3(raw_x, 0, raw_z).normalized()

	var is_sprinting = Input.is_action_pressed("sprint") and current_stamina > 10.0
	var target_speed = sprint_speed if is_sprinting else walk_speed

	if is_sprinting and move_dir.length_squared() > 0.1:
		current_stamina = maxf(0.0, current_stamina - 15.0 * delta)
		energy_changed.emit(current_stamina, max_stamina)

	# Grappling hook travel
	if is_grappling:
		var to_anchor = (grapple_target - global_position)
		var dist = to_anchor.length()
		if dist < 1.5:
			is_grappling = false
			velocity = to_anchor.normalized() * 8.0 + Vector3.UP * 5.0
		else:
			velocity = to_anchor.normalized() * 22.0
		return

	# Glider flight
	if is_gliding:
		if move_dir.length_squared() > 0.01:
			var glide_vel = move_dir * glider_speed
			velocity.x = move_toward(velocity.x, glide_vel.x, acceleration * 0.8 * delta)
			velocity.z = move_toward(velocity.z, glide_vel.z, acceleration * 0.8 * delta)
			visual_node.rotation.y = lerp_angle(visual_node.rotation.y, atan2(-move_dir.x, -move_dir.z), delta * 8.0)
		return

	# Ground / Air Locomotion
	if move_dir.length_squared() > 0.01:
		var target_vel = move_dir * target_speed
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
		visual_node.rotation.y = lerp_angle(visual_node.rotation.y, atan2(-move_dir.x, -move_dir.z), delta * 12.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	# Jump handling
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.12

	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0:
			perform_jump()
			jump_buffer_timer = 0.0
		elif can_double_jump and has_double_jump:
			perform_double_jump()
			jump_buffer_timer = 0.0
		elif has_glider and not is_on_floor() and velocity.y < 0.0:
			toggle_glider(true)
			jump_buffer_timer = 0.0

	# Release glider if jump released
	if is_gliding and Input.is_action_just_released("jump"):
		toggle_glider(false)

	# Grapple launch
	if Input.is_action_just_pressed("fire") and has_grapple:
		try_launch_grapple()

func perform_jump() -> void:
	velocity.y = jump_impulse
	coyote_timer = 0.0
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("jump", 1.0, 1.0)

func perform_double_jump() -> void:
	velocity.y = double_jump_impulse
	can_double_jump = false
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("jump", 1.3, 1.2)

func toggle_glider(enable: bool) -> void:
	is_gliding = enable
	if glider_mesh:
		glider_mesh.visible = enable
	if enable:
		velocity.y = maxf(velocity.y, -1.5)
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("boost", 0.8, 1.0)

func try_launch_grapple() -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return

	var space = get_world_3d().direct_space_state
	var ray_start = cam.global_position
	var ray_end = ray_start - cam.global_transform.basis.z * 35.0
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = GameConstants.LAYER_WORLD

	var hit = space.intersect_ray(query)
	if not hit.is_empty():
		grapple_target = hit.position
		is_grappling = true
		is_gliding = false
		if glider_mesh:
			glider_mesh.visible = false
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("weapon_beam", 1.4, 1.2)

func check_ledge_mantle() -> void:
	if is_on_floor() or is_mantling or not ledge_ray_forward or not ledge_ray_down:
		return

	if ledge_ray_forward.is_colliding():
		if ledge_ray_down.is_colliding():
			var ledge_point = ledge_ray_down.get_collision_point()
			# Valid climbable ledge detected!
			start_mantle(ledge_point + Vector3(0, 0.9, 0))

func start_mantle(target_pos: Vector3) -> void:
	is_mantling = true
	velocity = Vector3.ZERO
	is_gliding = false
	if glider_mesh:
		glider_mesh.visible = false

	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		is_mantling = false
		velocity = Vector3.ZERO
	)
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("jump", 0.8, 0.9)

func collect_shard(amount: int = 1) -> void:
	shards_collected += amount
	shard_collected.emit(shards_collected, amount)
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.show_toast_requested.emit("ENERGY SHARDS: %d" % shards_collected, Color(0.2, 0.9, 1.0))
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("pickup_health", 1.2, 1.4)

func recover_to_safe_ground() -> void:
	velocity = Vector3.ZERO
	global_transform = last_safe_grounded_transform
	global_position.y += 0.5
	is_gliding = false
	is_grappling = false
	is_mantling = false
	if glider_mesh:
		glider_mesh.visible = false
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("respawn", 1.0, 1.2)
