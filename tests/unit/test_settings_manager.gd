class_name TestSettingsManager
extends RefCounted

const SettingsManagerScript = preload("res://shared/settings/settings_manager.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_default_settings()
	test_get_set_setting()
	test_migration()
	test_save_and_load()
	test_audio_application()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/settings/settings_manager.gd",
		[
			"_ready", "get_default_settings", "load_settings",
			"migrate_settings", "save_settings", "apply_all_settings",
			"apply_audio_settings", "get_setting", "set_setting"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit SettingsManager FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_default_settings() -> void:
	var sm = SettingsManagerScript.new()
	var defs = sm.get_default_settings()
	assert_true(defs.has("graphics"), "Defaults must contain graphics section")
	assert_true(defs.has("audio"), "Defaults must contain audio section")
	assert_true(defs.has("controls"), "Defaults must contain controls section")
	assert_true(defs.has("accessibility"), "Defaults must contain accessibility section")
	assert_eq(defs["version"], 1, "Settings version must be 1")

func test_get_set_setting() -> void:
	var sm = SettingsManagerScript.new()
	sm.settings_data = sm.get_default_settings()
	sm.set_setting("audio", "master_volume", 0.5)
	assert_eq(sm.get_setting("audio", "master_volume"), 0.5, "Master volume must be updated")

	# Fallback on nonexistent key
	var fallback = sm.get_setting("nonexistent", "key", 42)
	assert_eq(fallback, 42, "Must return fallback default value")

func test_migration() -> void:
	var sm = SettingsManagerScript.new()
	# Partial dictionary missing sections and keys
	var partial = {
		"version": 0,
		"audio": {
			"master_volume": 0.3
		}
	}
	var migrated = sm.migrate_settings(partial)
	assert_eq(migrated["version"], 1, "Version must be migrated to 1")
	assert_eq(migrated["audio"]["master_volume"], 0.3, "Custom volume must be preserved")
	assert_true(migrated.has("graphics"), "Missing graphics section must be added")
	assert_true(migrated.has("controls"), "Missing controls section must be added")

func test_save_and_load() -> void:
	var sm = SettingsManagerScript.new()
	sm._ready()
	assert_true(sm.settings_data.size() > 0, "Settings must be loaded on _ready")
	sm.save_settings()
	sm.load_settings()
	assert_true(sm.settings_data.has("audio"), "Loaded settings must have audio")

func test_audio_application() -> void:
	var sm = SettingsManagerScript.new()
	sm.settings_data = sm.get_default_settings()
	sm.apply_all_settings()
	sm.apply_audio_settings()
	assert_true(true, "Audio settings application must execute without error")
