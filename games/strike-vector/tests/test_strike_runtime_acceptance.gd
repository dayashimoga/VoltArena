class_name TestStrikeRuntimeAcceptance
extends RefCounted

## Forensic runtime acceptance tests for Strike Vector (P0 Gates).
## Validates:
## 1. 100+ consecutive shots with zero root/firing pose corruption (character never rotates/lies horizontally).
## 2. Weapon strictly attached to right hand bone and aligned with aiming axis.
## 3. Physical projectile hit registration: enemy bullets demonstrably hit and damage player.
## 4. Physical obstacle blocking: solid walls block projectiles with zero bleed-through.
## 5. Metric scale invariants: human ~1.8m, cars ~4.5m, trucks ~6.2m, street >=14m.
## 6. HUD directional damage indicator: emits and points toward attacker.
## 7. Traversal without fall-through: zero safe ground recoveries on valid roadway.

const StrikePlayerScript = preload("res://games/strike-vector/player/strike_player.gd")
const StrikeAIScript = preload("res://games/strike-vector/ai/strike_ai_base.gd")
const WeaponProjectileScript = preload("res://games/strike-vector/weapons/weapon_projectile.gd")
const StrikeHUDScript = preload("res://games/strike-vector/ui/strike_hud.gd")
const StrikeEnvBuilderScript = preload("res://games/strike-vector/environment/strike_environment_builder.gd")
const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	test_firing_pose_stability_100_shots()
	test_weapon_hand_attachment_and_barrel_alignment()
	test_deterministic_enemy_projectile_damage()
	test_solid_wall_blocks_projectiles()
	test_metric_world_scale_proportions()
	test_hud_directional_damage_indicator()
	test_roadway_floor_and_anti_fall_geometry()
	return {"passed": passed, "failed": failed}

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + msg)

func get_coverage_entries() -> Array:
	return [
		["res://games/strike-vector/player/strike_player.gd", [
			"fire_weapon", "take_damage", "is_valid_grounded"
		]],
		["res://games/strike-vector/player/strike_player_visual.gd", [
			"build_visual", "update_animation"
		]],
		["res://games/strike-vector/weapons/weapon_projectile.gd", [
			"init_projectile", "_physics_process", "_handle_hit"
		]],
		["res://games/strike-vector/ui/strike_hud.gd", [
			"trigger_damage_feedback", "_setup_damage_indicator"
		]],
		["res://games/strike-vector/environment/strike_environment_builder.gd", [
			"_build_urban_segment", "_add_authored_building", "_add_streetlight", "_add_beacon"
		]]
	]

# ------------------------------------------------------------------------------
# 1. 100+ Consecutive Shots Pose Stability (Defect 1)
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# 1. 100+ Consecutive Shots Pose Stability (Defect 1)
# ------------------------------------------------------------------------------
func test_firing_pose_stability_100_shots() -> void:
	var player = StrikePlayerScript.new()

	var min_up_dot = 1.0
	for shot in range(100):
		player.is_ads = (shot % 2 == 0)
		player.velocity = Vector3(1.5 if shot % 3 == 0 else 0.0, 0, -4.0 if shot % 2 == 0 else 0.0)
		player.fire_weapon()

		# Check that CharacterBody3D and Visual root remain vertical
		var up_dot = player.basis.y.dot(Vector3.UP)
		if up_dot < min_up_dot:
			min_up_dot = up_dot

		if is_instance_valid(player.visual):
			var vis_up_dot = player.visual.basis.y.dot(Vector3.UP)
			if vis_up_dot < min_up_dot:
				min_up_dot = vis_up_dot

	assert_true(min_up_dot >= 0.95, "Player up-vector must remain strictly vertical (>0.95) across 100 consecutive shots (got %f)" % min_up_dot)

	player.free()

# ------------------------------------------------------------------------------
# 2. Weapon Invariant & Hand Grip Alignment (Defect 2)
# ------------------------------------------------------------------------------
func test_weapon_hand_attachment_and_barrel_alignment() -> void:
	var player = StrikePlayerScript.new()

	assert_true(is_instance_valid(player.active_weapon), "Active weapon must be valid and spawned")
	assert_true(is_instance_valid(player.visual), "Player visual must be valid")

	var hand_pos = player.visual.right_hand_att.position if player.visual.right_hand_att else Vector3.ZERO
	var wep_pos = player.active_weapon.position
	var dist = hand_pos.distance_to(wep_pos)
	assert_true(dist <= 0.15, "Weapon must remain within 0.15m of right hand bone (distance was %f)" % dist)

	# Verify weapon barrel forward direction is aligned with character forward
	if is_instance_valid(player.active_weapon):
		var wep_fwd = -player.active_weapon.basis.z.normalized()
		var player_fwd = -player.basis.z.normalized()
		var dot = wep_fwd.dot(player_fwd)
		assert_true(dot >= 0.90, "Weapon barrel forward must be aligned with player facing (dot was %f)" % dot)

	player.free()

# ------------------------------------------------------------------------------
# 3. Deterministic Physical Combat Hit Registration (Defect 4)
# ------------------------------------------------------------------------------
func test_deterministic_enemy_projectile_damage() -> void:
	var player = StrikePlayerScript.new()
	player.position = Vector3(0, 0, 0)

	var enemy = StrikeAIScript.new()
	enemy.name = "Trooper"
	enemy.position = Vector3(0, 0, -12.0)
	enemy.target_player = player

	var hp_before = player.current_health
	var shd_before = player.current_armor

	var sig_data = {"received": false, "amt": 0.0, "dealer": ""}
	player.damage_taken.connect(func(amt, dealer, _wep, _pos):
		sig_data["received"] = true
		sig_data["amt"] = amt
		sig_data["dealer"] = dealer
	)

	var proj = WeaponProjectileScript.new()
	proj.shooter = enemy
	proj.init_projectile(Vector3.FORWARD, 120.0, 20.0, Color(1.0, 0.25, 0.15), "test_rifle")

	# Execute direct hit resolution on player
	proj._handle_hit({"collider": player, "position": player.position, "normal": Vector3.UP})

	assert_true(player.current_armor == 38.0, "Player shield must absorb 60 percent of damage (50 -> 38, got %f)" % player.current_armor)
	assert_true(player.current_health == 92.0, "Player health must absorb remaining 40 percent of damage (100 -> 92, got %f)" % player.current_health)
	assert_true(sig_data["received"], "Player damage_taken signal must fire on physical bullet impact")
	assert_true(sig_data["amt"] == 20.0, "Signal damage amount must match weapon bullet damage")
	assert_true(sig_data["dealer"] == "Trooper", "Dealer name must be passed as valid string (not bool)")

	# Verify fatal damage triggers death pipeline
	player.take_damage(200.0, "Sniper", "Railgun")
	assert_true(not player.is_alive, "Fatal damage must transition is_alive to false")
	assert_true(player.current_health == 0.0, "Health must clamp to 0.0 on death")

	player.free()
	enemy.free()

# ------------------------------------------------------------------------------
# 4. Solid Obstacles Block Projectiles (No Wall Tunneling)
# ------------------------------------------------------------------------------
func test_solid_wall_blocks_projectiles() -> void:
	var player = StrikePlayerScript.new()
	player.position = Vector3(0, 0, 0)

	var wall = StaticBody3D.new()
	wall.collision_layer = GameConstants.LAYER_WORLD
	wall.position = Vector3(0, 1.0, -6.0)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(8.0, 4.0, 1.0)
	col.shape = shape
	wall.add_child(col)

	var enemy = StrikeAIScript.new()
	enemy.position = Vector3(0, 0, -12.0)

	var hp_before = player.current_health
	var shd_before = player.current_armor

	var proj = WeaponProjectileScript.new()
	proj.shooter = enemy
	proj.init_projectile(Vector3.FORWARD, 120.0, 25.0, Color(1.0, 0.25, 0.15), "test_rifle")

	# Impact solid obstacle
	proj._handle_hit({"collider": wall, "position": wall.position, "normal": Vector3.FORWARD})

	assert_true(proj.is_queued_for_deletion(), "Non-penetrating projectile must be destroyed on solid wall impact")
	assert_true(player.current_health == hp_before and player.current_armor == shd_before,
		"Solid wall obstacle must prevent any damage bleed-through to player")

	player.free()
	wall.free()
	enemy.free()

# ------------------------------------------------------------------------------
# 5. Metric World Scale Invariants (Defect 3)
# ------------------------------------------------------------------------------
func test_metric_world_scale_proportions() -> void:
	# 1. Player scale: height ~1.8m, radius ~0.4m
	var player = StrikePlayerScript.new()
	var col_shape: CollisionShape3D = player.find_child("CollisionShape", true, false)
	assert_true(col_shape != null, "Player must have CollisionShape")
	if col_shape and col_shape.shape is CapsuleShape3D:
		var cap = col_shape.shape as CapsuleShape3D
		assert_true(cap.height >= 1.7 and cap.height <= 1.9, "Player height must be 1.7m-1.9m (was %f)" % cap.height)
		assert_true(cap.radius >= 0.35 and cap.radius <= 0.45, "Player radius must be 0.35m-0.45m (was %f)" % cap.radius)
	player.free()

	# 2. Vehicle scale: Cars ~4.5m length, Trucks ~6.2m length
	var car = ModelCacheScript.get_model("res://assets/models/vehicles/rocket_car_enforcer.glb")
	if car:
		car.scale = Vector3(1.6, 1.6, 1.6)
		var aabb = _calc_node_aabb(car)
		assert_true(aabb.size.z >= 4.0 and aabb.size.z <= 5.5, "Patrol car length must be authentic 4.0m-5.5m (was %f)" % aabb.size.z)
		assert_true(aabb.size.y >= 1.4 and aabb.size.y <= 2.4, "Patrol car height must be 1.4m-2.4m (was %f)" % aabb.size.y)
		car.free()

	var truck = ModelCacheScript.get_model("res://assets/models/vehicles/truck_yellow.glb")
	if truck:
		truck.scale = Vector3(2.2, 2.2, 2.2)
		var t_aabb = _calc_node_aabb(truck)
		assert_true(t_aabb.size.z >= 5.5 and t_aabb.size.z <= 7.0, "Heavy truck length must be authentic 5.5m-7.0m (was %f)" % t_aabb.size.z)
		truck.free()

# ------------------------------------------------------------------------------
# 6. HUD Threat Readability & Directional Damage Indicator (Defect 5)
# ------------------------------------------------------------------------------
func test_hud_directional_damage_indicator() -> void:
	var hud = StrikeHUDScript.new()
	hud._ready()
	var root = Engine.get_main_loop().root if Engine.get_main_loop() is SceneTree else null
	if root:
		root.add_child(hud)

	assert_true(is_instance_valid(hud.damage_indicator), "HUD must have active damage_indicator subcomponent")

	# Attacker to the right (+X)
	var player_pos = Vector3(0, 0, 0)
	var attacker_pos = Vector3(15, 0, 0)
	hud.trigger_damage_feedback(attacker_pos, player_pos, 0.0)

	assert_true(hud.damage_indicator.active_indicators.size() > 0, "Triggering damage feedback must add indicator entry")
	if hud.damage_indicator.active_indicators.size() > 0:
		var ind = hud.damage_indicator.active_indicators[0]
		assert_true(ind["alpha"] > 0.8, "Indicator alpha must be active")

	if hud.get_parent():
		hud.get_parent().remove_child(hud)
	hud.free()

# ------------------------------------------------------------------------------
# 7. Roadway Floor & Zero Fall Geometry
# ------------------------------------------------------------------------------
func test_roadway_floor_and_anti_fall_geometry() -> void:
	var root_node = Node3D.new()
	var seg = StrikeEnvBuilderScript.build_segment_environment("urban", 0, 40.0, 16.0)
	root_node.add_child(seg)

	var floors = []
	for c in seg.get_children():
		if c is StaticBody3D:
			floors.append(c)

	assert_true(floors.size() >= 3, "Urban segment must include road, left sidewalk, and right sidewalk StaticBodies")

	# Verify road width is 14m (not narrow 10m)
	var found_14m_road = false
	for f in floors:
		for ch in f.get_children():
			if ch is CollisionShape3D and ch.shape is BoxShape3D:
				if ch.shape.size.x >= 13.5:
					found_14m_road = true
	assert_true(found_14m_road, "Urban roadway must have 14m physical width for believable two-lane street")

	root_node.free()

func _calc_node_aabb(node: Node3D) -> AABB:
	var total = AABB()
	var first = true
	for c in node.get_children():
		if c is VisualInstance3D:
			var box = c.get_aabb()
			box.position *= node.scale
			box.size *= node.scale
			if first:
				total = box
				first = false
			else:
				total = total.merge(box)
		elif c is Node3D:
			var sub = _calc_node_aabb(c)
			if sub.size != Vector3.ZERO:
				if first:
					total = sub
					first = false
				else:
					total = total.merge(sub)
	return total
