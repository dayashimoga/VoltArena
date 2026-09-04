extends Node

const SETTINGS_FILE_PATH: String = "user://voltarena_settings.json"
const CURRENT_SETTINGS_VERSION: int = 1

var settings_data: Dictionary = {}

func _ready() -> void:
	load_settings()

func get_default_settings() -> Dictionary:
	return {
		"version": CURRENT_SETTINGS_VERSION,
		"graphics": {
			"preset": 2, # 0: Low, 1: Med, 2: High, 3: Ultra, 4: Auto
			"resolution_scale": 1.0,
			"shadow_quality": 2, # 0: Off, 1: Low, 2: Med, 3: High
			"anti_aliasing": 2,  # 0: Off, 1: FXAA, 2: MSAA 2x, 3: MSAA 4x
			"glow_enabled": true,
			"particles_enabled": true,
			"fps_limit": 60
		},
		"audio": {
			"master_volume": 0.85,
			"music_volume": 0.70,
			"sfx_volume": 0.90,
			"muted": false
		},
		"controls": {
			"mouse_sensitivity": 0.0025,
			"gamepad_sensitivity": 2.5,
			"invert_y": false,
			"gamepad_deadzone": 0.15,
			"touch_scale": 1.0,
			"touch_opacity": 0.75
		},
		"accessibility": {
			"screen_shake_scale": 1.0,
			"subtitles": true,
			"high_contrast_hud": false,
			"reduced_motion": false
		}
	}

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		settings_data = get_default_settings()
		save_settings()
		return

	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if not file:
		settings_data = get_default_settings()
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_warning("Corrupted settings file detected! Restoring defaults safely.")
		settings_data = get_default_settings()
		save_settings()
		return

	var parsed_data = json.get_data()
	if typeof(parsed_data) != TYPE_DICTIONARY:
		settings_data = get_default_settings()
		save_settings()
		return

	# Version migration handling
	settings_data = migrate_settings(parsed_data)
	apply_all_settings()

func migrate_settings(loaded: Dictionary) -> Dictionary:
	var defaults = get_default_settings()
	var version = loaded.get("version", 0)

	# Ensure all sub-keys exist from defaults
	for section in defaults.keys():
		if section == "version":
			continue
		if not loaded.has(section) or typeof(loaded[section]) != TYPE_DICTIONARY:
			loaded[section] = defaults[section]
		else:
			for key in defaults[section].keys():
				if not loaded[section].has(key):
					loaded[section][key] = defaults[section][key]

	loaded["version"] = CURRENT_SETTINGS_VERSION
	return loaded

func save_settings() -> void:
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(settings_data, "  ")
		file.store_string(json_str)
		file.close()

func apply_all_settings() -> void:
	apply_audio_settings()

func apply_audio_settings() -> void:
	var audio = settings_data.get("audio", {})
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		var vol = audio.get("master_volume", 0.85)
		var muted = audio.get("muted", false)
		AudioServer.set_bus_mute(master_bus, muted)
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(max(0.001, vol)))

func get_setting(section: String, key: String, default_value = null):
	if settings_data.has(section) and settings_data[section].has(key):
		return settings_data[section][key]
	return default_value

func set_setting(section: String, key: String, value) -> void:
	if not settings_data.has(section):
		settings_data[section] = {}
	settings_data[section][key] = value
	save_settings()
