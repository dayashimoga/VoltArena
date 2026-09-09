class_name Mission4DesertConvoy
extends Node3D

## Mission 4: Desert Convoy
## Environment: Canyon settlement, sandstone gorge, high-speed moving convoy, refinery pipelines.
## Objective: Intercept moving convoy, destroy escort gunships, dismantle Convoy Battle Rig.
## Boss: Convoy Dreadnought Battle Rig.

const MissionDefinitionsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const SetPieceDirectorScript = preload("res://games/strike-vector/setpieces/setpiece_director.gd")

static func create_segments() -> Array:
	var segs = MissionDefinitionsScript.build_mission_segments(4)

	# Setup M4 Set-Piece: Armored Convoy Pursuit Shootout (Segment 3)
	if segs.size() > 2:
		var sp = SetPieceDirectorScript.new()
		sp.name = "SetPiece_ConvoyChase"
		sp.setpiece_id = "m4_convoy_chase"
		sp.duration_sec = 7.0
		sp.camera_shake_amount = 0.85
		segs[2].add_child(sp)

	return segs
