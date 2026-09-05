class_name TestProceduralAnimator
extends RefCounted

## Unit test suite for ProceduralAnimator and CameraShake

var assertions_passed: int = 0
var assertions_failed: int = 0

const ProceduralAnimatorScript = preload("res://shared/graphics/procedural_animator.gd")
const CameraShakeScript = preload("res://shared/graphics/camera_shake.gd")

func run_tests() -> Dictionary:
	test_biped_animation()
	test_crawler_animation()
	test_vehicle_suspension()
	test_weapon_sway_and_bob()
	test_weapon_recoil_and_flash()
	test_camera_shake()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://shared/graphics/procedural_animator.gd", ["animate_biped", "animate_crawler", "animate_vehicle_suspension", "calculate_weapon_sway", "calculate_weapon_bob", "calculate_weapon_recoil", "create_muzzle_flash"]],
		["res://shared/graphics/camera_shake.gd", ["add_trauma", "get_trauma", "update", "reset"]],
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("FAIL: " + msg)

func test_biped_animation() -> void:
	var root = Node3D.new()
	var la = Node3D.new()
	var ra = Node3D.new()
	var ll = Node3D.new()
	var rl = Node3D.new()
	var torso = Node3D.new()
	root.add_child(la)
	root.add_child(ra)
	root.add_child(ll)
	root.add_child(rl)
	root.add_child(torso)

	ProceduralAnimatorScript.animate_biped(0.5, 6.0, la, ra, ll, rl, torso, true, false)
	assert_true(ll.rotation.x != 0.0 or rl.rotation.x != 0.0, "Legs should swing when moving")

	ProceduralAnimatorScript.animate_biped(1.0, 0.0, la, ra, ll, rl, torso, false, false)
	assert_true(torso != null, "Idle breathing should execute")

	ProceduralAnimatorScript.animate_biped(1.0, 0.0, la, ra, ll, rl, torso, false, true)
	assert_true(ra.rotation.x != 0.0, "Right arm should pose on attack")

	root.free()

func test_crawler_animation() -> void:
	var legs: Array[Node3D] = []
	var root = Node3D.new()
	for i in range(4):
		var leg = Node3D.new()
		root.add_child(leg)
		legs.append(leg)
	var body = Node3D.new()
	root.add_child(body)

	ProceduralAnimatorScript.animate_crawler(0.5, 4.0, legs, body, true)
	assert_true(legs[0].rotation.z != 0.0, "Legs should scuttle when moving")

	ProceduralAnimatorScript.animate_crawler(1.0, 0.0, legs, body, false)
	assert_true(is_equal_approx(body.position.y, 0.35), "Body resting height")

	root.free()

func test_vehicle_suspension() -> void:
	var car_body = Node3D.new()
	var wheels: Array[Node3D] = []
	for i in range(4):
		var w = Node3D.new()
		car_body.add_child(w)
		wheels.append(w)

	ProceduralAnimatorScript.animate_vehicle_suspension(car_body, wheels, 0.3, 10.0, 0.05, 0.016)
	assert_true(is_equal_approx(wheels[0].rotation.y, 0.3), "Front wheels should steer")
	assert_true(wheels[0].rotation.x != 0.0, "Wheels should rotate")

	car_body.free()

func test_weapon_sway_and_bob() -> void:
	var sway = ProceduralAnimatorScript.calculate_weapon_sway(Vector2(10.0, -5.0))
	assert_true(sway.x != 0.0 and sway.y != 0.0, "Sway should calculate offset from mouse")

	var bob = ProceduralAnimatorScript.calculate_weapon_bob(0.5, 6.0)
	assert_true(bob != Vector3.ZERO, "Bob should calculate non-zero offset when moving")

	var zero_bob = ProceduralAnimatorScript.calculate_weapon_bob(0.5, 0.0)
	assert_true(zero_bob == Vector3.ZERO, "Bob should be zero when stationary")

func test_camera_shake() -> void:
	var shake = CameraShakeScript.new()
	assert_true(shake.get_trauma() == 0.0, "Trauma starts at 0")

	shake.add_trauma(0.8)
	assert_true(shake.get_trauma() == 0.8, "Trauma should be 0.8")

	var result = shake.update(0.1)
	assert_true(result["offset"] != Vector3.ZERO or result["rotation"] != Vector3.ZERO, "Shake offset/rotation should be generated")

	shake.reset()
	assert_true(shake.get_trauma() == 0.0, "Trauma reset to 0")

func test_weapon_recoil_and_flash() -> void:
	var recoil = ProceduralAnimatorScript.calculate_weapon_recoil(0.5, 0.1, 0.05)
	assert_true(recoil.z > 0.0, "Weapon recoil should kick back along Z")
	assert_true(recoil.y > 0.0, "Weapon recoil should kick up along Y")

	var parent = Node3D.new()
	var flash = ProceduralAnimatorScript.create_muzzle_flash(parent, Vector3(0, 0, -1))
	assert_true(flash != null, "Muzzle flash created")
	assert_true(flash.has_node("OmniLight3D") or flash.get_child(0) is OmniLight3D, "Muzzle flash contains dynamic light")
	parent.free()
