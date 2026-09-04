class_name TestQualityManager
extends RefCounted

const QualityManagerScript = preload("res://shared/graphics/quality_manager.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_ready()
	test_preset_constants()
	test_preset_transitions()
	test_auto_detect()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [["res://shared/graphics/quality_manager.gd", ["_ready", "apply_preset", "auto_detect_and_apply"]]]

func test_ready() -> void:
	var qm = QualityManagerScript.new()
	qm._ready()
	assert_true(qm.current_preset == QualityManagerScript.PRESET_HIGH, "Default preset must be HIGH")
	qm.queue_free()

func assert_true(cond: bool, msg: String) -> void:
	if cond: assertions_passed += 1
	else: assertions_failed += 1; push_error("Unit QualityManager FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_preset_constants() -> void:
	assert_eq(QualityManagerScript.PRESET_LOW, 0, "LOW preset must be 0")
	assert_eq(QualityManagerScript.PRESET_MEDIUM, 1, "MEDIUM preset must be 1")
	assert_eq(QualityManagerScript.PRESET_HIGH, 2, "HIGH preset must be 2")
	assert_eq(QualityManagerScript.PRESET_ULTRA, 3, "ULTRA preset must be 3")
	assert_eq(QualityManagerScript.PRESET_AUTO, 4, "AUTO preset must be 4")

func test_preset_transitions() -> void:
	var qm = QualityManagerScript.new()
	qm.current_preset = QualityManagerScript.PRESET_LOW
	# apply_preset without viewport won't crash but will set current_preset
	qm.apply_preset(QualityManagerScript.PRESET_HIGH)
	assert_eq(qm.current_preset, QualityManagerScript.PRESET_HIGH, "Preset must update to HIGH")

	qm.apply_preset(QualityManagerScript.PRESET_LOW)
	assert_eq(qm.current_preset, QualityManagerScript.PRESET_LOW, "Preset must update to LOW")

	qm.apply_preset(QualityManagerScript.PRESET_ULTRA)
	assert_eq(qm.current_preset, QualityManagerScript.PRESET_ULTRA, "Preset must update to ULTRA")

func test_auto_detect() -> void:
	var qm = QualityManagerScript.new()
	qm.auto_detect_and_apply()
	# After auto detect, current_preset should be MEDIUM or HIGH
	assert_true(qm.current_preset in [QualityManagerScript.PRESET_MEDIUM, QualityManagerScript.PRESET_HIGH],
		"AUTO must resolve to MEDIUM or HIGH")
