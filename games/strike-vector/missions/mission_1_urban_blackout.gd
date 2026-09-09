class_name Mission1UrbanBlackout
extends Node3D

## Mission 1: Urban Blackout
## Environment: Blackout city streets, alleys, shopping center, rooftops, evacuation plaza.
## Objective: Restore power route, destroy jammer, reach plaza extraction.
## Boss: Urban Jammer Command Mech.

const MissionDefinitionsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const SetPieceDirectorScript = preload("res://games/strike-vector/setpieces/setpiece_director.gd")

static func create_segments() -> Array:
	var segs = MissionDefinitionsScript.build_mission_segments(1)

	# Setup M1 Set-Piece: Collapsing Street Roadblock / Crane Drop in Segment 2
	if segs.size() > 1:
		var sp = SetPieceDirectorScript.new()
		sp.name = "SetPiece_CraneDrop"
		sp.setpiece_id = "m1_crane_drop"
		sp.duration_sec = 5.0
		sp.camera_shake_amount = 0.7
		segs[1].add_child(sp)

	return segs
