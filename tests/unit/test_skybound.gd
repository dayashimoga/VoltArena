class_name TestSkybound
extends RefCounted

## Unit tests for Skybound Odyssey Character & Systems (games/skybound-odyssey/)

const SkyCharacterScript = preload("res://games/skybound-odyssey/character/sky_character.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_character_initialization()
	test_locomotion_and_jumping()
	test_glider_aerodynamics()
	test_grapple_mechanics()
	test_ledge_mantling_detection()
	test_abyss_kill_plane_recovery()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/skybound-odyssey/character/sky_character.gd", [
			"_ready", "_physics_process", "setup_visuals",
			"setup_ledge_detectors", "handle_input", "perform_jump",
			"perform_double_jump", "toggle_glider", "try_launch_grapple",
			"start_mantle", "recover_to_safe_ground", "check_ledge_mantle", "collect_shard"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit Skybound FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_character_initialization() -> void:
	var player = SkyCharacterScript.new()
	assert_true(player.max_stamina > 0.0, "Max stamina must be positive")
	assert_true(player.move_speed > 0.0, "Move speed must be positive")
	assert_true(player.jump_velocity > 0.0, "Jump velocity must be positive")
	assert_true(player.can_double_jump, "Can double jump should initialize true")
	player.queue_free()

func test_locomotion_and_jumping() -> void:
	var player = SkyCharacterScript.new()
	player.trigger_jump()
	assert_true(player.velocity.y > 0.0, "Jump should impart positive upward velocity")
	var initial_vy = player.velocity.y

	# Double jump
	player.trigger_jump()
	assert_true(not player.can_double_jump, "can_double_jump should become false after second jump")
	player.queue_free()

func test_glider_aerodynamics() -> void:
	var player = SkyCharacterScript.new()
	assert_true(not player.is_gliding, "Player should not start gliding")

	player.deploy_glider()
	assert_true(player.is_gliding, "Player should be gliding after deploy")
	assert_true(player.glider_model != null, "Glider model should be created")

	player.stow_glider()
	assert_true(not player.is_gliding, "Player should not be gliding after stow")
	player.queue_free()

func test_grapple_mechanics() -> void:
	var player = SkyCharacterScript.new()
	var target = Vector3(0, 15, 20)
	player.fire_grapple(target)
	assert_true(player.is_grappling, "Player should be grappling after firing")
	assert_eq(player.grapple_target, target, "Grapple target should match")

	player.release_grapple()
	assert_true(not player.is_grappling, "Player should not be grappling after release")
	player.queue_free()

func test_ledge_mantling_detection() -> void:
	var player = SkyCharacterScript.new()
	player.position = Vector3(0, 5, 0)
	assert_true(not player.is_mantling, "Player should not start mantling")
	player.queue_free()

func test_abyss_kill_plane_recovery() -> void:
	var player = SkyCharacterScript.new()
	player.last_safe_ground_pos = Vector3(5, 2, 5)
	player.position = Vector3(5, -25, 5)
	player.recover_from_abyss()
	assert_true(player.position.y >= 2.0, "Player should recover to safe ground above abyss")
	assert_eq(player.velocity, Vector3.ZERO, "Velocity should reset to zero on recovery")
	player.queue_free()
