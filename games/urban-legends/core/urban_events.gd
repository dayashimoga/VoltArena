class_name UrbanEvents
extends RefCounted

## Event signaling and decoupled communication bus for Urban Legends.
## Emits notifications for vehicle state, stunt awards, district transitions,
## traffic events, and mission milestones.

signal vehicle_speed_updated(speed_kmh: float, gear: int, rpm_normalized: float)
signal vehicle_damaged(new_health: float, max_health: float, damage_amount: float)
signal vehicle_repaired(new_health: float)
signal vehicle_recovered(safe_position: Vector3)
signal vehicle_boost_changed(current_boost: float, max_boost: float)

signal stunt_performed(stunt_id: int, label: String, cash_reward: int, points: int)
signal drift_started()
signal drift_updated(drift_angle_deg: float, drift_points: int)
signal drift_ended(total_points: int, cash_bonus: int)

signal district_entered(district_id: String, district_name: String, description: String)
signal mission_started(mission_id: String, mission_title: String, time_limit_sec: float)
signal mission_checkpoint_reached(checkpoint_index: int, total_checkpoints: int)
signal mission_completed(mission_id: String, rank: String, cash_reward: int, completion_time: float)
signal mission_failed(mission_id: String, reason: String)

signal cash_balance_changed(new_balance: int, delta: int)
signal vehicle_unlocked(vehicle_id: String)
signal upgrade_purchased(vehicle_id: String, upgrade_type: String, new_level: int)
signal weather_changed(weather_state: int, weather_name: String)
