class_name StuntDetector
extends RefCounted

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanVehicle = preload("res://games/urban-legends/vehicles/urban_vehicle.gd")
const UrbanSaveData = preload("res://games/urban-legends/core/urban_save_data.gd")

## Real-time stunt, combo, and ballistic trajectory detector for Urban Legends.
## Detects and scores:
## - Air Time & Ballistic Distance (Meters cleared over roads and chasms)
## - Rotational Tricks: Barrel Rolls, Flips, Flat Spins
## - Massive Jumps ("INSANE STUNT BONUS" - Reference screenshot 5)
## - Continuous High-Speed Drifts & Power Slide Multipliers
## - Landing Quality: Perfect, Good, Hard (penalizes or rewards score)
## - Traffic Near-Misses (Passing at >80 km/h within 3.5m)

signal stunt_rewarded(stunt_title: String, cash_reward: int, details: Dictionary)
signal drift_combo_updated(current_score: float, current_multiplier: float)

var vehicle: UrbanVehicle = null
var save_data: UrbanSaveData = null

# Active Stunt Tracking
var is_tracking_jump: bool = false
var jump_start_pos: Vector3 = Vector3.ZERO
var jump_air_time: float = 0.0

# Active Drift Tracking
var current_drift_score: float = 0.0
var drift_combo_timer: float = 0.0
var drift_multiplier: float = 1.0

# Lifetime Stats
var total_stunts_completed: int = 0
var highest_single_stunt_reward: int = 0

func setup(tracked_vehicle: UrbanVehicle, user_save: UrbanSaveData = null) -> void:
	vehicle = tracked_vehicle
	save_data = user_save

	if vehicle:
		vehicle.stunt_airborne_started.connect(_on_airborne_started)
		vehicle.stunt_landed.connect(_on_stunt_landed)

func process_stunt_frame(delta: float) -> void:
	if not is_instance_valid(vehicle):
		return

	# Drift scoring during active ground contact
	if vehicle.is_drifting and vehicle.forward_speed > 6.0:
		var angle = vehicle.get_drift_angle()
		var spd = vehicle.get_speed_kmh()
		var rate = (angle / 45.0) * (spd / 50.0) * 120.0
		current_drift_score += rate * delta
		drift_combo_timer = 1.8 # Window to chain drifts
		drift_multiplier = minf(4.0, drift_multiplier + delta * 0.4)
		drift_combo_updated.emit(current_drift_score, drift_multiplier)
	elif drift_combo_timer > 0.0:
		drift_combo_timer -= delta
		if drift_combo_timer <= 0.0 and current_drift_score > 50.0:
			_bank_drift_combo()

func _on_airborne_started() -> void:
	is_tracking_jump = true
	jump_air_time = 0.0
	jump_start_pos = vehicle.global_position if vehicle.is_inside_tree() else vehicle.position

func _on_stunt_landed(landing_rating: String, vertical_speed: float, air_time: float) -> void:
	if not is_tracking_jump:
		return
	is_tracking_jump = false

	var land_pos = vehicle.global_position if vehicle.is_inside_tree() else vehicle.position
	var distance_cleared = jump_start_pos.distance_to(land_pos)
	var pitch_deg = vehicle.total_air_pitch_deg
	var yaw_deg = vehicle.total_air_yaw_deg
	var roll_deg = vehicle.total_air_roll_deg

	# Detect tricks completed
	var flips = int(pitch_deg / 300.0)
	var spins = int(yaw_deg / 300.0)
	var rolls = int(roll_deg / 300.0)

	# Evaluate stunt title & cash reward
	var stunt_title = ""
	var reward_cash = 0

	if distance_cleared >= 25.0 or air_time >= 0.9 or flips > 0 or spins > 0 or rolls > 0:
		var trick_parts: Array[String] = []

		if flips >= 2:
			trick_parts.append("DOUBLE FLIP")
			reward_cash += 150
		elif flips == 1:
			trick_parts.append("FLIP")
			reward_cash += 75

		if rolls >= 2:
			trick_parts.append("DOUBLE BARREL ROLL")
			reward_cash += 180
		elif rolls == 1:
			trick_parts.append("BARREL ROLL")
			reward_cash += 85

		if spins >= 2:
			trick_parts.append("720° FLAT SPIN")
			reward_cash += 160
		elif spins == 1:
			trick_parts.append("360° SPIN")
			reward_cash += 80

		# Ballistic distance scoring
		if distance_cleared >= 75.0:
			trick_parts.append("INSANE STUNT")
			reward_cash += 250
		elif distance_cleared >= 45.0:
			trick_parts.append("MONSTER JUMP")
			reward_cash += 125
		elif distance_cleared >= 25.0:
			trick_parts.append("BIG AIR")
			reward_cash += 60

		# Landing rating multiplier
		if landing_rating == "Hard":
			reward_cash = int(reward_cash * 0.5) # Impact penalty
		elif landing_rating == "Smooth" and reward_cash > 0:
			reward_cash = int(reward_cash * 1.25) # Clean landing bonus

		if trick_parts.is_empty():
			stunt_title = "STUNT JUMP"
			reward_cash = 50
		else:
			stunt_title = " + ".join(trick_parts)

		var details = {
			"distance": distance_cleared,
			"air_time": air_time,
			"rating": landing_rating,
			"vertical_speed": vertical_speed,
			"flips": flips,
			"spins": spins,
			"rolls": rolls
		}

		_award_stunt(stunt_title, reward_cash, details)

func _bank_drift_combo() -> void:
	var total_bank = int(current_drift_score * drift_multiplier * 0.15)
	if total_bank > 20:
		var title = "DRIFT COMBO x%.1f" % drift_multiplier
		_award_stunt(title, total_bank, {
			"score": current_drift_score,
			"multiplier": drift_multiplier
		})
	current_drift_score = 0.0
	drift_multiplier = 1.0

func _award_stunt(title: String, cash: int, details: Dictionary) -> void:
	total_stunts_completed += 1
	if cash > highest_single_stunt_reward:
		highest_single_stunt_reward = cash

	if save_data:
		save_data.add_cash(cash)

	stunt_rewarded.emit(title, cash, details)

func report_near_miss(other_speed_kmh: float) -> void:
	var bonus = int(other_speed_kmh * 0.75)
	if bonus > 20:
		_award_stunt("NEAR MISS BONUS", bonus, {"speed": other_speed_kmh})
