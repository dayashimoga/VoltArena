extends Node

# General Lifecycle
signal game_state_changed(old_state: int, new_state: int)
signal game_selected(game_id: String)
signal game_loaded(game_id: String)
signal return_to_launcher_requested()
signal game_restart_requested()

# Match / Gameplay Progress
signal match_started()
signal match_paused(is_paused: bool)
signal match_ended(results_data: Dictionary)
signal score_updated(team_or_player: int, new_score: int)
signal round_timer_updated(time_left_seconds: float)

# Player & Combat Events
signal player_spawned(player_node: Node)
signal player_health_changed(current_hp: float, max_hp: float)
signal player_armor_changed(current_armor: float, max_armor: float)
signal player_ammo_changed(current_ammo: int, max_ammo: int, reserve_ammo: int)
signal player_weapon_switched(weapon_name: String, weapon_icon: String)
signal player_died(killer_name: String)
signal enemy_died(enemy_type: String, score_value: int)
signal pickup_collected(pickup_type: String, amount: int)

# Wave / Survival Events
signal wave_started(wave_number: int, enemy_count: int)
signal wave_completed(wave_number: int, bonus_score: int)

# Vehicle & Sports Events
signal ball_hit(by_entity: Node, impulse: Vector3)
signal goal_scored(team_id: int, scorer_name: String)
signal boost_amount_changed(current_boost: float, max_boost: float)

# Racing Events
signal race_countdown(seconds: int)
signal checkpoint_passed(racer_id: int, checkpoint_index: int)
signal lap_completed(racer_id: int, lap_number: int, lap_time: float)
signal race_position_updated(racer_id: int, position: int, total_racers: int)
signal powerup_acquired(powerup_id: String)

# Settings & Audio
signal settings_updated()
signal play_sound_requested(sound_name: String, position: Vector3, pitch_variation: float)
signal show_toast_requested(message: String, color: Color)
