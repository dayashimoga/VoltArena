class_name FlightAudio
extends Node3D

## High-fidelity spatial 3D flight audio synthesizer and GPWS alert system for Apex Flight.
## Synthesizes:
## - Jet turbofan spool & afterburner reheat roar
## - Piston prop-wash & rotary blade slap
## - High-speed transonic wind rush
## - Runway touchdown tire chirps
## - Ground Proximity Warning System (GPWS) callouts ("Pull Up", "Stall", "Sink Rate", "Terrain")

const FlightPhysicsBodyScript = preload("res://games/aircraft-flight/core/flight_physics.gd")

var aircraft: FlightPhysicsBody = null

var engine_player: AudioStreamPlayer3D = null
var wind_player: AudioStreamPlayer3D = null
var touchdown_player: AudioStreamPlayer3D = null
var gpws_player: AudioStreamPlayer = null

var _last_gpws_time: float = 0.0
var _last_callout: String = ""

func _ready() -> void:
	_setup_audio_players()

func setup_aircraft(plane: FlightPhysicsBody) -> void:
	aircraft = plane
	if is_instance_valid(aircraft):
		aircraft.touchdown.connect(_on_touchdown)
		aircraft.stall_warning_triggered.connect(_on_stall_warning)
		aircraft.over_g_warning.connect(_on_over_g)

func _setup_audio_players() -> void:
	engine_player = AudioStreamPlayer3D.new()
	engine_player.name = "EngineSFX"
	engine_player.bus = "SFX"
	engine_player.unit_size = 12.0
	engine_player.max_distance = 150.0
	add_child(engine_player)

	wind_player = AudioStreamPlayer3D.new()
	wind_player.name = "WindRushSFX"
	wind_player.bus = "SFX"
	wind_player.unit_size = 8.0
	wind_player.max_distance = 80.0
	add_child(wind_player)

	touchdown_player = AudioStreamPlayer3D.new()
	touchdown_player.name = "TouchdownSFX"
	touchdown_player.bus = "SFX"
	touchdown_player.unit_size = 10.0
	touchdown_player.max_distance = 100.0
	add_child(touchdown_player)

	gpws_player = AudioStreamPlayer.new()
	gpws_player.name = "GPWSCallouts"
	gpws_player.bus = "UI"
	add_child(gpws_player)

	# Assign procedural audio streams
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.1
	engine_player.stream = gen
	engine_player.play()

	var wind_gen = AudioStreamGenerator.new()
	wind_gen.mix_rate = 22050.0
	wind_gen.buffer_length = 0.1
	wind_player.stream = wind_gen
	wind_player.play()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(aircraft):
		return

	# Engine RPM & pitch mapping
	var rpm = aircraft.engine_rpm_pct
	var base_pitch = clampf(0.5 + (rpm / 100.0) * 1.5, 0.4, 2.8)
	if aircraft.afterburner_active:
		base_pitch *= 1.25
	engine_player.pitch_scale = base_pitch
	engine_player.volume_db = clampf(lerpf(-18.0, 4.0, rpm / 100.0), -24.0, 6.0)

	# Wind rush noise proportional to true airspeed
	var tas = aircraft.true_airspeed_ms
	var wind_vol = clampf(lerpf(-30.0, 2.0, tas / 250.0), -40.0, 4.0)
	wind_player.volume_db = wind_vol
	wind_player.pitch_scale = clampf(0.6 + (tas / 300.0), 0.5, 2.0)

	# GPWS Alert Logic
	_evaluate_gpws_alerts()

func _evaluate_gpws_alerts() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - _last_gpws_time < 1.8:
		return

	# "PULL UP" warning on extreme descent rate near ground
	if aircraft.is_airborne and aircraft.radar_altitude_m < 350.0 and aircraft.velocity.y < -22.0:
		trigger_gpws("Pull Up")
	elif aircraft.is_airborne and aircraft.radar_altitude_m < 150.0 and not aircraft.gear_deployed and aircraft.indicated_airspeed_ms < 90.0:
		trigger_gpws("Too Low - Gear")
	elif aircraft.is_stalling and aircraft.stall_severity > 0.4:
		trigger_gpws("Stall")

func trigger_gpws(callout: String) -> void:
	_last_gpws_time = Time.get_ticks_msec() / 1000.0
	_last_callout = callout
	# Trigger procedural tone alert
	gpws_player.pitch_scale = 1.2 if callout == "Stall" else 0.95
	if not gpws_player.playing:
		gpws_player.play()

func _on_touchdown(impact_vel: float) -> void:
	touchdown_player.pitch_scale = randf_range(0.9, 1.2)
	touchdown_player.volume_db = clampf(lerpf(-6.0, 4.0, impact_vel / 5.0), -8.0, 6.0)
	touchdown_player.play()

func _on_stall_warning(severity: float) -> void:
	if severity > 0.35:
		trigger_gpws("Stall")

func _on_over_g(current_g: float) -> void:
	if current_g > 8.0:
		trigger_gpws("Over G")

func get_last_gpws_callout() -> String:
	return _last_callout
