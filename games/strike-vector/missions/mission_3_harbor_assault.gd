class_name Mission3HarborAssault
extends Node3D

## Mission 3: Harbor Assault
## Environment: Wet container port, labyrinthian warehouses, shipyard drydock, cargo vessel.
## Objective: Breach shipyard, clear crane yard, eliminate Gantry Loader Titan.
## Boss: Harbor Gantry Loader Titan.

const MissionDefinitionsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const SetPieceDirectorScript = preload("res://games/strike-vector/setpieces/setpiece_director.gd")

static func create_segments() -> Array:
	var segs = MissionDefinitionsScript.build_mission_segments(3)

	# Setup M3 Set-Piece: Gantry crane container drop (Segment 2)
	if segs.size() > 1:
		var sp = SetPieceDirectorScript.new()
		sp.name = "SetPiece_DrydockBreach"
		sp.setpiece_id = "m3_drydock_breach"
		sp.duration_sec = 5.5
		sp.camera_shake_amount = 0.8
		segs[1].add_child(sp)

	return segs
