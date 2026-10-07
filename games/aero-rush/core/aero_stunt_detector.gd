class_name AeroStuntDetector
extends RefCounted

## Analyzes and verifies stunt maneuvers, enforcing anti-exploit rules,
## speed thresholds, and repetition decay to prevent stationary score farming.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

signal stunt_verified(stunt_id: int, base_points: int, label: String)

var vehicle: CharacterBody3D = null
var recent_stunts: Array[Dictionary] = [] # {"id": int, "timestamp": float}
var near_miss_cooldown: float = 0.0

func setup(p_vehicle: CharacterBody3D) -> void:
	vehicle = p_vehicle
	if vehicle:
		if vehicle.has_signal("stunt_action_triggered"):
			vehicle.stunt_action_triggered.connect(_on_vehicle_stunt)
		if vehicle.has_signal("landing_performed"):
			vehicle.landing_performed.connect(_on_vehicle_landing)

func update(delta: float) -> void:
	if near_miss_cooldown > 0.0:
		near_miss_cooldown -= delta

	# Prune stunts older than 6.0 seconds from repetition history
	var now = Time.get_ticks_msec() / 1000.0
	for i in range(recent_stunts.size() - 1, -1, -1):
		if now - recent_stunts[i]["timestamp"] > 6.0:
			recent_stunts.remove_at(i)

func _on_vehicle_stunt(stunt_id: int, base_points: int, label: String) -> void:
	if not vehicle:
		return

	# 1. Anti-Exploit Speed Gate: Ignore tricks performed below minimum velocity
	var spd = vehicle.get("forward_speed")
	if spd != null and absf(float(spd)) < AeroConstants.MIN_STUNT_SPEED:
		return

	# 2. Diminishing Returns for Repeated Stunts within combo window
	var repeat_count = 0
	for s in recent_stunts:
		if s["id"] == stunt_id:
			repeat_count += 1

	var decay_mult = 1.0
	if repeat_count == 1:
		decay_mult = 0.65
	elif repeat_count == 2:
		decay_mult = 0.40
	elif repeat_count >= 3:
		decay_mult = 0.20

	var final_points = int(float(base_points) * decay_mult)
	if final_points > 0:
		recent_stunts.append({
			"id": stunt_id,
			"timestamp": Time.get_ticks_msec() / 1000.0
		})
		stunt_verified.emit(stunt_id, final_points, label)

func _on_vehicle_landing(quality: String, angle_deg: float, bonus: int) -> void:
	if quality == "perfect":
		stunt_verified.emit(AeroConstants.StuntType.PERFECT_LANDING, 500, "PERFECT LANDING")
	elif quality == "clean" and bonus > 0:
		stunt_verified.emit(AeroConstants.StuntType.AIRTIME, bonus, "CLEAN LANDING")

func trigger_near_miss(distance: float) -> void:
	if near_miss_cooldown <= 0.0:
		near_miss_cooldown = 1.2
		var pts = 250 if distance < 1.8 else 150
		stunt_verified.emit(AeroConstants.StuntType.NEAR_MISS, pts, "NEAR MISS")

func clear() -> void:
	recent_stunts.clear()
	near_miss_cooldown = 0.0
