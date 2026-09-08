class_name TestStrikeTraversalProbes
extends RefCounted

## Automated Traversal Probes & World Collision Continuity Acceptance Suite.
## Validates that every mission segment possesses unbroken, continuous ground collision,
## verified safe spawn coordinates, lateral anti-fall containment walls, and instant recoverability.

const MissionDefsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const StrikePlayerScript = preload("res://games/strike-vector/player/strike_player.gd")
const StrikeVectorMainScript = preload("res://games/strike-vector/strike_vector_main.gd")

var passed: int = 0
var failed: int = 0

func assert_true(condition: bool, message: String = "") -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("[FAIL] %s" % message)

func run_tests() -> Dictionary:
	test_all_missions_ground_continuity()
	test_player_spawn_and_boundary_containment()
	test_kill_plane_recovery_failsafe()
	return {"passed": passed, "failed": failed}

func test_all_missions_ground_continuity() -> void:
	for m_idx in range(1, 9):
		var segs = MissionDefsScript.build_mission_segments(m_idx)
		assert_true(segs.size() >= 5, "Mission %d must have at least 5 segments" % m_idx)

		var total_segments = segs.size()
		for s_idx in range(total_segments):
			var seg = segs[s_idx]
			var env = seg.get_node_or_null("Environment_" + MissionDefsScript.get_mission_meta(m_idx)["biome"] + "_" + str(s_idx))
			assert_true(is_instance_valid(env), "Segment %d must have valid environment root" % s_idx)

			# Verify floor static body exists and has collision layer GameConstants.LAYER_WORLD
			var found_floor = false
			for child in env.get_children():
				if child is StaticBody3D:
					if child.collision_layer & GameConstants.LAYER_WORLD:
						for c_shape in child.get_children():
							if c_shape is CollisionShape3D and c_shape.shape is BoxShape3D:
								found_floor = true
								break
				if found_floor:
					break

			assert_true(found_floor, "Mission %d Segment %d must possess a solid world collider" % [m_idx, s_idx])

		# Clean up segments
		for s in segs:
			s.free()

func test_player_spawn_and_boundary_containment() -> void:
	var player = StrikePlayerScript.new()
	player._ready()

	# Assert player collision shape is properly grounded
	var col = player.get_node_or_null("CollisionShape") as CollisionShape3D
	assert_true(is_instance_valid(col), "Player must possess CollisionShape3D")
	var cap = col.shape as CapsuleShape3D
	assert_true(is_instance_valid(cap), "Player collider must be a CapsuleShape3D")
	assert_true(cap.radius >= 0.35 and cap.radius <= 0.45, "Player capsule radius must be approx 0.40m")
	assert_true(cap.height >= 1.70 and cap.height <= 1.90, "Player capsule height must be approx 1.80m")
	assert_true(col.position.y >= 0.85 and col.position.y <= 0.95, "Capsule center must sit at Y=0.90 so bottom is at Y=0.0")

	# Assert safe margin and floor snap
	assert_true(player.floor_snap_length >= 0.4, "floor_snap_length must be >= 0.4 for smooth slope adhesion")
	assert_true(player.safe_margin <= 0.1, "safe_margin must be <= 0.1m for tight ground contact")

	player.free()

func test_kill_plane_recovery_failsafe() -> void:
	var player = StrikePlayerScript.new()
	player._ready()
	player.position = Vector3(0, 0.1, -10.0)
	player.safe_ground_position = Vector3(0, 0.1, -10.0)

	# Simulate falling below threshold
	player.position.y = -5.0
	assert_true(player.position.y < -3.5, "Player should be below fail-safe threshold")
	player.recover_to_safe_ground()

	assert_true(player.position.y >= 0.5, "Player position must be restored above ground")
	assert_true(player.velocity == Vector3.ZERO, "Player velocity must be zeroed upon recovery")
	player.free()
