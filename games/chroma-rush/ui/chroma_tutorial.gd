class_name ChromaTutorial
extends RefCounted

## Interactive 6-step guided tutorial manager for Chroma Rush: The Color Chase
## Teaches driving, color symbols, radar tracking, side-by-side alignment, atomic swaps, and checkpoint delivery.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const ColorSwapEngine = preload("res://games/chroma-rush/core/color_swap_engine.gd")
const ChromaSaveAdapter = preload("res://games/chroma-rush/persistence/chroma_save_adapter.gd")

signal step_changed(step_index: int, instruction_title: String, instruction_body: String)
signal tutorial_completed()

enum TutorialStep {
	DRIVING_BASICS = 0,
	COLOR_IDENTIFICATION = 1,
	TARGET_PURSUIT = 2,
	SIDE_ALIGNMENT = 3,
	ATOMIC_SWAP = 4,
	CHECKPOINT_DELIVERY = 5,
	COMPLETED = 6
}

var current_step: TutorialStep = TutorialStep.DRIVING_BASICS
var player_vehicle: ChromaVehicle
var swap_engine: ColorSwapEngine
var step_progress: float = 0.0

const STEP_DATA = {
	TutorialStep.DRIVING_BASICS: {
		"title": "STEP 1: ARCADE HANDLING",
		"desc": "Drive forward using [W / UP] and steer with [A/D / LEFT/RIGHT]. Reach 40 km/h to continue."
	},
	TutorialStep.COLOR_IDENTIFICATION: {
		"title": "STEP 2: COLOR & SYMBOLS",
		"desc": "Your vehicle is equipped with Crimson Red (◆ Diamond). Notice the matching glowing panels and roof symbol."
	},
	TutorialStep.TARGET_PURSUIT: {
		"title": "STEP 3: TARGET PURSUIT",
		"desc": "A target vehicle carrying Cobalt Blue (⬡ Hexagon) is ahead. Close the distance to within 8 meters."
	},
	TutorialStep.SIDE_ALIGNMENT: {
		"title": "STEP 4: PARALLEL ALIGNMENT",
		"desc": "Pull alongside the target vehicle, match its forward speed, and hold parallel alignment for 0.5s."
	},
	TutorialStep.ATOMIC_SWAP: {
		"title": "STEP 5: EXECUTE ATOMIC SWAP",
		"desc": "When the reticle locks green, press [SPACE / TAP SWAP] to atomically exchange colors!"
	},
	TutorialStep.CHECKPOINT_DELIVERY: {
		"title": "STEP 6: CHECKPOINT DELIVERY",
		"desc": "Deliver your newly acquired Cobalt Blue (⬡ Hexagon) through the glowing Checkpoint Gate ahead."
	}
}

func _init(p_vehicle: ChromaVehicle = null, p_engine: ColorSwapEngine = null) -> void:
	player_vehicle = p_vehicle
	swap_engine = p_engine

	if swap_engine:
		swap_engine.swap_committed.connect(_on_swap_committed)

func start_tutorial() -> void:
	current_step = TutorialStep.DRIVING_BASICS
	step_progress = 0.0
	_emit_current_step()

func update(delta: float) -> void:
	if current_step == TutorialStep.COMPLETED:
		return

	match current_step:
		TutorialStep.DRIVING_BASICS:
			if player_vehicle and player_vehicle.speed_kph > 25.0:
				step_progress += delta
				if step_progress >= 1.0:
					advance_step()

		TutorialStep.COLOR_IDENTIFICATION:
			step_progress += delta
			if step_progress >= 2.5: # 2.5 seconds reading time
				advance_step()

		TutorialStep.TARGET_PURSUIT:
			if swap_engine and player_vehicle:
				var info = swap_engine.find_nearest_eligible_target("player", 12.0)
				if info["target_id"] != "" and info["distance"] <= 8.5:
					advance_step()

		TutorialStep.SIDE_ALIGNMENT:
			if swap_engine and player_vehicle:
				var info = swap_engine.find_nearest_eligible_target("player", 10.0)
				if info["eligible"]:
					advance_step()

		TutorialStep.ATOMIC_SWAP:
			# Waiting for swap event
			pass

		TutorialStep.CHECKPOINT_DELIVERY:
			# Waiting for checkpoint trigger
			pass

func advance_step() -> void:
	step_progress = 0.0
	var next_idx = int(current_step) + 1
	if next_idx >= TutorialStep.COMPLETED:
		current_step = TutorialStep.COMPLETED
		ChromaSaveAdapter.set_tutorial_completed(true)
		tutorial_completed.emit()
	else:
		current_step = next_idx as TutorialStep
		_emit_current_step()

func handle_checkpoint_reached(is_matching: bool) -> void:
	if current_step == TutorialStep.CHECKPOINT_DELIVERY and is_matching:
		advance_step()

func _on_swap_committed(init_id: String, target_id: String, c1: int, c2: int) -> void:
	if current_step == TutorialStep.ATOMIC_SWAP:
		if init_id == "player" or target_id == "player":
			advance_step()

func _emit_current_step() -> void:
	if STEP_DATA.has(current_step):
		var data = STEP_DATA[current_step]
		step_changed.emit(int(current_step), data["title"], data["desc"])

func get_current_step_index() -> int:
	return int(current_step)
