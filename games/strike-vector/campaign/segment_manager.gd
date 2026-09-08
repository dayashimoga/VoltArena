class_name SegmentManager
extends Node3D

## Manages individual mission segments in Strike Vector.
## Implements the strict state machine:
## LOCKED -> PRELOADED -> ENTERED -> ACTIVE -> COMPLETE -> EXITED -> UNLOADED.

signal segment_state_changed(seg_index: int, old_state: SegmentState, new_state: SegmentState)
signal segment_completed(seg_index: int)

enum SegmentState {
	LOCKED,
	PRELOADED,
	ENTERED,
	ACTIVE,
	COMPLETE,
	EXITED,
	UNLOADED
}

@export var segment_index: int = 0
@export var segment_name: String = "Segment"
@export var is_boss_segment: bool = false
@export var is_setpiece_segment: bool = false

var current_state: SegmentState = SegmentState.LOCKED
var encounter_director: Node = null
var checkpoint_pos: Vector3 = Vector3.ZERO
var exit_gate: Node3D = null

func _ready() -> void:
	pass

func set_state(new_state: SegmentState) -> void:
	if current_state == new_state:
		return
	var old = current_state
	current_state = new_state
	segment_state_changed.emit(segment_index, old, new_state)

	match new_state:
		SegmentState.PRELOADED:
			visible = true
			set_process(true)
			set_physics_process(true)
		SegmentState.ENTERED:
			pass
		SegmentState.ACTIVE:
			if is_instance_valid(encounter_director) and not encounter_director.is_completed:
				encounter_director.trigger_encounter()
		SegmentState.COMPLETE:
			segment_completed.emit(segment_index)
		SegmentState.EXITED:
			pass
		SegmentState.UNLOADED:
			visible = false
			set_process(false)
			set_physics_process(false)

func complete_segment() -> void:
	if current_state != SegmentState.COMPLETE and current_state != SegmentState.EXITED:
		set_state(SegmentState.COMPLETE)
