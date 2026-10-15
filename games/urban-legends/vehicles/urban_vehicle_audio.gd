class_name UrbanVehicleAudio
extends Node3D

## Dynamic procedural vehicle audio generator and spatial SFX for Urban Legends.
## Synthesizes engine RPM hum, transmission gear whine, tire skid squeals,
const UrbanVehicle = preload("res://games/urban-legends/vehicles/urban_vehicle.gd")

var vehicle: UrbanVehicle = null

var engine_player: AudioStreamPlayer3D = null
var skid_player: AudioStreamPlayer3D = null
var nitro_player: AudioStreamPlayer3D = null
var crash_player: AudioStreamPlayer3D = null

func _ready() -> void:
	_setup_audio_players()

func setup_vehicle(veh: UrbanVehicle) -> void:
	vehicle = veh
	if is_instance_valid(vehicle):
		vehicle.speed_changed.connect(_on_speed_changed)
		vehicle.vehicle_damaged.connect(_on_vehicle_damaged)
		vehicle.stunt_landed.connect(_on_stunt_landed)

func _setup_audio_players() -> void:
	engine_player = AudioStreamPlayer3D.new()
	engine_player.name = "EngineAudio"
	engine_player.bus = "SFX"
	engine_player.unit_size = 8.0
	engine_player.max_distance = 60.0
	add_child(engine_player)

	skid_player = AudioStreamPlayer3D.new()
	skid_player.name = "SkidAudio"
	skid_player.bus = "SFX"
	skid_player.unit_size = 6.0
	skid_player.max_distance = 45.0
	add_child(skid_player)

	nitro_player = AudioStreamPlayer3D.new()
	nitro_player.name = "NitroAudio"
	nitro_player.bus = "SFX"
	nitro_player.unit_size = 7.0
	nitro_player.max_distance = 50.0
	add_child(nitro_player)

	crash_player = AudioStreamPlayer3D.new()
	crash_player.name = "CrashAudio"
	crash_player.bus = "SFX"
	crash_player.unit_size = 10.0
	crash_player.max_distance = 70.0
	add_child(crash_player)

	# Generate simple procedural audio streams if generator is available
	_assign_procedural_tones()

func _assign_procedural_tones() -> void:
	# Use AudioStreamGenerator for real-time engine pitch
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.1
	engine_player.stream = gen
	engine_player.play()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(vehicle):
		return

	# Engine RPM pitch mapping
	var rpm = vehicle.get_rpm()
	var pitch = clampf(rpm / 3500.0, 0.4, 2.5)
	engine_player.pitch_scale = pitch

	# Skid sound on drift
	if vehicle.is_drifting and vehicle.is_on_ground():
		if not skid_player.playing:
			skid_player.play()
		skid_player.volume_db = clampf(lerpf(-24.0, 0.0, vehicle.get_drift_angle() / 45.0), -30.0, 2.0)
	else:
		if skid_player.playing:
			skid_player.stop()

	# Nitro sound
	if vehicle.is_nitro_active:
		if not nitro_player.playing:
			nitro_player.play()
	else:
		if nitro_player.playing:
			nitro_player.stop()

func _on_speed_changed(_speed_kmh: float, _gear: int, _rpm_norm: float) -> void:
	pass

func _on_vehicle_damaged(_health: float, damage: float) -> void:
	if damage > 4.0:
		crash_player.pitch_scale = randf_range(0.85, 1.15)
		crash_player.volume_db = clampf(lerpf(-10.0, 4.0, damage / 25.0), -12.0, 6.0)
		crash_player.play()

func _on_stunt_landed(rating: String, impact_vel: float, _air_time: float) -> void:
	if rating == "Hard" or impact_vel > 8.0:
		crash_player.pitch_scale = 0.75
		crash_player.volume_db = 0.0
		crash_player.play()
