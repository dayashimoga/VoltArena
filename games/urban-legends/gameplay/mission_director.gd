class_name UrbanMissionDirector
extends Node3D

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanVehicle = preload("res://games/urban-legends/vehicles/urban_vehicle.gd")
const UrbanSaveData = preload("res://games/urban-legends/core/urban_save_data.gd")
const StuntDetector = preload("res://games/urban-legends/gameplay/stunt_detector.gd")

## Mission director and objective coordinator for Urban Legends.
## Governs 6 complete replayable mission archetypes:
## 1. Circuit Race ("Downtown Grand Prix"): 3 laps through downtown boulevards
## 2. Drift Trial ("Glen Park Slipstream"): Target 4,500 drift points in parkland
## 3. Hill Climb ("Colinas Ridge Ascent"): Winding switchback sprint against the clock
## 4. Courier Delivery ("Apex Express"): Multi-district rapid parcel drops
## 5. Stunt Leap ("Crest Aviator"): Colinas crest ramp ballistic launch >= 65m
## 6. District Explorer ("Urban Cartographer"): Visit iconic landmarks across all 8 zones

signal mission_started(mission_id: String, mission_title: String)
signal checkpoint_reached(index: int, total: int)
signal mission_completed(mission_id: String, reward_cash: int, completion_time: float)
signal mission_failed(mission_id: String, reason: String)

var active_mission_id: String = ""
var is_mission_active: bool = false
var mission_timer: float = 0.0
var time_limit: float = 0.0

var checkpoints: Array[Vector3] = []
var current_checkpoint_idx: int = 0
var current_lap: int = 1
var total_laps: int = 1

var target_score: float = 0.0
var accumulated_score: float = 0.0
var reward_cash: int = 0

var player_vehicle: UrbanVehicle = null
var save_data: UrbanSaveData = null

static func get_all_mission_ids() -> Array[String]:
	return [
		UrbanConstants.MISSION_CIRCUIT_RACE,
		UrbanConstants.MISSION_DRIFT_TRIAL,
		UrbanConstants.MISSION_HILL_CLIMB,
		UrbanConstants.MISSION_COURIER,
		UrbanConstants.MISSION_STUNT_LEAP,
		UrbanConstants.MISSION_EXPLORER
	]

func setup(player: UrbanVehicle, save: UrbanSaveData = null) -> void:
	player_vehicle = player
	save_data = save

func start_mission(mission_id: String) -> bool:
	if is_mission_active:
		abort_mission("New mission started")

	active_mission_id = mission_id
	is_mission_active = true
	mission_timer = 0.0
	current_checkpoint_idx = 0
	accumulated_score = 0.0

	match mission_id:
		UrbanConstants.MISSION_CIRCUIT_RACE:
			time_limit = 150.0
			total_laps = 3
			current_lap = 1
			reward_cash = 2500
			checkpoints = [
				Vector3(-100, 1.0, -350),
				Vector3(100, 1.0, -450),
				Vector3(100, 1.0, 100),
				Vector3(-450, 1.0, 100),
				Vector3(-450, 1.0, -450)
			]
			mission_started.emit(mission_id, "Downtown Grand Prix")

		UrbanConstants.MISSION_DRIFT_TRIAL:
			time_limit = 90.0
			total_laps = 1
			target_score = 4500.0
			reward_cash = 3000
			checkpoints = [
				Vector3(280, 8.0, -380),
				Vector3(380, 11.0, -220),
				Vector3(480, 15.0, 80)
			]
			mission_started.emit(mission_id, "Glen Park Slipstream")

		UrbanConstants.MISSION_HILL_CLIMB:
			time_limit = 75.0
			total_laps = 1
			reward_cash = 2800
			checkpoints = [
				Vector3(100, 1.0, 100),
				Vector3(220, 18.0, 250),
				Vector3(320, 35.0, 380),
				Vector3(450, 52.0, 620),
				Vector3(700, 92.0, 850)
			]
			mission_started.emit(mission_id, "Colinas Ridge Ascent")

		UrbanConstants.MISSION_COURIER:
			time_limit = 110.0
			total_laps = 1
			reward_cash = 3200
			checkpoints = [
				Vector3(-100, 1.0, -100), # Downtown
				Vector3(350, 18.0, 20),   # Harborfly
				Vector3(450, 14.0, -280), # Verdant Glen
				Vector3(0, 1.0, -850)     # Bayview
			]
			mission_started.emit(mission_id, "Apex Express Courier")

		UrbanConstants.MISSION_STUNT_LEAP:
			time_limit = 60.0
			total_laps = 1
			target_score = 65.0 # 65 meters air distance
			reward_cash = 3500
			checkpoints = [
				Vector3(350, 36.0, 480), # Approach run
				Vector3(450, 52.0, 620)  # Crest ramp launch
			]
			mission_started.emit(mission_id, "Crest Aviator Leap")

		UrbanConstants.MISSION_EXPLORER:
			time_limit = 180.0
			total_laps = 1
			reward_cash = 4000
			checkpoints = [
				Vector3(-100, 1.0, -100), # Downtown
				Vector3(450, 52.0, 620),  # Colinas
				Vector3(400, 10.0, -300), # Glen
				Vector3(0, 18.0, 20),     # Freeway
				Vector3(0, 1.0, -850),    # Bayview
				Vector3(-750, 1.0, 500),  # Industrial
				Vector3(180, 110.0, 850), # Ridgecrest
				Vector3(-750, 1.0, -520)  # Airport
			]
			mission_started.emit(mission_id, "Urban Cartographer")

		_:
			is_mission_active = false
			return false

	return true

func _physics_process(delta: float) -> void:
	if not is_mission_active:
		return

	mission_timer += delta

	# Check time expiration
	if time_limit > 0.0 and mission_timer > time_limit:
		fail_mission("Time expired!")
		return

	# Check vehicle health
	if is_instance_valid(player_vehicle) and player_vehicle.is_wrecked:
		fail_mission("Vehicle totaled!")
		return

	# Check checkpoint proximity
	if is_instance_valid(player_vehicle) and not checkpoints.is_empty():
		var p_pos = player_vehicle.global_position if player_vehicle.is_inside_tree() else player_vehicle.position
		var target_cp = checkpoints[current_checkpoint_idx]
		if p_pos.distance_to(target_cp) < 18.0:
			current_checkpoint_idx += 1
			checkpoint_reached.emit(current_checkpoint_idx, checkpoints.size())

			if current_checkpoint_idx >= checkpoints.size():
				if active_mission_id == UrbanConstants.MISSION_CIRCUIT_RACE and current_lap < total_laps:
					current_lap += 1
					current_checkpoint_idx = 0
				else:
					complete_mission()

func add_drift_points(points: float) -> void:
	if not is_mission_active:
		return
	accumulated_score += points
	if active_mission_id == UrbanConstants.MISSION_DRIFT_TRIAL:
		if accumulated_score >= target_score:
			complete_mission()

func report_jump_distance(dist_meters: float) -> void:
	if not is_mission_active:
		return
	if active_mission_id == UrbanConstants.MISSION_STUNT_LEAP:
		accumulated_score = maxf(accumulated_score, dist_meters)
		if accumulated_score >= target_score:
			complete_mission()

func complete_mission() -> void:
	if not is_mission_active:
		return
	is_mission_active = false
	var finished_id = active_mission_id
	var final_time = mission_timer

	if save_data:
		save_data.add_cash(reward_cash)

	mission_completed.emit(finished_id, reward_cash, final_time)

func fail_mission(reason: String) -> void:
	if not is_mission_active:
		return
	is_mission_active = false
	var failed_id = active_mission_id
	mission_failed.emit(failed_id, reason)

func abort_mission(reason: String = "Aborted by player") -> void:
	if is_mission_active:
		fail_mission(reason)

func get_current_objective_pos() -> Vector3:
	if is_mission_active and current_checkpoint_idx < checkpoints.size():
		return checkpoints[current_checkpoint_idx]
	return Vector3.ZERO
