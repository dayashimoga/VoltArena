class_name FlightMissionDirector
extends Node

## FlightMissionDirector: Mission Loop, Objective Tracking & Scoring Engine.
## Evaluates objectives for all 8 mission modes, manages countdown, tracks
## time splits, awards medals, and persists progression to SaveManager.

const FlightConst = preload("res://games/aircraft-flight/core/flight_constants.gd")
const MissionDefs = preload("res://games/aircraft-flight/missions/mission_definitions.gd")
const CheckpointRingScript = preload("res://games/aircraft-flight/missions/checkpoint_ring.gd")

var active_mission_id: String = "m1_free_flight"
var current_mission_data: Dictionary = {}
var is_mission_active: bool = false
var elapsed_time_s: float = 0.0
var score: int = 0
var current_objective_text: String = ""

# Mode specific tracking
var current_ring_index: int = 0
var total_rings: int = 0
var rings_container: Node3D
var has_taken_off: bool = false
var has_climbed_target_alt: bool = false
var urban_skimming_seconds: float = 0.0
var hover_timer_s: float = 0.0
var survivor_hoisted: bool = false
var landmarks_captured: int = 0

signal objective_updated(text: String)
signal mission_completed(summary: Dictionary)
signal mission_failed(reason: String)

func start_mission(mission_id: String, aircraft: CharacterBody3D, world_root: Node3D) -> void:
	active_mission_id = mission_id
	current_mission_data = MissionDefs.get_mission(mission_id)
	is_mission_active = true
	elapsed_time_s = 0.0
	score = 0
	current_ring_index = 0
	has_taken_off = false
	has_climbed_target_alt = false
	urban_skimming_seconds = 0.0
	hover_timer_s = 0.0
	survivor_hoisted = false
	landmarks_captured = 0

	# Apply initial mission state to aircraft
	if is_instance_valid(aircraft):
		if current_mission_data.get("engine_cut", false):
			aircraft.throttle = 0.0
			aircraft.set_pilot_inputs(0.0, 0.0, 0.0)

	# Spawn Checkpoint Rings if race
	if current_mission_data.get("type", -1) == FlightConst.MissionType.CHECKPOINT_AIR_RACE:
		_setup_race_rings(world_root)

	_update_initial_objective()

func _setup_race_rings(world_root: Node3D) -> void:
	if is_instance_valid(rings_container):
		rings_container.queue_free()

	rings_container = Node3D.new()
	rings_container.name = "AirRaceRings"
	world_root.add_child(rings_container)

	var waypoints = current_mission_data.get("ring_waypoints", [])
	total_rings = waypoints.size()

	for i in range(total_rings):
		var ring = CheckpointRingScript.new()
		ring.position = waypoints[i]
		ring.ring_index = i
		ring.is_final_ring = (i == total_rings - 1)
		ring.ring_passed.connect(_on_ring_passed)
		rings_container.add_child(ring)

func _update_initial_objective() -> void:
	var m_type = current_mission_data.get("type", FlightConst.MissionType.FREE_FLIGHT)
	match m_type:
		FlightConst.MissionType.FREE_FLIGHT:
			current_objective_text = "Explore the open skies. Perform touch-and-gos and aerobatics."
		FlightConst.MissionType.TAKEOFF_LANDING:
			current_objective_text = "Advance throttle to 100%. Rotate at 150 km/h and climb to 600m."
		FlightConst.MissionType.URBAN_LOW_ALTITUDE:
			current_objective_text = "Maintain altitude below 100m through downtown skyscraper avenues."
		FlightConst.MissionType.CHECKPOINT_AIR_RACE:
			current_objective_text = "Navigate through Aerial Ring 1 / %d." % total_rings
		FlightConst.MissionType.DEADSTICK_DESCENT:
			current_objective_text = "ENGINES OUT! Glide smoothly toward mountain plateau runway."
		FlightConst.MissionType.MOUNTAIN_SLALOM:
			current_objective_text = "Carve through alpine ridge checkpoints."
		FlightConst.MissionType.LANDMARK_RECON:
			current_objective_text = "Fly within 250m of Municipal Landmarks to capture reconnaissance photos (0/4)."
		FlightConst.MissionType.ROTORCRAFT_SAR:
			current_objective_text = "Locate emergency beacon in harbor basin and hover to hoist survivor."

	objective_updated.emit(current_objective_text)

func update_mission(delta: float, aircraft: CharacterBody3D) -> void:
	if not is_mission_active or not is_instance_valid(aircraft) or delta <= 0.0:
		return

	elapsed_time_s += delta

	# Check time limits
	var limit = current_mission_data.get("time_limit_s", 0.0)
	if limit > 0.0 and elapsed_time_s > limit:
		fail_mission("Time limit expired!")
		return

	var m_type = current_mission_data.get("type", FlightConst.MissionType.FREE_FLIGHT)
	match m_type:
		FlightConst.MissionType.TAKEOFF_LANDING:
			_update_takeoff_landing_logic(aircraft)
		FlightConst.MissionType.URBAN_LOW_ALTITUDE:
			_update_urban_corridor_logic(delta, aircraft)
		FlightConst.MissionType.DEADSTICK_DESCENT:
			_update_deadstick_logic(aircraft)
		FlightConst.MissionType.LANDMARK_RECON:
			_update_landmark_recon_logic(aircraft)
		FlightConst.MissionType.ROTORCRAFT_SAR:
			_update_sar_logic(delta, aircraft)

func _update_takeoff_landing_logic(aircraft: CharacterBody3D) -> void:
	if not has_taken_off:
		if aircraft.is_airborne and aircraft.barometric_altitude_m > 30.0:
			has_taken_off = true
			current_objective_text = "Climb to 600m pattern altitude and gear up."
			objective_updated.emit(current_objective_text)
	elif not has_climbed_target_alt:
		if aircraft.barometric_altitude_m >= 580.0:
			has_climbed_target_alt = true
			current_objective_text = "Pattern altitude reached! Turn final and land on Runway 09L (< 2.8 m/s VSI)."
			objective_updated.emit(current_objective_text)
	else:
		# Approach & Landing
		if not aircraft.is_airborne and aircraft.indicated_airspeed_kmh < 40.0:
			var vsi_touchdown = absf(aircraft.vertical_speed_ms)
			if vsi_touchdown <= current_mission_data.get("max_touchdown_vsi", 2.8):
				score = 5000 - int(vsi_touchdown * 600.0)
				complete_mission()
			else:
				fail_mission("Hard landing! Touchdown vertical speed was too high (%.1f m/s)." % vsi_touchdown)

func _update_urban_corridor_logic(delta: float, aircraft: CharacterBody3D) -> void:
	var alt = aircraft.barometric_altitude_m
	var max_alt = current_mission_data.get("max_allowed_alt_m", 120.0)

	if alt > max_alt:
		current_objective_text = "WARNING: CEILING EXCEEDED! Descend below 100m AGL!"
		objective_updated.emit(current_objective_text)
	else:
		urban_skimming_seconds += delta
		score = int(urban_skimming_seconds * 120.0)
		current_objective_text = "Urban Skimming: %.1fs / 45s (Alt: %.0fm)" % [urban_skimming_seconds, alt]
		objective_updated.emit(current_objective_text)

		if urban_skimming_seconds >= 45.0:
			complete_mission()

func _update_deadstick_logic(aircraft: CharacterBody3D) -> void:
	# Ensure engines remain cut
	aircraft.throttle = 0.0
	if not aircraft.is_airborne and aircraft.indicated_airspeed_kmh < 50.0:
		score = 5500 - int(elapsed_time_s * 15.0)
		complete_mission()

func _update_landmark_recon_logic(aircraft: CharacterBody3D) -> void:
	var targets = current_mission_data.get("recon_targets", [])
	for target in targets:
		if not target.get("captured", false):
			var dist = aircraft.global_position.distance_to(target.get("pos", Vector3.ZERO))
			if dist < 280.0:
				target["captured"] = true
				landmarks_captured += 1
				score += 1000
				current_objective_text = "PHOTO CAPTURED: %s! (%d/4 Complete)" % [target.get("name", ""), landmarks_captured]
				objective_updated.emit(current_objective_text)

	if landmarks_captured >= 4:
		complete_mission()

func _update_sar_logic(delta: float, aircraft: CharacterBody3D) -> void:
	if not survivor_hoisted:
		var beacon = current_mission_data.get("beacon_pos", Vector3.ZERO)
		var dist = aircraft.global_position.distance_to(beacon)
		var spd = aircraft.indicated_airspeed_kmh

		if dist < 45.0 and spd < 35.0:
			hover_timer_s += delta
			current_objective_text = "HOISTING SURVIVOR: %.1fs / 4.0s (Hold Hover)" % hover_timer_s
			objective_updated.emit(current_objective_text)
			if hover_timer_s >= 4.0:
				survivor_hoisted = true
				current_objective_text = "SURVIVOR ON BOARD! Fly to hospital rooftop helipad and land safely."
				objective_updated.emit(current_objective_text)
		else:
			hover_timer_s = maxf(0.0, hover_timer_s - delta)
	else:
		var helipad = current_mission_data.get("helipad_pos", Vector3.ZERO)
		var dist = aircraft.global_position.distance_to(helipad)
		if dist < 30.0 and not aircraft.is_airborne and aircraft.indicated_airspeed_kmh < 15.0:
			score = 5000 - int(elapsed_time_s * 10.0)
			complete_mission()

func _on_ring_passed(idx: int, orientation_matched: bool, roll_deg: float) -> void:
	if idx == current_ring_index:
		current_ring_index += 1
		score += 500 if orientation_matched else 250

		if current_ring_index >= total_rings:
			complete_mission()
		else:
			current_objective_text = "Navigate through Aerial Ring %d / %d." % [current_ring_index + 1, total_rings]
			objective_updated.emit(current_objective_text)

func complete_mission() -> void:
	if not is_mission_active:
		return
	is_mission_active = false

	var medal = _calculate_medal()
	var summary = {
		"mission_id": active_mission_id,
		"title": current_mission_data.get("title", "Mission"),
		"success": true,
		"time_s": elapsed_time_s,
		"score": score,
		"medal": medal
	}

	_save_progression(summary)
	mission_completed.emit(summary)

func fail_mission(reason: String) -> void:
	if not is_mission_active:
		return
	is_mission_active = false
	mission_failed.emit(reason)

func _calculate_medal() -> String:
	var m_type = current_mission_data.get("type", FlightConst.MissionType.FREE_FLIGHT)
	if m_type == FlightConst.MissionType.CHECKPOINT_AIR_RACE or m_type == FlightConst.MissionType.MOUNTAIN_SLALOM:
		var gold_t = current_mission_data.get("gold_time_s", 60.0)
		var silv_t = current_mission_data.get("silver_time_s", 80.0)
		if elapsed_time_s <= gold_t: return "Gold"
		if elapsed_time_s <= silv_t: return "Silver"
		return "Bronze"
	else:
		var gold_s = current_mission_data.get("gold_score", 4000)
		var silv_s = current_mission_data.get("silver_score", 2500)
		if score >= gold_s: return "Gold"
		if score >= silv_s: return "Silver"
		return "Bronze"

func _save_progression(summary: Dictionary) -> void:
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if not sm:
		return

	if not sm.save_data.has("statistics"):
		sm.save_data["statistics"] = {}
	if not sm.save_data["statistics"].has("aircraft_flight"):
		sm.save_data["statistics"]["aircraft_flight"] = {
			"missions_completed": 0,
			"flight_hours": 0.0,
			"best_medals": {},
			"best_scores": {}
		}

	var stats = sm.save_data["statistics"]["aircraft_flight"]
	stats["missions_completed"] = stats.get("missions_completed", 0) + 1
	stats["flight_hours"] = stats.get("flight_hours", 0.0) + (elapsed_time_s / 3600.0)
	stats["best_scores"][active_mission_id] = maxi(stats.get("best_scores", {}).get(active_mission_id, 0), score)
	stats["best_medals"][active_mission_id] = summary.get("medal", "Bronze")

	sm.save_game()
