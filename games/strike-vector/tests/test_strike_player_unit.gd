class_name TestStrikePlayerUnit
extends RefCounted

## Unit tests for Strike Vector Player Locomotion, Weapon Arsenal (all 9 weapons), and Camera Director.

const StrikePlayerScript = preload("res://games/strike-vector/player/strike_player.gd")
const LocomotionScript = preload("res://games/strike-vector/player/player_locomotion.gd")
const ArsenalScript = preload("res://games/strike-vector/weapons/strike_weapon_arsenal.gd")
const CameraDirectorScript = preload("res://games/strike-vector/camera/camera_director.gd")
const PickupScript = preload("res://games/strike-vector/weapons/strike_pickup.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	test_locomotion_physics_and_buffering()
	test_all_9_weapons_arsenal()
	test_weapon_fire_and_reload()
	test_weapon_attachments_and_upgrades()
	test_arcade_power_modules()
	test_camera_director_modes()
	test_player_damage_and_armor_absorption()
	test_strike_player_visual()
	return {"passed": passed, "failed": failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/strike-vector/player/strike_player.gd", [
			"_ready", "_setup_collision", "_setup_visual", "_setup_ledge_detectors", "_setup_weapons",
			"select_weapon", "_sync_active_modules_to_weapon", "_physics_process", "_calculate_world_input_direction",
			"_get_input_vector", "_handle_weapon_input", "_check_mantle", "_handle_mantle", "recover_to_safe_ground",
			"take_damage", "_die", "apply_pickup", "_activate_module", "_update_combos_and_modules", "register_kill",
			"_spawn_support_drone", "_spawn_shield_burst_fx", "_on_weapon_fired", "_on_weapon_reloaded", "trigger_jump", "fire_weapon"
		]],
		["res://games/strike-vector/player/player_locomotion.gd", [
			"update_timers", "buffer_jump", "can_jump", "consume_jump", "start_dodge", "start_slide", "calculate_horizontal_velocity"
		]],
		["res://games/strike-vector/weapons/strike_weapon_base.gd", [
			"_ready", "_setup_muzzle", "_process", "can_fire", "trigger_pull", "trigger_release", "update_charge",
			"_execute_shot", "_apply_spread", "_spawn_bullet", "_trigger_muzzle_fx", "_play_fire_audio",
			"start_reload", "_finish_reload", "get_effective_magazine_capacity", "add_ammo", "apply_upgrade"
		]],
		["res://games/strike-vector/weapons/strike_weapon_arsenal.gd", [
			"create_weapon_by_id", "get_all_weapon_ids", "create_vx7_assault", "create_tempest_smg", "create_breach_shotgun",
			"create_atlas_battle_rifle", "create_longshot_marksman", "create_cyclone_lmg", "create_arc_launcher",
			"create_pulse_cannon", "create_tactical_sidearm", "_attach_visual", "_add_box"
		]],
		["res://games/strike-vector/camera/camera_director.gd", [
			"_ready", "_setup_camera_rig", "_load_settings", "_unhandled_input", "_physics_process",
			"_process_third_person", "_process_corridor", "_process_side_scroll", "_process_vehicle",
			"_process_boss_cam", "_process_cinematic", "set_mode", "add_shake", "_update_shake"
		]],
		["res://games/strike-vector/weapons/strike_pickup.gd", [
			"_ready", "_setup_collision", "_setup_visual", "_process", "_on_body_entered", "_apply_to_player", "_respawn"
		]],
		["res://games/strike-vector/player/strike_player_visual.gd", [
			"_ready", "build_visual", "update_animation"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + msg)

func test_locomotion_physics_and_buffering() -> void:
	var loco = LocomotionScript.new()
	loco.update_timers(0.016, true)
	assert_true(loco.coyote_timer > 0.1, "Coyote timer should be active on floor")

	# Jump buffering
	loco.buffer_jump()
	assert_true(loco.can_jump(true), "Should be able to jump when buffered on floor")
	var j_vel = loco.consume_jump()
	assert_true(j_vel > 7.0, "Jump velocity should be imparted")
	assert_true(not loco.can_jump(false), "Should consume jump buffer")

	# Horizontal velocity calculation
	var vel = loco.calculate_horizontal_velocity(Vector3.ZERO, Vector3.FORWARD, false, false, false, true, 0.1)
	assert_true(vel.length() > 0.0, "Input should produce horizontal velocity")

	# Sliding
	loco.start_slide(Vector3.FORWARD)
	assert_true(loco.is_sliding, "Should be sliding")
	loco.update_timers(1.5, true)
	assert_true(not loco.is_sliding, "Slide should decay and finish")

func test_all_9_weapons_arsenal() -> void:
	var ids = ArsenalScript.get_all_weapon_ids()
	assert_true(ids.size() == 9, "Arsenal must have exactly 9 weapons")

	for id in ids:
		var w = ArsenalScript.create_weapon_by_id(id)
		assert_true(is_instance_valid(w), "Weapon %s must instantiate cleanly" % id)
		assert_true(w.damage > 0.0, "Weapon %s damage must be positive" % id)
		assert_true(w.magazine_capacity > 0, "Weapon %s mag capacity must be positive" % id)
		assert_true(w.max_reserve_ammo > 0, "Weapon %s max reserve must be positive" % id)
		w.queue_free()

func test_weapon_fire_and_reload() -> void:
	var w = ArsenalScript.create_vx7_assault()
	assert_true(w.can_fire(), "Weapon should be able to fire initially")
	var initial_mag = w.ammo_in_mag
	w.trigger_pull(Vector3.ZERO, Vector3.FORWARD)
	assert_true(w.ammo_in_mag == initial_mag - 1, "Ammo should decrement after fire")

	w.start_reload()
	assert_true(w.is_reloading, "Weapon should be reloading")
	w._finish_reload()
	assert_true(not w.is_reloading, "Weapon should finish reloading")
	assert_true(w.ammo_in_mag == w.magazine_capacity, "Mag should be full after reload")
	w.queue_free()

func test_weapon_attachments_and_upgrades() -> void:
	var w = ArsenalScript.create_vx7_assault()
	var base_cap = w.magazine_capacity
	w.apply_upgrade("extended_mag")
	assert_true(w.has_extended_mag, "Extended mag upgrade should apply")
	assert_true(w.get_effective_magazine_capacity() > base_cap, "Extended mag should increase effective capacity")

	w.apply_upgrade("suppressor")
	assert_true(w.has_suppressor, "Suppressor should apply")
	w.queue_free()

func test_arcade_power_modules() -> void:
	var player = StrikePlayerScript.new()
	player.apply_pickup("mod_rapid_fire", 20)
	assert_true(player.active_modules.has("rapid_fire"), "Rapid fire module should be active")

	player.apply_pickup("mod_shield", 25)
	assert_true(player.active_modules.has("shield_overcharge"), "Shield module should be active")

	player.free()

func test_camera_director_modes() -> void:
	var cam = CameraDirectorScript.new()
	cam.set_mode(CameraDirectorScript.CameraMode.TIGHT_ADS)
	assert_true(cam.current_mode == CameraDirectorScript.CameraMode.TIGHT_ADS, "Camera mode should set to TIGHT_ADS")

	cam.set_mode(CameraDirectorScript.CameraMode.SIDE_SCROLL_25D)
	assert_true(cam.current_mode == CameraDirectorScript.CameraMode.SIDE_SCROLL_25D, "Camera mode should set to 2.5D")

	cam.add_shake(1.0)
	assert_true(cam.shake_intensity > 0.5, "Camera shake should accumulate")
	cam.queue_free()

func test_player_damage_and_armor_absorption() -> void:
	var player = StrikePlayerScript.new()
	player.current_health = 100.0
	player.current_armor = 50.0

	player.take_damage(20.0)
	# 20 * 0.6 = 12 armor, 20 * 0.4 = 8 health
	assert_true(player.current_armor == 38.0, "Armor should absorb 60% of damage")
	assert_true(player.current_health == 92.0, "Health should take remainder")
	player.free()

func test_strike_player_visual() -> void:
	var vis_script = preload("res://games/strike-vector/player/strike_player_visual.gd")
	var vis = vis_script.new()
	vis._ready()
	vis.build_visual()
	vis.update_animation(5.0, true, false, false, 0.0, 0.016)
	assert_true(is_instance_valid(vis.weapon_socket), "WeaponSocket must be initialized")
	vis.free()
