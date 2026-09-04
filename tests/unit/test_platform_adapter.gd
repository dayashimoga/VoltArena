class_name TestPlatformAdapter
extends RefCounted

const PlatformAdapterScript = preload("res://shared/platform/platform_adapter.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_detection()
	test_platform_name_string()
	test_touch_and_safe_area()
	test_trigger_haptic()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/platform/platform_adapter.gd",
		[
			"_ready", "detect_platform", "detect_inputs",
			"is_touch_active", "get_safe_area_margins",
			"trigger_haptic", "get_platform_name_string"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit PlatformAdapter FAIL: " + msg)

func test_detection() -> void:
	var pa = PlatformAdapterScript.new()
	pa._ready()
	assert_true(pa.current_platform in [
		pa.PlatformType.WEB, pa.PlatformType.ANDROID, pa.PlatformType.WINDOWS,
		pa.PlatformType.LINUX, pa.PlatformType.MACOS, pa.PlatformType.IOS
	], "Platform must be one of the known PlatformTypes")

func test_platform_name_string() -> void:
	var pa = PlatformAdapterScript.new()
	pa.current_platform = pa.PlatformType.WINDOWS
	assert_true(pa.get_platform_name_string() == "Windows", "Windows platform name string")
	pa.current_platform = pa.PlatformType.LINUX
	assert_true(pa.get_platform_name_string() == "Linux", "Linux platform name string")
	pa.current_platform = pa.PlatformType.ANDROID
	assert_true(pa.get_platform_name_string() == "Android", "Android platform name string")
	pa.current_platform = pa.PlatformType.WEB
	assert_true(pa.get_platform_name_string().contains("Web"), "Web platform name string")

func test_touch_and_safe_area() -> void:
	var pa = PlatformAdapterScript.new()
	pa._ready()
	var is_touch = pa.is_touch_active()
	assert_true(typeof(is_touch) == TYPE_BOOL, "is_touch_active must return boolean")
	var safe_area = pa.get_safe_area_margins()
	assert_true(typeof(safe_area) == TYPE_RECT2, "get_safe_area_margins must return Rect2")

func test_trigger_haptic() -> void:
	var pa = PlatformAdapterScript.new()
	pa._ready()
	# trigger_haptic must not crash
	pa.trigger_haptic(20, 0.2, 0.2)
	assert_true(true, "trigger_haptic must execute without crashing")
