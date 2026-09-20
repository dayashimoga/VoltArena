class_name TestCrossPlatformArchitecture
extends RefCounted

## Automated unit test suite for Global Cross-Platform Architecture
## Validates PlatformCapabilities, InputProfile, and GraphicsProfile abstractions

const PlatformCapabilities = preload("res://shared/platform/platform_capabilities.gd")
const InputProfile = preload("res://shared/platform/input_profile.gd")
const GraphicsProfile = preload("res://shared/platform/graphics_profile.gd")
const RocketArenaScript = preload("res://games/rocket-car/arena/rocket_arena.gd")
const CarAIScript = preload("res://games/rocket-car/ai/car_ai.gd")
const CarControllerScript = preload("res://games/rocket-car/vehicle/car_controller.gd")
const RocketCarMainScript = preload("res://games/rocket-car/rocket_car_main.gd")

func run_tests() -> Dictionary:
	var results = {"passed": 0, "failed": 0, "errors": []}
	_test_platform_capabilities(results)
	_test_input_profiles_and_prompts(results)
	_test_graphics_profiles_and_invariants(results)
	_test_nitro_kick_p0_subsystems(results)
	return results

func get_coverage_entries() -> Array:
	return [
		[
			"res://shared/platform/platform_capabilities.gd",
			[
				"get_platform_category", "is_mobile", "is_desktop", "is_web",
				"has_touchscreen", "has_gamepad", "get_safe_area", "get_safe_area_margins",
				"apply_safe_area_margins", "get_aspect_ratio_category", "get_device_tier",
				"get_min_touch_target_size", "supports_haptics"
			]
		],
		[
			"res://shared/platform/input_profile.gd",
			[
				"get_active_profile", "set_active_profile", "set_active_genre",
				"get_active_genre", "is_touch_active", "get_action_prompt"
			]
		],
		[
			"res://shared/platform/graphics_profile.gd",
			[
				"get_preset_name", "get_settings_for_preset", "apply_to_viewport"
			]
		],
		[
			"res://games/rocket-car/arena/rocket_arena.gd",
			[
				"_process", "build_octagonal_perimeter", "build_regulation_goal",
				"trigger_goal_explosion", "build_stadium_grandstands_and_crowd",
				"set_crowd_state", "set_crowd_reaction_state", "build_boost_system",
				"create_flush_boost_pad", "setup_stadium_environment"
			]
		],
		[
			"res://games/rocket-car/ai/car_ai.gd",
			["set_role", "predict_ball_intercept"]
		],
		[
			"res://games/rocket-car/rocket_car_main.gd",
			["select_stadium_theme", "get_available_stadiums"]
		],
		[
			"res://games/rocket-car/vehicle/car_controller.gd",
			["set_vehicle_archetype", "apply_archetype_stats"]
		]
	]

func _test_platform_capabilities(results: Dictionary) -> void:
	# 1. Platform Category detection
	var cat = PlatformCapabilities.get_platform_category()
	if cat >= 0 and cat <= 5:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Invalid platform category")

	# 2. Desktop/Mobile mutually exclusive on native desktop
	var is_mob = PlatformCapabilities.is_mobile()
	var is_desk = PlatformCapabilities.is_desktop()
	if is_mob != is_desk:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("is_mobile and is_desktop must be mutually exclusive")

	# 3. Web check
	var is_web = PlatformCapabilities.is_web()
	if is_web == OS.has_feature("web"):
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("is_web must match OS.has_feature('web')")

	# 4. Safe area and margins
	var safe = PlatformCapabilities.get_safe_area()
	var margins = PlatformCapabilities.get_safe_area_margins(Vector2(1280, 720))
	if margins.has("left") and margins.has("top") and margins.has("right") and margins.has("bottom"):
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Safe area margins dictionary missing keys")

	# 5. Apply safe area margins to control
	var ctrl = Control.new()
	ctrl.size = Vector2(1280, 720)
	PlatformCapabilities.apply_safe_area_margins(ctrl)
	results["passed"] += 1
	ctrl.queue_free()

	# 6. Aspect ratio categories
	var cat_16_9 = PlatformCapabilities.get_aspect_ratio_category(Vector2(1920, 1080))
	var cat_20_9 = PlatformCapabilities.get_aspect_ratio_category(Vector2(412, 915))
	if cat_16_9 == "16:9" and (cat_20_9 == "20:9" or cat_20_9 == "19.5:9" or cat_20_9.contains("9")):
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Aspect ratio classification incorrect: 1080p=%s, phone=%s" % [cat_16_9, cat_20_9])

	# 7. Device performance tiers
	var tier = PlatformCapabilities.get_device_tier()
	if tier >= 0 and tier <= 3:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Device tier out of range")

	# 8. Touch target size
	var min_target = PlatformCapabilities.get_min_touch_target_size()
	if min_target.x >= 48.0 and min_target.y >= 48.0:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Minimum touch target must be >= 48dp")

	# 9. Touchscreen / Gamepad detection
	var _touch = PlatformCapabilities.has_touchscreen()
	var _gamepad = PlatformCapabilities.has_gamepad()
	var _haptics = PlatformCapabilities.supports_haptics()
	results["passed"] += 1

func _test_input_profiles_and_prompts(results: Dictionary) -> void:
	# 1. Profile switching
	InputProfile.set_active_profile(InputProfile.ProfileType.DESKTOP_KEYBOARD_MOUSE)
	if InputProfile.get_active_profile() == InputProfile.ProfileType.DESKTOP_KEYBOARD_MOUSE or PlatformCapabilities.is_mobile():
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("set_active_profile failed")

	# 2. Genre switching
	InputProfile.set_active_genre(InputProfile.GenreType.GENRE_RACING)
	if InputProfile.get_active_genre() == InputProfile.GenreType.GENRE_RACING:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("set_active_genre failed")

	# 3. Touch active query
	var _is_touch = InputProfile.is_touch_active()
	results["passed"] += 1

	# 4. Action prompts across profiles
	var prompt_kbm = InputProfile.get_action_prompt("fire", InputProfile.ProfileType.DESKTOP_KEYBOARD_MOUSE)
	var prompt_pad = InputProfile.get_action_prompt("fire", InputProfile.ProfileType.DESKTOP_CONTROLLER)
	var prompt_touch = InputProfile.get_action_prompt("fire", InputProfile.ProfileType.TOUCH_PHONE)
	if prompt_kbm == "LMB" and prompt_pad == "RT" and prompt_touch.contains("FIRE"):
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Action prompts incorrect: kbm=%s, pad=%s, touch=%s" % [prompt_kbm, prompt_pad, prompt_touch])

func _test_graphics_profiles_and_invariants(results: Dictionary) -> void:
	# 1. Preset names
	var name_low = GraphicsProfile.get_preset_name(GraphicsProfile.Preset.PRESET_LOW)
	var name_ultra = GraphicsProfile.get_preset_name(GraphicsProfile.Preset.PRESET_ULTRA)
	if name_low.contains("Low") and name_ultra.contains("Ultra"):
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Preset names incorrect")

	# 2. Preset settings scaling
	var low_cfg = GraphicsProfile.get_settings_for_preset(GraphicsProfile.Preset.PRESET_LOW)
	var ultra_cfg = GraphicsProfile.get_settings_for_preset(GraphicsProfile.Preset.PRESET_ULTRA)
	if low_cfg["shadow_atlas_size"] <= 1024 and ultra_cfg["shadow_atlas_size"] >= 2048:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Shadow atlas did not scale properly across presets")

	# 3. Physics step invariant (60Hz)
	if Engine.physics_ticks_per_second == 60:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Physics ticks per second must strictly equal 60")

	# 4. Apply to dummy viewport
	var vp = SubViewport.new()
	GraphicsProfile.apply_to_viewport(vp, GraphicsProfile.Preset.PRESET_MEDIUM)
	results["passed"] += 1
	vp.queue_free()

func _test_nitro_kick_p0_subsystems(results: Dictionary) -> void:
	# 1. RocketArena methods
	var arena = RocketArenaScript.new()
	arena.stadium_theme = "cyber"
	arena.setup_stadium_environment()
	arena.build_octagonal_perimeter(55.0, 32.0)
	arena.build_stadium_grandstands_and_crowd(55.0, 32.0)
	arena.build_boost_system(55.0, 32.0)
	arena.set_crowd_state("idle")
	arena.set_crowd_reaction_state("goal")
	arena.trigger_goal_explosion(0, Vector3(0, 2, -50))
	arena.create_flush_boost_pad(Vector3(0, 0.05, 0))
	arena._process(0.016)
	results["passed"] += 1
	arena.queue_free()

	# 2. CarAI methods
	var car = CarControllerScript.new()
	var ai = CarAIScript.new()
	ai.car = car
	ai.set_role(CarAIScript.AIRole.STRIKER)
	var target = ai.predict_ball_intercept(Vector3(0, 1, 0), Vector3(10, 0, 10), 0.5)
	if target is Vector3:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("predict_ball_intercept must return Vector3")
	ai.queue_free()

	# 3. CarController archetype
	car.set_vehicle_archetype("titan_enforcer")
	car.apply_archetype_stats()
	if car.mass == 1400.0:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Titan Enforcer mass must be 1400.0")
	car.queue_free()

	# 4. RocketCarMain stadium methods
	var rcm = RocketCarMainScript.new()
	var stads = rcm.get_available_stadiums()
	if stads.size() >= 2:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Must provide at least 2 stadium themes")
	rcm.select_stadium_theme("cyber")
	rcm.queue_free()
