class_name TestMaterialGenerator
extends RefCounted

const MatGenScript = preload("res://shared/graphics/material_generator.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_named_materials()
	test_material_reuse()
	test_create_pbr_material()
	test_clear_cache()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://shared/graphics/material_generator.gd", ["get_material", "create_pbr_material", "clear_cache"]],
		["res://shared/graphics/texture_synthesizer.gd", ["get_texture"]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond: assertions_passed += 1
	else: assertions_failed += 1; push_error("Unit MaterialGenerator FAIL: " + msg)

func test_named_materials() -> void:
	var names = ["sci_fi_metal", "neon_cyan", "neon_orange", "dark_concrete", "asphalt", "grass", "neon_red", "neon_green", "neon_blue", "nitro_fire", "sparks", "drift_smoke", "stadium_pitch", "hazard_stripe", "curb_stripes"]
	for mat_name in names:
		var mat = MatGenScript.get_material(mat_name)
		assert_true(mat != null, "Material '%s' must be generated" % mat_name)
		assert_true(mat is StandardMaterial3D, "Material '%s' must be StandardMaterial3D" % mat_name)

	var tex = MatGenScript.TexSynth.get_texture("sci_fi_metal_albedo")
	assert_true(tex != null, "TextureSynthesizer must return image texture")

func test_material_reuse() -> void:
	var m1 = MatGenScript.get_material("sci_fi_metal")
	var m2 = MatGenScript.get_material("sci_fi_metal")
	assert_true(m1 == m2, "Same material name must return cached instance")

func test_create_pbr_material() -> void:
	var pbr = MatGenScript.create_pbr_material(Color(0.8, 0.2, 0.3), 0.9, 0.2, Color(1, 0, 0), 2.5)
	assert_true(pbr != null, "PBR material must be created")
	assert_true(is_equal_approx(pbr.metallic, 0.9), "PBR metallic must match")
	assert_true(is_equal_approx(pbr.roughness, 0.2), "PBR roughness must match")
	assert_true(pbr.emission_enabled, "PBR emission must be enabled")

func test_clear_cache() -> void:
	MatGenScript.get_material("sci_fi_metal")
	MatGenScript.clear_cache()
	var fresh = MatGenScript.get_material("sci_fi_metal")
	assert_true(fresh != null, "Material re-created after clear_cache")
