class_name Mission8FinalCitadel
extends Node3D

## Mission 8: Final Citadel
## Environment: Fortified siege trenches, fortress vehicle bay, grand interior hall, ascension towers, apex rooftop.
## Objective: Storm final enemy citadel, defeat 3-phase Citadel Overlord, escape collapsing fortress.
## Boss: Citadel Command Overlord (3-Phase Apex Boss).

const MissionDefinitionsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const SetPieceDirectorScript = preload("res://games/strike-vector/setpieces/setpiece_director.gd")

static func create_segments() -> Array:
	var segs = MissionDefinitionsScript.build_mission_segments(8)

	# Setup M8 Set-Piece: Timed extraction sprint through collapsing fortress (Segment 5)
	if segs.size() > 4:
		var sp = SetPieceDirectorScript.new()
		sp.name = "SetPiece_CitadelExtraction"
		sp.setpiece_id = "m8_citadel_escape"
		sp.duration_sec = 8.0
		sp.camera_shake_amount = 1.0
		segs[4].add_child(sp)

	return segs
