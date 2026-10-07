class_name AeroComboSystem
extends RefCounted

## Combo manager and score aggregator for AeroRush: Impossible Circuit.
## Chains stunt actions into escalating multipliers, banks verified scores,
## and penalizes crashes without frustrating false drops.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

signal combo_updated(multiplier: int, pending_score: int, timer_ratio: float, stunt_label: String)
signal combo_banked(banked_amount: int, final_total_score: int)
signal combo_dropped()

var current_multiplier: int = 1
var pending_combo_score: int = 0
var total_banked_score: int = 0
var combo_timer: float = 0.0
var max_combo_timer: float = AeroConstants.COMBO_TIMEOUT_SECONDS
var is_combo_active: bool = false
var stunts_in_current_combo: int = 0

func update(delta: float) -> void:
	if is_combo_active:
		combo_timer -= delta
		var ratio = clampf(combo_timer / max_combo_timer, 0.0, 1.0)
		combo_updated.emit(current_multiplier, pending_combo_score, ratio, "")

		if combo_timer <= 0.0:
			_bank_combo()

func add_stunt(stunt_id: int, base_points: int, label: String) -> void:
	if not is_combo_active:
		is_combo_active = true
		current_multiplier = 1
		pending_combo_score = 0
		stunts_in_current_combo = 0

	stunts_in_current_combo += 1
	# Multiplier escalates every 2 stunts up to MAX_COMBO_MULTIPLIER
	current_multiplier = mini(1 + (stunts_in_current_combo / 2), AeroConstants.MAX_COMBO_MULTIPLIER)

	# Add scaled points
	pending_combo_score += base_points * current_multiplier
	combo_timer = max_combo_timer

	combo_updated.emit(current_multiplier, pending_combo_score, 1.0, label)

func _bank_combo() -> void:
	if pending_combo_score > 0:
		total_banked_score += pending_combo_score
		combo_banked.emit(pending_combo_score, total_banked_score)
	_reset_combo_state()

func on_vehicle_crash() -> void:
	if is_combo_active:
		_reset_combo_state()
		combo_dropped.emit()

func _reset_combo_state() -> void:
	is_combo_active = false
	current_multiplier = 1
	pending_combo_score = 0
	combo_timer = 0.0
	stunts_in_current_combo = 0

func get_total_score() -> int:
	return total_banked_score + pending_combo_score

func reset() -> void:
	total_banked_score = 0
	_reset_combo_state()
