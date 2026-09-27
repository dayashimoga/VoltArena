class_name RivalAI
extends RefCounted

## Competitive AI Rival that pursues color objectives, aligns alongside targets,
## executes authoritative color swaps, and races to matching checkpoints.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const ChromaAIDriver = preload("res://games/chroma-rush/ai/chroma_ai_driver.gd")
const ColorSwapEngine = preload("res://games/chroma-rush/core/color_swap_engine.gd")

enum RivalState {
	SEARCHING_COLOR,
	PURSUING_TARGET,
	ALIGNING_FOR_SWAP,
	DELIVERING_CHECKPOINT,
	RECOVERING
}

var vehicle: ChromaVehicle
var driver: ChromaAIDriver
var swap_engine: ColorSwapEngine
var rival_id: String = ""

# Gameplay Objective State
var current_state: RivalState = RivalState.SEARCHING_COLOR
var required_color: int = ChromaConstants.ChromaColor.CRIMSON
var current_target_id: String = ""
var target_checkpoint_pos: Vector3 = Vector3.ZERO
var checkpoints_delivered: int = 0
var score: int = 0

# Strategy & Difficulty Configuration
var difficulty_level: String = "skilled" # "novice", "skilled", "master"
var search_timer: float = 0.0
var swap_attempt_cooldown: float = 0.0
var alignment_time_spent: float = 0.0

func _init(p_vehicle: ChromaVehicle, p_engine: ColorSwapEngine, p_id: String, p_initial_color: int, p_difficulty: String = "skilled") -> void:
	vehicle = p_vehicle
	swap_engine = p_engine
	rival_id = p_id
	difficulty_level = p_difficulty
	driver = ChromaAIDriver.new(vehicle)

	if swap_engine and vehicle:
		swap_engine.register_vehicle(rival_id, vehicle, p_initial_color, true)

	_configure_difficulty()

func _configure_difficulty() -> void:
	match difficulty_level:
		"master":
			driver.steer_sensitivity = 3.0
			driver.cornering_slowdown_factor = 0.8
		"novice":
			driver.steer_sensitivity = 1.8
			driver.cornering_slowdown_factor = 0.5
		_: # skilled
			driver.steer_sensitivity = 2.4
			driver.cornering_slowdown_factor = 0.65

func set_required_objective(color_id: int, checkpoint_pos: Vector3) -> void:
	required_color = color_id
	target_checkpoint_pos = checkpoint_pos
	_evaluate_objective_state()

func update(delta: float) -> void:
	if not vehicle or not is_instance_valid(vehicle):
		return

	if swap_attempt_cooldown > 0.0:
		swap_attempt_cooldown -= delta

	match current_state:
		RivalState.SEARCHING_COLOR:
			_update_searching(delta)
		RivalState.PURSUING_TARGET:
			_update_pursuing(delta)
		RivalState.ALIGNING_FOR_SWAP:
			_update_aligning(delta)
		RivalState.DELIVERING_CHECKPOINT:
			_update_delivering(delta)
		RivalState.RECOVERING:
			_update_recovering(delta)

	driver.update_driving(delta)

func _evaluate_objective_state() -> void:
	var my_color = get_current_color()
	if my_color == required_color:
		current_state = RivalState.DELIVERING_CHECKPOINT
		driver.set_target(target_checkpoint_pos, vehicle.top_speed)
	else:
		current_state = RivalState.SEARCHING_COLOR

func _update_searching(delta: float) -> void:
	search_timer += delta
	if search_timer >= 0.35:
		search_timer = 0.0
		# Search world for any vehicle carrying required color
		var found_id = swap_engine.find_target_with_color(rival_id, required_color)
		if found_id != "":
			current_target_id = found_id
			current_state = RivalState.PURSUING_TARGET
			alignment_time_spent = 0.0

func _update_pursuing(delta: float) -> void:
	var target_node = swap_engine.get_vehicle_node(current_target_id)
	if not is_instance_valid(target_node):
		current_state = RivalState.SEARCHING_COLOR
		return

	# Re-verify target still holds the color we need
	if swap_engine.get_vehicle_color(current_target_id) != required_color:
		current_state = RivalState.SEARCHING_COLOR
		return

	var dist = vehicle.global_position.distance_to(target_node.global_position)
	if dist <= ChromaConstants.MAX_SWAP_DISTANCE:
		current_state = RivalState.ALIGNING_FOR_SWAP
	else:
		# Drive towards target vehicle with slight offset to side
		var tgt_forward = -target_node.global_transform.basis.z.normalized()
		var tgt_right = target_node.global_transform.basis.x.normalized()
		var intercept_pos = target_node.global_position + tgt_forward * 4.0 + tgt_right * 2.5
		driver.set_target(intercept_pos, vehicle.top_speed)

func _update_aligning(delta: float) -> void:
	var target_node = swap_engine.get_vehicle_node(current_target_id)
	if not is_instance_valid(target_node):
		current_state = RivalState.SEARCHING_COLOR
		return

	var dist = vehicle.global_position.distance_to(target_node.global_position)
	if dist > ChromaConstants.MAX_SWAP_DISTANCE * 1.5:
		# Slipped away, return to pursuit
		current_state = RivalState.PURSUING_TARGET
		return

	# Pull alongside target (2.5 meters to the right or left)
	var tgt_t = target_node.global_transform if target_node.is_inside_tree() else target_node.transform
	var tgt_pos = target_node.global_position if target_node.is_inside_tree() else target_node.position
	var veh_pos = vehicle.global_position if vehicle.is_inside_tree() else vehicle.position
	var tgt_right = tgt_t.basis.x.normalized()
	var side_offset = 2.4 if (tgt_pos - veh_pos).x < 0 else -2.4
	var parallel_pos = tgt_pos + tgt_right * side_offset

	# Match target speed
	var tgt_vel = target_node.velocity if "velocity" in target_node else Vector3.ZERO
	driver.set_target(parallel_pos, tgt_vel.length() + 1.0)

	# Check eligibility for swap
	var eval = swap_engine.evaluate_eligibility(rival_id, current_target_id, true)
	if eval["eligible"] and swap_attempt_cooldown <= 0.0:
		var result = swap_engine.request_swap(rival_id, current_target_id)
		if result["success"]:
			vehicle.set_color(result["initiator_new_color"])
			_evaluate_objective_state()
		else:
			swap_attempt_cooldown = 0.5

func _update_delivering(delta: float) -> void:
	driver.set_target(target_checkpoint_pos, vehicle.top_speed)

	var veh_pos = vehicle.global_position if vehicle.is_inside_tree() else vehicle.position
	var dist = veh_pos.distance_to(target_checkpoint_pos)
	if dist < 8.0:
		# Checkpoint achieved
		checkpoints_delivered += 1
		score += 500

func _update_recovering(delta: float) -> void:
	if vehicle.is_grounded:
		_evaluate_objective_state()

func get_current_color() -> int:
	if swap_engine:
		return swap_engine.get_vehicle_color(rival_id)
	return vehicle.current_color

func cleanup() -> void:
	if swap_engine and rival_id != "":
		swap_engine.unregister_vehicle(rival_id)
