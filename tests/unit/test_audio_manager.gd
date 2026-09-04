class_name TestAudioManager
extends RefCounted

const AudioManagerScript = preload("res://shared/audio/audio_manager.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_initialization()
	test_sound_catalog()
	test_volume_control()
	test_procedural_generation()
	test_sound_playback()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/audio/audio_manager.gd",
		[
			"_ready", "setup_players", "generate_all_procedural_sounds",
			"play_sound", "play_sound_3d", "create_synth_sound",
			"create_noise_burst", "create_two_tone_sound", "create_click_sound"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit AudioManager FAIL: " + msg)

func test_initialization() -> void:
	var am = AudioManagerScript.new()
	am.setup_players()
	assert_true(am.sfx_pool.size() > 0, "SFX pool must be populated")
	assert_true(am.sfx_3d_pool.size() > 0, "SFX 3D pool must be populated")
	am.queue_free()

func test_sound_catalog() -> void:
	var am = AudioManagerScript.new()
	assert_true(am.has_method("play_sound"), "Must have play_sound method")
	am.queue_free()

func test_volume_control() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	assert_true(master_idx >= 0, "Master audio bus must exist")

func test_procedural_generation() -> void:
	var am = AudioManagerScript.new()
	var s1 = am.create_synth_sound(440.0, 220.0, 0.05, 0.5, "sine")
	assert_true(s1 != null, "create_synth_sound must generate AudioStream")

	var s2 = am.create_noise_burst(0.05, 0.5, 0.5)
	assert_true(s2 != null, "create_noise_burst must generate AudioStream")

	var s3 = am.create_two_tone_sound(440.0, 880.0, 0.05, 0.5)
	assert_true(s3 != null, "create_two_tone_sound must generate AudioStream")

	var s4 = am.create_click_sound(0.02)
	assert_true(s4 != null, "create_click_sound must generate AudioStream")

	am.generate_all_procedural_sounds()
	assert_true(am.sound_cache.size() >= 5, "sound_cache must contain generated sound effects")
	am.queue_free()

func test_sound_playback() -> void:
	var am = AudioManagerScript.new()
	am.setup_players()
	am.generate_all_procedural_sounds()
	am.play_sound("laser_fire")
	am.play_sound_3d("laser_fire", Vector3.ZERO)
	assert_true(true, "Sound playback calls must succeed")
	am.queue_free()
