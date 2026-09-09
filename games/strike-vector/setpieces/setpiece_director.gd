class_name SetPieceDirector
extends Node3D

## Interactive set-piece framework for Strike Vector.
## Preserves active player input and gameplay during cinematic level events:
## collapsing bridges, moving train roof hazards, container drops, convoy chases, and factory explosions.

signal setpiece_started(setpiece_id: String)
signal setpiece_completed(setpiece_id: String)

@export var setpiece_id: String = "setpiece_event"
@export var duration_sec: float = 8.0
@export var camera_shake_amount: float = 0.8
@export var interactive_hazards: Array = []

var is_active: bool = false
var is_completed: bool = false
var timer: float = 0.0

func trigger_setpiece() -> void:
	if is_active or is_completed:
		return
	is_active = true
	timer = 0.0
	setpiece_started.emit(setpiece_id)

	# Trigger camera shake if camera director exists
	var cam_dir = get_tree().root.find_child("CameraDirector", true, false) if get_tree() else null
	if cam_dir and cam_dir.has_method("add_shake"):
		cam_dir.add_shake(camera_shake_amount)

	# Audio explosion / rumble
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("explosion", 1.0)

func _process(delta: float) -> void:
	if not is_active:
		return

	timer += delta
	_update_hazards(delta)

	if timer >= duration_sec:
		complete_setpiece()

func _update_hazards(delta: float) -> void:
	# Animate active hazards (e.g. falling debris or collapsing platforms)
	for hazard in interactive_hazards:
		if is_instance_valid(hazard):
			if hazard.has_meta("collapse_speed"):
				var spd = hazard.get_meta("collapse_speed")
				hazard.position.y -= spd * delta
			elif hazard.has_meta("rotate_speed"):
				var r_spd = hazard.get_meta("rotate_speed")
				hazard.rotate_y(r_spd * delta)

func complete_setpiece() -> void:
	if is_completed:
		return
	is_active = false
	is_completed = true
	setpiece_completed.emit(setpiece_id)
