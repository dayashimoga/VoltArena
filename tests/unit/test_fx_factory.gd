class_name TestFXFactory
extends RefCounted

const FXFactoryScript = preload("res://shared/graphics/fx_factory.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_muzzle_flash()
	test_impact_sparks()
	test_explosion()
	test_drift_smoke()
	test_rocket_exhaust()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://shared/graphics/fx_factory.gd", [
			"create_muzzle_flash",
			"create_impact_sparks",
			"create_explosion",
			"create_drift_smoke",
			"create_rocket_exhaust"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit FXFactory FAIL: " + msg)

func test_muzzle_flash() -> void:
	var p = FXFactoryScript.create_muzzle_flash(Vector3(0, 1, -1))
	assert_true(p != null, "Muzzle flash CPUParticles3D created")
	assert_true(p.one_shot, "Muzzle flash must be one_shot")
	assert_true(p.amount > 0, "Muzzle flash must have particles")
	p.queue_free()

func test_impact_sparks() -> void:
	var p = FXFactoryScript.create_impact_sparks(Vector3(5, 2, 3), Vector3(0, 1, 0))
	assert_true(p != null, "Impact sparks CPUParticles3D created")
	assert_true(p.one_shot, "Impact sparks must be one_shot")
	assert_true(p.direction == Vector3(0, 1, 0), "Impact direction must match normal")
	p.queue_free()

func test_explosion() -> void:
	var p = FXFactoryScript.create_explosion(Vector3(0, 0, 0), 3.0)
	assert_true(p != null, "Explosion CPUParticles3D created")
	assert_true(p.one_shot, "Explosion must be one_shot")
	assert_true(p.amount >= 32, "Explosion should have at least 32 particles")
	p.queue_free()

func test_drift_smoke() -> void:
	var p = FXFactoryScript.create_drift_smoke(Vector3(-1, 0, 1))
	assert_true(p != null, "Drift smoke CPUParticles3D created")
	assert_true(not p.one_shot, "Drift smoke is continuous while drifting")
	p.queue_free()

func test_rocket_exhaust() -> void:
	var p = FXFactoryScript.create_rocket_exhaust(Vector3(0, 0.5, 2))
	assert_true(p != null, "Rocket exhaust CPUParticles3D created")
	assert_true(not p.one_shot, "Rocket exhaust is continuous")
	p.queue_free()
