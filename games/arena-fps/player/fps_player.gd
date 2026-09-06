class_name FPSPlayer
extends CharacterBody3D

@export var walk_speed: float = 7.0
@export var sprint_speed: float = 11.5
@export var crouch_speed: float = 3.5
@export var jump_velocity: float = 8.5
@export var gravity: float = 22.0
@export var acceleration: float = 16.0
@export var air_control: float = 0.4

# Camera & Recoil
var camera_pivot: Node3D
var camera: Camera3D
var weapon_holder: Node3D
var health_component: HealthComponent

var current_recoil_pitch: float = 0.0
var current_recoil_yaw: float = 0.0
var bob_phase: float = 0.0
var default_camera_y: float = 1.4
var is_crouching: bool = false

# Weapons Inventory
var weapons: Array[WeaponBase] = []
var current_weapon_index: int = 0

func _ready() -> void:
	add_to_group("players")
	collision_layer = GameConstants.LAYER_PLAYER
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_ENEMIES | GameConstants.LAYER_PICKUPS

	setup_default_nodes()
	setup_weapons()
	connect_health()

	var im = GameConstants.get_autoload(self, "InputManager")
	if im:
		im.capture_mouse(true)

var health_connected: bool = false

func setup_default_nodes() -> void:
	if not camera_pivot:
		camera_pivot = Node3D.new()
		camera_pivot.name = "CameraPivot"
		camera_pivot.position = Vector3(0, default_camera_y, 0)
		camera_pivot.rotation.x = deg_to_rad(-8.0)
		add_child(camera_pivot)

		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera.current = true
		camera_pivot.add_child(camera)

		weapon_holder = Node3D.new()
		weapon_holder.name = "WeaponHolder"
		weapon_holder.position = Vector3(0.24, -0.22, -0.48)
		camera.add_child(weapon_holder)

	if not health_component:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		add_child(health_component)

	if not get_node_or_null("PlayerVisual"):
		var char_model = ModelCache.get_character("soldier")
		if char_model:
			char_model.name = "PlayerVisual"
			char_model.visible = false
			add_child(char_model)

func set_third_person(enabled: bool) -> void:
	var pv = get_node_or_null("PlayerVisual")
	if pv and is_instance_valid(pv):
		pv.visible = enabled
	if weapon_holder and is_instance_valid(weapon_holder):
		weapon_holder.visible = not enabled

	# Collision shape
	if not get_node_or_null("PlayerCollision"):
		var col = CollisionShape3D.new()
		col.name = "PlayerCollision"
		var cap = CapsuleShape3D.new()
		cap.radius = 0.45
		cap.height = 1.8
		col.shape = cap
		col.position = Vector3(0, 0.9, 0)
		add_child(col)

func setup_weapons() -> void:
	if not weapons.is_empty():
		return
	# Add the 5 weapons
	var w1 = WeaponBase.new() # Pulse rifle
	var w2 = ScatterCannon.new()
	var w3 = RailDriver.new()
	var w4 = GrenadeLauncher.new()
	var w5 = PlasmaCutter.new()

	var list = [w1, w2, w3, w4, w5]
	for w in list:
		w.owner_entity = self
		weapon_holder.add_child(w)
		w.visible = false
		weapons.append(w)

	select_weapon(0)

func select_weapon(index: int) -> void:
	if weapons.is_empty():
		return
	for w in weapons:
		w.visible = false
	current_weapon_index = posmod(index, weapons.size())
	var active_w = weapons[current_weapon_index]
	active_w.visible = true

	var parent = get_parent()
	if parent and parent.has_node("HUD"):
		var hud_node = parent.get_node("HUD")
		if hud_node and hud_node.has_method("highlight_active_weapon"):
			hud_node.highlight_active_weapon(current_weapon_index)

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.player_weapon_switched.emit(active_w.weapon_name, "")
		bus.player_ammo_changed.emit(active_w.current_clip_ammo, active_w.max_clip_ammo, active_w.current_reserve_ammo)

func connect_health() -> void:
	if health_connected or not health_component:
		return
	health_connected = true
	health_component.health_changed.connect(func(cur, max_hp):
		var bus = GameConstants.get_autoload(self, "EventBus")
		if bus:
			bus.player_health_changed.emit(cur, max_hp)
	)
	health_component.armor_changed.connect(func(cur, max_arm):
		var bus = GameConstants.get_autoload(self, "EventBus")
		if bus:
			bus.player_armor_changed.emit(cur, max_arm)
	)
	health_component.died.connect(_on_player_died)

func _physics_process(delta: float) -> void:
	if health_component.is_dead:
		return

	handle_look_and_recoil(delta)
	handle_movement(delta)
	handle_weapons_input()
	update_view_bobbing(delta)

func handle_look_and_recoil(delta: float) -> void:
	var im = GameConstants.get_autoload(self, "InputManager")
	if not im:
		return
	var look = im.get_look_vector(delta)

	# Yaw on player body
	rotate_y(-look.x)
	# Pitch on camera pivot
	camera_pivot.rotate_x(-look.y)
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

	# Decay recoil back to center
	current_recoil_pitch = lerpf(current_recoil_pitch, 0.0, delta * 12.0)
	current_recoil_yaw = lerpf(current_recoil_yaw, 0.0, delta * 12.0)
	if not camera.top_level:
		camera.rotation.x = current_recoil_pitch
		camera.rotation.y = current_recoil_yaw

func apply_recoil(pitch: float, yaw: float) -> void:
	current_recoil_pitch = min(current_recoil_pitch + pitch, deg_to_rad(15.0))
	current_recoil_yaw = clampf(current_recoil_yaw + yaw, deg_to_rad(-10.0), deg_to_rad(10.0))

func handle_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("jump")

	is_crouching = Input.is_action_pressed("crouch")
	var is_sprinting = Input.is_action_pressed("sprint") and not is_crouching

	var target_speed = walk_speed
	if is_crouching:
		target_speed = crouch_speed
		camera_pivot.position.y = lerpf(camera_pivot.position.y, 1.0, delta * 10.0)
	else:
		camera_pivot.position.y = lerpf(camera_pivot.position.y, default_camera_y, delta * 10.0)
		if is_sprinting:
			target_speed = sprint_speed

	var im = GameConstants.get_autoload(self, "InputManager")
	var input_vec = im.get_move_vector() if im else Vector2.ZERO
	var wish_dir = (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()

	var on_floor = is_on_floor() if is_inside_tree() else true
	var accel = acceleration if on_floor else (acceleration * air_control)
	var target_vel_x = wish_dir.x * target_speed
	var target_vel_z = wish_dir.z * target_speed
	velocity.x = lerpf(velocity.x, target_vel_x, accel * delta)
	velocity.z = lerpf(velocity.z, target_vel_z, accel * delta)

	if is_inside_tree():
		move_and_slide()

func handle_weapons_input() -> void:
	var active_w = weapons[current_weapon_index]
	var ray_origin = camera.global_position if camera.is_inside_tree() else camera.position
	var ray_dir = -camera.global_transform.basis.z if camera.is_inside_tree() else -camera.transform.basis.z

	if active_w.is_automatic:
		if Input.is_action_pressed("fire"):
			if active_w.trigger_fire(ray_origin, ray_dir):
				notify_ammo_update(active_w)
	else:
		if Input.is_action_just_pressed("fire"):
			if active_w.trigger_fire(ray_origin, ray_dir):
				notify_ammo_update(active_w)

	if Input.is_action_just_pressed("reload"):
		active_w.start_reload()

	# Weapon cycling with number keys
	if Input.is_key_pressed(KEY_1): select_weapon(0)
	elif Input.is_key_pressed(KEY_2): select_weapon(1)
	elif Input.is_key_pressed(KEY_3): select_weapon(2)
	elif Input.is_key_pressed(KEY_4): select_weapon(3)
	elif Input.is_key_pressed(KEY_5): select_weapon(4)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_weapon(current_weapon_index - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_weapon(current_weapon_index + 1)

func notify_ammo_update(w: WeaponBase) -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.player_ammo_changed.emit(w.current_clip_ammo, w.max_clip_ammo, w.current_reserve_ammo)

func update_view_bobbing(delta: float) -> void:
	var h_speed = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and h_speed > 0.5:
		bob_phase += delta * h_speed * 2.2
		weapon_holder.position.y = -0.25 + sin(bob_phase * 2.0) * 0.02
		weapon_holder.position.x = 0.28 + cos(bob_phase) * 0.015
	else:
		weapon_holder.position.y = lerpf(weapon_holder.position.y, -0.25, delta * 8.0)
		weapon_holder.position.x = lerpf(weapon_holder.position.x, 0.28, delta * 8.0)

func add_ammo(amount: int) -> void:
	for w in weapons:
		w.add_reserve_ammo(amount)
	var active_w = weapons[current_weapon_index]
	notify_ammo_update(active_w)

func _on_player_died(_source: Node) -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.player_died.emit("Enemy Bot")
