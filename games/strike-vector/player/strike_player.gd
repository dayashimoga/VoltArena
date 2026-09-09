class_name StrikePlayer
extends CharacterBody3D

## Core CharacterBody3D Player Controller for Strike Vector.
## Features: Walk, run, sprint, crouch, slide, jump (coyote/buffer), dodge, mantle,
## 9-weapon arsenal management, ADS, grenade throw, arcade modules, and zero world-fall recovery.

signal health_changed(current: float, max_val: float)
signal armor_changed(current: float, max_val: float)
signal weapon_switched(weapon_index: int, weapon_name: String, ammo: int, reserve: int)
signal ammo_updated(weapon_name: String, ammo: int, reserve: int)
signal arcade_module_activated(module_name: String, duration: float)
signal score_gained(amount: int, combo_mult: float)
signal damage_taken(amount: float, dealer_name: String, weapon: String, hit_pos: Vector3)
signal player_died()

const StrikeWeaponArsenalScript = preload("res://games/strike-vector/weapons/strike_weapon_arsenal.gd")
const StrikePlayerVisualScript = preload("res://games/strike-vector/player/strike_player_visual.gd")
const PlayerLocomotionScript = preload("res://games/strike-vector/player/player_locomotion.gd")

@export var max_health: float = 100.0
@export var max_armor: float = 100.0
@export var grenade_count: int = 3
@export var max_grenades: int = 5

var current_health: float = 100.0
var current_armor: float = 50.0
var is_alive: bool = true

# Locomotion & Physics
var locomotion: RefCounted = null
var visual: Node3D = null
var safe_ground_position: Vector3 = Vector3.ZERO
var mantle_target_position: Vector3 = Vector3.ZERO
var is_mantling: bool = false
var mantle_timer: float = 0.0

# Weapons & Inventory
var weapons: Array = []
var active_weapon_index: int = 0
var active_weapon: Node3D = null
var is_ads: bool = false
var is_firing: bool = false

# Arcade Power Modules
var active_modules: Dictionary = {} # { "rapid_fire": timer, ... }
var support_drone_instance: Node3D = null

# Score & Forward Progression Aggression Combo
var current_score: int = 0
var combo_multiplier: float = 1.0
var combo_decay_timer: float = 0.0
const COMBO_MAX_TIME: float = 4.5
const COMBO_MAX_MULT: float = 4.0

# Ledge & Vault raycasts
var ledge_ray_high: RayCast3D
var ledge_ray_low: RayCast3D

func _init() -> void:
	locomotion = PlayerLocomotionScript.new()
	_setup_collision()
	_setup_visual()
	_setup_ledge_detectors()
	_setup_weapons()

func _ready() -> void:
	add_to_group("players")
	collision_layer = GameConstants.LAYER_PLAYER
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_ENEMIES

	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(48.0)
	safe_margin = 0.08
	up_direction = Vector3.UP
	wall_min_slide_angle = deg_to_rad(15.0)

	current_health = max_health
	current_armor = 50.0
	safe_ground_position = global_position

	if not is_instance_valid(locomotion):
		locomotion = PlayerLocomotionScript.new()
	if not has_node("CollisionShape"):
		_setup_collision()
	if not is_instance_valid(visual):
		_setup_visual()
	if not has_node("LedgeRayHigh"):
		_setup_ledge_detectors()
	if weapons.is_empty():
		_setup_weapons()
	else:
		select_weapon(active_weapon_index)

func _setup_collision() -> void:
	collision_layer = GameConstants.LAYER_PLAYER
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_ENEMIES | GameConstants.LAYER_PICKUPS
	if has_node("CollisionShape"):
		return
	var col = CollisionShape3D.new()
	col.name = "CollisionShape"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.40
	cap.height = 1.80
	col.shape = cap
	col.position = Vector3(0, 0.90, 0)
	add_child(col)

func _setup_visual() -> void:
	if is_instance_valid(visual):
		return
	visual = StrikePlayerVisualScript.new()
	visual.name = "Visual"
	add_child(visual)
	visual.build_visual()

func _setup_ledge_detectors() -> void:
	if has_node("LedgeRayHigh"):
		return
	ledge_ray_high = RayCast3D.new()
	ledge_ray_high.name = "LedgeRayHigh"
	ledge_ray_high.position = Vector3(0, 1.6, 0)
	ledge_ray_high.target_position = Vector3(0, 0, -1.2)
	ledge_ray_high.collision_mask = GameConstants.LAYER_WORLD
	add_child(ledge_ray_high)

	ledge_ray_low = RayCast3D.new()
	ledge_ray_low.name = "LedgeRayLow"
	ledge_ray_low.position = Vector3(0, 0.9, 0)
	ledge_ray_low.target_position = Vector3(0, 0, -1.2)
	ledge_ray_low.collision_mask = GameConstants.LAYER_WORLD
	add_child(ledge_ray_low)

func _setup_weapons() -> void:
	if not weapons.is_empty():
		return
	var ids = StrikeWeaponArsenalScript.get_all_weapon_ids()
	for id in ids:
		var w = StrikeWeaponArsenalScript.create_weapon_by_id(id)
		w.owner_player = self
		w.weapon_fired.connect(_on_weapon_fired)
		w.weapon_reloaded.connect(_on_weapon_reloaded)
		weapons.append(w)

	select_weapon(0)

func select_weapon(index: int) -> void:
	if weapons.is_empty():
		return
	index = clampi(index, 0, weapons.size() - 1)
	if is_instance_valid(active_weapon):
		if active_weapon.get_parent():
			active_weapon.get_parent().remove_child(active_weapon)

	active_weapon_index = index
	active_weapon = weapons[active_weapon_index]

	# Attach to visual weapon grip
	var target_grip = null
	if is_instance_valid(visual):
		if "weapon_grip" in visual and is_instance_valid(visual.weapon_grip):
			target_grip = visual.weapon_grip
		elif "weapon_socket" in visual and is_instance_valid(visual.weapon_socket):
			target_grip = visual.weapon_socket

	if is_instance_valid(target_grip):
		target_grip.add_child(active_weapon)
		active_weapon.position = Vector3.ZERO
		active_weapon.rotation = Vector3.ZERO
	else:
		add_child(active_weapon)

	_sync_active_modules_to_weapon()
	weapon_switched.emit(active_weapon_index, active_weapon.weapon_name, active_weapon.ammo_in_mag, active_weapon.reserve_ammo)

func _sync_active_modules_to_weapon() -> void:
	if not is_instance_valid(active_weapon):
		return
	active_weapon.rapid_fire_active = active_modules.has("rapid_fire")
	active_weapon.spread_module_active = active_modules.has("spread_module")
	active_weapon.piercing_module_active = active_modules.has("piercing_module")

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_update_combos_and_modules(delta)
	_handle_mantle(delta)

	if is_mantling:
		return

	# Handle anti-fall / abyss protection
	var cur_pos = global_position if is_inside_tree() else position
	if is_valid_grounded():
		safe_ground_position = cur_pos
	elif cur_pos.y < -3.5:
		recover_to_safe_ground()
		return

	# Input gathering
	var input_vec = _get_input_vector()
	var is_sprint = Input.is_action_pressed("sprint")
	var is_crouch = Input.is_action_pressed("crouch")
	is_ads = Input.is_action_pressed("alt_fire")

	locomotion.update_timers(delta, is_on_floor())

	# Jump trigger
	if Input.is_action_just_pressed("jump"):
		locomotion.buffer_jump()

	# Slide trigger
	if is_crouch and is_on_floor() and velocity.length() > 6.0 and not locomotion.is_sliding:
		locomotion.start_slide(-global_transform.basis.z)

	# Dodge trigger (double-tap sprint or directional burst)
	if Input.is_action_just_pressed("boost") or (Input.is_action_just_pressed("sprint") and is_crouch):
		var dodge_dir = _calculate_world_input_direction(input_vec)
		locomotion.start_dodge(dodge_dir)

	# Execute jump
	if locomotion.can_jump(is_on_floor()):
		velocity.y = locomotion.consume_jump()
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am and am.has_method("play_sound"):
			am.play_sound("jump", 1.0)

	# Apply gravity
	if not is_on_floor():
		velocity.y -= locomotion.gravity * delta

	# Calculate horizontal velocity
	var world_dir = _calculate_world_input_direction(input_vec)
	var horiz_vel = locomotion.calculate_horizontal_velocity(
		Vector3(velocity.x, 0, velocity.z),
		world_dir,
		is_sprint,
		is_crouch,
		is_ads,
		is_on_floor(),
		delta
	)
	velocity.x = horiz_vel.x
	velocity.z = horiz_vel.z

	# Ledge Mantle Check
	_check_mantle()

	move_and_slide()

	# Track grounded safe transform and auto-recover if anomalous fall occurs
	if is_on_floor() and (global_position.y if is_inside_tree() else position.y) >= -0.2:
		safe_ground_position = global_position if is_inside_tree() else position
	elif (global_position.y if is_inside_tree() else position.y) < -6.0:
		recover_to_safe_ground()

	# Facing orientation update
	if is_instance_valid(visual):
		var is_firing = Input.is_action_pressed("fire")
		if is_ads or is_firing:
			# Combat aim mode: face camera yaw
			var cam = get_viewport().get_camera_3d() if is_inside_tree() else null
			if cam:
				var cam_fwd = -cam.global_transform.basis.z
				cam_fwd.y = 0.0
				var target_yaw = atan2(-cam_fwd.x, -cam_fwd.z)
				visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 16.0 * delta)
		elif horiz_vel.length() > 0.3:
			# Traversal mode: smoothly rotate towards travel direction
			var target_yaw = atan2(-horiz_vel.x, -horiz_vel.z)
			visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 12.0 * delta)

		# Update visual locomotion animations
		var local_move = visual.global_transform.basis.inverse() * Vector3(horiz_vel.x, 0, horiz_vel.z)
		visual.update_animation(horiz_vel.length(), is_on_floor(), locomotion.is_sliding, is_crouch, input_vec.x, delta, is_ads, Input.is_action_pressed("fire"), local_move.normalized())

	# Weapon firing
	_handle_weapon_input(delta)

func is_valid_grounded() -> bool:
	if not is_on_floor():
		return false
	var norm = get_floor_normal()
	return norm.dot(Vector3.UP) > 0.70 and absf(velocity.y) < 2.0

func recover_to_safe_ground() -> void:
	var target_safe = safe_ground_position
	target_safe.y = maxf(target_safe.y, 0.1)
	if is_inside_tree():
		global_position = target_safe + Vector3(0, 0.5, 0)
	else:
		position = target_safe + Vector3(0, 0.5, 0)
	velocity = Vector3.ZERO
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("hit", 0.6)
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus and bus.has_signal("telemetry_event_occurred"):
		var p_str = str(global_position if is_inside_tree() else position)
		bus.telemetry_event_occurred.emit("strike_vector_recovery", {"pos": p_str})

func _calculate_world_input_direction(input_vec: Vector2) -> Vector3:
	var cam = get_viewport().get_camera_3d() if is_inside_tree() else null
	if not cam:
		return (transform.basis * Vector3(input_vec.x, 0, -input_vec.y)).normalized()

	var cam_fwd = -cam.global_transform.basis.z
	cam_fwd.y = 0.0
	cam_fwd = cam_fwd.normalized()

	var cam_right = cam.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	# W input_vec.y = +1 -> cam_fwd; S input_vec.y = -1 -> -cam_fwd
	# D input_vec.x = +1 -> cam_right; A input_vec.x = -1 -> -cam_right
	return (cam_fwd * input_vec.y + cam_right * input_vec.x).normalized()

func _get_input_vector() -> Vector2:
	var im = GameConstants.get_autoload(self, "InputManager")
	var dir = Vector2.ZERO
	if Input.is_action_pressed("move_left"): dir.x -= 1.0
	if Input.is_action_pressed("move_right"): dir.x += 1.0
	if Input.is_action_pressed("move_forward"): dir.y += 1.0
	if Input.is_action_pressed("move_back"): dir.y -= 1.0

	if im and im.virtual_move_vector != Vector2.ZERO:
		dir = im.virtual_move_vector

	return dir.normalized()

func _handle_weapon_input(delta: float) -> void:
	if not is_instance_valid(active_weapon):
		return

	# Quick weapon switch via keys 1-9
	for i in range(1, 10):
		if Input.is_key_pressed(KEY_0 + i):
			select_weapon(i - 1)
			break

	# Crosshair raycast convergence to find 3D aim target
	var cam = get_viewport().get_camera_3d() if is_inside_tree() else null
	var target_point = Vector3.ZERO
	if cam:
		var vp = get_viewport()
		var center = vp.get_visible_rect().size * 0.5
		var ray_origin = cam.project_ray_origin(center)
		var ray_dir = cam.project_ray_normal(center)
		if is_inside_tree() and get_world_3d():
			var space = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * 150.0)
			query.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_ENEMIES
			query.exclude = [self]
			var hit = space.intersect_ray(query)
			if not hit.is_empty():
				target_point = hit.position
			else:
				target_point = ray_origin + ray_dir * 150.0
		else:
			target_point = ray_origin + ray_dir * 150.0
	else:
		target_point = global_position - global_transform.basis.z * 50.0

	var muzzle_pos = active_weapon.muzzle_socket.global_position if (is_instance_valid(active_weapon.muzzle_socket) and is_inside_tree()) else (global_position + Vector3(0, 1.0, 0))
	var aim_dir = (target_point - muzzle_pos).normalized() if target_point != muzzle_pos else -global_transform.basis.z

	# Automatic or semi-auto trigger
	if Input.is_action_pressed("fire"):
		var is_moving = velocity.length() > 1.0
		var is_air = not is_on_floor()
		active_weapon.trigger_pull(muzzle_pos, aim_dir, is_ads, is_moving, is_air)
	elif Input.is_action_just_released("fire"):
		var is_moving = velocity.length() > 1.0
		var is_air = not is_on_floor()
		active_weapon.trigger_release(muzzle_pos, aim_dir, is_ads, is_moving, is_air)

	if Input.is_action_just_pressed("reload"):
		active_weapon.start_reload()

	active_weapon.update_charge(delta)

func _check_mantle() -> void:
	if is_on_floor() or is_mantling:
		return
	if is_instance_valid(ledge_ray_low) and is_instance_valid(ledge_ray_high):
		# Low ray hits obstacle, but high ray is clear => mantleable ledge!
		if ledge_ray_low.is_colliding() and not ledge_ray_high.is_colliding():
			var hit_point = ledge_ray_low.get_collision_point()
			mantle_target_position = hit_point + Vector3(0, 1.2, 0) - global_transform.basis.z * 0.4
			is_mantling = true
			mantle_timer = 0.25

func _handle_mantle(delta: float) -> void:
	if not is_mantling:
		return
	mantle_timer -= delta
	global_position = global_position.lerp(mantle_target_position, 12.0 * delta)
	velocity = Vector3.ZERO
	if mantle_timer <= 0.0:
		global_position = mantle_target_position
		is_mantling = false

func take_damage(amount: float, _dealer_name: String = "", _weapon: String = "") -> void:
	if not is_alive:
		return

	# Energy Shield Overcharge module absorption
	if active_modules.has("shield_overcharge"):
		active_modules.erase("shield_overcharge")
		_spawn_shield_burst_fx()
		return

	# Armor absorption: absorbs 60% of damage
	var armor_absorb = amount * 0.60
	var health_absorb = amount * 0.40

	if current_armor > 0.0:
		if current_armor >= armor_absorb:
			current_armor -= armor_absorb
		else:
			var remainder = armor_absorb - current_armor
			current_armor = 0.0
			health_absorb += remainder
	else:
		health_absorb = amount

	current_health = maxf(0.0, current_health - health_absorb)
	health_changed.emit(current_health, max_health)
	armor_changed.emit(current_armor, max_armor)
	damage_taken.emit(amount, _dealer_name, _weapon, global_position if is_inside_tree() else position)

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("hit", 1.0)

	if current_health <= 0.0:
		_die()

func _die() -> void:
	is_alive = false
	player_died.emit()

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.player_died.emit()

func apply_pickup(pickup_type: String, value: int) -> void:
	match pickup_type:
		"ammo_pack":
			if is_instance_valid(active_weapon):
				active_weapon.add_ammo(value)
				ammo_updated.emit(active_weapon.weapon_name, active_weapon.ammo_in_mag, active_weapon.reserve_ammo)
		"health_pack":
			current_health = minf(max_health, current_health + float(value))
			health_changed.emit(current_health, max_health)
		"armor_pack":
			current_armor = minf(max_armor, current_armor + float(value))
			armor_changed.emit(current_armor, max_armor)
		"grenade_pack":
			grenade_count = mini(max_grenades, grenade_count + value)
		"mod_rapid_fire":
			_activate_module("rapid_fire", 20.0)
		"mod_spread":
			_activate_module("spread_module", 20.0)
		"mod_piercing":
			_activate_module("piercing_module", 20.0)
		"mod_shield":
			_activate_module("shield_overcharge", 25.0)
		"mod_overdrive":
			_activate_module("overdrive", 18.0)
		"mod_drone":
			_activate_module("support_drone", 22.0)

func _activate_module(mod_name: String, duration: float) -> void:
	active_modules[mod_name] = duration
	_sync_active_modules_to_weapon()
	arcade_module_activated.emit(mod_name, duration)

	if mod_name == "support_drone":
		_spawn_support_drone()

func _update_combos_and_modules(delta: float) -> void:
	# Combo decay
	if combo_decay_timer > 0.0:
		combo_decay_timer -= delta
		if combo_decay_timer <= 0.0:
			combo_multiplier = 1.0

	# Active modules expiration
	var expired = []
	for mod_key in active_modules.keys():
		active_modules[mod_key] -= delta
		if active_modules[mod_key] <= 0.0:
			expired.append(mod_key)

	for exp_mod in expired:
		active_modules.erase(exp_mod)
		if exp_mod == "support_drone" and is_instance_valid(support_drone_instance):
			support_drone_instance.queue_free()
			support_drone_instance = null

	if not expired.is_empty():
		_sync_active_modules_to_weapon()

func register_kill(score_val: int) -> void:
	combo_decay_timer = COMBO_MAX_TIME
	combo_multiplier = minf(COMBO_MAX_MULT, combo_multiplier + 0.25)
	var gained = int(score_val * combo_multiplier)
	current_score += gained
	score_gained.emit(gained, combo_multiplier)

func _spawn_support_drone() -> void:
	if is_instance_valid(support_drone_instance):
		return
	support_drone_instance = Node3D.new()
	support_drone_instance.name = "SupportDrone"

	var mi = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.50
	mi.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.95, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.95, 1.0)
	mat.emission_energy_multiplier = 4.0
	mi.material_override = mat
	support_drone_instance.add_child(mi)

	add_child(support_drone_instance)
	support_drone_instance.position = Vector3(0.8, 1.8, 0.8)

func _spawn_shield_burst_fx() -> void:
	var flash = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 1.6
	sph.height = 3.2
	flash.mesh = sph
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 1.0)
	flash.material_override = mat
	add_child(flash)
	var tw = flash.create_tween()
	tw.tween_property(flash, "scale", Vector3(2.0, 2.0, 2.0), 0.25)
	tw.tween_callback(flash.queue_free)

func _on_weapon_fired(w_name: String, ammo: int, reserve: int) -> void:
	ammo_updated.emit(w_name, ammo, reserve)

func _on_weapon_reloaded(w_name: String, ammo: int, reserve: int) -> void:
	ammo_updated.emit(w_name, ammo, reserve)

# API helper functions for tests and external controllers
func trigger_jump() -> void:
	if locomotion:
		locomotion.buffer_jump()
		velocity.y = locomotion.consume_jump()

func fire_weapon() -> void:
	if is_instance_valid(active_weapon):
		var aim_origin = global_position + Vector3(0, 1.4, 0)
		var aim_dir = -global_transform.basis.z
		active_weapon.trigger_pull(aim_origin, aim_dir, false, false, false)
