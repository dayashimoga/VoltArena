class_name AircraftVisuals
extends Node3D

## AircraftVisuals: Real-Time Aircraft Animation & Articulation Controller.
## Animates control surfaces, differential stabilators, 2D TVC nozzles,
## speedbrakes, spoilers, landing gear retraction, spinning propellers/rotors,
## high-RPM motion blur disks, afterburner plumes, navigation strobes, and smoke trails.

const FlightPhysics = preload("res://games/aircraft-flight/core/flight_physics.gd")

@export var aircraft_physics: CharacterBody3D

var elevator_l: Node3D
var elevator_r: Node3D
var aileron_l: Node3D
var aileron_r: Node3D
var rudder_l: Node3D
var rudder_r: Node3D
var flap_l: Node3D
var flap_r: Node3D
var speedbrake: Node3D
var spoiler_l: Node3D
var spoiler_r: Node3D
var vector_nozzle_l: Node3D
var vector_nozzle_r: Node3D
var fan_blades_l: Node3D
var fan_blades_r: Node3D
var landing_gear: Node3D
var afterburner_l: Node3D
var afterburner_r: Node3D
var prop_root: Node3D
var prop_blur_disk: Node3D
var main_rotor: Node3D
var main_rotor_blur: Node3D
var tail_rotor: Node3D
var tail_rotor_blur: Node3D

# Internal Rotations & Lighting
var _prop_spin_angle: float = 0.0
var _rotor_spin_angle: float = 0.0
var _beacon_timer: float = 0.0
var _beacon_light: OmniLight3D

func _ready() -> void:
	_bind_visual_nodes()
	_setup_nav_lights()

func _bind_visual_nodes() -> void:
	var search_root: Node = self
	if is_instance_valid(aircraft_physics):
		search_root = aircraft_physics
	elif get_parent() != null:
		search_root = get_parent()

	elevator_l = search_root.find_child("ElevatorLeft", true, false)
	elevator_r = search_root.find_child("ElevatorRight", true, false)
	if not elevator_l:
		elevator_l = search_root.find_child("Elevator", true, false)

	aileron_l = search_root.find_child("AileronLeft", true, false)
	aileron_r = search_root.find_child("AileronRight", true, false)
	rudder_l = search_root.find_child("RudderLeft", true, false)
	rudder_r = search_root.find_child("RudderRight", true, false)
	if not rudder_l:
		rudder_l = search_root.find_child("Rudder", true, false)

	flap_l = search_root.find_child("FlapLeft", true, false)
	flap_r = search_root.find_child("FlapRight", true, false)
	speedbrake = search_root.find_child("Speedbrake", true, false)
	spoiler_l = search_root.find_child("SpoilerLeft", true, false)
	spoiler_r = search_root.find_child("SpoilerRight", true, false)

	vector_nozzle_l = search_root.find_child("VectorNozzleLeft", true, false)
	vector_nozzle_r = search_root.find_child("VectorNozzleRight", true, false)
	fan_blades_l = search_root.find_child("FanBladesLeft", true, false)
	fan_blades_r = search_root.find_child("FanBladesRight", true, false)

	landing_gear = search_root.find_child("LandingGear", true, false)
	afterburner_l = search_root.find_child("AfterburnerPlumeLeft", true, false)
	afterburner_r = search_root.find_child("AfterburnerPlumeRight", true, false)

	prop_root = search_root.find_child("Propeller", true, false)
	prop_blur_disk = search_root.find_child("PropBlurDisk", true, false)
	main_rotor = search_root.find_child("MainRotor", true, false)
	main_rotor_blur = search_root.find_child("MainRotorBlur", true, false)
	tail_rotor = search_root.find_child("TailRotor", true, false)
	tail_rotor_blur = search_root.find_child("TailRotorBlur", true, false)

func _setup_nav_lights() -> void:
	# Port (Red) on left wingtip - localized emissive marker without floor projection blotches
	var port_light = OmniLight3D.new()
	port_light.light_color = Color(1.0, 0.1, 0.1)
	port_light.light_energy = 0.6
	port_light.omni_range = 0.6
	port_light.position = Vector3(-6.0, 0.5, 0.5)
	add_child(port_light)

	# Starboard (Green) on right wingtip - localized emissive marker without floor projection blotches
	var stbd_light = OmniLight3D.new()
	stbd_light.light_color = Color(0.1, 1.0, 0.2)
	stbd_light.light_energy = 0.6
	stbd_light.omni_range = 0.6
	stbd_light.position = Vector3(6.0, 0.5, 0.5)
	add_child(stbd_light)

	# Anti-collision beacon on spine
	_beacon_light = OmniLight3D.new()
	_beacon_light.light_color = Color(1.0, 0.2, 0.1)
	_beacon_light.light_energy = 0.0
	_beacon_light.omni_range = 8.0
	_beacon_light.position = Vector3(0.0, 1.8, 0.0)
	add_child(_beacon_light)

func _process(delta: float) -> void:
	if not is_instance_valid(aircraft_physics) or delta <= 0.0:
		return
	if elevator_l == null and aileron_l == null:
		_bind_visual_nodes()

	var elev_deg = aircraft_physics.elevator_deflection * 25.0
	var aileron_deg = aircraft_physics.aileron_left_deflection * 20.0

	# 1. Differential Stabilators & Elevators
	if elevator_l:
		elevator_l.rotation_degrees.x = elev_deg + aileron_deg * 0.25
	if elevator_r:
		elevator_r.rotation_degrees.x = elev_deg - aileron_deg * 0.25

	# 2. Ailerons (Roll deflection +/- 20 degrees, differential)
	if aileron_l:
		aileron_l.rotation_degrees.x = aileron_deg
	if aileron_r:
		aileron_r.rotation_degrees.x = -aileron_deg

	# 3. Rudder (Yaw deflection +/- 25 degrees)
	var rudder_deg = -aircraft_physics.rudder_deflection * 25.0
	if rudder_l:
		rudder_l.rotation_degrees.y = rudder_deg
	if rudder_r:
		rudder_r.rotation_degrees.y = rudder_deg

	# 4. Flaps (Downward deployment: 0 deg, 15 deg, 35 deg)
	var flap_target_deg = float(aircraft_physics.flaps_step) * 17.5
	if flap_l:
		flap_l.rotation_degrees.x = flap_target_deg
	if flap_r:
		flap_r.rotation_degrees.x = flap_target_deg

	# 5. Speedbrake & Spoilers
	var sb_active = aircraft_physics.airbrake_deployed
	if speedbrake:
		speedbrake.rotation_degrees.x = -50.0 if sb_active else 0.0
	if spoiler_l:
		spoiler_l.rotation_degrees.x = -35.0 if sb_active else 0.0
	if spoiler_r:
		spoiler_r.rotation_degrees.x = -35.0 if sb_active else 0.0

	# 6. 2D Pitch Thrust-Vectoring Nozzles (F-22 Raptor)
	if vector_nozzle_l:
		vector_nozzle_l.rotation_degrees.x = elev_deg * 0.75
	if vector_nozzle_r:
		vector_nozzle_r.rotation_degrees.x = elev_deg * 0.75

	# 7. N1 High-Bypass Turbofan Blades (A320)
	if fan_blades_l:
		fan_blades_l.rotation.z += deg_to_rad(aircraft_physics.engine_rpm_pct * 30.0 * delta)
	if fan_blades_r:
		fan_blades_r.rotation.z += deg_to_rad(aircraft_physics.engine_rpm_pct * 30.0 * delta)

	# 8. Landing Gear Retraction
	if landing_gear:
		var gear_pos = aircraft_physics.gear_position
		landing_gear.scale = Vector3(1.0, gear_pos, 1.0)
		landing_gear.visible = gear_pos > 0.05

	# 9. Afterburner Plume Scaling & Visibility
	var ab_active = aircraft_physics.afterburner_active and aircraft_physics.throttle >= 0.95
	var ab_scale = 1.8 if ab_active else (0.6 * (aircraft_physics.engine_rpm_pct / 100.0))
	if afterburner_l:
		afterburner_l.visible = aircraft_physics.engine_rpm_pct > 10.0
		afterburner_l.scale = Vector3(ab_scale, ab_scale, ab_scale * 1.5 if ab_active else 0.5)
	if afterburner_r:
		afterburner_r.visible = aircraft_physics.engine_rpm_pct > 10.0
		afterburner_r.scale = Vector3(ab_scale, ab_scale, ab_scale * 1.5 if ab_active else 0.5)

	# 10. Spinning Propeller & Motion Blur Disk (Extra 330)
	var prop_rpm = (aircraft_physics.engine_rpm_pct / 100.0) * 2800.0
	if prop_root:
		_prop_spin_angle += deg_to_rad(prop_rpm * 6.0 * delta)
		prop_root.rotation.z = _prop_spin_angle
	if prop_blur_disk:
		prop_blur_disk.visible = prop_rpm > 300.0
		if prop_blur_disk.material_override and prop_blur_disk.material_override is ShaderMaterial:
			prop_blur_disk.material_override.set_shader_parameter("rpm_normalized", clampf(prop_rpm / 2600.0, 0.0, 1.0))

	# 11. Helicopter Rotors & Radial Blur Disks (UH-60)
	var main_rpm = (aircraft_physics.rotor_rpm_pct / 100.0) * 320.0
	var tail_rpm = (aircraft_physics.rotor_rpm_pct / 100.0) * 1400.0
	if main_rotor:
		_rotor_spin_angle += deg_to_rad(main_rpm * 6.0 * delta)
		main_rotor.rotation.y = _rotor_spin_angle
	if main_rotor_blur:
		main_rotor_blur.visible = main_rpm > 100.0
		if main_rotor_blur.material_override and main_rotor_blur.material_override is ShaderMaterial:
			main_rotor_blur.material_override.set_shader_parameter("rpm_normalized", clampf(main_rpm / 300.0, 0.0, 1.0))

	if tail_rotor:
		tail_rotor.rotation.x += deg_to_rad(tail_rpm * 6.0 * delta)
	if tail_rotor_blur:
		tail_rotor_blur.visible = tail_rpm > 300.0
		if tail_rotor_blur.material_override and tail_rotor_blur.material_override is ShaderMaterial:
			tail_rotor_blur.material_override.set_shader_parameter("rpm_normalized", clampf(tail_rpm / 1300.0, 0.0, 1.0))

	# 12. Flashing Beacon Strobe (1 Hz flash)
	_beacon_timer += delta
	if _beacon_timer >= 1.0:
		_beacon_timer = 0.0
	if _beacon_light:
		_beacon_light.light_energy = 5.0 if _beacon_timer < 0.12 else 0.0
