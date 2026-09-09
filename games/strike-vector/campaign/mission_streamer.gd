class_name MissionStreamer
extends Node3D

## Coordinates async preloading and safe streaming of mission segments.
## Ensures current segment + next segment are always resident, and only unloads
## distant completed segments after safe gate transitions. Never exposes empty void.

signal streaming_updated(active_index: int, total_segments: int)

var segments: Array = []
var active_segment_index: int = 0

func setup_segments(mission_segments: Array) -> void:
	segments = mission_segments
	for i in range(segments.size()):
		var seg = segments[i]
		seg.segment_index = i
		if not seg.get_parent():
			add_child(seg)

	# Initial state: Segment 0 ACTIVE, Segment 1 PRELOADED, others LOCKED
	if not segments.is_empty():
		segments[0].set_state(segments[0].SegmentState.ACTIVE)
		if segments.size() > 1:
			segments[1].set_state(segments[1].SegmentState.PRELOADED)

	streaming_updated.emit(0, segments.size())

func advance_to_next_segment() -> void:
	if active_segment_index >= segments.size() - 1:
		return

	var old_idx = active_segment_index
	active_segment_index += 1

	# Transition old segment to EXITED
	segments[old_idx].set_state(segments[old_idx].SegmentState.EXITED)

	# Transition new segment to ACTIVE
	segments[active_segment_index].set_state(segments[active_segment_index].SegmentState.ACTIVE)

	# Preload next segment if available
	if active_segment_index + 1 < segments.size():
		segments[active_segment_index + 1].set_state(segments[active_segment_index + 1].SegmentState.PRELOADED)

	# Safely unload distant segments (2 steps back)
	if active_segment_index - 2 >= 0:
		segments[active_segment_index - 2].set_state(segments[active_segment_index - 2].SegmentState.UNLOADED)

	streaming_updated.emit(active_segment_index, segments.size())

func get_active_segment() -> Node3D:
	if active_segment_index >= 0 and active_segment_index < segments.size():
		return segments[active_segment_index]
	return null
