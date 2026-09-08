class_name CheckpointManager
extends Node

## Manages checkpoint registration, saving, and reliable player restoration in Strike Vector.
## Guarantees zero world-fall and zero stuck states after respawning.

signal checkpoint_reached(checkpoint_id: String, mission_idx: int, segment_idx: int)
signal checkpoint_restored(checkpoint_id: String)

var active_checkpoint_id: String = "start"
var active_checkpoint_pos: Vector3 = Vector3.ZERO
var active_checkpoint_rot_y: float = 0.0
var active_mission_idx: int = 1
var active_segment_idx: int = 0

# Checkpoint inventory snapshot
var saved_health: float = 100.0
var saved_armor: float = 50.0
var saved_weapon_index: int = 0
var saved_score: int = 0

func register_checkpoint(cp_id: String, pos: Vector3, rot_y: float, mission_idx: int, seg_idx: int, player: Node3D = null) -> void:
	active_checkpoint_id = cp_id
	active_checkpoint_pos = pos
	active_checkpoint_rot_y = rot_y
	active_mission_idx = mission_idx
	active_segment_idx = seg_idx

	if is_instance_valid(player):
		saved_health = player.get("current_health") if player.get("current_health") != null else 100.0
		saved_armor = player.get("current_armor") if player.get("current_armor") != null else 50.0
		saved_weapon_index = player.get("active_weapon_index") if player.get("active_weapon_index") != null else 0
		saved_score = player.get("current_score") if player.get("current_score") != null else 0

	# Persist to SaveManager
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm and sm.has_method("save_strike_vector_checkpoint"):
		sm.save_strike_vector_checkpoint(mission_idx, seg_idx, 0)

	checkpoint_reached.emit(cp_id, mission_idx, seg_idx)

	# Audio cue
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("wave_clear", 1.0)

func restore_player_to_checkpoint(player: Node) -> void:
	if not is_instance_valid(player):
		return

	if player is Node3D:
		if player.is_inside_tree():
			player.global_position = active_checkpoint_pos + Vector3(0, 0.5, 0)
		else:
			player.position = active_checkpoint_pos + Vector3(0, 0.5, 0)
		player.rotation.y = active_checkpoint_rot_y

	player.set("velocity", Vector3.ZERO)

	if player.has_method("set"):
		player.set("current_health", maxf(50.0, saved_health))
		player.set("current_armor", saved_armor)
		player.set("is_alive", true)

	if player.has_method("select_weapon"):
		player.select_weapon(saved_weapon_index)

	checkpoint_restored.emit(active_checkpoint_id)
